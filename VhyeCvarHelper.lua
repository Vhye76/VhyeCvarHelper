local addonName, addon = ...

-- Main addon table
local VhyeCvarHelper = {}
addon.VhyeCvarHelper = VhyeCvarHelper

-- Local references
local CreateFrame = CreateFrame
local C_CVar = C_CVar
local UIParent = UIParent
local table_sort = table.sort

------------------------------------------------------------
-- Slash Command (no globals)
------------------------------------------------------------
SLASH_VHYE_CVAR_HELPER1 = "/cvarhelper"
SlashCmdList["VHYE_CVAR_HELPER"] = function(msg)
    VhyeCvarHelper:Toggle()
end

------------------------------------------------------------
-- UI Creation (no global frame name, modern backdrop)
------------------------------------------------------------
function VhyeCvarHelper:CreateUI()
    if self.frame then return end

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    self.frame = frame

    frame:SetSize(400, 500)
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
    -- Title
    ------------------------------------------------------------
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -15)
    title:SetText("CVar Helper")

    ------------------------------------------------------------
    -- Search Box
    ------------------------------------------------------------
    local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    self.searchBox = searchBox
    searchBox:SetSize(200, 30)
    searchBox:SetPoint("TOP", 0, -50)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function()
        VhyeCvarHelper:RefreshList()
    end)

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

    ------------------------------------------------------------
    -- CVar List Container
    ------------------------------------------------------------
    self.cvarLines = {}
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
-- Build CVar List
------------------------------------------------------------
function VhyeCvarHelper:RefreshList()
    local filter = self.searchBox:GetText():lower()

    local cvars = {}
    for name in pairs(C_CVar.GetRegisteredCVars()) do
        if filter == "" or name:lower():find(filter, 1, true) then
            table.insert(cvars, name)
        end
    end

    table_sort(cvars)

    local parent = self.scrollChild

    -- Clear old lines
    for _, line in ipairs(self.cvarLines) do
        line:Hide()
    end

    local y = -5
    local index = 1

    for _, cvar in ipairs(cvars) do
        local line = self.cvarLines[index]

        if not line then
            line = CreateFrame("Button", nil, parent)
            line:SetSize(340, 20)

            line.text = line:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            line.text:SetPoint("LEFT")

            line:SetScript("OnClick", function(self)
                local value = C_CVar.GetCVar(self.cvarName)
                print(self.cvarName .. " = " .. tostring(value))
            end)

            self.cvarLines[index] = line
        end

        line.cvarName = cvar
        line.text:SetText(cvar)
        line:SetPoint("TOPLEFT", 0, y)
        line:Show()

        y = y - 20
        index = index + 1
    end

    parent:SetHeight(-y + 10)
end
