
local inputService   = game:GetService("UserInputService")
local runService     = game:GetService("RunService")
local tweenService   = game:GetService("TweenService")
local players        = game:GetService("Players")
local localPlayer    = players.LocalPlayer
local mouse          = localPlayer:GetMouse()

local menu           = game:GetObjects("rbxassetid://12702460854")[1]
local uiScale = Instance.new("UIScale")
uiScale.Scale = 0.85
uiScale.Parent = menu.bg
menu.bg.Position     = UDim2.new(0.5, -(menu.bg.Size.X.Offset * 0.85)/2, 0.5, -(menu.bg.Size.Y.Offset * 0.85)/2)
menu.Parent          = game:GetService("CoreGui")
local library = {cheatname = "";ext = "";gamename = "";colorpicking = false;tabbuttons = {};tabs = {};tabsData = {};options = {};flags = {};scrolling = false;playing = false;multiZindex = 200;toInvis = {};libColor = Color3.fromRGB(133, 115, 173);disabledcolor = Color3.fromRGB(233, 0, 0);blacklisted = {Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.UserInputType.MouseMovement};accentElements = {};onAccentChanged = {};copiedColor = nil}

local function clamp(val, lo, hi)
    if val < lo then return lo end
    if val > hi then return hi end
    return val
end

local function colorToHex(color)
    local r = clamp(math.floor(color.R * 255 + 0.5), 0, 255)
    local g = clamp(math.floor(color.G * 255 + 0.5), 0, 255)
    local b = clamp(math.floor(color.B * 255 + 0.5), 0, 255)
    return string.format("#%02x%02x%02x", r, g, b)
end

local cachedGameName = nil
local fetchingGameName = false

local function updateTitle()
    local hex = colorToHex(library.libColor)
    if library.flags["show game name"] then
        if cachedGameName then
            menu.bg.pre.Text = 'swag<font color="' .. hex .. '">.pro</font> | ' .. cachedGameName
        else
            menu.bg.pre.Text = 'swag<font color="' .. hex .. '">.pro</font> | Loading...'
            if not fetchingGameName then
                fetchingGameName = true
                spawn(function()
                    pcall(function()
                        cachedGameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
                    end)
                    cachedGameName = cachedGameName or "Unknown"
                    updateTitle()
                end)
            end
        end
    else
        menu.bg.pre.Text = 'swag<font color="' .. hex .. '">.pro</font>'
    end
end

local accentDebounce = false
local pendingAccentColor = nil

local function updateAccentColor(newColor)
    library.libColor = newColor
    -- Always update the title and direct element properties immediately (cheap)
    updateTitle()
    for _, entry in next, library.accentElements do
        if entry.obj and entry.obj.Parent then
            pcall(function()
                entry.obj[entry.prop] = newColor
            end)
        end
    end
    -- Throttle the heavier callbacks (toggles, configbox recolors) to avoid lag during dragging
    if accentDebounce then
        pendingAccentColor = newColor
        return
    end
    accentDebounce = true
    for _, fn in next, library.onAccentChanged do
        pcall(fn, newColor)
    end
    spawn(function()
        wait(0.05)
        accentDebounce = false
        if pendingAccentColor then
            local queued = pendingAccentColor
            pendingAccentColor = nil
            for _, fn in next, library.onAccentChanged do
                pcall(fn, queued)
            end
        end
    end)
end

local function colorToHSV(color)
    local r, g, b = color.R, color.G, color.B
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, v = 0, 0, max
    local d = max - min
    s = max == 0 and 0 or d / max
    if max ~= min then
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    return h, s, v
end

local function hueToColor(hue)
    local colors = {Color3.new(1,0,0),Color3.new(1,1,0),Color3.new(0,1,0),Color3.new(0,1,1),Color3.new(0,0,1),Color3.new(1,0,1),Color3.new(1,0,0)}
    local pos = hue * 6 + 1
    pos = math.max(1, math.min(7, pos))
    local idx = math.floor(pos)
    local frac = pos - idx
    if idx >= 7 then return colors[7] end
    return colors[idx]:Lerp(colors[idx + 1], frac)
end

updateTitle()

function draggable(a)local b=inputService;local c;local d;local e;local f;local function g(h)if not library.colorpicking then local i=h.Position-e;a.Position=UDim2.new(f.X.Scale,f.X.Offset+i.X,f.Y.Scale,f.Y.Offset+i.Y)end end;a.InputBegan:Connect(function(h)if h.UserInputType==Enum.UserInputType.MouseButton1 or h.UserInputType==Enum.UserInputType.Touch then c=true;e=h.Position;f=a.Position;h.Changed:Connect(function()if h.UserInputState==Enum.UserInputState.End then c=false end end)end end)a.InputChanged:Connect(function(h)if h.UserInputType==Enum.UserInputType.MouseMovement or h.UserInputType==Enum.UserInputType.Touch then d=h end end)b.InputChanged:Connect(function(h)if h==d and c then g(h)end end)end
draggable(menu.bg)

local tabholder = menu.bg.bg.bg.bg.main.group
local tabviewer = menu.bg.bg.bg.bg.tabbuttons



local menuKeybind = Enum.KeyCode.RightShift
local function toggleMenu()
    menu.Enabled = not menu.Enabled
    library.scrolling = false
    library.colorpicking = false
    for i,v in next, library.toInvis do
        v.Visible = false
    end
end

inputService.InputEnded:Connect(function(key)
    local k = key.KeyCode == Enum.KeyCode.Unknown and key.UserInputType or key.KeyCode
    if k == library.flags["MenuKeybind"] then
        toggleMenu()
    end
end)

local keyNames = {
    [Enum.KeyCode.LeftAlt] = 'LALT';
    [Enum.KeyCode.RightAlt] = 'RALT';
    [Enum.KeyCode.LeftControl] = 'LCTRL';
    [Enum.KeyCode.RightControl] = 'RCTRL';
    [Enum.KeyCode.LeftShift] = 'LSHIFT';
    [Enum.KeyCode.RightShift] = 'RSHIFT';
    [Enum.KeyCode.Underscore] = '_';
    [Enum.KeyCode.Minus] = '-';
    [Enum.KeyCode.Plus] = '+';
    [Enum.KeyCode.Period] = '.';
    [Enum.KeyCode.Slash] = '/';
    [Enum.KeyCode.BackSlash] = '\\';
    [Enum.KeyCode.Question] = '?';
    [Enum.UserInputType.MouseButton1] = 'MB1';
    [Enum.UserInputType.MouseButton2] = 'MB2';
    [Enum.UserInputType.MouseButton3] = 'MB3';
}
pcall(function() keyNames[Enum.UserInputType.MouseButton4] = 'MB4' end)
pcall(function() keyNames[Enum.UserInputType.MouseButton5] = 'MB5' end)

function library:Tween(...)
    tweenService:Create(...):Play()
end

-- Color context menu (right-click copy/paste)
library._colorCtxMenu = nil
function library:showColorContextMenu(input, flag, applyCallback)
    -- Destroy previous context menu and overlay if any
    if library._colorCtxMenu and library._colorCtxMenu.Parent then
        library._colorCtxMenu:Destroy()
    end
    if library._colorCtxOverlay and library._colorCtxOverlay.Parent then
        library._colorCtxOverlay:Destroy()
    end

    local mousePos = inputService:GetMouseLocation()
    local ctxGui = game:GetService("CoreGui"):FindFirstChild("Swag_Notifications")
    if not ctxGui then return end

    -- Full-screen transparent overlay to catch clicks outside the menu
    local overlay = Instance.new("TextButton")
    overlay.Name = "ContextMenuOverlay"
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.ZIndex = 9998
    overlay.Text = ""
    overlay.Parent = ctxGui
    library._colorCtxOverlay = overlay

    local ctx = Instance.new("Frame")
    ctx.Name = "ColorContextMenu"
    ctx.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    ctx.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ctx.BorderSizePixel = 2
    ctx.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y - 36)
    ctx.Size = UDim2.new(0, 90, 0, 40)
    ctx.ZIndex = 9999
    ctx.Parent = ctxGui
    library._colorCtxMenu = ctx

    local function closeMenu()
        if ctx.Parent then ctx:Destroy() end
        if overlay.Parent then overlay:Destroy() end
    end

    local inner = Instance.new("Frame")
    inner.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    inner.BorderColor3 = Color3.fromRGB(40, 40, 40)
    inner.Size = UDim2.new(1, 0, 1, 0)
    inner.ZIndex = 10000
    inner.Parent = ctx

    local function makeOption(text, yPos, onClick)
        local btn = Instance.new("TextButton")
        btn.BackgroundTransparency = 1
        btn.Size = UDim2.new(1, 0, 0, 20)
        btn.Position = UDim2.new(0, 0, 0, yPos)
        btn.Font = Enum.Font.Code
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 12
        btn.TextStrokeTransparency = 0
        btn.ZIndex = 10001
        btn.Parent = inner

        btn.MouseEnter:Connect(function()
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundTransparency = 0.85
            btn.BackgroundColor3 = library.libColor
        end)
        btn.MouseLeave:Connect(function()
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.BackgroundTransparency = 1
        end)
        btn.MouseButton1Click:Connect(function()
            onClick()
            closeMenu()
        end)
    end

    makeOption("Copy Color", 0, function()
        local c = library.flags[flag]
        if c and typeof(c) == "Color3" then
            library.copiedColor = c
            library:notify("Color copied.")
        end
    end)

    makeOption("Paste Color", 20, function()
        if library.copiedColor and typeof(library.copiedColor) == "Color3" then
            library.flags[flag] = library.copiedColor
            if applyCallback then applyCallback(library.copiedColor) end
            library:notify("Color pasted.")
        else
            library:notify("No color copied yet.")
        end
    end)

    -- Close when clicking the overlay (anywhere outside the menu)
    overlay.MouseButton1Click:Connect(closeMenu)
    overlay.MouseButton2Click:Connect(closeMenu)
end

-- Keybind context menu (Always/Toggle/Hold)
library._keybindCtxMenu = nil
function library:showKeybindContextMenu(input, flag, applyCallback)
    if library._keybindCtxMenu and library._keybindCtxMenu.Parent then
        library._keybindCtxMenu:Destroy()
    end
    if library._ctxOverlay and library._ctxOverlay.Parent then
        library._ctxOverlay:Destroy()
    end

    local mousePos = inputService:GetMouseLocation()
    local ctxGui = game:GetService("CoreGui"):FindFirstChild("Swag_Notifications")
    if not ctxGui then return end

    local overlay = Instance.new("TextButton")
    overlay.Name = "ContextMenuOverlay"
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.ZIndex = 9998
    overlay.Text = ""
    overlay.Parent = ctxGui
    library._ctxOverlay = overlay

    local ctx = Instance.new("Frame")
    ctx.Name = "KeybindContextMenu"
    ctx.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    ctx.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ctx.BorderSizePixel = 2
    ctx.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y - 36)
    ctx.Size = UDim2.new(0, 90, 0, 60)
    ctx.ZIndex = 9999
    ctx.Parent = ctxGui
    library._keybindCtxMenu = ctx

    local inner = Instance.new("Frame")
    inner.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    inner.BorderColor3 = Color3.fromRGB(40, 40, 40)
    inner.Size = UDim2.new(1, 0, 1, 0)
    inner.ZIndex = 10000
    inner.Parent = ctx
    
    local function closeMenu()
        if overlay then overlay:Destroy() end
        if ctx then ctx:Destroy() end
    end

    local function makeOption(text, yPos, onClick)
        local btn = Instance.new("TextButton")
        btn.BackgroundTransparency = 1
        btn.Size = UDim2.new(1, 0, 0, 20)
        btn.Position = UDim2.new(0, 0, 0, yPos)
        btn.Font = Enum.Font.Code
        btn.Text = "  " .. text
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 12
        btn.ZIndex = 10001
        btn.Parent = inner

        btn.MouseEnter:Connect(function()
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundTransparency = 0.85
            btn.BackgroundColor3 = library.libColor
        end)
        btn.MouseLeave:Connect(function()
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.BackgroundTransparency = 1
        end)
        btn.MouseButton1Click:Connect(function()
            onClick()
            closeMenu()
        end)
    end
    
    local modes = {"Always", "Toggle", "Hold"}
    for i, mode in ipairs(modes) do
        makeOption(mode, (i-1) * 20, function()
            if applyCallback then applyCallback(mode) end
        end)
    end

    overlay.MouseButton1Click:Connect(closeMenu)
    overlay.MouseButton2Click:Connect(closeMenu)
end

-- Colorpicker context menu (Copy/Paste Color)
library.copiedColor = Color3.fromRGB(255, 255, 255)
function library:showColorContextMenu(input, flag, applyCallback)
    if library._keybindCtxMenu and library._keybindCtxMenu.Parent then
        library._keybindCtxMenu:Destroy()
    end
    if library._ctxOverlay and library._ctxOverlay.Parent then
        library._ctxOverlay:Destroy()
    end

    local mousePos = inputService:GetMouseLocation()
    local ctxGui = game:GetService("CoreGui"):FindFirstChild("Swag_Notifications")
    if not ctxGui then return end

    local overlay = Instance.new("TextButton")
    overlay.Name = "ContextMenuOverlay"
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.ZIndex = 9998
    overlay.Text = ""
    overlay.Parent = ctxGui
    library._ctxOverlay = overlay

    local ctx = Instance.new("Frame")
    ctx.Name = "ColorContextMenu"
    ctx.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    ctx.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ctx.BorderSizePixel = 2
    ctx.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y - 36)
    ctx.Size = UDim2.new(0, 90, 0, 40)
    ctx.ZIndex = 9999
    ctx.Parent = ctxGui
    library._keybindCtxMenu = ctx

    local inner = Instance.new("Frame")
    inner.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    inner.BorderColor3 = Color3.fromRGB(40, 40, 40)
    inner.Size = UDim2.new(1, 0, 1, 0)
    inner.ZIndex = 10000
    inner.Parent = ctx
    
    local function closeMenu()
        if overlay then overlay:Destroy() end
        if ctx then ctx:Destroy() end
    end

    local function makeOption(text, yPos, onClick)
        local btn = Instance.new("TextButton")
        btn.BackgroundTransparency = 1
        btn.Size = UDim2.new(1, 0, 0, 20)
        btn.Position = UDim2.new(0, 0, 0, yPos)
        btn.Font = Enum.Font.Code
        btn.Text = "  " .. text
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 12
        btn.ZIndex = 10001
        btn.Parent = inner

        btn.MouseEnter:Connect(function()
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundTransparency = 0.85
            btn.BackgroundColor3 = library.libColor
        end)
        btn.MouseLeave:Connect(function()
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.BackgroundTransparency = 1
        end)
        btn.MouseButton1Click:Connect(function()
            onClick()
            closeMenu()
        end)
    end

    makeOption("Copy", 0, function()
        library.copiedColor = library.flags[flag]
    end)
    makeOption("Paste", 20, function()
        if applyCallback then
            applyCallback(library.copiedColor)
        end
    end)

    overlay.MouseButton1Click:Connect(closeMenu)
    overlay.MouseButton2Click:Connect(closeMenu)
end

-- Notification System
library.activeNotifications = {}
library.notifyDefaults = {
    maxStack = 64,
    offsetX = 10,
    offsetY = 40,
    animation = "Slide",
    duration = 3,
    alignment = "Left"
}

library.flags["notify_offset_x"] = library.notifyDefaults.offsetX
library.flags["notify_offset_y"] = library.notifyDefaults.offsetY
library.options["notify_offset_x"] = {skipflag = false}
library.options["notify_offset_y"] = {skipflag = false}

local notifySGui = Instance.new("ScreenGui")
notifySGui.Name = "Swag_Notifications"
notifySGui.Parent = game:GetService("CoreGui")
notifySGui.DisplayOrder = 100

local dummyTextString = "Drag me to set position"
local textService = game:GetService("TextService")
local dummyTextSize = textService:GetTextSize(dummyTextString, 13, Enum.Font.Code, Vector2.new(9999, 1000))
local dummyXSize = math.max(dummyTextSize.X + 16, 100)
local dummyYSize = math.max(dummyTextSize.Y + 8, 20)

local notifyArea = Instance.new("Frame")
notifyArea.Name = "NotificationArea"
notifyArea.BackgroundTransparency = 1
notifyArea.Position = UDim2.new(0, library.notifyDefaults.offsetX, 0, library.notifyDefaults.offsetY)
notifyArea.Size = UDim2.new(0, dummyXSize, 0, 600)
notifyArea.ZIndex = 500
notifyArea.Parent = notifySGui

local notifyLayout = Instance.new("UIListLayout")
notifyLayout.Padding = UDim.new(0, 4)
notifyLayout.FillDirection = Enum.FillDirection.Vertical
notifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifyLayout.Parent = notifyArea

library.notifyArea = notifyArea

local dummyFrame = Instance.new("Frame")
dummyFrame.Name = "DummyNotification"
dummyFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dummyFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
dummyFrame.BorderSizePixel = 1
dummyFrame.Size = UDim2.new(0, dummyXSize, 0, dummyYSize)
dummyFrame.Position = UDim2.new(0, library.notifyDefaults.offsetX, 0, library.notifyDefaults.offsetY)
dummyFrame.ClipsDescendants = true
dummyFrame.Visible = false
dummyFrame.ZIndex = 600
dummyFrame.Parent = notifySGui

local dummyInner = Instance.new("Frame")
dummyInner.Name = "Inner"
dummyInner.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
dummyInner.BorderColor3 = Color3.fromRGB(40, 40, 40)
dummyInner.BorderMode = Enum.BorderMode.Inset
dummyInner.Size = UDim2.new(1, 0, 1, 0)
dummyInner.ZIndex = 601
dummyInner.Parent = dummyFrame

local dummyGradient = Instance.new("UIGradient")
dummyGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 18)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 28))
})
dummyGradient.Rotation = -90
dummyGradient.Parent = dummyInner

local dummyContent = Instance.new("Frame")
dummyContent.Name = "Content"
dummyContent.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dummyContent.BackgroundTransparency = 1
dummyContent.BorderSizePixel = 0
dummyContent.Position = UDim2.new(0, 1, 0, 1)
dummyContent.Size = UDim2.new(1, -2, 1, -2)
dummyContent.ZIndex = 602
dummyContent.Parent = dummyInner

local dummyText = Instance.new("TextLabel")
dummyText.Name = "Text"
dummyText.BackgroundTransparency = 1
dummyText.Position = UDim2.new(0, 8, 0, 0)
dummyText.Size = UDim2.new(1, -12, 1, 0)
dummyText.Text = "Drag me to set position."
dummyText.Font = Enum.Font.Code
dummyText.TextColor3 = Color3.fromRGB(220, 220, 220)
dummyText.TextSize = 13
dummyText.TextStrokeTransparency = 0
dummyText.TextXAlignment = Enum.TextXAlignment.Left
dummyText.ZIndex = 603
dummyText.Parent = dummyContent

local dummyAccent = Instance.new("Frame")
dummyAccent.Name = "AccentBar"
dummyAccent.BackgroundColor3 = library.libColor
dummyAccent.BorderSizePixel = 0
dummyAccent.Position = UDim2.new(0, 0, 0, 0)
dummyAccent.Size = UDim2.new(0, 2, 1, 0)
dummyAccent.ZIndex = 604
dummyAccent.Parent = dummyFrame
table.insert(library.accentElements, {obj = dummyAccent, prop = "BackgroundColor3"})

local alignAssistContainer = Instance.new("Frame")
alignAssistContainer.Name = "AlignAssist"
alignAssistContainer.Size = UDim2.new(1, 0, 1, 0)
alignAssistContainer.BackgroundTransparency = 1
alignAssistContainer.Visible = false
alignAssistContainer.ZIndex = 499
alignAssistContainer.Parent = notifySGui

local vLine = Instance.new("Frame")
vLine.BackgroundColor3 = library.libColor
vLine.BorderSizePixel = 0
vLine.Size = UDim2.new(0, 1, 1, 0)
vLine.AnchorPoint = Vector2.new(0.5, 0)
vLine.Position = UDim2.new(0.5, 0, 0, 0)
vLine.Visible = false
vLine.Parent = alignAssistContainer
table.insert(library.accentElements, {obj = vLine, prop = "BackgroundColor3"})

local hLine = Instance.new("Frame")
hLine.BackgroundColor3 = library.libColor
hLine.BorderSizePixel = 0
hLine.Size = UDim2.new(1, 0, 0, 1)
hLine.AnchorPoint = Vector2.new(0, 0.5)
hLine.Position = UDim2.new(0, 0, 0.5, 0)
hLine.Visible = false
hLine.Parent = alignAssistContainer
table.insert(library.accentElements, {obj = hLine, prop = "BackgroundColor3"})

library.dummyFrame = dummyFrame
library.dummyText = dummyText
library.dummyAccent = dummyAccent
library.alignAssistContainer = alignAssistContainer
library.vLine = vLine
library.hLine = hLine

function library:updateDummyStyle()
    local alignment = library.flags["notify_alignment"] or library.notifyDefaults.alignment
    if alignment == "Center" then
        notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        library.dummyText.TextXAlignment = Enum.TextXAlignment.Center
        library.dummyAccent.Size = UDim2.new(1, 0, 0, 2)
        library.dummyAccent.Position = UDim2.new(0, 0, 1, -2)
        library.dummyText.Position = UDim2.new(0, 0, 0, -1)
        library.dummyText.Size = UDim2.new(1, 0, 1, 0)
    elseif alignment == "Right" then
        notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        library.dummyText.TextXAlignment = Enum.TextXAlignment.Right
        library.dummyAccent.Size = UDim2.new(0, 2, 1, 0)
        library.dummyAccent.Position = UDim2.new(1, -2, 0, 0)
        library.dummyText.Position = UDim2.new(0, 8, 0, 0)
        library.dummyText.Size = UDim2.new(1, -12, 1, 0)
    else
        notifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        library.dummyText.TextXAlignment = Enum.TextXAlignment.Left
        library.dummyAccent.Size = UDim2.new(0, 2, 1, 0)
        library.dummyAccent.Position = UDim2.new(0, 0, 0, 0)
        library.dummyText.Position = UDim2.new(0, 8, 0, 0)
        library.dummyText.Size = UDim2.new(1, -12, 1, 0)
    end
end

local isDraggingDummy = false
local dragStartPos = nil
local dummyStartPos = nil

function library:updateNotifyPosition()
    local x = library.flags["notify_offset_x"] or library.notifyDefaults.offsetX
    local y = library.flags["notify_offset_y"] or library.notifyDefaults.offsetY
    
    local showDummy = library.flags["notify_show_dummy"]
    local yOffset = showDummy and (dummyYSize + 4) or 0
    
    local alignment = library.flags["notify_alignment"] or library.notifyDefaults.alignment
    if alignment == "Right" then
        notifyArea.AnchorPoint = Vector2.new(1, 0)
        notifyArea.Position = UDim2.new(0, x + dummyFrame.Size.X.Offset, 0, y + yOffset)
    elseif alignment == "Center" then
        notifyArea.AnchorPoint = Vector2.new(0.5, 0)
        notifyArea.Position = UDim2.new(0, x + (dummyFrame.Size.X.Offset / 2), 0, y + yOffset)
    else
        notifyArea.AnchorPoint = Vector2.new(0, 0)
        notifyArea.Position = UDim2.new(0, x, 0, y + yOffset)
    end
    
    dummyFrame.Position = UDim2.new(0, x, 0, y)
    library:updateDummyStyle()
end

dummyFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingDummy = true
        dragStartPos = input.Position
        dummyStartPos = dummyFrame.Position
        
        local con
        con = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDraggingDummy = false
                vLine.Visible = false
                hLine.Visible = false
                if con then con:Disconnect() end
            end
        end)
    end
end)

inputService.InputChanged:Connect(function(input)
    if isDraggingDummy and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        local newX = dummyStartPos.X.Offset + delta.X
        local newY = dummyStartPos.Y.Offset + delta.Y
        
        local screenSize = notifySGui.AbsoluteSize
        if screenSize.X == 0 then
            local cam = workspace.CurrentCamera
            if cam then screenSize = cam.ViewportSize else screenSize = Vector2.new(1920, 1080) end
        end
        
        newX = math.clamp(newX, 0, screenSize.X - dummyFrame.AbsoluteSize.X)
        newY = math.clamp(newY, -36, screenSize.Y - dummyFrame.AbsoluteSize.Y)
        
        local centerX = (screenSize.X / 2) - (dummyFrame.AbsoluteSize.X / 2)
        local centerY = (screenSize.Y / 2) - (dummyFrame.AbsoluteSize.Y / 2)
        local snapThresh = 15
        
        if math.abs(newX - centerX) < snapThresh then
            newX = centerX
            vLine.Visible = true
        else
            vLine.Visible = false
        end
        
        if math.abs(newY - centerY) < snapThresh then
            newY = centerY
            hLine.Visible = true
        else
            hLine.Visible = false
        end
        
        library.notifyDefaults.offsetX = newX
        library.notifyDefaults.offsetY = newY
        library.flags["notify_offset_x"] = newX
        library.flags["notify_offset_y"] = newY
        library:updateNotifyPosition()
    end
end)

function library:notify(text, overrideTime)
    local maxStack = library.flags["notify_max_stack"] or library.notifyDefaults.maxStack
    local animStyle = library.flags["notify_animation"] or library.notifyDefaults.animation
    local duration = overrideTime or library.flags["notify_duration"] or library.notifyDefaults.duration
    local alignment = library.flags["notify_alignment"] or library.notifyDefaults.alignment

    -- Enforce max stack
    while #library.activeNotifications >= maxStack do
        local oldest = table.remove(library.activeNotifications, 1)
        if oldest and oldest.Parent then
            oldest:Destroy()
        end
    end

    local textService = game:GetService("TextService")
    local textSize = textService:GetTextSize(text, 13, Enum.Font.Code, Vector2.new(9999, 1000))
    local ySize = math.max(textSize.Y + 8, 20)
    local xSize = math.max(textSize.X + 16, 100)
    
    if notifyArea and xSize > notifyArea.AbsoluteSize.X then
        notifyArea.Size = UDim2.new(0, xSize, 0, 600)
    end

    -- Alignment
    local textAlign = Enum.TextXAlignment.Left
    local textPos = UDim2.new(0, 8, 0, 0)
    local textSizeU = UDim2.new(1, -12, 1, 0)
    local accentPos = UDim2.new(0, 0, 0, 0)
    local accentSize = UDim2.new(0, 2, 1, 0)

    if alignment == "Center" then
        textAlign = Enum.TextXAlignment.Center
        textPos = UDim2.new(0, 0, 0, -1)
        textSizeU = UDim2.new(1, 0, 1, 0)
        accentPos = UDim2.new(0, 0, 1, -2)
        accentSize = UDim2.new(1, 0, 0, 2)
    elseif alignment == "Right" then
        textAlign = Enum.TextXAlignment.Right
        textPos = UDim2.new(0, 8, 0, 0)
        textSizeU = UDim2.new(1, -12, 1, 0)
        accentPos = UDim2.new(1, -2, 0, 0)
        accentSize = UDim2.new(0, 2, 1, 0)
    end

    -- Outer frame
    local outer = Instance.new("Frame")
    outer.Name = "Notification"
    outer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    outer.BorderColor3 = Color3.fromRGB(0, 0, 0)
    outer.BorderSizePixel = 1
    outer.Size = animStyle == "Slide" and UDim2.new(0, 0, 0, ySize) or UDim2.new(0, xSize, 0, ySize)
    outer.ClipsDescendants = true
    outer.ZIndex = 500
    outer.Parent = notifyArea

    if animStyle == "Fade" then
        outer.BackgroundTransparency = 1
    end

    -- Inner frame
    local inner = Instance.new("Frame")
    inner.Name = "Inner"
    inner.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    inner.BorderColor3 = Color3.fromRGB(40, 40, 40)
    inner.BorderMode = Enum.BorderMode.Inset
    inner.Size = UDim2.new(1, 0, 1, 0)
    inner.ZIndex = 501
    inner.Parent = outer

    if animStyle == "Fade" then
        inner.BackgroundTransparency = 1
    end

    -- Gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 18)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 28))
    })
    gradient.Rotation = -90
    gradient.Parent = inner

    -- Content frame
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.Position = UDim2.new(0, 1, 0, 1)
    content.Size = UDim2.new(1, -2, 1, -2)
    content.ZIndex = 502
    content.Parent = inner

    -- Text label
    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.BackgroundTransparency = 1
    label.Position = textPos
    label.Size = textSizeU
    label.Font = Enum.Font.Code
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 13
    label.TextStrokeTransparency = 0
    label.TextXAlignment = textAlign
    label.ZIndex = 503
    label.Parent = content

    if animStyle == "Fade" then
        label.TextTransparency = 1
        label.TextStrokeTransparency = 1
    end

    -- Accent bar
    local accentBar = Instance.new("Frame")
    accentBar.Name = "AccentBar"
    accentBar.BackgroundColor3 = library.libColor
    accentBar.BorderSizePixel = 0
    accentBar.Position = accentPos
    accentBar.Size = accentSize
    accentBar.ZIndex = 504
    accentBar.Parent = outer

    if animStyle == "Fade" then
        accentBar.BackgroundTransparency = 1
    end

    -- Track accent bar for color updates
    table.insert(library.accentElements, {obj = accentBar, prop = "BackgroundColor3"})

    -- Track notification
    table.insert(library.activeNotifications, outer)

    -- Animate in
    local animDuration = 0.35

    if animStyle == "Slide" then
        outer:TweenSize(UDim2.new(0, xSize, 0, ySize), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, animDuration, true)
    elseif animStyle == "Fade" then
        library:Tween(outer, TweenInfo.new(animDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
        library:Tween(inner, TweenInfo.new(animDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
        library:Tween(label, TweenInfo.new(animDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0, TextStrokeTransparency = 0})
        library:Tween(accentBar, TweenInfo.new(animDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
    end

    -- Animate out and destroy
    spawn(function()
        wait(duration)

        if animStyle == "Slide" then
            outer:TweenSize(UDim2.new(0, 0, 0, ySize), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, animDuration, true)
            wait(animDuration)
        elseif animStyle == "Fade" then
            library:Tween(outer, TweenInfo.new(animDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
            library:Tween(inner, TweenInfo.new(animDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
            library:Tween(label, TweenInfo.new(animDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1, TextStrokeTransparency = 1})
            library:Tween(accentBar, TweenInfo.new(animDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
            wait(animDuration)
        end

        -- Remove from tracking
        for i, v in next, library.activeNotifications do
            if v == outer then
                table.remove(library.activeNotifications, i)
                break
            end
        end

        outer:Destroy()
    end)
end

function library:addTab(name)
    local newTab = tabholder.tab:Clone()
    local newButton = tabviewer.button:Clone()

    table.insert(library.tabs,newTab)
    newTab.Parent = tabholder
    newTab.Visible = false

    table.insert(library.tabbuttons,newButton)
    newButton.Parent = tabviewer
    newButton.Modal = true
    newButton.Visible = true
    newButton.text.Text = name
    newButton.element.BackgroundColor3 = library.libColor
    table.insert(library.accentElements, {obj = newButton.element, prop = "BackgroundColor3"})
    
    local listLayout = tabviewer:FindFirstChildWhichIsA("UIListLayout")
    if listLayout then
        listLayout.Padding = UDim.new(0, 0)
    end
    
    local tabCount = #library.tabbuttons
    for _, btn in ipairs(library.tabbuttons) do
        btn.Size = UDim2.new(1 / tabCount, 0, 1, 0)
    end
    
    newButton.MouseButton1Click:Connect(function()
        for i,v in next, library.tabs do
            v.Visible = v == newTab
        end
        for i,v in next, library.toInvis do
            v.Visible = false
        end
        for i,v in next, library.tabbuttons do
            local state = v == newButton
            if state then
                v.element.Visible = true
                library:Tween(v.element, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.000})
                v.text.TextColor3 = Color3.fromRGB(244, 244, 244)
            else
                library:Tween(v.element, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1.000})
                v.text.TextColor3 = Color3.fromRGB(144, 144, 144)
            end
        end
    end)

    local tab = {}
    library.tabsData[name] = tab
    local groupCount = 0
    local jigCount = 0
    local topStuff = 2000
  
    function tab:createGroup(pos,groupname) -- newTab[pos == 0 and "left" or "right"] 
        local groupbox = Instance.new("Frame")
        local grouper = Instance.new("Frame")
        local UIListLayout = Instance.new("UIListLayout")
        local UIPadding = Instance.new("UIPadding")
        local element = Instance.new("Frame")
        local title = Instance.new("TextLabel")
        local backframe = Instance.new("Frame")

        groupCount -= 1

        groupbox.Parent = newTab[pos]
        groupbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        groupbox.BorderColor3 = Color3.fromRGB(30, 30, 30)
        groupbox.BorderSizePixel = 2
        groupbox.Size = UDim2.new(0, 211, 0, 8)
        groupbox.ZIndex = groupCount

        grouper.Parent = groupbox
        grouper.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        grouper.BorderColor3 = Color3.fromRGB(0, 0, 0)
        grouper.Size = UDim2.new(1, 0, 1, 0)

        UIListLayout.Parent = grouper
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

        UIPadding.Parent = grouper
        UIPadding.PaddingBottom = UDim.new(0, 4)
        UIPadding.PaddingTop = UDim.new(0, 7)

        element.Name = "element"
        element.Parent = groupbox
        element.BackgroundColor3 = library.libColor
        table.insert(library.accentElements, {obj = element, prop = "BackgroundColor3"})
        element.BorderSizePixel = 0
        element.Size = UDim2.new(1, 0, 0, 1)

        title.Parent = groupbox
        title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        title.BackgroundTransparency = 1.000
        title.BorderSizePixel = 0
        title.Position = UDim2.new(0, 17, 0, 0)
        title.ZIndex = 2
        title.Font = Enum.Font.Code
        title.Text = groupname or ""
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 13.000
        title.TextStrokeTransparency = 0.000
        title.TextXAlignment = Enum.TextXAlignment.Left

        backframe.Parent = groupbox
        backframe.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        backframe.BorderSizePixel = 0
        backframe.Position = UDim2.new(0, 10, 0, -2)
        backframe.Size = UDim2.new(0, 13 + title.TextBounds.X, 0, 3)

        local group = {}
        function group:addToggle(args)
            if not args.flag and args.text then args.flag = args.text end
            if not args.flag then return warn("⚠️ incorrect arguments missing args on recent toggle") end
            groupbox.Size += UDim2.new(0, 0, 0, 20)

            local toggleframe = Instance.new("Frame")
            local tobble = Instance.new("Frame")
            local mid = Instance.new("Frame")
            local front = Instance.new("Frame")
            local text = Instance.new("TextLabel")
            local button = Instance.new("TextButton")

            jigCount -= 1
            library.multiZindex -= 1

            toggleframe.Name = "toggleframe"
            toggleframe.Parent = grouper
            toggleframe.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            toggleframe.BackgroundTransparency = 1.000
            toggleframe.BorderSizePixel = 0
            toggleframe.Size = UDim2.new(1, 0, 0, 20)
            toggleframe.ZIndex = library.multiZindex
            
            tobble.Name = "tobble"
            tobble.Parent = toggleframe
            tobble.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            tobble.BorderColor3 = Color3.fromRGB(0, 0, 0)
            tobble.BorderSizePixel = 3
                        tobble.Position = UDim2.new(0.0299999993, 0, 0.272000015, 0)

            tobble.Size = UDim2.new(0, 10, 0, 10)
            
            mid.Name = "mid"
            mid.Parent = tobble
            mid.BackgroundColor3 = Color3.fromRGB(69, 23, 255)
            mid.BorderColor3 = Color3.fromRGB(30,30,30)
            mid.BorderSizePixel = 2
            mid.Size = UDim2.new(0, 10, 0, 10)
            
            front.Name = "front"
            front.Parent = mid
            front.BackgroundColor3 = Color3.fromRGB(15,15,15)
            front.BorderColor3 = Color3.fromRGB(0, 0, 0)
            front.Size = UDim2.new(0, 10, 0, 10)
            
            text.Name = "text"
            text.Parent = toggleframe
            text.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
            text.BackgroundTransparency = 1.000
            text.Position = UDim2.new(0, 22, 0, 0)
            text.Size = UDim2.new(0, 0, 1, 2)
            text.Font = Enum.Font.Code
            text.Text = args.text or args.flag
            text.TextColor3 = Color3.fromRGB(155, 155, 155)
            text.TextSize = 13.000
            text.TextStrokeTransparency = 0.000
            text.TextXAlignment = Enum.TextXAlignment.Left
            
            button.Name = "button"
            button.Parent = toggleframe
            button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

            button.BackgroundTransparency = 1.000
            button.BorderSizePixel = 0
            button.Size = UDim2.new(0, 101, 1, 0)
            button.Font = Enum.Font.SourceSans
            button.Text = ""
            button.TextColor3 = Color3.fromRGB(0, 0, 0)
            button.TextSize = 14.000

            if args.disabled then
                button.Visible = false
                text.TextColor3 = library.disabledcolor
                text.Text = args.text
            return end

            local state = false
            function toggle(newState)
                state = newState
                library.flags[args.flag] = state
                front.BackgroundColor3 = state and library.libColor or Color3.fromRGB(15,15,15)
                text.TextColor3 = state and Color3.fromRGB(244, 244, 244) or Color3.fromRGB(144, 144, 144)
                if args.callback then
                    args.callback(state)
                end
            end
            button.MouseButton1Click:Connect(function()
                state = not state
                front.Name = state and "accent" or "back"
                library.flags[args.flag] = state
                mid.BorderColor3 = Color3.fromRGB(30,30,30)
                front.BackgroundColor3 = state and library.libColor or Color3.fromRGB(15,15,15)
                text.TextColor3 = state and Color3.fromRGB(244, 244, 244) or Color3.fromRGB(144, 144, 144)
                if args.callback then
                    args.callback(state)
                end
            end)
            button.MouseEnter:connect(function()
                mid.BorderColor3 = library.libColor
			end)
            button.MouseLeave:connect(function()
                mid.BorderColor3 = Color3.fromRGB(30,30,30)
			end)

            library.flags[args.flag] = false
            args._groupname = groupname
            library.options[args.flag] = {type = "toggle",changeState = toggle,skipflag = args.skipflag,oldargs = args}
            local _parentToggleText = args.text or args.flag
            local _parentToggleFlag = args.flag
            table.insert(library.onAccentChanged, function(newColor)
                if state then
                    front.BackgroundColor3 = newColor
                end
            end)
            local toggle = {}
            function toggle:addKeybind(args)
                if not args.flag then return warn("⚠️ incorrect arguments ⚠️ - missing args on toggle:keybind") end
                args._parentToggleText = _parentToggleText
                args._parentToggleFlag = _parentToggleFlag
                local next = false
                
                local keybind = Instance.new("Frame")
                local button_bg = Instance.new("Frame")
                local button_main = Instance.new("Frame")
                local button = Instance.new("TextButton")

                keybind.Parent = toggleframe
                keybind.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                keybind.BackgroundTransparency = 1.000
                keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
                keybind.BorderSizePixel = 0
                keybind.AnchorPoint = Vector2.new(1, 0)
                keybind.Position = UDim2.new(1, -6, 0.272, 0)
                keybind.Size = UDim2.new(0, 50, 0, 15)
                
                button_bg.Name = "bg"
                button_bg.Parent = keybind
                button_bg.BackgroundColor3 = Color3.fromRGB(15,15,15)
                button_bg.BorderColor3 = Color3.fromRGB(0, 0, 0)
                button_bg.BorderSizePixel = 2
                button_bg.Size = UDim2.new(1, 0, 1, 0)

                button_main.Name = "main"
                button_main.Parent = button_bg
                button_main.BackgroundColor3 = Color3.fromRGB(15,15,15)
                button_main.BorderColor3 = Color3.fromRGB(30, 30, 30)
                button_main.Size = UDim2.new(1, 0, 1, 0)
                
                button.Parent = button_main
                button.BackgroundColor3 = Color3.fromRGB(187, 131, 255)
                button.BackgroundTransparency = 1.000
                button.BorderSizePixel = 0
                button.Size = UDim2.new(1, 0, 1, 0)
                button.Font = Enum.Font.Code
                button.Text = "--"
                button.TextColor3 = Color3.fromRGB(155, 155, 155)
                button.TextSize = 13.000
                button.TextStrokeTransparency = 0.000
                button.TextXAlignment = Enum.TextXAlignment.Center
    
                function updateValue(val)
                    if library.colorpicking then return end
                    library.flags[args.flag] = val
                    if val == Enum.KeyCode.Unknown then
                        button.Text = "none"
                    else
                        button.Text = keyNames[val] or val.Name
                    end
                end
                inputService.InputBegan:Connect(function(key)
                    local key = key.KeyCode == Enum.KeyCode.Unknown and key.UserInputType or key.KeyCode
                    if next then
                        if key == Enum.KeyCode.Escape then
                            next = false
                            library.flags[args.flag] = Enum.KeyCode.Unknown
                            button.Text = "none"
                            button.TextColor3 = Color3.fromRGB(155, 155, 155)
                            return
                        end
                        if not table.find(library.blacklisted,key) then
                            next = false
                            library.flags[args.flag] = key
                            button.Text = keyNames[key] or key.Name
                            button.TextColor3 = Color3.fromRGB(155, 155, 155)
                        end
                    end
                    if not next and key == library.flags[args.flag] then
                        local opt = library.options[args.flag]
                        if opt then
                            local m = opt.mode or "Always"
                            if m == "Toggle" then
                                opt._active = not opt._active
                            elseif m == "Hold" then
                                opt._active = true
                            end
                        end
                        if args.callback then args.callback() end
                    end
                end)

                inputService.InputEnded:Connect(function(key)
                    local key = key.KeyCode == Enum.KeyCode.Unknown and key.UserInputType or key.KeyCode
                    if key == library.flags[args.flag] then
                        local opt = library.options[args.flag]
                        if opt and (opt.mode or "Always") == "Hold" then
                            opt._active = false
                        end
                    end
                end)
    
                button.MouseButton1Click:Connect(function()
                    if library.colorpicking then return end
                    library.flags[args.flag] = Enum.KeyCode.Unknown
                    button.Text = "..."
                    button.TextColor3 = library.libColor
                    next = true
                end)
                
                button.MouseButton2Click:Connect(function()
                    if library.colorpicking then return end
                    library:showKeybindContextMenu(nil, args.flag, function(mode)
                        library.options[args.flag].mode = mode
                        if mode == "Always" then
                            library.options[args.flag]._active = nil
                        end
                    end)
                end)
    
                library.flags[args.flag] = Enum.KeyCode.Unknown
                library.options[args.flag] = {type = "keybind", mode = "Always", changeState = updateValue, skipflag = args.skipflag, oldargs = args, parentToggleFlag = args._parentToggleFlag, _active = nil}
    
                updateValue(args.key or Enum.KeyCode.Unknown)
            end
            function toggle:addColorpicker(args)
                if not args.flag and args.text then args.flag = args.text end
                if not args.flag then return warn("⚠️ incorrect arguments ⚠️") end
                local colorpicker = Instance.new("Frame")
                local mid = Instance.new("Frame")
                local front = Instance.new("Frame")
                local button2 = Instance.new("TextButton")
                local colorFrame = Instance.new("Frame")
                local colorFrame_2 = Instance.new("Frame")
                local hueframe = Instance.new("Frame")
                local main = Instance.new("Frame")
                local hue = Instance.new("ImageLabel")
                local pickerframe = Instance.new("Frame")
                local main_2 = Instance.new("Frame")
                local picker = Instance.new("ImageLabel")
                local clr = Instance.new("Frame")
                local copy = Instance.new("TextButton")

                library.multiZindex -= 1
                jigCount -= 1
                topStuff -= 1 --args.second

                colorpicker.Parent = toggleframe
                colorpicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                colorpicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
                colorpicker.BorderSizePixel = 3
                colorpicker.Position = args.second and UDim2.new(0.720000029, 4, 0.272000015, 0) or UDim2.new(0.860000014, 4, 0.272000015, 0)
                colorpicker.Size = UDim2.new(0, 20, 0, 10)
                
                mid.Name = "mid"
                mid.Parent = colorpicker
                mid.BackgroundColor3 = Color3.fromRGB(69, 23, 255)
                mid.BorderColor3 = Color3.fromRGB(30,30,30)
                mid.BorderSizePixel = 2
                mid.Size = UDim2.new(1, 0, 1, 0)
                
                front.Name = "front"
                front.Parent = mid
                front.BackgroundColor3 = Color3.fromRGB(240, 142, 214)
                front.BorderColor3 = Color3.fromRGB(0, 0, 0)
                front.Size = UDim2.new(1, 0, 1, 0)
                
                button2.Name = "button2"
                button2.Parent = front
                button2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                button2.BackgroundTransparency = 1.000
                button2.Size = UDim2.new(1, 0, 1, 0)
                button2.Text = ""
                button2.Font = Enum.Font.SourceSans
                button2.TextColor3 = Color3.fromRGB(0, 0, 0)
                button2.TextSize = 14.000

				colorFrame.Name = "colorFrame"
				colorFrame.Parent = toggleframe
				colorFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				colorFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				colorFrame.BorderSizePixel = 2
				colorFrame.Position = UDim2.new(0.101092957, 0, 0.75, 0)
				colorFrame.Size = UDim2.new(0, 137, 0, 128)

				colorFrame_2.Name = "colorFrame"
				colorFrame_2.Parent = colorFrame
				colorFrame_2.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				colorFrame_2.BorderColor3 = Color3.fromRGB(60, 60, 60)
				colorFrame_2.Size = UDim2.new(1, 0, 1, 0)

				hueframe.Name = "hueframe"
				hueframe.Parent = colorFrame_2
				hueframe.Parent = colorFrame_2
                hueframe.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
                hueframe.BorderColor3 = Color3.fromRGB(60, 60, 60)
                hueframe.BorderSizePixel = 2
                hueframe.Position = UDim2.new(-0.0930000022, 18, -0.0599999987, 30)
                hueframe.Size = UDim2.new(0, 100, 0, 100)
    
                main.Name = "main"
                main.Parent = hueframe
                main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
                main.BorderColor3 = Color3.fromRGB(0, 0, 0)
                main.Size = UDim2.new(0, 100, 0, 100)
                main.ZIndex = 6
    
                picker.Name = "picker"
                picker.Parent = main
                picker.BackgroundColor3 = Color3.fromRGB(232, 0, 255)
                picker.BorderColor3 = Color3.fromRGB(0, 0, 0)
                picker.BorderSizePixel = 0
                picker.Size = UDim2.new(0, 100, 0, 100)
                picker.ZIndex = 104
                picker.Image = "rbxassetid://2615689005"
    
                pickerframe.Name = "pickerframe"
                pickerframe.Parent = colorFrame
                pickerframe.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
                pickerframe.BorderColor3 = Color3.fromRGB(60, 60, 60)
                pickerframe.BorderSizePixel = 2
                pickerframe.Position = UDim2.new(0.711000025, 14, -0.0599999987, 30)
                pickerframe.Size = UDim2.new(0, 20, 0, 100)
    
                main_2.Name = "main"
                main_2.Parent = pickerframe
                main_2.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
                main_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
                main_2.Size = UDim2.new(0, 20, 0, 100)
                main_2.ZIndex = 6
    
                hue.Name = "hue"
                hue.Parent = main_2
                hue.BackgroundColor3 = Color3.fromRGB(255, 0, 178)
                hue.BorderColor3 = Color3.fromRGB(0, 0, 0)
                hue.BorderSizePixel = 0
                hue.Size = UDim2.new(0, 20, 0, 100)
                hue.ZIndex = 104
                hue.Image = "rbxassetid://2615692420"
    
                clr.Name = "clr"
                clr.Parent = colorFrame
                clr.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                clr.BackgroundTransparency = 1.000
                clr.BorderColor3 = Color3.fromRGB(60, 60, 60)
                clr.BorderSizePixel = 2
                clr.Position = UDim2.new(0.0280000009, 0, 0, 2)
                clr.Size = UDim2.new(0, 129, 0, 14)
                clr.ZIndex = 5
    
                copy.Name = "copy"
                copy.Parent = clr
                copy.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
                copy.BackgroundTransparency = 1.000
                copy.BorderSizePixel = 0
                copy.Size = UDim2.new(0, 129, 0, 14)
                copy.ZIndex = 5
                copy.Font = Enum.Font.SourceSans
                copy.Text = args.text or args.flag
                copy.TextColor3 = Color3.fromRGB(100, 100, 100)
                copy.TextSize = 14.000
                copy.TextStrokeTransparency = 0.000

                copy.MouseButton1Click:Connect(function() -- "  "..args.text or "  "..args.flag
                    colorFrame.Visible = false
                end)

                button2.MouseButton1Click:Connect(function()
                    colorFrame.Visible = not colorFrame.Visible
                    mid.BorderColor3 = Color3.fromRGB(30,30,30)
                end)

                button2.MouseEnter:connect(function()
                    mid.BorderColor3 = library.libColor
                end)
                button2.MouseLeave:connect(function()
                    mid.BorderColor3 = Color3.fromRGB(30,30,30)
                end)

                -- Right-click context menu for copy/paste color
                button2.MouseButton2Click:Connect(function()
                    library:showColorContextMenu(nil, args.flag, function(color)
                        front.BackgroundColor3 = color
                        library.flags[args.flag] = color
                        if args.callback then args.callback(color) end
                    end)
                end)

                local function updateValue(value,fakevalue)
                    if typeof(value) == "table" then value = fakevalue end
                    library.flags[args.flag] = value
                    front.BackgroundColor3 = value
                    if args.callback then
                        args.callback(value)
                    end
                end

                local white, black = Color3.new(1,1,1), Color3.new(0,0,0)
                local colors = {Color3.new(1,0,0),Color3.new(1,1,0),Color3.new(0,1,0),Color3.new(0,1,1),Color3.new(0,0,1),Color3.new(1,0,1),Color3.new(1,0,0)}
                local heartbeat = game:GetService("RunService").Heartbeat

                local pickerX,pickerY,hueY = 0,0,0
                local oldpercentX,oldpercentY = 0,0

                -- Initialize picker from args.color so it doesn't show a solid wrong color
                do
                    local initColor = args.color or Color3.new(1,1,1)
                    local h, s, v = colorToHSV(initColor)
                    picker.BackgroundColor3 = hueToColor(h)
                    oldpercentX = s
                    oldpercentY = 1 - v
                end

                hue.MouseEnter:Connect(function()
                    local input = hue.InputBegan:connect(function(key)
                        if key.UserInputType == Enum.UserInputType.MouseButton1 then
                            while heartbeat:wait() and inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                                library.colorpicking = true
                                local percent = (hueY-hue.AbsolutePosition.Y-36)/hue.AbsoluteSize.Y
                                local num = math.max(1, math.min(7,math.floor(((percent*7+0.5)*100))/100))
                                local startC = colors[math.floor(num)]
                                local endC = colors[math.ceil(num)]
                                local color = white:lerp(picker.BackgroundColor3, oldpercentX):lerp(black, oldpercentY)
                                picker.BackgroundColor3 = startC:lerp(endC, num-math.floor(num)) or Color3.new(0, 0, 0)
                                updateValue(color)
                            end
                            library.colorpicking = false
                        end
                    end)
                    local leave
                    leave = hue.MouseLeave:connect(function()
                        input:disconnect()
                        leave:disconnect()
                    end)
                end)

                picker.MouseEnter:Connect(function()
                    local input = picker.InputBegan:connect(function(key)
                        if key.UserInputType == Enum.UserInputType.MouseButton1 then
                            while heartbeat:wait() and inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                                library.colorpicking = true
                                local xPercent = (pickerX-picker.AbsolutePosition.X)/picker.AbsoluteSize.X
                                local yPercent = (pickerY-picker.AbsolutePosition.Y-36)/picker.AbsoluteSize.Y
                                local color = white:lerp(picker.BackgroundColor3, xPercent):lerp(black, yPercent)
                                updateValue(color)
                                oldpercentX,oldpercentY = xPercent,yPercent
                            end
                            library.colorpicking = false
                        end
                    end)
                    local leave
                    leave = picker.MouseLeave:connect(function()
                        input:disconnect()
                        leave:disconnect()
                    end)
                end)

                hue.MouseMoved:connect(function(_, y)
                    hueY = y
                end)

                picker.MouseMoved:connect(function(x, y)
                    pickerX,pickerY = x,y
                end)

                table.insert(library.toInvis,colorFrame)
                library.flags[args.flag] = Color3.new(1,1,1)
                library.options[args.flag] = {type = "colorpicker",changeState = updateValue,skipflag = args.skipflag,oldargs = args}

                updateValue(args.color or Color3.new(1,1,1))
            end
            return toggle
        end
        function group:addButton(args)
            if not args.callback or not args.text then return warn("⚠️ incorrect arguments ⚠️") end
            groupbox.Size += UDim2.new(0, 0, 0, 22)

            local buttonframe = Instance.new("Frame")
            local bg = Instance.new("Frame")
            local main = Instance.new("Frame")
            local button = Instance.new("TextButton")
            local gradient = Instance.new("UIGradient")

            buttonframe.Name = "buttonframe"
            buttonframe.Parent = grouper
            buttonframe.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            buttonframe.BackgroundTransparency = 1.000
            buttonframe.BorderSizePixel = 0
            buttonframe.Size = UDim2.new(1, 0, 0, 21)
            
            bg.Name = "bg"
            bg.Parent = buttonframe
            bg.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            bg.BorderColor3 = Color3.fromRGB(0, 0, 0)
            bg.BorderSizePixel = 2
            bg.Position = UDim2.new(0.02, -1, 0, 0)
            bg.Size = UDim2.new(0, 205, 0, 15)
            
            main.Name = "main"
            main.Parent = bg
            main.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            main.BorderColor3 = Color3.fromRGB(60, 60, 60)
            main.Size = UDim2.new(1, 0, 1, 0)
            
            button.Name = "button"
            button.Parent = main
            button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            button.BackgroundTransparency = 1.000
            button.BorderSizePixel = 0
            button.Size = UDim2.new(1, 0, 1, 0)
            button.Font = Enum.Font.Code
            button.Text = args.text or args.flag
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.TextSize = 13.000
            button.TextStrokeTransparency = 0.000
            
            gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(105, 105, 105)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(121, 121, 121))}
            gradient.Rotation = 90
            gradient.Name = "gradient"
            gradient.Parent = main

            button.MouseButton1Click:Connect(function()
                if not library.colorpicking then
                    args.callback()
                end
            end)
            button.MouseEnter:connect(function()
                main.BorderColor3 = library.libColor
			end)
			button.MouseLeave:connect(function()
                main.BorderColor3 = Color3.fromRGB(60, 60, 60)
			end)
        end
        function group:addButtonRow(buttons)
            if not buttons or #buttons == 0 then return warn("⚠️ addButtonRow: no buttons provided") end
            local count = math.min(#buttons, 3)
            groupbox.Size += UDim2.new(0, 0, 0, 22)

            local rowframe = Instance.new("Frame")
            rowframe.Name = "buttonrow"
            rowframe.Parent = grouper
            rowframe.BackgroundTransparency = 1
            rowframe.BorderSizePixel = 0
            rowframe.Size = UDim2.new(1, 0, 0, 21)

            local totalWidth = 205
            local gap = 4
            local totalGaps = (count - 1) * gap
            local btnWidth = math.floor((totalWidth - totalGaps) / count)
            local startX = 3 -- matches the 0.02 offset used by other elements

            for i = 1, count do
                local bArgs = buttons[i]
                if not bArgs or not bArgs.text then continue end

                local xPos = startX + (i - 1) * (btnWidth + gap)
                local thisWidth = btnWidth
                -- Last button absorbs any remaining pixels to avoid sub-pixel gaps
                if i == count then
                    thisWidth = totalWidth - (count - 1) * (btnWidth + gap)
                end

                local bg = Instance.new("Frame")
                bg.Name = "bg_" .. i
                bg.Parent = rowframe
                bg.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                bg.BorderColor3 = Color3.fromRGB(0, 0, 0)
                bg.BorderSizePixel = 2
                bg.Position = UDim2.new(0, xPos, 0, 0)
                bg.Size = UDim2.new(0, thisWidth, 0, 15)

                local main = Instance.new("Frame")
                main.Name = "main"
                main.Parent = bg
                main.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                main.BorderColor3 = Color3.fromRGB(60, 60, 60)
                main.Size = UDim2.new(1, 0, 1, 0)

                local button = Instance.new("TextButton")
                button.Name = "button"
                button.Parent = main
                button.BackgroundTransparency = 1
                button.BorderSizePixel = 0
                button.Size = UDim2.new(1, 0, 1, 0)
                button.Font = Enum.Font.Code
                button.Text = bArgs.text
                button.TextColor3 = Color3.fromRGB(255, 255, 255)
                button.TextSize = 13
                button.TextStrokeTransparency = 0

                local gradient = Instance.new("UIGradient")
                gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(105, 105, 105)), ColorSequenceKeypoint.new(1, Color3.fromRGB(121, 121, 121))}
                gradient.Rotation = 90
                gradient.Parent = main

                if bArgs.callback then
                    button.MouseButton1Click:Connect(function()
                        if not library.colorpicking then
                            bArgs.callback()
                        end
                    end)
                end
                button.MouseEnter:connect(function()
                    main.BorderColor3 = library.libColor
                end)
                button.MouseLeave:connect(function()
                    main.BorderColor3 = Color3.fromRGB(60, 60, 60)
                end)
            end
        end
        function group:addSlider(args,sub)
            if not args.flag or not args.max then return warn("⚠️ incorrect arguments ⚠️") end
            groupbox.Size += UDim2.new(0, 0, 0, 30)

            local slider = Instance.new("Frame")
            local bg = Instance.new("Frame")
            local main = Instance.new("Frame")
            local fill = Instance.new("Frame")
            local button = Instance.new("TextButton")
            local valuetext = Instance.new("TextLabel")
            local UIGradient = Instance.new("UIGradient")
            local text = Instance.new("TextLabel")

            slider.Name = "slider"
            slider.Parent = grouper
            slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            slider.BackgroundTransparency = 1.000
            slider.BorderSizePixel = 0
            slider.Size = UDim2.new(1, 0, 0, 30)
            
            bg.Name = "bg"
            bg.Parent = slider
            bg.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            bg.BorderColor3 = Color3.fromRGB(0, 0, 0)
            bg.BorderSizePixel = 2
            bg.Position = UDim2.new(0.02, -1, 0, 16)
            bg.Size = UDim2.new(0, 205, 0, 10)
            
            main.Name = "main"
            main.Parent = bg
            main.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            main.BorderColor3 = Color3.fromRGB(50, 50, 50)
            main.Size = UDim2.new(1, 0, 1, 0)
            
            fill.Name = "fill"
            fill.Parent = main
            fill.BackgroundColor3 = library.libColor
            table.insert(library.accentElements, {obj = fill, prop = "BackgroundColor3"})
            fill.BackgroundTransparency = 0.200
            fill.BorderColor3 = Color3.fromRGB(60, 60, 60)
            fill.BorderSizePixel = 0
            fill.Size = UDim2.new(0.617238641, 13, 1, 0)
            
            button.Name = "button"
            button.Parent = main
            button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            button.BackgroundTransparency = 1.000
            button.Size = UDim2.new(0, 191, 1, 0)
            button.Font = Enum.Font.SourceSans
            button.Text = ""
            button.TextColor3 = Color3.fromRGB(0, 0, 0)
            button.TextSize = 14.000
            
            valuetext.Parent = main
            valuetext.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            valuetext.BackgroundTransparency = 1.000
            valuetext.Position = UDim2.new(0.5, 0, 0.5, 0)
            valuetext.Font = Enum.Font.Code
            valuetext.Text = "0.9172/10"
            valuetext.TextColor3 = Color3.fromRGB(255, 255, 255)
            valuetext.TextSize = 14.000
            valuetext.TextStrokeTransparency = 0.000
            
            UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(105, 105, 105)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(121, 121, 121))}
            UIGradient.Rotation = 90
            UIGradient.Parent = main
            
            text.Name = "text"
            text.Parent = slider
            text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            text.BackgroundTransparency = 1.000
            text.Position = UDim2.new(0.0299999993, -1, 0, 7)
            text.ZIndex = 2
            text.Font = Enum.Font.Code
            text.Text = args.text or args.flag
            text.TextColor3 = Color3.fromRGB(244, 244, 244)
            text.TextSize = 13.000
            text.TextStrokeTransparency = 0.000
            text.TextXAlignment = Enum.TextXAlignment.Left

            local entered = false
			local scrolling = false
			local amount = 0

            local function updateValue(value)
                if library.colorpicking then return end
				if value ~= 0 then
					fill:TweenSize(UDim2.new(value/args.max,0,1,0),Enum.EasingDirection.In,Enum.EasingStyle.Sine,0.01)
				else
					fill:TweenSize(UDim2.new(0,1,1,0),Enum.EasingDirection.In,Enum.EasingStyle.Sine,0.01)
                end
                valuetext.Text = value..sub
                library.flags[args.flag] = value
                if args.callback then
                    args.callback(value)
                end
			end
			local function updateScroll()
                if scrolling or library.scrolling or not newTab.Visible or library.colorpicking then return end
                while inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and menu.Enabled do runService.RenderStepped:Wait()
                    library.scrolling = true
                    valuetext.TextColor3 = Color3.fromRGB(255,255,255)
					scrolling = true
					local value = args.min + ((mouse.X - button.AbsolutePosition.X) / button.AbsoluteSize.X) * (args.max - args.min)
					if value < 0 then value = 0 end
					if value > args.max then value = args.max end
                    if value < args.min then value = args.min end
					local rounded = args.round and (math.floor(value / args.round + 0.5) * args.round) or math.floor(value)
				updateValue(rounded)
                end
                if scrolling and not entered then
                    valuetext.TextColor3 = Color3.fromRGB(255,255,255)
                end
                if not menu.Enabled then
                    entered = false
                end
                scrolling = false
                library.scrolling = false
			end
			button.MouseEnter:connect(function()
                if library.colorpicking then return end
				if scrolling or entered then return end
                entered = true
                main.BorderColor3 = library.libColor
				while entered do wait()
					updateScroll()
				end
			end)
			button.MouseLeave:connect(function()
                entered = false
                main.BorderColor3 = Color3.fromRGB(60, 60, 60)
			end)
            if args.value then
                updateValue(args.value)
            end
            library.flags[args.flag] = 0
            library.options[args.flag] = {type = "slider",changeState = updateValue,skipflag = args.skipflag,oldargs = args}
            updateValue(args.value or 0)
        end
        function group:addTextbox(args)
            if not args.flag then return warn("⚠️ incorrect arguments ⚠️") end
            groupbox.Size += UDim2.new(0, 0, 0, 35)

            local textbox = Instance.new("Frame")
            local bg = Instance.new("Frame")
            local main = Instance.new("ScrollingFrame")
            local box = Instance.new("TextBox")
            local gradient = Instance.new("UIGradient")
            local text = Instance.new("TextLabel")

            box:GetPropertyChangedSignal('Text'):Connect(function(val)
                if library.colorpicking then return end
                library.flags[args.flag] = box.Text
                args.value = box.Text
                if args.callback then
                    args.callback()
                end
            end)
            textbox.Name = "textbox"
            textbox.Parent = grouper
            textbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            textbox.BackgroundTransparency = 1.000
            textbox.BorderSizePixel = 0
            textbox.Size = UDim2.new(1, 0, 0, 35)
            textbox.ZIndex = 10

            bg.Name = "bg"
            bg.Parent = textbox
            bg.BackgroundColor3 = Color3.fromRGB(15,15,15)
            bg.BorderColor3 = Color3.fromRGB(0, 0, 0)
            bg.BorderSizePixel = 2
            bg.Position = UDim2.new(0.02, -1, 0, 16)
            bg.Size = UDim2.new(0, 205, 0, 15)

            main.Name = "main"
            main.Parent = bg
            main.Active = true
            main.BackgroundColor3 = Color3.fromRGB(15,15,15)
            main.BorderColor3 = Color3.fromRGB(30, 30, 30)
            main.Size = UDim2.new(1, 0, 1, 0)
            main.CanvasSize = UDim2.new(0, 0, 0, 0)
            main.ScrollBarThickness = 0

            box.Name = "box"
            box.Parent = main
            box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            box.BackgroundTransparency = 1.000
            box.Selectable = false
            box.Size = UDim2.new(1, 0, 1, 0)
            box.Font = Enum.Font.Code
            box.Text = args.value or ""
            box.TextColor3 = Color3.fromRGB(255, 255, 255)
            box.TextSize = 13.000
            box.TextStrokeTransparency = 0.000
            box.TextXAlignment = Enum.TextXAlignment.Left

            gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(105, 105, 105)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(121, 121, 121))}
            gradient.Rotation = 90
            gradient.Name = "gradient"
            gradient.Parent = main

            text.Name = "text"
            text.Parent = textbox
            text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            text.BackgroundTransparency = 1.000
            text.Position = UDim2.new(0.0299999993, -1, 0, 7)
            text.ZIndex = 2
            text.Font = Enum.Font.Code
            text.Text = args.text or args.flag
            text.TextColor3 = Color3.fromRGB(244, 244, 244)
            text.TextSize = 13.000
            text.TextStrokeTransparency = 0.000
            text.TextXAlignment = Enum.TextXAlignment.Left


            library.flags[args.flag] = args.value or ""
            library.options[args.flag] = {type = "textbox",changeState = function(text) box.Text = text end,skipflag = args.skipflag,oldargs = args}
        end
        function group:addDivider(args)
            groupbox.Size += UDim2.new(0, 0, 0, 10)
            
            local div = Instance.new("Frame")
            local bg = Instance.new("Frame")
            local main = Instance.new("Frame")

            div.Name = "div"
            div.Parent = grouper
            div.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            div.BackgroundTransparency = 1.000
            div.BorderSizePixel = 0
            div.Position = UDim2.new(0, 0, 0.743662, 0)
            div.Size = UDim2.new(0, 202, 0, 10)
            
            bg.Name = "bg"
            bg.Parent = div
            bg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            bg.BorderColor3 = Color3.fromRGB(0, 0, 0)
            bg.BorderSizePixel = 2
            bg.Position = UDim2.new(0.02, 0, 0, 4)
            bg.Size = UDim2.new(0, 191, 0, 1)
            
            main.Name = "main"
            main.Parent = bg
            main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            main.BorderColor3 = Color3.fromRGB(30, 30, 30)
            main.Size = UDim2.new(0, 191, 0, 1)
        end
        function group:addList(args)
            if not args.flag or not args.values then return warn("⚠️ incorrect arguments ⚠️") end
            groupbox.Size += UDim2.new(0, 0, 0, 35)
            
--args.multiselect and "..." or ""
            library.multiZindex -= 1

            local list = Instance.new("Frame")
            local bg = Instance.new("Frame")
            local main = Instance.new("ScrollingFrame")
            local button = Instance.new("TextButton")
            local dumbtriangle = Instance.new("ImageLabel")
            local valuetext = Instance.new("TextLabel")
            local gradient = Instance.new("UIGradient")
            local text = Instance.new("TextLabel")

            local frame = Instance.new("Frame")
            local holder = Instance.new("Frame")
            local UIListLayout = Instance.new("UIListLayout")
            
            list.Name = "list"
            list.Parent = grouper
            list.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            list.BackgroundTransparency = 1.000
            list.BorderSizePixel = 0
            list.Size = UDim2.new(1, 0, 0, 35)
            list.ZIndex = library.multiZindex

            bg.Name = "bg"
            bg.Parent = list
            bg.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            bg.BorderColor3 = Color3.fromRGB(0, 0, 0)
            bg.BorderSizePixel = 2
            bg.Position = UDim2.new(0.02, -1, 0, 16)
            bg.Size = UDim2.new(0, 205, 0, 15)

            main.Name = "main"
            main.Parent = bg
            main.Active = true
            main.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            main.BorderColor3 = Color3.fromRGB(60, 60, 60)
            main.Size = UDim2.new(1, 0, 1, 0)
            main.CanvasSize = UDim2.new(0, 0, 0, 0)
            main.ScrollBarThickness = 0

            button.Name = "button"
            button.Parent = main
            button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            button.BackgroundTransparency = 1.000
            button.Size = UDim2.new(0, 191, 1, 0)
            button.Font = Enum.Font.SourceSans
            button.Text = ""
            button.TextColor3 = Color3.fromRGB(0, 0, 0)
            button.TextSize = 14.000

            dumbtriangle.Name = "dumbtriangle"
            dumbtriangle.Parent = main
            dumbtriangle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            dumbtriangle.BackgroundTransparency = 1.000
            dumbtriangle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            dumbtriangle.BorderSizePixel = 0
            dumbtriangle.Position = UDim2.new(1, -11, 0.5, -3)
            dumbtriangle.Size = UDim2.new(0, 7, 0, 6)
            dumbtriangle.ZIndex = 3
            dumbtriangle.Image = "rbxassetid://8532000591"

            valuetext.Name = "valuetext"
            valuetext.Parent = main
            valuetext.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            valuetext.BackgroundTransparency = 1.000
            valuetext.Position = UDim2.new(0.00200000009, 2, 0, 7)
            valuetext.ZIndex = 2
            valuetext.Font = Enum.Font.Code
            valuetext.Text = ""
            valuetext.TextColor3 = Color3.fromRGB(244, 244, 244)
            valuetext.TextSize = 13.000
            valuetext.TextStrokeTransparency = 0.000
            valuetext.TextXAlignment = Enum.TextXAlignment.Left

            gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(105, 105, 105)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(121, 121, 121))}
            gradient.Rotation = 90
            gradient.Name = "gradient"
            gradient.Parent = main

            text.Name = "text"
            text.Parent = list
            text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            text.BackgroundTransparency = 1.000
            text.Position = UDim2.new(0.0299999993, -1, 0, 7)
            text.ZIndex = 2
            text.Font = Enum.Font.Code
            text.Text = args.text or args.flag
            text.TextColor3 = Color3.fromRGB(244, 244, 244)
            text.TextSize = 13.000
            text.TextStrokeTransparency = 0.000
            text.TextXAlignment = Enum.TextXAlignment.Left

            frame.Name = "frame"
            frame.Parent = list
            frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            frame.BorderSizePixel = 2
            frame.Position = UDim2.new(0.0299999993, -1, 0.605000019, 15)
            frame.Size = UDim2.new(0, 203, 0, 0)
            frame.Visible = false
            frame.ZIndex = library.multiZindex
            
            holder.Name = "holder"
            holder.Parent = frame
            holder.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            holder.BorderColor3 = Color3.fromRGB(60, 60, 60)
            holder.Size = UDim2.new(1, 0, 1, 0)
            
            UIListLayout.Parent = holder
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

			local function updateValue(value)
                if value == nil or (#library.options[args.flag].values == 0 and not args.multiselect) then valuetext.Text = "None" return end
				if args.multiselect then
                    if type(value) == "string" then
                        if not table.find(library.options[args.flag].values,value) then return end
                        if table.find(library.flags[args.flag],value) then
                            for i,v in pairs(library.flags[args.flag]) do
                                if v == value then
                                    table.remove(library.flags[args.flag],i)
                                end
                            end
                        else
                            table.insert(library.flags[args.flag],value)
                        end
                    else
                        library.flags[args.flag] = value
                    end
					local buttonText = ""
					for i,v in pairs(library.flags[args.flag]) do
						local jig = i ~= #library.flags[args.flag] and "," or ""
						buttonText = buttonText..v..jig
					end
                    if buttonText == "" then buttonText = "..." end
					for i,v in next, holder:GetChildren() do
						if v.ClassName ~= "Frame" then continue end
						v.off.TextColor3 = Color3.new(0.65,0.65,0.65)
						for _i,_v in next, library.flags[args.flag] do
							if v.Name == _v then
								v.off.TextColor3 = Color3.new(1,1,1)
							end
						end
					end
					valuetext.Text = buttonText
					if args.callback then
						args.callback(library.flags[args.flag])
					end
				else
                    if not table.find(library.options[args.flag].values,value) then value = library.options[args.flag].values[1] end
                    library.flags[args.flag] = value
					for i,v in next, holder:GetChildren() do
						if v.ClassName ~= "Frame" then continue end
						v.off.TextColor3 = Color3.new(0.65,0.65,0.65)
                        if v.Name == library.flags[args.flag] then
                            v.off.TextColor3 = Color3.new(1,1,1)
                        end
					end
					frame.Visible = false
                    if library.flags[args.flag] then
                        valuetext.Text = library.flags[args.flag]
                        if args.callback then
                            args.callback(library.flags[args.flag])
                        end
                    end
				end
			end

            function refresh(tbl)
                for i,v in next, holder:GetChildren() do
                    if v.ClassName == "Frame" then
                        v:Destroy()
                    end
					frame.Size = UDim2.new(0, 203, 0, 0)
                end
                for i,v in pairs(tbl) do
                    frame.Size += UDim2.new(0, 0, 0, 20)

                    local option = Instance.new("Frame")
                    local button_2 = Instance.new("TextButton")
                    local text_2 = Instance.new("TextLabel")

                    option.Name = v
                    option.Parent = holder
                    option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    option.BackgroundTransparency = 1.000
                    option.Size = UDim2.new(1, 0, 0, 20)

                    button_2.Name = "button"
                    button_2.Parent = option
                    button_2.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                    button_2.BackgroundTransparency = 0.850
                    button_2.BorderSizePixel = 0
                    button_2.Size = UDim2.new(1, 0, 1, 0)
                    button_2.Font = Enum.Font.SourceSans
                    button_2.Text = ""
                    button_2.TextColor3 = Color3.fromRGB(0, 0, 0)
                    button_2.TextSize = 14.000

                    text_2.Name = "off"
                    text_2.Parent = option
                    text_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    text_2.BackgroundTransparency = 1.000
                    text_2.Position = UDim2.new(0, 4, 0, 0)
                    text_2.Size = UDim2.new(0, 0, 1, 0)
                    text_2.Font = Enum.Font.Code
                    text_2.Text = v
                    text_2.TextColor3 = args.multiselect and Color3.new(0.65,0.65,0.65) or Color3.new(1,1,1)
                    text_2.TextSize = 14.000
                    text_2.TextStrokeTransparency = 0.000
                    text_2.TextXAlignment = Enum.TextXAlignment.Left
    
                    button_2.MouseButton1Click:Connect(function()
                        updateValue(v)
                    end)
                end
                library.options[args.flag].values = tbl
                local currentVal = library.flags[args.flag]
                if currentVal and currentVal ~= "" and table.find(tbl, currentVal) then
                    updateValue(currentVal)
                else
                    updateValue(tbl[1])
                end
            end

            button.MouseButton1Click:Connect(function()
                if not library.colorpicking then
                    frame.Visible = not frame.Visible
                end
            end)
            button.MouseEnter:connect(function()
                main.BorderColor3 = library.libColor
			end)
			button.MouseLeave:connect(function()
                main.BorderColor3 = Color3.fromRGB(60, 60, 60)
			end)
            
            table.insert(library.toInvis,frame)
            library.flags[args.flag] = args.multiselect and {} or ""
            library.options[args.flag] = {type = "list",changeState = updateValue,values = args.values,refresh = refresh,skipflag = args.skipflag,oldargs = args}

            refresh(args.values)
            updateValue(args.value or not args.multiselect and args.values[1] or "abcdefghijklmnopqrstuwvxyz")
        end
        function group:addConfigbox(args)
            if not args.flag or not args.values then return warn("⚠️ incorrect arguments ⚠️") end
            groupbox.Size += UDim2.new(0, 0, 0, 138)
            library.multiZindex -= 1
            
            local list2 = Instance.new("Frame")
            local frame = Instance.new("Frame")
            local main = Instance.new("Frame")
            local holder = Instance.new("ScrollingFrame")
            local UIListLayout = Instance.new("UIListLayout")
            local dwn = Instance.new("ImageLabel")
            local up = Instance.new("ImageLabel")
        
            list2.Name = "list2"
            list2.Parent = grouper
            list2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            list2.BackgroundTransparency = 1.000
            list2.BorderSizePixel = 0
            list2.Position = UDim2.new(0, 0, 0.108108111, 0)
            list2.Size = UDim2.new(1, 0, 0, 138)
            
            frame.Name = "frame"
            frame.Parent = list2
            frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            frame.BorderSizePixel = 2
            frame.Position = UDim2.new(0.02, -1, 0.0439999998, 0)
            frame.Size = UDim2.new(0, 205, 0, 128)
            
            main.Name = "main"
            main.Parent = frame
            main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            main.BorderColor3 = Color3.fromRGB(30,30,30)
            main.Size = UDim2.new(1, 0, 1, 0)
            
            holder.Name = "holder"
            holder.Parent = main
            holder.Active = true
            holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            holder.BackgroundTransparency = 1.000
            holder.BorderSizePixel = 0
            holder.Position = UDim2.new(0, 0, 0.00571428565, 0)
            holder.Size = UDim2.new(1, 0, 1, 0)
            holder.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
            holder.CanvasSize = UDim2.new(0, 0, 0, 0)
            holder.ScrollBarThickness = 0
            holder.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
            holder.AutomaticCanvasSize = Enum.AutomaticSize.Y
            holder.ScrollingEnabled = true
            holder.ScrollBarImageTransparency = 0
            
            UIListLayout.Parent = holder
            
            dwn.Name = "dwn"
            dwn.Parent = frame
            dwn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            dwn.BackgroundTransparency = 1.000
            dwn.BorderColor3 = Color3.fromRGB(0, 0, 0)
            dwn.BorderSizePixel = 0
            dwn.Position = UDim2.new(0.930000007, 4, 1, -9)
            dwn.Size = UDim2.new(0, 7, 0, 6)
            dwn.ZIndex = 3
            dwn.Image = "rbxassetid://8548723563"
            dwn.Visible = false
            
            up.Name = "up"
            up.Parent = frame
            up.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            up.BackgroundTransparency = 1.000
            up.BorderColor3 = Color3.fromRGB(0, 0, 0)
            up.BorderSizePixel = 0
            up.Position = UDim2.new(0, 3, 0, 3)
            up.Size = UDim2.new(0, 7, 0, 6)
            up.ZIndex = 3
            up.Image = "rbxassetid://8548757311"
            up.Visible = false

            local function updateValue(value)
                if value == nil then return end
                if not table.find(library.options[args.flag].values,value) then value = library.options[args.flag].values[1] end
                library.flags[args.flag] = value
        
                for i,v in next, holder:GetChildren() do
                    if v.ClassName ~= "Frame" then continue end
                    if v.text.Text == library.flags[args.flag] then
                        v.text.TextColor3 = library.libColor
                    else
                        v.text.TextColor3 = Color3.fromRGB(255,255,255)
                    end
                end
                if library.flags[args.flag] then
                    if args.callback then
                        args.callback(library.flags[args.flag])
                    end
                end
                holder.Visible = true
            end
            table.insert(library.onAccentChanged, function()
                for i,v in next, holder:GetChildren() do
                    if v.ClassName ~= "Frame" then continue end
                    if v.text.Text == library.flags[args.flag] then
                        v.text.TextColor3 = library.libColor
                    end
                end
            end)
            holder:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                up.Visible = (holder.CanvasPosition.Y > 1)
                dwn.Visible = (holder.CanvasPosition.Y + 1 < (holder.AbsoluteCanvasSize.Y - holder.AbsoluteSize.Y))
            end)
        
        
            function refresh(tbl)
                for i,v in next, holder:GetChildren() do
                    if v.ClassName == "Frame" then
                        v:Destroy()
                    end
                end
                for i,v in pairs(tbl) do
                    local item = Instance.new("Frame")
                    local button = Instance.new("TextButton")
                    local text = Instance.new("TextLabel")
        
                    item.Name = v
                    item.Parent = holder
                    item.Active = true
                    item.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    item.BackgroundTransparency = 1.000
                    item.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    item.BorderSizePixel = 0
                    item.Size = UDim2.new(1, 0, 0, 18)
                    
                    button.Parent = item
                    button.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
                    button.BackgroundTransparency = 1
                    button.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    button.BorderSizePixel = 0
                    button.Size = UDim2.new(1, 0, 1, 0)
                    button.Text = ""
                    button.TextTransparency = 1.000
                    
                    text.Name = 'text'
                    text.Parent = item
                    text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    text.BackgroundTransparency = 1.000
                    text.Size = UDim2.new(1, 0, 0, 18)
                    text.Font = Enum.Font.Code
                    text.Text = v
                    text.TextColor3 = Color3.fromRGB(255, 255, 255)
                    text.TextSize = 14.000
                    text.TextStrokeTransparency = 0.000
        
                    button.MouseButton1Click:Connect(function()
                        updateValue(v)
                    end)
                end
        
                holder.Visible = true
                library.options[args.flag].values = tbl
                updateValue(table.find(library.options[args.flag].values,library.flags[args.flag]) and library.flags[args.flag] or library.options[args.flag].values[1])
            end
        
        
            library.flags[args.flag] = ""
            library.options[args.flag] = {type = "cfg",changeState = updateValue,values = args.values,refresh = refresh,skipflag = args.skipflag,oldargs = args}
        
            refresh(args.values)
            updateValue(args.value or not args.multiselect and args.values[1] or "abcdefghijklmnopqrstuwvxyz")
        end
        function group:addColorpicker(args)
            if not args.flag then return warn("⚠️ incorrect arguments ⚠️") end
            groupbox.Size += UDim2.new(0, 0, 0, 20)
        
            library.multiZindex -= 1
            jigCount -= 1
            topStuff -= 1

            local colorpicker = Instance.new("Frame")
            local back = Instance.new("Frame")
            local mid = Instance.new("Frame")
            local front = Instance.new("Frame")
            local text = Instance.new("TextLabel")
            local colorpicker_2 = Instance.new("Frame")
            local button = Instance.new("TextButton")

            local colorFrame = Instance.new("Frame")
			local colorFrame_2 = Instance.new("Frame")
			local hueframe = Instance.new("Frame")
			local main = Instance.new("Frame")
			local hue = Instance.new("ImageLabel")
			local pickerframe = Instance.new("Frame")
			local main_2 = Instance.new("Frame")
			local picker = Instance.new("ImageLabel")
			local clr = Instance.new("Frame")
			local copy = Instance.new("TextButton")

            colorpicker.Name = "colorpicker"
            colorpicker.Parent = grouper
            colorpicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            colorpicker.BackgroundTransparency = 1.000
            colorpicker.BorderSizePixel = 0
            colorpicker.Size = UDim2.new(1, 0, 0, 20)
            colorpicker.ZIndex = topStuff

            text.Name = "text"
            text.Parent = colorpicker
            text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            text.BackgroundTransparency = 1.000
            text.Position = UDim2.new(0.02, -1, 0, 10)
            text.Font = Enum.Font.Code
            text.Text = args.text or args.flag
            text.TextColor3 = Color3.fromRGB(244, 244, 244)
            text.TextSize = 13.000
            text.TextStrokeTransparency = 0.000
            text.TextXAlignment = Enum.TextXAlignment.Left

            button.Name = "button"
            button.Parent = colorpicker
            button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            button.BackgroundTransparency = 1.000
            button.BorderSizePixel = 0
            button.Size = UDim2.new(1, 0, 1, 0)
            button.Font = Enum.Font.SourceSans
            button.Text = ""
            button.TextColor3 = Color3.fromRGB(0, 0, 0)
            button.TextSize = 14.000

            colorpicker_2.Name = "colorpicker"
            colorpicker_2.Parent = colorpicker
            colorpicker_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            colorpicker_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
            colorpicker_2.BorderSizePixel = 3
            colorpicker_2.Position = UDim2.new(0.860000014, 4, 0.272000015, 0)
            colorpicker_2.Size = UDim2.new(0, 20, 0, 10)

            mid.Name = "mid"
            mid.Parent = colorpicker_2
            mid.BackgroundColor3 = Color3.fromRGB(69, 23, 255)
            mid.BorderColor3 = Color3.fromRGB(30,30,30)
            mid.BorderSizePixel = 2
            mid.Size = UDim2.new(1, 0, 1, 0)

            front.Name = "front"
            front.Parent = mid
            front.BackgroundColor3 = Color3.fromRGB(240, 142, 214)
            front.BorderColor3 = Color3.fromRGB(0, 0, 0)
            front.Size = UDim2.new(1, 0, 1, 0)

            button.Name = "button"
            button.Parent = colorpicker
            button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            button.BackgroundTransparency = 1.000
            button.Size = UDim2.new(0, 202, 0, 22)
            button.Font = Enum.Font.SourceSans
            button.Text = ""
			button.ZIndex = args.ontop and topStuff or jigCount
            button.TextColor3 = Color3.fromRGB(0, 0, 0)
            button.TextSize = 14.000

			colorFrame.Name = "colorFrame"
			colorFrame.Parent = colorpicker
			colorFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			colorFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
			colorFrame.BorderSizePixel = 2
			colorFrame.Position = UDim2.new(0.101092957, 0, 0.75, 0)
			colorFrame.Size = UDim2.new(0, 137, 0, 128)

			colorFrame_2.Name = "colorFrame"
			colorFrame_2.Parent = colorFrame
			colorFrame_2.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			colorFrame_2.BorderColor3 = Color3.fromRGB(60, 60, 60)
			colorFrame_2.Size = UDim2.new(1, 0, 1, 0)

			hueframe.Name = "hueframe"
			hueframe.Parent = colorFrame_2
            hueframe.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
            hueframe.BorderColor3 = Color3.fromRGB(60, 60, 60)
            hueframe.BorderSizePixel = 2
            hueframe.Position = UDim2.new(-0.0930000022, 18, -0.0599999987, 30)
            hueframe.Size = UDim2.new(0, 100, 0, 100)

            main.Name = "main"
            main.Parent = hueframe
            main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            main.BorderColor3 = Color3.fromRGB(0, 0, 0)
            main.Size = UDim2.new(0, 100, 0, 100)
            main.ZIndex = 6

            picker.Name = "picker"
            picker.Parent = main
            picker.BackgroundColor3 = Color3.fromRGB(232, 0, 255)
            picker.BorderColor3 = Color3.fromRGB(0, 0, 0)
            picker.BorderSizePixel = 0
            picker.Size = UDim2.new(0, 100, 0, 100)
            picker.ZIndex = 104
            picker.Image = "rbxassetid://2615689005"

            pickerframe.Name = "pickerframe"
            pickerframe.Parent = colorFrame
            pickerframe.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
            pickerframe.BorderColor3 = Color3.fromRGB(60, 60, 60)
            pickerframe.BorderSizePixel = 2
            pickerframe.Position = UDim2.new(0.711000025, 14, -0.0599999987, 30)
            pickerframe.Size = UDim2.new(0, 20, 0, 100)

            main_2.Name = "main"
            main_2.Parent = pickerframe
            main_2.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            main_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
            main_2.Size = UDim2.new(0, 20, 0, 100)
            main_2.ZIndex = 6

            hue.Name = "hue"
            hue.Parent = main_2
            hue.BackgroundColor3 = Color3.fromRGB(255, 0, 178)
            hue.BorderColor3 = Color3.fromRGB(0, 0, 0)
            hue.BorderSizePixel = 0
            hue.Size = UDim2.new(0, 20, 0, 100)
            hue.ZIndex = 104
            hue.Image = "rbxassetid://2615692420"

            clr.Name = "clr"
            clr.Parent = colorFrame
            clr.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            clr.BackgroundTransparency = 1.000
            clr.BorderColor3 = Color3.fromRGB(60, 60, 60)
            clr.BorderSizePixel = 2
            clr.Position = UDim2.new(0.0280000009, 0, 0, 2)
            clr.Size = UDim2.new(0, 129, 0, 14)
            clr.ZIndex = 5

            copy.Name = "copy"
            copy.Parent = clr
            copy.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            copy.BackgroundTransparency = 1.000
            copy.BorderSizePixel = 0
            copy.Size = UDim2.new(0, 129, 0, 14)
            copy.ZIndex = 5
            copy.Font = Enum.Font.Code
            copy.Text = args.text or args.flag
            copy.TextColor3 = Color3.fromRGB(100, 100, 100)
            copy.TextSize = 14.000
            copy.TextStrokeTransparency = 0.000
            
            copy.MouseButton1Click:Connect(function()
                colorFrame.Visible = false
            end)

            button.MouseButton1Click:Connect(function()
				colorFrame.Visible = not colorFrame.Visible
                mid.BorderColor3 = Color3.fromRGB(30,30,30)
            end)

            button.MouseEnter:connect(function()
                mid.BorderColor3 = library.libColor
            end)
            button.MouseLeave:connect(function()
                mid.BorderColor3 = Color3.fromRGB(30,30,30)
            end)

            -- Right-click context menu for copy/paste color
            button.MouseButton2Click:Connect(function()
                library:showColorContextMenu(nil, args.flag, function(color)
                    front.BackgroundColor3 = color
                    library.flags[args.flag] = color
                    if args.callback then args.callback(color) end
                end)
            end)

            local function updateValue(value,fakevalue)
                if typeof(value) == "table" then value = fakevalue end
                library.flags[args.flag] = value
                front.BackgroundColor3 = value
                if args.callback then
                    args.callback(value)
                end
			end

            local white, black = Color3.new(1,1,1), Color3.new(0,0,0)
            local colors = {Color3.new(1,0,0),Color3.new(1,1,0),Color3.new(0,1,0),Color3.new(0,1,1),Color3.new(0,0,1),Color3.new(1,0,1),Color3.new(1,0,0)}
            local heartbeat = game:GetService("RunService").Heartbeat

            local pickerX,pickerY,hueY = 0,0,0
            local oldpercentX,oldpercentY = 0,0

            -- Initialize picker from args.color so it doesn't show a solid wrong color
            do
                local initColor = args.color or Color3.new(1,1,1)
                local h, s, v = colorToHSV(initColor)
                picker.BackgroundColor3 = hueToColor(h)
                oldpercentX = s
                oldpercentY = 1 - v
            end

            hue.MouseEnter:Connect(function()
                local input = hue.InputBegan:connect(function(key)
                    if key.UserInputType == Enum.UserInputType.MouseButton1 then
                        while heartbeat:wait() and inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            library.colorpicking = true
                            local percent = (hueY-hue.AbsolutePosition.Y-36)/hue.AbsoluteSize.Y
                            local num = math.max(1, math.min(7,math.floor(((percent*7+0.5)*100))/100))
                            local startC = colors[math.floor(num)]
                            local endC = colors[math.ceil(num)]
                            local color = white:lerp(picker.BackgroundColor3, oldpercentX):lerp(black, oldpercentY)
                            picker.BackgroundColor3 = startC:lerp(endC, num-math.floor(num)) or Color3.new(0, 0, 0)
                            updateValue(color)
                        end
                        library.colorpicking = false
                    end
                end)
                local leave
                leave = hue.MouseLeave:connect(function()
                    input:disconnect()
                    leave:disconnect()
                end)
            end)

            picker.MouseEnter:Connect(function()
                local input = picker.InputBegan:connect(function(key)
                    if key.UserInputType == Enum.UserInputType.MouseButton1 then
                        while heartbeat:wait() and inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            library.colorpicking = true
                            local xPercent = (pickerX-picker.AbsolutePosition.X)/picker.AbsoluteSize.X
                            local yPercent = (pickerY-picker.AbsolutePosition.Y-36)/picker.AbsoluteSize.Y
                            local color = white:lerp(picker.BackgroundColor3, xPercent):lerp(black, yPercent)
                            updateValue(color)
                            oldpercentX,oldpercentY = xPercent,yPercent
                        end
                        library.colorpicking = false
                    end
                end)
                local leave
                leave = picker.MouseLeave:connect(function()
                    input:disconnect()
                    leave:disconnect()
                end)
            end)

            hue.MouseMoved:connect(function(_, y)
                hueY = y
            end)

            picker.MouseMoved:connect(function(x, y)
                pickerX,pickerY = x,y
            end)

            table.insert(library.toInvis,colorFrame)
            library.flags[args.flag] = Color3.new(1,1,1)
            library.options[args.flag] = {type = "colorpicker",changeState = updateValue,skipflag = args.skipflag,oldargs = args}

            updateValue(args.color or Color3.new(1,1,1))
        end
        function group:addKeybind(args)
            if not args.flag then return warn("⚠️ incorrect arguments ⚠️ - missing args on toggle:keybind") end
            groupbox.Size += UDim2.new(0, 0, 0, 20)
            local next = false
            
            local keybind = Instance.new("Frame")
            local text = Instance.new("TextLabel")
            local button_bg = Instance.new("Frame")
            local button_main = Instance.new("Frame")
            local button = Instance.new("TextButton")

            keybind.Parent = grouper
            keybind.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            keybind.BackgroundTransparency = 1.000
            keybind.BorderSizePixel = 0
            keybind.Size = UDim2.new(1, 0, 0, 20)
            
            text.Parent = keybind
            text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            text.BackgroundTransparency = 1.000
            text.Position = UDim2.new(0.02, -1, 0, 10)
            text.Font = Enum.Font.Code
            text.Text = args.text or args.flag
            text.TextColor3 = Color3.fromRGB(244, 244, 244)
            text.TextSize = 13.000
            text.TextStrokeTransparency = 0.000
            text.TextXAlignment = Enum.TextXAlignment.Left
            
            button_bg.Name = "bg"
            button_bg.Parent = keybind
            button_bg.BackgroundColor3 = Color3.fromRGB(15,15,15)
            button_bg.BorderColor3 = Color3.fromRGB(0, 0, 0)
            button_bg.BorderSizePixel = 2
            button_bg.AnchorPoint = Vector2.new(1, 0)
            button_bg.Position = UDim2.new(1, -6, 0, 3)
            button_bg.Size = UDim2.new(0, 50, 0, 15)

            button_main.Name = "main"
            button_main.Parent = button_bg
            button_main.BackgroundColor3 = Color3.fromRGB(15,15,15)
            button_main.BorderColor3 = Color3.fromRGB(30, 30, 30)
            button_main.Size = UDim2.new(1, 0, 1, 0)
            
            button.Parent = button_main
            button.BackgroundColor3 = Color3.fromRGB(187, 131, 255)
            button.BackgroundTransparency = 1.000
            button.BorderSizePixel = 0
            button.Size = UDim2.new(1, 0, 1, 0)
            button.Font = Enum.Font.Code
            button.Text = "--"
            button.TextColor3 = Color3.fromRGB(155, 155, 155)
            button.TextSize = 13.000
            button.TextStrokeTransparency = 0.000
            button.TextXAlignment = Enum.TextXAlignment.Center

            function updateValue(val)
                if library.colorpicking then return end
                library.flags[args.flag] = val
                if val == Enum.KeyCode.Unknown then
                    button.Text = "none"
                else
                    button.Text = keyNames[val] or val.Name
                end
            end
            inputService.InputBegan:Connect(function(key)
                local key = key.KeyCode == Enum.KeyCode.Unknown and key.UserInputType or key.KeyCode
                if next then
                    if key == Enum.KeyCode.Escape then
                        next = false
                        library.flags[args.flag] = Enum.KeyCode.Unknown
                        button.Text = "none"
                        button.TextColor3 = Color3.fromRGB(155, 155, 155)
                        return
                    end
                    if not table.find(library.blacklisted,key) then
                        next = false
                        library.flags[args.flag] = key
                        button.Text = keyNames[key] or key.Name
                        button.TextColor3 = Color3.fromRGB(155, 155, 155)
                    end
                end
                if not next and key == library.flags[args.flag] and args.callback then
                    args.callback()
                end
            end)

            button.MouseButton1Click:Connect(function()
                if library.colorpicking then return end
                library.flags[args.flag] = Enum.KeyCode.Unknown
                button.Text = "..."
                button.TextColor3 = Color3.new(0.2,0.2,0.2)
                next = true
            end)
            
            if not args.nocontext then
                button.MouseButton2Click:Connect(function()
                    if library.colorpicking then return end
                    library:showKeybindContextMenu(nil, args.flag, function(mode)
                        library.options[args.flag].mode = mode
                    end)
                end)
            end

            library.flags[args.flag] = Enum.KeyCode.Unknown
            library.options[args.flag] = {type = "keybind", mode = "Always", changeState = updateValue, skipflag = args.skipflag, oldargs = args}

            updateValue(args.key or Enum.KeyCode.Unknown)
        end
        return group, groupbox
    end

    function tab:createTabbedGroup(pos, tabNames)
        local wrapper = Instance.new("Frame")
        wrapper.Parent = newTab[pos]
        wrapper.BackgroundTransparency = 1
        wrapper.Size = UDim2.new(0, 211, 0, 20)

        local tabContainer = Instance.new("Frame")
        tabContainer.Parent = wrapper
        tabContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        tabContainer.BorderColor3 = Color3.fromRGB(30, 30, 30)
        tabContainer.BorderSizePixel = 2
        tabContainer.Size = UDim2.new(1, 0, 0, 20)
        tabContainer.Position = UDim2.new(0, 0, 0, 1)
        tabContainer.ZIndex = 3
        
        local tabLayout = Instance.new("UIListLayout")
        tabLayout.Parent = tabContainer
        tabLayout.FillDirection = Enum.FillDirection.Horizontal
        
        local accent = Instance.new("Frame")
        accent.Parent = wrapper
        accent.BackgroundColor3 = library.libColor
        table.insert(library.accentElements, {obj = accent, prop = "BackgroundColor3"})
        accent.BorderSizePixel = 0
        accent.Size = UDim2.new(1, 0, 0, 1)
        accent.ZIndex = 4
        
        local btnWidth = 211 / #tabNames
        local tabGroups = {}
        local tabBoxes = {}
        local tabButtons = {}
        
        for i, tName in ipairs(tabNames) do
            local btn = Instance.new("TextButton")
            btn.Parent = tabContainer
            btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            btn.BackgroundTransparency = i == 1 and 0 or 0.4
            btn.BorderSizePixel = 0
            btn.Size = UDim2.new(0, btnWidth, 1, 0)
            btn.Font = Enum.Font.Code
            btn.Text = string.lower(tName)
            btn.TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
            btn.TextSize = 13
            btn.ZIndex = 4
            tabButtons[i] = btn
            
            if i < #tabNames then
                local div = Instance.new("Frame")
                div.Parent = btn
                div.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                div.BorderSizePixel = 0
                div.Size = UDim2.new(0, 2, 1, 0)
                div.Position = UDim2.new(1, -1, 0, 0)
                div.ZIndex = 5
            end

            local group, groupbox = tab:createGroup(pos, tName)
            tabGroups[tName] = group
            tabBoxes[i] = groupbox
            
            groupbox.Parent = wrapper
            groupbox.Position = UDim2.new(0, 0, 0, 21)
            groupbox.ZIndex = 2
            
            local title = groupbox:FindFirstChild("TextLabel")
            if title then title.Visible = false end
            for _, c in ipairs(groupbox:GetChildren()) do
                if c.ClassName == "Frame" and c.BackgroundColor3 == Color3.fromRGB(20,20,20) and c.Size.Y.Offset == 3 then
                    c.Visible = false
                end
                if c.ClassName == "Frame" and c.BackgroundColor3 == library.libColor then
                    c.Visible = false
                end
            end
            
            groupbox:GetPropertyChangedSignal("Size"):Connect(function()
                if groupbox.Visible then
                    wrapper.Size = UDim2.new(0, 211, 0, groupbox.Size.Y.Offset + 21)
                end
            end)
            
            groupbox.Visible = i == 1
            
            btn.MouseButton1Click:Connect(function()
                for j, b in ipairs(tabButtons) do
                    b.BackgroundTransparency = j == i and 0 or 0.4
                    b.TextColor3 = j == i and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
                    tabBoxes[j].Visible = j == i
                end
                wrapper.Size = UDim2.new(0, 211, 0, groupbox.Size.Y.Offset + 21)
            end)
        end
        
        return tabGroups
    end
    return tab
end

function contains(list, x)
	for _, v in pairs(list) do
		if v == x then return true end
	end
	return false
end

function library:createConfig()
    local name = library.flags["config_name"]
    if contains(library.options["selected_config"].values, name) then return library:notify(name..".cfg already exists") end
    if name == "" then return library:notify("No name present") end
    local jig = {}
    for i,v in next, library.flags do
        if library.options[i].skipflag then continue end
        if type(v) == "boolean" or type(v) == "string" or type(v) == "number" or type(v) == "table" then
            jig[i] = v
        elseif typeof(v) == "Color3" then
            jig[i] = {v.R,v.G,v.B}
        elseif typeof(v) == "EnumItem" then
            jig[i] = {string.split(tostring(v),".")[2],string.split(tostring(v),".")[3]}
        end
    end
    pcall(function()
        writefile("swag/"..name..".cfg",game:GetService("HttpService"):JSONEncode(jig))
        library:notify("Succesfully created config "..name..".cfg.")
        library:refreshConfigs()
    end)
end

function library:saveConfig()
    local name = library.flags["selected_config"]
    if not name or name == "" then
        return library:notify("No config selected to overwrite.")
    end
    local jig = {}
    for i,v in next, library.flags do
        if library.options[i].skipflag then continue end
        if type(v) == "boolean" or type(v) == "string" or type(v) == "number" or type(v) == "table" then
            jig[i] = v
        elseif typeof(v) == "Color3" then
            jig[i] = {v.R,v.G,v.B}
        elseif typeof(v) == "EnumItem" then
            jig[i] = {string.split(tostring(v),".")[2],string.split(tostring(v),".")[3]}
        end
    end
    pcall(function()
        writefile("swag/"..name..".cfg",game:GetService("HttpService"):JSONEncode(jig))
        library:notify("Succesfully updated config "..name..".cfg.")
        library:refreshConfigs()
    end)
end

function library:loadConfig()
    local name = library.flags["selected_config"]
    if not name or name == "" then
        library:notify("No config selected.")
        return
    end
    if not isfile("swag/"..name..".cfg") then
        library:notify("Config file not found.")
        return
    end
    local config = game:GetService("HttpService"):JSONDecode(readfile("swag/"..name..".cfg"))
    local skipKeys = {["selected_config"] = true, ["config_name"] = true}
    for i,v in next, library.options do
        if skipKeys[i] then continue end
        spawn(function()pcall(function()
            if config[i] then
                if v.type == "colorpicker" then
                    v.changeState(Color3.new(config[i][1],config[i][2],config[i][3]))
                elseif v.type == "keybind" then
                    v.changeState(Enum[config[i][1]][config[i][2]])
                else
                    if config[i] ~= library.flags[i] then
                        v.changeState(config[i])
                    end
                end
            else
                if v.type == "toggle" then
                    v.changeState(false)
                elseif v.type == "slider" then
                    v.changeState(v.oldargs.value or 0)
                elseif v.type == "textbox" or v.type == "list" or v.type == "cfg" then
                    v.changeState(v.oldargs.value or v.oldargs.text or "")
                elseif v.type == "colorpicker" then
                    v.changeState(v.oldargs.color or Color3.new(1,1,1))
                elseif v.type == "keybind" then
                    v.changeState(v.oldargs.key or Enum.KeyCode.Unknown)
                end
            end
        end)end)
    end
    library:notify("Succesfully loaded config "..name..".cfg.")
end

function library:refreshConfigs()
    local tbl = {}
    for i,v in next, listfiles("swag") do
        local name = v:match("[/\\]?([^/\\]+)$") or v
        name = name:gsub("%.cfg$", "")
        if name ~= "" then
            table.insert(tbl, name)
        end
    end
    library.options["selected_config"].refresh(tbl)
end

function library:deleteConfig()
    local name = library.flags["selected_config"]
    if not name or name == "" then return end
    if isfile("swag/"..name..".cfg") then
        delfile("swag/"..name..".cfg")
        library:refreshConfigs()
        library:notify("Deleted "..name..".cfg.")
    end
end

function library:setAutoload()
    local name = library.flags["selected_config"]
    if not name or name == "" then return library:notify("No config selected.") end
    if not isfile("swag/"..name..".cfg") then return library:notify("Config file not found.") end
    writefile("swag/autoload.txt", name)
    library:notify("Autoload set to "..name..".cfg.")
end

function library:removeAutoload()
    if isfile("swag/autoload.txt") then
        delfile("swag/autoload.txt")
        library:notify("Autoload removed.")
    else
        library:notify("No autoload is set.")
    end
end

function library:getAutoload()
    if isfile("swag/autoload.txt") then
        local content = readfile("swag/autoload.txt")
        return content:gsub("[\n\r]", ""):gsub("^%s*(.-)%s*$", "%1")
    end
    return nil
end
function library:getTab(name)
    return library.tabsData[name]
end

function library:loadAutoConfig()
    local name = library:getAutoload()
    if name and name ~= "" and isfile("swag/"..name..".cfg") then
        library.flags["selected_config"] = name
        if library.options["selected_config"] and library.options["selected_config"].changeState then
            library.options["selected_config"].changeState(name)
        end
        library:loadConfig()
    end
end

local mainTab = library:addTab("Main")
local espTab = library:addTab("ESP")
local visualsTab = library:addTab("Visuals")
local miscTab = library:addTab("Misc")
local settingsTab = library:addTab("Settings")

local configs = settingsTab:createGroup('left', 'Configs')
local uisettings = settingsTab:createGroup('center', 'UI Settings')
local notifysettings = settingsTab:createGroup('center', 'Notifications')
local othersettings = settingsTab:createGroup('right', 'Extra')

configs:addTextbox({text = "Config Name",flag = "config_name",skipflag = true})
configs:addList({text = "Config List",flag = "selected_config",values = {},skipflag = true})
configs:addDivider()
configs:addButtonRow({
    {text = "Create", callback = function() library:createConfig() end},
    {text = "Load", callback = function() library:loadConfig() end}
})

do -- Overwrite button with confirmation
    local overwriteConfirming = false
    configs:addButtonRow({
        {text = "Overwrite", callback = function()
            if overwriteConfirming then
                overwriteConfirming = false
                library:saveConfig()
            else
                overwriteConfirming = true
                library:notify("Press Overwrite again to confirm.")
                spawn(function()
                    wait(3)
                    overwriteConfirming = false
                end)
            end
        end}
    })
end

configs:addButtonRow({
    {text = "Refresh", callback = function() library:refreshConfigs() end}
})

do -- Delete button with confirmation
    local deleteConfirming = false
    configs:addButtonRow({
        {text = "Delete", callback = function()
            if deleteConfirming then
                deleteConfirming = false
                library:deleteConfig()
            else
                deleteConfirming = true
                library:notify("Press Delete again to confirm.")
                spawn(function()
                    wait(3)
                    deleteConfirming = false
                end)
            end
        end}
    })
end
configs:addButtonRow({
    {text = "Set Autoload", callback = function() library:setAutoload() end},
    {text = "Remove Autoload", callback = function() library:removeAutoload() end}
})

uisettings:addToggle({text = "Show Game Name",flag = "show game name",noarray = true,callback = function(state)
    updateTitle()
end})
uisettings:addToggle({text = "Show Keybinds",flag = "show keybinds",noarray = true})
uisettings:addToggle({text = "Show Arraylist",flag = "show arraylist",noarray = true})
uisettings:addToggle({text = "Show Watermark",flag = "show watermark",noarray = true})
uisettings:addColorpicker({text = "Menu Accent",ontop = true,flag = "menuaccent",color = library.libColor,callback = function(color)
    updateAccentColor(color)
end})
uisettings:addKeybind({text = "Menu Toggle",flag = "MenuKeybind",key = Enum.KeyCode.RightShift,nocontext = true})

notifysettings:addSlider({text = "Max Stack",flag = "notify_max_stack",min = 1,max = 64,value = 64},"")
notifysettings:addToggle({text = "Show Dummy",flag = "notify_show_dummy",noarray = true,callback = function(state)
    if library.dummyFrame then library.dummyFrame.Visible = state end
    if library.alignAssistContainer then library.alignAssistContainer.Visible = state end
    library:updateNotifyPosition()
end})
notifysettings:addList({text = "Animation",flag = "notify_animation",values = {"Slide","Fade"},value = "Slide"})
notifysettings:addSlider({text = "Duration",flag = "notify_duration",min = 1,max = 10,value = 3},"s")
notifysettings:addList({text = "Alignment",flag = "notify_alignment",values = {"Left","Center","Right"},value = "Left",callback = function()
    library:updateNotifyPosition()
end})
notifysettings:addButton({text = "Test Notification",callback = function()
    library:notify("This is a test notification.")
end})

othersettings:addButton({text = "Copy Game Invite",callback = function()
    pcall(function() setclipboard(tostring(game.JobId)) end)
    library:notify("Copied JobId to clipboard!")
end})
othersettings:addButton({text = "Rejoin Server",callback = function()
    library:notify("Rejoining server...")
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
end})
othersettings:addButton({text = "Server Hop",callback = function()
    library:notify("Hopping server...")
    spawn(function()
        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")
        local req = request or syn and syn.request or http_request or fluxus and fluxus.request or (http and http.request)
        if req then
            local success, res = pcall(function()
                return req({Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"})
            end)
            if success and res and res.Body then
                local servers = HttpService:JSONDecode(res.Body)
                for _, v in pairs(servers.data) do
                    if v.playing < v.maxPlayers and v.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, game.Players.LocalPlayer)
                        break
                    end
                end
            end
        else
            library:notify("Exploit does not support HTTP requests.")
        end
    end)
end})

othersettings:addDivider()
othersettings:addButtonRow({
    {text = "Unload", callback = function()
        if library.Unloaded then return end
        library.Unloaded = true
        if library.OnUnload then pcall(library.OnUnload) end
        if getgenv and getgenv().swagpro_unload then pcall(getgenv().swagpro_unload) end
        
        if menu then menu:Destroy() end
        if notifySGui then notifySGui:Destroy() end
        if library._colorCtxMenu then library._colorCtxMenu:Destroy() end
        if library._ctxOverlay then library._ctxOverlay:Destroy() end
        if library._keybindCtxMenu then library._keybindCtxMenu:Destroy() end
    end},
    {text = "Reload", callback = function()
        if library.Unloaded then return end
        library.Unloaded = true
        if library.OnUnload then pcall(library.OnUnload) end
        if getgenv and getgenv().swagpro_unload then pcall(getgenv().swagpro_unload) end
        
        if menu then menu:Destroy() end
        if notifySGui then notifySGui:Destroy() end
        if library._colorCtxMenu then library._colorCtxMenu:Destroy() end
        if library._ctxOverlay then library._ctxOverlay:Destroy() end
        if library._keybindCtxMenu then library._keybindCtxMenu:Destroy() end
        
        task.wait(0.2)
        if getgenv and getgenv().swagpro_reload then 
            pcall(getgenv().swagpro_reload) 
        end
    end}
})

-- ==========================================
-- ADVANCED UI PANELS (Watermark, Keybinds, Arraylist)
-- ==========================================

function library:CreateDraggablePanel(name, defaultPos, transparent)
    local panel = Instance.new("Frame")
    panel.Name = name
    panel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    panel.BorderSizePixel = 0
    panel.Position = defaultPos
    panel.Size = UDim2.new(0, 150, 0, 30)
    panel.Visible = false
    panel.ZIndex = 400
    panel.Active = true
    panel.Parent = notifySGui
    
    local innerBorder = Instance.new("Frame")
    innerBorder.Name = "InnerBorder"
    innerBorder.Parent = panel
    innerBorder.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    innerBorder.BorderSizePixel = 0
    innerBorder.Position = UDim2.new(0, 1, 0, 1)
    innerBorder.Size = UDim2.new(1, -2, 1, -2)
    innerBorder.ZIndex = 401
    
    local inner = Instance.new("Frame")
    inner.Name = "Inner"
    inner.Parent = innerBorder
    inner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    inner.BorderSizePixel = 0
    inner.Position = UDim2.new(0, 1, 0, 1)
    inner.Size = UDim2.new(1, -2, 1, -2)
    inner.ZIndex = 402
    
    local line = Instance.new("Frame")
    line.Name = "Line"
    line.BackgroundColor3 = library.libColor
    line.BorderSizePixel = 0
    line.Position = UDim2.new(0, 0, 0, 0)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Parent = inner
    line.ZIndex = 403
    table.insert(library.accentElements, {obj = line, prop = "BackgroundColor3"})

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 6, 0, 2)
    title.Size = UDim2.new(1, -12, 0, 18)
    title.Font = Enum.Font.Code
    title.Text = name
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = inner
    title.ZIndex = 403

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0, 0, 0, 21)
    content.Size = UDim2.new(1, 0, 1, -21)
    content.Parent = inner
    content.ZIndex = 403
    
    if transparent then
        panel.BackgroundTransparency = 1
        innerBorder.BackgroundTransparency = 1
        inner.BackgroundTransparency = 1
        title.Visible = false
        line.Visible = false
        content.Position = UDim2.new(0, 0, 0, 0)
        content.Size = UDim2.new(1, 0, 1, 0)
    end
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local dragging, dragInput, dragStart, startPos
    
    local function beginDrag(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and menu.Enabled then
            dragging = true
            dragStart = input.Position
            startPos = panel.Position
            
            local con
            con = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if con then con:Disconnect() end
                    if name == "Arraylist" then
                        local screenSize = notifySGui.AbsoluteSize
                        if screenSize.X == 0 then
                            local cam = workspace.CurrentCamera
                            if cam then screenSize = cam.ViewportSize else screenSize = Vector2.new(1920, 1080) end
                        end
                        if panel.Position.X.Offset + (panel.Position.X.Scale * screenSize.X) < screenSize.X / 2 then
                            panel.Position = UDim2.new(0, 10, panel.Position.Y.Scale, panel.Position.Y.Offset)
                        else
                            panel.Position = UDim2.new(1, -160, panel.Position.Y.Scale, panel.Position.Y.Offset)
                        end
                    else
                        if math.abs(panel.Position.X.Offset - defaultPos.X.Offset) < 30 and math.abs(panel.Position.Y.Offset - defaultPos.Y.Offset) < 30 then
                            panel.Position = defaultPos
                        end
                    end
                end
            end)
        end
    end
    
    title.InputBegan:Connect(beginDrag)
    if transparent then
        panel.InputBegan:Connect(beginDrag)
    end
    
    local function dragMove(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end
    title.InputChanged:Connect(dragMove)
    if transparent then
        panel.InputChanged:Connect(dragMove)
    end
    
    inputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    return panel, content, layout
end

-- 1. WATERMARK
local wmPanel, wmContent, wmLayout = library:CreateDraggablePanel("", UDim2.new(0.5, -150, 0, 10), false)

local textService = game:GetService("TextService")
local worstCaseText = string.format("swag.pro | %s | 999 fps | 9999 ms", game.Players.LocalPlayer.DisplayName)
local wmBounds = textService:GetTextSize(worstCaseText, 13, Enum.Font.Code, Vector2.new(9999, 100))

wmPanel.Size = UDim2.new(0, wmBounds.X + 16, 0, 24)
if wmLayout then wmLayout:Destroy() end
if wmContent then wmContent:Destroy() end

local wmTitle = wmPanel.InnerBorder.Inner.Title
wmTitle.Position = UDim2.new(0, 8, 0, 0)
wmTitle.Size = UDim2.new(1, -16, 1, 0)

local frames, lastTick = 0, tick()

-- 2. KEYBINDS
local kbPanel, kbContent, kbLayout = library:CreateDraggablePanel("Keybinds", UDim2.new(0, 10, 0.5, -100), false)
kbLayout.Padding = UDim.new(0, 1)

-- 3. ARRAYLIST
local alPanel, alContent, alLayout = library:CreateDraggablePanel("Arraylist", UDim2.new(1, -160, 0, 10), true)

local kbLabels = {}
local alLabels = {}

game:GetService("RunService").RenderStepped:Connect(function()
    if library.Unloaded then return end
    -- Watermark
    frames = frames + 1
    if tick() - lastTick >= 1 then
        local ping = 0
        pcall(function() ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        local text = string.format("swag.pro | %s | %d fps | %d ms", game.Players.LocalPlayer.DisplayName, frames, ping)
        wmTitle.Text = text
        
        frames = 0
        lastTick = tick()
    end

    if library.flags["show watermark"] then
        wmPanel.Visible = true
    else
        wmPanel.Visible = false
    end

    -- Keybinds
    if library.flags["show keybinds"] then
        local activeBinds = {}
        for flag, opt in pairs(library.options) do
            if opt.type == "keybind" and flag ~= "MenuKeybind" then
                if library.flags[flag] and library.flags[flag] ~= Enum.KeyCode.Unknown then
                    -- Only show if the parent toggle is checked
                    local parentFlag = opt.parentToggleFlag or (opt.oldargs and opt.oldargs._parentToggleFlag)
                    if parentFlag and not library.flags[parentFlag] then
                        continue
                    end
                    local keyNameStr = keyNames[library.flags[flag]] or library.flags[flag].Name
                    local displayName = (opt.oldargs and opt.oldargs._parentToggleText) or (opt.oldargs and opt.oldargs.text) or flag
                    -- Determine if this keybind is actively engaged
                    local isActive = false
                    local mode = opt.mode or "Always"
                    if mode == "Always" then
                        isActive = true
                    else
                        isActive = opt._active == true
                    end
                    table.insert(activeBinds, {text = tostring(displayName), key = keyNameStr, mode = mode, active = isActive})
                end
            end
        end

        -- Hide the panel entirely when there are no active keybinds
        if #activeBinds == 0 then
            kbPanel.Visible = false
        else
            kbPanel.Visible = true

            -- Calculate dynamic width based on longest entry
            local _ts = game:GetService("TextService")
            local maxLeftW = 0
            local modeW = 0
            for _, bind in ipairs(activeBinds) do
                local leftStr = string.format("  [%s] %s", bind.key, bind.text)
                local modeStr = string.format("[%s]  ", string.lower(bind.mode))
                local leftSize = _ts:GetTextSize(leftStr, 13, Enum.Font.Code, Vector2.new(9999, 20))
                local modeSize = _ts:GetTextSize(modeStr, 13, Enum.Font.Code, Vector2.new(9999, 20))
                if leftSize.X > maxLeftW then maxLeftW = leftSize.X end
                if modeSize.X > modeW then modeW = modeSize.X end
            end
            local panelW = math.max(maxLeftW + modeW + 20, 200)

            local kbHeight = 0
            for i, bind in ipairs(activeBinds) do
                local lbl = kbLabels[i]
                if not lbl then
                    lbl = Instance.new("TextLabel")
                    lbl.BackgroundTransparency = 1
                    lbl.Size = UDim2.new(1, 0, 0, 20)
                    lbl.Font = Enum.Font.Code
                    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
                    lbl.TextSize = 13
                    lbl.TextStrokeTransparency = 0
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.TextTruncate = Enum.TextTruncate.AtEnd
                    lbl.ClipsDescendants = true
                    lbl.ZIndex = 403
                    lbl.Parent = kbContent

                    local modeLbl = Instance.new("TextLabel")
                    modeLbl.Name = "Mode"
                    modeLbl.BackgroundTransparency = 1
                    modeLbl.Font = Enum.Font.Code
                    modeLbl.TextColor3 = Color3.fromRGB(120, 120, 120)
                    modeLbl.TextSize = 13
                    modeLbl.TextStrokeTransparency = 0
                    modeLbl.TextXAlignment = Enum.TextXAlignment.Right
                    modeLbl.ZIndex = 404
                    modeLbl.Parent = lbl

                    kbLabels[i] = lbl
                end
                lbl.Text = string.format("  [%s] %s", bind.key, bind.text)
                lbl.Mode.Text = string.format("[%s]  ", string.lower(bind.mode))

                -- Size: main label leaves room for mode on the right
                lbl.Size = UDim2.new(1, 0, 0, 20)
                lbl.Mode.Size = UDim2.new(0, modeW + 4, 1, 0)
                lbl.Mode.Position = UDim2.new(1, -(modeW + 4), 0, 0)

                -- Apply arraylist-style accent gradient when active, dim when inactive
                if bind.active then
                    lbl.TextColor3 = Color3.new(1, 1, 1)
                    local grad = lbl:FindFirstChild("UIGradient")
                    if not grad then
                        grad = Instance.new("UIGradient")
                        grad.Rotation = 45
                        grad.Parent = lbl
                    end
                    local c = library.libColor
                    grad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, c),
                        ColorSequenceKeypoint.new(0.35, c),
                        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
                        ColorSequenceKeypoint.new(0.65, c),
                        ColorSequenceKeypoint.new(1, c)
                    })
                    local waveOffset = math.sin(tick() * 0.8 + (i * 0.3))
                    grad.Offset = Vector2.new(waveOffset, 0)
                    grad.Enabled = true
                else
                    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
                    local grad = lbl:FindFirstChild("UIGradient")
                    if grad then
                        grad.Enabled = false
                    end
                end
                lbl.Visible = true
                kbHeight = kbHeight + 20
            end

            for i = #activeBinds + 1, #kbLabels do
                kbLabels[i].Visible = false
            end
            kbPanel.Size = UDim2.new(0, panelW, 0, kbHeight + 28)
        end
    else
        kbPanel.Visible = false
    end

    -- Arraylist
    if library.flags["show arraylist"] then
        alPanel.Visible = true
        local activeToggles = {}
        for flag, opt in pairs(library.options) do
            if opt.type == "toggle" and library.flags[flag] and not opt.oldargs.noarray then
                table.insert(activeToggles, tostring(opt.oldargs.text))
            end
        end
        if #activeToggles == 0 then
            table.insert(activeToggles, "none")
        end
        table.sort(activeToggles, function(a, b) return a:len() > b:len() end)
        
        local alHeight = 0
        local alignment = "Right"
        local screenSize = notifySGui.AbsoluteSize
        if screenSize.X == 0 then screenSize = Vector2.new(1920, 1080) end
        if alPanel.Position.X.Offset + (alPanel.Position.X.Scale * screenSize.X) < screenSize.X / 2 then
            alignment = "Left"
        end
        
        if alignment == "Right" then
            if alLayout then alLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right end
        else
            if alLayout then alLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left end
        end
        
        for i, text in ipairs(activeToggles) do
            local lbl = alLabels[i]
            if not lbl then
                lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, 0, 0, 22)
                lbl.Font = Enum.Font.Code
                lbl.TextSize = 16
                lbl.TextStrokeTransparency = 0.5
                lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                lbl.ZIndex = 403
                lbl.Parent = alContent
                alLabels[i] = lbl
            end
            lbl.Text = text
            lbl.TextColor3 = Color3.new(1, 1, 1)
            
            local grad = lbl:FindFirstChild("UIGradient")
            if not grad then
                grad = Instance.new("UIGradient")
                grad.Rotation = 45
                grad.Parent = lbl
            end
            
            local c = library.libColor
            grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, c),
                ColorSequenceKeypoint.new(0.35, c),
                ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(0.65, c),
                ColorSequenceKeypoint.new(1, c)
            })
            
            local waveOffset = math.sin(tick() * 0.8 + (i * 0.3))
            grad.Offset = Vector2.new(waveOffset, 0)
            
            if alignment == "Right" then
                lbl.TextXAlignment = Enum.TextXAlignment.Right
            else
                lbl.TextXAlignment = Enum.TextXAlignment.Left
            end
            lbl.Visible = true
            alHeight = alHeight + 22
        end
        
        for i = #activeToggles + 1, #alLabels do
            alLabels[i].Visible = false
        end
        alPanel.Size = UDim2.new(0, 150, 0, alHeight)
    else
        alPanel.Visible = false
    end
end)

-- Auto-fetch configs on startup
pcall(function()
    if not isfolder("swag") then
        makefolder("swag")
    end
    library:refreshConfigs()
    library:loadAutoConfig()
end)

return library
