local _, ns = ...

-- Whether the player is fishing: the pole, the Fishing spell, the skill,
-- the line going out and coming back, and the trip all of that adds up to.
--
-- Messages sent from here:
--   POLE_CHANGED (hasPole)       a pole went into or out of the main hand
--   LINE_OUT ()                  the Fishing channel started
--   LINE_IN ()                   it ended, for whatever reason
--   SKILL_CHANGED (rank, max, modifier)
--   TRIP_STARTED (trip)
--   TRIP_ENDED (trip)
--   TRIP_TICK ()                 once a second while a trip is open

local State = {}
ns.State = State

local MAIN_HAND = 16

-- The Classic Fishing spells, apprentice to artisan. Only used if the
-- profession can't tell us which one the player knows.
local FALLBACK_SPELLS = { 7620, 7731, 7732, 18248 }

-- A gap between casts longer than this doesn't count as time spent
-- fishing: a walk to the vendor, a fight, a chat.
local GAP_SECONDS = 120

State.hasPole = false
State.lineOut = false
State.lineOutAt = nil
State.lineSeconds = nil -- how long this cast's channel lasts
State.spellID = nil
State.rank, State.maxRank, State.modifier = nil, nil, 0

-- The open trip, if any. It's also the newest entry in the book's trips,
-- so it's saved as it grows.
State.trip = nil
local lastCastAt = nil

local function IsFishingPole(itemID)
    if not itemID then
        return false
    end
    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
    return classID == Enum.ItemClass.Weapon and subclassID == Enum.ItemWeaponSubclass.Fishingpole
end

local function CheckPole()
    local has = IsFishingPole(GetInventoryItemID("player", MAIN_HAND))
    if has ~= State.hasPole then
        State.hasPole = has
        ns.Send("POLE_CHANGED", has)
    end
end

-- On Forever, GetProfessions() hands back the fishing index fourth, after
-- first aid (Blizzard_ProfessionsBook/Camelot). The profession's first
-- spell is the Fishing spell at the player's rank.
local function ReadProfession()
    local fishing = select(4, GetProfessions())
    if not fishing then
        local had = State.spellID or State.rank
        State.spellID, State.rank, State.maxRank, State.modifier = nil, nil, nil, 0
        if had then
            ns.Send("SPELL_CHANGED", nil)
            ns.Send("SKILL_CHANGED", nil, nil, 0)
        end
        return
    end

    local _, _, rank, maxRank, _, spellOffset, _, modifier = GetProfessionInfo(fishing)
    local changed = rank ~= State.rank
        or maxRank ~= State.maxRank
        or (modifier or 0) ~= State.modifier
    State.rank, State.maxRank, State.modifier = rank, maxRank, modifier or 0

    local spellID
    if spellOffset then
        local info =
            C_SpellBook.GetSpellBookItemInfo(spellOffset + 1, Enum.SpellBookSpellBank.Player)
        spellID = info and info.spellID
    end
    if not spellID then
        for index = #FALLBACK_SPELLS, 1, -1 do
            if C_SpellBook.IsSpellKnown(FALLBACK_SPELLS[index]) then
                spellID = FALLBACK_SPELLS[index]
                break
            end
        end
    end
    if spellID ~= State.spellID then
        State.spellID = spellID
        ns.Send("SPELL_CHANGED", spellID)
    end
    if changed then
        ns.Send("SKILL_CHANGED", rank, maxRank, modifier or 0)
    end
end

--- Whether a spell is the player's Fishing, at any rank.
---@param spellID number
---@return boolean
function State.IsFishing(spellID)
    if not spellID then
        return false
    end
    if spellID == State.spellID then
        return true
    end
    for _, id in ipairs(FALLBACK_SPELLS) do
        if id == spellID then
            return true
        end
    end
    return false
end

--- The skill the game fishes with: rank plus pole, lure and gear.
---@return number|nil
function State.EffectiveSkill()
    if not State.rank then
        return nil
    end
    return State.rank + (State.modifier or 0)
end

-- Trips -------------------------------------------------------------------

local function Now()
    return time()
end

local tripBook

local function StartTrip()
    local book = ns.Book()
    local trip = {
        character = ns.CharacterKey(),
        startAt = Now(),
        seconds = 0,
        casts = 0,
        catches = {},
        caught = 0,
        spots = {},
        skillFrom = State.rank,
        skillTo = State.rank,
        vendor = 0,
        auction = 0,
    }
    table.insert(book.trips, 1, trip)
    book.totals.trips = (book.totals.trips or 0) + 1

    -- Keep the list bounded. What falls off the end is already counted in
    -- the totals and the per-fish and per-spot numbers.
    while #book.trips > ns.MAX_TRIPS do
        table.remove(book.trips)
    end

    State.trip = trip
    -- Kept so the trip can be tidied up in the book it started in, even
    -- after the character has switched to another.
    tripBook = book
    ns.Send("TRIP_STARTED", trip)
end

-- A trip with no catches isn't worth a line in the book.
local function DropIfEmpty(trip, book)
    if trip.caught > 0 or not book then
        return
    end
    for index, entry in ipairs(book.trips) do
        if entry == trip then
            table.remove(book.trips, index)
            book.totals.trips = math.max(0, (book.totals.trips or 1) - 1)
            break
        end
    end
end

--- Closes the open trip, if there is one.
function State.EndTrip()
    local trip = State.trip
    if not trip then
        return
    end
    State.trip = nil
    lastCastAt = nil
    trip.endAt = Now()
    DropIfEmpty(trip, tripBook)
    tripBook = nil
    ns.Send("TRIP_ENDED", trip)
end

-- Time fishing counts the gaps between casts that are short enough to be
-- fishing rather than doing something else.
local function CountCast()
    local now = Now()
    if not State.trip then
        StartTrip()
    end
    local book = ns.Book()
    if lastCastAt then
        local gap = now - lastCastAt
        if gap > 0 and gap <= GAP_SECONDS then
            State.trip.seconds = State.trip.seconds + gap
            book.totals.seconds = book.totals.seconds + gap
        end
    end
    lastCastAt = now
    State.trip.casts = State.trip.casts + 1
    book.totals.casts = (book.totals.casts or 0) + 1
end

--- Seconds of this trip so far, including the cast under way.
---@return number
function State.TripSeconds()
    local trip = State.trip
    if not trip then
        return 0
    end
    local extra = 0
    if lastCastAt then
        local gap = Now() - lastCastAt
        if gap > 0 and gap <= GAP_SECONDS then
            extra = gap
        end
    end
    return trip.seconds + extra
end

-- Events ------------------------------------------------------------------

ns.OnPlayerEvent("UNIT_SPELLCAST_CHANNEL_START", function(_, spellID)
    spellID = ns.Readable(spellID)
    if not State.IsFishing(spellID) then
        return
    end
    State.lineOut = true
    State.lineOutAt = GetTime()
    local _, _, _, startMS, endMS = UnitChannelInfo("player")
    startMS, endMS = ns.Readable(startMS), ns.Readable(endMS)
    State.lineSeconds = (startMS and endMS) and (endMS - startMS) / 1000 or 30
    CountCast()
    ns.Send("LINE_OUT")
end)

ns.OnPlayerEvent("UNIT_SPELLCAST_CHANNEL_STOP", function(_, spellID)
    spellID = ns.Readable(spellID)
    if not State.lineOut or (spellID and not State.IsFishing(spellID)) then
        return
    end
    State.lineOut = false
    State.lineOutAt = nil
    ns.Send("LINE_IN")
end)

ns.OnEvent("PLAYER_EQUIPMENT_CHANGED", function(slot)
    if slot == MAIN_HAND then
        CheckPole()
    end
end)

ns.OnEvent("SKILL_LINES_CHANGED", ReadProfession)
ns.OnEvent("LEARNED_SPELL_IN_SKILL_LINE", ReadProfession)

ns.OnEvent("PLAYER_ENTERING_WORLD", function()
    CheckPole()
    ReadProfession()
end)

-- The trip ends by itself after a while with no cast, or as soon as the
-- pole comes out of the hand.
ns.Listen("POLE_CHANGED", function(hasPole)
    if not hasPole and State.trip then
        State.EndTrip()
    end
end)

C_Timer.NewTicker(1, function()
    if not State.trip then
        return
    end
    if lastCastAt and Now() - lastCastAt > ns.settings.idleMinutes * 60 then
        State.EndTrip()
        return
    end
    if State.trip and State.rank and State.rank ~= State.trip.skillTo then
        State.trip.skillTo = State.rank
    end
    ns.Send("TRIP_TICK")
end)

ns.OnEvent("PLAYER_LOGOUT", function()
    -- Logging out closes the trip, but only the clock: the saved record
    -- is already up to date. A trip with nothing caught is dropped here
    -- directly rather than through EndTrip, whose listeners would start
    -- changing settings again after they've been put back.
    local trip = State.trip
    if not trip then
        return
    end
    trip.endAt = Now()
    DropIfEmpty(trip, tripBook)
end)

-- Switching books, or emptying one, mid-trip: the open trip belongs to
-- the book it started in, and the next cast starts a new one in the book
-- now in use.
ns.Listen("BOOK_CHANGED", function()
    if State.trip then
        local trip = State.trip
        State.trip = nil
        lastCastAt = nil
        trip.endAt = Now()
        DropIfEmpty(trip, tripBook)
        tripBook = nil
        ns.Send("TRIP_ENDED", trip)
    end
end)
