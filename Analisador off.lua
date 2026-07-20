--[[
  🔍 HACKERAI ANALYZER v9.2 — CORRIGIDO (sem propriedades invalidas)
  • Mesma interface da v7.0 que FUNCIONOU
  • Todas as propriedades com pcall pra nunca travar
  • 400x450 - mais quadrado
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local Chat = game:GetService("Chat")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ====== FUNCAO SEGURA ======
local function safeGet(obj, prop)
    local ok, val = pcall(function() return obj[prop] end)
    if ok then return tostring(val) end
    return "N/A"
end

local function truncate(s, maxLen)
    maxLen = maxLen or 100
    if type(s) ~= "string" then s = tostring(s) end
    if #s > maxLen then return s:sub(1, maxLen) .. "..." end
    return s
end

-- ====== COLETA TODOS OS DADOS ======
print("🔍 Coletando dados...")
local reportLines = {}

local function add(txt)
    table.insert(reportLines, txt)
end

local function sep()
    add("────────────────────────────────────────────────────")
end

-- CABECALHO
add("╔═══════════════════════════════════════════════════╗")
add("║   🔍 HACKERAI DEEP ANALYSIS v9.2                ║")
add("╠═══════════════════════════════════════════════════╣")
add("║  Modo: READ-ONLY | 0 remotes executados         ║")
add("║  Jogador: " .. string.format("%-42s", LocalPlayer.Name) .. "║")
add("║  Place ID: " .. string.format("%-40d", game.PlaceId) .. "║")
add("╚═══════════════════════════════════════════════════╝")
add("")

-- ===== 1. INFO DO JOGO =====
add("▓▓▓ 1. INFORMACOES DO JOGO ▓▓▓")
add("")
add("  Nome:              " .. game.Name)
add("  Place ID:          " .. game.PlaceId)
add("  Game ID:           " .. game.GameId)
add("  Creator ID:        " .. game.CreatorId)
add("  Creator Type:      " .. safeGet(game, "CreatorType"))
add("  Place Version:     " .. safeGet(game, "PlaceVersion"))
add("  Jogadores:         " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
add("  Gravidade:         " .. tostring(game.Workspace.Gravity))
add("  StreamingEnabled:  " .. tostring(game.Workspace.StreamingEnabled))
add("  FilteringEnabled:  " .. tostring(game.Workspace.FilteringEnabled))
add("  Lighting Tech:     " .. tostring(Lighting.Technology))
add("  Lighting Clock:    " .. tostring(Lighting.ClockTime))
add("  HttpService:       " .. tostring(game:GetService("HttpService").HttpEnabled))
add("  Chat Enabled:      " .. tostring(Chat:IsChatEnabled()))
add("")

-- ProductInfo
add("  --- INFORMACOES DA LOJA ---")
local pcallOk, productInfo = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)
if pcallOk and productInfo and type(productInfo) == "table" then
    add("  Nome:            " .. (productInfo.Name or "N/A"))
    add("  Descricao:       " .. truncate(productInfo.Description or "N/A", 90))
    add("  Preco:           " .. tostring(productInfo.PriceInRobux or 0) .. " Robux")
    add("  A venda:         " .. tostring(productInfo.IsForSale or false))
    add("  Criado em:       " .. (productInfo.Created or "N/A"))
    add("  Atualizado em:   " .. (productInfo.Updated or "N/A"))
    add("  Genero:          " .. (productInfo.Genre or "N/A"))
else
    add("  (Nao foi possivel obter info da loja)")
end
add("")

-- ===== 2. JOGADORES =====
add("▓▓▓ 2. JOGADORES ONLINE ▓▓▓")
add("")
for _, plr in ipairs(Players:GetPlayers()) do
    local team = (plr.Team and plr.Team.Name) or "Sem time"
    local hp = "N/A"
    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
        local hum = plr.Character.Humanoid
        hp = string.format("%.0f/%.0f", hum.Health, hum.MaxHealth)
    end
    local membro = safeGet(plr, "MembershipType")
    if membro:find("Premium") then membro = "PREMIUM" end
    
    add("  " .. plr.Name .. " [" .. plr.DisplayName .. "]")
    add("     ID: " .. plr.UserId .. " | " .. team .. " | HP: " .. hp .. " | " .. plr.AccountAge .. "d")
    add("     " .. membro)
    
    if plr:FindFirstChild("leaderstats") then
        local stats = {}
        for _, stat in ipairs(plr.leaderstats:GetChildren()) do
            table.insert(stats, stat.Name .. "=" .. tostring(stat.Value))
        end
        if #stats > 0 then
            add("     Stats: " .. table.concat(stats, " | "))
        end
    end
end
add("")

-- ===== 3. TIMES =====
add("▓▓▓ 3. TIMES ▓▓▓")
add("")
local times = Teams:GetTeams()
if #times > 0 then
    for _, t in ipairs(times) do
        add("  " .. t.Name .. " (" .. #t:GetPlayers() .. " jogadores)")
    end
else
    add("  Nenhum time configurado.")
end
add("")

-- ===== 4. SCRIPTS =====
add("▓▓▓ 4. SCRIPTS ▓▓▓")
add("")

local allScripts = {}
local totalLines = 0

local function collectScripts(c, d)
    if d > 7 then return end
    for _, o in ipairs(c:GetChildren()) do
        if o:IsA("Script") or o:IsA("LocalScript") or o:IsA("ModuleScript") then
            local lines = o.Source and #o.Source:split("\n") or 0
            table.insert(allScripts, {nome = o.Name, tipo = o.ClassName, linhas = lines, path = o:GetFullName()})
            totalLines = totalLines + lines
        end
        if o:IsA("Folder") or o:IsA("Model") or o:IsA("Configuration") then
            collectScripts(o, d + 1)
        end
    end
end

collectScripts(ReplicatedStorage, 0)
collectScripts(game:GetService("ServerScriptService"), 0)
collectScripts(game:GetService("ServerStorage"), 0)
collectScripts(game:GetService("StarterGui"), 0)
collectScripts(game:GetService("StarterPlayer"), 0)
collectScripts(game:GetService("Workspace"), 0)

add("  Total: " .. #allScripts .. " scripts (~" .. totalLines .. " linhas)")
add("")

local srv, cli, mod = 0, 0, 0
for _, s in ipairs(allScripts) do
    if s.tipo == "Script" then srv = srv + 1
    elseif s.tipo == "LocalScript" then cli = cli + 1
    elseif s.tipo == "ModuleScript" then mod = mod + 1
    end
end
add("  Server Scripts: " .. srv .. " | LocalScripts: " .. cli .. " | Modules: " .. mod)
add("")

-- ===== 5. REMOTES =====
add("▓▓▓ 5. REMOTES ▓▓▓")
add("")

local allRemotes = {}

local function collectRemotes(c, d)
    if d > 10 then return end
    for _, o in ipairs(c:GetChildren()) do
        if o:IsA("RemoteEvent") then
            table.insert(allRemotes, {nome = o.Name, tipo = "EVENT", metodo = ":FireServer()", path = o:GetFullName()})
        elseif o:IsA("RemoteFunction") then
            table.insert(allRemotes, {nome = o.Name, tipo = "FUNC", metodo = ":InvokeServer()", path = o:GetFullName()})
        elseif o:IsA("UnreliableRemoteEvent") then
            table.insert(allRemotes, {nome = o.Name, tipo = "UNREL", metodo = ":FireServer()", path = o:GetFullName()})
        end
        if o:IsA("Folder") or o:IsA("Configuration") or o:IsA("Model") then
            collectRemotes(o, d + 1)
        end
    end
end

collectRemotes(ReplicatedStorage, 0)
collectRemotes(game:GetService("Workspace"), 0)
collectRemotes(game:GetService("Players"), 0)

add("  Total: " .. #allRemotes .. " remotes")
add("")

local evt, fnc, unr = 0, 0, 0
for _, r in ipairs(allRemotes) do
    if r.tipo == "EVENT" then evt = evt + 1
    elseif r.tipo == "FUNC" then fnc = fnc + 1
    elseif r.tipo == "UNREL" then unr = unr + 1
    end
end
add("  Events: " .. evt .. " | Functions: " .. fnc .. " | Unreliable: " .. unr)
add("")

for i, r in ipairs(allRemotes) do
    add(string.format("  %d. [%s] %s %s", i, r.tipo, r.nome, r.metodo))
    add("     " .. r.path)
    
    local n = r.nome:lower()
    if n:find("buy") or n:find("compra") or n:find("purchase") then
        add("     ⮕ Compra. Args: itemId, qtd, price")
    elseif n:find("sell") or n:find("venda") then
        add("     ⮕ Venda. Args: itemId, qtd, price")
    elseif n:find("trade") or n:find("troca") or n:find("exchange") then
        add("     ⮕ **TRADE/TROCA**. Args: player, itensOferecidos, itensDesejados")
    elseif n:find("claim") or n:find("daily") then
        add("     ⮕ Recompensa diaria")
    elseif n:find("give") or n:find("reward") then
        add("     ⮕ Dar itens. Args: player, item, qtd")
    elseif n:find("kick") or n:find("ban") or n:find("punish") then
        add("     ⮕ ADMIN! Args: player, motivo")
    elseif n:find("admin") or n:find("command") or n:find("cmd") then
        add("     ⮕ ADMIN/COMANDO. Args: comando, args")
    elseif n:find("teleport") or n:find("spawn") or n:find("tp") or n:find("warp") then
        add("     ⮕ Teleporte. Args: destino/posicao")
    elseif n:find("chat") or n:find("say") or n:find("msg") then
        add("     ⮕ Chat. Args: mensagem")
    elseif n:find("damage") or n:find("hit") or n:find("attack") or n:find("dano") then
        add("     ⮕ Dano/ataque. Args: target, valor")
    elseif n:find("shop") or n:find("loja") or n:find("store") then
        add("     ⮕ Loja/shop")
    elseif n:find("inventory") or n:find("inventario") or n:find("backpack") then
        add("     ⮕ Inventario")
    elseif n:find("equip") or n:find("wear") or n:find("vestir") then
        add("     ⮕ Equipar. Args: itemId, slot")
    elseif n:find("upgrade") or n:find("enhance") or n:find("melhorar") then
        add("     ⮕ Upgrade. Args: itemId, level")
    elseif n:find("save") or n:find("load") or n:find("data") then
        add("     ⮕ Save/Load dados")
    elseif n:find("get") or n:find("fetch") or n:find("check") or n:find("request") then
        add("     ⮕ Consulta. Args: tipo, dados")
    elseif n:find("auction") or n:find("leilao") or n:find("market") then
        add("     ⮕ Leilao/mercado")
    elseif n:find("craft") or n:find("fabric") then
        add("     ⮕ Craft/fabricar. Args: recipeId, qtd")
    elseif n:find("pet") or n:find("mount") or n:find("montaria") then
        add("     ⮕ Pet/montaria")
    elseif n:find("party") or n:find("grupo") or n:find("squad") then
        add("     ⮕ Grupo/party")
    elseif n:find("vote") or n:find("votar") or n:find("like") then
        add("     ⮕ Voto/like")
    else
        add("     ⮕ Args desconhecidos")
    end
end
add("")

-- ===== 6. ECONOMIA / TRADES =====
add("▓▓▓ 6. ECONOMIA / TRADES ▓▓▓")
add("")

local ecoKeywords = {"trade","troca","shop","loja","venda","sell","buy","compra","market","coin","money","dinheiro","wallet","bank","banco","inventory","item","currency","moeda","price","preco","daily","claim","reward","crate","caixa","vip","premium","upgrade","rank","level","pet","montaria","guild","clan","auction","leilao","point","ponto","token","fragment","shard","gem","crystal","essence","gold","silver","bronze","cash","robux","ticket"}
local ecoItems = {}

local function scanEco(c, d)
    if d > 5 then return end
    for _, o in ipairs(c:GetChildren()) do
        local name = o.Name:lower()
        for _, kw in ipairs(ecoKeywords) do
            if name:find(kw, 1, true) then
                table.insert(ecoItems, {nome = o.Name, classe = o.ClassName, path = o:GetFullName()})
                break
            end
        end
        if o:IsA("Folder") or o:IsA("ModuleScript") or o:IsA("Configuration") then
            scanEco(o, d + 1)
        end
    end
end

scanEco(ReplicatedStorage, 0)
scanEco(game:GetService("ServerScriptService"), 0)
scanEco(game:GetService("ServerStorage"), 0)

add("  Objetos de economia: " .. #ecoItems)
add("")
if #ecoItems > 0 then
    for i, e in ipairs(ecoItems) do
        add(string.format("  %d. [%s] %s", i, e.classe, e.nome))
        add("     " .. e.path)
    end
    add("")
end

-- Trade detect
local hasTrade = false
for _, r in ipairs(allRemotes) do
    local n = r.nome:lower()
    if n:find("trade") or n:find("troca") or n:find("exchange") then
        hasTrade = true
        add("  🔄 **SISTEMA DE TRADE DETECTADO** no remote: " .. r.nome)
        add("")
        break
    end
end
for _, e in ipairs(ecoItems) do
    local n = e.nome:lower()
    if (n:find("trade") or n:find("troca") or n:find("exchange")) and not hasTrade then
        hasTrade = true
        add("  🔄 **SISTEMA DE TRADE DETECTADO** em: " .. e.nome)
        add("")
        break
    end
end
if not hasTrade then
    add("  Nenhum sistema de trade detectado nos remotes.")
    add("")
end

-- ===== 7. RESUMO =====
add("▓▓▓ 7. RESUMO FINAL ▓▓▓")
add("")
add("  Copie este relatorio e cole na conversa do HackerAI!")
add("")
add("  Total de remotes:     " .. #allRemotes)
add("  Total de scripts:     " .. #allScripts)
add("  Itens de economia:    " .. #ecoItems)
add("  Sistema de trade:     " .. (hasTrade and "SIM" or "NAO DETECTADO"))
add("")

sep()
add("  ✅ ANALISE CONCLUIDA!")
add("  📡 " .. #allRemotes .. " remotes | 📜 " .. #allScripts .. " scripts | 💰 " .. #ecoItems .. " eco")
add("  🔒 Modo READ-ONLY — 0 remotes executados")
sep()

local fullText = table.concat(reportLines, "\n")

-- ====== INTERFACE (MESMA DA V7.0 QUE FUNCIONOU) ======
print("🖥️  Criando interface...")

local clipboardOk = false
for _, func in ipairs({"setclipboard", "toclipboard", "set_clipboard"}) do
    local ok = pcall(function() _G[func](fullText) end)
    if ok then clipboardOk = true; break end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HackerAI_Analyzer"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Background = Instance.new("Frame")
Background.Name = "Background"
Background.Size = UDim2.new(1, 0, 1, 0)
Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Background.BackgroundTransparency = 0.5
Background.Parent = ScreenGui
Background.Active = true

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 400, 0, 450)
Main.Position = UDim2.new(0.5, -200, 0.5, -225)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Main

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 170, 255)
UIStroke.Thickness = 1.5
UIStroke.Parent = Main

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 50)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleMask = Instance.new("Frame")
TitleMask.Size = UDim2.new(1, 0, 0, 10)
TitleMask.Position = UDim2.new(0, 0, 0.7, 0)
TitleMask.BackgroundColor3 = Color3.fromRGB(20, 20, 50)
TitleMask.BorderSizePixel = 0
TitleMask.Parent = TitleBar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 30, 1, 0)
TitleIcon.Position = UDim2.new(0, 8, 0, 0)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "🔍"
TitleIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleIcon.TextScaled = true
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -80, 1, 0)
TitleText.Position = UDim2.new(0, 42, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "HackerAI v9.2"
TitleText.TextColor3 = Color3.fromRGB(0, 170, 255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.TextScaled = true
TitleText.Font = Enum.Font.GothamBold
TitleText.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextScaled = true
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
TitleBar.InputEnded:Connect(function()
    dragging = false
end)

local InfoBar = Instance.new("Frame")
InfoBar.Size = UDim2.new(1, -16, 0, 22)
InfoBar.Position = UDim2.new(0, 8, 0, 42)
InfoBar.BackgroundColor3 = Color3.fromRGB(15, 15, 40)
InfoBar.BorderSizePixel = 0
InfoBar.Parent = Main

local InfoBarCorner = Instance.new("UICorner")
InfoBarCorner.CornerRadius = UDim.new(0, 4)
InfoBarCorner.Parent = InfoBar

local InfoBarText = Instance.new("TextLabel")
InfoBarText.Size = UDim2.new(1, -10, 1, 0)
InfoBarText.Position = UDim2.new(0, 5, 0, 0)
InfoBarText.BackgroundTransparency = 1
InfoBarText.Text = "📡 " .. #allRemotes .. " remotes | 📜 " .. #allScripts .. " scripts | 💰 " .. #ecoItems .. " eco"
InfoBarText.TextColor3 = Color3.fromRGB(150, 200, 255)
InfoBarText.TextXAlignment = Enum.TextXAlignment.Left
InfoBarText.TextScaled = true
InfoBarText.Font = Enum.Font.Gotham
InfoBarText.Parent = InfoBar

local TextContainer = Instance.new("Frame")
TextContainer.Size = UDim2.new(1, -16, 1, -120)
TextContainer.Position = UDim2.new(0, 8, 0, 70)
TextContainer.BackgroundColor3 = Color3.fromRGB(8, 8, 22)
TextContainer.BorderSizePixel = 0
TextContainer.Parent = Main

local TextCorner = Instance.new("UICorner")
TextCorner.CornerRadius = UDim.new(0, 6)
TextCorner.Parent = TextContainer

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, -8, 1, -8)
ScrollingFrame.Position = UDim2.new(0, 4, 0, 4)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.ScrollBarThickness = 6
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
ScrollingFrame.Parent = TextContainer

local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(1, -8, 0, 0)
TextLabel.Position = UDim2.new(0, 4, 0, 4)
TextLabel.BackgroundTransparency = 1
TextLabel.Text = fullText
TextLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
TextLabel.TextXAlignment = Enum.TextXAlignment.Left
TextLabel.TextYAlignment = Enum.TextYAlignment.Top
TextLabel.Font = Enum.Font.Code
TextLabel.TextSize = 11
TextLabel.RichText = false
TextLabel.TextWrapped = true
TextLabel.Parent = ScrollingFrame

local textHeight = math.max(#reportLines * 16, ScrollingFrame.AbsoluteSize.Y - 8)
TextLabel.Size = UDim2.new(1, -8, 0, textHeight)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, textHeight + 16)

local ButtonBar = Instance.new("Frame")
ButtonBar.Size = UDim2.new(1, -16, 0, 36)
ButtonBar.Position = UDim2.new(0, 8, 1, -44)
ButtonBar.BackgroundTransparency = 1
ButtonBar.Parent = Main

local function criarBotao(texto, cor, x, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 32)
    btn.Position = UDim2.new(0, x, 0.5, -16)
    btn.BackgroundColor3 = cor
    btn.Text = texto
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = ButtonBar
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    btn.MouseButton1Click:Connect(callback)
    return btn
end

criarBotao("📋 Copiar", Color3.fromRGB(0, 150, 80), 0, function()
    local copiado = false
    for _, nome in ipairs({"setclipboard", "toclipboard", "set_clipboard"}) do
        local ok = pcall(function() _G[nome](fullText) end)
        if ok then copiado = true; break end
    end
    if copiado then
        InfoBarText.Text = "✅ COPIADO!"
    else
        InfoBarText.Text = "⚠️ Ctrl+A, Ctrl+C para copiar"
    end
    task.delay(3, function()
        InfoBarText.Text = "📡 " .. #allRemotes .. " remotes | 📜 " .. #allScripts .. " scripts | 💰 " .. #ecoItems .. " eco"
    end)
end)

criarBotao("✕ Fechar", Color3.fromRGB(180, 40, 40), 135, function()
    ScreenGui:Destroy()
end)

criarBotao("💾 Salvar", Color3.fromRGB(0, 100, 200), 270, function()
    local nomeArquivo = "HackerAI_v9_" .. game.PlaceId .. ".txt"
    local ok = pcall(function() writefile(nomeArquivo, fullText) end)
    if ok then
        InfoBarText.Text = "✅ Salvo: " .. nomeArquivo
    else
        InfoBarText.Text = "⚠️ Falha ao salvar"
    end
    task.delay(3, function()
        InfoBarText.Text = "📡 " .. #allRemotes .. " remotes | 📜 " .. #allScripts .. " scripts | 💰 " .. #ecoItems .. " eco"
    end)
end)

local Notif = Instance.new("Frame")
Notif.Size = UDim2.new(0, 320, 0, 44)
Notif.Position = UDim2.new(0.5, -160, 0, 10)
Notif.BackgroundColor3 = Color3.fromRGB(0, 60, 30)
Notif.BorderSizePixel = 0
Notif.Parent = ScreenGui

local NotifCorner = Instance.new("UICorner")
NotifCorner.CornerRadius = UDim.new(0, 8)
NotifCorner.Parent = Notif

local NotifStroke = Instance.new("UIStroke")
NotifStroke.Color = Color3.fromRGB(0, 200, 100)
NotifStroke.Thickness = 1.5
NotifStroke.Parent = Notif

local NotifText = Instance.new("TextLabel")
NotifText.Size = UDim2.new(1, -10, 1, 0)
NotifText.Position = UDim2.new(0, 5, 0, 0)
NotifText.BackgroundTransparency = 1
NotifText.Text = "✅ Analise concluida! Copie e cole aqui."
NotifText.TextColor3 = Color3.fromRGB(100, 255, 150)
NotifText.TextScaled = true
NotifText.Font = Enum.Font.GothamBold
NotifText.Parent = Notif

task.delay(5, function()
    TweenService:Create(Notif, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    task.delay(0.6, function() Notif:Destroy() end)
end)

if clipboardOk then
    print("✅ Relatorio copiado automaticamente!")
else
    print("⚠️ Clique em 'Copiar' na interface")
end

print("🖥️  Interface v9.2 criada! (400x450)")
StarterGui:SetCore("SendNotification", {
    Title = "HackerAI v9.2",
    Text = "Analise completa! Copie o texto.",
    Duration = 3
})
