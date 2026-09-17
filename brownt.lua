local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TARGET_USERNAME = "6oxiii"
local CHECK_INTERVAL = 5

if _G.CleanStalkerVisualCleanup then
	pcall(_G.CleanStalkerVisualCleanup)
end

local skins = ReplicatedStorage
	:WaitForChild("Killers")
	:WaitForChild("Hidden")
	:WaitForChild("Skins")

local stalker = skins
	:WaitForChild("Halloween_l4d2stalker")

local stalkerModel = stalker
	:WaitForChild("Model")

local sourcePants = stalker
	:WaitForChild("Legs")
	:FindFirstChildOfClass("Pants")

if not sourcePants then
	sourcePants = stalkerModel:FindFirstChildOfClass("Pants")
end

local hairFolder = stalker
	:WaitForChild("Head")
	:WaitForChild("Hair")

local sourceHood = hairFolder:FindFirstChild("VampireHoodBlack")
	or stalkerModel:FindFirstChild("VampireHoodBlack")

local sourceEyes = hairFolder:FindFirstChild("Accessory (Type0Eyes)")
	or stalkerModel:FindFirstChild("Accessory (Type0Eyes)")

if not sourcePants then
	warn("STALKER PANTS NOT FOUND")
	return
end

if not sourceHood then
	warn("STALKER HOOD NOT FOUND")
	return
end

if not sourceEyes then
	warn("STALKER EYES NOT FOUND")
	return
end

local STALKER_PANTS = sourcePants.PantsTemplate

local playerConnections = {}
local characterConnections = {}

local character = nil
local head = nil
local appliedPlayer = nil
local running = true

local added = {}
local hiddenParts = {}
local hiddenVisuals = {}
local originalPants = {}

local BODY_NAMES = {
	Head = true,
	Torso = true,
	UpperTorso = true,
	LowerTorso = true,
	HumanoidRootPart = true,
	["Right Arm"] = true,
	["Left Arm"] = true,
	["Right Leg"] = true,
	["Left Leg"] = true,
	RightUpperArm = true,
	RightLowerArm = true,
	RightHand = true,
	LeftUpperArm = true,
	LeftLowerArm = true,
	LeftHand = true,
	RightUpperLeg = true,
	RightLowerLeg = true,
	RightFoot = true,
	LeftUpperLeg = true,
	LeftLowerLeg = true,
	LeftFoot = true
}

local function contains(a, b)
	return string.find(
		string.lower(a),
		string.lower(b),
		1,
		true
	) ~= nil
end

local function isKiller(player)
	if not player or not player.Team then
		return false
	end

	return string.lower(player.Team.Name) == "killer"
end

local function weaponName(name)
	return contains(name, "weapon")
		or contains(name, "katana")
		or contains(name, "sword")
		or contains(name, "blade")
		or contains(name, "knife")
		or contains(name, "dagger")
		or contains(name, "melee")
		or contains(name, "stake")
		or contains(name, "axe")
		or contains(name, "scythe")
		or contains(name, "machete")
		or contains(name, "cleaver")
end

local function isOurs(obj)
	local current = obj

	while current and current ~= character do
		if current:GetAttribute("CleanStalkerVisual") == true then
			return true
		end

		current = current.Parent
	end

	return false
end

local function mark(obj)
	obj:SetAttribute("CleanStalkerVisual", true)

	table.insert(
		added,
		obj
	)

	return obj
end

local function isWeapon(obj)
	if not obj then
		return false
	end

	if obj:IsA("Tool") then
		return true
	end

	if obj:FindFirstAncestorOfClass("Tool") then
		return true
	end

	local current = obj

	while current and current ~= character do
		if weaponName(current.Name) then
			return true
		end

		current = current.Parent
	end

	return false
end

local function bodyPart(obj)
	return obj
		and obj:IsA("BasePart")
		and obj.Parent == character
		and BODY_NAMES[obj.Name] == true
end

local function rememberPart(part)
	if not part
	or not part:IsA("BasePart")
	or isOurs(part)
	or isWeapon(part)
	or bodyPart(part) then
		return
	end

	for _, data in ipairs(hiddenParts) do
		if data.object == part then
			part.LocalTransparencyModifier = 1
			return
		end
	end

	table.insert(hiddenParts, {
		object = part,
		value = part.LocalTransparencyModifier
	})

	part.LocalTransparencyModifier = 1
end

local function rememberVisual(obj)
	if not obj
	or not obj.Parent
	or isOurs(obj)
	or isWeapon(obj) then
		return
	end

	for _, data in ipairs(hiddenVisuals) do
		if data.object == obj then
			if obj:IsA("Decal") or obj:IsA("Texture") then
				obj.Transparency = 1
			end

			return
		end
	end

	if obj:IsA("Decal")
	or obj:IsA("Texture") then

		table.insert(hiddenVisuals, {
			object = obj,
			value = obj.Transparency
		})

		obj.Transparency = 1
	end
end

local function hideAccessory(accessory)
	if not accessory
	or not accessory:IsA("Accessory")
	or isOurs(accessory)
	or isWeapon(accessory) then
		return
	end

	for _, obj in ipairs(accessory:GetDescendants()) do
		if obj:IsA("BasePart") then
			rememberPart(obj)
		end
	end
end

local function forcePants()
	if not character
	or not character.Parent then
		return
	end

	local found = false

	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("Pants") then
			found = true

			if originalPants[obj] == nil then
				originalPants[obj] = obj.PantsTemplate
			end

			if obj.PantsTemplate ~= STALKER_PANTS then
				obj.PantsTemplate = STALKER_PANTS
			end
		end
	end

	if not found then
		local pants = Instance.new("Pants")

		pants.Name = "StalkerPants"
		pants.PantsTemplate = STALKER_PANTS

		mark(pants)

		pants.Parent = character
	end
end

local function hideOriginalSkin()
	if not character then
		return
	end

	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Shirt") then
			continue
		end

		if obj:IsA("Accessory") then
			hideAccessory(obj)
		end
	end

	for _, obj in ipairs(character:GetDescendants()) do
		if isOurs(obj)
		or isWeapon(obj) then
			continue
		end

		if obj:IsA("Shirt") then
			continue
		end

		if obj:IsA("BasePart") then
			if not bodyPart(obj) then
				rememberPart(obj)
			end

		elseif obj:IsA("Decal")
		or obj:IsA("Texture") then

			local parent = obj.Parent

			if parent
			and parent:IsA("BasePart")
			and parent ~= head then
				rememberVisual(obj)
			end
		end
	end
end

local function prepareAccessory(accessory)
	for _, obj in ipairs(accessory:GetDescendants()) do
		if obj:IsA("Script")
		or obj:IsA("LocalScript") then
			obj:Destroy()

		elseif obj:IsA("Weld")
		or obj:IsA("WeldConstraint")
		or obj:IsA("Motor6D")
		or obj:IsA("Snap") then
			obj:Destroy()

		elseif obj:IsA("BasePart") then
			obj.Anchored = false
			obj.CanCollide = false
			obj.CanTouch = false
			obj.CanQuery = false
			obj.Massless = true
			obj.LocalTransparencyModifier = 0
		end
	end
end

local function attach(source, offset)
	local clone = source:Clone()

	mark(clone)
	prepareAccessory(clone)

	clone.Parent = character

	local handle = clone:FindFirstChild("Handle")

	if not handle then
		clone:Destroy()
		return nil
	end

	handle.CFrame = head.CFrame * offset

	local weld = Instance.new("WeldConstraint")

	weld.Part0 = head
	weld.Part1 = handle
	weld.Parent = handle

	return clone
end

local function setAlpha(accessory, alpha)
	if not accessory
	or not accessory.Parent then
		return
	end

	for _, obj in ipairs(accessory:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.LocalTransparencyModifier = alpha

		elseif obj:IsA("Decal")
		or obj:IsA("Texture") then
			obj.Transparency = alpha
		end
	end
end

local function disconnectCharacter()
	for _, connection in ipairs(characterConnections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	table.clear(characterConnections)
end

local function restoreCharacter()
	disconnectCharacter()

	for _, obj in ipairs(added) do
		if obj and obj.Parent then
			obj:Destroy()
		end
	end

	for _, data in ipairs(hiddenParts) do
		if data.object
		and data.object.Parent then
			data.object.LocalTransparencyModifier = data.value
		end
	end

	for _, data in ipairs(hiddenVisuals) do
		if data.object
		and data.object.Parent then
			data.object.Transparency = data.value
		end
	end

	for pants, template in pairs(originalPants) do
		if pants
		and pants.Parent then
			pants.PantsTemplate = template
		end
	end

	table.clear(added)
	table.clear(hiddenParts)
	table.clear(hiddenVisuals)
	table.clear(originalPants)

	character = nil
	head = nil
	appliedPlayer = nil
end

local function apply(player, char)
	if not player
	or not char
	or not char.Parent
	or not isKiller(player) then
		return
	end

	restoreCharacter()

	character = char
	appliedPlayer = player

	head = character:WaitForChild("Head", 10)

	if not head then
		restoreCharacter()
		return
	end

	forcePants()
	hideOriginalSkin()

	local hood = attach(
		sourceHood,
		CFrame.new(
			0,
			0.1140,
			-0.0643
		)
	)

	local eyes = attach(
		sourceEyes,
		CFrame.new(
			0,
			0.2316,
			-0.5959
		)
	)

	table.insert(
		characterConnections,
		character.DescendantAdded:Connect(function(obj)
			task.defer(function()
				if not character
				or not character.Parent
				or not appliedPlayer
				or not isKiller(appliedPlayer)
				or not obj
				or not obj.Parent then
					return
				end

				if isOurs(obj)
				or isWeapon(obj) then
					return
				end

				if obj:IsA("Shirt") then
					return
				end

				if obj:IsA("Pants") then
					if originalPants[obj] == nil then
						originalPants[obj] = obj.PantsTemplate
					end

					obj.PantsTemplate = STALKER_PANTS
					return
				end

				local accessory =
					obj:FindFirstAncestorOfClass("Accessory")

				if accessory
				and not isOurs(accessory)
				and not isWeapon(accessory) then
					hideAccessory(accessory)
					return
				end

				if obj:IsA("Accessory") then
					hideAccessory(obj)
					return
				end

				if obj:IsA("BasePart")
				and not bodyPart(obj) then
					rememberPart(obj)
				end
			end)
		end)
	)

	table.insert(
		characterConnections,
		RunService.RenderStepped:Connect(function()
			if not character
			or not character.Parent
			or not appliedPlayer then
				return
			end

			if not isKiller(appliedPlayer) then
				restoreCharacter()
				return
			end

			forcePants()
			hideOriginalSkin()

			local torso =
				character:FindFirstChild("Torso")
				or character:FindFirstChild("UpperTorso")

			local alpha = 0

			if torso then
				alpha = math.max(
					torso.Transparency,
					torso.LocalTransparencyModifier
				)
			end

			setAlpha(hood, alpha)
			setAlpha(eyes, alpha)
		end)
	)

	print(
		"STALKER VISUAL APPLIED:",
		player.Name,
		"TEAM:",
		player.Team and player.Team.Name or "nil"
	)
end

local function updateTarget(player)
	if not player
	or player.Name ~= TARGET_USERNAME then
		return
	end

	if isKiller(player)
	and player.Character then
		if appliedPlayer ~= player
		or character ~= player.Character then
			apply(
				player,
				player.Character
			)
		end
	else
		if appliedPlayer == player
		or character then
			restoreCharacter()
		end
	end
end

local function watchPlayer(player)
	if player.Name ~= TARGET_USERNAME then
		return
	end

	updateTarget(player)

	table.insert(
		playerConnections,
		player:GetPropertyChangedSignal("Team"):Connect(function()
			updateTarget(player)
		end)
	)

	table.insert(
		playerConnections,
		player.CharacterAdded:Connect(function(char)
			task.wait(0.5)

			if isKiller(player) then
				apply(
					player,
					char
				)
			else
				restoreCharacter()
			end
		end)
	)
end

local target = Players:FindFirstChild(TARGET_USERNAME)

if target then
	watchPlayer(target)
end

table.insert(
	playerConnections,
	Players.PlayerAdded:Connect(function(player)
		if player.Name == TARGET_USERNAME then
			watchPlayer(player)
		end
	end)
)

table.insert(
	playerConnections,
	Players.PlayerRemoving:Connect(function(player)
		if player.Name == TARGET_USERNAME then
			restoreCharacter()
		end
	end)
)

task.spawn(function()
	while running do
		task.wait(CHECK_INTERVAL)

		if not running then
			break
		end

		local player =
			Players:FindFirstChild(
				TARGET_USERNAME
			)

		if player then
			pcall(function()
				updateTarget(player)
			end)
		else
			if character then
				restoreCharacter()
			end
		end
	end
end)

_G.CleanStalkerVisualCleanup = function()
	running = false

	restoreCharacter()

	for _, connection in ipairs(playerConnections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	table.clear(playerConnections)

	_G.CleanStalkerVisualCleanup = nil
end
