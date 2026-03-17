-- MM2 5v5 Milbase | Silent Aim
-- script by tolopoofcpae / tolopo637883

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenSvc   = game:GetService("TweenService")
local UIS        = game:GetService("UserInputService")
local RS         = game:GetService("ReplicatedStorage")
local lp         = Players.LocalPlayer
local pgui       = lp:WaitForChild("PlayerGui")
local cam        = workspace.CurrentCamera

-- ── char refs ────────────────────────────────────────────────────
local char, hrp, hum
local function refreshChar(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end
if lp.Character then refreshChar(lp.Character) end
lp.CharacterAdded:Connect(refreshChar)

-- ── gun list ─────────────────────────────────────────────────────
local GUNS = {
    ["Default Gun"]=1,["Alienbeam"]=1,["Amerilaser"]=1,["Blaster"]=1,
    ["Blizzard"]=1,["Chroma Blizzard"]=1,["Chroma Raygun"]=1,
    ["Chroma Snowcannon"]=1,["Chroma Snowstorm"]=1,["Darkshot"]=1,
    ["Emeraldshot"]=1,["Evergun"]=1,["Gingerscope"]=1,
    ["Gold Xenoshot"]=1,["Silver Xenoshot"]=1,["Bronze Xenoshot"]=1,
    ["Red Xenoshot"]=1,["Cyan Xenoshot"]=1,["Harvester"]=1,
    ["Admin Harvester"]=1,["Heat"]=1,["Icebeam"]=1,["Iceblaster"]=1,
    ["Icepiercer"]=1,["Admin Icepiercer"]=1,["Jinglegun"]=1,
    ["Laser"]=1,["Light Shot"]=1,["Lightbringer"]=1,["Luger"]=1,
    ["Red Luger"]=1,["Green Luger"]=1,["Ginger Luger"]=1,
    ["Lugercane"]=1,["Ocean"]=1,["Phaser"]=1,["Plasmabeam"]=1,
    ["Raygun"]=1,["Snowcannon"]=1,["Snowstorm"]=1,["Spectre"]=1,
    ["Swirly Gun"]=1,["Traveler's Gun"]=1,["Valeshot"]=1,
    ["Virtual"]=1,["Constellation"]=1,["Silver Constellation"]=1,
    ["Gold Constellation"]=1,["Bronze Constellation"]=1,
    ["Cupidshot"]=1,["Gemscope"]=1,["Flowerwood Gun"]=1,
    ["Vampire's Gun"]=1,["Skibidi Spectre"]=1,["Hallowgun"]=1,
    ["Borealis"]=1,["Elderwood Revolver"]=1,["Nightblade"]=1,
    ["Blue Gingerscope"]=1,["Gold Gingerscope"]=1,
    ["Silver Gingerscope"]=1,["Bronze Gingerscope"]=1,
}

local function getEquipped()
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end
local function isGun(t)   return t and GUNS[t.Name] ~= nil end
local function isKnife(t) return t and not GUNS[t.Name] end

local function getNearestEnemy()
    if not hrp then return nil end
    local best, bd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == lp then continue end
        local c = p.Character
        if not c then continue end
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h or h.Health <= 0 then continue end
        local r = c:FindFirstChild("HumanoidRootPart")
        if not r then continue end
        local d = (hrp.Position - r.Position).Magnitude
        if d < bd then bd = d; best = r end
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
    local t = getNearestEnemy()
    if not t then return end
    local rem = RS:FindFirstChild("Remotes")
        and RS.Remotes:FindFirstChild("WeaponRemotes")
        and RS.Remotes.WeaponRemotes:FindFirstChild("RequestShoot")
    if not rem then return end
    local ml = lp.PlayerScripts:FindFirstChild("MouseLock")
    local vp = cam.ViewportSize
    _bypass = true
    pcall(function()
        rem:FireServer(t.Position, ml and ml:GetAttribute("Enabled") or false,
            cam:ScreenPointToRay(vp.X/2, vp.Y/2))
    end)
    _bypass = false
    _gunCD  = true
    task.delay(0.55, function() _gunCD = false end)
end

local function silentStab()
    if _stabCD then return end
    local tool = getEquipped()
    if not tool then return end
    local sr = tool:FindFirstChild("Stab")
    if not sr then
        -- fallback: throw
        local tr = tool:FindFirstChild("Throw")
        local hd = tool:FindFirstChild("Handle")
        if not tr or not hd then return end
        local tg = getNearestEnemy()
        if not tg then return end
        _stabCD = true
        _bypass = true
        pcall(function() tr:FireServer(CFrame.new(tg.Position), hd.Position) end)
        _bypass = false
        task.delay(2.2, function() _stabCD = false end)
        return
    end
    local tg = getNearestEnemy()
    if not tg or not hrp then return end
    _stabCD = true
    local orig = hrp.CFrame
    _bypass = true
    pcall(function()
        hrp.CFrame = tg.CFrame * CFrame.new(0,0,2.5)
        task.wait()
        sr:FireServer(1)
    end)
    _bypass = false
    task.delay(0.12, function() pcall(function() if hrp then hrp.CFrame = orig end) end)
    task.delay(1.25, function() _stabCD = false end)
end

lp.CharacterAdded:Connect(function(c)
    refreshChar(c)
    _bypass=false _gunCD=false _stabCD=false
end)

-- ── hook (wrapped so GUI still shows if it fails) ─────────────────
pcall(function()
    local bl = {RequestShoot=true,Stab=true,Throw=true,FlingKnifeEvent=true}
    local old
    old = hookmetamethod(game,"__namecall",newcclosure(function(self,...)
        if saActive and not _bypass
        and getnamecallmethod()=="FireServer"
        and self:IsA("RemoteEvent") and bl[self.Name] then
            return
        end
        return old(self,...)
    end))
end)

-- ================================================================
-- HELPERS
-- ================================================================
local function new(cls, parent, props)
    local i = Instance.new(cls)
    if parent then i.Parent = parent end
    if props then
        for k,v in pairs(props) do
            i[k] = v
        end
    end
    return i
end

local function tween(obj, t, props, style, dir)
    TweenSvc:Create(obj,
        TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props):Play()
end

-- ================================================================
-- LOADING SCREEN
-- ================================================================
local LoadGui = new("ScreenGui", pgui, {
    Name="MM2_Load", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=9999,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
})

local bg = new("Frame", LoadGui, {
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(3,3,10),
    BorderSizePixel=0,
})

-- animated gradient overlay
do
    local gf = new("Frame", bg, {
        Size=UDim2.new(3,0,1,0),
        Position=UDim2.new(-1,0,0,0),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ZIndex=2,
    })
    local ug = new("UIGradient", gf, {
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(3,3,10)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(0,20,60)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,55,130)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(0,20,60)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(3,3,10)),
        }),
        Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0,0.92),
            NumberSequenceKeypoint.new(0.5,0.22),
            NumberSequenceKeypoint.new(1,0.92),
        }),
    })
    task.spawn(function()
        local t=0
        while LoadGui.Parent do
            t+=0.007
            gf.Position = UDim2.new(-1+math.sin(t)*0.45, 0, 0, 0)
            ug.Rotation = math.sin(t*0.45)*28
            RunService.RenderStepped:Wait()
        end
    end)
end

-- scan lines
for i=1,26 do
    new("Frame", bg, {
        Size=UDim2.new(1,0,0,1),
        Position=UDim2.new(0,0,i/26,0),
        BackgroundColor3=Color3.fromRGB(0,100,230),
        BackgroundTransparency=0.88,
        BorderSizePixel=0,
        ZIndex=3,
    })
end

-- particles
local function spawnDot()
    local s = math.random(4,14)
    local p = new("Frame", bg, {
        Size=UDim2.new(0,s,0,s),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(math.random(5,95)/100,0,1.1,0),
        BackgroundColor3=Color3.fromRGB(math.random(0,30),math.random(100,200),255),
        BackgroundTransparency=math.random(40,72)/100,
        BorderSizePixel=0,
        ZIndex=4,
    })
    new("UICorner",p,{CornerRadius=UDim.new(1,0)})
    local tw = TweenSvc:Create(p, TweenInfo.new(math.random(28,52)/10, Enum.EasingStyle.Linear), {
        Position=UDim2.new(p.Position.X.Scale+(math.random()-0.5)*0.2,0,-0.12,0),
        BackgroundTransparency=1,
    })
    tw:Play()
    tw.Completed:Connect(function() p:Destroy() end)
end
task.spawn(function()
    while LoadGui.Parent do
        spawnDot()
        task.wait(math.random(8,20)/100)
    end
end)

-- corner brackets
for _,cv in ipairs({
    {Vector2.new(0,0),UDim2.new(0,14,0,14)},
    {Vector2.new(1,0),UDim2.new(1,-14,0,14)},
    {Vector2.new(0,1),UDim2.new(0,14,1,-14)},
    {Vector2.new(1,1),UDim2.new(1,-14,1,-14)},
}) do
    local f = new("Frame", bg, {
        Size=UDim2.new(0,52,0,52),
        AnchorPoint=cv[1],
        Position=cv[2],
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ZIndex=5,
    })
    local st = new("UIStroke", f, {Color=Color3.fromRGB(0,140,255),Thickness=2})
    TweenSvc:Create(st, TweenInfo.new(1.2,Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,-1,true), {Transparency=0.85}):Play()
end

-- center card (starts below screen)
local card = new("Frame", bg, {
    Size=UDim2.new(0,490,0,278),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,1.7,0),
    BackgroundColor3=Color3.fromRGB(4,8,22),
    BackgroundTransparency=0.15,
    BorderSizePixel=0,
    ZIndex=6,
})
new("UICorner",card,{CornerRadius=UDim.new(0,18)})
local cst = new("UIStroke",card,{Color=Color3.fromRGB(0,145,255),Thickness=1.8,Transparency=0.12})

-- card gradient animation
do
    local cg = new("UIGradient",card,{
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,12,36)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,30,68)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,12,36)),
        }),
        Rotation=100,
    })
    task.spawn(function()
        local t=0
        while LoadGui.Parent do
            t+=0.012
            cg.Rotation=100+math.sin(t)*26
            RunService.RenderStepped:Wait()
        end
    end)
end

-- top accent (expands)
local accLine = new("Frame",card,{
    Size=UDim2.new(0,0,0,3),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,185,255),
    BorderSizePixel=0, ZIndex=7,
})
new("UICorner",accLine,{CornerRadius=UDim.new(0,2)})

local function cardLabel(txt,ypos,tsz,col,fnt)
    local lb = new("TextLabel",card,{
        Size=UDim2.new(1,-28,0,tsz+4),
        Position=UDim2.new(0,14,0,ypos),
        BackgroundTransparency=1,
        Text=txt,
        TextColor3=col or Color3.fromRGB(255,255,255),
        Font=fnt or Enum.Font.Gotham,
        TextSize=tsz,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=7,
    })
    return lb
end

cardLabel("▸  EXCLUSIVE  •  DELTA  •  MOBILE  ◂",13,11,Color3.fromRGB(0,160,255))

local titleLbl = cardLabel("",37,42,Color3.fromRGB(255,255,255),Enum.Font.GothamBlack)
do
    local tg = new("UIGradient",titleLbl,{
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,200,255)),
            ColorSequenceKeypoint.new(0.45,Color3.fromRGB(255,255,255)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,200,255)),
        }),
    })
    new("UIStroke",titleLbl,{Color=Color3.fromRGB(0,150,255),Thickness=1.6,Transparency=0.5})
    task.spawn(function()
        local t=0
        while LoadGui.Parent do
            t+=0.015
            tg.Rotation=math.sin(t)*16
            RunService.RenderStepped:Wait()
        end
    end)
end

cardLabel("5v5  MILBASE  •  SILENT AIM EDITION",100,15,Color3.fromRGB(70,155,255),Enum.Font.GothamBold)

-- divider line
local divLine = new("Frame",card,{
    Size=UDim2.new(0,0,0,1),
    Position=UDim2.new(0.075,0,0,136),
    BackgroundColor3=Color3.fromRGB(0,140,255),
    BackgroundTransparency=0.42,
    BorderSizePixel=0, ZIndex=7,
})

cardLabel("script by tolopoofcpae / tolopo637883",146,12,Color3.fromRGB(105,172,255))

local statusLbl = cardLabel("Inicializando...",170,11,Color3.fromRGB(50,125,255))

-- progress bar
local pbBG = new("Frame",card,{
    Size=UDim2.new(0.84,0,0,7),
    Position=UDim2.new(0.08,0,0,196),
    BackgroundColor3=Color3.fromRGB(6,16,38),
    BorderSizePixel=0, ZIndex=7,
})
new("UICorner",pbBG,{CornerRadius=UDim.new(1,0)})

local pbFill = new("Frame",pbBG,{
    Size=UDim2.new(0,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,185,255),
    BorderSizePixel=0, ZIndex=8,
})
new("UICorner",pbFill,{CornerRadius=UDim.new(1,0)})
new("UIGradient",pbFill,{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,110,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130,235,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,185,255)),
})})

cardLabel("v1.0  •  SHIFT LOCK SUPPORT",218,10,Color3.fromRGB(28,58,112))

-- slide card up
TweenSvc:Create(card,TweenInfo.new(0.82,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Position=UDim2.new(0.5,0,0.5,0),
}):Play()

-- expand accent + divider
task.spawn(function()
    task.wait(0.45)
    tween(accLine,0.9,{Size=UDim2.new(0.8,0,0,3)},Enum.EasingStyle.Cubic)
    tween(divLine,1.1,{Size=UDim2.new(0.84,0,0,1)},Enum.EasingStyle.Cubic)
end)

-- typewriter
task.spawn(function()
    task.wait(0.55)
    local txt = "MM2 5v5 Milbase"
    for i=1,#txt do
        titleLbl.Text = txt:sub(1,i)
        task.wait(0.054)
    end
end)

-- progress stages
task.spawn(function()
    local stages = {
        {0.18,"Carregando hooks..."},
        {0.36,"Verificando remotes..."},
        {0.52,"Montando armas..."},
        {0.70,"Preparando botões..."},
        {0.85,"Aplicando patch..."},
        {0.96,"Quase lá..."},
        {1.00,"Pronto!"},
    }
    task.wait(0.3)
    for _, s in ipairs(stages) do
        task.wait(0.44)
        statusLbl.Text = s[2]
        tween(pbFill,0.36,{Size=UDim2.new(s[1],0,1,0)},Enum.EasingStyle.Cubic)
    end
end)

task.wait(4.6)

-- fade out
local fd = new("Frame",LoadGui,{
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=1,
    BorderSizePixel=0, ZIndex=500,
})
tween(fd,0.55,{BackgroundTransparency=0},Enum.EasingStyle.Linear)
task.wait(0.6)
LoadGui:Destroy()

-- ================================================================
-- KEY GUI
-- ================================================================
local CORRECT_KEY = "TopoOp-ofc_mohd"
local keyOK = false

local KeyGui = new("ScreenGui",pgui,{
    Name="MM2_Key", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=8000,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
})

-- dim
local kDim = new("Frame",KeyGui,{
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=0.52,
    BorderSizePixel=0,
})

-- panel starts below screen
local kPanel = new("Frame",KeyGui,{
    Size=UDim2.new(0,408,0,305),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,1.8,0),
    BackgroundColor3=Color3.fromRGB(4,8,22),
    BackgroundTransparency=0.04,
    BorderSizePixel=0,
    ZIndex=2,
})
new("UICorner",kPanel,{CornerRadius=UDim.new(0,20)})
local kpSt = new("UIStroke",kPanel,{Color=Color3.fromRGB(0,148,255),Thickness=2})

-- panel gradient
do
    local pg = new("UIGradient",kPanel,{
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,10,30)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,26,60)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,10,30)),
        }),
        Rotation=112,
    })
    task.spawn(function()
        local t=0
        while KeyGui.Parent do
            t+=0.013
            pg.Rotation=112+math.sin(t)*20
            RunService.RenderStepped:Wait()
        end
    end)
end

-- top glow line
local kTopGlow = new("Frame",kPanel,{
    Size=UDim2.new(0.65,0,0,3),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,200,255),
    BorderSizePixel=0, ZIndex=3,
})
new("UICorner",kTopGlow,{CornerRadius=UDim.new(1,0)})
TweenSvc:Create(kTopGlow,TweenInfo.new(1.25,Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,-1,true),{BackgroundColor3=Color3.fromRGB(0,85,200)}):Play()

-- lock icon
local lockCircle = new("Frame",kPanel,{
    Size=UDim2.new(0,50,0,50),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,14),
    BackgroundColor3=Color3.fromRGB(0,36,86),
    BackgroundTransparency=0.22,
    BorderSizePixel=0, ZIndex=3,
})
new("UICorner",lockCircle,{CornerRadius=UDim.new(1,0)})
new("UIStroke",lockCircle,{Color=Color3.fromRGB(0,138,255),Thickness=1.5})
new("TextLabel",lockCircle,{
    Size=UDim2.new(1,0,1,0),
    BackgroundTransparency=1,
    Text="🔐", TextSize=22,
    Font=Enum.Font.GothamBold,
    ZIndex=4,
})

-- helper label
local function kLbl(parent,txt,y,sz,col,fnt)
    return new("TextLabel",parent,{
        Size=UDim2.new(1,-28,0,sz+4),
        Position=UDim2.new(0,14,0,y),
        BackgroundTransparency=1,
        Text=txt,
        TextColor3=col or Color3.fromRGB(75,148,220),
        Font=fnt or Enum.Font.Gotham,
        TextSize=sz,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=3,
    })
end

local ktLbl = kLbl(kPanel,"MM2  5v5  MILBASE",76,22,Color3.fromRGB(255,255,255),Enum.Font.GothamBlack)
do
    local tg = new("UIGradient",ktLbl,{
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,196,255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,240,255)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,196,255)),
        }),
    })
    task.spawn(function()
        local t=0
        while KeyGui.Parent do
            t+=0.017
            tg.Rotation=math.sin(t)*13
            RunService.RenderStepped:Wait()
        end
    end)
end

kLbl(kPanel,"Insira a key para continuar",108,13)
kLbl(kPanel,"📌  Pega a key grátis no  scriptblox.com",126,11,Color3.fromRGB(45,100,180))

-- input bg
local iBG = new("Frame",kPanel,{
    Size=UDim2.new(1,-38,0,46),
    Position=UDim2.new(0,19,0,150),
    BackgroundColor3=Color3.fromRGB(0,13,34),
    BorderSizePixel=0, ZIndex=3,
})
new("UICorner",iBG,{CornerRadius=UDim.new(0,10)})
local iSt = new("UIStroke",iBG,{Color=Color3.fromRGB(0,95,200),Thickness=1.5})

local tbox = new("TextBox",iBG,{
    Size=UDim2.new(1,-14,1,0),
    Position=UDim2.new(0,7,0,0),
    BackgroundTransparency=1,
    Text="",
    PlaceholderText="Cole a key aqui...",
    PlaceholderColor3=Color3.fromRGB(40,75,128),
    TextColor3=Color3.fromRGB(185,225,255),
    Font=Enum.Font.GothamBold,
    TextSize=15,
    ClearTextOnFocus=false,
    ZIndex=4,
})
tbox.Focused:Connect(function()
    tween(iSt,0.16,{Color=Color3.fromRGB(0,200,255),Thickness=2})
end)
tbox.FocusLost:Connect(function()
    tween(iSt,0.16,{Color=Color3.fromRGB(0,95,200),Thickness=1.5})
end)

local errLbl = kLbl(kPanel,"",207,12,Color3.fromRGB(255,75,75),Enum.Font.GothamBold)

-- confirm button
local confBtn = new("TextButton",kPanel,{
    Size=UDim2.new(1,-38,0,44),
    Position=UDim2.new(0,19,0,228),
    Text="CONFIRMAR KEY",
    TextColor3=Color3.fromRGB(255,255,255),
    Font=Enum.Font.GothamBlack,
    TextSize=15,
    BackgroundColor3=Color3.fromRGB(0,78,200),
    BorderSizePixel=0, ZIndex=3,
})
new("UICorner",confBtn,{CornerRadius=UDim.new(0,10)})
new("UIGradient",confBtn,{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,98,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,56,192)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,98,255)),
    }),
    Rotation=90,
})
new("UIStroke",confBtn,{Color=Color3.fromRGB(0,158,255)})

confBtn.MouseButton1Down:Connect(function()
    tween(confBtn,0.07,{Size=UDim2.new(1,-46,0,41),Position=UDim2.new(0,23,0,230)})
end)

local function doValidate()
    tween(confBtn,0.1,{Size=UDim2.new(1,-38,0,44),Position=UDim2.new(0,19,0,228)})
    local entered = tbox.Text:gsub("%s","")
    if entered == CORRECT_KEY then
        keyOK = true
        confBtn.Text = "✓  KEY CORRETA!"
        confBtn.BackgroundColor3 = Color3.fromRGB(0,152,55)
        errLbl.Text = ""
        task.delay(0.25,function()
            TweenSvc:Create(kPanel,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.In),{
                Position=UDim2.new(0.5,0,1.8,0),
            }):Play()
            tween(kDim,0.5,{BackgroundTransparency=1})
            task.delay(0.55,function() KeyGui:Destroy() end)
        end)
    else
        errLbl.Text = "✗  Key incorreta."
        tween(iSt,0.1,{Color=Color3.fromRGB(255,48,48)})
        task.delay(0.6,function() tween(iSt,0.2,{Color=Color3.fromRGB(0,95,200)}) end)
        -- shake
        local orig = kPanel.Position
        task.spawn(function()
            for i=1,6 do
                TweenSvc:Create(kPanel,TweenInfo.new(0.04),{
                    Position=UDim2.new(0.5,i%2==0 and 9 or -9,0.5,0),
                }):Play()
                task.wait(0.045)
            end
            kPanel.Position = orig
        end)
    end
end

confBtn.MouseButton1Up:Connect(doValidate)
tbox.FocusLost:Connect(function(enter) if enter then doValidate() end end)

-- slide panel up
TweenSvc:Create(kPanel,TweenInfo.new(0.76,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Position=UDim2.new(0.5,0,0.5,0),
}):Play()

repeat task.wait(0.1) until keyOK

-- ================================================================
-- BUTTONS
-- ================================================================
local BGui = new("ScreenGui",pgui,{
    Name="MM2_Btns", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=500,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
})

local function makeBtn(sz,pos,txt,tcol,draggable)
    -- outer ring: black transparent + dark stroke
    local outer = new("Frame",BGui,{
        Size=UDim2.new(0,sz,0,sz),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=pos,
        BackgroundColor3=Color3.fromRGB(0,0,0),
        BackgroundTransparency=0.62,
        BorderSizePixel=0, ZIndex=10,
    })
    new("UICorner",outer,{CornerRadius=UDim.new(1,0)})
    local ostroke = new("UIStroke",outer,{Color=Color3.fromRGB(20,20,20),Thickness=2.2})

    -- invisible gap (purely visual spacing via size difference)
    local gap = new("Frame",outer,{
        Size=UDim2.new(0,sz-13,0,sz-13),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,0),
        BackgroundTransparency=1,
        BorderSizePixel=0, ZIndex=11,
    })
    new("UICorner",gap,{CornerRadius=UDim.new(1,0)})

    -- inner circle: black transparent
    local inner = new("Frame",outer,{
        Size=UDim2.new(0,sz-18,0,sz-18),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,0),
        BackgroundColor3=Color3.fromRGB(0,0,0),
        BackgroundTransparency=0.48,
        BorderSizePixel=0, ZIndex=12,
    })
    new("UICorner",inner,{CornerRadius=UDim.new(1,0)})

    -- label
    local lbl = new("TextLabel",inner,{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text=txt,
        TextColor3=tcol,
        Font=Enum.Font.GothamBold,
        TextScaled=true,
        ZIndex=13,
    })

    -- invisible touch button
    local btn = new("TextButton",outer,{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="", ZIndex=14,
    })
    new("UICorner",btn,{CornerRadius=UDim.new(1,0)})

    -- drag
    if draggable then
        local dg,ds,dp=false,nil,nil
        btn.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch
            or i.UserInputType==Enum.UserInputType.MouseButton1 then
                dg=true ds=i.Position dp=outer.Position
            end
        end)
        btn.InputChanged:Connect(function(i)
            if dg and (i.UserInputType==Enum.UserInputType.Touch
            or i.UserInputType==Enum.UserInputType.MouseMovement) then
                local d=i.Position-ds
                outer.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y)
            end
        end)
        btn.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch
            or i.UserInputType==Enum.UserInputType.MouseButton1 then dg=false end
        end)
    end

    -- press
    btn.MouseButton1Down:Connect(function()
        tween(outer,0.07,{Size=UDim2.new(0,sz*0.87,0,sz*0.87)})
    end)
    btn.MouseButton1Up:Connect(function()
        TweenSvc:Create(outer,TweenInfo.new(0.14,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
            Size=UDim2.new(0,sz,0,sz)
        }):Play()
    end)

    return {f=outer,btn=btn,lbl=lbl,inner=inner,stroke=ostroke}
end

-- SA toggle — draggable, left
local saBtn = makeBtn(78,UDim2.new(0.12,0,0.80,0),"SA\nOFF",Color3.fromRGB(255,75,55),true)

saBtn.btn.MouseButton1Up:Connect(function()
    saActive = not saActive
    if saActive then
        saBtn.lbl.Text      = "SA\nON"
        saBtn.lbl.TextColor3 = Color3.fromRGB(75,255,95)
        saBtn.inner.BackgroundColor3 = Color3.fromRGB(0,20,0)
        saBtn.stroke.Color  = Color3.fromRGB(0,95,0)
    else
        saBtn.lbl.Text      = "SA\nOFF"
        saBtn.lbl.TextColor3 = Color3.fromRGB(255,75,55)
        saBtn.inner.BackgroundColor3 = Color3.fromRGB(0,0,0)
        saBtn.stroke.Color  = Color3.fromRGB(20,20,20)
    end
end)

-- Knife — draggable, above SA
local kBtn = makeBtn(74,UDim2.new(0.12,0,0.67,0),"FACA",Color3.fromRGB(175,195,255),true)

kBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local t = getEquipped()
    if t and isKnife(t) then silentStab() end
end)

-- Gun — fixed, bottom right near jump
local gBtn = makeBtn(80,UDim2.new(0.88,0,0.88,0),"GUN",Color3.fromRGB(255,208,0),false)

gBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local t = getEquipped()
    if t and isGun(t) then silentGun() end
end)

-- glow on active weapon
task.spawn(function()
    while true do
        task.wait(0.1)
        local t = getEquipped()
        kBtn.stroke.Color = (saActive and t and isKnife(t))
            and Color3.fromRGB(75,95,255) or Color3.fromRGB(20,20,20)
        gBtn.stroke.Color = (saActive and t and isGun(t))
            and Color3.fromRGB(255,175,0) or Color3.fromRGB(20,20,20)
    end
end)

-- slide buttons in from bottom one by one
for i, b in ipairs({saBtn,kBtn,gBtn}) do
    local orig = b.f.Position
    b.f.Position = UDim2.new(orig.X.Scale,orig.X.Offset, orig.Y.Scale+0.35,orig.Y.Offset)
    task.delay((i-1)*0.1, function()
        TweenSvc:Create(b.f,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
            Position=orig,
        }):Play()
    end)
end
