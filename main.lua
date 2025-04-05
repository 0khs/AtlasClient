-- main.lua
-- Orchestrates Meteor loading, runs scripts, handles core logic (non-UI)
-- Added more robust nil checks, especially in event handlers and loops.

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
    -- Added check for empty code string as well
    if not code or code == "" then warn("Loadstring Warning: Attempted to load empty code for", chunkName); return nil end
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
	httpGet = function(urlOrTable, useCache)
        if type(urlOrTable) == "table" then
            local s, r = pcall(syn.request, urlOrTable) -- Wrap Synapse request in pcall
            return s and r.Body or ""
        else
            local s, r = pcall(syn.request, {Url = urlOrTable, Method = "GET"})
            return s and r.Body or ""
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

        local suc, res = pcall(httpGet, url, true) -- Pass URL and cache hint directly

		if not suc then
            warn("Main: pcall error during download:", path, "Error:", tostring(res))
			return (func or function() return "" end)() -- Return empty string on failure
		end

        -- More robust checks for response type and content
        if type(res) ~= 'string' then
             warn("Main: Failed to download (Invalid Response Type):", path, "Type:", type(res))
             return (func or function() return "" end)()
        elseif res == "" then
             warn("Main: Failed to download (Empty Response):", path)
             return (func or function() return "" end)()
        elseif res == '404: Not Found' or res:find("404") or res:find("Not Found") then
            warn("Main: Failed to download (404 Not Found):", path)
            return (func or function() return "" end)()
        end

		if path:find('.lua') then res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after Meteor updates.\n'..res end
		local writeSuc, writeErr = pcall(writefile, filePath, res) -- Capture write error
        if writeSuc then
             print("Main: Downloaded successfully:", path)
        else
             warn("Main: Failed to write downloaded file:", path, "Error:", tostring(writeErr))
             -- Decide if we should proceed with potentially cached (but failed to write) content? Risky.
             -- For safety, maybe return empty string here too unless func is specified and handles it.
             return (func or function() return "" end)()
        end
	end
	-- Read the file after potential download/write
    local readSuccess, content = pcall(func or readfile, filePath)
    if readSuccess then
        return content
    else
        warn("Main: Failed to read file after download attempt:", filePath, "Error:", tostring(content))
        return "" -- Return empty string if read fails
    end
end


---[[ Load MeteorClient.lua ]]--
local meteorClientCode = downloadFile('Meteor_/MeteorClient.lua')
if not meteorClientCode or meteorClientCode == "" then error("FATAL: Failed to download or read MeteorClient.lua.") end

local clientLoaderFunc = safeLoadstring(meteorClientCode, 'MeteorClient.lua')
if not clientLoaderFunc then error("FATAL: Failed to load MeteorClient.lua code.") end

-- Wrap the client execution in pcall for safety
local clientSuccess, clientResult = pcall(clientLoaderFunc)
if not clientSuccess then error("FATAL: Error executing MeteorClient.lua: " .. tostring(clientResult)) end
if not clientResult or type(clientResult) ~= "table" then error("FATAL: MeteorClient.lua did not return API table.") end

Meteor = clientResult
shared.Meteor = Meteor -- Make API globally accessible


---[[ Add Core Non-UI Functions & Properties to Meteor API ]]--
Meteor.ExecutingScript = getexecutorname and getexecutorname() or 'Unknown'
Meteor.Debug = shared.MeteorDeveloper or false
Meteor._connections = {} -- Connections managed by main

function Meteor:Log(...)
    if self.Debug then print("Meteor Debug:", ...) end
end

function Meteor:Clean(connection)
    if connection and connection.Connected ~= nil then -- Check if it looks like a connection object
        table.insert(self._connections, connection)
    else
        self:Log("Warning: Attempted to clean an invalid or nil connection.")
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
local inputConnection = userInputService.InputBegan:Connect(function(input, gameProcessed)
    -- CRITICAL: Check if Meteor and ToggleGUI exist *inside the handler* before using them
    if not Meteor or not Meteor.ToggleGUI then
        -- Optionally disconnect if Meteor is gone? Or just warn.
        -- print("InputBegan: Meteor API not available, skipping.")
        return
    end

    if gameProcessed then return end

    -- Wrap checkKeybindPressed in pcall too, just in case
    local success, shouldToggle = pcall(checkKeybindPressed, input)
    if not success then
        Meteor:Log("Error in checkKeybindPressed:", shouldToggle)
        return
    end

    if shouldToggle then
        -- Call ToggleGUI within pcall
        local toggleSuccess, toggleErr = pcall(Meteor.ToggleGUI, Meteor)
        if not toggleSuccess then
            Meteor:Log("Error calling ToggleGUI:", toggleErr)
        end
    end
end)
-- Clean the connection immediately after creating it
if Meteor then pcall(Meteor.Clean, Meteor, inputConnection) else warn("Meteor not ready to clean InputBegan connection") end


---[[ Initialization Logic (Orchestration) ]]--
function Meteor:Init()
    -- Ensure 'self' (Meteor) is valid at the start of Init
    if not self then error("Meteor:Init called on a nil object!") end

    self:Log("Main: Initializing...")
    if self.ShowLoading then pcall(self.ShowLoading, self, "Meteor | Loading Config...") end

    if self.LoadConfig then pcall(self.LoadConfig, self) end
    task.wait(0.05)

    if self.ShowLoading then pcall(self.ShowLoading, self, "Meteor | Loading Modules...") end

    -- Load Universal Scripts
    local universalCode = downloadFile('Meteor_/games/universal.lua')
    if universalCode and universalCode ~= "" then
        local universalFunc = safeLoadstring(universalCode, 'universal.lua')
        if universalFunc then
            -- Pass Meteor API explicitly if needed, or rely on shared.Meteor
            local suc, err = pcall(universalFunc, self) -- Pass 'self' (Meteor API table)
             if not suc then self:Log("Error in universal.lua:", err) end
        end
    end

    -- Load Game-Specific Scripts
    local gameId = game.PlaceId
    local gameScriptPath = 'Meteor_/games/'..gameId..'.lua'
    local gameScriptCode = downloadFile(gameScriptPath)
    if gameScriptCode and gameScriptCode ~= "" then
         local gameFunc = safeLoadstring(gameScriptCode, tostring(gameId)..'.lua')
         if gameFunc then
             if self.ShowLoading then pcall(self.ShowLoading, self, "Meteor | Loading Game Specifics ("..gameId..")...") end
             -- Pass Meteor API explicitly if needed, or rely on shared.Meteor
             local suc, err = pcall(gameFunc, self) -- Pass 'self' (Meteor API table)
             if not suc then self:Log("Error in "..gameId..".lua:", err) end
         end
    end

    -- Finalize Loading
    self.Loaded = true -- Mark as loaded AFTER scripts are run
    self:Log("Main: Finished Loading.")
    if self.HideLoading then pcall(self.HideLoading, self) end

    -- Start Auto-Save Loop (with checks)
    task.spawn(function()
        while true do
            -- Check if Meteor is still loaded at the start of each loop iteration
            if not shared.Meteor or not shared.Meteor.Loaded then break end -- Use shared reference for loop condition

            local waitDuration = 15
            local currentMeteor = shared.Meteor -- Use the shared reference inside the loop

            if currentMeteor.SaveConfig then -- Check function exists on the current shared reference
                local suc, err = pcall(currentMeteor.SaveConfig, currentMeteor)
                if not suc then
                     if currentMeteor.Log then pcall(currentMeteor.Log, currentMeteor, "Auto-save error:", err) end
                     waitDuration = 60
                end
            else
                 if currentMeteor.Log then pcall(currentMeteor.Log, currentMeteor, "Auto-save skipped: SaveConfig is nil") end
                 waitDuration = 60
            end
            -- Check again before waiting, in case uninject happened during save attempt
            if not shared.Meteor or not shared.Meteor.Loaded then break end
            task.wait(waitDuration)
        end
        -- Use local Meteor reference for final log if it exists
        if Meteor and Meteor.Log then pcall(Meteor.Log, Meteor, "Main: Auto-save loop stopped.") end
    end)

    -- Teleport Handler (with checks)
    local teleportConnection = playersService.LocalPlayer.OnTeleport:Connect(function(state)
        -- Use shared reference inside the handler
        local currentMeteor = shared.Meteor
        if not currentMeteor then return end -- Exit if Meteor is gone

        if state == Enum.TeleportState.Started and not teleportedServers and not shared.MeteorIndependent then
			teleportedServers = true
            pcall(currentMeteor.Log, currentMeteor, "Main: Teleport detected.")
			local teleportScript = [[
				shared.Meteorreload = true
                if shared.MeteorDeveloper then shared.MeteorDeveloper = true end
                -- Safely access Profile using the checked currentMeteor reference
                if shared.MeteorCustomProfile then shared.MeteorCustomProfile = "]]..tostring(currentMeteor.Profile)..[[" end
                local commit = 'main'; local s,c = pcall(readfile,'Meteor_/profiles/commit.txt'); if s and c and c~="" then commit=c end
				if shared.MeteorDeveloper then loadstring(readfile('Meteor_/loader.lua'),'loader')()
				else loadstring(game:HttpGet('https://raw.githubusercontent.com/LiesInTheDarkness/MeteorForRoblox/'..commit..'/loader.lua', true),'loader')() end
			]]

            if currentMeteor.SaveConfig then pcall(currentMeteor.SaveConfig, currentMeteor) end
			queue_on_teleport(teleportScript)
            if currentMeteor.Uninject then pcall(currentMeteor.Uninject, currentMeteor) end
		end
	end)
    -- Clean the connection immediately
    if self.Clean then pcall(self.Clean, self, teleportConnection) end


    -- Initial "Finished Loading" Notification (with checks)
	if not shared.Meteorreload then
        -- Check 'self' properties exist before using them
		if self.ToggleNotifications and self.ToggleNotifications.Enabled and self.CreateNotification and self.Keybind then
			pcall(self.CreateNotification, self,
                'Meteor Loaded',
                'Press '..table.concat(self.Keybind, ' + '):upper()..' to toggle.',
                7, 'info' )
		end
	end
    shared.Meteorreload = false

    -- Apply loaded visual states again (with checks)
    task.defer(function()
        -- Use shared reference as this runs slightly later
        local currentMeteor = shared.Meteor
        if currentMeteor and currentMeteor.Modules then
            for _, moduleData in pairs(currentMeteor.Modules) do
                 -- Also check moduleData is a table and _updateVisual exists
                 if type(moduleData) == "table" and moduleData._updateVisual then
                     pcall(moduleData._updateVisual, moduleData, true) -- Update visual without tween
                 end
            end
        end
    end)
end


---[[ Main Uninjection (Cleans connections, calls GUI Uninject) ]]--
function Meteor:Uninject()
    -- Check if already uninjected based on shared variable
    if not shared.Meteor then
        print("Meteor Main: Already uninjected.")
        return
    end

    local currentMeteor = shared.Meteor -- Get current reference

    -- Set Loaded false early
    if currentMeteor then currentMeteor.Loaded = false end

    -- Clear the shared reference *before* disconnecting events
    -- This helps prevent event handlers running on a partially cleaned object
    shared.Meteor = nil

    -- Now use the local 'currentMeteor' reference for cleanup
    if not currentMeteor or not currentMeteor._connections then
         print("Meteor Main: Uninjecting - Invalid state or already cleaned.")
         return
    end

    pcall(currentMeteor.Log, currentMeteor, "Main: Uninjecting...")

    -- Disconnect connections safely using the local reference
    for i = #currentMeteor._connections, 1, -1 do
        local conn = currentMeteor._connections[i]
        if conn and conn.Connected then -- Check connection exists and is connected
             pcall(conn.Disconnect, conn)
        end
         -- Always try to remove, even if disconnect failed or conn was invalid
        pcall(table.remove, currentMeteor._connections, i)
    end
    currentMeteor._connections = {} -- Clear the table

    -- Call GUI uninject if it exists on the local reference
    if currentMeteor.UninjectGUI then
        pcall(currentMeteor.UninjectGUI, currentMeteor)
    end

    -- Avoid setting local 'Meteor' to nil here, allow GC
    print("Meteor Main: Uninjected.")
end


---[[ Execution Start ]]--
if Meteor and Meteor.ShowLoading then
     pcall(Meteor.ShowLoading, Meteor, "Meteor | Initializing...")
else
     warn("Meteor Main: Cannot show loading screen, Meteor API not ready.")
end

if shared.MeteorIndependent then
	if Meteor then pcall(Meteor.Log, Meteor, "Main: Meteor loaded in Independent Mode. Call Meteor:Init() manually.") end
	return Meteor
else
	if Meteor and Meteor.Init then
         -- Wrap Init in pcall as well
         local initSuccess, initErr = pcall(Meteor.Init, Meteor)
         if not initSuccess then
             error("FATAL: Error during Meteor:Init(): " .. tostring(initErr))
         end
    else
         error("FATAL: Meteor API or Meteor:Init failed to load.")
    end
end

return Meteor
