-- ============================================================
--  TopoOp Wall Hop Hub  |  by TopoOp-ofc_mohd
--  Version: 2.0
--  Key: TopoOp-ofc_mohd
--  AVISO: NÃO compartilhe sua Key! Compartilhar = BAN permanente.
-- ============================================================

--[[ DESCRIÇÃO
    TopoOp Wall Hop Hub é o melhor hub de Wall Hop para Roblox.
    Detecta automaticamente paredes via Raycast e gira a câmera
    45° para a direita ao pular encostado na parede.
    Possui sistema de Key com auto-save, configurações completas,
    tema visual premium e painel de banimento exclusivo para o dono.
    
    Site para pegar a Key: [EDITE AQUI COM SEU SITE]
    PROIBIDO compartilhar Keys — resulta em ban imediato.
--]]

-- ============================================================
-- SERVIÇOS & VARIÁVEIS GLOBAIS
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- ============================================================
-- CONFIGURAÇÃO DO HUB
-- ============================================================
local HUB_CONFIG = {
    -- Key System
    VALID_KEY       = "TopoOp-ofc_mohd",
    KEY_SAVE_FILE   = "TopoOpWH_Key.txt",

    -- Dono do Hub (quem vê o painel de ban)
    OWNER_NAME      = "TopoOp_ofc_mohd",  -- coloca seu nick exato aqui

    -- Ban system
    BAN_FILE        = "TopoOpWH_Bans.txt",
    BAN_MESSAGE     = "[TopoOp Hub] Você foi banido. Motivo: Violação dos Termos.",

    -- Padrões
    DEFAULT_DEGREE  = 45,      -- graus de rotação ao wall hop
    DEFAULT_ENABLED = true,
    WALL_DIST       = 3.5,     -- distância do raycast lateral (studs)
    COOLDOWN        = 0.35,    -- cooldown entre rotações (seg)
    SMOOTH_TIME     = 0.18,    -- tempo do lerp da câmera
}

-- ============================================================
-- UTILITÁRIOS DE ARQUIVO (writefile/readfile/isfile)
-- ============================================================
local function safeWrite(path, data)
    pcall(function() writefile(path, data) end)
end

local function safeRead(path)
    local ok, data = pcall(readfile, path)
    return ok and data or nil
end

local function safeExists(path)
    local ok, r = pcall(isfile, path)
    return ok and r
end

-- ============================================================
-- SISTEMA DE BAN
-- ============================================================
local BanList = {}

local function loadBans()
    local raw = safeRead(HUB_CONFIG.BAN_FILE)
    if raw then
        local ok, t = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(t) == "table" then
            BanList = t
        end
    end
end

local function saveBans()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(BanList) end)
    if ok then safeWrite(HUB_CONFIG.BAN_FILE, encoded) end
end

local function banPlayer(name)
    name = string.lower(name)
    if not BanList[name] then
        BanList[name] = true
        saveBans()
        return true
    end
    return false
end

local function unbanPlayer(name)
    name = string.lower(name)
    if BanList[name] then
        BanList[name] = nil
        saveBans()
        return true
    end
    return false
end

local function isBanned(name)
    return BanList[string.lower(name)] == true
end

-- Verifica ban do próprio jogador ao carregar
loadBans()
if isBanned(LocalPlayer.Name) then
    -- Cria aviso de ban simples e trava tudo
    local sg = Instance.new("ScreenGui")
    sg.Name = "BanScreen"
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.Parent = LocalPlayer.PlayerGui

    local bg = Instance.new("Frame", sg)
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
    bg.BorderSizePixel = 0

    local lbl = Instance.new("TextLabel", bg)
    lbl.Size = UDim2.fromScale(0.8, 0.3)
    lbl.Position = UDim2.fromScale(0.1, 0.35)
    lbl.BackgroundTransparency = 1
    lbl.Text = HUB_CONFIG.BAN_MESSAGE
    lbl.TextColor3 = Color3.fromRGB(255, 60, 60)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true

    -- Para a execução
    return
end

-- ============================================================
-- ESTADO DO HUB
-- ============================================================
local State = {
    keyValid    = false,
    enabled     = HUB_CONFIG.DEFAULT_ENABLED,
    degree      = HUB_CONFIG.DEFAULT_DEGREE,
    onCooldown  = false,
    isOnWall    = false,
    wasJumping  = false,
}

-- ============================================================
-- FUNÇÕES DE CÂMERA  (sem travamento)
-- ============================================================

-- Rotaciona a câmera no eixo Y (yaw) mantendo o pitch intacto
local function rotateCamera(deg)
    local cam   = Camera
    local cf    = cam.CFrame
    local pos   = cf.Position
    local look  = cf.LookVector
    local right = cf.RightVector
    local up    = Vector3.new(0, 1, 0)

    -- Decompõe yaw e pitch atuais
    local yaw   = math.atan2(-look.X, -look.Z)
    local pitch = math.atan2(look.Y, Vector2.new(look.X, look.Z).Magnitude)

    local newYaw = yaw + math.rad(deg)

    -- Reconstrói CFrame via ângulos separados (evita Z-roll acidental)
    local targetCF = CFrame.new(pos)
        * CFrame.Angles(0, newYaw, 0)
        * CFrame.Angles(pitch, 0, 0)

    -- Lerp suave
    local start = tick()
    local duration = HUB_CONFIG.SMOOTH_TIME

    local con
    con = RunService.RenderStepped:Connect(function()
        local t = (tick() - start) / duration
        if t >= 1 then
            t = 1
            con:Disconnect()
            State.onCooldown = false
        end
        cam.CFrame = cf:Lerp(targetCF, t)
    end)
end

-- ============================================================
-- DETECÇÃO DE PAREDE (Raycast lateral)
-- ============================================================
local function detectWall()
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local dirs = {
        hrp.CFrame.RightVector,
        -hrp.CFrame.RightVector,
    }

    for _, dir in ipairs(dirs) do
        local result = workspace:Raycast(hrp.Position, dir * HUB_CONFIG.WALL_DIST, params)
        if result then return true end
    end
    return false
end

-- ============================================================
-- LOOP PRINCIPAL (Wall Hop Logic)
-- ============================================================
local function startWallHopLoop()
    local hum = nil

    local function getHum()
        local char = LocalPlayer.Character
        if char then
            hum = char:FindFirstChildOfClass("Humanoid")
        end
    end

    getHum()
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        getHum()
        State.wasJumping = false
        State.onCooldown = false
    end)

    RunService.Heartbeat:Connect(function()
        if not State.keyValid then return end
        if not State.enabled then return end
        if not hum then getHum(); return end

        local jumping = hum.Jump
        local onWall  = detectWall()

        -- Detecta borda: estava pulando, chegou na parede, não estava na parede antes
        if jumping and onWall and not State.wasJumping and not State.onCooldown then
            State.onCooldown = true
            rotateCamera(State.degree)
        end

        State.wasJumping = jumping
        State.isOnWall   = onWall
    end)
end

-- ============================================================
-- GUI — TELA DE CARREGAMENTO
-- ============================================================
local function createLoadingScreen(parent)
    local gui = Instance.new("ScreenGui")
    gui.Name          = "TopoOpLoading"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn  = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent        = parent

    local bg = Instance.new("Frame", gui)
    bg.Size               = UDim2.fromScale(1, 1)
    bg.BackgroundColor3   = Color3.fromRGB(5, 5, 12)
    bg.BorderSizePixel    = 0

    -- Gradiente de fundo
    local uiGrad = Instance.new("UIGradient", bg)
    uiGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(5,  5,  15)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 5,  25)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(5,  5,  12)),
    })
    uiGrad.Rotation = 135

    -- Logo / Título
    local title = Instance.new("TextLabel", bg)
    title.Size               = UDim2.new(1, 0, 0, 60)
    title.Position           = UDim2.new(0, 0, 0.3, 0)
    title.BackgroundTransparency = 1
    title.Text               = "TopoOp Wall Hop Hub"
    title.TextColor3         = Color3.fromRGB(0, 200, 255)
    title.Font               = Enum.Font.GothamBold
    title.TextSize           = 34
    title.TextTransparency   = 1

    local sub = Instance.new("TextLabel", bg)
    sub.Size              = UDim2.new(1, 0, 0, 30)
    sub.Position          = UDim2.new(0, 0, 0.46, 0)
    sub.BackgroundTransparency = 1
    sub.Text              = "by TopoOp-ofc_mohd"
    sub.TextColor3        = Color3.fromRGB(120, 120, 180)
    sub.Font              = Enum.Font.Gotham
    sub.TextSize          = 16
    sub.TextTransparency  = 1

    -- Barra de progresso
    local barBg = Instance.new("Frame", bg)
    barBg.Size            = UDim2.new(0.5, 0, 0, 6)
    barBg.Position        = UDim2.new(0.25, 0, 0.62, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    barBg.BorderSizePixel  = 0
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame", barBg)
    barFill.Size             = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    barFill.BorderSizePixel  = 0
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    local statusLbl = Instance.new("TextLabel", bg)
    statusLbl.Size              = UDim2.new(1, 0, 0, 24)
    statusLbl.Position          = UDim2.new(0, 0, 0.68, 0)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text              = "Inicializando..."
    statusLbl.TextColor3        = Color3.fromRGB(100, 100, 150)
    statusLbl.Font              = Enum.Font.Gotham
    statusLbl.TextSize          = 13
    statusLbl.TextTransparency  = 1

    -- Animações de entrada
    local fadeIn = TweenService:Create
    local tw1 = TweenService:Create(title,      TweenInfo.new(0.6), {TextTransparency=0})
    local tw2 = TweenService:Create(sub,        TweenInfo.new(0.6), {TextTransparency=0})
    local tw3 = TweenService:Create(statusLbl,  TweenInfo.new(0.6), {TextTransparency=0})
    tw1:Play(); tw2:Play(); tw3:Play()

    local stages = {
        {p=0.2, t="Verificando integridade..."},
        {p=0.45, t="Carregando módulos..."},
        {p=0.7, t="Configurando câmera..."},
        {p=0.9, t="Quase pronto..."},
        {p=1.0, t="Concluído!"},
    }

    for _, s in ipairs(stages) do
        task.wait(0.32)
        statusLbl.Text = s.t
        TweenService:Create(barFill, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {
            Size = UDim2.new(s.p, 0, 1, 0)
        }):Play()
    end

    task.wait(0.4)
    TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()
    TweenService:Create(title,     TweenInfo.new(0.4), {TextTransparency=1}):Play()
    TweenService:Create(sub,       TweenInfo.new(0.4), {TextTransparency=1}):Play()
    TweenService:Create(statusLbl, TweenInfo.new(0.4), {TextTransparency=1}):Play()
    TweenService:Create(barBg,     TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
    TweenService:Create(barFill,   TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
    task.wait(0.55)
    gui:Destroy()
end

-- ============================================================
-- GUI — TELA DE KEY
-- ============================================================
local function createKeyScreen(parent, onSuccess)
    local gui = Instance.new("ScreenGui")
    gui.Name           = "TopoOpKey"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn   = false
    gui.Parent         = parent

    local overlay = Instance.new("Frame", gui)
    overlay.Size             = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromRGB(5, 5, 12)
    overlay.BorderSizePixel  = 0

    local card = Instance.new("Frame", overlay)
    card.Size               = UDim2.new(0, 380, 0, 220)
    card.Position           = UDim2.new(0.5, -190, 0.5, -110)
    card.BackgroundColor3   = Color3.fromRGB(12, 12, 28)
    card.BorderSizePixel    = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color     = Color3.fromRGB(0, 140, 220)
    stroke.Thickness = 1.5

    local t1 = Instance.new("TextLabel", card)
    t1.Size               = UDim2.new(1, 0, 0, 40)
    t1.Position           = UDim2.new(0, 0, 0, 14)
    t1.BackgroundTransparency = 1
    t1.Text               = "🔑  Insira sua Key"
    t1.TextColor3         = Color3.fromRGB(0, 200, 255)
    t1.Font               = Enum.Font.GothamBold
    t1.TextSize           = 20

    local t2 = Instance.new("TextLabel", card)
    t2.Size               = UDim2.new(0.9, 0, 0, 28)
    t2.Position           = UDim2.new(0.05, 0, 0, 52)
    t2.BackgroundTransparency = 1
    t2.Text               = "Acesse o site para obter sua Key."
    t2.TextColor3         = Color3.fromRGB(130, 130, 180)
    t2.Font               = Enum.Font.Gotham
    t2.TextSize           = 13
    t2.TextWrapped        = true

    local input = Instance.new("TextBox", card)
    input.Size               = UDim2.new(0.85, 0, 0, 38)
    input.Position           = UDim2.new(0.075, 0, 0, 96)
    input.BackgroundColor3   = Color3.fromRGB(18, 18, 36)
    input.BorderSizePixel    = 0
    input.Text               = ""
    input.PlaceholderText    = "Cole sua Key aqui..."
    input.TextColor3         = Color3.fromRGB(220, 220, 255)
    input.PlaceholderColor3  = Color3.fromRGB(80, 80, 120)
    input.Font               = Enum.Font.GothamMono
    input.TextSize           = 14
    input.ClearTextOnFocus   = false
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 8)

    local errLbl = Instance.new("TextLabel", card)
    errLbl.Size               = UDim2.new(1, 0, 0, 18)
    errLbl.Position           = UDim2.new(0, 0, 0, 140)
    errLbl.BackgroundTransparency = 1
    errLbl.Text               = ""
    errLbl.TextColor3         = Color3.fromRGB(255, 80, 80)
    errLbl.Font               = Enum.Font.Gotham
    errLbl.TextSize           = 12

    local btn = Instance.new("TextButton", card)
    btn.Size               = UDim2.new(0.5, 0, 0, 38)
    btn.Position           = UDim2.new(0.25, 0, 0, 164)
    btn.BackgroundColor3   = Color3.fromRGB(0, 140, 220)
    btn.Text               = "Verificar"
    btn.TextColor3         = Color3.fromRGB(255, 255, 255)
    btn.Font               = Enum.Font.GothamBold
    btn.TextSize           = 15
    btn.BorderSizePixel    = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    btn.MouseButton1Click:Connect(function()
        local k = input.Text:gsub("%s", "")
        if k == HUB_CONFIG.VALID_KEY then
            safeWrite(HUB_CONFIG.KEY_SAVE_FILE, k)
            gui:Destroy()
            onSuccess()
        else
            errLbl.Text = "Key inválida! Acesse o site e obtenha a sua."
            TweenService:Create(card, TweenInfo.new(0.05), {Position=UDim2.new(0.5,-188,0.5,-110)}):Play()
            task.wait(0.05)
            TweenService:Create(card, TweenInfo.new(0.05), {Position=UDim2.new(0.5,-192,0.5,-110)}):Play()
            task.wait(0.05)
            TweenService:Create(card, TweenInfo.new(0.05), {Position=UDim2.new(0.5,-190,0.5,-110)}):Play()
        end
    end)
end

-- ============================================================
-- GUI — HUB PRINCIPAL
-- ============================================================
local function createMainHub(parent)
    local gui = Instance.new("ScreenGui")
    gui.Name           = "TopoOpHub"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent         = parent

    -- Janela principal
    local win = Instance.new("Frame", gui)
    win.Size             = UDim2.new(0, 320, 0, 310)
    win.Position         = UDim2.new(0, 20, 0.5, -155)
    win.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
    win.BorderSizePixel  = 0
    win.Active           = true
    win.Draggable        = true
    Instance.new("UICorner", win).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke", win)
    stroke.Color     = Color3.fromRGB(0, 130, 210)
    stroke.Thickness = 1.5

    -- Header
    local header = Instance.new("Frame", win)
    header.Size             = UDim2.new(1, 0, 0, 46)
    header.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
    header.BorderSizePixel  = 0
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

    -- corrige canto inferior do header
    local hFix = Instance.new("Frame", header)
    hFix.Size             = UDim2.new(1, 0, 0.5, 0)
    hFix.Position         = UDim2.new(0, 0, 0.5, 0)
    hFix.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
    hFix.BorderSizePixel  = 0

    local htitle = Instance.new("TextLabel", header)
    htitle.Size               = UDim2.new(1, -50, 1, 0)
    htitle.Position           = UDim2.new(0, 14, 0, 0)
    htitle.BackgroundTransparency = 1
    htitle.Text               = "⚡  TopoOp Wall Hop Hub"
    htitle.TextColor3         = Color3.fromRGB(255, 255, 255)
    htitle.Font               = Enum.Font.GothamBold
    htitle.TextSize           = 15
    htitle.TextXAlignment     = Enum.TextXAlignment.Left

    local verLbl = Instance.new("TextLabel", header)
    verLbl.Size               = UDim2.new(0, 50, 1, 0)
    verLbl.Position           = UDim2.new(1, -56, 0, 0)
    verLbl.BackgroundTransparency = 1
    verLbl.Text               = "v2.0"
    verLbl.TextColor3         = Color3.fromRGB(180, 230, 255)
    verLbl.Font               = Enum.Font.GothamMono
    verLbl.TextSize           = 11
    verLbl.TextXAlignment     = Enum.TextXAlignment.Right

    -- ---- Toggle ATIVO/INATIVO ----
    local function makeToggle(parent, yPos, labelText, initState, onChange)
        local row = Instance.new("Frame", parent)
        row.Size             = UDim2.new(0.9, 0, 0, 34)
        row.Position         = UDim2.new(0.05, 0, 0, yPos)
        row.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", row)
        lbl.Size              = UDim2.new(0.7, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text              = labelText
        lbl.TextColor3        = Color3.fromRGB(200, 200, 230)
        lbl.Font              = Enum.Font.Gotham
        lbl.TextSize          = 14
        lbl.TextXAlignment    = Enum.TextXAlignment.Left

        local bg = Instance.new("Frame", row)
        bg.Size             = UDim2.new(0, 46, 0, 24)
        bg.Position         = UDim2.new(1, -46, 0.5, -12)
        bg.BackgroundColor3 = initState and Color3.fromRGB(0, 160, 80) or Color3.fromRGB(60, 60, 80)
        bg.BorderSizePixel  = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame", bg)
        knob.Size             = UDim2.new(0, 20, 0, 20)
        knob.Position         = initState and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel  = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local state = initState
        local btn = Instance.new("TextButton", row)
        btn.Size             = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.Text             = ""

        btn.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(bg, TweenInfo.new(0.2), {
                BackgroundColor3 = state and Color3.fromRGB(0,160,80) or Color3.fromRGB(60,60,80)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {
                Position = state and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
            }):Play()
            onChange(state)
        end)

        return row
    end

    -- ---- Slider de graus ----
    local function makeSlider(parent, yPos, labelText, min, max, initVal, onChange)
        local row = Instance.new("Frame", parent)
        row.Size             = UDim2.new(0.9, 0, 0, 52)
        row.Position         = UDim2.new(0.05, 0, 0, yPos)
        row.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", row)
        lbl.Size              = UDim2.new(0.65, 0, 0, 22)
        lbl.BackgroundTransparency = 1
        lbl.Text              = labelText
        lbl.TextColor3        = Color3.fromRGB(200, 200, 230)
        lbl.Font              = Enum.Font.Gotham
        lbl.TextSize          = 14
        lbl.TextXAlignment    = Enum.TextXAlignment.Left

        local valLbl = Instance.new("TextLabel", row)
        valLbl.Size              = UDim2.new(0.35, 0, 0, 22)
        valLbl.Position          = UDim2.new(0.65, 0, 0, 0)
        valLbl.BackgroundTransparency = 1
        valLbl.Text              = tostring(initVal) .. "°"
        valLbl.TextColor3        = Color3.fromRGB(0, 200, 255)
        valLbl.Font              = Enum.Font.GothamBold
        valLbl.TextSize          = 14
        valLbl.TextXAlignment    = Enum.TextXAlignment.Right

        local track = Instance.new("Frame", row)
        track.Size             = UDim2.new(1, 0, 0, 6)
        track.Position         = UDim2.new(0, 0, 0, 34)
        track.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
        track.BorderSizePixel  = 0
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame", track)
        fill.BackgroundColor3 = Color3.fromRGB(0, 160, 240)
        fill.BorderSizePixel  = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local handle = Instance.new("Frame", track)
        handle.Size             = UDim2.new(0, 14, 0, 14)
        handle.AnchorPoint      = Vector2.new(0.5, 0.5)
        handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        handle.BorderSizePixel  = 0
        Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)

        local function setVal(v)
            v = math.clamp(math.floor(v), min, max)
            local pct = (v - min) / (max - min)
            fill.Size         = UDim2.new(pct, 0, 1, 0)
            handle.Position   = UDim2.new(pct, 0, 0.5, 0)
            valLbl.Text       = tostring(v) .. "°"
            onChange(v)
        end

        setVal(initVal)

        local dragging = false
        local hitbox = Instance.new("TextButton", track)
        hitbox.Size             = UDim2.new(1, 0, 0, 20)
        hitbox.Position         = UDim2.new(0, 0, 0.5, -10)
        hitbox.BackgroundTransparency = 1
        hitbox.Text             = ""

        hitbox.MouseButton1Down:Connect(function() dragging = true end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        RunService.RenderStepped:Connect(function()
            if not dragging then return end
            local mPos = UserInputService:GetMouseLocation()
            local abs  = track.AbsolutePosition
            local sz   = track.AbsoluteSize
            local pct  = math.clamp((mPos.X - abs.X) / sz.X, 0, 1)
            setVal(min + pct * (max - min))
        end)

        return row
    end

    -- ========== CONTEÚDO DA JANELA ==========

    local yOff = 56

    makeToggle(win, yOff, "Wall Hop Ativo", State.enabled, function(v)
        State.enabled = v
    end)
    yOff = yOff + 40

    makeSlider(win, yOff, "Ângulo de Rotação", 10, 180, State.degree, function(v)
        State.degree = v
    end)
    yOff = yOff + 62

    -- Divider
    local div = Instance.new("Frame", win)
    div.Size             = UDim2.new(0.85, 0, 0, 1)
    div.Position         = UDim2.new(0.075, 0, 0, yOff)
    div.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
    div.BorderSizePixel  = 0
    yOff = yOff + 10

    -- Label info
    local infoLbl = Instance.new("TextLabel", win)
    infoLbl.Size              = UDim2.new(0.9, 0, 0, 30)
    infoLbl.Position          = UDim2.new(0.05, 0, 0, yOff)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text              = "ℹ️  Câmera gira apenas ao pular na parede"
    infoLbl.TextColor3        = Color3.fromRGB(110, 110, 160)
    infoLbl.Font              = Enum.Font.Gotham
    infoLbl.TextSize          = 11
    infoLbl.TextXAlignment    = Enum.TextXAlignment.Left
    infoLbl.TextWrapped       = true
    yOff = yOff + 34

    -- Status live
    local statusLbl = Instance.new("TextLabel", win)
    statusLbl.Size              = UDim2.new(0.9, 0, 0, 22)
    statusLbl.Position          = UDim2.new(0.05, 0, 0, yOff)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text              = "● Parede: Não detectada"
    statusLbl.TextColor3        = Color3.fromRGB(80, 80, 120)
    statusLbl.Font              = Enum.Font.GothamMono
    statusLbl.TextSize          = 12
    statusLbl.TextXAlignment    = Enum.TextXAlignment.Left

    RunService.Heartbeat:Connect(function()
        if State.isOnWall then
            statusLbl.Text       = "● Parede: DETECTADA"
            statusLbl.TextColor3 = Color3.fromRGB(0, 220, 100)
        else
            statusLbl.Text       = "● Parede: Não detectada"
            statusLbl.TextColor3 = Color3.fromRGB(80, 80, 120)
        end
    end)

    yOff = yOff + 32

    -- Rodapé
    local footer = Instance.new("TextLabel", win)
    footer.Size              = UDim2.new(1, 0, 0, 22)
    footer.Position          = UDim2.new(0, 0, 0, yOff)
    footer.BackgroundTransparency = 1
    footer.Text              = "Não compartilhe sua Key — resulta em BAN"
    footer.TextColor3        = Color3.fromRGB(180, 60, 60)
    footer.Font              = Enum.Font.Gotham
    footer.TextSize          = 10

    -- ============================================================
    -- PAINEL DE BAN (só para o dono)
    -- ============================================================
    if LocalPlayer.Name == HUB_CONFIG.OWNER_NAME then

        local banBtn = Instance.new("TextButton", win)
        banBtn.Size             = UDim2.new(0, 110, 0, 28)
        banBtn.Position         = UDim2.new(0.5, -55, 0, 268)
        banBtn.BackgroundColor3 = Color3.fromRGB(160, 30, 30)
        banBtn.Text             = "🛡  Painel Ban"
        banBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
        banBtn.Font             = Enum.Font.GothamBold
        banBtn.TextSize         = 12
        banBtn.BorderSizePixel  = 0
        Instance.new("UICorner", banBtn).CornerRadius = UDim.new(0, 8)

        -- Janela de ban
        local banWin = Instance.new("Frame", gui)
        banWin.Size             = UDim2.new(0, 300, 0, 220)
        banWin.Position         = UDim2.new(0.5, -150, 0.5, -110)
        banWin.BackgroundColor3 = Color3.fromRGB(16, 6, 6)
        banWin.BorderSizePixel  = 0
        banWin.Visible          = false
        banWin.Active           = true
        banWin.Draggable        = true
        Instance.new("UICorner", banWin).CornerRadius = UDim.new(0, 14)
        local banStroke = Instance.new("UIStroke", banWin)
        banStroke.Color     = Color3.fromRGB(200, 40, 40)
        banStroke.Thickness = 1.5

        local bh = Instance.new("Frame", banWin)
        bh.Size             = UDim2.new(1, 0, 0, 40)
        bh.BackgroundColor3 = Color3.fromRGB(160, 30, 30)
        bh.BorderSizePixel  = 0
        Instance.new("UICorner", bh).CornerRadius = UDim.new(0, 14)
        local bhFix = Instance.new("Frame", bh)
        bhFix.Size             = UDim2.new(1, 0, 0.5, 0)
        bhFix.Position         = UDim2.new(0, 0, 0.5, 0)
        bhFix.BackgroundColor3 = Color3.fromRGB(160, 30, 30)
        bhFix.BorderSizePixel  = 0
        local bTitle = Instance.new("TextLabel", bh)
        bTitle.Size               = UDim2.fromScale(1, 1)
        bTitle.BackgroundTransparency = 1
        bTitle.Text               = "🛡  Painel de Banimento"
        bTitle.TextColor3         = Color3.fromRGB(255, 255, 255)
        bTitle.Font               = Enum.Font.GothamBold
        bTitle.TextSize           = 14

        local bNameInput = Instance.new("TextBox", banWin)
        bNameInput.Size             = UDim2.new(0.85, 0, 0, 34)
        bNameInput.Position         = UDim2.new(0.075, 0, 0, 54)
        bNameInput.BackgroundColor3 = Color3.fromRGB(28, 10, 10)
        bNameInput.BorderSizePixel  = 0
        bNameInput.PlaceholderText  = "Nome do jogador..."
        bNameInput.Text             = ""
        bNameInput.TextColor3       = Color3.fromRGB(255, 200, 200)
        bNameInput.PlaceholderColor3 = Color3.fromRGB(120, 60, 60)
        bNameInput.Font             = Enum.Font.GothamMono
        bNameInput.TextSize         = 13
        bNameInput.ClearTextOnFocus = false
        Instance.new("UICorner", bNameInput).CornerRadius = UDim.new(0, 8)

        local bFeedback = Instance.new("TextLabel", banWin)
        bFeedback.Size              = UDim2.new(1, 0, 0, 18)
        bFeedback.Position          = UDim2.new(0, 0, 0, 96)
        bFeedback.BackgroundTransparency = 1
        bFeedback.Text              = ""
        bFeedback.Font              = Enum.Font.Gotham
        bFeedback.TextSize          = 12

        local function makeBanActionBtn(parent, xPos, label, color, action)
            local b = Instance.new("TextButton", parent)
            b.Size             = UDim2.new(0.4, 0, 0, 32)
            b.Position         = UDim2.new(xPos, 0, 0, 120)
            b.BackgroundColor3 = color
            b.Text             = label
            b.TextColor3       = Color3.fromRGB(255, 255, 255)
            b.Font             = Enum.Font.GothamBold
            b.TextSize         = 12
            b.BorderSizePixel  = 0
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
            b.MouseButton1Click:Connect(function()
                local name = bNameInput.Text:gsub("%s", "")
                if name == "" then
                    bFeedback.Text       = "Digite um nome primeiro."
                    bFeedback.TextColor3 = Color3.fromRGB(255, 200, 80)
                    return
                end
                local ok = action(name)
                if ok then
                    bFeedback.Text       = label .. " aplicado: " .. name
                    bFeedback.TextColor3 = Color3.fromRGB(100, 255, 100)
                else
                    bFeedback.Text       = "Operação falhou ou já feita."
                    bFeedback.TextColor3 = Color3.fromRGB(255, 100, 100)
                end
            end)
        end

        makeBanActionBtn(banWin, 0.075, "🔨 Banir", Color3.fromRGB(180, 40, 40), banPlayer)
        makeBanActionBtn(banWin, 0.525, "✅ Desbanir", Color3.fromRGB(40, 130, 60), unbanPlayer)

        -- lista de banidos
        local listLbl = Instance.new("TextLabel", banWin)
        listLbl.Size              = UDim2.new(0.85, 0, 0, 28)
        listLbl.Position          = UDim2.new(0.075, 0, 0, 164)
        listLbl.BackgroundTransparency = 1
        listLbl.Font              = Enum.Font.GothamMono
        listLbl.TextSize          = 10
        listLbl.TextColor3        = Color3.fromRGB(180, 100, 100)
        listLbl.TextXAlignment    = Enum.TextXAlignment.Left
        listLbl.TextWrapped       = true

        local function refreshList()
            local names = {}
            for n in pairs(BanList) do table.insert(names, n) end
            if #names == 0 then
                listLbl.Text = "Nenhum banido."
            else
                listLbl.Text = "Banidos: " .. table.concat(names, ", ")
            end
        end

        refreshList()
        banBtn.MouseButton1Click:Connect(function()
            refreshList()
            banWin.Visible = not banWin.Visible
        end)

        -- fechar painel ban ao clicar fora (botão X)
        local closeB = Instance.new("TextButton", banWin)
        closeB.Size             = UDim2.new(0, 24, 0, 24)
        closeB.Position         = UDim2.new(1, -28, 0, 8)
        closeB.BackgroundTransparency = 1
        closeB.Text             = "✕"
        closeB.TextColor3       = Color3.fromRGB(255, 180, 180)
        closeB.Font             = Enum.Font.GothamBold
        closeB.TextSize         = 14
        closeB.BorderSizePixel  = 0
        closeB.MouseButton1Click:Connect(function()
            banWin.Visible = false
        end)
    end

    -- Minimizar / maximizar
    local minimized = false
    local originalH = 310

    local minBtn = Instance.new("TextButton", win)
    minBtn.Size             = UDim2.new(0, 28, 0, 28)
    minBtn.Position         = UDim2.new(1, -34, 0, 9)
    minBtn.BackgroundTransparency = 1
    minBtn.Text             = "—"
    minBtn.TextColor3       = Color3.fromRGB(200, 200, 255)
    minBtn.Font             = Enum.Font.GothamBold
    minBtn.TextSize         = 16

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(win, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            Size = minimized and UDim2.new(0,320,0,46) or UDim2.new(0,320,0,originalH)
        }):Play()
        minBtn.Text = minimized and "□" or "—"
    end)
end

-- ============================================================
-- INICIALIZAÇÃO PRINCIPAL
-- ============================================================
local function init()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    -- Tela de carregamento
    createLoadingScreen(pg)
    task.wait(2.2)

    -- Checa Key salva
    local savedKey = safeRead(HUB_CONFIG.KEY_SAVE_FILE)
    if savedKey and savedKey:gsub("%s","") == HUB_CONFIG.VALID_KEY then
        State.keyValid = true
        createMainHub(pg)
        startWallHopLoop()
    else
        createKeyScreen(pg, function()
            State.keyValid = true
            createMainHub(pg)
            startWallHopLoop()
        end)
    end
end

init()
