-- ╔══════════════════════════════════════╗
-- ║   INSANE ELEVATOR · Delta Executor   ║
-- ╚══════════════════════════════════════╝

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UIS            = game:GetService("UserInputService")
local RS             = game:GetService("ReplicatedStorage")

local plr  = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum  = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local CFG = {
    WalkSpeed    = 16,
    JumpPower    = 50,
    FlySpeed     = 55,
    GodMode      = false,
    AntiVoid     = false,
    InfJump      = false,
    Fly          = false,
    Noclip       = false,
    AutoFarm     = false,
    AutoElevator = false,
    AutoSurvive  = false,
}

local POS = {
    Elevator = CFrame.new(-8.9,  7,   -16.2),
    Farm     = CFrame.new(-1953, -393,  896),
    Lobby    = CFrame.new(-1938, -397,  946),
    Spawn    = CFrame.new(-1907, -397,  946),
}

-- Limpar GUI antiga
if plr.PlayerGui:FindFirstChild("IEHub") then
    plr.PlayerGui.IEHub:Destroy()
end

local SG = Instance.new("ScreenGui")
SG.Name = "IEHub"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = plr.PlayerGui

-- ══════════════════════════════════════
--   BOTÃO FLUTUANTE (abre/fecha)
-- ══════════════════════════════════════
local TBtn = Instance.new("TextButton")
TBtn.Size = UDim2.new(0, 42, 0, 42)
TBtn.Position = UDim2.new(0, 16, 0.5, -21)
TBtn.BackgroundColor3 = Color3.fromRGB(75, 0, 200)
TBtn.Text = "🛗"
TBtn.TextSize = 20
TBtn.Font = Enum.Font.GothamBold
TBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TBtn.BorderSizePixel = 0
TBtn.ZIndex = 10
TBtn.Parent = SG
Instance.new("UICorner", TBtn).CornerRadius = UDim.new(0, 10)
local tbs = Instance.new("UIStroke", TBtn)
tbs.Color = Color3.fromRGB(155, 80, 255); tbs.Thickness = 1.5

-- ══════════════════════════════════════
--   JANELA PRINCIPAL
-- ══════════════════════════════════════
local Win = Instance.new("Frame")
Win.Size = UDim2.new(0, 295, 0, 415)
Win.Position = UDim2.new(0, 66, 0.5, -207)
Win.BackgroundColor3 = Color3.fromRGB(9, 8, 18)
Win.BorderSizePixel = 0
Win.ClipsDescendants = true
Win.Visible = false
Win.Parent = SG
Instance.new("UICorner", Win).CornerRadius = UDim.new(0, 10)
local ws = Instance.new("UIStroke", Win)
ws.Color = Color3.fromRGB(85, 0, 210); ws.Thickness = 1.5

-- Header
local Hdr = Instance.new("Frame")
Hdr.Size = UDim2.new(1, 0, 0, 42)
Hdr.BackgroundColor3 = Color3.fromRGB(18, 0, 55)
Hdr.BorderSizePixel = 0
Hdr.Parent = Win
Instance.new("UICorner", Hdr).CornerRadius = UDim.new(0, 10)
local hfix = Instance.new("Frame", Hdr) -- fix cantos inferiores
hfix.Size = UDim2.new(1,0,0,10); hfix.Position = UDim2.new(0,0,1,-10)
hfix.BackgroundColor3 = Color3.fromRGB(18,0,55); hfix.BorderSizePixel = 0
local hg = Instance.new("UIGradient", Hdr)
hg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(110,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(25,0,90))})
hg.Rotation = 90

local HdrLbl = Instance.new("TextLabel", Hdr)
HdrLbl.Size = UDim2.new(1,-46,1,0); HdrLbl.Position = UDim2.new(0,12,0,0)
HdrLbl.BackgroundTransparency = 1; HdrLbl.Text = "🛗  INSANE ELEVATOR"
HdrLbl.TextSize = 13; HdrLbl.Font = Enum.Font.GothamBold
HdrLbl.TextColor3 = Color3.fromRGB(235,215,255); HdrLbl.TextXAlignment = Enum.TextXAlignment.Left

local XBtn = Instance.new("TextButton", Hdr)
XBtn.Size = UDim2.new(0,25,0,25); XBtn.Position = UDim2.new(1,-32,0.5,-12)
XBtn.BackgroundColor3 = Color3.fromRGB(155,0,55); XBtn.Text = "✕"
XBtn.TextSize = 11; XBtn.Font = Enum.Font.GothamBold
XBtn.TextColor3 = Color3.fromRGB(255,255,255); XBtn.BorderSizePixel = 0
Instance.new("UICorner", XBtn).CornerRadius = UDim.new(0,6)

-- ScrollFrame
local Sc = Instance.new("ScrollingFrame", Win)
Sc.Size = UDim2.new(1,0,1,-42); Sc.Position = UDim2.new(0,0,0,42)
Sc.BackgroundTransparency = 1; Sc.ScrollBarThickness = 3
Sc.ScrollBarImageColor3 = Color3.fromRGB(100,0,255); Sc.BorderSizePixel = 0
local Li = Instance.new("UIListLayout", Sc); Li.Padding = UDim.new(0,5)
local Pa = Instance.new("UIPadding", Sc)
Pa.PaddingLeft = UDim.new(0,9); Pa.PaddingRight = UDim.new(0,9); Pa.PaddingTop = UDim.new(0,7)

-- ══════════════════════════════════════
--   HELPERS
-- ══════════════════════════════════════
local function Sec(txt)
    local l = Instance.new("TextLabel", Sc)
    l.Size = UDim2.new(1,0,0,16); l.BackgroundTransparency = 1
    l.Text = "◆ "..txt; l.TextSize = 10; l.Font = Enum.Font.GothamBold
    l.TextColor3 = Color3.fromRGB(125,65,255); l.TextXAlignment = Enum.TextXAlignment.Left
end

local function Tog(lbl, def, cb)
    local f = Instance.new("Frame", Sc)
    f.Size = UDim2.new(1,0,0,34); f.BackgroundColor3 = Color3.fromRGB(15,12,26); f.BorderSizePixel = 0
    Instance.new("UICorner",f).CornerRadius = UDim.new(0,7)
    local fs = Instance.new("UIStroke",f); fs.Color = Color3.fromRGB(38,26,68); fs.Thickness = 1

    local tl = Instance.new("TextLabel",f)
    tl.Size = UDim2.new(1,-50,1,0); tl.Position = UDim2.new(0,9,0,0)
    tl.BackgroundTransparency = 1; tl.Text = lbl; tl.TextSize = 11; tl.Font = Enum.Font.Gotham
    tl.TextColor3 = Color3.fromRGB(205,185,250); tl.TextXAlignment = Enum.TextXAlignment.Left

    local pill = Instance.new("Frame",f)
    pill.Size = UDim2.new(0,34,0,17); pill.Position = UDim2.new(1,-42,0.5,-8)
    pill.BackgroundColor3 = def and Color3.fromRGB(90,0,230) or Color3.fromRGB(33,28,48); pill.BorderSizePixel = 0
    Instance.new("UICorner",pill).CornerRadius = UDim.new(1,0)

    local dot = Instance.new("Frame",pill)
    dot.Size = UDim2.new(0,11,0,11); dot.Position = def and UDim2.new(1,-14,0.5,-5) or UDim2.new(0,3,0.5,-5)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255); dot.BorderSizePixel = 0
    Instance.new("UICorner",dot).CornerRadius = UDim.new(1,0)

    local state = def
    local btn = Instance.new("TextButton",f); btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        state = not state
        local ti = TweenInfo.new(0.16)
        TweenService:Create(pill,ti,{BackgroundColor3=state and Color3.fromRGB(90,0,230) or Color3.fromRGB(33,28,48)}):Play()
        TweenService:Create(dot,ti,{Position=state and UDim2.new(1,-14,0.5,-5) or UDim2.new(0,3,0.5,-5)}):Play()
        if cb then cb(state) end
    end)
end

local function Bt(lbl, col, cb)
    local b = Instance.new("TextButton", Sc)
    b.Size = UDim2.new(1,0,0,32); b.BackgroundColor3 = col
    b.Text = lbl; b.TextSize = 11; b.Font = Enum.Font.GothamBold
    b.TextColor3 = Color3.fromRGB(255,255,255); b.BorderSizePixel = 0
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,7)
    b.MouseButton1Click:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.08),{BackgroundTransparency=0.4}):Play()
        task.delay(0.1,function() TweenService:Create(b,TweenInfo.new(0.08),{BackgroundTransparency=0}):Play() end)
        if cb then cb() end
    end)
end

local function Notif(msg, col)
    local n = Instance.new("Frame",SG)
    n.Size = UDim2.new(0,235,0,36); n.Position = UDim2.new(0.5,-117,1,10)
    n.BackgroundColor3 = col or Color3.fromRGB(26,7,62); n.BorderSizePixel = 0; n.ZIndex = 20
    Instance.new("UICorner",n).CornerRadius = UDim.new(0,8)
    local ns = Instance.new("UIStroke",n); ns.Color = col or Color3.fromRGB(100,0,255); ns.Thickness = 1
    local nl = Instance.new("TextLabel",n)
    nl.Size = UDim2.new(1,-10,1,0); nl.Position = UDim2.new(0,10,0,0)
    nl.BackgroundTransparency = 1; nl.Text = "🔔 "..msg; nl.TextSize = 11; nl.Font = Enum.Font.Gotham
    nl.TextColor3 = Color3.fromRGB(255,255,255); nl.TextXAlignment = Enum.TextXAlignment.Left; nl.ZIndex = 21
    TweenService:Create(n,TweenInfo.new(0.22,Enum.EasingStyle.Back),{Position=UDim2.new(0.5,-117,1,-52)}):Play()
    task.delay(2.5,function()
        TweenService:Create(n,TweenInfo.new(0.18),{Position=UDim2.new(0.5,-117,1,10)}):Play()
        task.delay(0.2,function() n:Destroy() end)
    end)
end

-- ══════════════════════════════════════
--   MONTAR GUI
-- ══════════════════════════════════════
Sec("SOBREVIVÊNCIA")
Tog("☠️  God Mode",    false, function(v) CFG.GodMode   = v; Notif(v and "God Mode ON"  or "God Mode OFF")  end)
Tog("🛡️  Anti-Void",   false, function(v) CFG.AntiVoid  = v; Notif(v and "Anti-Void ON" or "Anti-Void OFF") end)
Tog("✅  Auto Sobreviver", false, function(v) CFG.AutoSurvive = v; Notif(v and "Auto Survive ON" or "OFF") end)

Sec("MOVIMENTO")
Tog("∞  Infinite Jump", false, function(v) CFG.InfJump = v; Notif(v and "Inf Jump ON" or "Inf Jump OFF") end)
Tog("✈️  Voar (Fly)",   false, function(v) CFG.Fly    = v; Notif(v and "Fly ON — WASD+SPACE" or "Fly OFF") end)
Tog("👻  Noclip",       false, function(v) CFG.Noclip = v; Notif(v and "Noclip ON" or "Noclip OFF") end)

Sec("VELOCIDADE")
Bt("🏃  Speed +50",    Color3.fromRGB(55,0,160), function()
    CFG.WalkSpeed = math.min(CFG.WalkSpeed+50, 250)
    if hum then hum.WalkSpeed = CFG.WalkSpeed end
    Notif("Speed: "..CFG.WalkSpeed)
end)
Bt("🔄  Speed Reset",  Color3.fromRGB(33,28,50), function()
    CFG.WalkSpeed = 16; if hum then hum.WalkSpeed = 16 end; Notif("Speed resetado")
end)

Sec("TELEPORTE")
Bt("🛗  Elevador",  Color3.fromRGB(70,0,185),  function() if root then root.CFrame=POS.Elevator; Notif("→ Elevador") end end)
Bt("🌾  Farm",      Color3.fromRGB(0,110,55),  function() if root then root.CFrame=POS.Farm;     Notif("→ Farm")     end end)
Bt("🏠  Lobby",     Color3.fromRGB(28,68,175), function() if root then root.CFrame=POS.Lobby;    Notif("→ Lobby")    end end)

Sec("FARM & ITENS")
Tog("⚡  Auto Farm",     false, function(v) CFG.AutoFarm     = v; Notif(v and "Auto Farm ON"     or "OFF") end)
Tog("🔄  Auto Elevador", false, function(v) CFG.AutoElevator = v; Notif(v and "Auto Elevador ON" or "OFF") end)
Bt("❤️  Curar HP",        Color3.fromRGB(175,0,52), function()
    if hum then hum.Health = hum.MaxHealth; Notif("HP curado! ❤️") end
end)
Bt("🎮  Disparar Survived", Color3.fromRGB(0,125,85), function()
    local re = RS:FindFirstChild("playerSurvived",true)
    if re then re:FireServer(); Notif("playerSurvived!") else Notif("Remote não encontrado") end
end)

Li:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Sc.CanvasSize = UDim2.new(0,0,0,Li.AbsoluteContentSize.Y+14)
end)

-- ══════════════════════════════════════
--   DRAG
-- ══════════════════════════════════════
local drag, ds, ws2 = false, nil, nil
Hdr.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=true; ds=i.Position; ws2=Win.Position end
end)
Hdr.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
end)
UIS.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - ds
        Win.Position = UDim2.new(ws2.X.Scale, ws2.X.Offset+d.X, ws2.Y.Scale, ws2.Y.Offset+d.Y)
    end
end)

-- ══════════════════════════════════════
--   TOGGLE ABRIR / FECHAR
-- ══════════════════════════════════════
local isOpen = false

local function SetOpen(v)
    isOpen = v
    if v then
        Win.Visible = true
        Win.Size = UDim2.new(0,0,0,0)
        TweenService:Create(Win,TweenInfo.new(0.26,Enum.EasingStyle.Back),{Size=UDim2.new(0,295,0,415)}):Play()
        TweenService:Create(TBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(110,20,255)}):Play()
    else
        TweenService:Create(Win,TweenInfo.new(0.18,Enum.EasingStyle.Quad),{Size=UDim2.new(0,0,0,0)}):Play()
        TweenService:Create(TBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(75,0,200)}):Play()
        task.delay(0.2,function() Win.Visible=false end)
    end
end

TBtn.MouseButton1Click:Connect(function() SetOpen(not isOpen) end)
XBtn.MouseButton1Click:Connect(function() SetOpen(false) end)
UIS.InputBegan:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.Insert then SetOpen(not isOpen) end
end)

-- ══════════════════════════════════════
--   LOOPS DE JOGO
-- ══════════════════════════════════════
plr.CharacterAdded:Connect(function(c)
    char=c; hum=c:WaitForChild("Humanoid"); root=c:WaitForChild("HumanoidRootPart")
    task.wait(0.5); hum.WalkSpeed=CFG.WalkSpeed; hum.JumpPower=CFG.JumpPower
end)

RunService.Heartbeat:Connect(function()
    if not char or not hum or not root then return end
    if CFG.GodMode  and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
    if CFG.AntiVoid and root.Position.Y < -700      then root.CFrame = POS.Spawn   end
    if CFG.Noclip then
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if CFG.InfJump and hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- Fly
local bv, bg, fc
local function startFly()
    if not root then return end
    bv = Instance.new("BodyVelocity"); bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Velocity=Vector3.zero; bv.Parent=root
    bg = Instance.new("BodyGyro");     bg.MaxTorque=Vector3.new(1e5,1e5,1e5); bg.P=1e4;                 bg.Parent=root
    fc = RunService.Heartbeat:Connect(function()
        if not CFG.Fly then
            if bv then bv:Destroy() end; if bg then bg:Destroy() end; if fc then fc:Disconnect() end; return
        end
        local cam=workspace.CurrentCamera; local v=Vector3.zero; local s=CFG.FlySpeed
        if UIS:IsKeyDown(Enum.KeyCode.W)         then v=v+cam.CFrame.LookVector*s  end
        if UIS:IsKeyDown(Enum.KeyCode.S)         then v=v-cam.CFrame.LookVector*s  end
        if UIS:IsKeyDown(Enum.KeyCode.A)         then v=v-cam.CFrame.RightVector*s end
        if UIS:IsKeyDown(Enum.KeyCode.D)         then v=v+cam.CFrame.RightVector*s end
        if UIS:IsKeyDown(Enum.KeyCode.Space)     then v=v+Vector3.new(0,s,0)       end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then v=v-Vector3.new(0,s,0)       end
        if bv then bv.Velocity=v end; if bg then bg.CFrame=cam.CFrame end
    end)
end
RunService.Heartbeat:Connect(function()
    if CFG.Fly and (not bv or not bv.Parent) then startFly() end
end)

task.spawn(function()
    while true do task.wait(2)
        if CFG.AutoFarm and char and root then
            root.CFrame=POS.Farm; task.wait(0.8); root.CFrame=POS.Elevator
        end
    end
end)

task.spawn(function()
    while true do task.wait(5)
        if CFG.AutoElevator then
            local re=RS:FindFirstChild("playerSurvived",true)
            if re then re:FireServer() end
        end
    end
end)

-- Pulsar botão ao iniciar
TweenService:Create(TBtn,TweenInfo.new(0.35,Enum.EasingStyle.Elastic),{Size=UDim2.new(0,48,0,48)}):Play()
task.delay(0.35,function() TweenService:Create(TBtn,TweenInfo.new(0.15),{Size=UDim2.new(0,42,0,42)}):Play() end)
task.delay(0.5,function() Notif("Script carregado! Clique 🛗 pra abrir") end)
print("✅ [InsaneElevator] Carregado! Clique no botão 🛗 ou pressione INSERT")
