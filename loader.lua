-- loader.lua
-- Bootstrapper for Meteor. Added checks for essential global functions.

--[[ Essential Global Function Check ]]--
local essentialGlobals = {
    "isfile", "readfile", "writefile", "makefolder", "listfiles", "delfile", -- File System
    "pcall", "select", "loadstring", "pairs", "ipairs", "type", "tostring", -- Lua Basics
    "game", "Instance", "Color3", "UDim2", "Vector2", "Enum", "task", -- Roblox Basics (task.wait might be used implicitly)
}
for _, name in ipairs(essentialGlobals) do
    if _G[name] == nil then
        -- Use warn or print if error isn't available or desired early
        local msg = "Meteor Loader FATAL: Essential global '" .. name .. "' is missing!"
        if error then error(msg) else print(msg) end
        return -- Stop execution if essential global is missing
    end
end
-- Check game:GetService specifically
if not game or type(game.GetService) ~= 'function' then
    local msg = "Meteor Loader FATAL: game:GetService is missing or not a function!"
    if error then error(msg) else print(msg) end
    return
end
-- Check HttpGet availability (basic check, main.lua does a more thorough one)
local httpGetCheck = game:GetService('HttpService') and game:GetService('HttpService').HttpGetAsync or game.HttpGet or HttpGet
if not httpGetCheck then
    print("Meteor Loader WARNING: No standard HttpGet function initially detected.")
    -- Rely on main.lua's more robust check
end
print("Meteor Loader: Essential globals check passed.")


--[[ File System Functions (Keep existing logic) ]]--
local isfile = isfile -- Already checked existence above
local delfile = delfile
local listfiles = listfiles
local isfolder = isfolder or function(f) local s,e=pcall(function() return readfile(f) end); return e and e:find("Cannot find specified file")==nil end -- Keep fallback just in case
local makefolder = makefolder
local readfile = readfile
local writefile = writefile

--[[ Download Function (Keep existing logic) ]]--
local function downloadFile(path, func)
	if not isfile(path) then
        -- Check HttpGet again before using it
        local HttpGetFunc = game.HttpGet or HttpGet or game:GetService('HttpService').HttpGetAsync
        if not HttpGetFunc then
            print("Meteor Loader downloadFile ERROR: No HttpGet function available!")
            return (func or function() return nil end)() -- Return nil/empty
        end

		local commit = 'main' -- Default commit
        local cs, cc = pcall(readfile,'Meteor_/profiles/commit.txt')
        if cs and cc and cc ~= "" then commit = cc end

		local url = 'https://raw.githubusercontent.com/LiesInTheDarkness/MeteorForRoblox/'.. commit ..'/'..select(1, path:gsub('Meteor_/', ''))
        print("Loader: Downloading:", url)

        local suc, res = pcall(HttpGetFunc, HttpGetFunc == game.HttpGet and url or game:GetService('HttpService'), url, true) -- Adjust call based on function type if needed (HttpService methods are often bound)

		if not suc then
            print("Loader downloadFile pcall ERROR:", tostring(res))
			return (func or function() return nil end)()
		end

        if type(res) ~= 'string' or res == "" or res == '404: Not Found' or res:find("404") or res:find("Not Found") then
            print("Loader downloadFile ERROR: Invalid response. Type:", type(res), "Content:", (type(res)=='string' and res:sub(1,50) or "N/A"))
            return (func or function() return nil end)()
        end

		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after Meteor updates.\n'..res
		end

        local writeSuc, writeErr = pcall(writefile, path, res)
		if not writeSuc then
            print("Loader downloadFile ERROR: Failed to write file:", path, "Error:", tostring(writeErr))
            -- Proceeding with potentially cached content if readfile works below, otherwise fails
        end
	end
    -- Read the file content after potential download/write
    local readSuccess, content = pcall(func or readfile, path)
    if readSuccess then
        return content
    else
        print("Loader downloadFile ERROR: Failed to read file:", path, "Error:", tostring(content))
        return nil -- Return nil explicitly on read failure
    end
end

--[[ Folder Management (Keep existing logic) ]]--
local function wipeFolder(path)
	if not isfolder(path) then return end
	local files = listfiles(path)
    if not files then print("Loader wipeFolder WARNING: listfiles failed for", path); return end -- Added check
	for _, file in ipairs(files) do -- Use ipairs for listfiles result
		if file:find('loader') then goto continue end -- Skip loader itself
        local isFileSuccess, isFileResult = pcall(isfile, file)
		if isFileSuccess and isFileResult then
            local readSuccess, content = pcall(readfile, file)
			if readSuccess and type(content) == 'string' and content:find('--This watermark is used to delete the file if its cached', 1, true) then -- Check for watermark
				pcall(delfile, file)
            -- else -- Uncomment to debug why files aren't deleted
            --     print("Loader wipeFolder: Skipping file (no watermark or read error):", file)
			end
		end
        ::continue::
	end
end

for _, folder in ipairs({'Meteor_', 'Meteor_/games', 'Meteor_/profiles', 'Meteor_/assets', 'Meteor_/libraries'}) do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

--[[ Commit Handling and Wiping (Keep existing logic, but add httpGet check) ]]--
if not shared.MeteorDeveloper then
	local _, subbed
    local HttpGetFunc = game.HttpGet or HttpGet -- Use simpler HttpGet here if available
    if HttpGetFunc then
         _, subbed = pcall(HttpGetFunc, HttpGetFunc, 'https://github.com/LiesInTheDarkness/MeteorForRoblox', true) -- Wrap github check
    else
         print("Loader Commit Check WARNING: No HttpGet function for GitHub check.")
         subbed = "" -- Assume no check possible
    end

    local commit = subbed and type(subbed)=='string' and subbed:match([[href="/LiesInTheDarkness/MeteorForRoblox/commit/(%x+)]]) or nil -- Use match for commit hash
	commit = commit or 'main' -- Fallback to main

    local currentCommit = ""
    local readSuc, currentCommitContent = pcall(readfile, 'Meteor_/profiles/commit.txt')
    if readSuc then currentCommit = currentCommitContent or "" end

	if commit ~= 'main' and currentCommit ~= commit then
        print("Loader: New commit detected ("..commit.."). Wiping watermarked files.")
		wipeFolder('Meteor_')
		wipeFolder('Meteor_/games')
		wipeFolder('Meteor_/libraries')
        -- Keep profiles and assets? Usually yes.
	end
    if commit ~= currentCommit then -- Write commit if changed or first run
	    pcall(writefile, 'Meteor_/profiles/commit.txt', commit)
    end
else
    print("Loader: Developer mode active, skipping commit check and wipe.")
end


--[[ Load and Execute main.lua (With more robust checks) ]]--
print("Loader: Attempting to load main.lua...")
local mainCode = downloadFile('Meteor_/main.lua')

if not mainCode or mainCode == "" then
    -- Critical failure, cannot proceed
    local msg = "Loader FATAL: Failed to download or read main.lua. Cannot continue execution."
    if error then error(msg) else print(msg) end
    return -- Stop
end

print("Loader: main.lua downloaded/read successfully. Attempting to loadstring...")

-- Loadstring the code
local mainFunc, loadErr = loadstring(mainCode, 'main.lua') -- Use loadstring directly

if not mainFunc then
    -- Critical failure, likely syntax error in main.lua
    local msg = "Loader FATAL: loadstring failed for main.lua. Error: " .. tostring(loadErr)
    if error then error(msg) else print(msg) end
    return -- Stop
end

print("Loader: loadstring successful. Executing main.lua...")

-- Execute the loaded function in a protected call
local execSuccess, execResult = pcall(mainFunc)

if not execSuccess then
    -- Error happened during main.lua's execution
    -- This is where the "attempt to call a nil value" likely originates if it's not a missing global in the loader itself
    local msg = "Loader FATAL: Error occurred during main.lua execution: " .. tostring(execResult)
    -- Attempt to show notification if possible, otherwise print/error
    if shared and shared.Meteor and shared.Meteor.CreateNotification then
        pcall(shared.Meteor.CreateNotification, shared.Meteor, "Meteor Load Error", msg:sub(1, 100), 15, "alert")
        print(msg) -- Also print it
    elseif error then
        error(msg)
    else
        print(msg)
    end
    return -- Stop
end

print("Loader: main.lua executed successfully.")

-- Return the result from main.lua (which should be the Meteor API table)
return execResult
