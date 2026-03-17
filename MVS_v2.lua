-- Murderers vs Sheriffs | Silent Aim v2
-- script by tolopoofcpae / tolopo637883

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenSvc   = game:GetService("TweenService")
local UIS        = game:GetService("UserInputService")
local RS         = game:GetService("ReplicatedStorage")
local Debris     = game:GetService("Debris")
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
-- WEAPON DETECTION
-- In this game: Knife = murderer weapon, Gun = sheriff weapon
-- Tools are named exactly "Knife" and "Gun" in the character
-- ================================================================
local function getEquipped()
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function isGun(t)
    if not t then return false end
    if t.Name == "Gun" then return true end
    if t:FindFirstChild("Barrel") then return true end
    return false
end

local function isKnife(t)
    if not t then return false end
    if t.Name == "Knife" then return true end
    local h = t:FindFirstChild("Handle")
    if h and h:FindFirstChild("Slash") then return true end
    return false
end

-- ================================================================
-- ENEMY DETECTION
-- Only target players on opposite team (or all if mode = Players)
-- ================================================================
local function isEnemy(p)
    if p == lp then return false end
    if not p.Team or not lp.Team then return true end
    if lp.Team.Name == "Players" then return p ~= lp end
    return p.Team ~= lp.Team
end

-- Returns: (character, hrpPart) of nearest enemy
-- useScreen: find nearest to screen center instead of 3D distance
local function getNearestEnemy(useScreen)
    if not hrp then return nil, nil end
    local bestChar, bestHRP, bestScore = nil, nil, math.huge
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)

    for _, p in pairs(Players:GetPlayers()) do
        if isEnemy(p) then
            local c = p.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                local r = c:FindFirstChild("HumanoidRootPart")
                if h and r and h.Health > 0 and not c:FindFirstChildOfClass("ForceField") then
                    -- Ignore if tagged IgnoreProjectiles (forcefields etc)
                    local score
                    if useScreen then
                        local sp, onScreen = cam:WorldToViewportPoint(r.Position)
                        if not onScreen then
                            -- Still consider but with big penalty
                            score = 9999 + (hrp.Position - r.Position).Magnitude
                        else
                            score = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        end
                    else
                        score = (hrp.Position - r.Position).Magnitude
                    end
                    if score < bestScore then
                        bestScore = score
                        bestChar  = c
                        bestHRP   = r
                    end
                end
            end
        end
    end
    return bestChar, bestHRP
end

-- ================================================================
-- SA + KILL TRACKING STATE
-- ================================================================
local saActive     = false
local thunderOn    = false
local _bypass      = false
local _knifeCD     = false
local _gunCD       = false
local killTargets  = {}  -- [Player] = true → apply kill FX on death

-- ================================================================
-- BLUE WEAPON EFFECTS
-- Applied to current tool's Handle when equipped
-- Removed when unequipped
-- ================================================================
local weaponFXParts = {}  -- store created instances to clean up

local function removeWeaponFX()
    for _, v in pairs(weaponFXParts) do
        pcall(function() v:Destroy() end)
    end
    weaponFXParts = {}
end

local function applyWeaponFX(tool)
    removeWeaponFX()
    if not tool then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    -- Deep blue PointLight (pulsing)
    local light = Instance.new("PointLight")
    light.Name       = "_BlueFX_Light"
    light.Color      = Color3.fromRGB(0, 80, 255)
    light.Brightness = 7
    light.Range      = 16
    light.Parent     = handle
    table.insert(weaponFXParts, light)

    -- Pulse the light
    task.spawn(function()
        while light.Parent do
            TweenSvc:Create(light, TweenInfo.new(0.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut), {Brightness=3}):Play()
            task.wait(0.7)
            if not light.Parent then break end
            TweenSvc:Create(light, TweenInfo.new(0.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut), {Brightness=7}):Play()
            task.wait(0.7)
        end
    end)

    -- Blue orb particles (no trail)
    local pe = Instance.new("ParticleEmitter")
    pe.Name          = "_BlueFX_Emit"
    pe.Color         = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 200, 255)),
        ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0, 100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,  40, 180)),
    })
    pe.LightEmission = 1
    pe.LightInfluence = 0
    pe.Size          = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.28),
        NumberSequenceKeypoint.new(0.5,0.15),
        NumberSequenceKeypoint.new(1, 0),
    })
    pe.Transparency  = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    pe.Rate          = 12
    pe.Lifetime      = NumberRange.new(0.25, 0.65)
    pe.Speed         = NumberRange.new(1.5, 5)
    pe.SpreadAngle   = Vector2.new(180, 180)
    pe.RotSpeed      = NumberRange.new(0, 45)
    pe.Rotation      = NumberRange.new(0, 360)
    pe.Parent        = handle
    table.insert(weaponFXParts, pe)

    -- Secondary smaller faster particles
    local pe2 = Instance.new("ParticleEmitter")
    pe2.Name          = "_BlueFX_Emit2"
    pe2.Color         = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 240, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,  150, 255)),
    })
    pe2.LightEmission = 1
    pe2.LightInfluence = 0
    pe2.Size          = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.12),
        NumberSequenceKeypoint.new(1, 0),
    })
    pe2.Transparency  = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    pe2.Rate          = 20
    pe2.Lifetime      = NumberRange.new(0.1, 0.35)
    pe2.Speed         = NumberRange.new(3, 8)
    pe2.SpreadAngle   = Vector2.new(180, 180)
    pe2.Parent        = handle
    table.insert(weaponFXParts, pe2)
end

-- Watch tool equip/unequip
local function watchToolEquip(c)
    c.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.08)
            applyWeaponFX(child)
            child.Unequipping:Connect(function()
                removeWeaponFX()
            end)
        end
    end)
    c.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            removeWeaponFX()
        end
    end)
end

if char then watchToolEquip(char) end
lp.CharacterAdded:Connect(function(c)
    refreshChar(c)
    _bypass = false _knifeCD = false _gunCD = false
    watchToolEquip(c)
    killTargets = {}
end)

-- Apply FX to whatever is currently equipped when script loads
task.spawn(function()
    task.wait(0.5)
    local t = getEquipped()
    if t then applyWeaponFX(t) end
end)

-- ================================================================
-- THUNDER KILL EFFECT
-- Triggered when a tracked kill target dies
-- 1. Thunder sound
-- 2. Lightning bolt (vertical stripe falling)
-- 3. Mini explosion burst
-- 4. Body turns black
-- 5. Yellow orbs float from body
-- ================================================================
local function playThunderKillFX(deadChar, deadHRP)
    if not deadChar or not deadHRP then return end
    local pos = deadHRP.Position

    -- 1. THUNDER SOUND
    pcall(function()
        local snd = Instance.new("Sound")
        snd.SoundId  = "rbxassetid://4590529876"  -- thunder crack
        snd.Volume   = 1.8
        snd.RollOffMaxDistance = 80
        snd.Parent   = deadHRP
        snd:Play()
        Debris:AddItem(snd, 4)
    end)
    pcall(function()
        local snd2 = Instance.new("Sound")
        snd2.SoundId = "rbxassetid://3145388100"  -- explosion
        snd2.Volume  = 1
        snd2.RollOffMaxDistance = 60
        snd2.Parent  = deadHRP
        snd2:Play()
        Debris:AddItem(snd2, 3)
    end)

    -- 2. LIGHTNING BOLT — zigzag falling stripe from sky
    task.spawn(function()
        local rng   = Random.new()
        local model = Instance.new("Model")
        model.Parent = workspace

        local curPos = pos + Vector3.new(0, 35, 0)
        local steps  = 18
        local stepLen = 35 / steps

        for i = 1, steps do
            local part = Instance.new("Part")
            part.Anchored    = true
            part.CanCollide  = false
            part.CanTouch    = false
            part.CastShadow  = false
            part.Material    = Enum.Material.Neon
            part.Color       = Color3.fromRGB(80, 180, 255)
            part.Transparency = 0
            part.Size        = Vector3.new(0.18, 0.18, stepLen + rng:NextNumber(0.5,1.5))
            part.TopSurface  = Enum.SurfaceType.Smooth
            part.BottomSurface = Enum.SurfaceType.Smooth

            local ox = (rng:NextNumber() - 0.5) * 3.5
            local oz = (rng:NextNumber() - 0.5) * 3.5
            local nextPos = curPos + Vector3.new(ox, -stepLen, oz)
            part.CFrame = CFrame.lookAt(curPos, nextPos) * CFrame.new(0, 0, -stepLen/2)
            part.Parent  = model
            curPos = nextPos

            -- Surface lights on bolt
            if i % 3 == 0 then
                local sl = Instance.new("PointLight", part)
                sl.Color      = Color3.fromRGB(80, 180, 255)
                sl.Brightness = 8
                sl.Range      = 18
                TweenSvc:Create(sl, TweenInfo.new(0.4, Enum.EasingStyle.Linear), {
                    Brightness = 0, Range = 0,
                }):Play()
            end

            -- Fade out
            TweenSvc:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
                Transparency = 1,
                Color        = Color3.fromRGB(200, 240, 255),
            }):Play()
        end

        -- Bright impact flash
        local flashPart = Instance.new("Part")
        flashPart.Anchored    = true
        flashPart.CanCollide  = false
        flashPart.CanTouch    = false
        flashPart.Transparency = 0.3
        flashPart.Material    = Enum.Material.Neon
        flashPart.Color       = Color3.fromRGB(200, 240, 255)
        flashPart.Size        = Vector3.new(5, 0.5, 5)
        flashPart.CFrame      = CFrame.new(pos + Vector3.new(0, 0.5, 0))
        flashPart.Parent      = model

        local flashLight = Instance.new("PointLight", flashPart)
        flashLight.Color      = Color3.fromRGB(80, 200, 255)
        flashLight.Brightness = 35
        flashLight.Range      = 36

        TweenSvc:Create(flashPart, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {
            Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.1),
        }):Play()
        TweenSvc:Create(flashLight, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {
            Brightness = 0, Range = 0,
        }):Play()

        Debris:AddItem(model, 2.5)
    end)

    -- 3. MINI EXPLOSION — particle burst
    task.spawn(function()
        local expModel = Instance.new("Model")
        expModel.Parent = workspace

        -- Burst orbs
        for i = 1, 12 do
            local p = Instance.new("Part")
            p.Anchored    = true
            p.CanCollide  = false
            p.CanTouch    = false
            p.Material    = Enum.Material.Neon
            p.Color       = Color3.fromRGB(80, 180, 255)
            p.Size        = Vector3.new(0.4, 0.4, 0.4)
            p.CFrame      = CFrame.new(pos + Vector3.new(0, 1, 0))
            p.Parent      = expModel
            Instance.new("UICorner") -- won't work on parts but keeps intent
            local angle = (i / 12) * math.pi * 2
            local speed = 8 + Random.new():NextNumber() * 5
            local dir   = Vector3.new(math.cos(angle), 0.4, math.sin(angle)) * speed
            TweenSvc:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                CFrame        = CFrame.new(pos + Vector3.new(0,1,0) + dir * 0.5),
                Transparency  = 1,
                Size          = Vector3.new(0.05, 0.05, 0.05),
            }):Play()
        end

        -- Shockwave ring
        local ring = Instance.new("Part")
        ring.Anchored    = true
        ring.CanCollide  = false
        ring.CanTouch    = false
        ring.Material    = Enum.Material.Neon
        ring.Color       = Color3.fromRGB(60, 160, 255)
        ring.Size        = Vector3.new(0.5, 0.1, 0.5)
        ring.Transparency = 0.2
        ring.CFrame       = CFrame.new(pos + Vector3.new(0, 0.5, 0))
        ring.Parent       = expModel
        TweenSvc:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size        = Vector3.new(16, 0.05, 16),
            Transparency = 1,
        }):Play()

        Debris:AddItem(expModel, 1.5)
    end)

    -- 4. BODY TURNS BLACK  +  5. YELLOW ORB PARTICLES
    task.spawn(function()
        task.wait(0.15)
        -- Turn all body parts black
        for _, part in pairs(deadChar:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    part.BrickColor   = BrickColor.Black()
                    part.Material     = Enum.Material.Neon
                    part.Reflectance  = 0
                end)
            elseif part:IsA("Decal") or part:IsA("Texture")
            or part:IsA("Shirt") or part:IsA("Pants")
            or part:IsA("ShirtGraphic") or part:IsA("SurfaceAppearance") then
                pcall(function() part.Transparency = 1 end)
            end
        end

        -- Yellow orbs from HRP
        if deadHRP and deadHRP.Parent then
            local yellowEmit = Instance.new("ParticleEmitter")
            yellowEmit.Name          = "_KillOrbs"
            yellowEmit.Color         = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 0)),
                ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255, 180, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0)),
            })
            yellowEmit.LightEmission = 1
            yellowEmit.LightInfluence = 0
            yellowEmit.Size          = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.35),
                NumberSequenceKeypoint.new(0.6,0.22),
                NumberSequenceKeypoint.new(1, 0),
            })
            yellowEmit.Transparency  = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(1, 1),
            })
            yellowEmit.Rate          = 28
            yellowEmit.Lifetime      = NumberRange.new(1.2, 2.5)
            yellowEmit.Speed         = NumberRange.new(2, 7)
            yellowEmit.SpreadAngle   = Vector2.new(180, 180)
            yellowEmit.RotSpeed      = NumberRange.new(0, 90)
            yellowEmit.Rotation      = NumberRange.new(0, 360)
            yellowEmit.Parent        = deadHRP

            -- Stop emitting after 4 seconds
            task.delay(4, function()
                pcall(function()
                    yellowEmit.Enabled = false
                end)
            end)
            Debris:AddItem(yellowEmit, 10)

            -- Floating yellow PointLight from body
            local bodyLight = Instance.new("PointLight", deadHRP)
            bodyLight.Color      = Color3.fromRGB(255, 200, 0)
            bodyLight.Brightness = 6
            bodyLight.Range      = 14
            TweenSvc:Create(bodyLight, TweenInfo.new(5, Enum.EasingStyle.Linear), {
                Brightness = 0, Range = 0,
            }):Play()
            Debris:AddItem(bodyLight, 5.5)
        end
    end)
end

-- Hook enemy deaths
local function hookEnemyDeaths(p)
    local function tryHook(c)
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        local r = c:FindFirstChild("HumanoidRootPart")
        if not h or not r then return end

        h.Died:Connect(function()
            if thunderOn and killTargets[p] then
                killTargets[p] = nil
                task.spawn(function()
                    playThunderKillFX(c, r)
                end)
            end
        end)
    end
    tryHook(p.Character)
    p.CharacterAdded:Connect(tryHook)
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= lp then hookEnemyDeaths(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= lp then hookEnemyDeaths(p) end
end)

-- ================================================================
-- SILENT KNIFE
-- Server uses Touched detection on the knife handle.
-- We warp to enemy → register touch → warp back.
-- ================================================================
local function silentKnife()
    if _knifeCD then return end
    local _, target = getNearestEnemy(false)
    if not target or not hrp then return end
    _knifeCD = true

    local origCF = hrp.CFrame

    -- Mark kill target for thunder FX
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r and r == target then
                killTargets[p] = true
                break
            end
        end
    end

    _bypass = true
    pcall(function()
        -- Move close to enemy
        hrp.CFrame = target.CFrame * CFrame.new(0, 0, 2.1)
        task.wait(0.04)
        hrp.CFrame = target.CFrame * CFrame.new(0, 0, 1.8)
        task.wait(0.04)
    end)
    _bypass = false

    -- Return to original position
    task.delay(0.1, function()
        pcall(function()
            if hrp then hrp.CFrame = origCF end
        end)
    end)

    task.delay(1.2, function() _knifeCD = false end)
end

-- ================================================================
-- SILENT GUN
-- The gun fires by sending the target world position via FireServer.
-- We intercept via __namecall and also directly call the RemoteEvent.
-- ================================================================
local function silentGun()
    if _gunCD then return end
    local targetChar, target = getNearestEnemy(true)  -- screen-nearest
    if not target or not hrp then return end
    _gunCD = true

    -- Mark kill target
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r and r == target then
                killTargets[p] = true
                break
            end
        end
    end

    local tool = getEquipped()
    if not tool then _gunCD = false return end

    _bypass = true
    pcall(function()
        -- Try to find and fire the RemoteEvent inside the gun tool
        for _, child in pairs(tool:GetDescendants()) do
            if child:IsA("RemoteEvent") then
                child:FireServer(target.Position)
                break
            end
        end
    end)
    pcall(function()
        -- Also try firesignal to trigger the tool's normal activation
        -- The __namecall hook will redirect the Vector3 to target
        if firesignal then
            firesignal(tool.Activated)
        end
    end)
    _bypass = false

    task.delay(0.5, function() _gunCD = false end)
end

-- ================================================================
-- __namecall HOOK
-- When SA is ON:
--   - Block normal tool FireServer (when _bypass=false)
--   - When gun fires and passes through (bypass=true), ensure Vector3 goes to enemy
-- ================================================================
pcall(function()
    local oldNC
    oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()

        if method == "FireServer" or method == "InvokeServer" then
            if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then

                -- Block normal input when SA is on (not from our buttons)
                if saActive and not _bypass then
                    -- Block knife/gun related remotes
                    local n = self.Name
                    if n == "ThrowConfirmation" then return end

                    -- Block tool's own RemoteEvents
                    local tool = getEquipped()
                    if tool then
                        if self:IsDescendantOf(tool) then return end
                    end
                end

                -- When our gun fires with bypass=true, redirect Vector3 to enemy
                if saActive and _bypass then
                    local args = {...}
                    local _, target = getNearestEnemy(true)
                    if target then
                        -- Replace any Vector3 argument with target position
                        for i, arg in ipairs(args) do
                            if typeof(arg) == "Vector3" then
                                args[i] = target.Position
                                break
                            end
                        end
                        return oldNC(self, table.unpack(args))
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
local LoadGui = make("ScreenGui",{
    Name="MVS_Load", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=9999,
}, pgui)

local LBG = make("Frame",{
    Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(3,3,10),
    BorderSizePixel=0,
}, LoadGui)

local gradF = make("Frame",{
    Size=UDim2.new(4,0,1,0), Position=UDim2.new(-1.5,0,0,0),
    BackgroundTransparency=1, BorderSizePixel=0, ZIndex=2,
}, LBG)
local gradUG = make("UIGradient",{
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
        gradF.Position = UDim2.new(-1.5+math.sin(t)*0.45,0,0,0)
        gradUG.Rotation = math.sin(t*0.45)*28
        RunService.RenderStepped:Wait()
    end
end)

for i = 1, 24 do
    make("Frame",{
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,i/24,0),
        BackgroundColor3=Color3.fromRGB(0,100,228),
        BackgroundTransparency=0.88, BorderSizePixel=0, ZIndex=3,
    }, LBG)
end

local function spawnLoadDot()
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
        spawnLoadDot()
        task.wait(math.random(8,20)/100)
    end
end)

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

local card = make("Frame",{
    Size=UDim2.new(0,490,0,275), AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,1.7,0),
    BackgroundColor3=Color3.fromRGB(4,8,22),
    BackgroundTransparency=0.14, BorderSizePixel=0, ZIndex=6,
}, LBG)
make("UICorner",{CornerRadius=UDim.new(0,18)},card)
make("UIStroke",{Color=Color3.fromRGB(0,142,255),Thickness=1.8,Transparency=0.1},card)

local cardGrad = make("UIGradient",{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(0,12,35)),
        ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,28,65)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(0,12,35)),
    }), Rotation=100,
}, card)
task.spawn(function()
    local t=0
    while LoadGui.Parent do
        t=t+0.012
        cardGrad.Rotation=100+math.sin(t)*25
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
local titleGrad = make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,198,255)),
    ColorSequenceKeypoint.new(0.45,Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,198,255)),
})},titleLbl)
make("UIStroke",{Color=Color3.fromRGB(0,148,255),Thickness=1.6,Transparency=0.5},titleLbl)
task.spawn(function()
    local t=0
    while LoadGui.Parent do
        t=t+0.015
        titleGrad.Rotation=math.sin(t)*16
        RunService.RenderStepped:Wait()
    end
end)

cLbl(card,"SILENT AIM  +  BLUE FX  +  THUNDER KILL",
    98,15,Color3.fromRGB(68,152,255),Enum.Font.GothamBold)

local divLine = make("Frame",{
    Size=UDim2.new(0,0,0,1), Position=UDim2.new(0.08,0,0,134),
    BackgroundColor3=Color3.fromRGB(0,138,255),
    BackgroundTransparency=0.4, BorderSizePixel=0, ZIndex=7,
}, card)

cLbl(card,"script by tolopoofcpae / tolopo637883",144,12,Color3.fromRGB(102,168,255))

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
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,108,255)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(128,232,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(0,182,255)),
})},pbFill)

cLbl(card,"v2.0  •  THUNDER KILL FX  •  BLUE LED  •  MOBILE",
    216,10,Color3.fromRGB(26,55,110))

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
        {0.52,"Blue FX preparados..."},
        {0.70,"Thunder kill FX pronto..."},
        {0.85,"Silent aim configurado..."},
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
    Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=1, BorderSizePixel=0, ZIndex=500,
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
    Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=0.52, BorderSizePixel=0,
}, KeyGui)

local kPanel = make("Frame",{
    Size=UDim2.new(0,408,0,305), AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,1.8,0),
    BackgroundColor3=Color3.fromRGB(4,8,22),
    BackgroundTransparency=0.04, BorderSizePixel=0, ZIndex=2,
}, KeyGui)
make("UICorner",{CornerRadius=UDim.new(0,20)},kPanel)
local kpStroke = make("UIStroke",{Color=Color3.fromRGB(0,148,255),Thickness=2},kPanel)

local kPG = make("UIGradient",{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(0,10,30)),
        ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,26,58)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(0,10,30)),
    }), Rotation=112,
}, kPanel)
task.spawn(function()
    local t=0
    while KeyGui.Parent do
        t=t+0.013
        kPG.Rotation=112+math.sin(t)*20
        RunService.RenderStepped:Wait()
    end
end)

local kTopGlow = make("Frame",{
    Size=UDim2.new(0.65,0,0,3), AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,0),
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
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,194,255)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(198,238,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(0,194,255)),
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
    Text="CONFIRMAR KEY", TextColor3=Color3.fromRGB(255,255,255),
    Font=Enum.Font.GothamBlack, TextSize=15,
    BackgroundColor3=Color3.fromRGB(0,76,198),
    BorderSizePixel=0, ZIndex=3,
}, kPanel)
make("UICorner",{CornerRadius=UDim.new(0,10)},confBtn)
make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,96,255)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,54,190)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(0,96,255)),
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
-- 3. MENU GUI
-- ================================================================
-- ================================================================
local MenuGui = make("ScreenGui",{
    Name="MVS_Menu", ResetOnSpawn=false,
    IgnoreGuiInset=true, DisplayOrder=600,
}, pgui)

local menuPanel = make("Frame",{
    Size=UDim2.new(0,272,0,340), AnchorPoint=Vector2.new(0,0.5),
    Position=UDim2.new(-0.35,0,0.5,0),
    BackgroundColor3=Color3.fromRGB(2,5,16),
    BackgroundTransparency=0.08, BorderSizePixel=0, ZIndex=2,
}, MenuGui)
make("UICorner",{CornerRadius=UDim.new(0,16)},menuPanel)
local mpStroke = make("UIStroke",{
    Color=Color3.fromRGB(0,200,255),Thickness=1.5,Transparency=0.1,
}, menuPanel)

for i = 1, 18 do
    make("Frame",{
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,i/18,0),
        BackgroundColor3=Color3.fromRGB(0,150,255),
        BackgroundTransparency=0.92, BorderSizePixel=0, ZIndex=3,
    }, menuPanel)
end

local mpGrad = make("UIGradient",{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(0,4,16)),
        ColorSequenceKeypoint.new(0.4,Color3.fromRGB(0,22,52)),
        ColorSequenceKeypoint.new(0.6,Color3.fromRGB(0,40,86)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(0,4,16)),
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

-- Moving scan line
local techLine = make("Frame",{
    Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,0,0),
    BackgroundColor3=Color3.fromRGB(0,200,255),
    BackgroundTransparency=0.3, BorderSizePixel=0, ZIndex=4,
}, menuPanel)
make("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,220,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,0)),
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

local mpTop = make("Frame",{
    Size=UDim2.new(0.7,0,0,3), AnchorPoint=Vector2.new(0.5,0),
    Position=UDim2.new(0.5,0,0,0),
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

mpLbl("MVS HUB",14,16,Color3.fromRGB(255,255,255),Enum.Font.GothamBlack)
mpLbl("EFEITOS + SILENT AIM",34,11,Color3.fromRGB(0,180,255))

make("Frame",{Size=UDim2.new(0.9,0,0,1),Position=UDim2.new(0.05,0,0,52),
    BackgroundColor3=Color3.fromRGB(0,160,255),BackgroundTransparency=0.5,
    BorderSizePixel=0,ZIndex=5},menuPanel)

-- Thunder toggle
local thunderRow = make("Frame",{
    Size=UDim2.new(1,-20,0,52), Position=UDim2.new(0,10,0,60),
    BackgroundColor3=Color3.fromRGB(0,12,35), BackgroundTransparency=0.3,
    BorderSizePixel=0, ZIndex=5,
}, menuPanel)
make("UICorner",{CornerRadius=UDim.new(0,10)},thunderRow)
make("UIStroke",{Color=Color3.fromRGB(0,120,220),Thickness=1},thunderRow)

make("TextLabel",{Size=UDim2.new(0.62,0,0,26),Position=UDim2.new(0,12,0,4),
    BackgroundTransparency=1,Text="Efeito Thunder Kill",
    TextColor3=Color3.fromRGB(0,220,255),Font=Enum.Font.GothamBold,TextSize=13,
    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},thunderRow)
make("TextLabel",{Size=UDim2.new(0.62,0,0,18),Position=UDim2.new(0,12,0,28),
    BackgroundTransparency=1,Text="Raio + explosao + corpo preto",
    TextColor3=Color3.fromRGB(55,115,185),Font=Enum.Font.Gotham,TextSize=11,
    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},thunderRow)

local togBG = make("Frame",{Size=UDim2.new(0,48,0,26),
    AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-10,0.5,0),
    BackgroundColor3=Color3.fromRGB(28,28,48),BorderSizePixel=0,ZIndex=6},thunderRow)
make("UICorner",{CornerRadius=UDim.new(1,0)},togBG)
make("UIStroke",{Color=Color3.fromRGB(80,80,120),Thickness=1},togBG)

local togKnob = make("Frame",{Size=UDim2.new(0,20,0,20),
    AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,3,0.5,0),
    BackgroundColor3=Color3.fromRGB(120,120,160),BorderSizePixel=0,ZIndex=7},togBG)
make("UICorner",{CornerRadius=UDim.new(1,0)},togKnob)

local togBtn = make("TextButton",{Size=UDim2.new(1,0,1,0),
    BackgroundTransparency=1,Text="",ZIndex=8},thunderRow)

togBtn.MouseButton1Up:Connect(function()
    thunderOn = not thunderOn
    if thunderOn then
        tw(togBG,0.2,{BackgroundColor3=Color3.fromRGB(0,45,95)})
        tw(togKnob,0.2,{Position=UDim2.new(1,-23,0.5,0),BackgroundColor3=Color3.fromRGB(0,200,255)})
    else
        tw(togBG,0.2,{BackgroundColor3=Color3.fromRGB(28,28,48)})
        tw(togKnob,0.2,{Position=UDim2.new(0,3,0.5,0),BackgroundColor3=Color3.fromRGB(120,120,160)})
    end
end)

local thunderStatusLbl = mpLbl("Thunder: Desativado",122,11,Color3.fromRGB(80,100,140))
task.spawn(function()
    while MenuGui.Parent do
        if thunderOn then
            thunderStatusLbl.Text = "Thunder: ATIVO"
            thunderStatusLbl.TextColor3 = Color3.fromRGB(0,220,255)
        else
            thunderStatusLbl.Text = "Thunder: Desativado"
            thunderStatusLbl.TextColor3 = Color3.fromRGB(80,100,140)
        end
        task.wait(0.3)
    end
end)

make("Frame",{Size=UDim2.new(0.9,0,0,1),Position=UDim2.new(0.05,0,0,142),
    BackgroundColor3=Color3.fromRGB(0,100,180),BackgroundTransparency=0.6,
    BorderSizePixel=0,ZIndex=5},menuPanel)

mpLbl("SILENT AIM",150,14,Color3.fromRGB(255,255,255),Enum.Font.GothamBlack)
mpLbl("SA  = Ativar/Desativar silent aim",168,11,Color3.fromRGB(100,180,255))
mpLbl("FACA = Slash no inimigo mais perto",184,11,Color3.fromRGB(100,180,255))
mpLbl("GUN  = Atira no mais perto da tela",200,11,Color3.fromRGB(100,180,255))

make("Frame",{Size=UDim2.new(0.9,0,0,1),Position=UDim2.new(0.05,0,0,218),
    BackgroundColor3=Color3.fromRGB(0,100,180),BackgroundTransparency=0.6,
    BorderSizePixel=0,ZIndex=5},menuPanel)

mpLbl("BLUE FX:",226,11,Color3.fromRGB(0,200,255))
mpLbl("LED azul + bolinhas nas armas",242,11,Color3.fromRGB(55,105,155))
mpLbl("Ativado automaticamente ao equipar",258,11,Color3.fromRGB(55,105,155))
mpLbl("Faca E Arma recebem o efeito",274,11,Color3.fromRGB(55,105,155))
mpLbl("v2.0  by tolopoofcpae / tolopo637883",312,10,Color3.fromRGB(30,60,110))

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
        Size=UDim2.new(0,sz,0,sz), AnchorPoint=Vector2.new(0.5,0.5), Position=pos,
        BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0.62,
        BorderSizePixel=0, ZIndex=10,
    }, BGui)
    make("UICorner",{CornerRadius=UDim.new(1,0)},outer)
    local ost = make("UIStroke",{Color=Color3.fromRGB(20,20,20),Thickness=2.2},outer)

    local gap = make("Frame",{
        Size=UDim2.new(0,sz-13,0,sz-13), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,0),
        BackgroundTransparency=1, BorderSizePixel=0, ZIndex=11,
    }, outer)
    make("UICorner",{CornerRadius=UDim.new(1,0)},gap)

    local inner = make("Frame",{
        Size=UDim2.new(0,sz-18,0,sz-18), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,0),
        BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0.48,
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
                local delta = inp.Position - ds
                outer.Position = UDim2.new(
                    dp.X.Scale, dp.X.Offset+delta.X,
                    dp.Y.Scale, dp.Y.Offset+delta.Y)
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

-- HUB (draggable)
local hubBtn = makeBtn(54, UDim2.new(0.06,0,0.54,0),
    "HUB", Color3.fromRGB(0,200,255), true)
hubBtn.btn.MouseButton1Up:Connect(toggleMenu)
TweenSvc:Create(hubBtn.f,TweenInfo.new(1.5,Enum.EasingStyle.Sine,
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

-- FACA (draggable, above SA)
local kBtn = makeBtn(74, UDim2.new(0.12,0,0.67,0),
    "FACA", Color3.fromRGB(172,195,255), true)
kBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local tool = getEquipped()
    if tool and isKnife(tool) then silentKnife() end
end)

-- GUN (fixed, bottom-right near jump)
local gBtn = makeBtn(80, UDim2.new(0.88,0,0.88,0),
    "GUN", Color3.fromRGB(255,205,0), false)
gBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local tool = getEquipped()
    if tool and isGun(tool) then silentGun() end
end)

-- Glow based on equipped weapon + SA state
task.spawn(function()
    while true do
        task.wait(0.1)
        local tool = getEquipped()
        local hasKnife = tool and isKnife(tool)
        local hasGun   = tool and isGun(tool)

        -- Knife button
        if saActive and hasKnife then
            kBtn.stroke.Color = Color3.fromRGB(72,92,255)
            kBtn.lbl.TextColor3 = Color3.fromRGB(255,255,255)
        elseif hasKnife then
            kBtn.stroke.Color = Color3.fromRGB(40,40,80)
            kBtn.lbl.TextColor3 = Color3.fromRGB(172,195,255)
        else
            kBtn.stroke.Color = Color3.fromRGB(20,20,20)
            kBtn.lbl.TextColor3 = Color3.fromRGB(100,100,140)
        end

        -- Gun button - YELLOW glow when gun equipped + SA active
        if saActive and hasGun then
            gBtn.stroke.Color = Color3.fromRGB(255,210,0)
            gBtn.lbl.TextColor3 = Color3.fromRGB(255,230,0)
            gBtn.inner.BackgroundColor3 = Color3.fromRGB(30,20,0)
        elseif hasGun then
            gBtn.stroke.Color = Color3.fromRGB(80,65,0)
            gBtn.lbl.TextColor3 = Color3.fromRGB(255,205,0)
            gBtn.inner.BackgroundColor3 = Color3.fromRGB(0,0,0)
        else
            gBtn.stroke.Color = Color3.fromRGB(20,20,20)
            gBtn.lbl.TextColor3 = Color3.fromRGB(100,90,30)
            gBtn.inner.BackgroundColor3 = Color3.fromRGB(0,0,0)
        end

        -- HUB button
        hubBtn.stroke.Color = thunderOn
            and Color3.fromRGB(0,200,255) or Color3.fromRGB(20,20,20)
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
