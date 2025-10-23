local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

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
creditText.Text = "made by @petrunya_nk"

task.wait(3)
local fadeInfo = TweenInfo.new(1.5)
local backgroundFade = TweenService:Create(background, fadeInfo, {BackgroundTransparency = 1})
local textFade = TweenService:Create(creditText, fadeInfo, {TextTransparency = 1})
backgroundFade:Play()
textFade:Play()
backgroundFade.Completed:Wait()
splashGui:Destroy()

local flyActive = false
local infJumpEnabled = false
local freezeActive = false
local flyNoclipConn, cube, godModeConnection = nil, nil, nil
local speedInput
local originalWalkSpeed = 16
local originalJumpHeight = 7.2

local function updateGodMode()
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
	if flyActive or infJumpEnabled then
		if humanoid and not godModeConnection then
			godModeConnection = RunService.Heartbeat:Connect(function()
				if humanoid.Health < humanoid.MaxHealth then
					humanoid.Health = humanoid.MaxHealth
				end
			end)
		end
	else
		if godModeConnection then
			godModeConnection:Disconnect()
			godModeConnection = nil
		end
	end
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
			local current_char = LocalPlayer.Character
			if not current_char then return end
			local root = current_char:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local speedMultiplier = (speedInput and tonumber(speedInput.Text)) or 1
			local BASE_SPEED = 0.05
			local SPEED = speedMultiplier * BASE_SPEED
			local STEP = SPEED / 4
			local flyDir = Camera.CFrame.LookVector
			local nextPos = cube.Position + flyDir * STEP
			cube.CFrame = CFrame.new(nextPos, nextPos + flyDir)
			local target = cube.Position + flyDir * SPEED
			root.CFrame = CFrame.new(root.Position:Lerp(target, 0.2), root.Position + root.CFrame.LookVector)
			root.Velocity = Vector3.zero
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
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

if PlayerGui:FindFirstChild("ModMenuGui") then
	PlayerGui.ModMenuGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ModMenuGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 99999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local function makeDraggable(trigger, elementToDrag, onClick)
	local dragging = false
	local dragStart, startPos, dragStartTime
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
					if tick() - dragStartTime < 0.2 and (dragStart - input.Position).Magnitude < 10 and onClick then
						onClick()
					end
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
			elementToDrag.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (input.Position - dragStart).X, startPos.Y.Scale, startPos.Y.Offset + (input.Position - dragStart).Y)
		end
	end)
end

local mainMenu = Instance.new("Frame", gui)
mainMenu.Size = UDim2.new(0, 250, 0, 290)
mainMenu.Position = UDim2.new(0.5, -125, 0.5, -145)
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

local function makeBtn(text, yPos)
	local btn = Instance.new("TextButton", mainMenu)
	btn.Size = UDim2.new(1, -20, 0, 50)
	btn.Position = UDim2.new(0.5, 0, 0, yPos)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextScaled = true
	btn.BackgroundTransparency = 0.08
	btn.BorderSizePixel = 0
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	return btn
end

local flyBtn = makeBtn("Fly + Noclip", 40)
local speedInputContainer = Instance.new("Frame", mainMenu)
speedInputContainer.Size = UDim2.new(1, -20, 0, 40)
speedInputContainer.Position = UDim2.new(0.5, 0, 0, 100)
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

local infBtn = makeBtn("Infinity Jump", 160)
local freezeBtn = makeBtn("Freeze", 220)

local function startRainbow(obj)
	RunService.RenderStepped:Connect(function()
		if obj and obj.Parent then
			obj.BackgroundColor3 = Color3.fromHSV((tick() * 0.18) % 1, 0.9, 1)
		end
	end)
end

startRainbow(flyBtn)
startRainbow(infBtn)
startRainbow(freezeBtn)

flyBtn.MouseButton1Click:Connect(function()
	flyActive = not flyActive
	flyBtn.Text = flyActive and "Fly + Noclip: ON" or "Fly + Noclip"
	setFlyNoclip(flyActive)
	updateGodMode()
end)

infBtn.MouseButton1Click:Connect(function()
	infJumpEnabled = not infJumpEnabled
	infBtn.Text = infJumpEnabled and "Infinity Jump: ON" or "Infinity Jump"
	updateGodMode()
end)

freezeBtn.MouseButton1Click:Connect(function()
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local root = char.HumanoidRootPart
	freezeActive = not freezeActive
	root.Anchored = freezeActive
	freezeBtn.Text = freezeActive and "Freeze: ON" or "Freeze"
end)

makeDraggable(icon, icon, function()
	mainMenu.Visible = not mainMenu.Visible
end)

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	updateGodMode()
end)
