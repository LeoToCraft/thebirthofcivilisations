local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImprovementRenderer = require(script.Parent:WaitForChild("ImprovementRenderer"))
local MapGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MapGenerator"))

local MapRenderer = {}

MapRenderer.TileSize = 3
MapRenderer.MaxRenderedAxis = 420

local MAP_FOLDER_NAME = "CivilisationGeneratedMap"

local function getTileTopY(tileInfo)
	return tileInfo.Height
end

local function createMapPart(parent, name, tileInfo, position, sizeX, sizeZ, transparency)
	local topY = getTileTopY(tileInfo)
	local thickness = tileInfo.Height
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = tileInfo.Walkable
	part.Color = tileInfo.Color
	part.Material = tileInfo.Material
	part.Size = Vector3.new(sizeX, thickness, sizeZ)
	part.Position = Vector3.new(position.X, topY - thickness * 0.5, position.Z)
	part.CastShadow = tileInfo.Key == "Mountain"
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Transparency = transparency or 0
	part:SetAttribute("BaseTransparency", transparency or 0)
	part:SetAttribute("TileType", tileInfo.Name)
	part:SetAttribute("HeightScale", tileInfo.Height)
	part:SetAttribute("Walkable", tileInfo.Walkable)
	part.Parent = parent
	return part
end

local function mapCellCenter(x, z, spanX, spanZ, width, length)
	return Vector3.new(
		((x - 1) + spanX * 0.5 - width * 0.5) * MapRenderer.TileSize,
		0,
		((z - 1) + spanZ * 0.5 - length * 0.5) * MapRenderer.TileSize
	)
end

local function createMapBorders(parent, width, length, seedValue)
	local water = MapGenerator.GetTileAt(-1, -1, width, length, seedValue)
	local sand = MapGenerator.GetTileAt(0, 0, width, length, seedValue)
	local waterPadding = 260

	local outerWater = createMapPart(parent, "OuterWater", water, Vector3.new(0, 0, 0), (width + waterPadding * 2) * MapRenderer.TileSize, (length + waterPadding * 2) * MapRenderer.TileSize, 0.08)
	outerWater.Position = Vector3.new(0, getTileTopY(water) - 0.55, 0)
	createMapPart(parent, "NorthSandBorder", sand, mapCellCenter(0, 0, width + 2, 1, width, length), (width + 2) * MapRenderer.TileSize, MapRenderer.TileSize, 0)
	createMapPart(parent, "SouthSandBorder", sand, mapCellCenter(0, length + 1, width + 2, 1, width, length), (width + 2) * MapRenderer.TileSize, MapRenderer.TileSize, 0)
	createMapPart(parent, "WestSandBorder", sand, mapCellCenter(0, 1, 1, length, width, length), MapRenderer.TileSize, length * MapRenderer.TileSize, 0)
	createMapPart(parent, "EastSandBorder", sand, mapCellCenter(width + 1, 1, 1, length, width, length), MapRenderer.TileSize, length * MapRenderer.TileSize, 0)
end

function MapRenderer.Clear()
	local existing = workspace:FindFirstChild(MAP_FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
end

function MapRenderer.SetVisible(folder, isVisible)
	if not folder then
		return
	end

	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = isVisible and descendant:GetAttribute("BaseTransparency") or 1
		end
	end
end

function MapRenderer.Render(mapConfig, onProgress)
	MapRenderer.Clear()

	local folder = Instance.new("Folder")
	folder.Name = MAP_FOLDER_NAME
	folder:SetAttribute("Seed", mapConfig.Seed)
	folder:SetAttribute("SeedValue", mapConfig.SeedValue)
	folder:SetAttribute("Width", mapConfig.Width)
	folder:SetAttribute("Length", mapConfig.Length)
	folder.Parent = workspace

	createMapBorders(folder, mapConfig.Width, mapConfig.Length, mapConfig.SeedValue)

	local step = math.max(1, math.ceil(math.max(mapConfig.Width, mapConfig.Length) / MapRenderer.MaxRenderedAxis))
	local columns = math.ceil(mapConfig.Width / step)
	local rows = math.ceil(mapConfig.Length / step)
	local totalTiles = columns * rows
	local renderedTiles = 0
	local stats = {
		Water = 0,
		Snow = 0,
		Sand = 0,
		Grass = 0,
		Mountain = 0,
	}
	local resources = {}
	for resourceKey in pairs(MapGenerator.ResourceTypes) do
		resources[resourceKey] = 0
	end
	local totalResources = 0

	for z = 1, mapConfig.Length, step do
		local spanZ = math.min(step, mapConfig.Length - z + 1)

		for x = 1, mapConfig.Width, step do
			local spanX = math.min(step, mapConfig.Width - x + 1)
			local tileInfo = MapGenerator.GetTileAt(x, z, mapConfig.Width, mapConfig.Length, mapConfig.SeedValue)
			local cellCount = spanX * spanZ
			stats[tileInfo.Key] = (stats[tileInfo.Key] or 0) + cellCount

			local part = createMapPart(
				folder,
				tileInfo.Key,
				tileInfo,
				mapCellCenter(x, z, spanX, spanZ, mapConfig.Width, mapConfig.Length),
				spanX * MapRenderer.TileSize,
				spanZ * MapRenderer.TileSize,
				0
			)
			part:SetAttribute("MapX", x)
			part:SetAttribute("MapZ", z)
			part:SetAttribute("SampleStep", step)

			if tileInfo.Resource then
				part:SetAttribute("ResourceKey", tileInfo.Resource.Key)
				part:SetAttribute("ResourceName", tileInfo.Resource.Name)
				resources[tileInfo.Resource.Key] = (resources[tileInfo.Resource.Key] or 0) + 1
				totalResources += 1
				ImprovementRenderer.Create(folder, part, tileInfo)
			end

			renderedTiles += 1
			if renderedTiles % 180 == 0 then
				onProgress(renderedTiles / totalTiles, ("Генерируем клетки: %d/%d"):format(renderedTiles, totalTiles))
				task.wait()
			end
		end
	end

	onProgress(1, "Клетки, высоты и проходимость готовы.")
	return {
		Folder = folder,
		Step = step,
		RenderedTiles = totalTiles,
		Stats = stats,
		Resources = resources,
		TotalResources = totalResources,
		TileSize = MapRenderer.TileSize,
	}
end

return MapRenderer
