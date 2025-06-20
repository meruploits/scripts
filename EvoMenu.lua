-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Configs
local aimbotBind = Enum.KeyCode.F
local currentTarget = nil
local aimbotFOV = 60
local maxDistance = 300
local showFOV = false
local espEnabled = false
local waitingForBind = false
local guiOpen = true
local blockMouseMovement = false

local aimPartOptions = {"Head", "Torso"}
local aimPartSelected = "Head"

local spawnIgnoreStart = 100 -- distância vertical a partir da qual ignora inimigos abaixo do player

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

-- GUI
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
local bindLbl = createLabel("BindLabel", 90, "Aimbot Bind: F")
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

-- Helper: verifica se tem linha de visão entre o jogador local e o alvo
local function hasLineOfSight(targetPart)
	if not targetPart then return false end
	local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not localRoot then return false end

	local origin = localRoot.Position
	local direction = (targetPart.Position - origin).Unit * maxDistance

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local raycastResult = Workspace:Raycast(origin, direction, raycastParams)
	if raycastResult then
		local hitPart = raycastResult.Instance
		if hitPart:IsDescendantOf(targetPart.Parent) then
			return true
		else
			return false
		end
	else
		return true
	end
end

-- Aimbot Helpers
local function isTargetValid(p)
	if not p.Character then return false end
	local head = p.Character:FindFirstChild("Head")
	local humanoid = p.Character:FindFirstChild("Humanoid")
	if not head or not humanoid then return false end
	if humanoid.Health <= 0 then return false end
	if p.Team == LocalPlayer.Team then return false end

	local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
	if localRoot and targetRoot then
		local verticalDiff = localRoot.Position.Y - targetRoot.Position.Y
		if verticalDiff > spawnIgnoreStart then
			return false -- ignora se estiver mais de 100 studs abaixo do player
		end
	end

	local camPos = Camera.CFrame.Position
	local dir = (head.Position - camPos).Unit
	local angle = math.deg(math.acos(Camera.CFrame.LookVector:Dot(dir)))
	local dist = (head.Position - camPos).Magnitude

	if angle > aimbotFOV or dist > maxDistance then
		return false
	end

	return true
end

local function getAimPart(p)
	return aimPartSelected == "Head" and p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
end

local function getScreenDistToMouse(p)
	local part = getAimPart(p)
	if not part then return math.huge end
	local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
	if not visible then return math.huge end
	local mouse = UIS:GetMouseLocation()
	return (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
end

local function getClosestToMouse()
	local mouse = UIS:GetMouseLocation()
	local visibleTargets = {}
	local invisibleTargets = {}

	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and isTargetValid(p) then
			local aimPart = getAimPart(p)
			if aimPart then
				if hasLineOfSight(aimPart) then
					table.insert(visibleTargets, p)
				else
					table.insert(invisibleTargets, p)
				end
			end
		end
	end

	local function sortByScreenDist(a, b)
		return getScreenDistToMouse(a) < getScreenDistToMouse(b)
	end

	table.sort(visibleTargets, sortByScreenDist)
	table.sort(invisibleTargets, sortByScreenDist)

	if #visibleTargets > 0 then
		return visibleTargets[1]
	elseif #invisibleTargets > 0 then
		return invisibleTargets[1]
	else
		return nil
	end
end

local function getAimPosition(character)
	local part = aimPartSelected == "Head" and character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	return part and part.Position or nil
end

-- Input para bloquear movimento do mouse enquanto aimbot ativo
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement and blockMouseMovement then
		input:CaptureController()
	end
end)

-- Aimbot core
RunService.RenderStepped:Connect(function()
	if UIS:IsKeyDown(aimbotBind) then
		blockMouseMovement = true

		local currentTargetValid = currentTarget and isTargetValid(currentTarget)
		local currentTargetDist = currentTargetValid and getScreenDistToMouse(currentTarget) or math.huge
		local margin = 15 -- margem para troca de alvo em pixels

		if not currentTargetValid or currentTargetDist > aimbotFOV * 2 or currentTargetDist > margin then
			local newTarget = getClosestToMouse()
			if newTarget then
				local newDist = getScreenDistToMouse(newTarget)
				if newDist + margin < currentTargetDist then
					currentTarget = newTarget
				end
			else
				currentTarget = nil
			end
		end

		if currentTarget and isTargetValid(currentTarget) then
			local aimPos = getAimPosition(currentTarget.Character)
			if aimPos then
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPos)
			end
		else
			currentTarget = nil
		end
	else
		blockMouseMovement = false
		currentTarget = nil
	end
end)

-- FOV circle
RunService.RenderStepped:Connect(function()
	if FOVCircle and showFOV then
		local mouse = UIS:GetMouseLocation()
		FOVCircle.Position = Vector2.new(mouse.X, mouse.Y)
		FOVCircle.Radius = math.clamp(aimbotFOV * 2, 30, 500)
		FOVCircle.Visible = true
	elseif FOVCircle then
		FOVCircle.Visible = false
	end
end)

-- 2D ESP System
local espBoxes = {}

local function remove2DBox(player)
	if espBoxes[player] then
		espBoxes[player]:Remove()
		espBoxes[player] = nil
	end
end

local function create2DBox(player)
	remove2DBox(player)

	local box = Drawing.new("Square")
	box.Thickness = 2
	box.Transparency = 1
	box.Color = Color3.fromRGB(255, 0, 0)
	box.Filled = false
	box.Visible = false

	espBoxes[player] = box
end

local function updateESPPlayers()
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local shouldShow = espEnabled and p.Team ~= LocalPlayer.Team
			if shouldShow and not espBoxes[p] then
				create2DBox(p)
			elseif not shouldShow and espBoxes[p] then
				remove2DBox(p)
			end
		end
	end
end

RunService.RenderStepped:Connect(function()
	if not espEnabled then
		for _, box in pairs(espBoxes) do
			box.Visible = false
		end
		return
	end

	for p, box in pairs(espBoxes) do
		local char = p.Character
		if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
			local hrp = char.HumanoidRootPart
			local head = char.Head
			local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
			local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
			local footPos, footOnScreen = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

			if onScreen and headOnScreen and footOnScreen then
				local height = math.abs(headPos.Y - footPos.Y)
				local width = height / 1.5
				box.Size = Vector2.new(width, height)
				box.Position = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)
				box.Visible = true
			else
				box.Visible = false
			end
		else
			box.Visible = false
		end
	end
end)

espBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	espBtn.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
	updateESPPlayers()
end)

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.5)
		updateESPPlayers()
	end)
end)

Players.PlayerRemoving:Connect(function(p)
	remove2DBox(p)
end)

RunService.Heartbeat:Connect(function()
	updateESPPlayers()
end)

fovInput.FocusLost:Connect(function(enter)
	if enter then
		local num = tonumber(fovInput.Text:match("%d+"))
		if num and num >= 5 and num <= 180 then
			aimbotFOV = num
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
end)
