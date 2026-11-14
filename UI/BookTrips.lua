local _, ns = ...

-- The Trips tab: lifetime totals across the top, a short row of records
-- under them, then every trip the book keeps, newest first, with the one
-- picked shown in full beside the list: what it caught, how much of each,
-- and its share of the trip.

local Kit = ns.Kit
local BookKit = ns.BookKit

local BookTrips = {}
ns.BookTrips = BookTrips

local MARGIN = BookKit.MARGIN
local GAP = 10

local RECORD_HEIGHT = 44
local RECORD_ICON = 28
local LIST_WIDTH = 380
local ROW_HEIGHT = 42
local MENU_WIDTH = 150
local DETAIL_PADDING = 12
local BAR_GAP = 4

local PORTRAIT = "Interface\\Icons\\Trade_Fishing"

local tab

-- Which character's trips are listed: nil for all of them.
local filter

-- The trip shown in full, by when it started.
local chosen

-- Trips ------------------------------------------------------------------------

local function FindTrip(startAt)
    for _, trip in ipairs(ns.Book().trips) do
        if trip.startAt == startAt then
            return trip
        end
    end
    return nil
end

local function TopCatch(trip)
    local bestID, best = nil, 0
    for itemID, count in pairs(trip.catches or {}) do
        if count > best or (count == best and bestID and itemID < bestID) then
            bestID, best = itemID, count
        end
    end
    return bestID
end

--- "Lake Everstill and The Loch", or "Lake Everstill and 3 more".
local function Places(trip)
    local spots = ns.Book().spots
    local names, seen = {}, {}
    for _, spotID in ipairs(trip.spots or {}) do
        local spot = spots[spotID]
        local name = spot and ns.Spots.Name(spot)
        if name and not seen[name] then
            seen[name] = true
            table.insert(names, name)
        end
    end
    if #names == 0 then
        return "Somewhere"
    elseif #names == 1 then
        return names[1]
    elseif #names == 2 then
        return names[1] .. " and " .. names[2]
    end
    return ("%s and %d more"):format(names[1], #names - 1)
end

local function SkillText(trip)
    if trip.skillFrom and trip.skillTo and trip.skillTo > trip.skillFrom then
        return ("skill %d → %d"):format(trip.skillFrom, trip.skillTo)
    elseif trip.skillTo or trip.skillFrom then
        return ("skill %d"):format(trip.skillTo or trip.skillFrom)
    end
    return nil
end

--- The small print under a trip: length, catches, worth, skill.
local function TripFigures(trip)
    local parts = {
        ns.Hours(trip.seconds or 0),
        BookKit.Plural(trip.caught or 0, "catch", "catches"),
    }
    if (trip.auction or 0) > 0 then
        table.insert(parts, ns.Money(trip.auction))
    end
    table.insert(parts, SkillText(trip))
    return table.concat(parts, " · ")
end

local function Characters(trips)
    local list, seen = {}, {}
    for _, trip in ipairs(trips) do
        if trip.character and not seen[trip.character] then
            seen[trip.character] = true
            table.insert(list, trip.character)
        end
    end
    table.sort(list)
    return list
end

-- The records -------------------------------------------------------------------

-- In the order they're shown. Each says what its figure is and how to
-- write it, and which icon stands for it: the trip's own biggest catch,
-- unless there's something better.
local RECORDS = {
    {
        key = "worth",
        label = "Best trip",
        Text = function(record)
            return ns.Money(record.value)
        end,
    },
    {
        key = "catches",
        label = "Most catches",
        Text = function(record)
            return BreakUpLargeNumbers(record.value)
        end,
    },
    {
        key = "perHour",
        label = "Fastest",
        Text = function(record)
            return ("%d an hour"):format(record.value)
        end,
    },
    {
        key = "seconds",
        label = "Longest trip",
        Text = function(record)
            return ns.Hours(record.value)
        end,
        icon = "clock",
    },
    {
        key = "rarest",
        label = "Rarest catch",
        Text = function(record)
            return BookKit.ShareText(record.share)
        end,
    },
}

local function CreateRecord(strip)
    local button = CreateFrame("Button", nil, strip)
    button:SetHeight(RECORD_HEIGHT)

    local box = Kit.Box(button)
    box:SetAllPoints()
    Kit.DressRow(button)

    button.icon = Kit.Icon(button, RECORD_ICON)
    button.icon:SetPoint("LEFT", 8, 0)

    button.label = Kit.Text(button, "GameFontDisableSmall")
    button.label:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 8, 0)
    button.label:SetPoint("RIGHT", -6, 0)

    button.value = Kit.Text(button, "GameFontHighlight")
    button.value:SetPoint("BOTTOMLEFT", button.icon, "BOTTOMRIGHT", 8, 0)
    button.value:SetPoint("RIGHT", -6, 0)

    button:SetScript("OnClick", function(self)
        if self.trip then
            BookTrips.Choose(self.trip.startAt)
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.definition.label)
        local record = self.record
        if record.itemID then
            GameTooltip:AddLine(BookKit.ColoredName(record.itemID), 1, 1, 1)
            local spot = record.spotID and ns.Book().spots[record.spotID]
            if spot then
                GameTooltip:AddLine(
                    ("%s of the catches at %s"):format(
                        BookKit.ShareText(record.share),
                        ns.Spots.Name(spot)
                    ),
                    1,
                    1,
                    1,
                    true
                )
            end
        end
        if self.trip then
            GameTooltip:AddLine(BookKit.DayAndTime(self.trip.startAt), 1, 1, 1)
            GameTooltip:AddLine("Click to see the trip.", Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])
        elseif record.tripStartAt then
            GameTooltip:AddLine(
                "That trip is older than the ones the book keeps in full.",
                Kit.MUTED[1],
                Kit.MUTED[2],
                Kit.MUTED[3],
                true
            )
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

local function FillRecords(book, width)
    local shown = {}
    for _, definition in ipairs(RECORDS) do
        local record = book.records[definition.key]
        if record then
            table.insert(shown, { definition = definition, record = record })
        end
    end

    tab.records:SetShown(#shown > 0)
    if #shown == 0 then
        tab.records:SetHeight(1)
        return
    end
    tab.records:SetHeight(RECORD_HEIGHT)

    local each = (width - GAP * (#shown - 1)) / #shown
    for index, button in ipairs(tab.recordButtons) do
        local entry = shown[index]
        button:SetShown(entry ~= nil)
        if entry then
            local record = entry.record
            button.definition = entry.definition
            button.record = record
            button.trip = record.tripStartAt and FindTrip(record.tripStartAt) or nil
            button.label:SetText(entry.definition.label)
            button.value:SetText(entry.definition.Text(record))

            local itemID = record.itemID or (button.trip and TopCatch(button.trip))
            if entry.definition.icon then
                Kit.SetIcon(button.icon, entry.definition.icon)
            elseif itemID then
                Kit.SetSpellIcon(button.icon, BookKit.Icon(itemID))
            else
                Kit.SetSpellIcon(button.icon, PORTRAIT)
            end

            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", (index - 1) * (each + GAP), 0)
            button:SetWidth(each)
        end
    end
end

-- The list ------------------------------------------------------------------------

local function CreateRow()
    local row = CreateFrame("Button", nil, tab.listPage)
    row:SetHeight(ROW_HEIGHT)
    Kit.DressRow(row)

    row.title = Kit.Text(row, "GameFontHighlight")
    row.title:SetPoint("TOPLEFT", 8, -6)
    row.title:SetPoint("RIGHT", -8, 0)

    row.figures = Kit.Text(row, "GameFontHighlightSmall")
    row.figures:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -4)
    row.figures:SetPoint("RIGHT", -8, 0)
    row.figures:SetTextColor(Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])

    row:SetScript("OnClick", function(self)
        BookTrips.Choose(self.trip.startAt)
    end)
    return row
end

local function FillRow(row, trip, showCharacter)
    row.trip = trip
    local title = ("%s · %s"):format(BookKit.DayAndTime(trip.startAt), Places(trip))
    row.title:SetText(title)
    local figures = TripFigures(trip)
    if showCharacter then
        figures = BookKit.CharacterName(trip.character) .. " · " .. figures
    end
    row.figures:SetText(figures)
    row.chosen:SetShown(trip.startAt == chosen)
end

-- The trip in full ----------------------------------------------------------------

local function CreateBar()
    local bar = Kit.Bar(tab.detailPage)
    bar:EnableMouse(true)
    bar:SetScript("OnEnter", function(self)
        BookKit.ItemTooltip(self, self.itemID, "Click to see it in the collection.")
    end)
    bar:SetScript("OnLeave", GameTooltip_Hide)
    bar:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self:IsMouseOver() then
            ns.BookWindow.Open("collection", self.itemID)
        end
    end)
    return bar
end

local function FillDetail(trip)
    local detail = tab.detail
    detail.empty:SetShown(trip == nil)
    detail.scroll:SetShown(trip ~= nil)
    if not trip then
        return
    end

    local page = tab.detailPage
    local width = detail.scroll:GetWidth()
    page:SetWidth(width)

    local going = ns.State.trip == trip
    detail.title:SetWidth(width)
    detail.title:SetText(
        BookKit.DayAndTime(trip.startAt)
            .. (going and Kit.Colored(" · still going", Kit.GOOD) or "")
    )

    local where = Places(trip)
    if trip.character then
        where = BookKit.CharacterName(trip.character) .. " at " .. where
    end
    detail.where:SetWidth(width)
    detail.where:SetText(where)

    local parts =
        { ns.Hours(trip.seconds or 0), BookKit.Plural(trip.caught or 0, "catch", "catches") }
    if (trip.seconds or 0) >= 600 then
        table.insert(
            parts,
            ("%d an hour"):format(math.floor((trip.caught or 0) * 3600 / trip.seconds))
        )
    end
    table.insert(parts, SkillText(trip))
    detail.figures:SetWidth(width)
    detail.figures:SetText(table.concat(parts, " · "))

    detail.worth:SetWidth(width)
    -- The auction figure only counts catches that had a price, so it's
    -- left out when there's none rather than shown as nothing.
    local worth = {}
    if (trip.vendor or 0) > 0 then
        table.insert(worth, ("%s at a vendor"):format(ns.Money(trip.vendor)))
    end
    if (trip.auction or 0) > 0 then
        table.insert(worth, ("about %s at auction"):format(ns.Money(trip.auction)))
    end
    detail.worth:SetText(#worth > 0 and ("Worth " .. table.concat(worth, ", ")) or "")

    local y = detail.title:GetStringHeight()
        + detail.where:GetStringHeight()
        + detail.figures:GetStringHeight()
        + detail.worth:GetStringHeight()
        + 24

    local list = {}
    for itemID, count in pairs(trip.catches or {}) do
        table.insert(list, { itemID = itemID, count = count })
    end
    table.sort(list, function(a, b)
        if a.count ~= b.count then
            return a.count > b.count
        end
        return a.itemID < b.itemID
    end)

    tab.bars:Reset()
    local caught = math.max(1, trip.caught or 0)
    for _, entry in ipairs(list) do
        local bar = tab.bars:Next()
        bar.itemID = entry.itemID
        local r, g, b = BookKit.QualityColor(entry.itemID)
        local share = entry.count / caught
        bar:Set(
            BookKit.Icon(entry.itemID),
            BookKit.Name(entry.itemID) or "",
            ("%d · %d%%"):format(entry.count, math.floor(share * 100 + 0.5)),
            share,
            { r, g, b }
        )
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", 0, -y)
        bar:SetWidth(width)
        y = y + bar:GetHeight() + BAR_GAP
    end
    tab.bars:HideRest()
    page:SetHeight(math.max(1, y))
end

local function CreateDetail()
    local detail = Kit.Box(tab)
    detail:SetPoint("TOPLEFT", tab.listHeading, "TOPRIGHT", BookKit.SCROLL_BAR_ROOM + GAP, 0)
    detail:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN)

    detail.scroll, tab.detailPage = BookKit.ScrollArea(detail)
    detail.scroll:SetPoint("TOPLEFT", DETAIL_PADDING, -DETAIL_PADDING)
    detail.scroll:SetPoint("BOTTOMRIGHT", -BookKit.SCROLL_BAR_ROOM, DETAIL_PADDING)

    local page = tab.detailPage
    detail.title = Kit.Paragraph(page, "GameFontNormalLarge")
    detail.title:SetPoint("TOPLEFT")
    detail.where = Kit.Paragraph(page, "GameFontHighlight")
    detail.where:SetPoint("TOPLEFT", detail.title, "BOTTOMLEFT", 0, -6)
    detail.figures = Kit.Paragraph(page, "GameFontHighlightSmall")
    detail.figures:SetPoint("TOPLEFT", detail.where, "BOTTOMLEFT", 0, -6)
    detail.figures:SetTextColor(Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])
    detail.worth = Kit.Paragraph(page, "GameFontHighlightSmall")
    detail.worth:SetPoint("TOPLEFT", detail.figures, "BOTTOMLEFT", 0, -3)
    detail.worth:SetTextColor(Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])

    detail.empty = Kit.Paragraph(detail, "GameFontHighlight", "CENTER")
    detail.empty:SetPoint("LEFT", DETAIL_PADDING, 0)
    detail.empty:SetPoint("RIGHT", -DETAIL_PADDING, 0)
    detail.empty:SetTextColor(Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])
    detail.empty:SetText("Pick a trip to see everything it caught.")

    return detail
end

-- The page ------------------------------------------------------------------------

local function FillStats(book)
    local vendor, auction = 0, 0
    for _, trip in ipairs(book.trips) do
        vendor = vendor + (trip.vendor or 0)
        auction = auction + (trip.auction or 0)
    end
    local totals = book.totals
    tab.stats:Fill({
        {
            label = "Trips",
            value = BreakUpLargeNumbers(totals.trips or #book.trips),
            figures = {},
        },
        {
            label = "Time fishing",
            value = ns.Hours(totals.seconds or 0),
            figures = {},
            note = "Counted between casts, so a walk to the vendor or a fight isn't fishing time.",
        },
        {
            label = "Catches",
            value = BreakUpLargeNumbers(totals.catches or 0),
            figures = {},
        },
        {
            label = "Worth",
            value = ns.Money(auction),
            title = "What the trips' catches were worth",
            figures = { { "At a vendor", ns.Money(vendor) }, { "At auction", ns.Money(auction) } },
            note = ("Added up over the trips the book keeps in full, the last %d."):format(
                ns.MAX_TRIPS
            ),
        },
    }, tab:GetWidth() - 2 * MARGIN, false)
end

local function Refresh()
    local book = ns.Book()
    FillStats(book)
    FillRecords(book, tab:GetWidth() - 2 * MARGIN)

    local characters = Characters(book.trips)
    local several = #characters > 1
    if not several then
        filter = nil
    end
    tab.menu:SetShown(several)
    if several then
        tab.menu:GenerateMenu()
    end

    local trips = {}
    for _, trip in ipairs(book.trips) do
        if not filter or trip.character == filter then
            table.insert(trips, trip)
        end
    end

    tab.empty:SetShown(#book.trips == 0)
    tab.listHeading:SetShown(#book.trips > 0)
    tab.listScroll:SetShown(#book.trips > 0)
    tab.detail:SetShown(#book.trips > 0)
    tab.listHeading:Set("Trips", BookKit.Plural(#trips, "trip", "trips"))

    -- The newest trip is shown in full until another is picked.
    if not chosen or not FindTrip(chosen) then
        chosen = trips[1] and trips[1].startAt or nil
    end

    local width = tab.listScroll:GetWidth()
    tab.listPage:SetWidth(width)
    tab.rowAt = {}
    tab.rows:Reset()
    local y = 0
    for _, trip in ipairs(trips) do
        local row = tab.rows:Next()
        FillRow(row, trip, several and not filter)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetWidth(width)
        tab.rowAt[trip.startAt] = y
        y = y + ROW_HEIGHT + 2
    end
    tab.rows:HideRest()
    tab.listPage:SetHeight(math.max(1, y))

    FillDetail(chosen and FindTrip(chosen))
end

--- Shows a trip in full and scrolls the list to it. A trip hidden by the
--- character menu brings every character back into the list.
---@param startAt number
function BookTrips.Choose(startAt)
    local trip = FindTrip(startAt)
    if not trip then
        return
    end
    if filter and trip.character ~= filter then
        filter = nil
    end
    chosen = startAt
    Refresh()
    local y = tab.rowAt[startAt]
    if y then
        BookKit.ScrollTo(tab.listScroll, y)
    end
end

local function CreateMenu()
    local menu = CreateFrame("DropdownButton", nil, tab, "WowStyle1DropdownTemplate")
    menu:SetWidth(MENU_WIDTH)
    menu:SetPoint("BOTTOMRIGHT", tab.listHeading, "BOTTOMRIGHT", 0, 3)
    menu:SetupMenu(function(_, root)
        local function IsChosen(key)
            return (key or false) == (filter or false)
        end
        local function Choose(key)
            filter = key or nil
            Refresh()
        end
        root:CreateRadio("All characters", IsChosen, Choose, false)
        for _, key in ipairs(Characters(ns.Book().trips)) do
            root:CreateRadio(BookKit.CharacterName(key), IsChosen, Choose, key)
        end
    end)
    return menu
end

---@param parent table  the window's inset, which the tab fills
function BookTrips.Create(parent)
    tab = CreateFrame("Frame", nil, parent)
    tab:SetAllPoints()

    tab.stats = Kit.StatRow(tab)
    tab.stats:SetPoint("TOPLEFT", MARGIN, -MARGIN)
    tab.stats:SetPoint("RIGHT", -MARGIN, 0)

    tab.records = CreateFrame("Frame", nil, tab)
    tab.records:SetPoint("TOPLEFT", tab.stats, "BOTTOMLEFT", 0, -GAP)
    tab.records:SetPoint("RIGHT", -MARGIN, 0)
    tab.records:SetHeight(RECORD_HEIGHT)
    tab.recordButtons = {}
    for index = 1, #RECORDS do
        tab.recordButtons[index] = CreateRecord(tab.records)
    end

    tab.listHeading = BookKit.Heading(tab)
    tab.listHeading:SetPoint("TOPLEFT", tab.records, "BOTTOMLEFT", 0, -GAP)
    tab.listHeading:SetWidth(LIST_WIDTH)

    tab.listScroll, tab.listPage = BookKit.ScrollArea(tab)
    tab.listScroll:SetPoint("TOPLEFT", tab.listHeading, "BOTTOMLEFT", 0, -6)
    tab.listScroll:SetPoint("BOTTOMRIGHT", tab, "BOTTOMLEFT", MARGIN + LIST_WIDTH, MARGIN)

    tab.rows = BookKit.Pool(CreateRow)
    tab.detail = CreateDetail()
    tab.bars = BookKit.Pool(CreateBar)
    tab.menu = CreateMenu()

    tab.empty = BookKit.Empty(
        tab,
        "No trips yet. A trip starts with your first cast and ends when you put the pole away."
    )

    tab.Refresh = Refresh
    tab.Target = function(_, startAt)
        BookTrips.Choose(startAt)
    end
    return tab
end
