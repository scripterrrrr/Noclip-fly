-- НАЧАЛО: Код для заставки (Splash Screen)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local splashGui = Instance.new("ScreenGui")
splashGui.Name = "SplashScreen_petrunya_nk"
splashGui.IgnoreGuiInset = true
splashGui.ResetOnSpawn = false
splashGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
splashGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 45)
background.BorderSizePixel = 0
background.Parent = splashGui

local creditText = Instance.new("TextLabel")
creditText.Size = UDim2.new(1, 0, 0, 100)
creditText.Position = UDim2.new(0.5, 0, 0.5, 0)
creditText.AnchorPoint = Vector2.new(0.5, 0.5)
creditText.BackgroundTransparency = 1
creditText.TextColor3 = Color3.fromRGB(225, 225, 225)
creditText.Font = Enum.Font.SourceSansBold
creditText.TextSize = 40
creditText.Text = "made by @petrunya_nk"
creditText.Parent = background

task.wait(3)

local fadeInfo = TweenInfo.new(1.5)
local backgroundFade = TweenService:Create(background, fadeInfo, {BackgroundTransparency = 1})
local textFade = TweenService:Create(creditText, fadeInfo, {TextTransparency = 1})

backgroundFade:Play()
textFade:Play()

backgroundFade.Completed:Wait()
splashGui:Destroy()
-- КОНЕЦ: Код для заставки

-- ОСНОВНОЙ СКРИПТ
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local SPEED = 0.02 
local STEP = 0.005 
local CUBE_SIZE = Vector3.new(1,1,1) * 0.7

local active = false
local flyNoclipConn = nil
local cube = nil

local function rainbow(obj)
 RunService.RenderStepped:Connect(function()
 if obj and obj.Parent then
 local t = tick()*2
 obj.BackgroundColor3 = Color3.fromHSV((t%6)/6,1,1)
 end
 end)
end

local function setFlyNoclip(state)
 if state and not flyNoclipConn then
 if cube and cube.Parent then cube:Destroy() end
 local char = LocalPlayer.Character
 cube = Instance.new("Part")
 cube.Size = CUBE_SIZE
 cube.Anchored = true
 cube.CanCollide = false
 cube.Transparency = 0.5
 cube.BrickColor = BrickColor.new("Institutional white")
 cube.Material = Enum.Material.Neon
 cube.Name = "FlyNoclipCube"
 if char and char:FindFirstChild("HumanoidRootPart") then
 cube.CFrame = char.HumanoidRootPart.CFrame
 end
 cube.Parent = workspace
 flyNoclipConn = RunService.RenderStepped:Connect(function()
 local char = LocalPlayer.Character
 if not active or not char or not char:FindFirstChild("HumanoidRootPart") then return end
 local root = char.HumanoidRootPart
 local bodyForward = root.CFrame.LookVector
 local flyDir = Camera.CFrame.LookVector
 local nextPos = cube.Position + flyDir * STEP
 cube.CFrame = CFrame.new(nextPos, nextPos + flyDir)
 local target = cube.Position + flyDir * SPEED
 root.CFrame = CFrame.new(
 root.Position:Lerp(target, 0.2),
 root.Position + bodyForward
 )
 root.Velocity = Vector3.new(0,0,0)
 end)
 elseif not state and flyNoclipConn then
 flyNoclipConn:Disconnect()
 flyNoclipConn = nil
 if cube and cube.Parent then cube:Destroy() end
 local char = LocalPlayer.Character
 if char and char:FindFirstChildOfClass("Humanoid") then
 char:FindFirstChildOfClass("Humanoid").PlatformStand = false
 end
 end
end

-- GUI
pcall(function() LocalPlayer.PlayerGui:FindFirstChild("FlyNoclipGui"):Destroy() end)
local gui = Instance.new("ScreenGui")
gui.Name = "FlyNoclipGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainContainer = Instance.new("Frame")
mainContainer.Size = UDim2.new(0, 160, 0, 100)
mainContainer.Position = UDim2.new(1, -180, 0.5, -50)
mainContainer.BackgroundTransparency = 1
mainContainer.Parent = gui

local btn = Instance.new("TextButton")
btn.Name = "FlyNoclipBtn"
btn.Size = UDim2.new(1, 0, 0, 54)
btn.Position = UDim2.new(0, 0, 0, 0)
btn.Text = "Fly+Noclip"
btn.TextColor3 = Color3.new(1,1,1)
btn.TextScaled = true
btn.BackgroundTransparency = 0.08
btn.BorderSizePixel = 0
btn.ZIndex = 11
btn.Parent = mainContainer
rainbow(btn)

btn.MouseButton1Click:Connect(function()
 active = not active
 btn.Text = active and "Fly+Noclip: ON" or "Fly+Noclip"
 setFlyNoclip(active)
end)

-- НОВОЕ: Редактируемое поле для скорости
local speedInputContainer = Instance.new("Frame")
speedInputContainer.Size = UDim2.new(1, 0, 0, 40)
speedInputContainer.Position = UDim2.new(0, 0, 1, -40)
speedInputContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
speedInputContainer.BackgroundTransparency = 0.2
speedInputContainer.BorderSizePixel = 0
speedInputContainer.Parent = mainContainer

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.4, 0, 1, 0) -- Метка "Speed:" слева
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.SourceSansSemibold
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.TextSize = 16
speedLabel.Text = "Speed:"
speedLabel.TextXAlignment = Enum.TextXAlignment.Right
speedLabel.Parent = speedInputContainer

local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(0.6, 0, 1, 0) -- Поле для ввода справа
speedInput.Position = UDim2.new(0.4, 0, 0, 0)
speedInput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
speedInput.BackgroundTransparency = 0.5
speedInput.TextColor3 = Color3.new(1, 1, 1)
speedInput.Font = Enum.Font.SourceSansBold
speedInput.TextSize = 18
speedInput.Text = "50" -- Начальное значение
speedInput.ClearTextOnFocus = false
speedInput.Parent = speedInputContainer

-- Функция обновления скорости из текстового поля
local function updateSpeedFromInput()
 local value = tonumber(speedInput.Text)
 if value then -- Проверяем, что введено число
 SPEED = value / 2500 
 STEP = SPEED / 4
 end
end

-- Обновляем скорость, когда игрок закончил редактирование
speedInput.FocusLost:Connect(updateSpeedFromInput)

-- Устанавливаем начальную скорость
updateSpeedFromInput()
