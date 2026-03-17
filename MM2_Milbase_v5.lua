-- MM2 5v5 Milbase | Silent Aim
-- script by tolopoofcpae / tolopo637883
-- v5 - fixed all errors

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenSvc   = game:GetService("TweenService")
local UIS        = game:GetService("UserInputService")
local RS         = game:GetService("ReplicatedStorage")

local lp   = Players.LocalPlayer
local pgui = lp.PlayerGui
local cam  = workspace.CurrentCamera

-- ── char refs ────────────────────────────────────────────────────
local char, hrp, hum

local function refreshChar(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end
if lp.Character then
    refreshChar(lp.Character)
end
lp.CharacterAdded:Connect(refreshChar)

-- ── gun list ─────────────────────────────────────────────────────
local GUNS = {
    ["Default Gun"]=true,["Alienbeam"]=true,["Amerilaser"]=true,
    ["Blaster"]=true,["Blizzard"]=true,["Chroma Blizzard"]=true,
    ["Chroma Raygun"]=true,["Chroma Snowcannon"]=true,
    ["Chroma Snowstorm"]=true,["Darkshot"]=true,["Emeraldshot"]=true,
    ["Evergun"]=true,["Gingerscope"]=true,["Gold Xenoshot"]=true,
    ["Silver Xenoshot"]=true,["Bronze Xenoshot"]=true,
    ["Red Xenoshot"]=true,["Cyan Xenoshot"]=true,["Harvester"]=true,
    ["Admin Harvester"]=true,["Heat"]=true,["Icebeam"]=true,
    ["Iceblaster"]=true,["Icepiercer"]=true,["Admin Icepiercer"]=true,
    ["Jinglegun"]=true,["Laser"]=true,["Light Shot"]=true,
    ["Lightbringer"]=true,["Luger"]=true,["Red Luger"]=true,
    ["Green Luger"]=true,["Ginger Luger"]=true,["Lugercane"]=true,
    ["Ocean"]=true,["Phaser"]=true,["Plasmabeam"]=true,
    ["Raygun"]=true,["Snowcannon"]=true,["Snowstorm"]=true,
    ["Spectre"]=true,["Swirly Gun"]=true,["Traveler's Gun"]=true,
    ["Valeshot"]=true,["Virtual"]=true,["Constellation"]=true,
    ["Silver Constellation"]=true,["Gold Constellation"]=true,
    ["Bronze Constellation"]=true,["Cupidshot"]=true,
    ["Gemscope"]=true,["Flowerwood Gun"]=true,
    ["Vampire's Gun"]=true,["Skibidi Spectre"]=true,
    ["Hallowgun"]=true,["Borealis"]=true,
    ["Elderwood Revolver"]=true,["Nightblade"]=true,
    ["Blue Gingerscope"]=true,["Gold Gingerscope"]=true,
    ["Silver Gingerscope"]=true,["Bronze Gingerscope"]=true,
}

local function getEquipped()
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end
local function isGun(t)   return t and GUNS[t.Name] == true end
local function isKnife(t) return t and not GUNS[t.Name] end

local function getNearestEnemy()
    if not hrp then return nil end
    local best, bd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp then
            local c = p.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                local r = c:FindFirstChild("HumanoidRootPart")
                if h and r and h.Health > 0 then
                    local d = (hrp.Position - r.Position).Magnitude
                    if d < bd then
                        bd   = d
                        best = r
                    end
                end
            end
        end
    end
    return best
end

-- ── SA state ─────────────────────────────────────────────────────
local saActive = false
local _bypass  = false
local _gunCD   = false
local _stabCD  = false

local function silentGun()
    if _gunCD then return end
    local target = getNearestEnemy()
    if not target then return end
    pcall(function()
        local remotes  = RS:FindFirstChild("Remotes")
        local wpRemotes = remotes and remotes:FindFirstChild("WeaponRemotes")
        local rem      = wpRemotes and wpRemotes:FindFirstChild("RequestShoot")
        if not rem then return end
        local ml       = lp.PlayerScripts:FindFirstChild("MouseLock")
        local mlOn     = ml and ml:GetAttribute("Enabled") or false
        local vp       = cam.ViewportSize
        local ray      = cam:ScreenPointToRay(vp.X / 2, vp.Y / 2)
        _bypass = true
        rem:FireServer(target.Position, mlOn, ray)
        _bypass = false
    end)
    _bypass = false
    _gunCD  = true
    task.delay(0.55, function() _gunCD = false end)
end

local function silentKnife()
    if _stabCD then return end
    local tool = getEquipped()
    if not tool then return end
    local target = getNearestEnemy()
    if not target then return end
    _stabCD = true
    pcall(function()
        local stabRE  = tool:FindFirstChild("Stab")
        local throwRE = tool:FindFirstChild("Throw")
        local handle  = tool:FindFirstChild("Handle")
        if stabRE then
            -- warp stab
            local origCF = hrp.CFrame
            _bypass = true
            hrp.CFrame = target.CFrame * CFrame.new(0, 0, 2.5)
            task.wait()
            stabRE:FireServer(1)
            _bypass = false
            task.delay(0.12, function()
                pcall(function()
                    if hrp then hrp.CFrame = origCF end
                end)
            end)
        elseif throwRE and handle then
            _bypass = true
            throwRE:FireServer(CFrame.new(target.Position), handle.Position)
            _bypass = false
        end
    end)
    _bypass = false
    task.delay(1.3, function() _stabCD = false end)
end

lp.CharacterAdded:Connect(function(c)
    refreshChar(c)
    _bypass = false
    _gunCD  = false
    _stabCD = false
end)

-- ================================================================
-- TWEEN HELPER
-- ================================================================
local function tw(obj, t, props, style, dir)
    TweenSvc:Create(obj,
        TweenInfo.new(t,
            style or Enum.EasingStyle.Quad,
            dir   or Enum.EasingDirection.Out),
        props):Play()
end

-- ================================================================
-- INSTANCE HELPER
-- (props set before Parent to avoid replication jitter)
-- ================================================================
local function make(cls, props, parent)
    local i = Instance.new(cls)
    if props then
        for k, v in pairs(props) do
            pcall(function() i[k] = v end)
        end
    end
    if parent then i.Parent = parent end
    return i
end

-- ================================================================
-- 1. LOADING SCREEN
-- ================================================================
local LoadGui = make("ScreenGui", {
    Name="MM2_Load", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=9999,
}, pgui)

local LBG = make("Frame", {
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(3,3,10),
    BorderSizePixel=0,
}, LoadGui)

-- animated gradient
local gradF = make("Frame", {
    Size=UDim2.new(4,0,1,0),
    Position=UDim2.new(-1.5,0,0,0),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    ZIndex=2,
}, LBG)
local gradUG = make("UIGradient", {
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(3,3,10)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(0,20,58)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,55,128)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(0,20,58)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(3,3,10)),
    }),
    Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.92),
        NumberSequenceKeypoint.new(0.5,0.22),
        NumberSequenceKeypoint.new(1, 0.92),
    }),
}, gradF)

task.spawn(function()
    local t = 0
    while LoadGui.Parent do
        t = t + 0.007
        gradF.Position = UDim2.new(-1.5 + math.sin(t)*0.45, 0, 0, 0)
        gradUG.Rotation = math.sin(t * 0.45) * 28
        RunService.RenderStepped:Wait()
    end
end)

-- scan lines
for i = 1, 24 do
    make("Frame", {
        Size=UDim2.new(1,0,0,1),
        Position=UDim2.new(0,0,i/24,0),
        BackgroundColor3=Color3.fromRGB(0,100,228),
        BackgroundTransparency=0.88,
        BorderSizePixel=0,
        ZIndex=3,
    }, LBG)
end

-- floating dots
local function spawnDot()
    local s = math.random(4, 13)
    local px = math.random(5, 95) / 100
    local dot = make("Frame", {
        Size=UDim2.new(0,s,0,s),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(px, 0, 1.1, 0),
        BackgroundColor3=Color3.fromRGB(
            math.random(0,28), math.random(100,195), 255),
        BackgroundTransparency=math.random(42,72)/100,
        BorderSizePixel=0,
        ZIndex=4,
    }, LBG)
    make("UICorner", {CornerRadius=UDim.new(1,0)}, dot)
    local dest = math.random() * 0.2 - 0.1
    local tw2 = TweenSvc:Create(dot,
        TweenInfo.new(math.random(28,52)/10, Enum.EasingStyle.Linear), {
        Position=UDim2.new(px + dest, 0, -0.12, 0),
        BackgroundTransparency=1,
    })
    tw2:Play()
    tw2.Completed:Connect(function() dot:Destroy() end)
end
task.spawn(function()
    while LoadGui.Parent do
        spawnDot()
        task.wait(math.random(8,20)/100)
    end
end)

-- corner brackets
local corners = {
    {Vector2.new(0,0), UDim2.new(0,12,0,12)},
    {Vector2.new(1,0), UDim2.new(1,-12,0,12)},
    {Vector2.new(0,1), UDim2.new(0,12,1,-12)},
    {Vector2.new(1,1), UDim2.new(1,-12,1,-12)},
}
for _, cv in pairs(corners) do
    local f = make("Frame", {
        Size=UDim2.new(0,52,0,52),
        AnchorPoint=cv[1],
        Position=cv[2],
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ZIndex=5,
    }, LBG)
    local st = make("UIStroke", {
        Color=Color3.fromRGB(0,138,255),
        Thickness=2,
    }, f)
    TweenSvc:Create(st,
        TweenInfo.new(1.2,Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut,-1,true),
        {Transparency=0.88}):Play()
end

-- center card — starts below screen
local card = make("Frame", {
    Size=UDim2.new(0,490,0,275),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,1.7,0),
    BackgroundColor3=Color3.fromRGB(4,8,22),
    BackgroundTransparency=0.14,
    BorderSizePixel=0,
    ZIndex=6,
}, LBG)
make("UICorner", {CornerRadius=UDim.new(0,18)}, card)
make("UIStroke", {
    Color=Color3.fromRGB(0,142,255),
    Thickness=1.8,
    Transparency=0.1,
}, card)

-- card inner gradient animation
local cardGrad = make("UIGradient", {
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,12,35)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,28,65)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,12,35)),
    }),
    Rotation=100,
}, card)
task.spawn(function()
    local t = 0
    while LoadGui.Parent do
        t = t + 0.012
        cardGrad.Rotation = 100 + math.sin(t) * 25
        RunService.RenderStepped:Wait()
    end
end)

-- top accent line (animated expand)
local accLine = make("Frame", {
    Size=UDim2.new(0,0,0,3),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,182,255),
    BorderSizePixel=0,
    ZIndex=7,
}, card)
make("UICorner", {CornerRadius=UDim.new(0,2)}, accLine)

local function cLabel(parent, text, ypos, tsz, col, fnt)
    return make("TextLabel", {
        Size=UDim2.new(1,-28,0,tsz+6),
        Position=UDim2.new(0,14,0,ypos),
        BackgroundTransparency=1,
        Text=text,
        TextColor3=col or Color3.fromRGB(255,255,255),
        Font=fnt or Enum.Font.Gotham,
        TextSize=tsz,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=7,
    }, parent)
end

cLabel(card, "▸  EXCLUSIVE  •  DELTA COMPATIBLE  •  MOBILE  ◂",
    13, 11, Color3.fromRGB(0,158,255))

local titleLbl = cLabel(card, "", 36, 42,
    Color3.fromRGB(255,255,255), Enum.Font.GothamBlack)
local titleGrad = make("UIGradient", {
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,198,255)),
        ColorSequenceKeypoint.new(0.45,Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,198,255)),
    }),
}, titleLbl)
make("UIStroke", {
    Color=Color3.fromRGB(0,148,255),
    Thickness=1.6,
    Transparency=0.5,
}, titleLbl)
task.spawn(function()
    local t = 0
    while LoadGui.Parent do
        t = t + 0.015
        titleGrad.Rotation = math.sin(t) * 16
        RunService.RenderStepped:Wait()
    end
end)

cLabel(card, "5v5  MILBASE  •  SILENT AIM EDITION",
    98, 15, Color3.fromRGB(68,152,255), Enum.Font.GothamBold)

local divLine = make("Frame", {
    Size=UDim2.new(0,0,0,1),
    Position=UDim2.new(0.08,0,0,134),
    BackgroundColor3=Color3.fromRGB(0,138,255),
    BackgroundTransparency=0.4,
    BorderSizePixel=0,
    ZIndex=7,
}, card)

cLabel(card, "script by tolopoofcpae / tolopo637883",
    144, 12, Color3.fromRGB(102,168,255))

local statusLbl = cLabel(card, "Inicializando...",
    168, 11, Color3.fromRGB(48,122,255))

-- progress bar
local pbBG = make("Frame", {
    Size=UDim2.new(0.84,0,0,7),
    Position=UDim2.new(0.08,0,0,194),
    BackgroundColor3=Color3.fromRGB(5,15,36),
    BorderSizePixel=0,
    ZIndex=7,
}, card)
make("UICorner", {CornerRadius=UDim.new(1,0)}, pbBG)

local pbFill = make("Frame", {
    Size=UDim2.new(0,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,182,255),
    BorderSizePixel=0,
    ZIndex=8,
}, pbBG)
make("UICorner", {CornerRadius=UDim.new(1,0)}, pbFill)
make("UIGradient", {
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,108,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(128,232,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,182,255)),
    }),
}, pbFill)

cLabel(card, "v1.0  •  SHIFT LOCK SUPPORT",
    216, 10, Color3.fromRGB(26,55,110))

-- slide card up
TweenSvc:Create(card,
    TweenInfo.new(0.82, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Position=UDim2.new(0.5,0,0.5,0)}):Play()

-- expand accent + divider after card arrives
task.spawn(function()
    task.wait(0.48)
    tw(accLine, 0.9, {Size=UDim2.new(0.8,0,0,3)}, Enum.EasingStyle.Cubic)
    tw(divLine,  1.1, {Size=UDim2.new(0.84,0,0,1)}, Enum.EasingStyle.Cubic)
end)

-- typewriter title
task.spawn(function()
    task.wait(0.55)
    local txt = "MM2 5v5 Milbase"
    for i = 1, #txt do
        titleLbl.Text = string.sub(txt, 1, i)
        task.wait(0.054)
    end
end)

-- progress stages
task.spawn(function()
    local stages = {
        {0.18, "Carregando hooks..."},
        {0.36, "Verificando remotes..."},
        {0.52, "Montando armas..."},
        {0.70, "Preparando botoes..."},
        {0.85, "Aplicando patch..."},
        {0.96, "Quase la..."},
        {1.00, "Pronto!"},
    }
    task.wait(0.3)
    for _, s in pairs(stages) do
        task.wait(0.44)
        statusLbl.Text = s[2]
        tw(pbFill, 0.36, {Size=UDim2.new(s[1],0,1,0)}, Enum.EasingStyle.Cubic)
    end
end)

task.wait(4.6)

-- fade out loading
local fadeOut = make("Frame", {
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    ZIndex=500,
}, LoadGui)
tw(fadeOut, 0.55, {BackgroundTransparency=0}, Enum.EasingStyle.Linear)
task.wait(0.6)
LoadGui:Destroy()

-- ================================================================
-- 2. KEY GUI
-- ================================================================
local CORRECT_KEY = "TopoOp-ofc_mohd"
local keyOK = false

local KeyGui = make("ScreenGui", {
    Name="MM2_Key", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=8000,
}, pgui)

-- dim overlay
local kDim = make("Frame", {
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=0.52,
    BorderSizePixel=0,
}, KeyGui)

-- panel — starts below screen
local kPanel = make("Frame", {
    Size=UDim2.new(0,408,0,305),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,1.8,0),
    BackgroundColor3=Color3.fromRGB(4,8,22),
    BackgroundTransparency=0.04,
    BorderSizePixel=0,
    ZIndex=2,
}, KeyGui)
make("UICorner", {CornerRadius=UDim.new(0,20)}, kPanel)
local kpStroke = make("UIStroke", {
    Color=Color3.fromRGB(0,148,255),
    Thickness=2,
}, kPanel)

-- panel gradient + animation
local kPanelGrad = make("UIGradient", {
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,10,30)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,26,58)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,10,30)),
    }),
    Rotation=112,
}, kPanel)
task.spawn(function()
    local t = 0
    while KeyGui.Parent do
        t = t + 0.013
        kPanelGrad.Rotation = 112 + math.sin(t) * 20
        RunService.RenderStepped:Wait()
    end
end)

-- top glow line
local kTopGlow = make("Frame", {
    Size=UDim2.new(0.65,0,0,3),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,198,255),
    BorderSizePixel=0,
    ZIndex=3,
}, kPanel)
make("UICorner", {CornerRadius=UDim.new(1,0)}, kTopGlow)
TweenSvc:Create(kTopGlow,
    TweenInfo.new(1.25,Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,-1,true),
    {BackgroundColor3=Color3.fromRGB(0,82,198)}):Play()

-- lock icon
local lockCircle = make("Frame", {
    Size=UDim2.new(0,50,0,50),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,14),
    BackgroundColor3=Color3.fromRGB(0,34,84),
    BackgroundTransparency=0.22,
    BorderSizePixel=0,
    ZIndex=3,
}, kPanel)
make("UICorner", {CornerRadius=UDim.new(1,0)}, lockCircle)
make("UIStroke", {Color=Color3.fromRGB(0,136,255), Thickness=1.5}, lockCircle)
make("TextLabel", {
    Size=UDim2.new(1,0,1,0),
    BackgroundTransparency=1,
    Text="🔐",
    TextSize=22,
    Font=Enum.Font.GothamBold,
    ZIndex=4,
}, lockCircle)

local function kLabel(txt, y, sz, col, fnt)
    return make("TextLabel", {
        Size=UDim2.new(1,-28,0,sz+4),
        Position=UDim2.new(0,14,0,y),
        BackgroundTransparency=1,
        Text=txt,
        TextColor3=col or Color3.fromRGB(72,145,218),
        Font=fnt or Enum.Font.Gotham,
        TextSize=sz,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=3,
    }, kPanel)
end

local kTitleLbl = kLabel("MM2  5v5  MILBASE", 76, 22,
    Color3.fromRGB(255,255,255), Enum.Font.GothamBlack)
local kTitleGrad = make("UIGradient", {
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,194,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(198,238,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,194,255)),
    }),
}, kTitleLbl)
task.spawn(function()
    local t = 0
    while KeyGui.Parent do
        t = t + 0.017
        kTitleGrad.Rotation = math.sin(t) * 13
        RunService.RenderStepped:Wait()
    end
end)

kLabel("Insira a key para continuar", 108, 13)
kLabel("Pega a key gratis no  scriptblox.com", 126, 11,
    Color3.fromRGB(42,98,178))

-- input background
local iBG = make("Frame", {
    Size=UDim2.new(1,-38,0,46),
    Position=UDim2.new(0,19,0,150),
    BackgroundColor3=Color3.fromRGB(0,12,33),
    BorderSizePixel=0,
    ZIndex=3,
}, kPanel)
make("UICorner", {CornerRadius=UDim.new(0,10)}, iBG)
local iStroke = make("UIStroke", {
    Color=Color3.fromRGB(0,92,198),
    Thickness=1.5,
}, iBG)

local tbox = make("TextBox", {
    Size=UDim2.new(1,-14,1,0),
    Position=UDim2.new(0,7,0,0),
    BackgroundTransparency=1,
    Text="",
    PlaceholderText="Cole a key aqui...",
    PlaceholderColor3=Color3.fromRGB(38,72,126),
    TextColor3=Color3.fromRGB(182,222,255),
    Font=Enum.Font.GothamBold,
    TextSize=15,
    ClearTextOnFocus=false,
    ZIndex=4,
}, iBG)

tbox.Focused:Connect(function()
    tw(iStroke, 0.16, {Color=Color3.fromRGB(0,198,255), Thickness=2})
end)
tbox.FocusLost:Connect(function()
    tw(iStroke, 0.16, {Color=Color3.fromRGB(0,92,198), Thickness=1.5})
end)

local errLbl = kLabel("", 205, 12, Color3.fromRGB(255,72,72), Enum.Font.GothamBold)

-- confirm button
local confBtn = make("TextButton", {
    Size=UDim2.new(1,-38,0,44),
    Position=UDim2.new(0,19,0,228),
    Text="CONFIRMAR KEY",
    TextColor3=Color3.fromRGB(255,255,255),
    Font=Enum.Font.GothamBlack,
    TextSize=15,
    BackgroundColor3=Color3.fromRGB(0,76,198),
    BorderSizePixel=0,
    ZIndex=3,
}, kPanel)
make("UICorner", {CornerRadius=UDim.new(0,10)}, confBtn)
make("UIGradient", {
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,96,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,54,190)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,96,255)),
    }),
    Rotation=90,
}, confBtn)
make("UIStroke", {Color=Color3.fromRGB(0,155,255)}, confBtn)

confBtn.MouseButton1Down:Connect(function()
    tw(confBtn, 0.07, {
        Size=UDim2.new(1,-46,0,41),
        Position=UDim2.new(0,23,0,230),
    })
end)

local function doValidate()
    tw(confBtn, 0.1, {
        Size=UDim2.new(1,-38,0,44),
        Position=UDim2.new(0,19,0,228),
    })
    local entered = string.gsub(tbox.Text, "%s", "")
    if entered == CORRECT_KEY then
        keyOK = true
        confBtn.Text = "KEY CORRETA!"
        confBtn.BackgroundColor3 = Color3.fromRGB(0,148,52)
        errLbl.Text = ""
        task.delay(0.25, function()
            TweenSvc:Create(kPanel,
                TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                {Position=UDim2.new(0.5,0,1.8,0)}):Play()
            tw(kDim, 0.5, {BackgroundTransparency=1})
            task.delay(0.55, function()
                KeyGui:Destroy()
            end)
        end)
    else
        errLbl.Text = "Key incorreta. Tente novamente."
        tw(iStroke, 0.1, {Color=Color3.fromRGB(255,46,46)})
        task.delay(0.6, function()
            tw(iStroke, 0.2, {Color=Color3.fromRGB(0,92,198)})
        end)
        -- shake
        local orig = kPanel.Position
        task.spawn(function()
            local offsets = {-10, 10, -8, 8, -5, 5, 0}
            for _, ox in pairs(offsets) do
                TweenSvc:Create(kPanel, TweenInfo.new(0.04), {
                    Position=UDim2.new(0.5, ox, 0.5, 0),
                }):Play()
                task.wait(0.045)
            end
            kPanel.Position = orig
        end)
    end
end

confBtn.MouseButton1Up:Connect(doValidate)
tbox.FocusLost:Connect(function(enter)
    if enter then doValidate() end
end)

-- slide panel up
TweenSvc:Create(kPanel,
    TweenInfo.new(0.76, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Position=UDim2.new(0.5,0,0.5,0)}):Play()

-- wait for key
repeat task.wait(0.1) until keyOK

-- ================================================================
-- 3. HOOK (after key — inside pcall so buttons still appear)
-- ================================================================
pcall(function()
    local blocked = {
        RequestShoot=true,
        Stab=true,
        Throw=true,
        FlingKnifeEvent=true,
    }
    local oldNC
    oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if saActive and not _bypass
        and getnamecallmethod() == "FireServer"
        and self:IsA("RemoteEvent")
        and blocked[self.Name] then
            return
        end
        return oldNC(self, ...)
    end))
end)

-- ================================================================
-- 4. MOBILE BUTTONS
-- ================================================================
local BGui = make("ScreenGui", {
    Name="MM2_Btns", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=500,
}, pgui)

local function makeBtn(sz, pos, label, textColor, draggable)
    -- outer ring: black transparent, dark stroke
    local outer = make("Frame", {
        Size=UDim2.new(0,sz,0,sz),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=pos,
        BackgroundColor3=Color3.fromRGB(0,0,0),
        BackgroundTransparency=0.62,
        BorderSizePixel=0,
        ZIndex=10,
    }, BGui)
    make("UICorner", {CornerRadius=UDim.new(1,0)}, outer)
    local ost = make("UIStroke", {
        Color=Color3.fromRGB(20,20,20),
        Thickness=2.2,
    }, outer)

    -- transparent gap (visual spacing)
    local gap = make("Frame", {
        Size=UDim2.new(0,sz-13,0,sz-13),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,0),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ZIndex=11,
    }, outer)
    make("UICorner", {CornerRadius=UDim.new(1,0)}, gap)

    -- inner circle: black transparent
    local inner = make("Frame", {
        Size=UDim2.new(0,sz-18,0,sz-18),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,0),
        BackgroundColor3=Color3.fromRGB(0,0,0),
        BackgroundTransparency=0.48,
        BorderSizePixel=0,
        ZIndex=12,
    }, outer)
    make("UICorner", {CornerRadius=UDim.new(1,0)}, inner)

    -- label
    local lbl = make("TextLabel", {
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text=label,
        TextColor3=textColor,
        Font=Enum.Font.GothamBold,
        TextScaled=true,
        ZIndex=13,
    }, inner)

    -- invisible tap area
    local btn = make("TextButton", {
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="",
        ZIndex=14,
    }, outer)
    make("UICorner", {CornerRadius=UDim.new(1,0)}, btn)

    -- drag
    if draggable then
        local dragging, dragStart, dragPos = false, nil, nil
        btn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch
            or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging  = true
                dragStart = inp.Position
                dragPos   = outer.Position
            end
        end)
        btn.InputChanged:Connect(function(inp)
            if dragging then
                if inp.UserInputType == Enum.UserInputType.Touch
                or inp.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = inp.Position - dragStart
                    outer.Position = UDim2.new(
                        dragPos.X.Scale,
                        dragPos.X.Offset + delta.X,
                        dragPos.Y.Scale,
                        dragPos.Y.Offset + delta.Y
                    )
                end
            end
        end)
        btn.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch
            or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end

    -- press animation
    btn.MouseButton1Down:Connect(function()
        tw(outer, 0.07, {Size=UDim2.new(0,sz*0.87,0,sz*0.87)})
    end)
    btn.MouseButton1Up:Connect(function()
        TweenSvc:Create(outer,
            TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size=UDim2.new(0,sz,0,sz)}):Play()
    end)

    return {f=outer, btn=btn, lbl=lbl, inner=inner, stroke=ost}
end

-- SA toggle — draggable, left side
local saBtn = makeBtn(78,
    UDim2.new(0.12,0,0.80,0),
    "SA\nOFF",
    Color3.fromRGB(255,72,50),
    true)

saBtn.btn.MouseButton1Up:Connect(function()
    saActive = not saActive
    if saActive then
        saBtn.lbl.Text            = "SA\nON"
        saBtn.lbl.TextColor3      = Color3.fromRGB(72,255,92)
        saBtn.inner.BackgroundColor3 = Color3.fromRGB(0,20,0)
        saBtn.stroke.Color        = Color3.fromRGB(0,92,0)
    else
        saBtn.lbl.Text            = "SA\nOFF"
        saBtn.lbl.TextColor3      = Color3.fromRGB(255,72,50)
        saBtn.inner.BackgroundColor3 = Color3.fromRGB(0,0,0)
        saBtn.stroke.Color        = Color3.fromRGB(20,20,20)
    end
end)

-- Knife — draggable, above SA
local kBtn = makeBtn(74,
    UDim2.new(0.12,0,0.67,0),
    "FACA",
    Color3.fromRGB(172,195,255),
    true)

kBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local t = getEquipped()
    if t and isKnife(t) then
        silentKnife()
    end
end)

-- Gun — fixed, bottom right (near jump button)
local gBtn = makeBtn(80,
    UDim2.new(0.88,0,0.88,0),
    "GUN",
    Color3.fromRGB(255,205,0),
    false)

gBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local t = getEquipped()
    if t and isGun(t) then
        silentGun()
    end
end)

-- glow active weapon button
task.spawn(function()
    while true do
        task.wait(0.1)
        local t = getEquipped()
        if saActive and t and isKnife(t) then
            kBtn.stroke.Color = Color3.fromRGB(72,92,255)
        else
            kBtn.stroke.Color = Color3.fromRGB(20,20,20)
        end
        if saActive and t and isGun(t) then
            gBtn.stroke.Color = Color3.fromRGB(255,172,0)
        else
            gBtn.stroke.Color = Color3.fromRGB(20,20,20)
        end
    end
end)

-- slide buttons in from bottom with stagger
do
    local allBtns = {saBtn, kBtn, gBtn}
    for i = 1, #allBtns do
        local b    = allBtns[i]
        local orig = b.f.Position
        b.f.Position = UDim2.new(
            orig.X.Scale, orig.X.Offset,
            orig.Y.Scale + 0.35, orig.Y.Offset
        )
        task.delay((i-1)*0.1, function()
            TweenSvc:Create(b.f,
                TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Position=orig}):Play()
        end)
    end
end
