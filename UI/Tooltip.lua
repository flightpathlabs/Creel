local _, ns = ...

-- One line on the tooltip of anything you've caught: how many, and the
-- water that has given you the most of it.
--
--   Creel: caught 214 · best at Lake Everstill
--
-- It goes through the game's own tooltip processor, which every item
-- tooltip passes through, so bags, the bank, the auction house and links
-- in chat all get it without hooking any of them. The setting turns it
-- off for players whose other addons already add catch counts.

local MUTED = ns.Kit.MUTED

-- The best spot for each item, worked out once and forgotten whenever a
-- catch could change it. False means no spot has any.
local bestSpots = {}

local function BestSpotName(itemID)
    if bestSpots[itemID] == nil then
        local best, most = nil, 0
        for _, spot in pairs(ns.Book().spots) do
            local count = spot.catches and spot.catches[itemID] or 0
            if count > most then
                best, most = spot, count
            end
        end
        bestSpots[itemID] = best and ns.Spots.Name(best) or false
    end
    return bestSpots[itemID] or nil
end

local function AddCatchLine(tooltip, data)
    if not ns.db or not ns.settings.tooltipLine then
        return
    end
    local itemID = data and ns.Readable(data.id)
    if type(itemID) ~= "number" then
        return
    end
    local fish = ns.Book().fish[itemID]
    if not fish or (fish.caught or 0) == 0 then
        return
    end

    local text = ("Creel: caught %d"):format(fish.caught)
    local where = BestSpotName(itemID)
    if where then
        text = ("%s · best at %s"):format(text, where)
    end
    tooltip:AddLine(text, MUTED[1], MUTED[2], MUTED[3])
end

local function Forget()
    wipe(bestSpots)
end

ns.Listen("CATCH", Forget)
ns.Listen("BOOK_CHANGED", Forget)

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddCatchLine)
end
