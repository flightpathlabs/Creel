local _, ns = ...

-- The panel: one small frame that keeps the trip while you fish.
--
-- From the top: the skill and three small buttons; a line that says what
-- the key will do, with the lure slot beside it; a thin bar that runs down
-- while the line is out; the trip's clock and what the water here has
-- shown so far. Under that, the catch card, where each catch lands with
-- Blizzard's own loot-toast border and glow, its worth both ways and a
-- line of tip or trivia. A unique find or an epic catch gets the grander
-- toast's art and sound for as long as it's the latest; something worth a
-- lot gets the auction house's sound. Then the trip's tally and its worth.
--
-- Folded, it's the top line alone. It hangs from UIParent, so Alt+Z hides
-- it with the rest of the interface, and it's an ordinary frame, so it
-- can show and hide in combat. The one secure piece on it, the lure
-- button, belongs to Fishing/Casting.lua and is only ever moved, shown or
-- hidden through there.
--
-- Everything is made once. A refresh fills in text and lays the pieces
-- out again under each other, and the clock ticking over only touches the
-- text that changes.

local Kit = ns.Kit

local Panel = {}
ns.Panel = Panel

-- Sizes ---------------------------------------------------------------------

local WIDTH = 280
local PADDING = 10
local INNER = WIDTH - 2 * PADDING

-- The top line, which is all a folded panel shows.
local HEADER_HEIGHT = 30
local HEADER_ICON = 16
local HEADER_BUTTON = 14
local FOLD_BUTTON = 12
local HEADER_BUTTON_GAP = 5

-- The faint look of the small buttons until the mouse is on one, so the
-- top line stays quiet.
local BUTTON_IDLE = 0.75

local STATUS_HEIGHT = 20
local STATUS_DOT = 10
local LURE_SIZE = 20
local LURE_ARROW_WIDTH = 12
local TIMER_HEIGHT = 4
local LINE_HEIGHT = 14
local LINE_GAP = 2

-- Space either side of the hairline between the parts of the panel.
local RULE_GAP = 8

-- The loot toast draws a 60 pixel border round a 52 pixel icon. The card
-- keeps the same proportions at a size that suits a small panel.
local CARD_ICON = 40
local CARD_BORDER = 46
local CARD_HEIGHT = CARD_BORDER
local CARD_TEXT_LEFT = CARD_BORDER + 8
local CARD_TEXT_WIDTH = INNER - CARD_TEXT_LEFT

-- A big moment's card sits on the toast's grander background, which is
-- 276 by 96 with the icon 22 pixels in from the left and the words after
-- it. Drawn across the panel, it keeps those proportions.
local BIG_HEIGHT = math.floor(INNER * 96 / 276 + 0.5)
local BIG_SLOT_LEFT = 20
local BIG_TEXT_LEFT = BIG_SLOT_LEFT + CARD_BORDER + 8
local BIG_TEXT_RIGHT = 18
local BIG_TEXT_WIDTH = INNER - BIG_TEXT_LEFT - BIG_TEXT_RIGHT
local BIG_TEXT_TOP = 14
local SHEEN_WIDTH = 110

local TIP_GAP = 6
local TIP_LINES = 2

local TALLY_ROWS = 5
local ROW_HEIGHT = 18
local ROW_ICON = 16
local ROW_COUNT_WIDTH = 26
local ROW_PERCENT_WIDTH = 30
local SHARE_BAR_WIDTH = 44
local SHARE_BAR_HEIGHT = 5
local MORE_HEIGHT = 18

local END_BUTTON_WIDTH = 72
local END_BUTTON_HEIGHT = 22
local END_BUTTON_GAP = 6

-- Where the panel starts out before it's ever moved: right of the middle
-- of the screen, clear of the water the player is looking at.
local DEFAULT_PLACE = { "TOPLEFT", "CENTER", 240, 160 }

-- The catch card's moment: how far the icon drops in from, and for how
-- long. A rare catch also gets a gold flash.
local DROP_FROM_SCALE = 1.3
local DROP_SECONDS = 0.35

-- A catch is rare at a spot when it's under this share of what's been
-- caught there, once the spot has this many catches to go by.
local RARE_SHARE = 0.05
local RARE_AFTER = 30

-- A trip shorter than this has no catch rate worth showing.
local RATE_AFTER = 120

-- How often the spot line and the lure's minutes are looked at again.
local SLOW_TICK = 5

-- Art and colours -------------------------------------------------------------

-- Each name was found in the client's own interface code: the loot toast
-- (Blizzard_FrameXML\Mainline\AlertFrameSystems), the channelled casting
-- bar, the voice chat speaker, the friends list's category arrow and the
-- damage meter's bars.
local BORDER_BY_QUALITY = {
    [Enum.ItemQuality.Poor] = "loottoast-itemborder-white",
    [Enum.ItemQuality.Common] = "loottoast-itemborder-white",
    [Enum.ItemQuality.Uncommon] = "loottoast-itemborder-green",
    [Enum.ItemQuality.Rare] = "loottoast-itemborder-blue",
    [Enum.ItemQuality.Epic] = "loottoast-itemborder-purple",
    [Enum.ItemQuality.Legendary] = "loottoast-itemborder-orange",
}
local GLOW = "loottoast-glow"
-- The big moment: the "upgraded" loot toast's background, with the quest
-- reward toast's as a fallback and the classic toast's own picture after
-- that; the upgrade toast's border glow and sheen. Both toasts are loaded
-- on Forever (Mainline\AlertFrameSystems).
local BIG_BACKS = { "LootToast-MoreAwesome", "loottoast-bg-questrewardupgrade" }
local TOAST_FILE = "Interface\\LootFrame\\LootToast"
local TOAST_BACK_COORDS = { 0.28222656, 0.55175781, 0.578125, 0.953125 }
local TOAST_SHEEN_COORDS = { 0.56347656, 0.73046875, 0.57421875, 0.8671875 }
local BORDER_GLOW = "loottoast-itemborder-glow"
local SHEEN = "loottoast-sheen"
local TIMER_FILL = "ui-castingbar-filling-channel"
local TIMER_BACK = "ui-castingbar-background"
local SPEAKER = "voicechat-icon-speaker"
local SPEAKER_HUSHED = "voicechat-icon-speaker-mute"
local MENU_ARROW = "friendslist-categorybutton-arrow-down"
local SHARE_FILL = "UI-HUD-CoolDownManager-Bar"
local SHARE_BACK = "ui-damagemeters-bar-shadowbg"

-- Pictures taken from the game's own items and spells, so they're always
-- there: the Fishing spell for the corner, the Expert Fishing book for the
-- book button, and a Shiny Bauble for an empty lure slot.
local FISHING_SPELL = 7620
local FISHING_BOOK_ITEM = 16083
local SHINY_BAUBLE = 6529

local MUTED = Kit.MUTED
local WHITE = { 1, 1, 1 }
local POOR_GREY = { 0.62, 0.62, 0.62 }
local TIP_COLOR = { 0.86, 0.8, 0.66 }
local WATER = { 0.3, 0.62, 0.92 }
local SEPARATOR = Kit.Colored(" · ", MUTED)

-- At a cap, where to go for the next one. The Classic route; Forever may
-- yet turn out to differ.
local TRAINING = {
    [75] = "Train at a fishing trainer",
    [150] = "Next: Expert Fishing book, Booty Bay",
    [225] = "Next: Nat Pagle, Dustwallow Marsh",
}

local VERDICTS = {
    safe = { "No getaways here at your skill", Kit.GOOD },
    risky = { "Some got away here at this skill", Kit.GOLD },
    new = { "New water", MUTED },
}

-- State -----------------------------------------------------------------------

local panel

-- Set by Panel.Toggle: shown or hidden for the rest of the session,
-- whatever the setting says. Nil goes by the setting.
local override
local overriddenSetting

-- The trip that just ended, kept on show until the next one starts, so
-- ending a trip doesn't wipe the panel the moment it's done.
local lastTrip

-- The latest catch on the card: { itemID, first, count, rare, tip, quality,
-- unique, special, valuable }. Nil before any this trip.
local latest

local Refresh

-- Small helpers ---------------------------------------------------------------

local function Plural(count, one, many)
    return ("%d %s"):format(count, count == 1 and one or many)
end

local function Ordinal(n)
    local suffix = "th"
    local lastTwo = n % 100
    if lastTwo < 11 or lastTwo > 13 then
        local last = n % 10
        suffix = last == 1 and "st" or last == 2 and "nd" or last == 3 and "rd" or "th"
    end
    return n .. suffix
end

-- "2h ago" for a price seen two hours back.
local function Ago(at)
    local seconds = math.max(0, time() - at)
    if seconds < 3600 then
        return ("%dm ago"):format(math.max(1, math.floor(seconds / 60)))
    elseif seconds < 48 * 3600 then
        return ("%dh ago"):format(math.floor(seconds / 3600))
    end
    return ("%dd ago"):format(math.floor(seconds / ns.SECONDS_PER_DAY))
end

-- "6m" for a lure, as the game counts buffs down: whole minutes rounded up.
local function ShortTime(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    if seconds >= 60 then
        return ("%dm"):format(math.ceil(seconds / 60))
    end
    return ("%ds"):format(seconds)
end

local function QualityColor(quality)
    if not quality then
        return WHITE
    end
    local r, g, b = C_Item.GetItemQualityColor(quality)
    return { r, g, b }
end

-- Item names and qualities may not be on the client yet. This calls back
-- once they are (straight away if they already are), and only once per
-- item while it waits.
local waiting = {}

local function WithItem(itemID, callback)
    if C_Item.IsItemDataCachedByID(itemID) then
        callback()
        return
    end
    waiting[itemID] = waiting[itemID] or {}
    table.insert(waiting[itemID], callback)
    if #waiting[itemID] > 1 then
        return
    end
    local item = Item:CreateFromItemID(itemID)
    if item:IsItemEmpty() then
        waiting[itemID] = nil
        return
    end
    item:ContinueOnItemLoad(function()
        local callbacks = waiting[itemID] or {}
        waiting[itemID] = nil
        for _, call in ipairs(callbacks) do
            call()
        end
    end)
end

local function OpenBook(tab, target)
    if ns.BookWindow and ns.BookWindow.Open then
        ns.BookWindow.Open(tab, target)
    end
end

-- The trip the panel is about: the one under way, or the one that just
-- ended.
local function ShownTrip()
    return ns.State.trip or lastTrip
end

-- A button made of one small picture, faint until the mouse is on it.
local function IconButton(parent, size)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    button:SetAlpha(BUTTON_IDLE)

    button.face = button:CreateTexture(nil, "ARTWORK")
    button.face:SetAllPoints()

    button.glow = button:CreateTexture(nil, "HIGHLIGHT")
    button.glow:SetBlendMode("ADD")
    button.glow:SetAlpha(0.4)
    button.glow:SetAllPoints()
    return button
end

-- Pieces that take the mouse (for a tooltip) would otherwise stop the
-- panel being dragged by them.
local function PassDragsOn(frame)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        panel:GetScript("OnDragStart")(panel)
    end)
    frame:SetScript("OnDragStop", function()
        panel:GetScript("OnDragStop")(panel)
    end)
end

-- Where it goes -----------------------------------------------------------------

-- The place is kept as it would be at scale 1, and the scale divided out
-- here, as Temper's panel and the game's Edit Mode do. A change of scale
-- then leaves the top left corner where the player put it.
local function Place()
    local scale = ns.settings.panelScale or 1
    local place = ns.settings.panelPoint
    if type(place) ~= "table" or not place[1] then
        place = DEFAULT_PLACE
    end
    panel:SetScale(scale)
    panel:ClearAllPoints()
    panel:SetPoint(
        place[1],
        UIParent,
        place[2] or place[1],
        (place[3] or 0) / scale,
        (place[4] or 0) / scale
    )
end

-- Held by its top left corner, so it grows and shrinks downwards and the
-- top line, with the fold button on it, stays put.
local function KeepPlace()
    local left, top = panel:GetLeft(), panel:GetTop()
    if not left or not top then
        return
    end
    local scale = panel:GetScale()
    ns.settings.panelPoint = { "TOPLEFT", "BOTTOMLEFT", left * scale, top * scale }
    Place()
end

-- The lure button sits over the slot while the slot can be seen.
local function SyncLureButton()
    local shown = panel:IsShown() and not ns.settings.panelCollapsed
    if shown then
        -- The layout may have moved the slot.
        ns.Casting.PlaceLureButton(panel.lure)
    end
    ns.Casting.ShowLureButton(shown)
end

-- The top line ------------------------------------------------------------------

local function HeaderText()
    local state = ns.State
    if not state.rank then
        return "Fishing"
    end
    local text = "Fishing "
        .. Kit.Colored(("%d/%d"):format(state.rank, state.maxRank or state.rank), WHITE)
    local modifier = state.modifier or 0
    if modifier > 0 then
        text = text .. " " .. Kit.Colored(("(+%d)"):format(modifier), Kit.GOOD)
    elseif modifier < 0 then
        text = text .. " " .. Kit.Colored(("(%d)"):format(modifier), Kit.BAD)
    end
    return text
end

local function RefreshHeader()
    local header = panel.header
    Kit.SetSpellIcon(header.icon, C_Spell.GetSpellTexture(ns.State.spellID or FISHING_SPELL))
    header.title:SetText(HeaderText())

    local hushed = ns.settings.quiet
    header.speaker.face:SetAtlas(hushed and SPEAKER_HUSHED or SPEAKER)
    header.speaker.glow:SetAtlas(hushed and SPEAKER_HUSHED or SPEAKER)

    Kit.ShowFolded(header.fold, ns.settings.panelCollapsed)
end

local function SpeakerTooltip()
    local lines = {}
    if ns.settings.quiet then
        table.insert(
            lines,
            "On: music, ambience, dialogue, pet and emote sounds go quiet while your "
                .. "line is out, so the splash stands out."
        )
        if ns.Sound.IsQuiet() then
            table.insert(lines, Kit.Colored("Quiet now.", Kit.GOOD))
        end
        table.insert(lines, Kit.Colored("Click to turn it off. Your sound comes back.", MUTED))
    else
        table.insert(lines, "Quiet other sounds while you fish, so the splash stands out.")
        table.insert(lines, Kit.Colored("Click to turn it on.", MUTED))
    end
    return lines
end

local function CreateHeader()
    local header = {}
    panel.header = header

    header.icon = panel:CreateTexture(nil, "ARTWORK")
    header.icon:SetSize(HEADER_ICON, HEADER_ICON)
    header.icon:SetPoint("TOPLEFT", PADDING - 1, -7)

    -- From the right: the options cog, the book, the fold and the speaker.
    local options = Kit.OptionsButton(panel, HEADER_BUTTON)
    options:SetPoint("TOPRIGHT", -(PADDING - 1), -8)
    options:SetAlpha(BUTTON_IDLE)

    local book = IconButton(panel, HEADER_BUTTON)
    book:SetPoint("RIGHT", options, "LEFT", -HEADER_BUTTON_GAP, 0)
    local bookIcon = C_Item.GetItemIconByID(FISHING_BOOK_ITEM)
    Kit.SetSpellIcon(book.face, bookIcon)
    Kit.SetSpellIcon(book.glow, bookIcon)
    book:SetScript("OnClick", function()
        if IsShiftKeyDown() then
            if ns.OpenOptions then
                ns.OpenOptions()
            end
        else
            OpenBook("collection")
        end
    end)
    Kit.Tooltip(book, "Fishing Book", function()
        return {
            "Everything you've caught, where, and what it's made you.",
            Kit.Colored("Shift-click for options.", MUTED),
        }
    end)
    header.book = book

    -- Setup ends with the book button breathing for a moment, so the
    -- player knows where the book is.
    book.pulse = book:CreateTexture(nil, "OVERLAY")
    Kit.SetSpellIcon(book.pulse, bookIcon)
    book.pulse:SetBlendMode("ADD")
    book.pulse:SetAllPoints()
    book.pulse:SetAlpha(0)
    book.pulseAnim = book.pulse:CreateAnimationGroup()
    book.pulseAnim:SetLooping("BOUNCE")
    local breathe = book.pulseAnim:CreateAnimation("Alpha")
    breathe:SetFromAlpha(0)
    breathe:SetToAlpha(0.9)
    breathe:SetDuration(0.6)
    breathe:SetSmoothing("IN_OUT")

    header.fold = Kit.FoldButton(panel, FOLD_BUTTON, "panelCollapsed", "the skill and the buttons")
    header.fold:SetPoint("RIGHT", book, "LEFT", -HEADER_BUTTON_GAP, 0)
    header.fold:SetAlpha(BUTTON_IDLE)

    local speaker = IconButton(panel, HEADER_BUTTON)
    speaker:SetPoint("RIGHT", header.fold, "LEFT", -HEADER_BUTTON_GAP, 0)
    speaker:SetScript("OnClick", function(self)
        ns.Sound.SetQuiet(not ns.settings.quiet)
        ns.Send("SETTINGS_CHANGED")
        if GameTooltip:IsOwned(self) then
            self:GetScript("OnEnter")(self)
        end
    end)
    Kit.Tooltip(speaker, "Quiet while fishing", SpeakerTooltip)
    header.speaker = speaker

    header.title = Kit.Text(panel, "GameFontNormal")
    header.title:SetPoint("LEFT", header.icon, "RIGHT", 6, 0)
    header.title:SetPoint("RIGHT", speaker, "LEFT", -6, 0)
end

-- The status line and the lure slot -------------------------------------------

-- What the key does now, in a few words, and the colour of the dot.
local function StatusOf()
    local state, settings = ns.State, ns.settings
    local key = ns.Casting.KeyText()
    local style = settings.castStyle
    local byKey = style == "key" and key ~= nil
    local shownKey = key and Kit.Colored(key, Kit.GOLD)

    if not state.spellID then
        return "Learn Fishing at a trainer", "idle"
    end
    if ns.InCombat() then
        if byKey then
            return ("Combat · %s is yours again"):format(shownKey), "combat"
        end
        return "In combat", "combat"
    end
    if not state.hasPole then
        return "Equip a fishing pole", "idle"
    end
    if state.lineOut then
        if byKey and settings.reelWithKey then
            if UnitExists("target") then
                return "Clear your target to reel", "combat"
            end
            return ("Line out · press %s at the splash"):format(shownKey), "out"
        end
        return "Line out · right-click the splash", "out"
    end
    if byKey then
        return ("Ready · press %s to cast"):format(shownKey), "ready"
    elseif style == "key" then
        return "Choose a key in Creel's options", "idle"
    elseif style == "double" then
        return "Double right-click to cast", "ready"
    end
    return "Ready to cast", "ready"
end

-- The friends list's status dots: online green for ready, away yellow for
-- a line out, busy red for combat or a target in the way.
local DOTS = {
    ready = "ready",
    out = "waiting",
    combat = "recording",
    idle = "ready",
}

local function RefreshStatus()
    if not panel then
        return
    end
    local row = panel.status
    local text, kind = StatusOf()
    row.text:SetText(text)
    Kit.SetIcon(row.dot, DOTS[kind])
    if kind == "idle" then
        row.dot:SetDesaturated(true)
        row.dot:SetAlpha(0.5)
    else
        row.dot:SetAlpha(1)
    end
    panel.timer:SetShown(ns.State.lineOut and not ns.settings.panelCollapsed)
end

local function LureName(itemID)
    local name = C_Item.GetItemNameByID(itemID)
    if not name then
        C_Item.RequestLoadItemDataByID(itemID)
    end
    return name or "a lure"
end

local function LureLabel(itemID)
    local lure = ns.Lures and ns.Lures[itemID]
    local icon = C_Item.GetItemIconByID(itemID)
    local text = LureName(itemID)
    if lure and lure.bonus then
        text = ("%s %s"):format(text, Kit.Colored(("+%d"):format(lure.bonus), Kit.GOOD))
    end
    if icon then
        text = ("|T%s:14:14|t %s"):format(icon, text)
    end
    return text
end

local function UpdateLure()
    if not panel then
        return
    end
    local slot = panel.lure
    local icon, secondsLeft = ns.Casting.CurrentLure()
    if icon then
        Kit.SetSpellIcon(slot.icon, icon)
        slot.icon:SetAlpha(1)
        slot.time:SetText(ShortTime(secondsLeft))
        slot.time:SetTextColor(unpack(secondsLeft and secondsLeft < 60 and Kit.GOLD or WHITE))
        return
    end
    -- Empty: what a click would put on, faded, or a bauble fainter still
    -- when there's nothing in the bags to use.
    local nextLure = ns.Casting.LureToUse()
    Kit.SetSpellIcon(slot.icon, C_Item.GetItemIconByID(nextLure or SHINY_BAUBLE))
    slot.icon:SetDesaturated(true)
    slot.icon:SetAlpha(nextLure and 0.6 or 0.3)
    slot.time:SetText("")
end

local function ShowLureTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Lure")

    local icon, secondsLeft = ns.Casting.CurrentLure()
    if icon then
        GameTooltip:AddLine(("On the pole, %s left."):format(ShortTime(secondsLeft)), 1, 1, 1, true)
    else
        GameTooltip:AddLine("Nothing on the pole.", 1, 1, 1, true)
    end

    local nextLure = ns.Casting.LureToUse()
    if nextLure then
        local line = ("Click to put on %s."):format(LureLabel(nextLure))
        GameTooltip:AddLine(line, 1, 1, 1, true)
    elseif ns.settings.lureChoice == 0 then
        GameTooltip:AddLine("Set to no lure.", 1, 1, 1, true)
    else
        GameTooltip:AddLine("No lure in your bags that your skill can use.", 1, 1, 1, true)
    end
    GameTooltip:AddLine("The arrow beside it picks another.", MUTED[1], MUTED[2], MUTED[3], true)
    GameTooltip:Show()
end

local function ShowLureMenu(owner)
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("Lure for the slot")
        local function Choice(label, value)
            root:CreateRadio(label, function()
                return ns.settings.lureChoice == value
            end, function()
                ns.Casting.ChooseLure(value)
                UpdateLure()
            end)
        end
        Choice("Best I can use", nil)
        for _, itemID in ipairs(ns.Casting.LuresInBags()) do
            Choice(LureLabel(itemID), itemID)
        end
        Choice("No lure", 0)
    end)
end

local function CreateStatus(body)
    local row = CreateFrame("Frame", nil, body)
    row:SetSize(INNER, STATUS_HEIGHT)
    panel.status = row

    row.dot = row:CreateTexture(nil, "ARTWORK")
    row.dot:SetSize(STATUS_DOT, STATUS_DOT)
    row.dot:SetPoint("LEFT", 1, 0)

    -- From the right: the arrow that opens the lure menu, the slot the
    -- lure button covers, and the lure's minutes left.
    local arrow = CreateFrame("Button", nil, row)
    arrow:SetSize(LURE_ARROW_WIDTH, STATUS_HEIGHT)
    arrow:SetPoint("RIGHT")
    local arrowFace = arrow:CreateTexture(nil, "ARTWORK")
    arrowFace:SetAtlas(MENU_ARROW)
    arrowFace:SetSize(LURE_ARROW_WIDTH - 2, 7)
    arrowFace:SetPoint("CENTER")
    arrowFace:SetAlpha(BUTTON_IDLE)
    local arrowGlow = arrow:CreateTexture(nil, "HIGHLIGHT")
    arrowGlow:SetAtlas(MENU_ARROW)
    arrowGlow:SetBlendMode("ADD")
    arrowGlow:SetAlpha(0.5)
    arrowGlow:SetAllPoints(arrowFace)
    arrow:SetScript("OnClick", ShowLureMenu)
    Kit.Tooltip(arrow, "Choose a lure", function()
        return { "Which lure a click on the slot puts on." }
    end)

    local slot = CreateFrame("Frame", nil, row)
    slot:SetSize(LURE_SIZE, LURE_SIZE)
    slot:SetPoint("RIGHT", arrow, "LEFT", -1, 0)
    local edge = slot:CreateTexture(nil, "BACKGROUND")
    edge:SetColorTexture(0, 0, 0, 0.7)
    edge:SetPoint("TOPLEFT", -1, 1)
    edge:SetPoint("BOTTOMRIGHT", 1, -1)
    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetAllPoints()

    -- Out of combat the lure button lies over the slot and takes the
    -- mouse; in combat, or before it's placed, the slot answers itself.
    slot:EnableMouse(true)
    slot:SetScript("OnEnter", ShowLureTooltip)
    slot:SetScript("OnLeave", GameTooltip_Hide)
    panel.lure = slot

    slot.time = Kit.Text(row, "GameFontHighlightSmall", "RIGHT")
    slot.time:SetPoint("RIGHT", slot, "LEFT", -4, 0)

    row.text = Kit.Text(row, "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row.dot, "RIGHT", 6, 0)
    row.text:SetPoint("RIGHT", slot.time, "LEFT", -6, 0)

    -- The line timer runs down the channel, since the game gives no bite
    -- event: the same art as the game's own bar for a channelled spell.
    local timer = CreateFrame("StatusBar", nil, body)
    timer:SetSize(INNER, TIMER_HEIGHT)
    timer:SetStatusBarTexture(TIMER_FILL)
    timer:SetMinMaxValues(0, 1)
    timer:Hide()
    local back = timer:CreateTexture(nil, "BACKGROUND")
    back:SetAtlas(TIMER_BACK)
    back:SetAllPoints()
    timer:SetScript("OnUpdate", function(self)
        local state = ns.State
        if not state.lineOut or not state.lineOutAt then
            self:Hide()
            return
        end
        local left = 1 - (GetTime() - state.lineOutAt) / (state.lineSeconds or 30)
        self:SetValue(math.max(0, math.min(1, left)))
    end)
    panel.timer = timer
end

-- The trip and spot lines -------------------------------------------------------

local function TripText()
    local allTime = Kit.Colored("All time", MUTED) .. " " .. ns.Hours(ns.Book().totals.seconds)
    if ns.State.trip then
        return Kit.Colored("This trip", MUTED)
            .. " "
            .. ns.Clock(ns.State.TripSeconds())
            .. SEPARATOR
            .. allTime
    elseif lastTrip then
        return Kit.Colored("Last trip", MUTED)
            .. " "
            .. ns.Clock(lastTrip.seconds)
            .. SEPARATOR
            .. allTime
    end
    return allTime
end

local function SpotText()
    local state = ns.State
    if not state.spellID then
        return ""
    end
    local verdict, spot, reason = ns.Spots.Verdict()
    local text
    if reason == "needs" then
        text = Kit.Colored(("Needs Fishing %d here"):format(spot.needsSkill), Kit.GOLD)
    else
        local words = VERDICTS[verdict] or VERDICTS.new
        text = Kit.Colored(words[1], words[2])
    end

    if state.rank and state.maxRank and state.rank >= state.maxRank then
        local hint = TRAINING[state.maxRank]
        if hint then
            text = text .. SEPARATOR .. hint
        end
    else
        local toNext = ns.Log.ToNextPoint()
        if toNext then
            text = text .. SEPARATOR .. ("%d to +1"):format(toNext)
        end
    end
    return text
end

local function UpdateSpot()
    if panel and panel:IsShown() then
        panel.spot:SetText(SpotText())
    end
end

-- The spot line opens the book's Next page, which says more than the
-- line's hint has room for. The text sits on a button of its own so it
-- can be clicked, and the panel still drags from it.
local function CreateSpotLine(body)
    local line = CreateFrame("Button", nil, body)
    line:SetSize(INNER, LINE_HEIGHT)

    panel.spot = Kit.Text(line, "GameFontHighlightSmall")
    panel.spot:SetWidth(INNER)
    panel.spot:SetPoint("LEFT")

    line:SetScript("OnClick", function()
        OpenBook("next")
    end)
    line:SetScript("OnEnter", function(self)
        SetCursor("INTERACT_CURSOR")
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click to see what's next for your fishing.", 1, 1, 1)
        GameTooltip:Show()
    end)
    line:SetScript("OnLeave", function()
        ResetCursor()
        GameTooltip_Hide()
    end)
    PassDragsOn(line)
    panel.spotLine = line
end

-- The catch card ----------------------------------------------------------------

local function ValuesText(itemID)
    local vendor = ns.Values.Vendor(itemID)
    local auction, _, seenAt = ns.Values.Auction(itemID)

    local vendorPart
    if vendor and vendor > 0 then
        vendorPart = Kit.Colored("Vendor", MUTED) .. " " .. ns.Money(vendor)
    end
    local auctionPart = Kit.Colored("no auction price yet", MUTED)
    if auction then
        auctionPart = Kit.Colored("Auction", MUTED) .. " ~" .. ns.Money(auction)
    end
    local age = (auction and seenAt) and Kit.Colored((" (%s)"):format(Ago(seenAt)), MUTED) or ""

    local function Join(last)
        if vendorPart then
            return vendorPart .. SEPARATOR .. last
        end
        return last
    end
    return Join(auctionPart .. age), Join(auctionPart)
end

local function DetailText(quality)
    local parts = {}
    if latest.rare then
        table.insert(parts, Kit.Colored(("Rare here: 1 in %d"):format(latest.rare), Kit.GOLD))
    elseif quality then
        local word = _G["ITEM_QUALITY" .. quality .. "_DESC"]
        if word then
            table.insert(parts, Kit.Colored(word, MUTED))
        end
    end
    if latest.first then
        table.insert(parts, Kit.Colored("First ever!", Kit.GOLD))
    elseif latest.count then
        table.insert(parts, Ordinal(latest.count) .. " this trip")
    end
    return table.concat(parts, SEPARATOR)
end

-- A unique find, or anything epic or better, gets the big moment unless
-- the player has switched it off.
local function IsBig(this)
    return this and this.special and ns.settings.specialEffects
end

-- A catch worth a lot gets the auction house's sound and its worth in
-- gold, both under the one setting.
local function IsValuable(this)
    return this and this.valuable and ns.settings.valuableSound
end

-- The banner over a big moment's name, in the item's own colour where
-- that's grand enough to show, and the game's gold otherwise.
local function BannerFor(this, quality)
    local grand = quality and quality >= Enum.ItemQuality.Epic
    local color = grand and QualityColor(quality) or Kit.GOLD
    if this.unique then
        return "Unique find!", color
    elseif quality and quality >= Enum.ItemQuality.Legendary then
        return "Legendary catch!", color
    end
    return "Epic catch!", color
end

-- One of the game's own sounds, on the effects channel, so quietening the
-- rest while fishing leaves it alone.
local function PlayKit(name)
    local kit = SOUNDKIT and SOUNDKIT[name]
    if kit then
        PlaySound(kit, "SFX")
    end
end

-- The card in one of its two shapes: the toast-sized one every catch
-- gets, or the big moment's, on the grander background with a banner.
local function ShapeCard(big)
    local card = panel.card
    card:SetHeight(big and BIG_HEIGHT or CARD_HEIGHT)
    card.back:SetShown(big)
    card.banner:SetShown(big)

    card.slot:ClearAllPoints()
    card.name:ClearAllPoints()
    if big then
        card.slot:SetPoint("LEFT", BIG_SLOT_LEFT, 0)
        card.name:SetPoint("TOPLEFT", card.banner, "BOTTOMLEFT", 0, -3)
    else
        card.slot:SetPoint("TOPLEFT")
        card.name:SetPoint("TOPLEFT", CARD_TEXT_LEFT, -2)
    end
    card.textWidth = big and BIG_TEXT_WIDTH or CARD_TEXT_WIDTH
    for _, text in ipairs({ card.name, card.detail, card.values }) do
        text:SetWidth(card.textWidth)
    end
end

local function FillPlaceholder()
    local card = panel.card
    ShapeCard(false)
    Kit.SetSpellIcon(card.icon, C_Spell.GetSpellTexture(ns.State.spellID or FISHING_SPELL))
    card.icon:SetDesaturated(true)
    card.icon:SetAlpha(0.25)
    card.border:SetAtlas(BORDER_BY_QUALITY[Enum.ItemQuality.Common])
    card.border:SetVertexColor(1, 1, 1)
    card.border:SetAlpha(0.3)
    card.name:SetText("")
    card.detail:SetText("")
    card.values:SetText("")
    card.empty:Show()
    card.slot.itemID = nil
end

local function FillCatch()
    local card = panel.card
    local itemID = latest.itemID
    card.empty:Hide()
    card.slot.itemID = itemID

    Kit.SetSpellIcon(card.icon, C_Item.GetItemIconByID(itemID))
    card.icon:SetAlpha(1)

    local quality = C_Item.GetItemQualityByID(itemID) or latest.quality
    local big = IsBig(latest)
    ShapeCard(big)
    if big then
        local words, color = BannerFor(latest, quality)
        card.banner:SetText(words)
        card.banner:SetTextColor(unpack(color))
    end

    card.border:SetAtlas(BORDER_BY_QUALITY[quality] or BORDER_BY_QUALITY[Enum.ItemQuality.Common])
    card.border:SetAlpha(1)
    -- The game has no grey loot border, so poor catches get the white one
    -- dimmed to their colour.
    if quality == Enum.ItemQuality.Poor then
        card.border:SetVertexColor(unpack(POOR_GREY))
    else
        card.border:SetVertexColor(1, 1, 1)
    end

    card.name:SetText(C_Item.GetItemNameByID(itemID) or "")
    card.name:SetTextColor(unpack(QualityColor(quality)))
    card.detail:SetText(DetailText(quality))

    -- Something worth a lot (and not already having its big moment) says
    -- so in gold, in place of the two prices.
    local worth = ns.Values.Auction(itemID) or ns.Values.Vendor(itemID)
    if IsValuable(latest) and not big and worth then
        card.values:SetText(Kit.Colored("Worth ", Kit.GOLD) .. ns.Money(worth))
        return
    end

    -- The price's age goes first if the line runs too long, never a price.
    local full, short = ValuesText(itemID)
    card.values:SetText(full)
    if card.values:GetUnboundedStringWidth() > card.textWidth then
        card.values:SetText(short)
    end
end

local function Play(anim)
    anim:Stop()
    anim:GetParent():Show()
    anim:Play()
end

-- The icon drops in and settles, and the toast's glow washes over the
-- card and fades. A rare catch gets a gold flash on top.
--
-- A big moment gets more, the way the game's grander toasts do: a burst
-- of light in the banner's colour, the border flaring, a sheen across the
-- card and the epic-loot sound, all done inside a second and a half. A
-- catch worth a lot gets the auction house's sound and a gold glint on
-- its worth. Never both sounds: the big moment wins.
local function Celebrate(this)
    if not panel or not panel:IsVisible() then
        return
    end
    local big = IsBig(this)
    if big then
        local quality = this.quality or C_Item.GetItemQualityByID(this.itemID)
        if quality and quality >= Enum.ItemQuality.Legendary then
            PlayKit("UI_LEGENDARY_LOOT_TOAST")
        else
            PlayKit("UI_EPICLOOT_TOAST")
        end
    elseif IsValuable(this) then
        PlayKit("AUCTION_WINDOW_OPEN")
    end

    if ns.settings.panelCollapsed then
        return
    end
    local card = panel.card
    card.drop:Stop()
    card.drop:Play()

    -- The washes are sized to the card's shape at the moment.
    local height = card:GetHeight()
    card.glow:SetSize(INNER + 14, height + 16)
    card.flash:SetSize(INNER + 14, height + 16)
    Play(card.glow.anim)

    if big then
        local _, color = BannerFor(this, this.quality or C_Item.GetItemQualityByID(this.itemID))
        card.burst:SetSize(INNER + 30, height + 34)
        card.burst:SetVertexColor(unpack(color))
        Play(card.burst.anim)
        Play(card.back.anim)
        Play(card.borderGlow.anim)
        Play(card.sheen.anim)
    elseif this.rare then
        Play(card.flash.anim)
    end
    if IsValuable(this) and not big then
        local width = math.min(card.values:GetUnboundedStringWidth(), card.textWidth)
        card.glint:SetWidth(width + 36)
        Play(card.glint.anim)
    end
end

-- Alpha steps one after another: { from, to, seconds }.
local function AddFades(anim, steps)
    for order, step in ipairs(steps) do
        local fade = anim:CreateAnimation("Alpha")
        fade:SetFromAlpha(step[1])
        fade:SetToAlpha(step[2])
        fade:SetDuration(step[3])
        fade:SetOrder(order)
    end
end

-- A glow over the card that comes up and fades, as the loot toast's does.
local function CreateGlow(card, color, steps)
    local glow = card:CreateTexture(nil, "OVERLAY")
    glow:SetAtlas(GLOW)
    glow:SetBlendMode("ADD")
    glow:SetSize(INNER + 14, CARD_HEIGHT + 16)
    glow:SetPoint("CENTER")
    glow:SetVertexColor(unpack(color))
    -- Dark until the animation lights it, or it flashes for a frame first.
    glow:SetAlpha(0)
    glow:Hide()

    glow.anim = glow:CreateAnimationGroup()
    AddFades(glow.anim, steps)
    glow.anim:SetScript("OnFinished", function()
        glow:Hide()
    end)
    return glow
end

-- Points a texture at the first of some atlases the client has.
local function SetFirstAtlas(texture, atlases)
    for _, atlas in ipairs(atlases) do
        if C_Texture.GetAtlasInfo(atlas) then
            texture:SetAtlas(atlas)
            return true
        end
    end
    return false
end

-- The big moment's pieces: the background under everything, the border's
-- flare on the icon, and the sheen that crosses the card.
local function CreateBigMoment(card)
    local back = card:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    if not SetFirstAtlas(back, BIG_BACKS) then
        back:SetTexture(TOAST_FILE)
        back:SetTexCoord(unpack(TOAST_BACK_COORDS))
    end
    back:Hide()
    back.anim = back:CreateAnimationGroup()
    AddFades(back.anim, { { 0, 1, 0.3 } })
    card.back = back

    card.burst = CreateGlow(card, WHITE, {
        { 0, 1, 0.15 },
        { 1, 0.6, 0.25 },
        { 0.6, 0, 0.7 },
    })

    -- The flare is drawn larger than the border it lights, by as much as
    -- the game's own pair of pictures differ.
    local flare = card.slot:CreateTexture(nil, "OVERLAY")
    flare:SetBlendMode("ADD")
    flare:SetPoint("CENTER")
    local glowInfo = C_Texture.GetAtlasInfo(BORDER_GLOW)
    local borderInfo = C_Texture.GetAtlasInfo(BORDER_BY_QUALITY[Enum.ItemQuality.Common])
    local size = CARD_BORDER * 1.4
    if glowInfo and borderInfo and borderInfo.width > 0 then
        size = CARD_BORDER * glowInfo.width / borderInfo.width
    end
    flare:SetSize(size, size)
    if glowInfo then
        flare:SetAtlas(BORDER_GLOW)
    else
        flare:SetAtlas(GLOW)
    end
    flare:SetAlpha(0)
    flare:Hide()
    flare.anim = flare:CreateAnimationGroup()
    local rise = flare.anim:CreateAnimation("Alpha")
    rise:SetFromAlpha(0)
    rise:SetToAlpha(1)
    rise:SetDuration(0.3)
    rise:SetSmoothing("IN")
    rise:SetOrder(1)
    local fall = flare.anim:CreateAnimation("Alpha")
    fall:SetFromAlpha(1)
    fall:SetToAlpha(0)
    fall:SetDuration(0.8)
    fall:SetOrder(2)
    flare.anim:SetScript("OnFinished", function()
        flare:Hide()
    end)
    card.borderGlow = flare

    -- The sheen runs left to right across the words, as on the game's
    -- upgrade toast, and is gone before it reaches the far edge.
    local sheen = card:CreateTexture(nil, "OVERLAY")
    sheen:SetBlendMode("ADD")
    sheen:SetSize(SHEEN_WIDTH, BIG_HEIGHT - 16)
    sheen:SetPoint("LEFT", 4, 0)
    if C_Texture.GetAtlasInfo(SHEEN) then
        sheen:SetAtlas(SHEEN)
    else
        sheen:SetTexture(TOAST_FILE)
        sheen:SetTexCoord(unpack(TOAST_SHEEN_COORDS))
    end
    sheen:SetAlpha(0)
    sheen:Hide()
    sheen.anim = sheen:CreateAnimationGroup()
    sheen.anim:SetToFinalAlpha(true)
    local show = sheen.anim:CreateAnimation("Alpha")
    show:SetStartDelay(0.25)
    show:SetFromAlpha(0)
    show:SetToAlpha(1)
    show:SetDuration(0.15)
    local sweep = sheen.anim:CreateAnimation("Translation")
    sweep:SetStartDelay(0.25)
    sweep:SetOffset(INNER - SHEEN_WIDTH - 8, 0)
    sweep:SetDuration(0.7)
    local hide = sheen.anim:CreateAnimation("Alpha")
    hide:SetStartDelay(0.7)
    hide:SetFromAlpha(1)
    hide:SetToAlpha(0)
    hide:SetDuration(0.25)
    sheen.anim:SetScript("OnFinished", function()
        sheen:Hide()
    end)
    card.sheen = sheen
end

local function CreateCard(body)
    local card = CreateFrame("Frame", nil, body)
    card:SetSize(INNER, CARD_HEIGHT)
    panel.card = card

    -- The icon and its border sit in a frame of their own, so the drop-in
    -- can scale them together about their middle.
    local slot = CreateFrame("Frame", nil, card)
    slot:SetSize(CARD_BORDER, CARD_BORDER)
    slot:SetPoint("TOPLEFT")
    slot:EnableMouse(true)
    slot:SetScript("OnEnter", function(self)
        if self.itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self.itemID)
            GameTooltip:Show()
        end
    end)
    slot:SetScript("OnLeave", GameTooltip_Hide)
    PassDragsOn(slot)
    card.slot = slot

    card.icon = slot:CreateTexture(nil, "BORDER")
    card.icon:SetSize(CARD_ICON, CARD_ICON)
    card.icon:SetPoint("CENTER")

    card.border = slot:CreateTexture(nil, "ARTWORK")
    card.border:SetSize(CARD_BORDER, CARD_BORDER)
    card.border:SetPoint("CENTER")

    card.drop = slot:CreateAnimationGroup()
    local scale = card.drop:CreateAnimation("Scale")
    scale:SetScaleFrom(DROP_FROM_SCALE, DROP_FROM_SCALE)
    scale:SetScaleTo(1, 1)
    scale:SetDuration(DROP_SECONDS)
    scale:SetSmoothing("OUT")
    local appear = card.drop:CreateAnimation("Alpha")
    appear:SetFromAlpha(0)
    appear:SetToAlpha(1)
    appear:SetDuration(DROP_SECONDS * 0.6)
    appear:SetSmoothing("OUT")

    card.glow = CreateGlow(card, WHITE, { { 0, 1, 0.2 }, { 1, 0, 0.5 } })
    card.flash = CreateGlow(card, Kit.GOLD, {
        { 0, 1, 0.15 },
        { 1, 0.3, 0.2 },
        { 0.3, 1, 0.15 },
        { 1, 0, 0.6 },
    })
    CreateBigMoment(card)

    -- A big moment's banner sits over the name, where the toast says "You
    -- received".
    card.banner = Kit.Text(card, "GameFontNormal")
    card.banner:SetPoint("TOPLEFT", BIG_TEXT_LEFT, -BIG_TEXT_TOP)
    card.banner:SetWidth(BIG_TEXT_WIDTH)
    card.banner:Hide()

    -- Name on top, as the toast has it, then the quality and the count,
    -- then what it's worth.
    card.textWidth = CARD_TEXT_WIDTH
    card.name = Kit.Text(card, "GameFontNormalMed3")
    card.name:SetPoint("TOPLEFT", CARD_TEXT_LEFT, -2)
    card.name:SetWidth(CARD_TEXT_WIDTH)

    card.detail = Kit.Text(card, "GameFontHighlightSmall")
    card.detail:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -3)
    card.detail:SetWidth(CARD_TEXT_WIDTH)

    card.values = Kit.Text(card, "GameFontHighlightSmall")
    card.values:SetPoint("TOPLEFT", card.detail, "BOTTOMLEFT", 0, -3)
    card.values:SetWidth(CARD_TEXT_WIDTH)

    -- A gold glint behind the worth of something worth a lot.
    card.glint = CreateGlow(card, Kit.GOLD, { { 0, 0.9, 0.15 }, { 0.9, 0, 0.8 } })
    card.glint:ClearAllPoints()
    card.glint:SetPoint("LEFT", card.values, "LEFT", -18, 0)
    card.glint:SetHeight(24)

    card.empty = Kit.Text(card, "GameFontHighlightSmall")
    card.empty:SetPoint("LEFT", CARD_TEXT_LEFT, 0)
    card.empty:SetWidth(CARD_TEXT_WIDTH)
    card.empty:SetTextColor(unpack(MUTED))
    card.empty:SetText("Your next catch will land here.")

    local tip = Kit.Paragraph(body, "GameFontHighlightSmall")
    tip:SetWidth(INNER)
    tip:SetTextColor(unpack(TIP_COLOR))
    tip:SetMaxLines(TIP_LINES)
    panel.tip = tip
end

-- The tally ---------------------------------------------------------------------

local function SortedCatches(trip)
    local list = {}
    for itemID, count in pairs(trip.catches or {}) do
        table.insert(list, { itemID = itemID, count = count })
    end
    table.sort(list, function(a, b)
        if a.count ~= b.count then
            return a.count > b.count
        end
        return a.itemID < b.itemID
    end)
    return list
end

local function CreateRow(body)
    local row = CreateFrame("Button", nil, body)
    row:SetSize(INNER, ROW_HEIGHT)
    Kit.DressRow(row)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ROW_ICON, ROW_ICON)
    row.icon:SetPoint("LEFT", 2, 0)

    row.percent = Kit.Text(row, "GameFontHighlightSmall", "RIGHT")
    row.percent:SetWidth(ROW_PERCENT_WIDTH)
    row.percent:SetPoint("RIGHT", -2, 0)
    row.percent:SetTextColor(unpack(MUTED))

    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetSize(SHARE_BAR_WIDTH, SHARE_BAR_HEIGHT)
    bar:SetPoint("RIGHT", row.percent, "LEFT", -6, 0)
    bar:SetStatusBarTexture(SHARE_FILL)
    bar:GetStatusBarTexture():SetVertexColor(unpack(WATER))
    bar:SetMinMaxValues(0, 1)
    local back = bar:CreateTexture(nil, "BACKGROUND")
    back:SetAtlas(SHARE_BACK)
    back:SetAllPoints()
    row.bar = bar

    row.count = Kit.Text(row, "GameFontHighlightSmall", "RIGHT")
    row.count:SetWidth(ROW_COUNT_WIDTH)
    row.count:SetPoint("RIGHT", bar, "LEFT", -6, 0)

    row.name = Kit.Text(row, "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.name:SetPoint("RIGHT", row.count, "LEFT", -6, 0)

    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.itemID)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self)
        OpenBook("collection", self.itemID)
    end)
    PassDragsOn(row)
    return row
end

local function FillRow(row, entry, total)
    local itemID = entry.itemID
    row.itemID = itemID
    Kit.SetSpellIcon(row.icon, C_Item.GetItemIconByID(itemID))

    local name = C_Item.GetItemNameByID(itemID)
    if not name and not waiting[itemID] then
        WithItem(itemID, function()
            Refresh()
        end)
    end
    row.name:SetText(name or "")
    row.name:SetTextColor(unpack(QualityColor(C_Item.GetItemQualityByID(itemID))))

    local share = total > 0 and entry.count / total or 0
    row.count:SetText(entry.count)
    row.bar:SetValue(share)
    row.percent:SetText(("%d%%"):format(math.floor(share * 100 + 0.5)))
end

-- The footer --------------------------------------------------------------------

local function SkillGained(trip)
    local to = trip == ns.State.trip and ns.State.rank or trip.skillTo
    if to and trip.skillFrom then
        return to - trip.skillFrom
    end
    return 0
end

local function CatchesText(trip)
    if (trip.caught or 0) == 0 then
        return Kit.Colored("No catches yet", MUTED)
    end
    local parts = { Plural(trip.caught, "catch", "catches") }
    local seconds = trip == ns.State.trip and ns.State.TripSeconds() or trip.seconds or 0
    if seconds >= RATE_AFTER then
        table.insert(parts, ("%d an hour"):format(math.floor(trip.caught * 3600 / seconds + 0.5)))
    end
    local gained = SkillGained(trip)
    if gained > 0 then
        table.insert(parts, Kit.Colored(("+%d skill"):format(gained), Kit.GOOD))
    end
    return table.concat(parts, SEPARATOR)
end

local function WorthText(trip)
    local parts = {}
    if (trip.vendor or 0) > 0 then
        table.insert(parts, "vendor " .. ns.Money(trip.vendor))
    end
    if (trip.auction or 0) > 0 then
        table.insert(parts, "auction ~" .. ns.Money(trip.auction))
    end
    if #parts == 0 then
        return nil
    end
    return Kit.Colored("Worth:", MUTED) .. " " .. table.concat(parts, SEPARATOR)
end

-- Laying it out -----------------------------------------------------------------

-- Fills every part of the body and stacks the parts that have something
-- to show under each other, then sizes the panel to fit.
local function LayOutBody()
    local body = panel.body
    local y = 0

    local function Put(region, height, gap)
        y = y + (gap or 0)
        region:ClearAllPoints()
        region:SetPoint("TOPLEFT", body, "TOPLEFT", PADDING, -y)
        region:Show()
        y = y + height
    end

    local rules = 0
    local function Rule()
        rules = rules + 1
        local rule = panel.rules[rules]
        rule:ClearAllPoints()
        rule:SetPoint("TOPLEFT", body, "TOPLEFT", PADDING, -(y + RULE_GAP))
        rule:SetWidth(INNER)
        rule:Show()
        y = y + RULE_GAP * 2 + 1
    end

    -- The status line, with room kept under it for the line timer, so the
    -- panel doesn't jump with every cast.
    RefreshStatus()
    UpdateLure()
    Put(panel.status, STATUS_HEIGHT)
    Put(panel.timer, TIMER_HEIGHT, 1)
    panel.timer:SetShown(ns.State.lineOut)

    panel.trip:SetText(TripText())
    Put(panel.trip, LINE_HEIGHT, 4)
    local spot = SpotText()
    panel.spot:SetText(spot)
    if spot ~= "" then
        Put(panel.spotLine, LINE_HEIGHT, LINE_GAP)
    else
        panel.spotLine:Hide()
    end

    -- The catch card, and its line of trivia when there is one.
    Rule()
    if latest then
        FillCatch()
    else
        FillPlaceholder()
    end
    Put(panel.card, panel.card:GetHeight())

    local tip = panel.tip
    local tipText = latest and ns.settings.tips and latest.tip
    if tipText then
        tip:SetText(tipText)
        local _, fontHeight = tip:GetFont()
        local most = TIP_LINES * (fontHeight or 10) + (TIP_LINES - 1) * 3 + 2
        Put(tip, math.min(tip:GetStringHeight(), most), TIP_GAP)
    else
        tip:Hide()
    end

    -- The tally: the trip's catches, most first.
    local trip = ShownTrip()
    local catches = trip and SortedCatches(trip) or {}
    local shownRows = math.min(#catches, TALLY_ROWS)
    if shownRows > 0 then
        Rule()
        for index = 1, shownRows do
            FillRow(panel.rows[index], catches[index], trip.caught or 0)
            Put(panel.rows[index], ROW_HEIGHT)
        end
    end
    for index = shownRows + 1, TALLY_ROWS do
        panel.rows[index]:Hide()
    end
    if #catches > TALLY_ROWS then
        panel.more:SetText(("+ %d more"):format(#catches - TALLY_ROWS))
        panel.more:SetWidth(panel.more:GetFontString():GetStringWidth() + 8)
        Put(panel.more, MORE_HEIGHT, 1)
    else
        panel.more:Hide()
    end

    -- The footer: the trip's catches and worth, and the button that ends it.
    if trip then
        Rule()
        panel.catches:SetText(CatchesText(trip))
        Put(panel.catches, LINE_HEIGHT)
        local worth = WorthText(trip)
        if worth then
            panel.worth:SetText(worth)
            Put(panel.worth, LINE_HEIGHT, LINE_GAP)
        else
            panel.worth:Hide()
        end
    else
        panel.catches:Hide()
        panel.worth:Hide()
    end

    if ns.State.trip then
        y = y + END_BUTTON_GAP
        panel.endTrip:ClearAllPoints()
        panel.endTrip:SetPoint("TOPRIGHT", body, "TOPRIGHT", -PADDING, -y)
        panel.endTrip:Show()
        y = y + END_BUTTON_HEIGHT
    else
        panel.endTrip:Hide()
    end

    for index = rules + 1, #panel.rules do
        panel.rules[index]:Hide()
    end

    local height = y + PADDING
    body:SetHeight(height)
    panel:SetHeight(HEADER_HEIGHT + height)
end

local function ApplySettings()
    local settings = ns.settings
    -- Scales are stored as floats, so an exact comparison would never match
    -- at anything but 1 and re-place the panel on every refresh.
    if math.abs(panel:GetScale() - (settings.panelScale or 1)) > 0.001 then
        Place()
    end
    panel:SetAlpha(settings.panelAlpha or 1)
    panel.soundNote:SetScale(panel:GetScale())
end

Refresh = function()
    if not panel then
        return
    end
    ApplySettings()
    RefreshHeader()
    if not panel:IsShown() then
        return
    end

    if ns.settings.panelCollapsed then
        panel.body:Hide()
        panel:SetHeight(HEADER_HEIGHT)
    else
        panel.body:Show()
        LayOutBody()
    end
    SyncLureButton()
end

-- Only the text that moves with the clock.
local function UpdateClock()
    if not panel or not panel:IsShown() or ns.settings.panelCollapsed then
        return
    end
    panel.trip:SetText(TripText())
    local trip = ShownTrip()
    if trip and panel.catches:IsShown() then
        panel.catches:SetText(CatchesText(trip))
    end
end

-- Sound left off by a crash ---------------------------------------------------------

-- A small note above the panel, never more than an offer: nothing changes
-- until the player clicks Restore. It sits apart from the panel so it's
-- seen even when the panel isn't.
local function CreateSoundNote()
    local note = CreateFrame("Frame", nil, UIParent, "TooltipBackdropTemplate")
    note:SetFrameStrata("LOW")
    note:SetHeight(32)
    note:SetClampedToScreen(true)
    note:SetPoint("BOTTOMLEFT", panel, "TOPLEFT", 0, 4)
    note:Hide()

    note.text = Kit.Text(note, "GameFontHighlightSmall")
    note.text:SetPoint("LEFT", PADDING, 0)
    note.text:SetText("Sound still off from fishing?")

    note.restore = Kit.Button(note, "Restore", 72, function()
        ns.Sound.RestoreRemembered()
        note:Hide()
    end)
    note.restore:SetPoint("RIGHT", -PADDING + 2, 0)

    note.dismiss = Kit.Link(note, "Leave it", function()
        note:Hide()
    end)
    note.dismiss:SetPoint("RIGHT", note.restore, "LEFT", -4, 0)

    note:SetWidth(
        PADDING + note.text:GetStringWidth() + 8 + note.dismiss:GetWidth() + 4 + 72 + PADDING
    )
    Kit.Tooltip(note.restore, "Restore sound", function()
        return {
            "Puts music, ambience and dialogue back the way they were when you "
                .. "last logged out cleanly.",
        }
    end)
    panel.soundNote = note
end

-- Offered once, at login or a reload, and not again once dismissed.
local function OfferSound()
    if panel and ns.Sound.LooksStuck() then
        panel.soundNote:Show()
    end
end

-- Taken away if the music comes back on some other way.
local function WithdrawSound()
    local note = panel and panel.soundNote
    if note and note:IsShown() and C_CVar.GetCVar("Sound_EnableMusic") == "1" then
        note:Hide()
    end
end

-- Building it -------------------------------------------------------------------

local function Create()
    panel = CreateFrame("Frame", nil, UIParent, "TooltipBackdropTemplate")
    panel:SetSize(WIDTH, HEADER_HEIGHT)
    panel:SetFrameStrata("LOW")
    panel:SetClampedToScreen(true)
    panel:Hide()
    Place()

    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self)
        if not ns.settings.panelLocked then
            self:StartMoving()
        end
    end)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        KeepPlace()
        ns.Casting.PlaceLureButton(panel.lure)
    end)

    CreateHeader()

    -- Everything below the top line hangs from the body, so folding the
    -- panel is hiding the one frame.
    local body = CreateFrame("Frame", nil, panel)
    body:SetPoint("TOPLEFT", 0, -HEADER_HEIGHT)
    body:SetPoint("TOPRIGHT", 0, -HEADER_HEIGHT)
    body:SetHeight(1)
    panel.body = body

    CreateStatus(body)

    panel.trip = Kit.Text(body, "GameFontHighlightSmall")
    panel.trip:SetWidth(INNER)
    CreateSpotLine(body)

    CreateCard(body)

    panel.rows = {}
    for index = 1, TALLY_ROWS do
        panel.rows[index] = CreateRow(body)
    end
    panel.more = Kit.Link(body, "+ more", function()
        local trip = ShownTrip()
        OpenBook("trips", trip and trip.startAt)
    end)

    panel.catches = Kit.Text(body, "GameFontHighlightSmall")
    panel.catches:SetWidth(INNER)
    panel.worth = Kit.Text(body, "GameFontHighlightSmall")
    panel.worth:SetWidth(INNER)

    panel.endTrip = Kit.Button(body, "End trip", END_BUTTON_WIDTH, function()
        ns.State.EndTrip()
    end)
    panel.endTrip:SetHeight(END_BUTTON_HEIGHT)

    panel.rules = {}
    for index = 1, 3 do
        local rule = Kit.Rule(body)
        rule:SetHeight(1)
        panel.rules[index] = rule
    end

    CreateSoundNote()

    -- The secure lure button is laid over the slot here, and again each
    -- time the panel is laid out or moved (it isn't anchored to the panel;
    -- see Casting.PlaceLureButton).
    ns.Casting.PlaceLureButton(panel.lure)
end

-- What others call ----------------------------------------------------------------

local function ShouldShow()
    local setting = ns.settings.showPanel
    if override ~= nil and setting == overriddenSetting then
        return override
    end
    override = nil
    if setting == "pole" then
        return ns.State.hasPole
    elseif setting == "fishing" then
        return ns.State.trip ~= nil
    end
    return false
end

--- Shows or hides the panel by the setting (or by Toggle, this session).
function Panel.UpdateVisibility()
    if not panel then
        return
    end
    local shown = ShouldShow() and true or false
    if shown ~= panel:IsShown() then
        panel:SetShown(shown)
    end
    if shown then
        Refresh()
    end
    SyncLureButton()
end

--- Redraws the panel. Others call this after changing a setting.
function Panel.Refresh()
    Refresh()
end

--- Shows the panel if it's hidden and hides it if it's shown, for the
--- rest of the session or until the setting is changed.
function Panel.Toggle()
    if not panel then
        return
    end
    override = not panel:IsShown()
    overriddenSetting = ns.settings.showPanel
    Panel.UpdateVisibility()
end

--- A few breaths of light on the book button, so a new player sees where
--- the book is. Setup calls it when it's done.
function Panel.PulseBook()
    -- A pulse nobody can see is no help: with the panel hidden (no pole in
    -- hand, or the panel set to stay away) the book is found from /creel.
    if not panel or not panel:IsVisible() then
        return
    end
    local anim = panel.header.book.pulseAnim
    anim:Stop()
    anim:Play()
    C_Timer.After(5, function()
        anim:Stop()
    end)
end

-- Listening -----------------------------------------------------------------------

ns.Listen("DATA_READY", function()
    Create()
    Panel.UpdateVisibility()
end)

ns.Listen("POLE_CHANGED", Panel.UpdateVisibility)
ns.Listen("SETTINGS_CHANGED", Panel.UpdateVisibility)
-- A different book (or an emptied one): what the panel was showing belongs
-- to the old one.
ns.Listen("BOOK_CHANGED", function()
    latest = nil
    lastTrip = nil
    Refresh()
end)

ns.Listen("TRIP_STARTED", function()
    latest = nil
    lastTrip = nil
    Panel.UpdateVisibility()
end)

ns.Listen("TRIP_ENDED", function(trip)
    if trip and (trip.caught or 0) > 0 then
        lastTrip = trip
    end
    Panel.UpdateVisibility()
end)

ns.Listen("CATCH", function(catch)
    local trip = ns.State.trip
    local spot = catch.spotID and ns.Book().spots[catch.spotID]
    local rare
    if
        catch.share
        and catch.share > 0
        and catch.share < RARE_SHARE
        and spot
        and spot.caught >= RARE_AFTER
    then
        rare = math.floor(1 / catch.share + 0.5)
    end

    local this = {
        itemID = catch.itemID,
        first = catch.first,
        count = trip and trip.catches[catch.itemID],
        rare = rare,
        quality = catch.quality,
        unique = catch.unique,
        special = catch.special,
        valuable = catch.valuable,
    }
    latest = this

    -- The tip is picked once per catch, when the item's name is known, so
    -- the lines that name what it cooks into have their words.
    WithItem(catch.itemID, function()
        if latest == this then
            this.tip = ns.Trivia.Pick(this.itemID)
            Refresh()
        end
    end)
    Refresh()
    Celebrate(this)
end)

for _, message in ipairs({
    "SPELL_CHANGED",
    "SKILL_CHANGED",
    "LINE_OUT",
    "LINE_IN",
    "GETAWAY",
    "NEXT_POINT",
    "QUIET_CHANGED",
}) do
    ns.Listen(message, Refresh)
end

ns.Listen("CASTING_CHANGED", RefreshStatus)
ns.Listen("LURE_CHANGED", UpdateLure)
ns.Listen("TRIP_TICK", UpdateClock)
ns.Listen("QUIET_CHANGED", WithdrawSound)

ns.OnEvent("PLAYER_TARGET_CHANGED", RefreshStatus)
ns.OnEvent("PLAYER_REGEN_DISABLED", RefreshStatus)
ns.OnEvent("PLAYER_REGEN_ENABLED", RefreshStatus)
ns.OnEvent("WEAPON_ENCHANT_CHANGED", UpdateLure)
ns.OnEvent("ZONE_CHANGED", UpdateSpot)
ns.OnEvent("ZONE_CHANGED_INDOORS", UpdateSpot)
ns.OnEvent("ZONE_CHANGED_NEW_AREA", UpdateSpot)

-- The sound check waits for the world: the sound settings are only all
-- there once the character is in it.
ns.OnEvent("PLAYER_ENTERING_WORLD", function(isLogin, isReload)
    if isLogin or isReload then
        OfferSound()
    end
end)

-- Walking to new water and the lure running down happen without an event
-- worth listening to, so both are looked at every few seconds.
C_Timer.NewTicker(SLOW_TICK, function()
    if panel and panel:IsShown() and not ns.settings.panelCollapsed then
        UpdateSpot()
        UpdateLure()
    end
    WithdrawSound()
end)
