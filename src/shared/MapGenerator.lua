local MapGenerator = {}

local MIN_MAP_SIZE = 200
local MAX_MAP_SIZE = 1000

MapGenerator.MinMapSize = MIN_MAP_SIZE
MapGenerator.MaxMapSize = MAX_MAP_SIZE

MapGenerator.TileTypes = {
	Water = {
		Name = "Вода",
		HeightMin = 0.75,
		HeightMax = 0.75,
		Walkable = false,
		Color = Color3.fromRGB(44, 126, 205),
		Material = Enum.Material.SmoothPlastic,
	},
	Snow = {
		Name = "Снег",
		HeightMin = 1,
		HeightMax = 1,
		Walkable = true,
		Color = Color3.fromRGB(232, 244, 248),
		Material = Enum.Material.Snow,
	},
	Sand = {
		Name = "Песок",
		HeightMin = 1,
		HeightMax = 1,
		Walkable = true,
		Color = Color3.fromRGB(222, 198, 126),
		Material = Enum.Material.Sand,
	},
	Grass = {
		Name = "Трава",
		HeightMin = 1,
		HeightMax = 1,
		Walkable = true,
		Color = Color3.fromRGB(83, 157, 79),
		Material = Enum.Material.Grass,
	},
	Mountain = {
		Name = "Гора",
		HeightMin = 1.25,
		HeightMax = 2,
		Walkable = false,
		Color = Color3.fromRGB(52, 54, 57),
		Material = Enum.Material.Slate,
	},
}

MapGenerator.ResourceTypes = {
	Fish = {
		Name = "Рыба",
		Color = Color3.fromRGB(175, 234, 255),
		SpawnOn = "Water",
	},
	Pearls = {
		Name = "Жемчуг",
		Color = Color3.fromRGB(248, 241, 222),
		SpawnOn = "Water",
	},
	Wheat = {
		Name = "Пшеница",
		Color = Color3.fromRGB(232, 202, 91),
		SpawnOn = "Grass",
	},
	Horses = {
		Name = "Лошади",
		Color = Color3.fromRGB(126, 82, 46),
		SpawnOn = "Grass",
	},
	Furs = {
		Name = "Меха",
		Color = Color3.fromRGB(125, 95, 72),
		SpawnOn = "Snow",
	},
	Deer = {
		Name = "Олени",
		Color = Color3.fromRGB(163, 118, 72),
		SpawnOn = "Snow",
	},
	Salt = {
		Name = "Соль",
		Color = Color3.fromRGB(238, 234, 207),
		SpawnOn = "Sand",
	},
	Dates = {
		Name = "Финики",
		Color = Color3.fromRGB(121, 84, 39),
		SpawnOn = "Sand",
	},
}

function MapGenerator.ClampDimension(value)
	return math.clamp(math.floor(tonumber(value) or MIN_MAP_SIZE), MIN_MAP_SIZE, MAX_MAP_SIZE)
end

function MapGenerator.NormalizeSeed(seed)
	local text = tostring(seed or "")
	if text == "" then
		text = "1"
	end

	local hash = 5381
	for index = 1, #text do
		hash = (hash * 33 + string.byte(text, index)) % 2147483647
	end

	return math.max(hash, 1)
end

local function smooth(value)
	return value * value * (3 - 2 * value)
end

local function lerp(a, b, alpha)
	return a + (b - a) * alpha
end

local function hash01(seedValue, x, z, salt)
	local value = math.sin(x * 127.1 + z * 311.7 + seedValue * 0.137 + salt * 19.19) * 43758.5453123
	return value - math.floor(value)
end

local function valueNoise(seedValue, x, z, scale, salt)
	local sampleX = x / scale
	local sampleZ = z / scale
	local x0 = math.floor(sampleX)
	local z0 = math.floor(sampleZ)
	local localX = smooth(sampleX - x0)
	local localZ = smooth(sampleZ - z0)

	local a = hash01(seedValue, x0, z0, salt)
	local b = hash01(seedValue, x0 + 1, z0, salt)
	local c = hash01(seedValue, x0, z0 + 1, salt)
	local d = hash01(seedValue, x0 + 1, z0 + 1, salt)

	return lerp(lerp(a, b, localX), lerp(c, d, localX), localZ)
end

local function fractalNoise(seedValue, x, z, scale, salt)
	local total = 0
	local amplitude = 1
	local frequency = 1
	local maxAmplitude = 0

	for octave = 1, 4 do
		total += valueNoise(seedValue, x * frequency, z * frequency, scale, salt + octave * 13) * amplitude
		maxAmplitude += amplitude
		amplitude *= 0.5
		frequency *= 2
	end

	return total / maxAmplitude
end

local function getMountainInputs(x, z, width, length, seedValue)
	local centeredX = x - width * 0.5
	local centeredZ = z - length * 0.5
	local elevation = fractalNoise(seedValue, centeredX, centeredZ, 66, 3)
	local continent = fractalNoise(seedValue, centeredX, centeredZ, 190, 41)
	local ridgeNoise = fractalNoise(seedValue, centeredX, centeredZ, 54, 211)
	local ridge = 1 - math.abs(ridgeNoise * 2 - 1)
	local peakNoise = fractalNoise(seedValue, centeredX, centeredZ, 18, 251)
	local landValue = elevation * 0.72 + continent * 0.28
	local mountainScore = landValue * 0.48 + ridge * 0.32 + peakNoise * 0.2

	return landValue, ridge, peakNoise, mountainScore
end

local function isMountainAt(x, z, width, length, seedValue)
	if x < 1 or x > width or z < 1 or z > length then
		return false
	end

	local landValue, _, peakNoise, mountainScore = getMountainInputs(x, z, width, length, seedValue)
	return mountainScore > 0.74 and landValue > 0.5 and peakNoise > 0.42
end

local function createResource(resourceKey)
	local resource = MapGenerator.ResourceTypes[resourceKey]
	return {
		Key = resourceKey,
		Name = resource.Name,
		Color = resource.Color,
		SpawnOn = resource.SpawnOn,
	}
end

local function getResourceKeyForTile(tileKey, x, z, seedValue, moisture, landValue)
	local resourceRoll = hash01(seedValue, x, z, 701)
	local detailRoll = hash01(seedValue, x, z, 719)

	if tileKey == "Water" then
		if resourceRoll < 0.025 then
			return "Fish"
		elseif resourceRoll < 0.032 then
			return "Pearls"
		end
	elseif tileKey == "Grass" then
		if moisture > 0.5 and resourceRoll < 0.028 then
			return "Wheat"
		elseif detailRoll < 0.018 and landValue > 0.44 then
			return "Horses"
		end
	elseif tileKey == "Snow" then
		if resourceRoll < 0.026 then
			return "Furs"
		elseif detailRoll < 0.02 then
			return "Deer"
		end
	elseif tileKey == "Sand" then
		if resourceRoll < 0.026 then
			return "Salt"
		elseif moisture > 0.36 and detailRoll < 0.017 then
			return "Dates"
		end
	end

	return nil
end

local function getTileContext(x, z, width, length, seedValue)
	local centeredX = x - width * 0.5
	local centeredZ = z - length * 0.5
	local moisture = fractalNoise(seedValue, centeredX, centeredZ, 95, 79)
	local temperature = fractalNoise(seedValue, centeredX, centeredZ, 150, 113)
	local lakeNoise = fractalNoise(seedValue, centeredX, centeredZ, 36, 331)
	local smallLakeNoise = fractalNoise(seedValue, centeredX, centeredZ, 16, 359)
	local beachNoise = fractalNoise(seedValue, centeredX, centeredZ, 28, 383)
	local landValue, ridge, peakNoise, mountainScore = getMountainInputs(x, z, width, length, seedValue)
	local latitude = math.abs((z / length) * 2 - 1)
	local coldness = (1 - temperature) * 0.62 + latitude * 0.38
	local riverWidthA = 1.35 + hash01(seedValue, 3, 7, 419) * 1.35
	local riverCenterZ = length * (0.22 + hash01(seedValue, 1, 1, 431) * 0.56)
		+ math.sin((x + seedValue % 97) / 28) * (8 + length * 0.025)
		+ math.sin((x + seedValue % 211) / 74) * (12 + length * 0.035)
	local riverA = math.abs(z - riverCenterZ) <= riverWidthA
	local riverWidthB = 1.1 + hash01(seedValue, 9, 2, 443) * 1.15
	local riverCenterX = width * (0.2 + hash01(seedValue, 5, 4, 457) * 0.6)
		+ math.sin((z + seedValue % 131) / 31) * (7 + width * 0.022)
		+ math.sin((z + seedValue % 251) / 82) * (10 + width * 0.03)
	local riverB = hash01(seedValue, 11, 11, 467) > 0.28 and math.abs(x - riverCenterX) <= riverWidthB
	local isLake = (landValue < 0.38 and lakeNoise < 0.31) or (smallLakeNoise > 0.84 and landValue < 0.58)
	local isShoreSand = landValue < 0.39 or (lakeNoise < 0.38 and landValue < 0.5) or beachNoise < 0.18
	local tileKey

	if riverA or riverB or isLake or landValue < 0.28 then
		tileKey = "Water"
	elseif mountainScore > 0.74 and landValue > 0.5 and peakNoise > 0.42 then
		tileKey = "Mountain"
	elseif coldness > 0.62 and landValue > 0.34 then
		tileKey = "Snow"
	elseif moisture < 0.31 or isShoreSand then
		tileKey = "Sand"
	else
		tileKey = "Grass"
	end

	return {
		TileKey = tileKey,
		Moisture = moisture,
		LandValue = landValue,
		Ridge = ridge,
		MountainScore = mountainScore,
	}
end

local function hasSameResourceNearby(resourceKey, x, z, width, length, seedValue)
	local radius = 4

	for offsetZ = -radius, radius do
		for offsetX = -radius, radius do
			local neighborX = x + offsetX
			local neighborZ = z + offsetZ
			if (offsetX ~= 0 or offsetZ ~= 0)
				and neighborX >= 1
				and neighborX <= width
				and neighborZ >= 1
				and neighborZ <= length
				and offsetX * offsetX + offsetZ * offsetZ <= radius * radius
			then
				local context = getTileContext(neighborX, neighborZ, width, length, seedValue)
				if getResourceKeyForTile(context.TileKey, neighborX, neighborZ, seedValue, context.Moisture, context.LandValue) == resourceKey then
					return true
				end
			end
		end
	end

	return false
end

local function getResourceForTile(tileKey, x, z, width, length, seedValue, moisture, landValue)
	local resourceKey = getResourceKeyForTile(tileKey, x, z, seedValue, moisture, landValue)
	if not resourceKey or hasSameResourceNearby(resourceKey, x, z, width, length, seedValue) then
		return nil
	end

	return createResource(resourceKey)
end

function MapGenerator.GetTileAt(x, z, width, length, seedValue)
	width = MapGenerator.ClampDimension(width)
	length = MapGenerator.ClampDimension(length)
	seedValue = tonumber(seedValue) or MapGenerator.NormalizeSeed(seedValue)

	if x < 0 or x > width + 1 or z < 0 or z > length + 1 then
		local water = MapGenerator.TileTypes.Water
		return {
			Key = "Water",
			Name = water.Name,
			Height = water.HeightMin,
			Walkable = water.Walkable,
			Color = water.Color,
			Material = water.Material,
			IsBorder = true,
			Resource = nil,
		}
	end

	if x == 0 or x == width + 1 or z == 0 or z == length + 1 then
		local sand = MapGenerator.TileTypes.Sand
		return {
			Key = "Sand",
			Name = sand.Name,
			Height = sand.HeightMin,
			Walkable = sand.Walkable,
			Color = sand.Color,
			Material = sand.Material,
			IsBorder = true,
			Resource = nil,
		}
	end

	local centeredX = x - width * 0.5
	local centeredZ = z - length * 0.5
	local moisture = fractalNoise(seedValue, centeredX, centeredZ, 95, 79)
	local temperature = fractalNoise(seedValue, centeredX, centeredZ, 150, 113)
	local heightDetail = fractalNoise(seedValue, centeredX, centeredZ, 38, 157)
	local heightNoise = hash01(seedValue, x, z, 307)
	local lakeNoise = fractalNoise(seedValue, centeredX, centeredZ, 36, 331)
	local smallLakeNoise = fractalNoise(seedValue, centeredX, centeredZ, 16, 359)
	local beachNoise = fractalNoise(seedValue, centeredX, centeredZ, 28, 383)
	local landValue, ridge, peakNoise, mountainScore = getMountainInputs(x, z, width, length, seedValue)
	local latitude = math.abs((z / length) * 2 - 1)
	local coldness = (1 - temperature) * 0.62 + latitude * 0.38
	local riverWidthA = 1.35 + hash01(seedValue, 3, 7, 419) * 1.35
	local riverCenterZ = length * (0.22 + hash01(seedValue, 1, 1, 431) * 0.56)
		+ math.sin((x + seedValue % 97) / 28) * (8 + length * 0.025)
		+ math.sin((x + seedValue % 211) / 74) * (12 + length * 0.035)
	local riverA = math.abs(z - riverCenterZ) <= riverWidthA
	local riverWidthB = 1.1 + hash01(seedValue, 9, 2, 443) * 1.15
	local riverCenterX = width * (0.2 + hash01(seedValue, 5, 4, 457) * 0.6)
		+ math.sin((z + seedValue % 131) / 31) * (7 + width * 0.022)
		+ math.sin((z + seedValue % 251) / 82) * (10 + width * 0.03)
	local riverB = hash01(seedValue, 11, 11, 467) > 0.28 and math.abs(x - riverCenterX) <= riverWidthB
	local isLake = (landValue < 0.38 and lakeNoise < 0.31) or (smallLakeNoise > 0.84 and landValue < 0.58)
	local isShoreSand = landValue < 0.39 or (lakeNoise < 0.38 and landValue < 0.5) or beachNoise < 0.18

	local tileKey
	local tile
	local height

	if riverA or riverB or isLake or landValue < 0.28 then
		tileKey = "Water"
		tile = MapGenerator.TileTypes.Water
		height = tile.HeightMin
	elseif mountainScore > 0.74 and landValue > 0.5 and peakNoise > 0.42 then
		tileKey = "Mountain"
		tile = MapGenerator.TileTypes.Mountain
		local mountainNeighbors = 0
		for offsetZ = -1, 1 do
			for offsetX = -1, 1 do
				if (offsetX ~= 0 or offsetZ ~= 0) and isMountainAt(x + offsetX, z + offsetZ, width, length, seedValue) then
					mountainNeighbors += 1
				end
			end
		end

		local innerStrength = mountainNeighbors / 8
		local heightAlpha = math.clamp(innerStrength * 0.72 + heightDetail * 0.12 + ridge * 0.1 + heightNoise * 0.06, 0, 1)
		height = tile.HeightMin + heightAlpha * (tile.HeightMax - tile.HeightMin)
	elseif coldness > 0.62 and landValue > 0.34 then
		tileKey = "Snow"
		tile = MapGenerator.TileTypes.Snow
		height = tile.HeightMin
	elseif moisture < 0.31 or isShoreSand then
		tileKey = "Sand"
		tile = MapGenerator.TileTypes.Sand
		height = tile.HeightMin
	else
		tileKey = "Grass"
		tile = MapGenerator.TileTypes.Grass
		height = tile.HeightMin
	end

	local resource = getResourceForTile(tileKey, x, z, width, length, seedValue, moisture, landValue)

	return {
		Key = tileKey,
		Name = tile.Name,
		Height = height,
		Walkable = tile.Walkable,
		Color = tile.Color,
		Material = tile.Material,
		IsBorder = false,
		Resource = resource,
	}
end

function MapGenerator.CreateConfig(seed, width, length)
	local clampedWidth = MapGenerator.ClampDimension(width)
	local clampedLength = MapGenerator.ClampDimension(length)

	return {
		Seed = tostring(seed or "1"),
		SeedValue = MapGenerator.NormalizeSeed(seed),
		Width = clampedWidth,
		Length = clampedLength,
	}
end

return MapGenerator
