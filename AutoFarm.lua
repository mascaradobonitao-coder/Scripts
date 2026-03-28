-- ╔══════════════════════════════════════════════════════╗
-- ║           AUTO FARM - RAYFIELD UI                   ║
-- ║     Sistema modular sem dependência de remotes      ║
-- ╚══════════════════════════════════════════════════════╝

-- ══════════════════════════════════════════
-- [SERVICES]
-- ══════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- ══════════════════════════════════════════
-- [RAYFIELD LOADER]
-- ══════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/rayfield"
))()

-- ══════════════════════════════════════════
-- [ESTADO GLOBAL]
-- ══════════════════════════════════════════
local State = {
    -- toggles
    AutoStrength  = false,
    AutoSpeed     = false,
    AutoFly       = false,
    AutoKi        = false,
    AutoZenkai    = false,
    AntiAFK       = false,
    AutoRespawn   = false,

    -- fly
    IsFlying      = false,
    TurboActive   = false,

    -- ki
    KiLevel       = 100,   -- 0-100
    KiSource      = "none",-- "leaderstats" | "attribute" | "gui" | "timer"

    -- zenkai
    MaxZenkai     = 5,
    CurrentZenkai = 0,
    ZenkaiActive  = false,

    -- debug
    StatusText    = "Idle",
    DetectedKeys  = {},
    FlyDetected   = false,
}

-- ══════════════════════════════════════════
-- [VIRTUAL INPUT MANAGER]
-- ══════════════════════════════════════════
local VIM = {}

-- Simula clique do mouse (soco)
function VIM.Click()
    VirtualUser:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(0.05)
    VirtualUser:Button1Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end

-- Simula pressionar tecla por duração
function VIM.PressKey(keyCode, duration)
    VirtualUser:CaptureController()
    VirtualUser:StartRecording()

    local key = keyCode
    -- Envia keydown
    game:GetService("VirtualInputManager"):SendKeyEvent(true,  key, false, game)
    task.wait(duration or 0.1)
    game:GetService("VirtualInputManager"):SendKeyEvent(false, key, false, game)

    VirtualUser:StopRecording()
end

-- Simula segurar tecla (sem soltar até cancelar)
local heldKeys = {}
function VIM.HoldKey(keyCode)
    if heldKeys[keyCode] then return end
    heldKeys[keyCode] = true
    task.spawn(function()
        while heldKeys[keyCode] do
            game:GetService("VirtualInputManager"):SendKeyEvent(true, keyCode, false, game)
            task.wait(0.05)
        end
        game:GetService("VirtualInputManager"):SendKeyEvent(false, keyCode, false, game)
    end)
end

function VIM.ReleaseKey(keyCode)
    heldKeys[keyCode] = nil
end

-- ══════════════════════════════════════════
-- [HELPERS: PLAYER / CHARACTER]
-- ══════════════════════════════════════════
local function GetChar()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local c = GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function IsAlive()
    local h = GetHumanoid()
    return h and h.Health > 0
end

-- Aguarda respawn se necessário
local function WaitForChar()
    while not IsAlive() do
        State.StatusText = "Aguardando respawn..."
        task.wait(0.5)
    end
end

-- ══════════════════════════════════════════
-- [BYTENET PLACEHOLDER]
-- ══════════════════════════════════════════
-- Estrutura preparada para uso futuro com ByteNetReliable.
-- NÃO usar sem conhecer os argumentos corretos.
local function TryByteNet(...)
    -- local remote = ReplicatedStorage:FindFirstChild("ByteNetReliable")
    -- if remote then
    --     remote:FireServer(...)  -- preencher args quando descobertos
    -- end
end

-- ══════════════════════════════════════════
-- [DETECÇÃO AUTOMÁTICA DE KI]
-- ══════════════════════════════════════════
local kiTimer       = 0
local KI_REGEN_TIME = 30 -- segundos para 100% (estimativa)

local function ScanGuiForKi()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return nil end

    for _, screen in ipairs(gui:GetDescendants()) do
        local name = screen.Name:lower()
        -- procura frames/labels com nomes típicos de ki
        if name:find("ki") or name:find("energy") or name:find("chakra") then
            -- tenta ler valor numérico de um TextLabel filho
            for _, child in ipairs(screen:GetDescendants()) do
                if child:IsA("TextLabel") then
                    local num = tonumber(child.Text:match("%d+"))
                    if num then
                        State.KiSource = "gui"
                        return num
                    end
                end
            end
            -- tenta ler como barra (Frame com Size.X.Scale)
            if screen:IsA("Frame") then
                local pct = screen.Size.X.Scale * 100
                if pct >= 0 and pct <= 100 then
                    State.KiSource = "gui_bar"
                    return pct
                end
            end
        end
    end
    return nil
end

local function GetKiLevel()
    -- 1) leaderstats
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        local kiStat = ls:FindFirstChild("Ki")
                    or ls:FindFirstChild("Energy")
                    or ls:FindFirstChild("Chakra")
        if kiStat then
            local max = 100
            local val = tonumber(kiStat.Value) or 0
            State.KiSource = "leaderstats"
            return math.clamp((val / math.max(max, 1)) * 100, 0, 100)
        end
    end

    -- 2) attributes
    local char = GetChar()
    if char then
        local ki  = char:GetAttribute("Ki")
                 or char:GetAttribute("Energy")
                 or char:GetAttribute("Chakra")
        local maxKi = char:GetAttribute("MaxKi")
                   or char:GetAttribute("MaxEnergy")
                   or 100
        if ki then
            State.KiSource = "attribute"
            return math.clamp((ki / math.max(maxKi, 1)) * 100, 0, 100)
        end
    end

    -- 3) PlayerGui scan
    local guiVal = ScanGuiForKi()
    if guiVal then return guiVal end

    -- 4) fallback timer
    State.KiSource = "timer"
    kiTimer = kiTimer + task.wait()
    return math.clamp((kiTimer / KI_REGEN_TIME) * 100, 0, 100)
end

-- ══════════════════════════════════════════
-- [1] AUTO STRENGTH (SOCO)
-- ══════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.1)
        if State.AutoStrength and IsAlive() then
            if State.AutoKi and State.KiLevel < 30 then
                -- Ki baixo: pausa o soco para não gastar
                task.wait(0.5)
            else
                VIM.Click()
                task.wait(math.random(10, 30) / 100) -- 0.10 - 0.30
            end
        end
    end
end)

-- ══════════════════════════════════════════
-- [2] AUTO SPEED (AGILIDADE VIA MOVIMENTO)
-- ══════════════════════════════════════════
local speedDir = 1 -- 1 = frente, -1 = trás
task.spawn(function()
    while true do
        task.wait(0.1)
        if State.AutoSpeed and IsAlive() then
            local root = GetRootPart()
            local hum  = GetHumanoid()
            if root and hum then
                -- destino: 20 studs na direção atual
                local offset = root.CFrame.LookVector * (20 * speedDir)
                local target = root.Position + offset
                hum:MoveTo(target)

                task.wait(1.8) -- tempo para chegar
                speedDir = speedDir * -1 -- inverte direção
            end
        end
    end
end)

-- ══════════════════════════════════════════
-- [3] AUTO FLY + TURBO
-- ══════════════════════════════════════════
local flyKeys   = {"F", "E"}        -- teclas para testar
local flyActive = false
local flyThread = nil

local function DetectFly()
    -- Testa cada tecla e verifica se o personagem subiu
    for _, key in ipairs(flyKeys) do
        local root   = GetRootPart()
        if not root then continue end
        local startY = root.Position.Y

        VIM.PressKey(Enum.KeyCode[key], 0.3)
        task.wait(0.5)

        local newY = root and root.Position.Y or startY
        if newY > startY + 2 then
            State.FlyDetected = true
            table.insert(State.DetectedKeys, "Fly:"..key)
            return key
        end
    end
    return nil
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if State.AutoFly and IsAlive() then
            if not flyActive then
                State.StatusText = "Detectando fly..."
                local key = DetectFly()
                if key then
                    flyActive = true
                    State.IsFlying = true
                    State.StatusText = "Voando ("..key..")"

                    -- Mantém fly ativo
                    flyThread = task.spawn(function()
                        while flyActive and State.AutoFly do
                            VIM.PressKey(Enum.KeyCode[key], 0.1)

                            -- Turbo (LeftShift)
                            if not State.TurboActive then
                                VIM.HoldKey(Enum.KeyCode.LeftShift)
                                State.TurboActive = true
                                table.insert(State.DetectedKeys, "Turbo:LeftShift")
                            end

                            -- Movimento lateral no ar
                            local root = GetRootPart()
                            local hum  = GetHumanoid()
                            if root and hum then
                                local side = (math.random(0, 1) == 0) and
                                    root.CFrame.RightVector or
                                    -root.CFrame.RightVector
                                hum:MoveTo(root.Position + side * 10 + Vector3.new(0, 5, 0))
                            end

                            task.wait(1.5)
                        end
                        VIM.ReleaseKey(Enum.KeyCode.LeftShift)
                        State.TurboActive = false
                    end)
                else
                    State.StatusText = "Fly não detectado"
                    task.wait(3)
                end
            end
        else
            if flyActive then
                flyActive = false
                State.IsFlying   = false
                State.TurboActive = false
                VIM.ReleaseKey(Enum.KeyCode.LeftShift)
            end
        end
    end
end)

-- ══════════════════════════════════════════
-- [4] AUTO KI
-- ══════════════════════════════════════════
local kiCharging = false
task.spawn(function()
    while true do
        task.wait(0.5)
        if State.AutoKi and IsAlive() then
            State.KiLevel = GetKiLevel()

            if State.KiLevel < 30 and not kiCharging then
                -- Ki baixo: começar a carregar
                kiCharging = true
                State.StatusText = "Carregando Ki... ("..math.floor(State.KiLevel).."%)"
                VIM.HoldKey(Enum.KeyCode.C) -- ou K; alterar conforme jogo

            elseif State.KiLevel >= 100 and kiCharging then
                -- Ki cheio: parar carga
                kiCharging = false
                kiTimer = KI_REGEN_TIME
                VIM.ReleaseKey(Enum.KeyCode.C)
                State.StatusText = "Ki cheio!"
            end
        else
            if kiCharging then
                kiCharging = false
                VIM.ReleaseKey(Enum.KeyCode.C)
            end
        end
    end
end)

-- ══════════════════════════════════════════
-- [5] AUTO ZENKAI
-- ══════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.5)
        if State.AutoZenkai and IsAlive() then
            local hum = GetHumanoid()
            if hum then
                local hpPct = (hum.Health / math.max(hum.MaxHealth, 1)) * 100

                if hpPct < 20 and not State.ZenkaiActive then
                    -- Vida crítica: possível zenkai
                    if State.CurrentZenkai < State.MaxZenkai then
                        State.ZenkaiActive = true
                        State.StatusText   = "Zenkai detectado! ("..State.CurrentZenkai.."/"..State.MaxZenkai..")"
                        -- aguarda morrer / revivar naturalmente
                        task.wait(2)
                        State.CurrentZenkai = State.CurrentZenkai + 1

                    else
                        -- Limite atingido
                        State.AutoZenkai = false
                        State.StatusText = "Limite de Zenkai atingido!"
                    end
                end

                if hum.Health > hum.MaxHealth * 0.5 then
                    State.ZenkaiActive = false
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════
-- [6] DETECÇÃO AUTOMÁTICA (SCAN GUI)
-- ══════════════════════════════════════════
-- Já integrado em GetKiLevel() via ScanGuiForKi()

-- ══════════════════════════════════════════
-- [7] ANTI AFK
-- ══════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(60)
        if State.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end
    end
end)

-- ══════════════════════════════════════════
-- [8] AUTO RESPAWN
-- ══════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(1)
        if State.AutoRespawn then
            local hum = GetHumanoid()
            if hum and hum.Health <= 0 then
                task.wait(3)
                LocalPlayer:LoadCharacter()
            end
        end
    end
end)

-- ══════════════════════════════════════════
-- [9] SISTEMA INTELIGENTE: REINÍCIO PÓS-MORTE
-- ══════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(char)
    State.StatusText = "Personagem carregado, reiniciando farm..."
    State.IsFlying    = false
    State.TurboActive = false
    flyActive         = false
    kiCharging        = false
    VIM.ReleaseKey(Enum.KeyCode.LeftShift)
    VIM.ReleaseKey(Enum.KeyCode.C)
    heldKeys = {}
    task.wait(2) -- grace period
    State.StatusText = "Farm ativo"
end)

-- ══════════════════════════════════════════
-- [RAYFIELD UI]
-- ══════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name             = "Auto Farm",
    LoadingTitle     = "Auto Farm",
    LoadingSubtitle  = "by script",
    ConfigurationSaving = {
        Enabled  = true,
        FileName = "AutoFarmCFG"
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- ─── ABA: FARM ────────────────────────────
local FarmTab = Window:CreateTab("⚔️ Farm", 4483362458)

FarmTab:CreateToggle({
    Name      = "Auto Strength (Soco)",
    CurrentValue = false,
    Flag      = "AutoStrength",
    Callback  = function(v) State.AutoStrength = v end,
})

FarmTab:CreateToggle({
    Name      = "Auto Speed (Agilidade)",
    CurrentValue = false,
    Flag      = "AutoSpeed",
    Callback  = function(v) State.AutoSpeed = v end,
})

FarmTab:CreateToggle({
    Name      = "Auto Fly + Turbo",
    CurrentValue = false,
    Flag      = "AutoFly",
    Callback  = function(v)
        State.AutoFly = v
        if not v then
            flyActive = false
            State.IsFlying   = false
            State.TurboActive = false
            VIM.ReleaseKey(Enum.KeyCode.LeftShift)
        end
    end,
})

-- ─── ABA: KI ──────────────────────────────
local KiTab = Window:CreateTab("💠 Ki", 4483362458)

KiTab:CreateToggle({
    Name      = "Auto Ki (Carregar / Controlar)",
    CurrentValue = false,
    Flag      = "AutoKi",
    Callback  = function(v)
        State.AutoKi = v
        if not v then
            kiCharging = false
            VIM.ReleaseKey(Enum.KeyCode.C)
        end
    end,
})

KiTab:CreateInput({
    Name        = "Tecla de Ki (padrão: C)",
    CurrentValue = "C",
    PlaceholderText = "C ou K",
    NumbersOnly = false,
    Callback    = function(val)
        -- pode ser usado futuramente para trocar a tecla de ki
    end,
})

-- ─── ABA: ZENKAI ──────────────────────────
local ZenkaiTab = Window:CreateTab("⚡ Zenkai", 4483362458)

ZenkaiTab:CreateToggle({
    Name      = "Auto Zenkai",
    CurrentValue = false,
    Flag      = "AutoZenkai",
    Callback  = function(v) State.AutoZenkai = v end,
})

ZenkaiTab:CreateSlider({
    Name       = "Limite de Zenkai",
    Range      = {1, 50},
    Increment  = 1,
    Suffix     = "x",
    CurrentValue = 5,
    Flag       = "MaxZenkai",
    Callback   = function(v)
        State.MaxZenkai = v
    end,
})

ZenkaiTab:CreateButton({
    Name     = "Resetar Contador Zenkai",
    Callback = function()
        State.CurrentZenkai = 0
        State.AutoZenkai    = true
        Rayfield:Notify({
            Title    = "Zenkai",
            Content  = "Contador resetado!",
            Duration = 3,
        })
    end,
})

-- ─── ABA: MISC ────────────────────────────
local MiscTab = Window:CreateTab("🔧 Misc", 4483362458)

MiscTab:CreateToggle({
    Name      = "Anti AFK",
    CurrentValue = false,
    Flag      = "AntiAFK",
    Callback  = function(v) State.AntiAFK = v end,
})

MiscTab:CreateToggle({
    Name      = "Auto Respawn",
    CurrentValue = false,
    Flag      = "AutoRespawn",
    Callback  = function(v) State.AutoRespawn = v end,
})

-- ─── ABA: DEBUG ───────────────────────────
local DebugTab = Window:CreateTab("🐛 Debug", 4483362458)

local StatusLabel = DebugTab:CreateLabel("Status: Idle")
local FlyLabel    = DebugTab:CreateLabel("Voando: Não")
local KiLabel     = DebugTab:CreateLabel("Ki: --% | Fonte: --")
local ZenkaiLabel = DebugTab:CreateLabel("Zenkai: 0/5")
local KeysLabel   = DebugTab:CreateLabel("Teclas detectadas: nenhuma")

-- Atualização do painel Debug
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            StatusLabel:Set("Status: " .. State.StatusText)
            FlyLabel:Set("Voando: " .. (State.IsFlying and "✅ Sim" or "❌ Não") ..
                         " | Turbo: " .. (State.TurboActive and "✅" or "❌"))
            KiLabel:Set("Ki: " .. math.floor(State.KiLevel) ..
                        "% | Fonte: " .. State.KiSource ..
                        (kiCharging and " [CARREGANDO]" or ""))
            ZenkaiLabel:Set("Zenkai: " .. State.CurrentZenkai ..
                            "/" .. State.MaxZenkai ..
                            (State.ZenkaiActive and " [ATIVO]" or ""))
            local keyStr = #State.DetectedKeys > 0
                and table.concat(State.DetectedKeys, ", ")
                or "nenhuma"
            KeysLabel:Set("Teclas: " .. keyStr)
        end)
    end
end)

-- ══════════════════════════════════════════
-- INIT
-- ══════════════════════════════════════════
Rayfield:Notify({
    Title    = "Auto Farm",
    Content  = "Script carregado! Ative os toggles para começar.",
    Duration = 5,
})

State.StatusText = "Pronto"
