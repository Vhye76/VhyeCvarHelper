-- Persistent storage
VhyeCvarHelperDB = VhyeCvarHelperDB or {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, addon)
    if event == "ADDON_LOADED" and addon == "VhyeCvarHelper" then
        if not VhyeCvarHelperDB then VhyeCvarHelperDB = {} end
    elseif event == "PLAYER_LOGIN" then
        for cvar, value in pairs(VhyeCvarHelperDB) do
            SetCVar(cvar, value)
        end
    end
end)

-- GUI Frame
local gui = CreateFrame("Frame", "VhyeCvarHelperFrame", UIParent, "BasicFrameTemplateWithInset")
gui:SetSize(450, 500)
gui:SetPoint("CENTER")
gui:Hide()
gui.title = gui:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
gui.title:SetPoint("TOP", 0, -10)
gui.title:SetText("Vhye CVar Helper")

-- Search Box for filtering CVars
local searchBox = CreateFrame("EditBox", nil, gui, "InputBoxTemplate")
searchBox:SetSize(180, 20)
searchBox:SetPoint("TOP", 0, -40)
searchBox:SetAutoFocus(false)
searchBox:SetScript("OnTextChanged", function(self)
    RefreshDropdown(self:GetText())
end)

-- Dropdown for CVars
local dropdown = CreateFrame("Frame", "VhyeCvarHelperDropdown", gui, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOP", searchBox, "BOTTOM", 0, -10)

local allCVars = {}
for i = 1, GetNumCVarDefaults() do
    local name = GetCVarDefault(i)
    if name then
        table.insert(allCVars, name)
    end
end

local selectedCVar = nil
UIDropDownMenu_SetWidth(dropdown, 180)

local function RefreshDropdown(filter)
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, cvar in ipairs(allCVars) do
            if not filter or filter == "" or string.find(cvar:lower(), filter:lower()) then
                local info = UIDropDownMenu_CreateInfo()
                info.text = cvar
                info.func = function()
                    UIDropDownMenu_SetSelectedName(dropdown, cvar)
                    selectedCVar = cvar
                end
                UIDropDownMenu_AddButton(info)
            end
        end
    end)
end

RefreshDropdown("") -- Initialize with all CVars

-- EditBox for value
local editBox = CreateFrame("EditBox", nil, gui, "InputBoxTemplate")
editBox:SetSize(100, 20)
editBox:SetPoint("TOP", dropdown, "BOTTOM", 0, -20)
editBox:SetAutoFocus(false)

-- Add Button
local addButton = CreateFrame("Button", nil, gui, "GameMenuButtonTemplate")
addButton:SetSize(120, 25)
addButton:SetPoint("TOP", editBox, "BOTTOM", 0, -10)
addButton:SetText("Add/Update CVar")
addButton:SetScript("OnClick", function()
    local value = editBox:GetText()
    if selectedCVar and value ~= "" then
        VhyeCvarHelperDB[selectedCVar] = value
        RefreshList()
        print("Added/Updated:", selectedCVar, "=", value)
    else
        print("Select a CVar and enter a value.")
    end
end)

-- Reset Button
local resetButton = CreateFrame("Button", nil, gui, "GameMenuButtonTemplate")
resetButton:SetSize(120, 25)
resetButton:SetPoint("TOP", addButton, "BOTTOM", 0, -10)
resetButton:SetText("Reset All to Defaults")
resetButton:SetScript("OnClick", function()
    for cvar in pairs(VhyeCvarHelperDB) do
        local default = GetCVarDefault(cvar)
        if default then
            SetCVar(cvar, default)
        end
    end
    VhyeCvarHelperDB = {}
    RefreshList()
    print("All CVars reset to defaults.")
end)

-- Export/Import Buttons
local exportBox = CreateFrame("EditBox", nil, gui, "InputBoxTemplate")
exportBox:SetSize(300, 20)
exportBox:SetPoint("TOP", resetButton, "BOTTOM", 0, -20)
exportBox:SetAutoFocus(false)
exportBox:SetText("Export/Import String")

local exportButton = CreateFrame("Button", nil, gui, "GameMenuButtonTemplate")
exportButton:SetSize(80, 25)
exportButton:SetPoint("TOPLEFT", exportBox, "BOTTOMLEFT", 0, -10)
exportButton:SetText("Export")
exportButton:SetScript("OnClick", function()
    local str = ""
    for cvar, value in pairs(VhyeCvarHelperDB) do
        str = str .. cvar .. "=" .. value .. ";"
    end
    exportBox:SetText(str)
    print("Exported CVars.")
end)

local importButton = CreateFrame("Button", nil, gui, "GameMenuButtonTemplate")
importButton:SetSize(80, 25)
importButton:SetPoint("LEFT", exportButton, "RIGHT", 10, 0)
importButton:SetText("Import")
importButton:SetScript("OnClick", function()
    local str = exportBox:GetText()
    for pair in string.gmatch(str, "([^;]+)") do
        local cvar, value = string.match(pair, "([^=]+)=([^=]+)")
        if cvar and value then
            VhyeCvarHelperDB[cvar] = value
        end
    end
    RefreshList()
    print("Imported CVars.")
end)

-- Scrollable list of saved CVars
local scrollFrame = CreateFrame("ScrollFrame", nil, gui, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(200, 150)
scrollFrame:SetPoint("TOP", importButton, "BOTTOM", 0, -20)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(200, 150)
scrollFrame:SetScrollChild(content)

local function RefreshList()
    for i, child in ipairs(content.children or {}) do
        child:Hide()
    end
    content.children = {}

    local yOffset = -10
    for cvar, value in pairs(VhyeCvarHelperDB) do
        local line = CreateFrame("Frame", nil, content)
        line:SetSize(180, 20)
        line:SetPoint("TOPLEFT", 0, yOffset)

        local text = line:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT")
        text:SetText(cvar .. " = " .. value)

        local removeBtn = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
        removeBtn:SetSize(50, 20)
        removeBtn:SetPoint("RIGHT")
        removeBtn:SetText("Remove")
        removeBtn:SetScript("OnClick", function()
            VhyeCvarHelperDB[cvar] = nil
            RefreshList()
        end)

        table.insert(content.children, line)
        yOffset = yOffset - 25
    end
end

-- Slash command to show GUI
SLASH_VHYECVARHELPER1 = "/vhye"
SlashCmdList["VHYECVARHELPER"] = function()
    gui:Show()
    RefreshList()
end
