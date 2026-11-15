local _, ns = ...

-- The Collection tab: everything that can come up on a line in this era,
-- as a gallery of icons grouped by kind. What's been caught is in colour
-- with a count in the corner; what hasn't is a dark silhouette with a
-- question mark, so there's always something left to go after.
--
-- Clicking an icon opens a small card beside it: a line or two about the
-- catch, where it's been caught best, what it's worth, and what it turns
-- into, with the values side by side.
--
-- Anything caught that Creel didn't know could come off a line is a unique
-- find. Those go first, under a heading of their own, and their card says
-- when, where and at what skill the first one came up, with a button that
-- writes up a report to copy to Creel's GitHub page.

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

-- Anything caught that isn't on Creel's list goes in a group of its own at
-- the top: things the game hands out that nobody knew could be fished up.
local UNIQUE_TITLE = "Unique finds"

-- Where a unique find is reported: an issue form on Creel's GitHub page.
local REPORT_ADDRESS = "https://github.com/flightpathlabs/Creel/issues/new?template=unique_find.yml"

-- Art for unique finds, all from the game's own interface code: the loot
-- toast's glow and its upgrade toast's border glow
-- (Blizzard_FrameXML\Mainline\AlertFrameSystems), and the ribbon from the
-- Traveler's Log (Blizzard_EncounterJournal\Mainline\Blizzard_MonthlyActivities).
local GLOW = "loottoast-glow"
local BORDER_GLOW = "loottoast-itemborder-glow"
local TOAST_BORDER = "loottoast-itemborder-white"
local RIBBON = "activities-ribbon"
local RIBBON_HEIGHT = 24

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
    -- These are the original game's rules; Forever may differ.
    if entry.time == "night" then
        table.insert(hints, "In the original game it bit only at night.")
    elseif entry.time == "day" then
        table.insert(hints, "In the original game it bit only by day.")
    end
    if entry.season == "summer" then
        table.insert(hints, "In the original game it came in summer.")
    elseif entry.season == "winter" then
        table.insert(hints, "In the original game it came in winter.")
    end
    if entry.kind == "event" then
        table.insert(hints, "Only while the Stranglethorn fishing contest is on.")
    end
    return hints
end

local function KindLine(itemID)
    local entry = ns.Catches and ns.Catches[itemID]
    local words = entry and KIND_WORDS[entry.kind] or "Not on Creel's list of catches"
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

--- Each group with its item IDs in order, with the unique finds (caught
--- items the list doesn't know about) first when there are any.
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

    local finds = {}
    for itemID in pairs(book.fish) do
        if not (ns.Catches and ns.Catches[itemID]) then
            table.insert(finds, itemID)
        end
    end
    if #finds > 0 then
        table.sort(finds)
        table.insert(groups, 1, { title = UNIQUE_TITLE, items = finds, unique = true })
    end
    return groups
end

-- Unique finds -----------------------------------------------------------------

--- How big the border glow is drawn round a border this many pixels
--- across: as much bigger as the game's own pair of pictures are.
local function GlowSize(borderSize)
    local glow = C_Texture.GetAtlasInfo(BORDER_GLOW)
    local border = C_Texture.GetAtlasInfo(TOAST_BORDER)
    if glow and border and border.width > 0 then
        return borderSize * glow.width / border.width
    end
    return borderSize * 1.4
end

--- A slow shine round a unique find's slot in the gallery, made the first
--- time a slot needs it. Slots are reused, so it's switched off again for
--- everything else.
local function SetShine(slot, on)
    if not slot.shine then
        if not on then
            return
        end
        local shine = slot:CreateTexture(nil, "OVERLAY", nil, 1)
        shine:SetPoint("CENTER")
        local size = GlowSize(SLOT_SIZE)
        shine:SetSize(size, size)
        if not BookKit.SetAtlasIfThere(shine, BORDER_GLOW) then
            BookKit.SetAtlasIfThere(shine, GLOW)
        end
        shine:SetBlendMode("ADD")
        shine:SetVertexColor(Kit.GOLD[1], Kit.GOLD[2], Kit.GOLD[3])

        shine.anim = shine:CreateAnimationGroup()
        shine.anim:SetLooping("BOUNCE")
        local breathe = shine.anim:CreateAnimation("Alpha")
        breathe:SetFromAlpha(0.15)
        breathe:SetToAlpha(0.55)
        breathe:SetDuration(1.6)
        breathe:SetSmoothing("IN_OUT")
        slot.shine = shine
    end
    slot.shine:SetShown(on)
    if on then
        if not slot.shine.anim:IsPlaying() then
            slot.shine.anim:Play()
        end
    else
        slot.shine.anim:Stop()
    end
end

--- The unique finds' heading stands apart from the rest: a soft gold light
--- behind it and the title in the colour of legendary loot. Headings are
--- reused, so the others are put back as they were.
local function DressHeading(heading, unique)
    if not heading.band then
        if not unique then
            return
        end
        local band = heading:CreateTexture(nil, "BACKGROUND")
        BookKit.SetAtlasIfThere(band, GLOW)
        band:SetBlendMode("ADD")
        band:SetVertexColor(Kit.GOLD[1], Kit.GOLD[2], Kit.GOLD[3])
        band:SetAlpha(0.45)
        band:SetPoint("TOPLEFT", heading.title, "TOPLEFT", -24, 10)
        band:SetPoint("BOTTOMRIGHT", heading.note, "BOTTOMRIGHT", 24, -10)
        heading.band = band
    end
    heading.band:SetShown(unique)
    if unique then
        local r, g, b = C_Item.GetItemQualityColor(Enum.ItemQuality.Legendary)
        heading.title:SetTextColor(r, g, b)
    else
        heading.title:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
    end
end

--- What's known about a unique find's first catch: from the record the
--- fishing code keeps, or, for a find caught before it kept one, from the
--- book's own entry for the item.
local function FindOf(book, itemID)
    local find = book.finds and book.finds[itemID]
    if find then
        return find
    end
    local fish = book.fish[itemID]
    if not fish then
        return nil
    end
    local spot = fish.firstSpot and book.spots[fish.firstSpot]
    return {
        firstAt = fish.firstAt,
        spotID = fish.firstSpot,
        zone = spot and spot.zone,
        subzone = spot and ns.Spots.Name(spot),
        mapID = spot and spot.mapID,
        mapX = spot and spot.mapX,
        mapY = spot and spot.mapY,
    }
end

--- "Lake Everstill, Redridge Mountains", or as much of it as is known.
local function PlaceText(find)
    local parts = {}
    if find.subzone and find.subzone ~= "" and find.subzone ~= find.zone then
        table.insert(parts, find.subzone)
    end
    if find.zone and find.zone ~= "" then
        table.insert(parts, find.zone)
    end
    return #parts > 0 and table.concat(parts, ", ") or nil
end

--- "187 (+25 from pole, lure and gear)": the skill and what was added to
--- it, apart. A find recorded before the two were kept apart has only the
--- total, and says so.
local function SkillText(find)
    if find.rank then
        local bonus = find.bonus or 0
        if bonus > 0 then
            return ("%d (+%d from pole, lure and gear)"):format(find.rank, bonus)
        end
        return tostring(find.rank)
    elseif find.skill then
        return ("%d with pole, lure and gear"):format(find.skill)
    end
    return nil
end

--- The report to paste into the issue form: plain text, one fact a line.
local function ReportText(itemID)
    local book = ns.ShownBook()
    local find = FindOf(book, itemID) or {}
    local fish = book.fish[itemID]
    local name = C_Item.GetItemNameByID(itemID) or "(name not loaded)"
    local link = select(2, C_Item.GetItemInfo(itemID))
    local itemString = link and link:match("|H(item:[^|]+)|h")

    local lines = {
        "Creel unique find",
        ("Item: %s"):format(name),
        ("Item ID: %d"):format(itemID),
    }
    if itemString then
        table.insert(lines, ("Item link: [%s] %s"):format(name, itemString))
    end
    table.insert(lines, ("Zone: %s"):format(find.zone or "unknown"))
    if find.subzone and find.subzone ~= "" then
        table.insert(lines, ("Subzone: %s"):format(find.subzone))
    end
    if find.mapX and find.mapY then
        local map = find.mapID and C_Map.GetMapInfo(find.mapID)
        table.insert(
            lines,
            ("Coordinates: %.1f, %.1f%s"):format(
                find.mapX * 100,
                find.mapY * 100,
                map and map.name and (" (%s, map %d)"):format(map.name, find.mapID) or ""
            )
        )
    end
    local skill = SkillText(find)
    if skill then
        table.insert(lines, ("Fishing skill: %s"):format(skill))
    end
    if find.firstAt then
        table.insert(lines, ("First caught: %s"):format(date("%Y-%m-%d %H:%M", find.firstAt)))
    end
    if fish then
        table.insert(lines, ("Times caught: %d"):format(fish.caught or 0))
    end
    local version, build = GetBuildInfo()
    table.insert(lines, ("Game: %s (%s)"):format(version or "?", build or "?"))
    local creel = C_AddOns.GetAddOnMetadata(ns.name, "Version")
    table.insert(lines, ("Creel: %s"):format(creel or "?"))
    return table.concat(lines, "\n")
end

-- The report window: what to copy and where to paste it. An addon can't
-- send anything anywhere, so this is as far as it goes.
local REPORT_WIDTH = 440
local REPORT_TEXT_HEIGHT = 190
local report

--- An edit box that shows a text and won't let it be changed: anything
--- typed puts the text back, all of it selected, ready for Ctrl+C.
local function ReadOnly(box)
    local function SelectAll(self)
        self:SetFocus()
        self:HighlightText()
    end
    box:SetAutoFocus(false)
    box:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(self.fixed or "")
            self:HighlightText()
        end
    end)
    box:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    box:SetScript("OnMouseUp", SelectAll)
    box:SetScript("OnEscapePressed", function()
        report:Hide()
    end)
    box:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)
end

local function CreateReport()
    -- It belongs to the book, so it goes when the book does and never
    -- keeps the keyboard after.
    report = CreateFrame("Frame", nil, tab.window)
    report:SetSize(REPORT_WIDTH, REPORT_TEXT_HEIGHT + 196)
    report:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    report:SetFrameStrata("DIALOG")
    report:SetToplevel(true)
    report:EnableMouse(true)
    report:Hide()

    local border = CreateFrame("Frame", nil, report, "DialogBorderTemplate")
    border:SetAllPoints()
    report.header = CreateFrame("Frame", nil, report, "DialogHeaderTemplate")
    report.header:Setup("Report this find")

    local inner = REPORT_WIDTH - 48

    local intro = Kit.Paragraph(report, "GameFontHighlight")
    intro:SetWidth(inner)
    intro:SetPoint("TOP", 0, -32)
    intro:SetText(
        "Copy this with Ctrl+C and paste it into the unique find form on Creel's GitHub page. "
            .. "Nothing is sent from the game."
    )

    local box = Kit.Box(report)
    box:SetPoint("TOP", intro, "BOTTOM", 0, -12)
    box:SetSize(inner, REPORT_TEXT_HEIGHT)

    report.text = CreateFrame("EditBox", nil, box)
    report.text:SetMultiLine(true)
    report.text:SetFontObject("GameFontHighlightSmall")
    report.text:SetPoint("TOPLEFT", 10, -10)
    report.text:SetPoint("BOTTOMRIGHT", -10, 10)
    report.text:SetWidth(inner - 20)
    ReadOnly(report.text)

    local where = Kit.Text(report, "GameFontNormal")
    where:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -14)
    where:SetText("Creel's GitHub page")

    report.address = CreateFrame("EditBox", nil, report, "InputBoxTemplate")
    report.address:SetHeight(22)
    report.address:SetPoint("TOPLEFT", where, "BOTTOMLEFT", 6, -4)
    report.address:SetWidth(inner - 6)
    report.address:SetFontObject("GameFontHighlightSmall")
    ReadOnly(report.address)

    local close = Kit.Button(report, OKAY, 110, function()
        report:Hide()
    end)
    close:SetPoint("BOTTOM", 0, 16)

    report:SetScript("OnHide", function()
        report.text:ClearFocus()
        report.address:ClearFocus()
    end)
end

local function ShowReport(itemID)
    if not report then
        CreateReport()
    end
    local text = ReportText(itemID)
    report.text.fixed = text
    report.text:SetText(text)
    report.address.fixed = REPORT_ADDRESS
    report.address:SetText(REPORT_ADDRESS)
    report.address:SetCursorPosition(0)
    report:Show()
    report.text:SetFocus()
    report.text:HighlightText()
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
    for spotID, spot in pairs(ns.ShownBook().spots) do
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

--- Whether a recipe's result is worth more than everything that goes into
--- it, at today's prices, as a short coloured note: the same sum as the
--- recipe card. Nothing when a part has no price yet.
local function Verdict(fromID, use)
    local rawTotal, madeTotal, complete = ns.Values.RecipeWorth(fromID, use)
    if not complete or not madeTotal or rawTotal <= 0 then
        return nil
    end
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
    -- Only a recipe item says the skill it's learned at; trainers keep
    -- theirs on the server.
    local label = BookKit.ColoredName(use.makes)
    if use.learn then
        label = label .. Kit.Colored((" (%s %d)"):format(profession, use.learn), Kit.MUTED)
    else
        label = label .. Kit.Colored((" (%s trainer)"):format(profession), Kit.MUTED)
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

    -- A unique find's ribbon across the card, and the button that writes
    -- up a report of it.
    card.ribbon = CreateFrame("Frame", nil, card)
    card.ribbon:SetHeight(RIBBON_HEIGHT)
    local ribbonArt = card.ribbon:CreateTexture(nil, "ARTWORK")
    ribbonArt:SetPoint("CENTER")
    local ribbonInfo = C_Texture.GetAtlasInfo(RIBBON)
    -- The Traveler's Log's ribbon where its shape suits a strip this
    -- size; a band of gold light otherwise.
    local ribbonWidth = ribbonInfo
        and ribbonInfo.height > 0
        and RIBBON_HEIGHT * ribbonInfo.width / ribbonInfo.height
    if ribbonWidth and ribbonWidth >= 120 and ribbonWidth <= CARD_WIDTH then
        ribbonArt:SetAtlas(RIBBON)
        ribbonArt:SetSize(ribbonWidth, RIBBON_HEIGHT)
    else
        BookKit.SetAtlasIfThere(ribbonArt, GLOW)
        ribbonArt:SetBlendMode("ADD")
        ribbonArt:SetVertexColor(Kit.GOLD[1], Kit.GOLD[2], Kit.GOLD[3])
        ribbonArt:SetAlpha(0.6)
        ribbonArt:SetSize(CARD_WIDTH - 2 * CARD_PADDING, RIBBON_HEIGHT + 8)
    end
    local ribbonText = Kit.Text(card.ribbon, "GameFontNormal", "CENTER")
    ribbonText:SetPoint("CENTER", 0, 1)
    ribbonText:SetText("Unique find")

    card.report = Kit.Button(card, "Report this find", 150, function()
        if card.itemID then
            ShowReport(card.itemID)
        end
    end)
    Kit.Tooltip(card.report, "Report this find", function()
        return {
            "Creel didn't know this could come off a fishing line. A report helps "
                .. "everyone find it.",
            "Shows a short report to copy into a form on Creel's GitHub page. Nothing "
                .. "is sent from the game.",
        }
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
        if report and report:IsShown() and report:IsMouseOver() then
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
    local book = ns.ShownBook()
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

    local unique = fish ~= nil and not (ns.Catches and ns.Catches[itemID])
    -- A find from the screenshot demo is made up, so it's never offered
    -- for reporting.
    local reportable = unique and not (ns.Demo and ns.Demo.IsOn())
    card.ribbon:SetShown(unique)
    card.report:SetShown(reportable)
    if unique then
        Place(card.ribbon, PART_GAP, RIBBON_HEIGHT)
    end

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

    -- A unique find: when, where and at what skill the first came up, and
    -- the button to report it.
    if unique then
        local find = FindOf(book, itemID) or {}
        Heading("Your find")
        if find.firstAt then
            Pair("First caught", BookKit.DayAndTime(find.firstAt))
        end
        local where = PlaceText(find)
        if where then
            Pair("Where", where)
        end
        if find.mapX and find.mapY then
            Pair("Map position", ("%.1f, %.1f"):format(find.mapX * 100, find.mapY * 100))
        end
        local skill = SkillText(find)
        if skill then
            Pair("Fishing skill", skill)
        end
        if find.character then
            Pair("Caught by", BookKit.CharacterName(find.character))
        end
        if reportable then
            y = y + PART_GAP
            card.report:ClearAllPoints()
            card.report:SetPoint("TOPLEFT", CARD_PADDING, -y)
            y = y + card.report:GetHeight()
        end
    end

    -- Where it's been caught best.
    local best = BestSpots(itemID, 3)
    local bestSpot = best[1] and best[1].spot
    card.bestSpot = bestSpot
            and bestSpot.mapX
            and BookKit.MapKnown(bestSpot.mapID)
            and best[1].spotID
        or nil
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
        if not group.unique then
            kinds = kinds + #group.items
            caughtKinds = caughtKinds + inGroup
            table.insert(byGroup, { group.title, ("%d of %d"):format(inGroup, #group.items) })
        end
    end

    local vendor, auction = ns.Values.Earned(book)
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
    local book = ns.ShownBook()
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
        if group.unique then
            heading:Set(group.title, ("%d not on Creel's list"):format(#group.items))
        else
            heading:Set(group.title, ("%d of %d"):format(group.caught, #group.items))
        end
        DressHeading(heading, group.unique == true)
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
            SetShine(slot, group.unique == true)
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
        if report then
            report:Hide()
        end
    end)

    tab.Refresh = Refresh
    tab.Target = Target
    return tab
end
