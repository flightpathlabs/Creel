local _, ns = ...

-- Casting and reeling with one key, or with a double right-click.
--
-- Blizzard's rules: a cast needs a key press or a click that reaches a
-- secure button, and nothing may cast on a timer. What an addon may do is
-- decide what a key does while the player is out of combat, so that's all
-- this does.
--
-- One key: the chosen key is pointed at CreelCastButton, which casts
-- Fishing. When the line goes out the same key is pointed at the game's
-- own interact action (the INTERACTTARGET binding), so the next press
-- reels in; when the line comes back it's pointed at the cast button
-- again. Double right-click: the second click of a quick pair is bound to
-- the cast button for that one click, then let go.
--
-- These are override bindings owned by the cast button, so the player's
-- saved key bindings are never touched. A secure state driver clears them
-- the moment combat starts, and the key does whatever the player had it
-- doing; they come back when combat ends.

local Casting = {}
ns.Casting = Casting

local MAIN_HAND = 16

-- Short enough not to get in the way of a real recast, long enough that
-- a double press doesn't cast twice.
local LOCKOUT = 0.5

local castButton = CreateFrame(
    "Button",
    "CreelCastButton",
    UIParent,
    "SecureActionButtonTemplate, SecureHandlerStateTemplate"
)
castButton:SetSize(1, 1)
castButton:Hide()
castButton:SetAttribute("type", "spell")
castButton:RegisterForClicks("AnyUp", "AnyDown")

-- In combat the restricted environment can still clear this button's
-- override bindings, which plain addon code can't.
castButton:SetAttribute(
    "_onstate-combat",
    [[
    if newstate == 1 or newstate == "1" then
        self:ClearBindings()
    end
    ]]
)
RegisterStateDriver(castButton, "combat", "[combat] 1; 0")

-- The double-click binding is good for one click. Letting go of it from
-- inside the click means it's gone even if combat started in between. Only
-- on the release: the cast itself happens on the release for the
-- double-click (see Casting.Apply), and clearing on the press would
-- swallow it.
SecureHandlerWrapScript(
    castButton,
    "OnClick",
    castButton,
    [[
    if not down and self:GetAttribute("creel-oneshot") then
        return nil, "clear"
    end
    ]],
    [[
    self:SetAttribute("creel-oneshot", nil)
    self:ClearBindings()
    ]]
)

-- The lure button sits on the panel (placed with Casting.PlaceLureButton).
-- It puts a lure on the pole when the player clicks it, never otherwise.
local lureButton = CreateFrame(
    "Button",
    "CreelLureButton",
    UIParent,
    "SecureActionButtonTemplate, SecureHandlerStateTemplate"
)
lureButton:SetSize(20, 20)
lureButton:Hide()

-- The panel can hide in combat but this button can't be hidden from addon
-- code then, and an invisible button would sit on screen catching clicks.
-- So it hides itself as combat starts, and comes back afterwards if the
-- panel still wants it (the creel-wanted attribute, set out of combat).
lureButton:SetAttribute(
    "_onstate-combat",
    [[
    if newstate == 1 or newstate == "1" then
        self:Hide()
    elseif self:GetAttribute("creel-wanted") then
        self:Show()
    end
    ]]
)
RegisterStateDriver(lureButton, "combat", "[combat] 1; 0")
lureButton:SetAttribute("type", "item")
lureButton:SetAttribute("target-slot", MAIN_HAND)
lureButton:RegisterForClicks("LeftButtonUp")
-- Only the release is registered, so the button mustn't wait for a press
-- when the player has "cast on key down" on.
lureButton:SetAttribute("useOnKeyDown", false)
Casting.lureButton = lureButton

-- Work that touches secure frames waits until combat is over.
local afterCombat = {}

local function OutOfCombat(key, work)
    -- ns.InCombat, not InCombatLockdown: the latter is still false while
    -- PLAYER_REGEN_DISABLED is handed out, and a button shown then would
    -- stay up through the fight.
    if ns.InCombat() then
        afterCombat[key] = work
    else
        work()
    end
end

ns.OnEvent("PLAYER_REGEN_ENABLED", function()
    local queued = afterCombat
    afterCombat = {}
    for _, work in pairs(queued) do
        work()
    end
    Casting.Apply()
end)

ns.OnEvent("PLAYER_REGEN_DISABLED", function()
    -- The bindings are already gone (the state driver saw to that). The
    -- wider interact range isn't needed in a fight either.
    pcall(ns.CVars.Release, "reel")
    ns.Send("CASTING_CHANGED")
end)

local function Keys()
    local keys = {}
    if ns.settings.castKey then
        table.insert(keys, ns.settings.castKey)
    end
    if ns.settings.castKey2 and ns.settings.castKey2 ~= ns.settings.castKey then
        table.insert(keys, ns.settings.castKey2)
    end
    return keys
end

--- Points the keys wherever they should point right now. Safe to call any
--- time; in combat it waits.
function Casting.Apply()
    OutOfCombat("apply", function()
        ClearOverrideBindings(castButton)
        castButton:SetAttribute("creel-oneshot", nil)

        local settings = ns.settings
        local state = ns.State

        -- The cast fires on the release for the double-click, because the
        -- binding only exists from the second press onwards. For a key it
        -- fires on the press, whatever the player's "cast on key down"
        -- setting: after a reel the key is pointed back at this button
        -- while still held, and its release mustn't cast again.
        castButton:SetAttribute("useOnKeyDown", settings.castStyle ~= "double")

        if state.spellID then
            castButton:SetAttribute("spell", state.spellID)
        end

        if settings.castStyle ~= "key" or not state.hasPole or not state.spellID then
            ns.Send("CASTING_CHANGED")
            return
        end

        for _, key in ipairs(Keys()) do
            if state.lineOut and settings.reelWithKey then
                SetOverrideBinding(castButton, true, key, "INTERACTTARGET")
            else
                SetOverrideBindingClick(castButton, true, key, "CreelCastButton")
            end
        end
        ns.Send("CASTING_CHANGED")
    end)
end

--- Whether the key does anything right now, and what.
---@return string|nil  "cast", "reel" or nil
function Casting.KeyAction()
    local settings, state = ns.settings, ns.State
    if settings.castStyle ~= "key" or #Keys() == 0 or not state.hasPole then
        return nil
    end
    if ns.InCombat() then
        return nil
    end
    if state.lineOut and settings.reelWithKey then
        return "reel"
    end
    return "cast"
end

--- The chosen key, the way the game writes it ("F", "Shift-F"). The
--- second key stands in when only that one is set.
---@return string|nil
function Casting.KeyText()
    local key = ns.settings.castKey or ns.settings.castKey2
    return key and GetBindingText(key) or nil
end

-- While the line is out the interact action has to find the bobber, so
-- soft targeting is turned on for objects and its range widened, and the
-- game's own icon marks the bobber it would reel. All of it goes back when
-- the line comes in.
local function HoldReelSettings()
    if ns.settings.castStyle ~= "key" or not ns.settings.reelWithKey then
        return
    end
    ns.CVars.Hold("reel", "SoftTargetInteract", Enum.SoftTargetEnableFlags.Any)
    ns.CVars.Hold("reel", "SoftTargetInteractRange", ns.settings.reelRange)
    ns.CVars.Hold("reel", "SoftTargetIconGameObject", 1)
    ns.CVars.Hold("reel", "SoftTargetIconInteract", 1)
end

local lastCastAt = 0

ns.Listen("LINE_OUT", function()
    lastCastAt = GetTime()
    if not InCombatLockdown() then
        HoldReelSettings()
    end
    Casting.Apply()
end)

ns.Listen("LINE_IN", function()
    ns.CVars.Release("reel")
    Casting.Apply()
end)

ns.Listen("POLE_CHANGED", Casting.Apply)
ns.Listen("SPELL_CHANGED", Casting.Apply)
ns.Listen("DATA_READY", function()
    ns.OnEvent("PLAYER_ENTERING_WORLD", Casting.Apply)
end)

-- Double right-click ------------------------------------------------------

local lastRightAt

local function MouseOverWorld()
    local foci = GetMouseFoci and GetMouseFoci()
    local focus = foci and foci[1]
    return focus == nil or focus == WorldFrame
end

local function CanDoubleClick()
    local state = ns.State
    return ns.settings.castStyle == "double"
        and state.hasPole
        and state.spellID
        and not state.lineOut
        and not ns.InCombat()
        and not IsMouseButtonDown("LeftButton")
        and not (LootFrame and LootFrame:IsShown())
        and GetTime() - lastCastAt > LOCKOUT
        and MouseOverWorld()
end

ns.OnEvent("GLOBAL_MOUSE_DOWN", function(button)
    if button ~= "RightButton" then
        return
    end
    if not CanDoubleClick() then
        lastRightAt = nil
        return
    end
    local now = GetTime()
    if lastRightAt and now - lastRightAt <= ns.settings.doubleClickSpeed then
        lastRightAt = nil
        castButton:SetAttribute("creel-oneshot", true)
        SetOverrideBindingClick(castButton, true, "BUTTON2", "CreelCastButton")
    else
        lastRightAt = now
    end
end)

-- If the second click didn't reach the button (it landed on a frame after
-- all), the one-click binding mustn't linger and eat the next right-click.
ns.OnEvent("GLOBAL_MOUSE_UP", function(button)
    if button ~= "RightButton" or ns.settings.castStyle ~= "double" then
        return
    end
    C_Timer.After(0, function()
        if not InCombatLockdown() and castButton:GetAttribute("creel-oneshot") then
            castButton:SetAttribute("creel-oneshot", nil)
            ClearOverrideBindings(castButton)
        end
    end)
end)

-- Lures -------------------------------------------------------------------

--- The lure on the pole now: its item icon and seconds left, if any.
---@return number|nil iconID
---@return number|nil secondsLeft
function Casting.CurrentLure()
    if not ns.State.hasPole then
        return nil
    end
    local enchants = C_Item.GetWeaponEnchantInfo(Enum.WeaponSlot.MainHand) or {}
    for _, enchant in ipairs(enchants) do
        if enchant.hasEnchant then
            return enchant.enchantIconID, (enchant.timeLeft or 0) / 1000
        end
    end
    return nil
end

--- The lures in the bags the player's skill can use, best first.
---@return table  list of item IDs
function Casting.LuresInBags()
    local skill = ns.State.rank or 0
    local list = {}
    for itemID, lure in pairs(ns.Lures or {}) do
        if (lure.skill or 0) <= skill and (C_Item.GetItemCount(itemID) or 0) > 0 then
            table.insert(list, itemID)
        end
    end
    table.sort(list, function(a, b)
        return ns.Lures[a].bonus > ns.Lures[b].bonus
    end)
    return list
end

--- The lure a click would put on: the player's pick if they have one and
--- it's in the bags, otherwise the best they can use. Nil for none.
---@return number|nil itemID
function Casting.LureToUse()
    local choice = ns.settings.lureChoice
    if choice == 0 then
        return nil
    end
    local available = Casting.LuresInBags()
    if choice then
        for _, itemID in ipairs(available) do
            if itemID == choice then
                return itemID
            end
        end
    end
    return available[1]
end

--- Points the lure button at the lure a click should use.
function Casting.UpdateLure()
    OutOfCombat("lure", function()
        local itemID = Casting.LureToUse()
        lureButton:SetAttribute("item", itemID and ("item:" .. itemID) or nil)
        ns.Send("LURE_CHANGED", itemID)
    end)
end

--- Sets which lure a click uses: an item ID, 0 for none, nil for the best.
---@param choice number|nil
function Casting.ChooseLure(choice)
    ns.settings.lureChoice = choice
    Casting.UpdateLure()
end

--- Lays the lure button over a spot on the panel.
---
--- It isn't anchored to the panel: a protected frame anchored to another
--- makes that one protected too, and then the panel couldn't move, fold or
--- hide in combat. Instead it's placed against UIParent where the slot is
--- on screen, and placed again whenever the panel says it has moved. In
--- combat it hides itself (see the state driver above), so it never
--- lingers where the slot used to be.
---@param anchor Frame
function Casting.PlaceLureButton(anchor)
    Casting.lureAnchor = anchor
    OutOfCombat("placeLure", function()
        local left, bottom = anchor:GetLeft(), anchor:GetBottom()
        if not left or not bottom then
            return
        end
        local scale = anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
        lureButton:ClearAllPoints()
        lureButton:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left * scale, bottom * scale)
        lureButton:SetSize(anchor:GetWidth() * scale, anchor:GetHeight() * scale)
        lureButton:SetFrameStrata(anchor:GetFrameStrata())
        lureButton:SetFrameLevel(anchor:GetFrameLevel() + 5)

        -- The button sits over the slot and takes the mouse, so the slot's
        -- own tooltip is shown from here.
        lureButton:SetScript("OnEnter", function()
            local onEnter = anchor:GetScript("OnEnter")
            if onEnter then
                onEnter(anchor)
            end
        end)
        lureButton:SetScript("OnLeave", GameTooltip_Hide)
    end)
end

-- The panel may have moved during the fight.
ns.OnEvent("PLAYER_REGEN_ENABLED", function()
    if Casting.lureAnchor then
        Casting.PlaceLureButton(Casting.lureAnchor)
    end
end)

---@param shown boolean
function Casting.ShowLureButton(shown)
    OutOfCombat("showLure", function()
        local wanted = shown and ns.State.hasPole or false
        lureButton:SetAttribute("creel-wanted", wanted)
        lureButton:SetShown(wanted)
    end)
end

ns.OnEvent("BAG_UPDATE_DELAYED", Casting.UpdateLure)
ns.Listen("SKILL_CHANGED", Casting.UpdateLure)
ns.Listen("POLE_CHANGED", function(hasPole)
    Casting.UpdateLure()
    if not hasPole then
        Casting.ShowLureButton(false)
    end
end)

-- Other addons ------------------------------------------------------------

-- Fishing addons that cast on a key or a double-click of their own. Two
-- addons answering the same press is the one way this goes wrong, so
-- setup names any that are loaded.
local RIVALS = {
    "FishingBuddy",
    "BetterFishing",
    "ForeverFishing",
    "FishFry",
    "ClassicFishingCompanion",
    "EasyFishing",
    "FishingForever",
    "ForeverAngler",
    "AnglersTackleBox",
}

--- The other casting addons that are loaded, by title.
---@return table
function Casting.Rivals()
    local found = {}
    for _, name in ipairs(RIVALS) do
        if C_AddOns.IsAddOnLoaded(name) then
            local title = C_AddOns.GetAddOnMetadata(name, "Title") or name
            table.insert(found, title)
        end
    end
    return found
end
