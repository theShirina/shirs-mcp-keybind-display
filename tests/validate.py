from pathlib import Path
import argparse, importlib.util, subprocess, zipfile, os
ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--lua', default=str(ROOT/'tools/lua503/lua50.exe'))
parser.add_argument('--luac', default=str(ROOT/'tools/lua503/luac50.exe'))
parser.add_argument('--mcp', default=os.environ.get('SMKD_MCP_PATH'), help='Inspected MicrobotControlPanel folder for the 117-action source fixture')
args = parser.parse_args()
flags = 0x08000000

def run(command):
    environment = os.environ.copy()
    if args.mcp: environment['SMKD_MCP_PATH'] = args.mcp
    result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True, creationflags=flags, env=environment)
    print(result.stdout, end=''); print(result.stderr, end='')
    assert result.returncode == 0, command

run([args.lua, '-v'])
assert args.mcp, 'Supply --mcp for all 117 installed MCP definitions'
cases = [('runtime_harness.lua', 'runtime/Core.lua'), ('ui_harness.lua', 'runtime/Core.lua', 'runtime/UI.lua'), ('migration_harness.lua', 'runtime/Core.lua'), ('standalone_migration.lua', 'runtime/Core.lua'), ('port_minimap.lua',), ('port_catalogue.lua',)]
for case in cases:
    run([args.lua, 'tests/'+case[0]] + list(case[1:]))
for path in sorted((ROOT/'runtime').glob('*.lua')):
    run([args.luac, '-p', str(path)])
toc = (ROOT/'runtime/ShirsMCPKeybindDisplay.toc').read_text()
assert '## Interface: 11200' in toc
assert '## Title: Shir\'s MCP Keybind Display' in toc
assert '## Version: 0.1.0' in toc
assert '## Dependencies: MicrobotControlPanel' in toc
assert '## SavedVariables: ShirsMCPKeybindDisplayDB' in toc
references = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith('#')]
assert references == ['Core.lua', 'UI.lua']
for file in (ROOT/'runtime').iterdir():
    source = file.read_text()
    for forbidden in ['CCP', '/ckd', 'SendChatMessage', 'rawget(_G', '_G[']:
        assert forbidden not in source, (file, forbidden)
assert (ROOT/'tools/package.py').exists(), 'MISSING PACKAGE IMPLEMENTATION'
spec = importlib.util.spec_from_file_location('package', ROOT/'tools/package.py')
package = importlib.util.module_from_spec(spec); spec.loader.exec_module(package)
a = ROOT/'dist/check-a.zip'; b = ROOT/'dist/check-b.zip'
package.build(a); package.build(b)
assert a.read_bytes() == b.read_bytes(), 'deterministic build'
with zipfile.ZipFile(a) as z:
    assert z.testzip() is None
    expected = ['ShirsMCPKeybindDisplay/'+name for name in ['Core.lua','UI.lua','ShirsMCPKeybindDisplay.toc','LICENSE']]
    assert sorted(z.namelist()) == sorted(expected), z.namelist()
    for name in expected:
        source = ROOT/'runtime'/Path(name).name
        if Path(name).name == 'LICENSE': source = ROOT/'LICENSE'
        assert z.read(name).decode() == source.read_text(), name
package.build(ROOT/'dist/ShirsMCPKeybindDisplay-0.1.0-candidate.zip')
a.unlink(); b.unlink()
print('validation: PASS (Lua 5.0.3 full runtime/UI/editor/migration/minimap/all-117, production syntax, MCP-only boundary, TOC, deterministic runtime package)')
