-- Murderers vs Sheriffs | Silent Aim + Thunder Skin
-- script by tolopoofcpae / tolopo637883

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenSvc   = game:GetService("TweenService")
local UIS        = game:GetService("UserInputService")
local RS         = game:GetService("ReplicatedStorage")
local CS         = game:GetService("CollectionService")

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
if lp.Character then refreshChar(lp.Character) end
lp.CharacterAdded:Connect(refreshChar)

-- ================================================================
-- GAME HELPERS
-- ================================================================
local function getEquipped()
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function isKnife(t)
    if not t then return false end
    return t.Name == "Knife" or t:FindFirstChild("Slash") ~= nil
end

local function isGun(t)
    if not t then return false end
    return t.Name == "Gun" or t:FindFirstChild("Barrel") ~= nil
end

local function getNearestEnemy()
    if not hrp then return nil, nil end
    local bestChar, bestHRP, bd = nil, nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp then
            -- Ignore teammates
            if lp.Team and p.Team and lp.Team == p.Team and lp.Team.Name ~= "Players" then
            else
                local c = p.Character
                if c then
                    local h = c:FindFirstChildOfClass("Humanoid")
                    local r = c:FindFirstChild("HumanoidRootPart")
                    if h and r and h.Health > 0 and not c:FindFirstChildOfClass("ForceField") then
                        local d = (hrp.Position - r.Position).Magnitude
                        if d < bd then
                            bd = d
                            bestChar = c
                            bestHRP  = r
                        end
                    end
                end
            end
        end
    end
    return bestChar, bestHRP
end

-- ================================================================
-- SA STATE
-- ================================================================
local saActive  = false
local _bypass   = false
local _knifeCD  = false
local _gunCD    = false
local thunderOn = false

-- ================================================================
-- THUNDER SKIN (Visual only - client side)
-- ================================================================
local thunderKnobConn = nil
local thunderParticles = {}

local function clearThunderFX()
    for _, obj in pairs(thunderParticles) do
        pcall(function() obj:Destroy() end)
    end
    thunderParticles = {}
    if thunderKnobConn then
        thunderKnobConn:Disconnect()
        thunderKnobConn = nil
    end
end

local function applyThunderFX()
    clearThunderFX()
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    -- Cyan neon light
    local pl = Instance.new("PointLight")
    pl.Name       = "_Thunder_Light"
    pl.Color      = Color3.fromRGB(100, 220, 255)
    pl.Brightness = 5
    pl.Range      = 16
    pl.Parent     = handle
    table.insert(thunderParticles, pl)

    -- Electric particles
    local pe = Instance.new("ParticleEmitter")
    pe.Name         = "_Thunder_Emit"
    pe.Color        = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,  120, 255)),
    })
    pe.LightEmission = 1
    pe.Size         = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.22),
        NumberSequenceKeypoint.new(1, 0),
    })
    pe.Rate         = 22
    pe.Lifetime     = NumberRange.new(0.2, 0.5)
    pe.Speed        = NumberRange.new(2, 8)
    pe.SpreadAngle  = Vector2.new(180, 180)
    pe.Parent       = handle
    table.insert(thunderParticles, pe)

    -- Trail on the knife
    local att0 = Instance.new("Attachment")
    att0.Name = "_TrAtt0"
    att0.Position = Vector3.new(0, 0.5, 0)
    att0.Parent = handle

    local att1 = Instance.new("Attachment")
    att1.Name = "_TrAtt1"
    att1.Position = Vector3.new(0, -0.5, 0)
    att1.Parent = handle

    local trail = Instance.new("Trail")
    trail.Name         = "_Thunder_Trail"
    trail.Attachment0  = att0
    trail.Attachment1  = att1
    trail.Lifetime     = 0.12
    trail.MinLength    = 0
    trail.Color        = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 220, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,  50, 200)),
    })
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.Parent = handle
    table.insert(thunderParticles, att0)
    table.insert(thunderParticles, att1)
    table.insert(thunderParticles, trail)

    -- Watch for when tool is unequipped to re-apply
    thunderKnobConn = tool.Unequipping:Connect(function()
        clearThunderFX()
    end)
end

-- Monitor tool equip to apply thunder
local function watchEquip(c)
    c.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            if thunderOn then applyThunderFX() end
        end
    end)
end
if char then watchEquip(char) end
lp.CharacterAdded:Connect(function(c)
    refreshChar(c)
    _bypass = false _knifeCD = false _gunCD = false
    watchEquip(c)
end)

-- ================================================================
-- THUNDER KILL EFFECT (lightning bolt at death position)
-- ================================================================
local function spawnLightningAt(pos)
    local rng = Random.new()
    local model = Instance.new("Model")
    model.Parent = workspace

    -- Build zigzag lightning
    local curPos = pos + Vector3.new(0, 18, 0)
    local segLen = 2.2
    local segs   = 14
    local col    = Color3.fromRGB(80, 200, 255)

    for _ = 1, segs do
        local part = Instance.new("Part")
        part.Anchored   = true
        part.CanCollide = false
        part.CanTouch   = false
        part.CastShadow = false
        part.Material   = Enum.Material.Neon
        part.Color      = col
        part.Size       = Vector3.new(0.1, 0.1, segLen)
        part.Transparency = 0.2
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth

        local ox = (rng:NextNumber() - 0.5) * 2.5
        local oz = (rng:NextNumber() - 0.5) * 2.5
        local nextPos = curPos + Vector3.new(ox, -segLen, oz)
        part.CFrame = CFrame.lookAt(curPos, nextPos) * CFrame.new(0, 0, -segLen/2)
        part.Parent = model
        curPos = nextPos

        -- Fade out
        TweenSvc:Create(part, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {
            Transparency = 1,
            Size = Vector3.new(0.01, 0.01, segLen),
        }):Play()
    end

    -- Bright flash at top
    local flash = Instance.new("Part")
    flash.Anchored = true
    flash.CanCollide = false
    flash.CanTouch = false
    flash.Transparency = 0.5
    flash.Size = Vector3.new(0.1, 0.1, 0.1)
    flash.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
    flash.Parent = model

    local pl = Instance.new("PointLight", flash)
    pl.Color      = Color3.fromRGB(80, 200, 255)
    pl.Brightness = 30
    pl.Range      = 28

    TweenSvc:Create(pl, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
        Brightness = 0, Range = 0,
    }):Play()

    -- Explosion particles (using the game's effects folder)
    pcall(function()
        local expPart = RS.ExplosionPart:Clone()
        expPart.Position = pos
        expPart.Parent = workspace
        expPart.Primary:Emit(25)
        expPart.Secondary:Emit(25)
        task.delay(0.15, function()
            expPart.Primary:Emit(15)
        end)
        game:GetService("Debris"):AddItem(expPart, 4)
    end)

    game:GetService("Debris"):AddItem(model, 1.5)
end

-- Hook ALL enemies for death to trigger thunder
local killTargets = {}

local function trackEnemy(p)
    p.CharacterAdded:Connect(function(c)
        local h = c:WaitForChild("Humanoid")
        local r = c:WaitForChild("HumanoidRootPart")
        h.Died:Connect(function()
            if thunderOn and killTargets[p] then
                local pos = r.Position
                killTargets[p] = nil
                task.spawn(function()
                    spawnLightningAt(pos)
                end)
            end
        end)
    end)
    if p.Character then
        local h = p.Character:FindFirstChildOfClass("Humanoid")
        local r = p.Character:FindFirstChild("HumanoidRootPart")
        if h and r then
            h.Died:Connect(function()
                if thunderOn and killTargets[p] then
                    local pos = r.Position
                    killTargets[p] = nil
                    task.spawn(function()
                        spawnLightningAt(pos)
                    end)
                end
            end)
        end
    end
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= lp then trackEnemy(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= lp then trackEnemy(p) end
end)

-- ================================================================
-- SILENT KNIFE
-- Knife uses server-side Touched detection.
-- We warp next to enemy → Touch registers → warp back.
-- ================================================================
local function silentKnife()
    if _knifeCD then return end
    local _, target = getNearestEnemy()
    if not target or not hrp then return end
    _knifeCD = true

    local origCF = hrp.CFrame
    pcall(function()
        hrp.CFrame = target.CFrame * CFrame.new(0, 0, 2.2)
        task.wait(0.05)
        hrp.CFrame = target.CFrame * CFrame.new(0, 0, 2)
        task.wait(0.05)
    end)
    task.delay(0.14, function()
        pcall(function()
            if hrp then hrp.CFrame = origCF end
        end)
    end)

    -- Mark this target for thunder kill effect
    local tc, th = getNearestEnemy()
    if tc then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lp and p.Character == tc then
                killTargets[p] = true
                break
            end
        end
    end

    task.delay(1.1, function() _knifeCD = false end)
end

-- ================================================================
-- SILENT GUN
-- Hook __namecall to redirect any gun FireServer position args
-- to the nearest enemy's position.
-- ================================================================
local function silentGun()
    if _gunCD then return end
    local _, target = getNearestEnemy()
    if not target or not hrp then return end
    _gunCD = true

    local tool = getEquipped()
    if not tool then _gunCD = false return end

    -- Try common gun remotes
    local rem = tool:FindFirstChildOfClass("RemoteEvent")
    if rem then
        _bypass = true
        pcall(function()
            rem:FireServer(target.Position)
        end)
        _bypass = false
    end

    -- Mark target for thunder
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r and (r.Position - target.Position).Magnitude < 1 then
                killTargets[p] = true
                break
            end
        end
    end

    task.delay(0.5, function() _gunCD = false end)
end

-- ================================================================
-- __namecall hook - block normal input when SA on,
-- AND redirect gun fire positions to nearest enemy
-- ================================================================
pcall(function()
    local oldNC
    oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()

        -- Redirect gun/throw positions while SA is active
        if saActive and not _bypass then
            if method == "FireServer" or method == "InvokeServer" then
                if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                    -- Block knife throw & existing gun calls so only our buttons work
                    local name = self.Name
                    if name == "ThrowConfirmation" or name == "ReplicateBullet" then
                        return
                    end
                    -- If it's a tool's own RemoteEvent, block it
                    local tool = getEquipped()
                    if tool then
                        local re = tool:FindFirstChildOfClass("RemoteEvent")
                        if re and re == self then
                            return
                        end
                    end
                end
            end
        end

        return oldNC(self, ...)
    end))
end)

-- ================================================================
-- HELPERS
-- ================================================================
local function tw(obj, t, props, style, dir)
    TweenSvc:Create(obj,
        TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props):Play()
end

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
-- ================================================================
-- 1. LOADING SCREEN
-- ================================================================
-- ================================================================
local LoadGui = make("ScreenGui", {
    Name="MVS_Load", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=9999,
}, pgui)

local LBG = make("Frame", {
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(3,3,10),
    BorderSizePixel=0,
}, LoadGui)

-- Animated gradient
local gradF = make("Frame", {
    Size=UDim2.new(4,0,1,0), Position=UDim2.new(-1.5,0,0,0),
    BackgroundTransparency=1, BorderSizePixel=0, ZIndex=2,
}, LBG)
local gradUG = make("UIGradient", {
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(3,3,10)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(0,18,55)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,50,120)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(0,18,55)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(3,3,10)),
    }),
    Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.92),
        NumberSequenceKeypoint.new(0.5,0.2),
        NumberSequenceKeypoint.new(1,0.92),
    }),
}, gradF)
task.spawn(function()
    local t = 0
    while LoadGui.Parent do
        t = t + 0.007
        gradF.Position = UDim2.new(-1.5+math.sin(t)*0.45, 0, 0, 0)
        gradUG.Rotation = math.sin(t*0.45)*28
        RunService.RenderStepped:Wait()
    end
end)

-- Scan lines
for i = 1, 24 do
    make("Frame",{
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,i/24,0),
        BackgroundColor3=Color3.fromRGB(0,100,228),
        BackgroundTransparency=0.88, BorderSizePixel=0, ZIndex=3,
    }, LBG)
end

-- Particles
local function spawnDot()
    local s = math.random(4,13)
    local px = math.random(5,95)/100
    local d = make("Frame",{
        Size=UDim2.new(0,s,0,s), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(px,0,1.1,0),
        BackgroundColor3=Color3.fromRGB(math.random(0,30),math.random(100,195),255),
        BackgroundTransparency=math.random(42,72)/100,
        BorderSizePixel=0, ZIndex=4,
    }, LBG)
    make("UICorner",{CornerRadius=UDim.new(1,0)},d)
    local t2 = TweenSvc:Create(d,TweenInfo.new(math.random(28,52)/10,Enum.EasingStyle.Linear),{
        Position=UDim2.new(px+(math.random()-0.5)*0.2,0,-0.12,0),
        BackgroundTransparency=1,
    })
    t2:Play()
    t2.Completed:Connect(function() d:Destroy() end)
end
task.spawn(function()
    while LoadGui.Parent do
        spawnDot()
        task.wait(math.random(8,20)/100)
    end
end)

-- Corner brackets
for _, cv in pairs({
    {Vector2.new(0,0),UDim2.new(0,12,0,12)},
    {Vector2.new(1,0),UDim2.new(1,-12,0,12)},
    {Vector2.new(0,1),UDim2.new(0,12,1,-12)},
    {Vector2.new(1,1),UDim2.new(1,-12,1,-12)},
}) do
    local f = make("Frame",{
        Size=UDim2.new(0,52,0,52), AnchorPoint=cv[1], Position=cv[2],
        BackgroundTransparency=1, BorderSizePixel=0, ZIndex=5,
    }, LBG)
    local st = make("UIStroke",{Color=Color3.fromRGB(0,138,255),Thickness=2},f)
    TweenSvc:Create(st,TweenInfo.new(1.2,Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,-1,true),{Transparency=0.88}):Play()
end

-- Center card
local card = make("Frame",{
    Size=UDim2.new(0,490,0,275),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,1.7,0),
    BackgroundColor3=Color3.fromRGB(4,8,22),
    BackgroundTransparency=0.14,
    BorderSizePixel=0, ZIndex=6,
}, LBG)
make("UICorner",{CornerRadius=UDim.new(0,18)},card)
make("UIStroke",{Color=Color3.fromRGB(0,142,255),Thickness=1.8,Transparency=0.1},card)

local cardGrad = make("UIGradient",{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,12,35)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,28,65)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,12,35)),
    }), Rotation=100,
}, card)
task.spawn(function()
    local t = 0
    while LoadGui.Parent do
        t = t+0.012
        cardGrad.Rotation = 100+math.sin(t)*25
        RunService.RenderStepped:Wait()
    end
end)

local accLine = make("Frame",{
    Size=UDim2.new(0,0,0,3), AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,182,255),
    BorderSizePixel=0, ZIndex=7,
}, card)
make("UICorner",{CornerRadius=UDim.new(0,2)},accLine)

local function cLbl(parent,text,ypos,tsz,col,fnt)
    return make("TextLabel",{
        Size=UDim2.new(1,-28,0,tsz+6), Position=UDim2.new(0,14,0,ypos),
        BackgroundTransparency=1, Text=text,
        TextColor3=col or Color3.fromRGB(255,255,255),
        Font=fnt or Enum.Font.Gotham, TextSize=tsz,
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=7,
    }, parent)
end

cLbl(card,"Murderers vs Sheriffs  •  EXCLUSIVE  •  DELTA",
    13,11,Color3.fromRGB(0,158,255))

local titleLbl = cLbl(card,"",36,42,Color3.fromRGB(255,255,255),Enum.Font.GothamBlack)
local titleGrad = make("UIGradient",{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,198,255)),
        ColorSequenceKeypoint.new(0.45,Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,198,255)),
    }),
}, titleLbl)
make("UIStroke",{Color=Color3.fromRGB(0,148,255),Thickness=1.6,Transparency=0.5},titleLbl)
task.spawn(function()
    local t=0
    while LoadGui.Parent do
        t=t+0.015
        titleGrad.Rotation=math.sin(t)*16
        RunService.RenderStepped:Wait()
    end
end)

cLbl(card,"SILENT AIM  +  THUNDER SKIN",98,15,
    Color3.fromRGB(68,152,255),Enum.Font.GothamBold)

local divLine = make("Frame",{
    Size=UDim2.new(0,0,0,1), Position=UDim2.new(0.08,0,0,134),
    BackgroundColor3=Color3.fromRGB(0,138,255),
    BackgroundTransparency=0.4, BorderSizePixel=0, ZIndex=7,
}, card)

cLbl(card,"script by tolopoofcpae / tolopo637883",
    144,12,Color3.fromRGB(102,168,255))

local statusLbl = cLbl(card,"Inicializando...",168,11,Color3.fromRGB(48,122,255))

local pbBG = make("Frame",{
    Size=UDim2.new(0.84,0,0,7), Position=UDim2.new(0.08,0,0,194),
    BackgroundColor3=Color3.fromRGB(5,15,36),
    BorderSizePixel=0, ZIndex=7,
}, card)
make("UICorner",{CornerRadius=UDim.new(1,0)},pbBG)

local pbFill = make("Frame",{
    Size=UDim2.new(0,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,182,255),
    BorderSizePixel=0, ZIndex=8,
}, pbBG)
make("UICorner",{CornerRadius=UDim.new(1,0)},pbFill)
make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,108,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(128,232,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,182,255)),
})}, pbFill)

cLbl(card,"v1.0  •  THUNDER KILL FX  •  MOBILE",
    216,10,Color3.fromRGB(26,55,110))

-- Slide card up
TweenSvc:Create(card,TweenInfo.new(0.82,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
    {Position=UDim2.new(0.5,0,0.5,0)}):Play()

task.spawn(function()
    task.wait(0.48)
    tw(accLine,0.9,{Size=UDim2.new(0.8,0,0,3)},Enum.EasingStyle.Cubic)
    tw(divLine, 1.1,{Size=UDim2.new(0.84,0,0,1)},Enum.EasingStyle.Cubic)
end)
task.spawn(function()
    task.wait(0.55)
    local txt = "MVS Silent Aim"
    for i = 1, #txt do
        titleLbl.Text = string.sub(txt,1,i)
        task.wait(0.06)
    end
end)
task.spawn(function()
    local stages = {
        {0.18,"Carregando hooks..."},
        {0.36,"Verificando remotes..."},
        {0.52,"Analisando skins..."},
        {0.70,"Preparando thunder kill fx..."},
        {0.85,"Botoes mobile prontos..."},
        {0.96,"Quase la..."},
        {1.00,"Pronto!"},
    }
    task.wait(0.3)
    for _, s in pairs(stages) do
        task.wait(0.44)
        statusLbl.Text = s[2]
        tw(pbFill,0.36,{Size=UDim2.new(s[1],0,1,0)},Enum.EasingStyle.Cubic)
    end
end)

task.wait(4.6)

local fadeOut = make("Frame",{
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=1,
    BorderSizePixel=0, ZIndex=500,
}, LoadGui)
tw(fadeOut,0.55,{BackgroundTransparency=0},Enum.EasingStyle.Linear)
task.wait(0.6)
LoadGui:Destroy()

-- ================================================================
-- ================================================================
-- 2. KEY GUI
-- ================================================================
-- ================================================================
local CORRECT_KEY = "TopoOp-ofc_mohd"
local keyOK = false

local KeyGui = make("ScreenGui",{
    Name="MVS_Key", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=8000,
}, pgui)

local kDim = make("Frame",{
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=0.52, BorderSizePixel=0,
}, KeyGui)

local kPanel = make("Frame",{
    Size=UDim2.new(0,408,0,305),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,1.8,0),
    BackgroundColor3=Color3.fromRGB(4,8,22),
    BackgroundTransparency=0.04,
    BorderSizePixel=0, ZIndex=2,
}, KeyGui)
make("UICorner",{CornerRadius=UDim.new(0,20)},kPanel)
local kpStroke = make("UIStroke",{Color=Color3.fromRGB(0,148,255),Thickness=2},kPanel)

local kPG = make("UIGradient",{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,10,30)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,26,58)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,10,30)),
    }), Rotation=112,
}, kPanel)
task.spawn(function()
    local t = 0
    while KeyGui.Parent do
        t = t+0.013
        kPG.Rotation = 112+math.sin(t)*20
        RunService.RenderStepped:Wait()
    end
end)

local kTopGlow = make("Frame",{
    Size=UDim2.new(0.65,0,0,3),
    AnchorPoint=Vector2.new(0.5,0), Position=UDim2.new(0.5,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,198,255),
    BorderSizePixel=0, ZIndex=3,
}, kPanel)
make("UICorner",{CornerRadius=UDim.new(1,0)},kTopGlow)
TweenSvc:Create(kTopGlow,TweenInfo.new(1.25,Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,-1,true),
    {BackgroundColor3=Color3.fromRGB(0,82,198)}):Play()

local lockCircle = make("Frame",{
    Size=UDim2.new(0,50,0,50), AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,14),
    BackgroundColor3=Color3.fromRGB(0,34,84),
    BackgroundTransparency=0.22, BorderSizePixel=0, ZIndex=3,
}, kPanel)
make("UICorner",{CornerRadius=UDim.new(1,0)},lockCircle)
make("UIStroke",{Color=Color3.fromRGB(0,136,255),Thickness=1.5},lockCircle)
make("TextLabel",{
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text="[KEY]", TextSize=16, Font=Enum.Font.GothamBlack,
    TextColor3=Color3.fromRGB(0,200,255), ZIndex=4,
}, lockCircle)

local function kLabel(txt,y,sz,col,fnt)
    return make("TextLabel",{
        Size=UDim2.new(1,-28,0,sz+4), Position=UDim2.new(0,14,0,y),
        BackgroundTransparency=1, Text=txt,
        TextColor3=col or Color3.fromRGB(72,145,218),
        Font=fnt or Enum.Font.Gotham, TextSize=sz,
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=3,
    }, kPanel)
end

local kTitleLbl = kLabel("Murderers vs Sheriffs",76,20,
    Color3.fromRGB(255,255,255),Enum.Font.GothamBlack)
local kTitleGrad = make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,194,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(198,238,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,194,255)),
})}, kTitleLbl)
task.spawn(function()
    local t=0
    while KeyGui.Parent do
        t=t+0.017
        kTitleGrad.Rotation=math.sin(t)*13
        RunService.RenderStepped:Wait()
    end
end)

kLabel("Insira a key para continuar",108,13)
kLabel("Pega a key gratis no  scriptblox.com",126,11,Color3.fromRGB(42,98,178))

local iBG = make("Frame",{
    Size=UDim2.new(1,-38,0,46), Position=UDim2.new(0,19,0,150),
    BackgroundColor3=Color3.fromRGB(0,12,33),
    BorderSizePixel=0, ZIndex=3,
}, kPanel)
make("UICorner",{CornerRadius=UDim.new(0,10)},iBG)
local iStroke = make("UIStroke",{Color=Color3.fromRGB(0,92,198),Thickness=1.5},iBG)

local tbox = make("TextBox",{
    Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,7,0,0),
    BackgroundTransparency=1, Text="",
    PlaceholderText="Cole a key aqui...",
    PlaceholderColor3=Color3.fromRGB(38,72,126),
    TextColor3=Color3.fromRGB(182,222,255),
    Font=Enum.Font.GothamBold, TextSize=15,
    ClearTextOnFocus=false, ZIndex=4,
}, iBG)

tbox.Focused:Connect(function()
    tw(iStroke,0.16,{Color=Color3.fromRGB(0,198,255),Thickness=2})
end)
tbox.FocusLost:Connect(function()
    tw(iStroke,0.16,{Color=Color3.fromRGB(0,92,198),Thickness=1.5})
end)

local errLbl = kLabel("",205,12,Color3.fromRGB(255,72,72),Enum.Font.GothamBold)

local confBtn = make("TextButton",{
    Size=UDim2.new(1,-38,0,44), Position=UDim2.new(0,19,0,228),
    Text="CONFIRMAR KEY",
    TextColor3=Color3.fromRGB(255,255,255),
    Font=Enum.Font.GothamBlack, TextSize=15,
    BackgroundColor3=Color3.fromRGB(0,76,198),
    BorderSizePixel=0, ZIndex=3,
}, kPanel)
make("UICorner",{CornerRadius=UDim.new(0,10)},confBtn)
make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,96,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,54,190)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,96,255)),
}),Rotation=90}, confBtn)
make("UIStroke",{Color=Color3.fromRGB(0,155,255)},confBtn)

confBtn.MouseButton1Down:Connect(function()
    tw(confBtn,0.07,{Size=UDim2.new(1,-46,0,41),Position=UDim2.new(0,23,0,230)})
end)

local function doValidate()
    tw(confBtn,0.1,{Size=UDim2.new(1,-38,0,44),Position=UDim2.new(0,19,0,228)})
    local entered = string.gsub(tbox.Text,"%s","")
    if entered == CORRECT_KEY then
        keyOK = true
        confBtn.Text = "KEY CORRETA!"
        confBtn.BackgroundColor3 = Color3.fromRGB(0,148,52)
        errLbl.Text = ""
        task.delay(0.25,function()
            TweenSvc:Create(kPanel,TweenInfo.new(0.5,Enum.EasingStyle.Back,
                Enum.EasingDirection.In),{Position=UDim2.new(0.5,0,1.8,0)}):Play()
            tw(kDim,0.5,{BackgroundTransparency=1})
            task.delay(0.55,function() KeyGui:Destroy() end)
        end)
    else
        errLbl.Text = "Key incorreta. Tente novamente."
        tw(iStroke,0.1,{Color=Color3.fromRGB(255,46,46)})
        task.delay(0.6,function() tw(iStroke,0.2,{Color=Color3.fromRGB(0,92,198)}) end)
        local orig = kPanel.Position
        task.spawn(function()
            for _, ox in pairs({-10,10,-8,8,-5,5,0}) do
                TweenSvc:Create(kPanel,TweenInfo.new(0.04),
                    {Position=UDim2.new(0.5,ox,0.5,0)}):Play()
                task.wait(0.045)
            end
            kPanel.Position = orig
        end)
    end
end

confBtn.MouseButton1Up:Connect(doValidate)
tbox.FocusLost:Connect(function(enter) if enter then doValidate() end end)

TweenSvc:Create(kPanel,TweenInfo.new(0.76,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
    {Position=UDim2.new(0.5,0,0.5,0)}):Play()

repeat task.wait(0.1) until keyOK

-- ================================================================
-- ================================================================
-- 3. MENU GUI
-- ================================================================
-- ================================================================
local MenuGui = make("ScreenGui",{
    Name="MVS_Menu", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=600,
}, pgui)

local menuPanel = make("Frame",{
    Size=UDim2.new(0,272,0,330),
    AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(-0.35,0,0.5,0),
    BackgroundColor3=Color3.fromRGB(2,5,16),
    BackgroundTransparency=0.08,
    BorderSizePixel=0, ZIndex=2,
}, MenuGui)
make("UICorner",{CornerRadius=UDim.new(0,16)},menuPanel)
local mpStroke = make("UIStroke",{
    Color=Color3.fromRGB(0,200,255),Thickness=1.5,Transparency=0.1,
}, menuPanel)

-- Scan lines on panel
for i = 1, 18 do
    make("Frame",{
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,i/18,0),
        BackgroundColor3=Color3.fromRGB(0,150,255),
        BackgroundTransparency=0.92,
        BorderSizePixel=0, ZIndex=3,
    }, menuPanel)
end

-- Animated panel gradient
local mpGrad = make("UIGradient",{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,4,16)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0,22,52)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0,40,86)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,4,16)),
    }),
    Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.1),
        NumberSequenceKeypoint.new(0.5,0),
        NumberSequenceKeypoint.new(1,0.1),
    }), Rotation=85,
}, menuPanel)

task.spawn(function()
    local t=0
    while MenuGui.Parent do
        t=t+0.01
        mpGrad.Rotation=85+math.sin(t)*30
        mpStroke.Transparency=0.1+math.sin(t*2)*0.08
        RunService.RenderStepped:Wait()
    end
end)

-- Moving scan line (tech effect)
local techLine = make("Frame",{
    Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,200,255),
    BackgroundTransparency=0.3,
    BorderSizePixel=0, ZIndex=4,
}, menuPanel)
make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,220,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,0,0)),
})}, techLine)
task.spawn(function()
    while MenuGui.Parent do
        TweenSvc:Create(techLine,TweenInfo.new(1.8,Enum.EasingStyle.Sine),
            {Position=UDim2.new(0,0,1.02,0)}):Play()
        task.wait(1.8)
        techLine.Position = UDim2.new(0,0,-0.02,0)
        task.wait(0.05)
    end
end)

-- Top accent (pulsing)
local mpTop = make("Frame",{
    Size=UDim2.new(0.7,0,0,3),
    AnchorPoint=Vector2.new(0.5,0), Position=UDim2.new(0.5,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,200,255),
    BorderSizePixel=0, ZIndex=5,
}, menuPanel)
make("UICorner",{CornerRadius=UDim.new(1,0)},mpTop)
TweenSvc:Create(mpTop,TweenInfo.new(1.4,Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,-1,true),
    {BackgroundColor3=Color3.fromRGB(0,80,200)}):Play()

local function mpLbl(txt,y,sz,col,fnt)
    return make("TextLabel",{
        Size=UDim2.new(1,-20,0,sz+4), Position=UDim2.new(0,10,0,y),
        BackgroundTransparency=1, Text=txt,
        TextColor3=col or Color3.fromRGB(200,235,255),
        Font=fnt or Enum.Font.Gotham, TextSize=sz,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5,
    }, menuPanel)
end

mpLbl("MVS  HUB",14,16,Color3.fromRGB(255,255,255),Enum.Font.GothamBlack)
mpLbl("SKINS  +  EFEITOS",34,11,Color3.fromRGB(0,180,255))

-- Divider
make("Frame",{
    Size=UDim2.new(0.9,0,0,1), Position=UDim2.new(0.05,0,0,52),
    BackgroundColor3=Color3.fromRGB(0,160,255),
    BackgroundTransparency=0.5, BorderSizePixel=0, ZIndex=5,
}, menuPanel)

-- Thunder toggle row
local thunderRow = make("Frame",{
    Size=UDim2.new(1,-20,0,52), Position=UDim2.new(0,10,0,60),
    BackgroundColor3=Color3.fromRGB(0,12,35),
    BackgroundTransparency=0.3, BorderSizePixel=0, ZIndex=5,
}, menuPanel)
make("UICorner",{CornerRadius=UDim.new(0,10)},thunderRow)
make("UIStroke",{Color=Color3.fromRGB(0,120,220),Thickness=1},thunderRow)

make("TextLabel",{
    Size=UDim2.new(0.62,0,0,26), Position=UDim2.new(0,12,0,4),
    BackgroundTransparency=1, Text="Skin Trovao",
    TextColor3=Color3.fromRGB(0,220,255),
    Font=Enum.Font.GothamBold, TextSize=14,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
}, thunderRow)
make("TextLabel",{
    Size=UDim2.new(0.62,0,0,18), Position=UDim2.new(0,12,0,28),
    BackgroundTransparency=1, Text="Faca + efeito morte trovao",
    TextColor3=Color3.fromRGB(55,115,185),
    Font=Enum.Font.Gotham, TextSize=11,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
}, thunderRow)

-- Toggle switch
local togBG = make("Frame",{
    Size=UDim2.new(0,48,0,26),
    AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
    BackgroundColor3=Color3.fromRGB(28,28,48),
    BorderSizePixel=0, ZIndex=6,
}, thunderRow)
make("UICorner",{CornerRadius=UDim.new(1,0)},togBG)
make("UIStroke",{Color=Color3.fromRGB(80,80,120),Thickness=1},togBG)

local togKnob = make("Frame",{
    Size=UDim2.new(0,20,0,20),
    AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,3,0.5,0),
    BackgroundColor3=Color3.fromRGB(120,120,160),
    BorderSizePixel=0, ZIndex=7,
}, togBG)
make("UICorner",{CornerRadius=UDim.new(1,0)},togKnob)

local togBtn = make("TextButton",{
    Size=UDim2.new(1,0,1,0),
    BackgroundTransparency=1, Text="", ZIndex=8,
}, thunderRow)

togBtn.MouseButton1Up:Connect(function()
    thunderOn = not thunderOn
    if thunderOn then
        tw(togBG,0.2,{BackgroundColor3=Color3.fromRGB(0,45,95)})
        tw(togKnob,0.2,{
            Position=UDim2.new(1,-23,0.5,0),
            BackgroundColor3=Color3.fromRGB(0,200,255),
        })
        applyThunderFX()
    else
        tw(togBG,0.2,{BackgroundColor3=Color3.fromRGB(28,28,48)})
        tw(togKnob,0.2,{
            Position=UDim2.new(0,3,0.5,0),
            BackgroundColor3=Color3.fromRGB(120,120,160),
        })
        clearThunderFX()
    end
end)

local skinStatusLbl = mpLbl("Status: Desativado",122,11,Color3.fromRGB(80,100,140))
task.spawn(function()
    while MenuGui.Parent do
        if thunderOn then
            skinStatusLbl.Text = "Status: TROVAO ATIVO"
            skinStatusLbl.TextColor3 = Color3.fromRGB(0,220,255)
        else
            skinStatusLbl.Text = "Status: Desativado"
            skinStatusLbl.TextColor3 = Color3.fromRGB(80,100,140)
        end
        task.wait(0.3)
    end
end)

-- Info divider
make("Frame",{
    Size=UDim2.new(0.9,0,0,1), Position=UDim2.new(0.05,0,0,142),
    BackgroundColor3=Color3.fromRGB(0,100,180),
    BackgroundTransparency=0.6, BorderSizePixel=0, ZIndex=5,
}, menuPanel)

mpLbl("SILENT AIM",150,14,Color3.fromRGB(255,255,255),Enum.Font.GothamBlack)
mpLbl("SA  = Ativar / Desativar",168,11,Color3.fromRGB(100,180,255))
mpLbl("FACA = Slash no mais perto",184,11,Color3.fromRGB(100,180,255))
mpLbl("GUN  = Atira no mais perto",200,11,Color3.fromRGB(100,180,255))

make("Frame",{
    Size=UDim2.new(0.9,0,0,1), Position=UDim2.new(0.05,0,0,218),
    BackgroundColor3=Color3.fromRGB(0,100,180),
    BackgroundTransparency=0.6, BorderSizePixel=0, ZIndex=5,
}, menuPanel)

mpLbl("SKIN TROVAO:",226,11,Color3.fromRGB(0,200,255))
mpLbl("Requer skin padrao equipada",242,11,Color3.fromRGB(55,105,155))
mpLbl("Particulas + luz + trail na faca",258,11,Color3.fromRGB(55,105,155))
mpLbl("Raio ao matar com SA ativo",274,11,Color3.fromRGB(55,105,155))
mpLbl("v1.0  by tolopoofcpae / tolopo637883",298,10,Color3.fromRGB(30,60,110))

-- Close button
local closeBtn = make("TextButton",{
    Size=UDim2.new(0,26,0,26), AnchorPoint=Vector2.new(1,0),
    Position=UDim2.new(1,-7,0,7),
    Text="X", TextColor3=Color3.fromRGB(180,80,80),
    Font=Enum.Font.GothamBlack, TextSize=12,
    BackgroundColor3=Color3.fromRGB(28,8,8),
    BackgroundTransparency=0.3, BorderSizePixel=0, ZIndex=8,
}, menuPanel)
make("UICorner",{CornerRadius=UDim.new(1,0)},closeBtn)
make("UIStroke",{Color=Color3.fromRGB(180,55,55),Thickness=1},closeBtn)

local menuShowing = false
local function toggleMenu()
    menuShowing = not menuShowing
    if menuShowing then
        menuPanel.Visible = true
        TweenSvc:Create(menuPanel,TweenInfo.new(0.4,Enum.EasingStyle.Back,
            Enum.EasingDirection.Out),{Position=UDim2.new(0.01,0,0.5,0)}):Play()
    else
        TweenSvc:Create(menuPanel,TweenInfo.new(0.3,Enum.EasingStyle.Back,
            Enum.EasingDirection.In),{Position=UDim2.new(-0.35,0,0.5,0)}):Play()
        task.delay(0.35,function() menuPanel.Visible = false end)
    end
end

menuPanel.Visible = false
closeBtn.MouseButton1Up:Connect(toggleMenu)

-- ================================================================
-- ================================================================
-- 4. BUTTONS
-- ================================================================
-- ================================================================
local BGui = make("ScreenGui",{
    Name="MVS_Btns", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=500,
}, pgui)

local function makeBtn(sz, pos, label, textColor, draggable)
    local outer = make("Frame",{
        Size=UDim2.new(0,sz,0,sz),
        AnchorPoint=Vector2.new(0.5,0.5), Position=pos,
        BackgroundColor3=Color3.fromRGB(0,0,0),
        BackgroundTransparency=0.62,
        BorderSizePixel=0, ZIndex=10,
    }, BGui)
    make("UICorner",{CornerRadius=UDim.new(1,0)},outer)
    local ost = make("UIStroke",{Color=Color3.fromRGB(20,20,20),Thickness=2.2},outer)

    -- Gap (transparent ring)
    local gap = make("Frame",{
        Size=UDim2.new(0,sz-13,0,sz-13),
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
        BackgroundTransparency=1, BorderSizePixel=0, ZIndex=11,
    }, outer)
    make("UICorner",{CornerRadius=UDim.new(1,0)},gap)

    local inner = make("Frame",{
        Size=UDim2.new(0,sz-18,0,sz-18),
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
        BackgroundColor3=Color3.fromRGB(0,0,0),
        BackgroundTransparency=0.48,
        BorderSizePixel=0, ZIndex=12,
    }, outer)
    make("UICorner",{CornerRadius=UDim.new(1,0)},inner)

    local lbl = make("TextLabel",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text=label, TextColor3=textColor,
        Font=Enum.Font.GothamBold, TextScaled=true, ZIndex=13,
    }, inner)

    local btn = make("TextButton",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text="", ZIndex=14,
    }, outer)
    make("UICorner",{CornerRadius=UDim.new(1,0)},btn)

    if draggable then
        local dg, ds, dp = false, nil, nil
        btn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch
            or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dg=true ds=inp.Position dp=outer.Position
            end
        end)
        btn.InputChanged:Connect(function(inp)
            if dg and (inp.UserInputType == Enum.UserInputType.Touch
            or inp.UserInputType == Enum.UserInputType.MouseMovement) then
                local d = inp.Position - ds
                outer.Position = UDim2.new(
                    dp.X.Scale, dp.X.Offset+d.X,
                    dp.Y.Scale, dp.Y.Offset+d.Y)
            end
        end)
        btn.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch
            or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dg=false
            end
        end)
    end

    btn.MouseButton1Down:Connect(function()
        tw(outer,0.07,{Size=UDim2.new(0,sz*0.87,0,sz*0.87)})
    end)
    btn.MouseButton1Up:Connect(function()
        TweenSvc:Create(outer,TweenInfo.new(0.14,Enum.EasingStyle.Back,
            Enum.EasingDirection.Out),{Size=UDim2.new(0,sz,0,sz)}):Play()
    end)

    return {f=outer, btn=btn, lbl=lbl, inner=inner, stroke=ost}
end

-- HUB button (draggable, top-left)
local hubBtn = makeBtn(54, UDim2.new(0.06,0,0.54,0),
    "HUB", Color3.fromRGB(0,200,255), true)
hubBtn.btn.MouseButton1Up:Connect(toggleMenu)
TweenSvc:Create(hubBtn.f, TweenInfo.new(1.5,Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=0.42}):Play()

-- SA toggle (draggable, left)
local saBtn = makeBtn(78, UDim2.new(0.12,0,0.80,0),
    "SA\nOFF", Color3.fromRGB(255,72,50), true)
saBtn.btn.MouseButton1Up:Connect(function()
    saActive = not saActive
    if saActive then
        saBtn.lbl.Text = "SA\nON"
        saBtn.lbl.TextColor3 = Color3.fromRGB(72,255,92)
        saBtn.inner.BackgroundColor3 = Color3.fromRGB(0,20,0)
        saBtn.stroke.Color = Color3.fromRGB(0,92,0)
    else
        saBtn.lbl.Text = "SA\nOFF"
        saBtn.lbl.TextColor3 = Color3.fromRGB(255,72,50)
        saBtn.inner.BackgroundColor3 = Color3.fromRGB(0,0,0)
        saBtn.stroke.Color = Color3.fromRGB(20,20,20)
    end
end)

-- Knife slash (draggable, above SA)
local kBtn = makeBtn(74, UDim2.new(0.12,0,0.67,0),
    "FACA", Color3.fromRGB(172,195,255), true)
kBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local tool = getEquipped()
    if tool and isKnife(tool) then silentKnife() end
end)

-- Gun (fixed, bottom-right)
local gBtn = makeBtn(80, UDim2.new(0.88,0,0.88,0),
    "GUN", Color3.fromRGB(255,205,0), false)
gBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local tool = getEquipped()
    if tool and isGun(tool) then silentGun() end
end)

-- Glow active weapon button
task.spawn(function()
    while true do
        task.wait(0.1)
        local tool = getEquipped()
        if saActive and tool and isKnife(tool) then
            kBtn.stroke.Color = Color3.fromRGB(72,92,255)
        else
            kBtn.stroke.Color = Color3.fromRGB(20,20,20)
        end
        if saActive and tool and isGun(tool) then
            gBtn.stroke.Color = Color3.fromRGB(255,172,0)
        else
            gBtn.stroke.Color = Color3.fromRGB(20,20,20)
        end
        if thunderOn then
            hubBtn.stroke.Color = Color3.fromRGB(0,200,255)
        else
            hubBtn.stroke.Color = Color3.fromRGB(20,20,20)
        end
    end
end)

-- Slide buttons in from bottom
do
    local allBtns = {saBtn, kBtn, gBtn, hubBtn}
    for i = 1, #allBtns do
        local b    = allBtns[i]
        local orig = b.f.Position
        b.f.Position = UDim2.new(
            orig.X.Scale, orig.X.Offset,
            orig.Y.Scale + 0.35, orig.Y.Offset)
        task.delay((i-1)*0.1, function()
            TweenSvc:Create(b.f,
                TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
                {Position=orig}):Play()
        end)
    end
end
