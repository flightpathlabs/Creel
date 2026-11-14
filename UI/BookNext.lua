local _, ns = ...

-- The Next tab: where fishing goes from here. The rank you're on and how
-- the next one comes, who teaches it and roughly where they stand, waters
-- that suit your skill, and a short list of things worth doing now.
--
-- The facts live in Data/Progression.lua. Most come from guides rather
-- than the game, so places are "roughly here" and waters "a rough guide".
-- What the player has already done (a pole owned, a lure in the bags)
-- drops off the list.

local Kit = ns.Kit
local BookKit = ns.BookKit

local BookNext = {}
ns.BookNext = BookNext

local MARGIN = BookKit.MARGIN
local MUTED = Kit.MUTED

local LINE_GAP = 4
local PART_GAP = 10
local ROW_GAP = 8

-- A row in "Worth doing": the icon, then a name over a sentence.
local ICON = 32
local ICON_GAP = 10

-- Places from the player's own book: how many, and how many catch icons
-- each. A place counts once it has as many catches as the panel wants
-- before it calls a water safe.
local OWN_PLACES = 3
local PLACE_HEIGHT = 36
local PLACE_CATCHES = 4
local SURE_AFTER = 10

local CATCH_ICON = 28
local CATCH_GAP = 6

-- Cooking lines in "Worth doing", at most.
local COOKING_LINES = 2

-- Under this many yards the trainer is as good as here.
local NEARBY = 100

local MAIN_HAND = 16
local MINUTES_PER_DAY = 24 * 60
local MINUTES_PER_WEEK = 7 * MINUTES_PER_DAY

local ROUGHLY = "Roughly where guides say. Nobody has checked it in game yet."

local tab

local function Data()
    return ns.Progression or {}
end

local function Muted(text)
    return Kit.Colored(text, MUTED)
end

-- "a, b or c".
local function Either(list)
    if #list <= 1 then
        return list[1] or ""
    end
    return table.concat(list, ", ", 1, #list - 1) .. " or " .. list[#list]
end

-- "3 days and 4 hours", "2 hours and 10 minutes", "25 minutes".
local function Span(minutes)
    local days = math.floor(minutes / MINUTES_PER_DAY)
    local hours = math.floor(minutes % MINUTES_PER_DAY / 60)
    local rest = minutes % 60
    local function Join(big, small)
        return small and (big .. " and " .. small) or big
    end
    if days > 0 then
        return Join(
            BookKit.Plural(days, "day", "days"),
            hours > 0 and BookKit.Plural(hours, "hour", "hours")
        )
    elseif hours > 0 then
        return Join(
            BookKit.Plural(hours, "hour", "hours"),
            rest > 0 and BookKit.Plural(rest, "minute", "minutes")
        )
    end
    return BookKit.Plural(math.max(1, rest), "minute", "minutes")
end

--- How long until the Extravaganza, by the server's clock. The guides give
--- its time without saying which clock they mean, so this is a best guess,
--- and the page says "server time" rather than promising more.
---@return string|nil
local function ExtravaganzaWhen()
    local event = Data().extravaganza
    if not event or not (C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime) then
        return nil
    end
    local now = C_DateAndTime.GetCurrentCalendarTime()
    if not (now and now.weekday and now.hour and now.minute) then
        return nil
    end
    local nowAt = ((now.weekday - 1) * 24 + now.hour) * 60 + now.minute
    local startAt = ((event.weekday - 1) * 24 + event.hour) * 60
    local since = (nowAt - startAt) % MINUTES_PER_WEEK
    if since < event.minutes then
        return ("It's on now, for another %s."):format(Span(event.minutes - since))
    end
    return ("The next one starts in %s."):format(Span(MINUTES_PER_WEEK - since))
end

-- Who and what ---------------------------------------------------------------------

local function ForSide(entry, side)
    return not entry.side or entry.side == "Both" or entry.side == side
end

-- Whether the player has a pole anywhere: bags, bank or in the hand.
local function HasPole(itemID)
    if GetInventoryItemID("player", MAIN_HAND) == itemID then
        return true
    end
    return (C_Item.GetItemCount(itemID, true) or 0) > 0
end

-- Whether a lure is in the bags, where it can be put on the pole.
local function InBags(itemID)
    return (C_Item.GetItemCount(itemID, false) or 0) > 0
end

-- Whether the player has learned a spell: a profession recipe, here.
local function Knows(spellID)
    return C_SpellBook.IsSpellKnown(spellID) and true or false
end

-- The rank the game says the player is on, by its cap.
---@return number|nil index, table|nil rank
local function CurrentRank(maxRank)
    local ranks = Data().ranks or {}
    if not maxRank then
        return nil, nil
    end
    for index, rank in ipairs(ranks) do
        if maxRank <= rank.cap then
            return index, rank
        end
    end
    return #ranks, ranks[#ranks]
end

-- Where a trainer stands in the world, worked out once each. False for a
-- map the client doesn't know.
local worldAt = {}

local function WorldPosition(npc)
    if worldAt[npc] == nil then
        worldAt[npc] = false
        if C_Map.GetMapInfo(npc.uiMapID) then
            local continent, world =
                C_Map.GetWorldPosFromMapPos(npc.uiMapID, CreateVector2D(npc.x / 100, npc.y / 100))
            if continent and world then
                worldAt[npc] = { continent = continent, x = world.x, y = world.y }
            end
        end
    end
    return worldAt[npc] or nil
end

--- The closest of several people on the player's continent, and how far
--- away in yards. When none is, the first of them, with no distance.
local function Nearest(candidates)
    local here = ns.Spots.Here()
    local best, bestDistance
    for _, npc in ipairs(candidates) do
        local at = here and WorldPosition(npc)
        if at and at.continent == here.continent then
            local dx, dy = at.x - here.x, at.y - here.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if not bestDistance or distance < bestDistance then
                best, bestDistance = npc, distance
            end
        end
    end
    if best then
        return best, bestDistance
    end
    return candidates[1], nil
end

local function Trainers(side)
    local list = {}
    for _, trainer in ipairs(Data().trainers or {}) do
        if ForSide(trainer, side) then
            table.insert(list, trainer)
        end
    end
    return list
end

local function DistanceText(yards)
    if not yards then
        return nil
    elseif yards < NEARBY then
        return "close by"
    end
    return ("about %s yards away"):format(BreakUpLargeNumbers(math.floor(yards / 50 + 0.5) * 50))
end

--- Sets the game's own map pin on someone and opens the map there. Not in
--- combat, where the map can't be opened from here.
local function ShowOnMap(npc)
    if ns.InCombat() then
        UIErrorsFrame:AddExternalErrorMessage(ERR_NOT_IN_COMBAT)
        return
    end
    if
        UiMapPoint
        and C_Map.CanSetUserWaypointOnMap
        and C_Map.CanSetUserWaypointOnMap(npc.uiMapID)
    then
        local point = UiMapPoint.CreateFromCoordinates(npc.uiMapID, npc.x / 100, npc.y / 100)
        if
            C_Map.SetUserWaypoint(point)
            and C_SuperTrack
            and C_SuperTrack.SetSuperTrackedUserWaypoint
        then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
    end
    if OpenWorldMap then
        OpenWorldMap(npc.uiMapID)
    end
    -- Out of the way, so the map can be seen.
    if WorldMapFrame and WorldMapFrame:IsShown() then
        ns.BookWindow.Close()
    end
end

-- What to suggest -------------------------------------------------------------------

local function Fits(entry, skill, level, side)
    return skill >= (entry.minSkill or 0)
        and (not entry.maxSkill or skill <= entry.maxSkill)
        and level >= (entry.minLevel or 0)
        and ForSide(entry, side)
        and not (entry.knownSpell and Knows(entry.knownSpell))
end

local function LureBonus(itemID)
    local lure = ns.Lures and ns.Lures[itemID]
    return lure and lure.bonus or 0
end

-- The best pole the player has, and the best lure they have and can use.
local function BestOwned(skill)
    local pole = 0
    for _, entry in ipairs(Data().worth or {}) do
        if entry.kind == "pole" and HasPole(entry.itemID) then
            pole = math.max(pole, entry.bonus or 0)
        end
    end
    local lure = 0
    for itemID, info in pairs(ns.Lures or {}) do
        if (info.skill or 0) <= skill and InBags(itemID) then
            lure = math.max(lure, info.bonus or 0)
        end
    end
    return pole, lure
end

-- A recipe that takes one of a fish and nothing else, for each of the
-- waters' fish that has one.
local function CookingEntries(bracket)
    local list = {}
    for _, fishID in ipairs(bracket and bracket.catches or {}) do
        for _, use in ipairs((ns.Uses or {})[fishID] or {}) do
            if use.profession == "cooking" and use.needs == 1 and not use.others and use.makes then
                local fish = BookKit.Name(fishID) or "the raw fish"
                local text
                if use.learn then
                    text = ("Cook it from %s once your Cooking reaches %d."):format(fish, use.learn)
                else
                    text = ("Cook it from %s."):format(fish)
                end
                table.insert(list, { itemID = use.makes, text = text, fromID = fishID, use = use })
                break
            end
        end
        if #list >= COOKING_LINES then
            break
        end
    end
    return list
end

--- What's worth doing now, in the data's order, with the cooking last.
local function WorthDoing(skill, level, side, bracket)
    local entries = Data().worth or {}
    local bestPole, bestLure = BestOwned(skill)

    -- Of the lures, only the best that beats what's in the bags.
    local lure, lureBonus = nil, bestLure
    for _, entry in ipairs(entries) do
        if entry.kind == "lure" and Fits(entry, skill, level, side) then
            local bonus = LureBonus(entry.itemID)
            if bonus > lureBonus then
                lure, lureBonus = entry, bonus
            end
        end
    end

    local list = {}
    for _, entry in ipairs(entries) do
        if Fits(entry, skill, level, side) then
            if entry.kind == "pole" then
                if (entry.bonus or 0) > bestPole and not HasPole(entry.itemID) then
                    table.insert(list, entry)
                end
            elseif entry.kind == "lure" then
                if entry == lure then
                    table.insert(list, entry)
                end
            else
                table.insert(list, entry)
            end
        end
    end
    for _, entry in ipairs(CookingEntries(bracket)) do
        table.insert(list, entry)
    end
    return list
end

-- The skill bracket a skill falls in; the last one past the top.
local function BracketFor(skill)
    local brackets = Data().brackets or {}
    for _, bracket in ipairs(brackets) do
        if skill < (bracket.to or math.huge) then
            return bracket
        end
    end
    return brackets[#brackets]
end

--- Places in the book that have given plenty with nothing getting away at
--- this skill, the hardest water first.
local function OwnPlaces(skill)
    local list = {}
    if not skill then
        return list
    end
    for spotID, spot in pairs(ns.Book().spots) do
        local safe = not spot.getawaySkill or skill > spot.getawaySkill
        if
            spot.lowestSkill
            and spot.lowestSkill <= skill
            and (spot.caught or 0) >= SURE_AFTER
            and safe
        then
            table.insert(list, { id = spotID, spot = spot })
        end
    end
    table.sort(list, function(a, b)
        if a.spot.lowestSkill ~= b.spot.lowestSkill then
            return a.spot.lowestSkill > b.spot.lowestSkill
        end
        if a.spot.caught ~= b.spot.caught then
            return a.spot.caught > b.spot.caught
        end
        return a.id < b.id
    end)
    for index = #list, OWN_PLACES + 1, -1 do
        list[index] = nil
    end
    return list
end

-- Pieces -----------------------------------------------------------------------------

local function CreateCatchSlot(parent)
    local slot = BookKit.Slot(parent, CATCH_ICON)
    slot:SetScript("OnEnter", function(self)
        BookKit.ItemTooltip(self, self.itemID, "Click to see it in the collection.")
    end)
    slot:SetScript("OnLeave", GameTooltip_Hide)
    slot:SetScript("OnClick", function(self)
        ns.BookWindow.Open("collection", self.itemID)
    end)
    return slot
end

-- What the map link will do. Setting a pin takes the place of the
-- player's own, and of a tracked quest's arrow, so they're told first.
local function MapLinkLines(npc)
    if not (npc and UiMapPoint and C_Map.CanSetUserWaypointOnMap(npc.uiMapID)) then
        return { "Opens the map there. The game can't put a pin on that map.", ROUGHLY }
    end
    local lines = { "Puts a map pin there and opens the map.", ROUGHLY }
    if C_Map.HasUserWaypoint() then
        table.insert(lines, Kit.Colored("This replaces the pin you already have.", Kit.GOLD))
    end
    return lines
end

local function MapLink(parent, onClick, npcOf)
    local link = Kit.Link(parent, "Show on map", onClick)
    Kit.Tooltip(link, "Show on map", function()
        return MapLinkLines(npcOf())
    end)
    return link
end

-- The person to see: name, place and distance, and a map link.
local function CreatePerson(parent)
    local person = CreateFrame("Frame", nil, parent)
    person:SetHeight(PLACE_HEIGHT)

    person.name = Kit.Text(person, "GameFontHighlight")
    person.name:SetPoint("TOPLEFT", 0, -2)

    person.place = Kit.Text(person, "GameFontHighlightSmall")
    person.place:SetPoint("TOPLEFT", person.name, "BOTTOMLEFT", 0, -LINE_GAP)
    person.place:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

    person.map = MapLink(person, function()
        if person.npc then
            ShowOnMap(person.npc)
        end
    end, function()
        return person.npc
    end)
    person.map:SetPoint("RIGHT")
    return person
end

local function CreatePlaceRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(PLACE_HEIGHT)

    row.name = Kit.Text(row, "GameFontHighlight")
    row.name:SetPoint("TOPLEFT", 0, -2)

    row.line = Kit.Text(row, "GameFontHighlightSmall")
    row.line:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -LINE_GAP)
    row.line:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

    row.map = Kit.Link(row, "Show on map", function()
        BookKit.ShowOnMap(row.spotID)
    end)
    row.map:SetPoint("RIGHT")

    row.slots = {}
    for index = 1, PLACE_CATCHES do
        local slot = CreateCatchSlot(row)
        slot:SetPoint(
            "RIGHT",
            row.map,
            "LEFT",
            -12 - (PLACE_CATCHES - index) * (CATCH_ICON + CATCH_GAP),
            0
        )
        row.slots[index] = slot
    end

    row.name:SetPoint("RIGHT", row.slots[1], "LEFT", -10, 0)
    row.line:SetPoint("RIGHT", row.slots[1], "LEFT", -10, 0)
    return row
end

local function FillPlaceRow(row, entry)
    local spot = entry.spot
    row.spotID = entry.id
    row.name:SetText(ns.Spots.Name(spot))
    local zone = (spot.zone and spot.zone ~= "") and spot.zone or "Unknown waters"
    row.line:SetText(("%s · fished from skill %d"):format(zone, spot.lowestSkill))
    row.map:SetShown(spot.mapID ~= nil and spot.mapX ~= nil)

    -- The icons fill from the right, so a place with two catches has them
    -- beside the map link rather than in a gap.
    local top = BookKit.TopCatches(spot, PLACE_CATCHES)
    local first = PLACE_CATCHES - #top
    for index, slot in ipairs(row.slots) do
        local catch = top[index - first]
        slot:SetShown(catch ~= nil)
        if catch then
            BookKit.FillSlot(slot, catch.itemID, nil, true)
        end
    end
end

-- A row of icons for what a bracket's waters give.
local function CreateCatchStrip(parent)
    local strip = CreateFrame("Frame", nil, parent)
    strip:SetHeight(CATCH_ICON)
    strip.slots = BookKit.Pool(function()
        return CreateCatchSlot(strip)
    end)
    return strip
end

local function FillCatchStrip(strip, catches)
    strip.slots:Reset()
    for index, itemID in ipairs(catches) do
        local slot = strip.slots:Next()
        slot:ClearAllPoints()
        slot:SetPoint("LEFT", (index - 1) * (CATCH_ICON + CATCH_GAP), 0)
        BookKit.FillSlot(slot, itemID, nil, true)
    end
    strip.slots:HideRest()
end

-- A row that's a recipe opens the recipe card. Only those rows take the
-- mouse, so only they light up under it.
local function OpenRecipe(row)
    if row.use and ns.RecipeCard then
        ns.RecipeCard.Show(row.fromID, row.use, row)
    end
end

local CLICK_RECIPE = "Click for how to make it and what it costs."

local function CreateWorthRow(parent)
    local row = CreateFrame("Button", nil, parent)
    Kit.DressRow(row)
    row:SetScript("OnEnter", function(self)
        BookKit.ItemTooltip(self, self.itemID, CLICK_RECIPE)
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", OpenRecipe)

    row.slot = BookKit.Slot(row, ICON)
    row.slot:SetPoint("TOPLEFT")
    row.slot:SetScript("OnEnter", function(self)
        BookKit.ItemTooltip(self, self.itemID, row.use and CLICK_RECIPE or nil)
    end)
    row.slot:SetScript("OnLeave", GameTooltip_Hide)
    row.slot:SetScript("OnClick", function()
        OpenRecipe(row)
    end)

    row.title = Kit.Text(row, "GameFontHighlight")
    row.title:SetPoint("TOPLEFT", row.slot, "TOPRIGHT", ICON_GAP, -1)

    row.text = Kit.Paragraph(row, "GameFontHighlightSmall")
    row.text:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -LINE_GAP)
    row.text:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    return row
end

local function FillWorthRow(row, width, entry)
    BookKit.FillSlot(row.slot, entry.itemID, nil, true)
    row.itemID = entry.itemID
    row.fromID = entry.fromID
    row.use = entry.use
    row:EnableMouse(entry.use ~= nil)

    local title = entry.title or BookKit.ColoredName(entry.itemID)
    if entry.where then
        title = title .. Muted(" · " .. entry.where)
    end
    local text = entry.text
    if entry.kind == "event" then
        local when = ExtravaganzaWhen()
        if when then
            text = text .. " " .. Kit.Colored(when, Kit.GOLD)
        end
    end

    local words = width - ICON - ICON_GAP
    row.title:SetWidth(words)
    row.title:SetText(title)
    row.text:SetWidth(words)
    row.text:SetText(text)
    row:SetHeight(
        math.max(ICON, 1 + row.title:GetStringHeight() + LINE_GAP + row.text:GetStringHeight())
    )
end

-- The sections ------------------------------------------------------------------------

-- Your next step: the rank, what comes next, and what's still to do.
-- Hands back the rank that comes next, if there is one.
local function FillStep(layout, skill, level)
    local section = tab.step
    local inside = Kit.Inside(layout, section)
    local ranks = Data().ranks or {}
    local maxRank = ns.State.maxRank
    local index, rank = CurrentRank(maxRank)

    local status, how, needs
    local nextRank
    if not rank then
        nextRank = ranks[1]
        status = "You haven't learned Fishing yet."
        how = nextRank and nextRank.text or ""
        needs = Kit.Colored("Ready when you are.", Kit.GOLD)
    elseif index >= #ranks then
        status = ("%s Fishing, skill %d of %d."):format(rank.name, skill, maxRank)
        if skill < maxRank then
            how = "That's the last rank. All that's left is the skill points."
            needs = BookKit.Plural(maxRank - skill, "more point", "more points") .. " to go."
        else
            how = "That's as far as Fishing goes. Time to try your luck at the Stranglethorn"
                .. " Fishing Extravaganza, Sundays from 2 to 4 pm server time."
            needs = ExtravaganzaWhen()
            needs = needs and Kit.Colored(needs, Kit.GOLD)
        end
    else
        nextRank = ranks[index + 1]
        status = ("%s Fishing, skill %d of %d."):format(rank.name, skill, maxRank)
        how = ("Next is %s, which lifts the cap to %d. %s"):format(
            nextRank.name,
            nextRank.cap,
            nextRank.text
        )

        local missing = {}
        local points = (nextRank.skill or 0) - skill
        if points > 0 then
            table.insert(missing, BookKit.Plural(points, "more skill point", "more skill points"))
        end
        if nextRank.level and level < nextRank.level then
            table.insert(missing, ("level %d"):format(nextRank.level))
        end
        if #missing > 0 then
            needs = "Still needed: " .. table.concat(missing, " and ") .. "."
        else
            local ready = "You're ready for it now."
            if nextRank.cost then
                ready = ready .. " The book costs " .. ns.Money(nextRank.cost) .. "."
            end
            needs = Kit.Colored(ready, Kit.GOLD)
        end
    end

    Kit.PlaceText(inside, section.status, 0, status)
    Kit.PlaceText(inside, section.how, LINE_GAP, how)
    section.needs:SetShown(needs ~= nil)
    if needs then
        Kit.PlaceText(inside, section.needs, LINE_GAP, needs)
    end
    Kit.PlaceSection(layout, section, inside)
    return nextRank
end

-- Who teaches the next rank: the nearest trainer, or the one person who
-- has the book or the quest.
local function FillPerson(layout, nextRank, side)
    local section = tab.person
    section:SetShown(nextRank ~= nil)
    if not nextRank then
        return
    end

    local npc, yards
    if nextRank.npc then
        local only = (Data().npcs or {})[nextRank.npc]
        if only then
            npc, yards = Nearest({ only })
        end
        section.title:SetText(
            nextRank.how == "book" and "Who sells the book" or "Who gives the quest"
        )
    else
        npc, yards = Nearest(Trainers(side))
        section.title:SetText("Nearest fishing trainer")
    end
    if not npc then
        section:Hide()
        return
    end

    local inside = Kit.Inside(layout, section)
    local person = section.person
    person.npc = npc
    person.name:SetText(npc.name)
    local where = npc.place
    local distance = DistanceText(yards)
    if distance then
        where = where .. " · " .. distance
    end
    person.place:SetText(where)
    Kit.Place(inside, person, 0)
    Kit.PlaceSection(layout, section, inside)
end

local function FillWaters(layout, effective, side)
    local section = tab.waters
    local inside = Kit.Inside(layout, section)
    local gap = 0

    local own = OwnPlaces(effective)
    section.ownLabel:SetShown(#own > 0)
    section.places:Reset()
    if #own > 0 then
        Kit.PlaceText(
            inside,
            section.ownLabel,
            0,
            "Your own places where nothing has got away at your skill"
        )
        for index, entry in ipairs(own) do
            local row = section.places:Next()
            FillPlaceRow(row, entry)
            Kit.Place(inside, row, index == 1 and LINE_GAP or 2)
        end
        gap = PART_GAP
    end
    section.places:HideRest()

    local bracket = BracketFor(effective or 0)
    local shown = bracket ~= nil
    section.bracketLabel:SetShown(shown)
    section.list:SetShown(shown)
    section.note:SetShown(shown and bracket.note ~= nil)
    section.strip:SetShown(shown)
    if shown then
        local range = bracket.to and ("skill %d to %d"):format(bracket.from, bracket.to)
            or ("skill %d and up"):format(bracket.from)
        Kit.PlaceText(
            inside,
            section.bracketLabel,
            gap,
            ("Waters for %s, as a rough guide"):format(range)
        )

        local names = {}
        for _, name in ipairs(bracket.waters[side] or {}) do
            table.insert(names, name)
        end
        for _, name in ipairs(bracket.waters.Both or {}) do
            table.insert(names, name)
        end
        local words = "Try " .. Either(names) .. "."
        if bracket.later then
            words = words .. " Further on: " .. Either(bracket.later) .. "."
        end
        Kit.PlaceText(inside, section.list, LINE_GAP, words)
        if bracket.note then
            Kit.PlaceText(inside, section.note, LINE_GAP, bracket.note)
        end

        FillCatchStrip(section.strip, bracket.catches or {})
        Kit.Place(inside, section.strip, LINE_GAP + 2, CATCH_ICON)
    end
    Kit.PlaceSection(layout, section, inside)
    return bracket
end

local function FillWorth(layout, skill, level, side, bracket)
    local section = tab.worth
    local inside = Kit.Inside(layout, section)
    local list = WorthDoing(skill, level, side, bracket)

    -- The rows are refilled in place, so a recipe card opened from one
    -- would end up beside something else. It stays only if its row still
    -- shows the same recipe.
    local owner = ns.RecipeCard and ns.RecipeCard.Owner()
    local before = owner and owner.use

    section.rows:Reset()
    for index, entry in ipairs(list) do
        local row = section.rows:Next()
        FillWorthRow(row, inside.width, entry)
        Kit.Place(inside, row, index == 1 and 0 or ROW_GAP)
    end
    section.rows:HideRest()
    if owner and (owner.use ~= before or not owner:IsShown()) then
        ns.RecipeCard.HideFrom(section)
    end

    section.nothing:SetShown(#list == 0)
    if #list == 0 then
        Kit.PlaceText(inside, section.nothing, 0, "Nothing more to suggest for now. Happy fishing!")
    end
    Kit.PlaceSection(layout, section, inside)
end

local function Refresh()
    local skill = ns.State.rank or 0
    local effective = ns.State.EffectiveSkill() or skill
    local level = UnitLevel("player") or 1
    local side = UnitFactionGroup("player")

    local width = tab.scroll:GetWidth()
    tab.page:SetWidth(width)
    local layout = { frame = tab.page, left = 0, width = width, y = 0 }

    local nextRank = FillStep(layout, skill, level)
    FillPerson(layout, nextRank, side)
    local bracket = FillWaters(layout, effective, side)
    FillWorth(layout, skill, level, side, bracket)

    tab.page:SetHeight(layout.y + Kit.SECTION_GAP)
end

-- Several things change together (a stack of fish lands, a level comes
-- with a new zone), so a redraw waits a moment and happens once.
local pending = false
local function RefreshSoon()
    if pending or not (tab and tab:IsVisible()) then
        return
    end
    pending = true
    C_Timer.After(0.5, function()
        pending = false
        if tab:IsVisible() then
            Refresh()
        end
    end)
end

local function MutedParagraph(parent)
    local text = Kit.Paragraph(parent, "GameFontHighlightSmall")
    text:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    return text
end

---@param parent table  the window's inset, which the tab fills
function BookNext.Create(parent)
    tab = CreateFrame("Frame", nil, parent)
    tab:SetAllPoints()

    tab.scroll, tab.page = BookKit.ScrollArea(tab)
    tab.scroll:SetPoint("TOPLEFT", MARGIN, -MARGIN)
    tab.scroll:SetPoint("BOTTOMRIGHT", -BookKit.SCROLL_BAR_ROOM, MARGIN)

    local step = Kit.Section(tab.page, "Your next step")
    step.status = Kit.Paragraph(step, "GameFontNormal")
    step.how = Kit.Paragraph(step, "GameFontHighlight")
    step.needs = Kit.Paragraph(step, "GameFontHighlight")
    tab.step = step

    local person = Kit.Section(tab.page, "Nearest fishing trainer")
    person.person = CreatePerson(person)
    tab.person = person

    local waters = Kit.Section(tab.page, "Where to fish")
    waters.ownLabel = MutedParagraph(waters)
    waters.places = BookKit.Pool(function()
        return CreatePlaceRow(waters)
    end)
    waters.bracketLabel = MutedParagraph(waters)
    waters.list = Kit.Paragraph(waters, "GameFontHighlight")
    waters.note = MutedParagraph(waters)
    waters.strip = CreateCatchStrip(waters)
    tab.waters = waters

    local worth = Kit.Section(tab.page, "Worth doing now")
    worth.rows = BookKit.Pool(function()
        return CreateWorthRow(worth)
    end)
    worth.nothing = MutedParagraph(worth)
    tab.worth = worth

    -- A recipe card opened from this page goes when the page does.
    tab:SetScript("OnHide", function(self)
        if ns.RecipeCard then
            ns.RecipeCard.HideFrom(self)
        end
    end)

    tab.Refresh = Refresh
    return tab
end

-- The page follows the skill, the bags (a new pole, a lure used up), the
-- player's level and where they are, while it's open.
ns.Listen("SKILL_CHANGED", RefreshSoon)
ns.OnEvent("BAG_UPDATE_DELAYED", RefreshSoon)
ns.OnEvent("ZONE_CHANGED_NEW_AREA", RefreshSoon)
ns.OnEvent("PLAYER_LEVEL_UP", RefreshSoon)
