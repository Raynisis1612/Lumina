-- iOS 19 UI Library
-- A high-performance, completely custom Roblox UI Library with an Apple iOS 19 aesthetic.

local Library = {
	Settings = {
		ConfigurationFolder = "iOS19_Configs",
		ConfigurationExtension = ".ios19"
	},
	Flags = {},
	Elements = {},
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
	}
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
				if input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
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
	
	if not isfolder(self.Settings.ConfigurationFolder) then
		makefolder(self.Settings.ConfigurationFolder)
	end
	
	local data = {}
	for flag, element in pairs(self.Flags) do
		if element.Type == "Toggle" then
			data[flag] = element.CurrentValue
		elseif element.Type == "Slider" then
			data[flag] = element.CurrentValue
		elseif element.Type == "Dropdown" then
			data[flag] = element.CurrentValue
		elseif element.Type == "Input" then
			data[flag] = element.CurrentValue
		end
	end
	
	local success, encoded = pcall(function()
		return HttpService:JSONEncode(data)
	end)
	
	if success then
		writefile(self.Settings.ConfigurationFolder .. "/" .. name .. self.Settings.ConfigurationExtension, encoded)
	end
end

function Library:LoadConfiguration(name)
	if not isfolder or not readfile then return end
	local path = self.Settings.ConfigurationFolder .. "/" .. name .. self.Settings.ConfigurationExtension
	if isfile and isfile(path) then
		local data = readfile(path)
		local success, decoded = pcall(function()
			return HttpService:JSONDecode(data)
		end)
		
		if success then
			for flag, value in pairs(decoded) do
				if self.Flags[flag] then
					pcall(function()
						self.Flags[flag]:Set(value)
					end)
				end
			end
		end
	end
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
		CurrentTab = nil
	}
	
	local ScreenGui = Create("ScreenGui", {
		Name = "iOS19Interface",
		Parent = ParentGui,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	})
	
	-- Destroy old instances
	for _, child in pairs(ParentGui:GetChildren()) do
		if child.Name == "iOS19Interface" and child ~= ScreenGui then
			child:Destroy()
		end
	end

	-- Main Container
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
		-- Drop Shadow (Simulating glossy liquid glass feel)
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
	
	-- Intro Tween
	MainFrame.Size = UDim2.new(0, 580, 0, 380)
	Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 400)}, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	-- Topbar
	local Topbar = Create("Frame", {
		Name = "Topbar",
		Parent = MainFrame,
		BackgroundColor3 = Library.Theme.Background,
		BackgroundTransparency = 0.2, -- Glass effect
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 44),
		ZIndex = 2
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 16)})
	})
	
	-- Fix bottom corners of topbar
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
	
	-- Topbar Divider
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
	
	-- Title and Icon
	local TitleLabel = Create("TextLabel", {
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
	
	local Icon = Create("ImageLabel", {
		Name = "Icon",
		Parent = Topbar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0.5, -10),
		Size = UDim2.new(0, 20, 0, 20),
		Image = "rbxassetid://10804731440", -- Rayfield icon as requested/similar star
		ImageColor3 = Library.Theme.TextPrimary,
		ZIndex = 3
	})

	-- Window Controls (Minimize / Close)
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
		Tween(MainFrame, {Size = UDim2.new(0, 580, 0, 380)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		Tween(MainFrame:FindFirstChildOfClass("UIStroke"), {Transparency = 1}, 0.3)
		Tween(ScreenGui, {DisplayOrder = -1}, 0.3) -- Hide trick
		if MainFrame:IsA("CanvasGroup") then
			Tween(MainFrame, {GroupTransparency = 1}, 0.3).Completed:Connect(function()
				ScreenGui:Destroy()
			end)
		else
			-- Manual transparency
			for _, v in pairs(MainFrame:GetDescendants()) do
				if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
					Tween(v, {TextTransparency = 1}, 0.3)
				elseif v:IsA("ImageLabel") or v:IsA("ImageButton") then
					Tween(v, {ImageTransparency = 1}, 0.3)
				elseif v:IsA("Frame") or v:IsA("ScrollingFrame") then
					Tween(v, {BackgroundTransparency = 1}, 0.3)
				elseif v:IsA("UIStroke") then
					Tween(v, {Transparency = 1}, 0.3)
				end
			end
			Tween(MainFrame, {BackgroundTransparency = 1}, 0.3).Completed:Connect(function()
				ScreenGui:Destroy()
			end)
		end
	end)

	-- Sidebar (Tabs)
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
	
	-- Sidebar Divider
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
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Center
		}),
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 0),
			PaddingBottom = UDim.new(0, 0)
		})
	})

	-- Content Area (Where sections go)
	local ContentContainer = Create("Frame", {
		Name = "ContentContainer",
		Parent = MainFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 160, 0, 44),
		Size = UDim2.new(1, -160, 1, -44),
		ZIndex = 1
	})

	-- Create Tab Function
	function WindowObj:CreateTab(tabOptions)
		tabOptions = tabOptions or {}
		local TabName = tabOptions.Name or "Tab"
		local TabIcon = tabOptions.Icon or "rbxassetid://3926305904" -- Default generic icon
		
		local TabObj = {
			Sections = {}
		}

		-- Tab Button
		local TabButton = Create("TextButton", {
			Name = TabName,
			Parent = TabContainerList,
			BackgroundColor3 = Library.Theme.Elevated,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -20, 0, 36),
			Text = "",
			AutoButtonColor = false
		}, {
			Create("UICorner", {CornerRadius = UDim.new(0, 10)})
		})
		
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
		if tabOptions.IconRectSize == nil then
			TIcon.ImageRectSize = Vector2.new(0,0) -- Clear if not needed, rely on full image
		end
		
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

		-- Tab Canvas
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
			Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 12),
				HorizontalAlignment = Enum.HorizontalAlignment.Center
			}),
			Create("UIPadding", {
				PaddingTop = UDim.new(0, 14),
				PaddingBottom = UDim.new(0, 14),
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 14)
			})
		})
		
		-- Auto-resize canvas
		SectionScroll.UIListLayout.GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			SectionScroll.CanvasSize = UDim2.new(0, 0, 0, SectionScroll.UIListLayout.AbsoluteContentSize.Y + 28)
		end)

		-- Select Tab Logic
		local function SelectTab()
			if WindowObj.CurrentTab == TabObj then return end
			
			-- Deselect current
			if WindowObj.CurrentTab then
				Tween(WindowObj.CurrentTab.Button, {BackgroundTransparency = 1}, 0.2)
				Tween(WindowObj.CurrentTab.Title, {TextColor3 = Library.Theme.TextSecondary}, 0.2)
				Tween(WindowObj.CurrentTab.Icon, {ImageColor3 = Library.Theme.TextSecondary}, 0.2)
				
				local oldCanvas = WindowObj.CurrentTab.Canvas
				Tween(oldCanvas, {GroupTransparency = 1}, 0.2).Completed:Connect(function()
					if WindowObj.CurrentTab ~= TabObj then
						oldCanvas.Visible = false
					end
				end)
			end
			
			WindowObj.CurrentTab = TabObj
			
			-- Select new
			Tween(TabButton, {BackgroundTransparency = 0}, 0.2)
			Tween(TTitle, {TextColor3 = Library.Theme.TextPrimary}, 0.2)
			Tween(TIcon, {ImageColor3 = Library.Theme.TextPrimary}, 0.2)
			
			TabCanvas.Visible = true
			Tween(TabCanvas, {GroupTransparency = 0}, 0.2)
		end

		TabButton.MouseButton1Click:Connect(SelectTab)
		
		TabObj.Button = TabButton
		TabObj.Title = TTitle
		TabObj.Icon = TIcon
		TabObj.Canvas = TabCanvas
		TabObj.Scroll = SectionScroll
		
		-- Auto select first tab
		if #WindowObj.Tabs == 0 then
			SelectTab()
		end
		
		table.insert(WindowObj.Tabs, TabObj)

		-- Create Section Function
		function TabObj:CreateSection(sectionName)
			local SectionObj = {}
			
			local SectionContainer = Create("Frame", {
				Name = "Section_"..sectionName,
				Parent = SectionScroll,
				BackgroundColor3 = Library.Theme.Elevated,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0), -- Auto height later
				AutomaticSize = Enum.AutomaticSize.Y
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0, 12)}),
				Create("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Transparency = 0.94,
					Thickness = 1
				})
			})
			
			local SectionLayout = Create("UIListLayout", {
				Parent = SectionContainer,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 0)
			})
			
			-- Elements within Section
			function SectionObj:CreateButton(btnOptions)
				btnOptions = btnOptions or {}
				local Name = btnOptions.Name or "Button"
				local Callback = btnOptions.Callback or function() end
				
				local BtnFrame = Create("Frame", {
					Name = Name,
					Parent = SectionContainer,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 44)
				})
				
				local BtnAct = Create("TextButton", {
					Name = "Action",
					Parent = BtnFrame,
					BackgroundColor3 = Library.Theme.AccentBlue,
					BackgroundTransparency = 1, -- Start invisible, just text
					Size = UDim2.new(1, -24, 0, 32),
					Position = UDim2.new(0, 12, 0.5, -16),
					Text = "",
					AutoButtonColor = false
				}, {
					Create("UICorner", {CornerRadius = UDim.new(1, 0)})
				})
				
				local BtnText = Create("TextLabel", {
					Parent = BtnAct,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = Name,
					TextColor3 = Library.Theme.AccentBlue,
					TextSize = 14
				})
				
				-- Divider (unless it's the last element, but for dynamic we just add it to all except the first? we can add it to the top of elements if LayoutOrder > 0)
				if #SectionContainer:GetChildren() > 2 then -- More than Layout+Corner
					Create("Frame", {
						Name = "Divider",
						Parent = BtnFrame,
						BackgroundColor3 = Library.Theme.Divider,
						BackgroundTransparency = 0.5,
						BorderSizePixel = 0,
						Position = UDim2.new(0, 12, 0, 0),
						Size = UDim2.new(1, -24, 0, 1)
					})
				end
				
				BtnAct.MouseButton1Down:Connect(function()
					Tween(BtnAct, {BackgroundTransparency = 0.8, Size = UDim2.new(1, -30, 0, 28), Position = UDim2.new(0, 15, 0.5, -14)}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				end)
				BtnAct.MouseButton1Up:Connect(function()
					Tween(BtnAct, {BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 32), Position = UDim2.new(0, 12, 0.5, -16)}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					Callback()
				end)
				BtnAct.MouseLeave:Connect(function()
					Tween(BtnAct, {BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 32), Position = UDim2.new(0, 12, 0.5, -16)}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				end)
			end

			function SectionObj:CreateToggle(tglOptions)
				tglOptions = tglOptions or {}
				local Name = tglOptions.Name or "Toggle"
				local Flag = tglOptions.Flag or Name
				local CurrentValue = tglOptions.CurrentValue or false
				local Callback = tglOptions.Callback or function() end
				
				local ToggleObj = {
					Type = "Toggle",
					CurrentValue = CurrentValue,
					Flag = Flag
				}
				
				local TglFrame = Create("Frame", {
					Name = Name,
					Parent = SectionContainer,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 44)
				})
				
				if #SectionContainer:GetChildren() > 2 then
					Create("Frame", {
						Name = "Divider",
						Parent = TglFrame,
						BackgroundColor3 = Library.Theme.Divider,
						BackgroundTransparency = 0.5,
						BorderSizePixel = 0,
						Position = UDim2.new(0, 12, 0, 0),
						Size = UDim2.new(1, -24, 0, 1)
					})
				end
				
				Create("TextLabel", {
					Parent = TglFrame,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 16, 0, 0),
					Size = UDim2.new(1, -100, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = Name,
					TextColor3 = Library.Theme.TextPrimary,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				})
				
				local TglBg = Create("TextButton", {
					Name = "Bg",
					Parent = TglFrame,
					BackgroundColor3 = CurrentValue and Library.Theme.AccentGreen or Library.Theme.Secondary,
					BorderSizePixel = 0,
					Position = UDim2.new(1, -66, 0.5, -16),
					Size = UDim2.new(0, 50, 0, 32),
					Text = "",
					AutoButtonColor = false
				}, {
					Create("UICorner", {CornerRadius = UDim.new(1, 0)})
				})
				
				local TglKnob = Create("Frame", {
					Name = "Knob",
					Parent = TglBg,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					Position = CurrentValue and UDim2.new(1, -30, 0.5, -14) or UDim2.new(0, 2, 0.5, -14),
					Size = UDim2.new(0, 28, 0, 28)
				}, {
					Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
					Create("UIStroke", {
						Color = Color3.fromRGB(0, 0, 0),
						Transparency = 0.9,
						Thickness = 1
					})
				})
				
				function ToggleObj:Set(value)
					ToggleObj.CurrentValue = value
					Tween(TglBg, {BackgroundColor3 = value and Library.Theme.AccentGreen or Library.Theme.Secondary}, 0.25)
					Tween(TglKnob, {Position = value and UDim2.new(1, -30, 0.5, -14) or UDim2.new(0, 2, 0.5, -14)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					Callback(value)
					if SaveConfig then Library:SaveConfiguration(ConfigName) end
				end
				
				TglBg.MouseButton1Click:Connect(function()
					ToggleObj:Set(not ToggleObj.CurrentValue)
				end)
				
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
				
				local SliderObj = {
					Type = "Slider",
					CurrentValue = CurrentValue,
					Flag = Flag
				}
				
				local SldFrame = Create("Frame", {
					Name = Name,
					Parent = SectionContainer,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 64)
				})
				
				if #SectionContainer:GetChildren() > 2 then
					Create("Frame", {
						Name = "Divider",
						Parent = SldFrame,
						BackgroundColor3 = Library.Theme.Divider,
						BackgroundTransparency = 0.5,
						BorderSizePixel = 0,
						Position = UDim2.new(0, 12, 0, 0),
						Size = UDim2.new(1, -24, 0, 1)
					})
				end
				
				Create("TextLabel", {
					Parent = SldFrame,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 16, 0, 8),
					Size = UDim2.new(1, -100, 0, 20),
					Font = Enum.Font.GothamMedium,
					Text = Name,
					TextColor3 = Library.Theme.TextPrimary,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				})
				
				local ValLabel = Create("TextLabel", {
					Parent = SldFrame,
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -66, 0, 8),
					Size = UDim2.new(0, 50, 0, 20),
					Font = Enum.Font.GothamMedium,
					Text = tostring(CurrentValue),
					TextColor3 = Library.Theme.TextSecondary,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Right
				})
				
				local TrackBg = Create("TextButton", {
					Name = "Track",
					Parent = SldFrame,
					BackgroundColor3 = Library.Theme.Secondary,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 16, 0, 36),
					Size = UDim2.new(1, -32, 0, 12),
					Text = "",
					AutoButtonColor = false
				}, {
					Create("UICorner", {CornerRadius = UDim.new(1, 0)})
				})
				
				local TrackFill = Create("Frame", {
					Name = "Fill",
					Parent = TrackBg,
					BackgroundColor3 = Library.Theme.AccentBlue,
					BorderSizePixel = 0,
					Size = UDim2.new(math.clamp((CurrentValue - Min) / (Max - Min), 0, 1), 0, 1, 0)
				}, {
					Create("UICorner", {CornerRadius = UDim.new(1, 0)})
				})
				
				local Dragging = false
				
				function SliderObj:Set(value)
					value = math.clamp(math.floor(value / Increment + 0.5) * Increment, Min, Max)
					SliderObj.CurrentValue = value
					ValLabel.Text = tostring(value)
					local percent = (value - Min) / (Max - Min)
					Tween(TrackFill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					Callback(value)
					if SaveConfig and not Dragging then Library:SaveConfiguration(ConfigName) end
				end
				
				local function updateSlider(input)
					local percent = math.clamp((input.Position.X - TrackBg.AbsolutePosition.X) / TrackBg.AbsoluteSize.X, 0, 1)
					local value = Min + (percent * (Max - Min))
					SliderObj:Set(value)
				end
				
				TrackBg.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						Dragging = true
						updateSlider(input)
					end
				end)
				
				TrackBg.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						Dragging = false
						if SaveConfig then Library:SaveConfiguration(ConfigName) end
					end
				end)
				
				UserInputService.InputChanged:Connect(function(input)
					if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						updateSlider(input)
					end
				end)
				
				Library.Flags[Flag] = SliderObj
				return SliderObj
			end

			function SectionObj:CreateInput(inpOptions)
				inpOptions = inpOptions or {}
				local Name = inpOptions.Name or "Input"
				local Flag = inpOptions.Flag or Name
				local CurrentValue = inpOptions.CurrentValue or ""
				local Placeholder = inpOptions.PlaceholderText or "Text..."
				local Callback = inpOptions.Callback or function() end
				
				local InputObj = {
					Type = "Input",
					CurrentValue = CurrentValue,
					Flag = Flag
				}
				
				local InpFrame = Create("Frame", {
					Name = Name,
					Parent = SectionContainer,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 44)
				})
				
				if #SectionContainer:GetChildren() > 2 then
					Create("Frame", {
						Name = "Divider",
						Parent = InpFrame,
						BackgroundColor3 = Library.Theme.Divider,
						BackgroundTransparency = 0.5,
						BorderSizePixel = 0,
						Position = UDim2.new(0, 12, 0, 0),
						Size = UDim2.new(1, -24, 0, 1)
					})
				end
				
				Create("TextLabel", {
					Parent = InpFrame,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 16, 0, 0),
					Size = UDim2.new(0.5, 0, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = Name,
					TextColor3 = Library.Theme.TextPrimary,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				})
				
				local TxtBox = Create("TextBox", {
					Parent = InpFrame,
					BackgroundColor3 = Library.Theme.Secondary,
					BackgroundTransparency = 0.5,
					BorderSizePixel = 0,
					Position = UDim2.new(0.5, 10, 0.5, -14),
					Size = UDim2.new(0.5, -26, 0, 28),
					Font = Enum.Font.Gotham,
					PlaceholderText = Placeholder,
					PlaceholderColor3 = Library.Theme.TextSecondary,
					Text = CurrentValue,
					TextColor3 = Library.Theme.TextPrimary,
					TextSize = 14,
					ClearTextOnFocus = false
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0, 6)})
				})
				
				function InputObj:Set(value)
					InputObj.CurrentValue = value
					TxtBox.Text = tostring(value)
					Callback(value)
					if SaveConfig then Library:SaveConfiguration(ConfigName) end
				end
				
				TxtBox.FocusLost:Connect(function()
					InputObj:Set(TxtBox.Text)
				end)
				
				Library.Flags[Flag] = InputObj
				return InputObj
			end
			
			function SectionObj:CreateDropdown(dropOptions)
				dropOptions = dropOptions or {}
				local Name = dropOptions.Name or "Dropdown"
				local Flag = dropOptions.Flag or Name
				local Options = dropOptions.Options or {}
				local CurrentValue = dropOptions.CurrentValue or Options[1] or ""
				local Callback = dropOptions.Callback or function() end
				
				local DropObj = {
					Type = "Dropdown",
					CurrentValue = CurrentValue,
					Options = Options,
					Flag = Flag
				}
				
				local DropFrame = Create("Frame", {
					Name = Name,
					Parent = SectionContainer,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 44),
					ClipsDescendants = true
				})
				
				if #SectionContainer:GetChildren() > 2 then
					Create("Frame", {
						Name = "Divider",
						Parent = DropFrame,
						BackgroundColor3 = Library.Theme.Divider,
						BackgroundTransparency = 0.5,
						BorderSizePixel = 0,
						Position = UDim2.new(0, 12, 0, 0),
						Size = UDim2.new(1, -24, 0, 1)
					})
				end
				
				local MainBtn = Create("TextButton", {
					Name = "Main",
					Parent = DropFrame,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 44),
					Text = ""
				})
				
				Create("TextLabel", {
					Parent = MainBtn,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 16, 0, 0),
					Size = UDim2.new(0.5, 0, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = Name,
					TextColor3 = Library.Theme.TextPrimary,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				})
				
				local ValLabel = Create("TextLabel", {
					Parent = MainBtn,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.5, 0, 0, 0),
					Size = UDim2.new(0.5, -40, 1, 0),
					Font = Enum.Font.Gotham,
					Text = CurrentValue,
					TextColor3 = Library.Theme.TextSecondary,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Right
				})
				
				local IconChevron = Create("ImageLabel", {
					Parent = MainBtn,
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -30, 0.5, -8),
					Size = UDim2.new(0, 16, 0, 16),
					Image = "rbxassetid://3926305904",
					ImageRectOffset = Vector2.new(564, 284),
					ImageRectSize = Vector2.new(36, 36),
					ImageColor3 = Library.Theme.TextSecondary
				})
				
				local OptionList = Create("Frame", {
					Name = "List",
					Parent = DropFrame,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 16, 0, 44),
					Size = UDim2.new(1, -32, 0, 0)
				}, {
					Create("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 4)
					})
				})
				
				local IsOpen = false
				
				local function BuildOptions()
					for _, v in pairs(OptionList:GetChildren()) do
						if v:IsA("TextButton") then v:Destroy() end
					end
					
					for i, opt in ipairs(DropObj.Options) do
						local OptBtn = Create("TextButton", {
							Name = opt,
							Parent = OptionList,
							BackgroundColor3 = Library.Theme.Secondary,
							BackgroundTransparency = 0.5,
							BorderSizePixel = 0,
							Size = UDim2.new(1, 0, 0, 32),
							Font = Enum.Font.Gotham,
							Text = "  " .. opt,
							TextColor3 = Library.Theme.TextPrimary,
							TextSize = 14,
							TextXAlignment = Enum.TextXAlignment.Left,
							AutoButtonColor = false
						}, {
							Create("UICorner", {CornerRadius = UDim.new(0, 6)})
						})
						
						OptBtn.MouseButton1Click:Connect(function()
							DropObj:Set(opt)
							DropObj:Toggle()
						end)
					end
				end
				
				function DropObj:Set(value)
					DropObj.CurrentValue = value
					ValLabel.Text = tostring(value)
					Callback(value)
					if SaveConfig then Library:SaveConfiguration(ConfigName) end
				end
				
				function DropObj:Toggle()
					IsOpen = not IsOpen
					if IsOpen then
						BuildOptions()
						local targetHeight = 44 + (#DropObj.Options * 36)
						Tween(DropFrame, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
						Tween(IconChevron, {Rotation = 180}, 0.3)
					else
						Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 44)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
						Tween(IconChevron, {Rotation = 0}, 0.3)
					end
				end
				
				MainBtn.MouseButton1Click:Connect(function()
					DropObj:Toggle()
				end)
				
				Library.Flags[Flag] = DropObj
				return DropObj
			end

			table.insert(TabObj.Sections, SectionObj)
			return SectionObj
		end

		return TabObj
	end

	return WindowObj
end

return Library
