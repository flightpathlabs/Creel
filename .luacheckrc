-- Luacheck configuration for Creel.
-- Run from the addon's folder:  luacheck .
--
-- There is no maintained luacheck "std" for the 12.x / Forever API, so we
-- list the globals we actually touch. A typo in an API name then shows up
-- as a lint warning instead of a nil error in game.

std = "lua51"
max_line_length = 100
max_string_line_length = false
max_comment_line_length = 100
codes = true

exclude_files = {
    "Libs/**",
    ".release/**",
}

ignore = {
    "212/self", -- unused "self" on script handlers is normal
}

-- The only globals Creel creates: its saved data, the slash command, the
-- addon compartment's handler and its key binding labels. The named
-- secure buttons are made through CreateFrame, which luacheck can't see.
globals = {
    "SlashCmdList",
    "StaticPopupDialogs",

    -- Ours
    "CreelDB",
    "SLASH_CREEL1",
    "Creel_OnAddonCompartmentClick",
}

-- Everything else is read only. A name that isn't listed is a typo until
-- it's been found in the client's own interface code and added here.
read_globals = {
    -- Lua extensions the client adds
    "strtrim",
    "tContains",
    "wipe",
    "geterrorhandler",
    "time",
    "date",

    -- Client constants and strings
    "BACKPACK_CONTAINER",
    "Enum",
    "ERR_FISH_ESCAPED",
    "ERR_NOT_IN_COMBAT",
    "ITEM_QUALITY_COLORS",
    "NORMAL_FONT_COLOR",
    "NUM_BAG_SLOTS",
    "HIGHLIGHT_FONT_COLOR",
    "GRAY_FONT_COLOR",
    "YES",
    "NO",
    "OKAY",
    "CANCEL",
    "BACK",
    "DONE",
    "NEXT",

    -- Blizzard's shared Lua helpers
    "BreakUpLargeNumbers",
    "ChatEdit_InsertLink",
    "ChatFrameUtil",
    "CreateFromMixins",
    "CreateColor",
    "CreateKeyChordStringUsingMetaKeyState",
    "CreateSettingsButtonInitializer",
    "CreateSettingsCheckboxSliderInitializer",
    "CreateSettingsListSectionHeaderInitializer",
    "CreateVector2D",
    "Mixin",
    "EventUtil",
    "GameMenuEscPriority",
    "GameTooltip_AddNormalLine",
    "GameTooltip_Hide",
    "GameTooltip_SetTitle",
    "GetBindingName",
    "GetConvertedKeyOrButton",
    "IsKeyPressIgnoredForBinding",
    "Item",
    "MapCanvasDataProviderMixin",
    "MapCanvasPinMixin",
    "MinimalSliderWithSteppersMixin",
    "OpenWorldMap",
    "PanelTemplates_SetNumTabs",
    "PanelTemplates_SetTab",
    "PanelTemplates_TabResize",
    "RegisterGameMenuEscHandler",

    "StaticPopup_Show",
    "StaticPopup_Visible",
    "TooltipDataProcessor",
    "UiMapPoint",
    "hooksecurefunc",
    "RegisterStateDriver",
    "SecureHandlerWrapScript",
    "PlaySound",
    "SOUNDKIT",

    -- Frames and widgets
    "CreateFrame",
    "UIParent",
    "WorldFrame",
    "GameTooltip",
    "LootFrame",
    "Settings",
    "WorldMapFrame",
    "MenuUtil",
    "MovieFrame",
    "SettingsPanel",
    "UIErrorsFrame",
    "UISpecialFrames",

    -- Namespaced API
    "C_AddOns",
    "C_Container",
    "C_CurrencyInfo",
    "C_CVar",
    "C_DateAndTime",
    "C_Item",
    "C_Map",
    "C_SpellBook",
    "C_Spell",
    "C_SuperTrack",
    "C_Texture",
    "C_Timer",
    "C_TooltipInfo",
    "C_TradeSkillUI",

    -- Loose API functions
    "ClearOverrideBindings",
    "GetBindingAction",
    "GetBindingText",
    "GetInboxHeaderInfo",
    "GetInboxInvoiceInfo",
    "GetInboxNumItems",
    "GetInventoryItemID",
    "GetLootSlotInfo",
    "GetLootSlotLink",
    "GetLootSlotType",
    "GetMouseFoci",
    "GetNumLootItems",
    "GetProfessionInfo",
    "GetProfessions",
    "GetRealmName",
    "GetRealZoneText",
    "GetSubZoneText",
    "GetTime",
    "InCinematic",
    "InCombatLockdown",
    "IsFishingLoot",
    "IsInCinematicScene",
    "IsModifiedClick",
    "IsMouseButtonDown",
    "IsShiftKeyDown",
    "ResetCursor",
    "SetCursor",
    "SetOverrideBinding",
    "SetOverrideBindingClick",
    "UnitChannelInfo",
    "UnitExists",
    "UnitFactionGroup",
    "UnitIsPlayer",
    "UnitLevel",
    "UnitName",
    "issecretvalue",
}
