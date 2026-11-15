local _, ns = ...

-- Catch spots on the world map.
--
-- With the setting on, every place in the book gets a pin on its own zone
-- map, and on the continent above it, sized a little by how much has been
-- caught there. The pin's tooltip names the place and its top catches;
-- clicking it opens the book at that place. With the setting off, the map
-- only shows a pin for a moment when the book asks for one ("Show on
-- map").
--
-- This is a data provider like the game's own (Blizzard_MapCanvas). The
-- pins are our own frames rather than ones from the map's pin pools: the
-- pools are made from XML templates, which a Lua-only addon doesn't have,
-- and writing our own pool into the map's table of them would leave our
-- fingerprints on it. The pins borrow the game's pin behaviour
-- (MapCanvasPinMixin) for their place, size and frame level.

local Kit = ns.Kit
local BookKit = ns.BookKit

local MapPins = {}
ns.MapPins = MapPins

-- The profession icon the game's own world quests use for fishing.
local PIN_ATLAS = "worldquest-icon-fishing"
local PIN_FALLBACK = "Interface\\Icons\\Trade_Fishing"
local GLOW_ATLAS = "ui-questpoi-outerglow"

-- A pin is this size at one catch, growing with each tenfold more, to a
-- limit. The glow round a pin being pointed out is this much bigger.
local SMALLEST = 16
local GROWTH = 3.5
local LARGEST = 26
local GLOW_SCALE = 2.2

-- On screen, pins keep about the same size as the map zooms, a little
-- larger zoomed in (see MapCanvasPinMixin:SetScalingLimits).
local SCALE_FACTOR = 1
local SCALE_ZOOMED_OUT = 0.85
local SCALE_ZOOMED_IN = 1.1

-- How long a pin asked for by the book stands out.
local POINTED_SECONDS = 10

-- The game's frame level for archaeology dig sites, which sit low among
-- the map's pins, under quests and flight points.
local FRAME_LEVEL = "PIN_FRAME_LEVEL_DIG_SITE"

local provider = CreateFromMixins(MapCanvasDataProviderMixin)
local pins = {}
local used = 0

-- The spot the book last asked to show, and until when.
local pointed

-- Where pins go ------------------------------------------------------------------

-- Whether a map is the continent a zone map belongs to, worked out once
-- per pair.
local continentOf = {}

local function IsContinentOf(mapID, zoneMapID)
    local key = mapID .. ":" .. zoneMapID
    if continentOf[key] == nil then
        local found = false
        local info = C_Map.GetMapInfo(mapID)
        if info and info.mapType == Enum.UIMapType.Continent then
            local step = C_Map.GetMapInfo(zoneMapID)
            -- Zone maps sit a level or two under their continent.
            for _ = 1, 5 do
                if not step or not step.parentMapID or step.parentMapID == 0 then
                    break
                end
                if step.parentMapID == mapID then
                    found = true
                    break
                end
                step = C_Map.GetMapInfo(step.parentMapID)
            end
        end
        continentOf[key] = found
    end
    return continentOf[key]
end

--- Where a spot goes on a map, from 0 to 1 each way, if it belongs there.
local function Position(spot, mapID)
    if not spot.mapX or not spot.mapY then
        return nil
    end
    if spot.mapID == mapID then
        return spot.mapX, spot.mapY
    end

    -- Inside an instance the spot has no world position to work from.
    if
        type(spot.continent) ~= "number"
        or not spot.mapID
        or not IsContinentOf(mapID, spot.mapID)
    then
        return nil
    end
    local _, position =
        C_Map.GetMapPosFromWorldPos(spot.continent, CreateVector2D(spot.x, spot.y), mapID)
    if position and position.x >= 0 and position.x <= 1 and position.y >= 0 and position.y <= 1 then
        return position.x, position.y
    end
    return nil
end

local function Size(caught)
    local size = SMALLEST + GROWTH * math.log10(math.max(1, caught or 1))
    return math.floor(math.min(LARGEST, size) + 0.5)
end

-- The pins -----------------------------------------------------------------------

local function ShowTooltip(pin)
    local spot = ns.ShownBook().spots[pin.spotID]
    if not spot then
        return
    end
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:SetText(ns.Spots.Name(spot))
    GameTooltip:AddLine(BookKit.Plural(spot.caught or 0, "catch", "catches"), 1, 1, 1)
    for _, entry in ipairs(BookKit.TopCatches(spot, 3)) do
        local icon = BookKit.Icon(entry.itemID)
        local name = BookKit.ColoredName(entry.itemID)
        GameTooltip:AddDoubleLine(
            ("|T%s:16:16|t %s"):format(icon or PIN_FALLBACK, name),
            BookKit.ShareText(entry.share),
            1,
            1,
            1,
            Kit.MUTED[1],
            Kit.MUTED[2],
            Kit.MUTED[3]
        )
    end
    GameTooltip:AddLine(
        "Click to open it in the Fishing Book.",
        Kit.MUTED[1],
        Kit.MUTED[2],
        Kit.MUTED[3]
    )
    GameTooltip:Show()
end

local function CreatePin(map)
    local pin = CreateFrame("Frame", nil, map:GetCanvas())
    Mixin(pin, MapCanvasPinMixin)
    pin:SetScalingLimits(SCALE_FACTOR, SCALE_ZOOMED_OUT, SCALE_ZOOMED_IN)
    pin:UseFrameLevelType(FRAME_LEVEL)

    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetAllPoints()
    if not BookKit.SetAtlasIfThere(pin.icon, PIN_ATLAS) then
        pin.icon:SetTexture(PIN_FALLBACK)
    end

    -- The glow round a pin the book has pointed out, pulsing for a while.
    pin.glow = pin:CreateTexture(nil, "BACKGROUND")
    pin.glow:SetPoint("CENTER")
    pin.glow:SetBlendMode("ADD")
    pin.glow:SetAlpha(0)
    BookKit.SetAtlasIfThere(pin.glow, GLOW_ATLAS)

    pin.pulse = pin.glow:CreateAnimationGroup()
    pin.pulse:SetLooping("BOUNCE")
    local fade = pin.pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(0.2)
    fade:SetToAlpha(1)
    fade:SetDuration(0.6)
    fade:SetSmoothing("IN_OUT")

    pin:EnableMouse(true)
    pin:SetScript("OnEnter", ShowTooltip)
    pin:SetScript("OnLeave", GameTooltip_Hide)
    pin:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self:IsMouseOver() then
            -- A maximised map covers the book, so the map goes first, the
            -- game's own way. In combat it can't, and the book opens anyway.
            if WorldMapFrame and WorldMapFrame:IsShown() and not ns.InCombat() then
                HideUIPanel(WorldMapFrame)
            end
            ns.BookWindow.Open("places", self.spotID)
        end
    end)

    -- A right-click on a pin still zooms the map out, as it does on the
    -- game's own pins. The game won't allow this to be set in combat, and
    -- a pin made then simply keeps the click.
    if not InCombatLockdown() then
        pin:SetPassThroughButtons("RightButton")
    end
    return pin
end

local function Place(map, spotID, spot, x, y, isPointed)
    used = used + 1
    local pin = pins[used]
    if not pin then
        pin = CreatePin(map)
        pins[used] = pin
    end

    pin.spotID = spotID
    pin:SetOwningMap(map)
    -- UseFrameLevelType only records the wish; Blizzard applies it when it
    -- acquires a pin, which ours never are. Without this the pins sit under
    -- the explored-area overlays.
    pin:ApplyFrameLevel()
    local size = Size(spot.caught)
    pin:SetSize(size, size)
    pin.glow:SetSize(size * GLOW_SCALE, size * GLOW_SCALE)
    pin:SetPosition(x, y)
    pin:ApplyCurrentScale()
    pin:Show()

    if isPointed then
        pin.pulse:Play()
    else
        pin.pulse:Stop()
        pin.glow:SetAlpha(0)
    end
end

-- The provider ------------------------------------------------------------------

function provider:RemoveAllData()
    for index = 1, used do
        local pin = pins[index]
        pin.pulse:Stop()
        pin:Hide()
        pin.spotID = nil
    end
    used = 0
end

function provider:RefreshAllData()
    self:RemoveAllData()
    local map = self:GetMap()
    local mapID = map and map:GetMapID()
    if not mapID or not ns.db then
        return
    end

    local pointedID = pointed and pointed.untilAt > GetTime() and pointed.spotID or nil
    if not ns.settings.mapPins and not pointedID then
        return
    end

    for spotID, spot in pairs(ns.ShownBook().spots) do
        if (spot.caught or 0) > 0 and (ns.settings.mapPins or spotID == pointedID) then
            local x, y = Position(spot, mapID)
            if x then
                Place(map, spotID, spot, x, y, spotID == pointedID)
            end
        end
    end
end

-- Pins live on the map's canvas, which scales as the map zooms; each pin
-- scales back the other way, and is put back in its place.
function provider:OnCanvasScaleChanged()
    for index = 1, used do
        pins[index]:ApplyCurrentScale()
    end
end

function provider:OnCanvasSizeChanged()
    for index = 1, used do
        pins[index]:ApplyCurrentPosition()
    end
end

-- Outside ------------------------------------------------------------------------

--- Redraws the pins, if the map is open.
function MapPins.Refresh()
    local map = provider:GetMap()
    if map and map:IsShown() then
        provider:RefreshAllData()
    end
end

--- Opens the world map on a spot's zone and makes its pin stand out for a
--- few seconds, whether or not the pins setting is on. The map can't be
--- opened from an addon in combat without the risk of spoiling the game's
--- own use of it, so then this does nothing and says so.
---@param spotID number
---@return boolean shown
function MapPins.ShowSpot(spotID)
    local spot = ns.db and ns.ShownBook().spots[spotID]
    local map = provider:GetMap()
    if not spot or not spot.mapX or not BookKit.MapKnown(spot.mapID) then
        return false
    end
    if not map or InCombatLockdown() then
        return false
    end

    pointed = { spotID = spotID, untilAt = GetTime() + POINTED_SECONDS }
    if not map:IsShown() then
        OpenWorldMap(spot.mapID)
    elseif map:GetMapID() ~= spot.mapID then
        map:SetMapID(spot.mapID)
    end
    MapPins.Refresh()

    -- Once the moment has passed, a pin that's only there because it was
    -- pointed out goes again.
    C_Timer.After(POINTED_SECONDS + 0.1, MapPins.Refresh)
    return map:IsShown()
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_WorldMap", function()
    if WorldMapFrame and WorldMapFrame.AddDataProvider then
        WorldMapFrame:AddDataProvider(provider)
    end
end)

for _, message in ipairs({ "CATCH", "SETTINGS_CHANGED" }) do
    ns.Listen(message, MapPins.Refresh)
end

-- Another book has other places under the same numbers, so a place
-- pointed out in the last one isn't this one's. DEMO_CHANGED also comes
-- with each demo catch, which changes no book.
local demoOn = false

ns.Listen("BOOK_CHANGED", function()
    pointed = nil
    MapPins.Refresh()
end)
ns.Listen("DEMO_CHANGED", function(on)
    on = on and true or false
    if on ~= demoOn then
        demoOn = on
        pointed = nil
    end
    MapPins.Refresh()
end)
