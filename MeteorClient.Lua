-- MeteorClient.lua
-- Handles ALL GUI Elements, Config File I/O, Themes, and Assets

local mainapi = {
	Categories = {}, -- Stores category data { Name, Modules, Order, UI={TabButton, ContentFrame} }
	GUIColor = { Hue = 0.46, Sat = 0.96, Value = 0.52 }, -- Example default color
	HeldKeybinds = {}, -- State for held keybinds (managed by main?)
	Keybind = {'RightShift'}, -- Default keybind, loaded from config
	Loaded = false, -- Flag set by main.lua when init is complete
	Libraries = {}, -- For external libraries if needed
	Modules = {}, -- Stores module data { Enabled=bool, _uiToggleButton=instance, _updateVisual=func, ...other options... }
	Notifications = {Enabled = true}, -- Setting loaded from config
	Place = game.PlaceId, -- Store current place ID
	Profile = 'default', -- Default profile name, potentially overwritten by main/shared var
	Profiles = {}, -- For managing multiple profiles if implemented later
	Scale = nil, -- Will hold the main UIScale Instance
	ToggleNotifications = {Enabled = true}, -- Setting loaded from config
	ThreadFix = setthreadidentity and true or false, -- Executor feature detection
	Version = '1.0.2', -- Client version
	Windows = {}, -- For additional draggable windows if added
    CurrentTheme = 'Water', -- Default theme, loaded from config
	_themeConnections = {}, -- Internal: store connections for theme updates
    _uiElements = {}, -- Internal: Store references {["Type_Name"]=Instance} for cleanup/updates
}

-- Roblox Services
local cloneref = cloneref or function(obj) return obj end
local tweenService = cloneref(game:GetService('TweenService'))
local inputService = cloneref(game:GetService('UserInputService'))
local textService = cloneref(game:GetService('TextService'))
local guiService = cloneref(game:GetService('GuiService'))
local httpService = cloneref(game:GetService('HttpService'))
local runService = cloneref(game:GetService('RunService'))
local playersService = cloneref(game:GetService('Players'))
local isTouchDevice = inputService.TouchEnabled

-- File System Functions (Ensure these exist in the environment)
local isfolder = isfolder or function(f) local s,e=pcall(function() return readfile(f) end); return e and e:find("Cannot find specified file")==nil end -- Basic check
local makefolder = makefolder or function() end
local writefile = writefile or function() return false end -- Should return success ideally
local readfile = readfile or function() return '' end
local delfile = delfile or function() end
local randomString = function(length)
    local str = ""
    for _ = 1, length or 10 do str = str .. string.char(math.random(97, 122)) end
    return str
end

-- Color Helpers
local color = {
	Dark = function(c3, factor) return Color3.fromRGB(math.max(0, c3.r * 255 - 255 * factor), math.max(0, c3.g * 255 - 255 * factor), math.max(0, c3.b * 255 - 255 * factor)) end,
	Light = function(c3, factor) return Color3.fromRGB(math.min(255, c3.r * 255 + 255 * factor), math.min(255, c3.g * 255 + 255 * factor), math.min(255, c3.b * 255 + 255 * factor)) end,
}

-- UI Palette and Themes
local uipallet = {
	Main = Color3.fromRGB(23, 26, 33),
	MainColor = Color3.fromRGB(12, 163, 232), -- Default: Water
	SecondaryColor = Color3.fromRGB(12, 232, 199), -- Default: Water
	Text = Color3.new(1, 1, 1),
	Font = Font.fromEnum(Enum.Font.GothamSemibold),
	Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear),
	Themes = {
		Default = {{Color3.fromRGB(12, 163, 232), Color3.fromRGB(12, 232, 199)}, 6, 7}, -- Use Water as default display
        Aubergine = {{Color3.fromRGB(170, 7, 107), Color3.fromRGB(97, 4, 95)}, 1, 8},
		Aqua = {{Color3.fromRGB(185, 250, 255), Color3.fromRGB(79, 199, 200)}, 6},
		Banana = {{Color3.fromRGB(253, 236, 177), Color3.fromRGB(255, 255, 255)}, 3},
		Blend = {{Color3.fromRGB(71, 148, 253), Color3.fromRGB(71, 253, 160)}, 4, 6},
		Blossom = {{Color3.fromRGB(226, 208, 249), Color3.fromRGB(49, 119, 115)}, 9, 10},
		Bubblegum = {{Color3.fromRGB(243, 145, 216), Color3.fromRGB(152, 165, 243)}, 8, 9},
		['Candy Cane'] = {{Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 255)}, 1},
		Cherry = {{Color3.fromRGB(187, 55, 125), Color3.fromRGB(251, 211, 233)}, 1, 8, 9},
		Christmas = {{Color3.fromRGB(255, 64, 64), Color3.fromRGB(255, 255, 255), Color3.fromRGB(64, 255, 64)}, 1, 4},
		Coral = {{Color3.fromRGB(244, 168, 150), Color3.fromRGB(52, 133, 151)}, 2, 7, 9},
		Creida = {{Color3.fromRGB(156, 164, 224), Color3.fromRGB(54, 57, 78)}, 10},
		['Creida Two'] = {{Color3.fromRGB(154, 202, 235), Color3.fromRGB(88, 130, 161)}, 10},
		['Digital Horizon'] = {{Color3.fromRGB(95, 195, 228), Color3.fromRGB(229, 93, 135)}, 1, 6, 9},
		Express = {{Color3.fromRGB(173, 83, 137), Color3.fromRGB(60, 16, 83)}, 8, 9},
		Gothic = {{Color3.fromRGB(31, 30, 30), Color3.fromRGB(196, 190, 190)}, 10},
		Halogen = {{Color3.fromRGB(255, 65, 108), Color3.fromRGB(255, 75, 43)}, 1, 2},
		Hyper = {{Color3.fromRGB(236, 110, 173), Color3.fromRGB(52, 148, 230)}, 6, 7, 9},
		Legacy = {{Color3.fromRGB(112, 206, 255), Color3.fromRGB(112, 206, 255)}, 6, 7},
		['Lime Water'] = {{Color3.fromRGB(18, 255, 247), Color3.fromRGB(179, 255, 171)}, 4, 6},
		Lush = {{Color3.fromRGB(168, 224, 99), Color3.fromRGB(86, 171, 47)}, 4, 5},
		Magic = {{Color3.fromRGB(74, 0, 224), Color3.fromRGB(142, 45, 226)}, 7, 8},
		May = {{Color3.fromRGB(170, 7, 107), Color3.fromRGB(238, 79, 238)}, 8, 9},
		['Orange Juice'] = {{Color3.fromRGB(252, 74, 26), Color3.fromRGB(247, 183, 51)}, 2, 3},
		Pastel = {{Color3.fromRGB(243, 155, 178), Color3.fromRGB(207, 196, 243)}, 9},
		Peony = {{Color3.fromRGB(226, 208, 249), Color3.fromRGB(207, 171, 255)}, 9, 10},
		Pumpkin = {{Color3.fromRGB(241, 166, 98), Color3.fromRGB(255, 216, 169), Color3.fromRGB(227, 139, 42)}, 2},
		Purple = {{Color3.fromRGB(82, 67, 145), Color3.fromRGB(117, 95, 207)}, 8},
		Rainbow = {{Color3.new(1, 1, 1), Color3.new(1, 1, 1)}, 10}, -- Requires special handling if animated
		Rue = {{Color3.fromRGB(234, 118, 176), Color3.fromRGB(31, 30, 30)}, 9},
		Satin = {{Color3.fromRGB(215, 60, 67), Color3.fromRGB(140, 23, 39)}, 1},
		Shadow = {{Color3.fromRGB(97, 131, 255), Color3.fromRGB(206, 212, 255)}, 6},
		['Snowy Sky'] = {{Color3.fromRGB(1, 171, 179), Color3.fromRGB(234, 234, 234), Color3.fromRGB(18, 232, 232)}, 6, 10},
		['Steel Fade'] = {{Color3.fromRGB(66, 134, 244), Color3.fromRGB(55, 59, 68)}, 7, 10},
		Sundae = {{Color3.fromRGB(206, 74, 126), Color3.fromRGB(122, 44, 77)}, 1, 8, 9},
		Sunkist = {{Color3.fromRGB(242, 201, 76), Color3.fromRGB(242, 153, 74)}, 2, 3},
		Water = {{Color3.fromRGB(12, 163, 232), Color3.fromRGB(12, 232, 199)}, 6, 7}, -- Swapped order to match Main/SecondaryColor defaults
		Winter = {{Color3.new(1, 1, 1), Color3.new(1, 1, 1)}, 10}, -- Requires special handling if animated
		Wood = {{Color3.fromRGB(79, 109, 81), Color3.fromRGB(170, 139, 87), Color3.fromRGB(240, 235, 206)}, 5}
	},
	ThemeObjects = {} -- Stores {Object=Instance, Property=string, Type=string}
}

-- Asset Management
local getcustomassets = {
	-- Replace with YOUR actual asset IDs or paths
	['Meteor_/assets/slice.png'] = 'rbxassetid://0', -- Placeholder
	['Meteor_/assets/blur.png'] = 'rbxassetid://0', -- Placeholder
	['Meteor_/assets/new/blur.png'] = 'rbxassetid://0', -- Placeholder (if used by addBlur)
	['Meteor_/assets/add.png'] = 'rbxassetid://14368300605',
	['Meteor_/assets/alert.png'] = 'rbxassetid://14368301329',
	['Meteor_/assets/back.png'] = 'rbxassetid://14368303894',
	['Meteor_/assets/bind.png'] = 'rbxassetid://14368304734',
	['Meteor_/assets/bindbkg.png'] = 'rbxassetid://14368305655',
	['Meteor_/assets/blurnotif.png'] = 'rbxassetid://16738720137',
	['Meteor_/assets/close.png'] = 'rbxassetid://14368309446',
	['Meteor_/assets/closemini.png'] = 'rbxassetid://14368310467',
	['Meteor_/assets/colorpreview.png'] = 'rbxassetid://14368311578',
	['Meteor_/assets/dots.png'] = 'rbxassetid://14368314459', -- Used for settings
    ['Meteor_/assets/settings_dots.png'] = 'rbxassetid://14368314459', -- Alias for settings
	['Meteor_/assets/guisettings.png'] = 'rbxassetid://14368318994',
	['Meteor_/assets/guislider.png'] = 'rbxassetid://14368320020',
	['Meteor_/assets/guisliderrain.png'] = 'rbxassetid://14368321228',
	['Meteor_/assets/info.png'] = 'rbxassetid://14368324807',
	['Meteor_/assets/miniicon.png'] = 'rbxassetid://14368326029',
	['Meteor_/assets/notification.png'] = 'rbxassetid://16738721069',
	['Meteor_/assets/overlaysicon.png'] = 'rbxassetid://14368339581',
	['Meteor_/assets/overlaystab.png'] = 'rbxassetid://14397380433',
	['Meteor_/assets/profilesicon.png'] = 'rbxassetid://14397465323',
	['Meteor_/assets/radaricon.png'] = 'rbxassetid://14368343291',
	['Meteor_/assets/rendericon.png'] = 'rbxassetid://14368350193',
	['Meteor_/assets/search.png'] = 'rbxassetid://14425646684',
	['Meteor_/assets/targetinfoicon.png'] = 'rbxassetid://14368354234',
	['Meteor_/assets/targetnpc1.png'] = 'rbxassetid://14497400332',
	['Meteor_/assets/targetnpc2.png'] = 'rbxassetid://14497402744',
	['Meteor_/assets/targetplayers1.png'] = 'rbxassetid://14497396015',
	['Meteor_/assets/targetplayers2.png'] = 'rbxassetid://14497397862',
	['Meteor_/assets/targetstab.png'] = 'rbxassetid://14497393895',
	['Meteor_/assets/MeteorLogo.png'] = 'rbxassetid://112074606899793',
	['Meteor_/assets/warning.png'] = 'rbxassetid://14368361552',
	['Meteor_/assets/worldicon.png'] = 'rbxassetid://14368362492'
}
local getcustomasset_cache = {}
local getcustomasset = function(path)
    if getcustomasset_cache[path] then return getcustomasset_cache[path] end
    local id = getcustomassets[path]
    if id then getcustomasset_cache[path] = id; return id
    else warn("Asset not found:", path); return "" end
end

-- UI Helper Functions
local function addCorner(parent, radius)
	local corner = Instance.new('UICorner'); corner.CornerRadius = radius or UDim.new(0, 6); corner.Parent = parent; return corner
end
local function addBlur(parent)
	local blur = Instance.new('ImageLabel'); blur.Name = 'Blur'; blur.Size = UDim2.new(1, 89, 1, 52); blur.Position = UDim2.fromOffset(-48, -31); blur.BackgroundTransparency = 1; blur.Image = getcustomasset('Meteor_/assets/blur.png'); blur.ScaleType = Enum.ScaleType.Slice; blur.SliceCenter = Rect.new(40, 40, 215, 215); blur.ZIndex = -1; blur.Parent = parent; return blur
end

-- Tween Management
local activeTweens = {}
local function createTween(obj, goal, infoOverride)
    local info = infoOverride or uipallet.Tween
    local existing = activeTweens[obj]
    if existing and existing.PlaybackState ~= Enum.PlaybackState.Cancelled and existing.PlaybackState ~= Enum.PlaybackState.Completed then
        existing:Cancel() -- Cancel previous tween on the same object
    end
    local newTween = tweenService:Create(obj, info, goal)
    activeTweens[obj] = newTween
    newTween.Completed:Connect(function()
        if activeTweens[obj] == newTween then
            activeTweens[obj] = nil -- Clear from active tweens on completion
        end
    end)
    newTween:Play()
    return newTween
end

-- GUI Instances (defined within this scope)
local gui, scaledgui, clickgui, modal, cursor, notifications, tooltip, toolblur, toolstroke
local loadingFrame, loadingText
local mainframe, mainscale, sidebar, categoryholder, categoryhighlight, contentFrame
local lastSelectedCategoryButton = nil
local mainGuiScale -- Renamed from 'scale' to avoid conflict with mainapi.Scale property

---[[ GUI Creation and Setup ]]--
local function setupGui()
    gui = Instance.new('ScreenGui')
    gui.Name = "MeteorClient_" .. randomString()
    gui.DisplayOrder = 9999999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Enabled = false -- Start disabled, enabled by ToggleGUI
    if mainapi.ThreadFix then
        gui.Parent = (gethui and gethui()) or cloneref(game:GetService('CoreGui'))
    else
        gui.Parent = playersService.LocalPlayer:WaitForChild("PlayerGui")
        gui.ResetOnSpawn = false
    end
    mainapi.gui = gui -- Store reference if needed externally (should be rare)

    scaledgui = Instance.new('Frame')
    scaledgui.Name = 'ScaledGui'; scaledgui.Size = UDim2.fromScale(1, 1); scaledgui.BackgroundTransparency = 1; scaledgui.Parent = gui

    mainGuiScale = Instance.new('UIScale')
    mainGuiScale.Scale = 1; mainGuiScale.Parent = scaledgui
    mainapi.Scale = mainGuiScale -- Allow main script to access/modify UIScale object

    -- Loading Frame
    loadingFrame = Instance.new("Frame")
    loadingFrame.Name = "LoadingFrame"; loadingFrame.Size = UDim2.new(0, 300, 0, 100); loadingFrame.Position = UDim2.fromScale(0.5, 0.5); loadingFrame.AnchorPoint = Vector2.new(0.5, 0.5); loadingFrame.BackgroundColor3 = uipallet.Main; loadingFrame.BorderSizePixel = 0; loadingFrame.Visible = false; loadingFrame.ZIndex = 10000; loadingFrame.Parent = scaledgui; addCorner(loadingFrame); addBlur(loadingFrame)
    loadingText = Instance.new("TextLabel")
    loadingText.Name = "LoadingText"; loadingText.Size = UDim2.new(1, -20, 1, -20); loadingText.Position = UDim2.fromScale(0.5, 0.5); loadingText.AnchorPoint = Vector2.new(0.5, 0.5); loadingText.BackgroundTransparency = 1; loadingText.Font = uipallet.Font; loadingText.TextColor3 = uipallet.Text; loadingText.TextSize = 18; loadingText.TextWrapped = true; loadingText.Text = "Meteor | Initializing..."; loadingText.Parent = loadingFrame

    -- ClickGUI Frame
    clickgui = Instance.new('Frame')
    clickgui.Name = 'ClickGui'; clickgui.Size = UDim2.fromScale(1, 1); clickgui.BackgroundTransparency = 1; clickgui.Visible = false; clickgui.Parent = scaledgui

    modal = Instance.new('TextButton') -- Background blocker (semi-transparent black)
    modal.Name = "ModalBackground"; modal.Size = UDim2.fromScale(1, 1); modal.BackgroundTransparency = 0.6; modal.BackgroundColor3 = Color3.new(0,0,0); modal.Modal = true; modal.Text = ''; modal.ZIndex = 1; modal.Parent = clickgui

    cursor = Instance.new('ImageLabel')
    cursor.Name = "Cursor"; cursor.Size = UDim2.fromOffset(24, 24); cursor.BackgroundTransparency = 1; cursor.Visible = false; cursor.Image = 'rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png'; cursor.ZIndex = 9999; cursor.Parent = gui
    if not isTouchDevice then
        inputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                cursor.Position = UDim2.fromOffset(input.Position.X, input.Position.Y)
            end
        end)
    else
        cursor.Visible = false -- No custom cursor on touch devices
    end

    notifications = Instance.new('Frame') -- Changed to Frame for better layout control
    notifications.Name = 'Notifications'; notifications.Size = UDim2.new(0, 270, 1, 0); notifications.Position = UDim2.new(1, -280, 0, 0); notifications.BackgroundTransparency = 1; notifications.ClipsDescendants = true; notifications.ZIndex = 2000; notifications.Parent = scaledgui
    local notificationLayout = Instance.new("UIListLayout")
    notificationLayout.FillDirection = Enum.FillDirection.Vertical
    notificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notificationLayout.Padding = UDim.new(0, 5)
    notificationLayout.Parent = notifications

    tooltip = Instance.new('TextLabel')
    tooltip.Name = 'Tooltip'; tooltip.Position = UDim2.fromScale(-1, -1); tooltip.ZIndex = 5000; tooltip.Size = UDim2.fromOffset(1,1); tooltip.AutomaticSize = Enum.AutomaticSize.XY; tooltip.BackgroundColor3 = color.Dark(uipallet.Main, 0.02); tooltip.BorderSizePixel = 0; tooltip.Visible = false; tooltip.Text = ''; tooltip.TextColor3 = color.Light(uipallet.Text, -0.16); tooltip.TextSize = 14; tooltip.Font = uipallet.Font; tooltip.TextXAlignment = Enum.TextXAlignment.Center; tooltip.TextYAlignment = Enum.TextYAlignment.Center; tooltip.PaddingLeft = UDim.new(0,8); tooltip.PaddingRight = UDim.new(0,8); tooltip.PaddingTop = UDim.new(0,5); tooltip.PaddingBottom = UDim.new(0,5); tooltip.Parent = scaledgui; toolblur = addBlur(tooltip); addCorner(tooltip, UDim.new(0, 4)); toolstroke = Instance.new('UIStroke'); toolstroke.Color = color.Light(uipallet.Main, 0.02); toolstroke.Thickness = 1; toolstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; toolstroke.Parent = tooltip

    mainframe = Instance.new('CanvasGroup')
    mainframe.Name = "MainFrame"; mainframe.Size = UDim2.fromOffset(650, 450); mainframe.Position = UDim2.fromScale(0.5, 0.5); mainframe.AnchorPoint = Vector2.new(0.5, 0.5); mainframe.BackgroundColor3 = uipallet.Main; mainframe.GroupTransparency = 1; mainframe.Visible = false; mainframe.ZIndex = 2; mainframe.Parent = clickgui; addBlur(mainframe); addCorner(mainframe)
    local mainFrameStroke = Instance.new("UIStroke"); mainFrameStroke.Thickness = 1; mainFrameStroke.Color = color.Light(uipallet.Main, 0.05); mainFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; mainFrameStroke.Parent = mainframe; table.insert(uipallet.ThemeObjects, {Object = mainFrameStroke, Property = "Color", Type = "AccentBorder"})

    mainscale = Instance.new('UIScale'); mainscale.Scale = 1; mainscale.Parent = mainframe -- Scale within mainframe if needed

    sidebar = Instance.new('Frame')
    sidebar.Name = "Sidebar"; sidebar.Size = UDim2.new(0, 150, 1, 0); sidebar.BackgroundColor3 = color.Dark(uipallet.Main, 0.03); sidebar.BorderSizePixel = 0; sidebar.Parent = mainframe; addCorner(sidebar)
    local scorner = Instance.new('Frame'); scorner.Name = "SidebarEdgeFix"; scorner.BorderSizePixel = 0; scorner.BackgroundColor3 = color.Dark(uipallet.Main, 0.03); scorner.Position = UDim2.new(1, -6, 0, 0); scorner.Size = UDim2.new(0, 6, 1, 0); scorner.Parent = sidebar
    local swatermark = Instance.new('TextLabel'); swatermark.Name = "Watermark"; swatermark.Size = UDim2.new(1, -20, 0, 30); swatermark.Position = UDim2.fromOffset(15, 15); swatermark.BackgroundTransparency = 1; swatermark.Text = 'Meteor'; swatermark.TextColor3 = uipallet.Text; swatermark.Font = uipallet.Font; swatermark.TextSize = 24; swatermark.TextXAlignment = Enum.TextXAlignment.Left; swatermark.TextYAlignment = Enum.TextYAlignment.Center; swatermark.Parent = sidebar
    local swatermarkversion = Instance.new('TextLabel'); swatermarkversion.Name = "Version"; swatermarkversion.Size = UDim2.new(1, -20, 0, 15); swatermarkversion.Position = UDim2.fromOffset(15, 45); swatermarkversion.BackgroundTransparency = 1; swatermarkversion.Text = mainapi.Version or "?.?.?"; swatermarkversion.TextColor3 = uipallet.MainColor; swatermarkversion.Font = uipallet.Font; swatermarkversion.TextSize = 12; swatermarkversion.TextXAlignment = Enum.TextXAlignment.Left; swatermarkversion.TextYAlignment = Enum.TextYAlignment.Top; swatermarkversion.Parent = sidebar; table.insert(uipallet.ThemeObjects, {Object = swatermarkversion, Property = "TextColor3", Type = "Main"})

    categoryholder = Instance.new('ScrollingFrame')
    categoryholder.Name = "CategoryHolder"; categoryholder.Size = UDim2.new(1, -10, 1, -70); categoryholder.Position = UDim2.fromOffset(5, 65); categoryholder.BackgroundTransparency = 1; categoryholder.BorderSizePixel = 0; categoryholder.ScrollBarThickness = 4; categoryholder.CanvasSize = UDim2.new(); categoryholder.Parent = sidebar
    local sort = Instance.new('UIListLayout'); sort.FillDirection = Enum.FillDirection.Vertical; sort.HorizontalAlignment = Enum.HorizontalAlignment.Center; sort.VerticalAlignment = Enum.VerticalAlignment.Top; sort.SortOrder = Enum.SortOrder.LayoutOrder; sort.Padding = UDim.new(0, 5); sort.Parent = categoryholder
    local listPadding = Instance.new("UIPadding"); listPadding.PaddingTop = UDim.new(0, 5); listPadding.PaddingBottom = UDim.new(0, 5); listPadding.Parent = categoryholder

    categoryhighlight = Instance.new("Frame")
    categoryhighlight.Name = "Highlight"; categoryhighlight.Size = UDim2.new(1, -10, 0, 30); categoryhighlight.Position = UDim2.fromOffset(5, -1000); -- Start offscreen
    categoryhighlight.BackgroundColor3 = uipallet.MainColor; categoryhighlight.BorderSizePixel = 0; categoryhighlight.ZIndex = 0; categoryhighlight.Visible = false; categoryhighlight.Parent = categoryholder; addCorner(categoryhighlight, UDim.new(0, 4)); table.insert(uipallet.ThemeObjects, {Object = categoryhighlight, Property = "BackgroundColor3", Type = "Main"})

    contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"; contentFrame.Size = UDim2.new(1, -150, 1, 0); contentFrame.Position = UDim2.new(0, 150, 0, 0); contentFrame.BackgroundColor3 = uipallet.Main; contentFrame.BackgroundTransparency = 0; contentFrame.BorderSizePixel = 0; contentFrame.ClipsDescendants = true; contentFrame.Parent = mainframe

    -- Add dragging only if mainframe exists
    if mainframe then setupDragging(mainframe, sidebar) end -- Pass main frame and drag handle
end

---[[ Tooltip Functions ]]--
local function showTooltip(text, parentObject)
    if not tooltip or not tooltip.Parent or not text or text == "" then return end
    tooltip.Text = text
    -- Calculate position near mouse, adjusted for tooltip size and screen bounds
    task.wait() -- Allow AutomaticSize to update AbsoluteSize
    local mousePos = inputService:GetMouseLocation()
    local guiSize = tooltip.AbsoluteSize
    local screenWidth = gui.AbsoluteSize.X
    local screenHeight = gui.AbsoluteSize.Y
    local posX = mousePos.X + 15
    local posY = mousePos.Y + 15
    if posX + guiSize.X > screenWidth then posX = mousePos.X - guiSize.X - 15 end
    if posY + guiSize.Y > screenHeight then posY = mousePos.Y - guiSize.Y - 15 end
    tooltip.Position = UDim2.fromOffset(math.max(0, posX), math.max(0, posY)) -- Clamp position >= 0
    tooltip.Visible = true
end
local function hideTooltip()
    if tooltip then tooltip.Visible = false end
end

---[[ Theme Apply Function ]]--
function mainapi:ApplyTheme(themeName)
	local themeData = uipallet.Themes[themeName]
	if not themeData then
		warn("Theme not found:", themeName)
		themeData = uipallet.Themes['Water'] -- Fallback
        themeName = 'Water'
	end
    mainapi.CurrentTheme = themeName

	local colors = themeData[1]
	uipallet.MainColor = colors[1]
    uipallet.SecondaryColor = colors[2] or colors[1]

    -- Update objects registered for theme changes
    for i = #uipallet.ThemeObjects, 1, -1 do
        local data = uipallet.ThemeObjects[i]
        local obj = data.Object
        if obj and obj.Parent then
            local targetColor
            if data.Type == "Main" then targetColor = uipallet.MainColor
            elseif data.Type == "Secondary" then targetColor = uipallet.SecondaryColor
            elseif data.Type == "Text" then targetColor = uipallet.Text
            elseif data.Type == "AccentBorder" then targetColor = color.Light(uipallet.Main, 0.05)
            elseif data.Type == "DarkBG" then targetColor = color.Dark(uipallet.Main, 0.03)
            elseif data.Type == "ToggleOn" then targetColor = uipallet.MainColor -- Specific for toggle state
            elseif data.Type == "ToggleOff" then targetColor = color.Light(uipallet.Main, 0.1) -- Specific for toggle state
            else targetColor = uipallet.MainColor end

            if targetColor then
                 createTween(obj, {[data.Property] = targetColor})
            end
        else
            table.remove(uipallet.ThemeObjects, i) -- Clean up removed objects
        end
    end
end

---[[ Loading Screen Functions ]]--
function mainapi:ShowLoading(text)
	if loadingFrame and loadingFrame.Parent then
		loadingText.Text = text or "Meteor | Loading..."
		loadingFrame.Visible = true
	else
		warn("Loading frame not available to show.")
	end
end
function mainapi:HideLoading()
	if loadingFrame and loadingFrame.Parent then
		loadingFrame.Visible = false
	end
end

---[[ GUI Toggle Function ]]--
function mainapi:ToggleGUI(visible)
    if not clickgui or not mainframe then warn("Cannot toggle GUI - elements not initialized."); return end
    local targetVisible = (visible == nil and not clickgui.Visible) or visible
    if targetVisible == clickgui.Visible then return end

    gui.Enabled = true -- Ensure ScreenGui is enabled when showing
	if targetVisible then
		clickgui.Visible = true
        mainframe.Visible = true
        createTween(mainframe, {GroupTransparency = 0}, TweenInfo.new(0.2))
		if not isTouchDevice then
            pcall(function() inputService.MouseIconEnabled = false end)
             if cursor and cursor.Parent then cursor.Visible = true end
        end
	else
        local hideTween = createTween(mainframe, {GroupTransparency = 1}, TweenInfo.new(0.2))
		hideTween.Completed:Connect(function()
            if mainframe and mainframe.GroupTransparency == 1 then
                clickgui.Visible = false
                mainframe.Visible = false
                gui.Enabled = false -- Disable ScreenGui when fully hidden
            end
        end)
        if not isTouchDevice then
            pcall(function() inputService.MouseIconEnabled = true end)
             if cursor and cursor.Parent then cursor.Visible = false end
        end
	end
end

---[[ Notification Creation ]]--
local notificationTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local activeNotifications = {} -- Track active notifications for repositioning

local function repositionNotifications()
    if not notifications or not notifications.Parent then return end
    local currentYoffset = 0
    local children = notifications:GetChildren()
    -- Sort by LayoutOrder (creation time, newest first if using -tick())
    table.sort(children, function(a,b) return a.LayoutOrder > b.LayoutOrder end)

    for _, child in ipairs(children) do
        if child:IsA("Frame") and child.Name == "Notification" and activeNotifications[child] then
            local targetY = 1 - (currentYoffset / notifications.AbsoluteSize.Y) - (child.AbsoluteSize.Y / notifications.AbsoluteSize.Y) -- Position from bottom
            createTween(child, { Position = UDim2.new(0, 0, targetY, 0) }, notificationTweenInfo) -- Align right edge (parent size is 270)
            currentYoffset = currentYoffset + child.AbsoluteSize.Y + 5 -- Add gap
        end
    end
end

function mainapi:CreateNotification(title, text, duration, iconName)
    if not mainapi.Notifications.Enabled or not notifications or not notifications.Parent then return end
    pcall(function()
        local notifFrame = Instance.new("Frame")
        notifFrame.Name = "Notification"
        notifFrame.Size = UDim2.new(1, 0, 0, 1) -- Full width of parent (270), auto height
        notifFrame.AutomaticSize = Enum.AutomaticSize.Y
        notifFrame.Position = UDim2.new(0, 50, 1, 0) -- Start off-screen right, bottom aligned
        notifFrame.BackgroundColor3 = color.Dark(uipallet.Main, 0.1)
        notifFrame.BorderSizePixel = 0
        notifFrame.ClipsDescendants = true
        notifFrame.ZIndex = 1000
        notifFrame.LayoutOrder = -tick() -- Use negative tick for newest on top when using bottom alignment
        notifFrame.Parent = notifications
        addCorner(notifFrame, UDim.new(0, 5))
        -- addBlur(notifFrame) -- Optional

        local notifPadding = Instance.new("UIPadding"); notifPadding.PaddingBottom=UDim.new(0,8); notifPadding.PaddingLeft=UDim.new(0,10); notifPadding.PaddingRight=UDim.new(0,10); notifPadding.PaddingTop=UDim.new(0,8); notifPadding.Parent=notifFrame
        local notifLayout = Instance.new("UIListLayout"); notifLayout.FillDirection=Enum.FillDirection.Vertical; notifLayout.SortOrder=Enum.SortOrder.LayoutOrder; notifLayout.Padding=UDim.new(0,4); notifLayout.Parent=notifFrame
        local notifStroke = Instance.new("UIStroke"); notifStroke.Thickness=1; notifStroke.Color=uipallet.MainColor; notifStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; notifStroke.Parent=notifFrame
        table.insert(uipallet.ThemeObjects, {Object = notifStroke, Property = "Color", Type = "Main"})

        local topFrame = Instance.new("Frame"); topFrame.Size=UDim2.new(1,0,0,20); topFrame.BackgroundTransparency=1; topFrame.LayoutOrder=1; topFrame.Parent=notifFrame
        local topLayout = Instance.new("UIListLayout"); topLayout.FillDirection=Enum.FillDirection.Horizontal; topLayout.VerticalAlignment=Enum.VerticalAlignment.Center; topLayout.SortOrder=Enum.SortOrder.LayoutOrder; topLayout.Padding=UDim.new(0,5); topLayout.Parent=topFrame

        local iconImage = Instance.new("ImageLabel"); iconImage.Name="Icon"; iconImage.Size=UDim2.fromOffset(18,18); iconImage.BackgroundTransparency=1; iconImage.Image=getcustomasset('Meteor_/assets/'..(iconName or 'info')..'.png') or ""; iconImage.Visible=(iconImage.Image ~= ""); iconImage.LayoutOrder=1; iconImage.Parent=topFrame
        local titleLabel = Instance.new("TextLabel"); titleLabel.Name="Title"; titleLabel.Size=UDim2.new(1,-(iconImage.Visible and 23 or 0),1,0); titleLabel.BackgroundTransparency=1; titleLabel.Font=uipallet.Font; titleLabel.TextColor3=uipallet.MainColor; titleLabel.TextSize=16; titleLabel.Text=title or "Notification"; titleLabel.TextXAlignment=Enum.TextXAlignment.Left; titleLabel.TextYAlignment=Enum.TextYAlignment.Center; titleLabel.LayoutOrder=2; titleLabel.Parent=topFrame
        table.insert(uipallet.ThemeObjects, {Object = titleLabel, Property = "TextColor3", Type = "Main"})

        local textLabel = Instance.new("TextLabel"); textLabel.Name="Text"; textLabel.Size=UDim2.new(1,0,0,1); textLabel.AutomaticSize=Enum.AutomaticSize.Y; textLabel.BackgroundTransparency=1; textLabel.Font=uipallet.Font; textLabel.TextColor3=uipallet.Text; textLabel.TextSize=13; textLabel.Text=text or ""; textLabel.TextWrapped=true; textLabel.TextXAlignment=Enum.TextXAlignment.Left; textLabel.TextYAlignment=Enum.TextYAlignment.Top; textLabel.LayoutOrder=2; textLabel.Parent=notifFrame

        activeNotifications[notifFrame] = true -- Mark as active

        -- Wait a frame for autosize, then tween in and reposition others
        task.wait()
        createTween(notifFrame, { Position = UDim2.new(0, 0, notifFrame.Position.Y.Scale, 0) }, notificationTweenInfo) -- Slide in from right
        repositionNotifications() -- Reposition existing ones based on new height

        local lifeConnection
        local function dismissNotification()
            task.cancel(lifeConnection)
             if notifFrame and notifFrame.Parent then
                activeNotifications[notifFrame] = nil -- Mark as inactive
                local outTween = createTween(notifFrame, { Position = UDim2.new(0, 50, notifFrame.Position.Y.Scale, 0) }, notificationTweenInfo) -- Slide out right
                outTween.Completed:Connect(function()
                    if notifFrame and notifFrame.Parent then notifFrame:Destroy() end
                    repositionNotifications() -- Reposition remaining after one is destroyed
                end)
            end
        end

        lifeConnection = task.delay(duration or 5, dismissNotification)
        notifFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dismissNotification() end end)

    end)
end

---[[ Category and Module UI Creation ]]--
function mainapi:CreateCategory(name)
	if not categoryholder or not categoryholder.Parent then return end
    if mainapi.Categories[name] then return mainapi.Categories[name] end

    local categoryData = { Name = name, Modules = {}, Order = #categoryholder:GetChildren() + 1, UI = {} }

    local tabButton = Instance.new("TextButton"); tabButton.Name = name .. "Tab"; tabButton.Size = UDim2.new(1, -10, 0, 30); tabButton.BackgroundColor3 = color.Dark(uipallet.Main, 0.01); tabButton.TextColor3 = uipallet.Text; tabButton.Text = name; tabButton.Font = uipallet.Font; tabButton.TextSize = 14; tabButton.LayoutOrder = categoryData.Order; tabButton.AutoButtonColor = false; tabButton.BackgroundTransparency = 0.5; tabButton.Parent = categoryholder; addCorner(tabButton, UDim.new(0, 4))
    categoryData.UI.TabButton = tabButton

    local categoryContent = Instance.new("ScrollingFrame"); categoryContent.Name = name .. "Content"; categoryContent.Size = UDim2.new(1, 0, 1, 0); categoryContent.Position = UDim2.fromScale(0, 0); categoryContent.BackgroundTransparency = 1; categoryContent.BorderSizePixel = 0; categoryContent.Visible = false; categoryContent.ClipsDescendants = true; categoryContent.ScrollBarThickness = 6; categoryContent.CanvasSize = UDim2.new(); categoryContent.Parent = contentFrame
    local contentLayout = Instance.new("UIListLayout"); contentLayout.Padding = UDim.new(0, 8); contentLayout.FillDirection = Enum.FillDirection.Vertical; contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; contentLayout.VerticalAlignment = Enum.VerticalAlignment.Top; contentLayout.SortOrder = Enum.SortOrder.LayoutOrder; contentLayout.Parent = categoryContent
    local contentPadding = Instance.new("UIPadding"); contentPadding.PaddingLeft = UDim.new(0, 10); contentPadding.PaddingRight = UDim.new(0, 10); contentPadding.PaddingTop = UDim.new(0, 10); contentPadding.PaddingBottom = UDim.new(0, 10); contentPadding.Parent = categoryContent
    categoryData.UI.ContentFrame = categoryContent

    tabButton.MouseEnter:Connect(function() if lastSelectedCategoryButton ~= tabButton then createTween(tabButton, {BackgroundTransparency = 0.3}) end; showTooltip(name .. " Category", tabButton) end)
	tabButton.MouseLeave:Connect(function() if lastSelectedCategoryButton ~= tabButton then createTween(tabButton, {BackgroundTransparency = 0.5}) end; hideTooltip() end)
	tabButton.MouseButton1Click:Connect(function()
		if lastSelectedCategoryButton == tabButton then return end
        if lastSelectedCategoryButton then createTween(lastSelectedCategoryButton, {BackgroundTransparency = 0.5}); local oldCat = mainapi.Categories[lastSelectedCategoryButton.Name:gsub("Tab$", "")]; if oldCat and oldCat.UI.ContentFrame then oldCat.UI.ContentFrame.Visible = false end end
        lastSelectedCategoryButton = tabButton; createTween(tabButton, {BackgroundTransparency = 0}); categoryData.UI.ContentFrame.Visible = true; categoryContent.CanvasPosition = Vector2.zero
        categoryhighlight.Visible = true; createTween(categoryhighlight, {Position = tabButton.Position})
	end)

    mainapi.Categories[name] = categoryData
    mainapi._uiElements["Category_"..name] = categoryData.UI -- Store UI refs

    if not lastSelectedCategoryButton then task.defer(function() if tabButton and tabButton.Parent and not lastSelectedCategoryButton then tabButton.MouseButton1Click:Fire() end end) end

	return categoryData
end

function mainapi:CreateToggle(categoryName, moduleName, options)
    local categoryData = mainapi.Categories[categoryName]
    if not categoryData or not categoryData.UI.ContentFrame then warn("Category/UI not found for toggle:", categoryName); return end
    options = options or {}

    if not mainapi.Modules[moduleName] then mainapi.Modules[moduleName] = {} end
    local moduleData = mainapi.Modules[moduleName]
    moduleData.Enabled = moduleData.Enabled or options.DefaultValue or false -- Load default if not already set

    local toggleFrame = Instance.new("Frame"); toggleFrame.Name = moduleName .. "Toggle"; toggleFrame.Size = UDim2.new(1, 0, 0, 35); -- Use padding on content frame instead of -10 here
    toggleFrame.BackgroundColor3 = color.Dark(uipallet.Main, 0.05); toggleFrame.BorderSizePixel = 0; toggleFrame.LayoutOrder = options.Order or (#categoryData.UI.ContentFrame:GetChildren() + 1); toggleFrame.Parent = categoryData.UI.ContentFrame; addCorner(toggleFrame, UDim.new(0, 4))

    local nameLabel = Instance.new("TextLabel"); nameLabel.Name = "NameLabel"; nameLabel.Size = UDim2.new(0.8, -30, 1, 0); nameLabel.Position = UDim2.fromOffset(10, 0); nameLabel.BackgroundTransparency = 1; nameLabel.Font = uipallet.Font; nameLabel.TextColor3 = uipallet.Text; nameLabel.TextSize = 14; nameLabel.Text = moduleName; nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.Parent = toggleFrame

    local toggleButton = Instance.new("TextButton"); toggleButton.Name = "Switch"; toggleButton.Size = UDim2.new(0, 50, 0, 20); toggleButton.Position = UDim2.new(1, -65, 0.5, 0); toggleButton.AnchorPoint = Vector2.new(1, 0.5); toggleButton.Font = uipallet.Font; toggleButton.Text = ""; toggleButton.AutoButtonColor = false; toggleButton.Parent = toggleFrame; addCorner(toggleButton, UDim.new(0.5, 0))

    local function updateToggleVisual(isInitial)
        local targetColor = moduleData.Enabled and uipallet.MainColor or color.Light(uipallet.Main, 0.1)
        local tweenInfo = isInitial and TweenInfo.new(0) or uipallet.Tween
        createTween(toggleButton, { BackgroundColor3 = targetColor }, tweenInfo)
        toggleButton.Text = moduleData.Enabled and "ON" or "OFF"
        toggleButton.TextColor3 = moduleData.Enabled and uipallet.Text or color.Light(uipallet.Text, -0.3)
        toggleButton.TextSize = 10
    end

    moduleData._uiToggleButton = toggleButton
    moduleData._updateVisual = updateToggleVisual
    updateToggleVisual(true) -- Set initial visual state based on loaded/default data

    toggleButton.MouseButton1Click:Connect(function()
        moduleData.Enabled = not moduleData.Enabled
        updateToggleVisual(false)
        if options.Callback then options.Callback(moduleData.Enabled) end
    end)

    local settingsButton = Instance.new("ImageButton"); settingsButton.Name = "SettingsButton"; settingsButton.Size = UDim2.fromOffset(15, 15); settingsButton.Position = UDim2.new(1, -15, 0.5, 0); settingsButton.AnchorPoint = Vector2.new(1, 0.5); settingsButton.BackgroundTransparency = 1; settingsButton.Image = getcustomasset('Meteor_/assets/settings_dots.png'); settingsButton.Visible = false; settingsButton.Parent = toggleFrame;
    settingsButton.MouseButton1Click:Connect(function() print("Settings:", moduleName) end)

    toggleFrame.MouseEnter:Connect(function() showTooltip(options.Tooltip or moduleName, toggleFrame) end)
    toggleFrame.MouseLeave:Connect(hideTooltip)

    mainapi._uiElements["Module_"..moduleName] = { Frame = toggleFrame, Button = toggleButton, Settings = settingsButton }

    return toggleFrame, moduleData
end

function mainapi:CreateLabel(categoryName, text, options)
    local categoryData = mainapi.Categories[categoryName]
    if not categoryData or not categoryData.UI.ContentFrame then warn("Category/UI not found for label:", categoryName); return end
    options = options or {}

    local label = Instance.new("TextLabel"); label.Name = (text:gsub("%s+", ""):sub(1,10)) .. "Label"; label.Size = UDim2.new(1, 0, 0, 0); -- Use padding on content frame
    label.AutomaticSize = Enum.AutomaticSize.Y; label.BackgroundTransparency = 1; label.Font = options.Font or uipallet.Font; label.TextColor3 = options.Color or uipallet.Text; label.TextSize = options.Size or 14; label.Text = text; label.TextXAlignment = options.Align or Enum.TextXAlignment.Left; label.TextWrapped = options.Wrapped or true; label.LayoutOrder = options.Order or (#categoryData.UI.ContentFrame:GetChildren() + 1); label.Parent = categoryData.UI.ContentFrame
    mainapi._uiElements["Label_"..label.Name] = label

    return label
end

---[[ Config Saving/Loading ]]--
local function getSafeProfileName()
    local name = shared.MeteorCustomProfile or mainapi.Profile or 'default'
    return name:gsub("[^%w_%.%-]", "_")
end

function mainapi:SaveConfig()
    if not mainapi.Loaded then return end -- Don't save if not fully initialized
    local configData = {
        Version = mainapi.Version, Keybind = mainapi.Keybind, GUIColor = mainapi.GUIColor,
        Scale = mainapi.Scale and mainapi.Scale.Scale or 1,
        NotificationsEnabled = mainapi.Notifications.Enabled,
        ToggleNotificationsEnabled = mainapi.ToggleNotifications.Enabled,
        CurrentTheme = mainapi.CurrentTheme or 'Water', Modules = {}
    }

    for moduleName, moduleData in pairs(mainapi.Modules) do
        if type(moduleData) == 'table' then
            local moduleSaveData = {}
            if moduleData.Enabled ~= nil then moduleSaveData.Enabled = moduleData.Enabled end
            -- Add saving for other types (slider values, dropdown index, etc.) here
            if next(moduleSaveData) then configData.Modules[moduleName] = moduleSaveData end
        end
    end

    local success, encoded = pcall(httpService.JSONEncode, httpService, configData)
    if success then
        local filePath = 'Meteor_/profiles/' .. getSafeProfileName() .. '.json'
        if not isfolder('Meteor_/profiles') then makefolder('Meteor_/profiles') end
        local writeSuccess = pcall(writefile, filePath, encoded) -- Use pcall for writefile
        if not writeSuccess then
            mainapi:CreateNotification('Save Error', 'Failed to write config file!', 10, 'alert')
        end
        pcall(writefile, 'Meteor_/profiles/current_theme.txt', mainapi.CurrentTheme or 'Water')
    else
        mainapi:CreateNotification('Save Error', 'Failed to encode config: '..tostring(encoded), 10, 'alert')
    end
end

function mainapi:LoadConfig()
    local profileName = getSafeProfileName()
    local filePath = 'Meteor_/profiles/' .. profileName .. '.json'

    -- Load Theme first from separate file
    local loadedTheme = "Water"
    local themeSuc, themeName = pcall(readfile, 'Meteor_/profiles/current_theme.txt')
    if themeSuc and themeName and themeName ~= "" and uipallet.Themes[themeName] then loadedTheme = themeName end
    mainapi:ApplyTheme(loadedTheme) -- Apply theme regardless of main config status

    -- Load main config file
    if not isfile(filePath) then print("MeteorClient: No config file for profile '"..profileName.."'."); return end
    local readSuc, fileContent = pcall(readfile, filePath)
    if not readSuc or not fileContent or fileContent == "" then warn("MeteorClient: Failed read/empty config:", filePath); return end

    local decodeSuc, decodedData = pcall(httpService.JSONDecode, httpService, fileContent)
    if not decodeSuc or type(decodedData) ~= 'table' then mainapi:CreateNotification('Load Error','Decode fail: '..tostring(decodedData),10,'alert'); return end

    -- Apply loaded settings
    mainapi.Keybind = type(decodedData.Keybind)=='table' and decodedData.Keybind or mainapi.Keybind
    mainapi.GUIColor = type(decodedData.GUIColor)=='table' and decodedData.GUIColor or mainapi.GUIColor
    if mainapi.Scale and type(decodedData.Scale)=='number' then mainapi.Scale.Scale=decodedData.Scale end
    mainapi.Notifications.Enabled = type(decodedData.NotificationsEnabled)=='boolean' and decodedData.NotificationsEnabled or mainapi.Notifications.Enabled
    mainapi.ToggleNotifications.Enabled = type(decodedData.ToggleNotificationsEnabled)=='boolean' and decodedData.ToggleNotificationsEnabled or mainapi.ToggleNotifications.Enabled

    -- Apply Theme from config if different from .txt file
    if type(decodedData.CurrentTheme)=='string' and decodedData.CurrentTheme~=loadedTheme and uipallet.Themes[decodedData.CurrentTheme] then
         mainapi:ApplyTheme(decodedData.CurrentTheme)
    end

    -- Apply module settings
    if type(decodedData.Modules) == 'table' then
        for moduleName, moduleConfig in pairs(decodedData.Modules) do
            if not mainapi.Modules[moduleName] then mainapi.Modules[moduleName] = {} end -- Ensure exists
            local moduleData = mainapi.Modules[moduleName]
            if type(moduleConfig)=='table' and moduleData then
                if moduleConfig.Enabled~=nil then moduleData.Enabled = moduleConfig.Enabled end
                -- Load other options here...
                -- Update visuals AFTER main script has potentially created the UI elements
                if moduleData._updateVisual then task.defer(moduleData._updateVisual, moduleData, true) end -- Defer update
            end
        end
    end
    print("MeteorClient: Config loaded for profile '"..profileName.."'.")
end

---[[ Mobile Dragging Setup ]]--
local function setupDragging(dragFrame, handle)
    local dragging = false; local dragInput=nil; local startPos=nil; local startGuiPos=nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            local mouseLoc = input.Position; local hPos=handle.AbsolutePosition; local hSize=handle.AbsoluteSize
            if mouseLoc.X>=hPos.X and mouseLoc.X<=hPos.X+hSize.X and mouseLoc.Y>=hPos.Y and mouseLoc.Y<=hPos.Y+hSize.Y then
                 local consumed=false; for _,d in ipairs(handle:GetDescendants()) do if d:IsA("GuiButton") and d.Active then local bP=d.AbsolutePosition; local bS=d.AbsoluteSize; if mouseLoc.X>=bP.X and mouseLoc.X<=bP.X+bS.X and mouseLoc.Y>=bP.Y and mouseLoc.Y<=bP.Y+bS.Y then consumed=true; break end end end
                 if not consumed then dragging=true; dragInput=input; startPos=input.Position; startGuiPos=dragFrame.Position end
            end
        end
    end)
    inputService.InputChanged:Connect(function(input) if dragging and dragInput and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then local delta=input.Position-startPos; dragFrame.Position=UDim2.new(startGuiPos.X.Scale,startGuiPos.X.Offset+delta.X, startGuiPos.Y.Scale,startGuiPos.Y.Offset+delta.Y) end end)
    inputService.InputEnded:Connect(function(input) if dragging and dragInput and input==dragInput then dragging=false; dragInput=nil end end)
end

---[[ Uninjection (GUI Specific) ]]--
function mainapi:UninjectGUI()
    print("MeteorClient: Uninjecting GUI...")
    if mainframe and mainframe.Parent then
        local hideTween = createTween(mainframe, {GroupTransparency = 1}, TweenInfo.new(0.1))
        hideTween.Completed:Connect(function()
            if gui and gui.Parent then gui:Destroy() end
            -- Clear local references and tables to aid GC
            gui=nil; scaledgui=nil; clickgui=nil; modal=nil; cursor=nil; notifications=nil; tooltip=nil; toolblur=nil; toolstroke=nil; loadingFrame=nil; loadingText=nil; mainframe=nil; mainscale=nil; sidebar=nil; categoryholder=nil; categoryhighlight=nil; contentFrame=nil; lastSelectedCategoryButton=nil; mainGuiScale=nil; activeNotifications={}; activeTweens={}
            mainapi.gui = nil; mainapi.Scale = nil; mainapi._uiElements = {}; mainapi.Categories = {}; uipallet.ThemeObjects = {}
            print("MeteorClient: GUI Destroyed.")
        end)
    elseif gui and gui.Parent then
         gui:Destroy() -- Destroy immediately if mainframe wasn't visible
         print("MeteorClient: GUI Destroyed (no tween).")
    end
end

-- Initialize GUI components when script runs
setupGui()

-- Return the API table for the main script
return mainapi
