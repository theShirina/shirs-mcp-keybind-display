# Shir's MCP Keybind Display

Version 0.1.0 for Microbot's World of Warcraft 1.12.1 client (Interface 11200). Microbot Control Panel must be installed and enabled.

Shir's MCP Keybind Display shows the registered Microbot Control Panel actions and their assigned keys. It reads the client's binding table, so new MCP actions appear without a copied command list. The addon does not add or replace MCP commands.

## Download and install

Download the ZIP from [GitHub Releases](https://github.com/theShirina/shirs-mcp-keybind-display/releases) and extract `ShirsMCPKeybindDisplay` into `Interface/AddOns`. Enable Shir's MCP Keybind Display on the AddOns screen, then restart the client after installing the addon for the first time. For later updates, restart the client or use `/reload`.

## Use

- `/smkd` opens or closes settings.
- `/smkd show` and `/smkd hide` show or hide the HUD.
- `/smkd lock` and `/smkd unlock` lock or unlock HUD dragging. When unlocked, drag anywhere on the HUD to move it.
- `/smkd refresh` reads the current bindings again.
- `/smkd reset` clears individual visibility choices and returns actions to their category defaults. It does not reset position, appearance, category choices, or keybindings.
- `/smkd minimap` shows or hides the minimap button. Click it to open or close settings, or drag it around the minimap.

The HUD is a single auto-sized vertical list. Command labels appear on the left and assigned keys on the right. When enabled, unassigned actions show as `Unassigned`. The settings list and keybind editor have Previous and Next controls.

Settings include HUD visibility and position, background, minimap visibility, opacity, font size, scale, row spacing, category filters, and individual action visibility. List filters do not change HUD choices. Show all assigned displays every assigned MCP action regardless of category and individual choices. Use category defaults, or `/smkd reset`, to clear individual visibility choices.

A new profile shows General actions and hides unassigned actions by default. Existing standalone preferences carry forward, including saved role choices and minimap settings.

## Keybind editor

Choose Manage keybinds in settings to filter commands by role and edit their WoW keybindings. Replace captures a key, including modifiers, and assigns it to the selected command. Escape cancels capture. If the command already has keys or the chosen key belongs to another command, the editor explains the change and asks for confirmation; cancel leaves bindings unchanged. Clear all removes both keys for that command.

Replace and Clear all save successful changes to the current WoW binding set. Display choices do not change keybindings. If an edit fails, the addon attempts to restore the affected bindings and does not save the failed change. If it cannot fully restore them, a chat warning asks you to review that command in WoW Key Bindings. Confirmed key conflicts can remove a key from another command, so read the prompt before accepting.

Display preferences are saved separately from WoW keybindings. This addon does not send companion commands, call MCP functions, or change another addon's files or saved data.

## Compatibility

Made for Microbot's World of Warcraft 1.12.1 client. Requires Microbot Control Panel.
