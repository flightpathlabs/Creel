local _, ns = ...

-- The line of tip or trivia under each catch.
--
-- Three kinds, mixed so the line doesn't wear thin: what the catch turns
-- into, worked out from the recipe data and today's prices; a hand-written
-- fact from Data/Tips.lua; and the game's own flavour text, for the few
-- catches that have any. Nothing is copied from anywhere; the flavour text
-- is read from the client as it's shown, never shipped.

local Trivia = {}
ns.Trivia = Trivia

local PROFESSION_WORDS = {
    cooking = "Cooking",
    alchemy = "Alchemy",
    fishing = "Fishing",
    enchanting = "Enchanting",
    tailoring = "Tailoring",
    leatherworking = "Leatherworking",
}

local NUMBER_WORDS = { "One", "Two", "Three", "Four", "Five" }

local function Name(itemID)
    local name = C_Item.GetItemNameByID(itemID)
    if not name then
        C_Item.RequestLoadItemDataByID(itemID)
    end
    return name
end

-- "at Cooking 175", where a recipe item says so; trainers keep their
-- levels on the server, so those recipes just name the profession.
local function AtSkill(profession, use)
    if use.learn then
        return ("%s %d"):format(profession, use.learn)
    end
    return profession .. ", from a trainer"
end

-- "Cooks into Rockscale Cod (Cooking 175). Worth about 9s made, against 6s
-- for what goes in." The comparison is the recipe card's sum, and only
-- appears when every part has a price and the two differ enough to say.
local function FromUse(itemID, use)
    local makes = Name(use.makes)
    if not makes then
        return nil
    end
    local profession = PROFESSION_WORDS[use.profession] or use.profession
    local text
    if (use.needs or 1) > 1 then
        local count = NUMBER_WORDS[use.needs] or tostring(use.needs)
        text = ("%s make %s %s (%s)."):format(
            count,
            use.count > 1 and use.count or "a",
            makes,
            AtSkill(profession, use)
        )
    elseif use.profession == "cooking" then
        text = ("Cooks into %s (%s)."):format(makes, AtSkill(profession, use))
    else
        text = ("%s turns it into %s (%s)."):format(profession, makes, AtSkill(profession, use))
    end

    local cost, made, complete = ns.Values.RecipeWorth(itemID, use)
    if complete and made and cost > 0 and math.abs(made - cost) / cost >= 0.15 then
        text = text
            .. (" Worth about %s made, against %s for what goes in."):format(
                ns.Money(made),
                ns.Money(cost)
            )
    end
    if use.forever then
        text = text .. " A recipe new to Forever."
    end
    return text
end

local function Flavour(itemID)
    local description = select(18, C_Item.GetItemInfo(itemID))
    description = ns.Readable(description)
    if description and description ~= "" then
        return '"' .. description .. '"'
    end
    return nil
end

--- Every line that could be said about a catch.
---@param itemID number
---@return table
function Trivia.Lines(itemID)
    local lines = {}
    for _, use in ipairs(ns.Uses and ns.Uses[itemID] or {}) do
        local line = FromUse(itemID, use)
        if line then
            table.insert(lines, line)
        end
    end
    for _, line in ipairs(ns.Tips and ns.Tips[itemID] or {}) do
        table.insert(lines, line)
    end
    local flavour = Flavour(itemID)
    if flavour then
        table.insert(lines, flavour)
    end
    return lines
end

local lastShown = {}

--- One line for the catch card, different from last time where possible.
--- A catch that would still teach the player Cooking says so every other
--- time, so the hint isn't lost in the mix but doesn't crowd it out.
---@param itemID number
---@return string|nil
function Trivia.Pick(itemID)
    local cooking = ns.Cooking and ns.Cooking.TipFor(itemID)
    if cooking and lastShown[itemID] ~= cooking then
        lastShown[itemID] = cooking
        return cooking
    end
    local lines = Trivia.Lines(itemID)
    if #lines == 0 then
        return nil
    end
    local index = math.random(#lines)
    if #lines > 1 and lines[index] == lastShown[itemID] then
        index = index % #lines + 1
    end
    lastShown[itemID] = lines[index]
    return lines[index]
end
