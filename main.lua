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


-- Function to download files
local function downloadFile(path, func)
	local filePath = path
	if not isfile(filePath) then
        local commit = 'main' -- Default commit
        local cs, cc = pcall(readfile,'Meteor_/profiles/commit.txt')
        if cs and cc and cc ~= "" then commit = cc end

		local url = 'https://raw.githubusercontent.com/LiesInTheDarkness/MeteorForRoblox/'.. commit ..'/'..select(1, path:gsub('Meteor_/', ''))
        print("Main: Downloading:", url)

        local suc, res = pcall(function()
            if syn and syn.request and httpGet == syn.request then
                 return httpGet({Url = url, Method = "GET"}) -- Use table for Synapse
            else
                 return httpGet(url, true) -- Use standard for others
            end
        end)

		if not suc then
            warn("Main: pcall error during download:", path, "Error:", tostring(res))
			return (func or function() return nil end)(filePath)
		end

        if type(res) == 'string' and (res == '404: Not Found' or res:find("404") or res:find("Not Found")) then
            warn("Main: Failed to download (404 Not Found):", path)
            return (func or function() return nil end)(filePath)
        elseif type(res) ~= 'string' then
             warn("Main: Failed to download (Invalid Response Type):", path, "Type:", type(res))
             return (func or function() return nil end)(filePath)
        end

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
    -- Add check to prevent adding nil connection
    if connection then
        table.insert(self._connections, connection)
    else
        self:Log("Warning: Attempted to clean a nil connection.")
    end
    return connection
end

Meteor.Profile = shared.MeteorCustomProfile or Meteor.Profile or 'default'


---[[ Keybind Handling (Calls API Toggle) ]]--
local function checkKeybindPressed(input)
    -- Added check for Meteor table existence at the start
    if not Meteor or not Meteor.Keybind or #Meteor.Keybind == 0 then return false end
    local primaryKeyPressed = false
    local modifiersRequiredDown = {}
    local primaryKey = nil

    for _, key in ipairs(Meteor.Keybind) do
        local keyEnum = Enum.KeyCode[key] or Enum.UserInputType[key]
        if not keyEnum then goto continue end

        if not (key:find('Shift') or key:find('Control') or key:find('Alt')) then
            if input.UserInputType == keyEnum or input.KeyCode == keyEnum then
                primaryKeyPressed = true
                primaryKey = keyEnum
            end
        else
            modifiersRequiredDown[keyEnum] = true
        end
        ::continue::
    end

    if not primaryKeyPressed then return false end

    for keyEnumMod, _ in pairs(modifiersRequiredDown) do
        if not userInputService:IsKeyDown(keyEnumMod) then
            return false
        end
    end
    return true
end

-- Add defensive checks inside the InputBegan handler
Meteor:Clean(userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if checkKeybindPressed(input) then
        if Meteor and Meteor.ToggleGUI then
            pcall(Meteor.ToggleGUI, Meteor)
        else
            warn("InputBegan: Meteor.ToggleGUI is nil!")
        end
    end
end))


---[[ Initialization Logic (Orchestration) ]]--
function Meteor:Init()
    self:Log("Main: Initializing...")
    -- Check if ShowLoading exists before calling
    if self.ShowLoading then pcall(self.ShowLoading, self, "Meteor | Loading Config...") end

    -- Check if LoadConfig exists before calling
    if self.LoadConfig then pcall(self.LoadConfig, self) end
    task.wait(0.05)

    if self.ShowLoading then pcall(self.ShowLoading, self, "Meteor | Loading Modules...") end

    -- Load Universal Scripts
    local universalCode = downloadFile('Meteor_/games/universal.lua')
    if universalCode and universalCode ~= "" then
        local universalFunc = safeLoadstring(universalCode, 'universal.lua')
        if universalFunc then pcall(universalFunc) end -- universalFunc might use Meteor API
    end

    -- Load Game-Specific Scripts
    local gameId = game.PlaceId
    local gameScriptPath = 'Meteor_/games/'..gameId..'.lua'
    local gameScriptCode = downloadFile(gameScriptPath)
    if gameScriptCode and gameScriptCode ~= "" then
         local gameFunc = safeLoadstring(gameScriptCode, tostring(gameId)..'.lua')
         if gameFunc then
             if self.ShowLoading then pcall(self.ShowLoading, self, "Meteor | Loading Game Specifics ("..gameId..")...") end
             pcall(gameFunc) -- gameFunc might use Meteor API
         end
    end

    -- Finalize Loading
    self.Loaded = true
    self:Log("Main: Finished Loading.")
    if self.HideLoading then pcall(self.HideLoading, self) end

    -- Start Auto-Save Loop (with checks)
    task.spawn(function()
        while true do

            if not Meteor or not Meteor.Loaded then break end -- Exit loop if uninjected
            local waitDuration = 15

            if Meteor.SaveConfig then
                local suc, err = pcall(Meteor.SaveConfig, Meteor)
                if not suc then
                     Meteor:Log("Auto-save error:", err)
                     waitDuration = 60 -- Wait longer after an error
                end
            else
                 Meteor:Log("Auto-save skipped: Meteor.SaveConfig is nil")
                 waitDuration = 60
            end
            task.wait(waitDuration)
        end
        if Meteor then Meteor:Log("Main: Auto-save loop stopped.") end
    end)

    -- Teleport Handler (with checks)
    local teleportedServers = false
	Meteor:Clean(playersService.LocalPlayer.OnTeleport:Connect(function(state)

        if not Meteor then return end

        if state == Enum.TeleportState.Started and not teleportedServers and not shared.MeteorIndependent then
			teleportedServers = true
            Meteor:Log("Main: Teleport detected.")
			local teleportScript = [[
				shared.Meteorreload = true
                if shared.MeteorDeveloper then shared.MeteorDeveloper = true end
                if shared.MeteorCustomProfile then shared.MeteorCustomProfile = "]]..tostring(Meteor.Profile)..[[" end -- Access Profile safely
                local commit = 'main'; local s,c = pcall(readfile,'Meteor_/profiles/commit.txt'); if s and c and c~="" then commit=c end
				if shared.MeteorDeveloper then loadstring(readfile('Meteor_/loader.lua'),'loader')()
				else loadstring(game:HttpGet('https://raw.githubusercontent.com/LiesInTheDarkness/MeteorForRoblox/'..commit..'/loader.lua', true),'loader')() end
			]]
			
            if Meteor.SaveConfig then pcall(Meteor.SaveConfig, Meteor) end
			queue_on_teleport(teleportScript)
            if Meteor.Uninject then pcall(Meteor.Uninject, Meteor) end
		end
	end))

    -- Initial "Finished Loading" Notification (with checks)
	if not shared.Meteorreload then
		if self.ToggleNotifications and self.ToggleNotifications.Enabled and self.CreateNotification then
			pcall(self.CreateNotification, self,
                'Meteor Loaded',
                'Press '..table.concat(self.Keybind or {'?'}, ' + '):upper()..' to toggle.',
                7, 'info' )
		end
	end
    shared.Meteorreload = false

    -- Apply loaded visual states again (with checks)
    task.defer(function()

        if Meteor and Meteor.Modules then
            for _, moduleData in pairs(Meteor.Modules) do
                 if moduleData and moduleData._updateVisual then -- Check moduleData exists too
                     pcall(moduleData._updateVisual, moduleData, true)
                 end
            end
        end
    end)
end


---[[ Main Uninjection (Cleans connections, calls GUI Uninject) ]]--
function Meteor:Uninject()
    -- Set Loaded false first to help stop loops/events
    if self then self.Loaded = false end

    -- Check if self exists before logging/accessing connections
    if not self or not self._connections then
         print("Meteor Main: Already uninjected or invalid state.")
         shared.Meteor = nil -- Ensure shared is cleared
         return
    end

    self:Log("Main: Uninjecting...")

    -- Disconnect connections safely
    for i = #self._connections, 1, -1 do
        local conn = self._connections[i]
        if conn and conn.Connected then -- Check connection exists and is connected
             pcall(conn.Disconnect, conn)
        end
        table.remove(self._connections, i) -- Remove even if disconnect failed
    end
    self._connections = {}

    -- Call GUI uninject if it exists
    if self.UninjectGUI then
        pcall(self.UninjectGUI, self)
    end

    -- Clear shared reference *before* local Meteor potentially becomes nil in event handlers
    shared.Meteor = nil
    -- Note: We don't set the local 'Meteor' to nil here, as it might still be needed by callbacks finishing up.
    -- Lua's garbage collector will handle the local variable when it's no longer referenced.

    print("Meteor Main: Uninjected.")
end


---[[ Execution Start ]]--
if Meteor and Meteor.ShowLoading then
     pcall(Meteor.ShowLoading, Meteor, "Meteor | Initializing...")
else
     warn("Meteor Main: Cannot show loading screen, Meteor API not ready.")
end

if shared.MeteorIndependent then
	if Meteor then Meteor:Log("Main: Meteor loaded in Independent Mode. Call Meteor:Init() manually.") end
	return Meteor
else
	if Meteor and Meteor.Init then
         Meteor:Init() -- Initialize immediately
    else
         error("FATAL: Meteor API or Meteor:Init failed to load.")
    end
end

return Meteor
