local _, ns = ...

-- The Places tab: the spots fished, grouped under their zones. A spot is
-- every catch within about forty yards of the others (Fishing/Spots.lua),
-- so a pond fished from three rocks is one place here.
--
-- Each place shows what it gives, as icons with their shares, how long
-- was spent there and how fast it gave, and the lowest skill it's been
-- fished at, with a warning if fish have got away there. The game keeps
-- zone skill levels on its servers, so this is learned from the player
-- rather than looked up.

local Kit = ns.Kit
local BookKit = ns.BookKit

local BookPlaces = {}
ns.BookPlaces = BookPlaces

local MARGIN = BookKit.MARGIN

local ROW_HEIGHT = 58
local ROW_GAP = 4
local ZONE_GAP = 16
local HEADING_GAP = 6

-- The words on the left, then the catch icons, then the map link.
local WORDS_WIDTH = 250
local CATCH_ICON = 28
local CATCH_CELL = 46
local CATCHES_SHOWN = 5

-- Below this much time at a place, a rate an hour says more about luck
-- than the water.
local RATE_AFTER = 300

local tab

local function SpotLines(spot)
    local first = {}
    if (spot.seconds or 0) > 0 then
        table.insert(first, ns.Hours(spot.seconds) .. " here")
    end
    if (spot.seconds or 0) >= RATE_AFTER then
        table.insert(first, ("%d an hour"):format(math.floor(spot.caught * 3600 / spot.seconds)))
    end
    table.insert(first, BookKit.Plural(spot.caught, "catch", "catches"))

    local second = {}
    if spot.lowestSkill then
        table.insert(second, ("Fished from skill %d"):format(spot.lowestSkill))
    end
    if spot.needsSkill then
        table.insert(second, Kit.Colored(("needs Fishing %d"):format(spot.needsSkill), Kit.GOLD))
    end
    if spot.getawaySkill then
        table.insert(
            second,
            Kit.Colored(("fish got away at %d"):format(spot.getawaySkill), Kit.GOLD)
        )
    end
    local line = table.concat(second, " · ")
    -- The line starts with a capital whichever part comes first.
    line = line:gsub("^(|c%x%x%x%x%x%x%x%x)(%l)", function(color, letter)
        return color .. letter:upper()
    end)
    return table.concat(first, " · "), line
end

-- A row --------------------------------------------------------------------------

local function CreateCatchIcon(row)
    local cell = CreateFrame("Frame", nil, row)
    cell:SetSize(CATCH_CELL, ROW_HEIGHT - 8)

    cell.slot = BookKit.Slot(cell, CATCH_ICON)
    cell.slot:SetPoint("TOP")
    cell.slot:SetScript("OnEnter", function(self)
        BookKit.ItemTooltip(self, self.itemID, "Click to see it in the collection.")
    end)
    cell.slot:SetScript("OnLeave", GameTooltip_Hide)
    cell.slot:SetScript("OnClick", function(self)
        ns.BookWindow.Open("collection", self.itemID)
    end)

    cell.share = Kit.Text(cell, "GameFontHighlightSmall", "CENTER")
    cell.share:SetPoint("TOP", cell.slot, "BOTTOM", 0, -3)
    cell.share:SetTextColor(Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])
    return cell
end

local function CreateRow()
    local row = CreateFrame("Frame", nil, tab.page)
    row:SetHeight(ROW_HEIGHT)
    Kit.DressRow(row)
    row:EnableMouse(true)

    row.name = Kit.Text(row, "GameFontHighlight")
    row.name:SetPoint("TOPLEFT", 8, -8)
    row.name:SetWidth(WORDS_WIDTH)

    row.figures = Kit.Text(row, "GameFontHighlightSmall")
    row.figures:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -5)
    row.figures:SetWidth(WORDS_WIDTH)
    row.figures:SetTextColor(Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])

    row.skill = Kit.Text(row, "GameFontHighlightSmall")
    row.skill:SetPoint("TOPLEFT", row.figures, "BOTTOMLEFT", 0, -3)
    row.skill:SetWidth(WORDS_WIDTH)
    row.skill:SetTextColor(Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])

    row.catches = {}
    for index = 1, CATCHES_SHOWN do
        local cell = CreateCatchIcon(row)
        cell:SetPoint("TOPLEFT", 8 + WORDS_WIDTH + 10 + (index - 1) * CATCH_CELL, -6)
        row.catches[index] = cell
    end

    row.map = Kit.Link(row, "Show on map", function()
        BookKit.ShowOnMap(row.spotID)
    end)
    row.map:SetPoint("RIGHT", -6, 0)

    return row
end

local function FillRow(row, spotID, spot)
    row.spotID = spotID
    row.name:SetText(ns.Spots.Name(spot))
    local figures, skill = SpotLines(spot)
    row.figures:SetText(figures)
    row.skill:SetText(skill)

    local top = BookKit.TopCatches(spot, CATCHES_SHOWN)
    for index, cell in ipairs(row.catches) do
        local entry = top[index]
        cell:SetShown(entry ~= nil)
        if entry then
            BookKit.FillSlot(cell.slot, entry.itemID, nil, true)
            cell.share:SetText(BookKit.ShareText(entry.share))
        end
    end

    row.map:SetShown(spot.mapX ~= nil and BookKit.MapKnown(spot.mapID))
    row.chosen:SetShown(spotID == tab.target)
end

-- The page -----------------------------------------------------------------------

--- The zones, each with its places, biggest first.
local function Gather(book)
    local zones, byName = {}, {}
    for spotID, spot in pairs(book.spots) do
        -- Water where something got away but nothing's been caught yet
        -- isn't a place to list.
        if (spot.caught or 0) > 0 then
            local name = (spot.zone and spot.zone ~= "") and spot.zone or "Unknown waters"
            local zone = byName[name]
            if not zone then
                zone = { name = name, spots = {}, caught = 0 }
                byName[name] = zone
                table.insert(zones, zone)
            end
            table.insert(zone.spots, { id = spotID, spot = spot })
            zone.caught = zone.caught + spot.caught
        end
    end
    table.sort(zones, function(a, b)
        return a.name < b.name
    end)
    for _, zone in ipairs(zones) do
        table.sort(zone.spots, function(a, b)
            if a.spot.caught ~= b.spot.caught then
                return a.spot.caught > b.spot.caught
            end
            return a.id < b.id
        end)
    end
    return zones
end

local function Refresh()
    local book = ns.ShownBook()
    local zones = Gather(book)

    tab.pins:SetChecked(ns.settings.mapPins)
    tab.empty:SetShown(#zones == 0)
    tab.scroll:SetShown(#zones > 0)

    local places = 0
    for _, zone in ipairs(zones) do
        places = places + #zone.spots
    end
    tab.summary:SetText(
        #zones > 0
                and ("%s in %s"):format(
                    BookKit.Plural(places, "place", "places"),
                    BookKit.Plural(#zones, "zone", "zones")
                )
            or ""
    )

    local width = tab.scroll:GetWidth()
    tab.page:SetWidth(width)
    tab.rowAt = {}
    local y = 0

    tab.headings:Reset()
    tab.rows:Reset()
    for zoneIndex, zone in ipairs(zones) do
        local heading = tab.headings:Next()
        heading:Set(
            zone.name,
            ("%s · %s"):format(
                BookKit.Plural(#zone.spots, "place", "places"),
                BookKit.Plural(zone.caught, "catch", "catches")
            )
        )
        heading:ClearAllPoints()
        heading:SetPoint("TOPLEFT", 0, -y)
        heading:SetWidth(width)
        y = y + heading:GetHeight() + HEADING_GAP

        for _, entry in ipairs(zone.spots) do
            local row = tab.rows:Next()
            FillRow(row, entry.id, entry.spot)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -y)
            row:SetWidth(width)
            tab.rowAt[entry.id] = y
            y = y + ROW_HEIGHT + ROW_GAP
        end
        if zoneIndex < #zones then
            y = y + ZONE_GAP
        end
    end
    tab.headings:HideRest()
    tab.rows:HideRest()
    tab.page:SetHeight(math.max(1, y))
end

--- Scrolls to a place and marks it.
local function Target(_, spotID)
    tab.target = spotID
    Refresh()
    local y = tab.rowAt[spotID]
    if y then
        BookKit.ScrollTo(tab.scroll, y)
    end
end

local function CreatePinsToggle()
    local check = CreateFrame("CheckButton", nil, tab, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check:SetPoint("TOPLEFT", MARGIN - 4, -MARGIN + 2)
    check.Text:SetFontObject("GameFontHighlight")
    check.Text:SetText("Show my spots on the world map")
    check.Text:SetPoint("LEFT", check, "RIGHT", 2, 1)

    check:SetScript("OnClick", function(self)
        ns.settings.mapPins = self:GetChecked() and true or false
        if ns.MapPins then
            ns.MapPins.Refresh()
        end
        ns.Send("SETTINGS_CHANGED")
    end)
    Kit.Tooltip(check, "Catch spots on the map", function()
        return {
            "Pins every place in this book on the world map, sized a little by how much "
                .. "you've caught there.",
            "Click a pin to open its place here.",
        }
    end)
    return check
end

---@param parent table  the window's inset, which the tab fills
function BookPlaces.Create(parent)
    tab = CreateFrame("Frame", nil, parent)
    tab:SetAllPoints()

    tab.pins = CreatePinsToggle()

    tab.summary = Kit.Text(tab, "GameFontDisableSmall", "RIGHT")
    tab.summary:SetPoint("RIGHT", -MARGIN, 0)
    tab.summary:SetPoint("TOP", tab.pins, "TOP", 0, -7)

    tab.scroll, tab.page = BookKit.ScrollArea(tab)
    tab.scroll:SetPoint("TOPLEFT", MARGIN, -(MARGIN + 32))
    tab.scroll:SetPoint("BOTTOMRIGHT", -BookKit.SCROLL_BAR_ROOM, MARGIN)

    tab.headings = BookKit.Pool(function()
        return BookKit.Heading(tab.page)
    end)
    tab.rows = BookKit.Pool(CreateRow)

    tab.empty = BookKit.Empty(
        tab,
        "No places yet. Every spot you fish lands here, with what it gave and how fast."
    )

    -- A marked place is for the visit that asked for it.
    tab:SetScript("OnHide", function()
        tab.target = nil
    end)

    tab.Refresh = Refresh
    tab.Target = Target
    return tab
end
