-- BaseCompleta.lua
-- LocalScript > StarterPlayerScripts

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart")

-- ============================================================
--  CONFIGURAÇÕES
-- ============================================================
local BASE_POS     = Vector3.new(9999, 0, 9999)   -- centro da base no chão
local BASE_W       = 70    -- largura total da base (eixo X)
local BASE_D       = 70    -- profundidade total (eixo Z)
local BASE_H       = 22    -- altura total das paredes
local CHECK_RATE   = 0.5   -- segundos entre cada checagem de hitbox

-- Hitbox AABB calculada automaticamente a partir das dimensões da base
-- Ponto mais baixo: BASE_POS.Y (nível do chão)
-- Ponto mais alto : BASE_POS.Y + BASE_H + 4 (margem extra no topo)
local HBOX = {
    minX = BASE_POS.X - BASE_W / 2 - 2,
    maxX = BASE_POS.X + BASE_W / 2 + 2,
    minY = BASE_POS.Y - 2,
    maxY = BASE_POS.Y + BASE_H + 4,
    minZ = BASE_POS.Z - BASE_D / 2 - 2,
    maxZ = BASE_POS.Z + BASE_D / 2 + 2,
}
local SPAWN_ABOVE  = BASE_POS + Vector3.new(0, BASE_H + 6, 0)

-- ============================================================
--  UTILITÁRIOS
-- ============================================================
local function P(size, pos, color, mat, name, parent)
    local p = Instance.new("Part")
    p.Name     = name or "P"
    p.Size     = size
    p.CFrame   = CFrame.new(pos)
    p.BrickColor = BrickColor.new(color)
    p.Material = mat or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.Parent   = parent
    return p
end

-- ============================================================
--  CONSTRUÇÃO DA BASE (maior)
-- ============================================================
local function buildBase()
    local folder = Instance.new("Folder")
    folder.Name  = "MinhaBase"
    folder.Parent = workspace

    local bx, by, bz = BASE_POS.X, BASE_POS.Y, BASE_POS.Z
    local W, D, H = BASE_W, BASE_D, BASE_H

    -- Chão externo / fundação
    P(Vector3.new(W+6, 3, D+6), Vector3.new(bx, by+1.5,  bz), "Dark stone grey", Enum.Material.SmoothPlastic, "Fundacao", folder)
    -- Chão interno
    P(Vector3.new(W-4, 1, D-4), Vector3.new(bx, by+3.5,  bz), "Reddish brown",   Enum.Material.WoodPlanks,    "PisoInterno", folder)

    local wallMat = Enum.Material.SmoothPlastic
    local wallCol = "Medium stone grey"

    -- Paredes (frente, fundo, esq, dir)
    -- Frente: dividida em 3 para ter porta no meio (14 studs de largura)
    local doorW = 14
    local sideW = (W - doorW) / 2
    P(Vector3.new(sideW, H, 3), Vector3.new(bx - (doorW/2 + sideW/2), by + H/2 + 3, bz - D/2), wallCol, wallMat, "FrenteL",  folder)
    P(Vector3.new(sideW, H, 3), Vector3.new(bx + (doorW/2 + sideW/2), by + H/2 + 3, bz - D/2), wallCol, wallMat, "FrenteR",  folder)
    P(Vector3.new(doorW, 5, 3), Vector3.new(bx,                        by + H - 2.5 + 3, bz - D/2), wallCol, wallMat, "Verga",    folder)
    -- Fundo
    P(Vector3.new(W, H, 3), Vector3.new(bx, by + H/2 + 3, bz + D/2), wallCol, wallMat, "Fundo",    folder)
    -- Laterais
    P(Vector3.new(3, H, D), Vector3.new(bx - W/2, by + H/2 + 3, bz), wallCol, wallMat, "Esq",      folder)
    P(Vector3.new(3, H, D), Vector3.new(bx + W/2, by + H/2 + 3, bz), wallCol, wallMat, "Dir",      folder)

    -- Teto
    P(Vector3.new(W+3, 3, D+3), Vector3.new(bx, by + H + 3 + 1.5, bz), "Dark stone grey", Enum.Material.SmoothPlastic, "Teto", folder)

    -- Chaminé decorativa
    P(Vector3.new(5, 8, 5), Vector3.new(bx - W/2 + 8, by + H + 3 + 6, bz + D/2 - 8), "Dark stone grey", Enum.Material.Brick, "Chamine", folder)

    -- Janelas (2 de cada lado)
    local winMat = Enum.Material.Glass
    for _, side in ipairs({-1, 1}) do
        for _, zoff in ipairs({-15, 15}) do
            P(Vector3.new(2, 8, 10), Vector3.new(bx + side*(W/2), by + 10 + 3, bz + zoff), "Bright blue", winMat, "Janela", folder)
        end
    end

    -- ---- MÓVEIS ----
    -- Cama grande
    P(Vector3.new(14, 3, 20), Vector3.new(bx - 22, by + 5,   bz + 22), "Bright red",   Enum.Material.SmoothPlastic, "Cama",        folder)
    P(Vector3.new(14, 5, 3),  Vector3.new(bx - 22, by + 6.5, bz + 30), "Dark red",     Enum.Material.SmoothPlastic, "Cabeceira",   folder)
    P(Vector3.new(10, 2, 14), Vector3.new(bx - 22, by + 6.5, bz + 21), "White",        Enum.Material.SmoothPlastic, "Travesseiro", folder)

    -- Mesa grande com cadeira
    P(Vector3.new(18, 1.5, 10), Vector3.new(bx + 22, by + 8,   bz + 22), "Reddish brown", Enum.Material.WoodPlanks, "MesaTampo", folder)
    for _, ox in ipairs({-7, 7}) do
        for _, oz in ipairs({-4, 4}) do
            P(Vector3.new(1.5, 7, 1.5), Vector3.new(bx+22+ox, by+4.5, bz+22+oz), "Brown", Enum.Material.WoodPlanks, "MesaPe", folder)
        end
    end
    -- Cadeira
    P(Vector3.new(7, 1,   7),  Vector3.new(bx + 22, by + 5.5, bz + 10), "Reddish brown", Enum.Material.WoodPlanks, "Cadeira_Assento", folder)
    P(Vector3.new(7, 6,   1),  Vector3.new(bx + 22, by + 9,   bz + 7),  "Reddish brown", Enum.Material.WoodPlanks, "Cadeira_Encosto", folder)
    for _, ox in ipairs({-3, 3}) do
        for _, oz in ipairs({-3, 3}) do
            P(Vector3.new(1, 5, 1), Vector3.new(bx+22+ox, by+3, bz+10+oz), "Brown", Enum.Material.WoodPlanks, "Cadeira_Pe", folder)
        end
    end

    -- Estante (parede do fundo)
    for shelf = 0, 2 do
        P(Vector3.new(20, 1, 5), Vector3.new(bx - 20, by + 5 + shelf*6, bz + D/2 - 5), "Brown", Enum.Material.WoodPlanks, "Prateleira"..shelf, folder)
    end

    -- Baús (2)
    P(Vector3.new(8, 5, 6), Vector3.new(bx + 22, by + 5.5, bz - 20), "Dark orange", Enum.Material.SmoothPlastic, "Bau1", folder)
    P(Vector3.new(8, 5, 6), Vector3.new(bx + 22, by + 5.5, bz - 30), "Dark orange", Enum.Material.SmoothPlastic, "Bau2", folder)

    -- Tapete central
    P(Vector3.new(20, 0.3, 20), Vector3.new(bx, by + 3.6, bz), "Bright red", Enum.Material.SmoothPlastic, "Tapete", folder)

    -- Tocha / luz de cada canto interno
    for _, ox in ipairs({-W/2+6, W/2-6}) do
        for _, oz in ipairs({-D/2+6, D/2-6}) do
            local torch = P(Vector3.new(1.5, 5, 1.5), Vector3.new(bx+ox, by+14, bz+oz), "Neon orange", Enum.Material.Neon, "Tocha", folder)
        end
    end

    print("[BaseCompleta] Base construída com sucesso!")
    return folder
end

-- ============================================================
--  TELEPORTE
-- ============================================================
local function teleport()
    character = player.Character
    if not character then return end
    rootPart  = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    rootPart.CFrame = CFrame.new(SPAWN_ABOVE)
    print("[BaseCompleta] Teleportado para a base!")
end

-- ============================================================
--  HITBOX AABB (caixa exata da construção)
-- ============================================================
local function inHitbox()
    character = player.Character
    if not character then return true end
    rootPart  = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return true end
    local p = rootPart.Position
    return  p.X >= HBOX.minX and p.X <= HBOX.maxX and
            p.Y >= HBOX.minY and p.Y <= HBOX.maxY and
            p.Z >= HBOX.minZ and p.Z <= HBOX.maxZ
end

-- ============================================================
--  GUI — MINIJOGOS
-- ============================================================
local function createGui()
    local sg = Instance.new("ScreenGui")
    sg.Name            = "BaseGui"
    sg.ResetOnSpawn    = false
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.Parent          = playerGui

    -- Botão flutuante para abrir/fechar
    local btn = Instance.new("TextButton")
    btn.Name            = "AbrirBtn"
    btn.Size            = UDim2.new(0, 140, 0, 44)
    btn.Position        = UDim2.new(1, -156, 0, 12)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.TextColor3      = Color3.fromRGB(255, 220, 80)
    btn.Font            = Enum.Font.GothamBold
    btn.TextSize        = 15
    btn.Text            = "🎮  Minijogos"
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    btn.Parent          = sg

    -- Painel principal
    local panel = Instance.new("Frame")
    panel.Name             = "Painel"
    panel.Size             = UDim2.new(0, 500, 0, 560)
    panel.Position         = UDim2.new(0.5, -250, 0.5, -280)
    panel.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    panel.BorderSizePixel  = 0
    panel.Visible          = false
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
    panel.Parent           = sg

    -- Título do painel
    local title = Instance.new("TextLabel")
    title.Size             = UDim2.new(1, -50, 0, 44)
    title.Position         = UDim2.new(0, 16, 0, 8)
    title.BackgroundTransparency = 1
    title.TextColor3       = Color3.fromRGB(255, 220, 80)
    title.Font             = Enum.Font.GothamBold
    title.TextSize         = 20
    title.TextXAlignment   = Enum.TextXAlignment.Left
    title.Text             = "🎮  Minijogos da Base"
    title.Parent           = panel

    -- Botão fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size             = UDim2.new(0, 36, 0, 36)
    closeBtn.Position         = UDim2.new(1, -44, 0, 8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeBtn.TextColor3       = Color3.fromRGB(255,255,255)
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.TextSize         = 18
    closeBtn.Text             = "✕"
    closeBtn.BorderSizePixel  = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    closeBtn.Parent           = panel

    -- Container dos jogos (scroll)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                  = UDim2.new(1, -20, 1, -60)
    scroll.Position              = UDim2.new(0, 10, 0, 54)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel       = 0
    scroll.ScrollBarThickness    = 4
    scroll.CanvasSize            = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    scroll.Parent                = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding   = UDim.new(0, 10)
    layout.Parent    = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingTop   = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent       = scroll

    -- ---- helpers de UI ----
    local function makeCard(color)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(1, -8, 0, 130)
        f.BackgroundColor3 = color or Color3.fromRGB(30, 30, 46)
        f.BorderSizePixel  = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
        f.Parent = scroll
        return f
    end

    local function makeLabel(parent, text, size, color, bold, pos, sz)
        local l = Instance.new("TextLabel")
        l.Size             = sz  or UDim2.new(1, -12, 0, 24)
        l.Position         = pos or UDim2.new(0, 8, 0, 4)
        l.BackgroundTransparency = 1
        l.TextColor3       = color or Color3.fromRGB(220,220,240)
        l.Font             = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextSize         = size or 14
        l.TextXAlignment   = Enum.TextXAlignment.Left
        l.TextWrapped      = true
        l.Text             = text
        l.Parent           = parent
        return l
    end

    local function makeButton(parent, text, pos, sz, bgColor)
        local b = Instance.new("TextButton")
        b.Size             = sz  or UDim2.new(0, 110, 0, 32)
        b.Position         = pos or UDim2.new(0, 8, 1, -40)
        b.BackgroundColor3 = bgColor or Color3.fromRGB(255, 200, 40)
        b.TextColor3       = Color3.fromRGB(20, 20, 20)
        b.Font             = Enum.Font.GothamBold
        b.TextSize         = 14
        b.BorderSizePixel  = 0
        b.Text             = text
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        b.Parent           = parent
        return b
    end

    -- ==========================================
    --  JOGO 1 — CLICKER
    -- ==========================================
    do
        local card = makeCard(Color3.fromRGB(28, 34, 52))
        card.Size = UDim2.new(1, -8, 0, 140)
        makeLabel(card, "⚡ Clicker Maluco", 16, Color3.fromRGB(100,180,255), true)
        local scoreLbl = makeLabel(card, "Cliques: 0", 13, Color3.fromRGB(180,220,255), false,
            UDim2.new(0, 8, 0, 28), UDim2.new(0.5, -4, 0, 24))
        local bestLbl  = makeLabel(card, "Recorde: 0 em 10s", 12, Color3.fromRGB(130,160,200), false,
            UDim2.new(0, 8, 0, 52), UDim2.new(1,-16, 0, 20))
        local timerLbl = makeLabel(card, "", 13, Color3.fromRGB(255,180,60), true,
            UDim2.new(0.5, 0, 0, 28), UDim2.new(0.5, -4, 0, 24))
        timerLbl.TextXAlignment = Enum.TextXAlignment.Right

        local clickBtn = makeButton(card, "CLICA AQUI!", UDim2.new(0.5,-60,1,-44), UDim2.new(120,0,0,36), Color3.fromRGB(40,160,255))
        clickBtn.TextColor3 = Color3.fromRGB(255,255,255)

        local clicks, best, running = 0, 0, false

        clickBtn.MouseButton1Click:Connect(function()
            if not running then
                running = true
                clicks  = 0
                local t = 10
                task.spawn(function()
                    while t > 0 do
                        task.wait(1)
                        t -= 1
                        timerLbl.Text = t > 0 and (t.."s") or ""
                    end
                    running = false
                    if clicks > best then best = clicks end
                    bestLbl.Text = "Recorde: "..best.." em 10s"
                    clickBtn.Text = "CLICA AQUI!"
                end)
            end
            if running then
                clicks += 1
                scoreLbl.Text = "Cliques: "..clicks
                clickBtn.Text = "+"..clicks.." 💥"
            end
        end)
    end

    -- ==========================================
    --  JOGO 2 — ADIVINHE O NÚMERO
    -- ==========================================
    do
        local card = makeCard(Color3.fromRGB(34, 28, 50))
        card.Size = UDim2.new(1,-8,0,160)
        makeLabel(card, "🔢 Adivinhe o Número (1-100)", 16, Color3.fromRGB(200,140,255), true)

        local hint = makeLabel(card, "Pensei num número! Tente descobrir.", 12, Color3.fromRGB(180,160,220), false,
            UDim2.new(0,8,0,30), UDim2.new(1,-16,0,18))
        local tentLbl = makeLabel(card, "Tentativas: 0", 12, Color3.fromRGB(150,130,200), false,
            UDim2.new(0,8,0,50), UDim2.new(1,-16,0,18))

        local box = Instance.new("TextBox")
        box.Size             = UDim2.new(0,90,0,32)
        box.Position         = UDim2.new(0,8,1,-44)
        box.BackgroundColor3 = Color3.fromRGB(46,38,70)
        box.TextColor3       = Color3.fromRGB(255,255,255)
        box.Font             = Enum.Font.GothamBold
        box.TextSize         = 16
        box.PlaceholderText  = "Número..."
        box.ClearTextOnFocus = true
        box.BorderSizePixel  = 0
        Instance.new("UICorner", box).CornerRadius = UDim.new(0,8)
        box.Parent = card

        local guessBtn = makeButton(card, "Tentar", UDim2.new(0,106,1,-44), UDim2.new(0,80,0,32), Color3.fromRGB(160,80,255))
        guessBtn.TextColor3 = Color3.fromRGB(255,255,255)

        local secret    = math.random(1,100)
        local tentativas = 0

        guessBtn.MouseButton1Click:Connect(function()
            local n = tonumber(box.Text)
            if not n then hint.Text = "Digite um número válido!" return end
            tentativas += 1
            tentLbl.Text = "Tentativas: "..tentativas
            if n == secret then
                hint.Text  = "🎉 Acertou em "..tentativas.." tentativa(s)!"
                secret     = math.random(1,100)
                tentativas = 0
                tentLbl.Text = "Tentativas: 0"
            elseif n < secret then
                hint.Text = "⬆ Muito baixo!"
            else
                hint.Text = "⬇ Muito alto!"
            end
            box.Text = ""
        end)
    end

    -- ==========================================
    --  JOGO 3 — PEDRA PAPEL TESOURA
    -- ==========================================
    do
        local card = makeCard(Color3.fromRGB(28, 44, 36))
        card.Size = UDim2.new(1,-8,0,160)
        makeLabel(card, "✊ Pedra Papel Tesoura", 16, Color3.fromRGB(100,220,140), true)

        local resultLbl = makeLabel(card, "Escolha uma opção!", 13, Color3.fromRGB(180,240,200), false,
            UDim2.new(0,8,0,30), UDim2.new(1,-16,0,18))
        local scoreLbl  = makeLabel(card, "Você: 0  |  PC: 0", 12, Color3.fromRGB(130,200,160), false,
            UDim2.new(0,8,0,50), UDim2.new(1,-16,0,18))

        local choices = {"✊","✋","✌"}
        local names   = {["✊"]="Pedra", ["✋"]="Papel", ["✌"]="Tesoura"}
        local beats   = {["✊"]="✌", ["✋"]="✊", ["✌"]="✋"}
        local pScore, cScore = 0, 0

        for i, ch in ipairs(choices) do
            local b = makeButton(card, ch,
                UDim2.new(0, 8 + (i-1)*106, 1, -44),
                UDim2.new(0,98,0,36),
                Color3.fromRGB(40, 120, 70))
            b.TextColor3 = Color3.fromRGB(255,255,255)
            b.TextSize   = 20
            b.MouseButton1Click:Connect(function()
                local cpu = choices[math.random(1,3)]
                if ch == cpu then
                    resultLbl.Text = "Empate! "..names[ch].." vs "..names[cpu]
                elseif beats[ch] == cpu then
                    pScore += 1
                    resultLbl.Text = "✅ Você venceu! "..names[ch].." > "..names[cpu]
                else
                    cScore += 1
                    resultLbl.Text = "❌ PC venceu! "..names[cpu].." > "..names[ch]
                end
                scoreLbl.Text = "Você: "..pScore.."  |  PC: "..cScore
            end)
        end
    end

    -- ==========================================
    --  JOGO 4 — SEQUÊNCIA DE MEMÓRIA
    -- ==========================================
    do
        local card = makeCard(Color3.fromRGB(50, 30, 30))
        card.Size = UDim2.new(1,-8,0,160)
        makeLabel(card, "🧠 Memória — Repita a Sequência", 16, Color3.fromRGB(255,150,100), true)

        local infoLbl = makeLabel(card, "Pressione Iniciar para começar", 12, Color3.fromRGB(230,180,160), false,
            UDim2.new(0,8,0,30), UDim2.new(1,-16,0,18))
        local seqLbl  = makeLabel(card, "", 13, Color3.fromRGB(255,200,150), true,
            UDim2.new(0,8,0,50), UDim2.new(1,-16,0,20))
        seqLbl.TextXAlignment = Enum.TextXAlignment.Center

        local startBtn = makeButton(card, "Iniciar", UDim2.new(0,8,1,-44), UDim2.new(0,100,0,36), Color3.fromRGB(200,80,50))
        startBtn.TextColor3 = Color3.fromRGB(255,255,255)

        local inputBox = Instance.new("TextBox")
        inputBox.Size             = UDim2.new(0,130,0,32)
        inputBox.Position         = UDim2.new(0,116,1,-44)
        inputBox.BackgroundColor3 = Color3.fromRGB(60,36,36)
        inputBox.TextColor3       = Color3.fromRGB(255,255,255)
        inputBox.Font             = Enum.Font.GothamBold
        inputBox.TextSize         = 14
        inputBox.PlaceholderText  = "Ex: 3 1 4 2 ..."
        inputBox.ClearTextOnFocus = true
        inputBox.BorderSizePixel  = 0
        Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0,8)
        inputBox.Parent = card

        local confirmBtn = makeButton(card, "OK", UDim2.new(0,254,1,-44), UDim2.new(0,50,0,32), Color3.fromRGB(255,180,60))
        confirmBtn.TextColor3 = Color3.fromRGB(20,20,20)

        local seq, level = {}, 0

        startBtn.MouseButton1Click:Connect(function()
            seq   = {}
            level = 1
            table.insert(seq, math.random(1,4))
            local display = table.concat(seq, "  ")
            seqLbl.Text  = display
            infoLbl.Text = "Memorize! Vai sumir em 3s..."
            task.delay(3, function()
                seqLbl.Text  = "?"
                infoLbl.Text = "Digite os números separados por espaço"
            end)
        end)

        confirmBtn.MouseButton1Click:Connect(function()
            if #seq == 0 then return end
            local parts = {}
            for v in inputBox.Text:gmatch("%S+") do
                table.insert(parts, tonumber(v))
            end
            local ok = #parts == #seq
            if ok then
                for i = 1, #seq do
                    if parts[i] ~= seq[i] then ok = false break end
                end
            end
            if ok then
                level += 1
                table.insert(seq, math.random(1,4))
                local display = table.concat(seq, "  ")
                seqLbl.Text  = display
                infoLbl.Text = "✅ Correto! Nível "..level..". Memorize!"
                task.delay(3 + level*0.3, function()
                    seqLbl.Text  = "?"
                    infoLbl.Text = "Digite os números separados por espaço"
                end)
            else
                infoLbl.Text = "❌ Errou! Recorde: nível "..(level-1)..". Reinicie."
                seq = {}
            end
            inputBox.Text = ""
        end)
    end

    -- ==========================================
    --  JOGO 5 — MATEMÁTICA RÁPIDA
    -- ==========================================
    do
        local card = makeCard(Color3.fromRGB(28, 40, 50))
        card.Size = UDim2.new(1,-8,0,150)
        makeLabel(card, "➕ Matemática Rápida", 16, Color3.fromRGB(80,200,255), true)

        local questionLbl = makeLabel(card, "Pressione Novo para começar", 14, Color3.fromRGB(160,220,255), false,
            UDim2.new(0,8,0,30), UDim2.new(1,-16,0,22))
        questionLbl.TextXAlignment = Enum.TextXAlignment.Center
        local resultLbl = makeLabel(card, "", 12, Color3.fromRGB(120,190,230), false,
            UDim2.new(0,8,0,54), UDim2.new(1,-16,0,18))
        resultLbl.TextXAlignment = Enum.TextXAlignment.Center
        local scoreLbl  = makeLabel(card, "Corretos: 0 | Erros: 0", 12, Color3.fromRGB(100,170,210), false,
            UDim2.new(0,8,0,74), UDim2.new(1,-16,0,18))
        scoreLbl.TextXAlignment = Enum.TextXAlignment.Center

        local ansBox = Instance.new("TextBox")
        ansBox.Size             = UDim2.new(0,100,0,32)
        ansBox.Position         = UDim2.new(0,8,1,-42)
        ansBox.BackgroundColor3 = Color3.fromRGB(36,52,66)
        ansBox.TextColor3       = Color3.fromRGB(255,255,255)
        ansBox.Font             = Enum.Font.GothamBold
        ansBox.TextSize         = 16
        ansBox.PlaceholderText  = "Resposta"
        ansBox.ClearTextOnFocus = true
        ansBox.BorderSizePixel  = 0
        Instance.new("UICorner", ansBox).CornerRadius = UDim.new(0,8)
        ansBox.Parent = card

        local novoBtn = makeButton(card, "Novo", UDim2.new(0,116,1,-42), UDim2.new(0,72,0,32), Color3.fromRGB(40,160,220))
        novoBtn.TextColor3 = Color3.fromRGB(255,255,255)
        local okBtn   = makeButton(card, "Responder", UDim2.new(0,196,1,-42), UDim2.new(0,110,0,32), Color3.fromRGB(40,200,130))
        okBtn.TextColor3   = Color3.fromRGB(255,255,255)

        local ops = {"+","-","*"}
        local correct_ans, corretos, erros = nil, 0, 0

        local function newQuestion()
            local a  = math.random(1,20)
            local b  = math.random(1,20)
            local op = ops[math.random(1,3)]
            if op == "+" then correct_ans = a + b
            elseif op == "-" then correct_ans = a - b
            else correct_ans = a * b end
            questionLbl.Text = a .. " " .. op .. " " .. b .. " = ?"
            resultLbl.Text   = ""
        end

        novoBtn.MouseButton1Click:Connect(newQuestion)

        okBtn.MouseButton1Click:Connect(function()
            if not correct_ans then return end
            local n = tonumber(ansBox.Text)
            if n == correct_ans then
                corretos += 1
                resultLbl.Text = "✅ Certo!"
            else
                erros += 1
                resultLbl.Text = "❌ Era "..correct_ans
            end
            scoreLbl.Text  = "Corretos: "..corretos.." | Erros: "..erros
            ansBox.Text    = ""
            task.delay(0.8, newQuestion)
        end)
    end

    -- ---- toggle abrir/fechar ----
    btn.MouseButton1Click:Connect(function()
        panel.Visible = not panel.Visible
    end)
    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
    end)
end

-- ============================================================
--  INICIALIZAÇÃO
-- ============================================================
player.CharacterAdded:Connect(function(char)
    character = char
    rootPart  = char:WaitForChild("HumanoidRootPart")
end)

if not workspace:FindFirstChild("MinhaBase") then
    buildBase()
end

task.wait(2)
teleport()
createGui()

-- Loop da hitbox
task.spawn(function()
    while true do
        task.wait(CHECK_RATE)
        if not inHitbox() then
            print("[BaseCompleta] Fora da hitbox! Retornando...")
            teleport()
        end
    end
end)
