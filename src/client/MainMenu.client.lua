local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local MapGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MapGenerator"))

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

local mapHud = Instance.new("Frame")
mapHud.Name = "GeneratedMapHud"
mapHud.BackgroundColor3 = Color3.fromRGB(27, 84, 124)
mapHud.BackgroundTransparency = 0.16
mapHud.BorderSizePixel = 0
mapHud.AnchorPoint = Vector2.new(1, 0)
mapHud.Position = UDim2.new(1, -18, 0, 18)
mapHud.Size = UDim2.fromOffset(112, 44)
mapHud.Visible = false
mapHud.ZIndex = 20
mapHud.Parent = gui
addCorner(mapHud, 6)
addStroke(mapHud, colors.borderSoft, 1, 0.28)
addPadding(mapHud, 14, 14, 10, 10)

local mapHudTitle = makeText(mapHud, "Карта не создана", 18, colors.ivory, Enum.Font.SourceSansSemibold)
mapHudTitle.Size = UDim2.new(1, -110, 0, 24)
mapHudTitle.ZIndex = 21
mapHudTitle.Visible = false

local mapHudStats = makeText(mapHud, "", 14, colors.muted, Enum.Font.SourceSans)
mapHudStats.Position = UDim2.new(0, 0, 0, 30)
mapHudStats.Size = UDim2.new(1, 0, 0, 42)
mapHudStats.TextYAlignment = Enum.TextYAlignment.Top
mapHudStats.ZIndex = 21
mapHudStats.Visible = false

local mapMenuButton = makeButton(mapHud, "Меню", 32, colors.cyan)
mapMenuButton.Position = UDim2.new(0, 0, 0, 0)
mapMenuButton.Size = UDim2.new(1, 0, 1, 0)
mapMenuButton.ZIndex = 21

local generatedMapFolder = nil
local mapTileSize = 3
local maxRenderedMapAxis = 420
local mapCameraTarget = Vector3.new(0, 0, 0)
local mapCameraHeight = 110
local mapCameraBounds = {
	MinX = -300,
	MaxX = 300,
	MinZ = -300,
	MaxZ = 300,
}
local playerControls = nil

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

local exitConfirmBody = makeText(mapExitConfirm, "Текущая карта будет закрыта, а вы вернётесь в главное меню.", 16, colors.muted, Enum.Font.SourceSans, Enum.TextXAlignment.Center)
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

local strategyHud = Instance.new("Frame")
strategyHud.Name = "StrategyHud"
strategyHud.BackgroundColor3 = Color3.fromRGB(24, 78, 128)
strategyHud.BackgroundTransparency = 0.12
strategyHud.BorderSizePixel = 0
strategyHud.Position = UDim2.new(0, 18, 0, 64)
strategyHud.Size = UDim2.fromOffset(392, 328)
strategyHud.Visible = false
strategyHud.ZIndex = 20
strategyHud.Parent = gui
addCorner(strategyHud, 6)
addStroke(strategyHud, colors.borderSoft, 1, 0.28)
addPadding(strategyHud, 14, 14, 12, 12)

local strategyTitle = makeText(strategyHud, "Государство", 20, colors.ivory, Enum.Font.Garamond)
strategyTitle.Size = UDim2.new(1, 0, 0, 26)
strategyTitle.ZIndex = 21

local strategyYields = makeText(strategyHud, "", 14, colors.cyan, Enum.Font.SourceSansSemibold)
strategyYields.Position = UDim2.new(0, 0, 0, 32)
strategyYields.Size = UDim2.new(1, 0, 0, 38)
strategyYields.ZIndex = 21

local strategySystems = makeText(strategyHud, "", 14, colors.muted, Enum.Font.SourceSans)
strategySystems.Position = UDim2.new(0, 0, 0, 76)
strategySystems.Size = UDim2.new(1, 0, 1, -126)
strategySystems.TextYAlignment = Enum.TextYAlignment.Top
strategySystems.ZIndex = 21

local nextTurnButton = makeButton(strategyHud, "Следующий ход", 38, colors.gold)
nextTurnButton.Position = UDim2.new(0, 0, 1, -38)
nextTurnButton.Size = UDim2.new(1, 0, 0, 38)
nextTurnButton.ZIndex = 21

local gameState = {
	Turn = 1,
	Era = "Древний мир",
	Government = "Вождизм",
	Science = 3,
	Culture = 2,
	Gold = 5,
	Faith = 0,
	DiplomaticFavor = 0,
	Technology = "Гончарное дело",
	Civic = "Свод законов",
	City = "Столица",
}

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

local function updateStrategyHud()
	strategyTitle.Text = ("%s | Ход %d | %s"):format(gameState.City, gameState.Turn, gameState.Era)
	strategyYields.Text = ("Наука +%d  Культура +%d  Золото +%d  Вера +%d  Дип. влияние +%d"):format(
		gameState.Science,
		gameState.Culture,
		gameState.Gold,
		gameState.Faith,
		gameState.DiplomaticFavor
	)
	strategySystems.Text = table.concat({
		("Технология: %s -> Письменность, Ирригация, Горное дело"):format(gameState.Technology),
		("Цивик: %s -> Ремесло, Внешняя торговля, Ранняя империя"):format(gameState.Civic),
		("Правительство: %s | политики: военная, экономическая, дипломатическая, wildcard"):format(gameState.Government),
		"Город и районы: центр города, кампус, священное место, коммерческий узел, театр, промышленная зона, гавань.",
		"Чудеса и великие люди: очки великих учёных/писателей/полководцев, места под чудеса рядом с подходящими тайлами.",
		"Религия и торговля: вера, пантеон, пророк, миссионеры, торговые пути и дороги между городами.",
		"Дипломатия: лидеры, город-государства, послы, союзы, дипломатическая валюта, мировой конгресс.",
		"Эпохи и империя: очки эпохи, золотой/тёмный век, лояльность городов, губернаторы, чрезвычайные ситуации.",
		"Мир: варвары, ресурсы, стихийные бедствия, климат, энергия, затопления, засухи и ураганы.",
	}, "\n")
end

local function setGeneratedMapVisible(isVisible)
	if generatedMapFolder then
		for _, child in ipairs(generatedMapFolder:GetChildren()) do
			if child:IsA("BasePart") then
				child.Transparency = isVisible and child:GetAttribute("BaseTransparency") or 1
			end
		end
	end

	mapHud.Visible = isVisible
	strategyHud.Visible = isVisible
	if not isVisible then
		mapExitConfirm.Visible = false
	end
end

local function clearGeneratedMap()
	local existing = workspace:FindFirstChild("CivilisationGeneratedMap")
	if existing then
		existing:Destroy()
	end

	generatedMapFolder = nil
	mapHud.Visible = false
end

local function setCharacterVisible(isVisible)
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

local function getPlayerControls()
	if playerControls then
		return playerControls
	end

	local playerScripts = player:WaitForChild("PlayerScripts")
	local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
	playerControls = playerModule:GetControls()
	return playerControls
end

local function setPlayerMovementEnabled(isEnabled)
	local controls = getPlayerControls()
	if isEnabled then
		controls:Enable()
	else
		controls:Disable()
	end
end

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
		((x - 1) + spanX * 0.5 - width * 0.5) * mapTileSize,
		0,
		((z - 1) + spanZ * 0.5 - length * 0.5) * mapTileSize
	)
end

local function createMapBorders(parent, width, length, seedValue)
	local water = MapGenerator.GetTileAt(-1, -1, width, length, seedValue)
	local sand = MapGenerator.GetTileAt(0, 0, width, length, seedValue)
	local waterPadding = 260

	local outerWater = createMapPart(parent, "OuterWater", water, Vector3.new(0, 0, 0), (width + waterPadding * 2) * mapTileSize, (length + waterPadding * 2) * mapTileSize, 0.08)
	outerWater.Position = Vector3.new(0, getTileTopY(water) - 0.55, 0)
	createMapPart(parent, "NorthSandBorder", sand, mapCellCenter(0, 0, width + 2, 1, width, length), (width + 2) * mapTileSize, mapTileSize, 0)
	createMapPart(parent, "SouthSandBorder", sand, mapCellCenter(0, length + 1, width + 2, 1, width, length), (width + 2) * mapTileSize, mapTileSize, 0)
	createMapPart(parent, "WestSandBorder", sand, mapCellCenter(0, 1, 1, length, width, length), mapTileSize, length * mapTileSize, 0)
	createMapPart(parent, "EastSandBorder", sand, mapCellCenter(width + 1, 1, 1, length, width, length), mapTileSize, length * mapTileSize, 0)
end

local function renderGeneratedMap(mapConfig, onProgress)
	clearGeneratedMap()

	local folder = Instance.new("Folder")
	folder.Name = "CivilisationGeneratedMap"
	folder:SetAttribute("Seed", mapConfig.Seed)
	folder:SetAttribute("SeedValue", mapConfig.SeedValue)
	folder:SetAttribute("Width", mapConfig.Width)
	folder:SetAttribute("Length", mapConfig.Length)
	folder.Parent = workspace
	generatedMapFolder = folder

	createMapBorders(folder, mapConfig.Width, mapConfig.Length, mapConfig.SeedValue)

	local step = math.max(1, math.ceil(math.max(mapConfig.Width, mapConfig.Length) / maxRenderedMapAxis))
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
				spanX * mapTileSize,
				spanZ * mapTileSize,
				0
			)
			part:SetAttribute("MapX", x)
			part:SetAttribute("MapZ", z)
			part:SetAttribute("SampleStep", step)

			renderedTiles += 1
			if renderedTiles % 180 == 0 then
				onProgress(renderedTiles / totalTiles, ("Генерируем клетки: %d/%d"):format(renderedTiles, totalTiles))
				task.wait()
			end
		end
	end

	onProgress(1, "Клетки, высоты и проходимость готовы.")
	return {
		Step = step,
		RenderedTiles = totalTiles,
		Stats = stats,
	}
end

local function applyMapCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 40
	camera.CFrame = CFrame.lookAt(
		mapCameraTarget + Vector3.new(0, mapCameraHeight, -mapCameraHeight * 0.95),
		mapCameraTarget + Vector3.new(0, 2, 0)
	)
end

local function focusCameraOnMap(width, length)
	local maxSide = math.max(width, length) * mapTileSize
	mapCameraHeight = math.clamp(maxSide * 0.045, 28, 72)
	mapCameraTarget = Vector3.new(0, 0, 0)
	mapCameraBounds = {
		MinX = -width * mapTileSize * 0.5,
		MaxX = width * mapTileSize * 0.5,
		MinZ = -length * mapTileSize * 0.5,
		MaxZ = length * mapTileSize * 0.5,
	}
	applyMapCamera()
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
		local renderInfo = renderGeneratedMap(mapConfig, function(progress, text)
			setProgress(0.22 + progress * 0.62, text)
		end)
		setProgress(0.88, "Настраиваем камеру и карту партии...")
		focusCameraOnMap(mapConfig.Width, mapConfig.Length)
		gameState.Turn = 1
		gameState.City = countryName
		gameState.Science = 3 + math.floor(renderInfo.Stats.Mountain / math.max(mapConfig.Width * mapConfig.Length, 1) * 12)
		gameState.Culture = 2 + math.floor(renderInfo.Stats.Snow / math.max(mapConfig.Width * mapConfig.Length, 1) * 10)
		gameState.Gold = 5 + math.floor(renderInfo.Stats.Sand / math.max(mapConfig.Width * mapConfig.Length, 1) * 18)
		gameState.Faith = math.floor(renderInfo.Stats.Grass / math.max(mapConfig.Width * mapConfig.Length, 1) * 4)
		gameState.DiplomaticFavor = 0
		updateStrategyHud()
		mapHudTitle.Text = ("%s | %dx%d"):format(countryName, mapConfig.Width, mapConfig.Length)
		mapHudStats.Text = ("Сид: %s | шаг отрисовки: %d | тайлов: %d\nВода %d, снег %d, песок %d, трава %d, горы %d"):format(
			mapConfig.Seed,
			renderInfo.Step,
			mapConfig.Width * mapConfig.Length,
			renderInfo.Stats.Water,
			renderInfo.Stats.Snow,
			renderInfo.Stats.Sand,
			renderInfo.Stats.Grass,
			renderInfo.Stats.Mountain
		)
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
		setPlayerMovementEnabled(false)
		setCharacterVisible(false)
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
	setPlayerMovementEnabled(true)
	setCharacterVisible(true)
	if workspace.CurrentCamera then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	end
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

nextTurnButton.MouseButton1Click:Connect(function()
	gameState.Turn += 1
	if gameState.Turn == 8 then
		gameState.Technology = "Письменность"
	elseif gameState.Turn == 14 then
		gameState.Civic = "Ремесло"
	elseif gameState.Turn == 22 then
		gameState.Government = "Автократия"
	elseif gameState.Turn == 35 then
		gameState.Era = "Классическая эпоха"
	end

	gameState.Gold += 1
	if gameState.Turn % 5 == 0 then
		gameState.Science += 1
		gameState.Culture += 1
	end
	if gameState.Turn % 7 == 0 then
		gameState.Faith += 1
	end
	if gameState.Turn % 12 == 0 then
		gameState.DiplomaticFavor += 1
	end
	updateStrategyHud()
end)

player.CharacterAdded:Connect(function()
	if mapHud.Visible then
		task.defer(function()
			setCharacterVisible(false)
		end)
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	if not mapHud.Visible or not generatedMapFolder then
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

	local speed = math.max(22, mapCameraHeight * 1.15)
	local nextTarget = mapCameraTarget + direction * speed * deltaTime
	mapCameraTarget = Vector3.new(
		math.clamp(nextTarget.X, mapCameraBounds.MinX, mapCameraBounds.MaxX),
		0,
		math.clamp(nextTarget.Z, mapCameraBounds.MinZ, mapCameraBounds.MaxZ)
	)
	applyMapCamera()
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
makeHeader(singleplayer, "Синглплеер", "Создай цивилизацию, выбери параметры мира и подготовь будущую партию.")

local singleGrid = Instance.new("Frame")
singleGrid.BackgroundTransparency = 1
singleGrid.Size = UDim2.new(1, 0, 0, 432)
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
local countryNameRequired = makeText(singleLeft, "Обязательное поле.", 14, Color3.fromRGB(255, 126, 126), Enum.Font.SourceSansSemibold)
countryNameRequired.Size = UDim2.new(1, 0, 0, 18)
countryNameRequired.Visible = false
local mapSeed = makeField(singleLeft, "Сид карты", "Случайный или свой сид")
local mapWidthSlider = makeSlider(singleLeft, "Ширина карты", 400, MapGenerator.MinMapSize, MapGenerator.MaxMapSize, 50, function(value)
	return tostring(math.floor(value))
end)
local mapLengthSlider = makeSlider(singleLeft, "Длина карты", 400, MapGenerator.MinMapSize, MapGenerator.MaxMapSize, 50, function(value)
	return tostring(math.floor(value))
end)
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
singleRight.BackgroundColor3 = Color3.fromRGB(34, 109, 172)
singleRight.BackgroundTransparency = 0.24
singleRight.BorderSizePixel = 0
singleRight.Position = UDim2.new(0.5, 18, 0, 0)
singleRight.Size = UDim2.new(0.5, -18, 1, 0)
singleRight.Parent = singleGrid
addCorner(singleRight, 6)
addStroke(singleRight, colors.borderSoft, 1, 0.35)
addPadding(singleRight, 16, 16, 16, 16)

local previewTitle = makeText(singleRight, "Готовность партии", 22, colors.gold, Enum.Font.Garamond)
previewTitle.Size = UDim2.new(1, 0, 0, 28)

local previewText = makeText(singleRight, "Карта создаётся по сиду: вода непроходима, горы непроходимы, песок, трава и снег доступны для хода. По краю мира идёт песок, дальше начинается внешнее море.", 17, colors.muted, Enum.Font.SourceSans)
previewText.Position = UDim2.new(0, 0, 0, 42)
previewText.Size = UDim2.new(1, 0, 0, 90)
previewText.TextYAlignment = Enum.TextYAlignment.Top

local saveCountryButton = makeButton(singleRight, "Сохранить страну", 46, colors.gold)
saveCountryButton.Position = UDim2.new(0, 0, 1, -100)
saveCountryButton.Size = UDim2.new(1, 0, 0, 46)

local startGameButton = makeButton(singleRight, "Начать игру", 46, colors.cyan)
startGameButton.Position = UDim2.new(0, 0, 1, -46)
startGameButton.Size = UDim2.new(1, 0, 0, 46)
local startGameGradient = startGameButton:FindFirstChildOfClass("UIGradient")
local startGameNormalGradient = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(62, 162, 224)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 124, 193)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 92, 153)),
})
local startGameErrorGradient = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(210, 78, 78)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(166, 48, 56)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(119, 34, 44)),
})

local singleStatus = makeText(singleplayer, "", 16, colors.green, Enum.Font.SourceSansSemibold)
singleStatus.Size = UDim2.new(1, 0, 0, 24)
singleStatus.TextTransparency = 1

local function setCountryNameError(hasError)
	countryNameRequired.Visible = hasError
	startGameButton.BackgroundColor3 = hasError and Color3.fromRGB(150, 43, 52) or colors.panelDeep
	startGameButton.TextColor3 = hasError and Color3.fromRGB(255, 230, 230) or colors.ivory
	if startGameGradient then
		startGameGradient.Color = hasError and startGameErrorGradient or startGameNormalGradient
	end
end

countryName:GetPropertyChangedSignal("Text"):Connect(function()
	if countryName.Text ~= "" then
		setCountryNameError(false)
	end
end)

local function readSingleplayerSetup()
	local name = countryName.Text

	local seed = mapSeed.Text
	if seed == "" then
		seed = tostring(math.random(100000, 999999))
		mapSeed.Text = seed
	end

	local mapWidth = MapGenerator.ClampDimension(mapWidthSlider.GetValue())
	local mapLength = MapGenerator.ClampDimension(mapLengthSlider.GetValue())

	return name, seed, mapWidth, mapLength
end

saveCountryButton.MouseButton1Click:Connect(function()
	local name, seed, mapWidth, mapLength = readSingleplayerSetup()
	singleStatus.Text = ("Страна \"%s\" сохранена. Карта: %dx%d, сложность: %s, сид: %s, боты: %s."):format(name, mapWidth, mapLength, difficulty.GetValue(), seed, botCount.GetValue())
	singleStatus.TextTransparency = 0
end)

startGameButton.MouseButton1Click:Connect(function()
	local name, seed, mapWidth, mapLength = readSingleplayerSetup()
	if name == "" then
		setCountryNameError(true)
		singleStatus.Text = "Введите название государства перед стартом."
		singleStatus.TextColor3 = Color3.fromRGB(255, 126, 126)
		singleStatus.TextTransparency = 0
		return
	end

	setCountryNameError(false)
	singleStatus.TextColor3 = colors.green
	singleStatus.Text = ("Запуск партии: %s | %dx%d | %s | сид %s | боты: %s."):format(name, mapWidth, mapLength, difficulty.GetValue(), seed, botCount.GetValue())
	singleStatus.TextTransparency = 0
	showLoadingScreen(name, difficulty.GetValue(), seed, botCount.GetValue(), mapWidth, mapLength)
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
