-- UI behavior harness for MCP Keybind Display under Lua 5.0 callbacks.

local addonPath = arg[1]
if not addonPath then error("addon path required") end
local optionsPath = arg[2]
if not optionsPath then error("options path required") end
local GlobalTable = _G
function getglobal(name) return GlobalTable[name] end
function setglobal(name, value) GlobalTable[name] = value end
_G = nil
local sliderSetCalls = 0
local sliderSetDepth = 0

local function NewWidget(kind, name)
    local widget = { kind = kind, name = name, shown = false, scripts = {}, points = {} }
    function widget:SetWidth(value) self.width = value end
    function widget:SetHeight(value) self.height = value end
    function widget:SetPoint(...) self.points[1] = arg end
    function widget:ClearAllPoints() self.points = {} end
    function widget:GetPoint() if self.points[1] then return unpack(self.points[1]) end end
    function widget:SetBackdrop(value) self.backdrop = value end
    function widget:SetBackdropColor(...) self.backdropColor = arg end
    function widget:SetBackdropBorderColor(...) self.backdropBorderColor = arg end
    function widget:SetMovable(value) self.movable = value end
    function widget:EnableMouse(value) self.mouseEnabled = value end
    function widget:EnableKeyboard(value) self.keyboardEnabled = value end
    function widget:RegisterForDrag(...) self.dragButtons = arg end
    function widget:SetScript(script, callback) self.scripts[script] = callback end
    function widget:GetScript(script) return self.scripts[script] end
    function widget:RegisterEvent() end
    function widget:CreateFontString(childName)
        local child = NewWidget("FontString", childName)
        self.children = self.children or {}
        table.insert(self.children, child)
        return child
    end
    function widget:SetFont(path, size, flags) self.font = { path, size, flags } end
    function widget:SetText(value) self.text = value end
    function widget:GetText() return self.text end
    function widget:GetStringWidth()
        local size = self.font and self.font[2] or 10
        local naturalWidth = string.len(self.text or "") * size * 0.5
        if self.width and self.width > 0 and naturalWidth > self.width then return self.width end
        return naturalWidth
    end
    function widget:SetTextColor(...) self.textColor = arg end
    function widget:SetJustifyH(value) self.justifyH = value end
    function widget:SetAlpha(value) self.alpha = value end
    function widget:SetScale(value) self.scale = value end
    function widget:SetChecked(value) self.checked = value and true or false end
    -- Vanilla check buttons return 1 or nil rather than strict booleans.
    function widget:GetChecked() if self.checked then return 1 end return nil end
    function widget:SetMinMaxValues(low, high) self.low = low; self.high = high end
    function widget:SetValueStep(value) self.valueStep = value end
    function widget:SetValue(value)
        self.value = value
        if self.kind == "Slider" and self.scripts.OnValueChanged then
            sliderSetCalls = sliderSetCalls + 1
            sliderSetDepth = sliderSetDepth + 1
            if sliderSetDepth > 2 then error("recursive slider refresh") end
            this = self
            arg1 = value
            self.scripts.OnValueChanged()
            sliderSetDepth = sliderSetDepth - 1
        end
    end
    function widget:GetValue() return self.value end
    function widget:SetID(value) self.id = value end
    function widget:GetID() return self.id end
    function widget:SetFrameStrata(value) self.strata = value end
    function widget:SetFrameLevel(value) self.frameLevel = value end
    function widget:GetFrameLevel() return self.frameLevel or 1 end
    function widget:SetToplevel(value) self.toplevel = value end
    function widget:SetClampedToScreen(value) self.clamped = value end
    function widget:RegisterForClicks() end
    function widget:SetHighlightTexture(value) self.highlightTexture = value end
    function widget:SetTexture(value) self.texture = value end
    function widget:SetTexCoord(...) self.texCoord = arg end
    function widget:CreateTexture(childName)
        local child = NewWidget("Texture", childName)
        self.children = self.children or {}
        table.insert(self.children, child)
        return child
    end
    function widget:GetLeft() return self.left or 100 end
    function widget:GetBottom() return self.bottom or 100 end
    function widget:GetScale() return self.scale or 1 end
    function widget:Enable() self.enabled = true end
    function widget:Disable() self.enabled = false end
    function widget:Show() self.shown = true end
    function widget:Hide() self.shown = false end
    function widget:IsShown() return self.shown end
    function widget:IsVisible() return self.shown end
    function widget:StartMoving() self.moving = true end
    function widget:StopMovingOrSizing() self.moving = false end
    return widget
end

UIParent = NewWidget("Frame", "UIParent")
Minimap = NewWidget("Frame", "Minimap")
Minimap.frameLevel = 2
local cursorX, cursorY = 170, 200
function GetCursorPosition() return cursorX, cursorY end
if not math.atan2 then math.atan2 = function(y, x) return math.atan(y / x) end end
function CreateFrame(kind, name, parent, template)
    local frame = NewWidget(kind, name)
    if name then setglobal(name, frame) end
    if template == "OptionsSliderTemplate" then
        setglobal(name .. "Text", NewWidget("FontString", name .. "Text"))
        setglobal(name .. "Low", NewWidget("FontString", name .. "Low"))
        setglobal(name .. "High", NewWidget("FontString", name .. "High"))
    end
    return frame
end

local bindings = {
    { "MCP_PANEL", "CTRL-C", nil },
    { "MCP_START", "F1", "ALT-F1" },
    { "MCP_COME", "F2", "CTRL-F2" },
    { "MCP_START_TANK", "SHIFT-F1", nil },
}
function GetNumBindings() return table.getn(bindings) end
function GetBinding(index) local row = bindings[index]; return row[1], row[2], row[3] end
function GetBindingKey(action)
    local index
    for index = 1, table.getn(bindings) do if bindings[index][1] == action then return bindings[index][2], bindings[index][3] end end
end
function GetBindingAction(key)
    local index
    for index = 1, table.getn(bindings) do if bindings[index][2] == key or bindings[index][3] == key then return bindings[index][1] end end
    return ""
end
function SetBinding(key, action)
    local index, row
    for index = 1, table.getn(bindings) do
        row = bindings[index]
        if row[2] == key then row[2] = nil end
        if row[3] == key then row[3] = nil end
    end
    if not action then return true end
    for index = 1, table.getn(bindings) do
        if bindings[index][1] == action then
            if bindings[index][2] == key or bindings[index][3] == key then return true end
            if not bindings[index][2] then bindings[index][2] = key elseif not bindings[index][3] then bindings[index][3] = key else bindings[index][2] = key end
            return true
        end
    end
    return false
end
local bindingSaveCalls = 0
function GetCurrentBindingSet() return 1 end
function SaveBindings()
    bindingSaveCalls = bindingSaveCalls + 1
    if ShirsMCPKeybindDisplay and ShirsMCPKeybindDisplay.eventFrame then
        this = ShirsMCPKeybindDisplay.eventFrame
        event = "UPDATE_BINDINGS"
        ShirsMCPKeybindDisplay.eventFrame:GetScript("OnEvent")()
    end
end
local shiftDown, altDown, controlDown = false, false, false
function IsShiftKeyDown() return shiftDown end
function IsAltKeyDown() return altDown end
function IsControlKeyDown() return controlDown end
StaticPopupDialogs = {}
local shownPopup
function StaticPopup_Show(name) shownPopup = name end

BINDING_NAME_MCP_PANEL = "Show/Hide MCP"
BINDING_NAME_MCP_START = "Start"
BINDING_NAME_MCP_COME = "Come"
BINDING_NAME_MCP_START_TANK = "Start: Tank"
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
ShirsMCPKeybindDisplayDB = nil

assert(pcall(dofile, addonPath))
local optionsLoaded, optionsMessage = pcall(dofile, optionsPath)
if not optionsLoaded then error("options failed to load: " .. tostring(optionsMessage)) end
ShirsMCPKeybindDisplay:Initialize()
local function FlushBindingRefresh()
    this = ShirsMCPKeybindDisplay.eventFrame
    arg1 = 0.016
    ShirsMCPKeybindDisplay.eventFrame:GetScript("OnUpdate")()
end

if not ShirsMCPKeybindDisplay.CreateOverlay then error("CreateOverlay is missing") end
ShirsMCPKeybindDisplay:CreateOverlay()
ShirsMCPKeybindDisplay:UpdateDisplay()

local function assertEqual(actual, expected, label)
    if actual ~= expected then error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual)) end
end

local originalRefresh = ShirsMCPKeybindDisplay.Refresh
local coalescedRefreshes = 0
ShirsMCPKeybindDisplay.Refresh = function(self)
    coalescedRefreshes = coalescedRefreshes + 1
    originalRefresh(self)
end
local burstIndex
for burstIndex = 1, 3 do
    this = ShirsMCPKeybindDisplay.eventFrame
    event = "UPDATE_BINDINGS"
    ShirsMCPKeybindDisplay.eventFrame:GetScript("OnEvent")()
end
assertEqual(ShirsMCPKeybindDisplay.bindingRefreshPending, true, "UPDATE_BINDINGS burst queues one refresh")
FlushBindingRefresh()
assertEqual(coalescedRefreshes, 1, "UPDATE_BINDINGS burst coalesces to one refresh")
assertEqual(ShirsMCPKeybindDisplay.bindingRefreshPending, false, "coalesced refresh clears pending state")
FlushBindingRefresh()
assertEqual(coalescedRefreshes, 1, "idle OnUpdate does not repeat a refresh")
local originalDiscoverBindings = ShirsMCPKeybindDisplay.DiscoverBindings
local injectedDuringRefresh = false
ShirsMCPKeybindDisplay.DiscoverBindings = function(self)
    local result = originalDiscoverBindings(self)
    if not injectedDuringRefresh then
        injectedDuringRefresh = true
        self:RequestBindingRefresh()
    end
    return result
end
coalescedRefreshes = 0
ShirsMCPKeybindDisplay:RequestBindingRefresh()
FlushBindingRefresh()
assertEqual(coalescedRefreshes, 1, "first queued refresh runs")
assertEqual(ShirsMCPKeybindDisplay.bindingRefreshPending, true, "event raised during refresh remains pending")
FlushBindingRefresh()
assertEqual(coalescedRefreshes, 2, "event raised during refresh runs on the next frame")
assertEqual(ShirsMCPKeybindDisplay.bindingRefreshPending, false, "follow-up refresh clears pending state")
FlushBindingRefresh()
assertEqual(coalescedRefreshes, 2, "event-during-refresh path settles without looping")
ShirsMCPKeybindDisplay.DiscoverBindings = originalDiscoverBindings
ShirsMCPKeybindDisplay.Refresh = originalRefresh

assertEqual(ShirsMCPKeybindDisplay.overlay.shown, true, "overlay visible by default")
assertEqual(ShirsMCPKeybindDisplay.overlay.width, 220, "command-key card auto-fits its default content")
assertEqual(ShirsMCPKeybindDisplay.overlay.height, 64, "single-list card default height")
assertEqual(ShirsMCPKeybindDisplay.overlayTitle.text, "MCP KEYBINDS", "HUD card title")
assertEqual(ShirsMCPKeybindDisplay.overlayDivider.shown, true, "HUD column divider shown")
assertEqual(table.getn(ShirsMCPKeybindDisplay.rows), 3, "one row per visible assigned general binding")
assertEqual(ShirsMCPKeybindDisplay.rows[1].label.text, "Show/Hide MCP", "first label")
assertEqual(ShirsMCPKeybindDisplay.rows[1].keys.text, "CTRL-C", "first key")
assertEqual(ShirsMCPKeybindDisplay.rows[3].keys.text, "F2 / CTRL-F2", "two assigned keys")
assertEqual(ShirsMCPKeybindDisplay.rows[2].keys.justifyH, "LEFT", "heads-up key values start beside their commands")
assertEqual(ShirsMCPKeybindDisplay.rows[2].keys.points[1][4], ShirsMCPKeybindDisplay.rows[2].label.points[1][4] + ShirsMCPKeybindDisplay.rows[2].label.width + 16, "short command key uses the aligned table gap")
assertEqual(ShirsMCPKeybindDisplay.rows[2].keys.points[1][4] < 100, true, "short command key no longer sits at the overlay border")
assertEqual(ShirsMCPKeybindDisplay.overlay.mouseEnabled, true, "overlay movable while unlocked")
setglobal("BINDING_NAME_MCP_START", "Selector: Previous (All/Role/Class)")
ShirsMCPKeybindDisplay:Refresh()
assertEqual(ShirsMCPKeybindDisplay.rows[2].label.width > 100, true, "reused label is unconstrained before measuring longer text")
assertEqual(ShirsMCPKeybindDisplay.rows[2].label.width <= 220, true, "command column caps long MCP labels safely")
assertEqual(ShirsMCPKeybindDisplay.rows[2].label.height, 12, "long labels are clipped to one row instead of overlapping")
assertEqual(ShirsMCPKeybindDisplay.rows[2].keys.points[1][4], ShirsMCPKeybindDisplay.rows[2].label.points[1][4] + ShirsMCPKeybindDisplay.rows[2].label.width + 16, "long command key follows the command column")
assertEqual(ShirsMCPKeybindDisplay.rows[2].keys.points[1][4] + ShirsMCPKeybindDisplay.rows[2].keys.width <= ShirsMCPKeybindDisplay.overlay.width - 6, true, "long command key stays inside the auto-fitted card")
ShirsMCPKeybindDisplay:SetVisualOption("fontSize", 24)
assertEqual(ShirsMCPKeybindDisplay.rows[2].label.width > 220, true, "command width cap grows with the selected font size")
assertEqual(ShirsMCPKeybindDisplay.rows[2].label:GetStringWidth() <= ShirsMCPKeybindDisplay.rows[2].label.width, true, "large-font command stays complete")
ShirsMCPKeybindDisplay:SetVisualOption("fontSize", 10)
setglobal("BINDING_NAME_MCP_START", "Start")
ShirsMCPKeybindDisplay:Refresh()
bindings[2][2] = "NUMPADDIVIDE"
bindings[2][3] = nil
ShirsMCPKeybindDisplay:Refresh()
assertEqual(ShirsMCPKeybindDisplay.rows[2].keys.width > 55, true, "reused key field is unconstrained before measuring longer text")
bindings[2][2] = "CTRL-SHIFT-PAGEDOWN"
bindings[2][3] = "ALT-CTRL-SHIFT-PAGEUP"
ShirsMCPKeybindDisplay:Refresh()
ShirsMCPKeybindDisplay:SetEntryOverride("MCP_START_TANK", true)
local geometryFont, geometryRow
for geometryFont = 8, 24 do
        ShirsMCPKeybindDisplay:SetVisualOption("fontSize", geometryFont)
        local geometryCount = table.getn(ShirsMCPKeybindDisplay:GetVisibleEntries())
        local rowsPerColumn = geometryCount
        local actualColumnWidth = ShirsMCPKeybindDisplay.overlay.width
        local firstLabelWidth = ShirsMCPKeybindDisplay.rows[1].label.width
        local firstKeyWidth = ShirsMCPKeybindDisplay.rows[1].keys.width
        for geometryRow = 1, geometryCount do
            local geometryKeys = ShirsMCPKeybindDisplay.rows[geometryRow].keys
            local geometryLabel = ShirsMCPKeybindDisplay.rows[geometryRow].label
            local geometryColumn = math.floor((geometryRow - 1) / rowsPerColumn)
            assertEqual(geometryLabel.width, firstLabelWidth, "all command cells use one aligned width")
            assertEqual(geometryKeys.width, firstKeyWidth, "all key cells use one aligned width")
            assertEqual(geometryKeys:GetStringWidth() <= geometryKeys.width, true, "complete key text fits the aligned key cell")
            assertEqual(geometryKeys.points[1][4], geometryLabel.points[1][4] + geometryLabel.width + 16, "aligned key text keeps the table gap")
            assertEqual(geometryKeys.points[1][4] + geometryKeys.width <= ((geometryColumn + 1) * actualColumnWidth) - 6, true, "aligned key cell stays inside its column")
        end
        if geometryFont == 24 then
            assertEqual(ShirsMCPKeybindDisplay.overlay.width > 320, true, "auto-fit expands for unusually long key values")
        end
end
bindings[2][2] = "F1"
bindings[2][3] = "ALT-F1"
ShirsMCPKeybindDisplay:ClearEntryOverride("MCP_START_TANK")
ShirsMCPKeybindDisplay:SetVisualOption("fontSize", 10)
assertEqual(ShirsMCPKeybindDisplay.minimapButton.shown, true, "minimap button shown by default")
assertEqual(ShirsMCPKeybindDisplay.minimapButton.width, 32, "minimap button compact size")
this = ShirsMCPKeybindDisplay.minimapButton
ShirsMCPKeybindDisplay.minimapButton:GetScript("OnDragStart")()
ShirsMCPKeybindDisplay.minimapButton:GetScript("OnUpdate")()
ShirsMCPKeybindDisplay.minimapButton:GetScript("OnDragStop")()
assertEqual(math.floor(ShirsMCPKeybindDisplay.db.minimap.angle), 90, "minimap drag saves angle")

print("UI_DEFAULT_OVERLAY=PASS")

ShirsMCPKeybindDisplay:SetLocked(true)
assertEqual(ShirsMCPKeybindDisplay.overlay.mouseEnabled, false, "locked overlay ignores mouse")
ShirsMCPKeybindDisplay:SetLocked(false)
assertEqual(ShirsMCPKeybindDisplay.overlay.mouseEnabled, true, "unlocked overlay accepts mouse")

ShirsMCPKeybindDisplay:SetVisualOption("alpha", 0.5)
ShirsMCPKeybindDisplay:SetVisualOption("fontSize", 10)
local compactAutoWidth = ShirsMCPKeybindDisplay.overlay.width
ShirsMCPKeybindDisplay:SetVisualOption("scale", 1)
ShirsMCPKeybindDisplay:SetVisualOption("fontSize", 24)
local largeFontLogicalWidth = ShirsMCPKeybindDisplay.overlay.width
ShirsMCPKeybindDisplay:SetVisualOption("scale", 1.25)
assertEqual(ShirsMCPKeybindDisplay.overlay.alpha, 0.5, "alpha applies immediately")
assertEqual(ShirsMCPKeybindDisplay.overlay.scale, 1.25, "scale applies immediately")
assertEqual(ShirsMCPKeybindDisplay.overlay.width > compactAutoWidth, true, "card grows when larger text needs more room")
assertEqual(ShirsMCPKeybindDisplay.overlay.width, largeFontLogicalWidth, "scale does not double-apply to logical card width")
assertEqual(ShirsMCPKeybindDisplay.overlay.width * ShirsMCPKeybindDisplay.overlay.scale, largeFontLogicalWidth * 1.25, "scale controls the final on-screen card width exactly once")
assertEqual(ShirsMCPKeybindDisplay.rows[1].label.font[2], 24, "font size applies immediately")

ShirsMCPKeybindDisplay.overlay:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 44, -55)
this = ShirsMCPKeybindDisplay.overlay
ShirsMCPKeybindDisplay.overlay:GetScript("OnDragStop")()
assertEqual(ShirsMCPKeybindDisplay.db.visual.point, "TOPLEFT", "drag saves point")
assertEqual(ShirsMCPKeybindDisplay.db.visual.relativePoint, "TOPLEFT", "drag saves relative point")
assertEqual(ShirsMCPKeybindDisplay.db.visual.x, 44, "drag saves x")
assertEqual(ShirsMCPKeybindDisplay.db.visual.y, -55, "drag saves y")

ShirsMCPKeybindDisplay:SetVisible(false)
assertEqual(ShirsMCPKeybindDisplay.overlay.shown, false, "visibility setting hides overlay")
ShirsMCPKeybindDisplay:SetVisible(true)
assertEqual(ShirsMCPKeybindDisplay.overlay.shown, true, "visibility setting shows overlay")

print("UI_VISUAL_SETTINGS=PASS")

assertEqual(ShirsMCPKeybindDisplay:SetVisualOption("columns", 2), false, "duplicate command-key pairs are rejected")
assertEqual(ShirsMCPKeybindDisplay.db.visual.columns, 1, "HUD remains one vertical command-key table")
assertEqual(ShirsMCPKeybindDisplay:SetVisualOption("width", 400), false, "removed preferred-width option is rejected")
assertEqual(ShirsMCPKeybindDisplay.db.visual.width, nil, "removed preferred width is not persisted")
assertEqual(ShirsMCPKeybindDisplay:SetVisualOption("rowSpacing", 6), true, "row-spacing option accepted")
assertEqual(ShirsMCPKeybindDisplay:SetVisualOption("background", false), true, "background option accepted")
assertEqual(ShirsMCPKeybindDisplay.rows[3].label.points[1][4], ShirsMCPKeybindDisplay.rows[1].label.points[1][4], "all commands stay in one left column")
assertEqual(ShirsMCPKeybindDisplay.rows[3].label.points[1][5] < ShirsMCPKeybindDisplay.rows[1].label.points[1][5], true, "bindings continue down the table")
assertEqual(ShirsMCPKeybindDisplay.rows[1].label.width, ShirsMCPKeybindDisplay.rows[2].label.width, "commands use one small aligned column")
assertEqual(ShirsMCPKeybindDisplay.rows[1].keys.width, ShirsMCPKeybindDisplay.rows[2].keys.width, "keybinds use one aligned column")
assertEqual(ShirsMCPKeybindDisplay.overlay.backdropColor[4], 0, "background can be hidden")
assertEqual(ShirsMCPKeybindDisplay.db.visual.columns, 1, "rejected width preserves the command-key table")

print("UI_LAYOUT_OPTIONS=PASS")

local function click(widget, checked)
    widget:SetChecked(checked)
    this = widget
    arg1 = "LeftButton"
    widget:GetScript("OnClick")()
end

ShirsMCPKeybindDisplay:CreateOptions()
assertEqual(ShirsMCPKeybindDisplay.options.shown, false, "options start hidden")
ShirsMCPKeybindDisplay:ToggleOptions()
assertEqual(ShirsMCPKeybindDisplay.options.shown, true, "options can be opened")
assertEqual(ShirsMCPKeybindDisplay.options.width, 790, "polished settings width")
assertEqual(ShirsMCPKeybindDisplay.options.height, 680, "polished settings height")
assertEqual(ShirsMCPKeybindDisplay.versionLabel.text, "v0.1.0", "release version shown")
assertEqual(ShirsMCPKeybindDisplay.creditLabel.text, "Shirina", "Shirina credit shown")
assertEqual(math.abs(ShirsMCPKeybindDisplay.displayPanel.points[1][5]) + ShirsMCPKeybindDisplay.displayPanel.height <= 594, true, "display card stays above its footer gap")
assertEqual(math.abs(ShirsMCPKeybindDisplay.sliders.rowSpacing.points[1][5]) + ShirsMCPKeybindDisplay.sliders.rowSpacing.height <= 594, true, "row-spacing slider stays inside the display card")
assertEqual(ShirsMCPKeybindDisplay.sliders.width, nil, "preferred-width slider is removed")
assertEqual(math.abs(ShirsMCPKeybindDisplay.footerPanel.points[1][5]) + ShirsMCPKeybindDisplay.footerPanel.height <= ShirsMCPKeybindDisplay.options.height, true, "settings footer stays inside the frame")
assertEqual(math.abs(ShirsMCPKeybindDisplay.creditLabel.points[1][5]) + 9 <= ShirsMCPKeybindDisplay.options.height, true, "Shirina credit stays inside the frame")
assertEqual(ShirsMCPKeybindDisplay.displayPanel.shown, true, "settings display section card")
assertEqual(ShirsMCPKeybindDisplay.entriesPanel.shown, true, "settings bindings section card")
assertEqual(ShirsMCPKeybindDisplay.optionsCategoryFilter, "all", "settings list starts with all categories")
assertEqual(ShirsMCPKeybindDisplay.showUnassignedCheck:GetChecked(), nil, "assigned-only default reflected")
assertEqual(table.getn(ShirsMCPKeybindDisplay.bindingRows), 14, "settings allocates one complete binding page")
assertEqual(ShirsMCPKeybindDisplay.bindingRows[5].check.shown, false, "unused initial rows stay hidden")
assertEqual(ShirsMCPKeybindDisplay.bindingRows[1].label:GetText(), "Show/Hide MCP", "binding row uses MCP label")
assertEqual(sliderSetCalls <= 12, true, "slider refresh is bounded")

local originalTankDefault = ShirsMCPKeybindDisplay.db.categories.tank
this = ShirsMCPKeybindDisplay.categoryFilterButtons.tank
ShirsMCPKeybindDisplay.categoryFilterButtons.tank:GetScript("OnClick")()
assertEqual(ShirsMCPKeybindDisplay.optionsCategoryFilter, "tank", "category control filters the settings list")
assertEqual(table.getn(ShirsMCPKeybindDisplay.optionsEntries), 1, "tank category displays only tank bindings")
assertEqual(ShirsMCPKeybindDisplay.optionsEntries[1].action, "MCP_START_TANK", "tank filter shows the tank action")
assertEqual(ShirsMCPKeybindDisplay.db.categories.tank, originalTankDefault, "category filter does not select HUD bindings")
this = ShirsMCPKeybindDisplay.categoryFilterButtons.all
ShirsMCPKeybindDisplay.categoryFilterButtons.all:GetScript("OnClick")()
assertEqual(ShirsMCPKeybindDisplay.optionsCategoryFilter, "all", "all category restores the full settings list")

click(ShirsMCPKeybindDisplay.backgroundCheck, false)
assertEqual(ShirsMCPKeybindDisplay.db.visual.background, false, "Vanilla nil checkbox value hides the card background")
assertEqual(ShirsMCPKeybindDisplay.overlay.backdropColor[4], 0, "background checkbox hides the backdrop immediately")
click(ShirsMCPKeybindDisplay.backgroundCheck, true)
assertEqual(ShirsMCPKeybindDisplay.db.visual.background, true, "Vanilla numeric checkbox value restores the card background")
click(ShirsMCPKeybindDisplay.visibleCheck, false)
assertEqual(ShirsMCPKeybindDisplay.db.visual.visible, false, "Vanilla nil checkbox value hides the HUD")
assertEqual(ShirsMCPKeybindDisplay.overlay.shown, false, "HUD checkbox hides the overlay immediately")
click(ShirsMCPKeybindDisplay.visibleCheck, true)
assertEqual(ShirsMCPKeybindDisplay.db.visual.visible, true, "Vanilla numeric checkbox value restores the HUD")
assertEqual(ShirsMCPKeybindDisplay.overlay.shown, true, "HUD checkbox restores the overlay immediately")

setglobal("BINDING_NAME_MCP_UNUSED", "Unused command")
table.insert(bindings, { "MCP_UNUSED", nil, nil })
ShirsMCPKeybindDisplay:Refresh()
assertEqual(table.getn(ShirsMCPKeybindDisplay.optionsEntries), 5, "front list initially includes assigned and unassigned commands")
this = ShirsMCPKeybindDisplay.assignedOnlyButton
ShirsMCPKeybindDisplay.assignedOnlyButton:GetScript("OnClick")()
assertEqual(ShirsMCPKeybindDisplay.db.optionsAssignedOnly, true, "assigned-only list filter toggles on")
assertEqual(table.getn(ShirsMCPKeybindDisplay.optionsEntries), 4, "assigned-only list hides unassigned commands")
assertEqual(ShirsMCPKeybindDisplay.assignedOnlyButton.text, "List: Assigned only", "filter button shows its active state")
ShirsMCPKeybindDisplay:SetCategory("tank", false)
ShirsMCPKeybindDisplay:ClearEntryOverride("MCP_START_TANK")
click(ShirsMCPKeybindDisplay.showAllAssignedCheck, true)
assertEqual(ShirsMCPKeybindDisplay.db.showAllAssigned, true, "show-all assigned mode toggles on")
assertEqual(ShirsMCPKeybindDisplay:IsEntryEnabled(ShirsMCPKeybindDisplay.entries[4]), true, "show-all mode includes assigned role bindings")
assertEqual(ShirsMCPKeybindDisplay.db.overrides.MCP_UNUSED, nil, "show-all mode leaves unassigned overrides unchanged")
click(ShirsMCPKeybindDisplay.bindingRows[2].check, false)
assertEqual(ShirsMCPKeybindDisplay.db.showAllAssigned, false, "hiding one binding leaves show-all mode")
assertEqual(ShirsMCPKeybindDisplay.db.overrides.MCP_START, false, "individual binding can be hidden after show-all mode")
assertEqual(ShirsMCPKeybindDisplay:IsEntryEnabled(ShirsMCPKeybindDisplay.entries[2]), false, "individual exclusion takes effect immediately")
ShirsMCPKeybindDisplay:ClearEntryOverride("MCP_START")
click(ShirsMCPKeybindDisplay.showAllAssignedCheck, true)
ShirsMCPKeybindDisplay:Refresh()
assertEqual(ShirsMCPKeybindDisplay.db.showAllAssigned, true, "show-all mode survives a full addon refresh")
assertEqual(ShirsMCPKeybindDisplay.showAllAssignedCheck:GetChecked(), 1, "show-all persisted state is reflected in settings")
SetBinding("SHIFT-F1")
ShirsMCPKeybindDisplay:Refresh()
assertEqual(table.getn(ShirsMCPKeybindDisplay:GetVisibleEntries()), 3, "show-all mode drops a binding that becomes unassigned")
assertEqual(ShirsMCPKeybindDisplay.db.showAllAssigned, true, "show-all mode remains enabled after a binding is cleared")
SetBinding("SHIFT-F1", "MCP_START_TANK")
ShirsMCPKeybindDisplay:Refresh()
assertEqual(table.getn(ShirsMCPKeybindDisplay:GetVisibleEntries()), 4, "show-all mode includes a binding assigned later")
click(ShirsMCPKeybindDisplay.showAllAssignedCheck, false)
assertEqual(ShirsMCPKeybindDisplay.db.showAllAssigned, false, "show-all assigned mode toggles off")
ShirsMCPKeybindDisplay:ToggleAssignedOnlyList()
assertEqual(ShirsMCPKeybindDisplay.db.optionsAssignedOnly, false, "assigned-only list filter toggles off")
table.remove(bindings)
ShirsMCPKeybindDisplay:Refresh()

this = ShirsMCPKeybindDisplay.manageBindingsButton
local firstManagerUpdates = 0
local firstManagerUpdate = ShirsMCPKeybindDisplay.UpdateBindingManager
ShirsMCPKeybindDisplay.UpdateBindingManager = function(self)
    firstManagerUpdates = firstManagerUpdates + 1
    firstManagerUpdate(self)
end
ShirsMCPKeybindDisplay.manageBindingsButton:GetScript("OnClick")()
ShirsMCPKeybindDisplay.UpdateBindingManager = firstManagerUpdate
assertEqual(ShirsMCPKeybindDisplay.bindingManager.shown, true, "binding manager opens")
assertEqual(ShirsMCPKeybindDisplay.options.shown, false, "binding manager hides settings")
assertEqual(firstManagerUpdates, 1, "first binding-manager open refreshes once")
assertEqual(ShirsMCPKeybindDisplay.bindingManager.width, 790, "polished binding manager width")
assertEqual(ShirsMCPKeybindDisplay.bindingManager.height, 610, "polished binding manager height")
assertEqual(math.abs(ShirsMCPKeybindDisplay.bindingListPanel.points[1][5]) + ShirsMCPKeybindDisplay.bindingListPanel.height <= 504, true, "binding list card stays above its footer gap")
assertEqual(math.abs(ShirsMCPKeybindDisplay.bindingFooterPanel.points[1][5]) + ShirsMCPKeybindDisplay.bindingFooterPanel.height <= ShirsMCPKeybindDisplay.bindingManager.height, true, "binding manager footer stays inside the frame")
assertEqual(ShirsMCPKeybindDisplay.bindingManagerRows[1].label.text, "Come", "manager rows render after the polished layout")
this = ShirsMCPKeybindDisplay.bindingFilterButtons.tank
ShirsMCPKeybindDisplay.bindingFilterButtons.tank:GetScript("OnClick")()
assertEqual(table.getn(ShirsMCPKeybindDisplay.bindingManagerEntries), 1, "tank filter isolates tank commands")
assertEqual(ShirsMCPKeybindDisplay.bindingManagerRows[1].bind._smkdAction, "MCP_START_TANK", "tank row targets tank action")
ShirsMCPKeybindDisplay:BeginBindingCapture("MCP_COME", "Come")
this = ShirsMCPKeybindDisplay.bindingCapture; arg1 = "UNKNOWN"
ShirsMCPKeybindDisplay.bindingCapture:GetScript("OnKeyDown")()
assertEqual(ShirsMCPKeybindDisplay.bindingCapture.shown, true, "unknown input leaves capture open")
local modifierKeys = { "SHIFT", "CTRL", "ALT", "LSHIFT", "RSHIFT", "LCTRL", "RCTRL", "LALT", "RALT" }
local modifierIndex
for modifierIndex = 1, table.getn(modifierKeys) do
    arg1 = modifierKeys[modifierIndex]
    ShirsMCPKeybindDisplay.bindingCapture:GetScript("OnKeyDown")()
    assertEqual(ShirsMCPKeybindDisplay.bindingCapture.shown, true, modifierKeys[modifierIndex] .. " alone leaves capture open")
end
arg1 = "ESCAPE"; ShirsMCPKeybindDisplay.bindingCapture:GetScript("OnKeyDown")()
assertEqual(ShirsMCPKeybindDisplay.bindingCapture.shown, false, "Escape cancels capture")
ShirsMCPKeybindDisplay:BeginBindingCapture("MCP_COME", "Come")
this = ShirsMCPKeybindDisplay.bindingCapture; arg1 = "F2"
ShirsMCPKeybindDisplay.bindingCapture:GetScript("OnKeyDown")()
local comePrimary, comeAlternate = GetBindingKey("MCP_COME")
assertEqual(comePrimary, "F2", "same-key capture preserves primary")
assertEqual(comeAlternate, "CTRL-F2", "same-key capture preserves alternate")
assertEqual(bindingSaveCalls, 0, "same-key capture does not save")
this = ShirsMCPKeybindDisplay.bindingManagerRows[1].bind
ShirsMCPKeybindDisplay.bindingManagerRows[1].bind:GetScript("OnClick")()
controlDown = true; this = ShirsMCPKeybindDisplay.bindingCapture; arg1 = "T"
ShirsMCPKeybindDisplay.bindingCapture:GetScript("OnKeyDown")()
controlDown = false
assertEqual(shownPopup, "SMKD_BIND_CONFLICT", "replacing an action's existing keys requires confirmation")
assertEqual(StaticPopupDialogs.SMKD_BIND_CONFLICT.hideOnEscape, 1, "replacement confirmation can be cancelled with Escape")
StaticPopupDialogs.SMKD_BIND_CONFLICT.OnCancel()
assertEqual(GetBindingAction("SHIFT-F1"), "MCP_START_TANK", "replacement cancellation preserves the selected action")
assertEqual(bindingSaveCalls, 0, "replacement cancellation does not save")
assertEqual(ShirsMCPKeybindDisplay.pendingBinding, nil, "replacement cancellation clears pending state")
ShirsMCPKeybindDisplay:BeginBindingCapture("MCP_START_TANK", "Start: Tank")
controlDown = true; this = ShirsMCPKeybindDisplay.bindingCapture; arg1 = "T"
ShirsMCPKeybindDisplay.bindingCapture:GetScript("OnKeyDown")()
controlDown = false
local originalUpdateBindingManager = ShirsMCPKeybindDisplay.UpdateBindingManager
local bindingManagerRefreshes = 0
ShirsMCPKeybindDisplay.UpdateBindingManager = function(self)
    bindingManagerRefreshes = bindingManagerRefreshes + 1
    originalUpdateBindingManager(self)
end
StaticPopupDialogs.SMKD_BIND_CONFLICT.OnAccept()
FlushBindingRefresh()
ShirsMCPKeybindDisplay.UpdateBindingManager = originalUpdateBindingManager
assertEqual(GetBindingAction("CTRL-T"), "MCP_START_TANK", "captured modified key is assigned")
assertEqual(GetBindingAction("SHIFT-F1"), "", "confirmed replace-all removes the former key")
assertEqual(bindingSaveCalls, 1, "captured binding is saved once")
assertEqual(bindingManagerRefreshes, 1, "successful replacement refreshes the binding manager once")
ShirsMCPKeybindDisplay:BeginBindingCapture("MCP_START_TANK", "Start: Tank")
this = ShirsMCPKeybindDisplay.bindingCapture; arg1 = "F1"
ShirsMCPKeybindDisplay.bindingCapture:GetScript("OnKeyDown")()
assertEqual(shownPopup, "SMKD_BIND_CONFLICT", "conflicting key requires confirmation")
StaticPopupDialogs.SMKD_BIND_CONFLICT.OnAccept()
FlushBindingRefresh()
assertEqual(GetBindingAction("F1"), "MCP_START_TANK", "confirmed conflict replaces old action")
assertEqual(GetBindingAction("ALT-F1"), "MCP_START", "confirmed conflict preserves the displaced action's alternate key")
ShirsMCPKeybindDisplay:CommitBinding("MCP_START", "F1")
ShirsMCPKeybindDisplay:CommitBinding("MCP_START_TANK", "CTRL-T")
ShirsMCPKeybindDisplay:SetBindingManagerFilter("tank")
this = ShirsMCPKeybindDisplay.bindingManagerRows[1].clear
bindingManagerRefreshes = 0
ShirsMCPKeybindDisplay.UpdateBindingManager = function(self)
    bindingManagerRefreshes = bindingManagerRefreshes + 1
    originalUpdateBindingManager(self)
end
ShirsMCPKeybindDisplay.bindingManagerRows[1].clear:GetScript("OnClick")()
FlushBindingRefresh()
ShirsMCPKeybindDisplay.UpdateBindingManager = originalUpdateBindingManager
assertEqual(GetBindingAction("CTRL-T"), "", "clear removes all keys from selected tank action")
assertEqual(bindingManagerRefreshes, 1, "successful clear-all refreshes the binding manager once")
ShirsMCPKeybindDisplay:BeginBindingCapture("MCP_START_TANK", "Start: Tank")
altDown = true; controlDown = true; shiftDown = true
this = ShirsMCPKeybindDisplay.bindingCapture; arg1 = "K"
ShirsMCPKeybindDisplay.bindingCapture:GetScript("OnKeyDown")()
altDown = false; controlDown = false; shiftDown = false
assertEqual(GetBindingAction("ALT-CTRL-SHIFT-K"), "MCP_START_TANK", "three modifiers use canonical Vanilla order")
ShirsMCPKeybindDisplay:ClearBinding("MCP_START_TANK")
FlushBindingRefresh()
this = ShirsMCPKeybindDisplay.minimapButton
ShirsMCPKeybindDisplay.minimapButton:GetScript("OnClick")()
assertEqual(ShirsMCPKeybindDisplay.options.shown, true, "minimap button opens settings")
assertEqual(ShirsMCPKeybindDisplay.bindingManager.shown, false, "minimap settings launcher hides binding manager")
ShirsMCPKeybindDisplay:ShowBindingManager()
SlashCmdList["SHIRSMCPKEYBINDDISPLAY"]("")
assertEqual(ShirsMCPKeybindDisplay.options.shown, true, "slash command opens settings from binding manager")
assertEqual(ShirsMCPKeybindDisplay.bindingManager.shown, false, "slash settings launcher hides binding manager")
ShirsMCPKeybindDisplay:SetMinimapVisible(false)
assertEqual(ShirsMCPKeybindDisplay.minimapButton.shown, false, "minimap button can be hidden")
ShirsMCPKeybindDisplay:SetMinimapVisible(true)
assertEqual(ShirsMCPKeybindDisplay.minimapButton.shown, true, "minimap button can be restored")

click(ShirsMCPKeybindDisplay.bindingRows[2].check, false)
assertEqual(ShirsMCPKeybindDisplay.db.overrides.MCP_START, false, "individual general binding hide persists")
click(ShirsMCPKeybindDisplay.bindingRows[4].check, true)
assertEqual(ShirsMCPKeybindDisplay.db.overrides.MCP_START_TANK, true, "individual role binding add persists")

ShirsMCPKeybindDisplay:ResetOverrides()
assertEqual(next(ShirsMCPKeybindDisplay.db.overrides), nil, "individual overrides reset")
assertEqual(ShirsMCPKeybindDisplay.bindingRows[2].check:GetChecked(), 1, "reset restores general category default")
assertEqual(ShirsMCPKeybindDisplay.bindingRows[4].check:GetChecked(), nil, "reset restores tank category default")

SlashCmdList.SHIRSMCPKEYBINDDISPLAY("lock")
assertEqual(ShirsMCPKeybindDisplay.db.visual.locked, true, "slash lock command")
SlashCmdList.SHIRSMCPKEYBINDDISPLAY("unlock")
assertEqual(ShirsMCPKeybindDisplay.db.visual.locked, false, "slash unlock command")
local originalRefreshOptions = ShirsMCPKeybindDisplay.RefreshOptions
local refreshOptionsCalls = 0
ShirsMCPKeybindDisplay.RefreshOptions = function(self)
    refreshOptionsCalls = refreshOptionsCalls + 1
    originalRefreshOptions(self)
end
SlashCmdList.SHIRSMCPKEYBINDDISPLAY("refresh")
assertEqual(refreshOptionsCalls, 1, "slash refresh updates options exactly once")
ShirsMCPKeybindDisplay.RefreshOptions = originalRefreshOptions

local growthIndex
for growthIndex = 1, 11 do
    local action = "MCP_GROWTH_" .. growthIndex
    setglobal("BINDING_NAME_" .. action, "Growth " .. growthIndex)
    table.insert(bindings, { action, "ALT-" .. growthIndex, nil })
end
event = "UPDATE_BINDINGS"
this = ShirsMCPKeybindDisplayEventFrame
ShirsMCPKeybindDisplayEventFrame:GetScript("OnEvent")()
FlushBindingRefresh()
assertEqual(table.getn(ShirsMCPKeybindDisplay.entries), 15, "UPDATE_BINDINGS discovers later MCP entries")
assertEqual(table.getn(ShirsMCPKeybindDisplay.bindingRows), 14, "options row pool grows to a full page")
assertEqual(ShirsMCPKeybindDisplay.bindingRows[14].check._smkdAction, "MCP_GROWTH_10", "page one reaches the fourteenth binding")

this = ShirsMCPKeybindDisplay.nextButton
ShirsMCPKeybindDisplay.nextButton:GetScript("OnClick")()
assertEqual(ShirsMCPKeybindDisplay.bindingRows[1].check._smkdAction, "MCP_GROWTH_11", "page two starts at the fifteenth binding")
assertEqual(ShirsMCPKeybindDisplay.bindingRows[2].check.shown, false, "partial final page hides unused rows")
click(ShirsMCPKeybindDisplay.bindingRows[1].check, false)
assertEqual(ShirsMCPKeybindDisplay.db.overrides.MCP_GROWTH_11, false, "reused page row updates its current action")
this = ShirsMCPKeybindDisplay.prevButton
ShirsMCPKeybindDisplay.prevButton:GetScript("OnClick")()
assertEqual(ShirsMCPKeybindDisplay.bindingRows[1].check._smkdAction, "MCP_PANEL", "previous returns to the first page")
this = ShirsMCPKeybindDisplay.nextButton
ShirsMCPKeybindDisplay.nextButton:GetScript("OnClick")()

local roleFixtures = {
    { "MCP_FIX_HEALER", "Fixture Healer" },
    { "MCP_FIX_TANHE", "Fixture Tank and Healer" },
    { "MCP_FIX_A_DPS", "Alpha DPS" },
    { "MCP_FIX_Z_DPS", "Zulu DPS" },
    { "MCP_FIX_MDPS", "Fixture Melee" },
    { "MCP_FIX_RDPS", "Fixture Ranged" },
}
local fixtureIndex
for fixtureIndex = 1, table.getn(roleFixtures) do
    setglobal("BINDING_NAME_" .. roleFixtures[fixtureIndex][1], roleFixtures[fixtureIndex][2])
    table.insert(bindings, { roleFixtures[fixtureIndex][1], "CTRL-F" .. fixtureIndex, nil })
end
ShirsMCPKeybindDisplay:Refresh()
ShirsMCPKeybindDisplay:ShowBindingManager()
local expectedFilterCounts = { general = 14, tank = 1, healer = 1, tanhe = 1, dps = 2, mdps = 1, rdps = 1, all = 21 }
local filterName, expectedCount
for filterName, expectedCount in expectedFilterCounts do
    ShirsMCPKeybindDisplay:SetBindingManagerFilter(filterName)
    assertEqual(table.getn(ShirsMCPKeybindDisplay.bindingManagerEntries), expectedCount, filterName .. " binding-manager filter count")
end
ShirsMCPKeybindDisplay:SetBindingManagerFilter("dps")
assertEqual(ShirsMCPKeybindDisplay.bindingManagerEntries[1].label, "Alpha DPS", "binding-manager sorts labels within a role")
assertEqual(ShirsMCPKeybindDisplay.bindingManagerEntries[2].label, "Zulu DPS", "binding-manager sort order is stable")
ShirsMCPKeybindDisplay:SetBindingManagerFilter("all")
local orderIndex
for orderIndex = 2, table.getn(ShirsMCPKeybindDisplay.bindingManagerEntries) do
    local previousEntry = ShirsMCPKeybindDisplay.bindingManagerEntries[orderIndex - 1]
    local currentEntry = ShirsMCPKeybindDisplay.bindingManagerEntries[orderIndex]
    assertEqual(previousEntry.category <= currentEntry.category, true, "unfiltered manager sorts categories")
    if previousEntry.category == currentEntry.category then
        assertEqual(string.lower(previousEntry.label) <= string.lower(currentEntry.label), true, "unfiltered manager sorts labels inside categories")
    end
end
assertEqual(ShirsMCPKeybindDisplay.bindingManagerPage, 1, "binding-manager filter resets to page one")
this = ShirsMCPKeybindDisplay.bindingManagerNext
ShirsMCPKeybindDisplay.bindingManagerNext:GetScript("OnClick")()
assertEqual(ShirsMCPKeybindDisplay.bindingManagerPage, 2, "binding manager reaches its second page")
assertEqual(ShirsMCPKeybindDisplay.bindingManagerRows[9].bind.shown, true, "binding-manager partial page shows its final entry")
assertEqual(ShirsMCPKeybindDisplay.bindingManagerRows[10].bind.shown, false, "binding-manager partial page hides stale rows")

while table.getn(bindings) > 3 do table.remove(bindings) end
bindings[1][2] = "CTRL-SHIFT-C"
event = "UPDATE_BINDINGS"
this = ShirsMCPKeybindDisplayEventFrame
ShirsMCPKeybindDisplayEventFrame:GetScript("OnEvent")()
FlushBindingRefresh()
assertEqual(ShirsMCPKeybindDisplay.optionsPage, 1, "shrinking discovery clamps the current page")
assertEqual(ShirsMCPKeybindDisplay.bindingManagerPage, 1, "shrinking discovery clamps the binding-manager page")
assertEqual(ShirsMCPKeybindDisplay.bindingManagerRows[4].bind.shown, false, "binding-manager shrink hides stale rows")
assertEqual(ShirsMCPKeybindDisplay.bindingRows[1].keys:GetText(), "CTRL-SHIFT-C", "open options refresh changed assignments")
assertEqual(ShirsMCPKeybindDisplay.bindingRows[4].check.shown, false, "shrink hides stale rows")

ShirsMCPKeybindDisplay.overlay = nil
ShirsMCPKeybindDisplay.rows = {}
ShirsMCPKeybindDisplay.db.visual.background = false
ShirsMCPKeybindDisplay:CreateOverlay()
assertEqual(ShirsMCPKeybindDisplay.overlay.backdropColor[4], 0, "saved transparent background applies on login")
assertEqual(ShirsMCPKeybindDisplay.overlay.backdropBorderColor[4], 0, "saved transparent border applies on login")

print("UI_OPTIONS_PANEL=PASS")
