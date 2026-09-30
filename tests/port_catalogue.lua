assert(_VERSION=="Lua 5.0.3")
local path=assert(os.getenv("SMKD_MCP_PATH"))
local xml=assert(io.open(path.."/Bindings.xml","r")):read("*a")
local env=_G
function getglobal(n) return env[n] end
_G=nil
function CreateFrame() return {RegisterEvent=function() end,SetScript=function() end} end
local rows={}
for action in string.gfind(xml,'<Binding name="([^"]+)"') do table.insert(rows,{action,"CTRL-F"..table.getn(rows)}) end
assert(table.getn(rows)==117)
table.insert(rows,{"CP","BAD"}); table.insert(rows,{"CCP_START","BAD"})
function GetNumBindings() return table.getn(rows) end
function GetBinding(i) return unpack(rows[i]) end
dofile("runtime/Core.lua")
local A=ShirsMCPKeybindDisplay
ShirsMCPKeybindDisplayDB={schema=1}; A:InitializeDatabase(); A:DiscoverBindings()
assert(table.getn(A.entries)==117 and table.getn(A:GetVisibleEntries())==117)
local categories={}
for i,e in ipairs(A.entries) do assert(e.action==rows[i][1] and e.key1==rows[i][2]); categories[e.category]=true end
for _,c in ipairs({"general","tank","healer","tanhe","dps","mdps","rdps"}) do assert(categories[c],c) end
assert(A.entries[1].action=="MCP_PANEL")
print("CATALOGUE_ALL_117=PASS (MCP order/keys/all roles, CCP/CP excluded; source fixture)")
