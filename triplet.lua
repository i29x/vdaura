local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local SurvivorColor = Color3.fromRGB(0, 255, 70)
local KillerColor = Color3.fromRGB(255, 35, 35)
local GeneratorColor = Color3.fromRGB(255, 220, 0)

local playerConnections = {}
local generatorHighlights = {}

local function getPlayerColor(player)
	local teamName = player.Team and string.lower(player.Team.Name) or ""

	if string.find(teamName, "killer") or string.find(teamName, "murderer") or string.find(teamName, "hunter") then
		return KillerColor
	end

	if string.find(teamName, "survivor") or string.find(teamName, "innocent") or string.find(teamName, "civilian") then
		return SurvivorColor
	end

	if player.TeamColor then
		return player.TeamColor.Color
	end

	return SurvivorColor
end

local function removePlayerVisuals(player)
	local character = player.Character
	if not character then
		return
	end

	local highlight = character:FindFirstChild("TeamHighlight")
	if highlight then
		highlight:Destroy()
	end

	local head = character:FindFirstChild("Head")
	if head then
		local nameGui = head:FindFirstChild("PlayerNameGui")
		if nameGui then
			nameGui:Destroy()
		end
	end
end

local function addPlayerVisuals(player)
	if player == LocalPlayer then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	removePlayerVisuals(player)

	local color = getPlayerColor(player)

	local highlight = Instance.new("Highlight")
	highlight.Name = "TeamHighlight"
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.45
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = character
	highlight.Parent = character

	local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 5)
	if not head then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlayerNameGui"
	billboard.Adornee = head
	billboard.Size = UDim2.fromOffset(220, 40)
	billboard.StudsOffset = Vector3.new(0, 2.7, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 1000
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = player.DisplayName .. " (@" .. player.Name .. ")"
	label.TextColor3 = color
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard
end

local function setupPlayer(player)
	if playerConnections[player] then
		for _, connection in ipairs(playerConnections[player]) do
			connection:Disconnect()
		end
	end

	playerConnections[player] = {}

	table.insert(playerConnections[player], player.CharacterAdded:Connect(function()
		task.wait(1)
		addPlayerVisuals(player)
	end))

	table.insert(playerConnections[player], player:GetPropertyChangedSignal("Team"):Connect(function()
		addPlayerVisuals(player)
	end))

	table.insert(playerConnections[player], player:GetPropertyChangedSignal("TeamColor"):Connect(function()
		addPlayerVisuals(player)
	end))

	if player.Character then
		task.spawn(function()
			task.wait(1)
			addPlayerVisuals(player)
		end)
	end
end

local function isGenerator(object)
	local name = string.lower(object.Name)

	return name == "generator"
		or name == "generators"
		or string.find(name, "generator")
		or object:GetAttribute("Generator") == true
		or object:GetAttribute("IsGenerator") == true
end

local function getGeneratorAdornee(object)
	if object:IsA("Model") or object:IsA("BasePart") then
		return object
	end

	return object:FindFirstAncestorOfClass("Model")
end

local function addGeneratorHighlight(object)
	if generatorHighlights[object] or not isGenerator(object) then
		return
	end

	local adornee = getGeneratorAdornee(object)
	if not adornee then
		return
	end

	local existing = adornee:FindFirstChild("GeneratorHighlight")
	if existing then
		generatorHighlights[object] = existing
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "GeneratorHighlight"
	highlight.FillColor = GeneratorColor
	highlight.OutlineColor = GeneratorColor
	highlight.FillTransparency = 0.35
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = adornee
	highlight.Parent = adornee

	generatorHighlights[object] = highlight
end

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	if playerConnections[player] then
		for _, connection in ipairs(playerConnections[player]) do
			connection:Disconnect()
		end

		playerConnections[player] = nil
	end
end)

for _, object in ipairs(workspace:GetDescendants()) do
	addGeneratorHighlight(object)
end

workspace.DescendantAdded:Connect(function(object)
	task.wait()
	addGeneratorHighlight(object)
end)

workspace.DescendantRemoving:Connect(function(object)
	generatorHighlights[object] = nil
end)
