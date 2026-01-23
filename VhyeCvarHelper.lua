local addonName, addon = ...

local VhyeCvarHelper = {}
addon.VhyeCvarHelper = VhyeCvarHelper

local CreateFrame = CreateFrame
local C_CVar = C_CVar
local UIParent = UIParent
local table_sort = table.sort
local ipairs = ipairs
local pairs = pairs
local strlower = string.lower

------------------------------------------------------------
-- Categorized CVar table (EXTEND THIS IN-GAME)
------------------------------------------------------------
local CVarCategories = {
    Graphics = {
        "graphicsQuality",
        "raidGraphicsQuality",
        "gxMaxFrameLatency",
        "shadowQuality",
        "particleDensity",
        "projectedTextures",
        "environmentDetail",
        "groundEffectDensity",
        "groundEffectDist",
        "outlineMode",
    },
    Sound = {
        "Sound_EnableAllSound",
        "Sound_MasterVolume",
        "Sound_SFXVolume",
        "Sound_MusicVolume",
        "Sound_AmbienceVolume",
        "Sound_DialogVolume",
        "Sound_EnableErrorSpeech",
        "Sound_EnableEmoteSounds",
    },
    Nameplates = {
        "nameplateShowEnemies",
        "nameplateShowFriends",
        "nameplateShowAll",
        "nameplateMaxDistance",
        "nameplateOtherTopInset",
        "nameplateOtherBottomInset",
        "nameplateOverlapV",
        "nameplateOverlapH",
    },
    Camera = {
        "cameraDistanceMaxZoomFactor",
        "cameraSmoothStyle",
        "cameraPitchMoveSpeed",
        "cameraYawMoveSpeed",
        "cameraWaterCollision",
    },
    Combat = {
        "floatingCombatTextCombatDamage",
        "floatingCombatTextCombatHealing",
        "floatingCombatTextLowManaHealth",
        "floatingCombatTextAuras",
        "floatingCombatTextReactives",
    },
    UI = {
        "autoLootDefault",
        "autoSelfCast",
        "spellQueueWindow",
        "showTargetOfTarget",
        "showPartyBackground",
        "showArenaEnemyFrames",
        "showArenaEnemyCastbar",
        "showArenaEnemyPets",
    },
    UnitNames = {
        "UnitNameOwn",
        "UnitNameNPC",
        "UnitNamePlayerGuild",
        "UnitNamePlayerPVPTitle",
        "UnitNameFriendlyPlayerName",
        "UnitNameEnemyPlayerName",
        "UnitNameFriendlyPetName",
        "UnitNameEnemyPetName",
        "UnitNameFriendlyGuardianName",
        "UnitNameEnemyGuardianName",
        "UnitNameFriendlyTotemName",
        "UnitNameEnemyTotemName",
        "UnitNameNonCombatCreatureName",
        "UnitNameInteractiveNPC",
    },
    Accessibility = {
        "colorblindMode",
        "colorblindSimulator",
        "colorblindWeaknessFactor",
        "enableMouseSpeed",
        "mouseSpeed",
    },
}

------------------------------------------------------------
-- Flattened index for search
------------------------------------------------------------
local function BuildFlatIndex(filterText)
    local flat = {}
    local filter = strlower(filterText or "")

    for category, list in pairs(CVarCategories) do
        for _, name in ipairs(list) do
            if filter == "" or strlower(name):find(filter, 1, true) or strlower(category):find(filter, 1, true) then
                flat[#flat + 1] = { category = category, name = name }
            end
        end
    end

    table_sort(flat, function(a, b)
        if a.category == b.category then
            return a.name < b.name
        end
        return a.category < b.category
    end)

    return flat
end

------------------------------------------------------------
-- Slash Command
------------------------------------------------------------
SLASH_VHYE_CVAR_HELPER1 = "/cvarhelper"
SlashCmdList["VHYE_CVAR_HELPER"] = function()
    VhyeCvarHelper:Toggle()
end

------------------------------------------------------------
-- UI Creation
------------------------------------------------------------
function VhyeCvarHelper:CreateUI()
    if self.frame then return end

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    self.frame = frame

    frame:SetSize(450, 550)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -15)
    title:SetText("CVar Helper (Midnight)")

    local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.searchBox = searchBox
    searchBox:SetSize(260, 24)
    searchBox:SetPoint("TOP", 0, -50)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function()
        VhyeCvarHelper:RefreshList()
    end)

    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("BOTTOMLEFT", searchBox, "TOPLEFT", 4, 2)
    searchLabel:SetText("Search (category or CVar name)")

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    self.scrollFrame = scrollFrame
    scrollFrame:SetPoint("TOPLEFT", 20, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 20)

    local scrollChild = CreateFrame("Frame")
    self.scrollChild = scrollChild
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(1, 1)

    self.lines = {}
end

------------------------------------------------------------
-- Toggle UI
------------------------------------------------------------
function VhyeCvarHelper:Toggle()
    if not self.frame then
        self:CreateUI()
    end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self:RefreshList()
        self.frame:Show()
    end
end

------------------------------------------------------------
-- Refresh categorized list
------------------------------------------------------------
function VhyeCvarHelper:RefreshList()
    local filterText = self.searchBox and self.searchBox:GetText() or ""
    local entries = BuildFlatIndex(filterText)

    local parent = self.scrollChild

    for _, line in ipairs(self.lines) do
        line:Hide()
    end

    local y = -5
    local index = 1
    local lastCategory

    for _, entry in ipairs(entries) do
        if entry.category ~= lastCategory then
            local header = self.lines[index]
            if not header then
                header = CreateFrame("Frame", nil, parent)
                header:SetSize(360, 18)

                header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                header.text:SetPoint("LEFT", 0, 0)

                self.lines[index] = header
            end

            header.text:SetText(entry.category)
            header:SetPoint("TOPLEFT", 0, y)
            header:Show()

            y = y - 18
            index = index + 1
            lastCategory = entry.category
        end

        local line = self.lines[index]
        if not line then
            line = CreateFrame("Button", nil, parent)
            line:SetSize(360, 18)

            line.text = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            line.text:SetPoint("LEFT", 10, 0)

            line.valueText = line:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            line.valueText:SetPoint("RIGHT", -5, 0)

            line:SetScript("OnClick", function(self)
                local value = C_CVar.GetCVar(self.cvarName)
                print(("|cff00ff00%s|r = |cffffff00%s|r"):format(self.cvarName, tostring(value)))
            end)

            self.lines[index] = line
        end

        line.cvarName = entry.name
        line.text:SetText(entry.name)

        local ok, value = pcall(C_CVar.GetCVar, entry.name)
        if ok then
            line.valueText:SetText(value)
        else
            line.valueText:SetText("n/a")
        end

        line:SetPoint("TOPLEFT", 0, y)
        line:Show()

        y = y - 18
        index = index + 1
    end

    parent:SetHeight(-y + 10)
end
