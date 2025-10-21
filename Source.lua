-- =================================================================
-- Мод-меню v2.1 (Блокировка ходьбы при полёте)
-- Создано на основе скрипта от @petrunya_nk
-- =================================================================

-- Службы Roblox
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")

-- Локальные переменные
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Camera = workspace.CurrentCamera

-- Заставка (без изменений)
-- ... (код заставки скрыт для краткости)
local splashGui = Instance.new("ScreenGui"); splashGui.Name = "SplashScreen_petrunya_nk"; splashGui.IgnoreGuiInset = true; splashGui.ResetOnSpawn = false; splashGui.ZIndexBehavior = Enum.ZIndexBehavior.Global; splashGui.DisplayOrder = 999999; splashGui.Parent = CoreGui; local background = Instance.new("Frame", splashGui); background.Size = UDim2.new(1, 0, 1, 0); background.BackgroundColor3 = Color3.fromRGB(0, 0, 45); local creditText = Instance.new("TextLabel", background); creditText.Size = UDim2.new(1, 0, 0, 100); creditText.Position = UDim2.new(0.5, 0, 0.5, 0); creditText.AnchorPoint = Vector2.new(0.5, 0.5); creditText.BackgroundTransparency = 1; creditText.TextColor3 = Color3.fromRGB(225, 225, 225); creditText.Font = Enum.Font.SourceSansBold; creditText.TextSize = 40; creditText.Text = "made by @petrunya_nk"; task.wait(3); local fadeInfo = TweenInfo.new(1.5); local backgroundFade = TweenService:Create(background, fadeInfo, {BackgroundTransparency = 1}); local textFade = TweenService:Create(creditText, fadeInfo, {TextTransparency = 1}); backgroundFade:Play(); textFade:Play(); backgroundFade.Completed:Wait(); splashGui:Destroy()

-- ================== ЛОГИКА ФУНКЦИЙ ==================
local flyActive = false; local flyNoclipConn = nil; local cube = nil
local infJumpEnabled = false
local speedInput 
-- ИЗМЕНЕНИЕ 1: Переменные для хранения оригинальной скорости и прыжка
local originalWalkSpeed = 16
local originalJumpHeight = 7.2 -- Стандартная высота прыжка в Roblox

local function setFlyNoclip(state)
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end -- Если персонажа нет, выходим

    local SPEED = tonumber(speedInput.Text)/2500 or 0.02
    local STEP = SPEED/4

    if state and not flyNoclipConn then -- ВКЛЮЧАЕМ ФЛАЙ
        -- ИЗМЕНЕНИЕ 2: Сохраняем текущие значения и обнуляем их
        originalWalkSpeed = humanoid.WalkSpeed
        originalJumpHeight = humanoid.JumpHeight
        humanoid.WalkSpeed = 0
        humanoid.JumpHeight = 0

        if cube and cube.Parent then cube:Destroy() end
        cube = Instance.new("Part", workspace); cube.Size = Vector3.new(1,1,1) * 0.7; cube.Anchored = true; cube.CanCollide = false
        cube.Transparency = 0.5; cube.Material = Enum.Material.Neon; cube.Name = "FlyNoclipCube"
        if char and char:FindFirstChild("HumanoidRootPart") then cube.CFrame = char.HumanoidRootPart.CFrame end

        flyNoclipConn = RunService.RenderStepped:Connect(function()
            local current_char = LocalPlayer.Character
            if not flyActive or not current_char or not current_char:FindFirstChild("HumanoidRootPart") then return end
            local root = current_char.HumanoidRootPart; local flyDir = Camera.CFrame.LookVector
            local nextPos = cube.Position + flyDir * STEP
            cube.CFrame = CFrame.new(nextPos, nextPos + flyDir)
            local target = cube.Position + flyDir * SPEED
            root.CFrame = CFrame.new(root.Position:Lerp(target, 0.2), root.Position + root.CFrame.LookVector)
            root.Velocity = Vector3.new(0,0,0)
        end)
    elseif not state and flyNoclipConn then -- ВЫКЛЮЧАЕМ ФЛАЙ
        -- ИЗМЕНЕНИЕ 3: Возвращаем сохраненные значения
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpHeight = originalJumpHeight

        flyNoclipConn:Disconnect(); flyNoclipConn = nil
        if cube and cube.Parent then cube:Destroy() end
    end
end
-- ... (Логика Infinite Jump без изменений)
UserInputService.JumpRequest:Connect(function() if not infJumpEnabled then return end; local char = LocalPlayer.Character; local hum = char and char:FindFirstChildWhichIsA("Humanoid"); local root = char and char:FindFirstChild("HumanoidRootPart"); if hum and root and hum:GetState() == Enum.HumanoidStateType.Freefall then local plat = Instance.new("Part", workspace); plat.Size = Vector3.new(3, 0.1, 3); plat.Position = root.Position - Vector3.new(0, 4, 0); plat.Anchored = true; plat.CanCollide = true; plat.Transparency = 1; plat.Name = "BypassPlatform"; hum:ChangeState(Enum.HumanoidStateType.Jumping); Debris:AddItem(plat, 0.1) end end)

-- ================== МОД-МЕНЮ GUI (без изменений) ==================
if CoreGui:FindFirstChild("ModMenuGui") then CoreGui.ModMenuGui:Destroy() end
local gui = Instance.new("ScreenGui"); gui.Name = "ModMenuGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 99999; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = CoreGui
local function makeDraggable(trigger, elementToDrag, onClick) local dragging = false; local dragStart, startPos; local dragStartTime = 0; trigger.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = elementToDrag.Position; dragStartTime = tick(); local conn; conn = input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false; conn:Disconnect(); if tick() - dragStartTime < 0.2 and (dragStart - input.Position).Magnitude < 10 and onClick then onClick() end end end) end end); UserInputService.InputChanged:Connect(function(input) if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then elementToDrag.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (input.Position - dragStart).X, startPos.Y.Scale, startPos.Y.Offset + (input.Position - dragStart).Y) end end) end
local mainMenu = Instance.new("Frame", gui); mainMenu.Name = "MainMenu"; mainMenu.Visible = false; mainMenu.Size = UDim2.new(0, 250, 0, 230); mainMenu.Position = UDim2.new(0.5, -125, 0.5, -115); mainMenu.BackgroundColor3 = Color3.fromRGB(45, 45, 45); mainMenu.BorderSizePixel = 1; mainMenu.BorderColor3 = Color3.fromRGB(80, 80, 80); mainMenu.ZIndex = 1; Instance.new("UICorner", mainMenu).CornerRadius = UDim.new(0, 5)
local icon = Instance.new("ImageButton", gui); icon.Name = "MenuIcon"; icon.Size = UDim2.new(0, 60, 0, 60); icon.Position = UDim2.new(0, 20, 0.5, -30); icon.BackgroundColor3 = Color3.fromRGB(200, 50, 50); icon.BackgroundTransparency = 0.1; icon.BorderSizePixel = 0; icon.ZIndex = 2; Instance.new("UICorner", icon).CornerRadius = UDim.new(0.5, 0)
local titleBar = Instance.new("Frame", mainMenu); titleBar.Size = UDim2.new(1, 0, 0, 30); titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35); titleBar.BorderSizePixel = 0; makeDraggable(titleBar, mainMenu)
local titleText = Instance.new("TextLabel", titleBar); titleText.Size = UDim2.new(1, -10, 1, 0); titleText.Position = UDim2.new(0.5, 0, 0.5, 0); titleText.AnchorPoint = Vector2.new(0.5, 0.5); titleText.BackgroundTransparency = 1; titleText.Font = Enum.Font.SourceSansBold; titleText.TextColor3 = Color3.new(1,1,1); titleText.Text = "Menu by @petrunya_nk"
local flyBtn = Instance.new("TextButton", mainMenu); flyBtn.Name = "FlyNoclipBtn"; flyBtn.Size = UDim2.new(1, -20, 0, 50); flyBtn.Position = UDim2.new(0.5, 0, 0, 40); flyBtn.AnchorPoint = Vector2.new(0.5, 0); flyBtn.Text = "Fly+Noclip"; flyBtn.TextColor3 = Color3.new(1,1,1); flyBtn.TextScaled = true; flyBtn.BackgroundTransparency = 0.08; flyBtn.BorderSizePixel = 0; Instance.new("UICorner", flyBtn).CornerRadius = UDim.new(0, 6)
local speedInputContainer = Instance.new("Frame", mainMenu); speedInputContainer.Size = UDim2.new(1, -20, 0, 40); speedInputContainer.Position = UDim2.new(0.5, 0, 0, 100); speedInputContainer.AnchorPoint = Vector2.new(0.5, 0); speedInputContainer.BackgroundTransparency = 1
local speedLabel = Instance.new("TextLabel", speedInputContainer); speedLabel.Size = UDim2.new(0.4, 0, 1, 0); speedLabel.BackgroundTransparency = 1; speedLabel.Font = Enum.Font.SourceSansSemibold; speedLabel.TextColor3 = Color3.new(1, 1, 1); speedLabel.TextSize = 16; speedLabel.Text = "Speed:"; speedLabel.TextXAlignment = Enum.TextXAlignment.Right
speedInput = Instance.new("TextBox", speedInputContainer); speedInput.Size = UDim2.new(0.6, 0, 1, 0); speedInput.Position = UDim2.new(0.4, 0, 0, 0); speedInput.BackgroundColor3 = Color3.fromRGB(20, 20, 20); speedInput.BackgroundTransparency = 0.5; speedInput.TextColor3 = Color3.new(1, 1, 1); speedInput.Font = Enum.Font.SourceSansBold; speedInput.TextSize = 18; speedInput.Text = "50"; speedInput.ClearTextOnFocus = false; Instance.new("UICorner", speedInput).CornerRadius = UDim.new(0, 4)
local infBtn = Instance.new("TextButton", mainMenu); infBtn.Name = "InfinityJumpBtn"; infBtn.Size = UDim2.new(1, -20, 0, 50); infBtn.Position = UDim2.new(0.5, 0, 0, 165); infBtn.AnchorPoint = Vector2.new(0.5, 0); infBtn.Text = "Infinity Jump"; infBtn.TextColor3 = Color3.new(1,1,1); infBtn.TextScaled = true; infBtn.BackgroundTransparency = 0.08; infBtn.BorderSizePixel = 0; Instance.new("UICorner", infBtn).CornerRadius = UDim.new(0, 6)
local function startRainbow(obj) RunService.RenderStepped:Connect(function() if obj and obj.Parent then obj.BackgroundColor3 = Color3.fromHSV((tick() * 0.18) % 1, 0.9, 1) end end) end
startRainbow(flyBtn); startRainbow(infBtn)

-- ================== ЛОГИКА ВЗАИМОДЕЙСТВИЯ (без изменений) ==================
flyBtn.MouseButton1Click:Connect(function() flyActive = not flyActive; flyBtn.Text = flyActive and "Fly+Noclip: ON" or "Fly+Noclip"; setFlyNoclip(flyActive) end)
infBtn.MouseButton1Click:Connect(function() infJumpEnabled = not infJumpEnabled; infBtn.Text = infJumpEnabled and "Infinity Jump: ON" or "Infinity Jump" end)
makeDraggable(icon, icon, function() mainMenu.Visible = not mainMenu.Visible end)
