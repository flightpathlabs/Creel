local _, ns = ...

-- The recipe card: what a catch turns into, and what that takes. Opened
-- from any "turns into" row in the book. It shows the product, the skill
-- the recipe asks for, every reagent with what it costs and where that
-- price comes from, and whether the product sells for more than its
-- parts. Where the product goes into something else in turn, those
-- recipes are listed too and open the card on themselves.
--
-- It looks like the book's fish card, and goes away the same ways: a
-- click anywhere else, or Escape (it's a named frame in UISpecialFrames,
-- as the book is; the game's own list of Escape handlers isn't touched,
-- since adding to it from addon code taints Escape's later steps).

local Kit = ns.Kit
local BookKit = ns.BookKit

local RecipeCard = {}
ns.RecipeCard = RecipeCard

local FRAME_NAME = "CreelRecipeCard"

local WIDTH = 300
local PADDING = 14
local ICON = 40
local ROW_ICON = 16
local LINE_GAP = 6
local PART_GAP = 12

-- Space between the card and whatever opened it.
local BESIDE = 20

local PROFESSIONS = {
    cooking = "Cooking",
    alchemy = "Alchemy",
    fishing = "Fishing",
    enchanting = "Enchanting",
    tailoring = "Tailoring",
    leatherworking = "Leatherworking",
}

local MUTED = Kit.MUTED

local card

-- What's showing: the source item, the recipe and what opened it.
local shown = {}

-- Prices -----------------------------------------------------------------------------

-- The auction house keeps this share of a sale.
local AUCTION_CUT = 0.05

--- What one of a reagent costs and where that price comes from: a vendor
--- where vendors sell it, otherwise the auction house. The catch itself,
--- which few people buy, falls back to what a vendor would pay for it:
--- what the player gives up by cooking it rather than selling it.
---@param isCatch boolean  the item the recipe was listed under
---@return number|nil copper, string|nil source
local function ReagentPrice(itemID, isCatch)
    local shop = ns.ShopPrices and ns.ShopPrices[itemID]
    if shop then
        return shop, "from a vendor"
    end
    local auction = ns.Values.Auction(itemID)
    if auction then
        return auction, "at auction"
    end
    if isCatch then
        local vendor = ns.Values.Vendor(itemID)
        if vendor and vendor > 0 then
            return vendor, "what a vendor pays"
        end
    end
    return nil, nil
end

--- What one of the product brings in: at auction, less the auction
--- house's cut, where there's a price, otherwise what a vendor pays.
---@return number|nil copper, string|nil source
local function ProductPrice(itemID)
    local auction = ns.Values.Auction(itemID)
    if auction then
        return math.floor(auction * (1 - AUCTION_CUT)), "At auction, after the auction house's cut."
    end
    local vendor = ns.Values.Vendor(itemID)
    if vendor and vendor > 0 then
        return vendor, "What a vendor pays."
    end
    return nil, nil
end

-- The reagents in a fixed order: the source item first, then the rest by ID.
local function Reagents(sourceID, use)
    local list = { { itemID = sourceID, count = use.needs or 1, source = true } }
    local others = {}
    for itemID, count in pairs(use.others or {}) do
        table.insert(others, { itemID = itemID, count = count })
    end
    table.sort(others, function(a, b)
        return a.itemID < b.itemID
    end)
    for _, other in ipairs(others) do
        table.insert(list, other)
    end
    return list
end

local function NameOrPlaceholder(itemID)
    return BookKit.Name(itemID) or "this"
end

-- "a, b and c".
local function Both(list)
    if #list <= 1 then
        return list[1] or ""
    end
    return table.concat(list, ", ", 1, #list - 1) .. " and " .. list[#list]
end

-- Pieces -----------------------------------------------------------------------------

local function ItemLink(itemID)
    local _, link = C_Item.GetItemInfo(itemID)
    return link
end

-- Shift-click puts an item's link in the chat box, the way the game's own
-- item buttons do.
local function InsertLink(itemID)
    local link = ItemLink(itemID)
    if not link then
        return false
    end
    local insert = (ChatFrameUtil and ChatFrameUtil.InsertLink) or ChatEdit_InsertLink
    return insert and insert(link) or false
end

-- One reagent: icon, count and name, its cost on the right, and where the
-- price comes from under it.
local function CreateReagent(parent)
    local row = CreateFrame("Button", nil, parent)

    row.icon = Kit.Icon(row, ROW_ICON)
    row.icon:SetPoint("TOPLEFT")

    row.cost = Kit.Text(row, "GameFontHighlightSmall", "RIGHT")
    row.cost:SetPoint("TOPRIGHT", 0, -1)

    row.name = Kit.Text(row, "GameFontHighlightSmall")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, -1)
    row.name:SetPoint("RIGHT", row.cost, "LEFT", -6, 0)

    row.note = Kit.Text(row, "GameFontHighlightSmall")
    row.note:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
    row.note:SetPoint("RIGHT")
    row.note:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

    Kit.DressRow(row)
    row:SetScript("OnEnter", function(self)
        BookKit.ItemTooltip(self, self.itemID)
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self)
        if IsModifiedClick("CHATLINK") then
            InsertLink(self.itemID)
        end
    end)
    row:SetHeight(ROW_ICON + 12)
    return row
end

-- One recipe the product goes into, which opens the card on itself.
local function CreateNextStep(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_ICON + 2)

    row.icon = Kit.Icon(row, ROW_ICON)
    row.icon:SetPoint("LEFT")

    row.name = Kit.Text(row, "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.name:SetPoint("RIGHT")

    Kit.DressRow(row)
    row:SetScript("OnEnter", function(self)
        BookKit.ItemTooltip(self, self.use.makes, "Click for how to make it.")
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self)
        if IsModifiedClick("CHATLINK") then
            InsertLink(self.use.makes)
            return
        end
        RecipeCard.Show(self.fromID, self.use, shown.owner)
    end)
    return row
end

local function CreatePair(parent)
    local pair = CreateFrame("Frame", nil, parent)
    pair:SetHeight(14)
    pair.label = Kit.Text(pair, "GameFontHighlightSmall")
    pair.label:SetPoint("LEFT")
    pair.label:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    pair.figure = Kit.Text(pair, "GameFontHighlightSmall", "RIGHT")
    pair.figure:SetPoint("RIGHT")
    return pair
end

local function OpenInGoldwise()
    local api = _G.GoldwiseAPI
    if shown.use and type(api) == "table" and type(api.ShowCraftTree) == "function" then
        local ok, opened = pcall(api.ShowCraftTree, shown.use.makes)
        if ok and opened then
            -- Goldwise's window sits under the book, so the book goes.
            card:Hide()
            ns.BookWindow.Close()
        end
    end
end

local function HasGoldwise()
    local api = _G.GoldwiseAPI
    return type(api) == "table" and type(api.ShowCraftTree) == "function"
end

-- The top-level window a frame sits in, so the card can live inside it and
-- close along with it.
local function WindowOf(frame)
    local window = frame
    while window and window:GetParent() and window:GetParent() ~= UIParent do
        window = window:GetParent()
    end
    return window or UIParent
end

local function IsWithin(frame, outer)
    while frame do
        if frame == outer then
            return true
        end
        frame = frame:GetParent()
    end
    return false
end

local function Create()
    card = CreateFrame("Frame", FRAME_NAME, UIParent, "TooltipBackdropTemplate")
    card:SetWidth(WIDTH)
    card:SetFrameStrata("FULLSCREEN_DIALOG")
    card:SetClampedToScreen(true)
    card:EnableMouse(true)
    card:Hide()
    table.insert(UISpecialFrames, FRAME_NAME)

    card.slot = BookKit.Slot(card, ICON)
    card.slot:SetPoint("TOPLEFT", PADDING, -PADDING)
    card.slot:SetScript("OnEnter", function(self)
        BookKit.ItemTooltip(self, self.itemID, "Shift-click to link it in chat.")
    end)
    card.slot:SetScript("OnLeave", GameTooltip_Hide)
    card.slot:SetScript("OnClick", function(self)
        if IsModifiedClick("CHATLINK") then
            InsertLink(self.itemID)
        end
    end)

    local nameLeft = PADDING + ICON + 10
    card.name = Kit.Paragraph(card, "GameFontNormalLarge")
    card.name:SetPoint("TOPLEFT", nameLeft, -(PADDING + 2))
    card.name:SetWidth(WIDTH - nameLeft - PADDING)
    card.skill = Kit.Text(card, "GameFontDisableSmall")
    card.skill:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)

    card.texts = BookKit.Pool(function()
        return Kit.Paragraph(card, "GameFontHighlightSmall")
    end)
    card.headings = BookKit.Pool(function()
        return Kit.Text(card, "GameFontNormalSmall")
    end)
    card.reagents = BookKit.Pool(function()
        return CreateReagent(card)
    end)
    card.pairs = BookKit.Pool(function()
        return CreatePair(card)
    end)
    card.steps = BookKit.Pool(function()
        return CreateNextStep(card)
    end)

    card.goldwise = Kit.Link(card, "Open in Goldwise", OpenInGoldwise)
    Kit.Tooltip(card.goldwise, "Open in Goldwise", function()
        return { "Shows the whole crafting tree for it in Goldwise, with prices." }
    end)

    -- A click anywhere else puts the card away. A click on what opened it
    -- is left to that, which closes the card as a toggle.
    card:SetScript("OnEvent", function(self, event)
        if event ~= "GLOBAL_MOUSE_DOWN" then
            return
        end
        if self:IsMouseOver() or (shown.owner and shown.owner:IsMouseOver()) then
            return
        end
        self:Hide()
    end)
    card:SetScript("OnShow", function(self)
        self:RegisterEvent("GLOBAL_MOUSE_DOWN")
    end)
    card:SetScript("OnHide", function(self)
        self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
        shown = {}
    end)
end

-- Filling it ---------------------------------------------------------------------------

local function Fill(sourceID, use)
    local width = WIDTH - 2 * PADDING
    local y = PADDING

    for _, pool in ipairs({ card.texts, card.headings, card.reagents, card.pairs, card.steps }) do
        pool:Reset()
    end

    local function Place(piece, gap, height)
        y = y + gap
        piece:ClearAllPoints()
        piece:SetPoint("TOPLEFT", PADDING, -y)
        piece:SetWidth(width)
        y = y + (height or piece:GetHeight())
    end

    local function Paragraph(words, gap)
        local text = card.texts:Next()
        text:SetWidth(width)
        text:SetText(words)
        Place(text, gap, text:GetStringHeight())
    end

    local function Heading(words)
        local heading = card.headings:Next()
        heading:SetText(words)
        Place(heading, PART_GAP, 14)
    end

    local function Pair(label, figure)
        local pair = card.pairs:Next()
        pair.label:SetText(label)
        pair.figure:SetText(figure)
        Place(pair, 3)
    end

    -- The product, and the skill it takes.
    local makes = use.makes
    BookKit.FillSlot(card.slot, makes, nil, true)
    card.name:SetText(BookKit.ColoredName(makes))

    local profession = PROFESSIONS[use.profession] or use.profession or ""
    -- Only a recipe item says the skill it's learned at. Trainers keep
    -- theirs on the server, so for those the colours below say the rest.
    local parts = {}
    if use.learn then
        table.insert(parts, ("%s %d"):format(profession, use.learn))
    else
        table.insert(parts, profession .. ", taught by a trainer")
    end
    table.insert(parts, ("makes %d"):format(use.count or 1))
    card.skill:SetText(table.concat(parts, " · "))
    y = y + math.max(ICON, card.name:GetStringHeight() + 18)

    -- When the recipe stops giving points. The data keeps yellow and grey;
    -- green is halfway between.
    if use.yellow and use.grey then
        local green = math.floor((use.yellow + use.grey) / 2)
        Paragraph(
            Kit.Colored(
                ("Yellow at %d, green at %d, grey at %d."):format(use.yellow, green, use.grey),
                MUTED
            ),
            PART_GAP
        )
    end
    if use.forever then
        Paragraph(Kit.Colored("New in Forever.", Kit.BLUE), LINE_GAP)
    end

    -- What goes in, and what that costs.
    Heading("Reagents")
    local total, missing = 0, {}
    for index, reagent in ipairs(Reagents(sourceID, use)) do
        local row = card.reagents:Next()
        row.itemID = reagent.itemID
        Kit.SetSpellIcon(row.icon, BookKit.Icon(reagent.itemID))
        row.name:SetText(("%d × %s"):format(reagent.count, BookKit.ColoredName(reagent.itemID)))

        local each, where = ReagentPrice(reagent.itemID, reagent.source)
        local notes = {}
        if each then
            local cost = each * reagent.count
            total = total + cost
            row.cost:SetText(ns.Money(cost))
            table.insert(notes, where)
        else
            row.cost:SetText("")
            table.insert(notes, "no price yet")
            table.insert(missing, NameOrPlaceholder(reagent.itemID))
        end
        if reagent.source then
            -- Bags only, as the book counts lures.
            local have = C_Item.GetItemCount(reagent.itemID, false) or 0
            table.insert(notes, ("you have %s"):format(BreakUpLargeNumbers(have)))
        end
        row.note:SetText(table.concat(notes, " · "))
        Place(row, index == 1 and LINE_GAP or 4)
    end

    -- Whether it's worth making, when everything has a price.
    Heading("Worth making?")
    local each, where = ProductPrice(makes)
    if #missing > 0 then
        Paragraph(
            Kit.Colored(
                ("No price yet for %s, so it can't be added up."):format(Both(missing)),
                MUTED
            ),
            LINE_GAP
        )
        if each then
            Pair("Sells for", ns.Money(each * (use.count or 1)))
            Paragraph(Kit.Colored(where, MUTED), 2)
        end
    elseif not each then
        Pair("Costs to make", ns.Money(total))
        Paragraph(Kit.Colored("No price yet for what it makes.", MUTED), LINE_GAP)
    else
        local sells = each * (use.count or 1)
        Pair("Costs to make", ns.Money(total))
        Pair("Sells for", ns.Money(sells))
        Paragraph(Kit.Colored(where, MUTED), 2)
        local difference = sells - total
        local words
        if difference >= 0 then
            words = Kit.Colored(
                ("About %s more than its parts."):format(ns.Money(difference)),
                Kit.GOOD
            )
        else
            words = Kit.Colored(
                ("About %s less than its parts."):format(ns.Money(-difference)),
                Kit.BAD
            )
        end
        Paragraph(words, LINE_GAP)
    end

    -- One step on: what the product goes into.
    local further = ns.Uses and ns.Uses[makes] or {}
    if #further > 0 then
        Heading("Goes into")
        for index, step in ipairs(further) do
            local row = card.steps:Next()
            row.fromID = makes
            row.use = step
            Kit.SetSpellIcon(row.icon, BookKit.Icon(step.makes))
            local label = BookKit.ColoredName(step.makes)
            local words = PROFESSIONS[step.profession] or step.profession or ""
            if step.learn then
                label = label .. Kit.Colored((" (%s %d)"):format(words, step.learn), MUTED)
            else
                label = label .. Kit.Colored((" (%s trainer)"):format(words), MUTED)
            end
            row.name:SetText(label)
            Place(row, index == 1 and LINE_GAP or 2)
        end
    end

    for _, pool in ipairs({ card.texts, card.headings, card.reagents, card.pairs, card.steps }) do
        pool:HideRest()
    end

    card.goldwise:SetShown(HasGoldwise())
    if HasGoldwise() then
        y = y + PART_GAP
        card.goldwise:ClearAllPoints()
        card.goldwise:SetPoint("TOPLEFT", PADDING - 4, -y)
        y = y + card.goldwise:GetHeight()
    end

    card:SetHeight(y + PADDING)
end

-- What others call ---------------------------------------------------------------------

--- Opens the card on a recipe beside whatever was clicked, or closes it
--- when it's already open there on the same recipe.
---@param sourceID number  the item the recipe was listed under
---@param use table  an entry from ns.Uses[sourceID]
---@param anchor table  the frame that was clicked
function RecipeCard.Show(sourceID, use, anchor)
    if not (sourceID and use and use.makes and anchor) then
        return
    end
    if not card then
        Create()
    end
    if card:IsShown() and shown.owner == anchor and shown.use == use then
        card:Hide()
        return
    end

    -- Inside the window it was opened from, so it closes with it.
    local window = WindowOf(anchor)
    if card:GetParent() ~= window then
        card:SetParent(window)
        card:SetFrameStrata("FULLSCREEN_DIALOG")
    end

    shown = { sourceID = sourceID, use = use, owner = anchor }
    Fill(sourceID, use)

    -- Beside what opened it, on the side of the screen with more room.
    card:ClearAllPoints()
    local x = anchor:GetCenter() or 0
    if x < UIParent:GetWidth() / 2 then
        card:SetPoint("TOPLEFT", anchor, "TOPRIGHT", BESIDE, 4)
    else
        card:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -BESIDE, 4)
    end
    card:Show()
end

function RecipeCard.Hide()
    if card then
        card:Hide()
    end
end

--- Closes the card if it was opened from inside a frame that's going away.
function RecipeCard.HideFrom(frame)
    if card and card:IsShown() and IsWithin(shown.owner, frame) then
        card:Hide()
    end
end

--- What the open card was opened from, if it's open.
---@return table|nil
function RecipeCard.Owner()
    return card and card:IsShown() and shown.owner or nil
end

--- Whether the mouse is over the card, for other popovers deciding
--- whether a click was meant for them.
function RecipeCard.IsMouseOver()
    return card ~= nil and card:IsShown() and card:IsMouseOver()
end

-- Names and prices fill in as the client's item cache answers.
local refillPending = false
ns.OnEvent("GET_ITEM_INFO_RECEIVED", function()
    if refillPending or not (card and card:IsShown()) then
        return
    end
    refillPending = true
    C_Timer.After(0.2, function()
        refillPending = false
        if card:IsShown() and shown.use then
            Fill(shown.sourceID, shown.use)
        end
    end)
end)
