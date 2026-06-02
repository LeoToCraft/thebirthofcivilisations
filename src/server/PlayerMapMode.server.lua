local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAME = "CivilisationMapMode"

local mapModeRemote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not mapModeRemote then
	mapModeRemote = Instance.new("RemoteEvent")
	mapModeRemote.Name = REMOTE_NAME
	mapModeRemote.Parent = ReplicatedStorage
end

local mapModePlayers = {}
local savedCharacterState = {}

local function getHumanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function saveState(player, character, humanoid, rootPart)
	if savedCharacterState[player] then
		return
	end

	savedCharacterState[player] = {
		WalkSpeed = humanoid.WalkSpeed,
		JumpPower = humanoid.JumpPower,
		JumpHeight = humanoid.JumpHeight,
		UseJumpPower = humanoid.UseJumpPower,
		AutoRotate = humanoid.AutoRotate,
		RootAnchored = rootPart and rootPart.Anchored or false,
	}
end

local function addProtection(character)
	local forceField = character:FindFirstChild("MapModeForceField")
	if forceField then
		return
	end

	forceField = Instance.new("ForceField")
	forceField.Name = "MapModeForceField"
	forceField.Visible = false
	forceField.Parent = character
end

local function removeProtection(character)
	local forceField = character and character:FindFirstChild("MapModeForceField")
	if forceField then
		forceField:Destroy()
	end
end

local function freezeCharacter(player)
	local character = player.Character
	local humanoid = getHumanoid(character)
	local rootPart = getRootPart(character)
	if not character or not humanoid then
		return
	end

	saveState(player, character, humanoid, rootPart)
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false

	if rootPart then
		rootPart.Anchored = true
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end

	addProtection(character)
end

local function unfreezeCharacter(player)
	local character = player.Character
	local humanoid = getHumanoid(character)
	local rootPart = getRootPart(character)
	local state = savedCharacterState[player]

	if humanoid and state then
		humanoid.WalkSpeed = state.WalkSpeed
		humanoid.JumpPower = state.JumpPower
		humanoid.JumpHeight = state.JumpHeight
		humanoid.UseJumpPower = state.UseJumpPower
		humanoid.AutoRotate = state.AutoRotate
	end

	if rootPart and state then
		rootPart.Anchored = state.RootAnchored
	end

	removeProtection(character)
	savedCharacterState[player] = nil
end

local function setMapMode(player, isEnabled)
	mapModePlayers[player] = isEnabled or nil

	if isEnabled then
		freezeCharacter(player)
	else
		unfreezeCharacter(player)
	end
end

mapModeRemote.OnServerEvent:Connect(function(player, isEnabled)
	setMapMode(player, isEnabled == true)
end)

Players.PlayerAdded:Connect(function(player)
	mapModePlayers[player] = true

	player.CharacterAdded:Connect(function()
		if mapModePlayers[player] then
			task.defer(function()
				freezeCharacter(player)
			end)
		end
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	mapModePlayers[player] = true
	if player.Character then
		freezeCharacter(player)
	end

	player.CharacterAdded:Connect(function()
		if mapModePlayers[player] then
			task.defer(function()
				freezeCharacter(player)
			end)
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	mapModePlayers[player] = nil
	savedCharacterState[player] = nil
end)
