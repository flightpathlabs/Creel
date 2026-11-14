local _, ns = ...

-- What things are worth, and what fishing has earned.
--
-- The vendor price comes from the client. The auction price comes from
-- Goldwise when it's installed (it already weighs its own scans, other
-- players' prices, its price feed and Auctionator's), and from
-- Auctionator's public API otherwise. Creel never scans the auction house
-- itself.
--
-- Earnings are counted from two places the game lets us see: items sold
-- to a vendor while the merchant window is open, and "Auction successful"
-- mail when it's opened. Only catches and the things they turn into count.

local Values = {}
ns.Values = Values

local CALLER = "Creel"

--- What a vendor pays for one.
---@param itemID number
---@return number|nil copper
function Values.Vendor(itemID)
    local sellPrice = select(11, C_Item.GetItemInfo(itemID))
    return sellPrice
end

--- The best auction price we can find for one, and where it came from.
---@param itemID number
---@return number|nil copper
---@return string|nil source   "Goldwise" or "Auctionator"
---@return number|nil seenAt   when the price was seen, as time()
function Values.Auction(itemID)
    local api = _G.GoldwiseAPI
    if type(api) == "table" and type(api.Price) == "function" then
        local ok, price, seenAt = pcall(api.Price, itemID)
        if ok and price and price > 0 then
            return price, "Goldwise", seenAt
        end
    end

    local auctionator = _G.Auctionator
    local v1 = type(auctionator) == "table" and auctionator.API and auctionator.API.v1
    if v1 and v1.GetAuctionPriceByItemID then
        -- Auctionator raises an error for a caller it doesn't like rather
        -- than returning nothing, so it's asked at arm's length.
        local ok, price = pcall(v1.GetAuctionPriceByItemID, CALLER, itemID)
        if ok and price and price > 0 then
            local seenAt
            if v1.GetAuctionAgeByItemID then
                local okAge, days = pcall(v1.GetAuctionAgeByItemID, CALLER, itemID)
                if okAge and days then
                    seenAt = time() - days * ns.SECONDS_PER_DAY
                end
            end
            return price, "Auctionator", seenAt
        end
    end
    return nil
end

--- Both prices for one.
---@param itemID number
---@return number|nil vendor
---@return number|nil auction
function Values.Of(itemID)
    return Values.Vendor(itemID), (Values.Auction(itemID))
end

-- Earnings ----------------------------------------------------------------

-- Every item whose sales count: the catches, and what they turn into.
local counted

local function Counted()
    if counted then
        return counted
    end
    counted = {}
    for itemID in pairs(ns.Catches or {}) do
        counted[itemID] = true
    end
    for _, uses in pairs(ns.Uses or {}) do
        for _, use in ipairs(uses) do
            counted[use.makes] = true
        end
    end
    return counted
end

--- Whether sales of an item count toward fishing's earnings.
---@param itemID number
---@return boolean
function Values.Counts(itemID)
    return Counted()[itemID] == true
end

local function AddSale(kind, itemID, copper)
    if copper and copper > 0 then
        local sales = ns.Book().sales[kind]
        sales[itemID] = (sales[itemID] or 0) + copper
        ns.Send("SALE", kind, itemID, copper)
    end
end

-- Selling to a vendor is a right-click on the item with the merchant open,
-- which goes through UseContainerItem. The hook runs after the call, while
-- the item is still in the slot, since the sale itself is the server's.
local merchantOpen = false
ns.OnEvent("MERCHANT_SHOW", function()
    merchantOpen = true
end)
ns.OnEvent("MERCHANT_CLOSED", function()
    merchantOpen = false
end)

hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot)
    if not merchantOpen then
        return
    end
    local info = C_Container.GetContainerItemInfo(bag, slot)
    -- A locked item is one whose sale is already on its way; a second
    -- right-click on it mustn't count it again.
    if not info or info.isLocked then
        return
    end
    local itemID = ns.Readable(info.itemID)
    if itemID and Values.Counts(itemID) then
        local count = ns.Readable(info.stackCount) or 1
        AddSale("vendor", itemID, (Values.Vendor(itemID) or 0) * count)
    end
end)

-- Auction mail names the item but not its ID, so names are matched against
-- the counted items' names as the client knows them.
-- The second return is true when some names weren't loaded yet, so a
-- miss might only mean "not yet".
local function ItemByName(name)
    local unsure = false
    for itemID in pairs(Counted()) do
        local known = C_Item.GetItemNameByID(itemID)
        if known == name then
            return itemID
        elseif not known then
            unsure = true
            C_Item.RequestLoadItemDataByID(itemID)
        end
    end
    return nil, unsure
end

local function SeenMail()
    local book = ns.Book()
    book.sales.seenMail = book.sales.seenMail or {}
    return book.sales.seenMail
end

ns.OnEvent("MAIL_INBOX_UPDATE", function()
    local seen = SeenMail()
    local now = time()
    -- Two lots of the same thing sold for the same price in the same hour
    -- look alike, so each look-alike in this inbox gets its own number.
    local alike = {}
    for index = 1, GetInboxNumItems() do
        local invoiceType, itemName, _, bid, _, _, consignment = GetInboxInvoiceInfo(index)
        if invoiceType == "seller" and itemName and bid then
            -- A mail's expiry doesn't move while it sits in the box, so it
            -- and the sale's details name the mail well enough not to count
            -- it twice. The expiry is worked out from a fraction of a day
            -- left, so it can wobble across an hour's edge between visits;
            -- the neighbouring hours are checked too.
            local daysLeft = select(7, GetInboxHeaderInfo(index)) or 0
            local hour = math.floor((now + daysLeft * ns.SECONDS_PER_DAY) / 3600 + 0.5)
            local base = ("%s:%d"):format(itemName, bid)
            alike[base] = (alike[base] or 0) + 1
            local function Key(h)
                return ("%s:%d:%d"):format(base, h, alike[base])
            end
            local key = Key(hour)
            if not (seen[key] or seen[Key(hour - 1)] or seen[Key(hour + 1)]) then
                -- A name the client hasn't loaded yet can't be matched; the
                -- mail is left unseen so the next look at the inbox counts it.
                local itemID, unsure = ItemByName(itemName)
                if itemID then
                    seen[key] = now
                    AddSale("auction", itemID, bid - (consignment or 0))
                elseif not unsure then
                    seen[key] = now
                end
            end
        end
    end

    -- Mail lasts 30 days, so older keys can go.
    for key, at in pairs(seen) do
        if now - at > 31 * ns.SECONDS_PER_DAY then
            seen[key] = nil
        end
    end
end)

--- Totals of what's been earned, by kind.
---@return number vendor
---@return number auction
function Values.Earned()
    local sales = ns.Book().sales
    local vendor, auction = 0, 0
    for _, copper in pairs(sales.vendor) do
        vendor = vendor + copper
    end
    for _, copper in pairs(sales.auction) do
        auction = auction + copper
    end
    return vendor, auction
end
