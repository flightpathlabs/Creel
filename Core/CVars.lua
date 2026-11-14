local _, ns = ...

-- Changing the player's own game settings, and always putting them back.
--
-- Creel changes a few settings for a while: the interact range while the
-- line is out, and the sound while fishing quietly. Every one is written to
-- saved data before it changes, with the player's own value, and restored
-- when the last reason for changing it ends, on logout or /reload, and on
-- the next login if the game closed in between.
--
-- Two parts of Creel can want the same setting at once, so each change
-- names an owner, and the original only comes back when no owner is left.

local CVars = {}
ns.CVars = CVars

-- True while we're writing a value ourselves, so CVAR_UPDATE can tell our
-- changes from the player's.
local writing = false

local function Write(name, value)
    writing = true
    C_CVar.SetCVar(name, value)
    writing = false
end

local function Saved()
    return ns.db.saved
end

--- Sets a game setting for as long as owner needs it.
---@param owner string
---@param name string
---@param value string|number
function CVars.Hold(owner, name, value)
    local current = C_CVar.GetCVar(name)
    if current == nil then
        -- Not a setting on this client. Nothing to change or put back.
        return
    end

    local entry = Saved()[name]
    if not entry then
        entry = { value = current, owners = {} }
        Saved()[name] = entry
    end
    entry.owners[owner] = true

    if tostring(current) ~= tostring(value) then
        Write(name, tostring(value))
    end
end

--- Gives back every setting owner was holding. Each returns to the
--- player's own value once nothing else holds it.
---@param owner string
function CVars.Release(owner)
    for name, entry in pairs(Saved()) do
        if entry.owners[owner] then
            entry.owners[owner] = nil
            if next(entry.owners) == nil then
                Write(name, entry.value)
                Saved()[name] = nil
            end
        end
    end
end

--- Whether owner is holding anything right now.
---@param owner string
---@return boolean
function CVars.IsHolding(owner)
    for _, entry in pairs(Saved()) do
        if entry.owners[owner] then
            return true
        end
    end
    return false
end

--- Puts every held setting back, whoever holds it.
function CVars.ReleaseAll()
    for name, entry in pairs(Saved()) do
        Write(name, entry.value)
    end
    wipe(Saved())
end

ns.Listen("DATA_READY", function()
    -- Anything still held from last time means the game closed before we
    -- could put it back. Do that before anything else runs.
    CVars.ReleaseAll()
end)

ns.OnEvent("PLAYER_LOGOUT", function()
    CVars.ReleaseAll()
end)

-- If the player changes a setting we're holding, their choice wins: we
-- stop holding it and won't put the old value back over theirs.
ns.OnEvent("CVAR_UPDATE", function(name)
    if writing or not ns.db then
        return
    end
    for held in pairs(Saved()) do
        if held:lower() == tostring(name):lower() then
            Saved()[held] = nil
            ns.Send("CVAR_TAKEN_BACK", held)
        end
    end
end)
