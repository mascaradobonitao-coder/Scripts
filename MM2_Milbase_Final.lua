-- MM2 5v5 Milbase | Silent Aim + Thunder Skin
-- script by tolopoofcpae / tolopo637883

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenSvc   = game:GetService("TweenService")
local UIS        = game:GetService("UserInputService")
local RS         = game:GetService("ReplicatedStorage")
local Debris     = game:GetService("Debris")

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

-- ── gun list ─────────────────────────────────────────────────────
local GUNS = {
    ["BasicGun"]=true,["AmericaGun"]=true,["CandyGun"]=true,
    ["RainbowGun"]=true,["SwirlyGun"]=true,["IceBeam"]=true,
    ["Alienbeam"]=true,["DualAlienbeam"]=true,["Amerilaser"]=true,
    ["Harvester"]=true,["GoldHarvester"]=true,["Laser"]=true,
    ["IcepierCer"]=true,["Lightbringer"]=true,["Luger"]=true,
    ["GreenLuger"]=true,["RedLuger"]=true,["Ocean"]=true,
    ["Phaser"]=true,["Plasmabeam"]=true,["Raygun"]=true,
    ["Spectre"]=true,["SharkNerf"]=true,["Shark"]=true,
    ["Gingerscope"]=true,["Xenoshot"]=true,
}
local function getEquipped()
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end
local function isGun(t)   return t and (GUNS[t.Name] == true) end
local function isKnife(t)
    if not t then return false end
    if GUNS[t.Name] then return false end
    -- check if it has a KnifeScript_Local or KnifeSystem usage
    local name = t.Name:lower()
    if name:find("gun") or name:find("beam") or name:find("laser")
    or name:find("scope") or name:find("shot") or name:find("blaster") then
        return false
    end
    return true
end

local function getNearestEnemy()
    if not hrp then return nil, nil end
    local bestChar, bestHRP, bestDist = nil, nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp then
            local c = p.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                local r = c:FindFirstChild("HumanoidRootPart")
                if h and r and h.Health > 0 then
                    local d = (hrp.Position - r.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestChar = c
                        bestHRP  = r
                    end
                end
            end
        end
    end
    return bestChar, bestHRP
end

-- ── SA state ─────────────────────────────────────────────────────
local saActive    = false
local _bypass     = false
local _gunCD      = false
local _knifeCD    = false
local thunderOn   = false
local menuOpen    = false

-- ================================================================
-- THUNDER SKIN — client side
-- ================================================================
local thunderConnections = {}
local function clearThunder(handle)
    if not handle then return end
    for _, v in pairs(handle:GetChildren()) do
        if v.Name == "_TLight" or v.Name == "_TParticles" then
            v:Destroy()
        end
    end
end

local function applyThunderToHandle(handle)
    if not handle then return end
    clearThunder(handle)
    pcall(function()
        handle.BrickColor = BrickColor.new("Cyan")
        handle.Material   = Enum.Material.Neon
    end)
    local pl = Instance.new("PointLight")
    pl.Name       = "_TLight"
    pl.Color      = Color3.fromRGB(0, 220, 255)
    pl.Brightness = 4
    pl.Range      = 14
    pl.Parent     = handle

    local pe = Instance.new("ParticleEmitter")
    pe.Name      = "_TParticles"
    pe.Color     = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255)),
    })
    pe.LightEmission = 1
    pe.Size      = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(1, 0),
    })
    pe.Rate      = 18
    pe.Lifetime  = NumberRange.new(0.25, 0.55)
    pe.Speed     = NumberRange.new(2, 7)
    pe.SpreadAngle = Vector2.new(180, 180)
    pe.Parent    = handle
end

local function removeThunderFromHandle(handle)
    if not handle then return end
    clearThunder(handle)
    pcall(function()
        handle.BrickColor = BrickColor.new("Medium stone grey")
        handle.Material   = Enum.Material.SmoothPlastic
    end)
end

local function refreshThunderSkin()
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end
    if thunderOn then
        applyThunderToHandle(handle)
    else
        removeThunderFromHandle(handle)
    end
end

-- Watch for tool equip/unequip to apply thunder
local function watchToolEquip(c)
    c.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.05)
            if thunderOn then
                local handle = child:FindFirstChild("Handle")
                if handle then applyThunderToHandle(handle) end
            end
        end
    end)
end
if char then watchToolEquip(char) end
lp.CharacterAdded:Connect(function(c)
    refreshChar(c)
    _bypass = false _gunCD = false _knifeCD = false
    watchToolEquip(c)
end)

-- Lightning bolt effect at a world position (client only)
local function spawnLightning(pos)
    local segments = 7
    local segH = 10 / segments
    local parts = {}
    for i = 1, segments do
        local p = Instance.new("Part")
        p.Anchored    = true
        p.CanCollide  = false
        p.CastShadow  = false
        p.Material    = Enum.Material.Neon
        p.BrickColor  = BrickColor.new("Cyan")
        p.Size        = Vector3.new(0.08, segH, 0.08)
        local ox = (math.random() - 0.5) * 1.8
        local oz = (math.random() - 0.5) * 1.8
        local oy = (i - 0.5) * segH
        p.CFrame = CFrame.new(pos + Vector3.new(ox, oy, oz))
        p.Parent  = workspace
        table.insert(parts, p)
    end
    -- bright light
    local lp2 = Instance.new("Part")
    lp2.Size = Vector3.new(0.1,0.1,0.1)
    lp2.Anchored = true
    lp2.CanCollide = false
    lp2.Transparency = 1
    lp2.CFrame = CFrame.new(pos + Vector3.new(0,5,0))
    local pl2 = Instance.new("PointLight", lp2)
    pl2.Color      = Color3.fromRGB(0,220,255)
    pl2.Brightness = 25
    pl2.Range      = 22
    lp2.Parent = workspace
    table.insert(parts, lp2)

    -- fade & destroy
    for _, p in pairs(parts) do
        TweenSvc:Create(p, TweenInfo.new(0.55, Enum.EasingStyle.Linear), {
            Transparency = 1,
        }):Play()
    end
    task.delay(0.6, function()
        for _, p in pairs(parts) do
            pcall(function() p:Destroy() end)
        end
    end)
end

-- Monitor all enemies for death to trigger lightning
local function hookEnemyDeath(p)
    local function tryHook(c)
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        local r = c:FindFirstChild("HumanoidRootPart")
        if h and r then
            h.Died:Connect(function()
                if thunderOn then
                    pcall(function() spawnLightning(r.Position) end)
                end
            end)
        end
    end
    tryHook(p.Character)
    p.CharacterAdded:Connect(tryHook)
end
for _, p in pairs(Players:GetPlayers()) do
    if p ~= lp then hookEnemyDeath(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= lp then hookEnemyDeath(p) end
end)

-- ================================================================
-- SILENT GUN
-- Three remotes used in this game:
--  1. FireWeapon:FireServer(Vector3)  — cl_revolver guns
--  2. tool.RemoteEvent:FireServer(CFrame)  — ClienScript guns
--  3. Fire:FireServer(Vector3 or CFrame)  — others
-- We hook __namecall to redirect the position to the nearest enemy
-- ================================================================
local function silentGun()
    if _gunCD then return end
    local _, target = getNearestEnemy()
    if not target then return end
    local tool = getEquipped()
    if not tool then return end

    -- Try all gun remotes
    local fired = false

    -- ClienScript style: tool has a RemoteEvent child
    local re = tool:FindFirstChildOfClass("RemoteEvent")
    if re then
        _bypass = true
        pcall(function()
            re:FireServer(CFrame.new(target.Position))
        end)
        _bypass = false
        fired = true
    end

    -- cl_revolver style: tool has FireWeapon
    if not fired then
        local fw = tool:FindFirstChild("FireWeapon")
        if fw and fw:IsA("RemoteEvent") then
            _bypass = true
            pcall(function()
                fw:FireServer(target.Position)
            end)
            _bypass = false
            fired = true
        end
    end

    -- Fire remote style
    if not fired then
        local fr = tool:FindFirstChild("Fire")
        if fr and fr:IsA("RemoteEvent") then
            _bypass = true
            pcall(function()
                fr:FireServer(target.Position)
            end)
            _bypass = false
        end
    end

    _gunCD = true
    task.delay(0.5, function() _gunCD = false end)
end

-- ================================================================
-- SILENT KNIFE — Murder stab (direct DamageConfirmation, NO teleport)
-- Signature: DamageConfirmation:FireServer(damage, character, {TargetCFrame=hrp.CFrame})
-- Located at: game.ReplicatedStorage["::Events"].DamageConfirmation
-- ================================================================
local function silentKnife()
    if _knifeCD then return end
    local targetChar, targetHRP = getNearestEnemy()
    if not targetChar or not targetHRP then return end

    _knifeCD = true

    pcall(function()
        local events = RS:FindFirstChild("::Events")
        if not events then return end
        local dmgRE = events:FindFirstChild("DamageConfirmation")
        if not dmgRE then return end

        -- Play stab animation locally
        if char then
            local hm = char:FindFirstChildOfClass("Humanoid")
            if hm then
                local animator = hm:FindFirstChildOfClass("Animator")
                if animator then
                    local anims = RS:FindFirstChild("::Game_Animations")
                    if anims then
                        local stabAnim = anims:FindFirstChild("Stab")
                        if stabAnim then
                            pcall(function()
                                local track = animator:LoadAnimation(stabAnim)
                                track:Play()
                            end)
                        end
                    end
                end
            end
        end

        -- Fire damage to server
        _bypass = true
        dmgRE:FireServer(100, targetChar, {
            TargetCFrame = targetHRP.CFrame
        })
        _bypass = false
    end)
    _bypass = false

    task.delay(1.2, function() _knifeCD = false end)
end

-- ================================================================
-- NAMECALL HOOK — block normal inputs when SA is ON
-- ================================================================
local BLOCKED = {
    FireWeapon        = true,
    Fire              = true,
    DamageConfirmation= true,
    ThrowConfirmation = true,
}

pcall(function()
    local oldNC
    oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if saActive and not _bypass then
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                    if BLOCKED[self.Name] then return end
                    -- Also block tool's own RemoteEvent (ClienScript)
                    local tool = getEquipped()
                    if tool then
                        local re = tool:FindFirstChildOfClass("RemoteEvent")
                        if re and re == self then return end
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
    Name="MM2_Load", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=9999,
}, pgui)

local LBG = make("Frame", {
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(3,3,10),
    BorderSizePixel=0,
}, LoadGui)

-- moving gradient
local gradF = make("Frame", {
    Size=UDim2.new(4,0,1,0),
    Position=UDim2.new(-1.5,0,0,0),
    BackgroundTransparency=1,
    BorderSizePixel=0, ZIndex=2,
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
        BorderSizePixel=0, ZIndex=3,
    }, LBG)
end

-- floating dots
local function spawnDot()
    local s  = math.random(4,13)
    local px = math.random(5,95)/100
    local dot = make("Frame", {
        Size=UDim2.new(0,s,0,s),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(px,0,1.1,0),
        BackgroundColor3=Color3.fromRGB(
            math.random(0,28), math.random(100,195), 255),
        BackgroundTransparency=math.random(42,72)/100,
        BorderSizePixel=0, ZIndex=4,
    }, LBG)
    make("UICorner",{CornerRadius=UDim.new(1,0)},dot)
    local dest = math.random()*0.2 - 0.1
    local t2 = TweenSvc:Create(dot,
        TweenInfo.new(math.random(28,52)/10, Enum.EasingStyle.Linear),{
        Position=UDim2.new(px+dest, 0, -0.12, 0),
        BackgroundTransparency=1,
    })
    t2:Play()
    t2.Completed:Connect(function() dot:Destroy() end)
end
task.spawn(function()
    while LoadGui.Parent do
        spawnDot()
        task.wait(math.random(8,20)/100)
    end
end)

-- corner brackets
for _, cv in pairs({
    {Vector2.new(0,0),UDim2.new(0,12,0,12)},
    {Vector2.new(1,0),UDim2.new(1,-12,0,12)},
    {Vector2.new(0,1),UDim2.new(0,12,1,-12)},
    {Vector2.new(1,1),UDim2.new(1,-12,1,-12)},
}) do
    local f = make("Frame",{
        Size=UDim2.new(0,52,0,52),
        AnchorPoint=cv[1], Position=cv[2],
        BackgroundTransparency=1, BorderSizePixel=0, ZIndex=5,
    }, LBG)
    local st = make("UIStroke",{Color=Color3.fromRGB(0,138,255),Thickness=2},f)
    TweenSvc:Create(st, TweenInfo.new(1.2,Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,-1,true),{Transparency=0.88}):Play()
end

-- center card
local card = make("Frame",{
    Size=UDim2.new(0,490,0,275),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,1.7,0),
    BackgroundColor3=Color3.fromRGB(4,8,22),
    BackgroundTransparency=0.14,
    BorderSizePixel=0, ZIndex=6,
},LBG)
make("UICorner",{CornerRadius=UDim.new(0,18)},card)
make("UIStroke",{Color=Color3.fromRGB(0,142,255),Thickness=1.8,Transparency=0.1},card)

local cardGrad = make("UIGradient",{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,12,35)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,28,65)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,12,35)),
    }),
    Rotation=100,
},card)
task.spawn(function()
    local t = 0
    while LoadGui.Parent do
        t = t + 0.012
        cardGrad.Rotation = 100 + math.sin(t)*25
        RunService.RenderStepped:Wait()
    end
end)

local accLine = make("Frame",{
    Size=UDim2.new(0,0,0,3),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,182,255),
    BorderSizePixel=0, ZIndex=7,
},card)
make("UICorner",{CornerRadius=UDim.new(0,2)},accLine)

local function cLbl(parent, text, ypos, tsz, col, fnt)
    return make("TextLabel",{
        Size=UDim2.new(1,-28,0,tsz+6),
        Position=UDim2.new(0,14,0,ypos),
        BackgroundTransparency=1,
        Text=text,
        TextColor3=col or Color3.fromRGB(255,255,255),
        Font=fnt or Enum.Font.Gotham,
        TextSize=tsz,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=7,
    },parent)
end

cLbl(card,"▸  EXCLUSIVE  •  DELTA COMPATIBLE  •  MOBILE  ◂",
    13,11,Color3.fromRGB(0,158,255))

local titleLbl = cLbl(card,"",36,42,Color3.fromRGB(255,255,255),Enum.Font.GothamBlack)
local titleGrad = make("UIGradient",{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,198,255)),
        ColorSequenceKeypoint.new(0.45,Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,198,255)),
    }),
},titleLbl)
make("UIStroke",{Color=Color3.fromRGB(0,148,255),Thickness=1.6,Transparency=0.5},titleLbl)
task.spawn(function()
    local t = 0
    while LoadGui.Parent do
        t = t + 0.015
        titleGrad.Rotation = math.sin(t)*16
        RunService.RenderStepped:Wait()
    end
end)

cLbl(card,"5v5  MILBASE  •  SILENT AIM EDITION",98,15,
    Color3.fromRGB(68,152,255),Enum.Font.GothamBold)

local divLine = make("Frame",{
    Size=UDim2.new(0,0,0,1),
    Position=UDim2.new(0.08,0,0,134),
    BackgroundColor3=Color3.fromRGB(0,138,255),
    BackgroundTransparency=0.4,
    BorderSizePixel=0, ZIndex=7,
},card)

cLbl(card,"script by tolopoofcpae / tolopo637883",144,12,Color3.fromRGB(102,168,255))
local statusLbl = cLbl(card,"Inicializando...",168,11,Color3.fromRGB(48,122,255))

local pbBG = make("Frame",{
    Size=UDim2.new(0.84,0,0,7),
    Position=UDim2.new(0.08,0,0,194),
    BackgroundColor3=Color3.fromRGB(5,15,36),
    BorderSizePixel=0, ZIndex=7,
},card)
make("UICorner",{CornerRadius=UDim.new(1,0)},pbBG)
local pbFill = make("Frame",{
    Size=UDim2.new(0,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,182,255),
    BorderSizePixel=0, ZIndex=8,
},pbBG)
make("UICorner",{CornerRadius=UDim.new(1,0)},pbFill)
make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,108,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(128,232,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,182,255)),
})},pbFill)
cLbl(card,"v2.0  •  THUNDER SKIN  •  MURDER MODE",216,10,Color3.fromRGB(26,55,110))

-- slide card up
TweenSvc:Create(card,TweenInfo.new(0.82,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
    {Position=UDim2.new(0.5,0,0.5,0)}):Play()

task.spawn(function()
    task.wait(0.48)
    tw(accLine,0.9,{Size=UDim2.new(0.8,0,0,3)},Enum.EasingStyle.Cubic)
    tw(divLine, 1.1,{Size=UDim2.new(0.84,0,0,1)},Enum.EasingStyle.Cubic)
end)
task.spawn(function()
    task.wait(0.55)
    local txt = "MM2 5v5 Milbase"
    for i = 1, #txt do
        titleLbl.Text = string.sub(txt,1,i)
        task.wait(0.054)
    end
end)
task.spawn(function()
    local stages = {
        {0.18,"Carregando hooks..."},
        {0.36,"Verificando remotes..."},
        {0.52,"Montando armas..."},
        {0.70,"Preparando murder mode..."},
        {0.85,"Thunder skin pronto..."},
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
},LoadGui)
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
    Name="MM2_Key", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=8000,
},pgui)

local kDim = make("Frame",{
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=0.52, BorderSizePixel=0,
},KeyGui)

local kPanel = make("Frame",{
    Size=UDim2.new(0,408,0,305),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,1.8,0),
    BackgroundColor3=Color3.fromRGB(4,8,22),
    BackgroundTransparency=0.04,
    BorderSizePixel=0, ZIndex=2,
},KeyGui)
make("UICorner",{CornerRadius=UDim.new(0,20)},kPanel)
local kpStroke = make("UIStroke",{Color=Color3.fromRGB(0,148,255),Thickness=2},kPanel)

local kPG = make("UIGradient",{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,10,30)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,26,58)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,10,30)),
    }),Rotation=112,
},kPanel)
task.spawn(function()
    local t = 0
    while KeyGui.Parent do
        t = t + 0.013
        kPG.Rotation = 112 + math.sin(t)*20
        RunService.RenderStepped:Wait()
    end
end)

local kTopGlow = make("Frame",{
    Size=UDim2.new(0.65,0,0,3),
    AnchorPoint=Vector2.new(0.5,0), Position=UDim2.new(0.5,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,198,255),
    BorderSizePixel=0, ZIndex=3,
},kPanel)
make("UICorner",{CornerRadius=UDim.new(1,0)},kTopGlow)
TweenSvc:Create(kTopGlow, TweenInfo.new(1.25,Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,-1,true),
    {BackgroundColor3=Color3.fromRGB(0,82,198)}):Play()

local lockCircle = make("Frame",{
    Size=UDim2.new(0,50,0,50),
    AnchorPoint=Vector2.new(0.5,0), Position=UDim2.new(0.5,0,0,14),
    BackgroundColor3=Color3.fromRGB(0,34,84),
    BackgroundTransparency=0.22, BorderSizePixel=0, ZIndex=3,
},kPanel)
make("UICorner",{CornerRadius=UDim.new(1,0)},lockCircle)
make("UIStroke",{Color=Color3.fromRGB(0,136,255),Thickness=1.5},lockCircle)
make("TextLabel",{
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text="[KEY]", TextSize=16, Font=Enum.Font.GothamBlack,
    TextColor3=Color3.fromRGB(0,200,255), ZIndex=4,
},lockCircle)

local function kLabel(txt,y,sz,col,fnt)
    return make("TextLabel",{
        Size=UDim2.new(1,-28,0,sz+4),
        Position=UDim2.new(0,14,0,y),
        BackgroundTransparency=1,
        Text=txt,
        TextColor3=col or Color3.fromRGB(72,145,218),
        Font=fnt or Enum.Font.Gotham,
        TextSize=sz,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=3,
    },kPanel)
end

local kTitleLbl = kLabel("MM2  5v5  MILBASE",76,22,
    Color3.fromRGB(255,255,255),Enum.Font.GothamBlack)
local kTitleGrad = make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,194,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(198,238,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,194,255)),
})},kTitleLbl)
task.spawn(function()
    local t = 0
    while KeyGui.Parent do
        t = t + 0.017
        kTitleGrad.Rotation = math.sin(t)*13
        RunService.RenderStepped:Wait()
    end
end)

kLabel("Insira a key para continuar",108,13)
kLabel("Pega a key gratis no  scriptblox.com",126,11,Color3.fromRGB(42,98,178))

local iBG = make("Frame",{
    Size=UDim2.new(1,-38,0,46),
    Position=UDim2.new(0,19,0,150),
    BackgroundColor3=Color3.fromRGB(0,12,33),
    BorderSizePixel=0, ZIndex=3,
},kPanel)
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
},iBG)
tbox.Focused:Connect(function()
    tw(iStroke,0.16,{Color=Color3.fromRGB(0,198,255),Thickness=2})
end)
tbox.FocusLost:Connect(function()
    tw(iStroke,0.16,{Color=Color3.fromRGB(0,92,198),Thickness=1.5})
end)

local errLbl = kLabel("",205,12,Color3.fromRGB(255,72,72),Enum.Font.GothamBold)

local confBtn = make("TextButton",{
    Size=UDim2.new(1,-38,0,44),
    Position=UDim2.new(0,19,0,228),
    Text="CONFIRMAR KEY",
    TextColor3=Color3.fromRGB(255,255,255),
    Font=Enum.Font.GothamBlack, TextSize=15,
    BackgroundColor3=Color3.fromRGB(0,76,198),
    BorderSizePixel=0, ZIndex=3,
},kPanel)
make("UICorner",{CornerRadius=UDim.new(0,10)},confBtn)
make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,96,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,54,190)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,96,255)),
}),Rotation=90},confBtn)
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
-- 3. MENU GUI (opened by draggable button)
-- ================================================================
-- ================================================================
local MenuGui = make("ScreenGui",{
    Name="MM2_Menu", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=600,
},pgui)

-- Menu panel (tech/hologram style) — hidden initially
local menuPanel = make("Frame",{
    Size=UDim2.new(0,280,0,320),
    AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(-0.35,0,0.5,0),  -- starts off left
    BackgroundColor3=Color3.fromRGB(2,6,18),
    BackgroundTransparency=0.08,
    BorderSizePixel=0, ZIndex=2,
},MenuGui)
make("UICorner",{CornerRadius=UDim.new(0,16)},menuPanel)
local mpStroke = make("UIStroke",{Color=Color3.fromRGB(0,200,255),Thickness=1.5,Transparency=0.1},menuPanel)

-- Tech background with moving scan lines
for i = 1, 18 do
    make("Frame",{
        Size=UDim2.new(1,0,0,1),
        Position=UDim2.new(0,0,i/18,0),
        BackgroundColor3=Color3.fromRGB(0,150,255),
        BackgroundTransparency=0.92,
        BorderSizePixel=0, ZIndex=3,
    },menuPanel)
end

-- Animated UIGradient overlay on panel
local mpGrad = make("UIGradient",{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,5,18)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0,25,55)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0,45,90)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,5,18)),
    }),
    Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.1),
    }),
    Rotation=85,
},menuPanel)

task.spawn(function()
    local t = 0
    while MenuGui.Parent do
        t = t + 0.01
        mpGrad.Rotation = 85 + math.sin(t)*30
        mpStroke.Transparency = 0.1 + math.sin(t*2)*0.08
        RunService.RenderStepped:Wait()
    end
end)

-- Moving horizontal line (tech effect)
local techLine = make("Frame",{
    Size=UDim2.new(1,0,0,2),
    Position=UDim2.new(0,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,200,255),
    BackgroundTransparency=0.3,
    BorderSizePixel=0, ZIndex=4,
},menuPanel)
make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,220,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,0,0)),
})},techLine)
task.spawn(function()
    while MenuGui.Parent do
        TweenSvc:Create(techLine,TweenInfo.new(1.8,Enum.EasingStyle.Sine),
            {Position=UDim2.new(0,0,1.02,0)}):Play()
        task.wait(1.8)
        techLine.Position = UDim2.new(0,0,-0.02,0)
        task.wait(0.05)
    end
end)

-- Top accent
local mpTop = make("Frame",{
    Size=UDim2.new(0.7,0,0,3),
    AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,200,255),
    BorderSizePixel=0, ZIndex=5,
},menuPanel)
make("UICorner",{CornerRadius=UDim.new(1,0)},mpTop)
TweenSvc:Create(mpTop,TweenInfo.new(1.4,Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,-1,true),
    {BackgroundColor3=Color3.fromRGB(0,80,200)}):Play()

local function mpLbl(txt,y,sz,col,fnt)
    return make("TextLabel",{
        Size=UDim2.new(1,-20,0,sz+4),
        Position=UDim2.new(0,10,0,y),
        BackgroundTransparency=1,
        Text=txt,
        TextColor3=col or Color3.fromRGB(200,235,255),
        Font=fnt or Enum.Font.Gotham,
        TextSize=sz,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=5,
    },menuPanel)
end

mpLbl("MM2  MILBASE  HUB",14,16,Color3.fromRGB(255,255,255),Enum.Font.GothamBlack)
mpLbl("SKINS & EFEITOS",36,11,Color3.fromRGB(0,180,255))

-- Divider
local mpDiv = make("Frame",{
    Size=UDim2.new(0.9,0,0,1),
    Position=UDim2.new(0.05,0,0,54),
    BackgroundColor3=Color3.fromRGB(0,160,255),
    BackgroundTransparency=0.5, BorderSizePixel=0, ZIndex=5,
},menuPanel)

-- Thunder Skin toggle
local thunderRow = make("Frame",{
    Size=UDim2.new(1,-20,0,48),
    Position=UDim2.new(0,10,0,62),
    BackgroundColor3=Color3.fromRGB(0,12,35),
    BackgroundTransparency=0.3, BorderSizePixel=0, ZIndex=5,
},menuPanel)
make("UICorner",{CornerRadius=UDim.new(0,10)},thunderRow)
make("UIStroke",{Color=Color3.fromRGB(0,120,220),Thickness=1},thunderRow)

make("TextLabel",{
    Size=UDim2.new(0,0.62,1,0),
    Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1,
    Text="Skin Trovao",
    TextColor3=Color3.fromRGB(0,220,255),
    Font=Enum.Font.GothamBold, TextSize=14,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=6,
},thunderRow)

local thunderSubLbl = make("TextLabel",{
    Size=UDim2.new(0.62,0,0,16),
    Position=UDim2.new(0,12,0,26),
    BackgroundTransparency=1,
    Text="Faca + Efeito de morte",
    TextColor3=Color3.fromRGB(60,120,180),
    Font=Enum.Font.Gotham, TextSize=11,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=6,
},thunderRow)

-- Toggle button
local toggleBG = make("Frame",{
    Size=UDim2.new(0,48,0,26),
    AnchorPoint=Vector2.new(1,0.5),
    Position=UDim2.new(1,-10,0.5,0),
    BackgroundColor3=Color3.fromRGB(30,30,50),
    BorderSizePixel=0, ZIndex=6,
},thunderRow)
make("UICorner",{CornerRadius=UDim.new(1,0)},toggleBG)
make("UIStroke",{Color=Color3.fromRGB(80,80,120),Thickness=1},toggleBG)

local toggleKnob = make("Frame",{
    Size=UDim2.new(0,20,0,20),
    AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(0,3,0.5,0),
    BackgroundColor3=Color3.fromRGB(120,120,160),
    BorderSizePixel=0, ZIndex=7,
},toggleBG)
make("UICorner",{CornerRadius=UDim.new(1,0)},toggleKnob)

local toggleBtn = make("TextButton",{
    Size=UDim2.new(1,0,1,0),
    BackgroundTransparency=1, Text="",
    ZIndex=8,
},thunderRow)

toggleBtn.MouseButton1Up:Connect(function()
    thunderOn = not thunderOn
    if thunderOn then
        tw(toggleBG,0.2,{BackgroundColor3=Color3.fromRGB(0,50,100)})
        tw(toggleKnob,0.2,{
            Position=UDim2.new(1,-23,0.5,0),
            BackgroundColor3=Color3.fromRGB(0,200,255),
        })
        refreshThunderSkin()
    else
        tw(toggleBG,0.2,{BackgroundColor3=Color3.fromRGB(30,30,50)})
        tw(toggleKnob,0.2,{
            Position=UDim2.new(0,3,0.5,0),
            BackgroundColor3=Color3.fromRGB(120,120,160),
        })
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local handle = tool:FindFirstChild("Handle")
                if handle then removeThunderFromHandle(handle) end
            end
        end
    end
end)

-- Status labels
local skinStatus = mpLbl("Status: Desativado",120,11,Color3.fromRGB(80,100,140))
task.spawn(function()
    while MenuGui.Parent do
        if thunderOn then
            skinStatus.Text = "Status: TROVAO ATIVO"
            skinStatus.TextColor3 = Color3.fromRGB(0,220,255)
        else
            skinStatus.Text = "Status: Desativado"
            skinStatus.TextColor3 = Color3.fromRGB(80,100,140)
        end
        task.wait(0.3)
    end
end)

-- Info section
local mpDiv2 = make("Frame",{
    Size=UDim2.new(0.9,0,0,1),
    Position=UDim2.new(0.05,0,0,140),
    BackgroundColor3=Color3.fromRGB(0,100,180),
    BackgroundTransparency=0.6, BorderSizePixel=0, ZIndex=5,
},menuPanel)

mpLbl("SILENT AIM",148,14,Color3.fromRGB(255,255,255),Enum.Font.GothamBlack)
mpLbl("SA = Ativar/Desativar",168,11,Color3.fromRGB(100,180,255))
mpLbl("FACA = Murder p/ pessoa mais perto",184,11,Color3.fromRGB(100,180,255))
mpLbl("GUN = Atira p/ pessoa mais perto",200,11,Color3.fromRGB(100,180,255))

local mpDiv3 = make("Frame",{
    Size=UDim2.new(0.9,0,0,1),
    Position=UDim2.new(0.05,0,0,218),
    BackgroundColor3=Color3.fromRGB(0,100,180),
    BackgroundTransparency=0.6, BorderSizePixel=0, ZIndex=5,
},menuPanel)

mpLbl("SKIN TROVAO:",226,11,Color3.fromRGB(0,200,255))
mpLbl("Requer skin padrao do jogo",242,11,Color3.fromRGB(60,110,160))
mpLbl("Troca cor + particulas + efeito morte",258,11,Color3.fromRGB(60,110,160))

-- Close button
local closeBtn = make("TextButton",{
    Size=UDim2.new(0,28,0,28),
    AnchorPoint=Vector2.new(1,0),
    Position=UDim2.new(1,-8,0,8),
    Text="X",
    TextColor3=Color3.fromRGB(180,100,100),
    Font=Enum.Font.GothamBlack, TextSize=13,
    BackgroundColor3=Color3.fromRGB(30,10,10),
    BackgroundTransparency=0.3, BorderSizePixel=0, ZIndex=8,
},menuPanel)
make("UICorner",{CornerRadius=UDim.new(1,0)},closeBtn)
make("UIStroke",{Color=Color3.fromRGB(180,60,60),Thickness=1},closeBtn)

-- Toggle menu function
local menuShowing = false
local function toggleMenu()
    menuShowing = not menuShowing
    if menuShowing then
        menuPanel.Visible = true
        TweenSvc:Create(menuPanel,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
            {Position=UDim2.new(0.01,0,0.5,0)}):Play()
    else
        TweenSvc:Create(menuPanel,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In),
            {Position=UDim2.new(-0.35,0,0.5,0)}):Play()
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
    Name="MM2_Btns", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=500,
},pgui)

local function makeBtn(sz, pos, label, textColor, draggable)
    local outer = make("Frame",{
        Size=UDim2.new(0,sz,0,sz),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=pos,
        BackgroundColor3=Color3.fromRGB(0,0,0),
        BackgroundTransparency=0.62,
        BorderSizePixel=0, ZIndex=10,
    },BGui)
    make("UICorner",{CornerRadius=UDim.new(1,0)},outer)
    local ost = make("UIStroke",{Color=Color3.fromRGB(20,20,20),Thickness=2.2},outer)

    make("Frame",{
        Size=UDim2.new(0,sz-13,0,sz-13),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,0),
        BackgroundTransparency=1, BorderSizePixel=0, ZIndex=11,
    },outer)

    local inner = make("Frame",{
        Size=UDim2.new(0,sz-18,0,sz-18),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,0),
        BackgroundColor3=Color3.fromRGB(0,0,0),
        BackgroundTransparency=0.48, BorderSizePixel=0, ZIndex=12,
    },outer)
    make("UICorner",{CornerRadius=UDim.new(1,0)},inner)

    local lbl = make("TextLabel",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text=label, TextColor3=textColor,
        Font=Enum.Font.GothamBold, TextScaled=true, ZIndex=13,
    },inner)

    local btn = make("TextButton",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text="", ZIndex=14,
    },outer)
    make("UICorner",{CornerRadius=UDim.new(1,0)},btn)

    if draggable then
        local dragging, dragStart, dragPos = false, nil, nil
        btn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch
            or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
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
                        dragPos.X.Scale, dragPos.X.Offset + delta.X,
                        dragPos.Y.Scale, dragPos.Y.Offset + delta.Y)
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

    btn.MouseButton1Down:Connect(function()
        tw(outer,0.07,{Size=UDim2.new(0,sz*0.87,0,sz*0.87)})
    end)
    btn.MouseButton1Up:Connect(function()
        TweenSvc:Create(outer,TweenInfo.new(0.14,Enum.EasingStyle.Back,
            Enum.EasingDirection.Out),{Size=UDim2.new(0,sz,0,sz)}):Play()
    end)

    return {f=outer, btn=btn, lbl=lbl, inner=inner, stroke=ost}
end

-- MENU open button (draggable, top left)
local menuOpenBtn = makeBtn(56, UDim2.new(0.06,0,0.55,0), "HUB",
    Color3.fromRGB(0,200,255), true)
menuOpenBtn.btn.MouseButton1Up:Connect(toggleMenu)
TweenSvc:Create(menuOpenBtn.f, TweenInfo.new(1.5,Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,-1,true),
    {BackgroundTransparency=0.45}):Play()

-- SA toggle (draggable, left)
local saBtn = makeBtn(78, UDim2.new(0.12,0,0.80,0), "SA\nOFF",
    Color3.fromRGB(255,72,50), true)
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

-- Knife/Murder (draggable, above SA)
local kBtn = makeBtn(74, UDim2.new(0.12,0,0.67,0), "FACA",
    Color3.fromRGB(172,195,255), true)
kBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local tool = getEquipped()
    if tool and isKnife(tool) then silentKnife() end
end)

-- Gun (fixed, bottom right near jump)
local gBtn = makeBtn(80, UDim2.new(0.88,0,0.88,0), "GUN",
    Color3.fromRGB(255,205,0), false)
gBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local tool = getEquipped()
    if tool and isGun(tool) then silentGun() end
end)

-- glow active weapon
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
        -- thunder glow on HUB button
        if thunderOn then
            menuOpenBtn.stroke.Color = Color3.fromRGB(0,200,255)
        else
            menuOpenBtn.stroke.Color = Color3.fromRGB(20,20,20)
        end
    end
end)

-- slide buttons in from bottom
do
    local allBtns = {saBtn, kBtn, gBtn, menuOpenBtn}
    for i = 1, #allBtns do
        local b    = allBtns[i]
        local orig = b.f.Position
        b.f.Position = UDim2.new(
            orig.X.Scale, orig.X.Offset,
            orig.Y.Scale + 0.35, orig.Y.Offset)
        task.delay((i-1)*0.1, function()
            TweenSvc:Create(b.f,
                TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Position=orig}):Play()
        end)
    end
end
