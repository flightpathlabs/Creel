local _, ns = ...

-- Quiet while fishing: music, ambience, dialogue, pet and emote sounds and
-- error speech go off while you fish, so the splash stands out.
--
-- It uses the game's own on/off switches rather than the volume sliders,
-- so the player's levels are never touched. The splash is a sound effect,
-- and the game can't separate it from other effects, so those stay on;
-- the optional splash boost turns the effects volume up instead.
--
-- Everything is held through ns.CVars, which saves the player's values
-- first and puts them back exactly. Quiet ends when the toggle goes off,
-- a minute after the line last came in (so music doesn't bounce on and
-- off between casts), when the pole comes out of the hand, when combat
-- starts, and on logout or /reload.

local Sound = {}
ns.Sound = Sound

local OWNER = "quiet"

local SILENCED = {
    "Sound_EnableMusic",
    "Sound_EnableAmbience",
    "Sound_EnableDialog",
    "Sound_EnablePetSounds",
    "Sound_EnableEmoteSounds",
    "Sound_EnableErrorSpeech",
}

local LINGER = 60

-- The player's own sound settings at their last clean logout, compared on
-- login to spot settings a crash left muted.
local REMEMBERED = {
    "Sound_EnableMusic",
    "Sound_EnableAmbience",
    "Sound_EnableDialog",
    "Sound_SFXVolume",
}

local lingerTimer

local function ShouldBeQuiet()
    local state = ns.State
    return ns.settings.quiet
        and state.hasPole
        and not InCombatLockdown()
        and (state.lineOut or lingerTimer ~= nil)
end

local function Update()
    if ShouldBeQuiet() then
        for _, name in ipairs(SILENCED) do
            ns.CVars.Hold(OWNER, name, 0)
        end
        if ns.settings.splashBoost then
            local current = tonumber(C_CVar.GetCVar("Sound_SFXVolume")) or 1
            ns.CVars.Hold(OWNER, "Sound_SFXVolume", math.max(current, ns.settings.splashBoost))
        end
    elseif ns.CVars.IsHolding(OWNER) then
        ns.CVars.Release(OWNER)
    end
    ns.Send("QUIET_CHANGED", Sound.IsQuiet())
end

--- Whether sounds are being kept quiet right now.
---@return boolean
function Sound.IsQuiet()
    return ns.CVars.IsHolding(OWNER)
end

--- The panel's speaker button.
---@param on boolean
function Sound.SetQuiet(on)
    ns.settings.quiet = on and true or false
    Update()
end

ns.Listen("LINE_OUT", function()
    if lingerTimer then
        lingerTimer:Cancel()
        lingerTimer = nil
    end
    Update()
end)

ns.Listen("LINE_IN", function()
    if lingerTimer then
        lingerTimer:Cancel()
    end
    lingerTimer = C_Timer.NewTimer(LINGER, function()
        lingerTimer = nil
        Update()
    end)
    Update()
end)

ns.Listen("POLE_CHANGED", Update)
ns.Listen("TRIP_ENDED", function()
    if lingerTimer then
        lingerTimer:Cancel()
        lingerTimer = nil
    end
    Update()
end)
ns.OnEvent("PLAYER_REGEN_DISABLED", Update)
ns.OnEvent("PLAYER_REGEN_ENABLED", Update)

-- A new splash level, or a change to what's quiet, takes effect at once.
-- Letting go first matters: the boost only ever raises the volume from
-- where it stands, and while held, where it stands is the old boost.
ns.Listen("SETTINGS_CHANGED", function()
    if ns.CVars.IsHolding(OWNER) then
        ns.CVars.Release(OWNER)
    end
    Update()
end)

-- The crash backstop ------------------------------------------------------

ns.OnEvent("PLAYER_LOGOUT", function()
    -- ns.CVars has already put everything back by the time this runs (its
    -- handler was registered first), so these are the player's own values.
    if ns.CVars.IsHolding(OWNER) then
        return
    end
    for _, name in ipairs(REMEMBERED) do
        ns.db.ownSound[name] = C_CVar.GetCVar(name)
    end
end)

--- Whether the sound looks left muted by a session that didn't end
--- cleanly: music off now, but on at the last clean logout.
---@return boolean
function Sound.LooksStuck()
    local own = ns.db and ns.db.ownSound
    if not own or own.Sound_EnableMusic ~= "1" then
        return false
    end
    return C_CVar.GetCVar("Sound_EnableMusic") == "0" and not Sound.IsQuiet()
end

--- Puts the remembered sound settings back. Only ever on the player's
--- click.
function Sound.RestoreRemembered()
    for name, value in pairs(ns.db.ownSound) do
        if value ~= nil then
            C_CVar.SetCVar(name, value)
        end
    end
    ns.Send("QUIET_CHANGED", Sound.IsQuiet())
end
