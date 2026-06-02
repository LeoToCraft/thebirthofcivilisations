local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MapCamera = {}

local isEnabled = false
local cameraTarget = Vector3.new(0, 0, 0)
local cameraHeight = 110
local bounds = {
	MinX = -300,
	MaxX = 300,
	MinZ = -300,
	MaxZ = 300,
}

local function applyCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 34
	camera.CFrame = CFrame.lookAt(
		cameraTarget + Vector3.new(0, cameraHeight, -cameraHeight * 0.82),
		cameraTarget + Vector3.new(0, 2, 0)
	)
end

function MapCamera.Focus(width, length, tileSize)
	local maxSide = math.max(width, length) * tileSize
	cameraHeight = math.clamp(maxSide * 0.025, 16, 42)
	cameraTarget = Vector3.new(0, 0, 0)
	bounds = {
		MinX = -width * tileSize * 0.5,
		MaxX = width * tileSize * 0.5,
		MinZ = -length * tileSize * 0.5,
		MaxZ = length * tileSize * 0.5,
	}
	applyCamera()
end

function MapCamera.SetEnabled(enabled)
	isEnabled = enabled
	if enabled then
		applyCamera()
	elseif workspace.CurrentCamera then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	end
end

RunService.RenderStepped:Connect(function(deltaTime)
	if not isEnabled then
		return
	end

	local moveRight = 0
	local moveForward = 0

	if UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		moveRight -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		moveRight += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		moveForward += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		moveForward -= 1
	end

	if moveRight == 0 and moveForward == 0 then
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z)
	local forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	if right.Magnitude > 0 then
		right = right.Unit
	end
	if forward.Magnitude > 0 then
		forward = forward.Unit
	end

	local direction = right * moveRight + forward * moveForward
	if direction.Magnitude > 1 then
		direction = direction.Unit
	end

	local speed = math.max(22, cameraHeight * 1.15)
	local nextTarget = cameraTarget + direction * speed * deltaTime
	cameraTarget = Vector3.new(
		math.clamp(nextTarget.X, bounds.MinX, bounds.MaxX),
		0,
		math.clamp(nextTarget.Z, bounds.MinZ, bounds.MaxZ)
	)
	applyCamera()
end)

return MapCamera
