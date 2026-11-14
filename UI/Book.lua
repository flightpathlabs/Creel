local _, ns = ...

-- The Fishing Book: a window in the game's own style with five tabs along
-- the bottom, the way the game's journals have them.
--
--   Collection  everything that comes up on a line, caught ones in colour
--   Places      the spots fished, grouped by zone
--   Trips       past trips, newest first, and a few records
--   Earnings    what fishing has made, as far as the game lets us see
--   Next        the next rank and who teaches it, and what's worth doing
--
-- Each tab is built by its own file and knows how to redraw itself. This
-- file owns the frame and which tab is showing, and keeps the small pieces
-- the tabs share in ns.BookKit: item names and colours, the item slot,
-- dates, shares, a scrolling page.

local Kit = ns.Kit

local BookKit = {}
ns.BookKit = BookKit

local BookWindow = {}
ns.BookWindow = BookWindow

-- The window's size, and how far above the middle of the screen it opens.
local WIDTH = 700
local HEIGHT = 520
local RAISED = 20

-- The line under the title bar starts this far in, clear of the portrait,
-- and this far down.
local BLURB_LEFT = 66
local BLURB_TOP = 34

-- How far the tabs hang below the window's own edge.
local TABS_HANG = 30

-- Until the brand art arrives, the game's own fishing icon.
local PORTRAIT = "Interface\\Icons\\Trade_Fishing"

-- The window needs a name for Escape to close it, through UISpecialFrames.
local FRAME_NAME = "CreelBookFrame"

local TITLE = "Fishing Book"

-- Space round the edge of each tab's page, and what a scroll bar takes.
BookKit.MARGIN = 12
BookKit.SCROLL_BAR_ROOM = 24

-- Items -----------------------------------------------------------------------

-- Names and qualities come from the client's item cache, which fills as
-- items are asked for. Anything missing is asked for once, and the book is
-- redrawn when the answers arrive.
local asked = {}
local ScheduleRefresh

local function Ask(itemID)
    if not asked[itemID] then
        asked[itemID] = true
        C_Item.RequestLoadItemDataByID(itemID)
    end
end

-- RequestLoadItemDataByID answers with ITEM_DATA_LOAD_RESULT; an item the
-- client fetches for GetItemInfo answers with GET_ITEM_INFO_RECEIVED. Both
-- are heard, or names asked for the first way never arrive on the page.
local function OnItemLoaded(itemID, success)
    if asked[itemID] then
        -- An item the client says doesn't exist stays marked as asked, so
        -- a redraw doesn't ask again and again.
        if success then
            asked[itemID] = nil
        end
        ScheduleRefresh()
    end
end
ns.OnEvent("ITEM_DATA_LOAD_RESULT", OnItemLoaded)
ns.OnEvent("GET_ITEM_INFO_RECEIVED", OnItemLoaded)

---@return string|nil
function BookKit.Name(itemID)
    local name = C_Item.GetItemNameByID(itemID)
    if not name then
        Ask(itemID)
    end
    return name
end

--- An item's icon. This one never waits on the cache.
function BookKit.Icon(itemID)
    local _, _, _, _, icon = C_Item.GetItemInfoInstant(itemID)
    return icon
end

--- An item's quality colour, and the quality itself once it's known.
---@return number r, number g, number b, number|nil quality
function BookKit.QualityColor(itemID)
    local quality = C_Item.GetItemQualityByID(itemID)
    if not quality then
        Ask(itemID)
        return 1, 1, 1, nil
    end
    local r, g, b = C_Item.GetItemQualityColor(quality)
    return r, g, b, quality
end

--- The name in its quality colour, or a placeholder while it loads.
function BookKit.ColoredName(itemID)
    local name = BookKit.Name(itemID)
    if not name then
        return Kit.Colored("Loading", Kit.MUTED)
    end
    local r, g, b = BookKit.QualityColor(itemID)
    return Kit.Colored(name, { r, g, b })
end

--- What one is worth: at auction if anyone's seen it there, at a vendor
--- otherwise.
---@return number|nil copper
function BookKit.Worth(itemID)
    return ns.Values.Auction(itemID) or ns.Values.Vendor(itemID)
end

--- The game's flavour text for an item, quoted, for the few that have any.
--- Read from the client each time, never kept.
---@return string|nil
function BookKit.Flavour(itemID)
    local description = ns.Readable((select(18, C_Item.GetItemInfo(itemID))))
    if description and description ~= "" then
        return '"' .. description .. '"'
    end
    return nil
end

-- Words -----------------------------------------------------------------------

--- "1 in 4" for a share of 0.25. Past about two in three it's "most".
---@param share number|nil  0 to 1
function BookKit.ShareText(share)
    if not share or share <= 0 then
        return ""
    end
    local oneIn = math.floor(1 / share + 0.5)
    if oneIn <= 1 then
        return "most"
    end
    return ("1 in %d"):format(oneIn)
end

local function Day(at)
    return (date("%d", at):gsub("^0", ""))
end

--- "13 Nov 2026".
function BookKit.DateText(at)
    return ("%s %s"):format(Day(at), date("%b %Y", at))
end

--- "Fri 13 Nov, 19:40".
function BookKit.DayAndTime(at)
    return ("%s %s %s, %s"):format(date("%a", at), Day(at), date("%b", at), date("%H:%M", at))
end

--- How long ago something was: "20 minutes ago", "5 hours ago", "3 days ago".
function BookKit.Age(at)
    local seconds = math.max(0, time() - at)
    if seconds < 3600 then
        local minutes = math.max(1, math.floor(seconds / 60))
        return minutes == 1 and "a minute ago" or ("%d minutes ago"):format(minutes)
    elseif seconds < 2 * ns.SECONDS_PER_DAY then
        local hours = math.floor(seconds / 3600)
        return hours == 1 and "an hour ago" or ("%d hours ago"):format(hours)
    end
    return ("%d days ago"):format(math.floor(seconds / ns.SECONDS_PER_DAY))
end

--- The name part of a "Name - Realm" character key.
function BookKit.CharacterName(key)
    return key and key:match("^(.-) %- ") or key or ""
end

--- "1 catch", "44 catches".
function BookKit.Plural(count, one, many)
    return ("%s %s"):format(BreakUpLargeNumbers(count), count == 1 and one or many)
end

--- A count short enough for an icon's corner: 999, 1.2k, 15k.
function BookKit.ShortCount(count)
    if count >= 10000 then
        return ("%dk"):format(math.floor(count / 1000))
    elseif count >= 1000 then
        return ("%.1fk"):format(count / 1000)
    end
    return tostring(count)
end

-- Spots -----------------------------------------------------------------------

--- A spot's catches, most first: list of { itemID, count, share }.
---@param limit number|nil
function BookKit.TopCatches(spot, limit)
    local list = {}
    for itemID, count in pairs(spot.catches or {}) do
        table.insert(list, { itemID = itemID, count = count, share = ns.Spots.Share(spot, itemID) })
    end
    table.sort(list, function(a, b)
        if a.count ~= b.count then
            return a.count > b.count
        end
        return a.itemID < b.itemID
    end)
    if limit then
        for index = #list, limit + 1, -1 do
            list[index] = nil
        end
    end
    return list
end

--- Shows a spot on the world map, and puts the book away so the map can be
--- seen. In combat the map can't be opened, so the book goes to the place's
--- row instead.
function BookKit.ShowOnMap(spotID)
    if ns.MapPins and ns.MapPins.ShowSpot(spotID) then
        BookWindow.Close()
        return
    end
    -- The map can't be opened from here in combat; say so the game's way,
    -- and show the place in the book instead.
    if ns.InCombat() then
        UIErrorsFrame:AddExternalErrorMessage(ERR_NOT_IN_COMBAT)
    end
    BookWindow.Open("places", spotID)
end

-- Pictures --------------------------------------------------------------------

--- Points a texture at an atlas if the client has it. Returns false, and
--- leaves the texture alone, when it doesn't.
function BookKit.SetAtlasIfThere(texture, atlas)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
        texture:SetAtlas(atlas)
        return true
    end
    return false
end

-- The auction house's own item slot: an empty socket, the icon rounded off
-- by the game's icon mask, and a border in the item's quality colour.
local SLOT_BACK = "auctionhouse-itemicon-empty"
local ICON_MASK = "Interface\\Common\\common-iconmask"
local HIGHLIGHT = "Interface\\Buttons\\ButtonHilight-Square"
local BORDERS = {
    [Enum.ItemQuality.Poor] = "auctionhouse-itemicon-border-gray",
    [Enum.ItemQuality.Common] = "auctionhouse-itemicon-border-white",
    [Enum.ItemQuality.Uncommon] = "auctionhouse-itemicon-border-green",
    [Enum.ItemQuality.Rare] = "auctionhouse-itemicon-border-blue",
    [Enum.ItemQuality.Epic] = "auctionhouse-itemicon-border-purple",
    [Enum.ItemQuality.Legendary] = "auctionhouse-itemicon-border-orange",
}

-- How dark a silhouette is: the icon in grey, then most of the light taken
-- out, so the shape shows and nothing else.
local SILHOUETTE = 0.22

--- An item slot. Fill it with BookKit.FillSlot.
---@param size number  pixels across
function BookKit.Slot(parent, size)
    local slot = CreateFrame("Button", nil, parent)
    slot:SetSize(size, size)

    slot.back = slot:CreateTexture(nil, "BACKGROUND")
    slot.back:SetAtlas(SLOT_BACK)
    slot.back:SetAllPoints()

    local inset = math.max(1, math.floor(size / 24))
    slot.icon = slot:CreateTexture(nil, "BORDER")
    slot.icon:SetPoint("TOPLEFT", inset, -inset)
    slot.icon:SetPoint("BOTTOMRIGHT", -inset, inset)

    local mask = slot:CreateMaskTexture()
    mask:SetTexture(ICON_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(slot.icon)
    slot.icon:AddMaskTexture(mask)

    slot.border = slot:CreateTexture(nil, "OVERLAY")
    slot.border:SetAllPoints(slot.icon)

    slot.count = slot:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    slot.count:SetJustifyH("RIGHT")
    slot.count:SetPoint("BOTTOMRIGHT", -2, 2)

    slot.unknown = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    slot.unknown:SetPoint("CENTER", 1, 0)
    slot.unknown:SetText("?")
    slot.unknown:SetTextColor(Kit.GOLD[1], Kit.GOLD[2], Kit.GOLD[3], 0.75)

    local glow = slot:CreateTexture(nil, "HIGHLIGHT")
    glow:SetTexture(HIGHLIGHT)
    glow:SetBlendMode("ADD")
    glow:SetAllPoints(slot.icon)

    return slot
end

--- Shows an item in a slot: in colour with its quality border and a count
--- when it's been caught, as a dark silhouette with a question mark when
--- it hasn't.
---@param count number|nil  shown in the corner when given
---@param known boolean
function BookKit.FillSlot(slot, itemID, count, known)
    slot.itemID = itemID
    slot.icon:SetTexture(BookKit.Icon(itemID))

    if known then
        slot.icon:SetDesaturated(false)
        slot.icon:SetVertexColor(1, 1, 1)
        local _, _, _, quality = BookKit.QualityColor(itemID)
        slot.border:SetAtlas(BORDERS[quality] or BORDERS[Enum.ItemQuality.Common])
        slot.border:Show()
        slot.count:SetText(count and BookKit.ShortCount(count) or "")
        slot.unknown:Hide()
    else
        slot.icon:SetDesaturated(true)
        slot.icon:SetVertexColor(SILHOUETTE, SILHOUETTE, SILHOUETTE)
        slot.border:Hide()
        slot.count:SetText("")
        slot.unknown:Show()
    end
end

--- The item's own tooltip, for anything that shows an item.
function BookKit.ItemTooltip(owner, itemID, extra)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(itemID)
    if extra then
        GameTooltip:AddLine(extra, Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3], true)
    end
    GameTooltip:Show()
end

-- Page pieces -----------------------------------------------------------------

--- A scrolling area and the page inside it. Give the scroll frame a place;
--- set the page's width and height each time it's filled, since the scroll
--- range comes from the page's height.
---@return table scroll, table page
function BookKit.ScrollArea(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "ScrollFrameTemplate")
    scroll.ScrollBar:SetHideIfUnscrollable(true)

    local page = CreateFrame("Frame", nil, scroll)
    page:SetSize(1, 1)
    scroll:SetScrollChild(page)
    return scroll, page
end

--- Scrolls so that a point on the page, y pixels down it, is in view, a
--- little below the top.
function BookKit.ScrollTo(scroll, y)
    scroll:UpdateScrollChildRect()
    local range = scroll:GetVerticalScrollRange() or 0
    scroll:SetVerticalScroll(math.max(0, math.min(range, y - 8)))
end

--- A heading inside a page: the title in the game's gold, a short note
--- beside it in grey, and a hairline under both.
---@return table heading  call heading:Set(title, note)
function BookKit.Heading(parent)
    local heading = CreateFrame("Frame", nil, parent)
    heading:SetHeight(22)

    heading.title = Kit.Text(heading, "GameFontNormal")
    heading.title:SetPoint("BOTTOMLEFT", 0, 6)

    heading.note = Kit.Text(heading, "GameFontDisableSmall")
    heading.note:SetPoint("BOTTOMLEFT", heading.title, "BOTTOMRIGHT", 8, 0)

    local rule = Kit.Rule(heading)
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT")
    rule:SetPoint("BOTTOMRIGHT")

    function heading:Set(title, note)
        self.title:SetText(title)
        self.note:SetText(note or "")
    end
    return heading
end

--- Frames made as they're first needed and kept from one fill to the next.
---@param create fun(): table
function BookKit.Pool(create)
    local pool = { used = 0, items = {} }

    function pool:Reset()
        self.used = 0
    end

    function pool:Next()
        self.used = self.used + 1
        local item = self.items[self.used]
        if not item then
            item = create()
            self.items[self.used] = item
        end
        item:Show()
        return item
    end

    --- Puts away whatever this fill didn't use.
    function pool:HideRest()
        for index = self.used + 1, #self.items do
            self.items[index]:Hide()
        end
    end

    return pool
end

-- The fishing card from the game's professions book, as a picture for a
-- page with nothing on it yet. Its own size is about 225 by 275.
local CARD_ATLAS = "Profession-overview-card-generic-fishing"
local CARD_WIDTH = 150
local CARD_HEIGHT = 183

--- What a page shows before there's anything in it: the fishing card and
--- a sentence under it. Shown and hidden by the page.
function BookKit.Empty(parent, words)
    local empty = CreateFrame("Frame", nil, parent)
    empty:SetAllPoints()

    local card = empty:CreateTexture(nil, "ARTWORK")
    card:SetSize(CARD_WIDTH, CARD_HEIGHT)
    card:SetPoint("CENTER", 0, 40)
    if not BookKit.SetAtlasIfThere(card, CARD_ATLAS) then
        card:SetTexture(PORTRAIT)
        card:SetSize(64, 64)
    end

    local text = Kit.Paragraph(empty, "GameFontHighlight", "CENTER")
    text:SetWidth(380)
    text:SetPoint("TOP", card, "BOTTOM", 0, -14)
    text:SetTextColor(Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])
    text:SetText(words)

    empty:Hide()
    return empty
end

-- The window -----------------------------------------------------------------

--- A page that says one thing, standing in for a tab that couldn't be
--- built, so the rest of the window still opens.
local function PlaceHolder(parent, words)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    local text = Kit.Text(page, "GameFontHighlight", "CENTER")
    text:SetPoint("CENTER")
    text:SetText(words)
    function page.Refresh() end
    return page
end

-- The game only finds a file that's new to an addon when it starts.
local RESTART = "Quit the game and start it again to finish installing this page."

local TABS = {
    {
        key = "collection",
        label = "Collection",
        blurb = "Everything you've caught, and what's still out there.",
        module = "BookCollection",
    },
    {
        key = "places",
        label = "Places",
        blurb = "Where you've fished, with nearby catches grouped into one place.",
        module = "BookPlaces",
    },
    {
        key = "trips",
        label = "Trips",
        blurb = "Your fishing trips, newest first.",
        module = "BookTrips",
    },
    {
        key = "earnings",
        label = "Earnings",
        blurb = "What fishing has made you, as far as the game lets us see.",
        module = "BookEarnings",
    },
    {
        key = "next",
        label = "Next",
        blurb = "Where your fishing goes from here, and what's worth doing on the way.",
        module = "BookNext",
    },
}

local TAB_INDEX = {}
for index, tab in ipairs(TABS) do
    TAB_INDEX[tab.key] = index
end

local window
local currentTab = 1

local function UpdateTitle()
    if ns.Me().ownBook then
        window:SetTitle(("%s · %s"):format(TITLE, UnitName("player") or ""))
    else
        window:SetTitle(TITLE)
    end
end

--- Redraws the tab that's showing, if the window is open.
function BookWindow.Refresh()
    if window and window:IsShown() then
        UpdateTitle()
        window.pages[currentTab]:Refresh()
    end
end

-- Several things can change at once (a stack sold, a dozen names arriving
-- from the item cache), so redraws asked for together happen once.
local refreshPending = false
function ScheduleRefresh()
    if refreshPending or not (window and window:IsShown()) then
        return
    end
    refreshPending = true
    C_Timer.After(0.2, function()
        refreshPending = false
        BookWindow.Refresh()
    end)
end

local function ShowTab(index)
    currentTab = index
    PanelTemplates_SetTab(window, index)
    window.blurb:SetText(TABS[index].blurb)
    for place, page in ipairs(window.pages) do
        page:SetShown(place == index)
    end
    BookWindow.Refresh()
end

local function CreateTabs(frame)
    for index, definition in ipairs(TABS) do
        -- The template adds each tab to frame.Tabs.
        local tab = CreateFrame("Button", nil, frame, "PanelTabButtonTemplate")
        tab:SetID(index)
        tab:SetText(definition.label)
        PanelTemplates_TabResize(tab, 0)
        tab:SetScript("OnClick", function(self)
            ShowTab(self:GetID())
        end)

        -- Only the first needs placing. SetNumTabs chains the rest to it.
        if index == 1 then
            tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 11, 2)
        end
    end
    PanelTemplates_SetNumTabs(frame, #TABS)
end

--- Says what the book is when the mouse is on the portrait.
local function CreatePortraitTooltip(frame)
    local hover = CreateFrame("Frame", nil, frame)
    hover:SetAllPoints(frame:GetPortrait())
    hover:SetFrameLevel(frame.CloseButton:GetFrameLevel())

    -- Clicks go through, so the window can still be dragged by this corner.
    hover:SetMouseClickEnabled(false)
    hover:SetMouseMotionEnabled(true)

    hover:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.TITLE)
        if ns.Me().ownBook then
            GameTooltip:AddLine("This character keeps a book of its own.", 1, 1, 1, true)
        else
            GameTooltip:AddLine("One book for all your characters.", 1, 1, 1, true)
        end
        local version = C_AddOns.GetAddOnMetadata(ns.name, "Version")
        if version then
            GameTooltip:AddLine("Version " .. version, Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])
        end
        GameTooltip:Show()
    end)
    hover:SetScript("OnLeave", GameTooltip_Hide)
end

local function Create()
    local frame = CreateFrame("Frame", FRAME_NAME, UIParent, "ButtonFrameTemplate")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 0, RAISED)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:Hide()

    frame:SetPortraitToAsset(PORTRAIT)
    CreatePortraitTooltip(frame)

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    -- The tabs hang below the frame. Count them in, or the window can be
    -- dragged until they're off the screen.
    frame:SetClampRectInsets(0, 0, 0, -TABS_HANG)

    frame.blurb = Kit.Text(frame, "GameFontHighlight")
    frame.blurb:SetPoint("TOPLEFT", BLURB_LEFT, -BLURB_TOP)
    frame.blurb:SetPoint("RIGHT", -16, 0)

    table.insert(UISpecialFrames, FRAME_NAME)

    frame.pages = {}
    for index, definition in ipairs(TABS) do
        local module = ns[definition.module]
        local page
        if module then
            page = module.Create(frame.Inset, frame)
        else
            page = PlaceHolder(frame.Inset, RESTART)
        end
        page:Hide()
        frame.pages[index] = page
    end
    CreateTabs(frame)

    frame:SetScript("OnShow", function()
        ShowTab(currentTab)
    end)
    return frame
end

--- Opens the book, building it the first time.
---@param tab string|nil  "collection", "places", "trips", "earnings" or
---                       "next"; the tab it was last on when not given
---@param target any  what to show on that tab: an item ID on Collection,
---                   a spot ID on Places, a trip's startAt on Trips.
---                   Earnings and Next take none
---@return boolean opened  false before the saved data has loaded
function BookWindow.Open(tab, target)
    if not ns.db then
        return false
    end
    if not window then
        window = Create()
    end

    currentTab = TAB_INDEX[tab] or currentTab
    if window:IsShown() then
        ShowTab(currentTab)
    else
        window:Show()
    end

    local page = window.pages[currentTab]
    if target ~= nil and page.Target then
        page:Target(target)
    end
    return true
end

function BookWindow.Close()
    if window then
        window:Hide()
    end
end

--- Opens the book where it was left, or closes it.
function BookWindow.Toggle()
    if window and window:IsShown() then
        window:Hide()
    else
        BookWindow.Open()
    end
end

function BookWindow.IsShown()
    return window ~= nil and window:IsShown()
end

-- Whatever changes what's in the book redraws the tab that's showing.
for _, message in ipairs({ "CATCH", "TRIP_ENDED", "SALE", "BOOK_CHANGED", "SETTINGS_CHANGED" }) do
    ns.Listen(message, ScheduleRefresh)
end
