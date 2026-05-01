local SynergyUI = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local function getDefaultParent()
    if RunService:IsStudio() then
        local player = Players.LocalPlayer
        if player then return player:WaitForChild("PlayerGui") end
    end
    return CoreGui
end

local function addCorner(frame, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = frame
    return corner
end

local function addStroke(frame, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.85
    stroke.Parent = frame
    return stroke
end

local function createTween(instance, duration, properties, style, direction)
    style = style or Enum.EasingStyle.Quint
    direction = direction or Enum.EasingDirection.Out
    local tweenInfo = TweenInfo.new(duration, style, direction)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function addHoverEffect(button, originalColor, hoverColor, useScale)
    local scale = nil
    if useScale then
        scale = Instance.new("UIScale")
        scale.Scale = 1
        scale.Parent = button
    end

    button.MouseEnter:Connect(function()
        createTween(button, 0.18, {BackgroundColor3 = hoverColor})
        if scale then createTween(scale, 0.18, {Scale = 1.04}) end
    end)
    button.MouseLeave:Connect(function()
        createTween(button, 0.18, {BackgroundColor3 = originalColor})
        if scale then createTween(scale, 0.18, {Scale = 1}) end
    end)
end

local NotificationQueue = {}
local function showNextNotification()
    if #NotificationQueue == 0 then return end
    local notification = NotificationQueue[1]
    table.remove(NotificationQueue, 1)

    local gui = Instance.new("ScreenGui")
    gui.Name = "SynergyToast_" .. HttpService:GenerateGUID(false)
    gui.Parent = notification.Parent or getDefaultParent()
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true

    local frame = Instance.new("Frame")
    frame.Parent = gui
    frame.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(0, 290, 0, 68)
    addCorner(frame, 14)
    addStroke(frame, Color3.fromRGB(255,255,255), 1, 0.92)

    local pos = notification.Position or "TopRight"
    if pos == "TopRight" then
        frame.Position = UDim2.new(1, 310, 0, 25)
        frame.AnchorPoint = Vector2.new(1, 0)
    elseif pos == "TopLeft" then
        frame.Position = UDim2.new(0, -310, 0, 25)
        frame.AnchorPoint = Vector2.new(0, 0)
    elseif pos == "BottomRight" then
        frame.Position = UDim2.new(1, 310, 1, -93)
        frame.AnchorPoint = Vector2.new(1, 1)
    elseif pos == "BottomLeft" then
        frame.Position = UDim2.new(0, -310, 1, -93)
        frame.AnchorPoint = Vector2.new(0, 1)
    end

    local indicator = Instance.new("Frame")
    indicator.Parent = frame
    indicator.BackgroundColor3 = notification.TypeColor or Color3.fromRGB(0, 170, 255)
    indicator.Size = UDim2.new(0, 6, 1, 0)
    addCorner(indicator, 14)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 25, 0, 0)
    label.Font = Enum.Font.GothamMedium
    label.Text = notification.Message
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14.5
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center

    local targetPos
    if pos == "TopRight" then targetPos = UDim2.new(1, -15, 0, 25)
    elseif pos == "TopLeft" then targetPos = UDim2.new(0, 15, 0, 25)
    elseif pos == "BottomRight" then targetPos = UDim2.new(1, -15, 1, -93)
    else targetPos = UDim2.new(0, 15, 1, -93) end

    createTween(frame, 0.45, {Position = targetPos}, Enum.EasingStyle.Quint)

    task.spawn(function()
        task.wait(notification.Duration or 4.2)
        local exitPos
        if pos == "TopRight" then exitPos = UDim2.new(1, 330, 0, 25)
        elseif pos == "TopLeft" then exitPos = UDim2.new(0, -330, 0, 25)
        elseif pos == "BottomRight" then exitPos = UDim2.new(1, 330, 1, -93)
        else exitPos = UDim2.new(0, -330, 1, -93) end
        createTween(frame, 0.45, {Position = exitPos})
        task.wait(0.45)
        gui:Destroy()
        showNextNotification()
    end)
end

function SynergyUI:Notify(message, duration, typeColor, position)
    table.insert(NotificationQueue, {Message = message, Duration = duration, TypeColor = typeColor, Position = position})
    if #NotificationQueue == 1 then showNextNotification() end
end

local ControlFactory = {}
function ControlFactory:new(parent, theme, saveCallback, loadCallback, updateThemeCallback)
    local obj = {}
    obj.parent = parent
    obj.theme = theme
    obj.save = saveCallback
    obj.load = loadCallback
    obj.updateTheme = updateThemeCallback
    obj.controls = {}
    obj.connections = {}
    setmetatable(obj, { __index = ControlFactory })
    return obj
end

function ControlFactory:createLabel(text)
    local label = Instance.new("TextLabel")
    label.Parent = self.parent
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, self.theme.LabelHeight)
    label.Font = self.theme.Font
    label.Text = text
    label.TextColor3 = self.theme.Text
    label.TextSize = self.theme.TextSizeNormal
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

function ControlFactory:createSeparator()
    local sep = Instance.new("Frame")
    sep.Parent = self.parent
    sep.BackgroundColor3 = self.theme.StrokeColor
    sep.BorderSizePixel = 0
    sep.Size = UDim2.new(1, 0, 0, 1)
    return sep
end

function ControlFactory:createButton(options)
    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.ButtonHeight)
    addCorner(frame, self.theme.CornerRadius)
    addStroke(frame, self.theme.StrokeColor, 1, 0.82)

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Font = self.theme.Font
    btn.Text = options.Name
    btn.TextColor3 = self.theme.Text
    btn.TextSize = self.theme.TextSizeNormal

    addHoverEffect(btn, self.theme.Element, self.theme.HoverColor, true)

    local connection = btn.MouseButton1Click:Connect(function()
        local s, e = pcall(options.Callback)
        if not s then SynergyUI:Notify("Error: " .. tostring(e), 3, Color3.fromRGB(255, 80, 80)) end
    end)

    if options.Tooltip then
        local tooltip = Instance.new("Frame")
        tooltip.Name = "Tooltip"
        tooltip.Parent = btn
        tooltip.BackgroundColor3 = self.theme.ElementDark
        tooltip.BorderSizePixel = 0
        tooltip.Position = UDim2.new(0, 0, 1, 4)
        tooltip.Size = UDim2.new(0, 0, 0, 24)
        addCorner(tooltip, 6)
        addStroke(tooltip, self.theme.StrokeColor)

        local tipLabel = Instance.new("TextLabel")
        tipLabel.Parent = tooltip
        tipLabel.BackgroundTransparency = 1
        tipLabel.Size = UDim2.new(1, -12, 1, 0)
        tipLabel.Position = UDim2.new(0, 6, 0, 0)
        tipLabel.Font = self.theme.Font
        tipLabel.Text = options.Tooltip
        tipLabel.TextColor3 = self.theme.TextMuted
        tipLabel.TextSize = self.theme.TextSizeSmall
        tipLabel.TextXAlignment = Enum.TextXAlignment.Left

        tooltip.Visible = false
        local show = btn.MouseEnter:Connect(function()
            tooltip.Visible = true
            tooltip.Size = UDim2.new(0, TextService:GetTextSize(options.Tooltip, self.theme.TextSizeSmall, self.theme.Font, Vector2.new(9999, 9999)).X + 18, 0, 24)
        end)
        local hide = btn.MouseLeave:Connect(function() tooltip.Visible = false end)
        table.insert(self.connections, show)
        table.insert(self.connections, hide)
    end

    return frame, connection
end

function ControlFactory:createToggle(options)
    local state = options.CurrentValue or false
    local flag = options.Flag or options.Name

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.ToggleHeight)
    addCorner(frame, self.theme.CornerRadius)
    addStroke(frame, self.theme.StrokeColor, 1, 0.82)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, 0)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Font = self.theme.Font
    label.Text = options.Name
    label.TextColor3 = self.theme.Text
    label.TextSize = self.theme.TextSizeNormal
    label.TextXAlignment = Enum.TextXAlignment.Left

    local outer = Instance.new("Frame")
    outer.Parent = frame
    outer.BackgroundColor3 = self.theme.ElementDark
    outer.Position = UDim2.new(1, -self.theme.ToggleWidth - self.theme.PaddingHorizontal, 0.5, -self.theme.ToggleHeight/2 + 1)
    outer.Size = UDim2.new(0, self.theme.ToggleWidth, 0, self.theme.ToggleHeight - 8)
    addCorner(outer, 999)

    local inner = Instance.new("Frame")
    inner.Parent = outer
    inner.BackgroundColor3 = state and self.theme.Accent or self.theme.TextMuted
    local innerSize = self.theme.ToggleHeight - 16
    inner.Position = state and UDim2.new(1, -innerSize - 4, 0.5, -innerSize/2) or UDim2.new(0, 4, 0.5, -innerSize/2)
    inner.Size = UDim2.new(0, innerSize, 0, innerSize)
    addCorner(inner, 999)

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = ""

    local function update(val)
        state = val
        createTween(inner, 0.25, {
            Position = state and UDim2.new(1, -innerSize - 4, 0.5, -innerSize/2) or UDim2.new(0, 4, 0.5, -innerSize/2),
            BackgroundColor3 = state and self.theme.Accent or self.theme.TextMuted
        })
        label.TextColor3 = state and self.theme.Accent or self.theme.Text
        pcall(options.Callback, state)
        self.save()
    end

    local flagObj = {
        GetValue = function() return state end,
        SetValue = function(_, v) update(v) end
    }
    self.controls[flag] = flagObj

    local connection = btn.MouseButton1Click:Connect(function() update(not state) end)
    if state then pcall(options.Callback, state) end

    self.registerControl(flag,
        function() return state end,
        function(v) update(v) end,
        function(c) if state then inner.BackgroundColor3 = c end end
    )

    return frame, connection
end

function ControlFactory:createSlider(options)
    local val = options.CurrentValue or options.Range[1]
    local flag = options.Flag or options.Name

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.SliderHeight)
    addCorner(frame, self.theme.CornerRadius)
    addStroke(frame, self.theme.StrokeColor, 1, 0.82)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical)
    label.Size = UDim2.new(0.65, 0, 0, self.theme.TextSizeNormal + 4)
    label.Font = self.theme.Font
    label.Text = options.Name
    label.TextColor3 = self.theme.Text
    label.TextSize = self.theme.TextSizeNormal
    label.TextXAlignment = Enum.TextXAlignment.Left

    local valLabel = Instance.new("TextLabel")
    valLabel.Parent = frame
    valLabel.BackgroundTransparency = 1
    valLabel.Position = UDim2.new(1, -68 - self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical)
    valLabel.Size = UDim2.new(0, 60, 0, self.theme.TextSizeNormal + 4)
    valLabel.Font = self.theme.Font
    valLabel.Text = tostring(val)
    valLabel.TextColor3 = self.theme.Accent
    valLabel.TextSize = self.theme.TextSizeNormal
    valLabel.TextXAlignment = Enum.TextXAlignment.Right

    local bg = Instance.new("Frame")
    bg.Parent = frame
    bg.BackgroundColor3 = self.theme.ElementDark
    bg.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical + self.theme.TextSizeNormal + 8)
    bg.Size = UDim2.new(1, -2 * self.theme.PaddingHorizontal - 130, 0, self.theme.SliderBarHeight)
    addCorner(bg, self.theme.SliderBarHeight / 2)
    addStroke(bg, self.theme.StrokeColor, 1, 0.9)

    local fill = Instance.new("Frame")
    fill.Parent = bg
    fill.BackgroundColor3 = self.theme.Accent
    fill.Size = UDim2.new((val - options.Range[1]) / (options.Range[2] - options.Range[1]), 0, 1, 0)
    addCorner(fill, self.theme.SliderBarHeight / 2)

    local thumb = Instance.new("Frame")
    thumb.Parent = fill
    thumb.BackgroundColor3 = self.theme.Accent
    thumb.Position = UDim2.new(1, -8, 0.5, -8)
    thumb.Size = UDim2.new(0, 16, 0, 16)
    addCorner(thumb, 999)
    addStroke(thumb, Color3.fromRGB(255,255,255), 1.5, 0.4)

    local inputBg = Instance.new("Frame")
    inputBg.Parent = frame
    inputBg.BackgroundColor3 = self.theme.ElementDark
    inputBg.Position = UDim2.new(1, -68 - self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical + self.theme.TextSizeNormal + 6)
    inputBg.Size = UDim2.new(0, 60, 0, 22)
    addCorner(inputBg, 8)
    addStroke(inputBg, self.theme.StrokeColor)

    local numInput = Instance.new("TextBox")
    numInput.Parent = inputBg
    numInput.BackgroundTransparency = 1
    numInput.ClearTextOnFocus = false
    numInput.Size = UDim2.new(1, 0, 1, 0)
    numInput.Font = self.theme.Font
    numInput.Text = tostring(val)
    numInput.TextColor3 = self.theme.Text
    numInput.TextSize = self.theme.TextSizeSmall
    numInput.TextXAlignment = Enum.TextXAlignment.Center

    numInput:GetPropertyChangedSignal("Text"):Connect(function()
        numInput.Text = numInput.Text:gsub("[^%d%.%-]", "")
    end)

    local dragging = false
    local function move(input)
        local pos = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        local calc = options.Range[1] + pos * (options.Range[2] - options.Range[1])
        local inc = options.Increment or 1
        calc = math.floor(calc / inc + 0.5) * inc
        calc = math.clamp(calc, options.Range[1], options.Range[2])
        val = calc
        valLabel.Text = math.floor(val) == val and tostring(val) or string.format("%.2f", val)
        numInput.Text = valLabel.Text
        createTween(fill, 0.12, {Size = UDim2.new((val - options.Range[1]) / (options.Range[2] - options.Range[1]), 0, 1, 0)})
        pcall(options.Callback, val)
    end

    local btn = Instance.new("TextButton")
    btn.Parent = bg
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = ""

    local connection1 = btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            move(input)
        end
    end)

    local connection2 = UserInputService.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            self.save()
            dragging = false
        end
    end)

    local connection3 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            move(input)
        end
    end)

    local connection4 = numInput.FocusLost:Connect(function()
        local newVal = tonumber(numInput.Text)
        if newVal then
            newVal = math.clamp(newVal, options.Range[1], options.Range[2])
            local inc = options.Increment or 1
            newVal = math.floor(newVal / inc + 0.5) * inc
            val = newVal
            valLabel.Text = tostring(val)
            fill.Size = UDim2.new((val - options.Range[1]) / (options.Range[2] - options.Range[1]), 0, 1, 0)
            pcall(options.Callback, val)
            self.save()
        else
            numInput.Text = tostring(val)
        end
    end)

    local flagObj = {
        GetValue = function() return val end,
        SetValue = function(_, v)
            v = math.clamp(v, options.Range[1], options.Range[2])
            if options.Increment then
                v = math.floor(v / options.Increment + 0.5) * options.Increment
            end
            val = v
            valLabel.Text = tostring(v)
            numInput.Text = tostring(v)
            fill.Size = UDim2.new((v - options.Range[1]) / (options.Range[2] - options.Range[1]), 0, 1, 0)
            pcall(options.Callback, v)
            self.save()
        end
    }
    self.controls[flag] = flagObj

    self.registerControl(flag,
        function() return val end,
        function(v) flagObj.SetValue(v) end,
        function(c)
            fill.BackgroundColor3 = c
            thumb.BackgroundColor3 = c
            valLabel.TextColor3 = c
        end
    )

    return frame, {connection1, connection2, connection3, connection4}
end

function ControlFactory:createDropdown(options)
    local current = options.CurrentOption or options.Options[1] or ""
    local optionsList = options.Options or {}
    local flag = options.Flag or options.Name

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.DropdownHeight)
    frame.ClipsDescendants = true
    addCorner(frame, self.theme.CornerRadius)
    addStroke(frame, self.theme.StrokeColor, 1, 0.82)

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 0, self.theme.DropdownHeight)
    btn.Font = self.theme.Font
    btn.Text = options.Name .. " : " .. current
    btn.TextColor3 = self.theme.Text
    btn.TextSize = self.theme.TextSizeNormal
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, 0)

    local icon = Instance.new("TextLabel")
    icon.Parent = frame
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.new(1, -34, 0.5, -8)
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Font = Enum.Font.GothamBold
    icon.Text = "v"
    icon.TextColor3 = self.theme.TextMuted
    icon.TextSize = 14

    local container = Instance.new("ScrollingFrame")
    container.Parent = frame
    container.BackgroundColor3 = self.theme.ElementDark
    container.BorderSizePixel = 0
    container.Position = UDim2.new(0, 0, 0, self.theme.DropdownHeight)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.ScrollBarThickness = 4
    container.ScrollBarImageColor3 = self.theme.Accent
    container.CanvasSize = UDim2.new(0, 0, 0, 0)

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)

    local isOpen = false
    local optionButtons = {}

    local function updateButtonText()
        btn.Text = options.Name .. " : " .. (current == "" and "None" or current)
    end

    local function rebuild()
        for _, b in ipairs(optionButtons) do if b and b.Parent then b:Destroy() end end
        optionButtons = {}
        for _, opt in ipairs(optionsList) do
            local optBtn = Instance.new("TextButton")
            optBtn.Parent = container
            optBtn.BackgroundColor3 = self.theme.ElementDark
            optBtn.BorderSizePixel = 0
            optBtn.Size = UDim2.new(1, 0, 0, self.theme.DropdownItemHeight)
            optBtn.Font = self.theme.Font
            optBtn.Text = "   " .. opt
            optBtn.TextColor3 = self.theme.TextMuted
            optBtn.TextSize = self.theme.TextSizeSmall
            optBtn.TextXAlignment = Enum.TextXAlignment.Left
            addHoverEffect(optBtn, self.theme.ElementDark, self.theme.HoverColor, false)
            optBtn.MouseButton1Click:Connect(function()
                current = opt
                updateButtonText()
                isOpen = false
                createTween(frame, 0.25, {Size = UDim2.new(1, 0, 0, self.theme.DropdownHeight)})
                container.Size = UDim2.new(1, 0, 0, 0)
                icon.Text = "v"
                pcall(options.Callback, opt)
                self.save()
            end)
            table.insert(optionButtons, optBtn)
        end
        container.CanvasSize = UDim2.new(0, 0, 0, #optionsList * self.theme.DropdownItemHeight + 8)
    end
    rebuild()

    local connection = btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            local expandedHeight = math.min(#optionsList * self.theme.DropdownItemHeight + 8, 180)
            local targetHeight = self.theme.DropdownHeight + expandedHeight
            createTween(frame, 0.25, {Size = UDim2.new(1, 0, 0, targetHeight)})
            container.Size = UDim2.new(1, 0, 0, expandedHeight)
            icon.Text = "^"
        else
            createTween(frame, 0.25, {Size = UDim2.new(1, 0, 0, self.theme.DropdownHeight)})
            container.Size = UDim2.new(1, 0, 0, 0)
            icon.Text = "v"
        end
    end)

    local flagObj = {
        GetValue = function() return current end,
        SetValue = function(_, v)
            if table.find(optionsList, v) then
                current = v
                updateButtonText()
                pcall(options.Callback, v)
                self.save()
            end
        end,
        SetOptions = function(_, newOpts)
            optionsList = newOpts
            rebuild()
            if not table.find(optionsList, current) then
                current = ""
                updateButtonText()
                pcall(options.Callback, "")
            end
        end
    }
    self.controls[flag] = flagObj

    self.registerControl(flag,
        function() return current end,
        function(v) flagObj.SetValue(v) end,
        function(c) container.ScrollBarImageColor3 = c end
    )

    return flagObj, connection
end

function ControlFactory:createChecklist(options)
    local optionsList = options.Options or {}
    local selected = {}
    if options.CurrentSelected then
        for _, v in ipairs(options.CurrentSelected) do selected[v] = true end
    end
    local flag = options.Flag or options.Name

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.ChecklistHeight)
    frame.ClipsDescendants = true
    addCorner(frame, self.theme.CornerRadius)
    addStroke(frame, self.theme.StrokeColor, 1, 0.82)

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 0, self.theme.ChecklistHeight)
    btn.Font = self.theme.Font
    btn.Text = options.Name
    btn.TextColor3 = self.theme.Text
    btn.TextSize = self.theme.TextSizeNormal
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, 0)

    local countLabel = Instance.new("TextLabel")
    countLabel.Parent = frame
    countLabel.BackgroundTransparency = 1
    countLabel.Position = UDim2.new(1, -80, 0.5, -10)
    countLabel.Size = UDim2.new(0, 60, 0, 20)
    countLabel.Font = self.theme.Font
    countLabel.Text = "0 selected"
    countLabel.TextColor3 = self.theme.Accent
    countLabel.TextSize = self.theme.TextSizeSmall
    countLabel.TextXAlignment = Enum.TextXAlignment.Right

    local icon = Instance.new("TextLabel")
    icon.Parent = frame
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.new(1, -34, 0.5, -8)
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Font = Enum.Font.GothamBold
    icon.Text = "v"
    icon.TextColor3 = self.theme.TextMuted
    icon.TextSize = 14

    local container = Instance.new("ScrollingFrame")
    container.Parent = frame
    container.BackgroundColor3 = self.theme.ElementDark
    container.BorderSizePixel = 0
    container.Position = UDim2.new(0, 0, 0, self.theme.ChecklistHeight)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.ScrollBarThickness = 4
    container.ScrollBarImageColor3 = self.theme.Accent
    container.CanvasSize = UDim2.new(0, 0, 0, 0)

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)

    local function updateSelectedCount()
        local count = 0
        for _, v in pairs(selected) do if v then count += 1 end end
        countLabel.Text = count .. " selected"
        pcall(options.Callback, selected)
        self.save()
    end

    local function rebuild()
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        for _, opt in ipairs(optionsList) do
            local row = Instance.new("Frame")
            row.Parent = container
            row.BackgroundColor3 = self.theme.ElementDark
            row.BorderSizePixel = 0
            row.Size = UDim2.new(1, 0, 0, self.theme.ChecklistItemHeight)

            local toggleOuter = Instance.new("Frame")
            toggleOuter.Parent = row
            toggleOuter.BackgroundColor3 = self.theme.Element
            toggleOuter.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0.5, -10)
            toggleOuter.Size = UDim2.new(0, 20, 0, 20)
            addCorner(toggleOuter, 6)
            addStroke(toggleOuter, self.theme.StrokeColor)

            local toggleInner = Instance.new("Frame")
            toggleInner.Parent = toggleOuter
            toggleInner.BackgroundColor3 = selected[opt] and self.theme.Accent or Color3.fromRGB(60,60,60)
            toggleInner.Position = selected[opt] and UDim2.new(0.5, -6, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
            toggleInner.Size = UDim2.new(0, 12, 0, 12)
            addCorner(toggleInner, 6)

            local optLabel = Instance.new("TextLabel")
            optLabel.Parent = row
            optLabel.BackgroundTransparency = 1
            optLabel.Position = UDim2.new(0, self.theme.PaddingHorizontal + 32, 0.5, -10)
            optLabel.Size = UDim2.new(1, -self.theme.PaddingHorizontal - 40, 0, 20)
            optLabel.Font = self.theme.Font
            optLabel.Text = opt
            optLabel.TextColor3 = self.theme.TextMuted
            optLabel.TextSize = self.theme.TextSizeSmall
            optLabel.TextXAlignment = Enum.TextXAlignment.Left

            local clickBtn = Instance.new("TextButton")
            clickBtn.Parent = row
            clickBtn.BackgroundTransparency = 1
            clickBtn.Size = UDim2.new(1, 0, 1, 0)
            clickBtn.Text = ""

            clickBtn.MouseButton1Click:Connect(function()
                selected[opt] = not selected[opt]
                createTween(toggleInner, 0.2, {
                    BackgroundColor3 = selected[opt] and self.theme.Accent or Color3.fromRGB(60,60,60),
                    Position = selected[opt] and UDim2.new(0.5, -6, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
                })
                updateSelectedCount()
            end)
        end
        container.CanvasSize = UDim2.new(0, 0, 0, #optionsList * self.theme.ChecklistItemHeight + 8)
        updateSelectedCount()
    end
    rebuild()

    local isOpen = false
    local connection = btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            local expandedHeight = math.min(#optionsList * self.theme.ChecklistItemHeight + 8, 220)
            local targetHeight = self.theme.ChecklistHeight + expandedHeight
            createTween(frame, 0.25, {Size = UDim2.new(1, 0, 0, targetHeight)})
            container.Size = UDim2.new(1, 0, 0, expandedHeight)
            icon.Text = "^"
        else
            createTween(frame, 0.25, {Size = UDim2.new(1, 0, 0, self.theme.ChecklistHeight)})
            container.Size = UDim2.new(1, 0, 0, 0)
            icon.Text = "v"
        end
    end)

    local flagObj = {
        GetValue = function()
            local result = {}
            for k, v in pairs(selected) do if v then table.insert(result, k) end end
            return result
        end,
        SetValue = function(_, tbl)
            selected = {}
            for _, x in ipairs(tbl) do selected[x] = true end
            rebuild()
            self.save()
        end,
        SetOptions = function(_, newOpts)
            optionsList = newOpts
            selected = {}
            rebuild()
        end,
        GetSelected = function()
            local result = {}
            for k, v in pairs(selected) do if v then table.insert(result, k) end end
            return result
        end,
        SetSelected = function(_, tbl)
            selected = {}
            for _, v in ipairs(tbl) do selected[v] = true end
            rebuild()
        end
    }
    self.controls[flag] = flagObj

    self.registerControl(flag,
        function() return flagObj.GetValue() end,
        function(v) flagObj.SetValue(v) end,
        function(c) container.ScrollBarImageColor3 = c countLabel.TextColor3 = c end
    )

    return flagObj, connection
end

function ControlFactory:createTextInput(options)
    local flag = options.Flag or options.Name

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.TextInputHeight)
    addCorner(frame, self.theme.CornerRadius)
    addStroke(frame, self.theme.StrokeColor, 1, 0.82)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical)
    label.Size = UDim2.new(1, -2 * self.theme.PaddingHorizontal, 0, self.theme.TextSizeNormal + 4)
    label.Font = self.theme.Font
    label.Text = options.Name
    label.TextColor3 = self.theme.Text
    label.TextSize = self.theme.TextSizeNormal
    label.TextXAlignment = Enum.TextXAlignment.Left

    local input = Instance.new("TextBox")
    input.Parent = frame
    input.BackgroundColor3 = self.theme.ElementDark
    input.ClearTextOnFocus = false
    input.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical + self.theme.TextSizeNormal + 10)
    input.Size = UDim2.new(1, -2 * self.theme.PaddingHorizontal, 0, self.theme.TextInputFieldHeight)
    input.Font = self.theme.Font
    input.Text = options.CurrentText or ""
    input.TextColor3 = self.theme.Text
    input.TextSize = self.theme.TextSizeSmall
    input.PlaceholderText = options.Placeholder or ""
    input.PlaceholderColor3 = self.theme.TextMuted
    input.TextXAlignment = Enum.TextXAlignment.Left
    addCorner(input, self.theme.CornerRadius)
    addStroke(input, self.theme.StrokeColor)

    local inputPad = Instance.new("UIPadding")
    inputPad.Parent = input
    inputPad.PaddingLeft = UDim.new(0, 10)
    inputPad.PaddingRight = UDim.new(0, 10)

    local connection = input.FocusLost:Connect(function()
        pcall(options.Callback, input.Text)
        self.save()
    end)

    local flagObj = {
        GetValue = function() return input.Text end,
        SetValue = function(_, v) input.Text = v end
    }
    self.controls[flag] = flagObj

    self.registerControl(flag,
        function() return input.Text end,
        function(v) input.Text = v end,
        function() end
    )
    return flagObj, connection
end

function ControlFactory:createNumberInput(options)
    local flag = options.Flag or options.Name
    local currentVal = tonumber(options.CurrentValue) or 0

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.TextInputHeight)
    addCorner(frame, self.theme.CornerRadius)
    addStroke(frame, self.theme.StrokeColor, 1, 0.82)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical)
    label.Size = UDim2.new(1, -2 * self.theme.PaddingHorizontal, 0, self.theme.TextSizeNormal + 4)
    label.Font = self.theme.Font
    label.Text = options.Name
    label.TextColor3 = self.theme.Text
    label.TextSize = self.theme.TextSizeNormal
    label.TextXAlignment = Enum.TextXAlignment.Left

    local input = Instance.new("TextBox")
    input.Parent = frame
    input.BackgroundColor3 = self.theme.ElementDark
    input.ClearTextOnFocus = false
    input.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical + self.theme.TextSizeNormal + 10)
    input.Size = UDim2.new(1, -2 * self.theme.PaddingHorizontal, 0, self.theme.TextInputFieldHeight)
    input.Font = self.theme.Font
    input.Text = tostring(currentVal)
    input.TextColor3 = self.theme.Text
    input.TextSize = self.theme.TextSizeSmall
    input.PlaceholderColor3 = self.theme.TextMuted
    input.TextXAlignment = Enum.TextXAlignment.Left
    addCorner(input, self.theme.CornerRadius)
    addStroke(input, self.theme.StrokeColor)

    local inputPad = Instance.new("UIPadding")
    inputPad.Parent = input
    inputPad.PaddingLeft = UDim.new(0, 10)
    inputPad.PaddingRight = UDim.new(0, 10)

    input:GetPropertyChangedSignal("Text"):Connect(function()
        input.Text = input.Text:gsub("[^%d%.%-]", "")
    end)

    local connection = input.FocusLost:Connect(function()
        local num = tonumber(input.Text)
        if num then
            currentVal = num
            pcall(options.Callback, currentVal)
            self.save()
        else
            input.Text = tostring(currentVal)
        end
    end)

    local flagObj = {
        GetValue = function() return currentVal end,
        SetValue = function(_, v) currentVal = tonumber(v) or 0; input.Text = tostring(currentVal); pcall(options.Callback, currentVal); self.save() end
    }
    self.controls[flag] = flagObj

    self.registerControl(flag,
        function() return currentVal end,
        function(v) flagObj.SetValue(v) end,
        function() end
    )
    return flagObj, connection
end

function ControlFactory:createKeybind(options)
    local current = options.CurrentKeybind or "None"
    local flag = options.Flag or options.Name

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.KeybindHeight)
    addCorner(frame, self.theme.CornerRadius)
    addStroke(frame, self.theme.StrokeColor, 1, 0.82)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, 0)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Font = self.theme.Font
    label.Text = options.Name
    label.TextColor3 = self.theme.Text
    label.TextSize = self.theme.TextSizeNormal
    label.TextXAlignment = Enum.TextXAlignment.Left

    local bindBtn = Instance.new("TextButton")
    bindBtn.Parent = frame
    bindBtn.BackgroundColor3 = self.theme.ElementDark
    bindBtn.Position = UDim2.new(1, -self.theme.KeybindWidth - self.theme.PaddingHorizontal, 0.5, -self.theme.KeybindHeight/2)
    bindBtn.Size = UDim2.new(0, self.theme.KeybindWidth, 0, self.theme.KeybindHeight)
    bindBtn.Font = self.theme.Font
    bindBtn.Text = current
    bindBtn.TextColor3 = self.theme.Accent
    bindBtn.TextSize = self.theme.TextSizeSmall
    addCorner(bindBtn, self.theme.CornerRadius)
    addStroke(bindBtn, self.theme.StrokeColor)

    local binding = false
    local connection1 = bindBtn.MouseButton1Click:Connect(function()
        binding = true
        bindBtn.Text = "..."
    end)

    local connection2 = UserInputService.InputBegan:Connect(function(input, gp)
        if binding then
            if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType.Name:find("MouseButton") then
                local keyName = input.KeyCode.Name ~= "Unknown" and input.KeyCode.Name or input.UserInputType.Name
                if keyName == "Escape" then keyName = "None" end
                current = keyName
                bindBtn.Text = current
                binding = false
                pcall(options.Callback, current)
                self.save()
            end
        elseif not gp then
            local inputName = input.KeyCode.Name ~= "Unknown" and input.KeyCode.Name or input.UserInputType.Name
            if inputName == current and current ~= "None" then
                pcall(options.Callback, current)
            end
        end
    end)

    local flagObj = {
        GetValue = function() return current end,
        SetValue = function(_, v) current = v; bindBtn.Text = v; pcall(options.Callback, v); self.save() end
    }
    self.controls[flag] = flagObj

    self.registerControl(flag,
        function() return current end,
        function(v) flagObj.SetValue(v) end,
        function(c) bindBtn.TextColor3 = c end
    )
    return flagObj, {connection1, connection2}
end

function ControlFactory:createColorPicker(options)
    local color = options.Color or Color3.fromRGB(0, 170, 255)
    local flag = options.Flag or options.Name
    local r, g, b = color.R, color.G, color.B

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.ColorPickerHeight)
    frame.ClipsDescendants = true
    addCorner(frame, self.theme.CornerRadius)
    addStroke(frame, self.theme.StrokeColor, 1, 0.82)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, 0)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Font = self.theme.Font
    label.Text = options.Name
    label.TextColor3 = self.theme.Text
    label.TextSize = self.theme.TextSizeNormal
    label.TextXAlignment = Enum.TextXAlignment.Left

    local preview = Instance.new("Frame")
    preview.Parent = frame
    preview.BackgroundColor3 = color
    preview.Position = UDim2.new(1, -self.theme.ColorPickerPreviewSize - self.theme.PaddingHorizontal, 0.5, -self.theme.ColorPickerPreviewSize/2)
    preview.Size = UDim2.new(0, self.theme.ColorPickerPreviewSize, 0, self.theme.ColorPickerPreviewSize)
    addCorner(preview, self.theme.CornerRadius)
    addStroke(preview, Color3.fromRGB(255,255,255), 1.5, 0.6)

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 0, self.theme.ColorPickerHeight)
    btn.Text = ""

    local container = Instance.new("Frame")
    container.Parent = frame
    container.BackgroundColor3 = self.theme.ElementDark
    container.Position = UDim2.new(0, 0, 0, self.theme.ColorPickerHeight)
    container.Size = UDim2.new(1, 0, 0, self.theme.ColorPickerExpandedHeight - self.theme.ColorPickerHeight)
    container.Visible = false

    local function update()
        local c = Color3.new(r, g, b)
        preview.BackgroundColor3 = c
        pcall(options.Callback, c)
        self.save()
    end

    local function makeSlider(name, yPos, tint, initVal, callback)
        local sFrame = Instance.new("Frame")
        sFrame.Parent = container
        sFrame.BackgroundTransparency = 1
        sFrame.Position = UDim2.new(0, 0, 0, yPos)
        sFrame.Size = UDim2.new(1, 0, 0, 28)

        local sLbl = Instance.new("TextLabel")
        sLbl.Parent = sFrame
        sLbl.BackgroundTransparency = 1
        sLbl.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, 0)
        sLbl.Size = UDim2.new(0, 18, 1, 0)
        sLbl.Font = self.theme.Font
        sLbl.Text = name
        sLbl.TextColor3 = tint
        sLbl.TextSize = self.theme.TextSizeSmall

        local sBg = Instance.new("Frame")
        sBg.Parent = sFrame
        sBg.BackgroundColor3 = self.theme.Element
        sBg.Position = UDim2.new(0, 42, 0.5, -4)
        sBg.Size = UDim2.new(1, -self.theme.PaddingHorizontal - 70, 0, 8)
        addCorner(sBg, 4)
        addStroke(sBg, self.theme.StrokeColor)

        local sFill = Instance.new("Frame")
        sFill.Parent = sBg
        sFill.BackgroundColor3 = tint
        sFill.Size = UDim2.new(initVal, 0, 1, 0)
        addCorner(sFill, 4)

        local sBtn = Instance.new("TextButton")
        sBtn.Parent = sBg
        sBtn.BackgroundTransparency = 1
        sBtn.Size = UDim2.new(1, 0, 1, 0)
        sBtn.Text = ""

        local dragging = false
        sBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                local pos = math.clamp((inp.Position.X - sBg.AbsolutePosition.X) / sBg.AbsoluteSize.X, 0, 1)
                sFill.Size = UDim2.new(pos, 0, 1, 0)
                callback(pos)
                update()
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                local pos = math.clamp((inp.Position.X - sBg.AbsolutePosition.X) / sBg.AbsoluteSize.X, 0, 1)
                sFill.Size = UDim2.new(pos, 0, 1, 0)
                callback(pos)
                update()
            end
        end)
    end

    makeSlider("R", 12, Color3.fromRGB(255, 80, 80), r, function(v) r = v end)
    makeSlider("G", 48, Color3.fromRGB(80, 255, 80), g, function(v) g = v end)
    makeSlider("B", 84, Color3.fromRGB(80, 150, 255), b, function(v) b = v end)

    local isOpen = false
    local connection = btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        container.Visible = isOpen
        createTween(frame, 0.28, {Size = UDim2.new(1, 0, 0, isOpen and self.theme.ColorPickerExpandedHeight or self.theme.ColorPickerHeight)})
    end)

    local flagObj = {
        GetValue = function() return Color3.new(r, g, b) end,
        SetValue = function(_, newColor)
            r, g, b = newColor.R, newColor.G, newColor.B
            update()
        end
    }
    self.controls[flag] = flagObj

    self.registerControl(flag,
        function() return {r, g, b} end,
        function(v) r, g, b = v[1], v[2], v[3]; update() end,
        function() end
    )
    return flagObj, connection
end

function ControlFactory:createRadioGroup(options)
    local selected = options.CurrentValue or options.Options[1] or ""
    local flag = options.Flag or options.Name

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, #options.Options * self.theme.RadioItemHeight + 16)
    addCorner(frame, self.theme.CornerRadius)
    addStroke(frame, self.theme.StrokeColor, 1, 0.82)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, 6)
    label.Size = UDim2.new(1, -2 * self.theme.PaddingHorizontal, 0, 20)
    label.Font = self.theme.Font
    label.Text = options.Name
    label.TextColor3 = self.theme.Text
    label.TextSize = self.theme.TextSizeNormal
    label.TextXAlignment = Enum.TextXAlignment.Left

    local radioButtons = {}

    for i, opt in ipairs(options.Options) do
        local row = Instance.new("Frame")
        row.Parent = frame
        row.BackgroundTransparency = 1
        row.Position = UDim2.new(0, 0, 0, 30 + (i-1) * self.theme.RadioItemHeight)
        row.Size = UDim2.new(1, 0, 0, self.theme.RadioItemHeight)

        local outer = Instance.new("Frame")
        outer.Parent = row
        outer.BackgroundColor3 = self.theme.ElementDark
        outer.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0.5, -10)
        outer.Size = UDim2.new(0, 20, 0, 20)
        addCorner(outer, 999)
        addStroke(outer, self.theme.StrokeColor)

        local inner = Instance.new("Frame")
        inner.Parent = outer
        inner.BackgroundColor3 = (opt == selected) and self.theme.Accent or Color3.fromRGB(60,60,60)
        inner.Position = UDim2.new(0.5, -6, 0.5, -6)
        inner.Size = UDim2.new(0, 12, 0, 12)
        addCorner(inner, 999)

        local optLabel = Instance.new("TextLabel")
        optLabel.Parent = row
        optLabel.BackgroundTransparency = 1
        optLabel.Position = UDim2.new(0, self.theme.PaddingHorizontal + 32, 0.5, -10)
        optLabel.Size = UDim2.new(1, -self.theme.PaddingHorizontal - 40, 0, 20)
        optLabel.Font = self.theme.Font
        optLabel.Text = opt
        optLabel.TextColor3 = self.theme.TextMuted
        optLabel.TextSize = self.theme.TextSizeSmall
        optLabel.TextXAlignment = Enum.TextXAlignment.Left

        local click = Instance.new("TextButton")
        click.Parent = row
        click.BackgroundTransparency = 1
        click.Size = UDim2.new(1, 0, 1, 0)
        click.Text = ""

        click.MouseButton1Click:Connect(function()
            if opt ~= selected then
                selected = opt
                for _, rb in ipairs(radioButtons) do
                    rb.Inner.BackgroundColor3 = (rb.Option == selected) and self.theme.Accent or Color3.fromRGB(60,60,60)
                end
                pcall(options.Callback, selected)
                self.save()
            end
        end)

        table.insert(radioButtons, {Option = opt, Inner = inner})
    end

    local flagObj = {
        GetValue = function() return selected end,
        SetValue = function(_, v)
            if table.find(options.Options, v) then
                selected = v
                for _, rb in ipairs(radioButtons) do
                    rb.Inner.BackgroundColor3 = (rb.Option == selected) and self.theme.Accent or Color3.fromRGB(60,60,60)
                end
                pcall(options.Callback, selected)
                self.save()
            end
        end
    }
    self.controls[flag] = flagObj

    self.registerControl(flag,
        function() return selected end,
        function(v) flagObj.SetValue(v) end,
        function(c)
            for _, rb in ipairs(radioButtons) do
                if rb.Option == selected then rb.Inner.BackgroundColor3 = c end
            end
        end
    )
    return flagObj, nil
end

function SynergyUI:CreateWindow(options)
    options = options or {}
    local window = {
        Flags = {},
        Tabs = {},
        Controls = {},
        Connections = {},
        CurrentTab = nil,
        ConfigFile = options.ConfigFile or "",
        Theme = {
            Accent = options.AccentColor or Color3.fromRGB(0, 170, 255),
            Background = Color3.fromRGB(8, 8, 8),
            Sidebar = Color3.fromRGB(12, 12, 12),
            Element = Color3.fromRGB(18, 18, 18),
            ElementDark = Color3.fromRGB(13, 13, 13),
            Text = Color3.fromRGB(240, 240, 240),
            TextMuted = Color3.fromRGB(160, 160, 160),
            StrokeColor = Color3.fromRGB(35, 35, 35),
            HoverColor = Color3.fromRGB(26, 26, 26),
            Font = Enum.Font.GothamMedium,
            CornerRadius = 12,
            PaddingHorizontal = 14,
            PaddingVertical = 8,
            TextSizeNormal = 14,
            TextSizeSmall = 13,
            LabelHeight = 24,
            ButtonHeight = 42,
            ToggleHeight = 34,
            ToggleWidth = 50,
            SliderHeight = 52,
            SliderBarHeight = 8,
            DropdownHeight = 42,
            DropdownItemHeight = 32,
            ChecklistHeight = 42,
            ChecklistItemHeight = 32,
            TextInputHeight = 76,
            TextInputFieldHeight = 34,
            KeybindHeight = 42,
            KeybindWidth = 72,
            ColorPickerHeight = 42,
            ColorPickerPreviewSize = 26,
            ColorPickerExpandedHeight = 178,
            RadioItemHeight = 34,
        },
        ToggleKey = options.ToggleKey or Enum.KeyCode.RightShift,
        IsVisible = true,
        IsMinimized = false
    }

    local strokeThickness = 2

    local gui = Instance.new("ScreenGui")
    gui.Name = "SynergyUI_" .. HttpService:GenerateGUID(false)
    gui.Parent = options.Parent or getDefaultParent()
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    window.Gui = gui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = gui
    mainFrame.BackgroundColor3 = window.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Position = UDim2.new(0.5, -280, 0.5, -190)
    mainFrame.Size = UDim2.new(0, 560, 0, 380)
    mainFrame.ClipsDescendants = true
    addCorner(mainFrame, window.Theme.CornerRadius)
    addStroke(mainFrame, window.Theme.Accent, strokeThickness, 0.4)
    window.MainFrame = mainFrame

    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Parent = mainFrame
    topBar.BackgroundColor3 = window.Theme.Sidebar
    topBar.BorderSizePixel = 0
    topBar.Size = UDim2.new(1, 0, 0, 42)
    addCorner(topBar, window.Theme.CornerRadius)
    topBar.ZIndex = 10

    local topBarSep = Instance.new("Frame")
    topBarSep.Parent = topBar
    topBarSep.BackgroundColor3 = window.Theme.StrokeColor
    topBarSep.BorderSizePixel = 0
    topBarSep.Position = UDim2.new(0, 0, 1, -1)
    topBarSep.Size = UDim2.new(1, 0, 0, 1)
    topBarSep.ZIndex = 10

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = topBar
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, window.Theme.PaddingHorizontal, 0, 0)
    titleLabel.Size = UDim2.new(0, 240, 1, 0)
    titleLabel.Font = window.Theme.Font
    titleLabel.Text = options.Title or "Synergy Hub"
    titleLabel.TextColor3 = window.Theme.Accent
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 10

    local controlContainer = Instance.new("Frame")
    controlContainer.Parent = topBar
    controlContainer.BackgroundTransparency = 1
    controlContainer.Position = UDim2.new(1, -88, 0, 0)
    controlContainer.Size = UDim2.new(0, 88, 1, 0)
    controlContainer.ZIndex = 10

    local minBtn = Instance.new("TextButton")
    minBtn.Parent = controlContainer
    minBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
    minBtn.BackgroundTransparency = 0.72
    minBtn.Position = UDim2.new(0, 14, 0.5, -10)
    minBtn.Size = UDim2.new(0, 20, 0, 20)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(255, 210, 120)
    minBtn.TextSize = 16
    minBtn.ZIndex = 10
    addCorner(minBtn, 999)

    minBtn.MouseEnter:Connect(function()
        createTween(minBtn, 0.15, {BackgroundTransparency = 0.15})
    end)
    minBtn.MouseLeave:Connect(function()
        createTween(minBtn, 0.15, {BackgroundTransparency = 0.72})
    end)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = controlContainer
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
    closeBtn.BackgroundTransparency = 0.72
    closeBtn.Position = UDim2.new(0, 50, 0.5, -10)
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 160, 160)
    closeBtn.TextSize = 11
    closeBtn.ZIndex = 10
    addCorner(closeBtn, 999)

    closeBtn.MouseEnter:Connect(function()
        createTween(closeBtn, 0.15, {BackgroundTransparency = 0.1})
    end)
    closeBtn.MouseLeave:Connect(function()
        createTween(closeBtn, 0.15, {BackgroundTransparency = 0.72})
    end)

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Parent = mainFrame
    sidebar.BackgroundColor3 = window.Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Position = UDim2.new(0, 0, 0, 42)
    sidebar.Size = UDim2.new(0, 150, 1, -42 - strokeThickness)
    sidebar.ZIndex = 5
    addCorner(sidebar, window.Theme.CornerRadius)
    sidebar.ClipsDescendants = true

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Parent = sidebar
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 2)

    local sidebarPad = Instance.new("UIPadding")
    sidebarPad.Parent = sidebar
    sidebarPad.PaddingTop = UDim.new(0, 6)

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Parent = mainFrame
    contentArea.BackgroundColor3 = window.Theme.Background
    contentArea.BorderSizePixel = 0
    contentArea.Position = UDim2.new(0, 150, 0, 42)
    contentArea.Size = UDim2.new(1, -150 - strokeThickness, 1, -42 - strokeThickness)
    contentArea.ZIndex = 1
    addCorner(contentArea, window.Theme.CornerRadius)
    contentArea.ClipsDescendants = true

    local function addConnection(conn)
        table.insert(window.Connections, conn)
        return conn
    end

    local resizeHandle = Instance.new("Frame")
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.Parent = gui
    resizeHandle.BackgroundColor3 = window.Theme.Accent
    resizeHandle.BackgroundTransparency = 0.45
    resizeHandle.BorderSizePixel = 0
    resizeHandle.Size = UDim2.new(0, 5, 0, 54)
    resizeHandle.ZIndex = 150
    addCorner(resizeHandle, 999)

    local function syncResizeHandle()
        local ap = mainFrame.AbsolutePosition
        local as = mainFrame.AbsoluteSize
        resizeHandle.Position = UDim2.new(0, ap.X + as.X + 18, 0, ap.Y + as.Y / 2 - 27)
    end

    addConnection(mainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(syncResizeHandle))
    addConnection(mainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncResizeHandle))
    task.defer(syncResizeHandle)

    resizeHandle.MouseEnter:Connect(function()
        createTween(resizeHandle, 0.18, {BackgroundTransparency = 0.1, Size = UDim2.new(0, 7, 0, 54)})
    end)
    resizeHandle.MouseLeave:Connect(function()
        createTween(resizeHandle, 0.18, {BackgroundTransparency = 0.45, Size = UDim2.new(0, 5, 0, 54)})
    end)

    local dragging = false
    local dragStart, startPos
    addConnection(topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end))

    addConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))

    addConnection(UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
        end
    end))

    local resizing = false
    local resizeStart, startSize
    addConnection(resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = mainFrame.Size
        end
    end))

    addConnection(UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local newWidth = math.clamp(startSize.X.Offset + delta.X, 460, 1200)
            local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 280, 820)
            mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end))

    addConnection(UserInputService.InputEnded:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            resizing = false
        end
    end))

    addConnection(minBtn.MouseButton1Click:Connect(function()
        window.IsMinimized = not window.IsMinimized
        if window.IsMinimized then
            createTween(mainFrame, 0.35, {Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 42)})
            sidebar.Visible = false
            contentArea.Visible = false
            resizeHandle.Visible = false
        else
            createTween(mainFrame, 0.35, {Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 380)})
            sidebar.Visible = true
            contentArea.Visible = true
            resizeHandle.Visible = true
        end
    end))

    addConnection(closeBtn.MouseButton1Click:Connect(function()
        window:Destroy()
    end))

    addConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == window.ToggleKey then
            window.IsVisible = not window.IsVisible
            gui.Enabled = window.IsVisible
        end
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Escape and options.CloseOnEscape then
            window:Destroy()
        end
    end))

    local function saveConfig()
        if window.ConfigFile == "" then return end
        local config = {
            position = {mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset},
            size = {mainFrame.Size.X.Scale, mainFrame.Size.X.Offset, mainFrame.Size.Y.Scale, mainFrame.Size.Y.Offset},
            accent = {window.Theme.Accent.R, window.Theme.Accent.G, window.Theme.Accent.B},
            controls = {}
        }
        for _, control in ipairs(window.Controls) do
            if control.Save then config.controls[control.Id] = control.Save() end
        end
        if type(writefile) == "function" then
            writefile(window.ConfigFile, HttpService:JSONEncode(config))
        end
    end

    local function loadConfig()
        if window.ConfigFile == "" then return end
        if type(readfile) == "function" then
            local success, res = pcall(readfile, window.ConfigFile)
            if success then
                local s, decoded = pcall(HttpService.JSONDecode, HttpService, res)
                if s and decoded then
                    if decoded.position then
                        mainFrame.Position = UDim2.new(decoded.position[1], decoded.position[2], decoded.position[3], decoded.position[4])
                    end
                    if decoded.size then
                        mainFrame.Size = UDim2.new(decoded.size[1], decoded.size[2], decoded.size[3], decoded.size[4])
                    end
                    if decoded.accent then
                        window:SetAccent(Color3.new(decoded.accent[1], decoded.accent[2], decoded.accent[3]))
                    end
                    if decoded.controls then
                        for _, control in ipairs(window.Controls) do
                            if control.Load and decoded.controls[control.Id] ~= nil then
                                control.Load(decoded.controls[control.Id])
                            end
                        end
                    end
                end
            end
        end
    end

    function window:SaveConfig(filename)
        if filename then window.ConfigFile = filename end
        saveConfig()
    end

    function window:LoadConfig(filename)
        if filename then window.ConfigFile = filename end
        loadConfig()
    end

    function window:SetAccent(color)
        window.Theme.Accent = color
        mainFrame:FindFirstChild("UIStroke").Color = color
        titleLabel.TextColor3 = color
        resizeHandle.BackgroundColor3 = color
        for _, tab in ipairs(window.Tabs) do
            if tab.Button.TextColor3 ~= window.Theme.TextMuted then tab.Button.TextColor3 = color end
            if tab.ActiveIndicator then tab.ActiveIndicator.BackgroundColor3 = color end
        end
        for _, control in ipairs(window.Controls) do
            if control.UpdateTheme then control.UpdateTheme(color) end
        end
    end

    function window:Destroy()
        for _, conn in ipairs(window.Connections) do
            if conn and conn.Connected then conn:Disconnect() end
        end
        gui:Destroy()
    end

    function window:CreateTab(name, icon)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Parent = sidebar
        tabBtn.BackgroundColor3 = window.Theme.Sidebar
        tabBtn.BorderSizePixel = 0
        tabBtn.Size = UDim2.new(1, 0, 0, 42)
        tabBtn.Font = window.Theme.Font
        tabBtn.Text = name
        tabBtn.TextColor3 = window.Theme.TextMuted
        tabBtn.TextSize = 14
        tabBtn.TextXAlignment = Enum.TextXAlignment.Left
        tabBtn.Position = UDim2.new(0, window.Theme.PaddingHorizontal + 10, 0, 0)

        local activeIndicator = Instance.new("Frame")
        activeIndicator.Parent = tabBtn
        activeIndicator.BackgroundColor3 = window.Theme.Accent
        activeIndicator.BorderSizePixel = 0
        activeIndicator.Position = UDim2.new(0, -window.Theme.PaddingHorizontal - 10, 0.15, 0)
        activeIndicator.Size = UDim2.new(0, 3, 0.7, 0)
        activeIndicator.Visible = false
        addCorner(activeIndicator, 999)

        if icon then
            local iconLabel = Instance.new("ImageLabel")
            iconLabel.Parent = tabBtn
            iconLabel.BackgroundTransparency = 1
            iconLabel.Position = UDim2.new(0, 8, 0.5, -10)
            iconLabel.Size = UDim2.new(0, 20, 0, 20)
            iconLabel.Image = icon
            iconLabel.ImageColor3 = window.Theme.TextMuted
            tabBtn.Text = "      " .. name
        else
            tabBtn.TextXAlignment = Enum.TextXAlignment.Center
            tabBtn.Position = UDim2.new(0, 0, 0, 0)
            activeIndicator.Position = UDim2.new(0, 0, 0.15, 0)
        end

        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Parent = contentArea
        scrollFrame.Active = true
        scrollFrame.BackgroundColor3 = window.Theme.Background
        scrollFrame.BorderSizePixel = 0
        scrollFrame.Size = UDim2.new(1, 0, 1, 0)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.ScrollBarThickness = 5
        scrollFrame.ScrollBarImageColor3 = window.Theme.Accent
        scrollFrame.Visible = (#window.Tabs == 0)
        scrollFrame.ZIndex = 1

        local layout = Instance.new("UIListLayout")
        layout.Parent = scrollFrame
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, window.Theme.PaddingVertical)

        local padding = Instance.new("UIPadding")
        padding.Parent = scrollFrame
        padding.PaddingLeft = UDim.new(0, window.Theme.PaddingHorizontal)
        padding.PaddingRight = UDim.new(0, window.Theme.PaddingHorizontal + 6)
        padding.PaddingTop = UDim.new(0, window.Theme.PaddingVertical)
        padding.PaddingBottom = UDim.new(0, window.Theme.PaddingVertical)

        addConnection(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + window.Theme.PaddingVertical * 2)
        end))

        local tabData = {Button = tabBtn, Content = scrollFrame, ActiveIndicator = activeIndicator}
        table.insert(window.Tabs, tabData)

        if #window.Tabs == 1 then
            tabBtn.TextColor3 = window.Theme.Accent
            activeIndicator.Visible = true
            window.CurrentTab = scrollFrame
        end

        addConnection(tabBtn.MouseButton1Click:Connect(function()
            for _, t in ipairs(window.Tabs) do
                t.Button.TextColor3 = window.Theme.TextMuted
                t.Content.Visible = false
                if t.ActiveIndicator then t.ActiveIndicator.Visible = false end
            end
            tabBtn.TextColor3 = window.Theme.Accent
            activeIndicator.Visible = true
            scrollFrame.Visible = true
            window.CurrentTab = scrollFrame
        end))

        local elements = {}
        local controlFactory = ControlFactory:new(scrollFrame, window.Theme, saveConfig, loadConfig, window.SetAccent)
        controlFactory.controls = window.Flags
        controlFactory.registerControl = function(id, saveFunc, loadFunc, themeFunc)
            table.insert(window.Controls, {Id = id, Save = saveFunc, Load = loadFunc, UpdateTheme = themeFunc})
        end
        controlFactory.connections = window.Connections

        elements.CreateLabel = function(_, text) return controlFactory:createLabel(text) end
        elements.CreateSeparator = function() return controlFactory:createSeparator() end
        elements.CreateButton = function(_, opts) return controlFactory:createButton(opts) end
        elements.CreateToggle = function(_, opts) return controlFactory:createToggle(opts) end
        elements.CreateSlider = function(_, opts) return controlFactory:createSlider(opts) end
        elements.CreateDropdown = function(_, opts) return controlFactory:createDropdown(opts) end
        elements.CreateChecklist = function(_, opts) return controlFactory:createChecklist(opts) end
        elements.CreateTextInput = function(_, opts) return controlFactory:createTextInput(opts) end
        elements.CreateNumberInput = function(_, opts) return controlFactory:createNumberInput(opts) end
        elements.CreateKeybind = function(_, opts) return controlFactory:createKeybind(opts) end
        elements.CreateColorPicker = function(_, opts) return controlFactory:createColorPicker(opts) end
        elements.CreateRadioGroup = function(_, opts) return controlFactory:createRadioGroup(opts) end

        function elements:CreateSection(name)
            local section = Instance.new("TextLabel")
            section.Parent = scrollFrame
            section.BackgroundTransparency = 1
            section.Size = UDim2.new(1, 0, 0, 28)
            section.Font = window.Theme.Font
            section.Text = name
            section.TextColor3 = window.Theme.Accent
            section.TextSize = 15
            section.TextXAlignment = Enum.TextXAlignment.Left
            section.TextYAlignment = Enum.TextYAlignment.Center
            return section
        end

        function elements:CreateParagraph(opts)
            local title = opts.Title or ""
            local content = opts.Content or ""
            local imageUrl = opts.Image or ""

            local frame = Instance.new("Frame")
            frame.Parent = scrollFrame
            frame.BackgroundColor3 = window.Theme.Element
            frame.BorderSizePixel = 0
            frame.Size = UDim2.new(1, 0, 0, 0)
            addCorner(frame, window.Theme.CornerRadius)
            addStroke(frame, window.Theme.StrokeColor)

            local textContainer = Instance.new("Frame")
            textContainer.Parent = frame
            textContainer.BackgroundTransparency = 1
            textContainer.Position = UDim2.new(0, window.Theme.PaddingHorizontal, 0, window.Theme.PaddingVertical)
            textContainer.Size = UDim2.new(1, -2 * window.Theme.PaddingHorizontal, 0, 0)

            if imageUrl ~= "" then
                local imageLabel = Instance.new("ImageLabel")
                imageLabel.Parent = frame
                imageLabel.BackgroundTransparency = 1
                imageLabel.Position = UDim2.new(0, window.Theme.PaddingHorizontal, 0, window.Theme.PaddingVertical)
                imageLabel.Size = UDim2.new(0, 52, 0, 52)
                imageLabel.Image = imageUrl
                imageLabel.ScaleType = Enum.ScaleType.Fit
                addCorner(imageLabel, window.Theme.CornerRadius)
                textContainer.Position = UDim2.new(0, 72, 0, window.Theme.PaddingVertical)
                textContainer.Size = UDim2.new(1, -80, 0, 0)
            end

            local titleLabel = Instance.new("TextLabel")
            titleLabel.Parent = textContainer
            titleLabel.BackgroundTransparency = 1
            titleLabel.Size = UDim2.new(1, 0, 0, 0)
            titleLabel.Font = window.Theme.Font
            titleLabel.Text = title
            titleLabel.TextColor3 = window.Theme.Accent
            titleLabel.TextSize = window.Theme.TextSizeNormal
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.TextYAlignment = Enum.TextYAlignment.Top
            titleLabel.TextWrapped = true

            local contentLabel = Instance.new("TextLabel")
            contentLabel.Parent = textContainer
            contentLabel.BackgroundTransparency = 1
            contentLabel.Position = UDim2.new(0, 0, 0, 0)
            contentLabel.Size = UDim2.new(1, 0, 0, 0)
            contentLabel.Font = window.Theme.Font
            contentLabel.Text = content
            contentLabel.TextColor3 = window.Theme.TextMuted
            contentLabel.TextSize = window.Theme.TextSizeSmall
            contentLabel.TextXAlignment = Enum.TextXAlignment.Left
            contentLabel.TextYAlignment = Enum.TextYAlignment.Top
            contentLabel.TextWrapped = true

            local function updateSize()
                local titleHeight = title ~= "" and TextService:GetTextSize(title, window.Theme.TextSizeNormal, window.Theme.Font, Vector2.new(textContainer.AbsoluteSize.X, 9999)).Y or 0
                local contentHeight = content ~= "" and TextService:GetTextSize(content, window.Theme.TextSizeSmall, window.Theme.Font, Vector2.new(textContainer.AbsoluteSize.X, 9999)).Y or 0
                local total = titleHeight + contentHeight + 16
                if imageUrl ~= "" then total = math.max(total, 70) end
                titleLabel.Size = UDim2.new(1, 0, 0, titleHeight)
                contentLabel.Position = UDim2.new(0, 0, 0, titleHeight + 8)
                contentLabel.Size = UDim2.new(1, 0, 0, contentHeight)
                textContainer.Size = UDim2.new(1, textContainer.Size.X.Offset, 0, total)
                frame.Size = UDim2.new(1, 0, 0, total + 2 * window.Theme.PaddingVertical)
            end

            frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSize)
            updateSize()
            return frame
        end

        return elements
    end

    if window.ConfigFile ~= "" then loadConfig() end
    return window
end

return SynergyUI
