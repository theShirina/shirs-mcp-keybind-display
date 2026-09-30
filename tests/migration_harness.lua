-- SavedVariables migration and corruption-resistance harness.

local addonPath = arg[1]
if not addonPath then error("addon path required") end
local GlobalTable = _G
function getglobal(name) return GlobalTable[name] end
function setglobal(name, value) GlobalTable[name] = value end
_G = nil

function GetNumBindings() return 0 end
function GetBinding() end
function CreateFrame()
    local frame = {}
    function frame:RegisterEvent() end
    function frame:SetScript() end
    return frame
end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }

ShirsMCPKeybindDisplayDB = {
    categories = "broken",
    overrides = { MCP_START = "false", MCP_COME = true },
    showUnassigned = "yes",
    optionsAssignedOnly = "yes",
    showAllAssigned = "yes",
    visual = {
        visible = "yes",
        locked = 1,
        point = "BROKEN",
        relativePoint = "NOPE",
        x = "left",
        y = false,
        width = 0,
        alpha = 7,
        scale = -1,
        fontSize = 99,
        columns = 0,
        rowSpacing = -5,
        background = "no",
    },
}

assert(pcall(dofile, addonPath))
ShirsMCPKeybindDisplay:Initialize()

local function assertEqual(actual, expected, label)
    if actual ~= expected then error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual)) end
end

assertEqual(type(ShirsMCPKeybindDisplay.db.categories), "table", "categories repaired")
assertEqual(ShirsMCPKeybindDisplay.db.categories.general, true, "general default restored")
assertEqual(ShirsMCPKeybindDisplay.db.categories.tank, false, "role default restored")
assertEqual(ShirsMCPKeybindDisplay.db.overrides.MCP_START, nil, "invalid override removed")
assertEqual(ShirsMCPKeybindDisplay.db.overrides.MCP_COME, true, "valid override preserved")
assertEqual(ShirsMCPKeybindDisplay.db.showUnassigned, false, "invalid assigned filter repaired")
assertEqual(ShirsMCPKeybindDisplay.db.optionsAssignedOnly, false, "invalid options-list filter repaired")
assertEqual(ShirsMCPKeybindDisplay.db.showAllAssigned, false, "invalid show-all mode repaired")
assertEqual(ShirsMCPKeybindDisplay.db.visual.visible, true, "visible repaired")
assertEqual(ShirsMCPKeybindDisplay.db.visual.locked, false, "locked repaired")
assertEqual(ShirsMCPKeybindDisplay.db.visual.point, "CENTER", "point repaired")
assertEqual(ShirsMCPKeybindDisplay.db.visual.relativePoint, "CENTER", "relative point repaired")
assertEqual(ShirsMCPKeybindDisplay.db.visual.x, 0, "x repaired")
assertEqual(ShirsMCPKeybindDisplay.db.visual.y, 0, "y repaired")
assertEqual(ShirsMCPKeybindDisplay.db.visual.width, nil, "retired preferred width removed")
assertEqual(ShirsMCPKeybindDisplay.db.visual.alpha, 0.78, "alpha repaired")
assertEqual(ShirsMCPKeybindDisplay.db.visual.scale, 1, "scale repaired")
assertEqual(ShirsMCPKeybindDisplay.db.visual.fontSize, 10, "font repaired")
assertEqual(ShirsMCPKeybindDisplay.db.visual.columns, 1, "single command-key table repaired")
assertEqual(ShirsMCPKeybindDisplay.db.visual.rowSpacing, 0, "spacing repaired")
assertEqual(ShirsMCPKeybindDisplay.db.visual.background, true, "background repaired")
assertEqual(ShirsMCPKeybindDisplay.db.schemaVersion, 5, "schema version recorded")
assertEqual(ShirsMCPKeybindDisplay.db.minimap.visible, true, "minimap visibility repaired")
assertEqual(ShirsMCPKeybindDisplay.db.minimap.angle, 220, "minimap angle repaired")

ShirsMCPKeybindDisplay.db.visual.columns = 4
ShirsMCPKeybindDisplay:InitializeDatabase()
assertEqual(ShirsMCPKeybindDisplay.db.visual.width, nil, "retired width remains removed")
assertEqual(ShirsMCPKeybindDisplay.db.visual.columns, 1, "saved columns are repaired to one table")

ShirsMCPKeybindDisplayDB = {
    schemaVersion = 1,
    categories = { general = false },
    overrides = { MCP_START = false },
    showUnassigned = true,
    optionsAssignedOnly = true,
    visual = { visible = false, locked = true, point = "TOPLEFT", relativePoint = "TOPLEFT", x = 11, y = -22, width = 600, alpha = 0.5, scale = 1.2, fontSize = 14, columns = 2, rowSpacing = 3, background = false },
}
ShirsMCPKeybindDisplay:InitializeDatabase()
assertEqual(ShirsMCPKeybindDisplay.db.categories.general, false, "schema-one category choice survives migration")
assertEqual(ShirsMCPKeybindDisplay.db.overrides.MCP_START, false, "schema-one override survives migration")
assertEqual(ShirsMCPKeybindDisplay.db.visual.width, nil, "old visual width is retired")
assertEqual(ShirsMCPKeybindDisplay.db.visual.columns, 1, "old layout migrates to one command-key table")
assertEqual(ShirsMCPKeybindDisplay.db.optionsAssignedOnly, true, "schema-one list filter survives migration")
assertEqual(ShirsMCPKeybindDisplay.db.minimap.visible, true, "schema-one migration adds minimap defaults")
assertEqual(ShirsMCPKeybindDisplay.db.minimap.angle, 220, "schema-one migration adds default minimap angle")
ShirsMCPKeybindDisplay.db.minimap.visible = false
ShirsMCPKeybindDisplay.db.minimap.angle = 123
ShirsMCPKeybindDisplay:InitializeDatabase()
assertEqual(ShirsMCPKeybindDisplay.db.minimap.visible, false, "valid minimap visibility survives repair")
assertEqual(ShirsMCPKeybindDisplay.db.minimap.angle, 123, "valid minimap angle survives repair")

ShirsMCPKeybindDisplayDB = {
    schemaVersion = 4,
    categories = { general = true },
    overrides = {},
    showUnassigned = false,
    optionsAssignedOnly = false,
    showAllAssigned = true,
    visual = { visible = true, locked = false, point = "CENTER", relativePoint = "CENTER", x = 0, y = 0, width = 420, alpha = 0.8, scale = 1, fontSize = 11, columns = 4, rowSpacing = 2, background = true },
}
ShirsMCPKeybindDisplay:InitializeDatabase()
assertEqual(ShirsMCPKeybindDisplay.db.showAllAssigned, true, "show-all mode survives logout-login repair")
assertEqual(ShirsMCPKeybindDisplay.db.visual.width, nil, "schema-four width is removed")
assertEqual(ShirsMCPKeybindDisplay.db.visual.columns, 1, "current layout remains one command-key table")

print("RUNTIME_MIGRATION=PASS")
