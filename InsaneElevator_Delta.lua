-- ╔══════════════════════════════════════════════════════════╗
-- ║         INSANE ELEVATOR - SCRIPT BY CLAUDE AI           ║
-- ║              Compatível com Delta Executor               ║
-- ╚══════════════════════════════════════════════════════════╝

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ══════════════════════════════════
--          CONFIGURAÇÕES
-- ══════════════════════════════════
local CONFIG = {
    WalkSpeed = 16,
    JumpPower = 50,
    FlySpeed = 60,
    InfiniteJumpEnabled = false,
    AutoSurviveEnabled = false,
    GodModeEnabled = false,
    AutoFarmEnabled = false,
    NoclipEnabled = false,
    FlyEnabled = false,
    AntiVoidEnabled = false,
    AutoElevatorEnabled = false,
}

-- Posições do mapa (extraídas do .rbxlx)
local POSITIONS = {
    Lobby     = CFrame.new(-1938, -397, 946),
    Elevator  = CFrame.new(-8.9, 7, -16.2),
    Farm      = CFrame.new(-1953, -393, 896),
    Spawn     = CFrame.new(-1907, -397, 946),
}

-- ══════════════════════════════════
--          ESTADO DA GUI
-- ══════════════════════════════════
local isOpen = true
local isDragging = false
local dragStartPos, frameStartPos

-- ══════════════════════════════════
--          CRIAR GUI
-- ══════════════════════════════════
-- Remove GUI antiga se existir
if player.PlayerGui:FindFirstChild("InsaneElevatorHub") then
    player.PlayerGui.InsaneElevatorHub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InsaneElevatorHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = player.PlayerGui

-- ── JANELA PRINCIPAL ──
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 380, 0, 500)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Borda gradiente
local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(80, 0, 200)
Stroke.Thickness = 1.5
Stroke.Parent = MainFrame

-- Gradiente de fundo
local BgGradient = Instance.new("UIGradient")
BgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 15)),
})
BgGradient.Rotation = 135
BgGradient.Parent = MainFrame

-- ── HEADER ──
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 55)
Header.BackgroundColor3 = Color3.fromRGB(20, 0, 60)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

-- Fix bottom corners do header
local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 12)
HeaderFix.Position = UDim2.new(0, 0, 1, -12)
HeaderFix.BackgroundColor3 = Color3.fromRGB(20, 0, 60)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local HeaderGradient = Instance.new("UIGradient")
HeaderGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 0, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 0, 180)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 80)),
})
HeaderGradient.Rotation = 90
HeaderGradient.Parent = Header

-- Ícone decorativo
local HeaderIcon = Instance.new("TextLabel")
HeaderIcon.Size = UDim2.new(0, 40, 0, 40)
HeaderIcon.Position = UDim2.new(0, 10, 0.5, -20)
HeaderIcon.BackgroundTransparency = 1
HeaderIcon.Text = "🛗"
HeaderIcon.TextSize = 28
HeaderIcon.Font = Enum.Font.GothamBold
HeaderIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderIcon.Parent = Header

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 55, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "INSANE ELEVATOR"
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(0, 200, 0, 16)
SubTitle.Position = UDim2.new(0, 57, 0, 30)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "▸ Script Hub by Claude AI"
SubTitle.TextSize = 10
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextColor3 = Color3.fromRGB(180, 120, 255)
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Header

-- Botão fechar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 80)
CloseBtn.Text = "✕"
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent = CloseBtn

-- Botão minimizar
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -78, 0.5, -15)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 140)
MinBtn.Text = "–"
MinBtn.TextSize = 18
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextColor3 = Color3.fromRGB(200, 180, 255)
MinBtn.BorderSizePixel = 0
MinBtn.Parent = Header

local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(0, 6)
MinBtnCorner.Parent = MinBtn

-- ── CONTEÚDO PRINCIPAL (SCROLL) ──
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Name = "Content"
ContentFrame.Size = UDim2.new(1, 0, 1, -55)
ContentFrame.Position = UDim2.new(0, 0, 0, 55)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ScrollBarThickness = 4
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 0, 255)
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 720)
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 8)
ListLayout.Parent = ContentFrame

local Padding = Instance.new("UIPadding")
Padding.PaddingLeft = UDim.new(0, 12)
Padding.PaddingRight = UDim.new(0, 12)
Padding.PaddingTop = UDim.new(0, 10)
Padding.Parent = ContentFrame

-- ══════════════════════════════════
--         FUNÇÕES HELPER
-- ══════════════════════════════════

local function CreateSectionLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = "  ◆ " .. text
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = Color3.fromRGB(140, 80, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = ContentFrame
    return lbl
end

local function CreateToggle(labelText, defaultState, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.BackgroundColor3 = Color3.fromRGB(18, 15, 32)
    frame.BorderSizePixel = 0
    frame.Parent = ContentFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local strokeToggle = Instance.new("UIStroke")
    strokeToggle.Color = Color3.fromRGB(45, 30, 80)
    strokeToggle.Thickness = 1
    strokeToggle.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.fromRGB(220, 200, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("Frame")
    toggleBtn.Size = UDim2.new(0, 44, 0, 22)
    toggleBtn.Position = UDim2.new(1, -54, 0.5, -11)
    toggleBtn.BackgroundColor3 = defaultState and Color3.fromRGB(100, 0, 255) or Color3.fromRGB(40, 35, 55)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBtn

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = defaultState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    circle.Parent = toggleBtn

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    local state = defaultState
    local clickDetector = Instance.new("TextButton")
    clickDetector.Size = UDim2.new(1, 0, 1, 0)
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.Parent = frame

    clickDetector.MouseButton1Click:Connect(function()
        state = not state
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
        TweenService:Create(toggleBtn, tweenInfo, {
            BackgroundColor3 = state and Color3.fromRGB(100, 0, 255) or Color3.fromRGB(40, 35, 55)
        }):Play()
        TweenService:Create(circle, tweenInfo, {
            Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
        if callback then callback(state) end
    end)

    return frame
end

local function CreateButton(labelText, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = color or Color3.fromRGB(70, 0, 180)
    btn.Text = labelText
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 0
    btn.Parent = ContentFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(
            math.min(color.R * 255 + 40, 255),
            math.min(color.G * 255 + 20, 255),
            math.min(color.B * 255 + 60, 255)
        )),
        ColorSequenceKeypoint.new(1, color),
    })
    gradient.Rotation = 90
    gradient.Parent = btn

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundTransparency = 0.3
        }):Play()
        task.delay(0.1, function()
            TweenService:Create(btn, TweenInfo.new(0.1), {
                BackgroundTransparency = 0
            }):Play()
        end)
        if callback then callback() end
    end)

    return btn
end

local function CreateSlider(labelText, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 52)
    frame.BackgroundColor3 = Color3.fromRGB(18, 15, 32)
    frame.BorderSizePixel = 0
    frame.Parent = ContentFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local strokeSlider = Instance.new("UIStroke")
    strokeSlider.Color = Color3.fromRGB(45, 30, 80)
    strokeSlider.Thickness = 1
    strokeSlider.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -14, 0, 22)
    lbl.Position = UDim2.new(0, 14, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText .. ": " .. tostring(default)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextColor3 = Color3.fromRGB(200, 180, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 4)
    track.Position = UDim2.new(0, 14, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
    track.BorderSizePixel = 0
    track.Parent = frame

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 0, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(220, 180, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local draggingSlider = false
    local inputCapture = Instance.new("TextButton")
    inputCapture.Size = UDim2.new(1, 0, 1, 0)
    inputCapture.BackgroundTransparency = 1
    inputCapture.Text = ""
    inputCapture.ZIndex = 5
    inputCapture.Parent = track

    local function updateSlider(input)
        local trackAbsPos = track.AbsolutePosition
        local trackAbsSize = track.AbsoluteSize
        local relX = math.clamp((input.Position.X - trackAbsPos.X) / trackAbsSize.X, 0, 1)
        local value = math.floor(min + relX * (max - min))
        lbl.Text = labelText .. ": " .. tostring(value)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, -7, 0.5, -7)
        if callback then callback(value) end
    end

    inputCapture.MouseButton1Down:Connect(function()
        draggingSlider = true
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)

    inputCapture.MouseButton1Click:Connect(function()
        local input = UserInputService:GetMouseLocation()
        updateSlider({Position = Vector2.new(input.X, input.Y)})
    end)

    return frame
end

local function Notify(msg, color)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 280, 0, 44)
    notif.Position = UDim2.new(0.5, -140, 1, -60)
    notif.BackgroundColor3 = color or Color3.fromRGB(30, 10, 70)
    notif.BorderSizePixel = 0
    notif.Parent = ScreenGui

    local nc = Instance.new("UICorner")
    nc.CornerRadius = UDim.new(0, 8)
    nc.Parent = notif

    local ns = Instance.new("UIStroke")
    ns.Color = color or Color3.fromRGB(100, 0, 255)
    ns.Thickness = 1
    ns.Parent = notif

    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(1, -10, 1, 0)
    nl.Position = UDim2.new(0, 10, 0, 0)
    nl.BackgroundTransparency = 1
    nl.Text = "🔔 " .. msg
    nl.TextSize = 12
    nl.Font = Enum.Font.Gotham
    nl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.Parent = notif

    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -140, 1, -110)
    }):Play()

    task.delay(3, function()
        TweenService:Create(notif, TweenInfo.new(0.3), {
            Position = UDim2.new(0.5, -140, 1, 20)
        }):Play()
        task.delay(0.3, function() notif:Destroy() end)
    end)
end

-- ══════════════════════════════════
--       CONSTRUIR SEÇÕES DA GUI
-- ══════════════════════════════════

-- ── SEÇÃO: SOBREVIVÊNCIA ──
CreateSectionLabel("SOBREVIVÊNCIA")

CreateToggle("☠️  God Mode (Sem Morte)", false, function(state)
    CONFIG.GodModeEnabled = state
    Notify(state and "God Mode ATIVADO" or "God Mode DESATIVADO",
        state and Color3.fromRGB(0, 150, 50) or Color3.fromRGB(150, 0, 50))
end)

CreateToggle("💀  Anti-Void (Salva da queda)", false, function(state)
    CONFIG.AntiVoidEnabled = state
    Notify(state and "Anti-Void ATIVADO" or "Anti-Void DESATIVADO")
end)

CreateToggle("🛡️  Auto Sobreviver (playerSurvived)", false, function(state)
    CONFIG.AutoSurviveEnabled = state
    Notify(state and "Auto Sobreviver ATIVADO" or "Auto Sobreviver DESATIVADO")
end)

-- ── SEÇÃO: MOVIMENTO ──
CreateSectionLabel("MOVIMENTO & VELOCIDADE")

CreateSlider("🏃 WalkSpeed", 16, 200, 16, function(val)
    CONFIG.WalkSpeed = val
    if humanoid then humanoid.WalkSpeed = val end
end)

CreateSlider("🦘 JumpPower", 50, 300, 50, function(val)
    CONFIG.JumpPower = val
    if humanoid then humanoid.JumpPower = val end
end)

CreateToggle("∞  Infinite Jump", false, function(state)
    CONFIG.InfiniteJumpEnabled = state
    Notify(state and "Infinite Jump ATIVADO" or "Infinite Jump DESATIVADO")
end)

CreateToggle("✈️  Voar (Fly Mode)", false, function(state)
    CONFIG.FlyEnabled = state
    Notify(state and "Fly ATIVADO — Segurar ESPAÇO" or "Fly DESATIVADO")
end)

CreateToggle("👻  Noclip", false, function(state)
    CONFIG.NoclipEnabled = state
    Notify(state and "Noclip ATIVADO" or "Noclip DESATIVADO")
end)

-- ── SEÇÃO: TELEPORTE ──
CreateSectionLabel("TELEPORTE")

CreateButton("🛗  Ir para o Elevador", Color3.fromRGB(80, 0, 200), function()
    if character and rootPart then
        rootPart.CFrame = POSITIONS.Elevator
        Notify("Teleportado: Elevador! 🛗")
    end
end)

CreateButton("🌾  Ir para o Farm", Color3.fromRGB(0, 120, 60), function()
    if character and rootPart then
        rootPart.CFrame = POSITIONS.Farm
        Notify("Teleportado: Farm! 🌾")
    end
end)

CreateButton("🏠  Ir para o Lobby", Color3.fromRGB(40, 80, 200), function()
    if character and rootPart then
        rootPart.CFrame = POSITIONS.Lobby
        Notify("Teleportado: Lobby! 🏠")
    end
end)

CreateButton("🔁  Respawn no Spawn", Color3.fromRGB(100, 50, 0), function()
    if character and rootPart then
        rootPart.CFrame = POSITIONS.Spawn
        Notify("Teleportado: Spawn!")
    end
end)

-- ── SEÇÃO: FARM / ITENS ──
CreateSectionLabel("FARM & ITENS")

CreateToggle("⚡  Auto Farm Coins", false, function(state)
    CONFIG.AutoFarmEnabled = state
    Notify(state and "Auto Farm ATIVADO" or "Auto Farm DESATIVADO",
        state and Color3.fromRGB(180, 140, 0) or nil)
end)

CreateToggle("🔄  Auto Elevador (Loop)", false, function(state)
    CONFIG.AutoElevatorEnabled = state
    Notify(state and "Auto Elevador ATIVADO" or "Auto Elevador DESATIVADO")
end)

CreateButton("💊  Pegar Fast Potion (Shop)", Color3.fromRGB(180, 0, 120), function()
    -- Tenta usar o RemoteEvent prevent_death + velocidade
    local re = ReplicatedStorage:FindFirstChild("prevent_death", true)
    if re then
        re:FireServer()
        Notify("Fast Potion enviada!")
    else
        -- Aumenta stats manualmente
        if humanoid then
            humanoid.WalkSpeed = math.min(humanoid.WalkSpeed + 20, 200)
            humanoid.JumpPower = math.min(humanoid.JumpPower + 30, 300)
        end
        Notify("Boost aplicado! ⚡")
    end
end)

CreateButton("❤️  Curar HP (Max)", Color3.fromRGB(200, 0, 60), function()
    if humanoid then
        humanoid.Health = humanoid.MaxHealth
        Notify("HP Restaurado! ❤️", Color3.fromRGB(200, 0, 60))
    end
end)

CreateButton("🎮  Disparar playerSurvived", Color3.fromRGB(0, 150, 100), function()
    local re = ReplicatedStorage:FindFirstChild("playerSurvived", true)
    if re then
        re:FireServer()
        Notify("playerSurvived disparado!")
    else
        Notify("RemoteEvent não encontrado", Color3.fromRGB(150, 50, 0))
    end
end)

-- ══════════════════════════════════
--           ARRASTAR GUI
-- ══════════════════════════════════
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStartPos = input.Position
        frameStartPos = MainFrame.Position
    end
end)

Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartPos
        MainFrame.Position = UDim2.new(
            frameStartPos.X.Scale,
            frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale,
            frameStartPos.Y.Offset + delta.Y
        )
    end
end)

-- ══════════════════════════════════
--       BOTÕES FECHAR / MINIMIZAR
-- ══════════════════════════════════
local minimized = false

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.new(0, 380, 0, 55) or UDim2.new(0, 380, 0, 500)
    }):Play()
    MinBtn.Text = minimized and "+" or "–"
end)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + 190,
                             MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + 250)
    }):Play()
    task.delay(0.3, function() ScreenGui:Destroy() end)
end)

-- Tecla INSERT para abrir/fechar
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- ══════════════════════════════════
--          LOOPS PRINCIPAIS
-- ══════════════════════════════════

-- Re-pegar referências ao respawn
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    -- Reaplicar WalkSpeed/JumpPower
    task.wait(0.5)
    humanoid.WalkSpeed = CONFIG.WalkSpeed
    humanoid.JumpPower = CONFIG.JumpPower
end)

-- God Mode loop
RunService.Heartbeat:Connect(function()
    if not character or not humanoid or not rootPart then return end

    -- God Mode
    if CONFIG.GodModeEnabled then
        if humanoid.Health < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end
        humanoid:SetAttribute("CanDie", false)
    end

    -- Anti-Void
    if CONFIG.AntiVoidEnabled then
        if rootPart.Position.Y < -700 then
            rootPart.CFrame = POSITIONS.Spawn
        end
    end

    -- Noclip
    if CONFIG.NoclipEnabled then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJumpEnabled and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Fly Mode
local flyConnection
local bodyVelocity, bodyGyro

local function enableFly()
    if not character or not rootPart then return end
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVelocity.Parent = rootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro.P = 1e4
    bodyGyro.Parent = rootPart

    flyConnection = RunService.Heartbeat:Connect(function()
        if not CONFIG.FlyEnabled then
            if bodyVelocity then bodyVelocity:Destroy() end
            if bodyGyro then bodyGyro:Destroy() end
            if flyConnection then flyConnection:Disconnect() end
            return
        end
        local cam = workspace.CurrentCamera
        local speed = CONFIG.FlySpeed
        local vel = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            vel = vel + cam.CFrame.LookVector * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            vel = vel - cam.CFrame.LookVector * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            vel = vel - cam.CFrame.RightVector * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            vel = vel + cam.CFrame.RightVector * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            vel = vel + Vector3.new(0, speed, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            vel = vel - Vector3.new(0, speed, 0)
        end

        if bodyVelocity then bodyVelocity.Velocity = vel end
        if bodyGyro then bodyGyro.CFrame = cam.CFrame end
    end)
end

-- Watcher para fly
RunService.Heartbeat:Connect(function()
    if CONFIG.FlyEnabled and (not bodyVelocity or not bodyVelocity.Parent) then
        enableFly()
    end
end)

-- Auto Farm loop (teleporta para Farm e volta ao Elevador)
task.spawn(function()
    while true do
        task.wait(2)
        if CONFIG.AutoFarmEnabled and character and rootPart then
            rootPart.CFrame = POSITIONS.Farm
            task.wait(1)
            rootPart.CFrame = POSITIONS.Elevator
        end
    end
end)

-- Auto Elevator loop (playerSurvived)
task.spawn(function()
    while true do
        task.wait(5)
        if CONFIG.AutoElevatorEnabled then
            local re = ReplicatedStorage:FindFirstChild("playerSurvived", true)
            if re then re:FireServer() end
        end
    end
end)

-- ══════════════════════════════════
--         ANIMAÇÃO DE ENTRADA
-- ══════════════════════════════════
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 380, 0, 500),
    Position = UDim2.new(0.5, -190, 0.5, -250)
}):Play()

task.delay(0.6, function()
    Notify("Insane Elevator Script Carregado! 🛗", Color3.fromRGB(80, 0, 200))
end)

-- Atualizar canvas automaticamente
ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 20)
end)

print("✅ [InsaneElevator] Script carregado com sucesso!")
print("📌 Pressione INSERT para mostrar/ocultar a GUI")
