--[[
    ██╗     ██╗   ██╗███╗   ███╗██╗███╗   ██╗ █████╗     ██╗   ██╗██╗
    ██║     ██║   ██║████╗ ████║██║████╗  ██║██╔══██╗    ██║   ██║██║
    ██║     ██║   ██║██╔████╔██║██║██╔██╗ ██║███████║    ██║   ██║██║
    ██║     ██║   ██║██║╚██╔╝██║██║██║╚██╗██║██╔══██║    ██║   ██║██║
    ███████╗╚██████╔╝██║ ╚═╝ ██║██║██║ ╚████║██║  ██║    ╚██████╔╝██║
    ╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝     ╚═════╝ ╚═╝

    Lumina UI  —  iOS-Inspired Roblox Interface Library
    Version : 1.0.0
    Author  : Sirius (spiritual successor / revamp of Rayfield)

    ─────────────────────────────────────────────────────────
    QUICK-START
    ─────────────────────────────────────────────────────────
    local Lumina = loadstring(game:HttpGet("URL_TO_THIS_FILE"))()

    local Window = Lumina:CreateWindow({ Name = "My Hub", Theme = "Dark" })
    local Tab    = Window:CreateTab("Combat", "sword")
    Tab:CreateToggle({ Name = "God Mode", CurrentValue = false,
        Flag = "GodMode", Callback = function(v) end })
    Lumina:Notify({ Title = "Ready", Content = "Loaded!", Duration = 4 })

    ─────────────────────────────────────────────────────────
    FULL API
    ─────────────────────────────────────────────────────────
    Lumina:CreateWindow(Settings)           -> Window
    Lumina:Notify(Settings)
    Lumina:Destroy()
    Lumina:SetVisibility(bool)
    Lumina:IsVisible()                      -> bool
    Lumina.LoadConfiguration()

    Window:CreateTab(Name, Icon, Ext)       -> Tab
    Window.ModifyTheme(Theme)

    Tab:CreateSection(Name)                 -> SectionValue
    Tab:CreateDivider()                     -> DividerValue
    Tab:CreateLabel(Text, Icon, Color)      -> LabelValue
    Tab:CreateParagraph(Settings)           -> ParagraphValue
    Tab:CreateButton(Settings)              -> ButtonValue
    Tab:CreateToggle(Settings)              -> ToggleSettings  (.Set, .CurrentValue)
    Tab:CreateSlider(Settings)              -> SliderSettings  (.Set, .CurrentValue)
    Tab:CreateInput(Settings)               -> InputSettings   (.Set, .CurrentValue)
    Tab:CreateDropdown(Settings)            -> DropdownSettings(.Set, .Refresh, .CurrentOption)
    Tab:CreateKeybind(Settings)             -> KeybindSettings (.Set, .CurrentKeybind)
    Tab:CreateColorPicker(Settings)         -> ColorPickerSettings(.Set, .Color)
    ─────────────────────────────────────────────────────────
--]]

-- ============================================================
--  SERVICES
-- ============================================================
local function getService(n)
    local s = game:GetService(n)
    return if cloneref then cloneref(s) else s
end
local UIS   = getService("UserInputService")
local TweenService   = getService("TweenService")
local RunService   = getService("RunService")
local Players   = getService("Players")
local CoreGui   = getService("CoreGui")
local HttpService   = getService("HttpService")

-- ============================================================
--  SAFETY HELPERS
-- ============================================================
local function safeCall(fn, ...)
    if type(fn) ~= "function" then return false, nil end
    local ok, r = pcall(fn, ...)
    if not ok then warn("[Lumina] " .. tostring(r)) end
    return ok, r
end
local function ensureFolder(p)
    if isfolder and not isfolder(p) then safeCall(makefolder, p) end
end

-- ============================================================
--  ICON LOADER  (Lucide via Rayfield CDN, optional)
-- ============================================================
local Icons = nil
task.spawn(function()
    local ok, r = pcall(function()
        return loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua"
        ))()
    end)
    if ok then Icons = r end
end)

local function resolveIcon(icon)
    if not icon or icon == 0 then return "", nil, nil end
    if type(icon) == "number" then
        return "rbxassetid://" .. icon, nil, nil
    end
    if type(icon) == "string" then
        if icon:sub(1,3) == "rbx" then return icon, nil, nil end
        if Icons then
            local r = Icons["48px"] and Icons["48px"][icon:lower()]
            if r then
                return "rbxassetid://" .. r[1],
                       Vector2.new(r[3][1], r[3][2]),
                       Vector2.new(r[2][1], r[2][2])
            end
        end
        -- Fallback: treat as asset id string
        return "rbxassetid://" .. icon, nil, nil
    end
    return "", nil, nil
end

local function applyIcon(lbl, icon)
    if not lbl then return end
    local img, off, sz = resolveIcon(icon)
    lbl.Image = img
    if off then lbl.ImageRectOffset = off end
    if sz  then lbl.ImageRectSize   = sz  end
end

-- ============================================================
--  TWEEN HELPERS
-- ============================================================
local function tw(inst, info, props)
    local t = TweenService:Create(inst, info, props)
    t:Play(); return t
end
local T_FAST   = TweenInfo.new(0.14, Enum.EasingStyle.Quint,        Enum.EasingDirection.Out)
local T_MED    = TweenInfo.new(0.26, Enum.EasingStyle.Quint,        Enum.EasingDirection.Out)
local T_SLOW   = TweenInfo.new(0.42, Enum.EasingStyle.Exponential,  Enum.EasingDirection.Out)
local T_SPRING = TweenInfo.new(0.32, Enum.EasingStyle.Back,         Enum.EasingDirection.Out)

-- ============================================================
--  THEMES
-- ============================================================
local Themes = {
    Dark = {
        Background          = Color3.fromRGB(18,  18,  22),
        Topbar              = Color3.fromRGB(26,  26,  32),
        TextPrimary         = Color3.fromRGB(242, 242, 247),
        TextSecondary       = Color3.fromRGB(152, 152, 160),
        TextTertiary        = Color3.fromRGB(89,  89,  99),
        ElementBackground   = Color3.fromRGB(35,  35,  45),
        ElementHover        = Color3.fromRGB(46,  46,  58),
        ElementStroke       = Color3.fromRGB(255, 255, 255),
        SecondaryBackground = Color3.fromRGB(28,  28,  36),
        Accent              = Color3.fromRGB(10,  132, 255),
        ToggleOn            = Color3.fromRGB(48,  209, 88),
        ToggleOff           = Color3.fromRGB(90,  90,  96),
        SliderFill          = Color3.fromRGB(10,  132, 255),
        SliderTrack         = Color3.fromRGB(55,  55,  65),
        InputBackground     = Color3.fromRGB(28,  28,  36),
        TabActive           = Color3.fromRGB(10,  132, 255),
        TabInactive         = Color3.fromRGB(36,  36,  46),
        TabTextActive       = Color3.fromRGB(255, 255, 255),
        TabTextInactive     = Color3.fromRGB(110, 110, 122),
        NotifBackground     = Color3.fromRGB(36,  36,  46),
        SectionText         = Color3.fromRGB(80,  80,  92),
        Divider             = Color3.fromRGB(50,  50,  62),
        Shadow              = Color3.fromRGB(0,   0,   0),
    },
    Light = {
        Background          = Color3.fromRGB(242, 242, 247),
        Topbar              = Color3.fromRGB(255, 255, 255),
        TextPrimary         = Color3.fromRGB(14,  14,  18),
        TextSecondary       = Color3.fromRGB(99,  99,  102),
        TextTertiary        = Color3.fromRGB(142, 142, 147),
        ElementBackground   = Color3.fromRGB(255, 255, 255),
        ElementHover        = Color3.fromRGB(240, 240, 245),
        ElementStroke       = Color3.fromRGB(0,   0,   0),
        SecondaryBackground = Color3.fromRGB(235, 235, 240),
        Accent              = Color3.fromRGB(0,   122, 255),
        ToggleOn            = Color3.fromRGB(52,  199, 89),
        ToggleOff           = Color3.fromRGB(174, 174, 178),
        SliderFill          = Color3.fromRGB(0,   122, 255),
        SliderTrack         = Color3.fromRGB(209, 209, 214),
        InputBackground     = Color3.fromRGB(242, 242, 247),
        TabActive           = Color3.fromRGB(0,   122, 255),
        TabInactive         = Color3.fromRGB(229, 229, 234),
        TabTextActive       = Color3.fromRGB(255, 255, 255),
        TabTextInactive     = Color3.fromRGB(99,  99,  102),
        NotifBackground     = Color3.fromRGB(255, 255, 255),
        SectionText         = Color3.fromRGB(142, 142, 147),
        Divider             = Color3.fromRGB(209, 209, 214),
        Shadow              = Color3.fromRGB(180, 180, 190),
    },
    Ocean = {
        Background          = Color3.fromRGB(10,  20,  35),
        Topbar              = Color3.fromRGB(14,  28,  46),
        TextPrimary         = Color3.fromRGB(220, 240, 255),
        TextSecondary       = Color3.fromRGB(110, 160, 200),
        TextTertiary        = Color3.fromRGB(60,  100, 140),
        ElementBackground   = Color3.fromRGB(18,  36,  58),
        ElementHover        = Color3.fromRGB(24,  46,  72),
        ElementStroke       = Color3.fromRGB(0,   130, 180),
        SecondaryBackground = Color3.fromRGB(14,  28,  46),
        Accent              = Color3.fromRGB(0,   180, 220),
        ToggleOn            = Color3.fromRGB(0,   200, 180),
        ToggleOff           = Color3.fromRGB(40,  70,  100),
        SliderFill          = Color3.fromRGB(0,   160, 210),
        SliderTrack         = Color3.fromRGB(20,  50,  80),
        InputBackground     = Color3.fromRGB(14,  28,  46),
        TabActive           = Color3.fromRGB(0,   170, 210),
        TabInactive         = Color3.fromRGB(18,  38,  60),
        TabTextActive       = Color3.fromRGB(255, 255, 255),
        TabTextInactive     = Color3.fromRGB(80,  130, 170),
        NotifBackground     = Color3.fromRGB(18,  36,  58),
        SectionText         = Color3.fromRGB(60,  110, 150),
        Divider             = Color3.fromRGB(20,  55,  85),
        Shadow              = Color3.fromRGB(0,   5,   15),
    },
    Amethyst = {
        Background          = Color3.fromRGB(20,  14,  32),
        Topbar              = Color3.fromRGB(28,  20,  44),
        TextPrimary         = Color3.fromRGB(240, 230, 255),
        TextSecondary       = Color3.fromRGB(160, 130, 200),
        TextTertiary        = Color3.fromRGB(100, 75,  140),
        ElementBackground   = Color3.fromRGB(36,  26,  56),
        ElementHover        = Color3.fromRGB(46,  34,  70),
        ElementStroke       = Color3.fromRGB(130, 60,  220),
        SecondaryBackground = Color3.fromRGB(28,  20,  44),
        Accent              = Color3.fromRGB(159, 90,  253),
        ToggleOn            = Color3.fromRGB(175, 82,  222),
        ToggleOff           = Color3.fromRGB(80,  50,  110),
        SliderFill          = Color3.fromRGB(150, 80,  240),
        SliderTrack         = Color3.fromRGB(50,  34,  80),
        InputBackground     = Color3.fromRGB(28,  20,  44),
        TabActive           = Color3.fromRGB(159, 90,  253),
        TabInactive         = Color3.fromRGB(36,  26,  56),
        TabTextActive       = Color3.fromRGB(255, 255, 255),
        TabTextInactive     = Color3.fromRGB(120, 90,  160),
        NotifBackground     = Color3.fromRGB(36,  26,  56),
        SectionText         = Color3.fromRGB(100, 70,  140),
        Divider             = Color3.fromRGB(55,  38,  85),
        Shadow              = Color3.fromRGB(8,   4,   16),
    },
    AmberGlow = {
        Background          = Color3.fromRGB(38,  26,  16),
        Topbar              = Color3.fromRGB(50,  34,  20),
        TextPrimary         = Color3.fromRGB(255, 245, 230),
        TextSecondary       = Color3.fromRGB(190, 150, 110),
        TextTertiary        = Color3.fromRGB(120, 90,  60),
        ElementBackground   = Color3.fromRGB(55,  40,  26),
        ElementHover        = Color3.fromRGB(66,  50,  34),
        ElementStroke       = Color3.fromRGB(200, 130, 60),
        SecondaryBackground = Color3.fromRGB(46,  32,  18),
        Accent              = Color3.fromRGB(255, 159, 10),
        ToggleOn            = Color3.fromRGB(255, 180, 50),
        ToggleOff           = Color3.fromRGB(110, 80,  40),
        SliderFill          = Color3.fromRGB(255, 159, 10),
        SliderTrack         = Color3.fromRGB(90,  60,  30),
        InputBackground     = Color3.fromRGB(46,  32,  18),
        TabActive           = Color3.fromRGB(255, 159, 10),
        TabInactive         = Color3.fromRGB(55,  40,  26),
        TabTextActive       = Color3.fromRGB(30,  20,  10),
        TabTextInactive     = Color3.fromRGB(150, 110, 70),
        NotifBackground     = Color3.fromRGB(55,  40,  26),
        SectionText         = Color3.fromRGB(130, 95,  55),
        Divider             = Color3.fromRGB(90,  65,  38),
        Shadow              = Color3.fromRGB(10,  6,   2),
    },
}

-- ============================================================
--  LIBRARY STATE
-- ============================================================
local LuminaLibrary = { Flags = {}, Theme = Themes }

local GuiRoot      = nil
local Theme        = Themes.Dark   -- active theme (alias)
local Hidden       = false
local Minimised    = false
local Debounce     = false
local globalLoaded = false

local RayfieldFolder      = "Lumina"
local ConfigurationFolder = RayfieldFolder .. "/Configurations"
local ConfigExt           = ".lumina"
local CEnabled            = false
local CFileName           = nil

local keybindConnections  = {}

-- ============================================================
--  CONFIGURATION
-- ============================================================
local function packColor(c)   return {R=c.R*255, G=c.G*255, B=c.B*255} end
local function unpackColor(t) return Color3.fromRGB(t.R, t.G, t.B)     end

local function SaveConfiguration()
    if not CEnabled or not globalLoaded then return end
    local data = {}
    for flag, el in pairs(LuminaLibrary.Flags) do
        if el.Type == "ColorPicker" then
            data[flag] = packColor(el.Color)
        elseif typeof(el.CurrentValue) == "boolean" then
            data[flag] = el.CurrentValue
        else
            data[flag] = el.CurrentValue or el.CurrentKeybind or el.CurrentOption or el.Color
        end
    end
    local ok, enc = pcall(HttpService.JSONEncode, HttpService, data)
    if ok then safeCall(writefile, ConfigurationFolder.."/"..CFileName..ConfigExt, enc) end
end

local function DoLoadConfiguration()
    if not CEnabled then globalLoaded = true return end
    local path = ConfigurationFolder.."/"..CFileName..ConfigExt
    if not (isfile and isfile(path)) then globalLoaded = true return end
    local raw = readfile(path)
    local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok or not data then globalLoaded = true return end
    local changed = false
    for flag, el in pairs(LuminaLibrary.Flags) do
        local val = data[flag]
        if val ~= nil then
            changed = true
            task.spawn(function()
                if el.Type == "ColorPicker" then el:Set(unpackColor(val))
                else el:Set(val) end
            end)
        end
    end
    globalLoaded = true
    if changed then
        LuminaLibrary:Notify({Title="Config Loaded", Content="Your saved configuration was applied.", Duration=4})
    end
end

-- ============================================================
--  GUI HELPERS
-- ============================================================
local function New(class, props, children)
    local i = Instance.new(class)
    for k,v in pairs(props or {}) do
        if k ~= "Parent" then i[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = i end
    if props and props.Parent then i.Parent = props.Parent end
    return i
end

local function corner(r)  return New("UICorner",  {CornerRadius = UDim.new(0,r)}) end
local function stroke(col,th,tr)
    return New("UIStroke", {Color=col, Thickness=th or 1, Transparency=tr or 0})
end
local function pad(t,b,l,r)
    return New("UIPadding",{
        PaddingTop=UDim.new(0,t or 0), PaddingBottom=UDim.new(0,b or 0),
        PaddingLeft=UDim.new(0,l or 0), PaddingRight=UDim.new(0,r or 0),
    })
end
local function list(dir, spacing, ha, va)
    return New("UIListLayout",{
        FillDirection=dir or Enum.FillDirection.Vertical,
        Padding=UDim.new(0,spacing or 0),
        HorizontalAlignment=ha or Enum.HorizontalAlignment.Left,
        VerticalAlignment=va or Enum.VerticalAlignment.Top,
        SortOrder=Enum.SortOrder.LayoutOrder,
    })
end

local function mkLabel(text, size, color, font, parent)
    local l = New("TextLabel",{
        Text=text, TextSize=size, TextColor3=color,
        Font=font or Enum.Font.GothamMedium,
        BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Parent=parent,
    })
    return l
end

-- ============================================================
--  DRAGGING
-- ============================================================
local function makeDraggable(frame, handle)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=frame.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end

-- ============================================================
--  NOTIFICATIONS
-- ============================================================
function LuminaLibrary:Notify(data)
    task.spawn(function()
        if not GuiRoot then return end
        local holder = GuiRoot:FindFirstChild("Notifications")
        if not holder then return end

        local notif = New("Frame",{
            Size=UDim2.new(1,-10,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundColor3=Theme.NotifBackground, BackgroundTransparency=0.08,
            ClipsDescendants=true, Parent=holder,
        },{corner(16), stroke(Theme.ElementStroke,1,0.86)})

        local inner = New("Frame",{
            Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Parent=notif,
        },{pad(12,12,14,14), list(Enum.FillDirection.Horizontal,12)})

        local iconBg = New("Frame",{
            Size=UDim2.new(0,36,0,36),
            BackgroundColor3=Theme.Accent, Parent=inner,
        },{corner(10)})
        local iconImg = New("ImageLabel",{
            Size=UDim2.new(0,18,0,18), AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.new(0.5,0,0.5,0), BackgroundTransparency=1, Parent=iconBg,
        })
        if data.Image then applyIcon(iconImg, data.Image) end

        local col = New("Frame",{
            Size=UDim2.new(1,-48,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Parent=inner,
        },{list(Enum.FillDirection.Vertical,3)})

        local tl = mkLabel(data.Title or "Notification", 13, Theme.TextPrimary, Enum.Font.GothamBold, col)
        tl.Size = UDim2.new(1,0,0,18); tl.TextTruncate=Enum.TextTruncate.AtEnd

        local cl = New("TextLabel",{
            Text=data.Content or "", TextSize=12, Font=Enum.Font.Gotham,
            TextColor3=Theme.TextSecondary, BackgroundTransparency=1,
            TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
            Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, Parent=col,
        })

        -- Progress bar
        local prog = New("Frame",{
            Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2),
            BackgroundColor3=Theme.Accent, ZIndex=5, Parent=notif,
        },{corner(1)})

        -- Animate in (transparent → visible)
        notif.BackgroundTransparency=1; tl.TextTransparency=1; cl.TextTransparency=1
        tw(notif,T_MED,{BackgroundTransparency=0.08})
        tw(tl,T_MED,{TextTransparency=0}); tw(cl,T_MED,{TextTransparency=0})

        local dur = data.Duration or math.clamp(#(data.Content or "")*0.05+2.5, 3, 10)
        tw(prog, TweenInfo.new(dur,Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,0,2)})

        task.wait(dur)

        tw(notif,T_MED,{BackgroundTransparency=1})
        tw(tl,T_FAST,{TextTransparency=1}); tw(cl,T_FAST,{TextTransparency=1})
        task.wait(0.3); notif:Destroy()
    end)
end

-- ============================================================
--  CREATE WINDOW
-- ============================================================
function LuminaLibrary:CreateWindow(S)
    S = S or {}

    -- Theme
    if S.Theme then
        if type(S.Theme)=="string" and Themes[S.Theme] then Theme=Themes[S.Theme]
        elseif type(S.Theme)=="table" then Theme=S.Theme end
    end

    -- Config
    CEnabled  = S.ConfigurationSaving and S.ConfigurationSaving.Enabled or false
    CFileName = (S.ConfigurationSaving and S.ConfigurationSaving.FileName) or tostring(game.PlaceId)
    if S.ConfigurationSaving and S.ConfigurationSaving.FolderName then
        ConfigurationFolder = S.ConfigurationSaving.FolderName
    end
    if CEnabled then ensureFolder(RayfieldFolder); ensureFolder(ConfigurationFolder) end

    -- ── Root ScreenGui ────────────────────────────────
    local gui = New("ScreenGui",{
        Name="LuminaUI", DisplayOrder=200, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, ResetOnSpawn=false,
    })
    GuiRoot = gui

    if gethui then gui.Parent=gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(gui); gui.Parent=CoreGui
    elseif CoreGui:FindFirstChild("RobloxGui") then gui.Parent=CoreGui.RobloxGui
    else gui.Parent=CoreGui end

    -- Remove stale copies
    for _,old in ipairs((gethui or function()return CoreGui end)():GetChildren()) do
        if old.Name=="LuminaUI" and old~=gui then old:Destroy() end
    end

    -- ── Notification holder ───────────────────────────
    New("Frame",{
        Name="Notifications", AnchorPoint=Vector2.new(1,1),
        Position=UDim2.new(1,-18,1,-18), Size=UDim2.new(0,310,0,0),
        BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y, Parent=gui,
    },{list(Enum.FillDirection.Vertical,8,Enum.HorizontalAlignment.Right,Enum.VerticalAlignment.Bottom)})

    -- ── Main window frame ─────────────────────────────
    local WIN_W, WIN_H = 524, 484
    local main = New("Frame",{
        Name="Main", AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(0,WIN_W,0,WIN_H),
        BackgroundColor3=Theme.Background, BackgroundTransparency=1, Parent=gui,
    },{corner(22), stroke(Theme.ElementStroke,1,0.88)})

    -- Drop shadow (ImageLabel trick)
    New("ImageLabel",{
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,8),
        Size=UDim2.new(1,50,1,50), BackgroundTransparency=1,
        ImageColor3=Theme.Shadow, ImageTransparency=0.5, ZIndex=-1,
        Image="rbxassetid://5554236805",
        ScaleType=Enum.ScaleType.Slice, SliceCenter=Rect.new(10,10,118,118),
        Parent=main,
    })

    -- ── Topbar ────────────────────────────────────────
    local topbar = New("Frame",{
        Name="Topbar", Size=UDim2.new(1,0,0,52),
        BackgroundColor3=Theme.Topbar, Parent=main,
    },{corner(22)})
    -- Repair bottom-corners of topbar
    New("Frame",{
        Size=UDim2.new(1,0,0,22), Position=UDim2.new(0,0,1,-22),
        BackgroundColor3=Theme.Topbar, ZIndex=2, Parent=topbar,
    })
    New("Frame",{
        Name="Divider", Position=UDim2.new(0,0,1,-1), Size=UDim2.new(1,0,0,1),
        BackgroundColor3=Theme.Divider, ZIndex=3, Parent=topbar,
    })
    stroke(Theme.ElementStroke,1,0.90).Parent = topbar

    -- App icon
    local appIcon = New("ImageLabel",{
        Size=UDim2.new(0,28,0,28), Position=UDim2.new(0,14,0.5,0),
        AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=Theme.Accent,
        ScaleType=Enum.ScaleType.Fit, ZIndex=3, Parent=topbar,
    },{corner(8)})
    if S.Icon then applyIcon(appIcon, S.Icon) end

    local titleLbl = mkLabel(S.Name or "Lumina UI", 14, Theme.TextPrimary, Enum.Font.GothamBold, topbar)
    titleLbl.Size = UDim2.new(1,-120,1,0)
    titleLbl.Position = UDim2.new(0, S.Icon and 52 or 16, 0,0)
    titleLbl.ZIndex = 3

    -- Right-side action buttons
    local btnRow = New("Frame",{
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
        Size=UDim2.new(0,92,0,30), BackgroundTransparency=1, ZIndex=5, Parent=topbar,
    },{list(Enum.FillDirection.Horizontal,4,Enum.HorizontalAlignment.Right,Enum.VerticalAlignment.Center)})

    local function mkTopBtn(iconName, tintOverride)
        local b = New("ImageButton",{
            Size=UDim2.new(0,28,0,28), BackgroundTransparency=1,
            ImageColor3=tintOverride or Theme.TextSecondary, ZIndex=5, Parent=btnRow,
        },{corner(7)})
        applyIcon(b, iconName)
        b.MouseEnter:Connect(function() tw(b,T_FAST,{BackgroundTransparency=0.82}) end)
        b.MouseLeave:Connect(function() tw(b,T_FAST,{BackgroundTransparency=1})    end)
        return b
    end

    local btnHide  = mkTopBtn("x")
    local btnMin   = mkTopBtn("minus")
    local btnSearch= mkTopBtn("search")

    -- ── Search bar ────────────────────────────────────
    local searchOpen = false
    local searchBar = New("Frame",{
        Position=UDim2.new(0,10,0,52), Size=UDim2.new(1,-20,0,0),
        BackgroundColor3=Theme.InputBackground, ClipsDescendants=true,
        Visible=false, Parent=main,
    },{corner(12), stroke(Theme.ElementStroke,1,0.85)})

    local searchIco = New("ImageLabel",{
        Size=UDim2.new(0,14,0,14), Position=UDim2.new(0,10,0.5,0),
        AnchorPoint=Vector2.new(0,0.5), BackgroundTransparency=1,
        ImageColor3=Theme.TextTertiary, Parent=searchBar,
    })
    applyIcon(searchIco, "search")

    local searchBox = New("TextBox",{
        Position=UDim2.new(0,32,0,0), Size=UDim2.new(1,-42,1,0),
        BackgroundTransparency=1, Text="", PlaceholderText="Search elements...",
        TextColor3=Theme.TextPrimary, PlaceholderColor3=Theme.TextTertiary,
        TextSize=13, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=false, Parent=searchBar,
    })

    local function openSearch()
        searchOpen=true; searchBar.Visible=true
        tw(searchBar, T_MED, {Size=UDim2.new(1,-20,0,38)})
        task.wait(0.1); searchBox:CaptureFocus()
    end
    local function closeSearch()
        searchOpen=false
        tw(searchBar,T_FAST,{Size=UDim2.new(1,-20,0,0)})
        task.wait(0.18); searchBar.Visible=false; searchBox.Text=""
    end
    btnSearch.MouseButton1Click:Connect(function()
        if searchOpen then closeSearch() else openSearch() end
    end)

    -- ── Tab list ──────────────────────────────────────
    local tabScroll = New("ScrollingFrame",{
        Name="TabList", Position=UDim2.new(0,0,0,52), Size=UDim2.new(1,0,0,40),
        BackgroundTransparency=1, ScrollBarThickness=0,
        ScrollingDirection=Enum.ScrollingDirection.X,
        AutomaticCanvasSize=Enum.AutomaticSize.X, CanvasSize=UDim2.new(0,0,0,0),
        Parent=main,
    },{pad(5,5,10,10), list(Enum.FillDirection.Horizontal,6)})

    -- ── Element area ──────────────────────────────────
    local elemArea = New("Frame",{
        Name="ElementArea", Position=UDim2.new(0,0,0,96),
        Size=UDim2.new(1,0,1,-100), BackgroundTransparency=1,
        ClipsDescendants=true, Parent=main,
    })

    -- Drag nub
    New("Frame",{
        AnchorPoint=Vector2.new(0.5,1), Position=UDim2.new(0.5,0,1,-4),
        Size=UDim2.new(0,44,0,4), BackgroundColor3=Theme.Divider,
        ZIndex=10, Parent=main,
    },{corner(2)})

    -- ── Loading screen ────────────────────────────────
    local loadingScreen = New("Frame",{
        Size=UDim2.new(1,0,1,0), BackgroundColor3=Theme.Background, ZIndex=50, Parent=main,
    },{corner(22)})

    local loadContent = New("Frame",{
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
        Size=UDim2.new(0,240,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, Parent=loadingScreen,
    },{list(Enum.FillDirection.Vertical,12, Enum.HorizontalAlignment.Center)})

    New("Frame",{Size=UDim2.new(0,64,0,64),BackgroundColor3=Theme.Accent,Parent=loadContent},{corner(18)})
    local ldTitle = mkLabel(S.LoadingTitle or "Lumina UI", 20, Theme.TextPrimary, Enum.Font.GothamBold, loadContent)
    ldTitle.Size=UDim2.new(1,0,0,28); ldTitle.TextXAlignment=Enum.TextXAlignment.Center
    local ldSub = mkLabel(S.LoadingSubtitle or "Interface Suite", 13, Theme.TextSecondary, Enum.Font.Gotham, loadContent)
    ldSub.Size=UDim2.new(1,0,0,20); ldSub.TextXAlignment=Enum.TextXAlignment.Center

    -- ── Key system ────────────────────────────────────
    if S.KeySystem and S.KeySettings then
        local ks = S.KeySettings
        ensureFolder(RayfieldFolder.."/Keys")
        local keyFile = RayfieldFolder.."/Keys/"..(ks.FileName or "key")..ConfigExt
        local keys = type(ks.Key)=="string" and {ks.Key} or (ks.Key or {})

        local savedKey = isfile and isfile(keyFile) and readfile(keyFile) or nil
        local pass = false
        if savedKey then
            for _,k in ipairs(keys) do if savedKey==k then pass=true break end end
        end

        if not pass then
            local ks_screen = New("Frame",{
                Size=UDim2.new(1,0,1,0), BackgroundColor3=Theme.Background, ZIndex=60, Parent=main,
            },{corner(22)})
            local ksBody = New("Frame",{
                AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
                Size=UDim2.new(0,320,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1, Parent=ks_screen,
            },{list(Enum.FillDirection.Vertical,14,Enum.HorizontalAlignment.Center)})

            New("Frame",{Size=UDim2.new(0,60,0,60), BackgroundColor3=Color3.fromRGB(255,159,10),Parent=ksBody},{corner(16)})
            local kt=mkLabel(ks.Title or "Key Required",18,Theme.TextPrimary,Enum.Font.GothamBold,ksBody)
            kt.Size=UDim2.new(1,0,0,26); kt.TextXAlignment=Enum.TextXAlignment.Center
            local kn=New("TextLabel",{Text=ks.Note or "Enter key to continue.",TextSize=12,Font=Enum.Font.Gotham,
                TextColor3=Theme.TextSecondary,BackgroundTransparency=1,TextWrapped=true,
                Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
                TextXAlignment=Enum.TextXAlignment.Center,Parent=ksBody})

            local kif=New("Frame",{Size=UDim2.new(1,0,0,42),BackgroundColor3=Theme.InputBackground,Parent=ksBody},
                {corner(12),stroke(Theme.ElementStroke,1,0.84),pad(0,0,10,10)})
            local kbox=New("TextBox",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",
                PlaceholderText="Enter key...", TextColor3=Theme.TextPrimary,
                PlaceholderColor3=Theme.TextTertiary, TextSize=14, Font=Enum.Font.Code,
                TextXAlignment=Enum.TextXAlignment.Center, Parent=kif})
            local kerr=mkLabel("",12,Color3.fromRGB(255,69,58),Enum.Font.Gotham,ksBody)
            kerr.Size=UDim2.new(1,0,0,16); kerr.TextXAlignment=Enum.TextXAlignment.Center

            kbox.FocusLost:Connect(function()
                if #kbox.Text==0 then return end
                local found=false
                for _,k in ipairs(keys) do if kbox.Text==k then found=true;pass=true break end end
                if found then
                    if ks.SaveKey then safeCall(writefile,keyFile,kbox.Text) end
                    tw(ks_screen,T_MED,{BackgroundTransparency=1})
                    task.wait(0.3); ks_screen:Destroy()
                    LuminaLibrary:Notify({Title="Access Granted",Content="Key verified.",Duration=4})
                else
                    kerr.Text="Invalid key — try again."
                    kbox.Text=""
                    task.wait(2.5); kerr.Text=""
                end
            end)
            repeat task.wait() until pass
        end
    end

    -- ── Animate window in ─────────────────────────────
    main.Visible = true
    tw(main, T_SLOW, {BackgroundTransparency=0})
    task.wait(1.5)
    tw(loadingScreen, T_MED, {BackgroundTransparency=1})
    task.wait(0.28); loadingScreen.Visible=false

    -- ── Dragging ──────────────────────────────────────
    makeDraggable(main, topbar)

    -- ── Hide / Unhide helpers ─────────────────────────
    -- FIX: Instead of tweening every child (which caused 1-2s lag on sliders/toggles),
    --      we simply hide the whole frame instantly and tween only the main container.
    local function doHide(notify)
        if Debounce then return end; Debounce=true; Hidden=true
        tw(main, T_MED, {BackgroundTransparency=1, Size=UDim2.new(0,WIN_W,0,0)})
        task.wait(0.28); main.Visible=false; Debounce=false
        if notify then
            LuminaLibrary:Notify({
                Title="Interface Hidden",
                Content="Press "..(S.ToggleUIKeybind or "K").." to show again.",
                Duration=5,
            })
        end
    end

    local function doUnhide()
        if Debounce then return end; Debounce=true; Hidden=false
        main.Visible=true; main.Size=UDim2.new(0,WIN_W,0,0)
        tw(main, T_SLOW, {BackgroundTransparency=0, Size=UDim2.new(0,WIN_W,0,WIN_H)})
        task.wait(0.42); Debounce=false
    end

    local function doMin()
        Minimised=true
        elemArea.Visible=false; tabScroll.Visible=false
        tw(main, T_MED, {Size=UDim2.new(0,WIN_W,0,54)})
    end
    local function doMax()
        Minimised=false
        tw(main, T_MED, {Size=UDim2.new(0,WIN_W,0,WIN_H)})
        task.wait(0.14); tabScroll.Visible=true; elemArea.Visible=true
    end

    btnHide.MouseButton1Click:Connect(function() doHide(true) end)
    btnMin.MouseButton1Click:Connect(function()
        if Minimised then doMax() else doMin() end
    end)

    local keybindKey = tostring(S.ToggleUIKeybind or "K"):upper()
    local hideConn = UIS.InputBegan:Connect(function(inp, proc)
        if proc then return end
        local kn = tostring(inp.KeyCode):split(".")[3] or ""
        if kn:upper() == keybindKey then
            if Hidden then doUnhide() else doHide(false) end
        end
    end)
    table.insert(keybindConnections, hideConn)

    -- ── Search filter ─────────────────────────────────
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = searchBox.Text:lower()
        -- Find current visible page
        for _, page in ipairs(elemArea:GetChildren()) do
            if page:IsA("ScrollingFrame") and page.Visible then
                for _, el in ipairs(page:GetChildren()) do
                    if el:IsA("Frame") then
                        if el.Name=="Section" or el.Name=="Divider" then
                            el.Visible = (q=="")
                        else
                            el.Visible = (q=="") or el.Name:lower():find(q,1,true)~=nil
                        end
                    end
                end
            end
        end
    end)

    -- ============================================================
    --  WINDOW OBJECT
    -- ============================================================
    local Window = {}
    local tabPages    = {}   -- [name] = { btn, page }
    local activeTab   = nil

    function Window.ModifyTheme(newTheme)
        if type(newTheme)=="string" and Themes[newTheme] then Theme=Themes[newTheme]
        elseif type(newTheme)=="table" then Theme=newTheme end
        main.BackgroundColor3   = Theme.Background
        topbar.BackgroundColor3 = Theme.Topbar
        LuminaLibrary:Notify({Title="Theme Changed",Content="Theme updated successfully.",Duration=3})
    end

    local function switchToTab(name)
        if activeTab==name then return end
        activeTab = name
        for n, data in pairs(tabPages) do
            local active = (n==name)
            -- FIX: use Visible instead of transparency so content never "disappears"
            data.page.Visible = active
            tw(data.btn, T_FAST, {BackgroundColor3 = active and Theme.TabActive or Theme.TabInactive})
            local tc = active and Theme.TabTextActive or Theme.TabTextInactive
            if data.btn:FindFirstChild("TitleLbl") then
                data.btn.TitleLbl.TextColor3 = tc
            end
            for _, ico in ipairs(data.btn:GetChildren()) do
                if ico:IsA("ImageLabel") then ico.ImageColor3 = tc end
            end
        end
    end

    -- ──────────────────────────────────────────────────────
    function Window:CreateTab(Name, Image, Ext)
        -- Measure text for auto-width
        local measureGui = New("ScreenGui",{Parent=game:GetService("CoreGui"),Name="_LuminaMeasure"})
        local measureLbl = New("TextLabel",{
            Text=Name, TextSize=12, Font=Enum.Font.GothamMedium,
            Size=UDim2.new(0,400,0,30), BackgroundTransparency=1, Parent=measureGui,
        })
        local textW = measureLbl.TextBounds.X
        measureGui:Destroy()

        local hasIcon = Image and Image~=0
        local btnW = textW + (hasIcon and 42 or 22)

        local tabBtn = New("Frame",{
            Name=Name, Size=UDim2.new(0,btnW,1,-4),
            BackgroundColor3=Theme.TabInactive, Parent=tabScroll,
        },{corner(100), stroke(Theme.ElementStroke,1,0.90)})

        local inner = New("Frame",{
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Parent=tabBtn,
        },{list(Enum.FillDirection.Horizontal,5,Enum.HorizontalAlignment.Center,Enum.VerticalAlignment.Center)})

        if hasIcon then
            local ico=New("ImageLabel",{
                Size=UDim2.new(0,14,0,14), BackgroundTransparency=1,
                ImageColor3=Theme.TabTextInactive, Parent=inner,
            })
            applyIcon(ico, Image)
        end

        local titleLbl2 = mkLabel(Name, 12, Theme.TabTextInactive, Enum.Font.GothamMedium, inner)
        titleLbl2.Name  = "TitleLbl"
        titleLbl2.Size  = UDim2.new(0,textW,1,0)
        titleLbl2.TextXAlignment = Enum.TextXAlignment.Center

        New("TextButton",{
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=5, Parent=tabBtn,
        }).MouseButton1Click:Connect(function() switchToTab(Name) end)

        -- Tab page (ScrollingFrame)
        local tabPage = New("ScrollingFrame",{
            Name=Name, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            ScrollBarThickness=3, ScrollBarImageColor3=Theme.Divider,
            CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
            Visible=false, Parent=elemArea,
        },{pad(8,14,10,10), list(Enum.FillDirection.Vertical,6)})

        tabPages[Name] = {btn=tabBtn, page=tabPage}
        if not activeTab and not Ext then switchToTab(Name) end

        -- Auto-refresh canvas
        local function rc()
            local ll = tabPage:FindFirstChildWhichIsA("UIListLayout")
            if ll then tabPage.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+20) end
        end

        -- ────────────────────────────────────────────────
        --  TAB API
        -- ────────────────────────────────────────────────
        local Tab = {}

        -- BASE CARD helper
        local function card(name, h, autoY)
            local f = New("Frame",{
                Name=name or "Element", LayoutOrder=#tabPage:GetChildren(),
                Size=autoY and UDim2.new(1,0,0,0) or UDim2.new(1,0,0,h or 50),
                AutomaticSize=autoY and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
                BackgroundColor3=Theme.ElementBackground, Parent=tabPage,
            },{corner(14), stroke(Theme.ElementStroke,1,0.88), pad(0,0,14,14)})
            f.MouseEnter:Connect(function() tw(f,T_FAST,{BackgroundColor3=Theme.ElementHover}) end)
            f.MouseLeave:Connect(function() tw(f,T_FAST,{BackgroundColor3=Theme.ElementBackground}) end)
            rc()
            return f
        end

        -- ROW helper
        local function row(parent, spacing)
            local r=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Parent=parent},
                {list(Enum.FillDirection.Horizontal,spacing or 10,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)})
            return r
        end

        -- TEXT COL helper
        local function textCol(parent, wOffset, name, desc)
            local col=New("Frame",{
                Size=UDim2.new(1,wOffset or 0,1,0), BackgroundTransparency=1,Parent=parent,
            },{list(Enum.FillDirection.Vertical,2,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)})
            local nl=mkLabel(name,14,Theme.TextPrimary,Enum.Font.GothamMedium,col); nl.Size=UDim2.new(1,0,0,18)
            if desc then
                local dl=mkLabel(desc,11,Theme.TextTertiary,Enum.Font.Gotham,col); dl.Size=UDim2.new(1,0,0,14)
            end
            return col
        end

        -- INTERACT OVERLAY
        local function interact(parent, zIndex)
            return New("TextButton",{
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="",
                ZIndex=zIndex or 5, Parent=parent,
            })
        end

        -- ── Section ──────────────────────────────────
        function Tab:CreateSection(n)
            local f=New("Frame",{Name="Section",Size=UDim2.new(1,0,0,24),
                BackgroundTransparency=1,LayoutOrder=#tabPage:GetChildren(),Parent=tabPage})
            local l=mkLabel(n:upper(),11,Theme.SectionText,Enum.Font.GothamBold,f)
            l.Size=UDim2.new(1,0,1,0)
            rc()
            return {Set=function(_,t) l.Text=t:upper() end}
        end

        -- ── Divider ───────────────────────────────────
        function Tab:CreateDivider()
            local f=New("Frame",{Name="Divider",Size=UDim2.new(1,0,0,10),
                BackgroundTransparency=1,LayoutOrder=#tabPage:GetChildren(),Parent=tabPage})
            New("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),
                Size=UDim2.new(1,0,0,1),BackgroundColor3=Theme.Divider,Parent=f},{corner(1)})
            rc()
            return {Set=function(_,v) f.Visible=v end}
        end

        -- ── Label ─────────────────────────────────────
        function Tab:CreateLabel(text, icon, color)
            local bg = color or Theme.Accent
            local f=New("Frame",{Name=text or "Label", LayoutOrder=#tabPage:GetChildren(),
                Size=UDim2.new(1,0,0,40), BackgroundColor3=bg, BackgroundTransparency=0.86,
                Parent=tabPage,
            },{corner(14),stroke(bg,1,0.76),pad(0,0,14,14),
               list(Enum.FillDirection.Horizontal,10,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)})
            if icon then
                local i=New("ImageLabel",{Size=UDim2.new(0,16,0,16),BackgroundTransparency=1,ImageColor3=bg,Parent=f})
                applyIcon(i,icon)
            end
            local l=mkLabel(text,12,Theme.TextSecondary,Enum.Font.Gotham,f)
            l.Size=UDim2.new(1,-30,1,0); l.TextWrapped=true
            rc()
            return {Set=function(_,t) l.Text=t end}
        end

        -- ── Paragraph ─────────────────────────────────
        function Tab:CreateParagraph(ps)
            local f=New("Frame",{Name=ps.Title or "Paragraph",LayoutOrder=#tabPage:GetChildren(),
                Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundColor3=Theme.SecondaryBackground or Theme.ElementBackground,Parent=tabPage,
            },{corner(14),stroke(Theme.ElementStroke,1,0.88),pad(12,12,14,14),
               list(Enum.FillDirection.Vertical,4)})
            local tl=mkLabel(ps.Title,13,Theme.TextPrimary,Enum.Font.GothamBold,f); tl.Size=UDim2.new(1,0,0,18)
            local cl=New("TextLabel",{Text=ps.Content,TextSize=12,Font=Enum.Font.Gotham,
                TextColor3=Theme.TextSecondary,BackgroundTransparency=1,
                TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,
                Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,Parent=f})
            rc()
            return {Set=function(_,s) tl.Text=s.Title; cl.Text=s.Content end}
        end

        -- ── Button ────────────────────────────────────
        function Tab:CreateButton(bs)
            local f=card(bs.Name,50)
            local r=row(f)
            textCol(r,-38,bs.Name,bs.Description)
            local chev=New("ImageLabel",{Size=UDim2.new(0,14,0,14),BackgroundTransparency=1,
                ImageColor3=Theme.TextTertiary,Parent=r})
            applyIcon(chev,"chevron-right")
            interact(f).MouseButton1Click:Connect(function()
                tw(f,T_FAST,{BackgroundColor3=Theme.Accent})
                task.wait(0.07); tw(f,T_MED,{BackgroundColor3=Theme.ElementBackground})
                local ok,err=pcall(bs.Callback)
                if not ok then warn("[Lumina] Button '"..bs.Name.."': "..tostring(err)) end
                if not bs.Ext then SaveConfiguration() end
            end)
            return {Set=function(_,n) f.Name=n end}
        end

        -- ── Toggle ────────────────────────────────────
        function Tab:CreateToggle(ts)
            ts.Type="Toggle"
            local f=card(ts.Name,50)
            local r=row(f)
            textCol(r,-62,ts.Name,ts.Description)

            local track=New("Frame",{Size=UDim2.new(0,48,0,28),
                BackgroundColor3=ts.CurrentValue and Theme.ToggleOn or Theme.ToggleOff,
                Parent=r},{corner(14)})
            local thumb=New("Frame",{Size=UDim2.new(0,22,0,22),
                Position=ts.CurrentValue and UDim2.new(0,24,0.5,0) or UDim2.new(0,4,0.5,0),
                AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=Color3.new(1,1,1),
                ZIndex=3,Parent=track},{corner(11)})

            -- FIX: single function, no competing tween chains, immediate state sync
            local function setVal(val, fire)
                ts.CurrentValue = val
                -- Immediately cancel any in-progress tweens by starting new ones
                tw(track, T_FAST,   {BackgroundColor3 = val and Theme.ToggleOn or Theme.ToggleOff})
                tw(thumb, T_SPRING, {Position = val and UDim2.new(0,24,0.5,0) or UDim2.new(0,4,0.5,0)})
                if fire and ts.Callback then
                    local ok,err=pcall(ts.Callback,val)
                    if not ok then warn("[Lumina] Toggle '"..ts.Name.."': "..tostring(err)) end
                end
                if not ts.Ext then SaveConfiguration() end
            end

            interact(f).MouseButton1Click:Connect(function() setVal(not ts.CurrentValue, true) end)

            if S.ConfigurationSaving and S.ConfigurationSaving.Enabled and ts.Flag then
                LuminaLibrary.Flags[ts.Flag]=ts
            end
            rc()
            function ts:Set(v) setVal(v, true) end
            return ts
        end

        -- ── Slider ────────────────────────────────────
        function Tab:CreateSlider(ss)
            ss.Type="Slider"
            local range=ss.Range; local inc=ss.Increment or 1
            local suf=ss.Suffix and (" "..ss.Suffix) or ""

            local f=New("Frame",{Name=ss.Name, Size=UDim2.new(1,0,0,66),
                BackgroundColor3=Theme.ElementBackground,
                LayoutOrder=#tabPage:GetChildren(),Parent=tabPage,
            },{corner(14),stroke(Theme.ElementStroke,1,0.88),pad(10,10,14,14)})
            f.MouseEnter:Connect(function() tw(f,T_FAST,{BackgroundColor3=Theme.ElementHover}) end)
            f.MouseLeave:Connect(function() tw(f,T_FAST,{BackgroundColor3=Theme.ElementBackground}) end)

            -- Top row: name + value display
            local topRow=New("Frame",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Parent=f})
            local nLbl=mkLabel(ss.Name,13,Theme.TextPrimary,Enum.Font.GothamMedium,topRow)
            nLbl.Size=UDim2.new(1,-68,1,0)
            local vLbl=New("TextLabel",{
                Text=tostring(ss.CurrentValue)..suf, TextSize=13,Font=Enum.Font.GothamBold,
                TextColor3=Theme.Accent, BackgroundTransparency=1,
                AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),
                Size=UDim2.new(0,66,1,0),TextXAlignment=Enum.TextXAlignment.Right,Parent=topRow,
            })

            -- Track
            local trackBg=New("Frame",{
                Position=UDim2.new(0,0,0,26),Size=UDim2.new(1,0,0,5),
                BackgroundColor3=Theme.SliderTrack,Parent=f},{corner(3)})
            local fill=New("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=Theme.SliderFill,
                Parent=trackBg},{corner(3)})
            local thumb2=New("Frame",{Size=UDim2.new(0,20,0,20),AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(0,0,0.5,0),BackgroundColor3=Color3.new(1,1,1),ZIndex=5,
                Parent=trackBg},{corner(10)})

            local function pct(v)
                return (v-range[1])/(range[2]-range[1])
            end
            local function applyPct(p)
                fill.Size         = UDim2.new(p,0,1,0)
                thumb2.Position   = UDim2.new(p,0,0.5,0)
            end
            applyPct(pct(ss.CurrentValue))

            -- Hit area (taller than track for easier touch)
            local hit=New("TextButton",{
                Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,0,26),
                BackgroundTransparency=1,Text="",ZIndex=6,Parent=f,
            })

            local dragging=false
            local moveConn, endConn

            local function updateX(absX)
                local tPos  = trackBg.AbsolutePosition.X
                local tSize = trackBg.AbsoluteSize.X
                local ratio = math.clamp((absX-tPos)/tSize,0,1)
                local raw   = range[1]+ratio*(range[2]-range[1])
                local snap  = math.floor(raw/inc+0.5)*inc
                snap = math.clamp(tonumber(string.format("%.8g",snap)),range[1],range[2])
                applyPct(pct(snap))
                vLbl.Text = tostring(snap)..suf
                if snap~=ss.CurrentValue then
                    ss.CurrentValue=snap
                    local ok,err=pcall(ss.Callback,snap)
                    if not ok then warn("[Lumina] Slider '"..ss.Name.."': "..tostring(err)) end
                    if not ss.Ext then SaveConfiguration() end
                end
            end

            hit.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1
                or inp.UserInputType==Enum.UserInputType.Touch then
                    dragging=true
                    -- FIX: slightly enlarge thumb for visual feedback, no delay
                    thumb2.Size=UDim2.new(0,24,0,24)
                    updateX(inp.Position.X)
                    moveConn = UIS.InputChanged:Connect(function(i)
                        if not dragging then return end
                        if i.UserInputType==Enum.UserInputType.MouseMovement
                        or i.UserInputType==Enum.UserInputType.Touch then
                            updateX(i.Position.X)
                        end
                    end)
                end
            end)

            -- FIX: bind to UIS.InputEnded (global), not just the frame
            -- This prevents the "stuck dragging" / delayed close bug
            endConn = UIS.InputEnded:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1
                or inp.UserInputType==Enum.UserInputType.Touch then
                    if dragging then
                        dragging=false
                        thumb2.Size=UDim2.new(0,20,0,20)
                        if moveConn then moveConn:Disconnect(); moveConn=nil end
                    end
                end
            end)

            -- Clean up connections when element is destroyed (prevents zombie conns)
            f.Destroying:Connect(function()
                if moveConn then moveConn:Disconnect() end
                if endConn  then endConn:Disconnect()  end
            end)

            if S.ConfigurationSaving and S.ConfigurationSaving.Enabled and ss.Flag then
                LuminaLibrary.Flags[ss.Flag]=ss
            end
            rc()

            function ss:Set(v)
                v=math.clamp(v,range[1],range[2]); ss.CurrentValue=v
                applyPct(pct(v)); vLbl.Text=tostring(v)..suf
                local ok,err=pcall(ss.Callback,v)
                if not ok then warn("[Lumina] Slider:Set '"..ss.Name.."': "..tostring(err)) end
            end
            return ss
        end

        -- ── Input ─────────────────────────────────────
        function Tab:CreateInput(is)
            is.Type="Input"
            local f=New("Frame",{Name=is.Name,Size=UDim2.new(1,0,0,72),
                BackgroundColor3=Theme.ElementBackground,LayoutOrder=#tabPage:GetChildren(),Parent=tabPage,
            },{corner(14),stroke(Theme.ElementStroke,1,0.88),pad(8,8,14,14)})
            f.MouseEnter:Connect(function() tw(f,T_FAST,{BackgroundColor3=Theme.ElementHover}) end)
            f.MouseLeave:Connect(function() tw(f,T_FAST,{BackgroundColor3=Theme.ElementBackground}) end)

            local nl=mkLabel(is.Name,13,Theme.TextPrimary,Enum.Font.GothamMedium,f); nl.Size=UDim2.new(1,0,0,16)

            local iFrame=New("Frame",{Size=UDim2.new(1,0,0,36),BackgroundColor3=Theme.InputBackground,
                Parent=f},{corner(10),stroke(Theme.ElementStroke,1,0.86),pad(0,0,10,10)})
            local iStroke=iFrame:FindFirstChildWhichIsA("UIStroke")

            local box2=New("TextBox",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
                Text=is.CurrentValue or "",PlaceholderText=is.PlaceholderText or "",
                TextColor3=Theme.TextPrimary,PlaceholderColor3=Theme.TextTertiary,
                TextSize=13,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
                ClearTextOnFocus=false,Parent=iFrame})

            box2.Focused:Connect(function()   tw(iStroke,T_FAST,{Transparency=0.5}) end)
            box2.FocusLost:Connect(function()
                tw(iStroke,T_FAST,{Transparency=0.86})
                is.CurrentValue=box2.Text
                local ok,err=pcall(is.Callback,box2.Text)
                if not ok then warn("[Lumina] Input '"..is.Name.."': "..tostring(err)) end
                if is.RemoveTextAfterFocusLost then box2.Text="" end
                if not is.Ext then SaveConfiguration() end
            end)

            if S.ConfigurationSaving and S.ConfigurationSaving.Enabled and is.Flag then
                LuminaLibrary.Flags[is.Flag]=is
            end
            rc()

            function is:Set(t) box2.Text=t; is.CurrentValue=t; pcall(is.Callback,t) end
            return is
        end

        -- ── Dropdown ──────────────────────────────────
        function Tab:CreateDropdown(ds)
            ds.Type="Dropdown"
            if not ds.CurrentOption then ds.CurrentOption={}
            elseif type(ds.CurrentOption)=="string" then ds.CurrentOption={ds.CurrentOption}
            end
            if not ds.MultipleOptions and #ds.CurrentOption>1 then
                ds.CurrentOption={ds.CurrentOption[1]}
            end

            local isOpen=false

            local f=New("Frame",{Name=ds.Name,Size=UDim2.new(1,0,0,50),
                BackgroundColor3=Theme.ElementBackground,ClipsDescendants=true,
                LayoutOrder=#tabPage:GetChildren(),Parent=tabPage,
            },{corner(14),stroke(Theme.ElementStroke,1,0.88),pad(0,0,14,14)})
            f.MouseEnter:Connect(function() tw(f,T_FAST,{BackgroundColor3=Theme.ElementHover}) end)
            f.MouseLeave:Connect(function() tw(f,T_FAST,{BackgroundColor3=Theme.ElementBackground}) end)

            local topR=New("Frame",{Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,Parent=f},
                {list(Enum.FillDirection.Horizontal,8,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)})

            local tCol=New("Frame",{Size=UDim2.new(1,-90,1,0),BackgroundTransparency=1,Parent=topR},
                {list(Enum.FillDirection.Vertical,2,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)})
            mkLabel(ds.Name,14,Theme.TextPrimary,Enum.Font.GothamMedium,tCol).Size=UDim2.new(1,0,0,18)

            local function selText()
                if #ds.CurrentOption==0 then return "None"
                elseif #ds.CurrentOption==1 then return ds.CurrentOption[1]
                else return "Various" end
            end

            local selLbl=mkLabel(selText(),12,Theme.TextTertiary,Enum.Font.Gotham,topR)
            selLbl.Size=UDim2.new(0,62,1,0); selLbl.TextXAlignment=Enum.TextXAlignment.Right

            local chev2=New("ImageLabel",{Size=UDim2.new(0,12,0,12),BackgroundTransparency=1,
                ImageColor3=Theme.TextTertiary,Parent=topR})
            applyIcon(chev2,"chevron-down")

            -- Option list
            local optList=New("ScrollingFrame",{
                Position=UDim2.new(0,0,0,50),Size=UDim2.new(1,0,0,0),
                BackgroundTransparency=1,ScrollBarThickness=2,
                ScrollBarImageColor3=Theme.Divider,
                CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
                Parent=f,
            },{list(Enum.FillDirection.Vertical,0)})

            local function buildOpts()
                for _,c in ipairs(optList:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                for _,opt in ipairs(ds.Options) do
                    local sel=table.find(ds.CurrentOption,opt)~=nil
                    local oF=New("Frame",{Name=opt,Size=UDim2.new(1,0,0,38),
                        BackgroundColor3=sel and Theme.TabActive or Theme.ElementHover,
                        BackgroundTransparency=sel and 0.80 or 0.96,Parent=optList,
                    },{pad(0,0,14,14)})
                    New("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=Theme.Divider,Parent=oF})
                    local oR=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Parent=oF},
                        {list(Enum.FillDirection.Horizontal,8,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)})
                    local ol=mkLabel(opt,13,sel and Theme.Accent or Theme.TextSecondary,Enum.Font.Gotham,oR)
                    ol.Size=UDim2.new(1,-24,1,0)
                    if sel then
                        local chk=New("ImageLabel",{Size=UDim2.new(0,14,0,14),BackgroundTransparency=1,
                            ImageColor3=Theme.Accent,Parent=oR})
                        applyIcon(chk,"check")
                    end
                    local oInt=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
                        Text="",ZIndex=5,Parent=oF})
                    oInt.MouseButton1Click:Connect(function()
                        if not ds.MultipleOptions then
                            ds.CurrentOption={opt}
                        else
                            local idx=table.find(ds.CurrentOption,opt)
                            if idx then table.remove(ds.CurrentOption,idx)
                            else table.insert(ds.CurrentOption,opt) end
                        end
                        selLbl.Text=selText(); buildOpts()
                        local ok,err=pcall(ds.Callback,ds.CurrentOption)
                        if not ok then warn("[Lumina] Dropdown '"..ds.Name.."': "..tostring(err)) end
                        if not ds.Ext then SaveConfiguration() end
                        if not ds.MultipleOptions then
                            isOpen=false
                            tw(f,T_MED,{Size=UDim2.new(1,0,0,50)}); tw(chev2,T_FAST,{Rotation=0}); rc()
                        end
                    end)
                end
            end
            buildOpts()

            interact(f,4).MouseButton1Click:Connect(function()
                if Debounce then return end
                isOpen=not isOpen
                local listH=math.min(#ds.Options*38,192)
                if isOpen then
                    tw(f,T_MED,{Size=UDim2.new(1,0,0,50+listH)}); optList.Size=UDim2.new(1,0,0,listH)
                    tw(chev2,T_FAST,{Rotation=180})
                else
                    tw(f,T_MED,{Size=UDim2.new(1,0,0,50)}); tw(chev2,T_FAST,{Rotation=0})
                end
                rc()
            end)

            if S.ConfigurationSaving and S.ConfigurationSaving.Enabled and ds.Flag then
                LuminaLibrary.Flags[ds.Flag]=ds
            end
            rc()

            function ds:Set(v)
                ds.CurrentOption=type(v)=="string" and {v} or v
                selLbl.Text=selText(); buildOpts(); pcall(ds.Callback,ds.CurrentOption)
            end
            function ds:Refresh(newOpts)
                ds.Options=newOpts; buildOpts()
            end
            return ds
        end

        -- ── Keybind ───────────────────────────────────
        function Tab:CreateKeybind(ks)
            ks.Type="Keybind"
            local listening=false
            local f=card(ks.Name,50)
            local r=row(f)
            textCol(r,-80,ks.Name)

            local chip=New("TextLabel",{
                Text=ks.CurrentKeybind or "None", TextSize=12, Font=Enum.Font.Code,
                TextColor3=Theme.TextSecondary,BackgroundColor3=Theme.InputBackground,
                Size=UDim2.new(0,60,0,26), TextXAlignment=Enum.TextXAlignment.Center,
                Parent=r,
            },{corner(8),stroke(Theme.ElementStroke,1,0.85)})

            local chipBtn=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
                Text="",ZIndex=5,Parent=chip})

            local listenConn
            chipBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening=true; chip.Text="..."
                tw(chip,T_FAST,{BackgroundColor3=Color3.fromRGB(55,44,10)})
                listenConn = UIS.InputBegan:Connect(function(inp,proc)
                    if inp.KeyCode==Enum.KeyCode.Unknown then return end
                    local kn=tostring(inp.KeyCode):split(".")[3]
                    ks.CurrentKeybind=kn; chip.Text=kn
                    tw(chip,T_FAST,{BackgroundColor3=Theme.InputBackground})
                    listening=false
                    if listenConn then listenConn:Disconnect() end
                    if ks.CallOnChange then pcall(ks.Callback,kn) end
                    if not ks.Ext then SaveConfiguration() end
                end)
            end)

            local actConn=UIS.InputBegan:Connect(function(inp,proc)
                if proc or listening then return end
                if not ks.CallOnChange and ks.CurrentKeybind then
                    local ok,_=pcall(function()
                        if inp.KeyCode==Enum.KeyCode[ks.CurrentKeybind] then
                            pcall(ks.Callback)
                        end
                    end)
                end
            end)
            table.insert(keybindConnections,actConn)

            if S.ConfigurationSaving and S.ConfigurationSaving.Enabled and ks.Flag then
                LuminaLibrary.Flags[ks.Flag]=ks
            end
            rc()
            function ks:Set(v) ks.CurrentKeybind=v; chip.Text=v end
            return ks
        end

        -- ── ColorPicker ───────────────────────────────
        function Tab:CreateColorPicker(cps)
            cps.Type="ColorPicker"
            local isOpen=false
            local hh,ss2,vv = (cps.Color or Color3.fromRGB(10,132,255)):ToHSV()
            cps.Color = cps.Color or Color3.fromRGB(10,132,255)

            local f=New("Frame",{Name=cps.Name,Size=UDim2.new(1,0,0,50),
                BackgroundColor3=Theme.ElementBackground,ClipsDescendants=true,
                LayoutOrder=#tabPage:GetChildren(),Parent=tabPage,
            },{corner(14),stroke(Theme.ElementStroke,1,0.88),pad(0,0,14,14)})
            f.MouseEnter:Connect(function() tw(f,T_FAST,{BackgroundColor3=Theme.ElementHover}) end)
            f.MouseLeave:Connect(function() tw(f,T_FAST,{BackgroundColor3=Theme.ElementBackground}) end)

            local topR=New("Frame",{Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,Parent=f},
                {list(Enum.FillDirection.Horizontal,10,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)})
            mkLabel(cps.Name,14,Theme.TextPrimary,Enum.Font.GothamMedium,topR).Size=UDim2.new(1,-44,1,0)

            local swatch2=New("Frame",{Size=UDim2.new(0,28,0,28),
                BackgroundColor3=Color3.fromHSV(hh,ss2,vv),Parent=topR},
                {corner(8),stroke(Color3.new(1,1,1),1,0.78)})

            -- Panel (shown when open)
            local panel=New("Frame",{Position=UDim2.new(0,0,0,54),Size=UDim2.new(1,0,0,180),
                BackgroundTransparency=1,Parent=f},
                {pad(0,4,0,0),list(Enum.FillDirection.Vertical,8)})

            -- Sat/Val gradient
            local gF=New("Frame",{Size=UDim2.new(1,0,0,110),BackgroundColor3=Color3.fromHSV(hh,1,1),
                Parent=panel},{corner(10)})
            -- White → transparent (left to right) overlay
            local wGrad=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1),Parent=gF},{corner(10)})
            New("UIGradient",{Transparency=NumberSequence.new({{Time=0,Value=0},{Time=1,Value=1}}),Parent=wGrad})
            -- Black → transparent (bottom to top) overlay
            local bGrad=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),Parent=gF},{corner(10)})
            New("UIGradient",{Transparency=NumberSequence.new({{Time=0,Value=1},{Time=1,Value=0}}),Rotation=90,Parent=bGrad})

            local cpCursor=New("Frame",{Size=UDim2.new(0,14,0,14),AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(ss2,0,1-vv,0),BackgroundColor3=Color3.fromHSV(hh,ss2,vv),
                ZIndex=5,Parent=gF},{corner(7),stroke(Color3.new(1,1,1),2,0)})

            -- Hue bar
            local hBar=New("Frame",{Size=UDim2.new(1,0,0,16),Parent=panel},{corner(8)})
            New("UIGradient",{Color=ColorSequence.new({
                ColorSequenceKeypoint.new(0/6,Color3.fromRGB(255,0,0)),
                ColorSequenceKeypoint.new(1/6,Color3.fromRGB(255,255,0)),
                ColorSequenceKeypoint.new(2/6,Color3.fromRGB(0,255,0)),
                ColorSequenceKeypoint.new(3/6,Color3.fromRGB(0,255,255)),
                ColorSequenceKeypoint.new(4/6,Color3.fromRGB(0,0,255)),
                ColorSequenceKeypoint.new(5/6,Color3.fromRGB(255,0,255)),
                ColorSequenceKeypoint.new(6/6,Color3.fromRGB(255,0,0)),
            }),Parent=hBar})
            local hThumb=New("Frame",{Size=UDim2.new(0,14,0,14),AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(hh/360,0,0.5,0),BackgroundColor3=Color3.new(1,1,1),
                ZIndex=5,Parent=hBar},{corner(7)})

            local function updateDisplay()
                local c=Color3.fromHSV(hh,ss2,vv)
                swatch2.BackgroundColor3=c; cpCursor.BackgroundColor3=c
                cpCursor.Position=UDim2.new(ss2,0,1-vv,0)
                gF.BackgroundColor3=Color3.fromHSV(hh,1,1)
                hThumb.Position=UDim2.new(hh/360,0,0.5,0)
                cps.Color=c
            end

            -- Gradient interaction
            local gDrag=false
            local function gUpdate(ax,ay)
                local gp=gF.AbsolutePosition; local gs=gF.AbsoluteSize
                ss2=math.clamp((ax-gp.X)/gs.X,0,1); vv=1-math.clamp((ay-gp.Y)/gs.Y,0,1)
                updateDisplay(); pcall(cps.Callback,Color3.fromHSV(hh,ss2,vv))
                if not cps.Ext then SaveConfiguration() end
            end
            local gInt=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=6,Parent=gF})
            gInt.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                    gDrag=true; gUpdate(i.Position.X,i.Position.Y) end end)
            local gmc=UIS.InputChanged:Connect(function(i)
                if not gDrag then return end
                if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
                    gUpdate(i.Position.X,i.Position.Y) end end)
            local gec=UIS.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then gDrag=false end end)

            -- Hue interaction
            local hDrag=false
            local hInt=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=6,Parent=hBar})
            hInt.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                    hDrag=true; hh=math.clamp((i.Position.X-hBar.AbsolutePosition.X)/hBar.AbsoluteSize.X,0,1)*360
                    updateDisplay() end end)
            local hmc=UIS.InputChanged:Connect(function(i)
                if not hDrag then return end
                if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
                    hh=math.clamp((i.Position.X-hBar.AbsolutePosition.X)/hBar.AbsoluteSize.X,0,1)*360
                    updateDisplay(); pcall(cps.Callback,Color3.fromHSV(hh,ss2,vv)) end end)
            local hec=UIS.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then hDrag=false end end)

            f.Destroying:Connect(function()
                gmc:Disconnect();gec:Disconnect();hmc:Disconnect();hec:Disconnect()
            end)

            -- Swatch toggle
            New("TextButton",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-28,0.5,-14),
                BackgroundTransparency=1,Text="",ZIndex=5,Parent=f,
            }).MouseButton1Click:Connect(function()
                isOpen=not isOpen
                tw(f,T_MED,{Size=UDim2.new(1,0,0,isOpen and 248 or 50)}); rc()
            end)

            if S.ConfigurationSaving and S.ConfigurationSaving.Enabled and cps.Flag then
                LuminaLibrary.Flags[cps.Flag]=cps
            end
            rc()
            function cps:Set(c) hh,ss2,vv=c:ToHSV(); cps.Color=c; updateDisplay() end
            return cps
        end

        return Tab
    end -- CreateTab

    -- Kick off config loading after a short delay so all flags are registered
    task.delay(4, function()
        DoLoadConfiguration()
        globalLoaded = true
    end)

    return Window
end -- CreateWindow

-- ============================================================
--  TOP-LEVEL API
-- ============================================================
function LuminaLibrary:Destroy()
    for _,c in ipairs(keybindConnections) do c:Disconnect() end
    if GuiRoot then GuiRoot:Destroy() end
end

function LuminaLibrary:SetVisibility(v)
    Hidden = not v
end

function LuminaLibrary:IsVisible()
    return not Hidden
end

function LuminaLibrary.LoadConfiguration()
    DoLoadConfiguration()
end

return LuminaLibrary
