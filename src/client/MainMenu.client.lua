local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "CivilisationMainMenu"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local colors = {
	background = Color3.fromRGB(21, 74, 124),
	panel = Color3.fromRGB(22, 92, 150),
	panelDeep = Color3.fromRGB(14, 68, 115),
	border = Color3.fromRGB(100, 221, 255),
	borderSoft = Color3.fromRGB(65, 174, 224),
	gold = Color3.fromRGB(194, 244, 255),
	goldSoft = Color3.fromRGB(119, 211, 248),
	ivory = Color3.fromRGB(235, 250, 255),
	muted = Color3.fromRGB(176, 225, 241),
	red = Color3.fromRGB(111, 180, 216),
	green = Color3.fromRGB(120, 238, 255),
	blue = Color3.fromRGB(39, 125, 190),
	cyan = Color3.fromRGB(103, 232, 255),
}

local activeTabName = nil
local tabs = {}
local tabButtons = {}

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or colors.goldSoft
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addPadding(parent, left, right, top, bottom)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.PaddingRight = UDim.new(0, right or left or 0)
	padding.PaddingTop = UDim.new(0, top or left or 0)
	padding.PaddingBottom = UDim.new(0, bottom or top or left or 0)
	padding.Parent = parent
	return padding
end

local function makeText(parent, text, size, color, font, alignment)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or colors.ivory
	label.TextSize = size or 18
	label.Font = font or Enum.Font.Garamond
	label.TextXAlignment = alignment or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function makeButton(parent, text, height, accentColor)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = false
	button.BackgroundColor3 = colors.panelDeep
	button.BorderSizePixel = 0
	button.Size = UDim2.new(1, 0, 0, height or 46)
	button.Text = text
	button.TextColor3 = colors.ivory
	button.TextSize = 19
	button.Font = Enum.Font.Garamond
	button.Parent = parent
	addCorner(button, 4)
	addStroke(button, accentColor or colors.border, 1, 0.08)

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 145, 213)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(24, 103, 173)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 70, 126)),
	})
	gradient.Rotation = 90
	gradient.Parent = button

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = Color3.fromRGB(42, 146, 210),
			TextColor3 = colors.cyan,
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		if tabButtons[activeTabName] ~= button then
			TweenService:Create(button, TweenInfo.new(0.12), {
				BackgroundColor3 = colors.panelDeep,
				TextColor3 = colors.ivory,
			}):Play()
		end
	end)

	return button
end

local function makeField(parent, labelText, placeholderText, wrapperHeight, boxHeight)
	local wrapper = Instance.new("Frame")
	wrapper.BackgroundTransparency = 1
	wrapper.Size = UDim2.new(1, 0, 0, wrapperHeight or 72)
	wrapper.Parent = parent

	local label = makeText(wrapper, labelText, 15, colors.muted, Enum.Font.SourceSansSemibold)
	label.Size = UDim2.new(1, 0, 0, 22)

	local box = Instance.new("TextBox")
	box.BackgroundColor3 = Color3.fromRGB(18, 83, 139)
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.PlaceholderText = placeholderText or ""
	box.PlaceholderColor3 = Color3.fromRGB(181, 224, 239)
	box.Text = ""
	box.TextColor3 = colors.ivory
	box.TextSize = 17
	box.Font = Enum.Font.SourceSans
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Position = UDim2.new(0, 0, 0, 28)
	box.Size = UDim2.new(1, 0, 0, boxHeight or 40)
	box.Parent = wrapper
	addCorner(box, 4)
	addStroke(box, colors.borderSoft, 1, 0.35)
	addPadding(box, 12, 12, 0, 0)

	return box
end

local function makeSelect(parent, labelText, options, defaultIndex)
	local index = defaultIndex or 1
	local wrapper = Instance.new("Frame")
	wrapper.BackgroundTransparency = 1
	wrapper.Size = UDim2.new(1, 0, 0, 72)
	wrapper.Parent = parent

	local label = makeText(wrapper, labelText, 15, colors.muted, Enum.Font.SourceSansSemibold)
	label.Size = UDim2.new(1, 0, 0, 22)

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.new(0, 0, 0, 28)
	row.Size = UDim2.new(1, 0, 0, 40)
	row.Parent = wrapper

	local previous = makeButton(row, "<", 40, colors.borderSoft)
	previous.Size = UDim2.new(0, 44, 1, 0)
	previous.Font = Enum.Font.SourceSansBold

	local value = makeText(row, options[index], 17, colors.ivory, Enum.Font.SourceSans, Enum.TextXAlignment.Center)
	value.BackgroundColor3 = Color3.fromRGB(18, 83, 139)
	value.BackgroundTransparency = 0
	value.BorderSizePixel = 0
	value.Position = UDim2.new(0, 52, 0, 0)
	value.Size = UDim2.new(1, -104, 1, 0)
	addCorner(value, 4)
	addStroke(value, colors.borderSoft, 1, 0.35)

	local nextButton = makeButton(row, ">", 40, colors.borderSoft)
	nextButton.Font = Enum.Font.SourceSansBold
	nextButton.Position = UDim2.new(1, -44, 0, 0)
	nextButton.Size = UDim2.new(0, 44, 1, 0)

	local function update(delta)
		index += delta
		if index < 1 then
			index = #options
		elseif index > #options then
			index = 1
		end
		value.Text = options[index]
	end

	previous.MouseButton1Click:Connect(function()
		update(-1)
	end)

	nextButton.MouseButton1Click:Connect(function()
		update(1)
	end)

	return {
		GetValue = function()
			return options[index]
		end,
		SetValue = function(newValue)
			for optionIndex, option in ipairs(options) do
				if option == newValue then
					index = optionIndex
					value.Text = option
					return
				end
			end
		end,
	}
end

local function makePanel(parent, name)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.BackgroundColor3 = colors.panel
	panel.BorderSizePixel = 0
	panel.Size = UDim2.new(1, 0, 1, 0)
	panel.Visible = false
	panel.Parent = parent
	addCorner(panel, 6)
	addStroke(panel, colors.border, 1, 0.15)
	addPadding(panel, 24, 24, 22, 22)

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 129, 198)),
		ColorSequenceKeypoint.new(0.56, Color3.fromRGB(20, 87, 149)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 68, 118)),
	})
	gradient.Rotation = 90
	gradient.Parent = panel

	tabs[name] = panel
	return panel
end

local background = Instance.new("Frame")
background.Name = "Background"
background.BackgroundColor3 = colors.background
background.BorderSizePixel = 0
background.Size = UDim2.fromScale(1, 1)
background.Parent = gui

local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(33, 119, 184)),
	ColorSequenceKeypoint.new(0.48, Color3.fromRGB(49, 166, 226)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 82, 145)),
})
bgGradient.Rotation = 30
bgGradient.Parent = background

for i = 1, 22 do
	local line = Instance.new("Frame")
	line.BackgroundColor3 = i % 3 == 0 and colors.cyan or Color3.fromRGB(122, 214, 246)
	line.BackgroundTransparency = i % 3 == 0 and 0.68 or 0.82
	line.BorderSizePixel = 0
	line.Position = UDim2.new((i * 0.07) % 1, 0, -0.1, 0)
	line.Rotation = -26 + (i % 5) * 4
	line.Size = UDim2.new(0, 1, 1.35, 0)
	line.Parent = background
end

local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundTransparency = 1
main.Position = UDim2.fromScale(0.5, 0.5)
main.Size = UDim2.fromOffset(1180, 720)
main.Parent = gui

local mainScale = Instance.new("UIScale")
mainScale.Parent = main
local cameraViewportConnection

local function updateMainScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local viewport = camera.ViewportSize
	mainScale.Scale = math.min(viewport.X * 0.94 / 1180, viewport.Y * 0.9 / 720, 1)
end

local function connectCameraScale()
	if cameraViewportConnection then
		cameraViewportConnection:Disconnect()
		cameraViewportConnection = nil
	end

	updateMainScale()

	if workspace.CurrentCamera then
		cameraViewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateMainScale)
	end
end

connectCameraScale()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(connectCameraScale)

local titleBlock = Instance.new("Frame")
titleBlock.BackgroundTransparency = 1
titleBlock.AnchorPoint = Vector2.new(0.5, 0)
titleBlock.Position = UDim2.new(0.5, 0, 0, 34)
titleBlock.Size = UDim2.new(0, 420, 0, 128)
titleBlock.Parent = main

local title = makeText(titleBlock, "THE BIRTH\nOF CIVILISATIONS", 35, colors.gold, Enum.Font.Garamond, Enum.TextXAlignment.Center)
title.Size = UDim2.new(1, 0, 0, 86)
title.TextYAlignment = Enum.TextYAlignment.Top

local subtitle = makeText(titleBlock, "A STRATEGY EXPERIENCE", 14, colors.cyan, Enum.Font.SourceSansSemibold, Enum.TextXAlignment.Center)
subtitle.Position = UDim2.new(0, 0, 0, 88)
subtitle.Size = UDim2.new(1, 0, 0, 20)

local menuColumn = Instance.new("Frame")
menuColumn.Name = "MenuColumn"
menuColumn.AnchorPoint = Vector2.new(0.5, 0.5)
menuColumn.BackgroundColor3 = Color3.fromRGB(22, 91, 150)
menuColumn.BorderSizePixel = 0
menuColumn.Position = UDim2.new(0.5, 0, 0.58, 0)
menuColumn.Size = UDim2.new(0, 330, 0, 344)
menuColumn.Parent = main
addCorner(menuColumn, 6)
addStroke(menuColumn, colors.border, 1, 0.18)
addPadding(menuColumn, 16, 16, 16, 16)

local menuLayout = Instance.new("UIListLayout")
menuLayout.Padding = UDim.new(0, 10)
menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
menuLayout.Parent = menuColumn

local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 0, 0, 0)
content.Size = UDim2.new(1, 0, 1, 0)
content.Visible = false
content.Parent = main

local footer = makeText(main, "Version 0.1", 13, colors.muted, Enum.Font.SourceSans, Enum.TextXAlignment.Center)
footer.AnchorPoint = Vector2.new(0, 1)
footer.Position = UDim2.new(0, 0, 1, 0)
footer.Size = UDim2.new(1, 0, 0, 22)

local loadingOverlay = Instance.new("Frame")
loadingOverlay.Name = "MapLoadingOverlay"
loadingOverlay.BackgroundColor3 = Color3.fromRGB(26, 114, 180)
loadingOverlay.BackgroundTransparency = 1
loadingOverlay.BorderSizePixel = 0
loadingOverlay.Size = UDim2.fromScale(1, 1)
loadingOverlay.Visible = false
loadingOverlay.ZIndex = 50
loadingOverlay.Parent = gui

local loadingGradient = Instance.new("UIGradient")
loadingGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(49, 173, 230)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 118, 186)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 88, 154)),
})
loadingGradient.Rotation = 90
loadingGradient.Parent = loadingOverlay

for i = 1, 16 do
	local ray = Instance.new("Frame")
	ray.BackgroundColor3 = i % 2 == 0 and colors.cyan or Color3.fromRGB(170, 236, 255)
	ray.BackgroundTransparency = 0.9
	ray.BorderSizePixel = 0
	ray.Position = UDim2.new((i * 0.09) % 1, 0, -0.18, 0)
	ray.Rotation = -18 + (i % 4) * 8
	ray.Size = UDim2.new(0, 2, 1.35, 0)
	ray.ZIndex = 51
	ray.Parent = loadingOverlay
end

local loadingTitle = makeText(loadingOverlay, "ЗАГРУЗКА КАРТЫ", 42, colors.ivory, Enum.Font.Garamond, Enum.TextXAlignment.Center)
loadingTitle.AnchorPoint = Vector2.new(0.5, 0.5)
loadingTitle.Position = UDim2.fromScale(0.5, 0.42)
loadingTitle.Size = UDim2.new(0, 620, 0, 56)
loadingTitle.TextTransparency = 1
loadingTitle.ZIndex = 52

local loadingSubtitle = makeText(loadingOverlay, "Создаём мир для новой цивилизации", 18, colors.muted, Enum.Font.SourceSansSemibold, Enum.TextXAlignment.Center)
loadingSubtitle.AnchorPoint = Vector2.new(0.5, 0.5)
loadingSubtitle.Position = UDim2.fromScale(0.5, 0.49)
loadingSubtitle.Size = UDim2.new(0, 620, 0, 28)
loadingSubtitle.TextTransparency = 1
loadingSubtitle.ZIndex = 52

local loadingStatus = makeText(loadingOverlay, "", 16, colors.ivory, Enum.Font.SourceSans, Enum.TextXAlignment.Center)
loadingStatus.AnchorPoint = Vector2.new(0.5, 0.5)
loadingStatus.Position = UDim2.fromScale(0.5, 0.56)
loadingStatus.Size = UDim2.new(0, 680, 0, 28)
loadingStatus.TextTransparency = 1
loadingStatus.ZIndex = 52

local progressBack = Instance.new("Frame")
progressBack.AnchorPoint = Vector2.new(0.5, 1)
progressBack.BackgroundColor3 = Color3.fromRGB(33, 132, 203)
progressBack.BackgroundTransparency = 1
progressBack.BorderSizePixel = 0
progressBack.Position = UDim2.new(0.5, 0, 1, -64)
progressBack.Size = UDim2.new(0.62, 0, 0, 14)
progressBack.ZIndex = 52
progressBack.Parent = loadingOverlay
addCorner(progressBack, 6)
addStroke(progressBack, colors.border, 1, 0.4)

local progressFill = Instance.new("Frame")
progressFill.BackgroundColor3 = colors.cyan
progressFill.BackgroundTransparency = 1
progressFill.BorderSizePixel = 0
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.ZIndex = 53
progressFill.Parent = progressBack
addCorner(progressFill, 6)

local loadingPercent = makeText(loadingOverlay, "0%", 15, colors.ivory, Enum.Font.SourceSansBold, Enum.TextXAlignment.Center)
loadingPercent.AnchorPoint = Vector2.new(0.5, 1)
loadingPercent.Position = UDim2.new(0.5, 0, 1, -82)
loadingPercent.Size = UDim2.new(0, 120, 0, 22)
loadingPercent.TextTransparency = 1
loadingPercent.ZIndex = 52

local loadingInProgress = false
local loadingStages = {
	{ progress = 0.18, text = "Прокладываем береговые линии..." },
	{ progress = 0.36, text = "Расставляем реки и горные хребты..." },
	{ progress = 0.58, text = "Подготавливаем стартовые позиции..." },
	{ progress = 0.79, text = "Проверяем параметры цивилизации..." },
	{ progress = 1, text = "Карта готова." },
}

local function tween(instance, time, properties, easingStyle, easingDirection)
	local info = TweenInfo.new(time, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out)
	local tweenObject = TweenService:Create(instance, info, properties)
	tweenObject:Play()
	return tweenObject
end

local function showLoadingScreen(countryName, difficultyName, seed, bots)
	if loadingInProgress then
		return
	end

	loadingInProgress = true
	loadingOverlay.Visible = true
	loadingOverlay.BackgroundTransparency = 1
	loadingTitle.TextTransparency = 1
	loadingSubtitle.TextTransparency = 1
	loadingStatus.TextTransparency = 1
	loadingPercent.TextTransparency = 1
	progressBack.BackgroundTransparency = 1
	progressFill.BackgroundTransparency = 1
	progressFill.Size = UDim2.fromScale(0, 1)
	loadingPercent.Text = "0%"
	loadingStatus.Text = ("Страна: %s | Сложность: %s | Сид: %s | Боты: %s"):format(countryName, difficultyName, seed, bots)

	task.spawn(function()
		tween(loadingOverlay, 0.35, { BackgroundTransparency = 0.02 })
		tween(loadingTitle, 0.35, { TextTransparency = 0 })
		tween(loadingSubtitle, 0.45, { TextTransparency = 0.05 })
		tween(loadingStatus, 0.45, { TextTransparency = 0.08 })
		tween(loadingPercent, 0.45, { TextTransparency = 0.05 })
		tween(progressBack, 0.45, { BackgroundTransparency = 0.08 })
		tween(progressFill, 0.45, { BackgroundTransparency = 0 })
		task.wait(0.45)

		for _, stage in ipairs(loadingStages) do
			loadingStatus.Text = stage.text
			loadingPercent.Text = tostring(math.floor(stage.progress * 100)) .. "%"
			tween(progressFill, 0.55, { Size = UDim2.fromScale(stage.progress, 1) }, Enum.EasingStyle.Sine)
			task.wait(0.72)
		end

		task.wait(0.35)
		tween(loadingTitle, 0.35, { TextTransparency = 1 })
		tween(loadingSubtitle, 0.35, { TextTransparency = 1 })
		tween(loadingStatus, 0.35, { TextTransparency = 1 })
		tween(loadingPercent, 0.35, { TextTransparency = 1 })
		tween(progressBack, 0.35, { BackgroundTransparency = 1 })
		tween(progressFill, 0.35, { BackgroundTransparency = 1 })
		tween(loadingOverlay, 0.45, { BackgroundTransparency = 1 })
		task.wait(0.45)

		loadingOverlay.Visible = false
		loadingInProgress = false
	end)
end

local function showMainMenu()
	activeTabName = nil
	content.Visible = false
	menuColumn.Visible = true
	titleBlock.Visible = true
	footer.Visible = true

	for _, panel in pairs(tabs) do
		panel.Visible = false
	end

	for _, button in pairs(tabButtons) do
		button.TextColor3 = colors.ivory
		button.BackgroundColor3 = colors.panelDeep
	end
end

local function setActiveTab(tabName)
	activeTabName = tabName
	content.Visible = true
	menuColumn.Visible = false
	titleBlock.Visible = false
	footer.Visible = false

	for name, panel in pairs(tabs) do
		panel.Visible = name == tabName
		panel.BackgroundTransparency = name == tabName and 0 or 1
	end

	for name, button in pairs(tabButtons) do
		local selected = name == tabName
		button.TextColor3 = selected and colors.cyan or colors.ivory
		button.BackgroundColor3 = selected and Color3.fromRGB(40, 143, 210) or colors.panelDeep
	end
end

local function makeHeader(parent, heading, body)
	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, body and 80 or 48)
	header.Parent = parent

	local h = makeText(header, heading, 27, colors.gold, Enum.Font.Garamond)
	h.Size = UDim2.new(1, -120, 0, 34)

	local backButton = makeButton(header, "Назад", 38, colors.border)
	backButton.Position = UDim2.new(1, -106, 0, 0)
	backButton.Size = UDim2.new(0, 106, 0, 38)
	backButton.MouseButton1Click:Connect(showMainMenu)

	if body then
		local b = makeText(header, body, 16, colors.muted, Enum.Font.SourceSans)
		b.Position = UDim2.new(0, 0, 0, 38)
		b.Size = UDim2.new(1, 0, 0, 40)
	end

	return header
end

local function makeSection(parent, titleText)
	local section = Instance.new("Frame")
	section.BackgroundColor3 = Color3.fromRGB(20, 88, 146)
	section.BorderSizePixel = 0
	section.Size = UDim2.new(1, 0, 0, 150)
	section.Parent = parent
	addCorner(section, 6)
	addStroke(section, colors.borderSoft, 1, 0.35)
	addPadding(section, 16, 16, 14, 14)

	local label = makeText(section, titleText, 20, colors.gold, Enum.Font.Garamond)
	label.Size = UDim2.new(1, 0, 0, 26)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = section

	return section
end

local function makeToggle(parent, text, defaultEnabled)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = false
	button.BackgroundColor3 = Color3.fromRGB(21, 89, 148)
	button.BorderSizePixel = 0
	button.Size = UDim2.new(1, 0, 0, 34)
	button.Text = ""
	button.Parent = parent
	addCorner(button, 4)
	addStroke(button, colors.borderSoft, 1, 0.5)

	local enabled = defaultEnabled
	local mark = makeText(button, enabled and "ON" or "OFF", 13, enabled and colors.green or colors.red, Enum.Font.SourceSansBold, Enum.TextXAlignment.Center)
	mark.Position = UDim2.new(0, 8, 0, 0)
	mark.Size = UDim2.new(0, 46, 1, 0)

	local label = makeText(button, text, 15, colors.ivory, Enum.Font.SourceSans)
	label.Position = UDim2.new(0, 64, 0, 0)
	label.Size = UDim2.new(1, -72, 1, 0)

	local function render()
		mark.Text = enabled and "ON" or "OFF"
		mark.TextColor3 = enabled and colors.green or colors.red
	end

	button.MouseButton1Click:Connect(function()
		enabled = not enabled
		render()
	end)

	return button
end

local function makeSlider(parent, text, value)
	local wrapper = Instance.new("Frame")
	wrapper.BackgroundTransparency = 1
	wrapper.Size = UDim2.new(1, 0, 0, 42)
	wrapper.Parent = parent

	local label = makeText(wrapper, text, 15, colors.ivory, Enum.Font.SourceSans)
	label.Size = UDim2.new(0.45, 0, 1, 0)

	local track = Instance.new("Frame")
	track.BackgroundColor3 = Color3.fromRGB(18, 75, 128)
	track.BorderSizePixel = 0
	track.Position = UDim2.new(0.48, 0, 0.5, -4)
	track.Size = UDim2.new(0.38, 0, 0, 8)
	track.Parent = wrapper
	addCorner(track, 3)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = colors.cyan
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(math.clamp(value, 0, 1), 0, 1, 0)
	fill.Parent = track
	addCorner(fill, 3)

	local amount = makeText(wrapper, tostring(math.floor(value * 100)), 14, colors.muted, Enum.Font.SourceSansBold, Enum.TextXAlignment.Right)
	amount.Position = UDim2.new(0.88, 0, 0, 0)
	amount.Size = UDim2.new(0.12, 0, 1, 0)

	return wrapper
end

local singleplayer = makePanel(content, "Singleplayer")
local singleLayout = Instance.new("UIListLayout")
singleLayout.Padding = UDim.new(0, 14)
singleLayout.SortOrder = Enum.SortOrder.LayoutOrder
singleLayout.Parent = singleplayer
makeHeader(singleplayer, "Синглплеер", "Создай цивилизацию, выбери параметры мира и подготовь будущую партию.")

local singleGrid = Instance.new("Frame")
singleGrid.BackgroundTransparency = 1
singleGrid.Size = UDim2.new(1, 0, 0, 324)
singleGrid.Parent = singleplayer

local singleLeft = Instance.new("Frame")
singleLeft.BackgroundTransparency = 1
singleLeft.Size = UDim2.new(0.5, -10, 1, 0)
singleLeft.Parent = singleGrid

local singleLeftLayout = Instance.new("UIListLayout")
singleLeftLayout.Padding = UDim.new(0, 12)
singleLeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
singleLeftLayout.Parent = singleLeft

local countryName = makeField(singleLeft, "Название страны", "Например: Новая Атлантида")
local mapSeed = makeField(singleLeft, "Сид карты", "Случайный или свой сид")
local difficulty = makeSelect(singleLeft, "Сложность", {
	"Поселенец",
	"Вождь",
	"Военачальник",
	"Князь",
	"Король",
	"Император",
	"Бессмертный",
	"Божество",
}, 4)
local botCount = makeSelect(singleLeft, "Количество ботов", { "3", "4", "5", "6", "7", "8", "10", "12" }, 1)

local singleRight = Instance.new("Frame")
singleRight.BackgroundColor3 = Color3.fromRGB(20, 88, 146)
singleRight.BorderSizePixel = 0
singleRight.Position = UDim2.new(0.5, 10, 0, 0)
singleRight.Size = UDim2.new(0.5, -10, 1, 0)
singleRight.Parent = singleGrid
addCorner(singleRight, 6)
addStroke(singleRight, colors.borderSoft, 1, 0.35)
addPadding(singleRight, 16, 16, 16, 16)

local previewTitle = makeText(singleRight, "Готовность партии", 22, colors.gold, Enum.Font.Garamond)
previewTitle.Size = UDim2.new(1, 0, 0, 28)

local previewText = makeText(singleRight, "Пока мир и ИИ будут добавлены позже, эта вкладка уже собирает все стартовые параметры будущей партии.", 17, colors.muted, Enum.Font.SourceSans)
previewText.Position = UDim2.new(0, 0, 0, 42)
previewText.Size = UDim2.new(1, 0, 0, 90)
previewText.TextYAlignment = Enum.TextYAlignment.Top

local saveCountryButton = makeButton(singleRight, "Сохранить страну", 46, colors.gold)
saveCountryButton.Position = UDim2.new(0, 0, 1, -100)
saveCountryButton.Size = UDim2.new(1, 0, 0, 46)

local startGameButton = makeButton(singleRight, "Начать игру", 46, colors.cyan)
startGameButton.Position = UDim2.new(0, 0, 1, -46)
startGameButton.Size = UDim2.new(1, 0, 0, 46)

local singleStatus = makeText(singleplayer, "", 16, colors.green, Enum.Font.SourceSansSemibold)
singleStatus.Size = UDim2.new(1, 0, 0, 28)
singleStatus.TextTransparency = 1

local function readSingleplayerSetup()
	local name = countryName.Text
	if name == "" then
		name = "Безымянная цивилизация"
	end

	local seed = mapSeed.Text
	if seed == "" then
		seed = tostring(math.random(100000, 999999))
		mapSeed.Text = seed
	end

	return name, seed
end

saveCountryButton.MouseButton1Click:Connect(function()
	local name, seed = readSingleplayerSetup()
	singleStatus.Text = ("Страна \"%s\" сохранена. Сложность: %s, сид: %s, боты: %s."):format(name, difficulty.GetValue(), seed, botCount.GetValue())
	singleStatus.TextTransparency = 0
end)

startGameButton.MouseButton1Click:Connect(function()
	local name, seed = readSingleplayerSetup()
	singleStatus.Text = ("Запуск партии: %s | %s | сид %s | боты: %s."):format(name, difficulty.GetValue(), seed, botCount.GetValue())
	singleStatus.TextTransparency = 0
	showLoadingScreen(name, difficulty.GetValue(), seed, botCount.GetValue())
end)

local multiplayer = makePanel(content, "Multiplayer")
local multiLayout = Instance.new("UIListLayout")
multiLayout.Padding = UDim.new(0, 14)
multiLayout.SortOrder = Enum.SortOrder.LayoutOrder
multiLayout.Parent = multiplayer
makeHeader(multiplayer, "Мультиплеер", "Поиск серверов, фильтры и подготовка лобби для будущей сетевой игры.")

local multiTop = Instance.new("Frame")
multiTop.BackgroundTransparency = 1
multiTop.Size = UDim2.new(1, 0, 0, 170)
multiTop.Parent = multiplayer

local filters = Instance.new("Frame")
filters.BackgroundColor3 = Color3.fromRGB(20, 88, 146)
filters.BorderSizePixel = 0
filters.Size = UDim2.new(1, -180, 1, 0)
filters.Parent = multiTop
addCorner(filters, 6)
addStroke(filters, colors.borderSoft, 1, 0.35)
addPadding(filters, 14, 14, 12, 12)

local filterTitle = makeText(filters, "Фильтры серверов", 20, colors.gold, Enum.Font.Garamond)
filterTitle.Size = UDim2.new(1, 0, 0, 24)

local filterGrid = Instance.new("Frame")
filterGrid.BackgroundTransparency = 1
filterGrid.Position = UDim2.new(0, 0, 0, 32)
filterGrid.Size = UDim2.new(1, 0, 1, -32)
filterGrid.Parent = filters

local filterLeft = Instance.new("Frame")
filterLeft.BackgroundTransparency = 1
filterLeft.Size = UDim2.new(0.5, -8, 1, 0)
filterLeft.Parent = filterGrid
local filterLeftLayout = Instance.new("UIListLayout")
filterLeftLayout.Padding = UDim.new(0, 8)
filterLeftLayout.Parent = filterLeft
makeField(filterLeft, "Название", "Поиск по названию", 58, 30)
makeField(filterLeft, "Пароль", "Любой / есть / нет", 58, 30)

local filterRight = Instance.new("Frame")
filterRight.BackgroundTransparency = 1
filterRight.Position = UDim2.new(0.5, 8, 0, 0)
filterRight.Size = UDim2.new(0.5, -8, 1, 0)
filterRight.Parent = filterGrid
local filterRightLayout = Instance.new("UIListLayout")
filterRightLayout.Padding = UDim.new(0, 8)
filterRightLayout.Parent = filterRight
makeField(filterRight, "Количество ботов", "От 3 до 12", 58, 30)
makeSelect(filterRight, "Боты", { "Не важно", "Есть боты", "Без ботов" }, 1)

local multiActions = Instance.new("Frame")
multiActions.BackgroundTransparency = 1
multiActions.Position = UDim2.new(1, -160, 0, 0)
multiActions.Size = UDim2.new(0, 160, 1, 0)
multiActions.Parent = multiTop
local multiActionLayout = Instance.new("UIListLayout")
multiActionLayout.Padding = UDim.new(0, 10)
multiActionLayout.Parent = multiActions
local refreshButton = makeButton(multiActions, "Обновить", 48, colors.border)
local createServerButton = makeButton(multiActions, "Создать сервер", 48, colors.gold)

local serverList = Instance.new("Frame")
serverList.BackgroundColor3 = Color3.fromRGB(17, 78, 135)
serverList.BorderSizePixel = 0
serverList.Size = UDim2.new(1, 0, 1, -264)
serverList.Parent = multiplayer
addCorner(serverList, 6)
addStroke(serverList, colors.borderSoft, 1, 0.42)
addPadding(serverList, 22, 22, 22, 22)

local serverEmptyTitle = makeText(serverList, "Список серверов пуст", 24, colors.cyan, Enum.Font.Garamond, Enum.TextXAlignment.Center)
serverEmptyTitle.Position = UDim2.new(0, 0, 0.5, -36)
serverEmptyTitle.Size = UDim2.new(1, 0, 0, 30)

local serverEmptyBody = makeText(serverList, "Настоящие лобби появятся здесь после подключения серверной логики.", 16, colors.muted, Enum.Font.SourceSans, Enum.TextXAlignment.Center)
serverEmptyBody.Position = UDim2.new(0.1, 0, 0.5, 0)
serverEmptyBody.Size = UDim2.new(0.8, 0, 0, 42)

refreshButton.MouseButton1Click:Connect(function()
	serverEmptyBody.Text = "Список обновлен. Пока серверная логика не подключена, лобби не отображаются."
end)
createServerButton.MouseButton1Click:Connect(function()
	serverEmptyBody.Text = "Создание сервера будет подключено на следующем этапе мультиплеера."
end)

local settings = makePanel(content, "Settings")
local settingsLayout = Instance.new("UIListLayout")
settingsLayout.Padding = UDim.new(0, 14)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Parent = settings
makeHeader(settings, "Настройки", "Звук, графика, управление, интерфейс и комфорт будущей стратегии.")

local settingsScroll = Instance.new("ScrollingFrame")
settingsScroll.BackgroundTransparency = 1
settingsScroll.BorderSizePixel = 0
settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 760)
settingsScroll.ScrollBarThickness = 6
settingsScroll.Size = UDim2.new(1, 0, 1, -94)
settingsScroll.Parent = settings

local settingsGrid = Instance.new("UIGridLayout")
settingsGrid.CellPadding = UDim2.new(0, 14, 0, 14)
settingsGrid.CellSize = UDim2.new(0.5, -10, 0, 252)
settingsGrid.SortOrder = Enum.SortOrder.LayoutOrder
settingsGrid.Parent = settingsScroll
settingsGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	settingsScroll.CanvasSize = UDim2.fromOffset(0, settingsGrid.AbsoluteContentSize.Y + 24)
end)

local audio = makeSection(settingsScroll, "Звук")
makeSlider(audio, "Общая громкость", 0.8)
makeSlider(audio, "Музыка", 0.65)
makeSlider(audio, "Эффекты", 0.76)
makeToggle(audio, "Приглушать звук в фоне", true)

local graphics = makeSection(settingsScroll, "Графика")
makeSelect(graphics, "Качество", { "Низкое", "Среднее", "Высокое", "Ультра" }, 3)
makeToggle(graphics, "Тени на карте", true)
makeToggle(graphics, "Анимации интерфейса", true)

local controls = makeSection(settingsScroll, "Управление")
makeSelect(controls, "Скорость камеры", { "Медленно", "Нормально", "Быстро", "Очень быстро" }, 2)
makeToggle(controls, "Инвертировать вращение", false)
makeToggle(controls, "Перемещение WASD", true)

local interface = makeSection(settingsScroll, "Интерфейс")
makeSelect(interface, "Размер интерфейса", { "Компактный", "Обычный", "Крупный" }, 2)
makeToggle(interface, "Подсказки советника", true)
makeToggle(interface, "Показывать сетку тайлов", true)

local gameplay = makeSection(settingsScroll, "Игровой процесс")
makeToggle(gameplay, "Быстрые ходы", false)
makeToggle(gameplay, "Автосохранение", true)
makeSelect(gameplay, "Частота автосохранения", { "Каждые 5 ходов", "Каждые 10 ходов", "Каждые 25 ходов" }, 2)

local accessibility = makeSection(settingsScroll, "Доступность")
makeToggle(accessibility, "Высокий контраст", false)
makeToggle(accessibility, "Крупные всплывающие подсказки", true)
makeSelect(accessibility, "Цветовая схема", { "Классическая", "Теплая", "Холодная", "Контрастная" }, 1)

local inventory = makePanel(content, "Inventory")
local inventoryLayout = Instance.new("UIListLayout")
inventoryLayout.Padding = UDim.new(0, 14)
inventoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
inventoryLayout.Parent = inventory
makeHeader(inventory, "Инвентарь", "Прокачка классов юнитов, косметика и будущие коллекции.")

local invGrid = Instance.new("Frame")
invGrid.BackgroundColor3 = Color3.fromRGB(17, 78, 135)
invGrid.BorderSizePixel = 0
invGrid.Size = UDim2.new(1, 0, 1, -94)
invGrid.Parent = inventory
addCorner(invGrid, 6)
addStroke(invGrid, colors.borderSoft, 1, 0.42)
addPadding(invGrid, 22, 22, 22, 22)

local inventoryEmptyTitle = makeText(invGrid, "Инвентарь пуст", 24, colors.cyan, Enum.Font.Garamond, Enum.TextXAlignment.Center)
inventoryEmptyTitle.Position = UDim2.new(0, 0, 0.5, -36)
inventoryEmptyTitle.Size = UDim2.new(1, 0, 0, 30)

local inventoryEmptyBody = makeText(invGrid, "Классы юнитов, прокачка и скины появятся здесь после добавления системы юнитов.", 16, colors.muted, Enum.Font.SourceSans, Enum.TextXAlignment.Center)
inventoryEmptyBody.Position = UDim2.new(0.12, 0, 0.5, 0)
inventoryEmptyBody.Size = UDim2.new(0.76, 0, 0, 42)

local shop = makePanel(content, "Shop")
local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 14)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shop
makeHeader(shop, "Магазин", "Скины за внутриигровую валюту и будущие покупки валюты за Robux.")

local currencyBar = Instance.new("Frame")
currencyBar.BackgroundColor3 = Color3.fromRGB(20, 88, 146)
currencyBar.BorderSizePixel = 0
currencyBar.Size = UDim2.new(1, 0, 0, 58)
currencyBar.Parent = shop
addCorner(currencyBar, 6)
addStroke(currencyBar, colors.border, 1, 0.24)
addPadding(currencyBar, 16, 16, 8, 8)

local coins = makeText(currencyBar, "Казна: 1 250 монет", 21, colors.gold, Enum.Font.Garamond)
coins.Size = UDim2.new(0.5, 0, 1, 0)

local buyCurrency = makeButton(currencyBar, "Купить монеты за Robux", 42, colors.cyan)
buyCurrency.Position = UDim2.new(1, -220, 0, 0)
buyCurrency.Size = UDim2.new(0, 220, 0, 42)

local shopGrid = Instance.new("Frame")
shopGrid.BackgroundColor3 = Color3.fromRGB(17, 78, 135)
shopGrid.BorderSizePixel = 0
shopGrid.Size = UDim2.new(1, 0, 1, -166)
shopGrid.Parent = shop
addCorner(shopGrid, 6)
addStroke(shopGrid, colors.borderSoft, 1, 0.42)
addPadding(shopGrid, 22, 22, 22, 22)

local shopEmptyTitle = makeText(shopGrid, "Магазин пуст", 24, colors.cyan, Enum.Font.Garamond, Enum.TextXAlignment.Center)
shopEmptyTitle.Position = UDim2.new(0, 0, 0.5, -36)
shopEmptyTitle.Size = UDim2.new(1, 0, 0, 30)

local shopEmptyBody = makeText(shopGrid, "Скины, товары и покупки валюты будут добавлены после настройки экономики и Developer Products.", 16, colors.muted, Enum.Font.SourceSans, Enum.TextXAlignment.Center)
shopEmptyBody.Position = UDim2.new(0.12, 0, 0.5, 0)
shopEmptyBody.Size = UDim2.new(0.76, 0, 0, 42)

local menuItems = {
	{ key = "Singleplayer", label = "Синглплеер" },
	{ key = "Multiplayer", label = "Мультиплеер" },
	{ key = "Settings", label = "Настройки" },
	{ key = "Inventory", label = "Инвентарь" },
	{ key = "Shop", label = "Магазин" },
}

for order, item in ipairs(menuItems) do
	local button = makeButton(menuColumn, item.label, 52, order == 1 and colors.gold or colors.border)
	button.LayoutOrder = order
	tabButtons[item.key] = button
	button.MouseButton1Click:Connect(function()
		setActiveTab(item.key)
	end)
end

showMainMenu()
