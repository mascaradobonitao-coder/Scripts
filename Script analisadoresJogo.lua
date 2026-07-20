--[[
  🔍 HACKERAI DEEP ANALYZER v5.0
  Modo: HEADLESS | Salva em arquivo via writefile()
  Compatível: Delta Executor
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Teams = game:GetService("Teams")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
local placeName = tostring(game.PlaceId)
local fileName = "HackerAI_Analysis_" .. placeName .. "_" .. timestamp .. ".txt"
local filePath = fileName -- No Delta, fica na pasta /delta/workspace/

-- ====== FUNÇÕES AUXILIARES ======
local outputLines = {}
local function log(msg)
    table.insert(outputLines, msg)
    print(msg)
end

local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 3
        })
    end)
end

local function salvarArquivo()
    local sucesso = pcall(function()
        writefile(fileName, table.concat(outputLines, "\n"))
    end)
    return sucesso
end

-- ====== CABEÇALHO ======
log("")
log("╔══════════════════════════════════════════════════════════════╗")
log("║        🔍 HACKERAI DEEP GAME ANALYSIS REPORT v5.0           ║")
log("╠══════════════════════════════════════════════════════════════╣")
log("║  Modo: READ-ONLY | Zero remotes executados                  ║")
log("║  Alvo: " .. string.format("%-51s", LocalPlayer.Name) .. "║")
log("║  Place ID: " .. string.format("%-49d", game.PlaceId) .. "║")
log("║  Data: " .. string.format("%-51s", os.date("%d/%m/%Y %H:%M:%S")) .. "║")
log("╚══════════════════════════════════════════════════════════════╝")
log("")
notify("HackerAI Analyzer", "Analisando... aguarde", 2)

-- ====== 1. INFORMAÇÕES DO JOGO ======
log("╔══════════════════════════════════════════════════════════════╗")
log("║  1. INFORMAÇÕES DO JOGO                                     ║")
log("╚══════════════════════════════════════════════════════════════╝")
log("")
log("  Nome do Jogo:    " .. game.Name)
log("  Descrição:       " .. (game.Description:sub(1, 100) or "N/A"))
log("  Place ID:        " .. game.PlaceId)
log("  Game ID:         " .. game.GameId)
log("  Creator ID:      " .. game.CreatorId)
log("  Creator Type:    " .. tostring(game.CreatorType))
log("  Jogadores:       " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
log("  Streaming:       " .. tostring(game.Workspace.StreamingEnabled))
log("  Gravidade:       " .. tostring(game.Workspace.Gravity))
log("  Lighting Tech:   " .. tostring(Lighting.Technology))
log("  Lighting Time:   " .. string.format("%.1f", Lighting.ClockTime))
log("  Som Ambiente:    " .. tostring(SoundService.AmbientReverb))
log("")

-- ====== 2. PLAYERS ONLINE ======
log("╔══════════════════════════════════════════════════════════════╗")
log("║  2. JOGADORES ONLINE                                        ║")
log("╚══════════════════════════════════════════════════════════════╝")
log("")

local jogadores = {}
for _, plr in ipairs(Players:GetPlayers()) do
    local team = (plr.Team and plr.Team.Name) or "Sem time"
    local hp = "N/A"
    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
        hp = string.format("%.0f/%.0f", plr.Character.Humanoid.Health, plr.Character.Humanoid.MaxHealth)
    end
    table.insert(jogadores, {
        nome = plr.Name,
        display = plr.DisplayName,
        id = plr.UserId,
        team = team,
        hp = hp,
        idade = plr.AccountAge,
    })
end

if #jogadores > 0 then
    for i, p in ipairs(jogadores) do
        log("  " .. i .. ". " .. p.nome .. " [" .. p.display .. "]")
        log("     ID: " .. p.id .. " | Time: " .. p.team .. " | HP: " .. p.hp .. " | Conta: " .. p.idade .. " dias")
    end
else
    log("  Nenhum jogador online (só você).")
end
log("")

-- ====== 3. TIMES ======
log("╔══════════════════════════════════════════════════════════════╗")
log("║  3. TIMES                                                    ║")
log("╚══════════════════════════════════════════════════════════════╝")
log("")

local times = Teams:GetTeams()
if #times > 0 then
    for _, t in ipairs(times) do
        log("  🏳️  " .. t.Name .. " (" .. #t:GetPlayers() .. " jogadores)")
    end
else
    log("  Nenhum time configurado neste jogo.")
end
log("")

-- ====== 4. SCRIPTS (DETALHADO) ======
log("╔══════════════════════════════════════════════════════════════╗")
log("║  4. SCRIPTS (CATEGORIZADOS)                                 ║")
log("╚══════════════════════════════════════════════════════════════╝")
log("")

local scripts = {
    Script = {},
    LocalScript = {},
    ModuleScript = {},
}
local totalScripts = 0
local totalLinhas = 0

local function scanScripts(container, depth)
    if depth > 7 then return end
    for _, obj in ipairs(container:GetChildren()) do
        if obj:IsA("Script") then
            local linhas = obj.Source and #obj.Source:split("\n") or 0
            local ctx = obj.RunContext and tostring(obj.RunContext) or "Legacy"
            table.insert(scripts.Script, {nome = obj.Name, linhas = linhas, ctx = ctx, path = obj:GetFullName()})
            totalScripts = totalScripts + 1
            totalLinhas = totalLinhas + linhas
        elseif obj:IsA("LocalScript") then
            local linhas = obj.Source and #obj.Source:split("\n") or 0
            table.insert(scripts.LocalScript, {nome = obj.Name, linhas = linhas, path = obj:GetFullName()})
            totalScripts = totalScripts + 1
            totalLinhas = totalLinhas + linhas
        elseif obj:IsA("ModuleScript") then
            local linhas = obj.Source and #obj.Source:split("\n") or 0
            table.insert(scripts.ModuleScript, {nome = obj.Name, linhas = linhas, path = obj:GetFullName()})
            totalScripts = totalScripts + 1
            totalLinhas = totalLinhas + linhas
        end
        if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("Configuration") then
            scanScripts(obj, depth + 1)
        end
    end
end

scanScripts(ReplicatedStorage, 0)
scanScripts(game:GetService("ServerScriptService"), 0)
scanScripts(game:GetService("ServerStorage"), 0)
scanScripts(game:GetService("StarterGui"), 0)
scanScripts(game:GetService("StarterPlayer"), 0)
scanScripts(game:GetService("Workspace"), 0)

log("  Total: " .. totalScripts .. " scripts (~" .. totalLinhas .. " linhas no total)")
log("")

-- SERVER SCRIPTS
log("  ┌── SCRIPTS DE SERVIDOR (Script) ──────────────────────┐")
if #scripts.Script > 0 then
    for i, s in ipairs(scripts.Script) do
        log(string.format("  │ %3d. %s (%d linhas) [%s]", i, s.nome, s.linhas, s.ctx))
        log("  │     📍 " .. s.path)
    end
else
    log("  │   Nenhum Script encontrado.")
end
log("  └──────────────────────────────────────────────────────┘")
log("")

-- LOCAL SCRIPTS
log("  ┌── LOCALSCRIPTS (Cliente) ────────────────────────────┐")
if #scripts.LocalScript > 0 then
    for i, s in ipairs(scripts.LocalScript) do
        log(string.format("  │ %3d. %s (%d linhas)", i, s.nome, s.linhas))
        log("  │     📍 " .. s.path)
    end
else
    log("  │   Nenhum LocalScript encontrado.")
end
log("  └──────────────────────────────────────────────────────┘")
log("")

-- MODULE SCRIPTS
log("  ┌── MODULESCRIPTS ─────────────────────────────────────┐")
if #scripts.ModuleScript > 0 then
    for i, s in ipairs(scripts.ModuleScript) do
        log(string.format("  │ %3d. %s (%d linhas)", i, s.nome, s.linhas))
        log("  │     📍 " .. s.path)
    end
else
    log("  │   Nenhum ModuleScript encontrado.")
end
log("  └──────────────────────────────────────────────────────┘")
log("")

-- ====== 5. REMOTES ======
log("╔══════════════════════════════════════════════════════════════╗")
log("║  5. REMOTES                                                 ║")
log("╚══════════════════════════════════════════════════════════════╝")
log("")

local remotes = {
    RemoteEvent = {},
    RemoteFunction = {},
    UnreliableRemoteEvent = {},
}
local totalRemotes = 0

local function scanRemotes(container, depth)
    if depth > 10 then return end
    for _, obj in ipairs(container:GetChildren()) do
        if obj:IsA("RemoteEvent") then
            table.insert(remotes.RemoteEvent, {nome = obj.Name, path = obj:GetFullName(), parent = container.Name})
            totalRemotes = totalRemotes + 1
        elseif obj:IsA("RemoteFunction") then
            table.insert(remotes.RemoteFunction, {nome = obj.Name, path = obj:GetFullName(), parent = container.Name})
            totalRemotes = totalRemotes + 1
        elseif obj:IsA("UnreliableRemoteEvent") then
            table.insert(remotes.UnreliableRemoteEvent, {nome = obj.Name, path = obj:GetFullName(), parent = container.Name})
            totalRemotes = totalRemotes + 1
        end
        if obj:IsA("Folder") or obj:IsA("Configuration") or obj:IsA("Model") then
            scanRemotes(obj, depth + 1)
        end
    end
end

scanRemotes(ReplicatedStorage, 0)
scanRemotes(game:GetService("Workspace"), 0)
scanRemotes(game:GetService("Players"), 0)
scanRemotes(game:GetService("ServerStorage"), 0)

log("  Total de remotes encontrados: " .. totalRemotes)
log("")

-- RemoteEvents
log("  ┌── REMOTEEVENTS (FireServer) ─────────────────────────┐")
if #remotes.RemoteEvent > 0 then
    for i, r in ipairs(remotes.RemoteEvent) do
        log("  │ " .. string.format("%3d. %s", i, r.nome))
        log("  │     📍 " .. r.path)
        
        -- Sugestão automática baseada no nome
        local nome = r.nome:lower()
        local sugestao = ""
        if nome:find("buy") or nome:find("compra") or nome:find("purchase") then
            sugestao = "🔸 Possível remote de compra. Args: itemId, quantidade"
        elseif nome:find("sell") or nome:find("venda") then
            sugestao = "🔸 Remote de venda. Args: itemId, quantidade"
        elseif nome:find("trade") or nome:find("troca") then
            sugestao = "🔸 Remote de troca. Args: player, itens"
        elseif nome:find("claim") or nome:find("daily") or nome:find("coletar") then
            sugestao = "🔸 Recompensa diária. Args: possivelmente vazio"
        elseif nome:find("give") or nome:find("reward") or nome:find("presente") then
            sugestao = "🔸 Remote de dar itens. Args: player, item, amount"
        elseif nome:find("kick") or nome:find("ban") or nome:find("punish") then
            sugestao = "⚠️ Remote administrativo! Args: player, motivo"
        elseif nome:find("admin") or nome:find("command") then
            sugestao = "⚠️ Remote de comandos admin! Args: comando, args"
        elseif nome:find("save") or nome:find("load") or nome:find("data") then
            sugestao = "🔸 Remote de save/load. Possível data corruption"
        elseif nome:find("spawn") or nome:find("teleport") then
            sugestao = "🔸 Remote de teleporte. Args: posição ou destino"
        elseif nome:find("chat") or nome:find("say") then
            sugestao = "🔸 Remote de chat. Args: mensagem"
        elseif nome:find("damage") or nome:find("hit") or nome:find("attack") then
            sugestao = "🔸 Remote de dano. Args: target, damage"
        elseif nome:find("equip") or nome:find("unequip") then
            sugestao = "🔸 Remote de equipar item. Args: itemId"
        elseif nome:find("upgrade") or nome:find("melhoria") then
            sugestao = "🔸 Remote de upgrade. Args: itemId"
        else
            sugestao = "🔸 Nome genérico. Use Remote Spy pra descobrir args"
        end
        log("  │     " .. sugestao)
    end
else
    log("  │   Nenhum RemoteEvent encontrado.")
end
log("  └──────────────────────────────────────────────────────┘")
log("")

-- RemoteFunctions
log("  ┌── REMOTEFUNCTIONS (InvokeServer) ────────────────────┐")
if #remotes.RemoteFunction > 0 then
    for i, r in ipairs(remotes.RemoteFunction) do
        log("  │ " .. string.format("%3d. %s", i, r.nome))
        log("  │     📍 " .. r.path)
        local nome = r.nome:lower()
        if nome:find("get") or nome:find("fetch") or nome:find("check") then
            log("  │     🔸 Função de consulta. Args: talvez playerId")
        elseif nome:find("inventory") or nome:find("stats") then
            log("  │     🔸 Retorna dados do inventário/stats")
        else
            log("  │     🔸 Use Remote Spy pra ver args e retorno")
        end
    end
else
    log("  │   Nenhum RemoteFunction encontrado.")
end
log("  └──────────────────────────────────────────────────────┘")
log("")

-- ====== 6. ECONOMIA / TRADES ======
log("╔══════════════════════════════════════════════════════════════╗")
log("║  6. ECONOMIA / TRADES / ITENS                               ║")
log("╚══════════════════════════════════════════════════════════════╝")
log("")

local ecoKeywords = {
    "trade", "troca", "negocia", "exchange",
    "economy", "economia",
    "shop", "loja", "store", "venda", "sell", "buy", "compra",
    "market", "mercado", "marketplace",
    "inventory", "inventario", "backpack", "mochila",
    "currency", "moeda", "coin", "money", "dinheiro", "gold", "ouro", "cash", "robux",
    "wallet", "carteira", "balance", "saldo",
    "bank", "banco", "deposit", "depositar", "withdraw", "sacar",
    "price", "preco", "value", "valor", "cost", "custo",
    "item", "items", "collect", "coletar", "reward", "recompensa",
    "daily", "diario", "claim",
    "auction", "leilao", "bid", "lance",
    "guild", "clan", "gang",
    "upgrade", "melhoria", "rank", "nivel", "level",
    "premium", "vip", "pass", "passe",
    "crate", "caixa", "box", "key", "chave",
    "pet", "montaria", "mount", "vehicle", "veiculo",
}

local ecoItems = {}

local function scanEconomia(container, depth)
    if depth > 6 then return end
    for _, obj in ipairs(container:GetChildren()) do
        local name = obj.Name:lower()
        for _, kw in ipairs(ecoKeywords) do
            if name:find(kw, 1, true) then
                table.insert(ecoItems, {
                    nome = obj.Name,
                    classe = obj.ClassName,
                    path = obj:GetFullName(),
                })
                break
            end
        end
        if obj:IsA("Folder") or obj:IsA("ModuleScript") or obj:IsA("Configuration") then
            scanEconomia(obj, depth + 1)
        end
    end
end

scanEconomia(ReplicatedStorage, 0)
scanEconomia(game:GetService("ServerScriptService"), 0)
scanEconomia(game:GetService("ServerStorage"), 0)
scanEconomia(game:GetService("Workspace"), 0)

if #ecoItems > 0 then
    log("  Objetos relacionados à economia/trades: " .. #ecoItems)
    log("")
    for i, e in ipairs(ecoItems) do
        log(string.format("  %3d. [%s] %s", i, e.classe, e.nome))
        log("       📍 " .. e.path)
    end
else
    log("  Nenhum objeto de economia identificado pelos keywords.")
    log("  Dica: Use Dex Explorer pra buscar manualmente 'Coin', 'Shop' etc.")
end
log("")

-- ====== 7. HIERARQUIA DO REPLICATEDSTORAGE ======
log("╔══════════════════════════════════════════════════════════════╗")
log("║  7. HIERARQUIA DO REPLICATEDSTORAGE                         ║")
log("╚══════════════════════════════════════════════════════════════╝")
log("")

local function mapTree(container, depth, indent)
    if depth > 5 then return end
    for _, obj in ipairs(container:GetChildren()) do
        local icon = "📁"
        if obj:IsA("RemoteEvent") then icon = "📡"
        elseif obj:IsA("RemoteFunction") then icon = "🔧"
        elseif obj:IsA("Script") then icon = "⚙️"
        elseif obj:IsA("LocalScript") then icon = "🖥️"
        elseif obj:IsA("ModuleScript") then icon = "📦"
        elseif obj:IsA("Folder") then icon = "📂"
        elseif obj:IsA("Model") then icon = "🏗️"
        elseif obj:IsA("ScreenGui") then icon = "🖥️"
        elseif obj:IsA("Tool") then icon = "🔫"
        elseif obj:IsA("Sound") then icon = "🔊"
        elseif obj:IsA("StringValue") then icon = "🔤"
        elseif obj:IsA("NumberValue") or obj:IsA("IntValue") then icon = "🔢"
        elseif obj:IsA("BoolValue") then icon = "✅"
        elseif obj:IsA("ObjectValue") then icon = "🎯"
        elseif obj:IsA("Color3Value") then icon = "🎨"
        elseif obj:IsA("CFrameValue") then icon = "📍"
        elseif obj:IsA("Animation") or obj:IsA("Animator") then icon = "💃"
        end
        
        local prefix = string.rep("  ", indent)
        log("  " .. prefix .. icon .. " " .. obj.Name .. " [" .. obj.ClassName .. "]")
        
        if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("Configuration") then
            mapTree(obj, depth + 1, indent + 1)
        end
    end
end

mapTree(ReplicatedStorage, 0, 0)
log("")

-- ====== 8. TEMPLATES DE EXPLOIT ======
log("╔══════════════════════════════════════════════════════════════╗")
log("║  8. EXPLOIT TEMPLATES PRONTOS PRA COPIAR E COLAR            ║")
log("╚══════════════════════════════════════════════════════════════╝")
log("")

if totalRemotes > 0 then
    log("  ── RemoteEvents ──")
    log("")
    for _, r in ipairs(remotes.RemoteEvent) do
        log(string.format([[
  -- %s
  -- Path: %s
  local args = {
      [1] = "", -- PREENCHA OS ARGUMENTOS
      [2] = "",
  }
  local remote = game:GetService("ReplicatedStorage"):FindFirstChild("%s", true)
  if remote and remote:IsA("RemoteEvent") then
      remote:FireServer(unpack(args))
      print("✅ Fired: %s")
  else
      warn("❌ Remote nao encontrado: %s")
  end
]], r.nome, r.path, r.nome, r.nome, r.nome))
    end
    
    log("  ── RemoteFunctions ──")
    log("")
    for _, r in ipairs(remotes.RemoteFunction) do
        log(string.format([[
  -- %s
  -- Path: %s
  local args = {
      [1] = "", -- PREENCHA OS ARGUMENTOS
  }
  local remote = game:GetService("ReplicatedStorage"):FindFirstChild("%s", true)
  if remote and remote:IsA("RemoteFunction") then
      local result = remote:InvokeServer(unpack(args))
      print("✅ Resultado:", result)
  else
      warn("❌ RemoteFunction nao encontrado: %s")
  end
]], r.nome, r.path, r.nome, r.nome))
    end
else
    log("  Nenhum remote encontrado para gerar templates.")
end
log("")

-- ====== FINALIZAÇÃO ======
log("╔══════════════════════════════════════════════════════════════╗")
log("║        ✅ ANÁLISE CONCLUÍDA COM SUCESSO!                    ║")
log("╠══════════════════════════════════════════════════════════════╣")
log(string.format("║  📡 Remotes:              %-37d ║", totalRemotes))
log(string.format("║  📜 Scripts:              %-37d ║", totalScripts))
log(string.format("║  📦 ModuleScripts:        %-37d ║", #scripts.ModuleScript))
log(string.format("║  🖥️  LocalScripts:         %-37d ║", #scripts.LocalScript))
log(string.format("║  ⚙️  Scripts (server):     %-37d ║", #scripts.Script))
log(string.format("║  💰 Economia/Trades:      %-37d ║", #ecoItems))
log(string.format("║  👥 Jogadores:            %-37d ║", #jogadores))
log(string.format("║  🏳️  Times:                %-37d ║", #times))
log("╠══════════════════════════════════════════════════════════════╣")
log("║  🔒 READ-ONLY - Nenhum remote foi executado                ║")
log("╚══════════════════════════════════════════════════════════════╝")
log("")

-- Tenta salvar
local salvou = salvarArquivo()
if salvou then
    log("✅ Arquivo salvo com sucesso: " .. fileName)
    log("📁 Localização: Pasta do Delta (workspace/)")
    notify("HackerAI Analyzer", "Análise salva em: " .. fileName, 5)
else
    log("❌ Erro ao salvar arquivo. Mas o relatório está no console acima.")
    log("   Selecione tudo (Ctrl+A) e copie (Ctrl+C) manualmente.")
    notify("HackerAI Analyzer", "Erro ao salvar. Copie manualmente do console.", 4)
end

log("")
log("📋 INSTRUÇÕES:")
log("   1. No Delta Executor, abra o console (F2 ou botão ☰ > Console)")
log("   2. O relatório completo está acima")
if salvou then
    log("   3. O arquivo '" .. fileName .. "' foi salvo na pasta workspace do Delta")
    log("   4. No Android: Internal Storage > delta > workspace > " .. fileName)
    log("   5. No PC: Pasta de instalação do Delta > workspace > " .. fileName)
end
log("")
