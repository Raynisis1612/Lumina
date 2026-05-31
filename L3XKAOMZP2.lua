-- iOS 19 UI Library (Expanded)
-- A high-performance, completely custom Roblox UI Library with an Apple iOS 19 aesthetic.
-- Now features full Rayfield parity (ColorPickers, Keybinds, Labels, Multi-Dropdowns, Notifications, etc.)

local Library = {
	Settings = {
		ConfigurationFolder = "iOS19_Configs",
		ConfigurationExtension = ".ios19"
	},
	Flags = {},
	Theme = {
		Background = Color3.fromRGB(28, 28, 30), -- #1C1C1E
		Elevated = Color3.fromRGB(44, 44, 46),   -- #2C2C2E
		Secondary = Color3.fromRGB(58, 58, 60),  -- #3A3A3C
		AccentBlue = Color3.fromRGB(10, 132, 255), -- #0A84FF
		AccentGreen = Color3.fromRGB(48, 209, 88), -- #30D158
		AccentRed = Color3.fromRGB(255, 69, 58),   -- #FF453A
		TextPrimary = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(235, 235, 245), -- Approx 60% opacity look
		Divider = Color3.fromRGB(84, 84, 88),
	},
	ToggleKeybind = Enum.KeyCode.RightControl
}

-- Services
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Protection for executors vs studio
local ParentGui = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or (gethui and gethui() or CoreGui)

-- Utility Functions
local function Create(className, properties, children)
	local inst = Instance.new(className)
	for i, v in pairs(properties or {}) do
		if i ~= "Parent" then
			inst[i] = v
		end
	end
	for _, child in pairs(children or {}) do
		child.Parent = inst
	end
	if properties and properties.Parent then
		inst.Parent = properties.Parent
	end
	return inst
end

local function Tween(instance, properties, duration, style, direction)
	duration = duration or 0.3
	style = style or Enum.EasingStyle.Quint
	direction = direction or Enum.EasingDirection.Out
	local tweenInfo = TweenInfo.new(duration, style, direction)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

local function MakeDraggable(topbarObject, object)
	local Dragging = nil
	local DragInput = nil
	local DragStart = nil
	local StartPosition = nil

	topbarObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = input.Position
			StartPosition = object.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then Dragging = false end
			end)
		end
	end)
	topbarObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			DragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == DragInput and Dragging then
			local delta = input.Position - DragStart
			Tween(object, {Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + delta.Y)}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end
	end)
end

-- Configuration System
function Library:SaveConfiguration(name)
	if not isfolder or not writefile then return end
	if not isfolder(self.Settings.ConfigurationFolder) then makefolder(self.Settings.ConfigurationFolder) end
	
	local data = {}
	for flag, element in pairs(self.Flags) do
		if element.Type == "ColorPicker" then
			data[flag] = {R = element.CurrentValue.R, G = element.CurrentValue.G, B = element.CurrentValue.B}
		elseif element.Type == "Keybind" then
			data[flag] = element.CurrentKeybind.Name
		else
			data[flag] = element.CurrentValue
		end
	end
	local success, encoded = pcall(function() return HttpService:JSONEncode(data) end)
	if success then
		writefile(self.Settings.ConfigurationFolder .. "/" .. name .. self.Settings.ConfigurationExtension, encoded)
	end
end

function Library:LoadConfiguration(name)
	if not isfolder or not readfile then return end
	local path = self.Settings.ConfigurationFolder .. "/" .. name .. self.Settings.ConfigurationExtension
	if isfile and isfile(path) then
		local data = readfile(path)
		local success, decoded = pcall(function() return HttpService:JSONDecode(data) end)
		if success then
			for flag, value in pairs(decoded) do
				if self.Flags[flag] then
					pcall(function()
						if self.Flags[flag].Type == "ColorPicker" then
							self.Flags[flag]:Set(Color3.new(value.R, value.G, value.B))
						elseif self.Flags[flag].Type == "Keybind" then
							self.Flags[flag]:Set(Enum.KeyCode[value])
						else
							self.Flags[flag]:Set(value)
						end
					end)
				end
			end
		end
	end
end

-- Global ScreenGui (Holds Window and Notifications)
local ScreenGui = Create("ScreenGui", {
	Name = "iOS19Interface",
	Parent = ParentGui,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

-- Destroy old instances
for _, child in pairs(ParentGui:GetChildren()) do
	if child.Name == "iOS19Interface" and child ~= ScreenGui then child:Destroy() end
end

local NotificationContainer = Create("Frame", {
	Name = "Notifications",
	Parent = ScreenGui,
	BackgroundTransparency = 1,
	Position = UDim2.new(1, -320, 1, -20),
	Size = UDim2.new(0, 300, 1, 0),
	AnchorPoint = Vector2.new(0, 1)
}, {
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		VerticalAlignment = Enum.VerticalAlignment.Bottom
	})
})

function Library:Notify(options)
	options = options or {}
	local Title = options.Title or "Notification"
	local Content = options.Content or "Description"
	local Duration = options.Duration or 5
	local Icon = options.Icon or "rbxassetid://10804731440"
	
	local NoteFrame = Create("Frame", {
		Parent = NotificationContainer,
		BackgroundColor3 = self.Theme.Elevated,
		BackgroundTransparency = 0.2,
		Size = UDim2.new(1, 0, 0, 80),
		Position = UDim2.new(1, 320, 0, 0),
		ClipsDescendants = true
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 16)}),
		Create("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Transparency = 0.9,
			Thickness = 1
		})
	})
	
	Create("ImageLabel", {
		Parent = NoteFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 16),
		Size = UDim2.new(0, 24, 0, 24),
		Image = Icon,
		ImageColor3 = self.Theme.TextPrimary
	})
	
	Create("TextLabel", {
		Parent = NoteFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 48, 0, 12),
		Size = UDim2.new(1, -60, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = Title,
		TextColor3 = self.Theme.TextPrimary,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	
	Create("TextLabel", {
		Parent = NoteFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 48, 0, 34),
		Size = UDim2.new(1, -60, 0, 34),
		Font = Enum.Font.Gotham,
		Text = Content,
		TextColor3 = self.Theme.TextSecondary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true
	})
	
	Tween(NoteFrame, {Position = UDim2.new(0, 0, 0, 0)}, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	
	task.spawn(function()
		task.wait(Duration)
		Tween(NoteFrame, {Position = UDim2.new(1, 320, 0, 0), BackgroundTransparency = 1}, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out).Completed:Connect(function()
			NoteFrame:Destroy()
		end)
	end)
end

-- UI Builder
function Library:CreateWindow(options)
	options = options or {}
	local Title = options.Name or "iOS 19 Window"
	local SaveConfig = options.SaveConfig or false
	local ConfigName = options.ConfigName or "Default"
	
	if SaveConfig then
		task.spawn(function()
			task.wait(1)
			self:LoadConfiguration(ConfigName)
		end)
	end

	local WindowObj = {
		Tabs = {},
		CurrentTab = nil,
		IsHidden = false
	}
	
	local MainFrame = Create("Frame", {
		Name = "MainFrame",
		Parent = ScreenGui,
		BackgroundColor3 = Library.Theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, -300, 0.5, -200),
		Size = UDim2.new(0, 600, 0, 400),
		ClipsDescendants = true
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 16)}),
		Create("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Transparency = 0.9,
			Thickness = 1
		}),
		Create("ImageLabel", {
			Name = "Shadow",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, -15, 0, -15),
			Size = UDim2.new(1, 30, 1, 30),
			ZIndex = 0,
			Image = "rbxassetid://601553681",
			ImageColor3 = Color3.fromRGB(0, 0, 0),
			ImageTransparency = 0.3,
			SliceCenter = Rect.new(10, 10, 118, 118)
		})
	})
	
	MainFrame.Size = UDim2.new(0, 580, 0, 380)
	Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 400)}, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	local Topbar = Create("Frame", {
		Name = "Topbar",
		Parent = MainFrame,
		BackgroundColor3 = Library.Theme.Background,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 44),
		ZIndex = 2
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 16)})
	})
	
	Create("Frame", {
		Name = "BottomFix",
		Parent = Topbar,
		BackgroundColor3 = Library.Theme.Background,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -8),
		Size = UDim2.new(1, 0, 0, 8),
		ZIndex = 2
	})
	
	Create("Frame", {
		Name = "Divider",
		Parent = Topbar,
		BackgroundColor3 = Library.Theme.Divider,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 3
	})
	
	MakeDraggable(Topbar, MainFrame)
	
	Create("TextLabel", {
		Name = "Title",
		Parent = Topbar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 44, 0, 0),
		Size = UDim2.new(1, -100, 1, 0),
		Font = Enum.Font.GothamMedium,
		Text = Title,
		TextColor3 = Library.Theme.TextPrimary,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3
	})
	
	Create("ImageLabel", {
		Name = "Icon",
		Parent = Topbar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0.5, -10),
		Size = UDim2.new(0, 20, 0, 20),
		Image = "rbxassetid://10804731440",
		ImageColor3 = Library.Theme.TextPrimary,
		ZIndex = 3
	})

	local ControlsContainer = Create("Frame", {
		Name = "Controls",
		Parent = Topbar,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -70, 0, 0),
		Size = UDim2.new(0, 70, 1, 0),
		ZIndex = 3
	})
	
	local CloseButton = Create("TextButton", {
		Name = "Close",
		Parent = ControlsContainer,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -34, 0.5, -12),
		Size = UDim2.new(0, 24, 0, 24),
		Text = "",
		ZIndex = 4
	}, {
		Create("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Image = "rbxassetid://3926305904",
			ImageRectOffset = Vector2.new(284, 4),
			ImageRectSize = Vector2.new(24, 24),
			ImageColor3 = Library.Theme.TextSecondary
		})
	})
	
	CloseButton.MouseButton1Click:Connect(function()
		Tween(MainFrame, {Size = UDim2.new(0, 580, 0, 380)}, 0.3)
		for _, v in pairs(MainFrame:GetDescendants()) do
			if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then Tween(v, {TextTransparency = 1}, 0.3)
			elseif v:IsA("ImageLabel") or v:IsA("ImageButton") then Tween(v, {ImageTransparency = 1}, 0.3)
			elseif v:IsA("Frame") or v:IsA("ScrollingFrame") then Tween(v, {BackgroundTransparency = 1}, 0.3)
			elseif v:IsA("UIStroke") then Tween(v, {Transparency = 1}, 0.3)
			end
		end
		Tween(MainFrame, {BackgroundTransparency = 1}, 0.3).Completed:Connect(function() ScreenGui:Destroy() end)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Library.ToggleKeybind then
			WindowObj.IsHidden = not WindowObj.IsHidden
			if WindowObj.IsHidden then
				Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			else
				Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 400), Position = UDim2.new(0.5, -300, 0.5, -200)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end
		end
	end)

	local Sidebar = Create("Frame", {
		Name = "Sidebar",
		Parent = MainFrame,
		BackgroundColor3 = Library.Theme.Elevated,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(0, 160, 1, -44),
		ZIndex = 1
	})
	
	Create("Frame", {
		Name = "SidebarDivider",
		Parent = Sidebar,
		BackgroundColor3 = Library.Theme.Divider,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0)
	})

	local TabContainerList = Create("ScrollingFrame", {
		Name = "TabList",
		Parent = Sidebar,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 10),
		Size = UDim2.new(1, 0, 1, -20),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 0
	}, {
		Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center}),
		Create("UIPadding", {PaddingTop = UDim.new(0, 0), PaddingBottom = UDim.new(0, 0)})
	})

	local ContentContainer = Create("Frame", {
		Name = "ContentContainer",
		Parent = MainFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 160, 0, 44),
		Size = UDim2.new(1, -160, 1, -44),
		ZIndex = 1
	})

	function WindowObj:CreateTab(tabOptions)
		tabOptions = tabOptions or {}
		local TabName = tabOptions.Name or "Tab"
		local TabIcon = tabOptions.Icon or "rbxassetid://3926305904"
		
		local TabObj = {Sections = {}}

		local TabButton = Create("TextButton", {
			Name = TabName,
			Parent = TabContainerList,
			BackgroundColor3 = Library.Theme.Elevated,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -20, 0, 36),
			Text = "",
			AutoButtonColor = false
		}, { Create("UICorner", {CornerRadius = UDim.new(0, 10)}) })
		
		local TIcon = Create("ImageLabel", {
			Name = "Icon",
			Parent = TabButton,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0.5, -10),
			Size = UDim2.new(0, 20, 0, 20),
			Image = TabIcon,
			ImageRectOffset = tabOptions.IconRectOffset or Vector2.new(0,0),
			ImageRectSize = tabOptions.IconRectSize or Vector2.new(0,0),
			ImageColor3 = Library.Theme.TextSecondary
		})
		if tabOptions.IconRectSize == nil then TIcon.ImageRectSize = Vector2.new(0,0) end
		
		local TTitle = Create("TextLabel", {
			Name = "Title",
			Parent = TabButton,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 40, 0, 0),
			Size = UDim2.new(1, -40, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = TabName,
			TextColor3 = Library.Theme.TextSecondary,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left
		})

		local TabCanvas = Create("CanvasGroup", {
			Name = TabName.."_Canvas",
			Parent = ContentContainer,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			GroupTransparency = 1,
			Visible = false
		})
		
		local SectionScroll = Create("ScrollingFrame", {
			Name = "Scroll",
			Parent = TabCanvas,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Library.Theme.Secondary
		}, {
			Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center}),
			Create("UIPadding", {PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)})
		})
		
		SectionScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			SectionScroll.CanvasSize = UDim2.new(0, 0, 0, SectionScroll.UIListLayout.AbsoluteContentSize.Y + 28)
		end)

		local function SelectTab()
			if WindowObj.CurrentTab == TabObj then return end
			if WindowObj.CurrentTab then
				Tween(WindowObj.CurrentTab.Button, {BackgroundTransparency = 1}, 0.2)
				Tween(WindowObj.CurrentTab.Title, {TextColor3 = Library.Theme.TextSecondary}, 0.2)
				Tween(WindowObj.CurrentTab.Icon, {ImageColor3 = Library.Theme.TextSecondary}, 0.2)
				local oldCanvas = WindowObj.CurrentTab.Canvas
				Tween(oldCanvas, {GroupTransparency = 1}, 0.2).Completed:Connect(function()
					if WindowObj.CurrentTab ~= TabObj then oldCanvas.Visible = false end
				end)
			end
			WindowObj.CurrentTab = TabObj
			Tween(TabButton, {BackgroundTransparency = 0}, 0.2)
			Tween(TTitle, {TextColor3 = Library.Theme.TextPrimary}, 0.2)
			Tween(TIcon, {ImageColor3 = Library.Theme.TextPrimary}, 0.2)
			TabCanvas.Visible = true
			Tween(TabCanvas, {GroupTransparency = 0}, 0.2)
		end

		TabButton.MouseButton1Click:Connect(SelectTab)
		TabObj.Button = TabButton; TabObj.Title = TTitle; TabObj.Icon = TIcon; TabObj.Canvas = TabCanvas; TabObj.Scroll = SectionScroll
		
		if #WindowObj.Tabs == 0 then SelectTab() end
		table.insert(WindowObj.Tabs, TabObj)

		function TabObj:CreateSection(sectionName)
			local SectionObj = {}
			local SectionContainer = Create("Frame", {
				Name = "Section_"..sectionName,
				Parent = SectionScroll,
				BackgroundColor3 = Library.Theme.Elevated,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0, 12)}),
				Create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.94, Thickness = 1})
			})
			Create("UIListLayout", {Parent = SectionContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0)})
			
			local function AddDivider()
				if #SectionContainer:GetChildren() > 2 then
					Create("Frame", {
						Name = "Divider",
						Parent = SectionContainer,
						BackgroundColor3 = Library.Theme.Divider,
						BackgroundTransparency = 0.5,
						BorderSizePixel = 0,
						Position = UDim2.new(0, 12, 0, 0),
						Size = UDim2.new(1, -24, 0, 1)
					})
				end
			end

			-- Elements
			function SectionObj:CreateLabel(lblName)
				AddDivider()
				local LblFrame = Create("Frame", {Name = "Label", Parent = SectionContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36)})
				Create("TextLabel", {
					Parent = LblFrame,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 16, 0, 0),
					Size = UDim2.new(1, -32, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = lblName,
					TextColor3 = Library.Theme.TextPrimary,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				})
			end

			function SectionObj:CreateParagraph(pOptions)
				pOptions = pOptions or {}
				local Title = pOptions.Title or "Paragraph"
				local Content = pOptions.Content or "Content here"
				AddDivider()
				local PFrame = Create("Frame", {Name = "Paragraph", Parent = SectionContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
				Create("UIListLayout", {Parent = PFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
				Create("UIPadding", {Parent = PFrame, PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16)})
				
				Create("TextLabel", {
					Parent = PFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
					Font = Enum.Font.GothamMedium, Text = Title, TextColor3 = Library.Theme.TextPrimary,
					TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1
				})
				Create("TextLabel", {
					Parent = PFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
					Font = Enum.Font.Gotham, Text = Content, TextColor3 = Library.Theme.TextSecondary,
					TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, LayoutOrder = 2
				})
			end

			function SectionObj:CreateButton(btnOptions)
				btnOptions = btnOptions or {}
				local Name = btnOptions.Name or "Button"
				local Callback = btnOptions.Callback or function() end
				AddDivider()
				local BtnFrame = Create("Frame", {Name = Name, Parent = SectionContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44)})
				local BtnAct = Create("TextButton", {
					Parent = BtnFrame, BackgroundColor3 = Library.Theme.AccentBlue, BackgroundTransparency = 1,
					Size = UDim2.new(1, -24, 0, 32), Position = UDim2.new(0, 12, 0.5, -16), Text = "", AutoButtonColor = false
				}, { Create("UICorner", {CornerRadius = UDim.new(1, 0)}) })
				Create("TextLabel", {
					Parent = BtnAct, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
					Font = Enum.Font.GothamMedium, Text = Name, TextColor3 = Library.Theme.AccentBlue, TextSize = 14
				})
				BtnAct.MouseButton1Down:Connect(function() Tween(BtnAct, {BackgroundTransparency = 0.8, Size = UDim2.new(1, -30, 0, 28), Position = UDim2.new(0, 15, 0.5, -14)}, 0.15) end)
				BtnAct.MouseButton1Up:Connect(function() Tween(BtnAct, {BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 32), Position = UDim2.new(0, 12, 0.5, -16)}, 0.15); Callback() end)
				BtnAct.MouseLeave:Connect(function() Tween(BtnAct, {BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 32), Position = UDim2.new(0, 12, 0.5, -16)}, 0.15) end)
			end

			function SectionObj:CreateToggle(tglOptions)
				tglOptions = tglOptions or {}
				local Name = tglOptions.Name or "Toggle"
				local Flag = tglOptions.Flag or Name
				local CurrentValue = tglOptions.CurrentValue or false
				local Callback = tglOptions.Callback or function() end
				local ToggleObj = {Type = "Toggle", CurrentValue = CurrentValue, Flag = Flag}
				AddDivider()
				local TglFrame = Create("Frame", {Name = Name, Parent = SectionContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44)})
				Create("TextLabel", {
					Parent = TglFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(1, -100, 1, 0),
					Font = Enum.Font.GothamMedium, Text = Name, TextColor3 = Library.Theme.TextPrimary, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
				})
				local TglBg = Create("TextButton", {
					Parent = TglFrame, BackgroundColor3 = CurrentValue and Library.Theme.AccentGreen or Library.Theme.Secondary,
					BorderSizePixel = 0, Position = UDim2.new(1, -66, 0.5, -16), Size = UDim2.new(0, 50, 0, 32), Text = "", AutoButtonColor = false
				}, { Create("UICorner", {CornerRadius = UDim.new(1, 0)}) })
				local TglKnob = Create("Frame", {
					Parent = TglBg, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
					Position = CurrentValue and UDim2.new(1, -30, 0.5, -14) or UDim2.new(0, 2, 0.5, -14), Size = UDim2.new(0, 28, 0, 28)
				}, { Create("UICorner", {CornerRadius = UDim.new(1, 0)}), Create("UIStroke", {Color = Color3.fromRGB(0, 0, 0), Transparency = 0.9, Thickness = 1}) })
				
				function ToggleObj:Set(value)
					ToggleObj.CurrentValue = value
					Tween(TglBg, {BackgroundColor3 = value and Library.Theme.AccentGreen or Library.Theme.Secondary}, 0.25)
					Tween(TglKnob, {Position = value and UDim2.new(1, -30, 0.5, -14) or UDim2.new(0, 2, 0.5, -14)}, 0.3)
					Callback(value)
					if SaveConfig then Library:SaveConfiguration(ConfigName) end
				end
				TglBg.MouseButton1Click:Connect(function() ToggleObj:Set(not ToggleObj.CurrentValue) end)
				Library.Flags[Flag] = ToggleObj
				return ToggleObj
			end

			function SectionObj:CreateSlider(sldOptions)
				sldOptions = sldOptions or {}
				local Name = sldOptions.Name or "Slider"
				local Flag = sldOptions.Flag or Name
				local Min = sldOptions.Range and sldOptions.Range[1] or 0
				local Max = sldOptions.Range and sldOptions.Range[2] or 100
				local Increment = sldOptions.Increment or 1
				local CurrentValue = sldOptions.CurrentValue or Min
				local Callback = sldOptions.Callback or function() end
				local SliderObj = {Type = "Slider", CurrentValue = CurrentValue, Flag = Flag}
				AddDivider()
				local SldFrame = Create("Frame", {Name = Name, Parent = SectionContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 64)})
				Create("TextLabel", {
					Parent = SldFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 8), Size = UDim2.new(1, -100, 0, 20),
					Font = Enum.Font.GothamMedium, Text = Name, TextColor3 = Library.Theme.TextPrimary, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
				})
				local ValLabel = Create("TextLabel", {
					Parent = SldFrame, BackgroundTransparency = 1, Position = UDim2.new(1, -66, 0, 8), Size = UDim2.new(0, 50, 0, 20),
					Font = Enum.Font.GothamMedium, Text = tostring(CurrentValue), TextColor3 = Library.Theme.TextSecondary, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right
				})
				local TrackBg = Create("TextButton", {
					Parent = SldFrame, BackgroundColor3 = Library.Theme.Secondary, BorderSizePixel = 0,
					Position = UDim2.new(0, 16, 0, 36), Size = UDim2.new(1, -32, 0, 12), Text = "", AutoButtonColor = false
				}, { Create("UICorner", {CornerRadius = UDim.new(1, 0)}) })
				local TrackFill = Create("Frame", {
					Parent = TrackBg, BackgroundColor3 = Library.Theme.AccentBlue, BorderSizePixel = 0,
					Size = UDim2.new(math.clamp((CurrentValue - Min) / (Max - Min), 0, 1), 0, 1, 0)
				}, { Create("UICorner", {CornerRadius = UDim.new(1, 0)}) })
				
				local Dragging = false
				function SliderObj:Set(value)
					value = math.clamp(math.floor(value / Increment + 0.5) * Increment, Min, Max)
					SliderObj.CurrentValue = value
					ValLabel.Text = tostring(value)
					Tween(TrackFill, {Size = UDim2.new((value - Min) / (Max - Min), 0, 1, 0)}, 0.15)
					Callback(value)
					if SaveConfig and not Dragging then Library:SaveConfiguration(ConfigName) end
				end
				local function updateSlider(input)
					local percent = math.clamp((input.Position.X - TrackBg.AbsolutePosition.X) / TrackBg.AbsoluteSize.X, 0, 1)
					SliderObj:Set(Min + (percent * (Max - Min)))
				end
				TrackBg.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						Dragging = true; updateSlider(input)
					end
				end)
				TrackBg.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						Dragging = false; if SaveConfig then Library:SaveConfiguration(ConfigName) end
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateSlider(input) end
				end)
				Library.Flags[Flag] = SliderObj
				return SliderObj
			end

			function SectionObj:CreateDropdown(dropOptions)
				dropOptions = dropOptions or {}
				local Name = dropOptions.Name or "Dropdown"
				local Flag = dropOptions.Flag or Name
				local Options = dropOptions.Options or {}
				local Multi = dropOptions.Multi or false
				local CurrentValue = dropOptions.CurrentValue or (Multi and {} or Options[1] or "")
				local Callback = dropOptions.Callback or function() end
				local DropObj = {Type = "Dropdown", CurrentValue = CurrentValue, Options = Options, Flag = Flag, Multi = Multi}
				AddDivider()
				
				local DropFrame = Create("Frame", {Name = Name, Parent = SectionContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), ClipsDescendants = true})
				local MainBtn = Create("TextButton", {Parent = DropFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), Text = ""})
				Create("TextLabel", {
					Parent = MainBtn, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
					Font = Enum.Font.GothamMedium, Text = Name, TextColor3 = Library.Theme.TextPrimary, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
				})
				local ValLabel = Create("TextLabel", {
					Parent = MainBtn, BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -40, 1, 0),
					Font = Enum.Font.Gotham, Text = Multi and table.concat(CurrentValue, ", ") or tostring(CurrentValue), TextColor3 = Library.Theme.TextSecondary, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right
				})
				local IconChevron = Create("ImageLabel", {
					Parent = MainBtn, BackgroundTransparency = 1, Position = UDim2.new(1, -30, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
					Image = "rbxassetid://3926305904", ImageRectOffset = Vector2.new(564, 284), ImageRectSize = Vector2.new(36, 36), ImageColor3 = Library.Theme.TextSecondary
				})
				local OptionList = Create("Frame", {
					Parent = DropFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 44), Size = UDim2.new(1, -32, 0, 0)
				}, { Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)}) })
				
				local IsOpen = false
				local function BuildOptions()
					for _, v in pairs(OptionList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
					for _, opt in ipairs(DropObj.Options) do
						local isSelected = Multi and table.find(DropObj.CurrentValue, opt) or (not Multi and DropObj.CurrentValue == opt)
						local OptBtn = Create("TextButton", {
							Name = opt, Parent = OptionList, BackgroundColor3 = isSelected and Library.Theme.AccentBlue or Library.Theme.Secondary,
							BackgroundTransparency = isSelected and 0.2 or 0.5, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 32),
							Font = Enum.Font.Gotham, Text = "  " .. opt, TextColor3 = Library.Theme.TextPrimary, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false
						}, { Create("UICorner", {CornerRadius = UDim.new(0, 6)}) })
						
						OptBtn.MouseButton1Click:Connect(function()
							if Multi then
								local idx = table.find(DropObj.CurrentValue, opt)
								if idx then table.remove(DropObj.CurrentValue, idx) else table.insert(DropObj.CurrentValue, opt) end
								DropObj:Set(DropObj.CurrentValue)
								BuildOptions() -- Rebuild to show active states
							else
								DropObj:Set(opt)
								DropObj:Toggle()
							end
						end)
					end
				end
				
				function DropObj:Set(value)
					DropObj.CurrentValue = value
					ValLabel.Text = Multi and table.concat(value, ", ") or tostring(value)
					Callback(value)
					if SaveConfig then Library:SaveConfiguration(ConfigName) end
				end
				function DropObj:Toggle()
					IsOpen = not IsOpen
					if IsOpen then
						BuildOptions()
						Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 44 + (#DropObj.Options * 36))}, 0.3)
						Tween(IconChevron, {Rotation = 180}, 0.3)
					else
						Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 44)}, 0.3)
						Tween(IconChevron, {Rotation = 0}, 0.3)
					end
				end
				MainBtn.MouseButton1Click:Connect(function() DropObj:Toggle() end)
				Library.Flags[Flag] = DropObj
				return DropObj
			end
			
			function SectionObj:CreateKeybind(keyOptions)
				keyOptions = keyOptions or {}
				local Name = keyOptions.Name or "Keybind"
				local Flag = keyOptions.Flag or Name
				local CurrentKeybind = keyOptions.CurrentKeybind or Enum.KeyCode.E
				local Callback = keyOptions.Callback or function() end
				local KeyObj = {Type = "Keybind", CurrentKeybind = CurrentKeybind, Flag = Flag}
				AddDivider()
				
				local KeyFrame = Create("Frame", {Name = Name, Parent = SectionContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44)})
				Create("TextLabel", {
					Parent = KeyFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
					Font = Enum.Font.GothamMedium, Text = Name, TextColor3 = Library.Theme.TextPrimary, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
				})
				local KeyBtn = Create("TextButton", {
					Parent = KeyFrame, BackgroundColor3 = Library.Theme.Secondary, BackgroundTransparency = 0.5, BorderSizePixel = 0,
					Position = UDim2.new(1, -76, 0.5, -14), Size = UDim2.new(0, 60, 0, 28), Text = CurrentKeybind.Name, Font = Enum.Font.GothamMedium,
					TextColor3 = Library.Theme.TextPrimary, TextSize = 13, AutoButtonColor = false
				}, { Create("UICorner", {CornerRadius = UDim.new(0, 6)}) })
				
				local isBinding = false
				function KeyObj:Set(key)
					KeyObj.CurrentKeybind = key
					KeyBtn.Text = key.Name
					if SaveConfig then Library:SaveConfiguration(ConfigName) end
				end
				
				KeyBtn.MouseButton1Click:Connect(function()
					isBinding = true
					KeyBtn.Text = "..."
					Tween(KeyBtn, {BackgroundColor3 = Library.Theme.AccentBlue}, 0.2)
				end)
				
				UserInputService.InputBegan:Connect(function(input, processed)
					if isBinding and input.UserInputType == Enum.UserInputType.Keyboard then
						isBinding = false
						Tween(KeyBtn, {BackgroundColor3 = Library.Theme.Secondary}, 0.2)
						KeyObj:Set(input.KeyCode)
					elseif not isBinding and input.KeyCode == KeyObj.CurrentKeybind and not processed then
						Callback(KeyObj.CurrentKeybind)
					end
				end)
				
				Library.Flags[Flag] = KeyObj
				return KeyObj
			end
			
			function SectionObj:CreateColorPicker(cpOptions)
				cpOptions = cpOptions or {}
				local Name = cpOptions.Name or "ColorPicker"
				local Flag = cpOptions.Flag or Name
				local CurrentColor = cpOptions.Color or Color3.fromRGB(255, 255, 255)
				local Callback = cpOptions.Callback or function() end
				local CPObj = {Type = "ColorPicker", CurrentValue = CurrentColor, Flag = Flag}
				AddDivider()
				
				local CPFrame = Create("Frame", {Name = Name, Parent = SectionContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), ClipsDescendants = true})
				local MainBtn = Create("TextButton", {Parent = CPFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), Text = ""})
				Create("TextLabel", {
					Parent = MainBtn, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
					Font = Enum.Font.GothamMedium, Text = Name, TextColor3 = Library.Theme.TextPrimary, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
				})
				local ColorPreview = Create("Frame", {
					Parent = MainBtn, BackgroundColor3 = CurrentColor, Position = UDim2.new(1, -76, 0.5, -14), Size = UDim2.new(0, 60, 0, 28)
				}, { Create("UICorner", {CornerRadius = UDim.new(0, 6)}) })
				
				local SlidersFrame = Create("Frame", {
					Parent = CPFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 44), Size = UDim2.new(1, -32, 0, 100)
				}, { Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)}) })
				
				local function CreateRGBTrack(name, colorTheme, defaultVal, layoutOrder)
					local TrackFrame = Create("Frame", {Parent = SlidersFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = layoutOrder})
					Create("TextLabel", {
						Parent = TrackFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 20, 1, 0),
						Font = Enum.Font.GothamMedium, Text = name, TextColor3 = Library.Theme.TextSecondary, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left
					})
					local TrackBg = Create("TextButton", {
						Parent = TrackFrame, BackgroundColor3 = Library.Theme.Secondary, BorderSizePixel = 0,
						Position = UDim2.new(0, 25, 0.5, -6), Size = UDim2.new(1, -65, 0, 12), Text = "", AutoButtonColor = false
					}, { Create("UICorner", {CornerRadius = UDim.new(1, 0)}) })
					local TrackFill = Create("Frame", {
						Parent = TrackBg, BackgroundColor3 = colorTheme, BorderSizePixel = 0,
						Size = UDim2.new(defaultVal, 0, 1, 0)
					}, { Create("UICorner", {CornerRadius = UDim.new(1, 0)}) })
					local ValInput = Create("TextBox", {
						Parent = TrackFrame, BackgroundTransparency = 1, Position = UDim2.new(1, -35, 0, 0), Size = UDim2.new(0, 35, 1, 0),
						Font = Enum.Font.Gotham, Text = tostring(math.floor(defaultVal * 255)), TextColor3 = Library.Theme.TextPrimary, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right
					})
					return TrackBg, TrackFill, ValInput
				end
				
				local rBg, rFill, rVal = CreateRGBTrack("R", Color3.fromRGB(255, 69, 58), CurrentColor.R, 1)
				local gBg, gFill, gVal = CreateRGBTrack("G", Color3.fromRGB(48, 209, 88), CurrentColor.G, 2)
				local bBg, bFill, bVal = CreateRGBTrack("B", Color3.fromRGB(10, 132, 255), CurrentColor.B, 3)
				
				local IsOpen = false
				
				local function updateColor()
					local r = tonumber(rVal.Text) or 255; local g = tonumber(gVal.Text) or 255; local b = tonumber(bVal.Text) or 255
					CPObj:Set(Color3.fromRGB(r, g, b))
				end
				
				local function setupDrag(trackBg, fill, valBox, colorChannel)
					local Dragging = false
					trackBg.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							Dragging = true
							local percent = math.clamp((input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
							valBox.Text = tostring(math.floor(percent * 255)); updateColor()
						end
					end)
					trackBg.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
					end)
					UserInputService.InputChanged:Connect(function(input)
						if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							local percent = math.clamp((input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
							valBox.Text = tostring(math.floor(percent * 255)); updateColor()
						end
					end)
					valBox.FocusLost:Connect(function()
						local val = math.clamp(tonumber(valBox.Text) or 255, 0, 255)
						valBox.Text = tostring(val); updateColor()
					end)
				end
				
				setupDrag(rBg, rFill, rVal, "R")
				setupDrag(gBg, gFill, gVal, "G")
				setupDrag(bBg, bFill, bVal, "B")
				
				function CPObj:Set(color)
					CPObj.CurrentValue = color
					Tween(ColorPreview, {BackgroundColor3 = color}, 0.2)
					Tween(rFill, {Size = UDim2.new(color.R, 0, 1, 0)}, 0.15)
					Tween(gFill, {Size = UDim2.new(color.G, 0, 1, 0)}, 0.15)
					Tween(bFill, {Size = UDim2.new(color.B, 0, 1, 0)}, 0.15)
					rVal.Text = tostring(math.floor(color.R * 255))
					gVal.Text = tostring(math.floor(color.G * 255))
					bVal.Text = tostring(math.floor(color.B * 255))
					Callback(color)
					if SaveConfig then Library:SaveConfiguration(ConfigName) end
				end
				
				function CPObj:Toggle()
					IsOpen = not IsOpen
					if IsOpen then Tween(CPFrame, {Size = UDim2.new(1, 0, 0, 144)}, 0.3)
					else Tween(CPFrame, {Size = UDim2.new(1, 0, 0, 44)}, 0.3) end
				end
				
				MainBtn.MouseButton1Click:Connect(function() CPObj:Toggle() end)
				Library.Flags[Flag] = CPObj
				return CPObj
			end
			
			function SectionObj:CreateInput(inpOptions)
				inpOptions = inpOptions or {}
				local Name = inpOptions.Name or "Input"
				local Flag = inpOptions.Flag or Name
				local CurrentValue = inpOptions.CurrentValue or ""
				local Placeholder = inpOptions.PlaceholderText or "Text..."
				local Callback = inpOptions.Callback or function() end
				local InputObj = {Type = "Input", CurrentValue = CurrentValue, Flag = Flag}
				AddDivider()
				local InpFrame = Create("Frame", {Name = Name, Parent = SectionContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44)})
				Create("TextLabel", {
					Parent = InpFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
					Font = Enum.Font.GothamMedium, Text = Name, TextColor3 = Library.Theme.TextPrimary, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
				})
				local TxtBox = Create("TextBox", {
					Parent = InpFrame, BackgroundColor3 = Library.Theme.Secondary, BackgroundTransparency = 0.5, BorderSizePixel = 0,
					Position = UDim2.new(0.5, 10, 0.5, -14), Size = UDim2.new(0.5, -26, 0, 28), Font = Enum.Font.Gotham,
					PlaceholderText = Placeholder, PlaceholderColor3 = Library.Theme.TextSecondary, Text = CurrentValue,
					TextColor3 = Library.Theme.TextPrimary, TextSize = 14, ClearTextOnFocus = false
				}, { Create("UICorner", {CornerRadius = UDim.new(0, 6)}) })
				
				function InputObj:Set(value)
					InputObj.CurrentValue = value
					TxtBox.Text = tostring(value)
					Callback(value)
					if SaveConfig then Library:SaveConfiguration(ConfigName) end
				end
				TxtBox.FocusLost:Connect(function() InputObj:Set(TxtBox.Text) end)
				Library.Flags[Flag] = InputObj
				return InputObj
			end

			table.insert(TabObj.Sections, SectionObj)
			return SectionObj
		end
		return TabObj
	end
	return WindowObj
end

return Library
