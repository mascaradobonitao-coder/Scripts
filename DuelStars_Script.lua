-- ╔══════════════════════════════════════════════╗
-- ║        DUEL STARS BETA  |  Full Script       ║
-- ║   Rayfield UI  |  Delta Executor  |  by Lia  ║
-- ╚══════════════════════════════════════════════╝

-- ━━━━━━━━━━━━  RAYFIELD LOAD  ━━━━━━━━━━━━
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok then
    warn("[DuelStars] Rayfield failed to load: " .. tostring(Rayfield))
    return
end

-- ━━━━━━━━━━━━  SERVICES  ━━━━━━━━━━━━
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local Workspace      = game:GetService("Workspace")
local Camera         = Workspace.CurrentCamera
local LocalPlayer    = Players.LocalPlayer

-- ━━━━━━━━━━━━  REMOTES  ━━━━━━━━━━━━
local RS = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes", 10)

local function getRemote(path)
    local cur = Remotes
    for _, name in ipairs(path) do
        local child = cur:WaitForChild(name, 5)
        if not child then return nil end
        cur = child
    end
    return cur
end

local R_EquipWeapon     = getRemote({"EquipWeapon"})
local R_FireWeapon      = getRemote({"FireWeapon"})
local R_UpdateEquipped  = getRemote({"UpdateEquipped"})
local R_Teammates       = getRemote({"MatchSystem", "Teammates"})
local R_OutlineTeam     = getRemote({"MatchSystem", "OutlineTeam"})
local R_GetEquipped     = getRemote({"GetEquipped"})

-- ━━━━━━━━━━━━  STATE  ━━━━━━━━━━━━
local teammates = {}  -- Set of UserId's on same team

local Settings = {
    -- Aimbot
    Aimbot          = false,
    AimKey          = Enum.KeyCode.Q,      -- PC hold key
    MobileAimActive = false,               -- toggled by mobile button
    AimPart         = "Head",
    Smoothness      = 0.18,
    FOV             = 200,
    TeamCheck       = true,
    DeathCheck      = true,
    WallCheck       = false,
    ShowFOV         = true,

    -- ESP
    ESP             = false,
    ESPTeamColor    = Color3.fromRGB(0, 200, 255),
    ESPEnemyColor   = Color3.fromRGB(255, 60, 60),
    ESPFillTrans    = 0.7,

    -- Movement
    SpeedEnabled    = false,
    WalkSpeed       = 32,
    JumpEnabled     = false,
    JumpPower       = 100,
    NoclipEnabled   = false,
    FlyEnabled      = false,
    FlySpeed        = 50,

    -- Skin
    KnifeSkinID     = "",
    GunSkinID       = "",

    -- Silent Aim
    SilentAim       = false,
    SilentAimPart   = "Head",   -- part to redirect shots to
}

-- ━━━━━━━━━━━━  HELPERS  ━━━━━━━━━━━━
local function getChar(p)
    return p and p.Character
end

local function getHRP(p)
    local c = getChar(p)
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(p)
    local c = getChar(p)
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function isAlive(p)
    if Settings.DeathCheck then
        local h = getHumanoid(p)
        return h and h.Health > 0
    end
    return true
end

local function isTeammate(p)
    if not Settings.TeamCheck then return false end
    return teammates[p.UserId] == true
end

local function worldToViewport(pos)
    local vp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vp.X, vp.Y), onScreen, vp.Z
end

local function inFOV(pos)
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local screen, onScreen = worldToViewport(pos)
    if not onScreen then return false end
    return (screen - center).Magnitude <= Settings.FOV
end

local function wallCheck(targetPart)
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local origin = hrp.Position
    local direction = (targetPart.Position - origin)
    local dist = direction.Magnitude
    local result = Workspace:Raycast(origin, direction.Unit * dist, RaycastParams.new())
    if result then
        local hit = result.Instance
        -- If hit is part of target character it's clear
        local targetChar = targetPart.Parent
        if hit:IsDescendantOf(targetChar) then return false end
        return true  -- wall in between
    end
    return false
end

local function getNearestTarget()
    local best, bestDist = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if isTeammate(p) then continue end
        if not isAlive(p) then continue end
        local char = getChar(p)
        if not char then continue end
        local part = char:FindFirstChild(Settings.AimPart) or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        local screen, onScreen = worldToViewport(part.Position)
        if not onScreen then continue end
        local dist = (screen - center).Magnitude
        if dist > Settings.FOV then continue end
        if Settings.WallCheck and wallCheck(part) then continue end
        if dist < bestDist then
            best = part
            bestDist = dist
        end
    end
    return best
end


-- ━━━━━━━━━━━━  SILENT AIM (Remote Hook)  ━━━━━━━━━━━━
-- Hooks RemoteEvent:FireServer via __namecall metatable.
-- When a weapon fire remote is called, all Vector3/CFrame args
-- are silently replaced with the nearest enemy target part position.

local WEAPON_REMOTES = {
    ["FireWeapon"]         = true,
    ["FireWeaponUnreliable"] = true,
    ["ClientKnifeThrow"]   = true,
    ["ClientKnifeSwing"]   = true,
    ["ClientGunShot"]      = true,
}

local function getSilentTarget()
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if isTeammate(p) then continue end
        if not isAlive(p) then continue end
        local char = getChar(p)
        if not char then continue end
        local part = char:FindFirstChild(Settings.SilentAimPart)
                  or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        local hrp = getHRP(LocalPlayer)
        local dist = hrp and (part.Position - hrp.Position).Magnitude or math.huge
        if dist < bestDist then best = part; bestDist = dist end
    end
    return best
end

local function hookSilentAim()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall

    pcall(setreadonly, mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()

        if (method == "FireServer" or method == "InvokeServer")
            and Settings.SilentAim
            and WEAPON_REMOTES[self.Name]
        then
            local target = getSilentTarget()
            if target then
                local targetPos = target.Position
                local args = {...}
                local replaced = false
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3" then
                        args[i] = targetPos
                        replaced = true
                    elseif typeof(v) == "CFrame" then
                        args[i] = CFrame.new(targetPos)
                        replaced = true
                    end
                end
                -- If game passes position as a table/RaycastResult, fallback:
                -- just prepend target pos so server can see it
                if not replaced then
                    table.insert(args, 1, targetPos)
                end
                return oldNamecall(self, table.unpack(args))
            end
        end

        return oldNamecall(self, ...)
    end)

    pcall(setreadonly, mt, true)
end

pcall(hookSilentAim)

-- ━━━━━━━━━━━━  TEAMMATES TRACKING  ━━━━━━━━━━━━
if R_Teammates then
    R_Teammates.OnClientEvent:Connect(function(data)
        teammates = {}
        if type(data) == "table" then
            for _, uid in ipairs(data) do
                teammates[uid] = true
            end
        end
    end)
end

-- ━━━━━━━━━━━━  FOV CIRCLE  ━━━━━━━━━━━━
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Radius = Settings.FOV
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Transparency = 0.6
fovCircle.NumSides = 64
fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

-- ━━━━━━━━━━━━  ESP SYSTEM  ━━━━━━━━━━━━
local espHighlights = {}

local function clearESP()
    for _, v in pairs(espHighlights) do
        if v and v.Parent then v:Destroy() end
    end
    espHighlights = {}
end

local function updateESP()
    -- Remove highlights for gone players
    for uid, h in pairs(espHighlights) do
        local p = Players:GetPlayerByUserId(uid)
        if not p or not getChar(p) then
            h:Destroy()
            espHighlights[uid] = nil
        end
    end

    if not Settings.ESP then
        clearESP()
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = getChar(p)
        if not char then continue end

        local h = espHighlights[p.UserId]
        if not h then
            h = Instance.new("SelectionBox")
            h.LineThickness = 0.05
            h.SurfaceTransparency = Settings.ESPFillTrans
            h.Adornee = char
            h.Parent = Workspace
            espHighlights[p.UserId] = h
        end

        local alive = isAlive(p)
        local teammate = isTeammate(p)
        local col = teammate and Settings.ESPTeamColor or Settings.ESPEnemyColor
        h.Color3 = col
        h.SurfaceColor3 = col
        h.Adornee = alive and char or nil
    end
end

Players.PlayerRemoving:Connect(function(p)
    local h = espHighlights[p.UserId]
    if h then h:Destroy(); espHighlights[p.UserId] = nil end
end)

-- ━━━━━━━━━━━━  AIMBOT LOOP  ━━━━━━━━━━━━
local isAiming = false

local function isAimActive()
    if Settings.MobileAimActive then return true end
    return UserInputService:IsKeyDown(Settings.AimKey)
end

RunService.RenderStepped:Connect(function()
    -- Update FOV circle
    fovCircle.Visible = Settings.ShowFOV and Settings.Aimbot
    fovCircle.Radius = Settings.FOV
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- ESP update
    updateESP()

    -- Aimbot
    if not Settings.Aimbot then return end
    if not isAimActive() then return end

    local target = getNearestTarget()
    if not target then return end

    local targetPos = target.Position
    local currentCF = Camera.CFrame
    local targetCF = CFrame.lookAt(currentCF.Position, targetPos)
    Camera.CFrame = currentCF:Lerp(targetCF, Settings.Smoothness)
end)

-- ━━━━━━━━━━━━  MOVEMENT  ━━━━━━━━━━━━
local noclipConn

local function applySpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then
        h.WalkSpeed = Settings.SpeedEnabled and Settings.WalkSpeed or 16
        h.JumpPower = Settings.JumpEnabled and Settings.JumpPower or 50
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applySpeed()
end)

local function setNoclip(on)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end)
    else
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                end
            end
        end
    end
end

-- Fly system
local flyConn
local bodyVelocity, bodyGyro

local function setFly(on)
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not on then
        if hum then hum.PlatformStand = false end
        return
    end

    if hum then hum.PlatformStand = true end

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVelocity.Parent = hrp

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro.D = 100
    bodyGyro.Parent = hrp

    flyConn = RunService.RenderStepped:Connect(function()
        local char2 = LocalPlayer.Character
        if not char2 then return end
        local hrp2 = char2:FindFirstChild("HumanoidRootPart")
        if not hrp2 then return end

        local vel = Vector3.zero
        local cf = Camera.CFrame

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.yAxis end

        bodyVelocity.Velocity = vel * Settings.FlySpeed
        bodyGyro.CFrame = cf
    end)
end

-- ━━━━━━━━━━━━  SKIN CHANGER  ━━━━━━━━━━━━
local function applyTextureToModel(model, textureId)
    if not model then return end
    if textureId == "" then return end
    local fullId = "rbxassetid://" .. textureId
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("SpecialMesh") then
            part.TextureId = fullId
        elseif part:IsA("MeshPart") then
            part.TextureID = fullId
        elseif part:IsA("Decal") then
            part.Texture = fullId
        end
    end
end

local function applyColorToModel(model, color)
    if not model then return end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Color = color
        end
    end
end

local function findEquippedTool(itemType)
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            -- Rough guess by tool name containing "Knife" or "Gun"
            if itemType == "Knife" and (v.Name:lower():find("knife") or v.Name:lower():find("blade") or v.Name:lower():find("sword")) then
                return v
            elseif itemType == "Gun" and (v.Name:lower():find("gun") or v.Name:lower():find("bow") or v.Name:lower():find("pistol")) then
                return v
            end
        end
    end
    -- fallback: return first tool
    if itemType == "Knife" then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") then return v end
        end
    end
    return nil
end

local function applySkins()
    if Settings.KnifeSkinID ~= "" then
        local tool = findEquippedTool("Knife")
        if tool then applyTextureToModel(tool, Settings.KnifeSkinID) end
    end
    if Settings.GunSkinID ~= "" then
        local tool = findEquippedTool("Gun")
        if tool then applyTextureToModel(tool, Settings.GunSkinID) end
    end
end

-- Watch for new tools equip
LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        task.wait(0.1)
        if child:IsA("Tool") then
            applySkins()
        end
    end)
end)

-- ━━━━━━━━━━━━  AUTO-FIRE (RAPID FIRE)  ━━━━━━━━━━━━
local autoFireEnabled = false
local autoFireConn

local function setAutoFire(on)
    if autoFireConn then autoFireConn:Disconnect(); autoFireConn = nil end
    autoFireEnabled = on
    if not on then return end

    autoFireConn = RunService.Heartbeat:Connect(function()
        if not R_FireWeapon then return end
        local target = getNearestTarget()
        if not target then return end
        -- Fire toward target
        pcall(function()
            R_FireWeapon:FireServer(target.Position)
        end)
    end)
end

-- ━━━━━━━━━━━━  KNIFE THROW SPAM  ━━━━━━━━━━━━
local knifeSpamEnabled = false
local knifeSpamConn

local function setKnifeSpam(on)
    if knifeSpamConn then knifeSpamConn:Disconnect(); knifeSpamConn = nil end
    if not on then return end

    local R_KnifeThrow = getRemote({"ClientKnifeThrow"})
    if not R_KnifeThrow then return end

    knifeSpamConn = RunService.Heartbeat:Connect(function()
        local target = getNearestTarget()
        if not target then return end
        pcall(function()
            R_KnifeThrow:FireServer(target.Position)
        end)
    end)
end

-- ━━━━━━━━━━━━  EQUIP WEAPON UTIL  ━━━━━━━━━━━━
local function equipWeapon(weaponName)
    if not R_EquipWeapon then return end
    pcall(function()
        R_EquipWeapon:FireServer(weaponName)
    end)
end

-- ━━━━━━━━━━━━  GUI  ━━━━━━━━━━━━
local Window = Rayfield:CreateWindow({
    Name = "⚔ Duel Stars | by Lia",
    LoadingTitle = "Duel Stars Script",
    LoadingSubtitle = "Loading modules...",
    Theme = "DarkBlue",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = false,
    },
    KeySystem = false,
})

-- ━━━━━━━━━━━━  TAB: AIMBOT  ━━━━━━━━━━━━
local AimTab = Window:CreateTab("🎯 Aimbot", nil)

AimTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(v) Settings.Aimbot = v end,
})

AimTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Flag = "FOVCircleToggle",
    Callback = function(v) Settings.ShowFOV = v end,
})

AimTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "TeamCheckToggle",
    Callback = function(v) Settings.TeamCheck = v end,
})

AimTab:CreateToggle({
    Name = "Death Check",
    CurrentValue = true,
    Flag = "DeathCheckToggle",
    Callback = function(v) Settings.DeathCheck = v end,
})

AimTab:CreateToggle({
    Name = "Wall Check (skip behind walls)",
    CurrentValue = false,
    Flag = "WallCheckToggle",
    Callback = function(v) Settings.WallCheck = v end,
})

AimTab:CreateSlider({
    Name = "FOV Radius",
    Range = {30, 600},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 200,
    Flag = "FOVSlider",
    Callback = function(v) Settings.FOV = v end,
})

AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {1, 20},
    Increment = 1,
    Suffix = "",
    CurrentValue = 5,
    Flag = "SmoothSlider",
    Callback = function(v)
        -- Map 1-20 → 0.05-0.9 (lower slider = smoother)
        Settings.Smoothness = v / 22
    end,
})

AimTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = {"Head"},
    Flag = "AimPartDropdown",
    Callback = function(v) Settings.AimPart = v[1] end,
})

AimTab:CreateKeybind({
    Name = "Aim Key (PC Hold)",
    CurrentKeybind = "Q",
    HoldToInteract = false,
    Flag = "AimKey",
    Callback = function(v)
        Settings.AimKey = Enum.KeyCode[v] or Enum.KeyCode.Q
    end,
})

-- Mobile aimbot toggle button
AimTab:CreateButton({
    Name = "📱 Mobile Aim Toggle (tap to toggle on/off)",
    Callback = function()
        Settings.MobileAimActive = not Settings.MobileAimActive
        Rayfield:Notify({
            Title = "Mobile Aim",
            Content = Settings.MobileAimActive and "Aimbot ACTIVE (mobile)" or "Aimbot STOPPED",
            Duration = 2,
        })
    end,
})

-- ━━━━━━━━━━━━  TAB: ESP  ━━━━━━━━━━━━
local ESPTab = Window:CreateTab("👁 ESP", nil)

ESPTab:CreateToggle({
    Name = "Player ESP (Highlight)",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(v)
        Settings.ESP = v
        if not v then clearESP() end
    end,
})

ESPTab:CreateSlider({
    Name = "ESP Fill Transparency",
    Range = {0, 10},
    Increment = 1,
    Suffix = "",
    CurrentValue = 7,
    Flag = "ESPTransSlider",
    Callback = function(v) Settings.ESPFillTrans = v / 10 end,
})

ESPTab:CreateColorPicker({
    Name = "Enemy Color",
    Color = Color3.fromRGB(255, 60, 60),
    Flag = "ESPEnemyColor",
    Callback = function(v) Settings.ESPEnemyColor = v end,
})

ESPTab:CreateColorPicker({
    Name = "Teammate Color",
    Color = Color3.fromRGB(0, 200, 255),
    Flag = "ESPTeamColor",
    Callback = function(v) Settings.ESPTeamColor = v end,
})

-- ━━━━━━━━━━━━  TAB: COMBAT  ━━━━━━━━━━━━
local CombatTab = Window:CreateTab("⚔ Combat", nil)

CombatTab:CreateSection("🔇 Silent Aim")

CombatTab:CreateToggle({
    Name = "Silent Aim (redirects shots to enemy, mobile-friendly)",
    CurrentValue = false,
    Flag = "SilentAimToggle",
    Callback = function(v)
        Settings.SilentAim = v
        Rayfield:Notify({
            Title = "Silent Aim",
            Content = v and "ON — tiros vão no inimigo automaticamente!" or "OFF",
            Duration = 2,
        })
    end,
})

CombatTab:CreateDropdown({
    Name = "Silent Aim Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    CurrentOption = {"Head"},
    Flag = "SilentAimPartDropdown",
    Callback = function(v) Settings.SilentAimPart = v[1] end,
})

CombatTab:CreateSection("Other Combat")

CombatTab:CreateToggle({
    Name = "Auto Fire (fires toward nearest enemy)",
    CurrentValue = false,
    Flag = "AutoFireToggle",
    Callback = function(v) setAutoFire(v) end,
})

CombatTab:CreateToggle({
    Name = "Knife Throw Spam",
    CurrentValue = false,
    Flag = "KnifeSpamToggle",
    Callback = function(v) setKnifeSpam(v) end,
})

CombatTab:CreateSection("Equip Weapons")

CombatTab:CreateButton({
    Name = "Equip Knife Slot",
    Callback = function()
        equipWeapon("Knife")
        Rayfield:Notify({ Title = "Equip", Content = "Sent equip knife request", Duration = 2 })
    end,
})

CombatTab:CreateButton({
    Name = "Equip Gun Slot",
    Callback = function()
        equipWeapon("Gun")
        Rayfield:Notify({ Title = "Equip", Content = "Sent equip gun request", Duration = 2 })
    end,
})

-- ━━━━━━━━━━━━  TAB: MOVEMENT  ━━━━━━━━━━━━
local MoveTab = Window:CreateTab("🏃 Movement", nil)

MoveTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(v)
        Settings.SpeedEnabled = v
        applySpeed()
    end,
})

MoveTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 150},
    Increment = 1,
    Suffix = "stud/s",
    CurrentValue = 32,
    Flag = "WalkSpeedSlider",
    Callback = function(v)
        Settings.WalkSpeed = v
        if Settings.SpeedEnabled then applySpeed() end
    end,
})

MoveTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "JumpToggle",
    Callback = function(v)
        Settings.JumpEnabled = v
        applySpeed()
    end,
})

MoveTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 400},
    Increment = 10,
    Suffix = "",
    CurrentValue = 100,
    Flag = "JumpPowerSlider",
    Callback = function(v)
        Settings.JumpPower = v
        if Settings.JumpEnabled then applySpeed() end
    end,
})

MoveTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(v)
        Settings.NoclipEnabled = v
        setNoclip(v)
    end,
})

MoveTab:CreateToggle({
    Name = "Fly (WASD + Space/Ctrl)",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(v)
        Settings.FlyEnabled = v
        setFly(v)
    end,
})

MoveTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    Suffix = "stud/s",
    CurrentValue = 50,
    Flag = "FlySpeedSlider",
    Callback = function(v) Settings.FlySpeed = v end,
})

-- ━━━━━━━━━━━━  TAB: SKIN CHANGE  ━━━━━━━━━━━━
local SkinTab = Window:CreateTab("🎨 Skin Change", nil)

SkinTab:CreateSection("Knife Skin")

SkinTab:CreateInput({
    Name = "Knife Texture ID",
    PlaceholderText = "Enter asset ID (numbers only)",
    RemoveTextAfterFocusLost = false,
    Flag = "KnifeTextureInput",
    Callback = function(v)
        Settings.KnifeSkinID = v:match("^%d+$") and v or ""
    end,
})

SkinTab:CreateColorPicker({
    Name = "Knife Color Override",
    Color = Color3.fromRGB(200, 200, 200),
    Flag = "KnifeColorPicker",
    Callback = function(v)
        local tool = findEquippedTool("Knife")
        if tool then applyColorToModel(tool, v) end
    end,
})

SkinTab:CreateButton({
    Name = "Apply Knife Skin",
    Callback = function()
        local tool = findEquippedTool("Knife")
        if not tool then
            Rayfield:Notify({ Title = "Skin", Content = "Equip your knife first!", Duration = 3 })
            return
        end
        applyTextureToModel(tool, Settings.KnifeSkinID)
        Rayfield:Notify({ Title = "Knife Skin", Content = "Applied!", Duration = 2 })
    end,
})

SkinTab:CreateSection("Gun Skin")

SkinTab:CreateInput({
    Name = "Gun Texture ID",
    PlaceholderText = "Enter asset ID (numbers only)",
    RemoveTextAfterFocusLost = false,
    Flag = "GunTextureInput",
    Callback = function(v)
        Settings.GunSkinID = v:match("^%d+$") and v or ""
    end,
})

SkinTab:CreateColorPicker({
    Name = "Gun Color Override",
    Color = Color3.fromRGB(200, 200, 200),
    Flag = "GunColorPicker",
    Callback = function(v)
        local tool = findEquippedTool("Gun")
        if tool then applyColorToModel(tool, v) end
    end,
})

SkinTab:CreateButton({
    Name = "Apply Gun Skin",
    Callback = function()
        local tool = findEquippedTool("Gun")
        if not tool then
            Rayfield:Notify({ Title = "Skin", Content = "Equip your gun first!", Duration = 3 })
            return
        end
        applyTextureToModel(tool, Settings.GunSkinID)
        Rayfield:Notify({ Title = "Gun Skin", Content = "Applied!", Duration = 2 })
    end,
})

SkinTab:CreateButton({
    Name = "Apply All Skins",
    Callback = function()
        applySkins()
        Rayfield:Notify({ Title = "Skins", Content = "Applied all skins!", Duration = 2 })
    end,
})

-- ━━━━━━━━━━━━  TAB: MISC  ━━━━━━━━━━━━
local MiscTab = Window:CreateTab("⚙ Misc", nil)

MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(v)
        if v then
            local vc = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            -- Fire dummy input to prevent AFK
            local conn
            conn = RunService.Heartbeat:Connect(function()
                if not v then conn:Disconnect() return end
                LocalPlayer:Move(Vector3.zero, false)
            end)
        end
    end,
})

MiscTab:CreateToggle({
    Name = "Always Show Nametags",
    CurrentValue = false,
    Flag = "NametagToggle",
    Callback = function(v)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local char = getChar(p)
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local billboard = hrp:FindFirstChildOfClass("BillboardGui")
                        if billboard then
                            billboard.Enabled = v
                        end
                    end
                end
            end
        end
    end,
})

MiscTab:CreateSection("Player Utilities")

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

MiscTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.Health = 0 end
    end,
})

MiscTab:CreateButton({
    Name = "Copy UserId",
    Callback = function()
        setclipboard(tostring(LocalPlayer.UserId))
        Rayfield:Notify({ Title = "Copied", Content = "UserID copied to clipboard", Duration = 2 })
    end,
})

-- ━━━━━━━━━━━━  MOBILE: QUICK BUTTONS (ScreenGui)  ━━━━━━━━━━━━
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

if isMobile then
    local sg = Instance.new("ScreenGui")
    sg.Name = "DuelStarsMobileButtons"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LocalPlayer.PlayerGui

    local function makeBtn(txt, posX, posY, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 70, 0, 55)
        btn.Position = UDim2.new(posX, 0, posY, 0)
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.25
        btn.TextColor3 = Color3.new(1,1,1)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.Text = txt
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0.15, 0)
        btn.Parent = sg
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Aimbot toggle
    makeBtn("🎯 AIM\nOFF", 0.02, 0.55, Color3.fromRGB(30, 120, 220), function(self)
        Settings.MobileAimActive = not Settings.MobileAimActive
        Settings.Aimbot = Settings.MobileAimActive
    end)

    -- ESP toggle
    makeBtn("👁 ESP\nOFF", 0.02, 0.68, Color3.fromRGB(100, 60, 200), function()
        Settings.ESP = not Settings.ESP
        if not Settings.ESP then clearESP() end
    end)

    -- Speed toggle
    makeBtn("🏃 SPD\nOFF", 0.02, 0.81, Color3.fromRGB(30, 160, 80), function()
        Settings.SpeedEnabled = not Settings.SpeedEnabled
        applySpeed()
    end)

    -- Fly toggle
    makeBtn("✈ FLY\nOFF", 0.87, 0.55, Color3.fromRGB(200, 130, 20), function()
        Settings.FlyEnabled = not Settings.FlyEnabled
        setFly(Settings.FlyEnabled)
    end)

    -- Noclip toggle
    makeBtn("👻 NC\nOFF", 0.87, 0.68, Color3.fromRGB(180, 40, 40), function()
        Settings.NoclipEnabled = not Settings.NoclipEnabled
        setNoclip(Settings.NoclipEnabled)
    end)
end

-- ━━━━━━━━━━━━  INIT  ━━━━━━━━━━━━
Rayfield:Notify({
    Title = "⚔ Duel Stars Script",
    Content = "Loaded! Use tabs to configure features.",
    Duration = 4,
})

-- Apply stats on character load
if LocalPlayer.Character then
    task.wait(0.5)
    applySpeed()
end
