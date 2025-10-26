local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MyCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local MyRoot = MyCharacter and MyCharacter:FindFirstChild("HumanoidRootPart")

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = function(self, ...)
 local method = getnamecallmethod()
 if method == "Kick" and self == Players.LocalPlayer then
  return
 end
 return oldNamecall(self, ...)
end

setreadonly(mt, true)

-- Цвета
local COLOR_OFF = Color3.fromRGB(150, 40, 40)
local COLOR_ON = Color3.fromRGB(40, 150, 40)
local COLOR_OVERRIDDEN = Color3.fromRGB(80, 80, 80)

-- Заставка (без изменений)
local splashGui = Instance.new("ScreenGui")
splashGui.Name = "SplashScreen_petrunya_nk"
splashGui.IgnoreGuiInset = true; splashGui.ResetOnSpawn = false; splashGui.ZIndexBehavior = Enum.ZIndexBehavior.Global; splashGui.DisplayOrder = 999999
splashGui.Parent = PlayerGui
local background = Instance.new("Frame", splashGui); background.Size = UDim2.new(1, 0, 1, 0); background.BackgroundColor3 = Color3.fromRGB(0, 0, 45)
local creditText = Instance.new("TextLabel", background); creditText.Size = UDim2.new(1, 0, 0, 100); creditText.Position = UDim2.new(0.5, 0, 0.5, 0); creditText.AnchorPoint = Vector2.new(0.5, 0.5); creditText.BackgroundTransparency = 1; creditText.TextColor3 = Color3.fromRGB(225, 225, 225); creditText.Font = Enum.Font.SourceSansBold; creditText.TextSize = 40; creditText.Text = "тг @petrunya_nk"
task.wait(3); local fadeInfo = TweenInfo.new(1.5); local backgroundFade = TweenService:Create(background, fadeInfo, {BackgroundTransparency = 1}); local textFade = TweenService:Create(creditText, fadeInfo, {TextTransparency = 1}); backgroundFade:Play(); backgroundFade.Completed:Wait(); splashGui:Destroy()

-- Переменные состояния
local flyActive, infJumpEnabled, freezeActive, flipActive, isElevatorEnabled = false, false, false, false, false
local flyNoclipConn, cube, godModeConnection, freezeConn, CloneAnchorLoop = nil, nil, nil, nil, nil
local speedInput
local originalWalkSpeed, originalJumpHeight = 16, 7.2
local globalWalkSpeed = 16
local TARGET_CLONE_ID = "8879553925"

-- Кнопки
local flyBtn, infBtnUniversal, freezeBtnUniversal, infBtnSAB, flipFreezeBtn, elevatorBtnSAB = nil, nil, nil, nil, nil, nil
local draggableElevatorButton = nil -- Новая переменная для подвижной кнопки

-- ==================== ЛОГИКА ELEVATOR ====================
local function findCloneRoot()
 for _, obj in ipairs(Workspace:GetChildren()) do
  if obj:IsA("Model") and obj.Name:find(TARGET_CLONE_ID) then
   if obj ~= MyCharacter then
    local cloneRoot = obj:FindFirstChild("HumanoidRootPart")
    if cloneRoot and cloneRoot:IsA("BasePart") then return cloneRoot end
   end
  end
 end
 return nil
end

local function moveCloneToAnchor(cloneRootPart)
 if not MyRoot or not MyRoot.Parent then return end
 if not cloneRootPart or not cloneRootPart.Parent then return end
 local MyCFrame = MyRoot.CFrame
 local horizontalRotation = CFrame.Angles(math.rad(90), 0, 0) 
 local TargetCFrame = (MyCFrame * CFrame.new(0, -3, 0)) * horizontalRotation
 cloneRootPart.CanCollide = true; cloneRootPart.Anchored = true; cloneRootPart.CFrame = TargetCFrame
 task.delay(0.1, function()
  if cloneRootPart and cloneRootPart.Parent then cloneRootPart.Anchored = false end
 end)
end

local function teleportLoop()
 while isElevatorEnabled do
  local currentCloneRoot = findCloneRoot() 
  if currentCloneRoot then
   moveCloneToAnchor(currentCloneRoot)
  else
   isElevatorEnabled = false
   if draggableElevatorButton then 
    draggableElevatorButton.Text = "CLONE?"; draggableElevatorButton.BackgroundColor3 = COLOR_OFF 
   end
   if CloneAnchorLoop then task.cancel(CloneAnchorLoop); CloneAnchorLoop = nil end
   break 
  end
  task.wait(0.01) 
 end
end
-- =========================================================

local function updateGodMode()
 local char = LocalPlayer.Character
 local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
 if flyActive or infJumpEnabled or flipActive or isElevatorEnabled then
  if humanoid and not godModeConnection then
   godModeConnection = RunService.Heartbeat:Connect(function()
    if humanoid.Health < 100 then humanoid.Health = 100 end
    humanoid.BreakJointsOnDeath = false
   end)
  end
 elseif godModeConnection then
  godModeConnection:Disconnect(); godModeConnection = nil
 end
end

-- Основные функции (setFlyNoclip, setFreezeState и т.д. без изменений)
local function setCharacterVisualState(character, isFlipped)
 local humanoid=character:FindFirstChildWhichIsA("Humanoid");local root=character:FindFirstChild("HumanoidRootPart")
 if not humanoid or not root then return end
 for _,p in ipairs(character:GetChildren()) do if p:IsA("BasePart")or p:IsA("Decal")or p:IsA("MeshPart")then p.LocalTransparencyModifier=isFlipped and 0.999 or 0;p.CanCollide=not isFlipped elseif p:IsA("Tool")then for _,tp in ipairs(p:GetDescendants())do if tp:IsA("BasePart")then tp.LocalTransparencyModifier=isFlipped and 0.999 or 0;tp.CanCollide=not isFlipped end end end end
 local head=character:FindFirstChild("Head")
 if head and head:FindFirstChildOfClass("BillboardGui") then head:FindFirstChildOfClass("BillboardGui").Enabled=not isFlipped end
end
local function setFreezeState(state)
 local char=LocalPlayer.Character;local humanoid=char and char:FindFirstChildWhichIsA("Humanoid");local root=char and char:FindFirstChild("HumanoidRootPart")
 if not humanoid or not root then return end
 if state then globalWalkSpeed=humanoid.WalkSpeed;humanoid.WalkSpeed=0;root.Anchored=true;freezeActive=true;if not freezeConn then freezeConn=RunService.Heartbeat:Connect(function()root.Velocity=Vector3.new(0,0,0);root.RotVelocity=Vector3.new(0,0,0)end)end
 else if freezeConn then freezeConn:Disconnect();freezeConn=nil end;root.Anchored=false;humanoid.WalkSpeed=globalWalkSpeed;freezeActive=false end
end
local function setFlipState(state)
 local char=LocalPlayer.Character;local root=char and char:FindFirstChild("HumanoidRootPart");local humanoid=char and char:FindFirstChildWhichIsA("Humanoid")
 if not root or not humanoid then return end
 if state then local fr=CFrame.Angles(math.pi,0,0);local tc=root.CFrame*fr;local bh=2.8;local hh=humanoid.HipHeight or 0.5;local comp=CFrame.new(0,-(bh-2*hh),0);root.CFrame=tc*comp;setCharacterVisualState(char,true);setFreezeState(true)
 else local _,y,_=root.CFrame:ToOrientation();root.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,y,0);setCharacterVisualState(char,false);setFreezeState(false)end
 flipActive=state;updateGodMode()
end
local function setFlyNoclip(state)
 local char=LocalPlayer.Character;local humanoid=char and char:FindFirstChildWhichIsA("Humanoid")
 if not humanoid then return end
 if state and not flyNoclipConn then originalWalkSpeed=humanoid.WalkSpeed;originalJumpHeight=humanoid.JumpHeight;humanoid.WalkSpeed=0;humanoid.JumpHeight=0;if cube and cube.Parent then cube:Destroy()end;cube=Instance.new("Part",workspace);cube.Size=Vector3.new(0.7,0.7,0.7);cube.Anchored=true;cube.CanCollide=false;cube.Transparency=1;cube.Material=Enum.Material.Neon;cube.Name="FlyNoclipCube";if char:FindFirstChild("HumanoidRootPart")then cube.CFrame=char.HumanoidRootPart.CFrame end;flyNoclipConn=RunService.RenderStepped:Connect(function()if not flyActive then return end;local curChar=LocalPlayer.Character;if not curChar then return end;local root=curChar:FindFirstChild("HumanoidRootPart");if not root or not Camera then return end;local speedMul=(speedInput and tonumber(speedInput.Text))or 1;local BASE_SPEED=0.05;local SPEED=speedMul*BASE_SPEED;local STEP=SPEED/4;local flyDir=Camera.CFrame.LookVector;local nextPos=cube.Position+flyDir*STEP;cube.CFrame=CFrame.new(nextPos,nextPos+flyDir);local target=cube.Position+flyDir*SPEED;root.CFrame=CFrame.new(root.Position:Lerp(target,0.2),root.Position+root.CFrame.LookVector);root.Velocity=Vector3.new(0,0,0)end)
 elseif not state and flyNoclipConn then humanoid.WalkSpeed=originalWalkSpeed;humanoid.JumpHeight=originalJumpHeight;flyNoclipConn:Disconnect();flyNoclipConn=nil;if cube and cube.Parent then cube:Destroy()end end
end
UserInputService.JumpRequest:Connect(function()
 if not infJumpEnabled then return end
 local char=LocalPlayer.Character;local h=char and char:FindFirstChildWhichIsA("Humanoid")
 if h then h:ChangeState(Enum.HumanoidStateType.Jumping)end
end)

-- Обновление кнопок
local function updateButtonColor(btn,state,isOverridden)
 if not btn then return end
 if isOverridden then btn.BackgroundColor3=COLOR_OVERRIDDEN;btn.BackgroundTransparency=0.5;return end
 btn.BackgroundColor3=state and COLOR_ON or COLOR_OFF;btn.BackgroundTransparency=0.08
end
local function updateFlyButton()if flyBtn then flyBtn.Text=flyActive and"Fly + Noclip: ON"or"Fly + Noclip";updateButtonColor(flyBtn,flyActive,false)end;updateGodMode()end
local function updateInfJumpButtons()local t=infJumpEnabled and"Infinity Jump: ON"or"Infinity Jump";if infBtnUniversal then infBtnUniversal.Text=t;updateButtonColor(infBtnUniversal,infJumpEnabled,false)end;if infBtnSAB then infBtnSAB.Text=t;updateButtonColor(infBtnSAB,infJumpEnabled,false)end;updateGodMode()end
local function updateFlipButton()if flipFreezeBtn then flipFreezeBtn.Text=flipActive and"FLIP + FREEZE: ON"or"FLIP + FREEZE";updateButtonColor(flipFreezeBtn,flipActive,false)end end
local function updateFreezeButtons()local ft=freezeActive and"Freeze: ON"or"Freeze";local isO=flipActive;if freezeBtnUniversal then if isO then freezeBtnUniversal.Text="[OVERRIDDEN]";updateButtonColor(freezeBtnUniversal,false,true)else freezeBtnUniversal.Text=ft;updateButtonColor(freezeBtnUniversal,freezeActive,false)end end end
-- Функция сброса
local function resetUniversalCheats()
 if flyActive then setFlyNoclip(false);flyActive=false;updateFlyButton()end
 infJumpEnabled=false;updateInfJumpButtons()
 if flipActive then setFlipState(false)end;updateFlipButton()
 setFreezeState(false);updateFreezeButtons()
 -- Добавлен сброс для ELEVATOR
 if isElevatorEnabled then isElevatorEnabled=false end
 if CloneAnchorLoop then task.cancel(CloneAnchorLoop);CloneAnchorLoop=nil end
 if draggableElevatorButton then draggableElevatorButton:Destroy();draggableElevatorButton=nil end
 updateGodMode()
end

-- Создание GUI
if PlayerGui:FindFirstChild("ModMenuGui") then PlayerGui.ModMenuGui:Destroy() end
local gui=Instance.new("ScreenGui");gui.Name="ModMenuGui";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=99999;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=PlayerGui

local function makeDraggable(trigger,elementToDrag,onClick)
 local dragging,dragStart,startPos,dragStartTime=false,nil,nil,0
 trigger.InputBegan:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
   dragging=true;dragStart=input.Position;startPos=elementToDrag.Position;dragStartTime=tick()
   local conn;conn=input.Changed:Connect(function()
    if input.UserInputState==Enum.UserInputState.End then
     dragging=false;conn:Disconnect()
     if tick()-dragStartTime<0.2 and(dragStart-input.Position).Magnitude<10 and onClick then onClick()end
    end
   end)
  end
 end)
 UserInputService.InputChanged:Connect(function(input)
  if dragging and(input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch)then
   elementToDrag.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+(input.Position-dragStart).X,startPos.Y.Scale,startPos.Y.Offset+(input.Position-dragStart).Y)
  end
 end)
end

local MENU_WIDTH,MENU_HEIGHT,SIDEBAR_WIDTH=320,420,70;local CONTENT_WIDTH,CONTENT_X_OFFSET=MENU_WIDTH-SIDEBAR_WIDTH,SIDEBAR_WIDTH
local mainMenu=Instance.new("Frame",gui);mainMenu.Size=UDim2.new(0,MENU_WIDTH,0,MENU_HEIGHT);mainMenu.Position=UDim2.new(0.5,-MENU_WIDTH/2,0.5,-MENU_HEIGHT/2);mainMenu.BackgroundColor3=Color3.fromRGB(45,45,45);mainMenu.BorderSizePixel=1;mainMenu.BorderColor3=Color3.fromRGB(80,80,80);mainMenu.Visible=false;Instance.new("UICorner",mainMenu).CornerRadius=UDim.new(0,5)
local icon=Instance.new("ImageButton",gui);icon.Size=UDim2.new(0,60,0,60);icon.Position=UDim2.new(0,20,0.5,-30);icon.BackgroundColor3=Color3.fromRGB(200,50,50);icon.BackgroundTransparency=0.1;icon.BorderSizePixel=0;Instance.new("UICorner",icon).CornerRadius=UDim.new(0.5,0);makeDraggable(icon,icon,function()mainMenu.Visible=not mainMenu.Visible end)
local titleBar=Instance.new("Frame",mainMenu);titleBar.Size=UDim2.new(1,0,0,30);titleBar.BackgroundColor3=Color3.fromRGB(35,35,35);titleBar.BorderSizePixel=0;makeDraggable(titleBar,mainMenu)
local titleText=Instance.new("TextLabel",titleBar);titleText.Size=UDim2.new(1,-10,1,0);titleText.Position=UDim2.new(0.5,0,0.5,0);titleText.AnchorPoint=Vector2.new(0.5,0.5);titleText.BackgroundTransparency=1;titleText.Font=Enum.Font.SourceSansBold;titleText.TextColor3=Color3.new(1,1,1);titleText.Text="Mod Menu"
local contentFrame=Instance.new("Frame",mainMenu);contentFrame.Size=UDim2.new(0,CONTENT_WIDTH,1,-30);contentFrame.Position=UDim2.new(0,CONTENT_X_OFFSET,0,30);contentFrame.BackgroundColor3=Color3.fromRGB(45,45,45);contentFrame.ClipsDescendants=true
local universalScriptsFrame=Instance.new("Frame",contentFrame);universalScriptsFrame.Size=UDim2.new(1,0,1,0);universalScriptsFrame.BackgroundTransparency=1;universalScriptsFrame.Visible=true
local sabScriptsFrame=Instance.new("Frame",contentFrame);sabScriptsFrame.Size=UDim2.new(1,0,1,0);sabScriptsFrame.BackgroundTransparency=1;sabScriptsFrame.Visible=false

local function makeBtn(parent,text,yPos)
 local btn=Instance.new("TextButton",parent);btn.Size=UDim2.new(1,-20,0,50);btn.Position=UDim2.new(0.5,0,0,yPos);btn.AnchorPoint=Vector2.new(0.5,0);btn.Text=text;btn.TextColor3=Color3.new(1,1,1);btn.TextScaled=true;btn.BackgroundTransparency=0.08;btn.BorderSizePixel=0;btn.BackgroundColor3=COLOR_OFF;Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
 return btn
end

local sidebarFrame=Instance.new("Frame",mainMenu);sidebarFrame.Size=UDim2.new(0,SIDEBAR_WIDTH,1,-30);sidebarFrame.Position=UDim2.new(0,0,0,30);sidebarFrame.BackgroundColor3=Color3.fromRGB(30,30,30)
local function switchSection(sectionFrame,button)
 for _,c in ipairs(sidebarFrame:GetChildren())do if c:IsA("TextButton")then c.BackgroundColor3=Color3.fromRGB(30,30,30)end end
 for _,c in ipairs(contentFrame:GetChildren())do if c:IsA("Frame")then c.Visible=false end end
 button.BackgroundColor3=Color3.fromRGB(50,50,50);sectionFrame.Visible=true
end
local universalSectionBtn=Instance.new("TextButton",sidebarFrame);universalSectionBtn.Size=UDim2.new(1,0,0,50);universalSectionBtn.Position=UDim2.new(0,0,0,0);universalSectionBtn.Text="Universal";universalSectionBtn.TextSize=12;universalSectionBtn.TextColor3=Color3.new(1,1,1);universalSectionBtn.BorderSizePixel=0;universalSectionBtn.BackgroundColor3=Color3.fromRGB(50,50,50)
local sabSectionBtn=Instance.new("TextButton",sidebarFrame);sabSectionBtn.Size=UDim2.new(1,0,0,50);sabSectionBtn.Position=UDim2.new(0,0,0,50);sabSectionBtn.BackgroundColor3=Color3.fromRGB(30,30,30);sabSectionBtn.Text="SAB";sabSectionBtn.TextSize=12;sabSectionBtn.TextColor3=Color3.new(1,1,1);sabSectionBtn.BorderSizePixel=0
universalSectionBtn.MouseButton1Click:Connect(function()switchSection(universalScriptsFrame,universalSectionBtn)end)
sabSectionBtn.MouseButton1Click:Connect(function()switchSection(sabScriptsFrame,sabSectionBtn)end)

-- Universal Buttons
flyBtn=makeBtn(universalScriptsFrame,"Fly + Noclip",10)
local speedInputContainer=Instance.new("Frame",universalScriptsFrame);speedInputContainer.Size=UDim2.new(1,-20,0,40);speedInputContainer.Position=UDim2.new(0.5,0,0,70);speedInputContainer.AnchorPoint=Vector2.new(0.5,0);speedInputContainer.BackgroundTransparency=1
local speedLabel=Instance.new("TextLabel",speedInputContainer);speedLabel.Size=UDim2.new(0.4,0,1,0);speedLabel.BackgroundTransparency=1;speedLabel.Font=Enum.Font.SourceSansSemibold;speedLabel.TextColor3=Color3.new(1,1,1);speedLabel.TextSize=16;speedLabel.Text="Speed:";speedLabel.TextXAlignment=Enum.TextXAlignment.Right
speedInput=Instance.new("TextBox",speedInputContainer);speedInput.Size=UDim2.new(0.6,0,1,0);speedInput.Position=UDim2.new(0.4,0,0,0);speedInput.BackgroundColor3=Color3.fromRGB(20,20,20);speedInput.BackgroundTransparency=0.5;speedInput.TextColor3=Color3.new(1,1,1);speedInput.Font=Enum.Font.SourceSansBold;speedInput.TextSize=18;speedInput.Text="1";speedInput.ClearTextOnFocus=false;Instance.new("UICorner",speedInput).CornerRadius=UDim.new(0,4)
infBtnUniversal=makeBtn(universalScriptsFrame,"Infinity Jump",130)
freezeBtnUniversal=makeBtn(universalScriptsFrame,"Freeze",190)

-- SAB Buttons
infBtnSAB=makeBtn(sabScriptsFrame,"Infinity Jump",10)
flipFreezeBtn=makeBtn(sabScriptsFrame,"FLIP + FREEZE",70)
elevatorBtnSAB=makeBtn(sabScriptsFrame,"ELEVATOR",130)

-- Подключения кнопок (кроме ELEVATOR)
flyBtn.MouseButton1Click:Connect(function()flyActive=not flyActive;setFlyNoclip(flyActive);updateFlyButton()end)
local function infJumpClicked()infJumpEnabled=not infJumpEnabled;updateInfJumpButtons()end
infBtnUniversal.MouseButton1Click:Connect(infJumpClicked);infBtnSAB.MouseButton1Click:Connect(infJumpClicked)
freezeBtnUniversal.MouseButton1Click:Connect(function()if flipActive then return end;setFreezeState(not freezeActive);updateFreezeButtons()end)
flipFreezeBtn.MouseButton1Click:Connect(function()if flipActive then setFlipState(false)else setFlipState(true)end;updateFlipButton();updateFreezeButtons()end)

-- ==================== НОВАЯ ЛОГИКА КНОПКИ ELEVATOR ====================
local function createDraggableElevatorButton()
 if draggableElevatorButton then return end -- Не создавать, если уже есть

 local button = Instance.new("TextButton", gui)
 button.Size = UDim2.new(0, 120, 0, 40)
 button.Position = UDim2.new(0, 100, 0.5, 0) -- Начальная позиция
 button.Text = "ELEVATOR"
 button.TextColor3 = Color3.new(1, 1, 1)
 button.TextScaled = true
 button.BackgroundColor3 = COLOR_OFF
 button.BackgroundTransparency = 0.08
 Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

 draggableElevatorButton = button

 local function onButtonClick()
  isElevatorEnabled = not isElevatorEnabled
  if isElevatorEnabled then
   local cloneRoot = findCloneRoot()
   if cloneRoot then
    button.BackgroundColor3 = COLOR_ON
    button.Text = "ELEVATOR: ON"
    CloneAnchorLoop = task.spawn(teleportLoop)
   else
    isElevatorEnabled = false
    button.Text = "CLONE?"
    task.delay(1, function() if button.Parent then button.Text = "ELEVATOR" end end)
   end
  else
   button.BackgroundColor3 = COLOR_OFF
   button.Text = "ELEVATOR"
   if CloneAnchorLoop then task.cancel(CloneAnchorLoop); CloneAnchorLoop = nil end
  end
  updateGodMode()
 end

 makeDraggable(button, button, onButtonClick)
end

elevatorBtnSAB.MouseButton1Click:Connect(function()
 if draggableElevatorButton and draggableElevatorButton.Parent then
  if isElevatorEnabled then isElevatorEnabled = false; updateGodMode() end
  if CloneAnchorLoop then task.cancel(CloneAnchorLoop); CloneAnchorLoop = nil end
  draggableElevatorButton:Destroy()
  draggableElevatorButton = nil
 else
  createDraggableElevatorButton()
 end
end)

-- Сброс при смерти
LocalPlayer.CharacterAdded:Connect(function(char)
 MyCharacter=char;MyRoot=char:WaitForChild("HumanoidRootPart")
 task.wait(0.5)
 resetUniversalCheats()
end)

-- Инициализация
updateFlyButton();updateInfJumpButtons();updateFreezeButtons();updateFlipButton()
