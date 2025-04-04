-- main.lua

repeat task.wait() until game:IsLoaded()

if shared.Meteor and type(shared.Meteor.Uninject) == 'function' then
    pcall(shared.Meteor.Uninject)
    task.wait(0.1)
end
shared.Meteor = nil

local Meteor -- Will hold the API table from MeteorClient

-- Services needed in main
local playersService = cloneref(game:GetService('Players'))
local userInputService = cloneref(game:GetService('UserInputService'))
local httpService = cloneref(game:GetService('HttpService')) -- For GUID, maybe other non-UI tasks

-- Simple loadstring wrapper
local function safeLoadstring(code, chunkName)
    local func, err = loadstring(code, chunkName)
    if err then warn("Loadstring error in", chunkName, ":", err); return nil end
    return func
end

-- File system checks needed here too
local isfile = isfile or function(file) local s,r=pcall(readfile,file); return s and r~=nil and r~='' end
local readfile = readfile or function() return '' end
local writefile = writefile or function() end -- Ensure exists if used elsewhere in main
local makefolder = makefolder or function() end
local queue_on_teleport = queue_on_teleport or function() end -- Ensure exists

-- HTTP Get needed for downloading client/scripts
local httpGet = (syn and syn.request) and function(req) local resp = syn.request({Url=req.Url, Method=req.Method or "GET"}); return resp.Body end or game.HttpGet or HttpGet or http_request or request or function() return "" end

-- Function to download files (kept here as main orchestrates loading)
local function downloadFile(path, func)
	local filePath = path
	if not isfile(filePath) then
        local commit = 'main' -- Default commit
        if isfile('Meteor_/profiles/commit.txt') then commit = readfile('Meteor_/profiles/commit.txt') end
		local url = 'https://raw.githubusercontent.com/LiesInTheDarkness/MeteorForRoblox/'.. commit ..'/'..select(1, path:gsub('Meteor_/', ''))
        print("Main: Downloading:", url)
		local suc, res = pcall(function() return httpGet({Url = url, Method = "GET"}) end)
		if not suc or (res and (res == '404: Not Found' or res:find("404")) ) then
            warn("Main: Failed to download:", path, "Error:", res)
			return (func or function() return nil end)(filePath)
		end
		if path:find('.lua') then res = '--Watermark\n'..res end -- Basic watermark
		writefile(filePath, res)
        print("Main: Downloaded successfully:", path)
	end
	return (func or readfile)(filePath)
end


--[[ Load MeteorClient.lua ]]--
local meteorClientCode = downloadFile('Meteor_/MeteorClient.lua')
if not meteorClientCode or meteorClientCode == "" then error("FATAL: Failed to download MeteorClient.lua.") end

local clientLoaderFunc = safeLoadstring(meteorClientCode, 'MeteorClient.lua')
if not clientLoaderFunc then error("FATAL: Failed to load MeteorClient.lua code.") end

-- Execute to get the API table
Meteor = clientLoaderFunc()
if not Meteor or type(Meteor) ~= "table" then error("FATAL: MeteorClient.lua did not return API table.") end
shared.Meteor = Meteor -- Make API globally accessible


--[[ Add Core Non-UI Functions & Properties to Meteor API ]]--
Meteor.ExecutingScript = getexecutorname and getexecutorname() or 'Unknown'
Meteor.Debug = shared.MeteorDeveloper or false
Meteor._connections = {} -- Connections managed by main

function Meteor:Log(...)
    if self.Debug then print("Meteor Debug:", ...) end
end

function Meteor:Clean(connection)
    if connection then table.insert(self._connections, connection) end
    return connection
end

-- Set initial profile name from shared var if exists
Meteor.Profile = shared.MeteorCustomProfile or Meteor.Profile or 'default'


--[[ Keybind Handling (Calls API Toggle) ]]--
local function checkKeybindPressed(input)
    -- Uses Meteor.Keybind which is loaded/set by MeteorClient's LoadConfig
    if not Meteor or not Meteor.Keybind or #Meteor.Keybind == 0 then return false end
    -- Simplified check: is the primary key pressed AND are all modifier keys down?
    local primaryKeyPressed = false
    local modifiersRequiredDown = {}
    local primaryKey

    for _, key in ipairs(Meteor.Keybind) do
        if not (key:find('Shift') or key:find('Control') or key:find('Alt')) then
            primaryKey = Enum.KeyCode[key] or Enum.UserInputType[key]
            if input.KeyCode == primaryKey or input.UserInputType == primaryKey then
                primaryKeyPressed = true
            end
        else
            modifiersRequiredDown[Enum.KeyCode[key] or Enum.UserInputType[key]] = true
        end
    end

    if not primaryKeyPressed then return false end

    for keycode, _ in pairs(modifiersRequiredDown) do
        if not userInputService:IsKeyDown(keycode) then
            return false -- A required modifier is not down
        end
    end
    return true
end

Meteor:Clean(userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    -- Use MeteorClient's ToggleGUI
    if checkKeybindPressed(input) then
        pcall(Meteor.ToggleGUI, Meteor) -- Call ToggleGUI from API
    end
end))


--[[ Initialization Logic (Orchestration) ]]--
function Meteor:Init()
    self:Log("Main: Initializing...")
    if self.ShowLoading then pcall(self.ShowLoading, self, "Meteor | Loading Config...") end

    -- Load configuration using the function from MeteorClient API
    pcall(self.LoadConfig, self)
    task.wait(0.05) -- Short pause after loading config

    if self.ShowLoading then pcall(self.ShowLoading, self, "Meteor | Loading Modules...") end

    -- Load Universal Scripts (these will use the shared.Meteor API)
    local universalCode = downloadFile('Meteor_/games/universal.lua')
    if universalCode and universalCode ~= "" then
        local universalFunc = safeLoadstring(universalCode, 'universal.lua')
        if universalFunc then pcall(universalFunc) end -- Execute universal script
    end

    -- Load Game-Specific Scripts (these will use the shared.Meteor API)
    local gameId = game.PlaceId
    local gameScriptPath = 'Meteor_/games/'..gameId..'.lua'
    local gameScriptCode = downloadFile(gameScriptPath)
    if gameScriptCode and gameScriptCode ~= "" then
         local gameFunc = safeLoadstring(gameScriptCode, tostring(gameId)..'.lua')
         if gameFunc then
             if self.ShowLoading then pcall(self.ShowLoading, self, "Meteor | Loading Game Specifics ("..gameId..")...") end
             pcall(gameFunc) -- Execute game-specific script
         end
    end

    -- Finalize Loading
    self.Loaded = true -- Mark Meteor as fully loaded
    self:Log("Main: Finished Loading.")
    if self.HideLoading then pcall(self.HideLoading, self) end -- Hide loading screen via API

    -- Start Auto-Save Loop (Calls API Save)
    task.spawn(function()
        while self.Loaded and task.wait(15) do
            pcall(self.SaveConfig, self) -- Call SaveConfig from API
        end
        self:Log("Main: Auto-save loop stopped.")
    end)

    -- Teleport Handler (Calls API Save and Uninject)
    local teleportedServers = false
	Meteor:Clean(playersService.LocalPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Started and not teleportedServers and not shared.MeteorIndependent then
			teleportedServers = true
            self:Log("Main: Teleport detected.")
			local teleportScript = [[ -- Script remains the same
				shared.Meteorreload = true
                if shared.MeteorDeveloper then shared.MeteorDeveloper = true end
                if shared.MeteorCustomProfile then shared.MeteorCustomProfile = "]]..tostring(self.Profile)..[[" end -- Use current profile
                local commit = 'main'; local s,c = pcall(readfile,'Meteor_/profiles/commit.txt'); if s and c and c~="" then commit=c end
				if shared.MeteorDeveloper then loadstring(readfile('Meteor_/loader.lua'),'loader')()
				else loadstring(game:HttpGet('https://raw.githubusercontent.com/LiesInTheDarkness/MeteorForRoblox/'..commit..'/loader.lua', true),'loader')() end
			]]
            -- Save current config via API before teleporting
            pcall(self.SaveConfig, self)
			queue_on_teleport(teleportScript)
            -- Uninject via main uninject function (which calls GUI uninject)
            pcall(self.Uninject, self)
		end
	end))

    -- Initial "Finished Loading" Notification (Calls API CreateNotification)
	if not shared.Meteorreload then
		if self.ToggleNotifications.Enabled and self.CreateNotification then -- Check if API function exists
			pcall(self.CreateNotification, self,
                'Meteor Loaded',
                'Press '..table.concat(self.Keybind or {'?'}, ' + '):upper()..' to toggle.', -- Use loaded keybind
                7, 'info' )
		end
	end
    shared.Meteorreload = false -- Reset reload flag
end


--[[ Main Uninjection (Cleans connections, calls GUI Uninject) ]]--
function Meteor:Uninject()
    if not self.Loaded then return end -- Prevent double uninject
    self:Log("Main: Uninjecting...")
    self.Loaded = false -- Stop loops, prevent re-entry

    -- Disconnect all managed connections in main
    for _, conn in ipairs(self._connections) do
        pcall(conn.Disconnect, conn)
    end
    self._connections = {}

    -- Call the GUI-specific uninject function from MeteorClient API
    if self.UninjectGUI then
        pcall(self.UninjectGUI, self)
    end

    -- Clean up shared references
    shared.Meteor = nil
    Meteor = nil -- Allow garbage collection
    print("Meteor Main: Uninjected.")
end


--[[ Execution Start ]]--
if Meteor.ShowLoading then pcall(Meteor.ShowLoading, Meteor, "Meteor | Initializing...") end -- Show loading early

if shared.MeteorIndependent then
	Meteor:Log("Main: Meteor loaded in Independent Mode. Call Meteor:Init() manually.")
	return Meteor
else
	Meteor:Init() -- Initialize immediately
end

return Meteor -- Return API table
