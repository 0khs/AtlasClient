-- main.lua
-- Orchestrates Meteor loading. Simplified checks focused on event handlers.

repeat task.wait() until game:IsLoaded()

-- Clean up previous instance if exists (Keep this pcall for safety)
if shared.Meteor and type(shared.Meteor.Uninject) == 'function' then
    pcall(shared.Meteor.Uninject)
    task.wait(0.1)
end
shared.Meteor = nil

local Meteor -- Will hold the API table from MeteorClient

-- Services
local cloneref = cloneref or function(obj) return obj end
local playersService = cloneref(game:GetService('Players'))
local userInputService = cloneref(game:GetService('UserInputService'))
local httpService = cloneref(game:GetService('HttpService'))

-- Simple loadstring (Assume loadstring exists from loader check)
local function safeLoadstring(code, chunkName)
    local func, err = loadstring(code, chunkName)
    if err then warn("Loadstring error in", chunkName, ":", err); return nil end
    return func
end

-- File system checks (Assume funcs exist from loader check)
local isfolder = isfolder or function(f) local s,e=pcall(readfile,f); return e and e:find("Cannot find specified file")==nil end
local isfile = isfile or function(file) local s,r=pcall(readfile,file); return s and r~=nil and r~='' end
local readfile = readfile or function() return '' end
local writefile = writefile or function() return false end
local makefolder = makefolder or function() end
local queue_on_teleport = queue_on_teleport or function() end

-- HTTP Get (Assume func exists from loader check, use simplified logic)
local httpGet = game.HttpGet or HttpGet or game:GetService('HttpService').HttpGetAsync or function() return "" end

-- Download Function (Simplified error handling)
local function downloadFile(path, func)
	local filePath = path
	if not isfile(filePath) then
        local commit = 'main'; local cs, cc = pcall(readfile,'Meteor_/profiles/commit.txt'); if cs and cc and cc ~= "" then commit = cc end
		local url = 'https://raw.githubusercontent.com/LiesInTheDarkness/MeteorForRoblox/'.. commit ..'/'..select(1, path:gsub('Meteor_/', ''))
        local suc, res = pcall(httpGet, url, true)
		if not suc or type(res)~='string' or res=="" or res=='404: Not Found' or res:find("404") then return "" end -- Return empty on fail
		if path:find('.lua') then res = '--Watermark\n'..res end
		pcall(writefile, filePath, res)
	end
    local readSuccess, content = pcall(func or readfile, filePath)
    return readSuccess and content or "" -- Return empty on fail
end


---[[ Load MeteorClient.lua ]]--
local meteorClientCode = downloadFile('Meteor_/MeteorClient.lua')
if not meteorClientCode or meteorClientCode == "" then error("FATAL: Failed to download or read MeteorClient.lua.") end
local clientLoaderFunc = safeLoadstring(meteorClientCode, 'MeteorClient.lua')
if not clientLoaderFunc then error("FATAL: Failed to load MeteorClient.lua code.") end
local clientSuccess, clientResult = pcall(clientLoaderFunc); if not clientSuccess then error("FATAL: Error executing MeteorClient.lua: "..tostring(clientResult)) end; if not clientResult or type(clientResult)~="table" then error("FATAL: MeteorClient.lua did not return API table.") end
Meteor = clientResult; shared.Meteor = Meteor


---[[ Add Core Non-UI Functions & Properties ]]--
Meteor.ExecutingScript = getexecutorname and getexecutorname() or 'Unknown'
Meteor.Debug = shared.MeteorDeveloper or false
Meteor._connections = {} -- Initialized here

function Meteor:Log(...) if self.Debug then print("Meteor Debug:", ...) end end

-- Assume Clean is defined correctly in MeteorClient if it exists there,
-- otherwise define a basic one here if needed for internal main.lua use.
-- If Clean is *only* used for event connections managed *by main.lua*, define it here.
if not Meteor.Clean then
    print("Main: Defining basic Meteor:Clean for main.lua connections.")
    function Meteor:Clean(connection)
        if not self._connections then self._connections = {} end -- Ensure table exists
        if connection and connection.Connected ~= nil then
            table.insert(self._connections, connection)
        end
        return connection
    end
end

Meteor.Profile = shared.MeteorCustomProfile or Meteor.Profile or 'default'


---[[ Keybind Handling ]]--
local function checkKeybindPressed(input)
    -- Important: Check Meteor *inside* this function too, as it's called by the event
    if not Meteor or not Meteor.Keybind or #Meteor.Keybind == 0 then return false end
    local pK=false; local mRD={}; for _,k in ipairs(Meteor.Keybind) do local kE=Enum.KeyCode[k] or Enum.UserInputType[k]; if kE then if not(k:find('Shift')or k:find('Control')or k:find('Alt')) then if input.UserInputType==kE or input.KeyCode==kE then pK=true end else mRD[kE]=true end end end; if not pK then return false end; for kEM,_ in pairs(mRD) do if not userInputService:IsKeyDown(kEM) then return false end end; return true
end

-- DIRECT check for Meteor inside the event handler
local inputConnection = userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    -- Check if Meteor and necessary function exist RIGHT NOW
    if Meteor and Meteor.ToggleGUI and checkKeybindPressed(input) then
        Meteor:ToggleGUI() -- Direct call, assume ToggleGUI won't error internally
    end
end)
-- Clean the connection using the potentially self-defined Clean
if Meteor and Meteor.Clean then Meteor:Clean(inputConnection) end


---[[ Initialization Logic ]]--
function Meteor:Init()
    if not self then error("Meteor:Init called on nil!") end -- Check self
    self:Log("Main: Initializing...")
    if self.ShowLoading then self:ShowLoading("Meteor | Loading Config...") end -- Direct calls
    if self.LoadConfig then self:LoadConfig() end; task.wait(0.05)
    if self.ShowLoading then self:ShowLoading("Meteor | Loading Modules...") end

    -- Load Scripts (Simplified error handling)
    local uniCode=downloadFile('Meteor_/games/universal.lua'); if uniCode and uniCode~="" then local uniF=safeLoadstring(uniCode,'universal.lua'); if uniF then pcall(uniF, self) end end
    local gId=game.PlaceId; local gPath='Meteor_/games/'..gId..'.lua'; local gCode=downloadFile(gPath); if gCode and gCode~="" then local gF=safeLoadstring(gCode,tostring(gId)..'.lua'); if gF then if self.ShowLoading then self:ShowLoading("Loading "..gId) end; pcall(gF, self) end end

    self.Loaded=true
    self:Log("Main: Finished Loading.")
    if self.HideLoading then self:HideLoading() end

    -- Auto-Save Loop (Simplified)
    task.spawn(function()
        while task.wait(15) do
            -- Use shared reference check for loop condition
            if not shared.Meteor or not shared.Meteor.Loaded then break end
            -- Check function exists before calling inside loop
            if shared.Meteor.SaveConfig then
                pcall(shared.Meteor.SaveConfig, shared.Meteor) -- Use pcall for safety
            end
        end
        if Meteor then Meteor:Log("Main: Auto-save loop stopped.") end -- Use local Meteor for final log
    end)

    -- Teleport Handler (Simplified)
    local teleportedServers=false
    local teleportConn = playersService.LocalPlayer.OnTeleport:Connect(function(state)
        -- Check shared reference inside handler
        if not shared.Meteor then return end

        if state==Enum.TeleportState.Started and not teleportedServers and not shared.MeteorIndependent then
            teleportedServers=true
            shared.Meteor:Log("Main: Teleport detected.")
            local tS = [[...]]; -- Keep teleport script logic
             if shared.Meteor.SaveConfig then pcall(shared.Meteor.SaveConfig, shared.Meteor) end
			queue_on_teleport(tS)
             if shared.Meteor.Uninject then pcall(shared.Meteor.Uninject, shared.Meteor) end -- Use pcall
		end
	end)
    if Meteor and Meteor.Clean then Meteor:Clean(teleportConn) end -- Clean the connection

    -- Initial Notification (Simplified)
	if not shared.Meteorreload then if self.ToggleNotifications and self.ToggleNotifications.Enabled and self.CreateNotification and self.Keybind then self:CreateNotification('Meteor Loaded','Press '..table.concat(self.Keybind,' + '):upper(),7,'info') end end; shared.Meteorreload=false

    -- Deferred Update (Simplified)
    task.defer(function() if shared.Meteor and shared.Meteor.Modules then for _,mD in pairs(shared.Meteor.Modules) do if type(mD)=="table" and mD._updateVisual then pcall(mD._updateVisual, mD, true) end end end end)
end

---[[ Main Uninjection ]]--
function Meteor:Uninject()
    if not shared.Meteor then return end -- Check if already gone
    local currentMeteor = shared.Meteor -- Grab reference
    shared.Meteor = nil -- Clear shared ref first
    if not currentMeteor then return end -- Check if reference was valid

    currentMeteor.Loaded = false -- Set flag on the local reference
    currentMeteor:Log("Main: Uninjecting...")

    -- Disconnect connections stored in the local reference
    if currentMeteor._connections then
        for i=#currentMeteor._connections,1,-1 do local c=currentMeteor._connections[i]; if c and c.Connected then pcall(c.Disconnect,c) end; pcall(table.remove,currentMeteor._connections,i) end
        currentMeteor._connections = {}
    end

    -- Call GUI uninject if it exists on the local reference
    if currentMeteor.UninjectGUI then pcall(currentMeteor.UninjectGUI, currentMeteor) end
    print("Meteor Main: Uninjected.")
end

---[[ Execution Start ]]--
if Meteor and Meteor.ShowLoading then Meteor:ShowLoading("Initializing...") else warn("Cannot show loading screen.") end -- Direct call
if shared.MeteorIndependent then if Meteor then Meteor:Log("Independent Mode") end; return Meteor else if Meteor and Meteor.Init then local s,e=pcall(Meteor.Init,Meteor); if not s then error("FATAL: Init Error: "..tostring(e)) end else error("FATAL: Meteor or Init failed.") end end
return Meteor
