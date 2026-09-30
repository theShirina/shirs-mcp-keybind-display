assert(_VERSION == "Lua 5.0.3")
local env = _G
function getglobal(n) return env[n] end
_G = nil
function CreateFrame() return {RegisterEvent=function() end,SetScript=function() end} end
function GetNumBindings() return 0 end
function SetBinding() error("migration must not change native bindings") end
function SaveBindings() error("migration must not save native bindings") end
CCPKeybindDisplayDB = { sentinel = true }
ShirsMCPKeybindDisplayDB = {schema=1,visible=false,locked=true,background=false,unassigned=true,fontSize=16,scale=1.4,position={point="TOPLEFT",relativePoint="BOTTOMLEFT",x=123,y=456},actions={MCP_START=false,MCP_START_TANK=true,MCP_FUTURE_RDPS=false},minimap={visible=false,angle=123},sentinel={untouched=true}}
local original = ShirsMCPKeybindDisplayDB
local actions, position, minimap = original.actions, original.position, original.minimap
dofile(arg[1] or "runtime/Core.lua")
local A = ShirsMCPKeybindDisplay
assert(A.InitializeDatabase,"missing full CCP database/migration path")
A:InitializeDatabase()
assert(A.db==original and A.db.schemaVersion==5)
assert(A.db.standaloneMigration==1)
assert(A.db.visual.visible==false and A.db.visual.locked==true and A.db.visual.background==false)
assert(A.db.visual.fontSize==16 and A.db.visual.scale==1.4 and A.db.showUnassigned==true)
assert(A.db.visual.point=="TOPLEFT" and A.db.visual.relativePoint=="BOTTOMLEFT" and A.db.visual.x==123 and A.db.visual.y==456)
assert(A.db.minimap==minimap and A.db.minimap.visible==false and A.db.minimap.angle==123)
assert(A.db.overrides.MCP_START==false and A.db.overrides.MCP_START_TANK==true and A.db.overrides.MCP_FUTURE_RDPS==false)
for _,category in ipairs({"general","tank","healer","tanhe","dps","mdps","rdps"}) do assert(A.db.categories[category]==true,"standalone enabled all roles") end
assert(A.db.actions==actions and A.db.position==position and A.db.sentinel.untouched and CCPKeybindDisplayDB.sentinel)
A.db.visual.visible=true; A.db.overrides.MCP_START=true; A.db.categories.tank=false; A.db.showUnassigned=false
A:InitializeDatabase()
assert(A.db.visual.visible and A.db.overrides.MCP_START and A.db.categories.tank==false and A.db.showUnassigned==false,"migration reran")
ShirsMCPKeybindDisplayDB={schema=1,visible=false,actions={MCP_START=false},visual={visible=true},overrides={MCP_START=true},categories={tank=false},showUnassigned=false,unassigned=true}
A:InitializeDatabase()
assert(A.db.visual.visible==true and A.db.overrides.MCP_START==true and A.db.categories.tank==false and A.db.showUnassigned==false,"existing target choices win")
ShirsMCPKeybindDisplayDB={}
A:InitializeDatabase()
assert(A.db.visual.fontSize==10 and A.db.visual.visible and A.db.categories.general and not A.db.categories.tank,"fresh CCP defaults")
assert(A.db.standaloneMigration==nil,"fresh DB is not a standalone migration")
ShirsMCPKeybindDisplayDB={schema=1,position={point="bad",relativePoint="CENTER",x=1,y=2},visible="bad",actions={MCP_START="bad",MCP_STOP=false},minimap={angle=0/0,visible=false}}
A:InitializeDatabase()
assert(A.db.visual.point=="CENTER" and A.db.visual.visible and A.db.overrides.MCP_START==nil and A.db.overrides.MCP_STOP==false)
assert(A.db.minimap.angle==220 and A.db.minimap.visible==false,"malformed angle repair")
print("STANDALONE_MIGRATION=PASS (one-time, target-wins, all-role preservation, future overrides, native bindings untouched)")
