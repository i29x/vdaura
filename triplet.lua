local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local SurvivorColor = Color3.fromRGB(0, 255, 70)
local KillerColor = Color3.fromRGB(255, 35, 35)
local GeneratorColor = Color3.fromRGB(255, 220, 0)
local VaultPalletColor = Color3.fromRGB(255, 0, 0)

local playerConnections = {}
local generatorHighlights = {}
local vaultPalletHighlights = {}

local function getPlayerColor(player)
	local teamName = player.Team and string.lower(player.Team.Name) or ""

	if string.find(teamName, "killer") or string.find(teamName, "murderer") or string.find(teamName, "hunter") then
		return KillerColor
	end

	if string.find(teamName, "survivor") or string.find(teamName, "innocent") or string.find(teamName, "civilian") then
		return SurvivorColor
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

local function getAdornee(object)
	if object:IsA("Model") or object:IsA("BasePart") then
		return object
	end

	return object:FindFirstAncestorOfClass("Model")
end

local function isGenerator(object)
	local name = string.lower(object.Name)

	return name == "generator"
		or name == "generators"
		or string.find(name, "generator") ~= nil
		or object:GetAttribute("Generator") == true
		or object:GetAttribute("IsGenerator") == true
end

local function isVaultOrPallet(object)
	local name = string.lower(object.Name)

	return name == "vault"
		or name == "vaults"
		or name == "vualt"
		or name == "vualts"
		or name == "pallet"
		or name == "pallets"
		or string.find(name, "vault") ~= nil
		or string.find(name, "vaults") ~= nil
		or string.find(name, "vualt") ~= nil
		or string.find(name, "vualts") ~= nil
		or string.find(name, "pallet") ~= nil
		or string.find(name, "pallets") ~= nil
		or object:GetAttribute("Vault") == true
		or object:GetAttribute("Vaults") == true
		or object:GetAttribute("Vualt") == true
		or object:GetAttribute("Vualts") == true
		or object:GetAttribute("IsVault") == true
		or object:GetAttribute("IsVualt") == true
		or object:GetAttribute("Pallet") == true
		or object:GetAttribute("Pallets") == true
		or object:GetAttribute("IsPallet") == true
end

local function addHighlight(object, storage, highlightName, color, checkFunction)
	if storage[object] or not checkFunction(object) then
		return
	end

	local adornee = getAdornee(object)
	if not adornee then
		return
	end

	local existing = adornee:FindFirstChild(highlightName)
	if existing then
		storage[object] = existing
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = highlightName
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.35
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = adornee
	highlight.Parent = adornee

	storage[object] = highlight
end

local function scanObject(object)
	addHighlight(object, generatorHighlights, "GeneratorHighlight", GeneratorColor, isGenerator)
	addHighlight(object, vaultPalletHighlights, "VaultPalletHighlight", VaultPalletColor, isVaultOrPallet)
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
	scanObject(object)
end

workspace.DescendantAdded:Connect(function(object)
	task.wait()
	scanObject(object)
end)

workspace.DescendantRemoving:Connect(function(object)
	generatorHighlights[object] = nil
	vaultPalletHighlights[object] = nil
end)

