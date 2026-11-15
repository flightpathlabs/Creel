local _, ns = ...

-- Cooking from catches: which catches still teach the player Cooking at
-- their skill, and what it takes to learn the recipe. The Fishing Book's
-- Next page lists the best of them, and the catch card mentions it when a
-- catch is one.
--
-- Recipe levels come from Data/Uses.lua and recipe items from
-- Data/Shop.lua, both from the game's own tables. Who sells each recipe
-- comes from guides (Data/Progression.lua), so places are rough.

local Cooking = {}
ns.Cooking = Cooking

-- Clams are fished up and opened; it's the meat inside that's cooked.
local FROM_CLAMS = {
    [5503] = true, -- Clam Meat
    [5504] = true, -- Tangy Clam Meat
    [7974] = true, -- Zesty Clam Meat
}

-- A recipe a trainer teaches doesn't say what skill it's learned at; the
-- server keeps that. Most recipes of the era turn yellow 40 points after
-- they can be learned, so that's the guess.
local ORANGE_SPAN = 40

-- How the game colours a recipe against the player's skill, and how much
-- each colour is worth: orange always gives a point, yellow usually and
-- green now and then.
Cooking.COLOURS = {
    orange = { 1, 0.5, 0.25 },
    yellow = { 1, 1, 0 },
    green = { 0.25, 0.75, 0.25 },
}
local WORTH = { orange = 3, yellow = 2, green = 1 }

-- The Cooking window's own word on which recipes this character knows,
-- kept from the last time it was open. C_SpellBook.IsSpellKnown should
-- answer for recipes too, but nothing in the client's code proves it for
-- this one, so the window's list backs it up.
local function Listed()
    if not ns.db then
        return {}
    end
    local me = ns.Me()
    me.recipes = me.recipes or {}
    return me.recipes
end

-- The Cooking profession's base skill line.
local COOKING_LINE = 185

--- The player's Cooking: rank and cap. Nil when they haven't learned it.
---@return number|nil rank, number|nil maxRank
function Cooking.Skill()
    local index = select(5, GetProfessions())
    if not index then
        return nil
    end
    local _, _, rank, maxRank = GetProfessionInfo(index)
    return rank, maxRank
end

--- Whether the player knows a cooking recipe.
---@param spellID number
---@return boolean
function Cooking.Knows(spellID)
    if Listed()[spellID] then
        return true
    end
    return C_SpellBook.IsSpellKnown(spellID) and true or false
end

--- The skill a recipe is learned at, or a fair guess for a trainer's.
---@param use table  an entry from Data/Uses.lua
---@return number
function Cooking.LearnAt(use)
    return use.learn or math.max(1, use.yellow - ORANGE_SPAN)
end

--- The recipe's colour at a skill: "orange", "yellow", "green" or "grey".
---@param use table
---@param rank number
---@return string
function Cooking.Colour(use, rank)
    if rank >= use.grey then
        return "grey"
    elseif rank >= math.floor((use.yellow + use.grey) / 2) then
        return "green"
    elseif rank >= use.yellow then
        return "yellow"
    end
    return "orange"
end

--- The colour's name, in its colour.
---@param colour string
---@return string
function Cooking.ColourText(colour)
    local rgb = Cooking.COLOURS[colour]
    return rgb and ns.Kit.Colored(colour, rgb) or colour
end

--- Whether an item is something the player catches, or the meat out of
--- one: what the cooking tips are about.
---@param itemID number
---@return boolean
function Cooking.IsCatch(itemID)
    return (ns.Catches and ns.Catches[itemID] ~= nil) or FROM_CLAMS[itemID] == true
end

--- Whether an item comes out of clams rather than off the line.
---@param itemID number
---@return boolean
function Cooking.FromClams(itemID)
    return FROM_CLAMS[itemID] == true
end

-- The fishing skill a catch starts biting at, from the Next page's
-- brackets: the lowest bracket that lists it.
local function BitesFrom(itemID)
    local lowest
    for _, bracket in ipairs(ns.Progression and ns.Progression.brackets or {}) do
        for _, id in ipairs(bracket.catches or {}) do
            if id == itemID and (not lowest or bracket.from < lowest) then
                lowest = bracket.from
            end
        end
    end
    return lowest
end
Cooking.BitesFrom = BitesFrom

--- Every cooking recipe that takes a catch and still gives points at a
--- skill, best first, one per recipe. Each is { fromID, use, colour,
--- known, reach }: reach is "caught" when the player's book has the
--- catch, "now" when it bites at their fishing skill, else "later".
--- Also hands back the next recipe to come within reach, if any.
---@param rank number          Cooking
---@param fishing number|nil   effective Fishing skill
---@param book table           the book whose catches count
---@return table list, table|nil coming  coming = { fromID, use, at }
function Cooking.Suggestions(rank, fishing, book)
    local bySpell = {}
    local coming
    for fromID, uses in pairs(ns.Uses or {}) do
        if Cooking.IsCatch(fromID) then
            for _, use in ipairs(uses) do
                if use.profession == "cooking" and rank < use.grey then
                    local at = Cooking.LearnAt(use)
                    if rank < at then
                        if not coming or at < coming.at then
                            coming = { fromID = fromID, use = use, at = at }
                        end
                    else
                        local reach
                        if book.fish and book.fish[fromID] then
                            reach = "caught"
                        else
                            local from = BitesFrom(fromID)
                            reach = (from and fishing and fishing >= from) and "now" or "later"
                        end
                        local entry = {
                            fromID = fromID,
                            use = use,
                            colour = Cooking.Colour(use, rank),
                            known = Cooking.Knows(use.spell),
                            reach = reach,
                        }
                        -- A recipe that takes two catches is listed once,
                        -- under the one closer to hand.
                        local before = bySpell[use.spell]
                        if not before or (reach ~= "later" and before.reach == "later") then
                            bySpell[use.spell] = entry
                        end
                    end
                end
            end
        end
    end

    local list = {}
    for _, entry in pairs(bySpell) do
        table.insert(list, entry)
    end
    local reachOrder = { caught = 1, now = 1, later = 2 }
    table.sort(list, function(a, b)
        if reachOrder[a.reach] ~= reachOrder[b.reach] then
            return reachOrder[a.reach] < reachOrder[b.reach]
        end
        if WORTH[a.colour] ~= WORTH[b.colour] then
            return WORTH[a.colour] > WORTH[b.colour]
        end
        if a.known ~= b.known then
            return a.known
        end
        -- Fewer other things to buy or find first.
        local aOthers, bOthers = a.use.others ~= nil, b.use.others ~= nil
        if aOthers ~= bOthers then
            return bOthers
        end
        return a.use.spell < b.use.spell
    end)
    return list, coming
end

--- The line for the catch card when a catch still teaches Cooking at the
--- player's skill, or nil.
---@param itemID number
---@return string|nil
function Cooking.TipFor(itemID)
    local rank, maxRank = ns.ShownCooking()
    if not rank or (maxRank and rank >= maxRank) then
        return nil
    end
    local best, bestColour
    for _, use in ipairs(ns.Uses and ns.Uses[itemID] or {}) do
        if use.profession == "cooking" and rank >= Cooking.LearnAt(use) then
            local colour = Cooking.Colour(use, rank)
            if WORTH[colour] and (not best or WORTH[colour] > WORTH[bestColour]) then
                best, bestColour = use, colour
            end
        end
    end
    if not best then
        return nil
    end
    local makes = C_Item.GetItemNameByID(best.makes)
    if not makes then
        C_Item.RequestLoadItemDataByID(best.makes)
        return nil
    end
    local colour = Cooking.ColourText(bestColour)
    if Cooking.Knows(best.spell) then
        return ("Good for your Cooking: %s is %s at your %d."):format(makes, colour, rank)
    end

    local line = ("Good for your Cooking: %s would be %s at your %d."):format(makes, colour, rank)
    local recipe = ns.RecipeItems and ns.RecipeItems[best.spell]
    if not recipe then
        return line .. " A cooking trainer teaches it."
    elseif #Cooking.Vendors(best.spell, UnitFactionGroup("player")) > 0 then
        local price = recipe.price > 0 and (" sells for %s and"):format(ns.Money(recipe.price))
            or ""
        return line .. (" The recipe%s is on the book's Next page."):format(price)
    end
    return line
end

--- Who the guides say sells a cooking recipe, on one side.
---@param spellID number
---@param side string|nil  "Alliance" or "Horde"
---@return table vendors   empty when none is known there
function Cooking.Vendors(spellID, side)
    local entry = ns.Progression
        and ns.Progression.cookingRecipes
        and ns.Progression.cookingRecipes[spellID]
    local list = {}
    for _, vendor in ipairs(entry and entry.vendors or {}) do
        if not vendor.side or vendor.side == "Both" or vendor.side == side then
            table.insert(list, vendor)
        end
    end
    return list
end

--- Whether the guides name a vendor for a cooking recipe on either side.
---@param spellID number
---@return boolean
function Cooking.SoldAnywhere(spellID)
    local entry = ns.Progression
        and ns.Progression.cookingRecipes
        and ns.Progression.cookingRecipes[spellID]
    return entry ~= nil and entry.vendors ~= nil and #entry.vendors > 0
end

-- Reading the Cooking window -------------------------------------------------------

-- Every cooking recipe Creel might suggest.
local function OurRecipes()
    local spells = {}
    for fromID, uses in pairs(ns.Uses or {}) do
        if Cooking.IsCatch(fromID) then
            for _, use in ipairs(uses) do
                if use.profession == "cooking" then
                    spells[use.spell] = true
                end
            end
        end
    end
    return spells
end

local function CookingIsOpen()
    local info = C_TradeSkillUI.GetBaseProfessionInfo()
    return info ~= nil and info.professionID == COOKING_LINE
end

-- The window lists its recipes on the first update after it opens, not
-- when it opens, and an update while its data is still changing over is
-- only half done.
local reading = false

ns.OnEvent("TRADE_SKILL_SHOW", function()
    reading = true
end)

ns.OnEvent("TRADE_SKILL_LIST_UPDATE", function()
    if not reading or C_TradeSkillUI.IsDataSourceChanging() then
        return
    end
    reading = false
    -- A crafter's window opened from a chat link or the guild list is
    -- someone else's recipes.
    local tradeSkill = C_TradeSkillUI
    if
        (tradeSkill.IsTradeSkillLinked and tradeSkill.IsTradeSkillLinked())
        or (tradeSkill.IsTradeSkillGuild and tradeSkill.IsTradeSkillGuild())
        or (tradeSkill.IsTradeSkillGuildMember and tradeSkill.IsTradeSkillGuildMember())
    then
        return
    end
    if not CookingIsOpen() then
        return
    end
    local listed = Listed()
    for spellID in pairs(OurRecipes()) do
        local info = C_TradeSkillUI.GetRecipeInfo(spellID)
        if info then
            listed[spellID] = info.learned and true or nil
        end
    end
    ns.Send("RECIPES_CHANGED")
end)

ns.OnEvent("NEW_RECIPE_LEARNED", function(recipeID)
    recipeID = ns.Readable(recipeID)
    if recipeID and OurRecipes()[recipeID] then
        Listed()[recipeID] = true
        ns.Send("RECIPES_CHANGED")
    end
end)
