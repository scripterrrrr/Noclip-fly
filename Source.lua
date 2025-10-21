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
-- Увеличена высота окна, чтобы вместить элементы
mainMenu.Size = UDim2.new(0, 250, 0, 230)
mainMenu.Position = UDim2.new(0.5, -125, 0.5, -115)
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
local flyBtn = Instance.new("TextButton", mainMenu)
flyBtn.Name = "FlyNoclipBtn"; flyBtn.Size = UDim2.new(1, -20, 0, 50)
flyBtn.Position = UDim2.new(0.5, 0, 0, 40); flyBtn.AnchorPoint = Vector2.new(0.5, 0)
flyBtn.Text = "Fly+Noclip"; flyBtn.TextColor3 = Color3.new(1,1,1); flyBtn.TextScaled = true
flyBtn.BackgroundTransparency = 0.08; flyBtn.BorderSizePixel = 0; flyBtn.ZIndex = 11
Instance.new("UICorner", flyBtn).CornerRadius = UDim.new(0, 6)

-- Infinity Jump Button
local infBtn = Instance.new("TextButton", mainMenu)
infBtn.Name = "InfinityJumpBtn"; infBtn.Size = UDim2.new(1, -20, 0, 50)
-- ПЕРЕМЕСТИЛ: ставим кнопку Infinity Jump туда, где раньше был контейнер скорости (ниже)
infBtn.Position = UDim2.new(0.5, 0, 0, 165); infBtn.AnchorPoint = Vector2.new(0.5, 0)
infBtn.Text = "Infinity Jump"; infBtn.TextColor3 = Color3.new(1,1,1); infBtn.TextScaled = true
infBtn.BackgroundTransparency = 0.08; infBtn.BorderSizePixel = 0; infBtn.ZIndex = 11
Instance.new("UICorner", infBtn).CornerRadius = UDim.new(0, 6)

-- Функция для запуска радужного эффекта и возврата коннекта (чтобы можно было при желании отключить)
local function startRainbow(obj)
 local conn
 conn = RunService.RenderStepped:Connect(function()
  if not obj or not obj.Parent then
   if conn then conn:Disconnect() end
   return
  end
  -- Используем более плавное изменение оттенка
  local hue = (tick() * 0.18) % 1
  obj.BackgroundColor3 = Color3.fromHSV(hue, 0.9, 1)
 end)
 return conn
end

-- Запускаем радужный эффект на обеих кнопках (fly и infinity)
local flyRainbowConn = startRainbow(flyBtn)
local infRainbowConn = startRainbow(infBtn)

-- Контейнер скорости (ПЕРЕМЕЩЁН: теперь занимает позицию, где была кнопка Infinity Jump)
local speedInputContainer = Instance.new("Frame", mainMenu)
speedInputContainer.Size = UDim2.new(1, -20, 0, 40)
speedInputContainer.Position = UDim2.new(0.5, 0, 0, 100) -- раньше 165, теперь 100 (место инф кнопки)
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
Instance.new("UICorner", speedInput).CornerRadius = UDim.new(0, 4)

-- ================== ЛОГИКА ВЗАИМОДЕЙСТВИЯ ==================

flyBtn.MouseButton1Click:Connect(function()
 active = not active
 flyBtn.Text = active and "Fly+Noclip: ON" or "Fly+Noclip"
 setFlyNoclip(active)
end)

-- Infinity Jump логика
local infJumpEnabled = false

-- Подключаемся к событию JumpRequest. Когда infJumpEnabled = true, Humanoid будет заставлен прыгать при любой попытке прыжка.
UserInputService.JumpRequest:Connect(function()
 if not infJumpEnabled then return end
 local char = LocalPlayer.Character
 local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
 if humanoid then
  humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
 end
end)

infBtn.MouseButton1Click:Connect(function()
 infJumpEnabled = not infJumpEnabled
 if infJumpEnabled then
  infBtn.Text = "Infinity Jump: ON"
  -- ТЕКСТ ВСЕГДА БЕЛЫЙ: оставляем цвет текста белым и не меняем его
  infBtn.TextColor3 = Color3.new(1, 1, 1)
 else
  infBtn.Text = "Infinity Jump"
  infBtn.TextColor3 = Color3.new(1, 1, 1)
 end
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

-- Дополнительно: скрываем интерфейс при смерти/респавне и привязываем к новому персонажу (чтобы бесконечный прыжок работал корректно после респа)
LocalPlayer.CharacterAdded:Connect(function(char)
 -- небольшая задержка, чтобы humanoid создался
 task.wait(0.2)
 cube = nil
end)
