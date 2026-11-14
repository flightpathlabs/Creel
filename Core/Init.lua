local addonName, ns = ...

-- Creel
--
-- A fishing companion: one key to cast and reel, a small panel that keeps
-- the trip's tally, and a book of everything you've caught and where.
--
-- Everything hangs off the private table the client hands every file in
-- the addon (ns). The only globals are the saved data, the slash command
-- and the named secure buttons in Fishing/Casting.lua, which key bindings
-- have to reach by name.

ns.name = addonName
ns.TITLE = "Creel"

-- How the player's choices start out. Setup asks about the first few; the
-- rest live on the settings page.
ns.DEFAULT_SETTINGS = {
    -- "key", "double" or "none".
    castStyle = "key",
    -- Up to two keys for the one-key style, as binding strings ("F",
    -- "SHIFT-F", "BUTTON4"). Nothing is bound until setup or the settings
    -- page picks one.
    castKey = nil,
    castKey2 = nil,
    -- Swap the key to the game's interact action while the line is out, so
    -- the same key reels in.
    reelWithKey = true,
    -- How far the interact action looks for the bobber while the line is
    -- out, in yards. The game's own default is too short for a long cast.
    reelRange = 30,
    -- Seconds between the two clicks of a double right-click.
    doubleClickSpeed = 0.35,

    -- "pole", "fishing" or "never".
    showPanel = "pole",
    panelScale = 1,
    panelAlpha = 1,
    panelLocked = false,
    panelCollapsed = false,

    tips = true,
    tooltipLine = true,
    mapPins = false,

    -- Quiet other sounds while fishing.
    quiet = false,
    -- Effects volume while quiet, 0 to 1; nil leaves it alone.
    splashBoost = nil,

    -- Minutes without a cast before a trip ends by itself.
    idleMinutes = 10,
}

ns.SECONDS_PER_DAY = 24 * 60 * 60

local frame = CreateFrame("Frame")
local handlers = {}

--- Calls handler(...) with the event's payload whenever the client fires it.
---@param event string
---@param handler fun(...)
function ns.OnEvent(event, handler)
    if not handlers[event] then
        handlers[event] = {}
        frame:RegisterEvent(event)
    end
    table.insert(handlers[event], handler)
end

-- Unit events for the player alone come through a frame of their own, so
-- the casts of everyone nearby never reach the handlers.
local playerFrame = CreateFrame("Frame")
local playerHandlers = {}

--- Like ns.OnEvent, for a unit event about the player. The handler gets
--- the payload after the unit.
---@param event string
---@param handler fun(...)
function ns.OnPlayerEvent(event, handler)
    if not playerHandlers[event] then
        playerHandlers[event] = {}
        playerFrame:RegisterUnitEvent(event, "player")
    end
    table.insert(playerHandlers[event], handler)
end

-- One handler failing shouldn't stop the others hearing the same event, so
-- each runs on its own and an error is reported without unwinding the rest.
local function Dispatch(list, ...)
    for _, handler in ipairs(list) do
        local ok, message = pcall(handler, ...)
        if not ok then
            geterrorhandler()(message)
        end
    end
end

frame:SetScript("OnEvent", function(_, event, ...)
    Dispatch(handlers[event], ...)
end)

playerFrame:SetScript("OnEvent", function(_, event, _, ...)
    Dispatch(playerHandlers[event], ...)
end)

-- Messages between Creel's own files, so the panel and the book can follow
-- what the fishing code learns without either knowing about the other.
local listeners = {}

---@param message string
---@param listener fun(...)
function ns.Listen(message, listener)
    listeners[message] = listeners[message] or {}
    table.insert(listeners[message], listener)
end

---@param message string
function ns.Send(message, ...)
    if listeners[message] then
        Dispatch(listeners[message], ...)
    end
end

-- InCombatLockdown() is still false while PLAYER_REGEN_DISABLED is being
-- handed out, so anything deciding "are we fighting?" from inside that
-- event would get it wrong. These handlers are registered before any
-- other file's, so the flag is right by the time the rest hear the event.
local inCombat = false
ns.OnEvent("PLAYER_REGEN_DISABLED", function()
    inCombat = true
end)
ns.OnEvent("PLAYER_REGEN_ENABLED", function()
    inCombat = false
end)

--- Whether the player is in combat, including the moment it starts.
---@return boolean
function ns.InCombat()
    return inCombat or InCombatLockdown()
end

--- A value the client may hand back as secret is treated as unknown.
function ns.Readable(value)
    if issecretvalue and issecretvalue(value) then
        return nil
    end
    return value
end

--- The key a character's records are kept under: "Name - Realm". Forever
--- has no realms as such; the realm string carries the ruleset.
---@return string
function ns.CharacterKey()
    return ("%s - %s"):format(UnitName("player") or "?", GetRealmName() or "")
end

--- Formats copper the way the game does, with coin icons.
---@param copper number|nil
---@return string
function ns.Money(copper)
    if not copper then
        return ""
    end
    return C_CurrencyInfo.GetCoinTextureString(math.floor(copper + 0.5))
end

--- "1:05:20" or "42:10" for a length of time in seconds.
---@param seconds number
---@return string
function ns.Clock(seconds)
    seconds = math.floor(seconds or 0)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor(seconds % 3600 / 60)
    if hours > 0 then
        return ("%d:%02d:%02d"):format(hours, minutes, seconds % 60)
    end
    return ("%d:%02d"):format(minutes, seconds % 60)
end

--- "31h 12m" or "12m" for a long stretch of time.
---@param seconds number
---@return string
function ns.Hours(seconds)
    local minutes = math.floor((seconds or 0) / 60)
    if minutes < 60 then
        return ("%dm"):format(minutes)
    end
    return ("%dh %dm"):format(math.floor(minutes / 60), minutes % 60)
end
