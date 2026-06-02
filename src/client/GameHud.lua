local GameHud = {}

local function resourceCount(resources, key)
	return resources and resources[key] or 0
end

function GameHud.Create(gui, helpers)
	local colors = helpers.Colors
	local makeText = helpers.MakeText
	local makeButton = helpers.MakeButton
	local addCorner = helpers.AddCorner
	local addStroke = helpers.AddStroke
	local addPadding = helpers.AddPadding

	local hudMetrics = {}
	local hudResourceRows = {}
	local hudTerrainRows = {}
	local hudContext = {}
	local hudTurn = 1
	local hudTurnSuffix = "Древний мир"

	local mapHud = Instance.new("Frame")
	mapHud.Name = "GeneratedMapHud"
	mapHud.BackgroundTransparency = 1
	mapHud.BorderSizePixel = 0
	mapHud.Size = UDim2.fromScale(1, 1)
	mapHud.Visible = false
	mapHud.ZIndex = 20
	mapHud.Parent = gui

	local function makeHudPanel(parent, name, position, size, transparency)
		local panel = Instance.new("Frame")
		panel.Name = name
		panel.BackgroundColor3 = Color3.fromRGB(19, 38, 48)
		panel.BackgroundTransparency = transparency or 0.1
		panel.BorderSizePixel = 0
		panel.Position = position
		panel.Size = size
		panel.ZIndex = 21
		panel.Parent = parent
		addCorner(panel, 4)
		addStroke(panel, Color3.fromRGB(196, 171, 104), 1, 0.18)

		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 63, 72)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(17, 31, 38)),
		})
		gradient.Rotation = 90
		gradient.Parent = panel

		return panel
	end

	local function makeHudText(parent, text, size, color, font, alignment)
		local label = makeText(parent, text, size, color, font or Enum.Font.SourceSansSemibold, alignment)
		label.TextWrapped = false
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.ZIndex = 22
		return label
	end

	local topHud = makeHudPanel(mapHud, "TopResourceBar", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 62), 0.04)
	topHud.BackgroundColor3 = Color3.fromRGB(21, 37, 43)
	addPadding(topHud, 18, 18, 8, 8)

	local mapHudTitle = makeHudText(topHud, "Новая держава", 18, Color3.fromRGB(248, 238, 202), Enum.Font.Garamond)
	mapHudTitle.Position = UDim2.fromOffset(0, 2)
	mapHudTitle.Size = UDim2.fromOffset(210, 24)

	local mapHudStats = makeHudText(topHud, "Ход 1 | Древний мир", 13, Color3.fromRGB(186, 205, 205), Enum.Font.SourceSans)
	mapHudStats.Position = UDim2.fromOffset(0, 29)
	mapHudStats.Size = UDim2.fromOffset(210, 18)

	local resourceStrip = Instance.new("Frame")
	resourceStrip.Name = "ResourceStrip"
	resourceStrip.BackgroundTransparency = 1
	resourceStrip.Position = UDim2.new(0, 226, 0, 7)
	resourceStrip.Size = UDim2.new(1, -500, 0, 48)
	resourceStrip.ZIndex = 22
	resourceStrip.Parent = topHud

	local resourceStripScale = Instance.new("UIScale")
	resourceStripScale.Parent = resourceStrip

	local resourceLayout = Instance.new("UIListLayout")
	resourceLayout.FillDirection = Enum.FillDirection.Horizontal
	resourceLayout.Padding = UDim.new(0, 7)
	resourceLayout.SortOrder = Enum.SortOrder.LayoutOrder
	resourceLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	resourceLayout.Parent = resourceStrip

	local function makeHudMetric(key, title, accentColor, order)
		local item = Instance.new("Frame")
		item.Name = key
		item.BackgroundColor3 = Color3.fromRGB(27, 46, 53)
		item.BackgroundTransparency = 0.06
		item.BorderSizePixel = 0
		item.LayoutOrder = order
		item.Size = UDim2.fromOffset(88, 46)
		item.ZIndex = 22
		item.Parent = resourceStrip
		addCorner(item, 3)
		addStroke(item, Color3.fromRGB(92, 110, 111), 1, 0.55)

		local icon = Instance.new("Frame")
		icon.BackgroundColor3 = accentColor
		icon.BorderSizePixel = 0
		icon.Position = UDim2.fromOffset(8, 9)
		icon.Size = UDim2.fromOffset(8, 28)
		icon.ZIndex = 23
		icon.Parent = item
		addCorner(icon, 2)

		local name = makeHudText(item, title, 10, Color3.fromRGB(176, 190, 188), Enum.Font.SourceSansBold)
		name.Position = UDim2.fromOffset(20, 4)
		name.Size = UDim2.fromOffset(58, 13)

		local value = makeHudText(item, "0", 18, Color3.fromRGB(245, 241, 225), Enum.Font.SourceSansBold, Enum.TextXAlignment.Right)
		value.Position = UDim2.fromOffset(18, 16)
		value.Size = UDim2.fromOffset(40, 20)

		local rate = makeHudText(item, "+0", 12, accentColor, Enum.Font.SourceSansBold, Enum.TextXAlignment.Right)
		rate.Position = UDim2.fromOffset(57, 19)
		rate.Size = UDim2.fromOffset(25, 16)

		hudMetrics[key] = {
			Value = value,
			Rate = rate,
		}
	end

	makeHudMetric("Science", "НАУКА", Color3.fromRGB(103, 201, 242), 1)
	makeHudMetric("Culture", "КУЛЬТ", Color3.fromRGB(194, 124, 222), 2)
	makeHudMetric("Gold", "ЗОЛОТО", Color3.fromRGB(238, 196, 90), 3)
	makeHudMetric("Faith", "ВЕРА", Color3.fromRGB(218, 222, 236), 4)
	makeHudMetric("Food", "ЕДА", Color3.fromRGB(116, 204, 112), 5)
	makeHudMetric("Production", "ПРОИЗВ", Color3.fromRGB(218, 128, 72), 6)
	makeHudMetric("Influence", "ВЛИЯН", Color3.fromRGB(103, 226, 197), 7)
	makeHudMetric("Cities", "ГОРОДА", Color3.fromRGB(236, 145, 116), 8)

	local hudEraButton = makeButton(topHud, "Сводка", 34, Color3.fromRGB(196, 171, 104))
	hudEraButton.Position = UDim2.new(1, -184, 0, 10)
	hudEraButton.Size = UDim2.fromOffset(84, 34)
	hudEraButton.ZIndex = 22

	local mapMenuButton = makeButton(topHud, "Меню", 34, colors.cyan)
	mapMenuButton.Position = UDim2.new(1, -90, 0, 10)
	mapMenuButton.Size = UDim2.fromOffset(72, 34)
	mapMenuButton.ZIndex = 22

	local leftTracker = makeHudPanel(mapHud, "WorldTracker", UDim2.fromOffset(18, 78), UDim2.fromOffset(268, 242), 0.08)
	addPadding(leftTracker, 14, 14, 12, 12)

	local trackerTitle = makeHudText(leftTracker, "ПОВЕСТКА ДЕРЖАВЫ", 14, Color3.fromRGB(236, 214, 156), Enum.Font.SourceSansBold)
	trackerTitle.Size = UDim2.new(1, 0, 0, 18)

	local trackerLine = Instance.new("Frame")
	trackerLine.BackgroundColor3 = Color3.fromRGB(196, 171, 104)
	trackerLine.BackgroundTransparency = 0.24
	trackerLine.BorderSizePixel = 0
	trackerLine.Position = UDim2.fromOffset(0, 26)
	trackerLine.Size = UDim2.new(1, 0, 0, 1)
	trackerLine.ZIndex = 22
	trackerLine.Parent = leftTracker

	local trackerItems = {
		{ Key = "Research", Title = "Исследование", Accent = Color3.fromRGB(103, 201, 242) },
		{ Key = "Civic", Title = "Общественный курс", Accent = Color3.fromRGB(194, 124, 222) },
		{ Key = "Capital", Title = "Столица", Accent = Color3.fromRGB(116, 204, 112) },
	}

	for index, item in ipairs(trackerItems) do
		local row = Instance.new("Frame")
		row.BackgroundColor3 = Color3.fromRGB(26, 45, 52)
		row.BackgroundTransparency = 0.24
		row.BorderSizePixel = 0
		row.Position = UDim2.fromOffset(0, 42 + (index - 1) * 58)
		row.Size = UDim2.new(1, 0, 0, 48)
		row.ZIndex = 22
		row.Parent = leftTracker
		addCorner(row, 3)

		local marker = Instance.new("Frame")
		marker.BackgroundColor3 = item.Accent
		marker.BorderSizePixel = 0
		marker.Position = UDim2.fromOffset(8, 10)
		marker.Size = UDim2.fromOffset(7, 28)
		marker.ZIndex = 23
		marker.Parent = row
		addCorner(marker, 2)

		local title = makeHudText(row, item.Title, 12, Color3.fromRGB(185, 200, 198), Enum.Font.SourceSansBold)
		title.Position = UDim2.fromOffset(24, 5)
		title.Size = UDim2.new(1, -32, 0, 16)

		local value = makeHudText(row, "Ожидание данных", 15, Color3.fromRGB(244, 238, 219), Enum.Font.SourceSansSemibold)
		value.Position = UDim2.fromOffset(24, 23)
		value.Size = UDim2.new(1, -32, 0, 18)
		hudContext[item.Key] = value
	end

	local rightResources = makeHudPanel(mapHud, "ResourceLedger", UDim2.new(1, -250, 0, 78), UDim2.fromOffset(232, 354), 0.08)
	addPadding(rightResources, 14, 14, 12, 12)

	local ledgerTitle = makeHudText(rightResources, "РЕСУРСЫ МИРА", 14, Color3.fromRGB(236, 214, 156), Enum.Font.SourceSansBold)
	ledgerTitle.Size = UDim2.new(1, 0, 0, 18)

	local resourceRows = {
		{ Key = "Fish", Label = "Рыба", Color = Color3.fromRGB(137, 217, 246) },
		{ Key = "Pearls", Label = "Жемчуг", Color = Color3.fromRGB(242, 235, 214) },
		{ Key = "Wheat", Label = "Пшеница", Color = Color3.fromRGB(232, 202, 91) },
		{ Key = "Horses", Label = "Лошади", Color = Color3.fromRGB(170, 111, 66) },
		{ Key = "Furs", Label = "Меха", Color = Color3.fromRGB(152, 119, 90) },
		{ Key = "Deer", Label = "Олени", Color = Color3.fromRGB(184, 132, 76) },
		{ Key = "Salt", Label = "Соль", Color = Color3.fromRGB(236, 232, 203) },
		{ Key = "Dates", Label = "Финики", Color = Color3.fromRGB(158, 101, 44) },
	}

	for index, resource in ipairs(resourceRows) do
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Position = UDim2.fromOffset(0, 34 + (index - 1) * 35)
		row.Size = UDim2.new(1, 0, 0, 27)
		row.ZIndex = 22
		row.Parent = rightResources

		local swatch = Instance.new("Frame")
		swatch.BackgroundColor3 = resource.Color
		swatch.BorderSizePixel = 0
		swatch.Position = UDim2.fromOffset(0, 6)
		swatch.Size = UDim2.fromOffset(12, 12)
		swatch.ZIndex = 23
		swatch.Parent = row
		addCorner(swatch, 2)

		local label = makeHudText(row, resource.Label, 14, Color3.fromRGB(224, 229, 220), Enum.Font.SourceSansSemibold)
		label.Position = UDim2.fromOffset(20, 1)
		label.Size = UDim2.new(1, -70, 0, 22)

		local count = makeHudText(row, "0", 16, Color3.fromRGB(248, 238, 202), Enum.Font.SourceSansBold, Enum.TextXAlignment.Right)
		count.Position = UDim2.new(1, -54, 0, 0)
		count.Size = UDim2.fromOffset(54, 24)
		hudResourceRows[resource.Key] = count
	end

	local bottomSummary = makeHudPanel(mapHud, "MapSummary", UDim2.new(0, 18, 1, -154), UDim2.fromOffset(268, 136), 0.08)
	addPadding(bottomSummary, 14, 14, 12, 12)

	local summaryTitle = makeHudText(bottomSummary, "МИНИ-КАРТА", 14, Color3.fromRGB(236, 214, 156), Enum.Font.SourceSansBold)
	summaryTitle.Size = UDim2.new(1, 0, 0, 18)

	local terrainRows = {
		{ Key = "Water", Label = "Вода", Color = Color3.fromRGB(58, 133, 201) },
		{ Key = "Grass", Label = "Трава", Color = Color3.fromRGB(88, 163, 85) },
		{ Key = "Sand", Label = "Песок", Color = Color3.fromRGB(219, 196, 121) },
		{ Key = "Snow", Label = "Снег", Color = Color3.fromRGB(228, 240, 244) },
		{ Key = "Mountain", Label = "Горы", Color = Color3.fromRGB(72, 75, 78) },
	}

	for index, terrain in ipairs(terrainRows) do
		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Position = UDim2.fromOffset(0, 30 + (index - 1) * 20)
		row.Size = UDim2.new(1, 0, 0, 17)
		row.ZIndex = 22
		row.Parent = bottomSummary

		local label = makeHudText(row, terrain.Label, 11, Color3.fromRGB(204, 214, 211), Enum.Font.SourceSansBold)
		label.Size = UDim2.fromOffset(48, 17)

		local barBack = Instance.new("Frame")
		barBack.BackgroundColor3 = Color3.fromRGB(17, 30, 36)
		barBack.BorderSizePixel = 0
		barBack.Position = UDim2.fromOffset(58, 5)
		barBack.Size = UDim2.new(1, -100, 0, 7)
		barBack.ZIndex = 22
		barBack.Parent = row
		addCorner(barBack, 3)

		local bar = Instance.new("Frame")
		bar.BackgroundColor3 = terrain.Color
		bar.BorderSizePixel = 0
		bar.Size = UDim2.fromScale(0, 1)
		bar.ZIndex = 23
		bar.Parent = barBack
		addCorner(bar, 3)

		local value = makeHudText(row, "0%", 11, Color3.fromRGB(244, 238, 219), Enum.Font.SourceSansBold, Enum.TextXAlignment.Right)
		value.Position = UDim2.new(1, -34, 0, 0)
		value.Size = UDim2.fromOffset(34, 17)
		hudTerrainRows[terrain.Key] = {
			Bar = bar,
			Value = value,
		}
	end

	local cityPanel = makeHudPanel(mapHud, "CapitalPanel", UDim2.new(0.5, -222, 1, -112), UDim2.fromOffset(444, 94), 0.08)
	addPadding(cityPanel, 16, 16, 12, 12)

	local cityName = makeHudText(cityPanel, "Столица ожидает основания", 20, Color3.fromRGB(248, 238, 202), Enum.Font.Garamond, Enum.TextXAlignment.Center)
	cityName.Size = UDim2.new(1, 0, 0, 25)
	hudContext.CityName = cityName

	local cityDetails = makeHudText(cityPanel, "Поселенец готов к первому ходу", 14, Color3.fromRGB(195, 209, 206), Enum.Font.SourceSans, Enum.TextXAlignment.Center)
	cityDetails.Position = UDim2.fromOffset(0, 31)
	cityDetails.Size = UDim2.new(1, 0, 0, 18)
	hudContext.CityDetails = cityDetails

	local actionStrip = Instance.new("Frame")
	actionStrip.BackgroundTransparency = 1
	actionStrip.Position = UDim2.fromOffset(14, 58)
	actionStrip.Size = UDim2.new(1, -28, 0, 22)
	actionStrip.ZIndex = 22
	actionStrip.Parent = cityPanel

	local actionLayout = Instance.new("UIListLayout")
	actionLayout.FillDirection = Enum.FillDirection.Horizontal
	actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	actionLayout.Padding = UDim.new(0, 8)
	actionLayout.Parent = actionStrip

	local actionLabels = { "Основать", "Разведать", "Производство", "Технологии" }
	for index, labelText in ipairs(actionLabels) do
		local action = Instance.new("TextButton")
		action.AutoButtonColor = false
		action.BackgroundColor3 = Color3.fromRGB(33, 58, 65)
		action.BackgroundTransparency = 0.08
		action.BorderSizePixel = 0
		action.LayoutOrder = index
		action.Size = UDim2.fromOffset(86, 22)
		action.Text = labelText
		action.TextColor3 = Color3.fromRGB(232, 225, 205)
		action.TextSize = 12
		action.Font = Enum.Font.SourceSansBold
		action.ZIndex = 23
		action.Parent = actionStrip
		addCorner(action, 3)
		addStroke(action, Color3.fromRGB(196, 171, 104), 1, 0.48)
	end

	local nextTurnButton = makeButton(mapHud, "Следующий ход", 58, Color3.fromRGB(196, 171, 104))
	nextTurnButton.AnchorPoint = Vector2.new(1, 1)
	nextTurnButton.Position = UDim2.new(1, -18, 1, -18)
	nextTurnButton.Size = UDim2.fromOffset(166, 58)
	nextTurnButton.ZIndex = 22

	local function updateHudScale()
		local width = math.max(gui.AbsoluteSize.X, 1)
		resourceStrip.Visible = width >= 860
		resourceStripScale.Scale = math.clamp((width - 500) / 746, 0.58, 1)
		rightResources.Visible = width >= 900
		leftTracker.Visible = width >= 760
		bottomSummary.Visible = width >= 760
		cityPanel.Visible = width >= 760
	end

	local function setHudMetric(key, value, rate)
		local metric = hudMetrics[key]
		if not metric then
			return
		end

		metric.Value.Text = tostring(value)
		metric.Rate.Text = rate
	end

	local function updateHudTurnText()
		mapHudStats.Text = ("Ход %d | %s"):format(hudTurn, hudTurnSuffix)
	end

	local api = {
		Root = mapHud,
		MenuButton = mapMenuButton,
	}

	function api.SetVisible(isVisible)
		mapHud.Visible = isVisible
	end

	function api.Update(countryName, difficultyName, bots, mapConfig, renderInfo)
		local stats = renderInfo.Stats or {}
		local resources = renderInfo.Resources or {}
		local totalTiles = math.max(mapConfig.Width * mapConfig.Length, 1)
		local water = stats.Water or 0
		local grass = stats.Grass or 0
		local snow = stats.Snow or 0
		local mountains = stats.Mountain or 0
		local land = math.max(totalTiles - water, 1)
		local fish = resourceCount(resources, "Fish")
		local pearls = resourceCount(resources, "Pearls")
		local wheat = resourceCount(resources, "Wheat")
		local horses = resourceCount(resources, "Horses")
		local furs = resourceCount(resources, "Furs")
		local deer = resourceCount(resources, "Deer")
		local salt = resourceCount(resources, "Salt")
		local dates = resourceCount(resources, "Dates")
		local totalResources = renderInfo.TotalResources or 0

		hudTurn = 1
		hudTurnSuffix = ("%s | %dx%d | %s ботов"):format(difficultyName, mapConfig.Width, mapConfig.Length, bots)
		mapHudTitle.Text = countryName
		updateHudTurnText()

		local foodRate = 3 + math.floor(grass / 950) + wheat * 2 + fish + deer + dates
		local productionRate = 2 + math.floor(mountains / 700) + horses + deer + salt
		local goldRate = 5 + pearls * 4 + salt * 2 + dates * 2 + fish
		local scienceRate = 2 + math.floor(mountains / 1400) + pearls
		local cultureRate = 2 + math.floor(land / 36000) + furs + deer
		local faithRate = 1 + math.floor(snow / 1800) + dates
		local influenceRate = 1 + math.floor(tonumber(bots) or 0) + math.floor(totalResources / 12)

		setHudMetric("Science", 2, ("+%d"):format(scienceRate))
		setHudMetric("Culture", 1, ("+%d"):format(cultureRate))
		setHudMetric("Gold", 50 + goldRate * 2, ("+%d"):format(goldRate))
		setHudMetric("Faith", 0, ("+%d"):format(faithRate))
		setHudMetric("Food", math.max(8, foodRate), ("+%d"):format(foodRate))
		setHudMetric("Production", math.max(5, productionRate), ("+%d"):format(productionRate))
		setHudMetric("Influence", 0, ("+%d"):format(influenceRate))
		setHudMetric("Cities", 1, "+0")

		for key, label in pairs(hudResourceRows) do
			label.Text = tostring(resourceCount(resources, key))
		end

		for key, row in pairs(hudTerrainRows) do
			local ratio = math.clamp((stats[key] or 0) / totalTiles, 0, 1)
			row.Bar.Size = UDim2.fromScale(ratio, 1)
			row.Value.Text = ("%d%%"):format(math.floor(ratio * 100 + 0.5))
		end

		hudContext.Research.Text = ("Гончарство: %d ходов"):format(math.max(3, 8 - scienceRate))
		hudContext.Civic.Text = ("Свод законов: %d ходов"):format(math.max(4, 10 - cultureRate))
		hudContext.Capital.Text = ("Карта: %d ресурсных точек"):format(totalResources)
		hudContext.CityName.Text = countryName
		hudContext.CityDetails.Text = ("Столица: рост +%d, производство +%d, казна +%d"):format(foodRate, productionRate, goldRate)
	end

	nextTurnButton.MouseButton1Click:Connect(function()
		hudTurn += 1
		updateHudTurnText()
	end)

	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateHudScale)
	updateHudScale()

	return api
end

return GameHud
