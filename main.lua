-- main.lua

repeat task.wait() until game:IsLoaded()

-- Clean up previous instance if exists
if shared.Meteor and type(shared.Meteor.Uninject) == 'function' then
    pcall(shared.Meteor.Uninject)
    task.wait(0.1)
end
shared.Meteor = nil

local Meteor -- Will hold the API table from MeteorClient

-- Environment detection and service cloning
local cloneref = cloneref or function(obj) return obj end
local playersService = cloneref(game:GetService('Players'))
local userInputService = cloneref(game:GetService('UserInputService'))
local httpService = cloneref(game:GetService('HttpService')) -- Used for JSON

-- Simple loadstring wrapper
local function safeLoadstring(code, chunkName)
    local func, err = loadstring(code, chunkName)
    if err then warn("Loadstring error in", chunkName, ":", err); return nil end
    return func
end

-- File system checks needed here too
local isfolder = isfolder or function(f) local s,e=pcall(function() return readfile(f) end); return e and e:find("Cannot find specified file")==nil end
local isfile = isfile or function(file) local s,r=pcall(readfile,file); return s and r~=nil and r~='' end
local readfile = readfile or function() return '' end
local writefile = writefile or function() return false end
local makefolder = makefolder or function() end
local queue_on_teleport = queue_on_teleport or function() end -- Ensure exists

-- HTTP Get function resolution (Synapse compatibility check included)
local httpGet = nil
if syn and syn.request then -- Check for Synapse
	httpGet = function(urlOrTable, useCache) -- Wrapper to handle both signatures
        if type(urlOrTable) == "table" then
            return syn.request(urlOrTable).Body
        else
             -- Synapse doesn't have a direct equivalent for simple HttpGet with caching bool?
             -- Fallback to making a table request anyway.
            return syn.request({Url = urlOrTable, Method = "GET"}).Body
        end
    end
else -- Fallback for other executors
    httpGet = game.HttpGet or HttpGet or http_request or request or game.HttpGetAsync or HttpGetAsync
    if not httpGet then
        warn("Meteor Main: No suitable HTTP GET function found!")
        httpGet = function() return "" end -- Dummy function
    end
end


-- Function to download files (FIXED)
local function downloadFile(path, func)
	local filePath = path
	if not isfile(filePath) then
        local commit = 'main' -- Default commit
        local cs, cc = pcall(readfile,'Meteor_/profiles/commit.txt')
        if cs and cc and cc ~= "" then commit = cc end

		local url = 'https://raw.githubusercontent.com/LiesInTheDarkness/MeteorForRoblox/'.. commit ..'/'..select(1, path:gsub('Meteor_/', ''))
        print("Main: Downloading:", url)

        local suc, res = pcall(function()
            -- Call httpGet correctly depending on what it resolved to
            if syn and syn.request and httpGet == syn.request then -- Check if we are using Synapse's function
                 return httpGet({Url = url, Method = "GET"}) -- Use table for Synapse
            else
                 -- Use standard (URL, Cache) signature for game.HttpGet or others
                 return httpGet(url, true)
            end
        end)

		if not suc then
            warn("Main: pcall error during download:", path, "Error:", tostring(res))
			return (func or function() return nil end)(filePath)
		end

        -- Check response content for errors (like 404)
        if type(res) == 'string' and (res == '404: Not Found' or res:find("404") or res:find("Not Found")) then
            warn("Main: Failed to download (404 Not Found):", path)
            return (func or function() return nil end)(filePath)
        elseif type(res) ~= 'string' then
             warn("Main: Failed to download (Invalid Response Type):", path, "Type:", type(res))
             return (func or function() return nil end)(filePath)
        end

		-- Add watermark and save
		if path:find('.lua') then res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after Meteor updates.\n'..res end
		local writeSuc = pcall(writefile, filePath, res)
        if writeSuc then
             print("Main: Downloaded successfully:", path)
        else
             warn("Main: Failed to write downloaded file:", path)
        end
	end
	return (func or readfile)(filePath)
end


---[[ Load MeteorClient.lua ]]--
local meteorClientCode = downloadFile('Meteor_/MeteorClient.lua')
if not meteorClientCode or meteorClientCode == "" then error("FATAL: Failed to download MeteorClient.lua.") end

local clientLoaderFunc = safeLoadstring(meteorClientCode, 'MeteorClient.lua')
if not clientLoaderFunc then error("FATAL: Failed to load MeteorClient.lua code.") end

-- Execute to get the API table
Meteor = clientLoaderFunc()
if not Meteor or type(Meteor) ~= "table" then error("FATAL: MeteorClient.lua did not return API table.") end
shared.Meteor = Meteor -- Make API globally accessible


---[[ Add Core Non-UI Functions & Properties to Meteor API ]]--
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


---[[ Keybind Handling (Calls API Toggle) ]]--
local function checkKeybindPressed(input)
    if not Meteor or not Meteor.Keybind or #Meteor.Keybind == 0 then return false end
    local primaryKeyPressed = false
    local modifiersRequiredDown = {}
    local primaryKey = nil

    for _, key in ipairs(Meteor.Keybind) do
        local keyEnum = Enum.KeyCode[key] or Enum.UserInputType[key]
        if not keyEnum then goto continue end -- Skip invalid keys

        if not (key:find('Shift') or key:find('Control') or key:find('Alt')) then
             -- Check if it's a UserInputType or KeyCode match
            if input.UserInputType == keyEnum or input.KeyCode == keyEnum then
                primaryKeyPressed = true
                primaryKey = keyEnum -- Store the primary key that was pressed
            end
        else
            modifiersRequiredDown[keyEnum] = true -- Mark modifier as required
        end
        ::continue::
    end

    -- If the input event wasn't the primary key press/type, it can't trigger the bind
    if not primaryKeyPressed then return false end

    -- Check if all required modifier keys are currently held down
    for keyEnumMod, _ in pairs(modifiersRequiredDown) do
        if not userInputService:IsKeyDown(keyEnumMod) then
            -- Allow trigger if the modifier itself was the *last* key pressed in the combo
            -- This check is tricky and might need refinement for complex binds.
            -- For simplicity, we require modifiers to be held *before* primary key.
            return false
        end
    end

    return true -- Primary key pressed and all required modifiers are down
end


Meteor:Clean(userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if checkKeybindPressed(input) then
        pcall(Meteor.ToggleGUI, Meteor) -- Call ToggleGUI from API
    end
end))


---[[ Initialization Logic (Orchestration) ]]--
function Meteor:Init()
    self:Log("Main: Initializing...")
    if self.ShowLoading then pcall(self.ShowLoading, self, "Meteor | Loading Config...") end

    pcall(self.LoadConfig, self)
    task.wait(0.05)

    if self.ShowLoading then pcall(self.ShowLoading, self, "Meteor | Loading Modules...") end

    -- Load Universal Scripts
    local universalCode = downloadFile('Meteor_/games/universal.lua')
    if universalCode and universalCode ~= "" then
        local universalFunc = safeLoadstring(universalCode, 'universal.lua')
        if universalFunc then pcall(universalFunc) end
    end

    -- Load Game-Specific Scripts
    local gameId = game.PlaceId
    local gameScriptPath = 'Meteor_/games/'..gameId..'.lua'
    local gameScriptCode = downloadFile(gameScriptPath)
    if gameScriptCode and gameScriptCode ~= "" then
         local gameFunc = safeLoadstring(gameScriptCode, tostring(gameId)..'.lua')
         if gameFunc then
             if self.ShowLoading then pcall(self.ShowLoading, self, "Meteor | Loading Game Specifics ("..gameId..")...") end
             pcall(gameFunc)
         end
    end

    -- Finalize Loading
    self.Loaded = true
    self:Log("Main: Finished Loading.")
    if self.HideLoading then pcall(self.HideLoading, self) end

    -- Start Auto-Save Loop
    task.spawn(function()
        while self.Loaded and task.wait(15) do
            pcall(self.SaveConfig, self)
        end
        self:Log("Main: Auto-save loop stopped.")
    end)

    -- Teleport Handler
    local teleportedServers = false
	Meteor:Clean(playersService.LocalPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Started and not teleportedServers and not shared.MeteorIndependent then
			teleportedServers = true
            self:Log("Main: Teleport detected.")
			local teleportScript = [[
				shared.Meteorreload = true
                if shared.MeteorDeveloper then shared.MeteorDeveloper = true end
                if shared.MeteorCustomProfile then shared.MeteorCustomProfile = "]]..tostring(self.Profile)..[[" end
                local commit = 'main'; local s,c = pcall(readfile,'Meteor_/profiles/commit.txt'); if s and c and c~="" then commit=c end
				if shared.MeteorDeveloper then loadstring(readfile('Meteor_/loader.lua'),'loader')()
				else loadstring(game:HttpGet('https://raw.githubusercontent.com/LiesInTheDarkness/MeteorForRoblox/'..commit..'/loader.lua', true),'loader')() end
			]]
            pcall(self.SaveConfig, self)
			queue_on_teleport(teleportScript)
            pcall(self.Uninject, self)
		end
	end))

    -- Initial "Finished Loading" Notification
	if not shared.Meteorreload then
		if self.ToggleNotifications and self.ToggleNotifications.Enabled and self.CreateNotification then -- Check toggle exists
			pcall(self.CreateNotification, self,
                'Meteor Loaded',
                'Press '..table.concat(self.Keybind or {'?'}, ' + '):upper()..' to toggle.',
                7, 'info' )
		end
	end
    shared.Meteorreload = false

    -- Apply loaded visual states again after game scripts run
    -- This helps if game scripts create toggles before LoadConfig could update them initially.
    task.defer(function()
        if self.Modules then
            for _, moduleData in pairs(self.Modules) do
                 if moduleData._updateVisual then
                     moduleData._updateVisual(true) -- Update visuals without tween
                 end
            end
        end
    end)
end


---[[ Main Uninjection (Cleans connections, calls GUI Uninject) ]]--
function Meteor:Uninject()
    if not self or not self.Loaded then return end -- Prevent double/invalid uninject
    self:Log("Main: Uninjecting...")
    self.Loaded = false

    for i = #self._connections, 1, -1 do -- Iterate backwards for safety
        pcall(self._connections[i].Disconnect, self._connections[i])
        table.remove(self._connections, i)
    end
    self._connections = {}

    if self.UninjectGUI then
        pcall(self.UninjectGUI, self)
    end

    shared.Meteor = nil
    Meteor = nil -- Allow garbage collection (local var)
    print("Meteor Main: Uninjected.")
end


---[[ Execution Start ]]--
if Meteor and Meteor.ShowLoading then pcall(Meteor.ShowLoading, Meteor, "Meteor | Initializing...") end

if shared.MeteorIndependent then
	if Meteor then Meteor:Log("Main: Meteor loaded in Independent Mode. Call Meteor:Init() manually.") end
	return Meteor
else
	if Meteor then Meteor:Init() else error("FATAL: Meteor API failed to load before Init.") end -- Initialize immediately
end

return Meteor -- Return API table
