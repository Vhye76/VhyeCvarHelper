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
-- Categorized CVar table (extend as needed)
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
            -- Edit Dialog
            ------------------------------------------------------------
            local function CreateEditDialog(ownerFrame, ownerAddon)
            local dlg = CreateFrame("Frame", nil, ownerFrame, "BackdropTemplate")
            dlg:SetSize(260, 160)
            dlg:SetPoint("LEFT", ownerFrame, "RIGHT", 10, 0)
            dlg:Hide()

            dlg:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 }
            })
            dlg:SetBackdropColor(0, 0, 0, 1)

            dlg.title = dlg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            dlg.title:SetPoint("TOP", 0, -10)

            dlg.editBox = CreateFrame("EditBox", nil, dlg, "InputBoxTemplate")
            dlg.editBox:SetSize(200, 30)
            dlg.editBox:SetPoint("TOP", dlg.title, "BOTTOM", 0, -10)
            dlg.editBox:SetAutoFocus(true)

            dlg.ok = CreateFrame("Button", nil, dlg, "UIPanelButtonTemplate")
            dlg.ok:SetSize(80, 22)
            dlg.ok:SetPoint("BOTTOMLEFT", 15, 15)
            dlg.ok:SetText("Apply")

            dlg.reset = CreateFrame("Button", nil, dlg, "UIPanelButtonTemplate")
            dlg.reset:SetSize(80, 22)
            dlg.reset:SetPoint("BOTTOM", 0, 15)
            dlg.reset:SetText("Default")

            dlg.cancel = CreateFrame("Button", nil, dlg, "UIPanelButtonTemplate")
            dlg.cancel:SetSize(80, 22)
            dlg.cancel:SetPoint("BOTTOMRIGHT", -15, 15)
            dlg.cancel:SetText("Close")

            dlg.ok:SetScript("OnClick", function()
            if dlg.cvarName then
                C_CVar.SetCVar(dlg.cvarName, dlg.editBox:GetText())
                end
                ownerAddon:RefreshList()
                end)

            dlg.reset:SetScript("OnClick", function()
            if dlg.cvarName then
                local default = C_CVar.GetCVarDefault(dlg.cvarName)
                if default ~= nil then
                    C_CVar.SetCVar(dlg.cvarName, default)
                    dlg.editBox:SetText(default)
                    ownerAddon:RefreshList()
                    end
                    end
                    end)

            dlg.cancel:SetScript("OnClick", function()
            dlg:Hide()
            end)

            return dlg
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

                ------------------------------------------------------------
                -- Close Button
                ------------------------------------------------------------
                local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
                close:SetPoint("TOPRIGHT", -5, -5)

                ------------------------------------------------------------
                -- Title
                ------------------------------------------------------------
                local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                title:SetPoint("TOP", 0, -15)
                title:SetText("Vhye's CVar Helper")

                ------------------------------------------------------------
                -- Search Box
                ------------------------------------------------------------
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
                searchLabel:SetText("Search")

                ------------------------------------------------------------
                -- Scroll Frame
                ------------------------------------------------------------
                local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
                self.scrollFrame = scrollFrame
                scrollFrame:SetPoint("TOPLEFT", 20, -90)
                scrollFrame:SetPoint("BOTTOMRIGHT", -40, 20)

                local scrollChild = CreateFrame("Frame")
                self.scrollChild = scrollChild
                scrollFrame:SetScrollChild(scrollChild)
                scrollChild:SetSize(1, 1)

                self.lines = {}

                ------------------------------------------------------------
                -- Edit Dialog
                ------------------------------------------------------------
                self.editDialog = CreateEditDialog(frame, self)
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

                                                line:SetScript("OnClick", function(selfBtn)
                                                local dlg = VhyeCvarHelper.editDialog
                                                dlg.cvarName = selfBtn.cvarName
                                                dlg.title:SetText(selfBtn.cvarName)

                                                local ok, value = pcall(C_CVar.GetCVar, selfBtn.cvarName)
                                                dlg.editBox:SetText(ok and value or "")

                                                dlg:Show()
                                                dlg.editBox:SetFocus()
                                                end)

                                                self.lines[index] = line
                                                end

                                                line.cvarName = entry.name
                                                line.text:SetText(entry.name)

                                                local ok, value = pcall(C_CVar.GetCVar, entry.name)
                                                line.valueText:SetText(ok and value or "n/a")

                                                line:SetPoint("TOPLEFT", 0, y)
                                                line:Show()

                                                y = y - 18
                                                index = index + 1
                                                end

                                                parent:SetHeight(-y + 10)
                                                end

                                                ------------------------------------------------------------
                                                -- Live CVar Update Listener
                                                ------------------------------------------------------------
                                                local liveUpdateFrame = CreateFrame("Frame")
                                                liveUpdateFrame:RegisterEvent("CVAR_UPDATE")
                                                liveUpdateFrame:SetScript("OnEvent", function()
                                                if VhyeCvarHelper.frame and VhyeCvarHelper.frame:IsShown() then
                                                    VhyeCvarHelper:RefreshList()
                                                    end
                                                    end)

