local _, ns = ...

-- Fishing spots: catches grouped by where they were made, so a pond fished
-- from three rocks is one place in the book rather than three points.
--
-- A spot is the average position of its catches in world coordinates
-- (yards), which is what distances need; the zone map position is kept
-- too, averaged the same way, for pins on the map. A catch joins the
-- nearest spot within RADIUS on the same continent, or starts a new one.
-- If a spot's centre drifts within RADIUS of another, the two merge.
--
-- A spot looks like:
--   { continent, x, y, mapID, mapX, mapY, zone, subzones = { name -> n },
--     catches = { itemID -> n }, caught, seconds, lowestSkill,
--     getawaySkill, needsSkill, firstAt, lastAt }
--
-- A fish getting away, or the game saying the water needs more skill,
-- starts a spot too, so new water remembers it. Such a spot has nothing
-- caught yet; lists of places leave it out until it has.

local Spots = {}
ns.Spots = Spots

local RADIUS = 40

-- Where the player is standing: continent and world position, plus the
-- zone map and its 0-1 position. Inside instances the map position is
-- missing, so the whole instance is treated as one place.
---@return table|nil
function Spots.Here()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        return nil
    end

    local here = {
        mapID = mapID,
        zone = GetRealZoneText() or "",
        subzone = GetSubZoneText() or "",
    }

    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    if position then
        local continent, world = C_Map.GetWorldPosFromMapPos(mapID, position)
        if continent and world then
            here.continent = continent
            here.x, here.y = world.x, world.y
            here.mapX, here.mapY = position.x, position.y
            return here
        end
    end

    here.continent = "map" .. mapID
    here.x, here.y = 0, 0
    return here
end

local function Distance(spot, x, y)
    local dx, dy = spot.x - x, spot.y - y
    return math.sqrt(dx * dx + dy * dy)
end

--- The saved spot the player is standing at, if any.
---@return number|nil spotID
---@return table|nil spot
function Spots.Current()
    local here = Spots.Here()
    if not here then
        return nil
    end
    local bestID, best, bestDistance
    for id, spot in pairs(ns.Book().spots) do
        if spot.continent == here.continent then
            local distance = Distance(spot, here.x, here.y)
            if distance <= RADIUS and (not bestDistance or distance < bestDistance) then
                bestID, best, bestDistance = id, spot, distance
            end
        end
    end
    return bestID, best
end

--- The name a spot goes by: the subzone most of its catches came from,
--- or the zone when the water has no subzone of its own.
---@param spot table
---@return string
function Spots.Name(spot)
    local name, most = nil, 0
    for subzone, count in pairs(spot.subzones or {}) do
        if subzone ~= "" and count > most then
            name, most = subzone, count
        end
    end
    return name or spot.zone or "Unknown waters"
end

-- Folds spot b into spot a. Positions are weighted by how many catches
-- each holds, so the bigger spot barely moves.
local function Merge(a, b)
    local total = a.caught + b.caught
    if total > 0 then
        a.x = (a.x * a.caught + b.x * b.caught) / total
        a.y = (a.y * a.caught + b.y * b.caught) / total
        if a.mapX and b.mapX and a.mapID == b.mapID then
            a.mapX = (a.mapX * a.caught + b.mapX * b.caught) / total
            a.mapY = (a.mapY * a.caught + b.mapY * b.caught) / total
        end
    end
    a.caught = total
    a.seconds = (a.seconds or 0) + (b.seconds or 0)
    for itemID, count in pairs(b.catches) do
        a.catches[itemID] = (a.catches[itemID] or 0) + count
    end
    for name, count in pairs(b.subzones) do
        a.subzones[name] = (a.subzones[name] or 0) + count
    end
    if b.lowestSkill and (not a.lowestSkill or b.lowestSkill < a.lowestSkill) then
        a.lowestSkill = b.lowestSkill
    end
    if b.getawaySkill and (not a.getawaySkill or b.getawaySkill > a.getawaySkill) then
        a.getawaySkill = b.getawaySkill
    end
    if b.needsSkill and (not a.needsSkill or b.needsSkill > a.needsSkill) then
        a.needsSkill = b.needsSkill
    end
    a.firstAt = math.min(a.firstAt or b.firstAt, b.firstAt or a.firstAt)
    a.lastAt = math.max(a.lastAt or 0, b.lastAt or 0)
end

-- Other books (trips, fish) point at spot IDs, so a merged-away ID is
-- rewritten to the one that absorbed it.
local function Repoint(book, fromID, toID)
    for _, fish in pairs(book.fish) do
        if fish.firstSpot == fromID then
            fish.firstSpot = toID
        end
    end
    for _, trip in ipairs(book.trips) do
        -- A trip that fished both spots would list the survivor twice.
        local had = tContains(trip.spots, toID)
        for index = #trip.spots, 1, -1 do
            if trip.spots[index] == fromID then
                if had then
                    table.remove(trip.spots, index)
                else
                    trip.spots[index] = toID
                    had = true
                end
            end
        end
    end
    local rarest = book.records.rarest
    if rarest and rarest.spotID == fromID then
        rarest.spotID = toID
    end
end

local function MergeNeighbours(book, id)
    local spot = book.spots[id]
    for otherID, other in pairs(book.spots) do
        if otherID ~= id and other.continent == spot.continent then
            if Distance(other, spot.x, spot.y) <= RADIUS then
                Merge(spot, other)
                book.spots[otherID] = nil
                Repoint(book, otherID, id)
            end
        end
    end
end

-- A new spot where the player stands, with nothing caught yet.
local function NewSpot(book, here, now)
    local id = book.nextSpot
    book.nextSpot = id + 1
    local spot = {
        continent = here.continent,
        x = here.x,
        y = here.y,
        mapID = here.mapID,
        mapX = here.mapX,
        mapY = here.mapY,
        zone = here.zone,
        subzones = {},
        catches = {},
        caught = 0,
        seconds = 0,
        firstAt = now,
    }
    book.spots[id] = spot
    return id, spot
end

-- The spot the player is at, made if there isn't one yet.
local function SpotHere()
    local here = Spots.Here()
    if not here then
        return nil
    end
    local id, spot = Spots.Current()
    if not spot then
        id, spot = NewSpot(ns.Book(), here, time())
    end
    return id, spot
end

--- Files a catch at the player's position.
---@param itemID number
---@param count number
---@return number|nil spotID
function Spots.Record(itemID, count)
    local here = Spots.Here()
    if not here then
        return nil
    end
    local book = ns.Book()
    local id, spot = Spots.Current()
    local now = time()

    if not spot then
        id, spot = NewSpot(book, here, now)
    else
        -- Move the centre a step toward this catch.
        local weight = spot.caught + count
        spot.x = (spot.x * spot.caught + here.x * count) / weight
        spot.y = (spot.y * spot.caught + here.y * count) / weight
        if here.mapX and spot.mapX and here.mapID == spot.mapID then
            spot.mapX = (spot.mapX * spot.caught + here.mapX * count) / weight
            spot.mapY = (spot.mapY * spot.caught + here.mapY * count) / weight
        end
    end

    spot.caught = spot.caught + count
    spot.catches[itemID] = (spot.catches[itemID] or 0) + count
    spot.subzones[here.subzone] = (spot.subzones[here.subzone] or 0) + count
    spot.lastAt = now

    local skill = ns.State.EffectiveSkill()
    if skill and (not spot.lowestSkill or skill < spot.lowestSkill) then
        spot.lowestSkill = skill
    end

    MergeNeighbours(book, id)
    return id
end

--- Notes a fish that got away at the player's position.
function Spots.RecordGetaway()
    local skill = ns.State.EffectiveSkill()
    if not skill then
        return
    end
    local _, spot = SpotHere()
    if spot and (not spot.getawaySkill or skill > spot.getawaySkill) then
        spot.getawaySkill = skill
    end
end

--- Notes the skill the game said this water needs.
---@param skill number
function Spots.RecordNeeded(skill)
    local _, spot = SpotHere()
    if spot and (not spot.needsSkill or skill > spot.needsSkill) then
        spot.needsSkill = skill
    end
end

-- Enough catches at a spot to say anything about it.
local SURE_AFTER = 10

--- How the player's skill compares with what this water has shown so far.
---@return string verdict  "safe", "risky" or "new"
---@return table|nil spot
---@return string|nil reason  for "risky": "needs" when the game said the
---                           water needs more skill, "getaway" otherwise
function Spots.Verdict()
    local _, spot = Spots.Current()
    local skill = ns.State.EffectiveSkill()
    if not spot or not skill then
        return "new", spot
    end
    if spot.needsSkill and skill < spot.needsSkill then
        return "risky", spot, "needs"
    end
    if spot.getawaySkill and skill <= spot.getawaySkill then
        return "risky", spot, "getaway"
    end
    if spot.caught >= SURE_AFTER then
        return "safe", spot
    end
    return "new", spot
end

--- What share of a spot's catches were this item, from 0 to 1.
---@param spot table
---@param itemID number
---@return number
function Spots.Share(spot, itemID)
    if not spot or spot.caught == 0 then
        return 0
    end
    return (spot.catches[itemID] or 0) / spot.caught
end
