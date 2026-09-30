-- Prior launcher cases rebased onto the complete CCP UI API.
assert(_VERSION == "Lua 5.0.3")
arg={"runtime/Core.lua","runtime/UI.lua"}; dofile("tests/ui_harness.lua")
local A=ShirsMCPKeybindDisplay
local function fire(f,s) this=f; assert(f:GetScript(s))() end
local function near(a,b) assert(math.abs(a-b)<0.00001) end
local function position(angle)
 local p,parent,r,x,y=A.minimapButton:GetPoint()
 assert(p=="TOPLEFT" and parent==Minimap and r=="TOPLEFT")
 near(x,54-78*math.cos(math.rad(angle))); near(y,78*math.sin(math.rad(angle))-55)
end
ShirsMCPKeybindDisplayDB={schema=1,visible=false,locked=true,actions={MCP_START=false},minimap={visible=true,angle=220}}
A.minimapButton=nil; A:Initialize(); local b=A.minimapButton
assert(b.name=="ShirsMCPKeybindDisplayMinimapButton" and b.width==32 and b.height==32 and b.strata=="MEDIUM")
assert(b.frameLevel==Minimap:GetFrameLevel()+8 and not A.overlay:IsShown())
local icon,border=b.children[1],b.children[2]
assert(icon.texture=="Interface\\Icons\\INV_Misc_Key_03" and icon.width==20 and icon.height==20)
assert(icon.texCoord[1]==0.08 and icon.texCoord[2]==0.92 and icon.texCoord[3]==0.08 and icon.texCoord[4]==0.92)
assert(border.texture=="Interface\\Minimap\\MiniMap-TrackingBorder" and border.width==52 and border.height==52)
assert(b.highlightTexture=="Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"); position(220)
A.options:Hide(); fire(b,"OnClick"); assert(A.options:IsShown()); fire(b,"OnClick"); assert(not A.options:IsShown())
SlashCmdList.SHIRSMCPKEYBINDDISPLAY(""); assert(A.options:IsShown())
local check=A.minimapCheck
check:SetChecked(nil); fire(check,"OnClick"); assert(not b:IsShown() and not A.db.minimap.visible)
check:SetChecked(1); fire(check,"OnClick"); assert(b:IsShown() and A.db.minimap.visible)
SlashCmdList.SHIRSMCPKEYBINDDISPLAY("minimap"); assert(not b:IsShown())
SlashCmdList.SHIRSMCPKEYBINDDISPLAY("minimap"); assert(b:IsShown())
SlashCmdList.SHIRSMCPKEYBINDDISPLAY("show"); assert(A.overlay:IsShown() and b:IsShown())
SlashCmdList.SHIRSMCPKEYBINDDISPLAY("hide"); assert(not A.overlay:IsShown() and b:IsShown())
UIParent:SetScale(0.5)
function GetCursorPosition() return 85,135 end
fire(b,"OnDragStart"); fire(b,"OnUpdate"); near(A.db.minimap.angle,90); position(90)
function GetCursorPosition() return 85,55 end
fire(b,"OnDragStop"); assert(b:GetScript("OnUpdate")==nil); near(A.db.minimap.angle,270); position(270)
local saved=A.db; A.minimapButton=nil; A:Initialize(); b=A.minimapButton
assert(A.db==saved and not A.db.visual.visible and A.db.visual.locked and A.db.overrides.MCP_START==false); position(270)
A:SetMinimapVisible(false); A.minimapButton=nil; A:Initialize(); b=A.minimapButton
assert(not b:IsShown()); position(270)
for _,v in ipairs({"bad",{},{visible="bad",angle=360},{visible=false,angle=-1},{visible=false,angle=0/0},{visible=false,angle=math.huge}}) do
 ShirsMCPKeybindDisplayDB={schema=1,visible=false,locked=true,minimap=v}; A:InitializeDatabase()
 assert(A.db.minimap.angle==220 and not A.db.visual.visible and A.db.visual.locked)
end
ShirsMCPKeybindDisplayDB={schema=1,visible=false,minimap={visible=false,angle=0}}; A:InitializeDatabase()
A.minimapButton=nil; local map=Minimap; Minimap=nil; assert(A:CreateMinimapButton()==nil)
Minimap=map; b=A:CreateMinimapButton(); assert(b and not b:IsShown()); position(0)
print("MINIMAP_PORT=PASS (artwork/click/checkbox/slash/drag/persistence/malformed state/absent Minimap; mock only)")
