--This watermark is used to delete the file if its cached, remove it to make the file persist after Meteor updates.
-- Meteor Universal Script - Runs in all games

return function(Meteor)
	print("Meteor: Loading Universal Script")

	-- Example: Add a 'Universal' category
	local universalCategory = Meteor:CreateCategory("Universal")

	-- Example: Add an Anti-AFK toggle
	local antiAfkEnabled = false
	local lastInteraction = tick()
	local afkToggle = Meteor:CreateToggle("Universal", "Anti AFK", false, function(enabled)
		antiAfkEnabled = enabled
		if enabled then
			print("Meteor Universal: Anti-AFK Enabled")
            lastInteraction = tick() -- Reset timer when enabled
		else
			print("Meteor Universal: Anti-AFK Disabled")
		end
	end)

	-- Simple Anti-AFK Logic (Runs every 30 seconds)
	local function checkAfk()
        if not Meteor.Loaded then return end -- Stop if uninject
		if antiAfkEnabled and (tick() - lastInteraction) > 120 then -- 2 minutes idle threshold
			-- Simulate input (may not work in all games/executors)
			pcall(function() game.Players.LocalPlayer:Move(Vector3.new(0,0,-0.1), true) end)
            task.wait(0.2)
            pcall(function() game.Players.LocalPlayer:Move(Vector3.new(0,0,0.1), true) end)
			print("Meteor Universal: Anti-AFK simulated input.")
			lastInteraction = tick() -- Reset timer after simulating input
		end
        task.delay(30, checkAfk) -- Schedule next check
	end
    task.delay(30, checkAfk) -- Start the check loop


	-- Reset AFK timer on player input
	local uis = game:GetService("UserInputService")
	local inputConn = uis.InputBegan:Connect(function()
		lastInteraction = tick()
	end)
    Meteor:Clean(inputConn) -- Ensure connection is cleaned up on uninject

    -- Example: Add a button to print player name
    Meteor:CreateButton("Universal", "Print My Name", function()
        local playerName = game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Unknown"
        print("Meteor Universal: Local Player Name is:", playerName)
        Meteor:CreateNotification("Player Name", "Your name is: " .. playerName, 3, "info")
    end)


    -- Example: Add a test slider
    Meteor:CreateSlider("Universal", "Test Slider", 0, 100, 50, 1, function(value)
        print("Meteor Universal: Test Slider value:", value)
    end)

    -- Example: Add a test textbox
     Meteor:CreateTextBox("Universal", "Test Text", "Enter something...", "", false, function(text)
        print("Meteor Universal: Test TextBox value:", text)
        Meteor:CreateNotification("TextBox Updated", "You entered: "..text, 4)
    end)


	print("Meteor: Universal Script Loaded")
end
