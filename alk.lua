--[[
  ═══════════════════════════════════════════════════
  🔞 R63 SKIN SYSTEM + CUSTOM EMOTES (CLIENT-SIDE)
  ═══════════════════════════════════════════════════
  • 3 skins completas com acessórios
  • Acessórios criados por script (sem depender de IDs externos)
  • Animações custom via Motor6D (sem ID público)
  • Tecla R pra tirar/mostrar roupa
  • Botões no topo da tela (PC) + automático no mobile
  • Tudo client-side — ninguém vê nada
  ═══════════════════════════════════════════════════
]]

-- ─── Serviços ───
local player = game:GetService("Players").LocalPlayer
local userInput = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local context = game:GetService("ContextActionService")

-- ─── Variáveis globais ───
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local currentSkin = 1          -- 1, 2 ou 3
local clothesVisible = true
local currentEmote = nil
local emoteRunning = false
local physicsRunning = false
local skinAccessories = {}     -- guarda os acessórios criados
local clothingObjects = {}     -- guarda shirt/pants criados

-- ═══════════════════════════════════════════════════
--  CONFIGURAÇÃO DAS SKINS
-- ═══════════════════════════════════════════════════

local SKINS = {
    -- ─── SKIN 1: Neko Gata (Escolar / Fofa) ───
    [1] = {
        name = "Neko Gata",
        skinColor = "Light reddish brown",
        bodyScale = 0.7,
        widthScale = 0.6,
        headScale = 0.95,
        shirtColor = Color3.fromRGB(255, 230, 240),  -- rosa claro
        pantsColor = Color3.fromRGB(50, 50, 60),      -- cinza escuro
        accessories = {
            { type = "catEars",   color = Color3.fromRGB(255, 200, 210), size = 1.0 },
            { type = "catTail",   color = Color3.fromRGB(255, 200, 210), size = 1.0 },
            { type = "choker",    color = Color3.fromRGB(255, 100, 150), size = 1.0 },
            { type = "skirtPart", color = Color3.fromRGB(50, 50, 60),    size = 1.0 },
        }
    },
    
    -- ─── SKIN 2: Maid Sensual ───
    [2] = {
        name = "Maid",
        skinColor = "Pastel light blue",
        bodyScale = 0.65,
        widthScale = 0.55,
        headScale = 0.92,
        shirtColor = Color3.fromRGB(40, 40, 50),
        pantsColor = Color3.fromRGB(25, 25, 35),
        accessories = {
            { type = "maidHeadband", color = Color3.fromRGB(255, 255, 255), size = 1.0 },
            { type = "maidApron",    color = Color3.fromRGB(255, 255, 255), size = 1.0 },
            { type = "choker",       color = Color3.fromRGB(200, 50, 80),   size = 1.0 },
            { type = "skirtPart",    color = Color3.fromRGB(25, 25, 35),    size = 1.0 },
        }
    },
    
    -- ─── SKIN 3: Bunny (coelha) ───
    [3] = {
        name = "Bunny",
        skinColor = "Light stone grey",
        bodyScale = 0.68,
        widthScale = 0.58,
        headScale = 0.97,
        shirtColor = Color3.fromRGB(255, 200, 220),
        pantsColor = Color3.fromRGB(255, 180, 200),
        accessories = {
            { type = "bunnyEars",  color = Color3.fromRGB(255, 220, 230), size = 1.0 },
            { type = "bunnyTail",  color = Color3.fromRGB(255, 255, 255), size = 1.0 },
            { type = "choker",     color = Color3.fromRGB(200, 100, 150), size = 1.0 },
            { type = "skirtPart",  color = Color3.fromRGB(255, 180, 200), size = 1.0 },
        }
    }
}

-- ═══════════════════════════════════════════════════
--  SISTEMA DE ACESSÓRIOS (criados por script)
-- ═══════════════════════════════════════════════════

local function createAttachment(part, cfOffset)
    local att = Instance.new("Attachment")
    att.Parent = part
    if cfOffset then att.CFrame = cfOffset end
    return att
end

local function weldPartTo(part, target, cfOffset)
    local weld = Instance.new("Weld")
    weld.Part0 = target
    weld.Part1 = part
    weld.C0 = cfOffset or CFrame.new()
    weld.Parent = part
    return weld
end

-- Cria orelhas de gato
local function createCatEars(color, scale)
    local head = char:FindFirstChild("Head")
    if not head then return nil end
    
    local earL = Instance.new("WedgePart")
    earL.Name = "CatEar_Left"
    earL.Size = Vector3.new(1.2 * scale, 1.8 * scale, 1.2 * scale)
    earL.Color = color
    earL.Material = Enum.Material.SmoothPlastic
    earL.BrickColor = BrickColor.new(color)
    earL.TopSurface = Enum.SurfaceType.Smooth
    earL.BottomSurface = Enum.SurfaceType.Smooth
    earL.Anchored = false
    earL.CanCollide = false
    earL.Parent = char
    
    local earR = earL:Clone()
    earR.Name = "CatEar_Right"
    earR.Parent = char
    
    weldPartTo(earL, head, CFrame.new(-0.6 * scale, 0.55 * scale, -0.05) * CFrame.Angles(0, 0, math.rad(-15)))
    weldPartTo(earR, head, CFrame.new(0.6 * scale, 0.55 * scale, -0.05) * CFrame.Angles(0, 0, math.rad(15)))
    
    -- Parte interna da orelha (rosa)
    local innerL = Instance.new("WedgePart")
    innerL.Name = "CatEarInner_Left"
    innerL.Size = Vector3.new(0.6 * scale, 1.0 * scale, 0.6 * scale)
    innerL.Color = Color3.fromRGB(255, 180, 200)
    innerL.Material = Enum.Material.SmoothPlastic
    innerL.TopSurface = Enum.SurfaceType.Smooth
    innerL.BottomSurface = Enum.SurfaceType.Smooth
    innerL.Anchored = false
    innerL.CanCollide = false
    innerL.Parent = char
    
    local innerR = innerL:Clone()
    innerR.Name = "CatEarInner_Right"
    innerR.Parent = char
    
    weldPartTo(innerL, head, CFrame.new(-0.6 * scale, 0.45 * scale, 0.05) * CFrame.Angles(0, 0, math.rad(-15)))
    weldPartTo(innerR, head, CFrame.new(0.6 * scale, 0.45 * scale, 0.05) * CFrame.Angles(0, 0, math.rad(15)))
    
    return {earL, earR, innerL, innerR}
end

-- Cria orelhas de coelho
local function createBunnyEars(color, scale)
    local head = char:FindFirstChild("Head")
    if not head then return nil end
    
    local parts = {}
    
    for _, side in ipairs({-1, 1}) do
        local earMain = Instance.new("Part")
        earMain.Name = "BunnyEar_" .. (side < 0 and "Left" or "Right")
        earMain.Size = Vector3.new(0.4 * scale, 2.5 * scale, 0.8 * scale)
        earMain.Color = color
        earMain.Material = Enum.Material.SmoothPlastic
        earMain.Shape = Enum.PartType.Cylinder
        earMain.TopSurface = Enum.SurfaceType.Smooth
        earMain.BottomSurface = Enum.SurfaceType.Smooth
        earMain.Anchored = false
        earMain.CanCollide = false
        earMain.Parent = char
        
        weldPartTo(earMain, head, CFrame.new(side * 0.5 * scale, 0.8 * scale, -0.08) * CFrame.Angles(math.rad(-10), 0, math.rad(side * 12)))
        table.insert(parts, earMain)
        
        -- Parte interna rosa
        local inner = Instance.new("Part")
        inner.Name = "BunnyEarInner_" .. (side < 0 and "Left" or "Right")
        inner.Size = Vector3.new(0.15 * scale, 1.8 * scale, 0.4 * scale)
        inner.Color = Color3.fromRGB(255, 200, 210)
        inner.Material = Enum.Material.SmoothPlastic
        inner.Shape = Enum.PartType.Cylinder
        inner.TopSurface = Enum.SurfaceType.Smooth
        inner.BottomSurface = Enum.SurfaceType.Smooth
        inner.Anchored = false
        inner.CanCollide = false
        inner.Parent = char
        
        weldPartTo(inner, head, CFrame.new(side * 0.5 * scale, 0.7 * scale, 0.05) * CFrame.Angles(math.rad(-10), 0, math.rad(side * 12)))
        table.insert(parts, inner)
    end
    
    return parts
end

-- Cria rabo de gato
local function createCatTail(color, scale)
    local torso = char:FindFirstChild("Torso")
    if not torso then return nil end
    
    local parts = {}
    
    -- Rabo: 3 segmentos
    for i = 1, 3 do
        local seg = Instance.new("Part")
        seg.Name = "CatTail_Seg" .. i
        seg.Size = Vector3.new(0.4 * scale, 0.6 * scale, 0.4 * scale)
        seg.Color = color
        seg.Material = Enum.Material.SmoothPlastic
        seg.Shape = Enum.PartType.Ball
        seg.TopSurface = Enum.SurfaceType.Smooth
        seg.BottomSurface = Enum.SurfaceType.Smooth
        seg.Anchored = false
        seg.CanCollide = false
        seg.Parent = char
        
        if i == 1 then
            weldPartTo(seg, torso, CFrame.new(0, -0.3 * scale, -0.5 * scale) * CFrame.Angles(math.rad(30), 0, 0))
        else
            -- Welds entre segmentos
            local w = Instance.new("Weld")
            w.Part0 = parts[i-1]
            w.Part1 = seg
            w.C0 = CFrame.new(0, -0.4 * scale, 0) * CFrame.Angles(math.rad(15 * i), 0, math.rad((-1)^i * 10))
            w.Parent = seg
        end
        
        table.insert(parts, seg)
    end
    
    return parts
end

-- Cria rabo de coelho
local function createBunnyTail(color, scale)
    local torso = char:FindFirstChild("Torso")
    if not torso then return nil end
    
    local tail = Instance.new("Part")
    tail.Name = "BunnyTail"
    tail.Size = Vector3.new(0.6 * scale, 0.6 * scale, 0.6 * scale)
    tail.Color = color
    tail.Material = Enum.Material.SmoothPlastic
    tail.Shape = Enum.PartType.Ball
    tail.Anchored = false
    tail.CanCollide = false
    tail.Parent = char
    
    weldPartTo(tail, torso, CFrame.new(0, -0.2 * scale, -0.55 * scale))
    
    return {tail}
end

-- Cria tiara de maid
local function createMaidHeadband(color, scale)
    local head = char:FindFirstChild("Head")
    if not head then return nil end
    
    local parts = {}
    
    -- Faixa branca
    local band = Instance.new("Part")
    band.Name = "MaidBand"
    band.Size = Vector3.new(1.0 * scale, 0.15 * scale, 0.4 * scale)
    band.Color = color
    band.Material = Enum.Material.SmoothPlastic
    band.Anchored = false
    band.CanCollide = false
    band.Parent = char
    
    weldPartTo(band, head, CFrame.new(0, 0.4 * scale, 0.15 * scale))
    table.insert(parts, band)
    
    -- Babados (3 partes em cima)
    for i = 1, 3 do
        local frill = Instance.new("Part")
        frill.Name = "MaidFrill" .. i
        frill.Size = Vector3.new(0.35 * scale, 0.25 * scale, 0.2 * scale)
        frill.Color = color
        frill.Material = Enum.Material.SmoothPlastic
        frill.Anchored = false
        frill.CanCollide = false
        frill.Parent = char
        
        local xOff = (i - 2) * 0.3 * scale
        weldPartTo(frill, head, CFrame.new(xOff, 0.55 * scale, 0.12 * scale) * CFrame.Angles(math.rad(20), 0, 0))
        table.insert(parts, frill)
    end
    
    return parts
end

-- Cria avental de maid
local function createMaidApron(color, scale)
    local torso = char:FindFirstChild("Torso")
    if not torso then return nil end
    
    local apron = Instance.new("Part")
    apron.Name = "MaidApron"
    apron.Size = Vector3.new(0.8 * scale, 1.0 * scale, 0.08 * scale)
    apron.Color = color
    apron.Material = Enum.Material.SmoothPlastic
    apron.Anchored = false
    apron.CanCollide = false
    apron.Transparency = 0.1
    apron.Parent = char
    
    weldPartTo(apron, torso, CFrame.new(0, -0.1 * scale, -0.55 * scale))
    
    return {apron}
end

-- Cria choker (colar)
local function createChoker(color, scale)
    local head = char:FindFirstChild("Head")
    if not head then return nil end
    
    local choker = Instance.new("Part")
    choker.Name = "Choker"
    choker.Size = Vector3.new(0.6 * scale, 0.15 * scale, 0.6 * scale)
    choker.Color = color
    choker.Material = Enum.Material.SmoothPlastic
    choker.Shape = Enum.PartType.Cylinder
    choker.Anchored = false
    choker.CanCollide = false
    choker.Parent = char
    
    weldPartTo(choker, head, CFrame.new(0, -0.25 * scale, 0))
    
    return {choker}
end

-- Cria saia (skirt) de partes
local function createSkirt(color, scale)
    local torso = char:FindFirstChild("Torso")
    if not torso then return nil end
    
    local parts = {}
    
    -- Saia frontal
    local skirtF = Instance.new("Part")
    skirtF.Name = "SkirtFront"
    skirtF.Size = Vector3.new(1.1 * scale, 0.6 * scale, 0.08 * scale)
    skirtF.Color = color
    skirtF.Material = Enum.Material.SmoothPlastic
    skirtF.Anchored = false
    skirtF.CanCollide = false
    skirtF.Transparency = 0.05
    skirtF.Parent = char
    
    weldPartTo(skirtF, torso, CFrame.new(0, -0.5 * scale, -0.5 * scale))
    table.insert(parts, skirtF)
    
    -- Saia traseira
    local skirtB = skirtF:Clone()
    skirtB.Name = "SkirtBack"
    skirtB.Parent = char
    local wB = Instance.new("Weld")
    wB.Part0 = torso
    wB.Part1 = skirtB
    wB.C0 = CFrame.new(0, -0.5 * scale, 0.5 * scale)
    wB.Parent = skirtB
    table.insert(parts, skirtB)
    
    -- Saia lateral esquerda
    local skirtL = skirtF:Clone()
    skirtL.Name = "SkirtLeft"
    skirtL.Size = Vector3.new(0.08 * scale, 0.6 * scale, 0.9 * scale)
    skirtL.Parent = char
    local wL = Instance.new("Weld")
    wL.Part0 = torso
    wL.Part1 = skirtL
    wL.C0 = CFrame.new(-0.55 * scale, -0.5 * scale, 0)
    wL.Parent = skirtL
    table.insert(parts, skirtL)
    
    -- Saia lateral direita
    local skirtR = skirtL:Clone()
    skirtR.Name = "SkirtRight"
    skirtR.Parent = char
    local wR = Instance.new("Weld")
    wR.Part0 = torso
    wR.Part1 = skirtR
    wR.C0 = CFrame.new(0.55 * scale, -0.5 * scale, 0)
    wR.Parent = skirtR
    table.insert(parts, skirtR)
    
    return parts
end

-- ═══════════════════════════════════════════════════
--  CONSTRUIR SKIN
-- ═══════════════════════════════════════════════════

local function clearAccessories()
    for _, obj in ipairs(skinAccessories) do
        if obj and obj.Parent then obj:Destroy() end
    end
    skinAccessories = {}
end

local function clearClothing()
    for _, obj in ipairs(clothingObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    clothingObjects = {}
    
    -- Remove shirt/pants antigos
    local oldShirt = char:FindFirstChildOfClass("Shirt")
    local oldPants = char:FindFirstChildOfClass("Pants")
    if oldShirt then oldShirt:Destroy() end
    if oldPants then oldPants:Destroy() end
end

local function buildSkin(skinId)
    clearAccessories()
    clearClothing()
    
    local config = SKINS[skinId]
    if not config then return end
    
    -- ─── Aplica R63 ───
    local desc = humanoid:GetAppliedDescription() or Instance.new("HumanoidDescription")
    desc.BodyTypeScale = config.bodyScale
    desc.HeadScale = config.headScale
    desc.WidthScale = config.widthScale
    desc.DepthScale = config.widthScale * 0.9
    desc.ProportionScale = 0.85
    
    local skinBrick = BrickColor.new(config.skinColor)
    desc.SkinColor = skinBrick
    desc.HeadColor = skinBrick
    desc.LeftArmColor = skinBrick
    desc.RightArmColor = skinBrick
    desc.LeftLegColor = skinBrick
    desc.RightLegColor = skinBrick
    desc.TorsoColor = BrickColor.new("Really black")
    
    humanoid:ApplyDescription(desc)
    
    -- ─── Cria roupa (Shirt + Pants) ───
    if clothesVisible then
        local shirt = Instance.new("Shirt")
        shirt.Name = "CustomShirt"
        shirt.ShirtTemplate = "rbxassetid://4829770436"  -- template branco
        shirt.Parent = char
        
        local pants = Instance.new("Pants")
        pants.Name = "CustomPants"
        pants.PantsTemplate = "rbxassetid://4829771451"  -- template branco
        pants.Parent = char
        
        clothingObjects = {shirt, pants}
    end
    
    -- ─── Cria acessórios ───
    for _, accConfig in ipairs(config.accessories) do
        local parts = nil
        
        if accConfig.type == "catEars" then
            parts = createCatEars(accConfig.color, accConfig.size)
        elseif accConfig.type == "bunnyEars" then
            parts = createBunnyEars(accConfig.color, accConfig.size)
        elseif accConfig.type == "catTail" then
            parts = createCatTail(accConfig.color, accConfig.size)
        elseif accConfig.type == "bunnyTail" then
            parts = createBunnyTail(accConfig.color, accConfig.size)
        elseif accConfig.type == "maidHeadband" then
            parts = createMaidHeadband(accConfig.color, accConfig.size)
        elseif accConfig.type == "maidApron" then
            parts = createMaidApron(accConfig.color, accConfig.size)
        elseif accConfig.type == "choker" then
            parts = createChoker(accConfig.color, accConfig.size)
        elseif accConfig.type == "skirtPart" then
            parts = createSkirt(accConfig.color, accConfig.size)
        end
        
        if parts then
            for _, p in ipairs(parts) do
                if p then table.insert(skinAccessories, p) end
            end
        end
    end
    
    print("[Skin] " .. config.name .. " carregada!")
end

-- ═══════════════════════════════════════════════════
--  EMOTES CUSTOM VIA Motor6D (sem ID público)
-- ═══════════════════════════════════════════════════

-- Pega os Motor6D do personagem
local function getJoints()
    local torso = char:FindFirstChild("Torso")
    if not torso then return nil end
    
    return {
        neck = torso:FindFirstChild("Neck"),
        waist = torso:FindFirstChild("Waist"),
        rShoulder = torso:FindFirstChild("Right Shoulder"),
        lShoulder = torso:FindFirstChild("Left Shoulder"),
        rHip = torso:FindFirstChild("Right Hip"),
        lHip = torso:FindFirstChild("Left Hip"),
    }
end

-- Salva posições originais dos Motor6D
local jointOrigins = {}
local function saveJointOrigins()
    local joints = getJoints()
    if not joints then return end
    
    for name, joint in pairs(joints) do
        if joint then
            jointOrigins[name] = joint.C0
        end
    end
end

-- Restaura posições originais
local function restoreJoints()
    for name, origin in pairs(jointOrigins) do
        local joints = getJoints()
        if joints and joints[name] then
            joints[name].C0 = origin
        end
    end
end

-- Sistema de animação via Motor6D
local emoteTick = 0
local currentEmoteData = nil
local emoteConnection = nil

local EMOTES_CUSTOM = {
    -- EMOTE 1: Twerk (rebolar)
    twerk = {
        loop = true,
        speed = 4,
        update = function(t)
            local s = math.sin(t * 8)
            local hipSway = s * 0.3
            local bodyBounce = math.sin(t * 16) * 0.1
            
            local joints = getJoints()
            if not joints then return end
            
            if joints.lHip then
                joints.lHip.C0 = jointOrigins.lHip * CFrame.Angles(-hipSway, 0, 0)
            end
            if joints.rHip then
                joints.rHip.C0 = jointOrigins.rHip * CFrame.Angles(hipSway, 0, 0)
            end
            if joints.neck then
                joints.neck.C0 = jointOrigins.neck * CFrame.Angles(bodyBounce, 0, 0)
            end
        end
    },
    
    -- EMOTE 2: Pose sensual (mão na cintura, quadril pra fora)
    pose1 = {
        loop = false,
        duration = 3,
        update = function(t)
            local progress = math.min(t / 1.5, 1)
            local ease = 1 - (1 - progress)^3  -- easeOutCubic
            
            local joints = getJoints()
            if not joints then return end
            
            if joints.lShoulder then
                joints.lShoulder.C0 = jointOrigins.lShoulder * CFrame.Angles(-0.5 * ease, 0.3 * ease, -0.8 * ease)
            end
            if joints.rHip then
                joints.rHip.C0 = jointOrigins.rHip * CFrame.Angles(0, 0, 0.2 * ease)
            end
            if joints.lHip then
                joints.lHip.C0 = jointOrigins.lHip * CFrame.Angles(0, 0, -0.15 * ease)
            end
            if joints.neck then
                joints.neck.C0 = jointOrigins.neck * CFrame.Angles(-0.1 * ease, 0.2 * ease, 0)
            end
        end
    },
    
    -- EMOTE 3: Beijo no ar (blow kiss)
    blowKiss = {
        loop = false,
        duration = 4,
        update = function(t)
            local progress = math.min(t / 2, 1)
            
            -- Primeiro leva a mão à boca, depois "sopra"
            local armPhase = math.min(t / 1, 1)
            local kissPhase = math.max(0, math.min((t - 1) / 0.5, 1))
            local extendPhase = math.max(0, math.min((t - 1.5) / 0.5, 1))
            
            local joints = getJoints()
            if not joints then return end
            
            if joints.rShoulder then
                -- Mão direita vai até a boca
                local armUp = CFrame.Angles(-1.5 * armPhase, -0.5 * armPhase, 0.3 * armPhase)
                -- Depois estende pra frente (soprando)
                local armExtend = CFrame.Angles(-1.5, -1.0 * extendPhase, 0.3)
                joints.rShoulder.C0 = jointOrigins.rShoulder * (extendPhase > 0 and armExtend or armUp)
            end
            if joints.neck then
                local headTilt = math.sin(t * 3) * 0.05 * kissPhase
                joints.neck.C0 = jointOrigins.neck * CFrame.Angles(-0.1, headTilt, 0)
            end
        end
    },
    
    -- EMOTE 4: Levantar a perna (sensual)
    legLift = {
        loop = false,
        duration = 3,
        update = function(t)
            local progress = math.min(t / 1.5, 1)
            local ease = 1 - (1 - progress)^2
            
            local joints = getJoints()
            if not joints then return end
            
            if joints.rHip then
                joints.rHip.C0 = jointOrigins.rHip * CFrame.Angles(0, -0.3 * ease, 0.6 * ease)
            end
            if joints.lHip then
                joints.lHip.C0 = jointOrigins.lHip * CFrame.Angles(0, 0.1 * ease, -0.1 * ease)
            end
            if joints.neck then
                joints.neck.C0 = jointOrigins.neck * CFrame.Angles(-0.05 * ease, 0, 0)
            end
            if joints.lShoulder then
                joints.lShoulder.C0 = jointOrigins.lShoulder * CFrame.Angles(0, 0, 0.2 * ease)
            end
        end
    },
    
    -- EMOTE 5: Dança lenta (body wave)
    slowDance = {
        loop = true,
        speed = 1.5,
        update = function(t)
            local s1 = math.sin(t * 3)
            local s2 = math.sin(t * 2.5 + 1)
            local s3 = math.sin(t * 2 + 2)
            
            local joints = getJoints()
            if not joints then return end
            
            if joints.neck then
                joints.neck.C0 = jointOrigins.neck * CFrame.Angles(-0.05 * s1, 0.1 * s2, 0.05 * s3)
            end
            if joints.rShoulder then
                joints.rShoulder.C0 = jointOrigins.rShoulder * CFrame.Angles(0.1 * s2, -0.05 * s3, 0.15 * s1)
            end
            if joints.lShoulder then
                joints.lShoulder.C0 = jointOrigins.lShoulder * CFrame.Angles(-0.1 * s2, 0.05 * s3, -0.15 * s1)
            end
            if joints.rHip then
                joints.rHip.C0 = jointOrigins.rHip * CFrame.Angles(-0.05 * s2, 0.03 * s1, 0.08 * s3)
            end
            if joints.lHip then
                joints.lHip.C0 = jointOrigins.lHip * CFrame.Angles(0.05 * s2, -0.03 * s1, -0.08 * s3)
            end
        end
    },
}

-- Lista de emotes disponíveis (com teclas)
local EMOTE_LIST = {
    {name = "Twerk",      data = EMOTES_CUSTOM.twerk,      key = Enum.KeyCode.One},
    {name = "Pose1",      data = EMOTES_CUSTOM.pose1,      key = Enum.KeyCode.Two},
    {name = "Blow Kiss",  data = EMOTES_CUSTOM.blowKiss,   key = Enum.KeyCode.Three},
    {name = "Leg Lift",   data = EMOTES_CUSTOM.legLift,    key = Enum.KeyCode.Four},
    {name = "Slow Dance", data = EMOTES_CUSTOM.slowDance,  key = Enum.KeyCode.Five},
}

local function stopCustomEmote()
    emoteRunning = false
    currentEmoteData = nil
    emoteTick = 0
    
    if emoteConnection then
        emoteConnection:Disconnect()
        emoteConnection = nil
    end
    
    restoreJoints()
end

local function playCustomEmote(emoteData)
    stopCustomEmote()
    
    if not emoteData then return end
    
    emoteTick = 0
    currentEmoteData = emoteData
    emoteRunning = true
    
    saveJointOrigins()
    
    emoteConnection = runService.RenderStepped:Connect(function(dt)
        if not emoteRunning or not currentEmoteData then
            stopCustomEmote()
            return
        end
        
        emoteTick = emoteTick + dt
        
        -- Se não for loop e passou da duração, para
        if not currentEmoteData.loop and currentEmoteData.duration and emoteTick >= currentEmoteData.duration then
            stopCustomEmote()
            return
        end
        
        -- Atualiza a pose
        pcall(function()
            currentEmoteData.update(emoteTick)
        end)
    end)
end

-- ═══════════════════════════════════════════════════
--  FÍSICA SELETIVA (jiggle no peito e bunda)
-- ═══════════════════════════════════════════════════

local function startSelectivePhysics()
    if physicsRunning then return end
    physicsRunning = true
    
    local torso = char:WaitForChild("Torso")
    local neck = torso:FindFirstChild("Neck")
    local lHip = torso:FindFirstChild("Left Hip")
    local rHip = torso:FindFirstChild("Right Hip")
    
    if not neck or not lHip or not rHip then return end
    
    local neckOrg = neck.C0
    local lHipOrg = lHip.C0
    local rHipOrg = rHip.C0
    
    runService.RenderStepped:Connect(function(dt)
        if not char or not char.Parent then return end
        if emoteRunning then return end  -- não atrapalha os emotes
        
        local t = tick()
        
        -- Peito: balanço suave (Neck)
        local chestBob = math.sin(t * 5) * 0.025 + math.sin(t * 3.7) * 0.015
        neck.C0 = neckOrg * CFrame.Angles(chestBob, 0, 0)
        
        -- Bunda: balanço nos hips
        local buttSway = math.sin(t * 4.5) * 0.03 + math.sin(t * 3.2 + 1) * 0.02
        lHip.C0 = lHipOrg * CFrame.Angles(0, 0, -buttSway * 0.5)
        rHip.C0 = rHipOrg * CFrame.Angles(0, 0, buttSway * 0.5)
    end)
end

-- ═══════════════════════════════════════════════════
--  TOGGLE ROUPA (R ou botão)
-- ═══════════════════════════════════════════════════

local function toggleClothes()
    clothesVisible = not clothesVisible
    
    -- Mostra/esconde roupas e acessórios
    for _, obj in ipairs(clothingObjects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    clothingObjects = {}
    
    for _, obj in ipairs(skinAccessories) do
        if obj and obj.Parent then
            obj.Transparency = clothesVisible and 0 or 1
        end
    end
    
    if clothesVisible then
        -- Recria as roupas
        local config = SKINS[currentSkin]
        if config then
            local shirt = Instance.new("Shirt")
            shirt.Name = "CustomShirt"
            shirt.ShirtTemplate = "rbxassetid://4829770436"
            shirt.Parent = char
            
            local pants = Instance.new("Pants")
            pants.Name = "CustomPants"
            pants.PantsTemplate = "rbxassetid://4829771451"
            pants.Parent = char
            
            clothingObjects = {shirt, pants}
        end
    end
    
    print("[Roupa] " .. (clothesVisible and "Mostrada" or "Removida"))
end

-- ═══════════════════════════════════════════════════
--  GUI (botões no topo da tela)
-- ═══════════════════════════════════════════════════

local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SkinSystem"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.DisplayOrder = 999
    
    -- ─── Barra superior de skins ───
    local skinBar = Instance.new("Frame")
    skinBar.Name = "SkinBar"
    skinBar.Size = UDim2.new(0, 300, 0, 32)
    skinBar.Position = UDim2.new(0.5, -150, 0, 5)
    skinBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    skinBar.BackgroundTransparency = 0.3
    skinBar.BorderSizePixel = 0
    skinBar.Parent = screenGui
    
    -- Arredondar: UICorner
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = skinBar
    
    local function createSkinButton(skinId, text, xPos)
        local btn = Instance.new("TextButton")
        btn.Name = "SkinBtn" .. skinId
        btn.Size = UDim2.new(0, 90, 0, 26)
        btn.Position = UDim2.new(0, xPos, 0, 3)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.BackgroundColor3 = (skinId == currentSkin) and Color3.fromRGB(200, 80, 120) or Color3.fromRGB(40, 40, 55)
        btn.BackgroundTransparency = 0.2
        btn.BorderSizePixel = 0
        btn.Parent = skinBar
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            if currentSkin ~= skinId then
                currentSkin = skinId
                stopCustomEmote()
                buildSkin(skinId)
                -- Atualiza cor dos botões
                for _, child in ipairs(skinBar:GetChildren()) do
                    if child:IsA("TextButton") then
                        local id = tonumber(child.Name:match("%d+"))
                        child.BackgroundColor3 = (id == currentSkin) and Color3.fromRGB(200, 80, 120) or Color3.fromRGB(40, 40, 55)
                    end
                end
            end
        end)
        btn.TouchTap:Connect(function()
            if currentSkin ~= skinId then
                currentSkin = skinId
                stopCustomEmote()
                buildSkin(skinId)
                for _, child in ipairs(skinBar:GetChildren()) do
                    if child:IsA("TextButton") then
                        local id = tonumber(child.Name:match("%d+"))
                        child.BackgroundColor3 = (id == currentSkin) and Color3.fromRGB(200, 80, 120) or Color3.fromRGB(40, 40, 55)
                    end
                end
            end
        end)
        
        return btn
    end
    
    createSkinButton(1, "🌸 Neko", 5)
    createSkinButton(2, "🧹 Maid", 105)
    createSkinButton(3, "🐰 Bunny", 205)
    
    -- ─── Botão Remover Roupa (R) ───
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleClothes"
    toggleBtn.Size = UDim2.new(0, 30, 0, 30)
    toggleBtn.Position = UDim2.new(1, -40, 0, 5)
    toggleBtn.Text = "👗"
    toggleBtn.TextSize = 16
    toggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    toggleBtn.BackgroundTransparency = 0.3
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = screenGui
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleBtn
    
    toggleBtn.MouseButton1Click:Connect(toggleClothes)
    toggleBtn.TouchTap:Connect(toggleClothes)
    
    -- ─── Painel de Emotes (mobile-friendly) ───
    local emotePanel = Instance.new("Frame")
    emotePanel.Name = "EmotePanel"
    emotePanel.Size = UDim2.new(0, 160, 0, 220)
    emotePanel.Position = UDim2.new(1, -170, 0.5, -110)
    emotePanel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    emotePanel.BackgroundTransparency = 0.3
    emotePanel.BorderSizePixel = 0
    emotePanel.Parent = screenGui
    
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 8)
    panelCorner.Parent = emotePanel
    
    -- Label do painel
    local panelLabel = Instance.new("TextLabel")
    panelLabel.Name = "PanelLabel"
    panelLabel.Size = UDim2.new(1, 0, 0, 22)
    panelLabel.Position = UDim2.new(0, 0, 0, 2)
    panelLabel.Text = "🎭 EMOTES"
    panelLabel.TextColor3 = Color3.fromRGB(255, 200, 220)
    panelLabel.TextScaled = true
    panelLabel.TextSize = 12
    panelLabel.Font = Enum.Font.GothamBold
    panelLabel.BackgroundTransparency = 1
    panelLabel.Parent = emotePanel
    
    -- Botão Parar Emote (X)
    local stopEmoteBtn = Instance.new("TextButton")
    stopEmoteBtn.Name = "StopEmote"
    stopEmoteBtn.Size = UDim2.new(1, -10, 0, 26)
    stopEmoteBtn.Position = UDim2.new(0, 5, 0, 190)
    stopEmoteBtn.Text = "⏹ PARAR"
    stopEmoteBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    stopEmoteBtn.TextScaled = true
    stopEmoteBtn.TextSize = 10
    stopEmoteBtn.Font = Enum.Font.GothamBold
    stopEmoteBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
    stopEmoteBtn.BackgroundTransparency = 0.2
    stopEmoteBtn.BorderSizePixel = 0
    stopEmoteBtn.Parent = emotePanel
    
    local stopCorner = Instance.new("UICorner")
    stopCorner.CornerRadius = UDim.new(0, 5)
    stopCorner.Parent = stopEmoteBtn
    
    stopEmoteBtn.MouseButton1Click:Connect(stopCustomEmote)
    stopEmoteBtn.TouchTap:Connect(stopCustomEmote)
    
    -- Botões de emote
    for i, emote in ipairs(EMOTE_LIST) do
        local btn = Instance.new("TextButton")
        btn.Name = "EmoteBtn" .. i
        btn.Size = UDim2.new(1, -10, 0, 26)
        btn.Position = UDim2.new(0, 5, 0, 24 + (i - 1) * 32)
        btn.Text = i .. ". " .. emote.name
        btn.TextColor3 = Color3.fromRGB(220, 220, 255)
        btn.TextScaled = true
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        btn.BackgroundColor3 = Color3.fromRGB(35, 30, 45)
        btn.BackgroundTransparency = 0.2
        btn.BorderSizePixel = 0
        btn.Parent = emotePanel
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            playCustomEmote(emote.data)
        end)
        btn.TouchTap:Connect(function()
            playCustomEmote(emote.data)
        end)
    end
    
    print("[GUI] Sistema de skins criado!")
end

-- ═══════════════════════════════════════════════════
--  KEYBINDS (PC)
-- ═══════════════════════════════════════════════════

-- Tecla R = toggle roupa
userInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.R then
        toggleClothes()
    elseif input.KeyCode == Enum.KeyCode.X then
        stopCustomEmote()
    else
        -- Verifica se é tecla de emote
        for _, emote in ipairs(EMOTE_LIST) do
            if input.KeyCode == emote.key then
                playCustomEmote(emote.data)
                break
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════
--  INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════

local function onCharacterAdded(newChar)
    char = newChar
    humanoid = char:WaitForChild("Humanoid")
    physicsRunning = false
    
    -- Limpa estado anterior
    skinAccessories = {}
    clothingObjects = {}
    jointOrigins = {}
    emoteRunning = false
    currentEmoteData = nil
    if emoteConnection then
        emoteConnection:Disconnect()
        emoteConnection = nil
    end
    
    -- Reconstrói
    pcall(function() buildSkin(currentSkin) end)
    pcall(function() startSelectivePhysics() end)
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Primeira execução
pcall(function() buildSkin(currentSkin) end)
pcall(function() startSelectivePhysics() end)
pcall(function() createGUI() end)

print("═══════════════════════════════════════")
print("  ✅ Skin System + Custom Emotes ativo!")
print("  • 1-5 = Emotes custom")
print("  • X = Parar emote")
print("  • R = Tirar/colocar roupa")
print("  • Botões na tela pra mobile")
print("  • Tudo client-side")
print("═══════════════════════════════════════")
