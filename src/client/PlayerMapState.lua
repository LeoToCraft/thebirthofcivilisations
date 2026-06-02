local PlayerMapState = {}

local controlsByPlayer = {}

local function getControls(player)
	if controlsByPlayer[player] then
		return controlsByPlayer[player]
	end

	local playerScripts = player:WaitForChild("PlayerScripts")
	local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
	local controls = playerModule:GetControls()
	controlsByPlayer[player] = controls
	return controls
end

function PlayerMapState.SetCharacterVisible(player, isVisible)
	local character = player.Character
	if not character then
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = isVisible and 0 or 1
			descendant.CanCollide = false
		elseif descendant:IsA("Decal") then
			descendant.Transparency = isVisible and 0 or 1
		end
	end
end

function PlayerMapState.SetMovementEnabled(player, isEnabled)
	local controls = getControls(player)
	if isEnabled then
		controls:Enable()
	else
		controls:Disable()
	end
end

return PlayerMapState
