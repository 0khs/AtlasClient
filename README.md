# Meteor Client 
*For Roblox*

## Description

Meteor provides a foundation for creating in-game user interfaces (GUIs) to control scripts and cheats. It features:

*   A dynamic loading system (`loader.lua`) that can fetch updates from GitHub.
*   A core GUI client (`MeteorClient.lua`) providing UI elements (Buttons, Toggles, Sliders, TextBoxes) and management.
*   Support for universal scripts (`games/universal.lua`) that run in any game.
*   Support for game-specific scripts (`games/<PlaceId>.lua`).
*   Basic configuration saving/loading.
*   Designed with mobile compatibility in mind using standard Roblox UI instances.

## Basic Usage

1. **Execute the `loader.lua` script:**
    ```lua
    loadstring(game:HttpGet("https://raw.githubusercontent.com/LiesInTheDarkness/MeteorForRoblox/refs/heads/main/loader.lua"))()
    ```
2. **Loader Functionality:**
    - The loader will handle downloading necessary files (if they don't exist or an update is found) and then execute `main.lua` to initialize the GUI.
    - By default, press `RightShift` (or tap the top-right "Meteor" button if it appears) to open/close the GUI.

## Development

### Adding Features
- Modify `MeteorClient.lua` to add new UI element types or core functionality.

### Universal Scripts
- Add code to `games/universal.lua` for features you want in every game.

### Game-Specific Scripts
- Create a new file named `<PlaceId>.lua` inside the `Meteor/games/` folder (e.g., `920587237.lua` for Adopt Me).
- Use the `Meteor` API provided as the first argument to your script.
