local _, ns = ...

-- The Collection tab: everything that can come up on a line in this era,
-- as a gallery of icons grouped by kind. What's been caught is in colour
-- with a count in the corner; what hasn't is a dark silhouette with a
-- question mark, so there's always something left to go after.
--
-- Clicking an icon opens a small card beside it: a line or two about the
-- catch, where it's been caught best, what it's worth, and what it turns
-- into, with the values side by side.

local Kit = ns.Kit
local BookKit = ns.BookKit

local BookCollection = {}
ns.BookCollection = BookCollection

local MARGIN = BookKit.MARGIN

-- The gallery: eight to a row, each icon in a cell this tall.
local COLUMNS = 8
local SLOT_SIZE = 40
local ROW_HEIGHT = 54
local HEADING_GAP = 10
local GROUP_GAP = 18

-- The groups, top to bottom. Kinds come from Data/Catches.lua; within a
-- group, kinds keep this order and items go by ID, which keeps a species'
-- trophies together and roughly follows the order they were added to the
-- game.
local GROUPS = {
    { title = "Fish", kinds = { "fish" } },
    { title = "Oils, shellfish and oddities", kinds = { "oil", "shellfish", "other" } },
    { title = "Chests and junk", kinds = { "container", "junk" } },
    { title = "Trophies, contest and quest fish", kinds = { "trophy", "event", "quest" } },
}
local OTHER_TITLE = "Other catches"

local KIND_WORDS = {
    fish = "Fish",
    oil = "For alchemists",
    shellfish = "Shellfish",
    container = "Something to open",
    trophy = "Trophy fish",
    event = "Contest fish",
    quest = "Wanted for a quest",
    junk = "Junk",
    other = "Oddity",
}

local PROFESSION_WORDS = {
    cooking = "Cooking",
    alchemy = "Alchemy",
    fishing = "Fishing",
    enchanting = "Enchanting",
    tailoring = "Tailoring",
    leatherworking = "Leatherworking",
}

local tab

--- When and how a catch turns up, where the data says: for the silhouettes'
--- tooltips and the card.
local function Hints(itemID)
    local entry = ns.Catches and ns.Catches[itemID]
    local hints = {}
    if not entry then
        return hints
    end
    if entry.time == "night" then
        table.insert(hints, "Bites at night.")
    elseif entry.time == "day" then
        table.insert(hints, "Bites by day.")
    end
    if entry.season == "summer" then
        table.insert(hints, "Comes in summer.")
    elseif entry.season == "winter" then
        table.insert(hints, "Comes in winter.")
    end
    if entry.kind == "event" then
        table.insert(hints, "Only while the Stranglethorn fishing contest is on.")
    end
    return hints
end

local function KindLine(itemID)
    local entry = ns.Catches and ns.Catches[itemID]
    local words = entry and KIND_WORDS[entry.kind] or "A catch"
    if entry and entry.time then
        words = words .. (entry.time == "night" and " · night only" or " · day only")
    end
    if entry and entry.season then
        words = words .. " · " .. entry.season
    end
    return words
end

-- The groups' contents ---------------------------------------------------------

local function KindOrder(kinds)
    local order = {}
    for index, kind in ipairs(kinds) do
        order[kind] = index
    end
    return order
end

--- Each group with its item IDs in order, and the caught items the list
--- doesn't know about at the end.
local function Gather(book)
    local groups = {}
    for _, definition in ipairs(GROUPS) do
        local order = KindOrder(definition.kinds)
        local items = {}
        for itemID, entry in pairs(ns.Catches or {}) do
            if order[entry.kind] then
                table.insert(items, itemID)
            end
        end
        table.sort(items, function(a, b)
            local kindA, kindB = order[ns.Catches[a].kind], order[ns.Catches[b].kind]
            if kindA ~= kindB then
                return kindA < kindB
            end
            return a < b
        end)
        table.insert(groups, { title = definition.title, items = items })
    end

    local others = {}
    for itemID in pairs(book.fish) do
        if not (ns.Catches and ns.Catches[itemID]) then
            table.insert(others, itemID)
        end
    end
    if #others > 0 then
        table.sort(others)
        table.insert(groups, { title = OTHER_TITLE, items = others })
    end
    return groups
end

-- The card ---------------------------------------------------------------------

local CARD_WIDTH = 310
local CARD_PADDING = 14
local CARD_ICON = 44
local USE_ICON = 20
local USE_INDENT = 22
local LINE_GAP = 6
local PART_GAP = 12

-- A made thing is "worth more" when it beats the fish that go into it by
-- this much; inside the margin either way it's about the same.
local WORTH_MARGIN = 0.1

-- How many of a product's own uses are shown under it, one step on.
local NEXT_STEPS = 3

local card

--- The best places for a catch: where most of it has come from, with what
--- share of that place's catches it makes up.
local function BestSpots(itemID, limit)
    local list = {}
    for spotID, spot in pairs(ns.Book().spots) do
        local count = spot.catches[itemID]
        if count and count > 0 then
            table.insert(list, {
                spotID = spotID,
                spot = spot,
                count = count,
                share = ns.Spots.Share(spot, itemID),
            })
        end
    end
    table.sort(list, function(a, b)
        if a.count ~= b.count then
            return a.count > b.count
        end
        return a.spotID < b.spotID
    end)
    for index = #list, limit + 1, -1 do
        list[index] = nil
    end
    return list
end

--- A line or two of lore: the game's flavour text where there is any, and
--- the hand-written facts. "Cooks into" lines aren't wanted here; the card
--- has its own rows for those.
local function Lore(itemID)
    local lines = {}
    local flavour = BookKit.Flavour(itemID)
    if flavour then
        table.insert(lines, Kit.Colored(flavour, Kit.GOLD))
    end
    local tips = ns.Tips and ns.Tips[itemID] or {}
    if #tips > 0 then
        -- A different fact each time the card opens, where there are several.
        local first = math.random(#tips)
        table.insert(lines, tips[first])
        if #lines < 2 and #tips > 1 then
            table.insert(lines, tips[first % #tips + 1])
        end
    end
    return lines
end

--- Whether a recipe's result is worth more than what goes into it, at
--- today's prices, as a short coloured note. Other reagents aren't counted,
--- which the row's tooltip says.
local function Verdict(fromID, use)
    local raw = BookKit.Worth(fromID)
    local made = BookKit.Worth(use.makes)
    if not raw or not made or raw <= 0 then
        return nil
    end
    local rawTotal = raw * (use.needs or 1)
    local madeTotal = made * (use.count or 1)
    local word = use.profession == "cooking" and "cooked" or "made"
    if madeTotal > rawTotal * (1 + WORTH_MARGIN) then
        return Kit.Colored("worth more " .. word, Kit.GOOD)
    elseif madeTotal < rawTotal * (1 - WORTH_MARGIN) then
        return Kit.Colored("worth more as it is", Kit.MUTED)
    end
    return Kit.Colored("about the same either way", Kit.MUTED)
end

local function CreateText(parent, font)
    local text = Kit.Paragraph(parent, font)
    return text
end

--- One row of "Turns into": the product's icon, its name and the skill on
--- the first line with its value at the right; how many go in, whether
--- it's worth it, and whether Forever added it on the second. Clicking it
--- opens the recipe card, with every reagent and what it all costs.
local function CreateUseRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:EnableMouse(true)
    Kit.DressRow(row)

    row.icon = Kit.Icon(row, USE_ICON)
    row.icon:SetPoint("TOPLEFT")

    row.value = Kit.Text(row, "GameFontHighlightSmall", "RIGHT")
    row.value:SetPoint("TOPRIGHT", 0, -1)

    row.name = Kit.Text(row, "GameFontHighlightSmall")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, -1)
    row.name:SetPoint("RIGHT", row.value, "LEFT", -6, 0)

    row.note = Kit.Text(row, "GameFontHighlightSmall")
    row.note:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
    row.note:SetPoint("RIGHT")

    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.use.makes)
        local others = {}
        for otherID, count in pairs(self.use.others or {}) do
            local name = BookKit.Name(otherID) or "something else"
            table.insert(others, ("%d %s"):format(count, name))
        end
        if #others > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Also takes " .. table.concat(others, ", ") .. ".", 1, 1, 1, true)
            GameTooltip:AddLine(
                "Those aren't counted in whether it's worth making.",
                Kit.MUTED[1],
                Kit.MUTED[2],
                Kit.MUTED[3],
                true
            )
        end
        GameTooltip:AddLine(
            "Click for how to make it and what it costs.",
            Kit.MUTED[1],
            Kit.MUTED[2],
            Kit.MUTED[3]
        )
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self)
        if ns.RecipeCard then
            ns.RecipeCard.Show(self.fromID, self.use, self)
        end
    end)
    return row
end

local function FillUseRow(row, fromID, use, indent)
    row.use = use
    row.fromID = fromID
    row.icon:ClearAllPoints()
    row.icon:SetPoint("TOPLEFT", indent, 0)
    Kit.SetSpellIcon(row.icon, BookKit.Icon(use.makes))

    local profession = PROFESSION_WORDS[use.profession] or use.profession or ""
    local skill = use.learn or use.yellow
    local label = BookKit.ColoredName(use.makes)
    if skill then
        label = label .. Kit.Colored((" (%s %d)"):format(profession, skill), Kit.MUTED)
    end
    row.name:SetText(label)

    local worth = BookKit.Worth(use.makes)
    row.value:SetText(worth and ns.Money(worth) or "")

    local notes = {}
    if (use.needs or 1) > 1 or (use.count or 1) > 1 then
        table.insert(
            notes,
            Kit.Colored(("%d → %d"):format(use.needs or 1, use.count or 1), Kit.MUTED)
        )
    end
    local verdict = Verdict(fromID, use)
    if verdict then
        table.insert(notes, verdict)
    end
    if use.forever then
        table.insert(notes, Kit.Colored("new in Forever", Kit.BLUE))
    end
    row.note:SetText(table.concat(notes, Kit.Colored(" · ", Kit.MUTED)))
    row:SetHeight(USE_ICON + (#notes > 0 and 12 or 0))
end

--- A label on the left and a figure on the right, for the card's values.
local function CreatePair(parent)
    local pair = CreateFrame("Frame", nil, parent)
    pair:SetHeight(14)
    pair.label = Kit.Text(pair, "GameFontHighlightSmall")
    pair.label:SetPoint("LEFT")
    pair.label:SetTextColor(Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])
    pair.figure = Kit.Text(pair, "GameFontHighlightSmall", "RIGHT")
    pair.figure:SetPoint("RIGHT")
    return pair
end

local function CreateSpotLine(parent)
    local line = CreateFrame("Button", nil, parent)
    line:SetHeight(16)
    line.name = Kit.Text(line, "GameFontHighlightSmall")
    line.name:SetPoint("LEFT")
    line.share = Kit.Text(line, "GameFontHighlightSmall", "RIGHT")
    line.share:SetPoint("RIGHT")
    line.share:SetTextColor(Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])
    line.name:SetPoint("RIGHT", line.share, "LEFT", -8, 0)
    Kit.DressRow(line)
    line:SetScript("OnClick", function(self)
        ns.BookWindow.Open("places", self.spotID)
    end)
    return line
end

local function CreateCard(window)
    card = CreateFrame("Frame", nil, window, "TooltipBackdropTemplate")
    card:SetWidth(CARD_WIDTH)
    card:SetFrameStrata("DIALOG")
    card:SetClampedToScreen(true)
    card:EnableMouse(true)
    card:Hide()

    card.slot = BookKit.Slot(card, CARD_ICON)
    card.slot:EnableMouse(false)

    card.name = Kit.Paragraph(card, "GameFontNormalLarge")
    card.kind = Kit.Text(card, "GameFontDisableSmall")

    card.texts = BookKit.Pool(function()
        return CreateText(card, "GameFontHighlightSmall")
    end)
    card.headings = BookKit.Pool(function()
        return Kit.Text(card, "GameFontNormalSmall")
    end)
    card.pairs = BookKit.Pool(function()
        return CreatePair(card)
    end)
    card.spots = BookKit.Pool(function()
        return CreateSpotLine(card)
    end)
    card.uses = BookKit.Pool(function()
        return CreateUseRow(card)
    end)

    card.map = Kit.Link(card, "Show on map", function()
        if card.bestSpot then
            BookKit.ShowOnMap(card.bestSpot)
        end
    end)

    -- A click anywhere else puts the card away. A click on the icon it
    -- belongs to is left to that icon, which closes it as a toggle.
    -- A click on the recipe card opened from this one counts as inside it.
    card:SetScript("OnEvent", function(self)
        if self:IsMouseOver() or (self.owner and self.owner:IsMouseOver()) then
            return
        end
        if ns.RecipeCard and ns.RecipeCard.IsMouseOver() then
            return
        end
        self:Hide()
    end)
    card:SetScript("OnShow", function(self)
        self:RegisterEvent("GLOBAL_MOUSE_DOWN")
    end)
    card:SetScript("OnHide", function(self)
        if ns.RecipeCard then
            ns.RecipeCard.HideFrom(self)
        end
        self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
        self.owner = nil
        self.itemID = nil
    end)
end

-- Escape closes the book, and the card with it (the book is in
-- UISpecialFrames). The game's own list of Escape handlers isn't used:
-- adding to it from addon code sorts Blizzard's entries from tainted code,
-- and Escape's later steps (clearing the target, stopping a cast) would
-- then run tainted.

--- Lays out the card for one item. Every piece goes under the one before.
local function FillCard(itemID)
    local book = ns.Book()
    local fish = book.fish[itemID]
    local width = CARD_WIDTH - 2 * CARD_PADDING
    local y = CARD_PADDING

    for _, pool in ipairs({ card.texts, card.headings, card.pairs, card.spots, card.uses }) do
        pool:Reset()
    end

    local function Place(piece, gap, height, indent)
        y = y + gap
        piece:ClearAllPoints()
        piece:SetPoint("TOPLEFT", CARD_PADDING + (indent or 0), -y)
        piece:SetWidth(width - (indent or 0))
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
        Place(heading, PART_GAP, heading:GetStringHeight())
    end

    local function Pair(label, figure)
        local pair = card.pairs:Next()
        pair.label:SetText(label)
        pair.figure:SetText(figure)
        Place(pair, LINE_GAP)
    end

    -- The icon and the name beside it.
    BookKit.FillSlot(card.slot, itemID, nil, fish ~= nil)
    card.slot:SetPoint("TOPLEFT", CARD_PADDING, -CARD_PADDING)

    local nameLeft = CARD_PADDING + CARD_ICON + 10
    card.name:ClearAllPoints()
    card.name:SetPoint("TOPLEFT", nameLeft, -(CARD_PADDING + 2))
    card.name:SetWidth(CARD_WIDTH - nameLeft - CARD_PADDING)
    card.name:SetText(BookKit.ColoredName(itemID))
    card.kind:ClearAllPoints()
    card.kind:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
    card.kind:SetText(KindLine(itemID))
    y = y + math.max(CARD_ICON, card.name:GetStringHeight() + 18)

    for index, line in ipairs(Lore(itemID)) do
        Paragraph(line, index == 1 and PART_GAP or LINE_GAP)
    end

    -- Caught, when first, and where.
    if fish then
        local caught = fish.caught == 1 and "Caught once"
            or ("Caught %s times"):format(BreakUpLargeNumbers(fish.caught))
        local first = ""
        if fish.firstAt then
            first = " · first on " .. BookKit.DateText(fish.firstAt)
            local spot = fish.firstSpot and book.spots[fish.firstSpot]
            if spot then
                first = first .. " at " .. ns.Spots.Name(spot)
            end
        end
        Paragraph(caught .. Kit.Colored(first, Kit.MUTED), PART_GAP)
    else
        local hints = Hints(itemID)
        table.insert(hints, 1, "Not caught yet.")
        Paragraph(Kit.Colored(table.concat(hints, " "), Kit.MUTED), PART_GAP)
    end

    -- Where it's been caught best.
    local best = BestSpots(itemID, 3)
    card.bestSpot = best[1] and best[1].spot.mapID and best[1].spot.mapX and best[1].spotID or nil
    if #best > 0 then
        Heading("Best spots")
        for index, entry in ipairs(best) do
            local line = card.spots:Next()
            line.spotID = entry.spotID
            line.name:SetText(ns.Spots.Name(entry.spot))
            line.share:SetText(BookKit.ShareText(entry.share))
            Place(line, index == 1 and LINE_GAP or 2)
        end
    end

    -- What it's worth, and what it's made.
    Heading("Value")
    local vendor = ns.Values.Vendor(itemID)
    if vendor == nil then
        Pair("Vendor", Kit.Colored("not known yet", Kit.MUTED))
    else
        Pair("Vendor", vendor > 0 and ns.Money(vendor) or Kit.Colored("won't buy it", Kit.MUTED))
    end
    local auction, source, seenAt = ns.Values.Auction(itemID)
    if auction then
        local where = source or ""
        if seenAt then
            where = ("%s, %s"):format(where, BookKit.Age(seenAt))
        end
        Pair("Auction", ns.Money(auction) .. Kit.Colored(" · " .. where, Kit.MUTED))
    else
        Pair("Auction", Kit.Colored("no price yet", Kit.MUTED))
    end
    local made = (book.sales.vendor[itemID] or 0) + (book.sales.auction[itemID] or 0)
    if made > 0 then
        Pair("You've made", ns.Money(made))
    end

    -- What it turns into, and one step on from there.
    local uses = ns.Uses and ns.Uses[itemID] or {}
    if #uses > 0 then
        Heading("Turns into")
        for _, use in ipairs(uses) do
            local row = card.uses:Next()
            FillUseRow(row, itemID, use, 0)
            Place(row, LINE_GAP)

            local further = ns.Uses[use.makes] or {}
            for index = 1, math.min(#further, NEXT_STEPS) do
                local step = card.uses:Next()
                FillUseRow(step, use.makes, further[index], USE_INDENT)
                Place(step, 4)
            end
        end
    end

    for _, pool in ipairs({ card.texts, card.headings, card.pairs, card.spots, card.uses }) do
        pool:HideRest()
    end

    card.map:SetShown(card.bestSpot ~= nil)
    if card.bestSpot then
        y = y + PART_GAP
        card.map:ClearAllPoints()
        card.map:SetPoint("TOPLEFT", CARD_PADDING - 4, -y)
        y = y + card.map:GetHeight()
    end

    card:SetHeight(y + CARD_PADDING)
end

--- Opens the card beside an icon, or closes it if it's already open there.
local function ToggleCard(slot)
    if not card then
        CreateCard(tab.window)
    end
    if card:IsShown() and card.owner == slot then
        card:Hide()
        return
    end

    card.owner = slot
    card.itemID = slot.itemID
    FillCard(slot.itemID)

    -- Beside the icon, on whichever side of the window has more room.
    card:ClearAllPoints()
    local windowLeft = tab.window:GetLeft() or 0
    local windowRight = tab.window:GetRight() or 0
    local slotX = slot:GetCenter() or 0
    if slotX - windowLeft < windowRight - slotX then
        card:SetPoint("TOPLEFT", slot, "TOPRIGHT", 8, 4)
    else
        card:SetPoint("TOPRIGHT", slot, "TOPLEFT", -8, 4)
    end
    card:Show()
end

-- The gallery ------------------------------------------------------------------

local function ShowSlotTooltip(slot)
    local itemID = slot.itemID
    if slot.known then
        BookKit.ItemTooltip(slot, itemID, "Click for more about it.")
        return
    end

    GameTooltip:SetOwner(slot, "ANCHOR_RIGHT")
    local name = BookKit.Name(itemID)
    GameTooltip:SetText(
        name or "Something still out there",
        Kit.MUTED[1],
        Kit.MUTED[2],
        Kit.MUTED[3]
    )
    GameTooltip:AddLine("Not caught yet.", 1, 1, 1)
    for _, hint in ipairs(Hints(itemID)) do
        GameTooltip:AddLine(hint, 1, 1, 1, true)
    end
    GameTooltip:AddLine("Click for more about it.", Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])
    GameTooltip:Show()
end

local function CreateSlot()
    local slot = BookKit.Slot(tab.page, SLOT_SIZE)
    slot:SetScript("OnEnter", ShowSlotTooltip)
    slot:SetScript("OnLeave", GameTooltip_Hide)
    slot:SetScript("OnClick", ToggleCard)
    return slot
end

--- The figures across the top: kinds caught out of all there are, how much
--- has been caught, and what it's made.
local function FillStats(book, groups)
    local kinds, caughtKinds = 0, 0
    local byGroup = {}
    for _, group in ipairs(groups) do
        local inGroup = 0
        for _, itemID in ipairs(group.items) do
            if book.fish[itemID] then
                inGroup = inGroup + 1
            end
        end
        group.caught = inGroup
        if group.title ~= OTHER_TITLE then
            kinds = kinds + #group.items
            caughtKinds = caughtKinds + inGroup
            table.insert(byGroup, { group.title, ("%d of %d"):format(inGroup, #group.items) })
        end
    end

    local vendor, auction = ns.Values.Earned()
    local width = tab:GetWidth() - 2 * MARGIN
    tab.stats:Fill({
        {
            label = "Kinds caught",
            value = ("%d of %d"):format(caughtKinds, kinds),
            figures = byGroup,
        },
        {
            label = "Catches",
            value = BreakUpLargeNumbers(book.totals.catches or 0),
            figures = {},
        },
        {
            label = "Made from them",
            value = ns.Money(vendor + auction),
            title = "Made from your catches",
            figures = {
                { "Sold to vendors", ns.Money(vendor) },
                { "Sold at auction", ns.Money(auction) },
            },
            note = "From the sales the book has seen. The Earnings tab has the detail.",
        },
    }, width, false)
end

local function Refresh()
    local book = ns.Book()
    local groups = Gather(book)
    FillStats(book, groups)

    local width = tab.scroll:GetWidth()
    tab.page:SetWidth(width)
    local cell = width / COLUMNS
    local y = 0
    tab.slotAt = {}

    tab.headings:Reset()
    tab.slots:Reset()
    for groupIndex, group in ipairs(groups) do
        local heading = tab.headings:Next()
        heading:Set(group.title, ("%d of %d"):format(group.caught, #group.items))
        heading:ClearAllPoints()
        heading:SetPoint("TOPLEFT", 0, -y)
        heading:SetWidth(width)
        y = y + heading:GetHeight() + HEADING_GAP

        for index, itemID in ipairs(group.items) do
            local column = (index - 1) % COLUMNS
            local row = math.floor((index - 1) / COLUMNS)
            local slot = tab.slots:Next()
            local fish = book.fish[itemID]
            slot.known = fish ~= nil
            BookKit.FillSlot(slot, itemID, fish and fish.caught, slot.known)
            slot:ClearAllPoints()
            slot:SetPoint(
                "TOPLEFT",
                math.floor(column * cell + (cell - SLOT_SIZE) / 2),
                -(y + row * ROW_HEIGHT)
            )
            tab.slotAt[itemID] = { slot = slot, y = y + row * ROW_HEIGHT }
        end
        y = y + math.ceil(#group.items / COLUMNS) * ROW_HEIGHT
        if groupIndex < #groups then
            y = y + GROUP_GAP
        end
    end
    tab.headings:HideRest()
    tab.slots:HideRest()
    tab.page:SetHeight(math.max(1, y))

    -- An open card follows its item through the redraw, or goes if the
    -- item's icon has gone.
    if card and card:IsShown() then
        local at = tab.slotAt[card.itemID]
        if at then
            card.owner = nil
            ToggleCard(at.slot)
        else
            card:Hide()
        end
    end
end

--- Scrolls to an item and opens its card.
local function Target(_, itemID)
    Refresh()
    local at = tab.slotAt[itemID]
    if not at then
        return
    end
    BookKit.ScrollTo(tab.scroll, at.y)
    if card and card:IsShown() and card.owner == at.slot then
        return
    end
    ToggleCard(at.slot)
end

---@param parent table  the window's inset, which the tab fills
---@param window table  the book's frame
function BookCollection.Create(parent, window)
    tab = CreateFrame("Frame", nil, parent)
    tab:SetAllPoints()
    tab.window = window

    tab.stats = Kit.StatRow(tab)
    tab.stats:SetPoint("TOPLEFT", MARGIN, -MARGIN)
    tab.stats:SetPoint("RIGHT", -MARGIN, 0)

    tab.scroll, tab.page = BookKit.ScrollArea(tab)
    tab.scroll:SetPoint("TOPLEFT", tab.stats, "BOTTOMLEFT", 0, -GROUP_GAP)
    tab.scroll:SetPoint("BOTTOMRIGHT", -BookKit.SCROLL_BAR_ROOM, MARGIN)

    tab.headings = BookKit.Pool(function()
        return BookKit.Heading(tab.page)
    end)
    tab.slots = BookKit.Pool(CreateSlot)

    tab:SetScript("OnHide", function()
        if card then
            card:Hide()
        end
    end)

    tab.Refresh = Refresh
    tab.Target = Target
    return tab
end
