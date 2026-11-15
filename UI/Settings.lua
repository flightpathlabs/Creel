local _, ns = ...

-- Creel's page in the game's Options window, the /creel command and the
-- entry in the minimap's addon menu.
--
-- Everything setup asks is here too, with the rest: the panel's size and
-- look, sound, the book, and starting again. A change takes effect as it's
-- made, like the game's own options.

local Kit = ns.Kit

-- Each setting is registered with the game under a name of its own: this,
-- followed by its key in the saved settings.
local PREFIX = "Creel_"

-- The splash boost's level while it's off, so turning it back on returns
-- to where it was.
local DEFAULT_BOOST = 0.8

local category, layout

-- Every setting on the page, so the page can be brought up to date when
-- something else (setup, the panel's speaker) changes one of them.
local registered = {}

-- True while the page is the one telling everyone a setting changed, or
-- while it's catching up with a change made elsewhere. Either way the
-- other direction stays quiet, or each would set off the other.
local telling = false
local catchingUp = false

local function Changed()
    telling = true
    ns.Send("SETTINGS_CHANGED")
    telling = false
end

local function CastingChanged()
    ns.Casting.Apply()
    Changed()
end

local function PanelChanged()
    Changed()
    if ns.Panel and ns.Panel.UpdateVisibility then
        ns.Panel.UpdateVisibility()
    end
end

local function MapChanged()
    Changed()
    if ns.MapPins and ns.MapPins.Refresh then
        ns.MapPins.Refresh()
    end
end

local function QuietChanged(_, _, value)
    if ns.Sound and ns.Sound.SetQuiet then
        ns.Sound.SetQuiet(value)
    end
    Changed()
end

--- Calls back when the player changes a setting, but not while the page
--- is only catching up.
local function OnChange(variable, callback)
    Settings.SetOnValueChangedCallback(variable, function(...)
        if not catchingUp then
            callback(...)
        end
    end)
end

--- Registers one key of the saved settings with the game's options.
local function Register(key, kind, label, onChange)
    local setting = Settings.RegisterAddOnSetting(
        category,
        PREFIX .. key,
        key,
        ns.settings,
        kind,
        label,
        ns.DEFAULT_SETTINGS[key]
    )
    OnChange(PREFIX .. key, onChange or Changed)
    table.insert(registered, setting)
    return setting
end

local function AddHeader(title)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(title))
end

local function AddCheckbox(key, label, tooltip, onChange)
    local setting = Register(key, Settings.VarType.Boolean, label, onChange)
    Settings.CreateCheckbox(category, setting, tooltip)
end

--- A dropdown for a setting saved as a word.
---@param choices table  list of { value, label }
local function AddDropdown(key, label, tooltip, choices, onChange)
    local setting = Register(key, Settings.VarType.String, label, onChange)
    Settings.CreateDropdown(category, setting, function()
        local container = Settings.CreateControlTextContainer()
        for _, choice in ipairs(choices) do
            container:Add(choice[1], choice[2])
        end
        return container:GetData()
    end, tooltip)
end

--- Slider options with the figure shown on the right.
---@param format fun(value: number): string
local function SliderOptions(lowest, highest, step, format)
    local options = Settings.CreateSliderOptions(lowest, highest, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, format)
    return options
end

local function AddSlider(key, label, tooltip, range, format, onChange)
    local setting = Register(key, Settings.VarType.Number, label, onChange)
    Settings.CreateSlider(
        category,
        setting,
        SliderOptions(range[1], range[2], range[3], format),
        tooltip
    )
end

local function Percent(value)
    return ("%d%%"):format(math.floor(value * 100 + 0.5))
end

--- A row with a button, for things that aren't a setting of their own.
---@param buttonText string|function  a function is asked each time the
---                                    row is drawn
local function AddButton(label, buttonText, onClick, tooltip)
    -- Search tags are added by hand: the game's own would try to use the
    -- button's words, which may be a function here.
    local initializer = CreateSettingsButtonInitializer(label, buttonText, onClick, tooltip, false)
    initializer:AddSearchTags(label)
    layout:AddInitializer(initializer)
    return initializer
end

-- The page --------------------------------------------------------------------

local function KeyText(key)
    local binding = ns.settings[key]
    return binding and GetBindingText(binding) or "None"
end

--- A row for one of the cast keys. Its button opens a small window that
--- waits for a key, the way the game's own key bindings page does.
local function AddKey(key, label, tooltip)
    local initializer
    initializer = AddButton(label, function()
        return KeyText(key)
    end, function(button)
        ns.Setup.ChooseKey(key, label, function()
            -- The row was drawn with the old key. Rows are reused as the
            -- page scrolls, so only say the new one if this button is
            -- still showing this row.
            local ok, same = pcall(function()
                return button:GetParent():GetElementData() == initializer
            end)
            if ok and same then
                button:SetText(KeyText(key))
            end
        end)
    end, tooltip)
end

local function AddCastingOptions()
    AddHeader("Casting")

    AddDropdown(
        "castStyle",
        "How you cast",
        "One key casts, and reels in at the splash. "
            .. "Double right-click casts with the mouse. My own buttons leaves it to you: put "
            .. "Fishing on an action bar as usual.",
        {
            { "key", "One key" },
            { "double", "Double right-click" },
            { "none", "My own buttons" },
        },
        CastingChanged
    )

    AddKey(
        "castKey",
        "Cast key",
        "The key that casts, and reels in at the splash. Creel only borrows it while you "
            .. "hold a fishing pole, and gives it back the moment a fight starts."
    )
    AddKey(
        "castKey2",
        "Second key",
        "Another key that does the same, such as a side mouse button. Optional."
    )

    AddCheckbox(
        "reelWithKey",
        "Let the key reel in too",
        "While the line is out the key presses the game's Interact Key, which reels in "
            .. "the bobber. Untick to reel by right-clicking the bobber instead.",
        CastingChanged
    )

    AddSlider(
        "reelRange",
        "How far the key reaches",
        "How far away the bobber can be for the key to reel it in. The game's own reach "
            .. "is too short for a long cast. Put back as it was when the line comes in.",
        { 10, 60, 5 },
        function(value)
            return ("%d yd"):format(value)
        end
    )

    AddSlider(
        "doubleClickSpeed",
        "Double-click speed",
        "How quickly the second right-click has to follow the first to cast.",
        { 0.2, 0.6, 0.05 },
        function(value)
            return ("%.2f s"):format(value)
        end
    )
end

local function AddPanelOptions()
    AddHeader("The panel")

    AddDropdown(
        "showPanel",
        "When the panel shows",
        "The panel keeps the trip's time, "
            .. "tally and catches. The Fishing Book has the same numbers either way.",
        {
            { "pole", "When I hold a fishing pole" },
            { "fishing", "When I start fishing" },
            { "never", "Only in the Fishing Book" },
        },
        PanelChanged
    )

    AddSlider("panelScale", "Size", "How large the panel is drawn.", { 0.6, 1.5, 0.05 }, Percent)
    AddSlider(
        "panelAlpha",
        "Opacity",
        "Lower lets the world show through the panel.",
        { 0.3, 1, 0.05 },
        Percent
    )

    AddCheckbox("panelLocked", "Lock the panel in place", "Stops the panel being dragged.")
    AddCheckbox(
        "tips",
        "Tips and trivia on the catch card",
        "A line worth reading with each catch: what it's good for, or a bit of its story."
    )
    AddCheckbox(
        "minimapButton",
        "Show a button on the minimap",
        "Left-click it for the Fishing Book, right-click for these options, and "
            .. "shift-click to show or hide the panel. Drag it to move it round the edge. "
            .. "Without it, /creel book opens the book."
    )
end

local function AddSoundOptions()
    AddHeader("Sound")

    AddCheckbox(
        "quiet",
        "Quiet other sounds while fishing",
        "Music, ambience and voices go quiet while you fish, so the splash stands out. "
            .. "Everything comes back a minute after your last cast, in a fight, and when "
            .. "you put the pole away. The speaker on the panel does the same.",
        QuietChanged
    )

    -- Off, or a level for the effects volume. Saved as nil when it's off,
    -- so it's two settings on the page: the box and the slider.
    local level = ns.settings.splashBoost or DEFAULT_BOOST
    local on = Settings.RegisterProxySetting(
        category,
        PREFIX .. "splashBoostOn",
        Settings.VarType.Boolean,
        "Turn the splash up",
        false,
        function()
            return ns.settings.splashBoost ~= nil
        end,
        function(value)
            ns.settings.splashBoost = value and level or nil
        end
    )
    local volume = Settings.RegisterProxySetting(
        category,
        PREFIX .. "splashBoost",
        Settings.VarType.Number,
        "Effects volume",
        DEFAULT_BOOST,
        function()
            return ns.settings.splashBoost or level
        end,
        function(value)
            level = value
            if ns.settings.splashBoost then
                ns.settings.splashBoost = value
            end
        end
    )
    OnChange(PREFIX .. "splashBoostOn", Changed)
    OnChange(PREFIX .. "splashBoost", Changed)
    table.insert(registered, on)
    table.insert(registered, volume)

    layout:AddInitializer(
        CreateSettingsCheckboxSliderInitializer(
            on,
            "Turn the splash up",
            "While other sounds are quiet, raise the effects volume to at least this, "
                .. "so the splash is easy to hear. Put back as it was afterwards.",
            volume,
            SliderOptions(0.5, 1, 0.05, Percent),
            "Effects volume",
            "The effects volume while you fish."
        )
    )
end

-- What "worth a lot" can be set to: a slider over these steps rather than
-- every copper between, finer at the cheap end where it matters.
local WORTH_STEPS = {
    1000,
    2000,
    5000,
    10000,
    20000,
    30000,
    50000,
    100000,
    150000,
    200000,
    300000,
    400000,
    500000,
}

--- The step nearest a threshold, so one set some other way still lands on
--- the slider.
local function NearestStep(copper)
    local best, bestGap = 1, math.huge
    for index, step in ipairs(WORTH_STEPS) do
        local gap = math.abs(step - (copper or 0))
        if gap < bestGap then
            best, bestGap = index, gap
        end
    end
    return best
end

local function AddCatchOptions()
    AddHeader("Catches")

    AddCheckbox(
        "specialEffects",
        "Make a fuss of special catches",
        "A unique find (something Creel didn't know comes off a line) or anything epic "
            .. "or better gets the loot toast's grander art, a burst of light and the "
            .. "game's epic-loot sound on the catch card."
    )

    -- The sound's switch and its threshold share a row, as the splash
    -- boost does. The threshold is saved in copper; the slider moves
    -- through WORTH_STEPS.
    local sound = Register(
        "valuableSound",
        Settings.VarType.Boolean,
        "Auction house sound for a valuable catch"
    )
    local worth = Settings.RegisterProxySetting(
        category,
        PREFIX .. "valuableStep",
        Settings.VarType.Number,
        "Worth at least",
        NearestStep(ns.DEFAULT_SETTINGS.valuableCopper),
        function()
            return NearestStep(ns.settings.valuableCopper)
        end,
        function(value)
            ns.settings.valuableCopper = WORTH_STEPS[math.floor(value + 0.5)]
                or ns.DEFAULT_SETTINGS.valuableCopper
        end
    )
    OnChange(PREFIX .. "valuableStep", Changed)
    table.insert(registered, worth)

    layout:AddInitializer(
        CreateSettingsCheckboxSliderInitializer(
            sound,
            "Auction house sound for a valuable catch",
            "When a catch is worth at least this much (one of it, at auction, or at a "
                .. "vendor where there's no auction price), the auction house's sound plays "
                .. "and the card shows its worth in gold.",
            worth,
            SliderOptions(1, #WORTH_STEPS, 1, function(value)
                return ns.Money(WORTH_STEPS[math.floor(value + 0.5)])
            end),
            "Worth at least",
            "What one of a catch has to be worth to count as valuable."
        )
    )
end

local function AddBookOptions()
    AddHeader("The Fishing Book")

    AddCheckbox(
        "tooltipLine",
        "Catch counts on fish tooltips",
        "A line on a fish's tooltip with how many you've caught, and where best."
    )
    AddCheckbox(
        "mapPins",
        "Show past catch spots on the world map",
        "A small pin wherever you've landed something.",
        MapChanged
    )

    AddSlider(
        "idleMinutes",
        "End a trip after",
        "A trip ends by itself after this long without a cast, or when the pole goes away.",
        { 5, 30, 1 },
        function(value)
            return ("%d min"):format(value)
        end
    )

    local ownBook = Settings.RegisterProxySetting(
        category,
        PREFIX .. "ownBook",
        Settings.VarType.Boolean,
        "A book of its own for this character",
        -- No default: the Options window's Defaults button would otherwise
        -- move the character back to the shared book without asking.
        nil,
        function()
            return ns.Me().ownBook and true or false
        end,
        function(value)
            -- The demo shows a book of its own; this is about the real one.
            if ns.Demo then
                ns.Demo.Stop()
            end
            ns.UseOwnBook(value)
        end
    )
    OnChange(PREFIX .. "ownBook", Changed)
    table.insert(registered, ownBook)
    Settings.CreateCheckbox(
        category,
        ownBook,
        "Otherwise all your characters share one Fishing Book. Nothing is moved or "
            .. "merged when you switch: each book keeps what's in it."
    )

    AddHeader("Starting again")

    AddButton("Run setup again", "Run setup", function()
        ns.Setup.Open(1)
    end, "The three questions from the first time you logged in with Fishing.")

    AddButton("Forget everything in this book", "Forget everything", function()
        -- The question is about the real book, so that's the one on show.
        if ns.Demo then
            ns.Demo.Stop()
        end
        local which = ns.Me().ownBook and "this character's Fishing Book"
            or "the Fishing Book your characters share"
        Kit.Confirm(
            ("Forget every catch, spot and trip in %s? This can't be undone."):format(which),
            ns.ForgetBook
        )
    end, "Empties the book in use. Your options stay as they are. It asks first.")
end

--- Opens the game's Options window on Creel's page.
function ns.OpenOptions()
    -- The Options window is one of the panels the game won't open in a
    -- fight. Say so the way the game does, not in chat.
    if InCombatLockdown() then
        if UIErrorsFrame and UIErrorsFrame.AddExternalErrorMessage then
            UIErrorsFrame:AddExternalErrorMessage(ERR_NOT_IN_COMBAT)
        end
        return
    end
    if category then
        Settings.OpenToCategory(category:GetID())
    end
end

-- Registered at login rather than when the addon loads, so the Options
-- window has finished setting itself up.
ns.OnEvent("PLAYER_LOGIN", function()
    category, layout = Settings.RegisterVerticalLayoutCategory(ns.TITLE)

    AddCastingOptions()
    AddPanelOptions()
    AddSoundOptions()
    AddCatchOptions()
    AddBookOptions()

    Settings.RegisterAddOnCategory(category)
end)

-- A setting changed somewhere else, by setup or a button on the panel. If
-- the page is open, its controls catch up.
local function CatchUp()
    if telling or not category or not (SettingsPanel and SettingsPanel:IsShown()) then
        return
    end
    catchingUp = true
    for _, setting in ipairs(registered) do
        pcall(setting.NotifyUpdate, setting)
    end
    catchingUp = false
end

ns.Listen("SETTINGS_CHANGED", CatchUp)

-- The panel's speaker flips the quiet setting without a word to anyone
-- else; the sound code's own message is the sign.
ns.Listen("QUIET_CHANGED", CatchUp)

-- The slash command and the addon menu ----------------------------------------

local function OpenBook()
    if ns.BookWindow and ns.BookWindow.Open then
        ns.BookWindow.Open()
    end
end

SLASH_CREEL1 = "/creel"
SlashCmdList.CREEL = function(message)
    local word = strtrim(message or ""):lower()
    if word == "" then
        if ns.Panel and ns.Panel.Toggle then
            ns.Panel.Toggle()
        else
            OpenBook()
        end
    elseif word == "book" then
        OpenBook()
    elseif word == "setup" then
        ns.Setup.Open()
    elseif (word == "demo" or word:match("^demo%s")) and ns.Demo then
        -- For screenshots: "/creel demo", then "catch", "find" or "worth".
        ns.Demo.Command(strtrim(word:sub(5)))
    else
        ns.OpenOptions()
    end
end

-- Named in the TOC, so the minimap's addon menu can call it. Left-click
-- opens the book, right-click the options.
function Creel_OnAddonCompartmentClick(_, mouseButton)
    if mouseButton == "RightButton" then
        ns.OpenOptions()
    else
        OpenBook()
    end
end
