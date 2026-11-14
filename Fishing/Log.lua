local _, ns = ...

-- Counting catches.
--
-- Only loot the game marks as fishing loot counts, so mob drops, opened
-- crates and vendor buys never reach the book. The slots are read on
-- LOOT_READY, which comes before the loot window and before any auto-loot
-- addon has taken anything, and each is counted when its slot clears: with
-- full bags a fish can stay in the window, and then it wasn't caught yet.
--
-- Messages sent from here:
--   CATCH (catch)   catch = { itemID, count, first, spotID, share, quality,
--                             unique, special, valuable }
--   CATCHES (list)  every catch from one loot window, in loot order, once
--                   each has had its own CATCH
--   GETAWAY ()
--   NEXT_POINT (estimate)

local Log = {}
ns.Log = Log

-- Slot -> { itemID, count, quality } for the loot window that's open, if it's a
-- catch. Cleared when the window closes.
local pending = {}

local function ItemFromLink(link)
    if not link then
        return nil
    end
    return tonumber(link:match("item:(%d+)"))
end

ns.OnEvent("LOOT_READY", function()
    if not IsFishingLoot() then
        return
    end
    for slot = 1, GetNumLootItems() do
        -- LOOT_READY can fire more than once for the same window; a slot
        -- read the first time is left as it is.
        if not pending[slot] and GetLootSlotType(slot) == Enum.LootSlotType.Item then
            local itemID = ItemFromLink(GetLootSlotLink(slot))
            local _, _, quantity, _, quality = GetLootSlotInfo(slot)
            if itemID then
                pending[slot] = {
                    itemID = itemID,
                    count = ns.Readable(quantity) or 1,
                    quality = ns.Readable(quality),
                }
            end
        end
    end
end)

-- Catches between skill-ups, to guess how many more the next point takes.
local sinceLastPoint = 0
local recentGaps = {}
local lastSpotAt = nil

local function UpdateRecords(book, trip)
    local records = book.records
    local function Beat(name, value)
        local record = records[name]
        if value and value > 0 and (not record or value > record.value) then
            records[name] = { value = value, tripStartAt = trip.startAt }
        end
    end
    Beat("worth", math.max(trip.auction or 0, trip.vendor or 0))
    Beat("catches", trip.caught)
    Beat("seconds", trip.seconds)
    if trip.seconds >= 600 then
        Beat("perHour", math.floor(trip.caught * 3600 / trip.seconds))
    end
end

-- Unique finds and big moments --------------------------------------------

-- Anything off a line that isn't on Creel's list is a unique find: the
-- game may hand out things nobody knew could be fished up. The first one
-- is remembered with where, when and at what skill, so it can be reported.
local function RecordFind(book, itemID, spotID)
    book.finds = book.finds or {}
    if book.finds[itemID] then
        return
    end
    local here = ns.Spots.Here() or {}
    book.finds[itemID] = {
        firstAt = time(),
        spotID = spotID,
        zone = here.zone,
        subzone = here.subzone,
        mapID = here.mapID,
        mapX = here.mapX,
        mapY = here.mapY,
        -- The skill itself and what the pole, lure and gear add, apart, so a
        -- report says which. skill is the two together, as older finds have it.
        rank = ns.State.rank,
        bonus = ns.State.modifier or 0,
        skill = ns.State.EffectiveSkill(),
        character = ns.CharacterKey(),
    }
end

-- What makes a catch worth a fuss. The quality and the vendor's price both
-- come from the client's item cache, so this runs once the item is in it.
local function Mark(catch)
    local itemID = catch.itemID
    catch.quality = catch.quality or C_Item.GetItemQualityByID(itemID)
    catch.unique = not (ns.Catches and ns.Catches[itemID]) or nil
    catch.special = (catch.unique or (catch.quality or 0) >= Enum.ItemQuality.Epic) or nil

    -- Worth a lot by one of it, not by the stack.
    local worth = ns.Values.Auction(itemID) or ns.Values.Vendor(itemID)
    local threshold = ns.settings.valuableCopper or 0
    catch.valuable = (worth and threshold > 0 and worth >= threshold) or nil
end

-- How long a loot window's messages wait for the client to load an item
-- it hasn't seen before. They go out once this is up, loaded or not.
local LOAD_WAIT = 2

-- Item ID -> what's waiting for it to load.
local loading = {}

ns.OnEvent("ITEM_DATA_LOAD_RESULT", function(itemID)
    local waiting = loading[itemID]
    if waiting then
        loading[itemID] = nil
        for _, callback in ipairs(waiting) do
            callback()
        end
    end
end)

--- Calls back once every item in the list is in the client's cache, or
--- once LOAD_WAIT is up, whichever comes first. Something just looted is
--- nearly always there already.
local function WhenKnown(catches, callback)
    local called = false
    local function Done()
        if not called then
            called = true
            callback()
        end
    end

    local unknown = 0
    local function OneLoaded()
        unknown = unknown - 1
        if unknown == 0 then
            Done()
        end
    end
    for _, catch in ipairs(catches) do
        local itemID = catch.itemID
        if not C_Item.IsItemDataCachedByID(itemID) and C_Item.DoesItemExistByID(itemID) then
            unknown = unknown + 1
            loading[itemID] = loading[itemID] or {}
            table.insert(loading[itemID], OneLoaded)
            C_Item.RequestLoadItemDataByID(itemID)
        end
    end
    if unknown == 0 then
        Done()
    else
        C_Timer.After(LOAD_WAIT, Done)
    end
end

-- The catches from the loot window that's open. The book takes each one
-- the moment its slot clears; the messages wait for the whole window, so
-- the panel can pick the one most worth showing and play one sound for
-- the lot.
local window = {}

local function SendWindow()
    if #window == 0 then
        return
    end
    local catches = window
    window = {}
    WhenKnown(catches, function()
        for _, catch in ipairs(catches) do
            Mark(catch)
            ns.Send("CATCH", catch)
        end
        ns.Send("CATCHES", catches)
    end)
end

local function Record(itemID, count, quality)
    local book = ns.Book()
    local trip = ns.State.trip
    local now = time()

    local fish = book.fish[itemID]
    local first = fish == nil
    if first then
        fish = { caught = 0, firstAt = now }
        book.fish[itemID] = fish
    end

    local spotID = ns.Spots.Record(itemID, count)
    local spot = spotID and book.spots[spotID]
    if first then
        fish.firstSpot = spotID
    end
    fish.caught = fish.caught + count
    fish.lastAt = now
    book.totals.catches = book.totals.catches + count

    -- Time at a spot is the gap since the last catch there, when it's short
    -- enough to have been spent fishing.
    if spot and lastSpotAt and now - lastSpotAt <= 120 then
        spot.seconds = (spot.seconds or 0) + (now - lastSpotAt)
    end
    lastSpotAt = now

    if trip then
        trip.catches[itemID] = (trip.catches[itemID] or 0) + count
        trip.caught = trip.caught + count
        if spotID and not tContains(trip.spots, spotID) then
            table.insert(trip.spots, spotID)
        end
        local vendor, auction = ns.Values.Of(itemID)
        trip.vendor = trip.vendor + (vendor or 0) * count
        -- Only real auction prices go in the auction sum; catches with no
        -- price yet count at the vendor's rate in the vendor sum alone.
        trip.auction = trip.auction + (auction or 0) * count
        UpdateRecords(book, trip)
    end

    -- The rarest thing ever caught: the lowest share of its spot's catches,
    -- once the spot has enough catches for a share to mean something.
    if spot and spot.caught >= 30 then
        local share = ns.Spots.Share(spot, itemID)
        local rarest = book.records.rarest
        if not rarest or share < rarest.share then
            book.records.rarest = {
                share = share,
                itemID = itemID,
                spotID = spotID,
                tripStartAt = trip and trip.startAt,
            }
        end
    end

    if not (ns.Catches and ns.Catches[itemID]) then
        RecordFind(book, itemID, spotID)
    end

    sinceLastPoint = sinceLastPoint + count
    table.insert(window, {
        itemID = itemID,
        count = count,
        first = first,
        spotID = spotID,
        share = spot and ns.Spots.Share(spot, itemID) or nil,
        quality = quality,
    })
end

ns.OnEvent("LOOT_SLOT_CLEARED", function(slot)
    local catch = pending[slot]
    if catch then
        pending[slot] = nil
        Record(catch.itemID, catch.count, catch.quality)
        -- With auto-loot the window may stay open a moment after its last
        -- slot clears; there's nothing more to wait for by then.
        if next(pending) == nil then
            C_Timer.After(0, SendWindow)
        end
    end
end)

-- A slot still full when the window closes (bags full) wasn't caught.
ns.OnEvent("LOOT_CLOSED", function()
    wipe(pending)
    SendWindow()
end)

-- "Your fish got away!" and "No fish are hooked." come through as error
-- messages. The strings are the client's own, so this works in any
-- language the client is in.
-- "Requires Fishing %d" turns up when the water wants more skill than the
-- player has. Its number is the one fact about a spot's skill the game
-- ever states outright, so it's kept. The pattern is built from the
-- client's own string, so it matches in any language.
local needsPattern
local function NeedsPattern()
    local text = _G.SPELL_FAILED_FISHING_TOO_LOW
    if not needsPattern and type(text) == "string" then
        needsPattern = text:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"):gsub("%%%%d", "(%%d+)")
    end
    return needsPattern
end

ns.OnEvent("UI_ERROR_MESSAGE", function(_, message)
    message = ns.Readable(message)
    if not message then
        return
    end
    if _G.ERR_FISH_ESCAPED and message == _G.ERR_FISH_ESCAPED then
        ns.Spots.RecordGetaway()
        ns.Send("GETAWAY")
        return
    end
    local pattern = NeedsPattern()
    local needed = pattern and tonumber(message:match(pattern))
    if needed then
        ns.Spots.RecordNeeded(needed)
        ns.Send("GETAWAY")
    end
end)

--- Roughly how many more catches the next skill point will take, from the
--- last few points. Nil until there's something to go on, and at the cap.
---@return number|nil
function Log.ToNextPoint()
    local state = ns.State
    if #recentGaps == 0 or not state.rank or state.rank >= (state.maxRank or 0) then
        return nil
    end
    local sum = 0
    for _, gap in ipairs(recentGaps) do
        sum = sum + gap
    end
    return math.max(1, math.floor(sum / #recentGaps + 0.5) - sinceLastPoint)
end

local lastRank
ns.Listen("SKILL_CHANGED", function(rank)
    if lastRank and rank and rank > lastRank and sinceLastPoint > 0 then
        table.insert(recentGaps, sinceLastPoint)
        if #recentGaps > 5 then
            table.remove(recentGaps, 1)
        end
        sinceLastPoint = 0
    end
    lastRank = rank
    ns.Send("NEXT_POINT", Log.ToNextPoint())
end)
