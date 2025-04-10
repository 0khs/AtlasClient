-- Credit : 7GrandDadPGN for the inspiration
local mainapi = {
    Categories = {},
    HeldKeybinds = {},
    Keybind = {'RightShift'},
    Loaded = false,
    Libraries = {},
    Modules = {},
    Place = game and game.PlaceId or 0,
    Profile = 'default',
    Profiles = {},
    Scale = {Value = 1},
    Version = '1.0.0',
    guiscale = nil
}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui", 60)

local guiParent = CoreGui or PlayerGui

local uipallet = {
    Main = Color3.fromRGB(20, 20, 20),
    MainDarker = Color3.fromRGB(15, 15, 15),
    MainLighter = Color3.fromRGB(30, 30, 30),
    MainColor = Color3.fromRGB(0, 191, 255),
    Text = Color3.new(1, 1, 1),
    TextSecondary = Color3.fromRGB(180, 180, 180),
    Tween = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    FontEnum = Enum.Font.SourceSans,
    FontBoldEnum = Enum.Font.SourceSansBold,
    Themes = {
        Aubergine={{Color3.fromRGB(170,7,107),Color3.fromRGB(97,4,95)},1,8},
        Aqua={{Color3.fromRGB(185,250,255),Color3.fromRGB(79,199,200)},6},
        Banana={{Color3.fromRGB(253,236,177),Color3.fromRGB(255,255,255)},3},
        Blend={{Color3.fromRGB(71,148,253),Color3.fromRGB(71,253,160)},4,6},
        Blossom={{Color3.fromRGB(226,208,249),Color3.fromRGB(49,119,115)},9,10},
        Bubblegum={{Color3.fromRGB(243,145,216),Color3.fromRGB(152,165,243)},8,9},
        ['Candy Cane']={{Color3.fromRGB(255,0,0),Color3.fromRGB(255,255,255)},1},
        Cherry={{Color3.fromRGB(187,55,125),Color3.fromRGB(251,211,233)},1,8,9},
        Christmas={{Color3.fromRGB(255,64,64),Color3.fromRGB(255,255,255),Color3.fromRGB(64,255,64)},1,4},
        Coral={{Color3.fromRGB(244,168,150),Color3.fromRGB(52,133,151)},2,7,9},
        Creida={{Color3.fromRGB(156,164,224),Color3.fromRGB(54,57,78)},10},
        ['Creida Two']={{Color3.fromRGB(154,202,235),Color3.fromRGB(88,130,161)},10},
        ['Digital Horizon']={{Color3.fromRGB(95,195,228),Color3.fromRGB(229,93,135)},1,6,9},
        Express={{Color3.fromRGB(173,83,137),Color3.fromRGB(60,16,83)},8,9},
        Gothic={{Color3.fromRGB(31,30,30),Color3.fromRGB(196,190,190)},10},
        Halogen={{Color3.fromRGB(255,65,108),Color3.fromRGB(255,75,43)},1,2},
        Hyper={{Color3.fromRGB(236,110,173),Color3.fromRGB(52,148,230)},6,7,9},
        Legacy={{Color3.fromRGB(112,206,255),Color3.fromRGB(112,206,255)},6,7},
        ['Lime Water']={{Color3.fromRGB(18,255,247),Color3.fromRGB(179,255,171)},4,6},
        Lush={{Color3.fromRGB(168,224,99),Color3.fromRGB(86,171,47)},4,5},
        Magic={{Color3.fromRGB(74,0,224),Color3.fromRGB(142,45,226)},7,8},
        May={{Color3.fromRGB(170,7,107),Color3.fromRGB(238,79,238)},8,9},
        ['Orange Juice']={{Color3.fromRGB(252,74,26),Color3.fromRGB(247,183,51)},2,3},
        Pastel={{Color3.fromRGB(243,155,178),Color3.fromRGB(207,196,243)},9},
        Peony={{Color3.fromRGB(226,208,249),Color3.fromRGB(207,171,255)},9,10},
        Pumpkin={{Color3.fromRGB(241,166,98),Color3.fromRGB(255,216,169),Color3.fromRGB(227,139,42)},2},
        Purple={{Color3.fromRGB(82,67,145),Color3.fromRGB(117,95,207)},8},
        Rainbow={{Color3.new(1,1,1),Color3.new(1,1,1)},10},
        Rue={{Color3.fromRGB(234,118,176),Color3.fromRGB(31,30,30)},9},
        Satin={{Color3.fromRGB(215,60,67),Color3.fromRGB(140,23,39)},1},
        blur={{Color3.fromRGB(97,131,255),Color3.fromRGB(206,212,255)},6},
        ['Snowy Sky']={{Color3.fromRGB(1,171,179),Color3.fromRGB(234,234,234),Color3.fromRGB(18,232,232)},6,10},
        ['Steel Fade']={{Color3.fromRGB(66,134,244),Color3.fromRGB(55,59,68)},7,10},
        Sundae={{Color3.fromRGB(206,74,126),Color3.fromRGB(122,44,77)},1,8,9},
        Sunkist={{Color3.fromRGB(242,201,76),Color3.fromRGB(242,153,74)},2,3},
        Water={{Color3.fromRGB(12,232,199),Color3.fromRGB(12,163,232)},6,7},
        Winter={{Color3.new(1,1,1),Color3.new(1,1,1)},10},
        Wood={{Color3.fromRGB(79,109,81),Color3.fromRGB(170,139,87),Color3.fromRGB(240,235,206)},5}
    }, ThemeObjects = {}
}

local AssetShit = {
    ['Atlas/assets/blur.png'] = 'rbxassetid://13350795660',
    ['Atlas/assets/alert.png'] = 'rbxassetid://14368301329',
    ['Atlas/assets/info.png'] = 'rbxassetid://14368324807',
    ['Atlas/assets/warning.png'] = 'rbxassetid://14368361552',
    ['Atlas/assets/AtlasLogo.png'] = 'rbxassetid://90453558240560',
    ['Atlas/assets/AtlasLogoText.png'] = 'rbxassetid://129311486422203'
}

local getcustomasset = getcustomasset or function(path) return AssetShit[path] end

local function addBlur(parent)
    local blurEffect = Instance.new("BlurEffect")
    blurEffect.Name = "ScreenBlur"
    blurEffect.Size = 40
    blurEffect.Parent = game.Lighting

    local blurFrame = Instance.new("Frame")
    blurFrame.Name = "BlurFrame"
    blurFrame.Size = UDim2.fromScale(1, 1)
    blurFrame.BackgroundTransparency = 1
    blurFrame.ZIndex = -1
    blurFrame.Parent = parent

    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0))
    uiGradient.Transparency = NumberSequence.new(0.2, 0.5)
    uiGradient.Parent = blurFrame

    return blurEffect, blurFrame
end

local function addCorner(parent, radius)
    local corner = Instance.new('UICorner')
    corner.Name = "UICorner"
    corner.CornerRadius = radius or UDim.new(0, 5)
    corner.Parent = parent
    return corner
end

local function addPadding(parent, paddingValues)
    local padding = Instance.new("UIPadding")
    padding.Name = "UIPadding"
    padding.PaddingTop = paddingValues.Top or UDim.new(0, 0)
    padding.PaddingBottom = paddingValues.Bottom or UDim.new(0, 0)
    padding.PaddingLeft = paddingValues.Left or UDim.new(0, 0)
    padding.PaddingRight = paddingValues.Right or UDim.new(0, 0)
    padding.Parent = parent
    return padding
end

function makeDragable(handle, targetFrame)
    local dragging, dragInput, startPos, startInputPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInputPos = input.Position
            startPos = targetFrame.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connection then
                        connection:Disconnect()
                        connection = nil
                    end
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - startInputPos
            targetFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function CreateLabel(text, size, parent)
    local Label = Instance.new("TextLabel")
    Label.Name = "LabelLol"
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.Text = text or "Default Text"
    Label.TextColor3 = uipallet.Text
    Label.Font = uipallet.FontEnum
    Label.TextSize = size or 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextYAlignment = Enum.TextYAlignment.Center
    Label.BackgroundTransparency = 1
    Label.ZIndex = 4
    if parent then
        Label.Parent = parent
    end
    return Label
end


local guiName = "AtlasGui455"
local oldGui = guiParent:FindFirstChild(guiName)
if oldGui then oldGui:Destroy(); task.wait(0.1) end

local gui = Instance.new("ScreenGui")
gui.Name = guiName
gui.DisplayOrder = 2147483647
gui.Enabled = true
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = guiParent

local scaledgui = Instance.new("Frame")
scaledgui.Name = "ScaledContainer"
scaledgui.BackgroundTransparency = 1
scaledgui.Size = UDim2.fromScale(1, 1)
scaledgui.Position = UDim2.fromScale(0.5, 0.5)
scaledgui.AnchorPoint = Vector2.new(0.5, 0.5)
scaledgui.Visible = true
scaledgui.Parent = gui
local screenBlur, blurFrame = addBlur(gui) -- Capture blur instance

local scale = Instance.new('UIScale')
scale.Scale = 0.7
scale.Parent = scaledgui
mainapi.guiscale = scale

local clickgui = Instance.new("Frame")
clickgui.Name = "ClickGuiContainer"
clickgui.Size = UDim2.fromScale(1, 1)
clickgui.BackgroundTransparency = 1
clickgui.Visible = true
clickgui.Parent = scaledgui

local mainframe = Instance.new('CanvasGroup')
mainframe.Name = "MainFrame"
mainframe.Size = UDim2.fromOffset(650, 400)
mainframe.Position = UDim2.fromScale(0.5, 0.5)
mainframe.AnchorPoint = Vector2.new(0.5, 0.5)
mainframe.BackgroundColor3 = uipallet.Main
mainframe.GroupTransparency = 1 -- Start hidden
mainframe.BorderSizePixel = 0
mainframe.Visible = false -- Start not visible
mainframe.ZIndex = 2
mainframe.Parent = clickgui
addCorner(mainframe, UDim.new(0, 5)) -- This applies the corner to the main frame container

local mainHeader = Instance.new('Frame')
mainHeader.Name = "mainHeader"
mainHeader.Size = UDim2.new(1, 0, 0, 40)
mainHeader.Position = UDim2.new(0, 0, 0, 0)
mainHeader.BackgroundColor3 = uipallet.MainDarker
mainHeader.BorderSizePixel = 0
mainHeader.ZIndex = 3
mainHeader.Parent = mainframe

addPadding(mainHeader, {Left=UDim.new(0,10)})

local headerLayout = Instance.new("UIListLayout")
headerLayout.Name = "HeaderLayout"
headerLayout.FillDirection = Enum.FillDirection.Horizontal
headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
headerLayout.Padding = UDim.new(0, 5)
headerLayout.Parent = mainHeader

makeDragable(mainHeader, mainframe)

local sidebarWidth = 270
local sidebar = Instance.new('Frame')
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, sidebarWidth, 1, -mainHeader.Size.Y.Offset)
sidebar.Position = UDim2.new(0, 0, 0, mainHeader.Size.Y.Offset)
sidebar.BackgroundColor3 = uipallet.MainDarker
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 4
sidebar.Parent = mainframe

local sidebarPadding = addPadding(sidebar, {Left=UDim.new(0,10), Right=UDim.new(0,10), Top=UDim.new(0,10), Bottom=UDim.new(0,10)})

local swatermark = Instance.new('ImageLabel')
swatermark.Name = "SWatermarkLogo"
swatermark.Image = AssetShit['Atlas/assets/AtlasLogo.png']
local logoSize = mainHeader.Size.Y.Offset * 0.8
swatermark.Size = UDim2.fromOffset(logoSize, logoSize)
swatermark.BackgroundTransparency = 1
swatermark.ZIndex = 6
swatermark.LayoutOrder = 1
swatermark.Parent = mainHeader

local swatermarktext = Instance.new('TextLabel')
swatermarktext.Name = "SWatermarkText"
swatermarktext.Text = "Atlas Client V" .. mainapi.Version
swatermarktext.Font = Enum.Font.SciFi
swatermarktext.Size = UDim2.new(0, 0, 1, 0)
swatermarktext.AutomaticSize = Enum.AutomaticSize.X
swatermarktext.TextColor3 = Color3.new(1, 1, 1)
swatermarktext.TextScaled = false
swatermarktext.TextSize = 16
swatermarktext.TextXAlignment = Enum.TextXAlignment.Left
swatermarktext.TextYAlignment = Enum.TextYAlignment.Center
swatermarktext.BackgroundTransparency = 1
swatermarktext.ZIndex = 6
swatermarktext.LayoutOrder = 2
swatermarktext.Parent = mainHeader

local categoryholder = Instance.new("Frame")
categoryholder.Name = "CategoryHolder"
categoryholder.Size = UDim2.fromScale(1, 1)
categoryholder.Position = UDim2.fromScale(0, 0)
categoryholder.ZIndex = 5
categoryholder.BackgroundTransparency = 1
categoryholder.Parent = sidebar

local contentholder = Instance.new("Frame")
contentholder.Name = "ContentHolder"
local contentWidth = mainframe.Size.X.Offset - sidebarWidth
contentholder.Size = UDim2.new(0, contentWidth, 1, -mainHeader.Size.Y.Offset)
contentholder.Position = UDim2.new(0, sidebarWidth, 0, mainHeader.Size.Y.Offset)
contentholder.ZIndex = 3
contentholder.BackgroundTransparency = 1
contentholder.Parent = mainframe

local contentPadding = addPadding(contentholder, {Left=UDim.new(0,10), Right=UDim.new(0,10), Top=UDim.new(0,10), Bottom=UDim.new(0,10)})

local contentLayout = Instance.new("UIListLayout")
contentLayout.Name = "ContentLayout"
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 5)
contentLayout.Parent = contentholder

-- Example usage:
local myLabel = CreateLabel("This is a test label", nil, contentholder)
local anotherLabel = CreateLabel("Another one", 20, contentholder)

-- Toggle visibility on keybind press
local function toggleGui()
    local isVisible = mainframe.Visible
    local targetTransparency = isVisible and 1 or 0
    local targetVisibility = not isVisible

    screenBlur.Enabled = targetVisibility -- Enable/disable blur with UI

    if targetVisibility then
        mainframe.Visible = true
        
    if mainframe.GroupTransparency == 1 then -- Check if fully faded out
                 mainframe.Visible = false
            end
        end)
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    local key = input.KeyCode
    local keyName = key.Name

    local isKeybind = false
    for _, bind in ipairs(mainapi.Keybind) do
        if keyName == bind then
            isKeybind = true
            break
        end
    end

    if isKeybind then
        toggleGui()
    end
end)

-- Clean up blur effect if GUI is destroyed
gui.Destroying:Connect(function()
    if screenBlur and screenBlur.Parent then
        screenBlur:Destroy()
    end
    if blurFrame and blurFrame.Parent then
        blurFrame:Destroy()
    end
end)

return mainapi