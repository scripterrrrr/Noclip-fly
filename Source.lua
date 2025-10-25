local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local COLOR_OFF = Color3.fromRGB(150, 40, 40)
local COLOR_ON = Color3.fromRGB(40, 150, 40)
local COLOR_OVERRIDDEN = Color3.fromRGB(80, 80, 80)

local splashGui = Instance.new("ScreenGui")
splashGui.Name = "SplashScreen_petrunya_nk"
splashGui.IgnoreGuiInset = true
splashGui.ResetOnSpawn = false
splashGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
splashGui.DisplayOrder = 999999
splashGui.Parent = PlayerGui

local background = Instance.new("Frame", splashGui)
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 45)

local creditText = Instance.new("TextLabel", background)
creditText.Size = UDim2.new(1, 0, 0, 100)
creditText.Position = UDim2.new(0.5, 0, 0.5, 0)
creditText.AnchorPoint = Vector2.new(0.5, 0.5)
creditText.BackgroundTransparency = 1
creditText.TextColor3 = Color3.fromRGB(225, 225, 225)
creditText.Font = Enum.Font.SourceSansBold
creditText.TextSize = 40
creditText.Text = "тг @petrunya_nk"

task.wait(3)
local fadeInfo = TweenInfo.new(1.5)
local backgroundFade = TweenService:Create(background, fadeInfo, {BackgroundTransparency = 1})
local textFade = TweenService:Create(creditText, fadeInfo, {TextTransparency = 1})
backgroundFade:Play()
backgroundFade.Completed:Wait()
splashGui:Destroy()

local flyActive, infJumpEnabled, freezeActive, flipActive = false, false, false, false
local flyNoclipConn, cube, godModeConnection, freezeConn = nil, nil, nil, nil
local speedInput
local originalWalkSpeed, originalJumpHeight = 16, 7.2
local globalWalkSpeed = 16

local flyBtn, infBtnUniversal, freezeBtnUniversal, infBtnSAB, flipFreezeBtn = nil, nil, nil, nil, nil

local function updateGodMode()
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
    if flyActive or infJumpEnabled or flipActive then
        if humanoid and not godModeConnection then
            godModeConnection = RunService.Heartbeat:Connect(function()
                if humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = humanoid.MaxHealth
                end
            end)
        end
    elseif godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
end

local function setCharacterVisualState(character, isFlipped)
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("MeshPart") then
            part.LocalTransparencyModifier = isFlipped and 0.999 or 0
            part.CanCollide = not isFlipped
        elseif part:IsA("Tool") then
            for _, toolPart in ipairs(part:GetDescendants()) do
                if toolPart:IsA("BasePart") then
                    toolPart.LocalTransparencyModifier = isFlipped and 0.999 or 0
                    toolPart.CanCollide = not isFlipped
                end
            end
        end
    end
    local head = character:FindFirstChild("Head")
    if head then
        local billboard = head:FindFirstChildOfClass("BillboardGui")
        if billboard then
            billboard.Enabled = not isFlipped
        end
    end
end

local function setFreezeState(state)
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end
    if state then
        globalWalkSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = 0
        root.Anchored = true
        freezeActive = true
        if not freezeConn then
            freezeConn = RunService.Heartbeat:Connect(function()
                root.Velocity = Vector3.new(0, 0, 0)
                root.RotVelocity = Vector3.new(0, 0, 0)
            end)
        end
    else
        if freezeConn then
            freezeConn:Disconnect()
            freezeConn = nil
        end
        root.Anchored = false
        humanoid.WalkSpeed = globalWalkSpeed
        freezeActive = false
    end
end

local function setFlipState(state)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
    if not root or not humanoid then return end
    if state then
        local flipRotation = CFrame.Angles(math.pi, 0, 0)
        local targetCFrame = root.CFrame * flipRotation
        local bodyHeight = 2.8
        local hipHeight = humanoid.HipHeight or 0.5
        local compensation = CFrame.new(0, -(bodyHeight - 2 * hipHeight), 0)
        root.CFrame = targetCFrame * compensation
        setCharacterVisualState(char, true)
        setFreezeState(true)
    else
        local _, y, _ = root.CFrame:ToOrientation()
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, y, 0)
        setCharacterVisualState(char, false)
        setFreezeState(false)
    end
    flipActive = state
    updateGodMode()
end

local function setFlyNoclip(state)
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    if state and not flyNoclipConn then
        originalWalkSpeed = humanoid.WalkSpeed
        originalJumpHeight = humanoid.JumpHeight
        humanoid.WalkSpeed = 0
        humanoid.JumpHeight = 0
        if cube and cube.Parent then cube:Destroy() end
        cube = Instance.new("Part", workspace)
        cube.Size = Vector3.new(0.7, 0.7, 0.7)
        cube.Anchored = true
        cube.CanCollide = false
        cube.Transparency = 1
        cube.Material = Enum.Material.Neon
        cube.Name = "FlyNoclipCube"
        if char:FindFirstChild("HumanoidRootPart") then
            cube.CFrame = char.HumanoidRootPart.CFrame
        end
        flyNoclipConn = RunService.RenderStepped:Connect(function()
            if not flyActive then return end
            local currentChar = LocalPlayer.Character
            if not currentChar then return end
            local root = currentChar:FindFirstChild("HumanoidRootPart")
            if not root or not Camera then return end
            local speedMultiplier = (speedInput and tonumber(speedInput.Text)) or 1
            local BASE_SPEED = 0.05
            local SPEED = speedMultiplier * BASE_SPEED
            local STEP = SPEED / 4
            local flyDir = Camera.CFrame.LookVector
            local nextPos = cube.Position + flyDir * STEP
            cube.CFrame = CFrame.new(nextPos, nextPos + flyDir)
            local target = cube.Position + flyDir * SPEED
            root.CFrame = CFrame.new(root.Position:Lerp(target, 0.2), root.Position + root.CFrame.LookVector)
            root.Velocity = Vector3.new(0, 0, 0)
        end)
    elseif not state and flyNoclipConn then
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpHeight = originalJumpHeight
        flyNoclipConn:Disconnect()
        flyNoclipConn = nil
        if cube and cube.Parent then cube:Destroy() end
    end
end

UserInputService.JumpRequest:Connect(function()
    if not infJumpEnabled then return end
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
    if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

local function updateButtonColor(btn, state, isOverridden)
    if not btn then return end
    if isOverridden then
        btn.BackgroundColor3 = COLOR_OVERRIDDEN
        btn.BackgroundTransparency = 0.5
        return
    end
    btn.BackgroundColor3 = state and COLOR_ON or COLOR_OFF
    btn.BackgroundTransparency = 0.08
end

local function updateFlyButton()
    if flyBtn then
        flyBtn.Text = flyActive and "Fly + Noclip: ON" or "Fly + Noclip"
        updateButtonColor(flyBtn, flyActive, false)
    end
    updateGodMode()
end

local function updateInfJumpButtons()
    local text = infJumpEnabled and "Infinity Jump: ON" or "Infinity Jump"
    if infBtnUniversal then
        infBtnUniversal.Text = text
        updateButtonColor(infBtnUniversal, infJumpEnabled, false)
    end
    if infBtnSAB then
        infBtnSAB.Text = text
        updateButtonColor(infBtnSAB, infJumpEnabled, false)
    end
    updateGodMode()
end

local function updateFlipButton()
    if flipFreezeBtn then
        flipFreezeBtn.Text = flipActive and "FLIP + FREEZE: ON" or "FLIP + FREEZE"
        updateButtonColor(flipFreezeBtn, flipActive, false)
    end
end

local function updateFreezeButtons()
    local freezeText = freezeActive and "Freeze: ON" or "Freeze"
    local isOverridden = flipActive
    if freezeBtnUniversal then
        if isOverridden then freezeBtnUniversal.Text = "[OVERRIDDEN]"
            updateButtonColor(freezeBtnUniversal, false, true)
        else
            freezeBtnUniversal.Text = freezeText
            updateButtonColor(freezeBtnUniversal, freezeActive, false)
        end
    end
end

local function resetUniversalCheats()
    if flyActive then
        setFlyNoclip(false)
        flyActive = false
        updateFlyButton()
    end
    infJumpEnabled = false
    updateInfJumpButtons()
    if flipActive then setFlipState(false) end
    updateFlipButton()
    setFreezeState(false)
    updateFreezeButtons()
    updateGodMode()
end

if PlayerGui:FindFirstChild("ModMenuGui") then PlayerGui.ModMenuGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ModMenuGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 99999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local function makeDraggable(trigger, elementToDrag, onClick)
    local dragging, dragStart, startPos, dragStartTime = false, nil, nil, 0
    trigger.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = elementToDrag.Position
            dragStartTime = tick()
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                    if tick() - dragStartTime < 0.2 and (dragStart - input.Position).Magnitude < 10 and onClick then onClick() end
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            elementToDrag.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + (input.Position - dragStart).X,
                startPos.Y.Scale, startPos.Y.Offset + (input.Position - dragStart).Y
            )
        end
    end)
end

local MENU_WIDTH, MENU_HEIGHT, SIDEBAR_WIDTH = 320, 420, 70
local CONTENT_WIDTH, CONTENT_X_OFFSET = MENU_WIDTH - SIDEBAR_WIDTH, SIDEBAR_WIDTH

local mainMenu = Instance.new("Frame", gui)
mainMenu.Size = UDim2.new(0, MENU_WIDTH, 0, MENU_HEIGHT)
mainMenu.Position = UDim2.new(0.5, -MENU_WIDTH/2, 0.5, -MENU_HEIGHT/2)
mainMenu.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainMenu.BorderSizePixel = 1
mainMenu.BorderColor3 = Color3.fromRGB(80, 80, 80)
mainMenu.Visible = false
Instance.new("UICorner", mainMenu).CornerRadius = UDim.new(0, 5)

local icon = Instance.new("ImageButton", gui)
icon.Size = UDim2.new(0, 60, 0, 60)
icon.Position = UDim2.new(0, 20, 0.5, -30)
icon.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
icon.BackgroundTransparency = 0.1
icon.BorderSizePixel = 0
Instance.new("UICorner", icon).CornerRadius = UDim.new(0.5, 0)
makeDraggable(icon, icon, function()
    mainMenu.Visible = not mainMenu.Visible
end)

local titleBar = Instance.new("Frame", mainMenu)
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleBar.BorderSizePixel = 0
makeDraggable(titleBar, mainMenu)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, -10, 1, 0)
titleText.Position = UDim2.new(0.5, 0, 0.5, 0)
titleText.AnchorPoint = Vector2.new(0.5, 0.5)
titleText.BackgroundTransparency = 1
titleText.Font = Enum.Font.SourceSansBold
titleText.TextColor3 = Color3.new(1, 1, 1)
titleText.Text = "Mod Menu"

local contentFrame = Instance.new("Frame", mainMenu)
contentFrame.Size = UDim2.new(0, CONTENT_WIDTH, 1, -30)
contentFrame.Position = UDim2.new(0, CONTENT_X_OFFSET, 0, 30)
contentFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
contentFrame.ClipsDescendants = true

local universalScriptsFrame = Instance.new("Frame", contentFrame)
universalScriptsFrame.Size = UDim2.new(1, 0, 1, 0)
universalScriptsFrame.BackgroundTransparency = 1
universalScriptsFrame.Visible = true

local sabScriptsFrame = Instance.new("Frame", contentFrame)
sabScriptsFrame.Size = UDim2.new(1, 0, 1, 0)
sabScriptsFrame.BackgroundTransparency = 1
sabScriptsFrame.Visible = false

local function makeBtn(parent, text, yPos)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -20, 0, 50)
    btn.Position = UDim2.new(0.5, 0, 0, yPos)
    btn.AnchorPoint = Vector2.new(0.5, 0)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextScaled = true
    btn.BackgroundTransparency = 0.08
    btn.BorderSizePixel = 0
    btn.BackgroundColor3 = COLOR_OFF
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local sidebarFrame = Instance.new("Frame", mainMenu)
sidebarFrame.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -30)
sidebarFrame.Position = UDim2.new(0, 0, 0, 30)
sidebarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local function switchSection(sectionFrame, button)
    for _, child in ipairs(sidebarFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end
    for _, child in ipairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") then child.Visible = false end
    end
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sectionFrame.Visible = true
end

local universalSectionBtn = Instance.new("TextButton", sidebarFrame)
universalSectionBtn.Size = UDim2.new(1, 0, 0, 50)
universalSectionBtn.Position = UDim2.new(0, 0, 0, 0)
universalSectionBtn.Text = "Universal"
universalSectionBtn.TextSize = 12
universalSectionBtn.TextColor3 = Color3.new(1, 1, 1)
universalSectionBtn.BorderSizePixel = 0
universalSectionBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

local sabSectionBtn = Instance.new("TextButton", sidebarFrame)
sabSectionBtn.Size = UDim2.new(1, 0, 0, 50)
sabSectionBtn.Position = UDim2.new(0, 0, 0, 50)
sabSectionBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
sabSectionBtn.Text = "SAB"
sabSectionBtn.TextSize = 12
sabSectionBtn.TextColor3 = Color3.new(1, 1, 1)
sabSectionBtn.BorderSizePixel = 0

universalSectionBtn.MouseButton1Click:Connect(function()
    switchSection(universalScriptsFrame, universalSectionBtn)
end)
sabSectionBtn.MouseButton1Click:Connect(function()
    switchSection(sabScriptsFrame, sabSectionBtn)
end)

flyBtn = makeBtn(universalScriptsFrame, "Fly + Noclip", 10)
local speedInputContainer = Instance.new("Frame", universalScriptsFrame)
speedInputContainer.Size = UDim2.new(1, -20, 0, 40)
speedInputContainer.Position = UDim2.new(0.5, 0, 0, 70)
speedInputContainer.AnchorPoint = Vector2.new(0.5, 0)
speedInputContainer.BackgroundTransparency = 1

local speedLabel = Instance.new("TextLabel", speedInputContainer)
speedLabel.Size = UDim2.new(0.4, 0, 1, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.SourceSansSemibold
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.TextSize = 16
speedLabel.Text = "Speed:"
speedLabel.TextXAlignment = Enum.TextXAlignment.Right

speedInput = Instance.new("TextBox", speedInputContainer)
speedInput.Size = UDim2.new(0.6, 0, 1, 0)
speedInput.Position = UDim2.new(0.4, 0, 0, 0)
speedInput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
speedInput.BackgroundTransparency = 0.5
speedInput.TextColor3 = Color3.new(1, 1, 1)
speedInput.Font = Enum.Font.SourceSansBold
speedInput.TextSize = 18
speedInput.Text = "1"
speedInput.ClearTextOnFocus = false
Instance.new("UICorner", speedInput).CornerRadius = UDim.new(0, 4)

infBtnUniversal = makeBtn(universalScriptsFrame, "Infinity Jump", 130)
freezeBtnUniversal = makeBtn(universalScriptsFrame, "Freeze", 190)
infBtnSAB = makeBtn(sabScriptsFrame, "Infinity Jump", 10)
flipFreezeBtn = makeBtn(sabScriptsFrame, "FLIP + FREEZE", 70)

flyBtn.MouseButton1Click:Connect(function()
    flyActive = not flyActive
    setFlyNoclip(flyActive)
    updateFlyButton()
end)

local function infJumpClicked()
    infJumpEnabled = not infJumpEnabled
    updateInfJumpButtons()
end
infBtnUniversal.MouseButton1Click:Connect(infJumpClicked)
infBtnSAB.MouseButton1Click:Connect(infJumpClicked)

freezeBtnUniversal.MouseButton1Click:Connect(function()
    if flipActive then return end
    setFreezeState(not freezeActive)
    updateFreezeButtons()
end)

flipFreezeBtn.MouseButton1Click:Connect(function()
    if flipActive then
        setFlipState(false)
    else
        setFlipState(true)
    end
    updateFlipButton()
    updateFreezeButtons()
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    resetUniversalCheats()
end)

updateFlyButton()
updateInfJumpButtons()
updateFreezeButtons()
updateFlipButton()
