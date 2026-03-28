local SynergyUI = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")

local function getDefaultParent()
    if RunService:IsStudio() then
        local player = Players.LocalPlayer
        if player then
            return player:WaitForChild("PlayerGui")
        end
    end
    return CoreGui
end

local function addCorner(frame, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = frame
    return corner
end

local function createTween(instance, duration, properties, style, direction)
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    local tweenInfo = TweenInfo.new(duration, style, direction)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
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
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    local pos = notification.Position or "TopRight"
    if pos == "TopRight" then
        frame.Position = UDim2.new(1, 210, 0, 10)
        frame.AnchorPoint = Vector2.new(1, 0)
    elseif pos == "TopLeft" then
        frame.Position = UDim2.new(0, -210, 0, 10)
        frame.AnchorPoint = Vector2.new(0, 0)
    elseif pos == "BottomRight" then
        frame.Position = UDim2.new(1, 210, 1, -60)
        frame.AnchorPoint = Vector2.new(1, 1)
    elseif pos == "BottomLeft" then
        frame.Position = UDim2.new(0, -210, 1, -60)
        frame.AnchorPoint = Vector2.new(0, 1)
    end
    frame.Size = UDim2.new(0, 250, 0, 50)
    addCorner(frame, 6)

    local indicator = Instance.new("Frame")
    indicator.Parent = frame
    indicator.BackgroundColor3 = notification.TypeColor or Color3.fromRGB(0, 255, 100)
    indicator.Size = UDim2.new(0, 4, 1, 0)
    addCorner(indicator, 6)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Font = Enum.Font.Gotham
    label.Text = notification.Message
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 13
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left

    local targetPos
    if pos == "TopRight" then
        targetPos = UDim2.new(1, -10, 0, 10)
    elseif pos == "TopLeft" then
        targetPos = UDim2.new(0, 10, 0, 10)
    elseif pos == "BottomRight" then
        targetPos = UDim2.new(1, -10, 1, -60)
    else
        targetPos = UDim2.new(0, 10, 1, -60)
    end
    createTween(frame, 0.4, {Position = targetPos})

    task.spawn(function()
        task.wait(notification.Duration or 3)
        local exitPos
        if pos == "TopRight" then
            exitPos = UDim2.new(1, 260, 0, 10)
        elseif pos == "TopLeft" then
            exitPos = UDim2.new(0, -260, 0, 10)
        elseif pos == "BottomRight" then
            exitPos = UDim2.new(1, 260, 1, -60)
        else
            exitPos = UDim2.new(0, -260, 1, -60)
        end
        createTween(frame, 0.4, {Position = exitPos})
        task.wait(0.4)
        gui:Destroy()
        showNextNotification()
    end)
end

function SynergyUI:Notify(message, duration, typeColor, position)
    table.insert(NotificationQueue, {Message = message, Duration = duration, TypeColor = typeColor, Position = position, Parent = nil})
    if #NotificationQueue == 1 then
        showNextNotification()
    end
end

local function createTooltip(parent, text, theme)
    local tooltip = Instance.new("Frame")
    tooltip.Name = "Tooltip"
    tooltip.Parent = parent
    tooltip.BackgroundColor3 = theme.Background
    tooltip.BorderSizePixel = 0
    tooltip.Position = UDim2.new(0, 0, 1, 2)
    tooltip.Size = UDim2.new(0, 100, 0, 20)
    tooltip.Visible = false
    addCorner(tooltip, 4)

    local label = Instance.new("TextLabel")
    label.Parent = tooltip
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = theme.Font
    label.Text = text
    label.TextColor3 = theme.Text
    label.TextSize = theme.TextSizeSmall
    label.TextWrapped = true
    return tooltip
end

local ControlFactory = {}
function ControlFactory:new(parent, theme, saveCallback, loadCallback, updateThemeCallback)
    local obj = {}
    obj.parent = parent
    obj.theme = theme
    obj.save = saveCallback
    obj.load = loadCallback
    obj.updateTheme = updateThemeCallback
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
    sep.BackgroundColor3 = self.theme.ElementDark
    sep.BorderSizePixel = 0
    sep.Size = UDim2.new(1, 0, 0, 2)
    return sep
end

function ControlFactory:createButton(options)
    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.ButtonHeight)
    addCorner(frame, self.theme.CornerRadius)

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Font = self.theme.Font
    btn.Text = options.Name
    btn.TextColor3 = self.theme.Text
    btn.TextSize = self.theme.TextSizeNormal

    local connection
    connection = btn.MouseButton1Click:Connect(function()
        local s, e = pcall(options.Callback)
        if not s then SynergyUI:Notify("Error: " .. tostring(e), 3, Color3.fromRGB(255, 50, 50)) end
        createTween(btn, 0.1, {TextColor3 = self.theme.Accent})
        task.wait(0.1)
        createTween(btn, 0.1, {TextColor3 = self.theme.Text})
    end)

    if options.Tooltip then
        local tooltip = createTooltip(btn, options.Tooltip, self.theme)
        local showTooltip, hideTooltip
        showTooltip = btn.MouseEnter:Connect(function() tooltip.Visible = true end)
        hideTooltip = btn.MouseLeave:Connect(function() tooltip.Visible = false end)
        table.insert(self.connections, showTooltip)
        table.insert(self.connections, hideTooltip)
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

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, 0)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Font = self.theme.Font
    label.Text = options.Name
    label.TextColor3 = state and self.theme.Accent or self.theme.Text
    label.TextSize = self.theme.TextSizeNormal
    label.TextXAlignment = Enum.TextXAlignment.Left

    local outer = Instance.new("Frame")
    outer.Parent = frame
    outer.BackgroundColor3 = self.theme.ElementDark
    outer.Position = UDim2.new(1, -self.theme.ToggleWidth - self.theme.PaddingHorizontal, 0.5, -self.theme.ToggleHeight/2)
    outer.Size = UDim2.new(0, self.theme.ToggleWidth, 0, self.theme.ToggleHeight)
    addCorner(outer, self.theme.ToggleHeight)

    local inner = Instance.new("Frame")
    inner.Parent = outer
    inner.BackgroundColor3 = state and self.theme.Accent or self.theme.TextMuted
    local innerSize = self.theme.ToggleHeight - 4
    inner.Position = state and UDim2.new(0, self.theme.ToggleWidth - innerSize - 2, 0, 2) or UDim2.new(0, 2, 0, 2)
    inner.Size = UDim2.new(0, innerSize, 0, innerSize)
    addCorner(inner, innerSize)

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = ""

    local function update(val)
        state = val
        createTween(inner, 0.2, {
            Position = state and UDim2.new(0, self.theme.ToggleWidth - innerSize - 2, 0, 2) or UDim2.new(0, 2, 0, 2),
            BackgroundColor3 = state and self.theme.Accent or self.theme.TextMuted
        })
        label.TextColor3 = state and self.theme.Accent or self.theme.Text
        local s, e = pcall(options.Callback, state)
        if not s then SynergyUI:Notify("Toggle error: " .. tostring(e), 3, Color3.fromRGB(255,50,50)) end
        self.save()
    end

    self.controls[flag] = {Set = function(_, v) update(v) end}
    local connection = btn.MouseButton1Click:Connect(function() update(not state) end)
    if state then pcall(options.Callback, state) end

    if options.Tooltip then
        local tooltip = createTooltip(btn, options.Tooltip, self.theme)
        local show = btn.MouseEnter:Connect(function() tooltip.Visible = true end)
        local hide = btn.MouseLeave:Connect(function() tooltip.Visible = false end)
        table.insert(self.connections, show)
        table.insert(self.connections, hide)
    end

    self.registerControl(flag,
        function() return state end,
        function(v) update(v) end,
        function(c)
            if state then
                inner.BackgroundColor3 = c
                label.TextColor3 = c
            end
        end
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

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical)
    label.Size = UDim2.new(0.7, 0, 0, self.theme.TextSizeNormal + 4)
    label.Font = self.theme.Font
    label.Text = options.Name
    label.TextColor3 = self.theme.Text
    label.TextSize = self.theme.TextSizeNormal
    label.TextXAlignment = Enum.TextXAlignment.Left

    local valLabel = Instance.new("TextLabel")
    valLabel.Parent = frame
    valLabel.BackgroundTransparency = 1
    valLabel.Position = UDim2.new(1, -60 - self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical)
    valLabel.Size = UDim2.new(0, 50, 0, self.theme.TextSizeNormal + 4)
    valLabel.Font = self.theme.Font
    valLabel.Text = tostring(val)
    valLabel.TextColor3 = self.theme.Accent
    valLabel.TextSize = self.theme.TextSizeNormal
    valLabel.TextXAlignment = Enum.TextXAlignment.Right

    local bg = Instance.new("Frame")
    bg.Parent = frame
    bg.BackgroundColor3 = self.theme.ElementDark
    bg.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical + self.theme.TextSizeNormal + 4)
    bg.Size = UDim2.new(1, -2 * self.theme.PaddingHorizontal, 0, self.theme.SliderBarHeight)
    addCorner(bg, self.theme.SliderBarHeight/2)

    local fill = Instance.new("Frame")
    fill.Parent = bg
    fill.BackgroundColor3 = self.theme.Accent
    fill.Size = UDim2.new((val - options.Range[1]) / (options.Range[2] - options.Range[1]), 0, 1, 0)
    addCorner(fill, self.theme.SliderBarHeight/2)

    local inputBg = Instance.new("Frame")
    inputBg.Parent = frame
    inputBg.BackgroundColor3 = self.theme.ElementDark
    inputBg.Position = UDim2.new(1, -70 - self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical + self.theme.TextSizeNormal + 4)
    inputBg.Size = UDim2.new(0, 60, 0, self.theme.SliderBarHeight)
    addCorner(inputBg, 4)

    local numInput = Instance.new("TextBox")
    numInput.Parent = inputBg
    numInput.BackgroundTransparency = 1
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
        createTween(fill, 0.1, {Size = UDim2.new((val - options.Range[1]) / (options.Range[2] - options.Range[1]), 0, 1, 0)})
        local s, e = pcall(options.Callback, val)
        if not s then SynergyUI:Notify("Slider error: " .. tostring(e), 3, Color3.fromRGB(255,50,50)) end
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then self.save() end
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

    self.registerControl(flag,
        function() return val end,
        function(v)
            val = v
            valLabel.Text = tostring(v)
            numInput.Text = tostring(v)
            fill.Size = UDim2.new((v - options.Range[1]) / (options.Range[2] - options.Range[1]), 0, 1, 0)
            pcall(options.Callback, v)
        end,
        function(c)
            fill.BackgroundColor3 = c
            valLabel.TextColor3 = c
        end
    )
    return frame, {connection1, connection2, connection3, connection4}
end

function ControlFactory:createDropdown(options)
    local current = options.CurrentOption or options.Options[1] or ""
    local optionsList = options.Options or {}
    local flag = options.Flag or options.Name
    local dropdown = {}

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.DropdownHeight)
    frame.ClipsDescendants = true
    addCorner(frame, self.theme.CornerRadius)

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundTransparency = 1
    btn.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, 0)
    btn.Size = UDim2.new(1, -2 * self.theme.PaddingHorizontal, 0, self.theme.DropdownHeight)
    btn.Font = self.theme.Font
    btn.Text = options.Name .. " : " .. current
    btn.TextColor3 = self.theme.Text
    btn.TextSize = self.theme.TextSizeNormal
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local icon = Instance.new("TextLabel")
    icon.Parent = btn
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.new(1, -20, 0, 0)
    icon.Size = UDim2.new(0, 20, 1, 0)
    icon.Font = self.theme.Font
    icon.Text = "+"
    icon.TextColor3 = self.theme.TextMuted
    icon.TextSize = self.theme.TextSizeNormal

    local container = Instance.new("ScrollingFrame")
    container.Parent = frame
    container.BackgroundColor3 = self.theme.ElementDark
    container.BorderSizePixel = 0
    container.Position = UDim2.new(0, 0, 0, self.theme.DropdownHeight)
    container.Size = UDim2.new(1, 0, 1, -self.theme.DropdownHeight)
    container.ScrollBarThickness = 3
    container.ScrollBarImageColor3 = self.theme.Accent

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local isOpen = false
    local optionButtons = {}

    local function updateButtonText()
        if current == "" then
            btn.Text = options.Name .. " : " .. "None"
        else
            btn.Text = options.Name .. " : " .. current
        end
    end

    local function rebuild()
        for _, btn in ipairs(optionButtons) do
            if btn and btn.Parent then btn:Destroy() end
        end
        optionButtons = {}
        for i, opt in ipairs(optionsList) do
            local optBtn = Instance.new("TextButton")
            optBtn.Parent = container
            optBtn.BackgroundColor3 = self.theme.ElementDark
            optBtn.BorderSizePixel = 0
            optBtn.Size = UDim2.new(1, 0, 0, self.theme.DropdownItemHeight)
            optBtn.Font = self.theme.Font
            optBtn.Text = opt
            optBtn.TextColor3 = self.theme.TextMuted
            optBtn.TextSize = self.theme.TextSizeSmall

            local connection = optBtn.MouseButton1Click:Connect(function()
                current = opt
                updateButtonText()
                isOpen = false
                createTween(frame, 0.2, {Size = UDim2.new(1, 0, 0, self.theme.DropdownHeight)})
                icon.Text = "+"
                pcall(options.Callback, opt)
                self.save()
            end)
            table.insert(optionButtons, optBtn)
        end
        container.CanvasSize = UDim2.new(0, 0, 0, #optionsList * self.theme.DropdownItemHeight)
    end
    rebuild()

    local connection = btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            local target = self.theme.DropdownHeight + math.min(#optionsList * self.theme.DropdownItemHeight, 150)
            createTween(frame, 0.2, {Size = UDim2.new(1, 0, 0, target)})
            icon.Text = "-"
        else
            createTween(frame, 0.2, {Size = UDim2.new(1, 0, 0, self.theme.DropdownHeight)})
            icon.Text = "+"
        end
    end)

    if options.Tooltip then
        local tooltip = createTooltip(btn, options.Tooltip, self.theme)
        local show = btn.MouseEnter:Connect(function() tooltip.Visible = true end)
        local hide = btn.MouseLeave:Connect(function() tooltip.Visible = false end)
        table.insert(self.connections, show)
        table.insert(self.connections, hide)
    end

    self.registerControl(flag,
        function() return current end,
        function(v)
            current = v
            updateButtonText()
            pcall(options.Callback, v)
        end,
        function(c)
            container.ScrollBarImageColor3 = c
        end
    )

    dropdown.SetOptions = function(_, newOpts)
        optionsList = newOpts
        rebuild()
        if not table.find(optionsList, current) then
            current = ""
            updateButtonText()
            pcall(options.Callback, "")
        end
    end

    dropdown.SetValue = function(_, val)
        if table.find(optionsList, val) or val == "" then
            current = val
            updateButtonText()
            pcall(options.Callback, val)
            self.save()
        end
    end

    dropdown.GetValue = function()
        return current
    end

    return frame, connection
end

function ControlFactory:createChecklist(options)
    local optionsList = options.Options or {}
    local selected = {}
    if options.CurrentSelected then
        for _, v in ipairs(options.CurrentSelected) do
            selected[v] = true
        end
    end
    local flag = options.Flag or options.Name

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.ChecklistHeight)
    frame.ClipsDescendants = true
    addCorner(frame, self.theme.CornerRadius)

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundTransparency = 1
    btn.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, 0)
    btn.Size = UDim2.new(1, -2 * self.theme.PaddingHorizontal, 0, self.theme.ChecklistHeight)
    btn.Font = self.theme.Font
    btn.Text = options.Name
    btn.TextColor3 = self.theme.Text
    btn.TextSize = self.theme.TextSizeNormal
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local countLabel = Instance.new("TextLabel")
    countLabel.Parent = btn
    countLabel.BackgroundTransparency = 1
    countLabel.Position = UDim2.new(1, -60, 0, 0)
    countLabel.Size = UDim2.new(0, 50, 1, 0)
    countLabel.Font = self.theme.Font
    countLabel.Text = "0 selected"
    countLabel.TextColor3 = self.theme.Accent
    countLabel.TextSize = self.theme.TextSizeSmall
    countLabel.TextXAlignment = Enum.TextXAlignment.Right

    local icon = Instance.new("TextLabel")
    icon.Parent = btn
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.new(1, -20, 0, 0)
    icon.Size = UDim2.new(0, 20, 1, 0)
    icon.Font = self.theme.Font
    icon.Text = "+"
    icon.TextColor3 = self.theme.TextMuted
    icon.TextSize = self.theme.TextSizeNormal

    local container = Instance.new("ScrollingFrame")
    container.Parent = frame
    container.BackgroundColor3 = self.theme.ElementDark
    container.BorderSizePixel = 0
    container.Position = UDim2.new(0, 0, 0, self.theme.ChecklistHeight)
    container.Size = UDim2.new(1, 0, 1, -self.theme.ChecklistHeight)
    container.ScrollBarThickness = 3
    container.ScrollBarImageColor3 = self.theme.Accent

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local function updateSelectedCount()
        local count = 0
        for _, v in pairs(selected) do if v then count = count + 1 end end
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

            local outer = Instance.new("Frame")
            outer.Parent = row
            outer.BackgroundColor3 = self.theme.Element
            outer.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0.5, -self.theme.ChecklistItemHeight/2)
            outer.Size = UDim2.new(0, self.theme.ToggleWidth, 0, self.theme.ToggleHeight)
            addCorner(outer, self.theme.ToggleHeight)

            local inner = Instance.new("Frame")
            inner.Parent = outer
            inner.BackgroundColor3 = selected[opt] and self.theme.Accent or self.theme.TextMuted
            local innerSize = self.theme.ToggleHeight - 4
            inner.Position = selected[opt] and UDim2.new(0, self.theme.ToggleWidth - innerSize - 2, 0, 2) or UDim2.new(0, 2, 0, 2)
            inner.Size = UDim2.new(0, innerSize, 0, innerSize)
            addCorner(inner, innerSize)

            local optLabel = Instance.new("TextLabel")
            optLabel.Parent = row
            optLabel.BackgroundTransparency = 1
            optLabel.Position = UDim2.new(0, self.theme.PaddingHorizontal + self.theme.ToggleWidth + 8, 0, 0)
            optLabel.Size = UDim2.new(1, -self.theme.PaddingHorizontal - self.theme.ToggleWidth - 8, 1, 0)
            optLabel.Font = self.theme.Font
            optLabel.Text = opt
            optLabel.TextColor3 = self.theme.TextMuted
            optLabel.TextSize = self.theme.TextSizeSmall
            optLabel.TextXAlignment = Enum.TextXAlignment.Left

            local btn = Instance.new("TextButton")
            btn.Parent = row
            btn.BackgroundTransparency = 1
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.Text = ""

            local connection = btn.MouseButton1Click:Connect(function()
                selected[opt] = not selected[opt]
                createTween(inner, 0.2, {
                    Position = selected[opt] and UDim2.new(0, self.theme.ToggleWidth - innerSize - 2, 0, 2) or UDim2.new(0, 2, 0, 2),
                    BackgroundColor3 = selected[opt] and self.theme.Accent or self.theme.TextMuted
                })
                updateSelectedCount()
            end)
        end
        container.CanvasSize = UDim2.new(0, 0, 0, #optionsList * self.theme.ChecklistItemHeight)
        updateSelectedCount()
    end
    rebuild()

    local isOpen = false
    local connection = btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            local target = self.theme.ChecklistHeight + math.min(#optionsList * self.theme.ChecklistItemHeight, 200)
            createTween(frame, 0.2, {Size = UDim2.new(1, 0, 0, target)})
            icon.Text = "-"
        else
            createTween(frame, 0.2, {Size = UDim2.new(1, 0, 0, self.theme.ChecklistHeight)})
            icon.Text = "+"
        end
    end)

    local function getSelectedTable()
        local result = {}
        for k, v in pairs(selected) do if v then table.insert(result, k) end end
        return result
    end

    local function setSelectedTable(tbl)
        for _, v in ipairs(optionsList) do selected[v] = false end
        for _, v in ipairs(tbl) do
            if selected[v] ~= nil then selected[v] = true end
        end
        rebuild()
    end

    self.registerControl(flag,
        function() return getSelectedTable() end,
        function(v) setSelectedTable(v) end,
        function(c)
            container.ScrollBarImageColor3 = c
            for _, row in ipairs(container:GetChildren()) do
                if row:IsA("Frame") then
                    local inner = row:FindFirstChild("Outer") and row.Outer:FindFirstChild("Inner")
                    if inner and selected[row.Text] then
                        inner.BackgroundColor3 = c
                    end
                end
            end
            countLabel.TextColor3 = c
        end
    )

    return {
        SetOptions = function(_, newOpts)
            optionsList = newOpts
            local newSelected = {}
            for _, v in ipairs(optionsList) do
                if selected[v] then newSelected[v] = true end
            end
            selected = newSelected
            rebuild()
        end,
        GetSelected = function() return getSelectedTable() end,
        SetSelected = function(_, tbl) setSelectedTable(tbl) end
    }, connection
end

function ControlFactory:createTextInput(options)
    local flag = options.Flag or options.Name

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.TextInputHeight)
    addCorner(frame, self.theme.CornerRadius)

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
    input.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical + self.theme.TextSizeNormal + 8)
    input.Size = UDim2.new(1, -2 * self.theme.PaddingHorizontal, 0, self.theme.TextInputFieldHeight)
    input.Font = self.theme.Font
    input.Text = options.CurrentText or ""
    input.TextColor3 = self.theme.TextMuted
    input.TextSize = self.theme.TextSizeSmall
    input.PlaceholderText = options.Placeholder or ""
    addCorner(input, self.theme.CornerRadius)

    local connection = input.FocusLost:Connect(function()
        pcall(options.Callback, input.Text)
        self.save()
    end)

    if options.Tooltip then
        local tooltip = createTooltip(input, options.Tooltip, self.theme)
        local show = input.MouseEnter:Connect(function() tooltip.Visible = true end)
        local hide = input.MouseLeave:Connect(function() tooltip.Visible = false end)
        table.insert(self.connections, show)
        table.insert(self.connections, hide)
    end

    self.registerControl(flag,
        function() return input.Text end,
        function(v) input.Text = v end,
        function(c) end
    )
    return frame, connection
end

function ControlFactory:createNumberInput(options)
    local flag = options.Flag or options.Name
    local currentVal = tonumber(options.CurrentValue) or 0

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.TextInputHeight)
    addCorner(frame, self.theme.CornerRadius)

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
    input.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, self.theme.PaddingVertical + self.theme.TextSizeNormal + 8)
    input.Size = UDim2.new(1, -2 * self.theme.PaddingHorizontal, 0, self.theme.TextInputFieldHeight)
    input.Font = self.theme.Font
    input.Text = tostring(currentVal)
    input.TextColor3 = self.theme.TextMuted
    input.TextSize = self.theme.TextSizeSmall
    addCorner(input, self.theme.CornerRadius)

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

    self.registerControl(flag,
        function() return currentVal end,
        function(v) currentVal = tonumber(v) or 0; input.Text = tostring(currentVal) end,
        function(c) end
    )
    return frame, connection
end

function ControlFactory:createKeybind(options)
    local current = options.CurrentKeybind or "None"
    local flag = options.Flag or options.Name

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.KeybindHeight)
    addCorner(frame, self.theme.CornerRadius)

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

    local binding = false
    local connection1 = bindBtn.MouseButton1Click:Connect(function()
        binding = true
        bindBtn.Text = "..."
    end)

    local connection2 = UserInputService.InputBegan:Connect(function(input, gp)
        if binding then
            if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType:find("MouseButton") then
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

    self.registerControl(flag,
        function() return current end,
        function(v) current = v; bindBtn.Text = v end,
        function(c) bindBtn.TextColor3 = c end
    )
    return frame, {connection1, connection2}
end

function ControlFactory:createColorPicker(options)
    local color = options.Color or Color3.fromRGB(255, 255, 255)
    local flag = options.Flag or options.Name

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, self.theme.ColorPickerHeight)
    frame.ClipsDescendants = true
    addCorner(frame, self.theme.CornerRadius)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, 0)
    label.Size = UDim2.new(0.7, 0, 0, self.theme.ColorPickerHeight)
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

    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 0, self.theme.ColorPickerHeight)
    btn.Text = ""

    local container = Instance.new("Frame")
    container.Parent = frame
    container.BackgroundColor3 = self.theme.ElementDark
    container.Position = UDim2.new(0, 0, 0, self.theme.ColorPickerHeight)
    container.Size = UDim2.new(1, 0, 1, -self.theme.ColorPickerHeight)

    local r, g, b = color.R, color.G, color.B
    local function update()
        local c = Color3.new(r, g, b)
        preview.BackgroundColor3 = c
        pcall(options.Callback, c)
        self.save()
    end

    local function make(name, y, tint, init, cb)
        local sFrame = Instance.new("Frame")
        sFrame.Parent = container
        sFrame.BackgroundTransparency = 1
        sFrame.Position = UDim2.new(0, 0, 0, y)
        sFrame.Size = UDim2.new(1, 0, 0, 30)

        local sLbl = Instance.new("TextLabel")
        sLbl.Parent = sFrame
        sLbl.BackgroundTransparency = 1
        sLbl.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, 0)
        sLbl.Size = UDim2.new(0, 15, 1, 0)
        sLbl.Font = self.theme.Font
        sLbl.Text = name
        sLbl.TextColor3 = tint
        sLbl.TextSize = self.theme.TextSizeSmall

        local sBg = Instance.new("Frame")
        sBg.Parent = sFrame
        sBg.BackgroundColor3 = self.theme.Element
        sBg.Position = UDim2.new(0, 35, 0.5, -4)
        sBg.Size = UDim2.new(1, -self.theme.PaddingHorizontal - 35, 0, 8)
        addCorner(sBg, 8)

        local sFill = Instance.new("Frame")
        sFill.Parent = sBg
        sFill.BackgroundColor3 = tint
        sFill.Size = UDim2.new(init, 0, 1, 0)
        addCorner(sFill, 8)

        local sBtn = Instance.new("TextButton")
        sBtn.Parent = sBg
        sBtn.BackgroundTransparency = 1
        sBtn.Size = UDim2.new(1, 0, 1, 0)
        sBtn.Text = ""

        local dragging = false
        local connection1 = sBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                local pos = math.clamp((input.Position.X - sBg.AbsolutePosition.X) / sBg.AbsoluteSize.X, 0, 1)
                sFill.Size = UDim2.new(pos, 0, 1, 0)
                cb(pos)
            end
        end)
        local connection2 = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        local connection3 = UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local pos = math.clamp((input.Position.X - sBg.AbsolutePosition.X) / sBg.AbsoluteSize.X, 0, 1)
                sFill.Size = UDim2.new(pos, 0, 1, 0)
                cb(pos)
            end
        end)
        table.insert(self.connections, connection1)
        table.insert(self.connections, connection2)
        table.insert(self.connections, connection3)
    end

    make("R", 5, Color3.fromRGB(255, 80, 80), r, function(v) r = v update() end)
    make("G", 35, Color3.fromRGB(80, 255, 80), g, function(v) g = v update() end)
    make("B", 65, Color3.fromRGB(80, 150, 255), b, function(v) b = v update() end)

    local isOpen = false
    local connection = btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        createTween(frame, 0.2, {Size = UDim2.new(1, 0, 0, isOpen and self.theme.ColorPickerExpandedHeight or self.theme.ColorPickerHeight)})
    end)

    self.registerControl(flag,
        function() return {r, g, b} end,
        function(v) r, g, b = v[1], v[2], v[3]; update() end,
        function(c) end
    )
    return frame, connection
end

function ControlFactory:createRadioGroup(options)
    local selected = options.CurrentValue or options.Options[1] or ""
    local flag = options.Flag or options.Name
    local group = {}

    local frame = Instance.new("Frame")
    frame.Parent = self.parent
    frame.BackgroundColor3 = self.theme.Element
    frame.Size = UDim2.new(1, 0, 0, #options.Options * self.theme.RadioItemHeight + 8)
    frame.ClipsDescendants = true
    addCorner(frame, self.theme.CornerRadius)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0, 4)
    label.Size = UDim2.new(1, -2 * self.theme.PaddingHorizontal, 0, 20)
    label.Font = self.theme.Font
    label.Text = options.Name
    label.TextColor3 = self.theme.Text
    label.TextSize = self.theme.TextSizeNormal
    label.TextXAlignment = Enum.TextXAlignment.Left

    local layout = Instance.new("UIListLayout")
    layout.Parent = frame
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local radioButtons = {}
    local function update(opt)
        selected = opt
        for _, btn in ipairs(radioButtons) do
            if btn.Option == opt then
                btn.Inner.BackgroundColor3 = self.theme.Accent
            else
                btn.Inner.BackgroundColor3 = self.theme.TextMuted
            end
        end
        pcall(options.Callback, selected)
        self.save()
    end

    for i, opt in ipairs(options.Options) do
        local row = Instance.new("Frame")
        row.Parent = frame
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, 0, 0, self.theme.RadioItemHeight)

        local outer = Instance.new("Frame")
        outer.Parent = row
        outer.BackgroundColor3 = self.theme.ElementDark
        outer.Position = UDim2.new(0, self.theme.PaddingHorizontal, 0.5, -self.theme.RadioItemHeight/2)
        outer.Size = UDim2.new(0, self.theme.ToggleWidth, 0, self.theme.ToggleHeight)
        addCorner(outer, self.theme.ToggleHeight)

        local inner = Instance.new("Frame")
        inner.Parent = outer
        inner.BackgroundColor3 = (opt == selected) and self.theme.Accent or self.theme.TextMuted
        local innerSize = self.theme.ToggleHeight - 4
        inner.Position = UDim2.new(0, 2, 0, 2)
        inner.Size = UDim2.new(0, innerSize, 0, innerSize)
        addCorner(inner, innerSize)

        local optLabel = Instance.new("TextLabel")
        optLabel.Parent = row
        optLabel.BackgroundTransparency = 1
        optLabel.Position = UDim2.new(0, self.theme.PaddingHorizontal + self.theme.ToggleWidth + 8, 0, 0)
        optLabel.Size = UDim2.new(1, -self.theme.PaddingHorizontal - self.theme.ToggleWidth - 8, 1, 0)
        optLabel.Font = self.theme.Font
        optLabel.Text = opt
        optLabel.TextColor3 = self.theme.TextMuted
        optLabel.TextSize = self.theme.TextSizeSmall
        optLabel.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton")
        btn.Parent = row
        btn.BackgroundTransparency = 1
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.Text = ""

        local connection = btn.MouseButton1Click:Connect(function()
            if opt ~= selected then
                update(opt)
            end
        end)

        table.insert(radioButtons, {Option = opt, Inner = inner, Btn = btn})
    end

    self.registerControl(flag,
        function() return selected end,
        function(v) if table.find(options.Options, v) then update(v) end end,
        function(c)
            for _, btn in ipairs(radioButtons) do
                if btn.Option == selected then
                    btn.Inner.BackgroundColor3 = c
                end
            end
        end
    )
    return frame, nil
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
            Accent = options.AccentColor or Color3.fromRGB(0, 255, 100),
            Background = options.BackgroundColor or Color3.fromRGB(15, 15, 15),
            Sidebar = options.SidebarColor or Color3.fromRGB(20, 20, 20),
            Element = Color3.fromRGB(25, 25, 25),
            ElementDark = Color3.fromRGB(15, 15, 15),
            Text = Color3.fromRGB(255, 255, 255),
            TextMuted = Color3.fromRGB(180, 180, 180),
            Font = options.Font or Enum.Font.Gotham,
            CornerRadius = options.CornerRadius or 6,
            PaddingHorizontal = options.PaddingHorizontal or 10,
            PaddingVertical = options.PaddingVertical or 6,
            TextSizeNormal = options.TextSizeNormal or 13,
            TextSizeSmall = options.TextSizeSmall or 12,
            LabelHeight = options.LabelHeight or 20,
            ButtonHeight = options.ButtonHeight or 35,
            ToggleHeight = options.ToggleHeight or 35,
            ToggleWidth = options.ToggleWidth or 30,
            SliderHeight = options.SliderHeight or 45,
            SliderBarHeight = options.SliderBarHeight or 8,
            DropdownHeight = options.DropdownHeight or 35,
            DropdownItemHeight = options.DropdownItemHeight or 25,
            ChecklistHeight = options.ChecklistHeight or 35,
            ChecklistItemHeight = options.ChecklistItemHeight or 30,
            TextInputHeight = options.TextInputHeight or 45,
            TextInputFieldHeight = options.TextInputFieldHeight or 15,
            KeybindHeight = options.KeybindHeight or 35,
            KeybindWidth = options.KeybindWidth or 60,
            ColorPickerHeight = options.ColorPickerHeight or 35,
            ColorPickerPreviewSize = options.ColorPickerPreviewSize or 25,
            ColorPickerExpandedHeight = options.ColorPickerExpandedHeight or 135,
            RadioItemHeight = options.RadioItemHeight or 30,
        },
        ToggleKey = options.ToggleKey or Enum.KeyCode.RightShift,
        IsVisible = true,
        IsMinimized = false
    }

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
    mainFrame.BorderColor3 = window.Theme.Accent
    mainFrame.BorderSizePixel = 1
    mainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
    mainFrame.Size = UDim2.new(0, 550, 0, 350)
    mainFrame.ClipsDescendants = true
    addCorner(mainFrame, window.Theme.CornerRadius)
    window.MainFrame = mainFrame

    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Parent = mainFrame
    topBar.BackgroundColor3 = window.Theme.Sidebar
    topBar.BorderSizePixel = 0
    topBar.Size = UDim2.new(1, 0, 0, 35)
    topBar.ZIndex = 10
    addCorner(topBar, window.Theme.CornerRadius)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = topBar
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, window.Theme.PaddingHorizontal, 0, 0)
    titleLabel.Size = UDim2.new(0, 200, 1, 0)
    titleLabel.Font = window.Theme.Font
    titleLabel.Text = options.Title or "Synergy Hub"
    titleLabel.TextColor3 = window.Theme.Accent
    titleLabel.TextSize = window.Theme.TextSizeNormal
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 10

    local controlContainer = Instance.new("Frame")
    controlContainer.Parent = topBar
    controlContainer.BackgroundTransparency = 1
    controlContainer.Position = UDim2.new(1, -70, 0, 0)
    controlContainer.Size = UDim2.new(0, 70, 1, 0)
    controlContainer.ZIndex = 10

    local minBtn = Instance.new("TextButton")
    minBtn.Parent = controlContainer
    minBtn.BackgroundTransparency = 1
    minBtn.Size = UDim2.new(0.5, 0, 1, 0)
    minBtn.Font = window.Theme.Font
    minBtn.Text = "-"
    minBtn.TextColor3 = window.Theme.Text
    minBtn.TextSize = 18
    minBtn.ZIndex = 10

    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = controlContainer
    closeBtn.BackgroundTransparency = 1
    closeBtn.Position = UDim2.new(0.5, 0, 0, 0)
    closeBtn.Size = UDim2.new(0.5, 0, 1, 0)
    closeBtn.Font = window.Theme.Font
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.TextSize = 14
    closeBtn.ZIndex = 10

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Parent = mainFrame
    sidebar.BackgroundColor3 = window.Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Position = UDim2.new(0, 0, 0, 35)
    sidebar.Size = UDim2.new(0, 140, 1, -35)
    sidebar.ZIndex = 5

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Parent = sidebar
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Parent = mainFrame
    contentArea.BackgroundColor3 = window.Theme.Background
    contentArea.BorderSizePixel = 0
    contentArea.Position = UDim2.new(0, 140, 0, 35)
    contentArea.Size = UDim2.new(1, -140, 1, -35)
    contentArea.ZIndex = 1

    local resizeGrip = Instance.new("TextButton")
    resizeGrip.Name = "ResizeGrip"
    resizeGrip.Parent = mainFrame
    resizeGrip.BackgroundTransparency = 1
    resizeGrip.Position = UDim2.new(1, -15, 1, -15)
    resizeGrip.Size = UDim2.new(0, 15, 0, 15)
    resizeGrip.Text = "â¢"
    resizeGrip.TextColor3 = window.Theme.TextMuted
    resizeGrip.TextSize = 10
    resizeGrip.ZIndex = 20

    local function addConnection(conn)
        table.insert(window.Connections, conn)
        return conn
    end

    local dragging = false
    local dragStart, startPos
    addConnection(topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end))

    addConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))

    local resizing = false
    local resizeStart, startSize
    addConnection(resizeGrip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = mainFrame.Size
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then resizing = false end
            end)
        end
    end))

    addConnection(UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local newWidth = math.clamp(startSize.X.Offset + delta.X, 400, 1200)
            local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 250, 800)
            mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end))

    addConnection(minBtn.MouseButton1Click:Connect(function()
        window.IsMinimized = not window.IsMinimized
        if window.IsMinimized then
            createTween(mainFrame, 0.3, {Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 35)})
        else
            createTween(mainFrame, 0.3, {Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 350)})
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

    local ctrlTabConn = nil
    if options.EnableCtrlTab then
        ctrlTabConn = UserInputService.InputBegan:Connect(function(input, gp)
            if not gp and input.KeyCode == Enum.KeyCode.Tab and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                if #window.Tabs > 0 then
                    local currentIdx = nil
                    for i, tab in ipairs(window.Tabs) do
                        if tab.Content.Visible then
                            currentIdx = i
                            break
                        end
                    end
                    local nextIdx = (currentIdx or 1) % #window.Tabs + 1
                    window.Tabs[nextIdx].Button:Click()
                end
            end
        end)
        addConnection(ctrlTabConn)
    end

    local function saveConfig()
        if window.ConfigFile == "" then return end
        local config = {
            position = {mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset},
            size = {mainFrame.Size.X.Scale, mainFrame.Size.X.Offset, mainFrame.Size.Y.Scale, mainFrame.Size.Y.Offset},
            accent = {window.Theme.Accent.R, window.Theme.Accent.G, window.Theme.Accent.B},
            theme = {
                Background = {window.Theme.Background.R, window.Theme.Background.G, window.Theme.Background.B},
                Sidebar = {window.Theme.Sidebar.R, window.Theme.Sidebar.G, window.Theme.Sidebar.B},
                Element = {window.Theme.Element.R, window.Theme.Element.G, window.Theme.Element.B},
                ElementDark = {window.Theme.ElementDark.R, window.Theme.ElementDark.G, window.Theme.ElementDark.B},
                Text = {window.Theme.Text.R, window.Theme.Text.G, window.Theme.Text.B},
                TextMuted = {window.Theme.TextMuted.R, window.Theme.TextMuted.G, window.Theme.TextMuted.B},
                Font = window.Theme.Font.Name,
                CornerRadius = window.Theme.CornerRadius,
                PaddingHorizontal = window.Theme.PaddingHorizontal,
                PaddingVertical = window.Theme.PaddingVertical,
                TextSizeNormal = window.Theme.TextSizeNormal,
                TextSizeSmall = window.Theme.TextSizeSmall,
            },
            controls = {}
        }
        for _, control in ipairs(window.Controls) do
            if control.Save then
                config.controls[control.Id] = control.Save()
            end
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
                    if decoded.theme then
                        local theme = decoded.theme
                        window.Theme.Background = Color3.new(theme.Background[1], theme.Background[2], theme.Background[3])
                        window.Theme.Sidebar = Color3.new(theme.Sidebar[1], theme.Sidebar[2], theme.Sidebar[3])
                        window.Theme.Element = Color3.new(theme.Element[1], theme.Element[2], theme.Element[3])
                        window.Theme.ElementDark = Color3.new(theme.ElementDark[1], theme.ElementDark[2], theme.ElementDark[3])
                        window.Theme.Text = Color3.new(theme.Text[1], theme.Text[2], theme.Text[3])
                        window.Theme.TextMuted = Color3.new(theme.TextMuted[1], theme.TextMuted[2], theme.TextMuted[3])
                        window.Theme.Font = Enum.Font[theme.Font] or Enum.Font.Gotham
                        window.Theme.CornerRadius = theme.CornerRadius
                        window.Theme.PaddingHorizontal = theme.PaddingHorizontal
                        window.Theme.PaddingVertical = theme.PaddingVertical
                        window.Theme.TextSizeNormal = theme.TextSizeNormal
                        window.Theme.TextSizeSmall = theme.TextSizeSmall
                        mainFrame.BackgroundColor3 = window.Theme.Background
                        topBar.BackgroundColor3 = window.Theme.Sidebar
                        sidebar.BackgroundColor3 = window.Theme.Sidebar
                        contentArea.BackgroundColor3 = window.Theme.Background
                        titleLabel.Font = window.Theme.Font
                        titleLabel.TextColor3 = window.Theme.Accent
                        minBtn.Font = window.Theme.Font
                        closeBtn.Font = window.Theme.Font
                        for _, tab in ipairs(window.Tabs) do
                            tab.Button.Font = window.Theme.Font
                            tab.Button.BackgroundColor3 = window.Theme.Sidebar
                        end
                        for _, control in ipairs(window.Controls) do
                            if control.UpdateTheme then
                                control.UpdateTheme(window.Theme.Accent)
                            end
                        end
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
        mainFrame.BorderColor3 = color
        titleLabel.TextColor3 = color
        for _, tab in ipairs(window.Tabs) do
            if tab.Button.TextColor3 ~= window.Theme.TextMuted then
                tab.Button.TextColor3 = color
            end
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
        tabBtn.Size = UDim2.new(1, 0, 0, 35)
        tabBtn.Font = window.Theme.Font
        tabBtn.Text = name
        tabBtn.TextColor3 = window.Theme.TextMuted
        tabBtn.TextSize = window.Theme.TextSizeSmall

        if icon then
            local iconLabel = Instance.new("ImageLabel")
            iconLabel.Parent = tabBtn
            iconLabel.BackgroundTransparency = 1
            iconLabel.Position = UDim2.new(0, 10, 0.5, -8)
            iconLabel.Size = UDim2.new(0, 16, 0, 16)
            iconLabel.Image = icon
            iconLabel.ImageColor3 = window.Theme.TextMuted
            tabBtn.Text = "      " .. name
            tabBtn.TextXAlignment = Enum.TextXAlignment.Left
        else
            tabBtn.TextXAlignment = Enum.TextXAlignment.Center
        end

        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Parent = contentArea
        scrollFrame.Active = true
        scrollFrame.BackgroundColor3 = window.Theme.Background
        scrollFrame.BorderSizePixel = 0
        scrollFrame.Size = UDim2.new(1, 0, 1, 0)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.ScrollBarThickness = 3
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
        padding.PaddingRight = UDim.new(0, window.Theme.PaddingHorizontal + 5)
        padding.PaddingTop = UDim.new(0, window.Theme.PaddingVertical)
        padding.PaddingBottom = UDim.new(0, window.Theme.PaddingVertical)

        addConnection(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + window.Theme.PaddingVertical*2)
        end))

        local tabData = {Button = tabBtn, Content = scrollFrame}
        table.insert(window.Tabs, tabData)

        if #window.Tabs == 1 then
            tabBtn.TextColor3 = window.Theme.Accent
            window.CurrentTab = scrollFrame
        end

        addConnection(tabBtn.MouseButton1Click:Connect(function()
            for _, t in ipairs(window.Tabs) do
                t.Button.TextColor3 = window.Theme.TextMuted
                t.Content.Visible = false
            end
            tabBtn.TextColor3 = window.Theme.Accent
            scrollFrame.Visible = true
            window.CurrentTab = scrollFrame
        end))

        local elements = {}
        local controlFactory = ControlFactory:new(scrollFrame, window.Theme, saveConfig, loadConfig, window.SetAccent)
        controlFactory.controls = window.Flags
        controlFactory.registerControl = function(id, saveFunc, loadFunc, themeFunc)
            table.insert(window.Controls, {
                Id = id,
                Save = saveFunc,
                Load = loadFunc,
                UpdateTheme = themeFunc
            })
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
            section.Size = UDim2.new(1, 0, 0, 25)
            section.Font = window.Theme.Font
            section.Text = name
            section.TextColor3 = window.Theme.Text
            section.TextSize = window.Theme.TextSizeNormal
            section.TextXAlignment = Enum.TextXAlignment.Left
            section.TextYAlignment = Enum.TextYAlignment.Center
            return section
        end

        function elements:CreateParagraph(opts)
            local title = opts.Title or ""
            local content = opts.Content or ""
            local imageUrl = opts.Image

            local frame = Instance.new("Frame")
            frame.Parent = scrollFrame
            frame.BackgroundColor3 = window.Theme.Element
            frame.BorderSizePixel = 0
            frame.Size = UDim2.new(1, 0, 0, 0)
            addCorner(frame, window.Theme.CornerRadius)

            local imageLabel = nil
            local textContainer = nil

            if imageUrl and imageUrl ~= "" then
                imageLabel = Instance.new("ImageLabel")
                imageLabel.Parent = frame
                imageLabel.BackgroundColor3 = window.Theme.ElementDark
                imageLabel.Position = UDim2.new(0, window.Theme.PaddingHorizontal, 0, window.Theme.PaddingVertical)
                imageLabel.Size = UDim2.new(0, 50, 0, 50)
                imageLabel.Image = imageUrl
                imageLabel.ScaleType = Enum.ScaleType.Fit
                addCorner(imageLabel, window.Theme.CornerRadius)

                textContainer = Instance.new("Frame")
                textContainer.Parent = frame
                textContainer.BackgroundTransparency = 1
                textContainer.Position = UDim2.new(0, 66, 0, window.Theme.PaddingVertical)
                textContainer.Size = UDim2.new(1, -74 - window.Theme.PaddingHorizontal, 0, 0)
            else
                textContainer = Instance.new("Frame")
                textContainer.Parent = frame
                textContainer.BackgroundTransparency = 1
                textContainer.Position = UDim2.new(0, window.Theme.PaddingHorizontal, 0, window.Theme.PaddingVertical)
                textContainer.Size = UDim2.new(1, -2 * window.Theme.PaddingHorizontal, 0, 0)
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
                local titleHeight = 0
                local contentHeight = 0
                if title ~= "" then
                    titleHeight = TextService:GetTextSize(title, window.Theme.TextSizeNormal, window.Theme.Font, Vector2.new(textContainer.AbsoluteSize.X, 1000)).Y
                end
                if content ~= "" then
                    contentHeight = TextService:GetTextSize(content, window.Theme.TextSizeSmall, window.Theme.Font, Vector2.new(textContainer.AbsoluteSize.X, 1000)).Y
                end
                local totalTextHeight = titleHeight + contentHeight + 8
                if imageUrl and imageUrl ~= "" then
                    totalTextHeight = math.max(totalTextHeight, 58)
                end
                titleLabel.Size = UDim2.new(1, 0, 0, titleHeight)
                contentLabel.Position = UDim2.new(0, 0, 0, titleHeight + 4)
                contentLabel.Size = UDim2.new(1, 0, 0, contentHeight)
                textContainer.Size = UDim2.new(1, textContainer.Size.X.Offset, 0, totalTextHeight)
                frame.Size = UDim2.new(1, 0, 0, totalTextHeight + 2 * window.Theme.PaddingVertical)
            end

            frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSize)
            titleLabel:GetPropertyChangedSignal("Text"):Connect(updateSize)
            contentLabel:GetPropertyChangedSignal("Text"):Connect(updateSize)
            if textContainer then
                textContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSize)
            end
            updateSize()
            return frame
        end

        return elements
    end

    if window.ConfigFile ~= "" then loadConfig() end
    return window
end

return SynergyUI
