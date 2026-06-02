local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local MapCamera = require(script.Parent:WaitForChild("MapCamera"))
local GameHud = require(script.Parent:WaitForChild("GameHud"))
local MapGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MapGenerator"))
local MapRenderer = require(script.Parent:WaitForChild("MapRenderer"))
local PlayerMapState = require(script.Parent:WaitForChild("PlayerMapState"))
local MapModeRemote = ReplicatedStorage:WaitForChild("CivilisationMapMode")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "CivilisationMainMenu"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local colors = {
	background = Color3.fromRGB(32, 93, 145),
	panel = Color3.fromRGB(34, 110, 171),
	panelDeep = Color3.fromRGB(26, 86, 145),
	border = Color3.fromRGB(129, 231, 255),
	borderSoft = Color3.fromRGB(88, 194, 237),
	gold = Color3.fromRGB(218, 249, 255),
	goldSoft = Color3.fromRGB(154, 225, 252),
	ivory = Color3.fromRGB(235, 250, 255),
	muted = Color3.fromRGB(194, 234, 247),
	red = Color3.fromRGB(132, 196, 227),
	green = Color3.fromRGB(149, 243, 255),
	blue = Color3.fromRGB(55, 145, 207),
	cyan = Color3.fromRGB(135, 239, 255),
}

local activeTabName = nil
local tabs = {}
local tabButtons = {}
local random = Random.new()

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
	button.BackgroundTransparency = 0.26
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
		ColorSequenceKeypoint.new(0, Color3.fromRGB(62, 162, 224)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 124, 193)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 92, 153)),
	})
	gradient.Rotation = 90
	gradient.Parent = button

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = Color3.fromRGB(70, 170, 226),
			BackgroundTransparency = 0.08,
			TextColor3 = colors.cyan,
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		if tabButtons[activeTabName] ~= button then
			TweenService:Create(button, TweenInfo.new(0.12), {
				BackgroundColor3 = colors.panelDeep,
				BackgroundTransparency = 0.26,
				TextColor3 = colors.ivory,
			}):Play()
		end
	end)

	return button
end

local function makeMainMenuButton(parent, text, height)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = false
	button.BackgroundColor3 = Color3.fromRGB(56, 151, 210)
	button.BackgroundTransparency = 0.82
	button.BorderSizePixel = 0
	button.Size = UDim2.new(1, 0, 0, height or 34)
	button.Text = text
	button.TextColor3 = colors.ivory
	button.TextSize = 18
	button.Font = Enum.Font.SourceSansSemibold
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Parent = parent
	addCorner(button, 3)
	addPadding(button, 12, 12, 0, 0)

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.14), {
			BackgroundTransparency = 0.42,
			TextColor3 = colors.cyan,
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		if tabButtons[activeTabName] ~= button then
			TweenService:Create(button, TweenInfo.new(0.14), {
				BackgroundTransparency = 0.82,
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
	box.BackgroundColor3 = Color3.fromRGB(31, 105, 166)
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
	value.BackgroundColor3 = Color3.fromRGB(31, 105, 166)
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
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.Size = UDim2.new(1, 0, 1, 0)
	panel.Visible = false
	panel.Parent = parent
	addPadding(panel, 64, 64, 96, 46)

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
	ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 142, 204)),
	ColorSequenceKeypoint.new(0.48, Color3.fromRGB(76, 184, 236)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 107, 175)),
})
bgGradient.Rotation = 30
bgGradient.Parent = background

task.spawn(function()
	while bgGradient.Parent do
		TweenService:Create(bgGradient, TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Offset = Vector2.new(0.18, -0.08),
			Rotation = 42,
		}):Play()
		task.wait(8)

		TweenService:Create(bgGradient, TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Offset = Vector2.new(-0.16, 0.1),
			Rotation = 26,
		}):Play()
		task.wait(8)
	end
end)

local function animateBackgroundElement(element, config)
	task.spawn(function()
		task.wait(config.Delay or 0)

		while element.Parent do
			local yScale = random:NextNumber(config.MinY or 0.04, config.MaxY or 0.96)
			local startXScale = random:NextNumber(config.MinStartX or -0.42, config.MaxStartX or -0.12)
			local endXScale = random:NextNumber(config.MinEndX or 1.04, config.MaxEndX or 1.22)
			local duration = random:NextNumber(config.MinDuration or 6, config.MaxDuration or 12)
			local height = random:NextInteger(config.MinHeight or 2, config.MaxHeight or 3)
			local widthScale = random:NextNumber(config.MinWidthScale or 0.16, config.MaxWidthScale or 0.48)
			local sizePixels = random:NextInteger(config.MinSize or 8, config.MaxSize or 16)
			local visibleTransparency = random:NextNumber(config.MinVisibleTransparency or 0.52, config.MaxVisibleTransparency or 0.72)
			local idleTransparency = random:NextNumber(config.MinIdleTransparency or 0.86, config.MaxIdleTransparency or 0.94)

			if config.Kind == "node" then
				element.Size = UDim2.fromOffset(sizePixels, sizePixels)
				element.Rotation = random:NextNumber(0, 90)
			elseif config.Kind == "facet" then
				local facetSize = random:NextInteger(config.MinSize or 36, config.MaxSize or 82)
				element.Size = UDim2.fromOffset(facetSize, facetSize)
				element.Rotation = random:NextNumber(18, 78)
			else
				element.Size = UDim2.new(widthScale, 0, 0, height)
				element.Rotation = random:NextNumber(config.MinRotation or -24, config.MaxRotation or 32)
			end

			element.Position = UDim2.new(startXScale, 0, yScale, 0)
			element.BackgroundTransparency = idleTransparency

			TweenService:Create(element, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = UDim2.new(endXScale, 0, random:NextNumber(config.MinY or 0.04, config.MaxY or 0.96), 0),
				BackgroundTransparency = visibleTransparency,
			}):Play()

			task.wait(duration)

			TweenService:Create(element, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				BackgroundTransparency = idleTransparency,
			}):Play()

			task.wait(random:NextNumber(0.35, 1.2))
		end
	end)
end

for i = 1, 24 do
	local connector = Instance.new("Frame")
	connector.BackgroundColor3 = i % 2 == 0 and colors.cyan or Color3.fromRGB(187, 244, 255)
	connector.BackgroundTransparency = 0.84
	connector.BorderSizePixel = 0
	connector.Position = UDim2.new(-0.16, 0, 0.05 + (i % 10) * 0.1, 0)
	connector.Rotation = -18 + (i % 7) * 7
	connector.Size = UDim2.new(0.16 + (i % 7) * 0.035, 0, 0, i % 5 == 0 and 3 or 2)
	connector.Parent = background
	animateBackgroundElement(connector, {
		Delay = i * 0.11,
		Kind = "line",
		MinWidthScale = 0.14,
		MaxWidthScale = 0.46,
		MinDuration = 6.4,
		MaxDuration = 12.5,
		MinVisibleTransparency = 0.46,
		MaxVisibleTransparency = 0.72,
	})
end

for i = 1, 34 do
	local node = Instance.new("Frame")
	node.BackgroundColor3 = i % 3 == 0 and colors.ivory or colors.cyan
	node.BackgroundTransparency = 0.72
	node.BorderSizePixel = 0
	node.Position = UDim2.new(-0.1, 0, 0.04 + (i % 12) * 0.079, 0)
	node.Rotation = 45
	node.Size = UDim2.fromOffset(i % 6 == 0 and 15 or 8, i % 6 == 0 and 15 or 8)
	node.Parent = background
	addCorner(node, 2)
	animateBackgroundElement(node, {
		Delay = i * 0.08,
		Kind = "node",
		MinSize = 6,
		MaxSize = 18,
		MinDuration = 5.8,
		MaxDuration = 11.5,
		MinVisibleTransparency = 0.5,
		MaxVisibleTransparency = 0.76,
	})
end

for i = 1, 18 do
	local facet = Instance.new("Frame")
	facet.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(114, 220, 251) or Color3.fromRGB(197, 247, 255)
	facet.BackgroundTransparency = 0.91
	facet.BorderSizePixel = 0
	facet.Position = UDim2.new(-0.18, 0, 0.07 + (i % 9) * 0.105, 0)
	facet.Rotation = 45 + (i % 4) * 15
	facet.Size = UDim2.fromOffset(42 + (i % 4) * 12, 42 + (i % 4) * 12)
	facet.Parent = background
	addCorner(facet, 4)
	addStroke(facet, i % 2 == 0 and colors.border or colors.ivory, 1, 0.54)
	animateBackgroundElement(facet, {
		Delay = i * 0.14,
		Kind = "facet",
		MinSize = 34,
		MaxSize = 88,
		MinDuration = 8.5,
		MaxDuration = 15,
		MinVisibleTransparency = 0.74,
		MaxVisibleTransparency = 0.9,
		MinIdleTransparency = 0.92,
		MaxIdleTransparency = 0.97,
	})
end

for i = 1, 8 do
	local route = Instance.new("Frame")
	route.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(219, 250, 255) or colors.cyan
	route.BackgroundTransparency = 0.88
	route.BorderSizePixel = 0
	route.Position = UDim2.new(-0.2, 0, 0.1 + (i % 6) * 0.14, 0)
	route.Rotation = random:NextNumber(-34, 34)
	route.Size = UDim2.new(0.54, 0, 0, 1)
	route.Parent = background
	animateBackgroundElement(route, {
		Delay = i * 0.22,
		Kind = "line",
		MinWidthScale = 0.34,
		MaxWidthScale = 0.72,
		MinHeight = 1,
		MaxHeight = 1,
		MinDuration = 11,
		MaxDuration = 18,
		MinVisibleTransparency = 0.64,
		MaxVisibleTransparency = 0.82,
		MinIdleTransparency = 0.9,
		MaxIdleTransparency = 0.97,
	})
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
titleBlock.AnchorPoint = Vector2.new(1, 0.5)
titleBlock.Position = UDim2.new(0.5, -14, 0.36, 0)
titleBlock.Size = UDim2.new(0, 680, 0, 154)
titleBlock.Parent = main

local title = makeText(titleBlock, "BIRTH OF CIVILISATIONS", 56, colors.ivory, Enum.Font.Garamond, Enum.TextXAlignment.Right)
title.Position = UDim2.new(0, 0, 0, 38)
title.Size = UDim2.new(1, 0, 0, 76)
title.TextYAlignment = Enum.TextYAlignment.Top

local subtitle = makeText(titleBlock, "A ROBLOX STRATEGY PROJECT", 14, colors.cyan, Enum.Font.SourceSansSemibold, Enum.TextXAlignment.Right)
subtitle.Position = UDim2.new(0, 4, 0, 20)
subtitle.Size = UDim2.new(1, 0, 0, 20)

local menuColumn = Instance.new("Frame")
menuColumn.Name = "MenuColumn"
menuColumn.AnchorPoint = Vector2.new(0, 0.5)
menuColumn.BackgroundTransparency = 1
menuColumn.BackgroundColor3 = Color3.fromRGB(34, 109, 172)
menuColumn.BorderSizePixel = 0
menuColumn.Position = UDim2.new(0.5, 0, 0.53, 0)
menuColumn.Size = UDim2.new(0, 290, 0, 320)
menuColumn.Parent = main
addPadding(menuColumn, 0, 0, 0, 0)

local menuLayout = Instance.new("UIListLayout")
menuLayout.Padding = UDim.new(0, 8)
menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
menuLayout.Parent = menuColumn

local menuDivider = Instance.new("Frame")
menuDivider.Name = "MenuDivider"
menuDivider.BackgroundColor3 = colors.cyan
menuDivider.BackgroundTransparency = 0.36
menuDivider.BorderSizePixel = 0
menuDivider.AnchorPoint = Vector2.new(0.5, 0.5)
menuDivider.Position = UDim2.new(0.5, 0, 0.53, 0)
menuDivider.Size = UDim2.new(0, 2, 0, 462)
menuDivider.Parent = main

local dividerTop = makeText(main, "▲", 24, colors.cyan, Enum.Font.SourceSansBold, Enum.TextXAlignment.Center)
dividerTop.AnchorPoint = Vector2.new(0.5, 0.5)
dividerTop.Position = UDim2.new(0.5, 0, 0.53, -238)
dividerTop.Size = UDim2.fromOffset(28, 24)

local dividerBottom = makeText(main, "▼", 24, colors.cyan, Enum.Font.SourceSansBold, Enum.TextXAlignment.Center)
dividerBottom.AnchorPoint = Vector2.new(0.5, 0.5)
dividerBottom.Position = UDim2.new(0.5, 0, 0.53, 238)
dividerBottom.Size = UDim2.fromOffset(28, 24)

local newsPanel = Instance.new("Frame")
newsPanel.Name = "ProjectNews"
newsPanel.AnchorPoint = Vector2.new(1, 0.5)
newsPanel.BackgroundColor3 = Color3.fromRGB(39, 121, 184)
newsPanel.BackgroundTransparency = 0.24
newsPanel.BorderSizePixel = 0
newsPanel.Position = UDim2.new(0.5, 0, 0.655, 0)
newsPanel.Size = UDim2.new(0, 360, 0, 300)
newsPanel.Parent = main
addCorner(newsPanel, 6)
addStroke(newsPanel, colors.borderSoft, 1, 0.34)
addPadding(newsPanel, 18, 18, 16, 16)

local newsGradient = Instance.new("UIGradient")
newsGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 153, 215)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(32, 104, 171)),
})
newsGradient.Rotation = 90
newsGradient.Parent = newsPanel

local newsTitle = makeText(newsPanel, "Новости проекта", 22, colors.ivory, Enum.Font.Garamond)
newsTitle.Size = UDim2.new(1, 0, 0, 28)

local newsLine = Instance.new("Frame")
newsLine.BackgroundColor3 = colors.cyan
newsLine.BackgroundTransparency = 0.18
newsLine.BorderSizePixel = 0
newsLine.Position = UDim2.new(0, 0, 0, 38)
newsLine.Size = UDim2.new(1, 0, 0, 2)
newsLine.Parent = newsPanel

local newsItems = {
	"Меню переработано под стиль стратегической карты.",
	"Загрузка теперь скрывает интерфейс после 100%.",
	"Следующий этап: игровой HUD и стартовая карта.",
	"Позже добавим генерацию мира по выбранному сиду.",
}

for index, text in ipairs(newsItems) do
	local marker = Instance.new("Frame")
	marker.BackgroundColor3 = colors.cyan
	marker.BackgroundTransparency = 0.12
	marker.BorderSizePixel = 0
	marker.Position = UDim2.new(0, 0, 0, 62 + (index - 1) * 55)
	marker.Size = UDim2.fromOffset(6, 6)
	marker.Parent = newsPanel
	addCorner(marker, 3)

	local item = makeText(newsPanel, text, 15, colors.muted, Enum.Font.SourceSans)
	item.Position = UDim2.new(0, 18, 0, 53 + (index - 1) * 55)
	item.Size = UDim2.new(1, -18, 0, 42)
	item.TextYAlignment = Enum.TextYAlignment.Top
end

local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 0, 0, 0)
content.Size = UDim2.new(1, 0, 1, 0)
content.Visible = false
content.Parent = main

local tabDivider = Instance.new("Frame")
tabDivider.Name = "TabDivider"
tabDivider.BackgroundColor3 = colors.cyan
tabDivider.BackgroundTransparency = 0.36
tabDivider.BorderSizePixel = 0
tabDivider.AnchorPoint = Vector2.new(0.5, 0.5)
tabDivider.Position = UDim2.new(0.5, 0, 0.53, 0)
tabDivider.Size = UDim2.new(0, 2, 0, 462)
tabDivider.Visible = false
tabDivider.Parent = main

local tabDividerTop = makeText(main, "▲", 24, colors.cyan, Enum.Font.SourceSansBold, Enum.TextXAlignment.Center)
tabDividerTop.AnchorPoint = Vector2.new(0.5, 0.5)
tabDividerTop.Position = UDim2.new(0.5, 0, 0.53, -238)
tabDividerTop.Size = UDim2.fromOffset(28, 24)
tabDividerTop.Visible = false

local tabDividerBottom = makeText(main, "▼", 24, colors.cyan, Enum.Font.SourceSansBold, Enum.TextXAlignment.Center)
tabDividerBottom.AnchorPoint = Vector2.new(0.5, 0.5)
tabDividerBottom.Position = UDim2.new(0.5, 0, 0.53, 238)
tabDividerBottom.Size = UDim2.fromOffset(28, 24)
tabDividerBottom.Visible = false

local footer = makeText(main, "Version 0.1", 13, colors.muted, Enum.Font.SourceSans, Enum.TextXAlignment.Center)
footer.AnchorPoint = Vector2.new(0, 1)
footer.Position = UDim2.new(0, 0, 1, 0)
footer.Size = UDim2.new(1, 0, 0, 22)

local gameHud = GameHud.Create(gui, {
	Colors = colors,
	MakeText = makeText,
	MakeButton = makeButton,
	AddCorner = addCorner,
	AddStroke = addStroke,
	AddPadding = addPadding,
})
local mapHud = gameHud.Root
local mapMenuButton = gameHud.MenuButton

local generatedMapFolder = nil

local mapExitConfirm = Instance.new("Frame")
mapExitConfirm.Name = "MapExitConfirm"
mapExitConfirm.AnchorPoint = Vector2.new(0.5, 0.5)
mapExitConfirm.BackgroundColor3 = Color3.fromRGB(24, 78, 128)
mapExitConfirm.BackgroundTransparency = 0.06
mapExitConfirm.BorderSizePixel = 0
mapExitConfirm.Position = UDim2.fromScale(0.5, 0.5)
mapExitConfirm.Size = UDim2.fromOffset(360, 174)
mapExitConfirm.Visible = false
mapExitConfirm.ZIndex = 60
mapExitConfirm.Parent = gui
addCorner(mapExitConfirm, 6)
addStroke(mapExitConfirm, colors.border, 1, 0.12)
addPadding(mapExitConfirm, 18, 18, 16, 16)

local exitConfirmTitle = makeText(mapExitConfirm, "Вы уверены?", 28, colors.ivory, Enum.Font.Garamond, Enum.TextXAlignment.Center)
exitConfirmTitle.Size = UDim2.new(1, 0, 0, 34)
exitConfirmTitle.ZIndex = 61

local exitConfirmBody = makeText(mapExitConfirm, "Текущая карта будет закрыта, а вы вернетесь в главное меню.", 16, colors.muted, Enum.Font.SourceSans, Enum.TextXAlignment.Center)
exitConfirmBody.Position = UDim2.new(0, 0, 0, 44)
exitConfirmBody.Size = UDim2.new(1, 0, 0, 44)
exitConfirmBody.ZIndex = 61

local exitConfirmCancel = makeButton(mapExitConfirm, "Отмена", 38, colors.borderSoft)
exitConfirmCancel.Position = UDim2.new(0, 0, 1, -38)
exitConfirmCancel.Size = UDim2.new(0.5, -7, 0, 38)
exitConfirmCancel.ZIndex = 61

local exitConfirmAccept = makeButton(mapExitConfirm, "В меню", 38, colors.gold)
exitConfirmAccept.Position = UDim2.new(0.5, 7, 1, -38)
exitConfirmAccept.Size = UDim2.new(0.5, -7, 0, 38)
exitConfirmAccept.ZIndex = 61

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

local loadingDivider = Instance.new("Frame")
loadingDivider.BackgroundColor3 = colors.cyan
loadingDivider.BackgroundTransparency = 1
loadingDivider.BorderSizePixel = 0
loadingDivider.AnchorPoint = Vector2.new(0.5, 0.5)
loadingDivider.Position = UDim2.new(0.5, 0, 0.5, 0)
loadingDivider.Size = UDim2.new(0, 2, 0, 390)
loadingDivider.ZIndex = 52
loadingDivider.Parent = loadingOverlay

local loadingDividerTop = makeText(loadingOverlay, "▲", 24, colors.cyan, Enum.Font.SourceSansBold, Enum.TextXAlignment.Center)
loadingDividerTop.AnchorPoint = Vector2.new(0.5, 0.5)
loadingDividerTop.Position = UDim2.new(0.5, 0, 0.5, -202)
loadingDividerTop.Size = UDim2.fromOffset(28, 24)
loadingDividerTop.TextTransparency = 1
loadingDividerTop.ZIndex = 52

local loadingDividerBottom = makeText(loadingOverlay, "▼", 24, colors.cyan, Enum.Font.SourceSansBold, Enum.TextXAlignment.Center)
loadingDividerBottom.AnchorPoint = Vector2.new(0.5, 0.5)
loadingDividerBottom.Position = UDim2.new(0.5, 0, 0.5, 202)
loadingDividerBottom.Size = UDim2.fromOffset(28, 24)
loadingDividerBottom.TextTransparency = 1
loadingDividerBottom.ZIndex = 52

local loadingTitle = makeText(loadingOverlay, "ЗАГРУЗКА КАРТЫ", 46, colors.ivory, Enum.Font.Garamond, Enum.TextXAlignment.Right)
loadingTitle.AnchorPoint = Vector2.new(1, 0.5)
loadingTitle.Position = UDim2.new(0.5, -14, 0.43, 0)
loadingTitle.Size = UDim2.new(0, 520, 0, 60)
loadingTitle.TextTransparency = 1
loadingTitle.ZIndex = 52

local loadingSubtitle = makeText(loadingOverlay, "Создаём мир для новой цивилизации", 18, colors.cyan, Enum.Font.SourceSansSemibold, Enum.TextXAlignment.Right)
loadingSubtitle.AnchorPoint = Vector2.new(1, 0.5)
loadingSubtitle.Position = UDim2.new(0.5, -14, 0.5, 0)
loadingSubtitle.Size = UDim2.new(0, 520, 0, 28)
loadingSubtitle.TextTransparency = 1
loadingSubtitle.ZIndex = 52

local loadingStatus = makeText(loadingOverlay, "", 16, colors.ivory, Enum.Font.SourceSans, Enum.TextXAlignment.Left)
loadingStatus.AnchorPoint = Vector2.new(0, 0.5)
loadingStatus.Position = UDim2.new(0.5, 18, 0.45, 0)
loadingStatus.Size = UDim2.new(0, 520, 0, 42)
loadingStatus.TextTransparency = 1
loadingStatus.ZIndex = 52

local progressBack = Instance.new("Frame")
progressBack.AnchorPoint = Vector2.new(0, 0.5)
progressBack.BackgroundColor3 = Color3.fromRGB(33, 132, 203)
progressBack.BackgroundTransparency = 1
progressBack.BorderSizePixel = 0
progressBack.Position = UDim2.new(0.5, 18, 0.55, 0)
progressBack.Size = UDim2.new(0, 410, 0, 14)
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
loadingPercent.AnchorPoint = Vector2.new(0, 0.5)
loadingPercent.Position = UDim2.new(0.5, 18, 0.6, 0)
loadingPercent.Size = UDim2.new(0, 120, 0, 22)
loadingPercent.TextTransparency = 1
loadingPercent.ZIndex = 52

local loadingInProgress = false

local function tween(instance, time, properties, easingStyle, easingDirection)
	local info = TweenInfo.new(time, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out)
	local tweenObject = TweenService:Create(instance, info, properties)
	tweenObject:Play()
	return tweenObject
end

local function setGeneratedMapVisible(isVisible)
	MapRenderer.SetVisible(generatedMapFolder, isVisible)
	gameHud.SetVisible(isVisible)
	if not isVisible then
		mapExitConfirm.Visible = false
	end
end

local function clearGeneratedMap()
	MapRenderer.Clear()
	generatedMapFolder = nil
	gameHud.SetVisible(false)
end

local function showLoadingScreen(countryName, difficultyName, seed, bots, mapWidth, mapLength)
	if loadingInProgress then
		return
	end

	local mapConfig = MapGenerator.CreateConfig(seed, mapWidth, mapLength)

	loadingInProgress = true
	loadingOverlay.Visible = true
	loadingOverlay.BackgroundTransparency = 1
	loadingTitle.TextTransparency = 1
	loadingSubtitle.TextTransparency = 1
	loadingStatus.TextTransparency = 1
	loadingPercent.TextTransparency = 1
	loadingDivider.BackgroundTransparency = 1
	loadingDividerTop.TextTransparency = 1
	loadingDividerBottom.TextTransparency = 1
	progressBack.BackgroundTransparency = 1
	progressFill.BackgroundTransparency = 1
	progressFill.Size = UDim2.fromScale(0, 1)
	loadingPercent.Text = "0%"
	loadingStatus.Text = ("Страна: %s | %dx%d | сид: %s | боты: %s"):format(countryName, mapConfig.Width, mapConfig.Length, seed, bots)

	task.spawn(function()
		local function setProgress(progress, text)
			loadingStatus.Text = text
			loadingPercent.Text = tostring(math.floor(progress * 100)) .. "%"
			tween(progressFill, 0.22, { Size = UDim2.fromScale(progress, 1) }, Enum.EasingStyle.Sine)
		end

		tween(loadingOverlay, 0.35, { BackgroundTransparency = 0.02 })
		tween(loadingTitle, 0.35, { TextTransparency = 0 })
		tween(loadingSubtitle, 0.45, { TextTransparency = 0.05 })
		tween(loadingStatus, 0.45, { TextTransparency = 0.08 })
		tween(loadingPercent, 0.45, { TextTransparency = 0.05 })
		tween(loadingDivider, 0.45, { BackgroundTransparency = 0.28 })
		tween(loadingDividerTop, 0.45, { TextTransparency = 0 })
		tween(loadingDividerBottom, 0.45, { TextTransparency = 0 })
		tween(progressBack, 0.45, { BackgroundTransparency = 0.08 })
		tween(progressFill, 0.45, { BackgroundTransparency = 0 })
		task.wait(0.45)

		setProgress(0.12, "Нормализуем сид и размеры мира...")
		task.wait(0.12)
		setProgress(0.22, "Создаём песчаную границу и внешнее море...")
		local renderInfo = MapRenderer.Render(mapConfig, function(progress, text)
			setProgress(0.22 + progress * 0.62, text)
		end)
		generatedMapFolder = renderInfo.Folder
		setProgress(0.88, "Настраиваем камеру и карту партии...")
		MapCamera.Focus(mapConfig.Width, mapConfig.Length, renderInfo.TileSize)
		gameHud.Update(countryName, difficultyName, bots, mapConfig, renderInfo)
		setProgress(1, "Карта готова.")

		task.wait(0.35)
		tween(loadingTitle, 0.35, { TextTransparency = 1 })
		tween(loadingSubtitle, 0.35, { TextTransparency = 1 })
		tween(loadingStatus, 0.35, { TextTransparency = 1 })
		tween(loadingPercent, 0.35, { TextTransparency = 1 })
		tween(loadingDivider, 0.35, { BackgroundTransparency = 1 })
		tween(loadingDividerTop, 0.35, { TextTransparency = 1 })
		tween(loadingDividerBottom, 0.35, { TextTransparency = 1 })
		tween(progressBack, 0.35, { BackgroundTransparency = 1 })
		tween(progressFill, 0.35, { BackgroundTransparency = 1 })
		main.Visible = false
		background.Visible = false
		PlayerMapState.SetMovementEnabled(player, false)
		PlayerMapState.SetCharacterVisible(player, false)
		MapModeRemote:FireServer(true)
		MapCamera.SetEnabled(true)
		setGeneratedMapVisible(true)
		tween(loadingOverlay, 0.45, { BackgroundTransparency = 1 })
		task.wait(0.45)

		loadingOverlay.Visible = false
		loadingInProgress = false
	end)
end

local function showMainMenu()
	activeTabName = nil
	main.Visible = true
	background.Visible = true
	setGeneratedMapVisible(false)
	PlayerMapState.SetMovementEnabled(player, false)
	PlayerMapState.SetCharacterVisible(player, false)
	MapModeRemote:FireServer(true)
	MapCamera.SetEnabled(false)
	content.Visible = false
	menuColumn.Visible = true
	menuDivider.Visible = true
	dividerTop.Visible = true
	dividerBottom.Visible = true
	tabDivider.Visible = false
	tabDividerTop.Visible = false
	tabDividerBottom.Visible = false
	newsPanel.Visible = true
	titleBlock.Visible = true
	footer.Visible = true

	for _, panel in pairs(tabs) do
		panel.Visible = false
	end

	for _, button in pairs(tabButtons) do
		button.TextColor3 = colors.ivory
		button.BackgroundColor3 = colors.panelDeep
		button.BackgroundTransparency = 0.82
	end
end

mapMenuButton.MouseButton1Click:Connect(function()
	mapExitConfirm.Visible = true
end)

exitConfirmCancel.MouseButton1Click:Connect(function()
	mapExitConfirm.Visible = false
end)

exitConfirmAccept.MouseButton1Click:Connect(function()
	mapExitConfirm.Visible = false
	clearGeneratedMap()
	showMainMenu()
end)

player.CharacterAdded:Connect(function()
	if mapHud.Visible then
		task.defer(function()
			PlayerMapState.SetCharacterVisible(player, false)
		end)
	end
end)

local function setActiveTab(tabName)
	activeTabName = tabName
	main.Visible = true
	background.Visible = true
	content.Visible = true
	menuColumn.Visible = false
	menuDivider.Visible = false
	dividerTop.Visible = false
	dividerBottom.Visible = false
	tabDivider.Visible = true
	tabDividerTop.Visible = true
	tabDividerBottom.Visible = true
	if tabName == "Shop" then
		tabDivider.Position = UDim2.new(0.5, 0, 0, 474)
		tabDivider.Size = UDim2.new(0, 2, 0, 330)
		tabDividerTop.Position = UDim2.new(0.5, 0, 0, 309)
		tabDividerBottom.Position = UDim2.new(0.5, 0, 0, 639)
	else
		tabDivider.Position = UDim2.new(0.5, 0, 0.53, 0)
		tabDivider.Size = UDim2.new(0, 2, 0, 462)
		tabDividerTop.Position = UDim2.new(0.5, 0, 0.53, -238)
		tabDividerBottom.Position = UDim2.new(0.5, 0, 0.53, 238)
	end
	newsPanel.Visible = false
	titleBlock.Visible = false
	footer.Visible = false

	for name, panel in pairs(tabs) do
		panel.Visible = name == tabName
		panel.BackgroundTransparency = 1
	end

	for name, button in pairs(tabButtons) do
		local selected = name == tabName
		button.TextColor3 = selected and colors.cyan or colors.ivory
		button.BackgroundColor3 = selected and Color3.fromRGB(64, 162, 224) or colors.panelDeep
	end
end

local function makeHeader(parent, heading, body)
	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, body and 92 or 60)
	header.Parent = parent

	local h = makeText(header, heading, 36, colors.ivory, Enum.Font.Garamond, Enum.TextXAlignment.Right)
	h.Position = UDim2.new(0, 0, 0, 0)
	h.Size = UDim2.new(0.5, -18, 0, 44)

	local headerLine = Instance.new("Frame")
	headerLine.BackgroundColor3 = colors.cyan
	headerLine.BackgroundTransparency = 0.24
	headerLine.BorderSizePixel = 0
	headerLine.Position = UDim2.new(0, 0, 0, 48)
	headerLine.Size = UDim2.new(0.5, -18, 0, 2)
	headerLine.Parent = header

	local backButton = makeButton(header, "Назад", 38, colors.border)
	backButton.Position = UDim2.new(0.5, 18, 0, 6)
	backButton.Size = UDim2.new(0, 140, 0, 38)
	backButton.MouseButton1Click:Connect(showMainMenu)

	if body then
		local b = makeText(header, body, 16, colors.muted, Enum.Font.SourceSans, Enum.TextXAlignment.Right)
		b.Position = UDim2.new(0, 0, 0, 58)
		b.Size = UDim2.new(0.5, -18, 0, 34)
	end

	return header
end

local function makeSection(parent, titleText)
	local section = Instance.new("Frame")
	section.BackgroundColor3 = Color3.fromRGB(34, 109, 172)
	section.BackgroundTransparency = 0.24
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
	button.BackgroundColor3 = Color3.fromRGB(35, 112, 174)
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

local function makeSlider(parent, text, value, minValue, maxValue, stepValue, formatter)
	minValue = minValue or 0
	maxValue = maxValue or 1
	stepValue = stepValue or 0.01
	local currentValue = math.clamp(value or minValue, minValue, maxValue)

	local wrapper = Instance.new("Frame")
	wrapper.BackgroundTransparency = 1
	wrapper.Size = UDim2.new(1, 0, 0, 42)
	wrapper.Parent = parent

	local label = makeText(wrapper, text, 15, colors.ivory, Enum.Font.SourceSans)
	label.Size = UDim2.new(0.45, 0, 1, 0)

	local track = Instance.new("Frame")
	track.Active = true
	track.BackgroundColor3 = Color3.fromRGB(32, 100, 166)
	track.BorderSizePixel = 0
	track.Position = UDim2.new(0.48, 0, 0.5, -4)
	track.Size = UDim2.new(0.38, 0, 0, 8)
	track.Parent = wrapper
	addCorner(track, 3)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = colors.cyan
	fill.BorderSizePixel = 0
	fill.Parent = track
	addCorner(fill, 3)

	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.BackgroundColor3 = colors.ivory
	knob.BorderSizePixel = 0
	knob.Size = UDim2.fromOffset(14, 14)
	knob.Parent = track
	addCorner(knob, 7)
	addStroke(knob, colors.border, 1, 0.25)

	local amount = makeText(wrapper, "", 14, colors.muted, Enum.Font.SourceSansBold, Enum.TextXAlignment.Right)
	amount.Position = UDim2.new(0.88, 0, 0, 0)
	amount.Size = UDim2.new(0.12, 0, 1, 0)

	local changedCallbacks = {}
	local dragging = false

	local function formatValue(numberValue)
		if formatter then
			return formatter(numberValue)
		end

		if minValue == 0 and maxValue == 1 then
			return tostring(math.floor(numberValue * 100))
		end

		return tostring(math.floor(numberValue))
	end

	local function render()
		local alpha = (currentValue - minValue) / (maxValue - minValue)
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.fromScale(alpha, 0.5)
		amount.Text = formatValue(currentValue)
	end

	local function setValue(newValue, shouldNotify)
		local stepped = math.floor((newValue - minValue) / stepValue + 0.5) * stepValue + minValue
		currentValue = math.clamp(stepped, minValue, maxValue)
		render()

		if shouldNotify then
			for _, callback in ipairs(changedCallbacks) do
				callback(currentValue)
			end
		end
	end

	local function setFromInput(inputObject)
		local trackPosition = track.AbsolutePosition.X
		local trackWidth = math.max(track.AbsoluteSize.X, 1)
		local alpha = math.clamp((inputObject.Position.X - trackPosition) / trackWidth, 0, 1)
		setValue(minValue + (maxValue - minValue) * alpha, true)
	end

	track.InputBegan:Connect(function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromInput(inputObject)
		end
	end)

	UserInputService.InputChanged:Connect(function(inputObject)
		if dragging and (inputObject.UserInputType == Enum.UserInputType.MouseMovement or inputObject.UserInputType == Enum.UserInputType.Touch) then
			setFromInput(inputObject)
		end
	end)

	UserInputService.InputEnded:Connect(function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	render()

	return {
		Wrapper = wrapper,
		GetValue = function()
			return currentValue
		end,
		SetValue = function(newValue)
			setValue(newValue, true)
		end,
		OnChanged = function(callback)
			table.insert(changedCallbacks, callback)
		end,
	}
end

local singleplayer = makePanel(content, "Singleplayer")
local singleLayout = Instance.new("UIListLayout")
singleLayout.Padding = UDim.new(0, 10)
singleLayout.SortOrder = Enum.SortOrder.LayoutOrder
singleLayout.Parent = singleplayer
makeHeader(singleplayer, "Синглплеер", "Выбери настройки партии, загрузи шаблон страны и подготовь старт будущей игры.")

local singleGrid = Instance.new("ScrollingFrame")
singleGrid.BackgroundTransparency = 1
singleGrid.BorderSizePixel = 0
singleGrid.Size = UDim2.new(1, 0, 0, 500)
singleGrid.CanvasSize = UDim2.new(0, 0, 0, 500)
singleGrid.ScrollBarThickness = 4
singleGrid.ScrollBarImageColor3 = colors.cyan
singleGrid.Parent = singleplayer

local singleLeft = Instance.new("Frame")
singleLeft.BackgroundColor3 = Color3.fromRGB(34, 109, 172)
singleLeft.BackgroundTransparency = 0.24
singleLeft.BorderSizePixel = 0
singleLeft.Size = UDim2.new(0.5, -10, 1, 0)
singleLeft.Parent = singleGrid
addCorner(singleLeft, 6)
addStroke(singleLeft, colors.borderSoft, 1, 0.35)
addPadding(singleLeft, 16, 16, 16, 16)

local gameSettingsTitle = makeText(singleLeft, "Настройки игры", 22, colors.gold, Enum.Font.Garamond)
gameSettingsTitle.Size = UDim2.new(1, 0, 0, 28)

local gameSettingsText = makeText(singleLeft, "Здесь только параметры партии: карта, сложность и будущие боты. Данные государства хранятся в шаблонах справа.", 16, colors.muted, Enum.Font.SourceSans)
gameSettingsText.Position = UDim2.new(0, 0, 0, 42)
gameSettingsText.Size = UDim2.new(1, 0, 0, 54)
gameSettingsText.TextYAlignment = Enum.TextYAlignment.Top

local gameSettingsFields = Instance.new("Frame")
gameSettingsFields.BackgroundTransparency = 1
gameSettingsFields.Position = UDim2.new(0, 0, 0, 104)
gameSettingsFields.Size = UDim2.new(1, 0, 1, -104)
gameSettingsFields.Parent = singleLeft

local singleLeftLayout = Instance.new("UIListLayout")
singleLeftLayout.Padding = UDim.new(0, 12)
singleLeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
singleLeftLayout.Parent = gameSettingsFields

local mapSeed = makeField(gameSettingsFields, "Сид карты", "Случайный или свой сид")
local mapWidthSlider = makeSlider(gameSettingsFields, "Ширина карты", 400, MapGenerator.MinMapSize, MapGenerator.MaxMapSize, 50, function(value)
	return tostring(math.floor(value))
end)
local mapLengthSlider = makeSlider(gameSettingsFields, "Длина карты", 400, MapGenerator.MinMapSize, MapGenerator.MaxMapSize, 50, function(value)
	return tostring(math.floor(value))
end)
local difficulty = makeSelect(gameSettingsFields, "Сложность", {
	"Поселенец",
	"Вождь",
	"Военачальник",
	"Князь",
	"Король",
	"Император",
	"Бессмертный",
	"Божество",
}, 4)
local botCount = makeSelect(gameSettingsFields, "Количество ботов", { "3", "4", "5", "6", "7", "8", "10", "12" }, 1)

local singleRight = Instance.new("Frame")
singleRight.BackgroundColor3 = Color3.fromRGB(34, 109, 172)
singleRight.BackgroundTransparency = 0.24
singleRight.BorderSizePixel = 0
singleRight.Position = UDim2.new(0.5, 18, 0, 0)
singleRight.Size = UDim2.new(0.5, -18, 1, 0)
singleRight.Parent = singleGrid
addCorner(singleRight, 6)
addStroke(singleRight, colors.borderSoft, 1, 0.35)
addPadding(singleRight, 16, 16, 16, 16)

local templatesTitle = makeText(singleRight, "Шаблоны стран", 22, colors.gold, Enum.Font.Garamond)
templatesTitle.Size = UDim2.new(1, 0, 0, 28)

local selectedTemplateCard = Instance.new("Frame")
selectedTemplateCard.BackgroundColor3 = Color3.fromRGB(31, 105, 166)
selectedTemplateCard.BackgroundTransparency = 0.18
selectedTemplateCard.BorderSizePixel = 0
selectedTemplateCard.Position = UDim2.new(0, 0, 0, 42)
selectedTemplateCard.Size = UDim2.new(1, 0, 0, 88)
selectedTemplateCard.Parent = singleRight
addCorner(selectedTemplateCard, 4)
addStroke(selectedTemplateCard, colors.borderSoft, 1, 0.42)
addPadding(selectedTemplateCard, 12, 12, 10, 10)

local selectedTemplateTitle = makeText(selectedTemplateCard, "Шаблон не выбран", 18, colors.cyan, Enum.Font.SourceSansSemibold)
selectedTemplateTitle.Size = UDim2.new(1, 0, 0, 24)

local selectedTemplateInfo = makeText(selectedTemplateCard, "Создай или выбери страну из списка, чтобы начать игру.", 15, colors.muted, Enum.Font.SourceSans)
selectedTemplateInfo.Position = UDim2.new(0, 0, 0, 30)
selectedTemplateInfo.Size = UDim2.new(1, 0, 0, 38)
selectedTemplateInfo.TextYAlignment = Enum.TextYAlignment.Top

local saveCountryButton = makeButton(singleRight, "Создать", 42, colors.gold)
saveCountryButton.Position = UDim2.new(0, 0, 0, 146)
saveCountryButton.Size = UDim2.new(0.34, -6, 0, 42)

local editTemplateButton = makeButton(singleRight, "Изменить", 42, colors.borderSoft)
editTemplateButton.Position = UDim2.new(0.34, 4, 0, 146)
editTemplateButton.Size = UDim2.new(0.33, -8, 0, 42)

local deleteTemplateButton = makeButton(singleRight, "Удалить", 42, colors.borderSoft)
deleteTemplateButton.Position = UDim2.new(0.67, 6, 0, 146)
deleteTemplateButton.Size = UDim2.new(0.33, -6, 0, 42)

local templateList = Instance.new("ScrollingFrame")
templateList.BackgroundColor3 = Color3.fromRGB(31, 105, 166)
templateList.BackgroundTransparency = 0.18
templateList.BorderSizePixel = 0
templateList.Position = UDim2.new(0, 0, 0, 204)
templateList.Size = UDim2.new(1, 0, 1, -262)
templateList.ScrollBarThickness = 4
templateList.ScrollBarImageColor3 = colors.cyan
templateList.CanvasSize = UDim2.new(0, 0, 0, 0)
templateList.Parent = singleRight
addCorner(templateList, 4)
addStroke(templateList, colors.borderSoft, 1, 0.42)
addPadding(templateList, 8, 8, 8, 8)

local templateListLayout = Instance.new("UIListLayout")
templateListLayout.Padding = UDim.new(0, 8)
templateListLayout.SortOrder = Enum.SortOrder.LayoutOrder
templateListLayout.Parent = templateList

local templateEmpty = makeText(templateList, "Шаблонов пока нет", 17, colors.muted, Enum.Font.SourceSans, Enum.TextXAlignment.Center)
templateEmpty.Size = UDim2.new(1, -16, 0, 52)
templateEmpty.LayoutOrder = 1

local startGameButton = makeButton(singleRight, "Начать игру", 46, colors.cyan)
startGameButton.Position = UDim2.new(0, 0, 1, -46)
startGameButton.Size = UDim2.new(1, 0, 0, 46)

local function updateSingleplayerLayout()
	local compact = gui.AbsoluteSize.X < 820
	if compact then
		singleGrid.Size = UDim2.new(1, 0, 0, 500)
		singleGrid.CanvasSize = UDim2.new(0, 0, 0, 1020)
		singleLeft.Position = UDim2.new(0, 0, 0, 0)
		singleLeft.Size = UDim2.new(1, -8, 0, 500)
		singleRight.Position = UDim2.new(0, 0, 0, 520)
		singleRight.Size = UDim2.new(1, -8, 0, 500)
	else
		singleGrid.Size = UDim2.new(1, 0, 0, 500)
		singleGrid.CanvasSize = UDim2.new(0, 0, 0, 500)
		singleLeft.Position = UDim2.new(0, 0, 0, 0)
		singleLeft.Size = UDim2.new(0.5, -18, 1, 0)
		singleRight.Position = UDim2.new(0.5, 18, 0, 0)
		singleRight.Size = UDim2.new(0.5, -18, 1, 0)
	end
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSingleplayerLayout)
updateSingleplayerLayout()

local singleStatus = makeText(singleplayer, "", 16, colors.green, Enum.Font.SourceSansSemibold)
singleStatus.Size = UDim2.new(1, 0, 0, 24)
singleStatus.TextTransparency = 1

local templateModalOverlay = Instance.new("Frame")
templateModalOverlay.BackgroundColor3 = Color3.fromRGB(16, 68, 118)
templateModalOverlay.BackgroundTransparency = 0.18
templateModalOverlay.BorderSizePixel = 0
templateModalOverlay.Size = UDim2.fromScale(1, 1)
templateModalOverlay.Visible = false
templateModalOverlay.ZIndex = 40
templateModalOverlay.Parent = main

local templateModal = Instance.new("Frame")
templateModal.AnchorPoint = Vector2.new(0.5, 0.5)
templateModal.BackgroundColor3 = Color3.fromRGB(34, 109, 172)
templateModal.BackgroundTransparency = 0.08
templateModal.BorderSizePixel = 0
templateModal.Position = UDim2.fromScale(0.5, 0.5)
templateModal.Size = UDim2.fromOffset(560, 500)
templateModal.ZIndex = 41
templateModal.Parent = templateModalOverlay
addCorner(templateModal, 6)
addStroke(templateModal, colors.border, 1, 0.16)
addPadding(templateModal, 18, 18, 16, 16)

local templateModalTitle = makeText(templateModal, "Создание шаблона", 28, colors.ivory, Enum.Font.Garamond)
templateModalTitle.Size = UDim2.new(1, -150, 0, 34)

local templateModalClose = makeButton(templateModal, "Закрыть", 36, colors.borderSoft)
templateModalClose.Position = UDim2.new(1, -130, 0, 0)
templateModalClose.Size = UDim2.new(0, 130, 0, 36)

local templateModalLine = Instance.new("Frame")
templateModalLine.BackgroundColor3 = colors.cyan
templateModalLine.BackgroundTransparency = 0.18
templateModalLine.BorderSizePixel = 0
templateModalLine.Position = UDim2.new(0, 0, 0, 46)
templateModalLine.Size = UDim2.new(1, 0, 0, 2)
templateModalLine.Parent = templateModal

local templateModalFields = Instance.new("Frame")
templateModalFields.BackgroundTransparency = 1
templateModalFields.Position = UDim2.new(0, 0, 0, 62)
templateModalFields.Size = UDim2.new(1, 0, 1, -132)
templateModalFields.Parent = templateModal

local templateModalLayout = Instance.new("UIListLayout")
templateModalLayout.Padding = UDim.new(0, 10)
templateModalLayout.SortOrder = Enum.SortOrder.LayoutOrder
templateModalLayout.Parent = templateModalFields

local templateCountryName = makeField(templateModalFields, "Название страны", "Например: Новая Атлантида", 62, 34)
local templateCapitalName = makeField(templateModalFields, "Столица", "Например: Аурелия", 62, 34)
local templateLeaderName = makeField(templateModalFields, "Правитель", "Например: Левон I", 62, 34)
local templateGovernment = makeSelect(templateModalFields, "Форма правления", {
	"Вождизм",
	"Республика",
	"Монархия",
	"Олигархия",
	"Технократия",
}, 1)

local templateModalSave = makeButton(templateModal, "Сохранить шаблон", 42, colors.cyan)
templateModalSave.Position = UDim2.new(0, 0, 1, -42)
templateModalSave.Size = UDim2.new(1, 0, 0, 42)

for _, descendant in ipairs(templateModalOverlay:GetDescendants()) do
	if descendant:IsA("GuiObject") then
		descendant.ZIndex = math.max(descendant.ZIndex, 41)
	end
end

local countryTemplates = {}
local selectedTemplateId = nil
local nextTemplateId = 1
local editingTemplateId = nil

local function readGameSetup()
	local seed = mapSeed.Text
	if seed == "" then
		seed = tostring(math.random(100000, 999999))
		mapSeed.Text = seed
	end

	local mapWidth = MapGenerator.ClampDimension(mapWidthSlider.GetValue())
	local mapLength = MapGenerator.ClampDimension(mapLengthSlider.GetValue())

	return seed, mapWidth, mapLength
end

local function findTemplateIndex(templateId)
	for index, template in ipairs(countryTemplates) do
		if template.Id == templateId then
			return index
		end
	end

	return nil
end

local function setModalVisible(isVisible)
	templateModalOverlay.Visible = isVisible
end

local function readTemplateFromModal()
	return {
		Name = templateCountryName.Text,
		Capital = templateCapitalName.Text ~= "" and templateCapitalName.Text or "Столица",
		Leader = templateLeaderName.Text ~= "" and templateLeaderName.Text or "Безымянный правитель",
		Government = templateGovernment.GetValue(),
	}
end

local function applyTemplateToModal(template)
	templateCountryName.Text = template and template.Name or ""
	templateCapitalName.Text = template and template.Capital or ""
	templateLeaderName.Text = template and template.Leader or ""
	templateGovernment.SetValue(template and template.Government or "Вождизм")
end

local function openTemplateModal(templateId)
	editingTemplateId = templateId
	local selectedIndex = findTemplateIndex(templateId)
	if selectedIndex then
		templateModalTitle.Text = "Изменение шаблона"
		templateModalSave.Text = "Сохранить изменения"
		applyTemplateToModal(countryTemplates[selectedIndex])
	else
		templateModalTitle.Text = "Создание шаблона"
		templateModalSave.Text = "Создать шаблон"
		applyTemplateToModal(nil)
	end

	setModalVisible(true)
end

local function refreshTemplateList()
	for _, child in ipairs(templateList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	templateEmpty.Visible = #countryTemplates == 0

	local selectedTemplate = nil
	for index, template in ipairs(countryTemplates) do
		local isSelected = template.Id == selectedTemplateId
		if isSelected then
			selectedTemplate = template
		end

		local row = makeButton(templateList, "", 58, isSelected and colors.cyan or colors.borderSoft)
		row.LayoutOrder = index + 1
		row.BackgroundTransparency = isSelected and 0.08 or 0.26
		row.Text = ("%s\n%s | %s | %s"):format(template.Name, template.Capital, template.Leader, template.Government)
		row.TextSize = 15
		row.Font = Enum.Font.SourceSansSemibold
		row.TextXAlignment = Enum.TextXAlignment.Left
		addPadding(row, 12, 12, 0, 0)

		row.MouseButton1Click:Connect(function()
			selectedTemplateId = template.Id
			singleStatus.TextColor3 = colors.green
			singleStatus.Text = ("Шаблон \"%s\" выбран."):format(template.Name)
			singleStatus.TextTransparency = 0
			refreshTemplateList()
		end)
	end

	if selectedTemplate then
		selectedTemplateTitle.Text = selectedTemplate.Name
		selectedTemplateInfo.Text = ("%s | %s\nПравитель: %s"):format(selectedTemplate.Capital, selectedTemplate.Government, selectedTemplate.Leader)
	else
		selectedTemplateTitle.Text = "Шаблон не выбран"
		selectedTemplateInfo.Text = "Создай или выбери страну из списка, чтобы начать игру."
	end

	templateList.CanvasSize = UDim2.new(0, 0, 0, templateListLayout.AbsoluteContentSize.Y + 16)
end

templateListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	templateList.CanvasSize = UDim2.new(0, 0, 0, templateListLayout.AbsoluteContentSize.Y + 16)
end)

templateModalClose.MouseButton1Click:Connect(function()
	setModalVisible(false)
end)

saveCountryButton.MouseButton1Click:Connect(function()
	openTemplateModal(nil)
end)

editTemplateButton.MouseButton1Click:Connect(function()
	if not findTemplateIndex(selectedTemplateId) then
		singleStatus.TextColor3 = Color3.fromRGB(255, 126, 126)
		singleStatus.Text = "Сначала выбери шаблон из списка."
		singleStatus.TextTransparency = 0
		return
	end

	openTemplateModal(selectedTemplateId)
end)

deleteTemplateButton.MouseButton1Click:Connect(function()
	local selectedIndex = findTemplateIndex(selectedTemplateId)
	if not selectedIndex then
		singleStatus.TextColor3 = Color3.fromRGB(255, 126, 126)
		singleStatus.Text = "Сначала выбери шаблон из списка."
		singleStatus.TextTransparency = 0
		return
	end

	local removedTemplate = table.remove(countryTemplates, selectedIndex)
	selectedTemplateId = countryTemplates[selectedIndex] and countryTemplates[selectedIndex].Id or countryTemplates[selectedIndex - 1] and countryTemplates[selectedIndex - 1].Id or nil
	refreshTemplateList()
	singleStatus.TextColor3 = colors.green
	singleStatus.Text = ("Шаблон \"%s\" удалён."):format(removedTemplate.Name)
	singleStatus.TextTransparency = 0
end)

templateModalSave.MouseButton1Click:Connect(function()
	local template = readTemplateFromModal()
	if template.Name == "" then
		singleStatus.TextColor3 = Color3.fromRGB(255, 126, 126)
		singleStatus.Text = "Введите название страны в окне шаблона."
		singleStatus.TextTransparency = 0
		return
	end

	local editingIndex = findTemplateIndex(editingTemplateId)
	if editingIndex then
		template.Id = editingTemplateId
		countryTemplates[editingIndex] = template
		selectedTemplateId = template.Id
		singleStatus.Text = ("Шаблон \"%s\" изменён."):format(template.Name)
	else
		template.Id = nextTemplateId
		nextTemplateId += 1
		table.insert(countryTemplates, template)
		selectedTemplateId = template.Id
		singleStatus.Text = ("Шаблон \"%s\" создан."):format(template.Name)
	end

	singleStatus.TextColor3 = colors.green
	singleStatus.TextTransparency = 0
	setModalVisible(false)
	refreshTemplateList()
end)

refreshTemplateList()

startGameButton.MouseButton1Click:Connect(function()
	local selectedIndex = findTemplateIndex(selectedTemplateId)
	if not selectedIndex then
		singleStatus.TextColor3 = Color3.fromRGB(255, 126, 126)
		singleStatus.Text = "Сначала выбери шаблон страны."
		singleStatus.TextTransparency = 0
		return
	end

	local selectedTemplate = countryTemplates[selectedIndex]
	local seed, mapWidth, mapLength = readGameSetup()
	singleStatus.TextColor3 = colors.green
	singleStatus.Text = ("Запуск партии: %s | %dx%d | %s | сид %s | боты: %s."):format(selectedTemplate.Name, mapWidth, mapLength, difficulty.GetValue(), seed, botCount.GetValue())
	singleStatus.TextTransparency = 0
	showLoadingScreen(selectedTemplate.Name, difficulty.GetValue(), seed, botCount.GetValue(), mapWidth, mapLength)
end)

local multiplayer = makePanel(content, "Multiplayer")
local multiLayout = Instance.new("UIListLayout")
multiLayout.Padding = UDim.new(0, 14)
multiLayout.SortOrder = Enum.SortOrder.LayoutOrder
multiLayout.Parent = multiplayer
makeHeader(multiplayer, "Мультиплеер", "Поиск серверов, фильтры и подготовка лобби для будущей сетевой игры.")

local multiTop = Instance.new("Frame")
multiTop.BackgroundTransparency = 1
multiTop.Size = UDim2.new(1, 0, 0, 218)
multiTop.Parent = multiplayer

local filters = Instance.new("Frame")
filters.BackgroundColor3 = Color3.fromRGB(34, 109, 172)
filters.BackgroundTransparency = 0.24
filters.BorderSizePixel = 0
filters.Size = UDim2.new(0.5, -18, 1, 0)
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
multiActions.Position = UDim2.new(0.5, 18, 0, 0)
multiActions.Size = UDim2.new(0, 160, 1, 0)
multiActions.Parent = multiTop
local multiActionLayout = Instance.new("UIListLayout")
multiActionLayout.Padding = UDim.new(0, 10)
multiActionLayout.Parent = multiActions
local refreshButton = makeButton(multiActions, "Обновить", 48, colors.border)
local createServerButton = makeButton(multiActions, "Создать сервер", 48, colors.gold)

local serverList = Instance.new("Frame")
serverList.BackgroundColor3 = Color3.fromRGB(30, 99, 166)
serverList.BackgroundTransparency = 0.28
serverList.BorderSizePixel = 0
serverList.Position = UDim2.new(0.5, 18, 0, 0)
serverList.Size = UDim2.new(0.5, -18, 1, -92)
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
invGrid.BackgroundColor3 = Color3.fromRGB(30, 99, 166)
invGrid.BackgroundTransparency = 0.28
invGrid.BorderSizePixel = 0
invGrid.Position = UDim2.new(0.5, 18, 0, 0)
invGrid.Size = UDim2.new(0.5, -18, 1, -40)
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
currencyBar.BackgroundColor3 = Color3.fromRGB(34, 109, 172)
currencyBar.BackgroundTransparency = 0.24
currencyBar.BorderSizePixel = 0
currencyBar.Size = UDim2.new(1, 0, 0, 58)
currencyBar.Parent = shop
addCorner(currencyBar, 6)
addStroke(currencyBar, colors.border, 1, 0.24)
addPadding(currencyBar, 16, 16, 8, 8)

local coins = makeText(currencyBar, "Казна: 0 монет", 21, colors.gold, Enum.Font.Garamond)
coins.Size = UDim2.new(0.5, 0, 1, 0)

local buyCurrency = makeButton(currencyBar, "Купить монеты за Robux", 42, colors.cyan)
buyCurrency.Position = UDim2.new(1, -220, 0, 0)
buyCurrency.Size = UDim2.new(0, 220, 0, 42)

local shopBody = Instance.new("Frame")
shopBody.BackgroundTransparency = 1
shopBody.Size = UDim2.new(1, 0, 1, -166)
shopBody.Parent = shop

local shopGrid = Instance.new("Frame")
shopGrid.BackgroundColor3 = Color3.fromRGB(30, 99, 166)
shopGrid.BackgroundTransparency = 0.28
shopGrid.BorderSizePixel = 0
shopGrid.Position = UDim2.new(0, 0, 0, 0)
shopGrid.Size = UDim2.new(0.5, -26, 1, 0)
shopGrid.Parent = shopBody
addCorner(shopGrid, 6)
addStroke(shopGrid, colors.borderSoft, 1, 0.42)
addPadding(shopGrid, 22, 22, 22, 22)

local shopEmptyTitle = makeText(shopGrid, "Магазин пуст", 24, colors.cyan, Enum.Font.Garamond, Enum.TextXAlignment.Center)
shopEmptyTitle.Position = UDim2.new(0, 0, 0.5, -36)
shopEmptyTitle.Size = UDim2.new(1, 0, 0, 30)

local shopEmptyBody = makeText(shopGrid, "Скины, товары и покупки валюты будут добавлены после настройки экономики и Developer Products.", 16, colors.muted, Enum.Font.SourceSans, Enum.TextXAlignment.Center)
shopEmptyBody.Position = UDim2.new(0.12, 0, 0.5, 0)
shopEmptyBody.Size = UDim2.new(0.76, 0, 0, 42)

local bonusPanel = Instance.new("Frame")
bonusPanel.BackgroundColor3 = Color3.fromRGB(30, 99, 166)
bonusPanel.BackgroundTransparency = 0.28
bonusPanel.BorderSizePixel = 0
bonusPanel.Position = UDim2.new(0.5, 26, 0, 0)
bonusPanel.Size = UDim2.new(0.5, -26, 1, 0)
bonusPanel.Parent = shopBody
addCorner(bonusPanel, 6)
addStroke(bonusPanel, colors.borderSoft, 1, 0.42)
addPadding(bonusPanel, 22, 22, 22, 22)

local bonusTitle = makeText(bonusPanel, "Бонусы", 24, colors.cyan, Enum.Font.Garamond)
bonusTitle.Size = UDim2.new(1, 0, 0, 30)

local bonusLine = Instance.new("Frame")
bonusLine.BackgroundColor3 = colors.cyan
bonusLine.BackgroundTransparency = 0.2
bonusLine.BorderSizePixel = 0
bonusLine.Position = UDim2.new(0, 0, 0, 40)
bonusLine.Size = UDim2.new(1, 0, 0, 2)
bonusLine.Parent = bonusPanel

local dailyTitle = makeText(bonusPanel, "Ежедневный бонус", 19, colors.ivory, Enum.Font.SourceSansSemibold)
dailyTitle.Position = UDim2.new(0, 0, 0, 62)
dailyTitle.Size = UDim2.new(1, 0, 0, 24)

local dailyBody = makeText(bonusPanel, "+100 монет за первый вход дня", 16, colors.muted, Enum.Font.SourceSans)
dailyBody.Position = UDim2.new(0, 0, 0, 92)
dailyBody.Size = UDim2.new(1, 0, 0, 24)

local claimDailyButton = makeButton(bonusPanel, "Забрать позже", 42, colors.cyan)
claimDailyButton.Position = UDim2.new(0, 0, 0, 132)
claimDailyButton.Size = UDim2.new(1, 0, 0, 42)

local bonusItems = {
	"Серия входов: 0 дней",
	"Бонус за победу: заблокирован",
	"Бонус за исследование: скоро",
	"Премиум-набор: не подключён",
}

for index, bonusText in ipairs(bonusItems) do
	local row = makeText(bonusPanel, bonusText, 15, colors.muted, Enum.Font.SourceSans)
	row.Position = UDim2.new(0, 0, 0, 196 + (index - 1) * 34)
	row.Size = UDim2.new(1, 0, 0, 24)
end

local menuItems = {
	{ key = "Singleplayer", label = "Синглплеер" },
	{ key = "Multiplayer", label = "Мультиплеер" },
	{ key = "Settings", label = "Настройки" },
	{ key = "Inventory", label = "Инвентарь" },
	{ key = "Shop", label = "Магазин" },
}

for order, item in ipairs(menuItems) do
	local button = makeMainMenuButton(menuColumn, item.label, 38)
	button.LayoutOrder = order
	tabButtons[item.key] = button
	button.MouseButton1Click:Connect(function()
		setActiveTab(item.key)
	end)
end

showMainMenu()
