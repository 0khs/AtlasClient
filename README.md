# Meteor Client 
* For Roblox

## Basic Usage

•  Execute the `loader.lua` script:
    ```lua loadstring(game:HttpGet("https://raw.githubusercontent.com/LiesInTheDarkness/MeteorForRoblox/refs/heads/main/loader.lua"))():
    ```
•  The loader will handle downloading necessary files (if they don't exist or an update is found) and then execute `main.lua` to initialize the GUI.
•  By default, press `RightShift` (or tap the top-right "Meteor" button if it appears) to open/close the GUI.

## Development

*   **Adding Features:** Modify `MeteorClient.lua` to add new UI element types or core functionality.
*   **Universal Scripts:** Add code to `games/universal.lua` for features you want in every game.
*   **Game-Specific Scripts:** Create a new file named `<PlaceId>.lua` inside the `Meteor/games/` folder (e.g., `920587237.lua` for Adopt Me). Use the `Meteor` API provided as the first argument to your script function to add game-specific options. See the example file (`123456789.lua`) for structure.
