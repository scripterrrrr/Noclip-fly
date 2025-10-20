-- =================================================================
-- Мод-меню v1.5 (Исправлен интерфейс)
-- Создано на основе скрипта от @petrunya_nk
-- =================================================================

-- Службы Roblox
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Локальные переменные
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Заставка (Splash Screen)
local splashGui = Instance.new("ScreenGui")
splashGui.Name = "SplashScreen_petrunya_nk"
splashGui.IgnoreGuiInset = true; splashGui.ResetOnSpawn = false
splashGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
splashGui.Parent = PlayerGui

local background = Instance.new("Frame", splashGui)
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 45)
background.BorderSizePixel = 0

local creditText = Instance.new("TextLabel", background)
creditText.Size = UDim2.new(1, 0, 0, 100); creditText.Position = UDim2.new(0.5, 0, 0.5, 0)
creditText.AnchorPoint = Vector2.new(0.5, 0.5); creditText.BackgroundTransparency = 1
creditText.TextColor3 = Color3.fromRGB(225, 225, 225); creditText.Font = Enum.Font.SourceSansBold
creditText.TextSize = 40; creditText.Text = "made by @petrunya_nk"

task.wait(3)

local fadeInfo = TweenInfo.new(1.5)
local backgroundFade = TweenService:Create(background, fadeInfo, {BackgroundTransparency = 1})
local textFade = TweenService:Create(creditText, fadeInfo, {TextTransparency = 1})
backgroundFade:Play(); textFade:Play()
backgroundFade.Completed:Wait()
splashGui:Destroy()

-- ================== ЛОГИКА ПОЛЕТА ==================
local SPEED = 0.02
local STEP = 0.005
local CUBE_SIZE = Vector3.new(1,1,1) * 0.7
local active = false
local flyNoclipConn = nil
local cube = nil

local function setFlyNoclip(state)
 if state and not flyNoclipConn then
 if cube and cube.Parent then cube:Destroy() end
 local char = LocalPlayer.Character
 cube = Instance.new("Part", workspace)
 cube.Size = CUBE_SIZE; cube.Anchored = true; cube.CanCollide = false
 cube.Transparency = 0.5; cube.Material = Enum.Material.Neon
 cube.Name = "FlyNoclipCube"
 if char and char:FindFirstChild("HumanoidRootPart") then
 cube.CFrame = char.HumanoidRootPart.CFrame
 end
 flyNoclipConn = RunService.RenderStepped:Connect(function()
 local char = LocalPlayer.Character
 if not active or not char or not char:FindFirstChild("HumanoidRootPart") then return end
 local root = char.HumanoidRootPart
 local flyDir = Camera.CFrame.LookVector
 local nextPos = cube.Position + flyDir * STEP
 cube.CFrame = CFrame.new(nextPos, nextPos + flyDir)
 local target = cube.Position + flyDir * SPEED
 root.CFrame = CFrame.new(root.Position:Lerp(target, 0.2), root.Position + root.CFrame.LookVector)
 root.Velocity = Vector3.new(0,0,0)
 end)
 elseif not state and flyNoclipConn then
 flyNoclipConn:Disconnect(); flyNoclipConn = nil
 if cube and cube.Parent then cube:Destroy() end
 end
end

-- ================== МОД-МЕНЮ GUI ==================
if PlayerGui:FindFirstChild("ModMenuGui") then PlayerGui.ModMenuGui:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "ModMenuGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = PlayerGui

local function makeDraggable(trigger, elementToDrag, onClick)
 local dragging = false; local dragStart, startPos; local dragStartTime = 0
 trigger.InputBegan:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
 dragging = true; dragStart = input.Position; startPos = elementToDrag.Position; dragStartTime = tick()
 local conn; conn = input.Changed:Connect(function()
 if input.UserInputState == Enum.UserInputState.End then
  dragging = false; conn:Disconnect()
  if tick() - dragStartTime < 0.2 and (dragStart - input.Position).Magnitude < 10 and onClick then onClick() end
 end
 end)
 end
 end)
 UserInputService.InputChanged:Connect(function(input)
 if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
 local delta = input.Position - dragStart
 elementToDrag.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
 end
 end)
end

-- 1. Создание перетаскиваемой иконки
local icon = Instance.new("ImageButton", gui)
icon.Name = "MenuIcon"; icon.Size = UDim2.new(0, 60, 0, 60)
icon.Position = UDim2.new(0, 20, 0.5, -30); icon.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
icon.BackgroundTransparency = 0.1; icon.BorderSizePixel = 0
Instance.new("UICorner", icon).CornerRadius = UDim.new(0.5, 0)

-- 2. Создание основного окна меню
local mainMenu = Instance.new("Frame", gui)
mainMenu.Name = "MainMenu"; mainMenu.Visible = false
-- ИСПРАВЛЕНИЕ: Увеличена высота окна
mainMenu.Size = UDim2.new(0, 250, 0, 170) 
mainMenu.Position = UDim2.new(0.5, -125, 0.5, -85)
mainMenu.BackgroundColor3 = Color3.fromRGB(45, 45, 45); mainMenu.BorderSizePixel = 1
mainMenu.BorderColor3 = Color3.fromRGB(80, 80, 80)
Instance.new("UICorner", mainMenu).CornerRadius = UDim.new(0, 5)

local titleBar = Instance.new("Frame", mainMenu)
titleBar.Size = UDim2.new(1, 0, 0, 30); titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleBar.BorderSizePixel = 0
makeDraggable(titleBar, mainMenu) -- Окно можно таскать за заголовок

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, -10, 1, 0); titleText.Position = UDim2.new(0.5, 0, 0.5, 0)
titleText.AnchorPoint = Vector2.new(0.5, 0.5); titleText.BackgroundTransparency = 1
titleText.Font = Enum.Font.SourceSansBold; titleText.TextColor3 = Color3.new(1,1,1)
titleText.Text = "Menu by @petrunya_nk"

-- 3. Добавление элементов в меню
local btn = Instance.new("TextButton", mainMenu)
btn.Name = "FlyNoclipBtn"; btn.Size = UDim2.new(1, -20, 0, 50)
btn.Position = UDim2.new(0.5, 0, 0, 40); btn.AnchorPoint = Vector2.new(0.5, 0)
btn.Text = "Fly+Noclip"; btn.TextColor3 = Color3.new(1,1,1); btn.TextScaled = true
btn.BackgroundTransparency = 0.08; btn.BorderSizePixel = 0; btn.ZIndex = 11

local function rainbow(obj)
 RunService.RenderStepped:Connect(function()
 if obj and obj.Parent then obj.BackgroundColor3 = Color3.fromHSV((tick()*2%6)/6,1,1) end
 end)
end
rainbow(btn)

local speedInputContainer = Instance.new("Frame", mainMenu)
speedInputContainer.Size = UDim2.new(1, -20, 0, 40)
-- ИСПРАВЛЕНИЕ: Подвинул контейнер скорости ниже
speedInputContainer.Position = UDim2.new(0.5, 0, 0, 105) 
speedInputContainer.AnchorPoint = Vector2.new(0.5, 0)
speedInputContainer.BackgroundTransparency = 1

local speedLabel = Instance.new("TextLabel", speedInputContainer)
speedLabel.Size = UDim2.new(0.4, 0, 1, 0); speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.SourceSansSemibold; speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.TextSize = 16; speedLabel.Text = "Speed:"; speedLabel.TextXAlignment = Enum.TextXAlignment.Right

local speedInput = Instance.new("TextBox", speedInputContainer)
speedInput.Size = UDim2.new(0.6, 0, 1, 0); speedInput.Position = UDim2.new(0.4, 0, 0, 0)
speedInput.BackgroundColor3 = Color3.fromRGB(20, 20, 20); speedInput.BackgroundTransparency = 0.5
speedInput.TextColor3 = Color3.new(1, 1, 1); speedInput.Font = Enum.Font.SourceSansBold
speedInput.TextSize = 18; speedInput.Text = "50"; speedInput.ClearTextOnFocus = false

-- ================== ЛОГИКА ВЗАИМОДЕЙСТВИЯ ==================

btn.MouseButton1Click:Connect(function()
 active = not active
 btn.Text = active and "Fly+Noclip: ON" or "Fly+Noclip"
 setFlyNoclip(active)
end)

local function updateSpeedFromInput()
 local value = tonumber(speedInput.Text)
 if value then SPEED = value / 2500; STEP = SPEED / 4 end
end
speedInput.FocusLost:Connect(updateSpeedFromInput)
updateSpeedFromInput()

makeDraggable(icon, icon, function()
 mainMenu.Visible = not mainMenu.Visible
end)
