local addonName, ns = ...

-- The saved data, and which book the current character writes in.
--
-- Everything lives in one account-wide table, CreelDB. A "book" holds the
-- catches, spots, trips and sales; by default every character shares the
-- account's book, and setup offers a separate one per character. Settings
-- are account-wide either way.

-- Bumped when the shape of the saved data changes, so an older table can
-- be brought up to date in Upgrade below instead of being thrown away.
local VERSION = 1

-- How many trips a book keeps in full. Older ones fold into the totals,
-- which keeps the saved file from growing without end.
ns.MAX_TRIPS = 200

local function NewBook()
    return {
        fish = {}, -- item ID -> { caught, firstAt, firstSpot, lastAt }
        spots = {}, -- spot ID -> see Fishing/Spots.lua
        nextSpot = 1,
        trips = {}, -- newest first
        totals = { seconds = 0, catches = 0, casts = 0, trips = 0 },
        records = {}, -- name -> { value, tripStartAt }
        sales = { vendor = {}, auction = {} }, -- item ID -> copper
        -- Item ID -> the first of a catch Creel didn't know about; see
        -- Fishing/Log.lua. Older books gain it with their first such catch.
        finds = {},
    }
end

local function Upgrade(db)
    -- Nothing to do yet: version 1 is the first shape. Later versions add
    -- their steps here, oldest first, each guarded by the version it fixes.
    db.version = VERSION
end

local function Fill(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = value
        end
    end
end

ns.OnEvent("ADDON_LOADED", function(name)
    if name ~= addonName then
        return
    end

    CreelDB = type(CreelDB) == "table" and CreelDB or {}
    local db = CreelDB

    db.settings = type(db.settings) == "table" and db.settings or {}
    Fill(db.settings, ns.DEFAULT_SETTINGS)

    db.characters = db.characters or {} -- key -> { setupDone, ownBook }
    db.books = db.books or {}
    db.books.account = db.books.account or NewBook()
    db.saved = db.saved or {} -- CVars we've changed: name -> { value, owners }
    db.ownSound = db.ownSound or {} -- sound settings at the last clean logout

    if (db.version or 0) < VERSION then
        Upgrade(db)
    end

    ns.db = db
    ns.settings = db.settings
    ns.Send("DATA_READY")
end)

--- What Creel remembers about the current character.
---@return table  { setupDone, ownBook }
function ns.Me()
    local key = ns.CharacterKey()
    ns.db.characters[key] = ns.db.characters[key] or {}
    return ns.db.characters[key]
end

--- The book the current character writes in.
---@return table
function ns.Book()
    if ns.Me().ownBook then
        local key = ns.CharacterKey()
        ns.db.books[key] = ns.db.books[key] or NewBook()
        return ns.db.books[key]
    end
    return ns.db.books.account
end

-- What the interface shows -----------------------------------------------------
--
-- The panel, the book, the map pins and the tooltips read the book, the
-- skill and the open trip through these, never through ns.Book() and
-- ns.State directly. Each gives the real thing; something that wants the
-- interface to show something else for a while (screenshots, say) can put
-- its own in their place without the fishing code, which always writes
-- through ns.Book() and ns.State, being any the wiser.

--- The book to show.
---@return table
function ns.ShownBook()
    return ns.Book()
end

--- The trip under way to show, if any.
---@return table|nil
function ns.ShownTrip()
    return ns.State.trip
end

--- Seconds of the trip under way so far.
---@return number
function ns.ShownTripSeconds()
    return ns.State.TripSeconds()
end

--- The Fishing skill to show: rank, the cap, and what gear and lure add.
---@return number|nil rank, number|nil maxRank, number modifier
function ns.ShownSkill()
    local state = ns.State
    return state.rank, state.maxRank, state.modifier or 0
end

--- How the water underfoot compares with the skill: see Spots.Verdict.
---@return string verdict, table|nil spot, string|nil reason
function ns.ShownVerdict()
    return ns.Spots.Verdict()
end

--- Switches the current character between the shared book and one of its
--- own. Nothing is moved or merged; each book keeps what's in it.
---@param own boolean
function ns.UseOwnBook(own)
    ns.Me().ownBook = own and true or nil
    ns.Send("BOOK_CHANGED")
end

--- Empties the book in use. Settings stay.
function ns.ForgetBook()
    if ns.Me().ownBook then
        ns.db.books[ns.CharacterKey()] = NewBook()
    else
        ns.db.books.account = NewBook()
    end
    ns.Send("BOOK_CHANGED")
end
