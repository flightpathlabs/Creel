local _, ns = ...

-- The button on the edge of the minimap. Left-click opens the Fishing
-- Book, right-click the options, shift-click shows or hides the panel, and
-- it can be dragged around the rim.
--
-- Built by hand, as Goldwise's is, rather than with the usual button
-- library, so Creel has no dependencies. It keeps that library's
-- conventions all the same: the art and size of every other minimap
-- button, and a name that button-tidying addons recognise and gather up.

local Kit = ns.Kit

-- How far outside the minimap's edge the button's centre sits.
local EDGE_OFFSET = 5

local button

-- Puts the button on the minimap's rim at the saved angle.
local function Place()
    local angle = math.rad(ns.settings.minimapAngle or ns.DEFAULT_SETTINGS.minimapAngle)
    local x, y = math.cos(angle), math.sin(angle)
    local halfWidth = Minimap:GetWidth() / 2 + EDGE_OFFSET
    local halfHeight = Minimap:GetHeight() / 2 + EDGE_OFFSET

    -- Minimap addons that reshape the map announce the shape through this
    -- function. On a square map the button follows the edges and corners
    -- instead of cutting across them on a circle.
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    if shape == "ROUND" then
        x, y = x * halfWidth, y * halfHeight
    else
        local reach = math.sqrt(2)
        x = math.max(-halfWidth, math.min(x * halfWidth * reach, halfWidth))
        y = math.max(-halfHeight, math.min(y * halfHeight * reach, halfHeight))
    end

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- While dragging: point the button at wherever the cursor is, measured as
-- an angle from the minimap's centre.
local function FollowCursor()
    local centerX, centerY = Minimap:GetCenter()
    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()

    ns.settings.minimapAngle =
        math.deg(math.atan2(cursorY / scale - centerY, cursorX / scale - centerX))
    Place()
end

local function ToggleBook()
    local book = ns.BookWindow
    if not book then
        return
    end
    if book.Toggle then
        book.Toggle()
    elseif book.IsShown and book.IsShown() and book.Close then
        book.Close()
    elseif book.Open then
        book.Open()
    end
end

local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(ns.TITLE, Kit.GOLD[1], Kit.GOLD[2], Kit.GOLD[3])
    GameTooltip:AddLine("Left-click for the Fishing Book.", 1, 1, 1)
    GameTooltip:AddLine("Right-click for options.", 1, 1, 1)
    GameTooltip:AddLine("Shift-click to show or hide the panel.", 1, 1, 1)

    local trip = ns.State.trip
    if trip then
        local caught = trip.caught or 0
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(
            ("This trip: %d %s in %s"):format(
                caught,
                caught == 1 and "catch" or "catches",
                ns.Clock(ns.State.TripSeconds())
            ),
            1,
            1,
            1
        )
    end

    GameTooltip:AddLine("Drag to move.", Kit.MUTED[1], Kit.MUTED[2], Kit.MUTED[3])
    GameTooltip:Show()
end

local function Create()
    -- The name matters: addons that collect minimap buttons look for
    -- "MinimapButton" in it.
    local frame = CreateFrame("Button", "CreelMinimapButton", Minimap)
    frame:SetSize(31, 31)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(8)
    frame:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- The standard look: a dark disc, the icon, and the gold ring on top,
    -- at the sizes other addons' buttons use on this client, so it lines
    -- up with its neighbours.
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetSize(24, 24)
    background:SetPoint("CENTER")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    icon:SetTexture(ns.ICON)

    -- The icon is square and the ring is round, so trim its corners.
    local mask = frame:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture(
        "Interface\\CharacterFrame\\TempPortraitAlphaMask",
        "CLAMPTOBLACKADDITIVE",
        "CLAMPTOBLACKADDITIVE"
    )
    icon:AddMaskTexture(mask)

    local ring = frame:CreateTexture(nil, "OVERLAY")
    ring:SetSize(50, 50)
    ring:SetPoint("TOPLEFT")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            ns.OpenOptions()
        elseif IsShiftKeyDown() then
            if ns.Panel and ns.Panel.Toggle then
                ns.Panel.Toggle()
            end
        else
            ToggleBook()
        end
    end)

    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", FollowCursor)
    end)
    frame:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    frame:SetScript("OnEnter", ShowTooltip)
    frame:SetScript("OnLeave", GameTooltip_Hide)

    return frame
end

-- Shows or hides the button to match the player's setting.
local function Update()
    if ns.settings.minimapButton then
        button = button or Create()
        Place()
        button:Show()
    elseif button then
        button:Hide()
    end
end

ns.OnEvent("PLAYER_LOGIN", Update)
ns.Listen("SETTINGS_CHANGED", Update)
