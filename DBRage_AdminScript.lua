--[[
    Dragon Ball Rage - Admin Script (Client-Side)
    Auto Farm | Auto Fly (Agility) | Auto Ki Recharge | Auto Zenkai
    GUI Arrastável | Logs | Baseplate | Teleporte
--]]

-- ===================== SERVIÇOS =====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local mouse = lp:GetMouse()

-- ===================== ESTADO =====================
local state = {
    autoFarm = false,
    autoFly = false,
    fastFly = false,
    autoKiRecharge = false,
    autoZenkai = false,
    farmStartTime = nil,
    farmElapsed = 0,
    currentStat = "Strength", -- cicla entre Strength, Agility, Defense, Ki
    logs = {},
    maxLogs = 200,
    guiOpen = true,
    flySpeed = 150,
    fastFlySpeed = 600,
    kiRechargeFull = false,
    baseplateCreated = false,
    baseplatePart = nil,
}

-- ===================== UTILITÁRIOS =====================
local function addLog(msg)
    local t = os.date("%H:%M:%S")
    local entry = "[" .. t .. "] " .. msg
    table.insert(state.logs, 1, entry)
    if #state.logs > state.maxLogs then
        table.remove(state.logs)
    end
    return entry
end

local function getChar()
    return lp.Character
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getStats()
    return lp:FindFirstChild("Stats") or lp:FindFirstChild("leaderstats")
end

local function getStatValue(name)
    local stats = getStats()
    if stats then
        local v = stats:FindFirstChild(name)
        return v and v.Value or 0
    end
    return 0
end

local function getMaxStatValue(name)
    local stats = getStats()
    if stats then
        -- Tenta BaseMaxStats ou MaxStats
        local maxFolder = stats:FindFirstChild("MaxStats") or stats:FindFirstChild("Limits")
        if maxFolder then
            local v = maxFolder:FindFirstChild(name)
            if v then return v.Value end
        end
        -- Tenta atributo BaseMaxStats do jogo (45000000 conforme config)
    end
    return 45000000 -- BaseMaxStats do jogo
end

-- ===================== BASEPLATE =====================
local function createBaseplate()
    if state.baseplateCreated and state.baseplatePart and state.baseplatePart.Parent then
        return state.baseplatePart
    end
    local bp = Instance.new("Part")
    bp.Name = "AdminBaseplate"
    bp.Anchored = true
    bp.Size = Vector3.new(2048, 4, 2048)
    bp.Position = Vector3.new(0, 10000, 0)
    bp.Material = Enum.Material.SmoothPlastic
    bp.BrickColor = BrickColor.new("Bright green")
    bp.Parent = Workspace
    state.baseplatePart = bp
    state.baseplateCreated = true
    addLog("Baseplate criada em Y=10000")
    return bp
end

local function teleportToBaseplate()
    local bp = createBaseplate()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(bp.Position + Vector3.new(0, 5, 0))
        addLog("Teleportado para a baseplate")
    end
end

-- ===================== VOOAR =====================
local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil

local function stopFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    local hrp = getHRP()
    if hrp then
        -- Limpa FlightVelocity e FlightAngle se o jogo criou
        local fv = hrp:FindFirstChild("FlightVelocity")
        local fa = hrp:FindFirstChild("FlightAngle")
        -- Não destruímos os do jogo, só os nossos
    end
    local hum = getHumanoid()
    if hum then
        hum.PlatformStand = false
    end
end

local function startFly()
    stopFly()
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return end

    hum.PlatformStand = true

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVelocity.Name = "AdminFlyVelocity"
    bodyVelocity.Parent = hrp

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro.P = 10000
    bodyGyro.Name = "AdminFlyGyro"
    bodyGyro.Parent = hrp

    flyConnection = RunService.Heartbeat:Connect(function()
        if not state.autoFly then
            stopFly()
            return
        end
        local hrp2 = getHRP()
        if not hrp2 then return end

        local speed = state.fastFly and state.fastFlySpeed or state.flySpeed
        local camDir = workspace.CurrentCamera.CFrame.LookVector
        local vel = Vector3.new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            vel = camDir * speed
        elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then
            vel = -camDir * speed
        elseif UserInputService:IsKeyDown(Enum.KeyCode.A) then
            vel = -workspace.CurrentCamera.CFrame.RightVector * speed
        elseif UserInputService:IsKeyDown(Enum.KeyCode.D) then
            vel = workspace.CurrentCamera.CFrame.RightVector * speed
        elseif UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            vel = Vector3.new(0, speed, 0)
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            vel = Vector3.new(0, -speed, 0)
        end

        bodyVelocity.Velocity = vel
        bodyGyro.CFrame = workspace.CurrentCamera.CFrame
    end)
    addLog("Voo ativado (velocidade: " .. (state.fastFly and state.fastFlySpeed or state.flySpeed) .. ")")
end

-- ===================== KI RECHARGE =====================
local function tryRechargeKi()
    -- Tenta disparar o evento de recarregar Ki do jogo
    -- O jogo usa remotes dentro de ReplicatedStorage ou dentro de scripts
    local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events")
    if remotes then
        local recharge = remotes:FindFirstChild("RechargeKi")
            or remotes:FindFirstChild("KiRecharge")
            or remotes:FindFirstChild("ChargeKi")
        if recharge then
            recharge:FireServer()
            return true
        end
    end
    -- Fallback: simula tecla Q (comum para recarregar Ki em DBR)
    -- Nota: apenas via virtual input services
    return false
end

local kiRechargeConn = nil

local function startKiRecharge()
    if kiRechargeConn then kiRechargeConn:Disconnect() end
    kiRechargeConn = RunService.Heartbeat:Connect(function()
        if not state.autoKiRecharge then
            if kiRechargeConn then kiRechargeConn:Disconnect() end
            return
        end
        -- Verifica Ki atual via Stats
        local stats = getStats()
        if stats then
            local currentKi = stats:FindFirstChild("CurrentKi") or stats:FindFirstChild("Ki")
            local maxKi = stats:FindFirstChild("MaxKi")
            if currentKi and maxKi then
                if currentKi.Value < maxKi.Value then
                    tryRechargeKi()
                end
            else
                -- Tenta mesmo assim
                tryRechargeKi()
            end
        end
    end)
end

-- ===================== AUTO FARM =====================
local STAT_ORDER = {"Strength", "Agility", "Defense", "Ki"}
local currentStatIdx = 1

local function getNextTarget()
    -- Encontra NPC com tag Character mais próximo
    local hrp = getHRP()
    if not hrp then return nil end

    local closest = nil
    local closestDist = math.huge

    for _, model in pairs(workspace:GetChildren()) do
        if model:IsA("Model") and model ~= lp.Character then
            -- Verifica tag Character
            if model:HasTag("Character") or model:GetAttribute("Key") then
                local targetHRP = model:FindFirstChild("HumanoidRootPart")
                local hum = model:FindFirstChildOfClass("Humanoid")
                if targetHRP and hum and hum.Health > 0 then
                    local dist = (hrp.Position - targetHRP.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = model
                    end
                end
            end
        end
    end
    return closest
end

local function trainCurrentStat()
    -- Tenta usar remotes de treino de stat
    local statName = STAT_ORDER[currentStatIdx]
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        or ReplicatedStorage:FindFirstChild("Events")
        or ReplicatedStorage

    -- Procura remote de treino
    local trainRemote = nil
    for _, v in pairs(remotes:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local n = v.Name:lower()
            if n:find("train") or n:find("stat") or n:find("punch") or n:find("strike") then
                trainRemote = v
                break
            end
        end
    end

    if trainRemote then
        if trainRemote:IsA("RemoteEvent") then
            trainRemote:FireServer(statName)
        elseif trainRemote:IsA("RemoteFunction") then
            trainRemote:InvokeServer(statName)
        end
    end
end

local autoFarmConn = nil
local autoFarmTick = 0

local function startAutoFarm()
    if autoFarmConn then autoFarmConn:Disconnect() end
    state.farmStartTime = tick()

    autoFarmConn = RunService.Heartbeat:Connect(function(dt)
        if not state.autoFarm then
            if autoFarmConn then autoFarmConn:Disconnect() end
            return
        end

        state.farmElapsed = tick() - state.farmStartTime
        autoFarmTick = autoFarmTick + dt

        -- Verifica se stat atual atingiu limite → próximo stat
        local currentStat = STAT_ORDER[currentStatIdx]
        local val = getStatValue(currentStat)
        local maxVal = getMaxStatValue(currentStat)

        if val >= maxVal then
            addLog("Stat " .. currentStat .. " maximizado! Passando para próximo...")
            currentStatIdx = currentStatIdx % #STAT_ORDER + 1
            addLog("Agora treinando: " .. STAT_ORDER[currentStatIdx])
        end

        -- Auto Ki recharge quando Ki estiver vazio
        if state.autoKiRecharge then
            local stats = getStats()
            if stats then
                local curKi = stats:FindFirstChild("CurrentKi") or stats:FindFirstChild("Ki")
                if curKi and curKi.Value <= 0 then
                    tryRechargeKi()
                end
            end
        end

        -- A cada 0.1s tenta atacar o target mais próximo
        if autoFarmTick >= 0.1 then
            autoFarmTick = 0
            local target = getNextTarget()
            if target then
                local hrp = getHRP()
                local targetHRP = target:FindFirstChild("HumanoidRootPart")
                if hrp and targetHRP then
                    -- Teleporta perto do alvo se muito longe
                    local dist = (hrp.Position - targetHRP.Position).Magnitude
                    if dist > 20 then
                        hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 5)
                    end
                end
                -- Tenta ativar ataque
                trainCurrentStat()
            end
        end
    end)

    addLog("Auto Farm iniciado | Treinando: " .. STAT_ORDER[currentStatIdx])
end

-- ===================== AUTO ZENKAI =====================
local zenkaiConn = nil

local function startAutoZenkai()
    if zenkaiConn then zenkaiConn:Disconnect() end
    zenkaiConn = RunService.Heartbeat:Connect(function()
        if not state.autoZenkai then
            if zenkaiConn then zenkaiConn:Disconnect() end
            return
        end

        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            or ReplicatedStorage:FindFirstChild("Events")
            or ReplicatedStorage

        for _, v in pairs(remotes:GetDescendants()) do
            if v:IsA("RemoteEvent") and (v.Name:lower():find("zenkai") or v.Name:lower():find("boost")) then
                v:FireServer()
                break
            end
        end
    end)
    addLog("Auto Zenkai ativado")
end

-- ===================== GUI =====================
-- Remove GUI antiga
if lp.PlayerGui:FindFirstChild("DBRageAdmin") then
    lp.PlayerGui:FindFirstChild("DBRageAdmin"):Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DBRageAdmin"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.Parent = lp.PlayerGui

-- ===== BOTÃO ABRIR/FECHAR (sempre visível) =====
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.new(0, 110, 0, 32)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -16)
toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "⚡ DBRage"
toggleBtn.TextColor3 = Color3.fromRGB(255, 220, 50)
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleBtn

-- ===== JANELA PRINCIPAL (arrastável) =====
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 560)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -280)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

-- Stroke da janela
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(80, 80, 160)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

-- ===== HEADER (arrastável) =====
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(25, 25, 50)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ Dragon Ball Rage Admin"
title.TextColor3 = Color3.fromRGB(255, 220, 50)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -38, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = header

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

-- ===== DRAG LOGIC =====
local dragging = false
local dragStart = nil
local startPos = nil

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ===== SCROLL CONTENT =====
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -40)
scrollFrame.Position = UDim2.new(0, 0, 0, 40)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 180)
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = scrollFrame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.PaddingTop = UDim.new(0, 8)
padding.Parent = scrollFrame

-- ===== HELPERS DE UI =====
local function makeSection(labelText)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(120, 120, 220)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = scrollFrame
    return lbl
end

local function makeToggleButton(labelText, key, onToggle)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Parent = scrollFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 50, 100)
    stroke.Thickness = 1
    stroke.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(220, 220, 255)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 40, 0, 20)
    indicator.Position = UDim2.new(1, -50, 0.5, -10)
    indicator.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    indicator.BorderSizePixel = 0
    indicator.Parent = btn

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indicator

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = UDim2.new(0, 2, 0.5, -8)
    dot.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    dot.BorderSizePixel = 0
    dot.Parent = indicator

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    local function updateVisual()
        local on = state[key]
        if on then
            indicator.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
            dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TweenService:Create(dot, TweenInfo.new(0.15), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
        else
            indicator.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            dot.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
            TweenService:Create(dot, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
        end
    end

    btn.MouseButton1Click:Connect(function()
        state[key] = not state[key]
        updateVisual()
        if onToggle then onToggle(state[key]) end
    end)

    updateVisual()
    return btn, updateVisual
end

local function makeActionButton(labelText, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 70)
    btn.BorderSizePixel = 0
    btn.Text = labelText
    btn.TextColor3 = Color3.fromRGB(200, 200, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Parent = scrollFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 180)
    stroke.Thickness = 1
    stroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
        task.delay(0.15, function()
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 70)
        end)
        onClick()
    end)
    return btn
end

-- ===== STATUS AUTO FARM =====
local farmStatusFrame = Instance.new("Frame")
farmStatusFrame.Size = UDim2.new(1, 0, 0, 50)
farmStatusFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 15)
farmStatusFrame.BorderSizePixel = 0
farmStatusFrame.Visible = false
farmStatusFrame.Parent = scrollFrame

local farmStatusCorner = Instance.new("UICorner")
farmStatusCorner.CornerRadius = UDim.new(0, 6)
farmStatusCorner.Parent = farmStatusFrame

local farmStatusLabel = Instance.new("TextLabel")
farmStatusLabel.Size = UDim2.new(1, -10, 1, 0)
farmStatusLabel.Position = UDim2.new(0, 5, 0, 0)
farmStatusLabel.BackgroundTransparency = 1
farmStatusLabel.Text = "🌱 Auto Farm: OFF"
farmStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
farmStatusLabel.TextSize = 13
farmStatusLabel.Font = Enum.Font.GothamBold
farmStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
farmStatusLabel.TextWrapped = true
farmStatusLabel.Parent = farmStatusFrame

-- ===== CURRENT STAT LABEL =====
local currentStatLabel = Instance.new("TextLabel")
currentStatLabel.Size = UDim2.new(1, 0, 0, 22)
currentStatLabel.BackgroundTransparency = 1
currentStatLabel.Text = "Stat Atual: Strength"
currentStatLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
currentStatLabel.TextSize = 12
currentStatLabel.Font = Enum.Font.Gotham
currentStatLabel.TextXAlignment = Enum.TextXAlignment.Left
currentStatLabel.Parent = scrollFrame

-- ===== CONSTRUÇÃO DOS BOTÕES =====
makeSection("── AUTO FARM ──")

local farmBtn, farmUpdate = makeToggleButton("Auto Farm", "autoFarm", function(on)
    if on then
        farmStatusFrame.Visible = true
        teleportToBaseplate()
        startAutoFarm()
    else
        farmStatusFrame.Visible = false
        addLog("Auto Farm desativado")
    end
end)

-- Separador de stat
local statFrame = Instance.new("Frame")
statFrame.Size = UDim2.new(1, 0, 0, 34)
statFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
statFrame.BorderSizePixel = 0
statFrame.Parent = scrollFrame

local statCorner = Instance.new("UICorner")
statCorner.CornerRadius = UDim.new(0, 6)
statCorner.Parent = statFrame

local statLabel = Instance.new("TextLabel")
statLabel.Size = UDim2.new(0.5, 0, 1, 0)
statLabel.Position = UDim2.new(0, 10, 0, 0)
statLabel.BackgroundTransparency = 1
statLabel.Text = "Stat: Strength"
statLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
statLabel.TextSize = 13
statLabel.Font = Enum.Font.Gotham
statLabel.TextXAlignment = Enum.TextXAlignment.Left
statLabel.Parent = statFrame

local cyclBtn = Instance.new("TextButton")
cyclBtn.Size = UDim2.new(0, 90, 0, 26)
cyclBtn.Position = UDim2.new(1, -98, 0.5, -13)
cyclBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
cyclBtn.BorderSizePixel = 0
cyclBtn.Text = "Ciclar ▶"
cyclBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
cyclBtn.TextSize = 12
cyclBtn.Font = Enum.Font.GothamBold
cyclBtn.Parent = statFrame

local cyclCorner = Instance.new("UICorner")
cyclCorner.CornerRadius = UDim.new(0, 4)
cyclCorner.Parent = cyclBtn

cyclBtn.MouseButton1Click:Connect(function()
    currentStatIdx = currentStatIdx % #STAT_ORDER + 1
    state.currentStat = STAT_ORDER[currentStatIdx]
    statLabel.Text = "Stat: " .. STAT_ORDER[currentStatIdx]
    addLog("Stat trocado para: " .. STAT_ORDER[currentStatIdx])
end)

makeSection("── KI / VOO ──")

local _, kiUpdate = makeToggleButton("Auto Ki Recharge", "autoKiRecharge", function(on)
    if on then
        startKiRecharge()
        addLog("Auto Ki Recharge ativado")
    else
        addLog("Auto Ki Recharge desativado")
    end
end)

local _, flyUpdate = makeToggleButton("Auto Fly (Agilidade)", "autoFly", function(on)
    if on then
        startFly()
        addLog("Voo ativado")
    else
        stopFly()
        addLog("Voo desativado")
    end
end)

local _, fastFlyUpdate = makeToggleButton("Fly Rápido (Fast Mode)", "fastFly", function(on)
    addLog("Fly rápido: " .. (on and "ON" or "OFF"))
    if state.autoFly then
        stopFly()
        startFly()
    end
end)

makeSection("── ZENKAI ──")

local _, zenkaiUpdate = makeToggleButton("Auto Zenkai", "autoZenkai", function(on)
    if on then
        startAutoZenkai()
        addLog("Auto Zenkai ativado")
    else
        addLog("Auto Zenkai desativado")
    end
end)

makeSection("── AÇÕES ──")

makeActionButton("📍 Criar Baseplate + Teleportar", function()
    teleportToBaseplate()
end)

makeActionButton("🔄 Recarregar Ki (Manual)", function()
    tryRechargeKi()
    addLog("Ki recarregado manualmente")
end)

makeActionButton("🚁 Teleportar para Spawn", function()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(0, 10, 0)
        addLog("Teleportado para spawn")
    end
end)

makeSection("── LOGS ──")

local copyLogsBtn = makeActionButton("📋 Copiar Logs", function()
    local text = table.concat(state.logs, "\n")
    setclipboard(text)
    addLog("Logs copiados para área de transferência!")
end)

local logsFrame = Instance.new("ScrollingFrame")
logsFrame.Size = UDim2.new(1, 0, 0, 150)
logsFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 15)
logsFrame.BorderSizePixel = 0
logsFrame.ScrollBarThickness = 3
logsFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 180)
logsFrame.Parent = scrollFrame

local logsCorner = Instance.new("UICorner")
logsCorner.CornerRadius = UDim.new(0, 6)
logsCorner.Parent = logsFrame

local logsLabel = Instance.new("TextLabel")
logsLabel.Size = UDim2.new(1, -8, 0, 100)
logsLabel.Position = UDim2.new(0, 4, 0, 4)
logsLabel.BackgroundTransparency = 1
logsLabel.Text = "Aguardando ações..."
logsLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
logsLabel.TextSize = 11
logsLabel.Font = Enum.Font.Code
logsLabel.TextXAlignment = Enum.TextXAlignment.Left
logsLabel.TextYAlignment = Enum.TextYAlignment.Top
logsLabel.TextWrapped = true
logsLabel.Parent = logsFrame

-- ===== OPEN/CLOSE =====
closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    state.guiOpen = false
end)

toggleBtn.MouseButton1Click:Connect(function()
    state.guiOpen = not state.guiOpen
    mainFrame.Visible = state.guiOpen
    toggleBtn.Text = state.guiOpen and "⚡ DBRage" or "⚡ Abrir"
end)

-- ===== UPDATE LOOP =====
local uiUpdateTimer = 0
RunService.Heartbeat:Connect(function(dt)
    uiUpdateTimer = uiUpdateTimer + dt
    if uiUpdateTimer < 0.25 then return end
    uiUpdateTimer = 0

    -- Atualiza logs
    if #state.logs > 0 then
        local lines = {}
        for i = 1, math.min(30, #state.logs) do
            lines[i] = state.logs[i]
        end
        local text = table.concat(lines, "\n")
        logsLabel.Text = text
        local textH = logsLabel.TextBounds.Y + 8
        logsLabel.Size = UDim2.new(1, -8, 0, math.max(100, textH))
        logsFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(150, textH + 8))
    end

    -- Atualiza status do farm
    if state.autoFarm and state.farmStartTime then
        local elapsed = tick() - state.farmStartTime
        local mins = math.floor(elapsed / 60)
        local secs = math.floor(elapsed % 60)
        local statName = STAT_ORDER[currentStatIdx]
        local val = getStatValue(statName)
        local maxVal = getMaxStatValue(statName)
        farmStatusLabel.Text = string.format(
            "🌱 Auto Farm: ON  ⏱ %02d:%02d\nStat: %s  [%s / %s]",
            mins, secs,
            statName,
            tostring(math.floor(val)),
            tostring(math.floor(maxVal))
        )
        statLabel.Text = "Stat: " .. statName
    end

    -- Atualiza canvas size do scroll
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 16)
end)

-- ===== INPUT HANDLER =====
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    -- F2 = toggle GUI
    if input.KeyCode == Enum.KeyCode.F2 then
        state.guiOpen = not state.guiOpen
        mainFrame.Visible = state.guiOpen
    end
    -- F3 = toggle Auto Farm
    if input.KeyCode == Enum.KeyCode.F3 then
        state.autoFarm = not state.autoFarm
        farmBtn.MouseButton1Click:Fire()
    end
    -- F4 = toggle Fly
    if input.KeyCode == Enum.KeyCode.F4 then
        state.autoFly = not state.autoFly
        if state.autoFly then startFly() else stopFly() end
        addLog("Voo (F4): " .. (state.autoFly and "ON" or "OFF"))
    end
    -- F5 = fast fly toggle
    if input.KeyCode == Enum.KeyCode.F5 then
        state.fastFly = not state.fastFly
        fastFlyUpdate()
        addLog("Fly rápido (F5): " .. (state.fastFly and "ON" or "OFF"))
        if state.autoFly then
            stopFly()
            startFly()
        end
    end
end)

-- ===== RESPAWN HANDLER =====
lp.CharacterAdded:Connect(function(char)
    task.wait(1)
    if state.autoFly then
        startFly()
    end
    if state.autoFarm then
        startAutoFarm()
    end
    if state.autoKiRecharge then
        startKiRecharge()
    end
    addLog("Personagem respawnado - módulos reiniciados")
end)

-- ===== INIT LOG =====
addLog("Script carregado! Dragon Ball Rage Admin")
addLog("Teclas: F2=GUI | F3=AutoFarm | F4=Fly | F5=FlyRápido")
addLog("Baseplate será criada ao ativar Auto Farm")

print("[DBRage Admin] Script carregado com sucesso!")
