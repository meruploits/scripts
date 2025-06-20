-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configs
local aimbotBind = Enum.KeyCode.F
local aimbotActive = false
local currentTarget = nil
local aimbotFOV = 60
local maxDistance = 300
local showFOV = false
local espEnabled = false
local waitingForBind = false
local boxes = {}
local guiOpen = true

local aimPartOptions = {"Head", "Torso"}
local aimPartSelected = "Head"

-- Drawing API
local Drawing = Drawing or getgenv().Drawing or getdrawing or nil
local FOVCircle = Drawing and Drawing.new("Circle") or nil
if FOVCircle then
	FOVCircle.Transparency = 1
	FOVCircle.Thickness = 2
	FOVCircle.NumSides = 100
	FOVCircle.Filled = false
	FOVCircle.Color = Color3.fromRGB(255, 255, 0)
end

-- GUI Setup
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "EvoMenu_GUI"
gui.ResetOnSpawn = false
gui.Enabled = true

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 340, 0, 360)
frame.Position = UDim2.new(0.5, -150, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderColor3 = Color3.fromRGB(70, 70, 70)
frame.BorderSizePixel = 2
frame.Active = true
frame.Draggable = true

local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0, 8)
local frameStroke = Instance.new("UIStroke", frame)
frameStroke.Thickness = 2
frameStroke.Color = Color3.fromRGB(70, 70, 70)
frameStroke.Transparency = 0.3

TweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Position = UDim2.new(0.5, -150, 0.5, -160)
}):Play()

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "EvoMenu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 26
title.TextXAlignment = Enum.TextXAlignment.Center
title.TextYAlignment = Enum.TextYAlignment.Center

local function createButton(name, posY, text)
	local btn = Instance.new("TextButton", frame)
	btn.Name = name
	btn.Size = UDim2.new(1, -20, 0, 30)
	btn.Position = UDim2.new(0, 10, 0, posY)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	btn.TextColor3 = Color3.fromRGB(230, 230, 230)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 18
	btn.Text = text
	btn.AutoButtonColor = true

	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(90, 90, 90)
	stroke.Transparency = 0.4
	stroke.Thickness = 1

	return btn
end

local function createLabel(name, posY, text)
	local lbl = Instance.new("TextLabel", frame)
	lbl.Name = name
	lbl.Size = UDim2.new(1, -20, 0, 22)
	lbl.Position = UDim2.new(0, 10, 0, posY)
	lbl.Text = text
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 16
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	return lbl
end

local espBtn = createButton("ESPButton", 50, "ESP: OFF")
local bindLbl = createLabel("BindLabel", 90, "Aimbot Bind: LeftShift")
local bindBtn = createButton("BindChangeBtn", 115, "Change Aimbot Bind")

local fovInput = Instance.new("TextBox", frame)
fovInput.Size = UDim2.new(1, -20, 0, 28)
fovInput.Position = UDim2.new(0, 10, 0, 150)
fovInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
fovInput.TextColor3 = Color3.fromRGB(230, 230, 230)
fovInput.Font = Enum.Font.Gotham
fovInput.TextSize = 16
fovInput.TextXAlignment = Enum.TextXAlignment.Left
fovInput.ClearTextOnFocus = false
fovInput.Text = "Aimbot FOV: " .. aimbotFOV

local fovPlus = createButton("FOVPlus", 185, "+ FOV")
local fovMinus = createButton("FOVMinus", 220, "- FOV")
local toggleFOVCircle = createButton("ToggleFOV", 255, "Show FOV Circle: OFF")
local aimPartLabel = createLabel("AimPartLabel", 290, "Aim Part: Head")
local aimPartBtn = createButton("AimPartBtn", 315, "Change Aim Part")

local function updateBindLabel()
	bindLbl.Text = "Aimbot Bind: " .. (aimbotBind.Name or tostring(aimbotBind))
end
updateBindLabel()

fovInput.FocusLost:Connect(function(enter)
	if enter then
		local text = fovInput.Text:gsub("[^%d]", "")
		local num = tonumber(text)
		if num and num >= 5 and num <= 180 then
			aimbotFOV = math.floor(num)
		end
		fovInput.Text = "Aimbot FOV: " .. aimbotFOV
	end
end)

fovPlus.MouseButton1Click:Connect(function()
	if aimbotFOV < 180 then
		aimbotFOV += 5
		fovInput.Text = "Aimbot FOV: " .. aimbotFOV
	end
end)

fovMinus.MouseButton1Click:Connect(function()
	if aimbotFOV > 5 then
		aimbotFOV -= 5
		fovInput.Text = "Aimbot FOV: " .. aimbotFOV
	end
end)

toggleFOVCircle.MouseButton1Click:Connect(function()
	showFOV = not showFOV
	toggleFOVCircle.Text = "Show FOV Circle: " .. (showFOV and "ON" or "OFF")
end)

bindBtn.MouseButton1Click:Connect(function()
	if waitingForBind then return end
	waitingForBind = true
	bindBtn.Text = "Press any key..."
end)

aimPartBtn.MouseButton1Click:Connect(function()
	local currentIndex = table.find(aimPartOptions, aimPartSelected)
	currentIndex = (currentIndex % #aimPartOptions) + 1
	aimPartSelected = aimPartOptions[currentIndex]
	aimPartLabel.Text = "Aim Part: " .. aimPartSelected
end)

local function isTargetValid(p)
	if not p.Character then return false end
	local head = p.Character:FindFirstChild("Head")
	local humanoid = p.Character:FindFirstChild("Humanoid")
	if not head or not humanoid then return false end
	if humanoid.Health <= 0 then return false end
	if p.Team == LocalPlayer.Team then return false end

	local camPos = Camera.CFrame.Position
	local dir = (head.Position - camPos).Unit
	local angle = math.deg(math.acos(Camera.CFrame.LookVector:Dot(dir)))
	local dist = (head.Position - camPos).Magnitude

	return angle <= aimbotFOV and dist <= maxDistance
end

local function getClosestPlayer()
	local camPos = Camera.CFrame.Position
	local lookVec = Camera.CFrame.LookVector
	local closest, smallestAngle = nil, math.huge
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and isTargetValid(p) then
			local dir = (p.Character.Head.Position - camPos).Unit
			local angle = math.deg(math.acos(lookVec:Dot(dir)))
			if angle < smallestAngle then
				closest = p
				smallestAngle = angle
			end
		end
	end
	return closest
end

local function getAimPosition(character)
	if aimPartSelected == "Head" then
		return character:FindFirstChild("Head") and character.Head.Position
	elseif aimPartSelected == "Torso" then
		return character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position
	end
	return nil
end

UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if waitingForBind then
		waitingForBind = false
		aimbotBind = input.KeyCode
		updateBindLabel()
		bindBtn.Text = "Change Aimbot Bind"
		return
	end

	if input.KeyCode == Enum.KeyCode.U then
		guiOpen = not guiOpen
		gui.Enabled = guiOpen
	end

	if input.KeyCode == aimbotBind then
		aimbotActive = true
		if not currentTarget or not isTargetValid(currentTarget) then
			currentTarget = getClosestPlayer()
		end
		coroutine.wrap(function()
			while aimbotActive do
				if currentTarget and isTargetValid(currentTarget) then
					local aimPos = getAimPosition(currentTarget.Character)
					if aimPos then
						Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPos)
					end
				else
					currentTarget = nil
				end
				RunService.RenderStepped:Wait()
			end
		end)()
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == aimbotBind then
		aimbotActive = false
		currentTarget = nil
	end
end)

-- ESP functions

local function createBoxForPlayer(p)
	if boxes[p] then return end
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local box = Instance.new("BoxHandleAdornment")
	box.Adornee = root
	box.Size = Vector3.new(4, 6, 2)
	box.AlwaysOnTop = true
	box.ZIndex = 10
	box.Transparency = 0.25
	box.Parent = game.CoreGui
	boxes[p] = box
	return box
end

local function updateBoxColor(p)
	if boxes[p] then
		-- Corrigido para mostrar vermelho para inimigos, verde para aliados
		if p.Team == LocalPlayer.Team then
			boxes[p].Color3 = Color3.fromRGB(0, 255, 0) -- Verde para aliados
		else
			boxes[p].Color3 = Color3.fromRGB(255, 0, 0) -- Vermelho para inimigos
		end
	end
end

local function removeBox(p)
	if boxes[p] then
		boxes[p]:Destroy()
		boxes[p] = nil
	end
end

local function espToggle(state)
	espEnabled = state
	if not espEnabled then
		for p in pairs(boxes) do removeBox(p) end
		return
	end

	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			-- Criar box para todos exceto local player
			createBoxForPlayer(p)
			updateBoxColor(p)
		end
	end
end

espBtn.MouseButton1Click:Connect(function()
	espToggle(not espEnabled)
	espBtn.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
end)

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.5)
		if espEnabled then
			createBoxForPlayer(p)
			updateBoxColor(p)
		end
	end)
	p:GetPropertyChangedSignal("Team"):Connect(function()
		updateBoxColor(p)
	end)
end)

Players.PlayerRemoving:Connect(removeBox)

RunService.RenderStepped:Connect(function()
	if FOVCircle and showFOV then
		local mousePos = UIS:GetMouseLocation()
		FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
		FOVCircle.Radius = math.clamp(aimbotFOV * 2, 30, 500)
		FOVCircle.Visible = true
	elseif FOVCircle then
		FOVCircle.Visible = false
	end
end)
