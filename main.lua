repeat task.wait() until game:IsLoaded()
if shared.Meteor then shared.Meteor:Uninject() end

local Meteor
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and Meteor then
		Meteor:CreateNotification('Meteor', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/Meteor/MeteorV4ForRoblox/'..readfile('Meteor_/profiles/commit.txt')..'/'..select(1, path:gsub('Meteor_/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after Meteor updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function finishLoading()
	Meteor.Init = nil
	Meteor:Load()
	task.spawn(function()
		repeat
			Meteor:Save()
			task.wait(10)
		until not Meteor.Loaded
	end)

	local teleportedServers
	Meteor:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.MeteorIndependent) then
			teleportedServers = true
			local teleportScript = [[
				shared.Meteorreload = true
				if shared.MeteorDeveloper then
					loadstring(readfile('Meteor_/loader.lua'), 'loader')()
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/Meteor/MeteorV4ForRoblox/'..readfile('Meteor_/profiles/commit.txt')..'/loader.lua', true), 'loader')()
				end
			]]
			if shared.MeteorDeveloper then
				teleportScript = 'shared.MeteorDeveloper = true\n'..teleportScript
			end
			if shared.MeteorCustomProfile then
				teleportScript = 'shared.MeteorCustomProfile = "'..shared.MeteorCustomProfile..'"\n'..teleportScript
			end
			Meteor:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.Meteorreload then
		if not Meteor.Categories then return end
		if Meteor.Categories.Main.Options['GUI bind indicator'].Enabled then
			Meteor:CreateNotification('Finished Loading', Meteor.MeteorButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(Meteor.Keybind, ' + '):upper()..' to open GUI', 5)
		end
	end
end

shared.Meteor = Meteor

if not shared.MeteorIndependent then
	loadstring(downloadFile('Meteor_/games/universal.lua'), 'universal')()
	if isfile('Meteor_/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('Meteor_/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
	else
		if not shared.MeteorDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/Meteor/MeteorV4ForRoblox/'..readfile('Meteor_/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				loadstring(downloadFile('Meteor_/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
			end
		end
	end
	finishLoading()
else
	Meteor.Init = finishLoading
	return Meteor
end
