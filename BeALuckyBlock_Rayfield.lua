-- ============================================
--   Be a Lucky Block - Script Rayfield
--   Compatível com Delta Executor
-- ============================================

local ok, err = pcall(function()

-- ── Rayfield ────────────────────────────────
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ── Serviços ────────────────────────────────
local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService      = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local LP              = Players.LocalPlayer

-- ── Remotes (busca robusta) ──────────────────
local function getRemote(name)
    return ReplicatedStorage:FindFirstChild(name, true)
end

local R_OpenLuckyBlock  = getRemote("OpenLuckyBlock")
local R_Smack           = getRemote("Smack")
local R_Collected       = getRemote("Collected")
local R_Pickup          = getRemote("Pickup")
local R_Rebirth         = getRemote("Rebirth")
local R_SellAll         = getRemote("SellAllBrainrots")
local R_SellOne         = getRemote("SellBrainrot")
local R_BuyGear         = getRemote("BuyGear")
local R_Equip           = getRemote("Equip")
local R_BuySkin         = getRemote("BuySkin")
local R_EquipSkin       = getRemote("EquipSkin")
local R_RedeemCode      = getRemote("RedeemCode")
local R_Upgrade         = getRemote("Upgrade")
local R_ChangeSetting   = getRemote("ChangeSetting")
local R_DropAll         = getRemote("DropAll")
local R_CollectOffline  = getRemote("CollectOfflineCash")
local R_UpgradeBrainrot = getRemote("UpgradeBrainrot")

-- ── Utilitário de invoke/fire ────────────────
local function callRemote(remote, ...)
    if not remote then return nil end
    local s, r = pcall(function(...)
        if remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        else
            remote:FireServer(...)
        end
    end, ...)
    return s and r or nil
end

-- ── Abreviação de números ────────────────────
local suffixes = {"","K","M","B","T","Qd","Qt","Sx","Sp","Oc","No","Dc"}
local function abbrev(n)
    n = tonumber(n) or 0
    local neg = n < 0
    n = math.abs(n)
    local i = 1
    while n >= 1000 and i < #suffixes do
        n = n / 1000
        i = i + 1
    end
    local s = (math.floor(n * 10) / 10)
    return (neg and "-" or "") .. tostring(s) .. suffixes[i]
end

-- ── Estado ───────────────────────────────────
local State = {
    AutoSmack      = false,
    AutoSmackSpeed = 0.1,
    AutoPickup     = false,
    AutoSellAll    = false,
    AutoSellDelay  = 5,
    AntiAFK        = false,
    WalkSpeed      = 16,
    JumpPower      = 50,
    InfJump        = false,
    InfJumpConn    = nil,
    NoClip         = false,
    SmackCount     = 0,
    PickupCount    = 0,
    SellCount      = 0,
    GodMode        = false,
}

-- ── Reaplicar stats no respawn ───────────────
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed  = State.WalkSpeed
        hum.JumpPower  = State.JumpPower
        if State.GodMode then hum.MaxHealth = math.huge; hum.Health = math.huge end
    end
end)

-- ────────────────────────────────────────────
--  JANELA
-- ────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name            = "Be a Lucky Block",
    Icon            = 0,
    LoadingTitle    = "Be a Lucky Block",
    LoadingSubtitle = "Delta Executor",
    Theme           = "Default",
    DisableRayfieldPrompts     = false,
    DisableBuildWarnings       = false,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "LuckyBlockScript",
        FileName   = "Config",
    },
    KeySystem = false,
})

-- ════════════════════════════════════════════
--  ABA 1 – AUTO FARM
-- ════════════════════════════════════════════
local FarmTab = Window:CreateTab("⛏️ Auto Farm", 4483362458)

FarmTab:CreateSection("Auto Smack (Lucky Block)")

FarmTab:CreateToggle({
    Name         = "Auto Smack",
    CurrentValue = false,
    Flag         = "AutoSmack",
    Callback     = function(v)
        State.AutoSmack = v
        if v then
            task.spawn(function()
                while State.AutoSmack do
                    -- Tenta smack em todos os lucky blocks do workspace
                    local ws = workspace
                    local found = false
                    for _, obj in pairs(ws:GetDescendants()) do
                        if obj:IsA("BasePart") and
                           (obj.Name:find("LuckyBlock") or obj.Name:find("Lucky") or obj.Name:find("Block")) and
                           obj.Parent and obj.Parent ~= LP.Character then
                            callRemote(R_Smack, obj)
                            found = true
                        end
                    end
                    -- Também tenta via OpenLuckyBlock genérico
                    if not found then
                        callRemote(R_OpenLuckyBlock)
                    end
                    State.SmackCount = State.SmackCount + 1
                    task.wait(State.AutoSmackSpeed)
                end
            end)
        end
    end,
})

FarmTab:CreateSlider({
    Name         = "Delay do Smack (s)",
    Range        = {0.05, 2},
    Increment    = 0.05,
    Suffix       = "s",
    CurrentValue = 0.1,
    Flag         = "SmackDelay",
    Callback     = function(v) State.AutoSmackSpeed = v end,
})

FarmTab:CreateSection("Auto Pickup (Brainrots)")

FarmTab:CreateToggle({
    Name         = "Auto Pickup",
    CurrentValue = false,
    Flag         = "AutoPickup",
    Callback     = function(v)
        State.AutoPickup = v
        if v then
            task.spawn(function()
                while State.AutoPickup do
                    -- Pega todos os pickable brainrots
                    local container = workspace:FindFirstChild("PickableBrainrots")
                    if container then
                        for _, brainrot in pairs(container:GetChildren()) do
                            if brainrot:IsA("Model") then
                                callRemote(R_Pickup, brainrot)
                                State.PickupCount = State.PickupCount + 1
                                task.wait(0.05)
                            end
                        end
                    end
                    -- Também tenta Collected genérico
                    callRemote(R_Collected)
                    task.wait(0.3)
                end
            end)
        end
    end,
})

FarmTab:CreateSection("Auto Sell")

FarmTab:CreateToggle({
    Name         = "Auto Sell All Brainrots",
    CurrentValue = false,
    Flag         = "AutoSell",
    Callback     = function(v)
        State.AutoSellAll = v
        if v then
            task.spawn(function()
                while State.AutoSellAll do
                    callRemote(R_SellAll)
                    State.SellCount = State.SellCount + 1
                    task.wait(State.AutoSellDelay)
                end
            end)
        end
    end,
})

FarmTab:CreateSlider({
    Name         = "Intervalo de Sell (s)",
    Range        = {1, 30},
    Increment    = 1,
    Suffix       = "s",
    CurrentValue = 5,
    Flag         = "SellDelay",
    Callback     = function(v) State.AutoSellDelay = v end,
})

FarmTab:CreateButton({
    Name     = "Vender Tudo Agora",
    Callback = function()
        callRemote(R_SellAll)
        Rayfield:Notify({ Title = "Vendido!", Content = "Todos os brainrots foram vendidos.", Duration = 3 })
    end,
})

FarmTab:CreateButton({
    Name     = "Coletar Cash Offline",
    Callback = function()
        callRemote(R_CollectOffline)
        Rayfield:Notify({ Title = "Cash Coletado", Content = "Cash offline coletado!", Duration = 3 })
    end,
})

FarmTab:CreateSection("Estatísticas da Sessão")

local lblSmack   = FarmTab:CreateLabel("Smacks: 0")
local lblPickup  = FarmTab:CreateLabel("Pickups: 0")
local lblSell    = FarmTab:CreateLabel("Vendas: 0")
local lblCash    = FarmTab:CreateLabel("Cash: –")

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            lblSmack:Set("Smacks nesta sessão: "  .. tostring(State.SmackCount))
            lblPickup:Set("Pickups nesta sessão: " .. tostring(State.PickupCount))
            lblSell:Set("Vendas nesta sessão: "   .. tostring(State.SellCount))
            -- Tentar ler cash do leaderstats ou atributo
            local ls = LP:FindFirstChild("leaderstats")
            if ls then
                local cash = ls:FindFirstChild("Cash") or ls:FindFirstChild("Coins") or ls:FindFirstChild("Gold")
                if cash then
                    lblCash:Set("💰 Cash: " .. abbrev(cash.Value))
                end
            end
        end)
    end
end)

-- ════════════════════════════════════════════
--  ABA 2 – PLAYER
-- ════════════════════════════════════════════
local PlayerTab = Window:CreateTab("⚡ Player", 4483362458)

PlayerTab:CreateSection("Movimento")

PlayerTab:CreateSlider({
    Name = "Walk Speed", Range = {16, 500}, Increment = 1,
    Suffix = "", CurrentValue = 16, Flag = "WalkSpeed",
    Callback = function(v)
        State.WalkSpeed = v
        local c = LP.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = v end
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power", Range = {50, 1000}, Increment = 10,
    Suffix = "", CurrentValue = 50, Flag = "JumpPower",
    Callback = function(v)
        State.JumpPower = v
        local c = LP.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h.JumpPower = v; h.JumpHeight = v / 10 end
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false, Flag = "InfJump",
    Callback = function(v)
        State.InfJump = v
        if v then
            State.InfJumpConn = UserInputService.JumpRequest:Connect(function()
                local c = LP.Character
                if c then
                    local h = c:FindFirstChildOfClass("Humanoid")
                    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        else
            if State.InfJumpConn then State.InfJumpConn:Disconnect(); State.InfJumpConn = nil end
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "No Clip", CurrentValue = false, Flag = "NoClip",
    Callback = function(v)
        State.NoClip = v
        if v then
            RunService.Stepped:Connect(function()
                if not State.NoClip then return end
                local c = LP.Character
                if c then
                    for _, p in pairs(c:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "God Mode (HP Infinito - local)", CurrentValue = false, Flag = "GodMode",
    Callback = function(v)
        State.GodMode = v
        local c = LP.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then
                if v then h.MaxHealth = math.huge; h.Health = math.huge
                else h.MaxHealth = 100; h.Health = 100 end
            end
        end
    end,
})

PlayerTab:CreateSection("Anti-AFK")

PlayerTab:CreateToggle({
    Name = "Anti-AFK", CurrentValue = false, Flag = "AntiAFK",
    Callback = function(v)
        State.AntiAFK = v
        if v then
            task.spawn(function()
                while State.AntiAFK do
                    task.wait(55)
                    if State.AntiAFK then
                        local vji = game:GetService("VirtualInputManager")
                        pcall(function() vji:SendKeyEvent(true,"W",false,game) end)
                        task.wait(0.1)
                        pcall(function() vji:SendKeyEvent(false,"W",false,game) end)
                    end
                end
            end)
        end
    end,
})

PlayerTab:CreateButton({
    Name = "Teleportar ao Plot",
    Callback = function()
        callRemote(getRemote("GetMyPlotId"))
        local pid = callRemote(getRemote("GetMyPlotId"))
        if pid then
            callRemote(getRemote("TeleportToPlot"), pid)
            Rayfield:Notify({ Title = "Teleporte", Content = "Teleportando ao seu plot!", Duration = 3 })
        else
            Rayfield:Notify({ Title = "Aviso", Content = "Não foi possível encontrar o plot.", Duration = 3 })
        end
    end,
})

-- ════════════════════════════════════════════
--  ABA 3 – SKINS / MUTAÇÕES
-- ════════════════════════════════════════════
local SkinsTab = Window:CreateTab("🎭 Skins", 4483362458)

SkinsTab:CreateSection("Equipar Skin de Lucky Block")

local skinIds = {
    "default","fairy_luckyblock","freezy_luckyblock","lava_luckyblock",
    "gliched_luckyblock","void_luckyblock","cyborg_luckyblock",
    "divine_luckyblock","inferno_luckyblock","colossus _luckyblock",
    "mogging_luckyblock","prestige_luckyblock","spirit_luckyblock",
}
local skinNames = {
    "Player Skin","Fairy Block","Freezy Block","Lava Block",
    "Gliched Block","Void Block","Cyborg Block",
    "Divine Block","Inferno Block","COLOSSUS BLOCK",
    "Mogging Block","Prestige Mogging Block","Spirit Lucky Block",
}

SkinsTab:CreateDropdown({
    Name    = "Selecionar Skin",
    Options = skinNames,
    CurrentOption = {"Player Skin"},
    Flag    = "SelectedSkin",
    Callback = function(opt)
        local chosen = (type(opt) == "table") and opt[1] or opt
        local id = "default"
        for i, n in ipairs(skinNames) do
            if n == chosen then id = skinIds[i]; break end
        end
        local result = callRemote(R_EquipSkin, id)
        Rayfield:Notify({
            Title   = "Skin",
            Content = "Tentando equipar: " .. chosen,
            Duration = 3,
        })
    end,
})

SkinsTab:CreateButton({
    Name = "Comprar Skin Selecionada",
    Callback = function()
        local chosen = Rayfield.Flags["SelectedSkin"]
        if not chosen then return end
        local id = "default"
        local name = (type(chosen) == "table") and chosen[1] or chosen
        for i, n in ipairs(skinNames) do
            if n == name then id = skinIds[i]; break end
        end
        callRemote(R_BuySkin, id)
        Rayfield:Notify({ Title = "Compra", Content = "Tentando comprar: " .. name, Duration = 3 })
    end,
})

-- ════════════════════════════════════════════
--  ABA 4 – BRAINROTS
-- ════════════════════════════════════════════
local BrainrotTab = Window:CreateTab("🧠 Brainrots", 4483362458)

BrainrotTab:CreateSection("Ações")

BrainrotTab:CreateButton({
    Name = "Vender Todos os Brainrots",
    Callback = function()
        callRemote(R_SellAll)
        Rayfield:Notify({ Title = "Vendido!", Content = "Todos os brainrots vendidos.", Duration = 3 })
    end,
})

BrainrotTab:CreateButton({
    Name = "Drop All Brainrots",
    Callback = function()
        callRemote(R_DropAll)
        Rayfield:Notify({ Title = "Drop", Content = "Todos os brainrots dropados.", Duration = 3 })
    end,
})

BrainrotTab:CreateSection("Upgrade de Brainrot")

local brainrotNamesList = {
    "Cacto Hipopotamo","Cocofanto Elefanto","Ballerina Cappuccina",
    "Gangster Foottera","Udin Din Din Dun","Brr Brr Patapim",
    "Capuccino Assassino","Gorillo Watermellondrillo","Trippi Troppi Troppa Trippa",
    "Raccooni Watermelunni","Ta Ta Ta Ta Sahur","Glorbo Frutodrillo",
    "Frigo Camello","Orangutini Ananassini","Ballerino Lololo",
    "Svinina Bombobardino","Frulli Frula","Tracoducotulu Delapeladustuz",
    "Ganganzelli Trulala","Orcalero Orcala","Lerulerulerule",
    "Cavallo Virtuoso","Rhino Toasterino","Te Te Te Te Sahur",
    "Mateo","Torrtuginni Dragonfrutinni","Los Tralaleritos",
    "Pot Hotspot","Los Crocodillitos","Chicleteira Bicicleteira",
    "La Vacca Saturno Saturnita","Las Vaquitas Saturnitas","Spaghetti Tualetti",
    "Tigrrullini Watermellini","Dragoni Cannelloni","Boneca Ambalabu",
    "Pipi Potato","Cathinni Sushinni","Graipus Medus",
    "Ti Ti Ti Sahur","Spioniro Golubiro","Salamino Penguino",
    "Karkirkur","Chachechi","Strawberry Elephant",
    "Tralalero Tralala","Meowl","Yoni","Burbaloni Luliloli",
    "Trulimero Trulicina","Agarrini Lapalini",
}
local brainrotIds = {
    "cacto_hipopotamo","cocofanto_elefanto","ballerina_cappuccina",
    "gangster_foottera","udin_din_din_dun","brr_brr_patapim",
    "capuccino_assassino","gorillo_watermellondrillo","trippi_troppi_troppa_trippa",
    "raccooni_watermelunni","ta_ta_ta_ta_sahur","glorbo_frutodrillo",
    "frigo_camello","orangutini_ananassini","ballerino_lololo",
    "svinina_bombobardino","frulli_frula","tracoducotulu_delapeladustuz",
    "ganganzelli_trulala","orcalero_orcala","lerulerulerule",
    "cavallo_virtuoso","rhino_toasterino","te_te_te_te_sahur",
    "mateo","torrtuginni_dragonfrutinni","los_tralaleritos",
    "pot_hotspot","los_crocodillitos","chicleteira_bicicleteira",
    "la_vacca_saturno_saturnita","las_vaquitas_saturnitas","spaghetti_tualetti",
    "tigrrullini_watermellini","dragoni_cannelloni","boneca_ambalabu",
    "pipi_potato","cathinni_sushinni","graipus_medus",
    "ti_ti_ti_sahur","spioniro_golubiro","salamino_penguinoo",
    "karkirkur","chachechi","strawberry_elephant",
    "tralalero_tralala","meowl","yoni","burbaloni_luliloli",
    "trulimero_trulicina","agarrini_lapalini",
}

BrainrotTab:CreateDropdown({
    Name    = "Brainrot para Upgrade",
    Options = brainrotNamesList,
    CurrentOption = {"Cacto Hipopotamo"},
    Flag    = "BrainrotUpgrade",
    Callback = function(opt) end, -- só armazena no flag
})

BrainrotTab:CreateButton({
    Name = "Fazer Upgrade do Brainrot Selecionado",
    Callback = function()
        local chosen = Rayfield.Flags["BrainrotUpgrade"]
        if not chosen then return end
        local name = (type(chosen) == "table") and chosen[1] or chosen
        local id = brainrotIds[1]
        for i, n in ipairs(brainrotNamesList) do
            if n == name then id = brainrotIds[i]; break end
        end
        callRemote(R_UpgradeBrainrot, id)
        Rayfield:Notify({ Title = "Upgrade", Content = "Upgrade enviado: " .. name, Duration = 3 })
    end,
})

-- ════════════════════════════════════════════
--  ABA 5 – PICKAXE / GEAR
-- ════════════════════════════════════════════
local GearTab = Window:CreateTab("⚒️ Pickaxe", 4483362458)

GearTab:CreateSection("Comprar / Equipar Pickaxe")

local pickaxeNames = {
    "Wooden Pickaxe","Stone Pickaxe","Golden Pickaxe","Ice Pickaxe",
    "Apocalypse Pickaxe","Mecha Pickaxe","Toy Pickaxe","Aqua Pickaxe",
    "Candy Pickaxe","Frost Pickaxe","Lava Pickaxe","Viking Pickaxe",
    "Radioactive Pickaxe","Rich Pickaxe","Diamond Pickaxe","Void Pickaxe",
    "Magma Pickaxe","Kingcold Pickaxe","Cosmic Pickaxe","Galaxy Pickaxe",
}
local pickaxeIds = {
    "Wooden_Pickaxe","Stone_Pickaxe","Golden_Pickaxe","Ice_Pickaxe",
    "Apocalypse_Pickaxe","Mecha_Pickaxe","Toy_Pickaxe","Aqua_Pickaxe",
    "Candy_Pickaxe","Frost_Pickaxe","Lava_Pickaxe","Viking_Pickaxe",
    "Radioactive_Pickaxe","Rich_Pickaxe","Diamond_Pickaxe","Void_Pickaxe",
    "Magma_Pickaxe","Kingcold_Pickaxe","Cosmic_Pickaxe","Galaxy_Pickaxe",
}
local pickaxeDmg = {
    1,2,5,25,100,400,1500,6000,25000,100000,400000,1750000,
    7000000,30000000,150000000,600000000,2500000000,12500000000,65000000000,1000000,
}

GearTab:CreateDropdown({
    Name    = "Selecionar Pickaxe",
    Options = pickaxeNames,
    CurrentOption = {"Wooden Pickaxe"},
    Flag    = "SelectedPickaxe",
    Callback = function(opt)
        local name = (type(opt) == "table") and opt[1] or opt
        local id, dmg = pickaxeIds[1], pickaxeDmg[1]
        for i, n in ipairs(pickaxeNames) do
            if n == name then id = pickaxeIds[i]; dmg = pickaxeDmg[i]; break end
        end
        Rayfield:Notify({
            Title   = "Pickaxe: " .. name,
            Content = "Dano: " .. abbrev(dmg),
            Duration = 3,
        })
    end,
})

GearTab:CreateButton({
    Name = "Comprar Pickaxe Selecionada",
    Callback = function()
        local chosen = Rayfield.Flags["SelectedPickaxe"]
        if not chosen then return end
        local name = (type(chosen) == "table") and chosen[1] or chosen
        local id = pickaxeIds[1]
        for i, n in ipairs(pickaxeNames) do
            if n == name then id = pickaxeIds[i]; break end
        end
        callRemote(R_BuyGear, id)
        Rayfield:Notify({ Title = "Compra", Content = "Tentando comprar: " .. name, Duration = 3 })
    end,
})

GearTab:CreateButton({
    Name = "Equipar Pickaxe Selecionada",
    Callback = function()
        local chosen = Rayfield.Flags["SelectedPickaxe"]
        if not chosen then return end
        local name = (type(chosen) == "table") and chosen[1] or chosen
        local id = pickaxeIds[1]
        for i, n in ipairs(pickaxeNames) do
            if n == name then id = pickaxeIds[i]; break end
        end
        callRemote(R_Equip, id)
        Rayfield:Notify({ Title = "Equipado", Content = name .. " equipada!", Duration = 3 })
    end,
})

GearTab:CreateSection("Speed Upgrade")

GearTab:CreateButton({
    Name = "Upgrade de Velocidade (x1)",
    Callback = function()
        callRemote(R_Upgrade, "MovementSpeed", 1)
        Rayfield:Notify({ Title = "Upgrade", Content = "+1 nível de velocidade enviado.", Duration = 3 })
    end,
})

GearTab:CreateButton({
    Name = "Upgrade de Velocidade (x10)",
    Callback = function()
        for i = 1, 10 do
            callRemote(R_Upgrade, "MovementSpeed", 1)
            task.wait(0.15)
        end
        Rayfield:Notify({ Title = "Upgrade", Content = "+10 níveis de velocidade enviados.", Duration = 3 })
    end,
})

-- ════════════════════════════════════════════
--  ABA 6 – CODES & MISC
-- ════════════════════════════════════════════
local MiscTab = Window:CreateTab("🔧 Misc", 4483362458)

MiscTab:CreateSection("Códigos")

-- Codes conhecidos — adiciona os teus próprios abaixo
local knownCodes = {
    "BRAINROT","LUCKY","LUCKBLOCK","RELEASE","FREE","UPDATE",
    "BRRRPATAPIM","TRALALERO","COCOFANTO","PATAPIM",
}

MiscTab:CreateDropdown({
    Name    = "Código Salvo",
    Options = knownCodes,
    CurrentOption = {knownCodes[1]},
    Flag    = "SavedCode",
    Callback = function(opt) end,
})

MiscTab:CreateButton({
    Name = "Resgatar Código Salvo",
    Callback = function()
        local chosen = Rayfield.Flags["SavedCode"]
        if not chosen then return end
        local code = (type(chosen) == "table") and chosen[1] or chosen
        local result = callRemote(R_RedeemCode, code)
        Rayfield:Notify({
            Title   = "Código",
            Content = "Resgatando: " .. code .. (result and "\n✅ Sucesso!" or "\n⚠️ Resposta do servidor recebida."),
            Duration = 5,
        })
    end,
})

MiscTab:CreateSection("Rebirth")

MiscTab:CreateButton({
    Name = "⚠️ Fazer Rebirth (CUIDADO)",
    Callback = function()
        callRemote(R_Rebirth)
        Rayfield:Notify({ Title = "Rebirth", Content = "Rebirth enviado ao servidor!", Duration = 4 })
    end,
})

MiscTab:CreateSection("Visual / UI")

MiscTab:CreateToggle({
    Name = "Esconder UI do Jogo",
    CurrentValue = false,
    Flag = "HideUI",
    Callback = function(v)
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then
            for _, g in pairs(pg:GetChildren()) do
                if g:IsA("ScreenGui") and g.Name ~= "RayfieldUI" then
                    g.Enabled = not v
                end
            end
        end
    end,
})

MiscTab:CreateSlider({
    Name = "FPS Cap", Range = {15, 240}, Increment = 5,
    Suffix = " FPS", CurrentValue = 60, Flag = "FPSCap",
    Callback = function(v)
        pcall(function() setfpscap(v) end)
    end,
})

MiscTab:CreateSection("Info")

MiscTab:CreateButton({
    Name = "Ver Remotes do Jogo",
    Callback = function()
        local list = {}
        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                table.insert(list, v.Name)
            end
        end
        Rayfield:Notify({
            Title   = "Remotes (" .. #list .. " encontrados)",
            Content = table.concat(list, ", "):sub(1, 280),
            Duration = 8,
        })
    end,
})

-- ── Boas-vindas ──────────────────────────────
task.wait(1.5)
Rayfield:Notify({
    Title   = "✅ Script Carregado!",
    Content = "Be a Lucky Block Script ativo!\nBem-vindo, " .. LP.DisplayName .. "!",
    Duration = 5,
})

end)

if not ok then
    warn("[LuckyBlock Script] Erro ao carregar: " .. tostring(err))
end
