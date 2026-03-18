-- ╔══════════════════════════════════════════════╗
-- ║        DUEL STARS BETA  |  Fixed Script      ║
-- ║   Custom GUI  |  No Rayfield  |  by Lia      ║
-- ║   FIX: Removido namecall hook (anti-kick)    ║
-- ╚══════════════════════════════════════════════╝

-- ━━━━━━━━━━━━  SERVICES  ━━━━━━━━━━━━
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local Camera           = Workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- ━━━━━━━━━━━━  REMOTES  ━━━━━━━━━━━━
local RS      = game:GetService("ReplicatedStorage")
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

local R_EquipWeapon    = getRemote({"EquipWeapon"})
local R_FireWeapon     = getRemote({"FireWeapon"})
local R_Teammates      = getRemote({"MatchSystem", "Teammates"})

-- ━━━━━━━━━━━━  STATE  ━━━━━━━━━━━━
local teammates = {}

local Settings = {
    Aimbot          = false,
    AimKey          = Enum.KeyCode.Q,
    MobileAimActive = false,
    AimPart         = "Head",
    Smoothness      = 0.18,
    FOV             = 200,
    TeamCheck       = true,
    DeathCheck      = true,
    WallCheck       = false,
    ShowFOV         = true,

    ESP             = false,
    ESPTeamColor    = Color3.fromRGB(0, 200, 255),
    ESPEnemyColor   = Color3.fromRGB(255, 60, 60),
    ESPFillTrans    = 0.7,

    SpeedEnabled    = false,
    WalkSpeed       = 32,
    JumpEnabled     = false,
    JumpPower       = 100,
    NoclipEnabled   = false,
    FlyEnabled      = false,
    FlySpeed        = 50,

    KnifeSkinID     = "",
    GunSkinID       = "",

    -- Silent Aim REMOVIDO: usava __namecall hook → causava o kick
    -- SilentAim    = false,
}

-- ━━━━━━━━━━━━  HELPERS  ━━━━━━━━━━━━
local function getChar(p)  return p and p.Character end
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
    local origin    = hrp.Position
    local direction = targetPart.Position - origin
    local result    = Workspace:Raycast(origin, direction.Unit * direction.Magnitude, RaycastParams.new())
    if result then
        if result.Instance:IsDescendantOf(targetPart.Parent) then return false end
        return true
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
        if dist < bestDist then best = part; bestDist = dist end
    end
    return best
end

-- ━━━━━━━━━━━━  TEAMMATES TRACKING  ━━━━━━━━━━━━
if R_Teammates then
    R_Teammates.OnClientEvent:Connect(function(data)
        teammates = {}
        if type(data) == "table" then
            for _, uid in ipairs(data) do teammates[uid] = true end
        end
    end)
end

-- ━━━━━━━━━━━━  FOV CIRCLE  ━━━━━━━━━━━━
local fovCircle          = Drawing.new("Circle")
fovCircle.Visible        = false
fovCircle.Radius         = Settings.FOV
fovCircle.Color          = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness      = 1.5
fovCircle.Filled         = false
fovCircle.Transparency   = 0.6
fovCircle.NumSides       = 64
fovCircle.Position       = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

-- ━━━━━━━━━━━━  ESP  ━━━━━━━━━━━━
local espHighlights = {}

local function clearESP()
    for _, v in pairs(espHighlights) do
        if v and v.Parent then v:Destroy() end
    end
    espHighlights = {}
end

local function updateESP()
    for uid, h in pairs(espHighlights) do
        local p = Players:GetPlayerByUserId(uid)
        if not p or not getChar(p) then h:Destroy(); espHighlights[uid] = nil end
    end
    if not Settings.ESP then clearESP(); return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = getChar(p)
        if not char then continue end
        local h = espHighlights[p.UserId]
        if not h then
            h = Instance.new("SelectionBox")
            h.LineThickness     = 0.05
            h.SurfaceTransparency = Settings.ESPFillTrans
            h.Adornee           = char
            h.Parent            = Workspace
            espHighlights[p.UserId] = h
        end
        local col = isTeammate(p) and Settings.ESPTeamColor or Settings.ESPEnemyColor
        h.Color3        = col
        h.SurfaceColor3 = col
        h.Adornee       = isAlive(p) and char or nil
    end
end

Players.PlayerRemoving:Connect(function(p)
    local h = espHighlights[p.UserId]
    if h then h:Destroy(); espHighlights[p.UserId] = nil end
end)

-- ━━━━━━━━━━━━  AIMBOT LOOP  ━━━━━━━━━━━━
RunService.RenderStepped:Connect(function()
    fovCircle.Visible  = Settings.ShowFOV and Settings.Aimbot
    fovCircle.Radius   = Settings.FOV
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    updateESP()
    if not Settings.Aimbot then return end
    local holding = Settings.MobileAimActive or UserInputService:IsKeyDown(Settings.AimKey)
    if not holding then return end
    local target = getNearestTarget()
    if not target then return end
    local currentCF = Camera.CFrame
    local targetCF  = CFrame.lookAt(currentCF.Position, target.Position)
    Camera.CFrame   = currentCF:Lerp(targetCF, Settings.Smoothness)
end)

-- ━━━━━━━━━━━━  MOVEMENT  ━━━━━━━━━━━━
local noclipConn

local function applySpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then
        h.WalkSpeed = Settings.SpeedEnabled and Settings.WalkSpeed or 16
        h.JumpPower = Settings.JumpEnabled  and Settings.JumpPower or 50
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
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

local flyConn, bodyVelocity, bodyGyro

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
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVelocity.Parent   = hrp
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro.D         = 100
    bodyGyro.Parent    = hrp
    flyConn = RunService.RenderStepped:Connect(function()
        local c2  = LocalPlayer.Character
        local h2  = c2 and c2:FindFirstChild("HumanoidRootPart")
        if not h2 then return end
        local vel = Vector3.zero
        local cf  = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then vel = vel + Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.yAxis end
        bodyVelocity.Velocity = vel * Settings.FlySpeed
        bodyGyro.CFrame       = cf
    end)
end

-- ━━━━━━━━━━━━  SKIN CHANGER  ━━━━━━━━━━━━
local function applyTextureToModel(model, textureId)
    if not model or textureId == "" then return end
    local fullId = "rbxassetid://" .. textureId
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("SpecialMesh") then part.TextureId = fullId
        elseif part:IsA("MeshPart") then part.TextureID = fullId
        elseif part:IsA("Decal")    then part.Texture   = fullId end
    end
end

local function applyColorToModel(model, color)
    if not model then return end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then part.Color = color end
    end
end

local function findEquippedTool(itemType)
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            local n = v.Name:lower()
            if itemType == "Knife" and (n:find("knife") or n:find("blade") or n:find("sword")) then return v end
            if itemType == "Gun"   and (n:find("gun")   or n:find("bow")   or n:find("pistol")) then return v end
        end
    end
    if itemType == "Knife" then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") then return v end
        end
    end
    return nil
end

local function applySkins()
    if Settings.KnifeSkinID ~= "" then
        local t = findEquippedTool("Knife")
        if t then applyTextureToModel(t, Settings.KnifeSkinID) end
    end
    if Settings.GunSkinID ~= "" then
        local t = findEquippedTool("Gun")
        if t then applyTextureToModel(t, Settings.GunSkinID) end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        task.wait(0.1)
        if child:IsA("Tool") then applySkins() end
    end)
end)

-- ━━━━━━━━━━━━  AUTO FIRE  ━━━━━━━━━━━━
local autoFireConn

local function setAutoFire(on)
    if autoFireConn then autoFireConn:Disconnect(); autoFireConn = nil end
    if not on then return end
    autoFireConn = RunService.Heartbeat:Connect(function()
        if not R_FireWeapon then return end
        local target = getNearestTarget()
        if not target then return end
        pcall(function() R_FireWeapon:FireServer(target.Position) end)
    end)
end

-- ━━━━━━━━━━━━  KNIFE SPAM  ━━━━━━━━━━━━
local knifeSpamConn

local function setKnifeSpam(on)
    if knifeSpamConn then knifeSpamConn:Disconnect(); knifeSpamConn = nil end
    if not on then return end
    local R_KnifeThrow = getRemote({"ClientKnifeThrow"})
    if not R_KnifeThrow then return end
    knifeSpamConn = RunService.Heartbeat:Connect(function()
        local target = getNearestTarget()
        if not target then return end
        pcall(function() R_KnifeThrow:FireServer(target.Position) end)
    end)
end

local function equipWeapon(weaponName)
    if not R_EquipWeapon then return end
    pcall(function() R_EquipWeapon:FireServer(weaponName) end)
end

-- ━━━━━━━━━━━━  CUSTOM GUI (sem Rayfield, sem namecall)  ━━━━━━━━━━━━
-- Cria ScreenGui nativo do Roblox — sem libraries externas que causam kick

local sg = Instance.new("ScreenGui")
sg.Name           = "DuelStarsGUI"
sg.ResetOnSpawn   = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true
sg.Parent         = LocalPlayer.PlayerGui

-- ── Cores da interface ──
local C = {
    BG      = Color3.fromRGB(15, 15, 22),
    Panel   = Color3.fromRGB(22, 22, 35),
    Header  = Color3.fromRGB(30, 60, 120),
    Accent  = Color3.fromRGB(60, 130, 255),
    ON      = Color3.fromRGB(60, 200, 100),
    OFF     = Color3.fromRGB(80, 80, 90),
    Text    = Color3.fromRGB(230, 230, 240),
    SubText = Color3.fromRGB(140, 140, 160),
    Border  = Color3.fromRGB(50, 50, 75),
}

-- ── Notificação flutuante ──
local notifFrame = Instance.new("Frame")
notifFrame.Size              = UDim2.new(0, 280, 0, 50)
notifFrame.Position          = UDim2.new(0.5, -140, 0, -60)
notifFrame.BackgroundColor3  = C.Panel
notifFrame.BorderSizePixel   = 0
notifFrame.Parent            = sg
Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", notifFrame).Color        = C.Accent

local notifLabel = Instance.new("TextLabel")
notifLabel.Size              = UDim2.new(1, -10, 1, 0)
notifLabel.Position          = UDim2.new(0, 5, 0, 0)
notifLabel.BackgroundTransparency = 1
notifLabel.TextColor3        = C.Text
notifLabel.TextScaled        = true
notifLabel.Font              = Enum.Font.GothamBold
notifLabel.Text              = ""
notifLabel.Parent            = notifFrame

local notifActive = false
local function notify(msg)
    if notifActive then return end
    notifActive = true
    notifLabel.Text = msg
    TweenService:Create(notifFrame, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -140, 0, 10)}):Play()
    task.wait(2.5)
    TweenService:Create(notifFrame, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -140, 0, -60)}):Play()
    task.wait(0.35)
    notifActive = false
end

-- ── Janela principal ──
local mainOpen = false

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size              = UDim2.new(0, 110, 0, 38)
toggleBtn.Position          = UDim2.new(0, 10, 0.5, -19)
toggleBtn.BackgroundColor3  = C.Header
toggleBtn.BorderSizePixel   = 0
toggleBtn.Text              = "⚔ DuelStars"
toggleBtn.TextColor3        = C.Text
toggleBtn.TextScaled        = true
toggleBtn.Font              = Enum.Font.GothamBold
toggleBtn.Parent            = sg
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local win = Instance.new("Frame")
win.Name                  = "MainWindow"
win.Size                  = UDim2.new(0, 340, 0, 460)
win.Position              = UDim2.new(0.5, -170, 0.5, -230)
win.BackgroundColor3      = C.BG
win.BorderSizePixel       = 0
win.Visible               = false
win.Parent                = sg
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
local winStroke = Instance.new("UIStroke", win)
winStroke.Color    = C.Border
winStroke.Thickness = 1

-- Titulo
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = C.Header
titleBar.BorderSizePixel  = 0
titleBar.Parent           = win
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size             = UDim2.new(1, -50, 1, 0)
titleLbl.Position         = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text             = "⚔  Duel Stars  |  by Lia"
titleLbl.TextColor3       = C.Text
titleLbl.TextScaled       = true
titleLbl.Font             = Enum.Font.GothamBold
titleLbl.TextXAlignment   = Enum.TextXAlignment.Left
titleLbl.Parent           = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 36, 0, 36)
closeBtn.Position         = UDim2.new(1, -38, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Text             = "✕"
closeBtn.TextColor3       = Color3.new(1,1,1)
closeBtn.TextScaled       = true
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.BorderSizePixel  = 0
closeBtn.Parent           = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 7)

-- Tabs
local tabNames = {"🎯 Aimbot","👁 ESP","⚔ Combat","🏃 Move","🎨 Skin","⚙ Misc"}
local tabBtns  = {}
local tabPages = {}

local tabBar = Instance.new("Frame")
tabBar.Size             = UDim2.new(1, 0, 0, 34)
tabBar.Position         = UDim2.new(0, 0, 0, 42)
tabBar.BackgroundColor3 = C.Panel
tabBar.BorderSizePixel  = 0
tabBar.Parent           = win
Instance.new("UIListLayout", tabBar).FillDirection = Enum.FillDirection.Horizontal

local content = Instance.new("Frame")
content.Size              = UDim2.new(1, -10, 1, -84)
content.Position          = UDim2.new(0, 5, 0, 78)
content.BackgroundTransparency = 1
content.Parent            = win

for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size              = UDim2.new(1/#tabNames, 0, 1, 0)
    btn.BackgroundColor3  = C.Panel
    btn.BorderSizePixel   = 0
    btn.Text              = name
    btn.TextColor3        = C.SubText
    btn.TextScaled        = true
    btn.Font              = Enum.Font.Gotham
    btn.Parent            = tabBar
    tabBtns[i] = btn

    local page = Instance.new("ScrollingFrame")
    page.Size              = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel   = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = C.Accent
    page.Visible           = (i == 1)
    page.CanvasSize        = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Parent            = content
    tabPages[i]            = page
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 4)
end

local activeTab = 1
local function switchTab(idx)
    activeTab = idx
    for i, p in ipairs(tabPages) do
        p.Visible = (i == idx)
        tabBtns[i].TextColor3 = (i == idx) and C.Accent or C.SubText
        tabBtns[i].BackgroundColor3 = (i == idx) and Color3.fromRGB(28,28,45) or C.Panel
    end
end
switchTab(1)
for i, btn in ipairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(i) end)
end

-- ── Widget Helpers ──
local function makeRow(parent)
    local row = Instance.new("Frame")
    row.Size              = UDim2.new(1, -4, 0, 36)
    row.BackgroundColor3  = C.Panel
    row.BorderSizePixel   = 0
    row.Parent            = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    return row
end

local function makeLabel(parent, txt, offsetX)
    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(0.65, 0, 1, 0)
    lbl.Position          = UDim2.new(0, offsetX or 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text              = txt
    lbl.TextColor3        = C.Text
    lbl.TextScaled        = true
    lbl.Font              = Enum.Font.Gotham
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Parent            = parent
    return lbl
end

-- Toggle widget
local function makeToggle(parent, labelTxt, initial, onChanged)
    local row = makeRow(parent)
    makeLabel(row, labelTxt)

    local pill = Instance.new("TextButton")
    pill.Size             = UDim2.new(0, 48, 0, 24)
    pill.Position         = UDim2.new(1, -58, 0.5, -12)
    pill.BorderSizePixel  = 0
    pill.Text             = ""
    pill.BackgroundColor3 = initial and C.ON or C.OFF
    pill.Parent           = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame")
    dot.Size              = UDim2.new(0, 18, 0, 18)
    dot.Position          = initial and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    dot.BackgroundColor3  = Color3.new(1,1,1)
    dot.BorderSizePixel   = 0
    dot.Parent            = pill
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local state = initial
    pill.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundColor3 = state and C.ON or C.OFF}):Play()
        TweenService:Create(dot, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
        }):Play()
        onChanged(state)
    end)
    return row
end

-- Button widget
local function makeButton(parent, labelTxt, onClick)
    local row = Instance.new("TextButton")
    row.Size              = UDim2.new(1, -4, 0, 34)
    row.BackgroundColor3  = C.Accent
    row.BorderSizePixel   = 0
    row.Text              = labelTxt
    row.TextColor3        = Color3.new(1,1,1)
    row.TextScaled        = true
    row.Font              = Enum.Font.GothamBold
    row.Parent            = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    row.MouseButton1Click:Connect(onClick)
    return row
end

-- Slider widget
local function makeSlider(parent, labelTxt, min, max, default, suffix, onChanged)
    local row = Instance.new("Frame")
    row.Size              = UDim2.new(1, -4, 0, 52)
    row.BackgroundColor3  = C.Panel
    row.BorderSizePixel   = 0
    row.Parent            = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(1, -10, 0, 22)
    lbl.Position          = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text              = labelTxt .. ": " .. default .. suffix
    lbl.TextColor3        = C.Text
    lbl.TextScaled        = true
    lbl.Font              = Enum.Font.Gotham
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Parent            = row

    local track = Instance.new("Frame")
    track.Size            = UDim2.new(1, -16, 0, 8)
    track.Position        = UDim2.new(0, 8, 0, 28)
    track.BackgroundColor3 = C.OFF
    track.BorderSizePixel = 0
    track.Parent          = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    local pct  = (default - min) / (max - min)
    fill.Size             = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = C.Accent
    fill.BorderSizePixel  = 0
    fill.Parent           = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local abs = track.AbsolutePosition
        local w   = track.AbsoluteSize.X
        local rel = math.clamp((inp.Position.X - abs.X) / w, 0, 1)
        local val = math.floor(min + (max - min) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text  = labelTxt .. ": " .. val .. suffix
        onChanged(val)
    end)
    return row
end

-- Section header
local function makeSection(parent, txt)
    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(1, -4, 0, 24)
    lbl.BackgroundColor3  = Color3.fromRGB(35, 35, 55)
    lbl.BorderSizePixel   = 0
    lbl.Text              = "  " .. txt
    lbl.TextColor3        = C.Accent
    lbl.TextScaled        = true
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Parent            = parent
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 5)
    return lbl
end

-- Input widget
local function makeInput(parent, placeholder, onSubmit)
    local row = Instance.new("Frame")
    row.Size              = UDim2.new(1, -4, 0, 36)
    row.BackgroundColor3  = C.Panel
    row.BorderSizePixel   = 0
    row.Parent            = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", row).Color        = C.Border

    local box = Instance.new("TextBox")
    box.Size              = UDim2.new(1, -12, 1, -8)
    box.Position          = UDim2.new(0, 6, 0, 4)
    box.BackgroundTransparency = 1
    box.Text              = ""
    box.PlaceholderText   = placeholder
    box.TextColor3        = C.Text
    box.PlaceholderColor3 = C.SubText
    box.TextScaled        = true
    box.Font              = Enum.Font.Gotham
    box.TextXAlignment    = Enum.TextXAlignment.Left
    box.ClearTextOnFocus  = false
    box.Parent            = row
    box.FocusLost:Connect(function() onSubmit(box.Text) end)
    return row
end

-- ── Página 1: Aimbot ──
local p1 = tabPages[1]
makeSection(p1, "Aimbot Settings")
makeToggle(p1, "Aimbot", false, function(v) Settings.Aimbot = v end)
makeToggle(p1, "Show FOV Circle", true,  function(v) Settings.ShowFOV = v end)
makeToggle(p1, "Team Check",      true,  function(v) Settings.TeamCheck = v end)
makeToggle(p1, "Death Check",     true,  function(v) Settings.DeathCheck = v end)
makeToggle(p1, "Wall Check",      false, function(v) Settings.WallCheck = v end)
makeSlider(p1, "FOV Radius", 30, 600, 200, "px", function(v) Settings.FOV = v end)
makeSlider(p1, "Smoothness",  1,  20,   5, "",   function(v) Settings.Smoothness = v / 22 end)
makeButton(p1, "📱 Mobile Aim Toggle", function()
    Settings.MobileAimActive = not Settings.MobileAimActive
    notify("Mobile Aim: " .. (Settings.MobileAimActive and "ON ✅" or "OFF ❌"))
end)

-- ── Página 2: ESP ──
local p2 = tabPages[2]
makeSection(p2, "ESP Settings")
makeToggle(p2, "Player ESP", false, function(v)
    Settings.ESP = v
    if not v then clearESP() end
end)
makeSlider(p2, "Fill Transparency", 0, 10, 7, "", function(v) Settings.ESPFillTrans = v / 10 end)

-- ── Página 3: Combat ──
local p3 = tabPages[3]
makeSection(p3, "Combat")
-- Silent Aim REMOVIDO — causava kick via __namecall hook
local saRow = makeRow(p3)
makeLabel(saRow, "⚠ Silent Aim (removido)")
local saNote = Instance.new("TextLabel")
saNote.Size              = UDim2.new(0.35, 0, 1, 0)
saNote.Position          = UDim2.new(0.65, 0, 0, 0)
saNote.BackgroundTransparency = 1
saNote.Text              = "kick risk"
saNote.TextColor3        = Color3.fromRGB(255, 100, 100)
saNote.TextScaled        = true
saNote.Font              = Enum.Font.GothamBold
saNote.Parent            = saRow

makeToggle(p3, "Auto Fire",       false, function(v) setAutoFire(v) end)
makeToggle(p3, "Knife Throw Spam",false, function(v) setKnifeSpam(v) end)
makeSection(p3, "Equip Weapons")
makeButton(p3, "Equip Knife",  function() equipWeapon("Knife"); notify("Knife equip enviado") end)
makeButton(p3, "Equip Gun",    function() equipWeapon("Gun");   notify("Gun equip enviado")   end)

-- ── Página 4: Movement ──
local p4 = tabPages[4]
makeSection(p4, "Movement")
makeToggle(p4, "Speed Hack",     false, function(v) Settings.SpeedEnabled = v; applySpeed() end)
makeSlider(p4, "Walk Speed",  16, 150, 32, " stud/s", function(v) Settings.WalkSpeed = v; if Settings.SpeedEnabled then applySpeed() end end)
makeToggle(p4, "Infinite Jump",  false, function(v) Settings.JumpEnabled = v; applySpeed() end)
makeSlider(p4, "Jump Power",  50, 400, 100, "", function(v) Settings.JumpPower = v; if Settings.JumpEnabled then applySpeed() end end)
makeToggle(p4, "Noclip",         false, function(v) Settings.NoclipEnabled = v; setNoclip(v) end)
makeToggle(p4, "Fly (WASD+Space)",false, function(v) Settings.FlyEnabled = v; setFly(v) end)
makeSlider(p4, "Fly Speed",  10, 200, 50, " stud/s", function(v) Settings.FlySpeed = v end)

-- ── Página 5: Skin ──
local p5 = tabPages[5]
makeSection(p5, "Knife Skin")
makeInput(p5, "Knife Texture ID (só números)", function(v)
    Settings.KnifeSkinID = v:match("^%d+$") and v or ""
end)
makeButton(p5, "Apply Knife Skin", function()
    local t = findEquippedTool("Knife")
    if not t then notify("Equipe a knife primeiro!"); return end
    applyTextureToModel(t, Settings.KnifeSkinID)
    notify("Knife skin aplicada!")
end)
makeSection(p5, "Gun Skin")
makeInput(p5, "Gun Texture ID (só números)", function(v)
    Settings.GunSkinID = v:match("^%d+$") and v or ""
end)
makeButton(p5, "Apply Gun Skin", function()
    local t = findEquippedTool("Gun")
    if not t then notify("Equipe a gun primeiro!"); return end
    applyTextureToModel(t, Settings.GunSkinID)
    notify("Gun skin aplicada!")
end)
makeButton(p5, "Apply All Skins", function()
    applySkins()
    notify("Todas as skins aplicadas!")
end)

-- ── Página 6: Misc ──
local p6 = tabPages[6]
makeSection(p6, "Player Utilities")
makeToggle(p6, "Anti-AFK", false, function(v)
    if v then
        RunService.Heartbeat:Connect(function()
            if not v then return end
            LocalPlayer:Move(Vector3.zero, false)
        end)
    end
end)
makeButton(p6, "Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)
makeButton(p6, "Reset Character", function()
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.Health = 0 end
end)
makeButton(p6, "Copy UserId", function()
    pcall(function() setclipboard(tostring(LocalPlayer.UserId)) end)
    notify("UserID copiado!")
end)

-- ── Toggle janela ──
toggleBtn.MouseButton1Click:Connect(function()
    mainOpen = not mainOpen
    win.Visible = mainOpen
end)
closeBtn.MouseButton1Click:Connect(function()
    mainOpen = false
    win.Visible = false
end)

-- ── Drag da janela ──
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = inp.Position
        startPos  = win.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseMovement then dragInput = inp end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp == dragInput then
        local delta = inp.Position - dragStart
        win.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ── Mobile: botões rápidos ──
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
if isMobile then
    local function makeQuickBtn(txt, posX, posY, col, cb)
        local btn = Instance.new("TextButton")
        btn.Size              = UDim2.new(0, 70, 0, 55)
        btn.Position          = UDim2.new(posX, 0, posY, 0)
        btn.BackgroundColor3  = col
        btn.BackgroundTransparency = 0.25
        btn.TextColor3        = Color3.new(1,1,1)
        btn.TextScaled        = true
        btn.Font              = Enum.Font.GothamBold
        btn.Text              = txt
        btn.BorderSizePixel   = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0.15, 0)
        btn.Parent            = sg
        btn.MouseButton1Click:Connect(cb)
        return btn
    end
    makeQuickBtn("🎯 AIM\nOFF", 0.02, 0.55, Color3.fromRGB(30,120,220),  function() Settings.MobileAimActive = not Settings.MobileAimActive; Settings.Aimbot = Settings.MobileAimActive end)
    makeQuickBtn("👁 ESP\nOFF", 0.02, 0.68, Color3.fromRGB(100,60,200),  function() Settings.ESP = not Settings.ESP; if not Settings.ESP then clearESP() end end)
    makeQuickBtn("🏃 SPD\nOFF", 0.02, 0.81, Color3.fromRGB(30,160,80),   function() Settings.SpeedEnabled = not Settings.SpeedEnabled; applySpeed() end)
    makeQuickBtn("✈ FLY\nOFF",  0.87, 0.55, Color3.fromRGB(200,130,20),  function() Settings.FlyEnabled = not Settings.FlyEnabled; setFly(Settings.FlyEnabled) end)
    makeQuickBtn("👻 NC\nOFF",  0.87, 0.68, Color3.fromRGB(180,40,40),   function() Settings.NoclipEnabled = not Settings.NoclipEnabled; setNoclip(Settings.NoclipEnabled) end)
end

-- ── Init ──
if LocalPlayer.Character then
    task.wait(0.5)
    applySpeed()
end

task.spawn(function()
    task.wait(0.5)
    notify("⚔ Duel Stars carregado! Clique no botão para abrir.")
end)
