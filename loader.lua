-- //=================================\\
-- ||    Configuration Variables    ||
-- \\=================================//

local GITHUB_USER = "LiesInTheDarkness"
local GITHUB_REPO = "MeteorForRoblox"
local LOCAL_FOLDER = "MeteorClient" -- Name for the local storage folder
local MAIN_SCRIPT_NAME = "MainScript.lua" -- Your main script file
local DEFAULT_BRANCH = "main" -- The default branch to download from

-- //=================================\\
-- ||     Helper Functions (Local)    ||
-- \\=================================//

-- Ensure these functions work in your execution environment
local isfolder = isfolder or function(folder)
    local success, _ = pcall(function() listfiles(folder) end)
    return success
end

local makefolder = makefolder or function(folder)
    pcall(makefolder, folder)
end

local listfiles = listfiles or function(folder)
    return {} -- Return empty table if unavailable
end

local readfile = readfile or function(file)
    print("Warning: readfile function may not be available.")
    return ""
end

local writefile = writefile or function(file, content)
     print("Warning: writefile function may not be available.")
end

local isfile = isfile or function(file)
	local suc, res = pcall(readfile, file)
	return suc and res ~= nil and res ~= '' -- Check if readable and not empty
end

-- Use game:HttpGet if available, otherwise provide a basic placeholder/warning
local HttpGet = game and game:GetService("HttpService") and game.HttpGet or function(service, url)
    warn("HttpGet function not available or HttpService missing.")
    return nil, "HttpGet not available"
end

-- //=================================\\
-- ||      Core Loader Functions      ||
-- \\=================================//

local BASE_RAW_URL = string.format("https://raw.githubusercontent.com/%s/%s/%s/", GITHUB_USER, GITHUB_REPO, DEFAULT_BRANCH)

-- Function to download a file if it doesn't exist locally
local function downloadFile(relativePath, func)
    local localFilePath = string.format("%s/%s", LOCAL_FOLDER, relativePath)

    if not isfile(localFilePath) then
        print("Downloading:", relativePath)
        local downloadUrl = BASE_RAW_URL .. relativePath
        -- print("Attempting download from:", downloadUrl) -- For debugging

        local suc, res = pcall(HttpGet, game, downloadUrl, true) -- Pass 'true' to ignore caching if supported

        if not suc or (type(res) == "string" and res:match("404: Not Found")) then
            error(string.format("Failed to download '%s' from branch '%s'. Error: %s", relativePath, DEFAULT_BRANCH, tostring(res)))
        end

        -- Ensure the directory exists before writing
        local dir = localFilePath:match("(.+)/")
        if dir and not isfolder(dir) then
            -- Create directories recursively if needed (simple version)
            local parts = {}
            for part in dir:gmatch("[^/]+") do
                table.insert(parts, part)
                local currentPath = table.concat(parts, "/")
                if not isfolder(currentPath) then
                    makefolder(currentPath)
                    -- print("Created folder:", currentPath) -- For debugging
                end
            end
        end

        -- Write the downloaded content to the local file
        local write_suc, write_err = pcall(writefile, localFilePath, res)
        if not write_suc then
             warn(string.format("Failed to write file '%s'. Error: %s", localFilePath, write_err))
             -- Consider if this should be a fatal error
        end
    end
    -- Use provided function (like loadstring) or default to readfile
    return (func or readfile)(localFilePath)
end

-- //=================================\\
-- ||         Initialization          ||
-- \\=================================//

-- 1. Create necessary local folders based *only* on your repo structure
local foldersToCreate = {
    LOCAL_FOLDER,
    string.format("%s/Asset", LOCAL_FOLDER),
    string.format("%s/Modules", LOCAL_FOLDER),
    string.format("%s/Profiles", LOCAL_FOLDER)
    -- Add other folders ONLY if they exist in your repo root and need creation
}
print("Ensuring local folders exist...")
for _, folder in ipairs(foldersToCreate) do
	if not isfolder(folder) then
        print("Creating folder:", folder)
		makefolder(folder)
	end
end

-- 2. Download and execute the main script
--    (No update check based on commit hash)
print("Loading main script:", MAIN_SCRIPT_NAME)
local mainScriptPath = MAIN_SCRIPT_NAME -- Relative path within the repo

-- Use loadstring with the content returned by downloadFile
local mainScriptContent = downloadFile(mainScriptPath)
local func, err = loadstring(mainScriptContent)

if not func then
    error("Failed to load main script content into function: " .. tostring(err))
end

-- Execute the loaded script
print("Executing main script...")
local success, result = pcall(func)
if not success then
    error("Error executing main script: " .. tostring(result))
end

print("Meteor Client script finished loading.")

-- Optionally return the result from the main script
return result
