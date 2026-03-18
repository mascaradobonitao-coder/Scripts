-- Murderers vs Sheriffs | Skin Hub
-- script by tolopoofcpae / tolopo637883
-- Só o Hub: Skin Sombra + Arma Azul + Efeito de Morte

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenSvc   = game:GetService("TweenService")
local UIS        = game:GetService("UserInputService")
local Debris     = game:GetService("Debris")

local lp   = Players.LocalPlayer
local pgui = lp.PlayerGui

-- ── char ─────────────────────────────────────────────────────────
local char, hrp, hum
local function refreshChar(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end
if lp.Character then refreshChar(lp.Character) end
lp.CharacterAdded:Connect(refreshChar)

-- ================================================================
-- TOGGLES
-- ================================================================
local skinOn   = false   -- corpo preto (sombra)
local weaponOn = false   -- arma/faca azul
local killFXOn = false   -- efeito morte trovao + pedras

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
        for k, v in pairs(props) do pcall(function() i[k] = v end) end
    end
    if parent then i.Parent = parent end
    return i
end

-- ================================================================
-- SKIN SOMBRA — corpo totalmente preto + silhueta
-- Igual print 1: body black neon, sem textura
-- ================================================================
local _origBodyData = {}

local function applySombraSkin()
    if not char then return end
    _origBodyData = {}
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                table.insert(_origBodyData, {
                    obj      = part,
                    color    = part.BrickColor,
                    material = part.Material,
                    refl     = part.Reflectance,
                    textureID = part:IsA("MeshPart") and part.TextureID or nil,
                })
                part.BrickColor   = BrickColor.new("Really black")
                part.Material     = Enum.Material.Neon
                part.Reflectance  = 0
                if part:IsA("MeshPart") then part.TextureID = "" end
            end)
        elseif part:IsA("Decal") or part:IsA("Texture")
        or part:IsA("Shirt") or part:IsA("Pants")
        or part:IsA("ShirtGraphic") or part:IsA("SurfaceAppearance") then
            pcall(function()
                table.insert(_origBodyData, {obj=part, transparency=part.Transparency})
                part.Transparency = 1
            end)
        elseif part:IsA("SpecialMesh") then
            pcall(function()
                table.insert(_origBodyData, {obj=part, textureId=part.TextureId})
                part.TextureId = ""
            end)
        end
    end
    -- Cyan body glow
    if hrp then
        local pl = Instance.new("PointLight")
        pl.Name       = "_Sombra_Glow"
        pl.Color      = Color3.fromRGB(0, 200, 255)
        pl.Brightness = 2
        pl.Range      = 12
        pl.Parent     = hrp
        -- subtle body particle
        local pe = Instance.new("ParticleEmitter")
        pe.Name         = "_Sombra_Body"
        pe.Color        = ColorSequence.new(Color3.fromRGB(0, 150, 255))
        pe.LightEmission = 1
        pe.Size         = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(1, 0),
        })
        pe.Rate         = 6
        pe.Lifetime     = NumberRange.new(0.3, 0.8)
        pe.Speed        = NumberRange.new(0.5, 2)
        pe.SpreadAngle  = Vector2.new(180, 180)
        pe.LightInfluence = 0
        pe.Parent       = hrp
    end
end

local function removeSombraSkin()
    if not char then return end
    for _, data in pairs(_origBodyData) do
        pcall(function()
            if not data.obj or not data.obj.Parent then return end
            if data.color    then data.obj.BrickColor   = data.color    end
            if data.material then data.obj.Material     = data.material end
            if data.refl     then data.obj.Reflectance  = data.refl     end
            if data.textureID then data.obj.TextureID   = data.textureID end
            if data.textureId then data.obj.TextureId   = data.textureId end
            if data.transparency then data.obj.Transparency = data.transparency end
        end)
    end
    _origBodyData = {}
    if hrp then
        local g = hrp:FindFirstChild("_Sombra_Glow")
        local b = hrp:FindFirstChild("_Sombra_Body")
        if g then g:Destroy() end
        if b then b:Destroy() end
    end
end

-- ================================================================
-- WEAPON FX AZUL
-- Igual print 1: arma cyan neon + partículas azuis + luz
-- ================================================================
local _weapFX = {}

local function removeWeaponFX()
    for _, v in pairs(_weapFX) do pcall(function() v:Destroy() end) end
    _weapFX = {}
end

local function applyWeaponFX(tool)
    removeWeaponFX()
    if not tool then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    -- Torna a arma cyan/azul
    pcall(function()
        handle.BrickColor = BrickColor.new("Cyan")
        handle.Material   = Enum.Material.Neon
        if handle:IsA("MeshPart") then handle.TextureID = "" end
    end)
    table.insert(_weapFX, {Destroy=function()
        pcall(function()
            handle.BrickColor = BrickColor.new("Medium stone grey")
            handle.Material   = Enum.Material.SmoothPlastic
        end)
    end})

    -- Luz pulsante azul escuro
    local light = Instance.new("PointLight")
    light.Name       = "_WeapLight"
    light.Color      = Color3.fromRGB(0, 80, 255)
    light.Brightness = 8
    light.Range      = 14
    light.Parent     = handle
    table.insert(_weapFX, light)

    task.spawn(function()
        while light.Parent do
            TweenSvc:Create(light, TweenInfo.new(0.65,Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut),{Brightness=2}):Play()
            task.wait(0.65)
            if not light.Parent then break end
            TweenSvc:Create(light, TweenInfo.new(0.65,Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut),{Brightness=8}):Play()
            task.wait(0.65)
        end
    end)

    -- Bolinhas azuis grandes (como print 1)
    local pe1 = Instance.new("ParticleEmitter")
    pe1.Name         = "_WeapOrbs"
    pe1.Color        = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,  210, 255)),
        ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,  100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,   40, 180)),
    })
    pe1.LightEmission = 1
    pe1.LightInfluence= 0
    pe1.Size         = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.32),
        NumberSequenceKeypoint.new(0.5,0.18),
        NumberSequenceKeypoint.new(1, 0),
    })
    pe1.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 1),
    })
    pe1.Rate         = 14
    pe1.Lifetime     = NumberRange.new(0.3, 0.8)
    pe1.Speed        = NumberRange.new(1.5, 5)
    pe1.SpreadAngle  = Vector2.new(180, 180)
    pe1.RotSpeed     = NumberRange.new(0, 60)
    pe1.Rotation     = NumberRange.new(0, 360)
    pe1.Parent       = handle
    table.insert(_weapFX, pe1)

    -- Bolinhas menores + rápidas (sparks)
    local pe2 = Instance.new("ParticleEmitter")
    pe2.Name         = "_WeapSparks"
    pe2.Color        = ColorSequence.new(Color3.fromRGB(180, 240, 255))
    pe2.LightEmission = 1
    pe2.LightInfluence= 0
    pe2.Size         = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 0),
    })
    pe2.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    pe2.Rate         = 22
    pe2.Lifetime     = NumberRange.new(0.1, 0.3)
    pe2.Speed        = NumberRange.new(3, 9)
    pe2.SpreadAngle  = Vector2.new(180, 180)
    pe2.Parent       = handle
    table.insert(_weapFX, pe2)
end

-- Monitora equipar/desequipar
local function watchTools(c)
    c.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and weaponOn then
            task.wait(0.08)
            applyWeaponFX(child)
        end
    end)
    c.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            removeWeaponFX()
        end
    end)
end
if char then watchTools(char) end
lp.CharacterAdded:Connect(function(c)
    refreshChar(c)
    watchTools(c)
    -- Reaplicar skins no respawn
    task.wait(0.2)
    if skinOn   then applySombraSkin() end
    if weaponOn then
        local t = c:FindFirstChildOfClass("Tool")
        if t then applyWeaponFX(t) end
    end
end)

-- ================================================================
-- EFEITO DE MORTE TROVÃO + PEDRAS
-- Baseado nas prints: raio atingindo + pedras voando + corpo preto
-- Igual print 2: pedras escuras + glow azul na arma do killer
-- ================================================================

-- Encontra todos os inimigos e hookeia morte
local function setupKillFX(p)
    local function hookChar(c)
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        local r = c:FindFirstChild("HumanoidRootPart")
        if not h or not r then return end
        h.Died:Connect(function()
            if not killFXOn then return end
            local pos = r.Position

            task.spawn(function()
                -- 1. SOM DE RAIO ATINGINDO ALGO
                local sndPart = Instance.new("Part")
                sndPart.Anchored    = true
                sndPart.CanCollide  = false
                sndPart.Transparency= 1
                sndPart.Size        = Vector3.new(1,1,1)
                sndPart.CFrame      = CFrame.new(pos)
                sndPart.Parent      = workspace

                local snd = Instance.new("Sound", sndPart)
                snd.SoundId  = "rbxassetid://4590529876"  -- thunderstrike
                snd.Volume   = 1.8
                snd.RollOffMaxDistance = 80
                snd:Play()

                local snd2 = Instance.new("Sound", sndPart)
                snd2.SoundId = "rbxassetid://1368605289"  -- impact crack
                snd2.Volume  = 1.2
                snd2.RollOffMaxDistance = 60
                snd2:Play()

                Debris:AddItem(sndPart, 5)

                -- 2. RAIO VERTICAL CAINDO (zigzag, como print 1)
                local boltModel = Instance.new("Model", workspace)
                local rng = Random.new()
                local cur = pos + Vector3.new(0, 30, 0)
                local nSegs = 20

                for i = 1, nSegs do
                    local p2 = Instance.new("Part")
                    p2.Anchored    = true
                    p2.CanCollide  = false
                    p2.CanTouch    = false
                    p2.CastShadow  = false
                    p2.Material    = Enum.Material.Neon
                    p2.Color       = Color3.fromRGB(80, 200, 255)
                    p2.Transparency= 0.1
                    local segLen   = 30 / nSegs
                    p2.Size        = Vector3.new(0.2, 0.2, segLen + rng:NextNumber(0.2,0.8))
                    p2.TopSurface  = Enum.SurfaceType.Smooth
                    p2.BottomSurface = Enum.SurfaceType.Smooth

                    local nx = cur + Vector3.new(
                        (rng:NextNumber()-0.5)*2.8,
                        -segLen,
                        (rng:NextNumber()-0.5)*2.8
                    )
                    p2.CFrame = CFrame.lookAt(cur, nx) * CFrame.new(0, 0, -segLen/2)
                    p2.Parent = boltModel
                    cur = nx

                    -- luz em alguns segmentos
                    if i % 4 == 0 then
                        local sl = Instance.new("PointLight", p2)
                        sl.Color      = Color3.fromRGB(80, 200, 255)
                        sl.Brightness = 8
                        sl.Range      = 16
                        TweenSvc:Create(sl, TweenInfo.new(0.5,Enum.EasingStyle.Linear),
                            {Brightness=0,Range=0}):Play()
                    end
                    TweenSvc:Create(p2, TweenInfo.new(0.55,Enum.EasingStyle.Sine),{
                        Transparency=1, Color=Color3.fromRGB(200,240,255),
                    }):Play()
                end
                Debris:AddItem(boltModel, 2)

                -- Flash de impacto no chão
                local flash = Instance.new("Part", workspace)
                flash.Anchored    = true
                flash.CanCollide  = false
                flash.Transparency= 0.2
                flash.Material    = Enum.Material.Neon
                flash.Color       = Color3.fromRGB(200,240,255)
                flash.Size        = Vector3.new(6,0.3,6)
                flash.CFrame      = CFrame.new(pos+Vector3.new(0,0.2,0))
                local fl = Instance.new("PointLight",flash)
                fl.Color=Color3.fromRGB(80,200,255) fl.Brightness=40 fl.Range=40
                TweenSvc:Create(flash,TweenInfo.new(0.4,Enum.EasingStyle.Quad),
                    {Transparency=1,Size=Vector3.new(0.1,0.1,0.1)}):Play()
                TweenSvc:Create(fl,TweenInfo.new(0.4,Enum.EasingStyle.Quad),
                    {Brightness=0,Range=0}):Play()
                Debris:AddItem(flash, 1)

                -- 3. PEDRAS ESCURAS VOANDO (como print 2)
                local rockModel = Instance.new("Model", workspace)
                for i = 1, 18 do
                    local rock = Instance.new("Part")
                    rock.Anchored    = true
                    rock.CanCollide  = false
                    rock.CanTouch    = false
                    rock.Material    = Enum.Material.SmoothPlastic
                    rock.Color       = Color3.fromRGB(
                        math.random(10,35),
                        math.random(10,35),
                        math.random(10,35)
                    )
                    local rs = rng:NextNumber(0.25, 0.85)
                    rock.Size        = Vector3.new(rs, rs*0.7, rs*0.5)
                    rock.CFrame      = CFrame.new(pos + Vector3.new(0,1,0))
                        * CFrame.Angles(
                            math.rad(rng:NextNumber(0,360)),
                            math.rad(rng:NextNumber(0,360)),
                            math.rad(rng:NextNumber(0,360))
                        )
                    rock.Parent      = rockModel

                    -- trajectória: voa pra fora e cai
                    local angle  = (i/18) * math.pi*2 + rng:NextNumber(-0.4,0.4)
                    local radius = rng:NextNumber(3, 8)
                    local height = rng:NextNumber(2, 7)
                    local dest   = pos + Vector3.new(
                        math.cos(angle)*radius,
                        height,
                        math.sin(angle)*radius
                    )
                    local dest2 = Vector3.new(dest.X, pos.Y - rng:NextNumber(0,1), dest.Z)
                    local dur   = rng:NextNumber(0.5, 1.2)

                    TweenSvc:Create(rock, TweenInfo.new(dur*0.6, Enum.EasingStyle.Quad,
                        Enum.EasingDirection.Out), {CFrame=CFrame.new(dest)
                        * CFrame.Angles(math.rad(rng:NextNumber(0,360)),
                            math.rad(rng:NextNumber(0,360)),
                            math.rad(rng:NextNumber(0,360)))}):Play()

                    task.delay(dur*0.6, function()
                        TweenSvc:Create(rock, TweenInfo.new(dur*0.4,Enum.EasingStyle.Quad,
                            Enum.EasingDirection.In),{CFrame=CFrame.new(dest2)
                            * CFrame.Angles(math.rad(rng:NextNumber(0,720)),
                                math.rad(rng:NextNumber(0,720)),
                                0)}):Play()
                    end)
                end
                Debris:AddItem(rockModel, 5)

                -- 4. CORPO FICA PRETO + bolinhas amarelas
                task.wait(0.1)
                for _, dp in pairs(c:GetDescendants()) do
                    if dp:IsA("BasePart") then
                        pcall(function()
                            dp.BrickColor  = BrickColor.new("Really black")
                            dp.Material    = Enum.Material.Neon
                            dp.Reflectance = 0
                            if dp:IsA("MeshPart") then dp.TextureID = "" end
                        end)
                    elseif dp:IsA("Decal") or dp:IsA("Shirt") or dp:IsA("Pants")
                    or dp:IsA("ShirtGraphic") or dp:IsA("SurfaceAppearance") then
                        pcall(function() dp.Transparency = 1 end)
                    end
                end

                -- bolinhas amarelas saindo do corpo
                if r and r.Parent then
                    local ye = Instance.new("ParticleEmitter")
                    ye.Name          = "_DeathOrbs"
                    ye.Color         = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,230,0)),
                        ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,160,0)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,80,0)),
                    })
                    ye.LightEmission = 1
                    ye.LightInfluence= 0
                    ye.Size          = NumberSequence.new({
                        NumberSequenceKeypoint.new(0,0.4),
                        NumberSequenceKeypoint.new(0.6,0.22),
                        NumberSequenceKeypoint.new(1,0),
                    })
                    ye.Transparency  = NumberSequence.new({
                        NumberSequenceKeypoint.new(0,0.1),
                        NumberSequenceKeypoint.new(1,1),
                    })
                    ye.Rate          = 30
                    ye.Lifetime      = NumberRange.new(1.0, 2.8)
                    ye.Speed         = NumberRange.new(2, 8)
                    ye.SpreadAngle   = Vector2.new(180,180)
                    ye.RotSpeed      = NumberRange.new(0,90)
                    ye.Rotation      = NumberRange.new(0,360)
                    ye.Parent        = r

                    local ylight = Instance.new("PointLight", r)
                    ylight.Color      = Color3.fromRGB(255,200,0)
                    ylight.Brightness = 5
                    ylight.Range      = 14
                    TweenSvc:Create(ylight,TweenInfo.new(5,Enum.EasingStyle.Linear),
                        {Brightness=0,Range=0}):Play()
                    Debris:AddItem(ylight,5.5)

                    task.delay(4, function()
                        pcall(function() ye.Enabled = false end)
                    end)
                    Debris:AddItem(ye, 10)
                end
            end)
        end)
    end
    hookChar(p.Character)
    p.CharacterAdded:Connect(hookChar)
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= lp then setupKillFX(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= lp then setupKillFX(p) end
end)

-- ================================================================
-- ================================================================
-- HUB GUI — Tech style
-- ================================================================
-- ================================================================
local HubGui = make("ScreenGui",{
    Name="MVS_Hub", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=500,
}, pgui)

-- ── Painel principal (começa fora à esquerda) ────────────────────
local panel = make("Frame",{
    Size=UDim2.new(0,300,0,420),
    AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(-0.28,0,0.5,0),
    BackgroundColor3=Color3.fromRGB(2,4,14),
    BackgroundTransparency=0.06,
    BorderSizePixel=0, ZIndex=2,
}, HubGui)
make("UICorner",{CornerRadius=UDim.new(0,16)},panel)

local panelStroke = make("UIStroke",{
    Color=Color3.fromRGB(0,200,255),
    Thickness=1.6, Transparency=0.08,
}, panel)

-- Gradiente interno animado
local pg = make("UIGradient",{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,3,14)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0,18,50)),
        ColorSequenceKeypoint.new(0.65,Color3.fromRGB(0,35,80)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,3,14)),
    }),
    Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.08),
        NumberSequenceKeypoint.new(0.5,0),
        NumberSequenceKeypoint.new(1,0.08),
    }),
    Rotation=80,
}, panel)

task.spawn(function()
    local t=0
    while HubGui.Parent do
        t=t+0.01
        pg.Rotation=80+math.sin(t)*35
        panelStroke.Transparency=0.08+math.sin(t*2)*0.1
        RunService.RenderStepped:Wait()
    end
end)

-- Scan lines
for i=1,22 do
    make("Frame",{
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,i/22,0),
        BackgroundColor3=Color3.fromRGB(0,140,255),
        BackgroundTransparency=0.90, BorderSizePixel=0, ZIndex=3,
    },panel)
end

-- Linha de luz descendo
local scanLine = make("Frame",{
    Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,-0.02,0),
    BackgroundColor3=Color3.fromRGB(0,200,255),
    BackgroundTransparency=0.25, BorderSizePixel=0, ZIndex=4,
},panel)
make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,220,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,0)),
})},scanLine)
task.spawn(function()
    while HubGui.Parent do
        TweenSvc:Create(scanLine,TweenInfo.new(2,Enum.EasingStyle.Sine),
            {Position=UDim2.new(0,0,1.02,0)}):Play()
        task.wait(2)
        scanLine.Position=UDim2.new(0,0,-0.02,0)
        task.wait(0.06)
    end
end)

-- Accent top
local accent = make("Frame",{
    Size=UDim2.new(0.7,0,0,3), AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,200,255),
    BorderSizePixel=0, ZIndex=5,
},panel)
make("UICorner",{CornerRadius=UDim.new(1,0)},accent)
TweenSvc:Create(accent,TweenInfo.new(1.3,Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,-1,true),
    {BackgroundColor3=Color3.fromRGB(0,80,200)}):Play()

-- Header
local headerLbl = make("TextLabel",{
    Size=UDim2.new(1,-44,0,28), Position=UDim2.new(0,14,0,12),
    BackgroundTransparency=1, Text="MVS  SKIN  HUB",
    TextColor3=Color3.fromRGB(255,255,255),
    Font=Enum.Font.GothamBlack, TextSize=17,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5,
},panel)
make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,200,255)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(0,200,255)),
})},headerLbl)

make("TextLabel",{
    Size=UDim2.new(1,-28,0,16), Position=UDim2.new(0,14,0,38),
    BackgroundTransparency=1, Text="script by tolopoofcpae / tolopo637883",
    TextColor3=Color3.fromRGB(0,130,200),
    Font=Enum.Font.Gotham, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5,
},panel)

-- Divider
make("Frame",{
    Size=UDim2.new(0.88,0,0,1), Position=UDim2.new(0.06,0,0,60),
    BackgroundColor3=Color3.fromRGB(0,160,255),
    BackgroundTransparency=0.5, BorderSizePixel=0, ZIndex=5,
},panel)

-- Close
local closeBtn = make("TextButton",{
    Size=UDim2.new(0,26,0,26), AnchorPoint=Vector2.new(1,0),
    Position=UDim2.new(1,-9,0,9),
    Text="X", TextColor3=Color3.fromRGB(180,80,80),
    Font=Enum.Font.GothamBlack, TextSize=13,
    BackgroundColor3=Color3.fromRGB(25,6,6),
    BackgroundTransparency=0.3, BorderSizePixel=0, ZIndex=8,
},panel)
make("UICorner",{CornerRadius=UDim.new(1,0)},closeBtn)
make("UIStroke",{Color=Color3.fromRGB(180,55,55),Thickness=1},closeBtn)

-- ================================================================
-- TOGGLE ROW FACTORY
-- ================================================================
local function makeToggleRow(parent, ypos, label, sublabel, accent_col)
    local row = make("Frame",{
        Size=UDim2.new(1,-22,0,58), Position=UDim2.new(0,11,0,ypos),
        BackgroundColor3=Color3.fromRGB(0,10,32),
        BackgroundTransparency=0.25, BorderSizePixel=0, ZIndex=5,
    }, parent)
    make("UICorner",{CornerRadius=UDim.new(0,10)},row)
    make("UIStroke",{Color=Color3.fromRGB(0,100,200),Thickness=1},row)

    -- left color accent bar
    local bar = make("Frame",{
        Size=UDim2.new(0,3,0.7,0), AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=accent_col or Color3.fromRGB(0,200,255),
        BorderSizePixel=0, ZIndex=6,
    }, row)
    make("UICorner",{CornerRadius=UDim.new(1,0)},bar)

    make("TextLabel",{
        Size=UDim2.new(0.65,0,0,24), Position=UDim2.new(0,14,0,6),
        BackgroundTransparency=1, Text=label,
        TextColor3=Color3.fromRGB(220,240,255),
        Font=Enum.Font.GothamBold, TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
    }, row)
    make("TextLabel",{
        Size=UDim2.new(0.65,0,0,18), Position=UDim2.new(0,14,0,30),
        BackgroundTransparency=1, Text=sublabel,
        TextColor3=Color3.fromRGB(60,120,190),
        Font=Enum.Font.Gotham, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
    }, row)

    -- Toggle switch
    local togBG = make("Frame",{
        Size=UDim2.new(0,52,0,28), AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-10,0.5,0),
        BackgroundColor3=Color3.fromRGB(22,22,44),
        BorderSizePixel=0, ZIndex=6,
    }, row)
    make("UICorner",{CornerRadius=UDim.new(1,0)},togBG)
    make("UIStroke",{Color=Color3.fromRGB(70,70,120),Thickness=1},togBG)

    local knob = make("Frame",{
        Size=UDim2.new(0,22,0,22), AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,3,0.5,0),
        BackgroundColor3=Color3.fromRGB(100,100,150),
        BorderSizePixel=0, ZIndex=7,
    }, togBG)
    make("UICorner",{CornerRadius=UDim.new(1,0)},knob)

    -- Invisible hit
    local btn = make("TextButton",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text="", ZIndex=8,
    }, row)

    return {row=row, btn=btn, togBG=togBG, knob=knob, bar=bar}
end

local function setToggleOn(t, accentCol)
    tw(t.togBG,0.2,{BackgroundColor3=Color3.fromRGB(0,38,90)})
    tw(t.knob, 0.2,{Position=UDim2.new(1,-25,0.5,0),
        BackgroundColor3=accentCol or Color3.fromRGB(0,200,255)})
    tw(t.row,  0.2,{BackgroundTransparency=0.1})
end

local function setToggleOff(t)
    tw(t.togBG,0.2,{BackgroundColor3=Color3.fromRGB(22,22,44)})
    tw(t.knob, 0.2,{Position=UDim2.new(0,3,0.5,0),
        BackgroundColor3=Color3.fromRGB(100,100,150)})
    tw(t.row,  0.2,{BackgroundTransparency=0.25})
end

-- SECCIÓN header
local function sectionLabel(parent, text, ypos)
    make("TextLabel",{
        Size=UDim2.new(1,-22,0,18), Position=UDim2.new(0,11,0,ypos),
        BackgroundTransparency=1, Text=text,
        TextColor3=Color3.fromRGB(0,160,255),
        Font=Enum.Font.GothamBold, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5,
    }, parent)
    make("Frame",{
        Size=UDim2.new(0.88,0,0,1), Position=UDim2.new(0.06,0,0,ypos+19),
        BackgroundColor3=Color3.fromRGB(0,100,180),
        BackgroundTransparency=0.65, BorderSizePixel=0, ZIndex=5,
    }, parent)
end

-- === SKIN ===
sectionLabel(panel, "SKIN", 68)

local sombraRow = makeToggleRow(panel, 92, "Sombra",
    "Corpo preto + glow cyan", Color3.fromRGB(0,200,255))
sombraRow.btn.MouseButton1Up:Connect(function()
    skinOn = not skinOn
    if skinOn then
        setToggleOn(sombraRow, Color3.fromRGB(0,200,255))
        applySombraSkin()
    else
        setToggleOff(sombraRow)
        removeSombraSkin()
    end
end)

-- === ARMA ===
sectionLabel(panel, "ARMA / FACA", 160)

local weapRow = makeToggleRow(panel, 184, "Arma Azul",
    "Faca + Arma cyan LED + bolinha", Color3.fromRGB(0,150,255))
weapRow.btn.MouseButton1Up:Connect(function()
    weaponOn = not weaponOn
    if weaponOn then
        setToggleOn(weapRow, Color3.fromRGB(0,150,255))
        if char then
            local t = char:FindFirstChildOfClass("Tool")
            if t then applyWeaponFX(t) end
        end
    else
        setToggleOff(weapRow)
        removeWeaponFX()
    end
end)

-- === EFEITO DE MORTE ===
sectionLabel(panel, "EFEITO DE MORTE", 252)

local killRow = makeToggleRow(panel, 276, "Trovao Kill",
    "Raio + pedras + corpo preto + som", Color3.fromRGB(255,210,0))
killRow.btn.MouseButton1Up:Connect(function()
    killFXOn = not killFXOn
    if killFXOn then
        setToggleOn(killRow, Color3.fromRGB(255,210,0))
    else
        setToggleOff(killRow)
    end
end)

-- === APPLY ALL ===
sectionLabel(panel, "", 344)
make("Frame",{
    Size=UDim2.new(0.88,0,0,1), Position=UDim2.new(0.06,0,0,348),
    BackgroundColor3=Color3.fromRGB(0,100,180),
    BackgroundTransparency=0.65, BorderSizePixel=0, ZIndex=5,
}, panel)

local applyAllBtn = make("TextButton",{
    Size=UDim2.new(1,-22,0,44), Position=UDim2.new(0,11,0,356),
    Text="ATIVAR TUDO",
    TextColor3=Color3.fromRGB(255,255,255),
    Font=Enum.Font.GothamBlack, TextSize=15,
    BackgroundColor3=Color3.fromRGB(0,60,180),
    BorderSizePixel=0, ZIndex=5,
},panel)
make("UICorner",{CornerRadius=UDim.new(0,10)},applyAllBtn)
make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,90,255)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,55,200)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(0,90,255)),
}),Rotation=90},applyAllBtn)
make("UIStroke",{Color=Color3.fromRGB(0,160,255)},applyAllBtn)

applyAllBtn.MouseButton1Down:Connect(function()
    tw(applyAllBtn,0.07,{Size=UDim2.new(1,-30,0,40),Position=UDim2.new(0,15,0,358)})
end)
applyAllBtn.MouseButton1Up:Connect(function()
    TweenSvc:Create(applyAllBtn,TweenInfo.new(0.12,Enum.EasingStyle.Back,
        Enum.EasingDirection.Out),
        {Size=UDim2.new(1,-22,0,44),Position=UDim2.new(0,11,0,356)}):Play()

    -- Ativa tudo
    if not skinOn then
        skinOn = true
        setToggleOn(sombraRow, Color3.fromRGB(0,200,255))
        applySombraSkin()
    end
    if not weaponOn then
        weaponOn = true
        setToggleOn(weapRow, Color3.fromRGB(0,150,255))
        if char then
            local t = char:FindFirstChildOfClass("Tool")
            if t then applyWeaponFX(t) end
        end
    end
    if not killFXOn then
        killFXOn = true
        setToggleOn(killRow, Color3.fromRGB(255,210,0))
    end

    -- Flash no botão
    TweenSvc:Create(applyAllBtn,TweenInfo.new(0.15),
        {BackgroundColor3=Color3.fromRGB(0,180,80)}):Play()
    task.delay(0.4,function()
        TweenSvc:Create(applyAllBtn,TweenInfo.new(0.3),
            {BackgroundColor3=Color3.fromRGB(0,60,180)}):Play()
    end)
end)

-- ================================================================
-- HUB BUTTON — arrastável
-- ================================================================
panel.Visible = false

local hubBtn = make("Frame",{
    Size=UDim2.new(0,62,0,62), AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.07,0,0.54,0),
    BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=0.55, BorderSizePixel=0, ZIndex=10,
},HubGui)
make("UICorner",{CornerRadius=UDim.new(1,0)},hubBtn)
local hubStroke = make("UIStroke",{
    Color=Color3.fromRGB(0,200,255),Thickness=2.2,
},hubBtn)

-- Gap transparente
local hubGap = make("Frame",{
    Size=UDim2.new(0,49,0,49), AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,0.5,0),
    BackgroundTransparency=1, BorderSizePixel=0, ZIndex=11,
},hubBtn)
make("UICorner",{CornerRadius=UDim.new(1,0)},hubGap)

-- Inner circle
local hubInner = make("Frame",{
    Size=UDim2.new(0,44,0,44), AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,0.5,0),
    BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=0.42, BorderSizePixel=0, ZIndex=12,
},hubBtn)
make("UICorner",{CornerRadius=UDim.new(1,0)},hubInner)

local hubLbl = make("TextLabel",{
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text="HUB", TextColor3=Color3.fromRGB(0,200,255),
    Font=Enum.Font.GothamBlack, TextScaled=true, ZIndex=13,
},hubInner)

-- Pulsação do botão
TweenSvc:Create(hubStroke,TweenInfo.new(1.2,Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,-1,true),
    {Transparency=0.65}):Play()
TweenSvc:Create(hubBtn,TweenInfo.new(1.2,Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,-1,true),
    {BackgroundTransparency=0.75}):Play()

-- Touch
local hubTouchBtn = make("TextButton",{
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text="", ZIndex=14,
},hubBtn)
make("UICorner",{CornerRadius=UDim.new(1,0)},hubTouchBtn)

-- Drag
local dg, ds, dp2 = false, nil, nil
hubTouchBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dg=true ds=inp.Position dp2=hubBtn.Position
    end
end)
hubTouchBtn.InputChanged:Connect(function(inp)
    if dg and (inp.UserInputType==Enum.UserInputType.Touch
    or inp.UserInputType==Enum.UserInputType.MouseMovement) then
        local d = inp.Position-ds
        hubBtn.Position=UDim2.new(
            dp2.X.Scale,dp2.X.Offset+d.X,
            dp2.Y.Scale,dp2.Y.Offset+d.Y)
    end
end)
hubTouchBtn.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.Touch
    or inp.UserInputType==Enum.UserInputType.MouseButton1 then
        dg=false
    end
end)

-- Press feedback
hubTouchBtn.MouseButton1Down:Connect(function()
    tw(hubBtn,0.07,{Size=UDim2.new(0,54,0,54)})
end)

-- Open/close menu
local menuOpen = false
local function toggleHub()
    menuOpen = not menuOpen
    if menuOpen then
        panel.Visible = true
        -- Open para a direita do botão HUB
        local bx = hubBtn.AbsolutePosition.X + hubBtn.AbsoluteSize.X + 10
        local by = hubBtn.AbsolutePosition.Y + hubBtn.AbsoluteSize.Y/2
        local vp = panel.Parent.AbsoluteSize
        local sx = math.min(bx / vp.X, 0.88)
        panel.AnchorPoint = Vector2.new(0,0.5)
        panel.Position = UDim2.new(sx-0.25,0,by/vp.Y,0)
        TweenSvc:Create(panel,TweenInfo.new(0.42,Enum.EasingStyle.Back,
            Enum.EasingDirection.Out),{Position=UDim2.new(sx,0,by/vp.Y,0)}):Play()
        TweenSvc:Create(hubBtn,TweenInfo.new(0.12,Enum.EasingStyle.Back,
            Enum.EasingDirection.Out),{Size=UDim2.new(0,62,0,62)}):Play()
        hubStroke.Color = Color3.fromRGB(0,255,120)
        hubLbl.TextColor3 = Color3.fromRGB(0,255,120)
    else
        local vp = panel.Parent.AbsoluteSize
        local bx = hubBtn.AbsolutePosition.X + hubBtn.AbsoluteSize.X + 10
        local by = hubBtn.AbsolutePosition.Y + hubBtn.AbsoluteSize.Y/2
        local sx = math.min(bx / vp.X, 0.88)
        TweenSvc:Create(panel,TweenInfo.new(0.28,Enum.EasingStyle.Back,
            Enum.EasingDirection.In),{Position=UDim2.new(sx-0.25,0,by/vp.Y,0)}):Play()
        task.delay(0.3,function() panel.Visible=false end)
        hubStroke.Color = Color3.fromRGB(0,200,255)
        hubLbl.TextColor3 = Color3.fromRGB(0,200,255)
    end
end

hubTouchBtn.MouseButton1Up:Connect(function()
    tw(hubBtn,0.12,{Size=UDim2.new(0,62,0,62)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    toggleHub()
end)
closeBtn.MouseButton1Up:Connect(toggleHub)

-- Slide in do botão ao carregar
hubBtn.Position = UDim2.new(hubBtn.Position.X.Scale,
    hubBtn.Position.X.Offset,
    hubBtn.Position.Y.Scale+0.3,
    hubBtn.Position.Y.Offset)
TweenSvc:Create(hubBtn,TweenInfo.new(0.55,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Position=UDim2.new(0.07,0,0.54,0),
}):Play()
