local _, ns = ...

-- The first-run setup page, and the small window the options page uses to
-- pick a key.
--
-- Setup asks three things before anything is bound: how to cast, when the
-- panel shows, and a few finishing touches. It opens by itself once per
-- character, the first time one with Fishing logs in, a few seconds after
-- the loading screen and never over a cinematic or in a fight. Every
-- choice is held on the page until Done, so Back, "Skip setup" and the
-- close button leave the saved settings exactly as they were. Closing it
-- any of those ways still counts as having seen it: it doesn't come back
-- by itself, and the options page can run it again.

local Kit = ns.Kit

local Setup = {}
ns.Setup = Setup

local WIDTH = 420
local HEIGHT = 520

-- Until Creel has art of its own, the portrait is the profession's icon.
local PORTRAIT = "Interface\\Icons\\Trade_Fishing"

-- The fishing card from the professions book (Blizzard_ProfessionsBook,
-- Camelot templates). It's an upright card, 225 by 275, so the band across
-- the top of the page shows a slice of it; CARD_OFFSET moves the slice.
local CARD_ATLAS = "Profession-overview-card-generic-fishing"
local CARD_RATIO = 275 / 225
local CARD_OFFSET = 0
local BAND_HEIGHT = 62

-- How far in from the inset's edges the choices start.
local PAGE_LEFT = 16
local PAGE_TOP = BAND_HEIGHT + 16

local RADIO_SIZE = 16
local DOT_SIZE = 12
local NOTE_INDENT = RADIO_SIZE + 8

local BUTTON_WIDTH = 100
local KEY_BUTTON_WIDTH = 160
local KEY_BUTTON_HEIGHT = 26

-- Seconds after the loading screen before setup opens by itself, and how
-- long to wait between looks while a cinematic is playing.
local OPEN_DELAY = 4
local RETRY = 5

-- The settings setup asks about. They're copied to a draft when the page
-- opens and only written back on Done.
local DRAFTED = {
    "castStyle",
    "castKey",
    "reelWithKey",
    "doubleClickSpeed",
    "showPanel",
    "quiet",
    "tips",
    "mapPins",
}

local STEPS = {
    {
        title = "How do you want to cast?",
        note = "Nothing is bound until you press Done.",
    },
    {
        title = "When should the panel show?",
        note = "A small panel with the trip's time, tally and catches.",
    },
    {
        title = "Finishing touches",
        note = "All optional. Every choice here is in Options later too.",
    },
}

local function PlayCheckSound(on)
    PlaySound(
        on and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
    )
end

-- Choosing a key -----------------------------------------------------------

-- The mouse buttons a key may be: the middle one and the two on the side.
-- The left and right buttons belong to clicking.
local MOUSE_KEYS = { BUTTON3 = true, BUTTON4 = true, BUTTON5 = true }

-- The key button that's waiting for a press, if any. A fight starting
-- stops it, so the keyboard is never held while the player needs it.
local listening

--- What a key normally does, in a sentence, so that picking one that's
--- already in use isn't a worry.
---@param key string|nil  a binding string such as "SHIFT-F"
---@return string
function Setup.KeyUsage(key)
    if not key then
        return "Click the button, then press the key you'd like."
    end

    local action = GetBindingAction(key)
    if action and action ~= "" then
        return (
            "It's your %s key. Creel only borrows it while you hold a fishing pole, "
            .. "and never in a fight."
        ):format(GetBindingName(action))
    end
    return "Nothing else uses this key."
end

local function ShowKey(button)
    button:SetText(button.key and GetBindingText(button.key) or "Choose a key")
end

local function LetGoOfKeyboard(button)
    button:EnableKeyboard(false)
    button:SetScript("OnKeyDown", nil)
    button:SetScript("OnKeyUp", nil)
end

---@param untilReleased boolean|nil  true to keep the keyboard until the key
---                                  just pressed comes back up
local function StopListening(button, untilReleased)
    if not button.listening then
        return
    end
    button.listening = false
    if listening == button then
        listening = nil
    end

    -- Let go of the keyboard straight away and the release of the key
    -- reaches the game, which would set off whatever it's bound to there
    -- (an action button cast on release, say). The game's key bindings
    -- page waits for the release too.
    if untilReleased then
        button:SetScript("OnKeyDown", nil)
        button:SetScript("OnKeyUp", LetGoOfKeyboard)
    else
        LetGoOfKeyboard(button)
    end

    button.selected:Hide()
    button:GetHighlightTexture():SetAlpha(1)
    ShowKey(button)
end

local function Choose(button, key, untilReleased)
    StopListening(button, untilReleased)
    button.key = key
    ShowKey(button)
    button.onChosen(key)
end

local function OnKeyDown(button, key)
    if key == "ESCAPE" then
        StopListening(button, true)
        return
    end

    -- A modifier on its own is the start of a chord such as Shift-F, so
    -- wait for the rest of it.
    if IsKeyPressIgnoredForBinding(key) then
        return
    end
    Choose(button, CreateKeyChordStringUsingMetaKeyState(key), true)
end

local function StartListening(button)
    if button.listening or InCombatLockdown() then
        return
    end
    if listening then
        StopListening(listening)
    end
    listening = button
    button.listening = true

    button.selected:Show()
    button:GetHighlightTexture():SetAlpha(0)
    button:SetText("Press a key")
    button:EnableKeyboard(true)
    button:SetScript("OnKeyDown", OnKeyDown)
    button:SetScript("OnKeyUp", nil)
end

ns.OnEvent("PLAYER_REGEN_DISABLED", function()
    if listening then
        StopListening(listening)
    end
end)

--- A button like the ones on the game's key bindings page: click it, then
--- press a key (with Shift, Ctrl or Alt if you like) or a side mouse
--- button. Escape or a click cancels; right-click clears the key.
---@param onChosen fun(key: string|nil)  called with the new key, or nil
---                                      when it's cleared
local function CreateKeyButton(parent, onChosen)
    local button = CreateFrame("Button", nil, parent, "UIMenuButtonStretchTemplate")
    button:SetSize(KEY_BUTTON_WIDTH, KEY_BUTTON_HEIGHT)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button.onChosen = onChosen

    -- The glow the key bindings page puts on the button that's listening.
    button.selected = button:CreateTexture(nil, "OVERLAY")
    button.selected:SetTexture("Interface\\Buttons\\UI-Silver-Button-Select")
    button.selected:SetBlendMode("ADD")
    button.selected:SetSize(KEY_BUTTON_WIDTH, 20)
    button.selected:SetPoint("CENTER", 0, -3)
    button.selected:Hide()

    -- Hooked rather than set: the template's own handler presses the
    -- button's art in.
    button:HookScript("OnMouseDown", function(self, mouseButton)
        if not self.listening then
            return
        end
        local key = GetConvertedKeyOrButton(mouseButton)
        if MOUSE_KEYS[key] then
            Choose(self, CreateKeyChordStringUsingMetaKeyState(key))
        else
            -- A left or right click while waiting cancels, and the
            -- release that follows mustn't start it waiting again.
            self.ignoreClick = true
            StopListening(self)
        end
    end)

    button:SetScript("OnClick", function(self, mouseButton)
        if self.ignoreClick then
            self.ignoreClick = nil
            return
        end
        if mouseButton == "RightButton" then
            if self.key then
                Choose(self, nil)
            end
            return
        end
        StartListening(self)
    end)

    -- Hidden, it can't hear the release it might be waiting for.
    button:SetScript("OnHide", function(self)
        StopListening(self)
        LetGoOfKeyboard(self)
    end)

    function button:SetKey(key)
        self.key = key
        StopListening(self)
        ShowKey(self)
    end

    button.Listen = StartListening

    Kit.Tooltip(button, "Choosing a key", function()
        return {
            "Click, then press a key. Shift, Ctrl and Alt work, and so do the side "
                .. "mouse buttons.",
            "Escape cancels. Right-click clears the key.",
        }
    end)
    ShowKey(button)
    return button
end

-- The small window for one key, used from the options page. The key is
-- saved the moment it's pressed.
local keyDialog

local function CreateKeyDialog()
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetSize(320, 168)
    dialog:SetPoint("CENTER", 0, 120)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)
    dialog:EnableMouse(true)
    dialog:Hide()

    local border = CreateFrame("Frame", nil, dialog, "DialogBorderTemplate")
    border:SetAllPoints()

    dialog.header = CreateFrame("Frame", nil, dialog, "DialogHeaderTemplate")

    dialog.prompt = Kit.Text(dialog, "GameFontHighlight", "CENTER")
    dialog.prompt:SetPoint("TOP", 0, -30)
    dialog.prompt:SetText("Click the button, then press a key.")

    dialog.button = CreateKeyButton(dialog, function(key)
        ns.settings[dialog.settingKey] = key
        ns.Casting.Apply()
        ns.Send("SETTINGS_CHANGED")
        dialog.usage:SetText(Setup.KeyUsage(key))
        if dialog.onChanged then
            dialog.onChanged(key)
        end
    end)
    dialog.button:SetPoint("TOP", dialog.prompt, "BOTTOM", 0, -10)

    dialog.usage = Kit.Paragraph(dialog, "GameFontHighlightSmall", "CENTER")
    dialog.usage:SetWidth(280)
    dialog.usage:SetPoint("TOP", dialog.button, "BOTTOM", 0, -8)

    local close = Kit.Button(dialog, OKAY, BUTTON_WIDTH, function()
        dialog:Hide()
    end)
    close:SetPoint("BOTTOM", 0, 16)

    return dialog
end

--- Opens a small window for choosing one of the keys. It's saved, and
--- casting updated, as soon as a key is pressed.
---@param settingKey string  "castKey" or "castKey2"
---@param title string
---@param onChanged fun(key: string|nil)|nil
function Setup.ChooseKey(settingKey, title, onChanged)
    if InCombatLockdown() then
        return
    end
    keyDialog = keyDialog or CreateKeyDialog()
    keyDialog.settingKey = settingKey
    keyDialog.onChanged = onChanged
    keyDialog.header:Setup(title)
    keyDialog.button:SetKey(ns.settings[settingKey])
    keyDialog.usage:SetText(Setup.KeyUsage(ns.settings[settingKey]))
    keyDialog:Show()
    keyDialog.button:Listen()
end

-- Pieces of the page --------------------------------------------------------

--- A choice in a group where only one can be picked: the game's round
--- button, a label in gold and a line under it.
local function CreateRadio(parent, label, note, onClick)
    local radio = CreateFrame("Button", nil, parent)
    radio:SetSize(RADIO_SIZE, RADIO_SIZE)
    radio:SetNormalAtlas("common-radiobutton-circle")
    radio:SetHighlightAtlas("common-radiobutton-circle", "ADD")
    radio:GetHighlightTexture():SetAlpha(0.2)

    radio.dot = radio:CreateTexture(nil, "OVERLAY")
    radio.dot:SetAtlas("common-radiobutton-dot")
    radio.dot:SetSize(DOT_SIZE, DOT_SIZE)
    radio.dot:SetPoint("CENTER")
    radio.dot:Hide()

    radio.label = Kit.Text(radio, "GameFontNormal")
    radio.label:SetPoint("LEFT", radio, "RIGHT", 8, 0)
    radio.label:SetText(label)

    radio.note = Kit.Text(radio, "GameFontHighlightSmall")
    radio.note:SetPoint("TOPLEFT", radio.label, "BOTTOMLEFT", 0, -4)
    radio.note:SetText(note)

    -- The label is part of what can be clicked.
    radio:SetHitRectInsets(0, -(radio.label:GetStringWidth() + 8), 0, 0)
    radio:SetScript("OnClick", function()
        PlayCheckSound(true)
        onClick()
    end)

    function radio:SetChecked(checked)
        self.dot:SetShown(checked)
    end
    return radio
end

--- A tick box with a label and a line under it.
local function CreateCheck(parent, label, note, onClick)
    local check = CreateFrame("CheckButton", nil, parent, "MinimalCheckboxTemplate")

    check.label = Kit.Text(check, "GameFontHighlight")
    check.label:SetPoint("LEFT", check, "RIGHT", 2, 1)
    check.label:SetText(label)

    if note then
        check.note = Kit.Text(check, "GameFontDisableSmall")
        check.note:SetPoint("TOPLEFT", check.label, "BOTTOMLEFT", 0, -3)
        check.note:SetText(note)
    end

    check:SetHitRectInsets(0, -(check.label:GetStringWidth() + 4), 0, 0)
    check:SetScript("OnClick", function(self)
        local on = self:GetChecked()
        PlayCheckSound(on)
        onClick(on)
    end)

    function check:SetEnabledLook(enabled)
        self:SetEnabled(enabled)
        self.label:SetFontObject(enabled and "GameFontHighlight" or "GameFontDisable")
    end
    return check
end

-- The window ------------------------------------------------------------------

local window
local draft = {}
local step = 1
local finished = false

local function Page(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", PAGE_LEFT, -PAGE_TOP)
    page:SetPoint("BOTTOMRIGHT", -PAGE_LEFT, 10)
    page:Hide()
    return page
end

local function UpdateCastPage()
    local page = window.pages[1]
    for style, radio in pairs(page.radios) do
        radio:SetChecked(draft.castStyle == style)
    end

    local usingKey = draft.castStyle == "key"
    page.keyButton:SetEnabled(usingKey)
    page.keyUsage:SetFontObject(usingKey and "GameFontHighlightSmall" or "GameFontDisableSmall")
    page.keyUsage:SetText(Setup.KeyUsage(draft.castKey))
    page.reel:SetChecked(draft.reelWithKey)
    page.reel:SetEnabledLook(usingKey)

    local double = draft.castStyle == "double"
    page.speed:SetEnabled(double)
    page.speedLabel:SetFontObject(double and "GameFontHighlightSmall" or "GameFontDisableSmall")
end

local function CreateCastPage(parent)
    local page = Page(parent)
    local indent = NOTE_INDENT

    local function Pick(style)
        return function()
            draft.castStyle = style
            UpdateCastPage()
        end
    end

    page.radios = {}

    page.radios.key = CreateRadio(
        page,
        "One key " .. Kit.Colored("(suggested)", Kit.MUTED),
        "Press it to cast, and again at the splash to reel in.",
        Pick("key")
    )
    page.radios.key:SetPoint("TOPLEFT", 0, 0)

    page.keyButton = CreateKeyButton(page, function(key)
        draft.castKey = key
        draft.castStyle = "key"
        UpdateCastPage()
    end)
    page.keyButton:SetPoint("TOPLEFT", indent, -40)

    page.keyUsage = Kit.Paragraph(page, "GameFontHighlightSmall")
    page.keyUsage:SetPoint("TOPLEFT", page.keyButton, "BOTTOMLEFT", 0, -6)
    page.keyUsage:SetPoint("RIGHT")

    page.reel = CreateCheck(
        page,
        "Let this key reel in too",
        "Turns on the game's Interact Key while the line is out.",
        function(on)
            draft.reelWithKey = on
        end
    )
    page.reel:SetPoint("TOPLEFT", indent - 6, -112)

    page.radios.double = CreateRadio(
        page,
        "Double right-click",
        "Double right-click to cast. Right-click the bobber to reel.",
        Pick("double")
    )
    page.radios.double:SetPoint("TOPLEFT", 0, -162)

    page.speedLabel = Kit.Text(page, "GameFontHighlightSmall")
    page.speedLabel:SetPoint("TOPLEFT", indent, -206)
    page.speedLabel:SetText("Click speed")

    -- The game's own slider with steppers, its figure on the right.
    page.speed = CreateFrame("Frame", nil, page, "MinimalSliderWithSteppersTemplate")
    page.speed:SetWidth(220)
    page.speed:SetPoint("LEFT", page.speedLabel, "RIGHT", 6, 0)
    page.speed:Init(ns.settings.doubleClickSpeed, 0.2, 0.6, 8, {
        [MinimalSliderWithSteppersMixin.Label.Right] = function(value)
            return ("%.2f s"):format(value)
        end,
    })
    page.speed:RegisterCallback(
        MinimalSliderWithSteppersMixin.Event.OnValueChanged,
        function(_, value)
            draft.doubleClickSpeed = value
        end,
        page
    )

    page.radios.none = CreateRadio(
        page,
        "My own buttons",
        "Nothing is bound. Put Fishing on an action bar as usual.",
        Pick("none")
    )
    page.radios.none:SetPoint("TOPLEFT", 0, -244)

    -- Another fishing addon that casts on a key of its own, if one is on.
    page.rivals = Kit.Paragraph(page, "GameFontDisableSmall")
    page.rivals:SetPoint("TOPLEFT", 0, -292)
    page.rivals:SetPoint("RIGHT")

    return page
end

local function UpdatePanelPage()
    for choice, radio in pairs(window.pages[2].radios) do
        radio:SetChecked(draft.showPanel == choice)
    end
end

local function CreatePanelPage(parent)
    local page = Page(parent)
    local choices = {
        {
            "pole",
            "When I hold a fishing pole " .. Kit.Colored("(suggested)", Kit.MUTED),
            "Comes and goes with the pole in your hand.",
        },
        {
            "fishing",
            "When I start fishing",
            "Shows on the first cast, and hides when the trip ends.",
        },
        {
            "never",
            "Only in the Fishing Book",
            "No panel. The book has the same numbers.",
        },
    }

    page.radios = {}
    for index, choice in ipairs(choices) do
        local value = choice[1]
        local radio = CreateRadio(page, choice[2], choice[3], function()
            draft.showPanel = value
            UpdatePanelPage()
        end)
        radio:SetPoint("TOPLEFT", 0, -(index - 1) * 50)
        page.radios[value] = radio
    end
    return page
end

local function UpdateTouchesPage()
    local page = window.pages[3]
    page.quiet:SetChecked(draft.quiet)
    page.tips:SetChecked(draft.tips)
    page.ownBook:SetChecked(draft.ownBook)
    page.mapPins:SetChecked(draft.mapPins)
    page.noKey:SetShown(draft.castStyle == "key" and not draft.castKey and not ns.settings.castKey2)
end

local function CreateTouchesPage(parent)
    local page = Page(parent)

    local function Toggle(key)
        return function(on)
            draft[key] = on
        end
    end

    local rows = {
        {
            "quiet",
            "Quiet other sounds while fishing",
            "Music and voices go quiet, so the splash stands out.",
        },
        { "tips", "Tips and trivia on the catch card", "A line worth reading with each catch." },
        {
            "ownBook",
            "A Fishing Book of its own for this character",
            "Otherwise all your characters share one book.",
        },
        {
            "mapPins",
            "Show past catch spots on the world map",
            "A small pin wherever you've landed something.",
        },
    }

    for index, row in ipairs(rows) do
        local check = CreateCheck(page, row[2], row[3], Toggle(row[1]))
        check:SetPoint("TOPLEFT", -6, -(index - 1) * 50 + 6)
        page[row[1]] = check
    end

    -- One key with no key chosen still finishes; it just says so, since
    -- the key can be picked later just as well.
    page.noKey = Kit.Paragraph(page, "GameFontHighlightSmall")
    page.noKey:SetPoint("TOPLEFT", 0, -#rows * 50 - 4)
    page.noKey:SetPoint("RIGHT")
    page.noKey:SetText(
        Kit.Colored("No key chosen for casting yet.", Kit.GOLD)
            .. " Pick one on the first page, or any time later in Creel's options."
    )
    page.noKey:Hide()
    return page
end

local function ShowStep(index)
    step = index
    local info = STEPS[index]
    window.heading:SetText(info.title)
    window.subheading:SetText(info.note)

    for number, page in ipairs(window.pages) do
        page:SetShown(number == index)
        window.dots[number]:SetShown(number <= index)
    end

    window.back:SetEnabled(index > 1)
    window.next:SetText(index == #STEPS and DONE or NEXT)

    if index == 1 then
        UpdateCastPage()
    elseif index == 2 then
        UpdatePanelPage()
    else
        UpdateTouchesPage()
    end
end

--- Writes the draft back and puts it to work.
local function Finish()
    local settings = ns.settings
    for _, key in ipairs(DRAFTED) do
        settings[key] = draft[key]
    end

    local me = ns.Me()
    if (me.ownBook and true or false) ~= draft.ownBook then
        ns.UseOwnBook(draft.ownBook)
    end
    me.setupDone = true
    finished = true

    -- The quiet switch takes effect through the sound code, so a trip
    -- under way goes quiet (or loud) now rather than at the next cast.
    if ns.Sound and ns.Sound.SetQuiet then
        ns.Sound.SetQuiet(draft.quiet)
    end
    ns.Casting.Apply()
    ns.Send("SETTINGS_CHANGED")
    if ns.Panel and ns.Panel.UpdateVisibility then
        ns.Panel.UpdateVisibility()
    end
    -- Point once at the book button, so the book is found without a tour.
    if ns.Panel and ns.Panel.PulseBook then
        ns.Panel.PulseBook()
    end

    window:Hide()
end

local function CreateWindow()
    -- Named so Escape can close it, as it does the game's own windows.
    local frame = CreateFrame("Frame", "CreelSetupFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 0, 40)
    -- Above the Options window, which it's sometimes opened from.
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:Hide()

    frame:SetTitle("Welcome to Creel")
    local icon = ns.State and ns.State.spellID and C_Spell.GetSpellTexture(ns.State.spellID)
    frame:SetPortraitToAsset(icon or PORTRAIT)

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    table.insert(UISpecialFrames, frame:GetName())

    -- The strip under the title bar, beside the portrait: where you are,
    -- and the way out.
    frame.dots = {}
    local dotGap = 18
    for index = 1, #STEPS do
        local ring = frame:CreateTexture(nil, "ARTWORK")
        ring:SetAtlas("common-radiobutton-circle")
        ring:SetSize(RADIO_SIZE, RADIO_SIZE)
        ring:SetPoint("CENTER", frame, "TOP", (index - (#STEPS + 1) / 2) * dotGap, -40)

        local dot = frame:CreateTexture(nil, "OVERLAY")
        dot:SetAtlas("common-radiobutton-dot")
        dot:SetSize(DOT_SIZE, DOT_SIZE)
        dot:SetPoint("CENTER", ring)
        frame.dots[index] = dot
    end

    local skip = Kit.Link(frame, "Skip setup", function()
        frame:Hide()
    end)
    skip:SetPoint("RIGHT", frame, "TOPRIGHT", -12, -40)

    -- The band across the top of the page, with the card art behind the
    -- step's question. The art sits on a frame of its own inside one that
    -- clips, so only the slice inside the band is drawn.
    local inset = frame.Inset
    local band = CreateFrame("Frame", nil, inset)
    band:SetPoint("TOPLEFT", 3, -3)
    band:SetPoint("TOPRIGHT", -3, -3)
    band:SetHeight(BAND_HEIGHT)
    band:SetClipsChildren(true)

    if C_Texture.GetAtlasInfo(CARD_ATLAS) then
        local art = CreateFrame("Frame", nil, band)
        local width = WIDTH - 16
        art:SetSize(width, width * CARD_RATIO)
        art:SetPoint("CENTER", 0, CARD_OFFSET)
        local card = art:CreateTexture(nil, "BACKGROUND")
        card:SetAtlas(CARD_ATLAS)
        card:SetAllPoints()
        card:SetAlpha(0.75)
    end

    local rule = Kit.Rule(inset)
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", band, "BOTTOMLEFT")
    rule:SetPoint("TOPRIGHT", band, "BOTTOMRIGHT")

    frame.heading = Kit.Text(band, "GameFontNormalLarge")
    frame.heading:SetPoint("TOPLEFT", 14, -14)
    frame.subheading = Kit.Text(band, "GameFontHighlight")
    frame.subheading:SetPoint("TOPLEFT", frame.heading, "BOTTOMLEFT", 0, -6)

    window = frame
    frame.pages = {
        CreateCastPage(inset),
        CreatePanelPage(inset),
        CreateTouchesPage(inset),
    }

    -- Along the bottom, where the game puts a window's own buttons.
    frame.back = Kit.Button(frame, BACK, BUTTON_WIDTH, function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
        ShowStep(math.max(1, step - 1))
    end)
    frame.back:SetPoint("BOTTOMLEFT", 4, 4)

    frame.next = Kit.Button(frame, NEXT, BUTTON_WIDTH, function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
        if step < #STEPS then
            ShowStep(step + 1)
        else
            Finish()
        end
    end)
    frame.next:SetPoint("BOTTOMRIGHT", -6, 4)

    frame:SetScript("OnHide", function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
        -- Closed without Done: nothing changes, but it was seen.
        if not finished and ns.db then
            ns.Me().setupDone = true
        end
    end)

    return frame
end

--- Opens setup, on its first step unless told otherwise. It starts from
--- the settings as they are now.
---@param index number|nil  1 to 3
function Setup.Open(index)
    if not ns.db then
        return
    end
    window = window or CreateWindow()

    for _, key in ipairs(DRAFTED) do
        draft[key] = ns.settings[key]
    end
    draft.ownBook = ns.Me().ownBook and true or false
    finished = false

    local page = window.pages[1]
    page.keyButton:SetKey(draft.castKey)
    page.speed:SetValue(draft.doubleClickSpeed)

    local rivals = ns.Casting.Rivals and ns.Casting.Rivals() or {}
    if #rivals > 0 then
        page.rivals:SetText(
            (
                "%s is on too. Two addons answering the same press trip over each other, "
                .. "so let only one of them handle casting."
            ):format(table.concat(rivals, " and "))
        )
        page.rivals:Show()
    else
        page.rivals:Hide()
    end

    ShowStep(math.min(math.max(index or 1, 1), #STEPS))
    if not window:IsShown() then
        window:Show()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
    end
end

-- Opening by itself -----------------------------------------------------------

local loading = false
local waiting = false -- a look is already on its way
local afterCombat = false

local function InCinematicNow()
    return (InCinematic and InCinematic())
        or (IsInCinematicScene and IsInCinematicScene())
        or (MovieFrame and MovieFrame:IsShown())
end

local function Wanted()
    return ns.db
        and not ns.Me().setupDone
        and select(4, GetProfessions()) ~= nil
        and not (window and window:IsShown())
end

local LookSoon

local function Look()
    waiting = false
    if not Wanted() then
        return
    end
    if InCombatLockdown() then
        afterCombat = true
        return
    end
    if loading or InCinematicNow() then
        LookSoon(RETRY)
        return
    end
    Setup.Open()
end

function LookSoon(delay)
    if waiting or not Wanted() then
        return
    end
    waiting = true
    C_Timer.After(delay, Look)
end

ns.OnEvent("LOADING_SCREEN_ENABLED", function()
    loading = true
end)
ns.OnEvent("LOADING_SCREEN_DISABLED", function()
    loading = false
end)

ns.OnEvent("PLAYER_ENTERING_WORLD", function()
    LookSoon(OPEN_DELAY)
end)

ns.OnEvent("PLAYER_REGEN_ENABLED", function()
    if afterCombat then
        afterCombat = false
        LookSoon(OPEN_DELAY)
    end
end)

-- A character who learns Fishing later gets setup then.
ns.OnEvent("SKILL_LINES_CHANGED", function()
    LookSoon(OPEN_DELAY)
end)
