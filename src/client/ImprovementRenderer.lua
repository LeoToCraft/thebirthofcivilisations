local ImprovementRenderer = {}

local function makePart(parent, name, color, material, size, position)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Size = size
	part.Position = position
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part:SetAttribute("BaseTransparency", 0)
	part.Parent = parent
	return part
end

local function makeModel(parent, resource)
	local model = Instance.new("Model")
	model.Name = "Improvement_" .. resource.Key
	model:SetAttribute("ResourceKey", resource.Key)
	model:SetAttribute("ResourceName", resource.Name)
	model.Parent = parent

	return model
end

local function addFarm(model, center)
	local soil = Color3.fromRGB(113, 84, 45)
	local wheat = Color3.fromRGB(220, 188, 79)
	makePart(model, "FieldA", soil, Enum.Material.Ground, Vector3.new(1.1, 0.08, 0.42), center + Vector3.new(-0.38, 0, -0.18))
	makePart(model, "FieldB", soil, Enum.Material.Ground, Vector3.new(1.1, 0.08, 0.42), center + Vector3.new(0.38, 0, 0.18))
	makePart(model, "CropA", wheat, Enum.Material.Grass, Vector3.new(0.92, 0.12, 0.12), center + Vector3.new(-0.38, 0.12, -0.18))
	makePart(model, "CropB", wheat, Enum.Material.Grass, Vector3.new(0.92, 0.12, 0.12), center + Vector3.new(0.38, 0.12, 0.18))
end

local function addPasture(model, center)
	local fence = Color3.fromRGB(134, 95, 52)
	local stable = Color3.fromRGB(111, 74, 42)
	makePart(model, "FenceNorth", fence, Enum.Material.Wood, Vector3.new(1.35, 0.14, 0.09), center + Vector3.new(0, 0.12, -0.62))
	makePart(model, "FenceSouth", fence, Enum.Material.Wood, Vector3.new(1.35, 0.14, 0.09), center + Vector3.new(0, 0.12, 0.62))
	makePart(model, "FenceWest", fence, Enum.Material.Wood, Vector3.new(0.09, 0.14, 1.25), center + Vector3.new(-0.68, 0.12, 0))
	makePart(model, "FenceEast", fence, Enum.Material.Wood, Vector3.new(0.09, 0.14, 1.25), center + Vector3.new(0.68, 0.12, 0))
	makePart(model, "Stable", stable, Enum.Material.WoodPlanks, Vector3.new(0.46, 0.28, 0.38), center + Vector3.new(0.28, 0.22, -0.16))
end

local function addFishing(model, center)
	local net = Color3.fromRGB(203, 230, 227)
	local buoy = Color3.fromRGB(238, 86, 68)
	makePart(model, "NetA", net, Enum.Material.SmoothPlastic, Vector3.new(1.2, 0.05, 0.12), center + Vector3.new(0, 0.08, -0.18))
	makePart(model, "NetB", net, Enum.Material.SmoothPlastic, Vector3.new(1.2, 0.05, 0.12), center + Vector3.new(0, 0.08, 0.18))
	makePart(model, "BuoyA", buoy, Enum.Material.Neon, Vector3.new(0.2, 0.2, 0.2), center + Vector3.new(-0.54, 0.18, -0.18))
	makePart(model, "BuoyB", buoy, Enum.Material.Neon, Vector3.new(0.2, 0.2, 0.2), center + Vector3.new(0.54, 0.18, 0.18))
end

local function addPearlBoat(model, center)
	local wood = Color3.fromRGB(117, 78, 43)
	local pearl = Color3.fromRGB(246, 241, 224)
	makePart(model, "Boat", wood, Enum.Material.Wood, Vector3.new(0.9, 0.18, 0.42), center + Vector3.new(0, 0.15, 0))
	makePart(model, "PearlCrate", pearl, Enum.Material.SmoothPlastic, Vector3.new(0.22, 0.22, 0.22), center + Vector3.new(0.18, 0.32, 0))
end

local function addCamp(model, center)
	local hide = Color3.fromRGB(124, 95, 72)
	local fire = Color3.fromRGB(235, 111, 53)
	makePart(model, "Tent", hide, Enum.Material.Fabric, Vector3.new(0.78, 0.42, 0.52), center + Vector3.new(-0.2, 0.25, 0))
	makePart(model, "Fire", fire, Enum.Material.Neon, Vector3.new(0.18, 0.18, 0.18), center + Vector3.new(0.42, 0.15, 0.12))
	makePart(model, "Log", Color3.fromRGB(87, 57, 35), Enum.Material.Wood, Vector3.new(0.44, 0.08, 0.1), center + Vector3.new(0.42, 0.08, -0.12))
end

local function addSaltPit(model, center)
	local salt = Color3.fromRGB(240, 237, 214)
	local clay = Color3.fromRGB(189, 157, 91)
	makePart(model, "SaltBed", salt, Enum.Material.Sand, Vector3.new(1.08, 0.1, 0.86), center + Vector3.new(0, 0.06, 0))
	makePart(model, "PitRim", clay, Enum.Material.Sand, Vector3.new(1.26, 0.08, 0.12), center + Vector3.new(0, 0.12, -0.48))
	makePart(model, "SaltPile", salt, Enum.Material.Snow, Vector3.new(0.34, 0.18, 0.34), center + Vector3.new(0.2, 0.22, 0.06))
end

local function addDateGrove(model, center)
	local trunk = Color3.fromRGB(115, 77, 42)
	local leaves = Color3.fromRGB(55, 126, 72)
	makePart(model, "PalmTrunkA", trunk, Enum.Material.Wood, Vector3.new(0.16, 0.78, 0.16), center + Vector3.new(-0.24, 0.42, -0.14))
	makePart(model, "PalmLeavesA", leaves, Enum.Material.Grass, Vector3.new(0.58, 0.16, 0.58), center + Vector3.new(-0.24, 0.86, -0.14))
	makePart(model, "PalmTrunkB", trunk, Enum.Material.Wood, Vector3.new(0.14, 0.58, 0.14), center + Vector3.new(0.32, 0.32, 0.18))
	makePart(model, "PalmLeavesB", leaves, Enum.Material.Grass, Vector3.new(0.46, 0.14, 0.46), center + Vector3.new(0.32, 0.66, 0.18))
end

function ImprovementRenderer.Create(parent, tilePart, tileInfo)
	local resource = tileInfo.Resource
	if not resource then
		return nil
	end

	local center = Vector3.new(
		tilePart.Position.X,
		tilePart.Position.Y + tilePart.Size.Y * 0.5 + 0.05,
		tilePart.Position.Z
	)
	local model = makeModel(parent, resource)

	if resource.Key == "Wheat" then
		addFarm(model, center)
	elseif resource.Key == "Horses" then
		addPasture(model, center)
	elseif resource.Key == "Fish" then
		addFishing(model, center)
	elseif resource.Key == "Pearls" then
		addPearlBoat(model, center)
	elseif resource.Key == "Furs" or resource.Key == "Deer" then
		addCamp(model, center)
	elseif resource.Key == "Salt" then
		addSaltPit(model, center)
	elseif resource.Key == "Dates" then
		addDateGrove(model, center)
	end

	return model
end

return ImprovementRenderer
