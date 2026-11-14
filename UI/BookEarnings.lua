local _, ns = ...

-- The Earnings tab: what fishing has made, as far as the game lets us see.
--
-- Sales to a vendor are counted as they happen, while the merchant is
-- open, and auction sales from the "Auction successful" mail when it's
-- opened (Fishing/Values.lua). Dishes and potions made from catches are
-- counted the same way, with a note: a dish made from your own fish and
-- one bought from someone else look the same to the game. Then what's
-- still in the bags, at today's prices, and every item by what it's made.

local Kit = ns.Kit
local BookKit = ns.BookKit

local BookEarnings = {}
ns.BookEarnings = BookEarnings

local MARGIN = BookKit.MARGIN
local LINE_GAP = 10
local NOTE_GAP = 3
local BAR_GAP = 4

-- The bags: the backpack and the bags beside it.
local FIRST_BAG = BACKPACK_CONTAINER or 0
local LAST_BAG = NUM_BAG_SLOTS or 4

-- How many items a tooltip lists before it stops.
local TOOLTIP_ITEMS = 10

local tab

--- Whether an item came off a line, rather than out of a recipe.
local function IsCatch(book, itemID)
    return (ns.Catches and ns.Catches[itemID]) ~= nil or book.fish[itemID] ~= nil
end

--- What's in the bags that counts toward fishing's earnings, and what it
--- would fetch today.
---@return table items  item ID -> count
---@return number worth  copper
local function InBags()
    local items = {}
    for bag = FIRST_BAG, LAST_BAG do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            local itemID = info and ns.Readable(info.itemID)
            if itemID and ns.Values.Counts(itemID) then
                local count = ns.Readable(info.stackCount) or 1
                items[itemID] = (items[itemID] or 0) + count
            end
        end
    end
    local worth = 0
    for itemID, count in pairs(items) do
        worth = worth + (BookKit.Worth(itemID) or 0) * count
    end
    return items, worth
end

--- The money made from each item, both ways.
local function ByItem(book)
    local byItem = {}
    local function Add(kind, sales)
        for itemID, copper in pairs(sales) do
            local entry = byItem[itemID]
            if not entry then
                entry = { itemID = itemID, vendor = 0, auction = 0, total = 0 }
                byItem[itemID] = entry
            end
            entry[kind] = entry[kind] + copper
            entry.total = entry.total + copper
        end
    end
    Add("vendor", book.sales.vendor)
    Add("auction", book.sales.auction)

    local list = {}
    for _, entry in pairs(byItem) do
        if entry.total > 0 then
            table.insert(list, entry)
        end
    end
    table.sort(list, function(a, b)
        if a.total ~= b.total then
            return a.total > b.total
        end
        return a.itemID < b.itemID
    end)
    return list
end

-- The table ---------------------------------------------------------------------

--- One line of the table: what it is, the money, and how we know in small
--- print under it.
local function CreateLine(section)
    local line = CreateFrame("Frame", nil, section)
    line:EnableMouse(true)

    line.value = Kit.Text(line, "GameFontHighlight", "RIGHT")
    line.value:SetPoint("TOPRIGHT")

    line.label = Kit.Text(line, "GameFontHighlight")
    line.label:SetPoint("TOPLEFT")
    line.label:SetPoint("RIGHT", line.value, "LEFT", -12, 0)

    line.note = Kit.Paragraph(line, "GameFontHighlightSmall")
    line.note:SetPoint("TOPLEFT", line.label, "BOTTOMLEFT", 0, -NOTE_GAP)
    line.note:SetTextColor(Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])

    line:SetScript("OnEnter", function(self)
        if not self.items or #self.items == 0 then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.label:GetText())
        for index, entry in ipairs(self.items) do
            if index > TOOLTIP_ITEMS then
                GameTooltip:AddLine(
                    ("and %d more"):format(#self.items - TOOLTIP_ITEMS),
                    Kit.MUTED[1],
                    Kit.MUTED[2],
                    Kit.MUTED[3]
                )
                break
            end
            local name = BookKit.ColoredName(entry.itemID)
            if entry.count then
                name = ("%s × %d"):format(name, entry.count)
            end
            GameTooltip:AddDoubleLine(name, ns.Money(entry.copper), 1, 1, 1, 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    line:SetScript("OnLeave", GameTooltip_Hide)
    return line
end

local function PlaceLine(inside, line, gap, label, value, note, items)
    line.label:SetText(label)
    line.value:SetText(value)
    line.items = items
    line:SetWidth(inside.width)
    line.note:SetWidth(inside.width)
    line.note:SetText(note or "")
    local height = line.label:GetStringHeight()
    if note then
        height = height + NOTE_GAP + line.note:GetStringHeight()
    end
    line:SetHeight(height)
    Kit.Place(inside, line, gap)
end

-- The page -----------------------------------------------------------------------

local function CreateBar()
    local bar = Kit.Bar(tab.byItem)
    bar:EnableMouse(true)
    bar:SetScript("OnEnter", function(self)
        local entry = self.entry
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(BookKit.ColoredName(entry.itemID))
        if entry.vendor > 0 then
            Kit.TooltipFigure("Sold to vendors", ns.Money(entry.vendor))
        end
        if entry.auction > 0 then
            Kit.TooltipFigure("Sold at auction", ns.Money(entry.auction))
        end
        GameTooltip:Show()
    end)
    bar:SetScript("OnLeave", GameTooltip_Hide)
    return bar
end

local function Refresh()
    local book = ns.Book()
    local list = ByItem(book)

    -- The table's four lines, split between catches and what they make.
    local fishVendor, fishAuction, made = 0, 0, 0
    local fishVendorItems, fishAuctionItems, madeItems = {}, {}, {}
    for _, entry in ipairs(list) do
        if IsCatch(book, entry.itemID) then
            fishVendor = fishVendor + entry.vendor
            fishAuction = fishAuction + entry.auction
            if entry.vendor > 0 then
                table.insert(fishVendorItems, { itemID = entry.itemID, copper = entry.vendor })
            end
            if entry.auction > 0 then
                table.insert(fishAuctionItems, { itemID = entry.itemID, copper = entry.auction })
            end
        else
            made = made + entry.total
            table.insert(madeItems, { itemID = entry.itemID, copper = entry.total })
        end
    end
    local function ByCopper(a, b)
        return a.copper > b.copper
    end
    table.sort(fishVendorItems, ByCopper)
    table.sort(fishAuctionItems, ByCopper)

    local bagItems, bagWorth = InBags()
    local bagList = {}
    for itemID, count in pairs(bagItems) do
        table.insert(bagList, {
            itemID = itemID,
            count = count,
            copper = (BookKit.Worth(itemID) or 0) * count,
        })
    end
    table.sort(bagList, ByCopper)

    local width = tab.scroll:GetWidth()
    tab.page:SetWidth(width)
    local layout = { frame = tab.page, left = 0, width = width, y = 0 }

    local inside = Kit.Inside(layout, tab.made)
    PlaceLine(
        inside,
        tab.lines[1],
        0,
        "Catches sold to vendors",
        ns.Money(fishVendor),
        "Counted as you sell, while the merchant's window is open. Buying something back, and"
            .. " the merchant's sell-junk button, aren't seen.",
        fishVendorItems
    )
    PlaceLine(
        inside,
        tab.lines[2],
        LINE_GAP,
        "Catches sold at auction",
        ns.Money(fishAuction),
        'From the "Auction successful" mail, once it\'s opened. Exact for the mail seen.',
        fishAuctionItems
    )
    PlaceLine(
        inside,
        tab.lines[3],
        LINE_GAP,
        "Dishes and potions made from them",
        ns.Money(made),
        "Includes all sales of these, since there's no telling a dish made from your fish "
            .. "from one you bought.",
        madeItems
    )
    PlaceLine(
        inside,
        tab.lines[4],
        LINE_GAP,
        "Still in your bags",
        ns.Money(bagWorth),
        "What they'd fetch at today's prices: at auction where there's a price, otherwise "
            .. "at a vendor.",
        bagList
    )

    -- The total, under a hairline.
    inside.y = inside.y + LINE_GAP
    tab.totalRule:ClearAllPoints()
    tab.totalRule:SetPoint("TOPLEFT", inside.left, -inside.y)
    tab.totalRule:SetWidth(inside.width)
    PlaceLine(
        inside,
        tab.lines[5],
        LINE_GAP,
        Kit.Colored("Made so far", Kit.GOLD),
        ns.Money(fishVendor + fishAuction + made),
        nil,
        nil
    )
    Kit.PlaceSection(layout, tab.made, inside)

    -- Every item by the money it's made.
    tab.byItem:SetShown(#list > 0)
    if #list > 0 then
        inside = Kit.Inside(layout, tab.byItem)
        tab.bars:Reset()
        local top = list[1].total
        for index, entry in ipairs(list) do
            local bar = tab.bars:Next()
            bar.entry = entry
            local r, g, b = BookKit.QualityColor(entry.itemID)
            bar:Set(
                BookKit.Icon(entry.itemID),
                BookKit.Name(entry.itemID) or "",
                ns.Money(entry.total),
                entry.total / top,
                { r, g, b }
            )
            Kit.Place(inside, bar, index == 1 and 0 or BAR_GAP)
        end
        tab.bars:HideRest()
        Kit.PlaceSection(layout, tab.byItem, inside)
    else
        local quiet = Kit.Inside(layout, tab.nothing)
        Kit.PlaceText(
            quiet,
            tab.nothing.text,
            0,
            'Nothing sold yet. Sell a catch to a vendor, or open an "Auction successful" mail, '
                .. "and it shows up here."
        )
        Kit.PlaceSection(layout, tab.nothing, quiet)
    end
    tab.nothing:SetShown(#list == 0)

    tab.page:SetHeight(layout.y + Kit.SECTION_GAP)
end

---@param parent table  the window's inset, which the tab fills
function BookEarnings.Create(parent)
    tab = CreateFrame("Frame", nil, parent)
    tab:SetAllPoints()

    tab.scroll, tab.page = BookKit.ScrollArea(tab)
    tab.scroll:SetPoint("TOPLEFT", MARGIN, -MARGIN)
    tab.scroll:SetPoint("BOTTOMRIGHT", -BookKit.SCROLL_BAR_ROOM, MARGIN)

    tab.made = Kit.Section(tab.page, "What fishing has made you")
    tab.lines = {}
    for index = 1, 5 do
        tab.lines[index] = CreateLine(tab.made)
    end
    tab.totalRule = Kit.Rule(tab.made)
    tab.totalRule:SetHeight(1)

    tab.byItem = Kit.Section(tab.page, "By item")
    tab.bars = BookKit.Pool(CreateBar)

    tab.nothing = Kit.Section(tab.page, "By item")
    tab.nothing.text = Kit.Paragraph(tab.nothing, "GameFontHighlight")
    tab.nothing.text:SetTextColor(Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])

    tab.Refresh = Refresh
    return tab
end

-- The bags change as catches come in and things are sold, made or used.
ns.OnEvent("BAG_UPDATE_DELAYED", function()
    if tab and tab:IsVisible() then
        Refresh()
    end
end)
