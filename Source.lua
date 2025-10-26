-- Mod Menu (cleaned & fixed)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MyCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local MyRoot = MyCharacter and MyCharacter:FindFirstChild("HumanoidRootPart")

-- NOTE: the following raw metatable override is typically used in exploit environments.
-- Keep or remove depending on your environment/security model.
local success, mt = pcall(function() return getrawmetatable(game) end)
if success and mt then
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = function(self, ...)
        local m = getnamecallmethod()
        if m == "Kick" and self == Players.LocalPlayer then
            return
        end
        return oldNamecall(self, ...)
    end
    setreadonly(mt, true)
end

local COLOR_OFF = Color3.fromRGB(150, 40, 40)
local COLOR_ON = Color3.fromRGB(40, 150, 40)
local COLOR_OVERRIDDEN = Color3.fromRGB(80, 80, 80)

-- Splash screen
local splashGui = Instance.new("ScreenGui")
splashGui.Name = "SplashScreen_petrunya_nk"
splashGui.IgnoreGuiInset = true
splashGui.ResetOnSpawn = false
splashGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
splashGui.DisplayOrder = 999999
splashGui.Parent = PlayerGui

local bg = Instance.new("Frame", splashGui)
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 45)

local ct = Instance.new("TextLabel", bg)
ct.Size = UDim2.new(1, 0, 0, 100)
ct.Position = UDim2.new(0.5, 0, 0.5, 0)
ct.AnchorPoint = Vector2.new(0.5, 0.5)
ct.BackgroundTransparency = 1
ct.TextColor3 = Color3.fromRGB(225, 225, 225)
ct.Font = Enum.Font.SourceSansBold
ct.TextSize = 40
ct.Text = "тг @petrunya_nk"

task.wait(3)
local fi = TweenInfo.new(1.5)
local bf = TweenService:Create(bg, fi, { BackgroundTransparency = 1 })
local tf = TweenService:Create(ct, fi, { TextTransparency = 1 })
bf:Play()
tf:Play()
bf.Completed:Wait()
splashGui:Destroy()

-- state
local flyActive = false
local infJumpEnabled = false
local freezeActive = false
local flipActive = false
local isElevatorEnabled = false

local flyNoclipConn, cube, godModeConnection, freezeConn, CloneAnchorLoop = nil, nil, nil, nil, nil
local speedInput
local originalWalkSpeed, originalJumpHeight = 16, 7.2
local globalWalkSpeed = 16

local flyBtn, infBtnUniversal, freezeBtnUniversal, infBtnSAB, flipFreezeBtn, elevatorBtnSAB = nil, nil, nil, nil, nil, nil
local draggableElevatorButton = nil

-- helpers for clone finding
local function findCloneRoot()
    local localUserId = tostring(LocalPlayer.UserId)
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and tostring(obj.Name):find(localUserId) then
            if obj ~= MyCharacter then
                local cr = obj:FindFirstChild("HumanoidRootPart")
                if cr and cr:IsA("BasePart") then
                    return cr
                end
            end
        end
    end
    return nil
end

local function moveCloneToAnchor(cr)
    if not MyRoot or not MyRoot.Parent then return end
    if not cr or not cr.Parent then return end
    local mc = MyRoot.CFrame
    local hr = CFrame.Angles(math.rad(90), 0, 0)
    local tc = (mc * CFrame.new(0, -3, 0)) * hr
    cr.CanCollide = true
    cr.Anchored = true
    cr.CFrame = tc
    task.delay(0.1, function()
        if cr and cr.Parent then
            cr.Anchored = false
        end
    end)
end

local function teleportLoop()
    while isElevatorEnabled do
        local ccr = findCloneRoot()
        if ccr then
            moveCloneToAnchor(ccr)
        else
            isElevatorEnabled = false
            if draggableElevatorButton then
                draggableElevatorButton.Text = "CLONE?"
                draggableElevatorButton.BackgroundColor3 = COLOR_OFF
            end
            if CloneAnchorLoop then
                task.cancel(CloneAnchorLoop)
                CloneAnchorLoop = nil
            end
            updateGodMode()
            break
        end
        task.wait(0.01)
    end
end

local function createCloneAndStartElevator(button)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local quantumCloner = backpack and backpack:FindFirstChild("Quantum Cloner")
    if not quantumCloner then
        if button and button.Parent then
            button.Text = "NO CLONER"
            task.delay(1, function()
                if button.Parent then button.Text = "ELEVATOR" end
            end)
        end
        return
    end

    local humanoid = MyCharacter and MyCharacter:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local equipLoopConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            humanoid:EquipTool(quantumCloner)
        end)
    end)
    -- Activate tool
    if quantumCloner and quantumCloner:IsA("Tool") and quantumCloner.Parent == backpack then
        pcall(function() quantumCloner:Activate() end)
    end
    task.wait(1)
    if equipLoopConnection then
        equipLoopConnection:Disconnect()
    end
    pcall(function() humanoid:UnequipTools() end)

    local cloneRoot = findCloneRoot()
    if cloneRoot then
        isElevatorEnabled = true
        if button then
            button.BackgroundColor3 = COLOR_ON
            button.Text = "ELEVATOR: ON"
        end
        CloneAnchorLoop = task.spawn(teleportLoop)
        updateGodMode()
    else
        if button and button.Parent then
            button.Text = "CLONE FAIL"
            task.delay(1, function()
                if button.Parent then button.Text = "ELEVATOR" end
            end)
        end
    end
end

-- god mode updater
function updateGodMode()
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildWhichIsA("Humanoid")
    if flyActive or infJumpEnabled or flipActive or isElevatorEnabled then
        if h and not godModeConnection then
            godModeConnection = RunService.Heartbeat:Connect(function()
                if h and h.Health and h.Health < 100 then h.Health = 100 end
                if h then h.BreakJointsOnDeath = false end
            end)
        end
    else
        if godModeConnection then
            godModeConnection:Disconnect()
            godModeConnection = nil
        end
    end
end

-- visuals & collision toggles for flip
local function setCharacterVisualState(c, isFlipped)
    if not c then return end
    local h = c:FindFirstChildWhichIsA("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    if not h or not r then return end

    for _, p in ipairs(c:GetChildren()) do
        if p:IsA("BasePart") or p:IsA("Decal") or p:IsA("MeshPart") then
            p.LocalTransparencyModifier = isFlipped and 0.999 or 0
            p.CanCollide = not isFlipped
        elseif p:IsA("Tool") then
            for _, tp in ipairs(p:GetDescendants()) do
                if tp:IsA("BasePart") then
                    tp.LocalTransparencyModifier = isFlipped and 0.999 or 0
                    tp.CanCollide = not isFlipped
                end
            end
        end
    end

    local head = c:FindFirstChild("Head")
    if head then
        local bb = head:FindFirstChildOfClass("BillboardGui")
        if bb then bb.Enabled = not isFlipped end
    end
end

local function setFreezeState(state)
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildWhichIsA("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if not h or not r then return end

    if state then
        globalWalkSpeed = h.WalkSpeed or globalWalkSpeed
        h.WalkSpeed = 0
        r.Anchored = true
        freezeActive = true
        if not freezeConn then
            freezeConn = RunService.Heartbeat:Connect(function()
                if r then
                    r.Velocity = Vector3.new(0, 0, 0)
                    r.RotVelocity = Vector3.new(0, 0, 0)
                end
            end)
        end
    else
        if freezeConn then
            freezeConn:Disconnect()
            freezeConn = nil
        end
        if r then r.Anchored = false end
        h.WalkSpeed = globalWalkSpeed or originalWalkSpeed
        freezeActive = false
    end
end

local function setFlipState(state)
    local c = LocalPlayer.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    local h = c and c:FindFirstChildWhichIsA("Humanoid")
    if not r or not h then return end

    if state then
        local fr = CFrame.Angles(math.pi, 0, 0)
        local tc = r.CFrame * fr
        local bh = 2.8
        local hh = h.HipHeight or 0.5
        local comp = CFrame.new(0, -(bh - 2 * hh), 0)
        r.CFrame = tc * comp
        setCharacterVisualState(c, true)
        setFreezeState(true)
    else
        local _, y, _ = r.CFrame:ToOrientation()
        r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, y, 0)
        setCharacterVisualState(c, false)
        setFreezeState(false)
    end

    flipActive = state
    updateGodMode()
end

-- fly + noclip
local function setFlyNoclip(state)
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildWhichIsA("Humanoid")
    if not h then return end

    if state and not flyNoclipConn then
        originalWalkSpeed = h.WalkSpeed or originalWalkSpeed
        originalJumpHeight = h.JumpHeight or originalJumpHeight
        h.WalkSpeed = 0
        h.JumpHeight = 0

        if cube and cube.Parent then cube:Destroy() end
        cube = Instance.new("Part", Workspace)
        cube.Size = Vector3.new(0.7, 0.7, 0.7)
        cube.Anchored = true
        cube.CanCollide = false
        cube.Transparency = 1
        cube.Material = Enum.Material.Neon
        cube.Name = "FlyNoclipCube"

        if c:FindFirstChild("HumanoidRootPart") then
            cube.CFrame = c.HumanoidRootPart.CFrame
        end

        flyNoclipConn = RunService.RenderStepped:Connect(function()
            if not flyActive then return end
            local cc = LocalPlayer.Character
            if not cc then return end
            local r = cc:FindFirstChild("HumanoidRootPart")
            if not r or not Camera then return end

            local sm = (speedInput and tonumber(speedInput.Text)) or 1
            local BS = 0.05
            local S = sm * BS
            local ST = S / 4
            local fd = Camera.CFrame.LookVector
            local np = cube.Position + fd * ST
            cube.CFrame = CFrame.new(np, np + fd)
            local t = cube.Position + fd * S
            -- Smoothly move root part towards target
            r.CFrame = CFrame.new(r.Position:Lerp(t, 0.2), r.Position + r.CFrame.LookVector)
            r.Velocity = Vector3.new(0, 0, 0)
        end)
    elseif not state and flyNoclipConn then
        h.WalkSpeed = originalWalkSpeed or 16
        h.JumpHeight = originalJumpHeight or 7.2
        flyNoclipConn:Disconnect()
        flyNoclipConn = nil
        if cube and cube.Parent then cube:Destroy() end
        cube = nil
    end
end

-- infinite jump
UserInputService.JumpRequest:Connect(function()
    if not infJumpEnabled then return end
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildWhichIsA("Humanoid")
    if h then
        h:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- UI helpers
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
    local t = infJumpEnabled and "Infinity Jump: ON" or "Infinity Jump"
    if infBtnUniversal then
        infBtnUniversal.Text = t
        updateButtonColor(infBtnUniversal, infJumpEnabled, false)
    end
    if infBtnSAB then
        infBtnSAB.Text = t
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
    local ft = freezeActive and "Freeze: ON" or "Freeze"
    local isO = flipActive
    if freezeBtnUniversal then
        if isO then
            freezeBtnUniversal.Text = "[OVERRIDDEN]"
            updateButtonColor(freezeBtnUniversal, false, true)
        else
            freezeBtnUniversal.Text = ft
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
    if isElevatorEnabled then isElevatorEnabled = false end
    if CloneAnchorLoop then task.cancel(CloneAnchorLoop); CloneAnchorLoop = nil end
    if draggableElevatorButton then
        draggableElevatorButton:Destroy()
        draggableElevatorButton = nil
    end
    updateGodMode()
end

-- Remove any prior mod menu
if PlayerGui:FindFirstChild("ModMenuGui") then
    PlayerGui.ModMenuGui:Destroy()
end

-- GUI creation
local gui = Instance.new("ScreenGui")
gui.Name = "ModMenuGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 99999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local function makeDraggable(trigger, elementToDrag, onClick)
    local dragging = false
    local startPos, startGuiPos, startTick, changedConn

    trigger.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = input.Position
            startGuiPos = elementToDrag.Position
            startTick = tick()
            changedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    changedConn:Disconnect()
                    if tick() - startTick < 0.2 and (startPos - input.Position).Magnitude < 10 and onClick then
                        pcall(onClick)
                    end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startPos
            elementToDrag.Position = UDim2.new(startGuiPos.X.Scale, startGuiPos.X.Offset + delta.X, startGuiPos.Y.Scale, startGuiPos.Y.Offset + delta.Y)
        end
    end)
end

local MW, MH, SW = 320, 420, 70
local CW, CXO = MW - SW, SW

local mainMenu = Instance.new("Frame", gui)
mainMenu.Size = UDim2.new(0, MW, 0, MH)
mainMenu.Position = UDim2.new(0.5, -MW / 2, 0.5, -MH / 2)
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
makeDraggable(icon, icon, function() mainMenu.Visible = not mainMenu.Visible end)

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
contentFrame.Size = UDim2.new(0, CW, 1, -30)
contentFrame.Position = UDim2.new(0, CXO, 0, 30)
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

local function makeBtn(p, t, y)
    local b = Instance.new("TextButton", p)
    b.Size = UDim2.new(1, -20, 0, 50)
    b.Position = UDim2.new(0.5, 0, 0, y)
    b.AnchorPoint = Vector2.new(0.5, 0)
    b.Text = t
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextScaled = true
    b.BackgroundTransparency = 0.08
    b.BorderSizePixel = 0
    b.BackgroundColor3 = COLOR_OFF
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local sidebarFrame = Instance.new("Frame", mainMenu)
sidebarFrame.Size = UDim2.new(0, SW, 1, -30)
sidebarFrame.Position = UDim2.new(0, 0, 0, 30)
sidebarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local function switchSection(sf, b)
    for _, c in ipairs(sidebarFrame:GetChildren()) do
        if c:IsA("TextButton") then
            c.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end
    for _, c in ipairs(contentFrame:GetChildren()) do
        if c:IsA("Frame") then
            c.Visible = false
        end
    end
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sf.Visible = true
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

-- Buttons and controls
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
elevatorBtnSAB = makeBtn(sabScriptsFrame, "ELEVATOR", 130)

-- Button connections
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

-- draggable elevator button creation
local function createDraggableElevatorButton()
    if draggableElevatorButton then return end
    local b = Instance.new("TextButton", gui)
    b.Size = UDim2.new(0, 120, 0, 40)
    b.Position = UDim2.new(0, 100, 0.5, 0)
    b.Text = "ELEVATOR"
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextScaled = true
    b.BackgroundColor3 = COLOR_OFF
    b.BackgroundTransparency = 0.08
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    draggableElevatorButton = b

    local function onButtonClick()
        if isElevatorEnabled then
            isElevatorEnabled = false
            b.BackgroundColor3 = COLOR_OFF
            b.Text = "ELEVATOR"
            if CloneAnchorLoop then
                task.cancel(CloneAnchorLoop)
                CloneAnchorLoop = nil
            end
            updateGodMode()
        else
            local existingClone = findCloneRoot()
            if existingClone then
                isElevatorEnabled = true
                b.BackgroundColor3 = COLOR_ON
                b.Text = "ELEVATOR: ON"
                CloneAnchorLoop = task.spawn(teleportLoop)
                updateGodMode()
            else
                createCloneAndStartElevator(b)
            end
        end
    end

    makeDraggable(b, b, onButtonClick)
end

elevatorBtnSAB.MouseButton1Click:Connect(function()
    if draggableElevatorButton and draggableElevatorButton.Parent then
        if isElevatorEnabled then isElevatorEnabled = false end
        if CloneAnchorLoop then
            task.cancel(CloneAnchorLoop)
            CloneAnchorLoop = nil
        end
        draggableElevatorButton:Destroy()
        draggableElevatorButton = nil
        updateGodMode()
    else
        createDraggableElevatorButton()
    end
end)

-- character reset handling
LocalPlayer.CharacterAdded:Connect(function(char)
    MyCharacter = char
    MyRoot = char:WaitForChild("HumanoidRootPart")
    task.wait(0.5)
    resetUniversalCheats()
end)

-- initialize UI states
updateFlyButton()
updateInfJumpButtons()
updateFreezeButtons()
updateFlipButton()
