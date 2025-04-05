--This watermark is used to delete the file if its cached, remove it to make the file persist after Meteor updates.
-- Meteor GUI Client - Core Functionality

return function(Meteor) -- Accept the Meteor table from main.lua

	-- Roblox Services
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local GuiService = game:GetService("GuiService")
	local CoreGui = game:GetService("CoreGui")
	local TweenService = game:GetService("TweenService")

	-- Local Player
	local LocalPlayer = Players.LocalPlayer

	-- Configuration
	local ConfigFileName = 'Meteor/profiles/config.lua' -- Using .lua for simple saving/loading
	local Settings = {} -- Holds loaded settings
	local ConnectionsToClean = {} -- Store connections for cleanup
	local Debounces = {} -- Simple debounce table

	-- UI Elements (will be created in Load)
	local ScreenGui = nil
	local MainWindow = nil
	local TopBar = nil
	local CategoryFrame = nil
	local ElementFrame = nil
	local CurrentCategoryButton = nil
	local NotificationFrame = nil
	local MeteorToggleButton = nil -- Optional top-right button

	-- Constants
	local UI_PRIMARY_COLOR = Color3.fromRGB(30, 30, 30)
	local UI_SECONDARY_COLOR = Color3.fromRGB(45, 45, 45)
	local UI_ACCENT_COLOR = Color3.fromRGB(0, 122, 204)
	local UI_TEXT_COLOR = Color3.fromRGB(220, 220, 200)
	local UI_FONT = Enum.Font.GothamSemibold
	local ZINDEX_BASE = 500 -- Base ZIndex to stay above most game UI

	-- State
	Meteor.Loaded = false
	Meteor.Visible = false
	Meteor.Keybind = { Enum.KeyCode.RightShift } -- Default Keybind
	Meteor.Categories = {} -- { ["CategoryName"] = { Button = GuiButton, Elements = { ["ElementName"] = { Type="Button", Instance=GuiObject, ... } } } }

	-- Forward Declarations
	local LoadSettings, SaveSettings

	-- Helper Functions
	local function Debounce(key, delay)
		delay = delay or 0.1
		local now = tick()
		if Debounces[key] and now - Debounces[key] < delay then
			return true -- Debounced
		end
		Debounces[key] = now
		return false -- Not debounced
	end

	local function CreateElement(elementType, properties)
		local element = Instance.new(elementType)
		for prop, value in pairs(properties) do
			element[prop] = value
		end
		return element
	end

	local function GetTopbarInset()
		return GuiService:GetGuiInset().Y
	end

	-- === UI Creation Functions ===

	local function CreateNotificationUI()
		NotificationFrame = CreateElement("Frame", {
			Name = "NotificationFrame",
			Size = UDim2.new(0, 300, 0, 50),
			Position = UDim2.new(0.5, -150, 0, 10 + GetTopbarInset()), -- Centered below top bar inset
			BackgroundColor3 = UI_SECONDARY_COLOR,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = ZINDEX_BASE + 100, -- Above main UI
			Parent = ScreenGui
		})
		local uiCorner = CreateElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = NotificationFrame })
		local Title = CreateElement("TextLabel", {
			Name = "Title",
			Size = UDim2.new(1, -10, 0, 20),
			Position = UDim2.new(0, 5, 0, 5),
			BackgroundTransparency = 1,
			Font = UI_FONT,
			TextColor3 = UI_ACCENT_COLOR,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "Notification Title",
			ZIndex = NotificationFrame.ZIndex + 1,
			Parent = NotificationFrame
		})
		local Message = CreateElement("TextLabel", {
			Name = "Message",
			Size = UDim2.new(1, -10, 0, 20),
			Position = UDim2.new(0, 5, 0, 25),
			BackgroundTransparency = 1,
			Font = UI_FONT,
			TextColor3 = UI_TEXT_COLOR,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "Notification message content.",
			ZIndex = NotificationFrame.ZIndex + 1,
			Parent = NotificationFrame
		})
	end

	local function CreateMainUI()
		ScreenGui = CreateElement("ScreenGui", {
			Name = "MeteorClient",
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			ResetOnSpawn = false,
			DisplayOrder = ZINDEX_BASE,
			Parent = CoreGui -- Use CoreGui for better persistence/priority
		})
		Meteor:Clean(ScreenGui) -- Register for cleanup

		MainWindow = CreateElement("Frame", {
			Name = "MainWindow",
			Size = UDim2.new(0, 500, 0, 350), -- Fixed size initially
			Position = UDim2.new(0.5, -250, 0.5, -175), -- Centered
			BackgroundColor3 = UI_PRIMARY_COLOR,
			BorderSizePixel = 0,
			Visible = false,
			Active = true, -- Allow dragging
			Draggable = true,
			ZIndex = ScreenGui.DisplayOrder + 1,
			Parent = ScreenGui
		})
		local uiCorner = CreateElement("UICorner", { CornerRadius = UDim.new(0, 6), Parent = MainWindow })

		TopBar = CreateElement("Frame", {
			Name = "TopBar",
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = UI_ACCENT_COLOR,
			BorderSizePixel = 0,
			ZIndex = MainWindow.ZIndex + 1,
			Parent = MainWindow
		})
		local topBarCorner = CreateElement("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TopBar }) -- Apply only to top corners potentially?

		local TitleLabel = CreateElement("TextLabel", {
			Name = "TitleLabel",
			Size = UDim2.new(1, -40, 1, 0),
			Position = UDim2.new(0, 5, 0, 0),
			BackgroundTransparency = 1,
			Font = UI_FONT,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 18,
			Text = "Meteor",
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = TopBar.ZIndex + 1,
			Parent = TopBar
		})

        -- Close Button (Example)
		local CloseButton = CreateElement("TextButton", {
			Name = "CloseButton",
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(1, -25, 0.5, -10),
			BackgroundColor3 = Color3.fromRGB(200, 50, 50),
			Text = "X",
			Font = UI_FONT,
			TextColor3 = Color3.new(1,1,1),
			TextSize = 16,
			ZIndex = TopBar.ZIndex + 1,
			Parent = TopBar
		})
        CreateElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = CloseButton })
		local closeConn = CloseButton.Activated:Connect(function()
			Meteor.SetVisible(false)
		end)
		Meteor:Clean(closeConn)

		CategoryFrame = CreateElement("Frame", {
			Name = "CategoryFrame",
			Size = UDim2.new(0, 120, 1, -30), -- Width 120px, full height minus top bar
			Position = UDim2.new(0, 0, 0, 30),
			BackgroundColor3 = UI_SECONDARY_COLOR,
			BorderSizePixel = 0,
			ZIndex = MainWindow.ZIndex + 1,
			Parent = MainWindow
		})
		local catListLayout = CreateElement("UIListLayout", {
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = CategoryFrame
		})
		local catPadding = CreateElement("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5),
            Parent = CategoryFrame
        })


		ElementFrame = CreateElement("ScrollingFrame", {
			Name = "ElementFrame",
			Size = UDim2.new(1, -120, 1, -30), -- Remaining width, full height minus top bar
			Position = UDim2.new(0, 120, 0, 30),
			BackgroundColor3 = UI_PRIMARY_COLOR, -- Match main window background
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0), -- Auto-sized by UIListLayout
            ScrollBarThickness = 6,
            ScrollBarImageColor3 = UI_ACCENT_COLOR,
			ZIndex = MainWindow.ZIndex + 1,
			Parent = MainWindow
		})
		local eleListLayout = CreateElement("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = ElementFrame
		})
        local elePadding = CreateElement("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            Parent = ElementFrame
        })


		-- Create Notification UI container
		CreateNotificationUI()
	end

	local function CreateMeteorToggleButton()
		if MeteorToggleButton then return end -- Don't recreate

		MeteorToggleButton = CreateElement("TextButton", {
			Name = "MeteorToggleButton",
			Size = UDim2.new(0, 80, 0, 25), -- Small button
			Position = UDim2.new(1, -90, 0, 10 + GetTopbarInset()), -- Top right below inset
			BackgroundColor3 = UI_ACCENT_COLOR,
			BorderSizePixel = 0,
			Text = "Meteor",
			Font = UI_FONT,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 14,
			Visible = true,
			ZIndex = ScreenGui.DisplayOrder, -- Same level as main window base
			Parent = ScreenGui
		})
		local tbCorner = CreateElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = MeteorToggleButton })

		local toggleConn = MeteorToggleButton.Activated:Connect(function()
			Meteor.SetVisible(not Meteor.Visible)
		end)
		Meteor:Clean(toggleConn)

		Meteor.MeteorButton = MeteorToggleButton -- Store reference as requested by main.lua
	end

	-- === API Functions ===

	Meteor.Load = function(self)
		if self.Loaded then return end
		print("Meteor: Loading UI...")

		LoadSettings() -- Load settings before creating UI elements

		CreateMainUI()
		CreateMeteorToggleButton() -- Create the optional top-right button

        -- Setup Keybind Listener
		local function InputBegan(input, gameProcessed)
			if gameProcessed then return end -- Don't process if typing in chat etc.

			if input.UserInputType == Enum.UserInputType.Keyboard then
                local match = true
                if #self.Keybind > 0 then
    				for _, key in ipairs(self.Keybind) do
	    				if not UserInputService:IsKeyDown(key) then
		    				match = false
			    			break
				    	end
				    end
                    -- Check if ONLY the keys in the keybind are pressed (optional, stricter check)
                    --[[
                    local pressedKeys = UserInputService:GetKeysPressed()
                    if #pressedKeys ~= #self.Keybind then
                         match = false
                    end
                    ]]
                else
                    match = false -- No keybind set
                end

				if match and input.KeyCode == self.Keybind[#self.Keybind] then -- Check if the LAST key in the combo was just pressed
                    if not Debounce('ToggleUIKeybind', 0.2) then
					    self.SetVisible(not self.Visible)
                    end
				end
			end
		end
        local inputConn = UserInputService.InputBegan:Connect(InputBegan)
		self:Clean(inputConn)

		-- Populate default category if none exist (after loading settings)
		if not next(self.Categories) then
			self:CreateCategory("Main")
		end

		-- Select the first category by default
        local firstCatName = next(self.Categories)
        if firstCatName then
            self.SelectCategory(self.Categories[firstCatName].Button)
        end

		self.Loaded = true
		print("Meteor: UI Loaded.")
		return true -- Indicate success
	end

	Meteor.Save = function(self)
		if not self.Loaded then return end
		--print("Meteor: Saving configuration...")
        SaveSettings()
	end

	Meteor.Uninject = function(self)
		if not self.Loaded then return end
		print("Meteor: Uninjecting...")

		self:Save() -- Save before closing

		-- Disconnect all registered connections
		for i, conn in ipairs(ConnectionsToClean) do
			pcall(function() conn:Disconnect() end)
		end
		ConnectionsToClean = {} -- Clear the table

		-- Destroy UI
		if ScreenGui then
			pcall(function() ScreenGui:Destroy() end)
			ScreenGui = nil
			MainWindow = nil
            TopBar = nil
            CategoryFrame = nil
            ElementFrame = nil
            NotificationFrame = nil
			MeteorToggleButton = nil
		end

		-- Clear internal state
		self.Categories = {}
		Settings = {}
		Debounces = {}
        CurrentCategoryButton = nil
        Meteor.MeteorButton = nil -- Clear reference

		self.Visible = false
		self.Loaded = false
		shared.Meteor = nil -- Clear shared reference
		print("Meteor: Uninjected.")
	end

	Meteor.Clean = function(self, objectToClean)
		if objectToClean then
			table.insert(ConnectionsToClean, objectToClean)
		end
	end

    Meteor.SetVisible = function(self, visible)
        if not MainWindow then return end
        self.Visible = visible
        MainWindow.Visible = visible
		-- Optionally hide the toggle button when the main window is open
		if MeteorToggleButton then
			MeteorToggleButton.Visible = not visible
		end
    end

	Meteor.SelectCategory = function(self, categoryButton)
        if CurrentCategoryButton == categoryButton then return end -- Already selected

        -- Deselect previous
        if CurrentCategoryButton then
            CurrentCategoryButton.BackgroundColor3 = UI_SECONDARY_COLOR
            CurrentCategoryButton.TextColor3 = UI_TEXT_COLOR
        end

        -- Select new
        categoryButton.BackgroundColor3 = UI_ACCENT_COLOR
        categoryButton.TextColor3 = Color3.new(1, 1, 1)
        CurrentCategoryButton = categoryButton

        -- Clear current elements
        for _, child in ipairs(ElementFrame:GetChildren()) do
            if child:IsA("GuiObject") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
				pcall(function() child:Destroy() end) -- Wrap destroy in pcall
            end
        end

        -- Populate with new elements
        local categoryData = self.Categories[categoryButton.Name]
        if categoryData and categoryData.Elements then
            local layoutOrder = 0
            -- Ensure elements are added in a consistent order if needed, or rely on LayoutOrder
            local sortedKeys = {}
            for name, _ in pairs(categoryData.Elements) do table.insert(sortedKeys, name) end
            table.sort(sortedKeys)

            for _, elementName in ipairs(sortedKeys) do
				local elementData = categoryData.Elements[elementName]
                if elementData and elementData.Instance then
                    elementData.Instance.LayoutOrder = layoutOrder
                    elementData.Instance.Parent = ElementFrame
                    layoutOrder = layoutOrder + 1
                end
            end
        end

        -- Update ScrollingFrame CanvasSize (important after adding/removing elements)
		task.wait() -- Wait a frame for UIListLayout to potentially update positions/sizes
        ElementFrame.CanvasSize = UDim2.new(0, 0, 0, eleListLayout.AbsoluteContentSize.Y + 20) -- Add some padding
	end

	Meteor.CreateCategory = function(self, name)
		if not CategoryFrame then
            warn("Meteor: Cannot create category, UI not loaded.")
            return
        end
        if self.Categories[name] then return self.Categories[name] end -- Already exists

		local categoryButton = CreateElement("TextButton", {
			Name = name,
			Size = UDim2.new(1, -10, 0, 30), -- Almost full width, fixed height
			Position = UDim2.new(0, 5, 0, 0), -- Handled by ListLayout
			BackgroundColor3 = UI_SECONDARY_COLOR,
			BorderSizePixel = 0,
			Text = name,
			Font = UI_FONT,
			TextColor3 = UI_TEXT_COLOR,
			TextSize = 16,
			LayoutOrder = #CategoryFrame:GetChildren(), -- Maintain order
			ZIndex = CategoryFrame.ZIndex + 1,
			Parent = CategoryFrame -- Add to category frame
		})
        CreateElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = categoryButton })

		local catData = { Button = categoryButton, Elements = {} }
		self.Categories[name] = catData

		local catConn = categoryButton.Activated:Connect(function()
			self:SelectCategory(categoryButton)
		end)
		self:Clean(catConn)

        -- If this is the first category, select it
        if not CurrentCategoryButton then
            self:SelectCategory(categoryButton)
        end

		return catData
	end

	Meteor.CreateNotification = function(self, title, message, duration, iconType)
		if not NotificationFrame then return end -- UI not ready

        local titleLabel = NotificationFrame:FindFirstChild("Title")
        local messageLabel = NotificationFrame:FindFirstChild("Message")

        if not titleLabel or not messageLabel then return end -- Should exist, but check anyway

		-- Cancel existing tween if any
		local existingTween = NotificationFrame:FindFirstChild("NotificationTween")
		if existingTween then existingTween:Cancel() existingTween:Destroy() end

        -- Customize based on iconType (optional)
        if iconType == "alert" then
            titleLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        elseif iconType == "warning" then
             titleLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
        elseif iconType == "info" then
            titleLabel.TextColor3 = UI_ACCENT_COLOR
        else
             titleLabel.TextColor3 = UI_ACCENT_COLOR -- Default
        end

		titleLabel.Text = title or "Notification"
		messageLabel.Text = message or ""
        NotificationFrame.Visible = true

		-- Simple fade in/out animation
		local tweenInfoShow = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tweenInfoHide = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

        NotificationFrame.BackgroundTransparency = 1
        titleLabel.TextTransparency = 1
        messageLabel.TextTransparency = 1

		local showTween = TweenService:Create(NotificationFrame, tweenInfoShow, { BackgroundTransparency = 0 })
        local showTextTween1 = TweenService:Create(titleLabel, tweenInfoShow, { TextTransparency = 0 })
        local showTextTween2 = TweenService:Create(messageLabel, tweenInfoShow, { TextTransparency = 0 })

        showTween:Play()
        showTextTween1:Play()
        showTextTween2:Play()

		local hideTween = TweenService:Create(NotificationFrame, tweenInfoHide, { BackgroundTransparency = 1 })
        local hideTextTween1 = TweenService:Create(titleLabel, tweenInfoHide, { TextTransparency = 1 })
        local hideTextTween2 = TweenService:Create(messageLabel, tweenInfoHide, { TextTransparency = 1 })

		local timer = task.delay(duration or 5, function()
            hideTween:Play()
            hideTextTween1:Play()
            hideTextTween2:Play()
            hideTween.Completed:Wait() -- Wait for hide animation
            NotificationFrame.Visible = false
		end)

        -- Store tween to allow cancelling if needed (e.g., during uninject)
        hideTween.Name = "NotificationTween"
        hideTween.Parent = NotificationFrame
        -- Ensure timer is cancelled on uninject
        self:Clean({ Disconnect = function() task.cancel(timer) end })
        self:Clean(showTween)
        self:Clean(showTextTween1)
        self:Clean(showTextTween2)
        self:Clean(hideTween)
        self:Clean(hideTextTween1)
        self:Clean(hideTextTween2)

	end

	-- === Element Creation API (Called by universal/game scripts) ===

    -- Helper to add element to category and settings
    local function RegisterElement(categoryName, elementName, elementData)
        local category = Meteor.Categories[categoryName]
        if not category then
            warn("Meteor: Category '"..tostring(categoryName).."' not found for element '"..tostring(elementName).."'")
            return
        end
        category.Elements[elementName] = elementData

        -- Initialize setting if not present
        if Settings[categoryName] == nil then Settings[categoryName] = {} end
        if Settings[categoryName][elementName] == nil then
             -- Set default value based on type
             if elementData.Type == "Toggle" then Settings[categoryName][elementName] = elementData.Default or false
             elseif elementData.Type == "Slider" then Settings[categoryName][elementName] = elementData.Default or elementData.Min or 0
             elseif elementData.Type == "TextBox" then Settings[categoryName][elementName] = elementData.Default or ""
             elseif elementData.Type == "Keybind" then Settings[categoryName][elementName] = elementData.Default or "None"
             -- Buttons don't usually have persistent settings unless tracking clicks etc.
             end
        end

        -- Apply loaded setting value if it exists
        local savedValue = Settings[categoryName] and Settings[categoryName][elementName]
        if savedValue ~= nil then
            pcall(elementData.SetValue, savedValue) -- Use SetValue to apply initially
        end
    end

	Meteor.CreateButton = function(self, categoryName, name, callback)
        local elementContainer = CreateElement("Frame", {
            Name = name,
            Size = UDim2.new(1, 0, 0, 30), -- Full width, fixed height
            BackgroundTransparency = 1,
            BorderSizePixel = 0
            -- Parent will be set when category is selected
        })

		local button = CreateElement("TextButton", {
			Name = "Button",
			Size = UDim2.new(1, 0, 1, 0), -- Fill container
			BackgroundColor3 = UI_SECONDARY_COLOR,
			BorderSizePixel = 0,
			Text = name,
			Font = UI_FONT,
			TextColor3 = UI_TEXT_COLOR,
			TextSize = 14,
			ZIndex = ElementFrame.ZIndex + 1,
			Parent = elementContainer
		})
        CreateElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = button })

		local btnConn = button.Activated:Connect(function()
            if not Debounce("Button_"..name, 0.1) and callback then
                local success, err = pcall(callback)
                if not success then
                    warn("Meteor Button Error ("..name.."):", err)
                    self:CreateNotification("Button Error", "Error in '"..name.."': "..tostring(err), 5, "alert")
                end
            end
		end)
		self:Clean(btnConn)

        local elementData = { Type = "Button", Instance = elementContainer, Button = button }
        RegisterElement(categoryName, name, elementData)
		return elementData
	end

    Meteor.CreateToggle = function(self, categoryName, name, defaultValue, callback)
        local enabled = defaultValue or false

        local elementContainer = CreateElement("Frame", {
            Name = name,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        })

        local label = CreateElement("TextLabel", {
            Name = "Label",
            Size = UDim2.new(0.7, -5, 1, 0), -- 70% width minus padding
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Font = UI_FONT,
            TextColor3 = UI_TEXT_COLOR,
            TextSize = 14,
            Text = name,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = ElementFrame.ZIndex + 1,
            Parent = elementContainer
        })

        local toggleButton = CreateElement("TextButton", {
            Name = "ToggleButton",
            Size = UDim2.new(0.3, 0, 1, 0), -- 30% width
            Position = UDim2.new(0.7, 5, 0, 0), -- Positioned after label
            BackgroundColor3 = enabled and UI_ACCENT_COLOR or UI_SECONDARY_COLOR,
            BorderSizePixel = 0,
            Text = enabled and "ON" or "OFF",
            Font = UI_FONT,
            TextColor3 = Color3.new(1,1,1),
            TextSize = 14,
            ZIndex = ElementFrame.ZIndex + 1,
            Parent = elementContainer
        })
        CreateElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = toggleButton })

        local function SetValue(newValue)
            enabled = newValue
            toggleButton.Text = enabled and "ON" or "OFF"
            toggleButton.BackgroundColor3 = enabled and UI_ACCENT_COLOR or UI_SECONDARY_COLOR
            -- Store the setting
            if Settings[categoryName] == nil then Settings[categoryName] = {} end
            Settings[categoryName][name] = enabled
            -- Trigger callback
            if callback then
                local success, err = pcall(callback, enabled)
                if not success then
                    warn("Meteor Toggle Error ("..name.."):", err)
                    self:CreateNotification("Toggle Error", "Error in '"..name.."': "..tostring(err), 5, "alert")
                end
            end
        end

		local togConn = toggleButton.Activated:Connect(function()
			SetValue(not enabled)
		end)
		self:Clean(togConn)

        local elementData = { Type = "Toggle", Instance = elementContainer, Button = toggleButton, Label = label, Default = defaultValue, GetValue = function() return enabled end, SetValue = SetValue }
        RegisterElement(categoryName, name, elementData)
        return elementData
    end

    Meteor.CreateSlider = function(self, categoryName, name, min, max, defaultValue, precision, callback)
        min = min or 0
        max = max or 100
        precision = precision or 0
        local currentValue = defaultValue or min

        local elementContainer = CreateElement("Frame", {
            Name = name,
            Size = UDim2.new(1, 0, 0, 40), -- Slightly taller for slider bar
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        })

        local label = CreateElement("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 15), -- Top part for label
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Font = UI_FONT,
            TextColor3 = UI_TEXT_COLOR,
            TextSize = 14,
            Text = name .. ": " .. string.format("%."..precision.."f", currentValue),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = ElementFrame.ZIndex + 1,
            Parent = elementContainer
        })

        local sliderTrack = CreateElement("Frame", {
            Name = "SliderTrack",
            Size = UDim2.new(1, 0, 0, 8), -- Main track bar
            Position = UDim2.new(0, 0, 0, 20), -- Below label
            BackgroundColor3 = UI_SECONDARY_COLOR,
            BorderSizePixel = 0,
            ZIndex = ElementFrame.ZIndex + 1,
            Parent = elementContainer
        })
        CreateElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = sliderTrack })

        local sliderFill = CreateElement("Frame", {
            Name = "SliderFill",
            Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0), -- Filled portion
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = UI_ACCENT_COLOR,
            BorderSizePixel = 0,
            ZIndex = sliderTrack.ZIndex + 1,
            Parent = sliderTrack
        })
        CreateElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = sliderFill })

		local sliderButton = CreateElement("TextButton", { -- Invisible button for input capture
            Name = "SliderInput",
            Size = UDim2.new(1, 0, 1, 12), -- Covers track area + some vertical space
			Position = UDim2.new(0,0,0,-2), -- Slightly offset
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = sliderTrack.ZIndex + 2,
            Parent = sliderTrack
        })

        local dragging = false

        local function UpdateValueFromInput(input)
			local relativePos = input.Position.X - sliderTrack.AbsolutePosition.X
            local percentage = math.clamp(relativePos / sliderTrack.AbsoluteSize.X, 0, 1)
            local newValue = min + percentage * (max - min)
            newValue = tonumber(string.format("%."..precision.."f", newValue)) -- Apply precision
            newValue = math.clamp(newValue, min, max) -- Clamp again after precision

            if newValue ~= currentValue then
                currentValue = newValue
                label.Text = name .. ": " .. string.format("%."..precision.."f", currentValue)
                sliderFill.Size = UDim2.new(percentage, 0, 1, 0)

                -- Store Setting
                if Settings[categoryName] == nil then Settings[categoryName] = {} end
                Settings[categoryName][name] = currentValue

                -- Callback
                if callback then
                    pcall(callback, currentValue)
                end
            end
		end

        local inputBeganConn = sliderButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                UpdateValueFromInput(input) -- Update on initial click
            end
        end)
        local inputChangedConn = sliderButton.InputChanged:Connect(function(input)
             if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                 UpdateValueFromInput(input)
             end
        end)
        local inputEndedConn = sliderButton.InputEnded:Connect(function(input)
             if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

		self:Clean(inputBeganConn)
		self:Clean(inputChangedConn)
		self:Clean(inputEndedConn)

        local function SetValue(newValue)
            newValue = tonumber(newValue) or min
            newValue = math.clamp(newValue, min, max)
            newValue = tonumber(string.format("%."..precision.."f", newValue)) -- Apply precision

            if newValue ~= currentValue then
                currentValue = newValue
                label.Text = name .. ": " .. string.format("%."..precision.."f", currentValue)
                local percentage = (max-min) > 0 and (currentValue - min) / (max - min) or 0
                sliderFill.Size = UDim2.new(percentage, 0, 1, 0)

                 -- Store Setting
                if Settings[categoryName] == nil then Settings[categoryName] = {} end
                Settings[categoryName][name] = currentValue

                -- Callback
                if callback then
                    pcall(callback, currentValue)
                end
            end
        end

        local elementData = { Type = "Slider", Instance = elementContainer, Min = min, Max = max, Precision = precision, Default = defaultValue, GetValue = function() return currentValue end, SetValue = SetValue }
        RegisterElement(categoryName, name, elementData)
        return elementData
    end

	Meteor.CreateTextBox = function(self, categoryName, name, placeholder, defaultValue, clearOnFocus, callback)
        local currentValue = defaultValue or ""

        local elementContainer = CreateElement("Frame", {
            Name = name,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        })

        local label = CreateElement("TextLabel", {
            Name = "Label",
            Size = UDim2.new(0.3, -5, 1, 0), -- 30% width for label
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Font = UI_FONT,
            TextColor3 = UI_TEXT_COLOR,
            TextSize = 14,
            Text = name,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = ElementFrame.ZIndex + 1,
            Parent = elementContainer
        })

        local textBox = CreateElement("TextBox", {
            Name = "TextBox",
            Size = UDim2.new(0.7, 0, 1, 0), -- 70% width for input
            Position = UDim2.new(0.3, 5, 0, 0),
            BackgroundColor3 = UI_SECONDARY_COLOR,
            BorderSizePixel = 0,
            Font = UI_FONT,
            TextColor3 = UI_TEXT_COLOR,
            TextSize = 14,
            Text = currentValue,
            PlaceholderText = placeholder or "Enter text...",
			PlaceholderColor3 = Color3.fromRGB(150,150,150),
            ClearTextOnFocus = clearOnFocus or false,
            ZIndex = ElementFrame.ZIndex + 1,
            Parent = elementContainer
        })
        CreateElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = textBox })

		local function SetValue(newValue)
			newValue = tostring(newValue)
			currentValue = newValue
			textBox.Text = currentValue
			 -- Store Setting
			if Settings[categoryName] == nil then Settings[categoryName] = {} end
			Settings[categoryName][name] = currentValue
			-- Callback
			if callback then
				local success, err = pcall(callback, currentValue)
				if not success then
					warn("Meteor TextBox Error ("..name.."):", err)
				end
			end
		end

		local focusLostConn = textBox.FocusLost:Connect(function(enterPressed)
			if enterPressed then -- Only callback/save if Enter was pressed
				SetValue(textBox.Text)
			else -- Still update internal value if focus is lost without Enter
				currentValue = textBox.Text
			end
		end)
		self:Clean(focusLostConn)

		local changedConn = textBox:GetPropertyChangedSignal("Text"):Connect(function()
			-- Can add live validation or updates here if needed, but saving on focus lost is common
			-- currentValue = textBox.Text -- Update live internal value maybe?
		end)
		self:Clean(changedConn)


		local elementData = { Type = "TextBox", Instance = elementContainer, TextBox = textBox, GetValue = function() return currentValue end, SetValue = SetValue, Default = defaultValue }
        RegisterElement(categoryName, name, elementData)
        return elementData
	end

	-- === Settings Management ===
	local function SerializeTable(tbl)
		local parts = {}
		local function serialize(val, indent)
			local t = type(val)
			if t == "string" then return "\"" .. val:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n") .. "\""
			elseif t == "number" or t == "boolean" then return tostring(val)
			elseif t == "table" then
				local isArray = #val > 0 and next(val, #val) == nil -- Basic array check
				local str = "{"
				local first = true
				if isArray then
					for i = 1, #val do
						if not first then str = str .. ", " end
						str = str .. serialize(val[i], (indent or "") .. "  ")
						first = false
					end
				else
					for k, v in pairs(val) do
						if not first then str = str .. ", " end
						local keyStr = type(k) == "string" and "[\"" .. k .. "\"]" or "[" .. tostring(k) .. "]"
						str = str .. keyStr .. " = " .. serialize(v, (indent or "") .. "  ")
						first = false
					end
				end
				return str .. "}"
			else return "nil" -- Unsupported type
			end
		end
		return "return " .. serialize(tbl)
	end

	LoadSettings = function()
		local suc, configContent = pcall(readfile, ConfigFileName)
		if suc and configContent and #configContent > 0 then
            -- Remove watermark if present
            configContent = configContent:gsub("--This watermark.*\n", "")
			local loadFunc, loadErr = loadstring(configContent, "MeteorConfig")
			if loadFunc then
				local loadSuc, loadedSettings = pcall(loadFunc)
				if loadSuc and type(loadedSettings) == "table" then
					Settings = loadedSettings
                    print("Meteor: Settings loaded.")
				else
					warn("Meteor: Failed to execute config file or invalid format.", loadedSettings or loadErr)
                    Settings = {} -- Reset to default if load failed
				end
			else
				warn("Meteor: Failed to load config string.", loadErr)
                Settings = {}
			end
		else
			warn("Meteor: No config file found or file is empty. Using defaults.")
			Settings = {} -- Initialize empty if no file
		end
	end

	SaveSettings = function()
        local currentSettings = {}
        -- Rebuild settings from current element values to ensure consistency
		for catName, catData in pairs(Meteor.Categories or {}) do
            if not currentSettings[catName] then currentSettings[catName] = {} end
			for elName, elData in pairs(catData.Elements or {}) do
				if elData.GetValue then
					currentSettings[catName][elName] = elData:GetValue()
				-- Add other element types here if they store persistent state differently
				end
			end
		end
        Settings = currentSettings -- Update internal settings table

		local serialized = SerializeTable(Settings)
		-- Add watermark back when saving
		serialized = "--This watermark is used to delete the file if its cached, remove it to make the file persist after Meteor updates.\n" .. serialized
		pcall(writefile, ConfigFileName, serialized)
		--print("Meteor: Settings saved.")
	end

	-- Return the populated Meteor table
	return Meteor
end
