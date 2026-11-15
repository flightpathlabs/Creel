local _, ns = ...

-- "/creel demo": a made-up angler, for taking screenshots.
--
-- Creel's panel and book fill in over weeks of fishing, which is no help
-- to someone who wants to show what they look like today. With the demo
-- on, the panel shows a trip under way at Booty Bay and the book is a
-- month of invented fishing: forty-odd kinds from ten waters across the
-- Eastern Kingdoms and Kalimdor, two dozen trips, records, sales and a
-- couple of unique finds.
--
-- Nothing is saved and nothing real is changed. Only what the interface
-- shows is swapped: ns.ShownBook(), ns.ShownTrip(), ns.ShownTripSeconds(),
-- ns.ShownSkill(), ns.ShownLevel(), ns.ShownVerdict() and
-- ns.ShownToNextPoint() (Core/Database.lua) give the invented angler while
-- the demo is on. The bags, known recipes and where the player stands stay
-- real.
-- Everything that writes (catches, casts, sales, the trip, casting and
-- sound) goes on using the real book and the real state, so fishing for
-- real with the demo on loses nothing.
-- It all goes back when the demo is switched off or the interface is
-- reloaded, and anything that changes which book is in use, or empties
-- it, switches the demo off first.
--
-- Then, while it's on:
--   /creel demo catch   an ordinary catch lands on the card
--   /creel demo find    the unique-find moment
--   /creel demo worth   the worth-a-lot moment

local Demo = {}
ns.Demo = Demo

local on = false

-- The real accessors, kept while the invented ones stand in.
local real = {}

local book
local trip
local turnedOnAt

-- A repeatable source of "random" numbers, so the same book comes out
-- every time and a screenshot can be retaken.
local function Wobble(seed)
    local state = seed % 2147483647
    return function()
        state = (state * 48271) % 2147483647
        return state / 2147483647
    end
end

-- The angler -------------------------------------------------------------------

-- Partway to Artisan: 187 of 225, with a pole and a lure adding 25.
local RANK = 187
local MAX_RANK = 225
local BONUS = 25
-- Old enough for everything up to the next rank, so the Next page asks
-- only for skill, whatever the character taking the pictures is.
local LEVEL = 40

-- Where they've fished, in the order they got there, with the skill they
-- had on arriving and what each water has given them. Real waters, at
-- rough positions on each zone's map; real catches, in the share they come
-- up in. The zone's name comes from the client, so it's in the player's
-- language; the subzone names are English.
local WATERS = {
    {
        mapID = 1429, -- Elwynn Forest
        x = 51.8,
        y = 64.6,
        subzone = "Crystal Lake",
        skill = 1,
        trips = 1,
        catches = { [6291] = 64, [6643] = 3, [6299] = 9, [17057] = 5 },
    },
    {
        mapID = 1436, -- Westfall
        x = 31.2,
        y = 46.8,
        subzone = "Longshore",
        skill = 22,
        trips = 2,
        catches = {
            [6303] = 72,
            [6291] = 18,
            [6644] = 4,
            [6351] = 3,
            [6458] = 9,
            [6307] = 2,
            [17058] = 4,
        },
    },
    {
        mapID = 1432, -- Loch Modan
        x = 51.4,
        y = 39.2,
        subzone = "The Loch",
        skill = 55,
        trips = 2,
        catches = {
            [6289] = 86,
            [6317] = 41,
            [6645] = 4,
            [6292] = 3,
            [6294] = 2,
            [6352] = 2,
        },
    },
    {
        mapID = 1433, -- Redridge Mountains
        x = 37.6,
        y = 54.2,
        subzone = "Lake Everstill",
        skill = 78,
        trips = 3,
        catches = { [6289] = 52, [6317] = 33, [6308] = 14, [6295] = 1, [6292] = 2 },
    },
    {
        mapID = 1439, -- Darkshore
        x = 35.8,
        y = 45.4,
        subzone = "Auberdine",
        skill = 96,
        trips = 2,
        catches = { [6361] = 31, [6358] = 15, [6303] = 11, [12238] = 4, [6646] = 2 },
    },
    {
        mapID = 1437, -- Wetlands
        x = 7.8,
        y = 58.4,
        subzone = "Menethil Harbor",
        skill = 108,
        trips = 3,
        catches = {
            [6361] = 61,
            [6358] = 44,
            [6359] = 29,
            [6646] = 5,
            [6352] = 3,
            [6353] = 2,
            [6354] = 1,
        },
    },
    {
        mapID = 1431, -- Duskwood
        x = 41.2,
        y = 26.8,
        subzone = "The Darkened Bank",
        skill = 124,
        trips = 3,
        catches = {
            [6308] = 57,
            [6359] = 11,
            [6309] = 3,
            [6310] = 2,
            [6311] = 1,
            [6647] = 4,
            [6299] = 6,
        },
    },
    {
        mapID = 1424, -- Hillsbrad Foothills
        x = 51.6,
        y = 60.2,
        subzone = "Southshore",
        skill = 141,
        trips = 3,
        catches = {
            [6361] = 38,
            [6362] = 36,
            [6358] = 21,
            [21071] = 16,
            [6355] = 2,
            [6363] = 1,
        },
    },
    {
        mapID = 1445, -- Dustwallow Marsh
        x = 69.4,
        y = 52.6,
        subzone = "Theramore Isle",
        skill = 163,
        trips = 3,
        catches = {
            [6362] = 41,
            [4603] = 28,
            [8365] = 24,
            [8366] = 2,
            [6358] = 10,
            [6360] = 1, -- a unique find
        },
    },
    {
        mapID = 1434, -- Stranglethorn Vale
        x = 26.6,
        y = 75.8,
        subzone = "Booty Bay",
        skill = 176,
        trips = 3,
        catches = {
            [6362] = 194,
            [4603] = 121,
            [6359] = 63,
            [6358] = 27,
            [7973] = 14,
            [21164] = 9,
            [6356] = 4,
            [6357] = 3,
            [9276] = 1,
            [19807] = 6,
            [7971] = 1, -- a unique find
        },
    },
}

-- The trip under way, at Booty Bay (the last water above).
local TRIP_WATER = #WATERS
local TRIP_CATCHES = { [6362] = 58, [4603] = 37, [6359] = 19, [6358] = 11, [7973] = 4, [21164] = 2 }
local TRIP_SKILL_FROM = RANK - 3
local TRIP_MINUTES = 42
-- Catches to the next skill point, about what it takes at 187.
local TO_NEXT_POINT = 4

-- The latest catch on the card when the demo starts.
local LATEST = 4603 -- Raw Spotted Yellowtail

-- Neither of these is on Creel's list of catches, so the book files them
-- as unique finds: a Steelscale Crushfish (a quest fish from Stonetalon)
-- and a Black Pearl, which comes out of clams. A third, an Iridescent
-- Pearl, is kept back for "/creel demo find".
local FIND_SKILL = { [6360] = 168, [7971] = 179 }
local RAREST = { itemID = 7971, spotID = #WATERS }
local NEW_FIND = 5500

-- Older trips than the book keeps in full, which the totals still count.
local FOLDED_TRIPS = 16

-- How long a catch takes, about: casting, the wait, and looting.
local SECONDS_A_CATCH = 17

local function ZoneName(mapID)
    local info = C_Map.GetMapInfo(mapID)
    return info and info.name or ""
end

-- Building the book ----------------------------------------------------------------

local function NewSpot(water, firstAt, lastAt)
    local spot = {
        mapID = water.mapID,
        mapX = water.x / 100,
        mapY = water.y / 100,
        zone = ZoneName(water.mapID),
        subzones = {},
        catches = {},
        caught = 0,
        seconds = 0,
        -- The skill as the game counts it at the water: rank and bonus.
        lowestSkill = water.skill + BONUS,
        firstAt = firstAt,
        lastAt = lastAt,
    }
    local continent, world =
        C_Map.GetWorldPosFromMapPos(water.mapID, CreateVector2D(spot.mapX, spot.mapY))
    if continent and world then
        spot.continent, spot.x, spot.y = continent, world.x, world.y
    else
        spot.continent, spot.x, spot.y = "map" .. water.mapID, 0, 0
    end
    for itemID, count in pairs(water.catches) do
        spot.catches[itemID] = count
        spot.caught = spot.caught + count
    end
    spot.subzones[water.subzone] = spot.caught
    spot.seconds = spot.caught * SECONDS_A_CATCH
    return spot
end

local function NewTrip(startAt, spotID, skillFrom, skillTo)
    return {
        character = ns.CharacterKey(),
        startAt = startAt,
        seconds = 0,
        casts = 0,
        catches = {},
        caught = 0,
        spots = { spotID },
        skillFrom = skillFrom,
        skillTo = skillTo,
        vendor = 0,
        auction = 0,
    }
end

local function AddToTrip(entry, itemID, count)
    if count > 0 then
        entry.catches[itemID] = (entry.catches[itemID] or 0) + count
        entry.caught = entry.caught + count
    end
end

-- What everything in the book is worth, from today's prices: the trips'
-- worth, what's been sold, and the records that follow from them. Asked
-- again a moment after the demo starts, since the client may only then
-- have loaded the prices.
local function FillMoney()
    local random = Wobble(5077)
    for _, entry in ipairs(book.trips) do
        entry.vendor, entry.auction = 0, 0
        for itemID, count in pairs(entry.catches) do
            local vendor, auction = ns.Values.Of(itemID)
            entry.vendor = entry.vendor + (vendor or 0) * count
            entry.auction = entry.auction + (auction or 0) * count
        end
    end

    -- About half of every catch sold: fish and junk to vendors, the oils
    -- and the trade fish at auction.
    wipe(book.sales.vendor)
    wipe(book.sales.auction)
    local atAuction = { oil = true, fish = true, shellfish = true }
    -- In a fixed order, so the same sales come out every time.
    local itemIDs = {}
    for itemID in pairs(book.fish) do
        table.insert(itemIDs, itemID)
    end
    table.sort(itemIDs)
    for _, itemID in ipairs(itemIDs) do
        local fish = book.fish[itemID]
        local entry = ns.Catches and ns.Catches[itemID]
        local sold = math.floor(fish.caught * (0.3 + random() * 0.4))
        local auction = entry and atAuction[entry.kind] and ns.Values.Auction(itemID)
        if sold > 0 and auction and random() > 0.35 then
            book.sales.auction[itemID] = math.floor(auction * 0.95) * sold
        elseif sold > 0 and entry then
            local vendor = ns.Values.Vendor(itemID)
            if vendor and vendor > 0 then
                book.sales.vendor[itemID] = vendor * sold
            end
        end
    end

    local records = {}
    local function Beat(name, value, startAt)
        if value and value > 0 and (not records[name] or value > records[name].value) then
            records[name] = { value = value, tripStartAt = startAt }
        end
    end
    for _, entry in ipairs(book.trips) do
        Beat("worth", math.max(entry.auction, entry.vendor), entry.startAt)
        Beat("catches", entry.caught, entry.startAt)
        Beat("seconds", entry.seconds, entry.startAt)
        if entry.seconds >= 600 then
            Beat("perHour", math.floor(entry.caught * 3600 / entry.seconds), entry.startAt)
        end
    end

    -- The rarest catch: the Black Pearl, one in hundreds at Booty Bay.
    local spot = book.spots[RAREST.spotID]
    records.rarest = {
        share = ns.Spots.Share(spot, RAREST.itemID),
        itemID = RAREST.itemID,
        spotID = RAREST.spotID,
    }
    book.records = records
end

local function BuildBook()
    local now = time()
    local day = ns.SECONDS_PER_DAY
    local random = Wobble(4242)

    book = {
        fish = {},
        spots = {},
        nextSpot = #WATERS + 1,
        trips = {},
        totals = { seconds = 0, catches = 0, casts = 0, trips = 0 },
        records = {},
        sales = { vendor = {}, auction = {} },
        finds = {},
    }

    -- Four weeks, the waters one after another, the last still being
    -- fished today.
    local span = 27 * day
    local each = span / #WATERS
    local past = {}
    for spotID, water in ipairs(WATERS) do
        local firstAt = math.floor(now - span + (spotID - 1) * each)
        local lastAt = spotID == #WATERS and now or math.floor(firstAt + each * 0.85)
        local spot = NewSpot(water, firstAt, lastAt)
        book.spots[spotID] = spot

        book.totals.catches = book.totals.catches + spot.caught
        book.totals.seconds = book.totals.seconds + spot.seconds
        book.totals.casts = book.totals.casts + math.floor(spot.caught * 1.16)

        for itemID, count in pairs(spot.catches) do
            local fish = book.fish[itemID]
            if not fish then
                local at = firstAt + math.floor(random() * each * 0.5)
                fish = { caught = 0, firstAt = at, firstSpot = spotID, lastAt = at }
                book.fish[itemID] = fish
            end
            fish.caught = fish.caught + count
            fish.lastAt = math.max(fish.lastAt, lastAt - math.floor(random() * day))
        end

        -- The trips kept in full share out over half of the water's catches;
        -- the rest went to older trips that are only in the totals.
        local nextSkill = WATERS[spotID + 1] and WATERS[spotID + 1].skill or TRIP_SKILL_FROM
        for index = 1, water.trips do
            local startAt = math.floor(firstAt + (index - 0.5) * (lastAt - firstAt) / water.trips)
            -- An evening's fishing, give or take, and never one still to come.
            startAt = startAt - startAt % day + 18 * 3600 + math.floor(random() * 3 * 3600)
            if startAt > now - (TRIP_MINUTES + 120) * 60 then
                startAt = startAt - day
            end
            local from = water.skill
                + math.floor((nextSkill - water.skill) * (index - 1) / water.trips)
            local to = water.skill + math.floor((nextSkill - water.skill) * index / water.trips)
            local entry = NewTrip(startAt, spotID, from, to)
            for itemID, count in pairs(water.catches) do
                if not FIND_SKILL[itemID] then
                    AddToTrip(
                        entry,
                        itemID,
                        math.floor(count * 0.6 / water.trips * (0.7 + random() * 0.6))
                    )
                end
            end
            entry.seconds = entry.caught * SECONDS_A_CATCH + math.floor(random() * 300)
            entry.casts = math.floor(entry.caught * 1.16)
            entry.endAt = startAt + entry.seconds + math.floor(random() * 900)
            if entry.caught > 0 then
                table.insert(past, entry)
            end
        end
    end

    -- The finds, each with where and when it came up and the skill then.
    for itemID, rank in pairs(FIND_SKILL) do
        local fish = book.fish[itemID]
        local spot = book.spots[fish.firstSpot]
        book.finds[itemID] = {
            firstAt = fish.firstAt,
            spotID = fish.firstSpot,
            zone = spot.zone,
            subzone = WATERS[fish.firstSpot].subzone,
            mapID = spot.mapID,
            mapX = spot.mapX,
            mapY = spot.mapY,
            rank = rank,
            bonus = BONUS,
            skill = rank + BONUS,
            character = ns.CharacterKey(),
        }
    end

    -- The trip under way, which is the newest in the book.
    trip = NewTrip(now - TRIP_MINUTES * 60, TRIP_WATER, TRIP_SKILL_FROM, RANK)
    for itemID, count in pairs(TRIP_CATCHES) do
        AddToTrip(trip, itemID, count)
    end
    trip.seconds = TRIP_MINUTES * 60 - 95
    trip.casts = math.floor(trip.caught * 1.2)

    table.sort(past, function(a, b)
        return a.startAt > b.startAt
    end)
    book.trips[1] = trip
    for _, entry in ipairs(past) do
        table.insert(book.trips, entry)
    end
    book.totals.trips = #book.trips + FOLDED_TRIPS

    FillMoney()
end

-- Every item the demo shows, asked of the client so names, icons and
-- prices are in by the time anyone looks.
local function LoadItems()
    local items = { [NEW_FIND] = true }
    for _, water in ipairs(WATERS) do
        for itemID in pairs(water.catches) do
            items[itemID] = true
        end
    end
    for itemID in pairs(items) do
        if not C_Item.IsItemDataCachedByID(itemID) then
            C_Item.RequestLoadItemDataByID(itemID)
        end
    end
end

-- Catches on the card -----------------------------------------------------------

--- Files a made-up catch in the demo's book and trip, and puts it on the
--- card the way a real one arrives.
---@param flags table|nil  { unique, special, valuable } for the moment wanted
local function Land(itemID, flags)
    local spotID = TRIP_WATER
    local spot = book.spots[spotID]
    local fish = book.fish[itemID]
    local first = fish == nil
    if first then
        fish = { caught = 0, firstAt = time(), firstSpot = spotID }
        book.fish[itemID] = fish
    end
    fish.caught = fish.caught + 1
    fish.lastAt = time()
    spot.catches[itemID] = (spot.catches[itemID] or 0) + 1
    spot.caught = spot.caught + 1
    book.totals.catches = book.totals.catches + 1
    AddToTrip(trip, itemID, 1)
    local vendor, auction = ns.Values.Of(itemID)
    trip.vendor = trip.vendor + (vendor or 0)
    trip.auction = trip.auction + (auction or 0)

    if flags and flags.unique and not book.finds[itemID] then
        book.finds[itemID] = {
            firstAt = time(),
            spotID = spotID,
            zone = spot.zone,
            subzone = WATERS[spotID].subzone,
            mapID = spot.mapID,
            mapX = spot.mapX,
            mapY = spot.mapY,
            rank = RANK,
            bonus = BONUS,
            skill = RANK + BONUS,
            character = ns.CharacterKey(),
        }
    end

    local catch = {
        itemID = itemID,
        count = 1,
        first = first,
        spotID = spotID,
        share = ns.Spots.Share(spot, itemID),
        quality = C_Item.GetItemQualityByID(itemID),
    }
    for key, value in pairs(flags or {}) do
        catch[key] = value
    end
    ns.Send("DEMO_CHANGED", true)
    if ns.Panel and ns.Panel.ShowDemoCatches then
        ns.Panel.ShowDemoCatches({ catch })
    end
end

-- An ordinary catch from the trip's water: one of the fish it gives.
local ORDINARY = { 6362, 6362, 6362, 4603, 4603, 6359, 6358 }
local ordinaryTurn = 0

local function LandOrdinary()
    ordinaryTurn = ordinaryTurn % #ORDINARY + 1
    Land(ORDINARY[ordinaryTurn], {})
end

-- Something worth a lot: whichever of the trip water's catches has the
-- best price today, with the Firefin Snapper when nothing has one.
local function LandValuable()
    local best, bestWorth = 6359, 0
    for itemID in pairs(WATERS[TRIP_WATER].catches) do
        local worth = ns.Values.Auction(itemID) or ns.Values.Vendor(itemID) or 0
        if worth > bestWorth and not FIND_SKILL[itemID] then
            best, bestWorth = itemID, worth
        end
    end
    Land(best, { valuable = true })
end

-- Switching -------------------------------------------------------------------

local ticker

local function TurnOn()
    -- Everything is built before anything is swapped, so a failure here
    -- leaves the interface as it was.
    LoadItems()
    BuildBook()
    turnedOnAt = time()

    real.ShownBook = ns.ShownBook
    real.ShownTrip = ns.ShownTrip
    real.ShownTripSeconds = ns.ShownTripSeconds
    real.ShownSkill = ns.ShownSkill
    real.ShownLevel = ns.ShownLevel
    real.ShownVerdict = ns.ShownVerdict
    real.ShownToNextPoint = ns.ShownToNextPoint

    ns.ShownBook = function()
        return book
    end
    ns.ShownTrip = function()
        return trip
    end
    ns.ShownTripSeconds = function()
        return trip.seconds + (time() - turnedOnAt)
    end
    ns.ShownSkill = function()
        return RANK, MAX_RANK, BONUS
    end
    ns.ShownLevel = function()
        return LEVEL
    end
    -- The water underfoot is the trip's, with no getaways at this skill.
    ns.ShownVerdict = function()
        return "safe", book.spots[TRIP_WATER]
    end
    ns.ShownToNextPoint = function()
        return TO_NEXT_POINT
    end
    on = true

    if ns.Panel and ns.Panel.SetDemo then
        ns.Panel.SetDemo(true)
    end
    ns.Send("DEMO_CHANGED", true)

    -- The trip's clock runs, as a real one does.
    ticker = C_Timer.NewTicker(1, function()
        ns.Send("DEMO_TICK")
    end)

    -- The card starts with a good catch on it, the way it would be.
    local spot = book.spots[TRIP_WATER]
    if ns.Panel and ns.Panel.ShowDemoCatches then
        ns.Panel.ShowDemoCatches({
            {
                itemID = LATEST,
                count = 1,
                first = false,
                spotID = TRIP_WATER,
                share = ns.Spots.Share(spot, LATEST),
                quality = C_Item.GetItemQualityByID(LATEST),
            },
        })
    end

    -- Prices the client only had once the items loaded.
    C_Timer.After(1.5, function()
        if on then
            FillMoney()
            ns.Send("DEMO_CHANGED", true)
            if ns.Panel then
                ns.Panel.Refresh()
            end
        end
    end)

    print(
        "|cffffd100Creel|r: Demo data is on: the panel and the Fishing Book show an invented "
            .. "angler, for screenshots. Nothing is saved. Type /creel demo again, or reload, "
            .. "to switch it off."
    )
end

local function TurnOff()
    if not on then
        return
    end
    on = false
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
    ns.ShownBook = real.ShownBook
    ns.ShownTrip = real.ShownTrip
    ns.ShownTripSeconds = real.ShownTripSeconds
    ns.ShownSkill = real.ShownSkill
    ns.ShownLevel = real.ShownLevel
    ns.ShownVerdict = real.ShownVerdict
    ns.ShownToNextPoint = real.ShownToNextPoint
    book, trip = nil, nil
    if ns.Panel and ns.Panel.SetDemo then
        ns.Panel.SetDemo(false)
    end
    ns.Send("DEMO_CHANGED", false)
end

---@return boolean
function Demo.IsOn()
    return on
end

--- Switches the demo off before something changes the real book (emptying
--- it, or moving to another), and says so, so nobody's left wondering
--- which book they're looking at.
function Demo.Stop()
    if on then
        TurnOff()
        print("|cffffd100Creel|r: Demo data is off. The panel and the book are back to your own.")
    end
end

--- The slash command's words after "demo".
---@param word string  "", "catch", "find" or "worth"
function Demo.Command(word)
    if word == "" then
        if on then
            TurnOff()
        else
            TurnOn()
        end
    elseif not on then
        return
    elseif word == "catch" then
        LandOrdinary()
    elseif word == "find" then
        Land(NEW_FIND, { unique = true, special = true })
    elseif word == "worth" then
        LandValuable()
    end
end

-- Another book, or this one emptied, by whatever route.
ns.Listen("BOOK_CHANGED", Demo.Stop)
