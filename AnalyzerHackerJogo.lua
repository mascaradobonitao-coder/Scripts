--[[
  🔍 HACKERAI ANALYZER v8.0 — GUI COMPACTA + REMOTE SPY
  • Interface quadrada e menor (mobile-friendly)
  • TextBox editável (ver + escrever)
  • Remote Spy passivo (10s de monitoramento)
  • 0 remotes executados — modo read-only
  Compatível: Delta Executor
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Chat = game:GetService("Chat")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ====== FUNÇÕES AUXILIARES ======
local function tableToString(tbl, depth)
    depth = depth or 0
    if depth > 3 then return "{...}" end
    if typeof(tbl) == "string" then return string.format("%q", tbl) end
    if typeof(tbl) == "number" or typeof(tbl) == "boolean" then return tostring(tbl) end
    if typeof(tbl) == "Instance" then return tbl:GetFullName() end
    if type(tbl) ~= "table" then return tostring(tbl) end
    
    local parts = {}
    for k, v in pairs(tbl) do
        local kStr = type(k) == "number" and ("[" .. k .. "]") or ("[" .. tableToString(k, depth+1) .. "]")
        table.insert(parts, kStr .. " = " .. tableToString(v, depth+1))
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

local function truncate(s, maxLen)
    maxLen = maxLen or 120
    if #s > maxLen then
        return s:sub(1, maxLen) .. "..."
    end
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

-- CABEÇALHO
add("╔═══════════════════════════════════════════════════╗")
add("║   🔍 HACKERAI DEEP ANALYSIS v8.0                ║")
add("╠═══════════════════════════════════════════════════╣")
add("║  Modo: READ-ONLY | 0 remotes executados         ║")
add("║  Jogador: " .. string.format("%-42s", LocalPlayer.Name) .. "║")
add("║  Place ID: " .. string.format("%-40d", game.PlaceId) .. "║")
add("╚═══════════════════════════════════════════════════╝")
add("")

-- ===== 1. INFORMAÇÕES DETALHADAS DO JOGO =====
add("▓▓▓ 1. INFORMACOES DO JOGO ▓▓▓")
add("")
add("  Nome:             " .. game.Name)
add("  Place ID:         " .. game.PlaceId)
add("  Game ID:          " .. game.GameId)
add("  Creator ID:       " .. game.CreatorId)
add("  Creator Type:     " .. tostring(game.CreatorType))
add("  Private:          " .. tostring(game.Private))
add("  Place Version:    " .. tostring(game.PlaceVersion))
add("  Jogadores:        " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
add("  Gravidade:        " .. tostring(game.Workspace.Gravity))
add("  Streaming:        " .. tostring(game.Workspace.StreamingEnabled))
add("  Lighting Tech:    " .. tostring(Lighting.Technology))
add("  Lighting Clock:   " .. tostring(Lighting.ClockTime))
add("  Lighting Ambient: " .. tostring(Lighting.Ambient))
add("  HttpEnabled:      " .. tostring(game:GetService("HttpService").HttpEnabled))
add("  Workspace Filter: " .. tostring(game.Workspace.FilteringEnabled))
add("  Replicated First: " .. tostring(game.ReplicatedFirst))
add("  Chat Enabled:     " .. tostring(Chat:IsChatEnabled()))
add("  Loaded Modules:   " .. #game:GetService("InsertService"):GetInsertProviders())
add("")

-- Tenta pegar info da loja (se for jogo pago)
local placeInfo = nil
local placeInfoOk, placeInfoResult = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)
if placeInfoOk and placeInfoResult then
    add("  Product Info:")
    add("    Name:          " .. (placeInfoResult.Name or "N/A"))
    add("    Description:   " .. truncate(placeInfoResult.Description or "N/A", 80))
    add("    Price:         " .. tostring(placeInfoResult.PriceInRobux or 0) .. " Robux")
    add("    IsForSale:     " .. tostring(placeInfoResult.IsForSale or false))
    add("    Seller:        " .. tostring(placeInfoResult.SellerId or 0))
    add("    Created:       " .. (placeInfoResult.Created or "N/A"))
    add("    Updated:       " .. (placeInfoResult.Updated or "N/A"))
    add("    Genre:         " .. (placeInfoResult.Genre or "N/A"))
    add("")
end

-- ===== 2. JOGADORES ONLINE =====
add("▓▓▓ 2. JOGADORES ONLINE ▓▓▓")
add("")
for _, plr in ipairs(Players:GetPlayers()) do
    local team = (plr.Team and plr.Team.Name) or "Sem time"
    local hp = "N/A"
    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
        local hum = plr.Character.Humanoid
        hp = string.format("%.0f/%.0f", hum.Health, hum.MaxHealth)
    end
    add("  " .. plr.Name .. " [" .. plr.DisplayName .. "]")
    add("     ID: " .. plr.UserId .. " | " .. team .. " | HP: " .. hp .. " | " .. plr.AccountAge .. "d")
    -- Mostra se tem VIP/Premium tags
    local membership = plr.MembershipType
    local membStr = tostring(membership)
    if membership == Enum.MembershipType.Premium then membStr = "PREMIUM" end
    add("     Membro: " .. membStr)
end
add("")

-- ===== 3. TIMES =====
add("▓▓▓ 3. TIMES ▓▓▓")
add("")
local times = Teams:GetTeams()
if #times > 0 then
    for _, t in ipairs(times) do
        local cor = t.TeamColor and tostring(t.TeamColor) or "N/A"
        add("  " .. t.Name .. " (" .. #t:GetPlayers() .. " jogadores) | Cor: " .. cor)
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
            table.insert(allScripts, {
                nome = o.Name,
                tipo = o.ClassName,
                linhas = lines,
                path = o:GetFullName(),
                source = o.Source or ""
            })
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

-- Agrupa por tipo
local srvScripts, cliScripts, modScripts = 0, 0, 0
for _, s in ipairs(allScripts) do
    if s.tipo == "Script" then srvScripts = srvScripts + 1
    elseif s.tipo == "LocalScript" then cliScripts = cliScripts + 1
    elseif s.tipo == "ModuleScript" then modScripts = modScripts + 1
    end
end
add("  Server Scripts: " .. srvScripts .. " | LocalScripts: " .. cliScripts .. " | Modules: " .. modScripts)
add("")

-- Mostra scripts maiores com keywords interessantes
local keywords = {"trade","troca","shop","buy","sell","venda","remote","event","function","invoke","fire","admin","ban","kick","teleport","spawn","coin","money","wallet","bank","daily","claim","reward","crate","pet","upgrade","equip","inventory"}
local interestingScripts = {}
for _, s in ipairs(allScripts) do
    local srcLower = s.source:lower()
    for _, kw in ipairs(keywords) do
        if srcLower:find(kw, 1, true) then
            table.insert(interestingScripts, s)
            break
        end
    end
end

if #interestingScripts > 0 then
    add("  Scripts com keywords interessantes:")
    add("")
    for i, s in ipairs(interestingScripts) do
        local t = ""
        if s.tipo == "Script" then t = "SRV"
        elseif s.tipo == "LocalScript" then t = "CLI"
        elseif s.tipo == "ModuleScript" then t = "MOD"
        end
        add(string.format("  %d. [%s] %s (%d linhas)", i, t, s.nome, s.linhas))
        add("     " .. s.path)
    end
    add("")
end

-- ===== 5. REMOTES =====
add("▓▓▓ 5. REMOTES ▓▓▓")
add("")

local allRemotes = {}

local function collectRemotes(c, d)
    if d > 10 then return end
    for _, o in ipairs(c:GetChildren()) do
        if o:IsA("RemoteEvent") then
            table.insert(allRemotes, {nome = o.Name, tipo = "EVENT", metodo = "FireServer", path = o:GetFullName(), instance = o})
        elseif o:IsA("RemoteFunction") then
            table.insert(allRemotes, {nome = o.Name, tipo = "FUNC", metodo = "InvokeServer", path = o:GetFullName(), instance = o})
        elseif o:IsA("UnreliableRemoteEvent") then
            table.insert(allRemotes, {nome = o.Name, tipo = "UNREL", metodo = "FireServer", path = o:GetFullName(), instance = o})
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

local events, funcs, unrels = 0, 0, 0
for _, r in ipairs(allRemotes) do
    if r.tipo == "EVENT" then events = events + 1
    elseif r.tipo == "FUNC" then funcs = funcs + 1
    elseif r.tipo == "UNREL" then unrels = unrels + 1
    end
end
add("  RemoteEvents: " .. events .. " | RemoteFunctions: " .. funcs .. " | UnreliableEvents: " .. unrels)
add("")

for i, r in ipairs(allRemotes) do
    add(string.format("  %d. [%s] %s (%s)", i, r.tipo, r.nome, r.metodo))
    add("     " .. r.path)
    
    local n = r.nome:lower()
    if n:find("buy") or n:find("compra") or n:find("purchase") then
        add("     ⮕ COMPRA. Args possiveis: itemId, quantidade, price")
    elseif n:find("sell") or n:find("venda") then
        add("     ⮕ VENDA. Args possiveis: itemId, quantidade, price")
    elseif n:find("trade") or n:find("troca") then
        add("     ⮕ TROCA/TRADE. Args possiveis: playerId, itensOferecidos, itensRecebidos")
    elseif n:find("claim") or n:find("daily") or n:find("presente") then
        add("     ⮕ RECOMPENSA DIARIA/CLAIM")
    elseif n:find("give") or n:find("reward") or n:find("present") then
        add("     ⮕ DAR ITEM. Args possiveis: player, item, quantidade")
    elseif n:find("kick") or n:find("ban") or n:find("punish") then
        add("     ⮕ ADMIN! Args possiveis: player, motivo, duracao")
    elseif n:find("admin") or n:find("command") or n:find("cmd") then
        add("     ⮕ ADMIN/COMANDO. Args possiveis: comando, args")
    elseif n:find("teleport") or n:find("spawn") or n:find("tp") or n:find("warp") then
        add("     ⮕ TELEPORTE. Args possiveis: posicao/destino/jogador")
    elseif n:find("chat") or n:find("say") or n:find("falar") or n:find("msg") then
        add("     ⮕ CHAT. Args possiveis: mensagem, channel")
    elseif n:find("damage") or n:find("hit") or n:find("attack") or n:find("dano") or n:find("deal") then
        add("     ⮕ DANO/ATAQUE. Args possiveis: target, valor, tipo")
    elseif n:find("shop") or n:find("loja") or n:find("store") then
        add("     ⮕ LOJA/SHOP")
    elseif n:find("inventory") or n:find("inventario") or n:find("backpack") then
        add("     ⮕ INVENTARIO")
    elseif n:find("equip") or n:find("wear") or n:find("vestir") then
        add("     ⮕ EQUIPAR. Args possiveis: itemId, slot")
    elseif n:find("upgrade") or n:find("melhorar") or n:find("enhance") then
        add("     ⮕ UPGRADE. Args possiveis: itemId, level")
    elseif n:find("save") or n:find("load") or n:find("data") then
        add("     ⮕ SAVE/LOAD. Args possiveis: dados")
    elseif n:find("get") or n:find("fetch") or n:find("check") or n:find("request") then
        add("     ⮕ CONSULTA. Args possiveis: tipo, dados")
    elseif n:find("vote") or n:find("votar") or n:find("like") then
        add("     ⮕ VOTO/LIKE")
    elseif n:find("friend") or n:find("amigo") or n:find("follow") then
        add("     ⮕ SOCIAL. Args possiveis: playerId")
    elseif n:find("party") or n:find("grupo") or n:find("squad") then
        add("     ⮕ GRUPO/PARTY")
    elseif n:find("pet") or n:find("montaria") or n:find("mount") then
        add("     ⮕ PET/MONTARIA")
    elseif n:find("craft") or n:find("craf") or n:find("fabric") then
        add("     ⮕ CRAFT/FABRICAR. Args possiveis: recipeId, qtd")
    elseif n:find("auction") or n:find("leilao") or n:find("market") then
        add("     ⮕ LEILAO/MERCADO")
    else
        add("     ⮕ Use Remote Spy abaixo para descobrir args")
    end
end
add("")

-- ===== 6. ECONOMIA / TRADES =====
add("▓▓▓ 6. ECONOMIA / TRADES ▓▓▓")
add("")

local keywords = {"trade","troca","shop","loja","venda","sell","buy","compra","market","coin","money","dinheiro","wallet","bank","banco","inventory","item","currency","moeda","price","preco","daily","claim","reward","crate","caixa","vip","premium","upgrade","rank","level","pet","montaria","guild","clan","auction","leilao","point","ponto","token","fragment","shard","gem","crystal","essence","gold","silver","bronze","cash"}
local ecoItems = {}
local ecoScripts = {}

local function scanEco(c, d)
    if d > 5 then return end
    for _, o in ipairs(c:GetChildren()) do
        local name = o.Name:lower()
        for _, kw in ipairs(keywords) do
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

-- Também procura em Leaderstats de cada player
local leaderstatsSamples = {}
for _, plr in ipairs(Players:GetPlayers()) do
    if plr:FindFirstChild("leaderstats") then
        local led = plr.leaderstats
        local info = {}
        for _, stat in ipairs(led:GetChildren()) do
            table.insert(info, stat.Name .. " = " .. tostring(stat.Value))
        end
        if #info > 0 then
            leaderstatsSamples[plr.Name] = info
        end
    end
end

add("  Itens de economia encontrados: " .. #ecoItems)
add("")
if #ecoItems > 0 then
    add("  Estruturas de economia:")
    for i, e in ipairs(ecoItems) do
        add(string.format("    %d. [%s] %s", i, e.classe, e.nome))
        add("       " .. e.path)
    end
    add("")
end

-- Leaderstats
if next(leaderstatsSamples) then
    add("  Leaderstats (amostra dos jogadores):")
    for plrName, stats in pairs(leaderstatsSamples) do
        add("    " .. plrName .. ":")
        for _, s in ipairs(stats) do
            add("      ◆ " .. s)
        end
    end
    add("")
end

-- Análise de sistema de trades
local tradeKeywords = {"trade", "troca", "exchange", "negociar", "swap"}
local hasTradeSystem = false
for _, r in ipairs(allRemotes) do
    local n = r.nome:lower()
    for _, tk in ipairs(tradeKeywords) do
        if n:find(tk, 1, true) then
            hasTradeSystem = true
            add("  🔄 SISTEMA DE TRADE DETECTADO!")
            add("    Remote: " .. r.nome .. " (" .. r.tipo .. ")")
            add("    Path: " .. r.path)
            add("")
            break
        end
    end
    if hasTradeSystem then break end
end

for _, e in ipairs(ecoItems) do
    local n = e.nome:lower()
    for _, tk in ipairs(tradeKeywords) do
        if n:find(tk, 1, true) then
            hasTradeSystem = true
            add("  🔄 SISTEMA DE TRADE DETECTADO!")
            add("    Item: " .. e.nome .. " (" .. e.classe .. ")")
            add("    Path: " .. e.path)
            add("")
            break
        end
    end
    if hasTradeSystem then break end
end

if not hasTradeSystem then
    add("  Nenhum sistema de trade detectado nos remotes.")
    add("  (Pode estar ofuscado ou ser via ModuleScript)")
    add("")
end

-- ===== 7. REMOTE SPY (PASSIVO - 10 SEGUNDOS) =====
add("▓▓▓ 7. REMOTE SPY (10s de monitoramento passivo) ▓▓▓")
add("")
add("  Monitorando remotes usados pelo jogo...")
add("  (Apenas observação - 0 remotes executados)")
add("")

-- Hooks para monitorar
local remoteLog = {}
local spying = true
local spyStart = tick()

-- Hook via namecall
local mt = nil
local oldNamecall = nil
local hookOk = false

local ok, err = pcall(function()
    mt = getrawmetatable(game)
    oldNamecall = mt.__namecall
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        if spying and (method == "FireServer" or method == "InvokeServer") 
           and typeof(self) == "Instance" 
           and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction") or self:IsA("UnreliableRemoteEvent")) then
            local args = {...}
            table.insert(remoteLog, {
                remote = self.Name,
                path = self:GetFullName(),
                tipo = self.ClassName,
                method = method,
                args = args,
                elapsed = math.floor((tick() - spyStart) * 10) / 10
            })
        end
        
        return oldNamecall(self, ...)
    end)
    
    setreadonly(mt, true)
    hookOk = true
end)

if hookOk then
    add("  ✅ Hook instalado! Monitorando por 10 segundos...")
    add("")
    
    -- Espera 10 segundos enquanto monitora
    task.wait(10)
    
    -- Para o spy
    spying = false
    
    -- Remove hook
    pcall(function()
        setreadonly(mt, false)
        mt.__namecall = oldNamecall
        setreadonly(mt, true)
    end)
    
    add("  ⏱️  Monitoramento concluido (10s)")
    add("")
    
    if #remoteLog > 0 then
        add("  Remotes observados durante o monitoramento: " .. #remoteLog)
        add("")
        
        -- Agrupa por remote
        local grouped = {}
        for _, entry in ipairs(remoteLog) do
            local key = entry.remote
            grouped[key] = grouped[key] or {nome = entry.remote, path = entry.path, tipo = entry.tipo, method = entry.method, calls = 0, args = {}}
            grouped[key].calls = grouped[key].calls + 1
            grouped[key].args = entry.args
        end
        
        -- Ordena por mais chamado
        local sorted = {}
        for _, v in pairs(grouped) do
            table.insert(sorted, v)
        end
        table.sort(sorted, function(a, b) return a.calls > b.calls end)
        
        for i, g in ipairs(sorted) do
            add(string.format("  %d. [%s] %s (%d chamadas)", i, g.tipo, g.nome, g.calls))
            add("     Path: " .. g.path)
            add("     Metodo: " .. g.method)
            if g.args and #g.args > 0 then
                local argsStr = {}
                for _, arg in ipairs(g.args) do
                    table.insert(argsStr, truncate(tableToString(arg, 0), 80))
                end
                add("     Args observados: " .. table.concat(argsStr, " | "))
            end
            add("")
        end
    else
        add("  Nenhum remote foi chamado durante o monitoramento.")
        add("  (O jogo pode usar BindToFunction ou estar ocioso)")
        add("")
    end
else
    add("  ⚠️  Nao foi possivel instalar o Remote Spy.")
    add("  (Executor pode nao suportar getrawmetatable ou newcclosure)")
    add("")
end

-- ===== 8. RESUMO PARA SCRIPTS =====
add("▓▓▓ 8. RESUMO PARA CRIACAO DE SCRIPTS ▓▓▓")
add("")
add("  Copie este relatorio e envie para o HackerAI,")
add("  que eu analiso e crio scripts especificos para")
add("  este jogo do ROBLOX!")
add("")
add("  Remote mais interessante: " .. (#allRemotes > 0 and allRemotes[1].nome or "N/A"))
add("  Total de remotes: " .. #allRemotes)
add("  Total de scripts: " .. #allScripts)
add("  Sistema de trade: " .. (hasTradeSystem and "SIM" or "NAO DETECTADO"))
add("  Remote Spy ativo: " .. (hookOk and "SIM (" .. #remoteLog .. " chamadas)" or "NAO"))
add("")

-- RODAPÉ
sep()
add("  ✅ ANALISE CONCLUIDA!")
add("  📡 Remotes: " .. #allRemotes .. " | 📜 Scripts: " .. #allScripts)
add("  🔍 Remote Spy: " .. #remoteLog .. " chamadas observadas")
add("  🔒 Modo READ-ONLY - Nenhum remote executado")
sep()

-- Junta tudo
local fullText = table.concat(reportLines, "\n")

-- ====== CRIA A INTERFACE COMPACTA ======
print("🖥️  Criando interface compacta...")

-- Tenta copiar pro clipboard
local clipboardOk = false
for _, func in ipairs({"setclipboard", "toclipboard", "set_clipboard"}) do
    local ok = pcall(function()
        _G[func](fullText)
    end)
    if ok then
        clipboardOk = true
        break
    end
end

-- Cria GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HackerAI_Analyzer_v8"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Fundo escuro semi-transparente
local Background = Instance.new("Frame")
Background.Name = "Background"
Background.Size = UDim2.new(1, 0, 1, 0)
Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Background.BackgroundTransparency = 0.45
Background.Parent = ScreenGui
Background.Active = true

-- MAIN WINDOW (mais quadrada e menor: 360x440)
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 360, 0, 440)
Main.Position = UDim2.new(0.5, -180, 0.5, -220)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 28)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

-- Cantos mais quadrados (4px em vez de 8)
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 4)
UICorner.Parent = Main

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 170, 255)
UIStroke.Thickness = 1.5
UIStroke.Parent = Main

-- TITLE BAR
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 34)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 45)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 4)
TitleCorner.Parent = TitleBar

-- Retângulo pra esconder curva inferior
local TitleMask = Instance.new("Frame")
TitleMask.Size = UDim2.new(1, 0, 0, 8)
TitleMask.Position = UDim2.new(0, 0, 0.7, 0)
TitleMask.BackgroundColor3 = Color3.fromRGB(18, 18, 45)
TitleMask.BorderSizePixel = 0
TitleMask.Parent = TitleBar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 24, 1, 0)
TitleIcon.Position = UDim2.new(0, 6, 0, 0)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "🔍"
TitleIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleIcon.TextScaled = true
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -70, 1, 0)
TitleText.Position = UDim2.new(0, 34, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "HackerAI v8.0"
TitleText.TextColor3 = Color3.fromRGB(0, 170, 255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.TextScaled = true
TitleText.Font = Enum.Font.GothamBold
TitleText.Parent = TitleBar

-- Botão Fechar (menor)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -32, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextScaled = true
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    -- Restaura o hook se ainda estiver ativo
    if mt and oldNamecall then
        pcall(function()
            setreadonly(mt, false)
            mt.__namecall = oldNamecall
            setreadonly(mt, true)
        end)
    end
    ScreenGui:Destroy()
end)

-- DRAG (com suporte a toque)
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

-- INFO BAR
local InfoBar = Instance.new("Frame")
InfoBar.Size = UDim2.new(1, -12, 0, 20)
InfoBar.Position = UDim2.new(0, 6, 0, 38)
InfoBar.BackgroundColor3 = Color3.fromRGB(13, 13, 36)
InfoBar.BorderSizePixel = 0
InfoBar.Parent = Main

local InfoBarCorner = Instance.new("UICorner")
InfoBarCorner.CornerRadius = UDim.new(0, 3)
InfoBarCorner.Parent = InfoBar

local InfoBarText = Instance.new("TextLabel")
InfoBarText.Size = UDim2.new(1, -8, 1, 0)
InfoBarText.Position = UDim2.new(0, 4, 0, 0)
InfoBarText.BackgroundTransparency = 1
InfoBarText.Text = "📡 " .. #allRemotes .. " remotes | 📜 " .. #allScripts .. " scripts | 🔍 " .. #remoteLog .. " spy"
InfoBarText.TextColor3 = Color3.fromRGB(130, 190, 255)
InfoBarText.TextXAlignment = Enum.TextXAlignment.Left
InfoBarText.TextScaled = true
InfoBarText.Font = Enum.Font.Gotham
InfoBarText.Parent = InfoBar

-- TEXTBOX EDITÁVEL (ScrollingFrame + TextBox)
local TextContainer = Instance.new("Frame")
TextContainer.Size = UDim2.new(1, -12, 1, -100)
TextContainer.Position = UDim2.new(0, 6, 0, 62)
TextContainer.BackgroundColor3 = Color3.fromRGB(6, 6, 18)
TextContainer.BorderSizePixel = 0
TextContainer.Parent = Main

local TextCorner = Instance.new("UICorner")
TextCorner.CornerRadius = UDim.new(0, 4)
TextCorner.Parent = TextContainer

-- TEXTBOX (editável - pode VER e ESCREVER)
local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -8, 1, -8)
TextBox.Position = UDim2.new(0, 4, 0, 4)
TextBox.BackgroundTransparency = 1
TextBox.BorderSizePixel = 0
TextBox.Text = fullText
TextBox.TextColor3 = Color3.fromRGB(190, 210, 255)
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.TextYAlignment = Enum.TextYAlignment.Top
TextBox.Font = Enum.Font.Code
TextBox.TextSize = 10
TextBox.TextWrapped = true
TextBox.MultiLine = true
TextBox.ClearTextOnFocus = false
TextBox.Parent = TextContainer

-- Scroll automático no TextBox (usa um ScrollingFrame invisível como container)
-- Na verdade, TextBox multi-line já dá scroll naturalmente

-- BOTOES (barra inferior)
local ButtonBar = Instance.new("Frame")
ButtonBar.Size = UDim2.new(1, -12, 0, 32)
ButtonBar.Position = UDim2.new(0, 6, 1, -38)
ButtonBar.BackgroundTransparency = 1
ButtonBar.Parent = Main

local function criarBotao(texto, cor, x, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 28)
    btn.Position = UDim2.new(0, x, 0.5, -14)
    btn.BackgroundColor3 = cor
    btn.Text = texto
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = ButtonBar
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    
    return btn
end

-- Botão COPIAR
criarBotao("📋 Copiar", Color3.fromRGB(0, 130, 70), 0, function()
    local textoAtual = TextBox.Text
    local copiado = false
    for _, nome in ipairs({"setclipboard", "toclipboard", "set_clipboard"}) do
        local ok = pcall(function()
            _G[nome](textoAtual)
        end)
        if ok then
            copiado = true
            break
        end
    end
    
    if copiado then
        InfoBarText.Text = "✅ COPIADO!"
    else
        -- Seleciona tudo como fallback
        TextBox:CaptureFocus()
        TextBox.SelectionStart = 1
        TextBox.CursorPosition = #textoAtual + 1
        InfoBarText.Text = "⚠️ Ctrl+A, Ctrl+C p/ copiar"
    end
    task.delay(2, function()
        InfoBarText.Text = "📡 " .. #allRemotes .. " remotes | 📜 " .. #allScripts .. " scripts | 🔍 " .. #remoteLog .. " spy"
    end)
end)

-- Botão FECHAR
criarBotao("✕ Fechar", Color3.fromRGB(160, 35, 35), 120, function()
    if mt and oldNamecall then
        pcall(function()
            setreadonly(mt, false)
            mt.__namecall = oldNamecall
            setreadonly(mt, true)
        end)
    end
    ScreenGui:Destroy()
end)

-- Botão SALVAR
criarBotao("💾 Salvar", Color3.fromRGB(0, 85, 180), 240, function()
    local nomeArquivo = "HackerAI_v8_" .. game.PlaceId .. ".txt"
    local ok = pcall(function()
        writefile(nomeArquivo, TextBox.Text)
    end)
    if ok then
        InfoBarText.Text = "✅ Salvo: " .. nomeArquivo
    else
        InfoBarText.Text = "⚠️ Falha ao salvar"
    end
    task.delay(2.5, function()
        InfoBarText.Text = "📡 " .. #allRemotes .. " remotes | 📜 " .. #allScripts .. " scripts | 🔍 " .. #remoteLog .. " spy"
    end)
end)

-- NOTIFICAÇÃO INICIAL
local Notif = Instance.new("Frame")
Notif.Size = UDim2.new(0, 280, 0, 36)
Notif.Position = UDim2.new(0.5, -140, 0, 8)
Notif.BackgroundColor3 = Color3.fromRGB(0, 55, 28)
Notif.BorderSizePixel = 0
Notif.Parent = ScreenGui

local NotifCorner = Instance.new("UICorner")
NotifCorner.CornerRadius = UDim.new(0, 6)
NotifCorner.Parent = Notif

local NotifStroke = Instance.new("UIStroke")
NotifStroke.Color = Color3.fromRGB(0, 190, 90)
NotifStroke.Thickness = 1.5
NotifStroke.Parent = Notif

local NotifText = Instance.new("TextLabel")
NotifText.Size = UDim2.new(1, -8, 1, 0)
NotifText.Position = UDim2.new(0, 4, 0, 0)
NotifText.BackgroundTransparency = 1
NotifText.Text = "✅ Analise + Spy concluidos! Copie o texto."
NotifText.TextColor3 = Color3.fromRGB(80, 255, 130)
NotifText.TextScaled = true
NotifText.Font = Enum.Font.GothamBold
NotifText.Parent = Notif

task.delay(5, function()
    TweenService:Create(Notif, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    task.delay(0.6, function() Notif:Destroy() end)
end)

-- Copia automática
local autoCopied = false
for _, nome in ipairs({"setclipboard", "toclipboard", "set_clipboard"}) do
    local ok = pcall(function()
        _G[nome](fullText)
    end)
    if ok then
        autoCopied = true
        break
    end
end

if autoCopied then
    print("✅ Relatorio copiado automaticamente!")
else
    print("⚠️ Clique em 'Copiar' na interface")
end

print("🖥️  Interface v8.0 carregada! (360x440, compacta)")
StarterGui:SetCore("SendNotification", {
    Title = "HackerAI v8.0",
    Text = "Analise + Spy concluidos!",
    Duration = 3
})
