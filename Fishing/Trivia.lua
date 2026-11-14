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

-- The worth of one: auction if known, vendor otherwise.
local function Worth(itemID)
    local auction = ns.Values.Auction(itemID)
    return auction or ns.Values.Vendor(itemID)
end

-- "Cooks into Rockscale Cod at Cooking 175. Sells for about 9s cooked
-- against 6s raw." The comparison only appears when both prices are known
-- and they differ enough to be worth saying.
local function FromUse(itemID, use)
    local makes = Name(use.makes)
    if not makes then
        return nil
    end
    local profession = PROFESSION_WORDS[use.profession] or use.profession
    local text
    if (use.needs or 1) > 1 then
        local count = NUMBER_WORDS[use.needs] or tostring(use.needs)
        text = ("%s make %s %s (%s %d)."):format(
            count,
            use.count > 1 and use.count or "a",
            makes,
            profession,
            use.learn or use.yellow or 1
        )
    elseif use.profession == "cooking" then
        text = ("Cooks into %s at Cooking %d."):format(makes, use.learn or use.yellow or 1)
    else
        text = ("%s turns it into %s (%d)."):format(profession, makes, use.learn or use.yellow or 1)
    end

    local raw = Worth(itemID)
    local made = Worth(use.makes)
    if raw and made and raw > 0 then
        local cooked = made * (use.count or 1) / (use.needs or 1)
        if math.abs(cooked - raw) / raw >= 0.15 then
            text = text
                .. (" Worth about %s made, against %s raw."):format(ns.Money(cooked), ns.Money(raw))
        end
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
---@param itemID number
---@return string|nil
function Trivia.Pick(itemID)
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
