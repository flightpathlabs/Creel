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
--   CATCH (catch)   catch = { itemID, count, first, spotID, share }
--   GETAWAY ()
--   NEXT_POINT (estimate)

local Log = {}
ns.Log = Log

-- Slot -> { itemID, count } for the loot window that's open, if it's a
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
            local quantity = select(3, GetLootSlotInfo(slot))
            if itemID then
                pending[slot] = { itemID = itemID, count = ns.Readable(quantity) or 1 }
            end
        end
    end
end)

ns.OnEvent("LOOT_CLOSED", function()
    wipe(pending)
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

local function Record(itemID, count)
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

    sinceLastPoint = sinceLastPoint + count
    ns.Send("CATCH", {
        itemID = itemID,
        count = count,
        first = first,
        spotID = spotID,
        share = spot and ns.Spots.Share(spot, itemID) or nil,
    })
end

ns.OnEvent("LOOT_SLOT_CLEARED", function(slot)
    local catch = pending[slot]
    if catch then
        pending[slot] = nil
        Record(catch.itemID, catch.count)
    end
end)

-- "Your fish got away!" and "No fish are hooked." come through as error
-- messages. The strings are the client's own, so this works in any
-- language the client is in.
ns.OnEvent("UI_ERROR_MESSAGE", function(_, message)
    if message and _G.ERR_FISH_ESCAPED and message == _G.ERR_FISH_ESCAPED then
        ns.Spots.RecordGetaway()
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
