# GUT Installation Required

This directory is a placeholder for the GUT (Godot Unit Testing) addon.

## Installation Steps

1. **Download GUT from AssetLib:**
   - Open Godot Editor
   - Go to **AssetLib** tab (top center)
   - Search for "GUT" or "Godot Unit Test"
   - Download and install the addon by **bitwes**

2. **Or Download from GitHub:**
   - Visit: https://github.com/bitwes/Gut
   - Download the latest release for Godot 4.x
   - Extract to this `addons/gut/` directory

3. **Enable the Plugin:**
   - Go to **Project > Project Settings > Plugins**
   - Find "GUT" in the list
   - Set status to **Enabled**

4. **Restart Editor:**
   - Close and reopen the Godot Editor
   - The GUT panel should appear at the bottom

## Verifying Installation

After installation, this directory should contain files like:
- `plugin.cfg`
- `gut.gd`
- `gut_cmdln.gd`
- `test.gd`
- And many other GUT source files

## Running Tests

Once GUT is installed:
1. Open the GUT panel at the bottom of the editor
2. Click **Run All** to execute all tests
3. Tests are located in `res://tests/unit/` and `res://tests/integration/`

## Configuration

Test configuration is defined in `.gutconfig.json` at the project root.
