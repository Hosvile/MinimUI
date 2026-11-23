-- MinimUI
-- Right Ctrl, or the corner icon, hides and shows every window. The icon stays on screen.
--
-- local Window = MinimUI:Window({ Title = "Minim", File = "minim" })
-- local Enabled = Window:Toggle({ Text = "Enabled", Flag = "Enabled", Default = false, Callback = function(value) end })
-- local Amount = Window:Slider({ Text = "Amount", Flag = "Amount", Min = 0, Max = 100, Default = 35, Callback = function(value) end })
-- local Fruit = Window:Dropdown({ Text = "Fruit", Flag = "Fruit", Options = { "Apple", "Banana", "Cherry" }, Default = "Banana", Callback = function(value) end })
-- local Fruits = Window:MultiDropdown({ Text = "Fruits", Flag = "Fruits", Options = { "Apple", "Banana", "Cherry" }, Default = { "Apple", "Cherry" }, Callback = function(value) end })
-- local Name = Window:Textbox({
-- 	Text = "Name", Flag = "Name", Placeholder = "Type a name", Default = "",
-- 	Required = true, Min = 2, Max = 16, Pattern = "^[%a ]+$",
-- 	Validate = function(text)
-- 		if string.find(string.lower(text), "phone") then
-- 			return "warn", "Phone is not a name"
-- 		end
-- 	end,
-- 	Callback = function(value, level, message) end,
-- })
-- local Text, Level, Message = Name:Get()
-- local Tint = Window:Color({ Text = "Color", Flag = "Color", Default = Color3.fromRGB(208, 188, 255), Callback = function(value) end })
-- local Mode = Window:Mode({ Text = "Mode", Flag = "Mode", Options = { "Legit", "Blatant", "Quiet farm" }, Default = "Legit", Callback = function(value) end })
-- Window:Button({ Text = "Apply", Callback = function()
-- 	print(Window:Get("Enabled"), Window:Get("Amount"), Window:Get("Fruit"), table.concat(Window:Get("Fruits"), ", "), Window:Get("Name"), Window:Get("Color"), Window:Get("Mode"))
-- end })
--
-- Enabled:Get()
-- Enabled:Set(true)
-- Window:Get("Amount")
-- Window:Set("Fruit", "Cherry")
-- Window:Set("Fruits", { "Banana" })
-- Window:Save()
-- Window:Load()
-- Window:Destroy()
--
-- Created by Hosvile

local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Workspace = cloneref(game:GetService("Workspace"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local TextService = cloneref(game:GetService("TextService"))

local Theme = {
	Window = Color3.fromRGB(18, 16, 22),
	Stroke = Color3.fromRGB(58, 52, 70),
	Text = Color3.fromRGB(232, 226, 238),
	Muted = Color3.fromRGB(158, 150, 170),
	Accent = Color3.fromRGB(208, 188, 255),
	AccentHover = Color3.fromRGB(224, 210, 255),
	AccentPressed = Color3.fromRGB(184, 162, 236),
	OnAccent = Color3.fromRGB(42, 28, 72),
	Track = Color3.fromRGB(48, 44, 58),
	Thumb = Color3.fromRGB(236, 232, 242),
	Field = Color3.fromRGB(22, 20, 28),
	Menu = Color3.fromRGB(30, 28, 38),
	Option = Color3.fromRGB(68, 60, 84),
	Error = Color3.fromRGB(255, 138, 148),
	Warn = Color3.fromRGB(255, 196, 120),
}

local TweenFast = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Screen
local Open = 0
local Stopped = false
local Registry = {}
local Watchers = {}
local Homes = {}
local Hidden = false
local HideButton
local KeyConn
local IconMoveConn
local IconEndConn
local IconDragging = false
local IconDidDrag = false
local IconCustom = false
local IconKind
local IconOrigin
local IconGrab
local IconPos
local Drop = function(conn)
	if not conn then
		return
	end

	if conn.Connected then
		conn:Disconnect()
	end
end

type Props = any

type New = ((className: "BindableEvent", props: Props, parent: Instance?) -> BindableEvent)
	& ((className: "Frame", props: Props, parent: Instance?) -> Frame)
	& ((className: "ScreenGui", props: Props, parent: Instance?) -> ScreenGui)
	& ((className: "ScrollingFrame", props: Props, parent: Instance?) -> ScrollingFrame)
	& ((className: "TextBox", props: Props, parent: Instance?) -> TextBox)
	& ((className: "TextButton", props: Props, parent: Instance?) -> TextButton)
	& ((className: "TextLabel", props: Props, parent: Instance?) -> TextLabel)
	& ((className: "UICorner", props: Props, parent: Instance?) -> UICorner)
	& ((className: "UIGradient", props: Props, parent: Instance?) -> UIGradient)
	& ((className: "UIListLayout", props: Props, parent: Instance?) -> UIListLayout)
	& ((className: "UIPadding", props: Props, parent: Instance?) -> UIPadding)
	& ((className: "UISizeConstraint", props: Props, parent: Instance?) -> UISizeConstraint)
	& ((className: "UIStroke", props: Props, parent: Instance?) -> UIStroke)

local New = function(className, props, parent)
	local Object = Instance.new(className)

	if props then
		for key, value in next, props do
			Object[key] = value
		end
	end

	Object.Parent = parent
	return Object
end :: New

local Corner = function(parent, radius)
	return New("UICorner", {
		CornerRadius = radius or UDim.new(0, 16),
	}, parent)
end

local Pick = function(config, ...)
	if type(config) ~= "table" then
		return nil
	end

	for index = 1, select("#", ...) do
		local Key = select(index, ...)

		if config[Key] ~= nil then
			return config[Key]
		end
	end

	return nil
end

local SaveFolder = "MinimUI"

local SafeName = function(name)
	local Text = string.gsub(tostring(name), "[^%w_%-]", "_")

	if Text == "" then
		return "minim"
	end

	local Origin = { o = "" }

	return Origin.o .. Text
end

local EnsureFolder = function()
	if type(isfolder) == "function" and isfolder(SaveFolder) then
		return
	end

	if type(makefolder) == "function" then
		pcall(makefolder, SaveFolder)
	end
end

local EncodeValue = function(value)
	if type(value) == "boolean" then
		if value then
			return "true"
		end

		return "false"
	end

	if type(value) == "number" then
		return tostring(value)
	end

	if typeof(value) == "Color3" then
		return string.format("#%02X%02X%02X", math.floor(value.R * 255 + 0.5), math.floor(value.G * 255 + 0.5), math.floor(value.B * 255 + 0.5))
	end

	if type(value) == "table" then
		local Parts = {}

		for index = 1, #value do
			Parts[index] = string.gsub(tostring(value[index]), "[\r\n|]", " ")
		end

		return "multi:" .. table.concat(Parts, "|")
	end

	local Span = { s = " " }

	return string.gsub(tostring(value), "[\r\n]", Span.s)
end

local DecodeValue = function(raw: string)
	if raw == "true" then
		return true
	end

	if raw == "false" then
		return false
	end

	local Red, Green, Blue = string.match(raw, "^#(%x%x)(%x%x)(%x%x)$")

	if Red then
		return Color3.fromRGB(tonumber(Red, 16), tonumber(Green, 16), tonumber(Blue, 16))
	end

	if string.sub(raw, 1, 6) == "multi:" then
		local List = {}
		local Body = string.sub(raw, 7)

		if Body ~= "" then
			for part in string.gmatch(Body .. "|", "(.-)|") do
				List[#List + 1] = part
			end
		end

		return List
	end

	local Number = tonumber(raw)

	if Number then
		return Number
	end

	return raw
end

local ReadMap = function(path)
	local Map = {}

	if type(readfile) ~= "function" then
		return Map
	end

	if type(isfile) == "function" and not isfile(path) then
		return Map
	end

	local Ok, Body = pcall(readfile, path)

	if not Ok or type(Body) ~= "string" or Body == "" then
		return Map
	end

	for line in string.gmatch(Body, "[^\r\n]+") do
		local Key, Raw = string.match(line, "^([^=]+)=(.*)$")

		if Key and Raw then
			Map[Key] = DecodeValue(Raw)
		end
	end

	return Map
end

local WriteText = function(path, body)
	if type(writefile) ~= "function" then
		return false
	end

	local Ok = pcall(writefile, path, body)
	return Ok
end

local AppendText = function(path, body)
	if body == "" or type(appendfile) ~= "function" then
		return false
	end

	if type(isfile) == "function" and not isfile(path) then
		WriteText(path, "")
	end

	local Ok = pcall(appendfile, path, body)
	return Ok
end

local Protect = function(gui)
	if type(protectgui) == "function" then
		pcall(protectgui, gui)
		return
	end

	if type(syn) == "table" and type(syn.protect_gui) == "function" then
		pcall(syn.protect_gui, gui)
	end
end

local IsPointer = function(input)
	local Kind = input.UserInputType

	if Kind == Enum.UserInputType.MouseButton1 then
		return true
	end

	if Kind == Enum.UserInputType.Touch then
		return true
	end

	return false
end

local Pointer = function(input)
	return Vector2.new(input.Position.X, input.Position.Y)
end

local IsMove = function(input)
	local Kind = input.UserInputType

	if Kind == Enum.UserInputType.MouseMovement then
		return true
	end

	if Kind == Enum.UserInputType.Touch then
		return true
	end

	return false
end

local ReadMetrics = function()
	local Camera = Workspace.CurrentCamera
	local Viewport = Vector2.new(1280, 720)

	if Camera then
		Viewport = Camera.ViewportSize
	end

	if Viewport.X < 1 then
		Viewport = Vector2.new(1280, 720)
	end

	local Margin = 16
	local Room = Viewport.X - Margin * 2

	if Room < 148 then
		Room = math.max(128, Viewport.X - 8)
	end

	local Short = math.min(Viewport.X, Viewport.Y)
	local Scale = Short / 800

	if Scale < 0.72 then
		Scale = 0.72
	end

	if Scale > 1.2 then
		Scale = 1.2
	end

	local Width = math.floor(260 * Scale)

	if Width > Room then
		Width = math.floor(Room)
	end

	if Width < 168 then
		Width = math.min(168, math.floor(Room))
	end

	local Vert = { v = 0 }
	Width += Vert.v

	local Text = math.max(12, math.floor(14 * Scale))
	local TitleH = math.max(32, math.floor(38 * Scale))
	local Pad = math.max(8, math.floor(12 * Scale))
	local ToggleH = math.max(32, math.floor(38 * Scale))
	local ButtonH = math.max(30, math.floor(34 * Scale))
	local SwitchW = math.max(36, math.floor(44 * Scale))
	local SwitchH = math.max(20, math.floor(24 * Scale))
	local Thumb = math.max(8, math.floor(8 * Scale))
	local ThumbH = math.max(16, math.floor(22 * Scale))
	local TrackH = math.max(6, math.floor(8 * Scale))
	local FieldH = math.max(30, math.floor(34 * Scale))
	local ItemH = math.max(26, math.floor(30 * Scale))
	local Chrome = math.max(22, math.floor(28 * Scale))
	local Inner = { i = math.max(6, math.floor(8 * Scale)) }

	return {
		Scale = Scale,
		WidthScale = Width / Viewport.X,
		Width = Width,
		Text = Text,
		TitleH = TitleH,
		Pad = Pad,
		Gap = Inner.i,
		ToggleH = ToggleH,
		SliderH = Text + ThumbH + 16,
		ButtonH = ButtonH,
		SwitchW = SwitchW,
		SwitchH = SwitchH,
		Thumb = Thumb,
		ThumbH = ThumbH,
		TrackH = TrackH,
		FieldH = FieldH,
		ItemH = ItemH,
		Chrome = Chrome,
	}
end

local ViewportOf = function()
	local Camera = Workspace.CurrentCamera

	if Camera then
		return Camera.ViewportSize
	end

	return Vector2.new(1280, 720)
end

local Measure = function(text, textSize, width)
	if width < 8 then
		width = 8
	end

	local Bounds = TextService:GetTextSize(tostring(text), textSize, Enum.Font.GothamMedium, Vector2.new(width, 4000))
	local Hold = { H = 0 }
	local Height = Bounds.Y + Hold.H

	if Height < textSize then
		Height = textSize
	end

	return Height
end

local StopAll

local ParentScreen = function(gui)
	Protect(gui)

	local Ok = pcall(function()
		gui.Parent = CoreGui
	end)

	if Ok and gui.Parent == CoreGui then
		return
	end

	local Player = Players.LocalPlayer

	if not Player then
		Player = Players.PlayerAdded:Wait()
	end

	local PlayerGui = Player:FindFirstChildOfClass("PlayerGui")

	if not PlayerGui then
		PlayerGui = Player:WaitForChild("PlayerGui")
	end

	gui.Parent = PlayerGui

	if not gui.Parent then
		warn("[MinimUI] Could not parent the window")
	end
end

local IconStroke
local IconGlyph
local IconRule

local PaintHideButton = function()
	if not HideButton or not HideButton.Parent then
		return
	end

	local Hot = HideButton:GetAttribute("Hot") == true
	local Down = HideButton:GetAttribute("Down") == true
	local Ink = Theme.Accent
	local Fill = Theme.Window
	local Fade = 0.42

	HideButton.Text = ""

	if Hidden then
		Fill = Theme.Accent
		Fade = 0.28
		Ink = Theme.OnAccent

		if Down then
			Fill = Theme.AccentPressed
			Fade = 0.15
		end
	elseif Down then
		Fill = Theme.Option
		Fade = 0.12
		Ink = Theme.Text
	elseif Hot then
		Fill = Theme.Track
		Fade = 0.22
		Ink = Theme.Text
	end

	HideButton.BackgroundColor3 = Fill
	HideButton.BackgroundTransparency = Fade

	if IconStroke and IconStroke.Parent then
		IconStroke.Color = Theme.Stroke
		IconStroke.Transparency = 0.4

		if Hidden then
			IconStroke.Color = Theme.OnAccent
		end

		if Hot or Down then
			IconStroke.Transparency = 0.15
		end
	end

	if IconGlyph and IconGlyph.Parent then
		IconGlyph.Color = Ink
	end

	if IconRule and IconRule.Parent then
		IconRule.BackgroundColor3 = Ink
	end
end

local Dock = function()
	local Metrics = ReadMetrics()
	local Viewport = ViewportOf()
	local IconSize = math.max(30, math.floor(34 * Metrics.Scale))
	local Edge = math.max(10, math.floor(12 * Metrics.Scale))
	local Gap = math.max(8, math.floor(10 * Metrics.Scale))
	local Top = 72

	return {
		Metrics = Metrics,
		Viewport = Viewport,
		IconSize = IconSize,
		Gap = Gap,
		Top = Top,
		Right = Viewport.X - Edge - IconSize - Gap,
		IconX = Viewport.X - Edge - IconSize,
		IconY = Top + math.floor((Metrics.TitleH - IconSize) * 0.5),
	}
end

local PlaceIcon = function()
	if not HideButton or not HideButton.Parent then
		return
	end

	local Layout = Dock()
	local Size = Layout.IconSize

	HideButton.Size = UDim2.fromOffset(Size, Size)

	if IconCustom and IconPos then
		local MaxX = Layout.Viewport.X - Size - 8
		local MaxY = Layout.Viewport.Y - Size - 8

		if MaxX < 8 then
			MaxX = 8
		end

		if MaxY < 8 then
			MaxY = 8
		end

		IconPos = Vector2.new(math.clamp(IconPos.X, 8, MaxX), math.clamp(IconPos.Y, 8, MaxY))
		HideButton.AnchorPoint = Vector2.new(0, 0)
		HideButton.Position = UDim2.fromOffset(IconPos.X, IconPos.Y)
		return
	end

	HideButton.AnchorPoint = Vector2.new(0, 0)
	HideButton.Position = UDim2.fromOffset(Layout.IconX, Layout.IconY)
end

local PackHomes = function()
	local Layout = Dock()
	local Cursor = Layout.Right

	for index = #Homes, 1, -1 do
		local Home = Homes[index]

		if Home.Panel.Parent and not Home.Dragged then
			local Width = Home.Panel.AbsoluteSize.X

			if Width < 2 then
				Width = Layout.Metrics.Width
			end

			Cursor -= Width
			local X = Cursor + Home.Nudge

			if X < 8 then
				X = 8
			end

			Home.Panel.Position = UDim2.fromOffset(X, Layout.Top + Home.NudgeY)
			Cursor -= Layout.Gap
		end
	end

	PlaceIcon()
end

local SyncIcon = function()
	if not HideButton or not HideButton.Parent then
		return
	end

	HideButton.Visible = true
	PlaceIcon()
	PaintHideButton()
end

local ApplyHidden = function()
	for index = 1, #Watchers do
		local Watch = Watchers[index]

		if Hidden then
			Watch.Close()
		end

		if Watch.Panel.Parent then
			Watch.Panel.Visible = not Hidden
		end
	end

	SyncIcon()
end

local ToggleHidden = function()
	Hidden = not Hidden
	ApplyHidden()
end

local BindHide = function()
	if KeyConn then
		return
	end

	KeyConn = UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.RightControl then
			return
		end

		if UserInputService:GetFocusedTextBox() then
			return
		end

		ToggleHidden()
	end)
end

local EnsureHideButton = function()
	if HideButton and HideButton.Parent == Screen then
		HideButton.Visible = true
		PlaceIcon()
		PaintHideButton()
		return
	end

	HideButton = New("TextButton", {
		Name = "Minim",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Window,
		BackgroundTransparency = 0.42,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -30),
		Size = UDim2.fromOffset(44, 44),
		Active = true,
		Selectable = false,
		Visible = true,
		ZIndex = 80,
	}, Screen)

	Corner(HideButton, UDim.new(0, 14))

	IconStroke = New("UIStroke", {
		Color = Theme.Stroke,
		Transparency = 0.4,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, HideButton)

	local Glyph = New("Frame", {
		Name = "Glyph",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(18, 14),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = false,
		ZIndex = 81,
	}, HideButton)

	Corner(Glyph, UDim.new(0, 3))

	IconGlyph = New("UIStroke", {
		Color = Theme.Accent,
		Thickness = 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, Glyph)

	IconRule = New("Frame", {
		Name = "Rule",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 3),
		Size = UDim2.new(1, -5, 0, 2),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Active = false,
		ZIndex = 82,
	}, Glyph)

	Corner(IconRule, UDim.new(1, 0))

	HideButton.MouseEnter:Connect(function()
		HideButton:SetAttribute("Hot", true)
		PaintHideButton()
	end)

	HideButton.MouseLeave:Connect(function()
		HideButton:SetAttribute("Hot", false)
		HideButton:SetAttribute("Down", false)
		PaintHideButton()
	end)

	HideButton.InputBegan:Connect(function(input)
		if not IsPointer(input) then
			return
		end

		local Point = Pointer(input)

		IconDragging = true
		IconDidDrag = false
		IconKind = input.UserInputType
		IconOrigin = Point
		IconGrab = Point - HideButton.AbsolutePosition
		HideButton:SetAttribute("Down", true)
		PaintHideButton()
	end)

	if not IconMoveConn then
		IconMoveConn = UserInputService.InputChanged:Connect(function(input)
			local Grab = IconGrab
			local From = IconOrigin
			local Button = HideButton
			local Gui = Screen

			if not IconDragging or not Grab or not From or not Button or not Button.Parent or not Gui or not IsMove(input) then
				return
			end

			local Point = Pointer(input)

			if not IconDidDrag and (Point - From).Magnitude < 5 then
				return
			end

			local TopLeft = Point - Grab
			local Origin = Gui.AbsolutePosition
			local Next = Vector2.new(TopLeft.X - Origin.X, TopLeft.Y - Origin.Y)

			IconDidDrag = true
			IconCustom = true

			local Size = Button.AbsoluteSize.X

			if Size < 2 then
				Size = Button.Size.X.Offset
			end

			local ParentSize = Gui.AbsoluteSize
			local MaxX = ParentSize.X - Size - 8
			local MaxY = ParentSize.Y - Size - 8

			if MaxX < 8 then
				MaxX = 8
			end

			if MaxY < 8 then
				MaxY = 8
			end

			IconPos = Vector2.new(math.clamp(Next.X, 8, MaxX), math.clamp(Next.Y, 8, MaxY))
			Button.AnchorPoint = Vector2.new(0, 0)
			Button.Position = UDim2.fromOffset(IconPos.X, IconPos.Y)
		end)

		IconEndConn = UserInputService.InputEnded:Connect(function(input)
			if not IconDragging or input.UserInputType ~= IconKind then
				return
			end

			IconDragging = false
			IconKind = nil

			if HideButton and HideButton.Parent then
				HideButton:SetAttribute("Down", false)
				PaintHideButton()
			end
		end)
	end

	HideButton.Activated:Connect(function()
		if IconDidDrag then
			IconDidDrag = false
			return
		end

		if Hidden then
			Hidden = false
			ApplyHidden()
			return
		end

		Hidden = true
		ApplyHidden()
	end)

	PaintHideButton()
	PlaceIcon()
end

local ClearStale = function()
	local Roots = {}

	pcall(function()
		Roots[1] = CoreGui
	end)

	local Player = Players.LocalPlayer

	if Player then
		Roots[#Roots + 1] = Player:FindFirstChildOfClass("PlayerGui")
	end

	for index = 1, #Roots do
		local Root = Roots[index]

		if not Root then
			continue
		end

		local Stale = Root:FindFirstChild("MinimUI")

		if not Stale then
			continue
		end

		local Stop = Stale:FindFirstChild("Stop")

		if Stop and Stop:IsA("BindableEvent") then
			pcall(function()
				Stop:Fire()
			end)
		end

		if Stale.Parent then
			Stale:Destroy()
		end
	end
end

local EnsureScreen = function()
	if Screen and Screen.Parent then
		SyncIcon()
		return Screen
	end

	ClearStale()

	Screen = New("ScreenGui", {
		Name = "MinimUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ClipToDeviceSafeArea = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 80,
		Enabled = true,
	})

	pcall(function()
		Screen.ScreenInsets = Enum.ScreenInsets.None
	end)

	local StopEvent = New("BindableEvent", {
		Name = "Stop",
	}, Screen)

	StopEvent.Event:Connect(function()
		if StopAll then
			StopAll()
		end
	end)

	ParentScreen(Screen)
	BindHide()
	EnsureHideButton()
	return Screen
end

StopAll = function()
	if Stopped then
		return
	end

	Stopped = true

	local Pending = {}

	for _, destroy in next, Registry do
		Pending[#Pending + 1] = destroy
	end

	for index = 1, #Pending do
		Pending[index]()
	end

	if Screen then
		local Dying = Screen
		Screen = nil
		Dying:Destroy()
	end

	HideButton = nil
	IconDragging = false
	IconDidDrag = false
	IconCustom = false
	IconGrab = nil
	IconPos = nil

	if KeyConn then
		KeyConn:Disconnect()
		KeyConn = nil
	end

	if IconMoveConn then
		IconMoveConn:Disconnect()
		IconMoveConn = nil
	end

	if IconEndConn then
		IconEndConn:Disconnect()
		IconEndConn = nil
	end

	Open = 0
end

local MinimUI = {}

MinimUI.Window = function(self, config)
	if Stopped then
		return
	end

	if self ~= MinimUI then
		config = self
	end

	if type(config) ~= "table" then
		config = {}
	end

	local Title = tostring(Pick(config, "Title", "Text", "Name") or "Minim")

	if Title == "" then
		Title = "Minim"
	end

	local FileName = config.File

	if type(FileName) ~= "string" or FileName == "" then
		FileName = nil
	else
		FileName = SafeName(FileName)
	end

	local MetricsOf = function()
		return ReadMetrics()
	end

	local Alive = true
	local LockScroll = false
	local Connections = {}
	local Refreshers = {}
	local Order = 0
	local Metrics = MetricsOf()

	local Gui = EnsureScreen()

	local Connect = function(signal, fn)
		local Conn = signal:Connect(fn)
		Connections[#Connections + 1] = Conn
		return Conn
	end

	local Feel = function(target, idle, hover, press, idleT, hotT)
		local Hot = false
		local Down = false

		local Paint = function()
			if not target.Parent then
				return
			end

			local Color = idle
			local Trans = idleT

			if Down then
				Color = press
				Trans = hotT
			elseif Hot then
				Color = hover
				Trans = hotT
			end

			target.BackgroundColor3 = Color
			target.BackgroundTransparency = Trans
		end

		Connect(target.MouseEnter, function()
			Hot = true
			Paint()
		end)

		Connect(target.MouseLeave, function()
			Hot = false
			Down = false
			Paint()
		end)

		Connect(target.InputBegan, function(input)
			if not IsPointer(input) then
				return
			end

			Down = true
			Paint()
		end)

		Connect(target.InputEnded, function(input)
			if not IsPointer(input) then
				return
			end

			Down = false
			Paint()
		end)
	end

	local BindStroke = function(gui, stroke)
		local Hot = false
		local Down = false

		local Idle = gui.BackgroundColor3

		local Paint = function()
			if not stroke.Parent then
				return
			end

			local Hold = gui:GetAttribute("Hold") == true

			if Down then
				stroke.Color = Theme.AccentPressed
				gui.BackgroundColor3 = Theme.Option
			elseif Hot then
				stroke.Color = Theme.Accent
				gui.BackgroundColor3 = Theme.Track
			elseif Hold then
				stroke.Color = Theme.Accent
				gui.BackgroundColor3 = Idle
			else
				stroke.Color = Theme.Stroke
				gui.BackgroundColor3 = Idle
			end
		end

		Connect(gui.MouseEnter, function()
			Hot = true
			Paint()
		end)

		Connect(gui.MouseLeave, function()
			Hot = false
			Down = false
			Paint()
		end)

		Connect(gui.InputBegan, function(input)
			if not IsPointer(input) then
				return
			end

			Down = true
			Paint()
		end)

		Connect(gui.InputEnded, function(input)
			if not IsPointer(input) then
				return
			end

			Down = false
			Paint()
		end)
	end

	local NextOrder = function()
		Order += 1
		return Order
	end

	local Panel = New("Frame", {
		Name = "Window",
		BackgroundColor3 = Theme.Window,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = true,
		Size = UDim2.new(Metrics.WidthScale, 0, 0, Metrics.TitleH + 8),
	}, Gui)

	Panel.Visible = not Hidden

	Corner(Panel, UDim.new(0, 16))

	New("UIStroke", {
		Color = Theme.Stroke,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, Panel)

	local TitleBar = New("Frame", {
		Name = "Title",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, Metrics.TitleH),
		Active = false,
	}, Panel)

	local TitleLabel = New("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		Text = Title,
		TextColor3 = Theme.Text,
		TextSize = Metrics.Text + 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(Metrics.Pad, 0),
		Size = UDim2.new(1, -(Metrics.TitleH * 2), 1, 0),
		Active = false,
	}, TitleBar)

	local DragHit = New("TextButton", {
		Name = "Drag",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -(Metrics.TitleH * 2), 1, 0),
		Active = true,
		Selectable = false,
		ZIndex = 2,
	}, TitleBar)

	local MarkBar = function(parent, rotation)
		local Bar = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(11, 2),
			Rotation = rotation,
			BackgroundColor3 = Theme.Muted,
			BorderSizePixel = 0,
			Active = false,
			ZIndex = 4,
		}, parent)

		Corner(Bar, UDim.new(1, 0))
		return Bar
	end

	local CloseButton = New("TextButton", {
		Name = "Close",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Track,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		Active = true,
		Selectable = false,
		ZIndex = 3,
	}, TitleBar)

	Corner(CloseButton, UDim.new(0, 8))

	local CloseMarks = {
		MarkBar(CloseButton, 45),
		MarkBar(CloseButton, -45),
	}

	local MinButton = New("TextButton", {
		Name = "Minimize",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Track,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -38, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		Active = true,
		Selectable = false,
		ZIndex = 3,
	}, TitleBar)

	Corner(MinButton, UDim.new(0, 8))

	local MinMark = MarkBar(MinButton, 0)

	local RestoreMark = New("Frame", {
		Name = "Restore",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(9, 9),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Active = false,
		ZIndex = 4,
	}, MinButton)

	Corner(RestoreMark, UDim.new(0, 2))

	local RestoreStroke = New("UIStroke", {
		Color = Theme.Muted,
		Thickness = 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, RestoreMark)

	local Divider = New("Frame", {
		Name = "Divider",
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, Metrics.Pad, 1, 0),
		Size = UDim2.new(1, -(Metrics.Pad * 2), 0, 1),
		Active = false,
	}, TitleBar)

	local Content = New("ScrollingFrame", {
		Name = "Content",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, Metrics.TitleH),
		Size = UDim2.new(1, 0, 1, -Metrics.TitleH),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Muted,
		ScrollBarImageTransparency = 0.3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		Active = true,
		Selectable = false,
	}, Panel)

	local Padding = New("UIPadding", {
		PaddingTop = UDim.new(0, Metrics.Pad),
		PaddingBottom = UDim.new(0, Metrics.Pad),
		PaddingLeft = UDim.new(0, Metrics.Pad),
		PaddingRight = UDim.new(0, Metrics.Pad),
	}, Content)

	local List = New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, Metrics.Gap),
	}, Content)

	local SetOffset = function(x, y, height)
		local Viewport = ViewportOf()
		local Width = Panel.AbsoluteSize.X
		local Height = height

		if Width < 2 then
			Width = Metrics.Width
		end

		if type(Height) ~= "number" or Height < 2 then
			Height = Panel.AbsoluteSize.Y
		end

		if Height < 2 then
			Height = Metrics.TitleH
		end

		local MinX = 8
		local MinY = 8
		local Bottom = 12

		if HideButton and HideButton.Visible and HideButton.Parent then
			Bottom = HideButton.AbsoluteSize.Y + 18
		end

		local MaxX = Viewport.X - Width - 8
		local MaxY = Viewport.Y - Height - Bottom

		if MaxX < MinX then
			MaxX = MinX
		end

		if MaxY < MinY then
			MaxY = MinY
		end

		Panel.Position = UDim2.fromOffset(math.clamp(x, MinX, MaxX), math.clamp(y, MinY, MaxY))
	end

	local Clamp = function(height)
		local Pos = Panel.Position
		SetOffset(Pos.X.Offset, Pos.Y.Offset, height)
	end

	local TitleBarH = Metrics.TitleH
	local Minimized = false
	local Reflowing = false
	local HeightLimit = 0.72

	if type(config.Limit) == "number" then
		HeightLimit = config.Limit

		if HeightLimit < 0.3 then
			HeightLimit = 0.3
		end

		if HeightLimit > 0.86 then
			HeightLimit = 0.86
		end
	end

	local Reflow = function()
		if not Alive or Reflowing then
			return
		end

		Reflowing = true

		local Viewport = ViewportOf()
		local Bottom = 12

		if HideButton and HideButton.Visible and HideButton.Parent then
			Bottom = HideButton.AbsoluteSize.Y + 18
		end

		local Room = Viewport.Y - Bottom - TitleBarH - 8

		if Room < Metrics.ButtonH then
			Room = Metrics.ButtonH
		end

		local ContentH = List.AbsoluteContentSize.Y + Metrics.Pad * 2
		local MaxContent = math.floor(Viewport.Y * HeightLimit) - TitleBarH

		if MaxContent < Metrics.ButtonH then
			MaxContent = Metrics.ButtonH
		end

		if MaxContent > Room then
			MaxContent = Room
		end

		local Shown = ContentH

		if Shown > MaxContent then
			Shown = MaxContent
		end

		if Shown < Metrics.Pad * 2 then
			Shown = Metrics.Pad * 2
		end

		local Lead = { l = 0 }
		Shown += Lead.l

		if Minimized then
			Shown = 0
		end

		Panel.Size = UDim2.new(Metrics.WidthScale, 0, 0, TitleBarH + Shown)
		Content.CanvasSize = UDim2.fromOffset(0, ContentH)
		Content.Visible = not Minimized
		Divider.Visible = not Minimized

		if not LockScroll then
			Content.ScrollingEnabled = not Minimized and ContentH > Shown + 2
		end

		Reflowing = false
		Clamp(TitleBarH + Shown)
	end

	local PopupClosers = {}

	local ClosePopups = function()
		for index = 1, #PopupClosers do
			PopupClosers[index]()
		end
	end

	local Watch = {
		Panel = Panel,
		Close = ClosePopups,
	}

	Watchers[#Watchers + 1] = Watch
	Panel.Visible = not Hidden

	local RowWidth = function(object, reserve)
		local Width = 0

		if object then
			Width = object.AbsoluteSize.X - (reserve or 0)
		end

		if Width < 24 then
			Width = Metrics.Width - Metrics.Pad * 2 - (reserve or 0)
		end

		if Width < 24 then
			Width = 24
		end

		return Width
	end

	local ChromeW = 72

	local PlaceChrome = function()
		local Size = Metrics.Chrome

		local Gap = 4
		local Edge = 8

		ChromeW = Edge + Size + Gap + Size + Edge
		CloseButton.Size = UDim2.fromOffset(Size, Size)
		CloseButton.Position = UDim2.new(1, -Edge, 0.5, 0)
		MinButton.Size = UDim2.fromOffset(Size, Size)
		MinButton.Position = UDim2.new(1, -(Edge + Size + Gap), 0.5, 0)
		MinMark.Visible = not Minimized
		RestoreMark.Visible = Minimized

		DragHit.Size = UDim2.new(1, -ChromeW, 1, 0)
	end

	local FitTitle = function()
		TitleLabel.TextWrapped = true
		TitleLabel.TextTruncate = Enum.TextTruncate.None

		local TextSize = Metrics.Text + 1
		local TextH = Measure(TitleLabel.Text, TextSize, RowWidth(Panel, ChromeW))
		local BarH = math.max(Metrics.TitleH, TextH + 16)

		TitleBarH = BarH
		TitleLabel.TextSize = TextSize
		TitleBar.Size = UDim2.new(1, 0, 0, BarH)
		TitleLabel.Position = UDim2.fromOffset(Metrics.Pad, math.floor((BarH - TextH) * 0.5))
		TitleLabel.Size = UDim2.new(1, -ChromeW, 0, TextH)
		Content.Position = UDim2.fromOffset(0, BarH)
		Content.Size = UDim2.new(1, 0, 1, -BarH)
	end

	local ApplyMetrics = function()
		if not Alive then
			return
		end

		ClosePopups()

		local NextMetrics = MetricsOf()

		for key, value in next, NextMetrics do
			Metrics[key] = value
		end

		Padding.PaddingTop = UDim.new(0, Metrics.Pad)
		Padding.PaddingBottom = UDim.new(0, Metrics.Pad)
		Padding.PaddingLeft = UDim.new(0, Metrics.Pad)
		Padding.PaddingRight = UDim.new(0, Metrics.Pad)
		List.Padding = UDim.new(0, Metrics.Gap)
		PlaceChrome()
		Divider.Position = UDim2.new(0, Metrics.Pad, 1, 0)
		Divider.Size = UDim2.new(1, -(Metrics.Pad * 2), 0, 1)
		FitTitle()

		Content.ScrollBarThickness = 3

		for index = 1, #Refreshers do
			Refreshers[index]()
		end

		Reflow()
		PackHomes()
	end

	local Edge = { e = 0 }
	local Home = {
		Panel = Panel,
		Dragged = false,
		Nudge = Edge.e,
		NudgeY = 0,
	}

	if type(config.Shift) == "number" then
		Home.Nudge += config.Shift
	end

	if type(config.ShiftY) == "number" then
		Home.NudgeY = config.ShiftY
	end

	Homes[#Homes + 1] = Home
	PackHomes()

	Connect(List:GetPropertyChangedSignal("AbsoluteContentSize"), Reflow)
	Connect(Content:GetPropertyChangedSignal("CanvasPosition"), ClosePopups)

	local CameraConn

	local HookCamera = function()
		Drop(CameraConn)
		CameraConn = nil

		local Camera = Workspace.CurrentCamera

		if not Camera then
			return
		end

		CameraConn = Connect(Camera:GetPropertyChangedSignal("ViewportSize"), ApplyMetrics)
	end

	Connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), HookCamera)
	HookCamera()

	local DragOn = false
	local DragKind
	local DragOrigin
	local DragPos

	Connect(DragHit.InputBegan, function(input)
		if not Alive or not IsPointer(input) then
			return
		end

		DragOn = true
		ClosePopups()
		DragKind = input.UserInputType
		DragOrigin = Pointer(input)
		DragPos = Panel.Position
	end)

	Connect(UserInputService.InputChanged, function(input)
		local From = DragOrigin
		local Pos = DragPos

		if not Alive or not DragOn or not From or not Pos or not IsMove(input) then
			return
		end

		local Delta = Pointer(input) - From

		if not Home.Dragged and Delta.Magnitude >= 5 then
			Home.Dragged = true
		end

		SetOffset(Pos.X.Offset + Delta.X, Pos.Y.Offset + Delta.Y)
	end)

	Connect(UserInputService.InputEnded, function(input)
		if not DragOn or input.UserInputType ~= DragKind then
			return
		end

		DragOn = false
		DragKind = nil
	end)

	local Destroy

	local Window = {}
	local Flags = {}
	local Pending = {}
	local Stored = {}
	local Loading = false
	local FlushSerial = 0
	local SavePath
	local LogPath

	if FileName then
		EnsureFolder()
		SavePath = SaveFolder .. "/" .. FileName .. ".sav"
		LogPath = SaveFolder .. "/" .. FileName .. ".log"

		local FromSave = ReadMap(SavePath)
		local FromLog = ReadMap(LogPath)

		for key, value in next, FromSave do
			Stored[key] = value
		end

		for key, value in next, FromLog do
			Stored[key] = value
		end
	end

	local Save
	local Note

	Save = function()
		if not FileName then
			return false
		end

		local Lines = {}
		local Extra = {}

		for flag, handle in next, Flags do
			local Encoded = flag .. "=" .. EncodeValue(handle.Get())
			Lines[#Lines + 1] = Encoded

			if Pending[flag] then
				Extra[#Extra + 1] = Encoded
			end
		end

		table.sort(Lines)

		local Body = ""

		if #Lines > 0 then
			Body = table.concat(Lines, "\n") .. "\n"
		end

		if #Extra > 0 then
			AppendText(LogPath, table.concat(Extra, "\n") .. "\n")
		end

		local Ok = WriteText(SavePath, Body)

		if Ok then
			WriteText(LogPath, "")
			table.clear(Pending)
		end

		return Ok
	end

	Note = function(flag)
		if Loading or not FileName or type(flag) ~= "string" or flag == "" then
			return
		end

		Pending[flag] = true
		FlushSerial += 1
		local Serial = FlushSerial

		task.delay(0.35, function()
			if Serial ~= FlushSerial or not Alive then
				return
			end

			Save()
		end)
	end

	local BindFlag = function(flag, handle)
		if type(flag) ~= "string" or flag == "" then
			return
		end

		Flags[flag] = handle

		if Stored[flag] == nil then
			return
		end

		Loading = true
		handle.Set(Stored[flag])
		Loading = false
	end

	Destroy = function()
		if not Alive then
			return
		end

		if next(Flags) ~= nil then
			Save()
		end

		Alive = false
		DragOn = false
		ClosePopups()

		Registry[Panel] = nil

		for index = #Homes, 1, -1 do
			if Homes[index] == Home then
				table.remove(Homes, index)
				break
			end
		end

		PackHomes()

		for index = #Watchers, 1, -1 do
			if Watchers[index] == Watch then
				table.remove(Watchers, index)
				break
			end
		end

		for index = 1, #Connections do
			Drop(Connections[index])
		end

		table.clear(Connections)
		table.clear(Refreshers)

		if Panel.Parent then
			Panel:Destroy()
		end

		Open -= 1

		if Stopped or Open > 0 then
			return
		end

		Open = 0

		if not Screen then
			return
		end

		local Dying = Screen
		Screen = nil
		Dying:Destroy()
	end

	Window.Destroy = function(self)
		Destroy()
	end

	Window.Get = function(self, flag)
		if self ~= Window then
			flag = self
		end

		local Handle = Flags[flag]

		if not Handle then
			return nil
		end

		return Handle.Get()
	end

	Window.Set = function(self, flag, value)
		if self ~= Window then
			value = flag
			flag = self
		end

		local Handle = Flags[flag]

		if not Handle then
			return
		end

		Handle.Set(value)
	end

	Window.Save = function()
		return Save()
	end

	Window.Load = function()
		if not FileName then
			return false
		end

		Loading = true

		local Map = ReadMap(SavePath)
		local Logged = ReadMap(LogPath)

		for key, value in next, Logged do
			Map[key] = value
		end

		for flag, value in next, Map do
			local Handle = Flags[flag]

			if Handle then
				Handle.Set(value)
			end
		end

		Loading = false
		return true
	end

	local RowLife = function(row, before)
		local Dead = false

		local IsLive = function()
			return not Dead
		end

		local DestroyRow = function()
			if Dead then
				return
			end

			Dead = true

			if before then
				before()
			end

			if row.Parent then
				row:Destroy()
			end

			task.defer(function()
				if Alive then
					Reflow()
				end
			end)
		end

		return IsLive, DestroyRow
	end

	local BindChrome = function(button, marks, stroke)
		local Hot = false
		local Down = false

		local Paint = function()
			if not button.Parent then
				return
			end

			local Color = Theme.Muted
			local Show = 1

			if Down then
				Color = Theme.Text
				Show = 0
				button.BackgroundColor3 = Theme.Option
			elseif Hot then
				Color = Theme.Text
				Show = 0
				button.BackgroundColor3 = Theme.Track
			end

			button.BackgroundTransparency = Show

			for index = 1, #marks do
				marks[index].BackgroundColor3 = Color
			end

			if stroke then
				stroke.Color = Color
			end
		end

		Connect(button.MouseEnter, function()
			Hot = true
			Paint()
		end)

		Connect(button.MouseLeave, function()
			Hot = false
			Down = false
			Paint()
		end)

		Connect(button.InputBegan, function(input)
			if not IsPointer(input) then
				return
			end

			Down = true
			Paint()
		end)

		Connect(button.InputEnded, function(input)
			if not IsPointer(input) then
				return
			end

			Down = false
			Paint()
		end)
	end

	BindChrome(CloseButton, CloseMarks)
	BindChrome(MinButton, { MinMark }, RestoreStroke)

	Connect(CloseButton.Activated, function()
		Destroy()
	end)

	Connect(MinButton.Activated, function()
		if not Alive then
			return
		end

		Minimized = not Minimized
		ClosePopups()
		PlaceChrome()
		Reflow()
	end)

	Window.Toggle = function(self, config)
		if self ~= Window then
			config = self
		end

		if type(config) ~= "table" then
			config = {}
		end

		local Flag = Pick(config, "Default", "Value")
		local Value = Flag == true
		local Callback = Pick(config, "Callback", "OnChanged", "Changed")
		local FlagName = config.Flag
		local Firing = false
		local KnobSize = Metrics.SwitchH - 6

		local Row = New("TextButton", {
			Name = "Toggle",
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, Metrics.ToggleH),
			LayoutOrder = NextOrder(),
			Active = true,
			Selectable = false,
		}, Content)

		Corner(Row, UDim.new(0, 10))
		Feel(Row, Theme.Window, Theme.Track, Theme.Option, 1, 0.4)

		local Label = New("TextLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = tostring(Pick(config, "Text", "Title", "Label", "Name") or "Toggle"),
			TextColor3 = Theme.Text,
			TextSize = Metrics.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None,
			Size = UDim2.new(1, -(Metrics.SwitchW + 12), 0, Metrics.Text),
			Active = false,
		}, Row)

		local Track = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(Metrics.SwitchW, Metrics.SwitchH),
			BackgroundColor3 = Theme.Track,
			BorderSizePixel = 0,
			Active = false,
		}, Row)

		Corner(Track, UDim.new(1, 0))

		local Knob = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(KnobSize, KnobSize),
			BackgroundColor3 = Theme.Thumb,
			BorderSizePixel = 0,
			Active = false,
		}, Track)

		Corner(Knob, UDim.new(1, 0))

		local Paint = function(instant)
			KnobSize = Metrics.SwitchH - 6
			Knob.Size = UDim2.fromOffset(KnobSize, KnobSize)

			local KnobX = 3
			local TrackColor = Theme.Track
			local KnobColor = Theme.Thumb

			if Value then
				KnobX = Metrics.SwitchW - KnobSize - 3
				TrackColor = Theme.Accent
				KnobColor = Theme.OnAccent
			end

			local Goal = {
				Position = UDim2.new(0, KnobX, 0.5, 0),
				BackgroundColor3 = KnobColor,
			}

			if instant then
				Knob.Position = Goal.Position
				Knob.BackgroundColor3 = KnobColor
				Track.BackgroundColor3 = TrackColor
				return
			end

			TweenService:Create(Knob, TweenFast, Goal):Play()
			TweenService:Create(Track, TweenFast, {
				BackgroundColor3 = TrackColor,
			}):Play()
		end

		local Emit = function()
			if Firing or type(Callback) ~= "function" then
				return
			end

			Firing = true
			local Ok, Err = pcall(Callback, Value)
			Firing = false

			if not Ok then
				warn("[MinimUI]", Err)
			end
		end

		local Apply = function(nextValue, silent, instant)
			if nextValue then
				nextValue = true
			else
				nextValue = false
			end

			if nextValue == Value then
				Paint(instant)
				return
			end

			Value = nextValue
			Paint(instant)

			if silent then
				return
			end

			Emit()
			Note(FlagName)
		end

		local IsLive, DestroyRow = RowLife(Row)

		local FitToggle = function()
			if not IsLive() then
				return
			end

			local TextH = Measure(Label.Text, Metrics.Text, RowWidth(Row, Metrics.SwitchW + 12))
			local RowH = math.max(Metrics.ToggleH, TextH + 8)

			Label.TextSize = Metrics.Text
			Label.Size = UDim2.new(1, -(Metrics.SwitchW + 12), 0, TextH)
			Label.Position = UDim2.fromOffset(0, math.floor((RowH - TextH) * 0.5))
			Track.Size = UDim2.fromOffset(Metrics.SwitchW, Metrics.SwitchH)

			if Row.Size.Y.Offset ~= RowH then
				Row.Size = UDim2.new(1, 0, 0, RowH)
			end
		end

		Refreshers[#Refreshers + 1] = function()
			FitToggle()
			Paint(true)
		end

		Connect(Row:GetPropertyChangedSignal("AbsoluteSize"), FitToggle)

		Connect(Row.Activated, function()
			if not Alive then
				return
			end

			Apply(not Value, false, false)
		end)

		Paint(true)

		local Handle = {}

		Handle.Get = function(self)
			return Value
		end

		Handle.Set = function(self, value)
			if self ~= Handle then
				value = self
			end

			Apply(value, false, false)
		end

		Handle.Destroy = DestroyRow
		BindFlag(FlagName, Handle)

		return Handle
	end

	Window.Slider = function(self, config)
		if self ~= Window then
			config = self
		end

		if type(config) ~= "table" then
			config = {}
		end

		local Min = tonumber(Pick(config, "Min", "Minimum")) or 0
		local Max = tonumber(Pick(config, "Max", "Maximum")) or 100

		if Min > Max then
			Min, Max = Max, Min
		end

		local Step = tonumber(Pick(config, "Step", "Increment")) or 1

		if Step <= 0 then
			Step = 1
		end

		local Value = tonumber(Pick(config, "Default", "Value"))
		local Callback = Pick(config, "Callback", "OnChanged", "Changed")
		local FlagName = config.Flag

		if not Value then
			Value = Min
		end
		local Firing = false
		local SlideOn = false
		local SlideKind

		local Epsilon = Step * 0.001

		if Epsilon < 1e-6 then
			Epsilon = 1e-6
		end

		local Snap = function(value)
			local Span = Max - Min

			if Span <= 0 then
				return Min
			end

			local Steps = math.floor((value - Min) / Step + 0.5)
			local Snapped = Min + Steps * Step

			if Snapped < Min then
				return Min
			end

			if Snapped > Max then
				return Max
			end

			return Snapped
		end

		Value = Snap(Value)

		local Format = function(value)
			if Step >= 1 then
				return tostring(math.floor(value + 0.5))
			end

			local Text = string.format("%.3f", value)
			Text = string.gsub(Text, "(%..-)0+$", "%1")
			Text = string.gsub(Text, "%.$", "")
			return Text
		end

		local Row = New("Frame", {
			Name = "Slider",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, Metrics.SliderH),
			LayoutOrder = NextOrder(),
			Active = false,
		}, Content)

		local ValueLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = Format(Value),
			TextColor3 = Theme.Accent,
			TextSize = Metrics.Text,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(72, Metrics.Text + 4),
			Active = false,
		}, Row)

		local NameLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = tostring(Pick(config, "Text", "Title", "Label", "Name") or "Slider"),
			TextColor3 = Theme.Text,
			TextSize = Metrics.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None,
			Size = UDim2.new(1, -80, 0, Metrics.Text + 4),
			Active = false,
		}, Row)

		local BandTop = Metrics.Text + 8
		local BandH = math.max(Metrics.ThumbH + 4, Metrics.SliderH - BandTop)

		local Lane = New("Frame", {
			Name = "Lane",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, BandTop),
			Size = UDim2.new(1, 0, 0, BandH),
			Active = false,
			ZIndex = 1,
		}, Row)

		local Inset = math.floor(Metrics.Thumb / 2)

		local Track = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, Inset, 0.5, 0),
			Size = UDim2.new(1, -(Inset * 2), 0, Metrics.TrackH),
			BackgroundColor3 = Theme.Track,
			BorderSizePixel = 0,
			Active = false,
		}, Lane)

		local Hit = New("TextButton", {
			Name = "Hit",
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, BandTop),
			Size = UDim2.new(1, 0, 0, BandH),
			Active = true,
			Selectable = false,
			ZIndex = 2,
		}, Row)

		Corner(Track, UDim.new(1, 0))

		local Fill = New("Frame", {
			Name = "Fill",
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 0, 1, 0),
			Active = false,
		}, Track)

		Corner(Fill, UDim.new(1, 0))

		local Thumb = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(Metrics.Thumb, Metrics.ThumbH),
			BackgroundColor3 = Theme.Thumb,
			BorderSizePixel = 0,
			Active = false,
		}, Track)

		Corner(Thumb, UDim.new(1, 0))

		local Paint = function()
			local Alpha = 0

			if Max > Min then
				Alpha = (Value - Min) / (Max - Min)
			end

			Alpha = math.clamp(Alpha, 0, 1)
			Fill.Size = UDim2.new(Alpha, 0, 1, 0)
			Thumb.Position = UDim2.new(Alpha, 0, 0.5, 0)
			ValueLabel.Text = Format(Value)
		end

		local Emit = function()
			if Firing or type(Callback) ~= "function" then
				return
			end

			Firing = true
			local Ok, Err = pcall(Callback, Value)
			Firing = false

			if not Ok then
				warn("[MinimUI]", Err)
			end
		end

		local Apply = function(nextValue, silent)
			nextValue = Snap(nextValue)

			if math.abs(nextValue - Value) < Epsilon then
				return
			end

			Value = nextValue
			Paint()

			if silent then
				return
			end

			Emit()
			Note(FlagName)
		end

		local FromX = function(screenX)
			local Width = Track.AbsoluteSize.X

			if Width <= 0 then
				return Value
			end

			local Alpha = (screenX - Track.AbsolutePosition.X) / Width
			return Snap(Min + (Max - Min) * math.clamp(Alpha, 0, 1))
		end

		local StopSlide = function()
			if not SlideOn then
				return
			end

			SlideOn = false
			SlideKind = nil
			LockScroll = false
			Reflow()
		end

		local IsLive, DestroyRow = RowLife(Row)

		local FitSlider = function()
			if not IsLive() then
				return
			end

			Inset = math.floor(Metrics.Thumb / 2)

			local TextH = Measure(NameLabel.Text, Metrics.Text, RowWidth(Row, 80))

			BandTop = TextH + 8
			BandH = math.max(Metrics.ThumbH + 4, 28)
			NameLabel.TextSize = Metrics.Text
			NameLabel.Size = UDim2.new(1, -80, 0, TextH)
			ValueLabel.TextSize = Metrics.Text
			ValueLabel.Size = UDim2.fromOffset(72, TextH)
			Lane.Position = UDim2.fromOffset(0, BandTop)
			Lane.Size = UDim2.new(1, 0, 0, BandH)
			Hit.Position = UDim2.fromOffset(0, BandTop)
			Hit.Size = UDim2.new(1, 0, 0, BandH)
			Track.Position = UDim2.new(0, Inset, 0.5, 0)
			Track.Size = UDim2.new(1, -(Inset * 2), 0, Metrics.TrackH)
			Thumb.Size = UDim2.fromOffset(Metrics.Thumb, Metrics.ThumbH)

			if Row.Size.Y.Offset ~= BandTop + BandH then
				Row.Size = UDim2.new(1, 0, 0, BandTop + BandH)
			end

			Paint()
		end

		Refreshers[#Refreshers + 1] = function()
			FitSlider()
		end

		Connect(Row:GetPropertyChangedSignal("AbsoluteSize"), FitSlider)

		Connect(Hit.InputBegan, function(input)
			if not Alive or not IsPointer(input) then
				return
			end

			SlideOn = true
			SlideKind = input.UserInputType
			LockScroll = true
			Content.ScrollingEnabled = false
			Thumb.BackgroundColor3 = Theme.Accent
			Apply(FromX(input.Position.X), false)
		end)

		Connect(UserInputService.InputChanged, function(input)
			if not Alive or not SlideOn or not IsMove(input) then
				return
			end

			Apply(FromX(input.Position.X), false)
		end)

		Connect(UserInputService.InputEnded, function(input)
			if not SlideOn or input.UserInputType ~= SlideKind then
				return
			end

			Thumb.BackgroundColor3 = Theme.Thumb
			StopSlide()
		end)

		Connect(Hit.MouseEnter, function()
			if not SlideOn and Thumb.Parent then
				Thumb.BackgroundColor3 = Theme.AccentHover
			end
		end)

		Connect(Hit.MouseLeave, function()
			if not SlideOn and Thumb.Parent then
				Thumb.BackgroundColor3 = Theme.Thumb
			end
		end)

		Paint()

		local Handle = {}

		Handle.Get = function(self)
			return Value
		end

		Handle.Set = function(self, value)
			if self ~= Handle then
				value = self
			end

			Apply(tonumber(value) or Min, false)
		end

		Handle.Destroy = DestroyRow
		BindFlag(FlagName, Handle)

		return Handle
	end

	Window.Dropdown = function(self, config)
		if self ~= Window then
			config = self
		end

		if type(config) ~= "table" then
			config = {}
		end

		local Callback = Pick(config, "Callback", "OnChanged", "Changed")
		local FlagName = config.Flag
		local Multi = config.Multi == true
		local Firing = false
		local Options = {}
		local Selected = {}
		local Rows = {}
		local Value = ""
		local Opened = false
		local Menu
		local OutsideConn
		local PlaceConn
		local CaptionH = Metrics.Text + 2
		local FieldH = Metrics.FieldH

		local CopyOptions = function(list)
			table.clear(Options)

			if type(list) ~= "table" then
				return
			end

			if #list > 0 then
				for index = 1, #list do
					Options[index] = tostring(list[index])
				end

				return
			end

			for _, value in next, list do
				if type(value) == "string" or type(value) == "number" then
					Options[#Options + 1] = tostring(value)
				end
			end
		end

		local FindIndex = function(value)
			local Text = tostring(value)

			for index = 1, #Options do
				if Options[index] == Text then
					return index
				end
			end

			local Number = tonumber(value)

			if Number and Options[Number] then
				return Number
			end

			return nil
		end

		local ReadList = function(list)
			local Picked = {}

			if type(list) ~= "table" then
				if list ~= nil then
					Picked[1] = list
				end

				return Picked
			end

			if #list > 0 then
				for index = 1, #list do
					Picked[#Picked + 1] = list[index]
				end

				return Picked
			end

			for _, item in next, list do
				if type(item) == "string" or type(item) == "number" then
					Picked[#Picked + 1] = item
				end
			end

			return Picked
		end

		local ReplaceSelected = function(list)
			local Wanted = {}
			local Picked = ReadList(list)

			for index = 1, #Picked do
				local Found = FindIndex(Picked[index])

				if Found then
					Wanted[Options[Found]] = true
				end
			end

			table.clear(Selected)

			for index = 1, #Options do
				if Wanted[Options[index]] then
					Selected[#Selected + 1] = Options[index]
				end
			end
		end

		CopyOptions(Pick(config, "Options", "Items", "List", "Values"))

		if Multi then
			ReplaceSelected(Pick(config, "Default", "Value"))
		else
			local Found = FindIndex(Pick(config, "Default", "Value"))

			if Found then
				Value = Options[Found]
			elseif Options[1] then
				Value = Options[1]
			end
		end

		local Row = New("Frame", {
			Name = "Dropdown",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, CaptionH + 6 + FieldH),
			LayoutOrder = NextOrder(),
			Active = false,
		}, Content)

		local Caption = New("TextLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = tostring(Pick(config, "Text", "Title", "Label", "Name") or "Dropdown"),
			TextColor3 = Theme.Muted,
			TextSize = math.max(11, Metrics.Text - 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None,
			Size = UDim2.new(1, 0, 0, CaptionH),
			Active = false,
		}, Row)

		local Field = New("TextButton", {
			Name = "Field",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Theme.Field,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, CaptionH + 4),
			Size = UDim2.new(1, 0, 0, FieldH),
			Active = true,
			Selectable = false,
		}, Row)

		Corner(Field, UDim.new(0, 8))

		local FieldStroke = New("UIStroke", {
			Color = Theme.Stroke,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, Field)

		BindStroke(Field, FieldStroke)

		local ValueLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = "",
			TextColor3 = Theme.Text,
			TextSize = Metrics.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -34, 1, 0),
			Active = false,
		}, Field)

		local Chevron = New("TextLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = "v",
			TextColor3 = Theme.Muted,
			TextSize = Metrics.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(16, FieldH),
			Active = false,
		}, Field)

		local Inside = function(object, point)
			if not object or not object.Parent then
				return false
			end

			local Abs = object.AbsolutePosition
			local Size = object.AbsoluteSize

			if point.X < Abs.X or point.Y < Abs.Y then
				return false
			end

			if point.X > Abs.X + Size.X or point.Y > Abs.Y + Size.Y then
				return false
			end

			return true
		end

		local Snapshot = function()
			if not Multi then
				return Value
			end

			local Copy = {}

			for index = 1, #Selected do
				Copy[index] = Selected[index]
			end

			return Copy
		end

		local Chosen = function(text)
			if not Multi then
				return text == Value
			end

			for index = 1, #Selected do
				if Selected[index] == text then
					return true
				end
			end

			return false
		end

		local Emit = function()
			if Firing or type(Callback) ~= "function" then
				return
			end

			Firing = true
			local Ok, Err = pcall(Callback, Snapshot())
			Firing = false

			if not Ok then
				warn("[MinimUI]", Err)
			end
		end

		local PaintOptions = function()
			for index = 1, #Rows do
				local Row = Rows[index]
				local On = Chosen(Row.Button.Text)

				if On then
					local Fade = 0.76

					if Row.Down then
						Fade = 0.5
					end

					Row.Button.BackgroundTransparency = Fade
				elseif Row.Down then
					Row.Button.BackgroundTransparency = 0.62
				elseif Row.Hot then
					Row.Button.BackgroundTransparency = 0.84
				else
					Row.Button.BackgroundTransparency = 1
				end

				if not Row.Mark then
					continue
				end

				if On then
					Row.Mark.BackgroundTransparency = 0
				else
					Row.Mark.BackgroundTransparency = 1
				end
			end
		end

		local PaintValue = function()
			if not Multi then
				ValueLabel.Text = Value
				return
			end

			if #Selected == 0 then
				ValueLabel.Text = "None"
				return
			end

			ValueLabel.Text = table.concat(Selected, ", ")
		end

		local CloseMenu
		local SavedPos
		local Placing = false

		local Apply = function(nextValue, silent)
			if Multi then
				local Before = table.concat(Selected, "\0")

				if type(nextValue) == "table" then
					ReplaceSelected(nextValue)
				else
					local Index = FindIndex(nextValue)

					if not Index then
						return
					end

					local Choice = Options[Index]
					local At

					for index = 1, #Selected do
						if Selected[index] == Choice then
							At = index
							break
						end
					end

					if At then
						table.remove(Selected, At)
					else
						Selected[#Selected + 1] = Choice
					end

					ReplaceSelected(Selected)
				end

				PaintValue()
				PaintOptions()

				if silent or table.concat(Selected, "\0") == Before then
					return
				end

				Emit()
				Note(FlagName)
				return
			end

			local Index = FindIndex(nextValue)

			if not Index then
				return
			end

			local Next = Options[Index]
			local Changed = Next ~= Value
			Value = Next
			PaintValue()
			PaintOptions()

			if silent or not Changed then
				return
			end

			Emit()
			Note(FlagName)
		end

		CloseMenu = function()
			Opened = false

			if Field.Parent then
				Chevron.Text = "v"
				Field:SetAttribute("Hold", false)
				FieldStroke.Color = Theme.Stroke
				Field.BackgroundColor3 = Theme.Field
			end
			Drop(OutsideConn)
			OutsideConn = nil
			Drop(PlaceConn)
			PlaceConn = nil

			if Menu then
				local Dying = Menu
				Menu = nil
				Dying:Destroy()
			end

			table.clear(Rows)

			local Restore = SavedPos
			SavedPos = nil

			if Restore and Panel.Parent then
				SetOffset(Restore.X.Offset, Restore.Y.Offset)
			end
		end

		local PlaceMenu = function()
			if Placing or not Menu or not Menu.Parent then
				return
			end

			Placing = true

			local ItemH = Metrics.ItemH
			local ItemGap = 3
			local MenuInset = 5

			local Shown = math.min(#Options, 6)
			local MenuH = MenuInset * 2 + Shown * ItemH

			if Shown > 1 then
				MenuH += (Shown - 1) * ItemGap
			end

			local WantW = math.max(Field.AbsoluteSize.X, 148)
			local Viewport = ViewportOf()
			local Gap = 8
			local PanelAbs = Panel.AbsolutePosition
			local PanelSize = Panel.AbsoluteSize
			local RightRoom = Viewport.X - 8 - (PanelAbs.X + PanelSize.X + Gap)
			local LeftRoom = PanelAbs.X - Gap - 8
			local Side = "Right"
			local Room = RightRoom

			if LeftRoom > RightRoom then
				Side = "Left"
				Room = LeftRoom
			end

			if Room < WantW then
				local Need = WantW - Room

				if not SavedPos then
					SavedPos = Panel.Position
				end

				local Pos = Panel.Position

				if Side == "Right" then
					SetOffset(Pos.X.Offset - Need, Pos.Y.Offset)
				else
					SetOffset(Pos.X.Offset + Need, Pos.Y.Offset)
				end

				PanelAbs = Panel.AbsolutePosition
				PanelSize = Panel.AbsoluteSize
			end

			local Width = WantW

			if Width < 120 then
				Width = 120
			end

			local X = PanelAbs.X + PanelSize.X + Gap

			if Side == "Left" then
				X = PanelAbs.X - Gap - Width
			end

			local First = Rows[1]
			local Y = Field.AbsolutePosition.Y + (Field.AbsoluteSize.Y - ItemH) * 0.5 - MenuInset

			if First and First.Button.AbsoluteSize.Y > 1 then
				local FieldMid = Field.AbsolutePosition.Y + Field.AbsoluteSize.Y * 0.5
				local ButtonMid = First.Button.AbsolutePosition.Y + First.Button.AbsoluteSize.Y * 0.5
				Y = Menu.Position.Y.Offset + (FieldMid - ButtonMid)
			end

			Menu.Position = UDim2.fromOffset(math.floor(X), math.floor(Y))
			Menu.Size = UDim2.fromOffset(math.floor(Width), MenuH)
			Placing = false
		end

		local OpenMenu = function()
			if not Alive then
				return
			end

			if Opened then
				CloseMenu()
				return
			end

			if #Options == 0 then
				return
			end

			ClosePopups()
			Opened = true
			Chevron.Text = "^"
			Field:SetAttribute("Hold", true)
			FieldStroke.Color = Theme.Accent

			local ItemH = Metrics.ItemH
			local ItemGap = 3
			local MenuInset = 5

			Menu = New("Frame", {
				Name = "Menu",
				BackgroundColor3 = Theme.Menu,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				AnchorPoint = Vector2.new(0, 0),
				Active = true,
				ZIndex = 30,
			}, Gui)

			Corner(Menu, UDim.new(0, 12))

			New("UIStroke", {
				Color = Theme.Stroke,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				LineJoinMode = Enum.LineJoinMode.Round,
			}, Menu)

			local List = New("ScrollingFrame", {
				Name = "List",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(MenuInset, MenuInset),
				Size = UDim2.new(1, -MenuInset * 2, 1, -MenuInset * 2),
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 0,
				ScrollingEnabled = #Options > 6,
				ElasticBehavior = Enum.ElasticBehavior.Never,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Active = true,
				Selectable = false,
				ZIndex = 31,
			}, Menu)

			if #Options > 6 then
				List.ScrollBarThickness = 2
				List.ScrollBarImageColor3 = Theme.Muted
			end

			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, ItemGap),
			}, List)

			local TextRight = 16

			for index = 1, #Options do
				local Choice = Options[index]
				local Option = New("TextButton", {
					Text = Choice,
					AutoButtonColor = false,
					Font = Enum.Font.GothamMedium,
					TextSize = Metrics.Text,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					BackgroundColor3 = Theme.Accent,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, ItemH),
					LayoutOrder = index,
					Active = true,
					Selectable = false,
					ZIndex = 32,
				}, List)

				Corner(Option, UDim.new(0, 8))

				New("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, TextRight),
				}, Option)

				local Mark = New("Frame", {
					BackgroundColor3 = Theme.Accent,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -2, 0.5, 0),
					Size = UDim2.fromOffset(7, 7),
					Active = false,
					ZIndex = 33,
				}, Option)

				Corner(Mark, UDim.new(1, 0))

				local Entry = {
					Button = Option,
					Mark = Mark,
					Hot = false,
					Down = false,
				}

				Rows[#Rows + 1] = Entry

				Option.MouseEnter:Connect(function()
					Entry.Hot = true
					PaintOptions()
				end)

				Option.MouseLeave:Connect(function()
					Entry.Hot = false
					Entry.Down = false
					PaintOptions()
				end)

				Option.InputBegan:Connect(function(input)
					if not IsPointer(input) then
						return
					end

					Entry.Down = true
					PaintOptions()
				end)

				Option.InputEnded:Connect(function(input)
					if not IsPointer(input) then
						return
					end

					Entry.Down = false
					PaintOptions()
				end)

				Option.Activated:Connect(function()
					if not Alive then
						return
					end

					Apply(Choice, false)

					if not Alive or Multi then
						return
					end

					CloseMenu()
				end)
			end

			PaintOptions()
			PlaceMenu()
			task.defer(function()
				if Opened and Menu then
					PlaceMenu()
				end
			end)
			PlaceConn = Connect(Field:GetPropertyChangedSignal("AbsolutePosition"), PlaceMenu)

			task.defer(function()
				if not Opened then
					return
				end

				OutsideConn = Connect(UserInputService.InputBegan, function(input)
					if not Opened or not IsPointer(input) then
						return
					end

					if Inside(Field, input.Position) or Inside(Menu, input.Position) then
						return
					end

					CloseMenu()
				end)
			end)
		end

		PopupClosers[#PopupClosers + 1] = CloseMenu

		local IsLive, DestroyRow = RowLife(Row, CloseMenu)

		local FitDrop = function()
			if not IsLive() then
				return
			end

			local TextSize = math.max(11, Metrics.Text - 1)

			CaptionH = Measure(Caption.Text, TextSize, RowWidth(Row, 0))
			FieldH = Metrics.FieldH

			Caption.TextSize = TextSize
			Caption.Size = UDim2.new(1, 0, 0, CaptionH)
			Field.Position = UDim2.fromOffset(0, CaptionH + 4)
			Field.Size = UDim2.new(1, 0, 0, FieldH)
			ValueLabel.TextSize = Metrics.Text
			Chevron.TextSize = Metrics.Text
			Chevron.Size = UDim2.fromOffset(16, FieldH)

			if Row.Size.Y.Offset ~= CaptionH + 4 + FieldH then
				Row.Size = UDim2.new(1, 0, 0, CaptionH + 4 + FieldH)
			end

			if Opened then
				PlaceMenu()
			end
		end

		Refreshers[#Refreshers + 1] = function()
			FitDrop()
		end

		Connect(Row:GetPropertyChangedSignal("AbsoluteSize"), FitDrop)

		Connect(Field.Activated, function()
			OpenMenu()
		end)

		PaintValue()

		local Handle = {}

		Handle.Get = function(self)
			return Snapshot()
		end

		Handle.Set = function(self, value)
			if self ~= Handle then
				value = self
			end

			Apply(value, false)
		end

		Handle.SetOptions = function(self, list)
			if self ~= Handle then
				list = self
			end

			local Previous = Value

			if Multi then
				Previous = table.concat(Selected, "\0")
			end

			CloseMenu()
			CopyOptions(list)

			if Multi then
				ReplaceSelected(Selected)
				PaintValue()

				if table.concat(Selected, "\0") ~= Previous then
					Emit()
					Note(FlagName)
				end

				return
			end

			if not FindIndex(Value) then
				Value = Options[1] or ""
			end

			PaintValue()

			if Value ~= Previous then
				Emit()
				Note(FlagName)
			end
		end

		Handle.Destroy = DestroyRow
		BindFlag(FlagName, Handle)

		return Handle
	end

	Window.MultiDropdown = function(self, config)
		if self ~= Window then
			config = self
		end

		if type(config) ~= "table" then
			config = {}
		end

		config.Multi = true
		return Window:Dropdown(config)
	end

	Window.Textbox = function(self, config)
		if self ~= Window then
			config = self
		end

		if type(config) ~= "table" then
			config = {}
		end

		local Callback = Pick(config, "Callback", "OnChanged", "Changed")
		local FlagName = config.Flag
		local Firing = false
		local Value = ""
		local Default = Pick(config, "Default", "Value")

		if Default ~= nil then
			Value = tostring(Default)
		end

		local FieldH = Metrics.FieldH

		local Row = New("Frame", {
			Name = "Textbox",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = NextOrder(),
			Active = false,
		}, Content)

		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}, Row)

		local Caption = New("TextLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = tostring(Pick(config, "Text", "Title", "Label", "Name") or "Text"),
			TextColor3 = Theme.Muted,
			TextSize = math.max(11, Metrics.Text - 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 1,
			Active = false,
		}, Row)

		local Box = New("TextBox", {
			BackgroundColor3 = Theme.Field,
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Font = Enum.Font.GothamMedium,
			MultiLine = false,
			PlaceholderColor3 = Theme.Muted,
			PlaceholderText = tostring(Pick(config, "Placeholder", "PlaceHolder") or ""),
			Text = Value,
			TextColor3 = Theme.Text,
			TextSize = Metrics.Text,
			TextWrapped = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ClipsDescendants = true,
			Size = UDim2.new(1, 0, 0, FieldH),
			LayoutOrder = 2,
		}, Row)

		Corner(Box, UDim.new(0, 8))

		local BoxStroke = New("UIStroke", {
			Color = Theme.Stroke,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, Box)

		local Status = "ok"
		local StatusText = ""
		local Hot = false
		local Down = false

		local Expect = function(text)
			local Level = "ok"
			local Message = ""

			local Keep = function(nextLevel, nextMessage)
				if nextLevel ~= "error" and nextLevel ~= "warn" then
					return
				end

				if Level == "error" then
					return
				end

				if Level == "warn" and nextLevel ~= "error" then
					return
				end

				Level = nextLevel
				Message = tostring(nextMessage or "")
			end

			local Count = #text
			local Length = utf8.len(text)

			if Length then
				Count = Length
			end

			if text == "" then
				if config.Required == true then
					Keep("error", config.Empty or "Required")
				end
			else
				if type(config.Min) == "number" and Count < config.Min then
					Keep("error", config.MinText or ("At least " .. config.Min .. " characters"))
				end

				if type(config.Max) == "number" and Count > config.Max then
					Keep("error", config.MaxText or ("At most " .. config.Max .. " characters"))
				end

				if type(config.Pattern) == "string" and config.Pattern ~= "" then
					local Ran, Matched = pcall(string.match, text, config.Pattern)

					if not Ran then
						Keep("error", "Bad pattern")
					elseif not Matched then
						Keep("error", config.PatternText or "Unexpected format")
					end
				end
			end

			if type(config.Validate) == "function" then
				local Ran, Kind, NoteText = pcall(config.Validate, text)

				if not Ran then
					Keep("error", "Check failed")
				elseif Kind == "error" or Kind == "warn" then
					Keep(Kind, NoteText or (Kind == "error" and "Invalid" or "Check this"))
				elseif Kind == false then
					Keep("error", NoteText or "Invalid")
				end
			end

			return Level, Message
		end

		local PaintBox = function()
			if not BoxStroke.Parent then
				return
			end

			if Status == "error" then
				BoxStroke.Color = Theme.Error
				return
			end

			if Status == "warn" and not Down then
				BoxStroke.Color = Theme.Warn
				return
			end

			if Down then
				BoxStroke.Color = Theme.AccentPressed
			elseif Hot or Box:IsFocused() then
				BoxStroke.Color = Theme.Accent
			else
				BoxStroke.Color = Theme.Stroke
			end
		end

		Connect(Box.MouseEnter, function()
			Hot = true
			PaintBox()
		end)

		Connect(Box.MouseLeave, function()
			Hot = false
			Down = false
			PaintBox()
		end)

		Connect(Box.Focused, function()
			PaintBox()
		end)

		Connect(Box.FocusLost, function()
			PaintBox()
		end)

		Connect(Box.InputBegan, function(input)
			if not IsPointer(input) then
				return
			end

			Down = true
			PaintBox()
		end)

		Connect(Box.InputEnded, function(input)
			if not IsPointer(input) then
				return
			end

			Down = false
			PaintBox()
		end)

		local BoxPad = New("UIPadding", {
			PaddingTop = UDim.new(0, 0),
			PaddingBottom = UDim.new(0, 0),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}, Box)

		local StatusLabel = New("TextLabel", {
			Name = "Status",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = "",
			TextColor3 = Theme.Error,
			TextSize = math.max(11, Metrics.Text - 2),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Visible = false,
			LayoutOrder = 3,
			Active = false,
		}, Row)

		local PaintNote = function()
			StatusLabel.Text = StatusText
			StatusLabel.Visible = StatusText ~= ""
			StatusLabel.TextSize = math.max(11, Metrics.Text - 2)

			if Status == "error" then
				StatusLabel.TextColor3 = Theme.Error
			else
				StatusLabel.TextColor3 = Theme.Warn
			end

			PaintBox()
		end

		local Emit = function()
			if Firing or type(Callback) ~= "function" then
				return
			end

			Firing = true
			local Ok, Err = pcall(Callback, Value, Status, StatusText)
			Firing = false

			if not Ok then
				warn("[MinimUI]", Err)
			end
		end

		local IsLive, DestroyRow = RowLife(Row)

		local FitBox = function()
			if not IsLive() then
				return
			end

			FieldH = Metrics.FieldH

			Caption.TextSize = math.max(11, Metrics.Text - 1)
			Box.TextSize = Metrics.Text

			local Sample = Box.Text

			if Sample == "" then
				Sample = Box.PlaceholderText
			end

			local TextH = Measure(Sample, Metrics.Text, RowWidth(Box, 20))
			local OneLine = Measure("Ag", Metrics.Text, 4000)
			local Wrapped = TextH > OneLine + 1
			local PadY = 0
			local BoxH = FieldH

			if Wrapped then
				PadY = 8
				BoxH = math.clamp(TextH + PadY * 2, FieldH, 120)
				Box.MultiLine = true
				Box.TextWrapped = true
				Box.TextYAlignment = Enum.TextYAlignment.Top
			else
				Box.MultiLine = false
				Box.TextWrapped = false
				Box.TextYAlignment = Enum.TextYAlignment.Center
			end

			BoxPad.PaddingTop = UDim.new(0, PadY)
			BoxPad.PaddingBottom = UDim.new(0, PadY)

			if Box.Size.Y.Offset ~= BoxH then
				Box.Size = UDim2.new(1, 0, 0, BoxH)
			end
		end

		Refreshers[#Refreshers + 1] = FitBox
		Connect(Box:GetPropertyChangedSignal("AbsoluteSize"), FitBox)

		local Sync = function(report)
			local Level, Message = Expect(Box.Text)
			Status = Level
			StatusText = Message
			PaintNote()
			FitBox()

			if Box.Text == Value then
				return
			end

			Value = Box.Text

			if not report then
				return
			end

			Emit()
			Note(FlagName)
		end

		Connect(Box:GetPropertyChangedSignal("Text"), function()
			if not Alive then
				return
			end

			Sync(true)
		end)

		local Handle = {}

		Handle.Get = function(self)
			return Value, Status, StatusText
		end

		Handle.Set = function(self, value)
			if self ~= Handle then
				value = self
			end

			local Next = tostring(value or "")
			local Changed = Next ~= Value or Box.Text ~= Next

			Value = Next

			if Box.Text ~= Next then
				Box.Text = Next
			end

			local Level, Message = Expect(Next)
			Status = Level
			StatusText = Message
			PaintNote()
			FitBox()

			if not Changed then
				return
			end

			Emit()
			Note(FlagName)
		end

		Handle.Destroy = DestroyRow
		BindFlag(FlagName, Handle)
		Sync(false)

		return Handle
	end

	Window.Color = function(self, config)
		if self ~= Window then
			config = self
		end

		if type(config) ~= "table" then
			config = {}
		end

		local ColorFrom = function(value)
			if typeof(value) == "Color3" then
				return value
			end

			if type(value) == "string" then
				local Text: string = value :: string
				local Red, Green, Blue = string.match(Text, "^#?(%x%x)(%x%x)(%x%x)$")

				if Red and Green and Blue then
					return Color3.fromRGB(tonumber(Red, 16) or 0, tonumber(Green, 16) or 0, tonumber(Blue, 16) or 0)
				end
			end

			if type(value) ~= "table" then
				return nil
			end

			local Red = value[1] or value.R or value.r
			local Green = value[2] or value.G or value.g
			local Blue = value[3] or value.B or value.b

			if type(Red) ~= "number" or type(Green) ~= "number" or type(Blue) ~= "number" then
				return nil
			end

			if Red <= 1 and Green <= 1 and Blue <= 1 then
				return Color3.new(Red, Green, Blue)
			end

			return Color3.fromRGB(Red, Green, Blue)
		end

		local Callback = Pick(config, "Callback", "OnChanged", "Changed")
		local FlagName = config.Flag
		local Firing = false
		local Opened = false
		local Value = ColorFrom(Pick(config, "Default", "Value")) or Color3.fromRGB(208, 188, 255)
		local Hue, Sat, Val = Value:ToHSV()
		local FieldH = Metrics.FieldH

		local Row = New("Frame", {
			Name = "Color",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = NextOrder(),
			Active = false,
		}, Content)

		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}, Row)

		local Caption = New("TextLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = tostring(Pick(config, "Text", "Title", "Label", "Name") or "Color"),
			TextColor3 = Theme.Muted,
			TextSize = math.max(11, Metrics.Text - 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 1,
			Active = false,
		}, Row)

		local Field = New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Theme.Field,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, FieldH),
			LayoutOrder = 2,
			Active = true,
			Selectable = false,
		}, Row)

		Corner(Field, UDim.new(0, 8))

		local FieldStroke = New("UIStroke", {
			Color = Theme.Stroke,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, Field)

		BindStroke(Field, FieldStroke)

		local Swatch = New("Frame", {
			BackgroundColor3 = Value,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(8, math.floor((FieldH - 18) * 0.5)),
			Size = UDim2.fromOffset(18, 18),
			Active = false,
		}, Field)

		Corner(Swatch, UDim.new(0, 6))

		local HexLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			TextColor3 = Theme.Text,
			TextSize = Metrics.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(34, 0),
			Size = UDim2.new(1, -44, 1, 0),
			Active = false,
		}, Field)

		local Editor = New("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 3,
			Active = false,
		}, Row)

		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}, Editor)

		local SwatchRow = New("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 1,
			Active = false,
		}, Editor)

		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Wraps = true,
		}, SwatchRow)

		local Presets = {
			Color3.fromRGB(208, 188, 255),
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(232, 226, 238),
			Color3.fromRGB(28, 26, 34),
			Color3.fromRGB(255, 98, 98),
			Color3.fromRGB(255, 176, 92),
			Color3.fromRGB(120, 210, 140),
			Color3.fromRGB(110, 170, 255),
		}

		local Bars = {}
		local DragBar

		local Emit = function()
			if Firing or type(Callback) ~= "function" then
				return
			end

			Firing = true
			local Ok, Err = pcall(Callback, Value)
			Firing = false

			if not Ok then
				warn("[MinimUI]", Err)
			end
		end

		local HexOf = function(color)
			return string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
		end

		local PaintColor = function()
			Swatch.BackgroundColor3 = Value
			HexLabel.Text = HexOf(Value)

			for index = 1, #Bars do
				local Bar = Bars[index]
				Bar.Knob.Position = UDim2.new(Bar.Read(), 0, 0.5, 0)
				Bar.Paint(Bar.Gradient)
			end
		end

		local ApplyColor = function(nextValue, silent)
			local Next = ColorFrom(nextValue)

			if not Next or Next == Value then
				return
			end

			Value = Next
			Hue, Sat, Val = Value:ToHSV()
			PaintColor()

			if silent then
				return
			end

			Emit()
			Note(FlagName)
		end

		local WriteChannel = function(kind, alpha)
			if kind == "H" then
				Hue = alpha
			elseif kind == "S" then
				Sat = alpha
			else
				Val = alpha
			end

			local Next = Color3.fromHSV(Hue, Sat, Val)

			if Next == Value then
				PaintColor()
				return
			end

			Value = Next
			PaintColor()
			Emit()
			Note(FlagName)
		end

		for index = 1, #Presets do
			local Preset = Presets[index]
			local Chip = New("TextButton", {
				Text = "",
				AutoButtonColor = false,
				BackgroundColor3 = Preset,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(22, 22),
				LayoutOrder = index,
				Active = true,
				Selectable = false,
			}, SwatchRow)

			Corner(Chip, UDim.new(1, 0))

			local ChipStroke = New("UIStroke", {
				Color = Theme.Text,
				Thickness = 2,
				Transparency = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}, Chip)

			Chip.MouseEnter:Connect(function()
				ChipStroke.Transparency = 0
			end)

			Chip.MouseLeave:Connect(function()
				ChipStroke.Transparency = 1
			end)

			Chip.InputBegan:Connect(function(input)
				if IsPointer(input) then
					ChipStroke.Color = Theme.Accent
					ChipStroke.Transparency = 0
				end
			end)

			Chip.InputEnded:Connect(function(input)
				if IsPointer(input) then
					ChipStroke.Color = Theme.Text
				end
			end)

			Chip.Activated:Connect(function()
				if not Alive then
					return
				end

				ApplyColor(Preset, false)
			end)
		end

		local AddBar = function(order, title, kind, read, paint)
			local Bar = New("Frame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 22),
				LayoutOrder = order,
				Active = false,
			}, Editor)

			New("TextLabel", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamMedium,
				Text = title,
				TextColor3 = Theme.Muted,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.fromOffset(14, 22),
				Active = false,
			}, Bar)

			local Track = New("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(18, 7),
				Size = UDim2.new(1, -18, 0, 8),
				Active = false,
			}, Bar)

			Corner(Track, UDim.new(1, 0))

			local Gradient = New("UIGradient", {}, Track)

			local Knob = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Theme.Thumb,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(12, 16),
				Active = false,
				ZIndex = 2,
			}, Track)

			Corner(Knob, UDim.new(1, 0))

			New("UIStroke", {
				Color = Theme.Window,
				Thickness = 1,
			}, Knob)

			local Hit = New("TextButton", {
				Text = "",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(18, 0),
				Size = UDim2.new(1, -18, 1, 0),
				Active = true,
				Selectable = false,
				ZIndex = 3,
			}, Bar)

			local Entry = {
				Kind = kind,
				Track = Track,
				Knob = Knob,
				Gradient = Gradient,
				Read = read,
				Paint = paint,
			}

			Bars[#Bars + 1] = Entry

			Connect(Hit.InputBegan, function(input)
				if not Alive or not IsPointer(input) then
					return
				end

				DragBar = Entry
				LockScroll = true
				Knob.BackgroundColor3 = Theme.Accent

				local Width = Track.AbsoluteSize.X
				local Alpha = 0

				if Width > 0 then
					Alpha = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Width, 0, 1)
				end

				WriteChannel(kind, Alpha)
			end)
		end

		AddBar(2, "H", "H", function()
			return Hue
		end, function(gradient)
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
				ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
				ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
				ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
				ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
				ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(0, 1, 1)),
			})
		end)

		AddBar(3, "S", "S", function()
			return Sat
		end, function(gradient)
			gradient.Color = ColorSequence.new(Color3.fromHSV(Hue, 0, Val), Color3.fromHSV(Hue, 1, Val))
		end)

		AddBar(4, "V", "V", function()
			return Val
		end, function(gradient)
			gradient.Color = ColorSequence.new(Color3.fromHSV(Hue, Sat, 0), Color3.fromHSV(Hue, Sat, 1))
		end)

		Connect(UserInputService.InputChanged, function(input)
			if not DragBar or not IsMove(input) then
				return
			end

			local Width = DragBar.Track.AbsoluteSize.X
			local Alpha = 0

			if Width > 0 then
				Alpha = math.clamp((input.Position.X - DragBar.Track.AbsolutePosition.X) / Width, 0, 1)
			end

			WriteChannel(DragBar.Kind, Alpha)
		end)

		Connect(UserInputService.InputEnded, function(input)
			if not DragBar or not IsPointer(input) then
				return
			end

			if DragBar.Knob and DragBar.Knob.Parent then
				DragBar.Knob.BackgroundColor3 = Theme.Thumb
			end

			DragBar = nil
			LockScroll = false
			Reflow()
		end)

		local CloseEditor

		CloseEditor = function()
			Opened = false
			Editor.Visible = false

			if Field.Parent then
				Field:SetAttribute("Hold", false)
				FieldStroke.Color = Theme.Stroke
				Field.BackgroundColor3 = Theme.Field
			end
		end

		PopupClosers[#PopupClosers + 1] = CloseEditor

		Connect(Field.Activated, function()
			if not Alive then
				return
			end

			if Opened then
				CloseEditor()
				return
			end

			ClosePopups()
			Opened = true
			Editor.Visible = true
			Field:SetAttribute("Hold", true)
			FieldStroke.Color = Theme.Accent
			PaintColor()
		end)

		local IsLive, DestroyRow = RowLife(Row, CloseEditor)

		Refreshers[#Refreshers + 1] = function()
			if not IsLive() then
				return
			end

			FieldH = Metrics.FieldH

			Caption.TextSize = math.max(11, Metrics.Text - 1)
			Field.Size = UDim2.new(1, 0, 0, FieldH)
			Swatch.Position = UDim2.fromOffset(8, math.floor((FieldH - 18) * 0.5))
			HexLabel.TextSize = Metrics.Text
			PaintColor()
		end

		PaintColor()

		local Handle = {}

		Handle.Get = function(self)
			return Value
		end

		Handle.Set = function(self, value)
			if self ~= Handle then
				value = self
			end

			ApplyColor(value, false)
		end

		Handle.Destroy = DestroyRow
		BindFlag(FlagName, Handle)

		return Handle
	end

	Window.Mode = function(self, config)
		if self ~= Window then
			config = self
		end

		if type(config) ~= "table" then
			config = {}
		end

		local Callback = Pick(config, "Callback", "OnChanged", "Changed")
		local FlagName = config.Flag
		local Firing = false
		local Options = {}
		local Pills = {}
		local Limits = {}
		local Value = ""
		local Source = Pick(config, "Options", "Items", "List", "Values")

		if type(Source) == "table" then
			if #Source > 0 then
				for index = 1, #Source do
					Options[index] = tostring(Source[index])
				end
			else
				for _, item in next, Source do
					if type(item) == "string" or type(item) == "number" then
						Options[#Options + 1] = tostring(item)
					end
				end
			end
		end

		local Wanted = tostring(Pick(config, "Default", "Value") or "")

		for index = 1, #Options do
			if Options[index] == Wanted then
				Value = Wanted
				break
			end
		end

		if Value == "" then
			Value = Options[1] or ""
		end

		local Row = New("Frame", {
			Name = "Mode",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = NextOrder(),
			Active = false,
		}, Content)

		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}, Row)

		local Caption = New("TextLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = tostring(Pick(config, "Text", "Title", "Label", "Name") or "Mode"),
			TextColor3 = Theme.Muted,
			TextSize = math.max(11, Metrics.Text - 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 1,
			Active = false,
		}, Row)

		local Holder = New("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 2,
			Active = false,
		}, Row)

		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Wraps = true,
		}, Holder)

		local Emit = function()
			if Firing or type(Callback) ~= "function" then
				return
			end

			Firing = true
			local Ok, Err = pcall(Callback, Value)
			Firing = false

			if not Ok then
				warn("[MinimUI]", Err)
			end
		end

		local PaintModes = function()
			for index = 1, #Pills do
				local Pill = Pills[index]
				local Down = Pill:GetAttribute("Down") == true
				local Hot = Pill:GetAttribute("Hot") == true

				if Pill.Text == Value then
					local Fill = Theme.Accent

					if Down then
						Fill = Theme.AccentPressed
					end

					Pill.BackgroundColor3 = Fill
					Pill.TextColor3 = Theme.OnAccent
				elseif Hot or Down then
					Pill.BackgroundColor3 = Theme.Option
					Pill.TextColor3 = Theme.Text
				else
					Pill.BackgroundColor3 = Theme.Field
					Pill.TextColor3 = Theme.Text
				end
			end
		end

		local ApplyMode = function(nextValue, silent)
			local Next = tostring(nextValue or "")
			local Found = false

			for index = 1, #Options do
				if Options[index] == Next then
					Found = true
					break
				end
			end

			if not Found or Next == Value then
				return
			end

			Value = Next
			PaintModes()

			if silent then
				return
			end

			Emit()
			Note(FlagName)
		end

		for index = 1, #Options do
			local Choice = Options[index]
			local Pill = New("TextButton", {
				Text = Choice,
				AutoButtonColor = false,
				Font = Enum.Font.GothamMedium,
				TextSize = Metrics.Text,
				TextWrapped = true,
				TextColor3 = Theme.Text,
				BackgroundColor3 = Theme.Field,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.fromOffset(0, 0),
				LayoutOrder = index,
				Active = true,
				Selectable = false,
			}, Holder)

			Corner(Pill, UDim.new(1, 0))

			New("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 7),
				PaddingBottom = UDim.new(0, 7),
			}, Pill)

			local Limit = New("UISizeConstraint", {
				MinSize = Vector2.new(0, 30),
				MaxSize = Vector2.new(400, 240),
			}, Pill)

			Pills[#Pills + 1] = Pill
			Limits[#Limits + 1] = Limit

			Connect(Pill.MouseEnter, function()
				Pill:SetAttribute("Hot", true)
				PaintModes()
			end)

			Connect(Pill.MouseLeave, function()
				Pill:SetAttribute("Hot", false)
				Pill:SetAttribute("Down", false)
				PaintModes()
			end)

			Connect(Pill.InputBegan, function(input)
				if not IsPointer(input) then
					return
				end

				Pill:SetAttribute("Down", true)
				PaintModes()
			end)

			Connect(Pill.InputEnded, function(input)
				if not IsPointer(input) then
					return
				end

				Pill:SetAttribute("Down", false)
				PaintModes()
			end)

			Pill.Activated:Connect(function()
				if not Alive then
					return
				end

				ApplyMode(Choice, false)
			end)
		end

		local IsLive, DestroyRow = RowLife(Row)

		local FitModes = function()
			if not IsLive() then
				return
			end

			local Width = RowWidth(Row, 0)

			Caption.TextSize = math.max(11, Metrics.Text - 1)

			for index = 1, #Pills do
				Pills[index].TextSize = Metrics.Text
				Limits[index].MaxSize = Vector2.new(Width, 240)
			end
		end

		Refreshers[#Refreshers + 1] = FitModes
		Connect(Row:GetPropertyChangedSignal("AbsoluteSize"), FitModes)
		PaintModes()
		FitModes()

		local Handle = {}

		Handle.Get = function(self)
			return Value
		end

		Handle.Set = function(self, value)
			if self ~= Handle then
				value = self
			end

			ApplyMode(value, false)
		end

		Handle.Destroy = DestroyRow
		BindFlag(FlagName, Handle)

		return Handle
	end

	Window.Button = function(self, config)
		if self ~= Window then
			config = self
		end

		if type(config) ~= "table" then
			config = {}
		end

		local Callback = Pick(config, "Callback", "OnChanged", "Changed")
		local Firing = false

		local Button = New("TextButton", {
			Name = "Button",
			AutoButtonColor = false,
			Font = Enum.Font.GothamMedium,
			Text = tostring(Pick(config, "Text", "Title", "Label", "Name") or "Button"),
			TextColor3 = Theme.OnAccent,
			TextSize = Metrics.Text,
			TextWrapped = true,
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, Metrics.ButtonH),
			LayoutOrder = NextOrder(),
			Active = true,
			Selectable = false,
		}, Content)

		Corner(Button, UDim.new(1, 0))
		Feel(Button, Theme.Accent, Theme.AccentHover, Theme.AccentPressed, 0, 0)

		local IsLive, DestroyRow = RowLife(Button)

		local FitButton = function()
			if not IsLive() then
				return
			end

			local TextH = Measure(Button.Text, Metrics.Text, RowWidth(Button, 24))
			local RowH = math.max(Metrics.ButtonH, TextH + 16)

			Button.TextSize = Metrics.Text

			if Button.Size.Y.Offset ~= RowH then
				Button.Size = UDim2.new(1, 0, 0, RowH)
			end
		end

		Refreshers[#Refreshers + 1] = function()
			FitButton()
		end

		Connect(Button:GetPropertyChangedSignal("AbsoluteSize"), FitButton)

		local Emit = function()
			if Firing or type(Callback) ~= "function" then
				return
			end

			Firing = true
			local Ok, Err = pcall(Callback)
			Firing = false

			if not Ok then
				warn("[MinimUI]", Err)
			end
		end

		Connect(Button.Activated, function()
			if not Alive then
				return
			end

			Emit()
		end)

		local Handle = {}

		Handle.SetText = function(self, text)
			if self ~= Handle then
				text = self
			end

			Button.Text = tostring(text or "")
			FitButton()
		end

		Handle.Destroy = DestroyRow

		return Handle
	end

	Registry[Panel] = Destroy
	Open += 1

	Connect(Gui:GetPropertyChangedSignal("AbsoluteSize"), ApplyMetrics)

	task.defer(function()
		if not Alive then
			return
		end

		ApplyMetrics()
	end)

	SyncIcon()

	return Window
end

MinimUI.Destroy = function()
	local Pending = {}

	for _, destroy in next, Registry do
		Pending[#Pending + 1] = destroy
	end

	for index = 1, #Pending do
		Pending[index]()
	end
end

MinimUI.Demo = function()
	local Window = MinimUI:Window({
		Title = "Minim",
		File = "minim",
	})

	if not Window then
		return nil
	end

	local Enabled = Window:Toggle({
		Text = "Enabled",
		Flag = "Enabled",
		Default = true,
		Callback = function(value)
			print("[Minim] Enabled", value)
		end,
	})

	local Amount = Window:Slider({
		Text = "Amount",
		Flag = "Amount",
		Min = 0,
		Max = 100,
		Default = 35,
		Step = 1,
		Callback = function(value)
			print("[Minim] Amount", value)
		end,
	})

	local Fruit = Window:Dropdown({
		Text = "Fruit",
		Flag = "Fruit",
		Options = { "Apple", "Banana", "Cherry" },
		Default = "Banana",
		Callback = function(value)
			print("[Minim] Fruit", value)
		end,
	})

	local Fruits = Window:MultiDropdown({
		Text = "Fruits",
		Flag = "Fruits",
		Options = { "Apple", "Banana", "Cherry" },
		Default = { "Apple", "Cherry" },
		Callback = function(value)
			print("[Minim] Fruits", table.concat(value, ", "))
		end,
	})

	local Name = Window:Textbox({
		Text = "Name",
		Flag = "Name",
		Placeholder = "2 to 16 letters",
		Default = "",
		Required = true,
		Min = 2,
		Max = 16,
		Pattern = "^[%a ]+$",
		Validate = function(text)
			if string.find(string.lower(text), "phone") then
				return "warn", "Phone is not a name"
			end
		end,
		Callback = function(value, level, message)
			print("[Minim] Name", value, level, message)
		end,
	})

	local Tint = Window:Color({
		Text = "Color",
		Flag = "Color",
		Default = Color3.fromRGB(208, 188, 255),
		Callback = function(value)
			print("[Minim] Color", value)
		end,
	})

	local ChosenMode = Window:Mode({
		Text = "Mode",
		Flag = "Mode",
		Options = { "Legit", "Blatant", "Quiet farm" },
		Default = "Legit",
		Callback = function(value)
			print("[Minim] Mode", value)
		end,
	})

	Window:Button({
		Text = "Apply",
		Callback = function()
			local On = Window:Get("Enabled")
			local Count = Window:Get("Amount")
			local Choice = Window:Get("Fruit")
			local Picked = Window:Get("Fruits")
			local Text, Level, Message = Name:Get()
			print("[Minim] Apply", On, Count, Choice, table.concat(Picked, ", "), Text, Level, Message, Tint:Get(), ChosenMode:Get())
		end,
	})

	return Window
end

-- MinimUI.Demo()

return MinimUI
