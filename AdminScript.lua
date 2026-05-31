-- ╔══════════════════════════════════════════╗
-- ║   NICO'S NEXTBOTS - ADMIN PANEL v2.0    ║
-- ║   LocalScript → StarterPlayerScripts    ║
-- ╚══════════════════════════════════════════╝

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting      = game:GetService("Lighting")

local lp           = Players.LocalPlayer
local mouse        = lp:GetMouse()
local char         = lp.Character or lp.CharacterAdded:Wait()
local humanoid     = char:WaitForChild("Humanoid")
local rootPart     = char:WaitForChild("HumanoidRootPart")

-- ══════════════════════════════
--  LISTA DE ADMINS — edite aqui
-- ══════════════════════════════
local ADMINS = {
    [lp.Name] = true,   -- dono sempre admin
    -- ["OutroJogador"] = true,
}

if not ADMINS[lp.Name] then
    return  -- não é admin, script não roda
end

-- ══════════════════════════════
--  REMOTE EVENTS REAIS DO JOGO
-- ══════════════════════════════
local RE = ReplicatedStorage:WaitForChild("events", 5)

local function getEvent(name)
    if RE then
        local ev = RE:FindFirstChild(name)
        if ev then return ev end
    end
    return nil
end

local function fireEvent(name, ...)
    local ev = getEvent(name)
    if ev then ev:FireServer(...) end
end

-- ══════════════════════════════
--  ESTADO INTERNO
-- ══════════════════════════════
local state = {
    noclip      = false,
    speedHack   = false,
    godMode     = false,
    frozen      = false,
    espEnabled  = false,
    noFog       = false,
    fullBright  = false,
    origSpeed   = humanoid.WalkSpeed,
    origJump    = humanoid.JumpPower,
    espLabels   = {},
}

-- ══════════════════════════════════════════════════════
--  GUI BASE
-- ══════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "NNAdminPanel"
screenGui.ResetOnSpawn  = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent        = lp:WaitForChild("PlayerGui")

-- Botão flutuante de abrir/fechar
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size              = UDim2.new(0, 44, 0, 44)
toggleBtn.Position          = UDim2.new(0, 12, 0.5, -22)
toggleBtn.BackgroundColor3  = Color3.fromRGB(20, 20, 30)
toggleBtn.TextColor3        = Color3.fromRGB(255, 80, 80)
toggleBtn.Text              = "⚙"
toggleBtn.Font              = Enum.Font.GothamBold
toggleBtn.TextSize          = 22
toggleBtn.BorderSizePixel   = 0
toggleBtn.ZIndex            = 10
toggleBtn.Parent            = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

-- Janela principal
local mainFrame = Instance.new("Frame")
mainFrame.Name              = "MainFrame"
mainFrame.Size              = UDim2.new(0, 360, 0, 520)
mainFrame.Position          = UDim2.new(0, 70, 0.5, -260)
mainFrame.BackgroundColor3  = Color3.fromRGB(12, 12, 20)
mainFrame.BorderSizePixel   = 0
mainFrame.ClipsDescendants  = true
mainFrame.Visible           = false
mainFrame.Parent            = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

-- Borda colorida
local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color     = Color3.fromRGB(200, 40, 40)
stroke.Thickness = 2

-- Barra de título (drag aqui)
local titleBar = Instance.new("Frame")
titleBar.Size               = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3   = Color3.fromRGB(200, 40, 40)
titleBar.BorderSizePixel    = 0
titleBar.Parent             = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

-- Cobrir canto inferior da titleBar
local titleFix = Instance.new("Frame")
titleFix.Size               = UDim2.new(1, 0, 0, 10)
titleFix.Position           = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3   = Color3.fromRGB(200, 40, 40)
titleFix.BorderSizePixel    = 0
titleFix.Parent             = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size             = UDim2.new(1, -40, 1, 0)
titleLabel.Position         = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3       = Color3.fromRGB(255, 255, 255)
titleLabel.Text             = "⚡ NICO'S ADMIN PANEL"
titleLabel.Font             = Enum.Font.GothamBold
titleLabel.TextSize         = 14
titleLabel.TextXAlignment   = Enum.TextXAlignment.Left
titleLabel.Parent           = titleBar

-- Botão X dentro do painel
local closeInner = Instance.new("TextButton")
closeInner.Size             = UDim2.new(0, 28, 0, 28)
closeInner.Position         = UDim2.new(1, -32, 0, 4)
closeInner.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
closeInner.TextColor3       = Color3.fromRGB(255, 255, 255)
closeInner.Text             = "✕"
closeInner.Font             = Enum.Font.GothamBold
closeInner.TextSize         = 13
closeInner.BorderSizePixel  = 0
closeInner.Parent           = titleBar
Instance.new("UICorner", closeInner).CornerRadius = UDim.new(0, 6)

-- Scroll de conteúdo
local scroll = Instance.new("ScrollingFrame")
scroll.Size                     = UDim2.new(1, -8, 1, -44)
scroll.Position                 = UDim2.new(0, 4, 0, 40)
scroll.BackgroundTransparency   = 1
scroll.BorderSizePixel          = 0
scroll.ScrollBarThickness       = 4
scroll.ScrollBarImageColor3     = Color3.fromRGB(200, 40, 40)
scroll.CanvasSize               = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize      = Enum.AutomaticSize.Y
scroll.Parent                   = mainFrame

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding              = UDim.new(0, 6)
listLayout.SortOrder            = Enum.SortOrder.LayoutOrder
listLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Center

local listPad = Instance.new("UIPadding", scroll)
listPad.PaddingTop    = UDim.new(0, 6)
listPad.PaddingBottom = UDim.new(0, 10)
listPad.PaddingLeft   = UDim.new(0, 6)
listPad.PaddingRight  = UDim.new(0, 6)

-- ══════════════════════════════════════════════════════
--  HELPERS DE UI
-- ══════════════════════════════════════════════════════
local function makeSection(label)
    local sec = Instance.new("TextLabel")
    sec.Size                = UDim2.new(1, 0, 0, 22)
    sec.BackgroundColor3    = Color3.fromRGB(200, 40, 40)
    sec.TextColor3          = Color3.fromRGB(255, 255, 255)
    sec.Text                = "  " .. label
    sec.Font                = Enum.Font.GothamBold
    sec.TextSize            = 12
    sec.TextXAlignment      = Enum.TextXAlignment.Left
    sec.BorderSizePixel     = 0
    sec.Parent              = scroll
    Instance.new("UICorner", sec).CornerRadius = UDim.new(0, 6)
    return sec
end

local function makeButton(label, color, callback)
    color = color or Color3.fromRGB(35, 35, 55)
    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3    = color
    btn.TextColor3          = Color3.fromRGB(220, 220, 220)
    btn.Text                = label
    btn.Font                = Enum.Font.Gotham
    btn.TextSize            = 13
    btn.BorderSizePixel     = 0
    btn.AutoButtonColor     = false
    btn.Parent              = scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(
                math.clamp(color.R * 255 + 30, 0, 255),
                math.clamp(color.G * 255 + 30, 0, 255),
                math.clamp(color.B * 255 + 30, 0, 255)
            )
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = color}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.07), {
            BackgroundColor3 = Color3.fromRGB(200, 40, 40)
        }):Play()
        task.delay(0.12, function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = color}):Play()
        end)
        pcall(callback)
    end)
    return btn
end

-- Botão toggle (liga/desliga)
local function makeToggle(label, getter, setter)
    local baseColor     = Color3.fromRGB(35, 35, 55)
    local activeColor   = Color3.fromRGB(180, 30, 30)

    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3    = getter() and activeColor or baseColor
    btn.TextColor3          = Color3.fromRGB(220, 220, 220)
    btn.Text                = (getter() and "✔ " or "✘ ") .. label
    btn.Font                = Enum.Font.Gotham
    btn.TextSize            = 13
    btn.BorderSizePixel     = 0
    btn.AutoButtonColor     = false
    btn.Parent              = scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local function refresh()
        local on = getter()
        btn.BackgroundColor3 = on and activeColor or baseColor
        btn.Text             = (on and "✔ " or "✘ ") .. label
    end

    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
    end)
    return btn, refresh
end

-- Input de texto + botão
local function makeInput(placeholder, btnLabel, btnColor, callback)
    local row = Instance.new("Frame")
    row.Size                = UDim2.new(1, 0, 0, 34)
    row.BackgroundTransparency = 1
    row.Parent              = scroll

    local rowLayout = Instance.new("UIListLayout", row)
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.Padding       = UDim.new(0, 4)
    rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local box = Instance.new("TextBox")
    box.Size                = UDim2.new(0.62, 0, 1, 0)
    box.BackgroundColor3    = Color3.fromRGB(25, 25, 40)
    box.TextColor3          = Color3.fromRGB(220, 220, 220)
    box.PlaceholderText     = placeholder
    box.PlaceholderColor3   = Color3.fromRGB(100, 100, 120)
    box.Text                = ""
    box.Font                = Enum.Font.Gotham
    box.TextSize            = 12
    box.BorderSizePixel     = 0
    box.ClearTextOnFocus    = false
    box.Parent              = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)

    local execBtn = Instance.new("TextButton")
    execBtn.Size                = UDim2.new(0.35, 0, 1, 0)
    execBtn.BackgroundColor3    = btnColor or Color3.fromRGB(200, 40, 40)
    execBtn.TextColor3          = Color3.fromRGB(255, 255, 255)
    execBtn.Text                = btnLabel
    execBtn.Font                = Enum.Font.GothamBold
    execBtn.TextSize            = 12
    execBtn.BorderSizePixel     = 0
    execBtn.AutoButtonColor     = false
    execBtn.Parent              = row
    Instance.new("UICorner", execBtn).CornerRadius = UDim.new(0, 7)

    execBtn.MouseButton1Click:Connect(function()
        pcall(callback, box.Text)
    end)
    return box
end

-- ══════════════════════════════════════════════════════
--  DRAG
-- ══════════════════════════════════════════════════════
do
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = mainFrame.Position
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
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ══════════════════════════════════════════════════════
--  ABRIR / FECHAR
-- ══════════════════════════════════════════════════════
local panelOpen = false
local function togglePanel()
    panelOpen = not panelOpen
    mainFrame.Visible = panelOpen
    toggleBtn.Text    = panelOpen and "✕" or "⚙"
end
toggleBtn.MouseButton1Click:Connect(togglePanel)
closeInner.MouseButton1Click:Connect(togglePanel)

-- ══════════════════════════════════════════════════════
--  HELPERS DO JOGO
-- ══════════════════════════════════════════════════════
local function getPlayerByName(name)
    name = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(name, 1, true) then return p end
    end
    return nil
end

local function notify(msg)
    local sg = Instance.new("ScreenGui")
    sg.ResetOnSpawn = false
    sg.Parent       = lp:WaitForChild("PlayerGui")
    local lbl = Instance.new("TextLabel", sg)
    lbl.Size                = UDim2.new(0, 300, 0, 40)
    lbl.Position            = UDim2.new(0.5, -150, 0, 20)
    lbl.BackgroundColor3    = Color3.fromRGB(200, 40, 40)
    lbl.TextColor3          = Color3.fromRGB(255, 255, 255)
    lbl.Text                = "⚡ " .. msg
    lbl.Font                = Enum.Font.GothamBold
    lbl.TextSize            = 14
    lbl.BorderSizePixel     = 0
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
    TweenService:Create(lbl, TweenInfo.new(0.3), {Position = UDim2.new(0.5,-150,0,10)}):Play()
    task.delay(2.5, function()
        TweenService:Create(lbl, TweenInfo.new(0.4), {BackgroundTransparency=1, TextTransparency=1}):Play()
        task.delay(0.5, function() sg:Destroy() end)
    end)
end

-- ══════════════════════════════════════════════════════
--  SEÇÃO: SELF — opções pro próprio jogador
-- ══════════════════════════════════════════════════════
makeSection("👤  SELF")

-- NOCLIP
makeToggle("Noclip",
    function() return state.noclip end,
    function(v)
        state.noclip = v
        notify(v and "Noclip ON" or "Noclip OFF")
    end
)

RunService.Stepped:Connect(function()
    if state.noclip and char and char.PrimaryPart then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end
end)

-- SPEED HACK
makeToggle("Speed Hack  (2× WalkSpeed)",
    function() return state.speedHack end,
    function(v)
        state.speedHack = v
        if v then
            state.origSpeed     = humanoid.WalkSpeed
            humanoid.WalkSpeed  = state.origSpeed * 2
            notify("Speed ON")
        else
            humanoid.WalkSpeed  = state.origSpeed
            notify("Speed OFF")
        end
    end
)

-- SUPER JUMP
makeToggle("Super Jump  (3× JumpPower)",
    function() return state.superJump end,
    function(v)
        state.superJump = v
        if v then
            state.origJump      = humanoid.JumpPower
            humanoid.JumpPower  = state.origJump * 3
            notify("Super Jump ON")
        else
            humanoid.JumpPower  = state.origJump
            notify("Super Jump OFF")
        end
    end
)

-- GOD MODE (MaxHealth infinito + sem dano)
makeToggle("God Mode",
    function() return state.godMode end,
    function(v)
        state.godMode = v
        if v then
            humanoid.MaxHealth = math.huge
            humanoid.Health    = math.huge
            notify("God Mode ON")
        else
            humanoid.MaxHealth = 100
            humanoid.Health    = 100
            notify("God Mode OFF")
        end
    end
)

-- FREEZE SELF
makeToggle("Freeze Self",
    function() return state.frozen end,
    function(v)
        state.frozen = v
        if rootPart then
            rootPart.Anchored = v
        end
        notify(v and "Frozen" or "Unfrozen")
    end
)

-- FLY
local flying = false
local flyBV, flyBA
makeToggle("Fly",
    function() return flying end,
    function(v)
        flying = v
        if v then
            local bp = Instance.new("BodyPosition")
            bp.Name     = "AdminFlyBP"
            bp.MaxForce = Vector3.new(1e5,1e5,1e5)
            bp.Parent   = rootPart
            local bg = Instance.new("BodyGyro")
            bg.Name     = "AdminFlyBG"
            bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
            bg.Parent   = rootPart
            flyBV = bp
            flyBA = bg
            humanoid.PlatformStand = true

            local conn
            conn = RunService.RenderStepped:Connect(function()
                if not flying then conn:Disconnect() return end
                local cf    = workspace.CurrentCamera.CFrame
                local dir   = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
                flyBV.Position  = rootPart.Position + dir * 2
                flyBA.CFrame    = cf
            end)
            notify("Fly ON  (WASD + Space/Ctrl)")
        else
            if flyBV then flyBV:Destroy() end
            if flyBA then flyBA:Destroy() end
            humanoid.PlatformStand = false
            notify("Fly OFF")
        end
    end
)

-- TELEPORT PARA CURSOR
makeButton("📍  Teleport to Cursor", Color3.fromRGB(40, 60, 100), function()
    local target = mouse.Hit.Position + Vector3.new(0, 3, 0)
    rootPart.CFrame = CFrame.new(target)
    notify("Teleported to cursor")
end)

-- ══════════════════════════════════════════════════════
--  SEÇÃO: VISUAIS
-- ══════════════════════════════════════════════════════
makeSection("🌟  VISUAIS")

-- FULLBRIGHT
makeToggle("Full Bright",
    function() return state.fullBright end,
    function(v)
        state.fullBright = v
        if v then
            Lighting.Brightness         = 10
            Lighting.ClockTime          = 14
            Lighting.FogEnd             = 1e6
            Lighting.GlobalShadows      = false
            Lighting.OutdoorAmbient     = Color3.fromRGB(128,128,128)
            notify("Full Bright ON")
        else
            Lighting.Brightness         = 1
            Lighting.ClockTime          = 0
            Lighting.FogEnd             = 300
            Lighting.GlobalShadows      = true
            Lighting.OutdoorAmbient     = Color3.fromRGB(70,70,70)
            notify("Full Bright OFF")
        end
    end
)

-- NO FOG
makeToggle("Remove Fog",
    function() return state.noFog end,
    function(v)
        state.noFog = v
        Lighting.FogEnd = v and 1e6 or 300
        Lighting.FogStart = v and 1e6 or 0
        notify(v and "Fog removido" or "Fog restaurado")
    end
)

-- ESP
local espConn
makeToggle("Player ESP",
    function() return state.espEnabled end,
    function(v)
        state.espEnabled = v
        if v then
            espConn = RunService.RenderStepped:Connect(function()
                -- limpar labels velhos
                for p, lbl in pairs(state.espLabels) do
                    if not Players:FindFirstChild(p) then
                        lbl:Destroy()
                        state.espLabels[p] = nil
                    end
                end
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character then
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            if not state.espLabels[p.Name] then
                                local bb = Instance.new("BillboardGui")
                                bb.Size            = UDim2.new(0, 100, 0, 30)
                                bb.StudsOffset     = Vector3.new(0, 3, 0)
                                bb.AlwaysOnTop     = true
                                bb.Parent          = hrp
                                local tl = Instance.new("TextLabel", bb)
                                tl.Size            = UDim2.new(1, 0, 1, 0)
                                tl.BackgroundTransparency = 1
                                tl.TextColor3      = Color3.fromRGB(255, 80, 80)
                                tl.Font            = Enum.Font.GothamBold
                                tl.TextSize        = 14
                                tl.Text            = p.Name
                                state.espLabels[p.Name] = bb
                            end
                            -- atualizar distância
                            local dist = math.floor((rootPart.Position - hrp.Position).Magnitude)
                            state.espLabels[p.Name]:FindFirstChild("TextLabel", true).Text =
                                p.Name .. "\n" .. dist .. "m"
                        end
                    end
                end
            end)
            notify("ESP ON")
        else
            if espConn then espConn:Disconnect() end
            for _, lbl in pairs(state.espLabels) do lbl:Destroy() end
            state.espLabels = {}
            notify("ESP OFF")
        end
    end
)

-- ══════════════════════════════════════════════════════
--  SEÇÃO: SERVER EVENTS (RemoteEvents reais do jogo)
-- ══════════════════════════════════════════════════════
makeSection("⚡  SERVER EVENTS")

-- JUMPSCARE
makeButton("💀  Jumpscare All", Color3.fromRGB(80, 10, 10), function()
    for _, p in ipairs(Players:GetPlayers()) do
        fireEvent("jumpscare", p)
    end
    notify("Jumpscare enviado para todos!")
end)

-- SHOUT (mensagem global)
do
    local box = makeInput("Mensagem global...", "SHOUT", Color3.fromRGB(160, 30, 30), function(txt)
        if txt and txt ~= "" then
            fireEvent("shout", txt)
            notify("Shout enviado!")
        end
    end)
end

-- SHAKE
makeButton("📳  Shake Screen (all)", Color3.fromRGB(60, 40, 100), function()
    fireEvent("shakeevent", 1, 5)
    notify("Shake enviado!")
end)

-- EXPLOSION no cursor
makeButton("💥  Explosion no Cursor", Color3.fromRGB(180, 80, 0), function()
    local pos = mouse.Hit.Position
    fireEvent("explosion", pos)
    notify("Explosion!")
end)

-- FIX LIGHTING
makeButton("💡  Fix Lighting", Color3.fromRGB(30, 80, 60), function()
    fireEvent("fixLighting")
    notify("Lighting restaurado!")
end)

-- STATUS message
do
    makeInput("Status do server...", "Status", Color3.fromRGB(80, 60, 140), function(txt)
        if txt and txt ~= "" then
            fireEvent("status", txt)
            notify("Status enviado!")
        end
    end)
end

-- CHAT message falsa
do
    makeInput("Mensagem de chat...", "Chat", Color3.fromRGB(40, 80, 40), function(txt)
        if txt and txt ~= "" then
            fireEvent("showchatmsg", txt)
        end
    end)
end

-- RESPAWN self
makeButton("🔄  Respawn Self", Color3.fromRGB(30, 60, 30), function()
    fireEvent("respawnchar", lp)
    notify("Respawning...")
end)

-- ══════════════════════════════════════════════════════
--  SEÇÃO: PLAYERS (admin sobre outros)
-- ══════════════════════════════════════════════════════
makeSection("👥  PLAYERS")

-- TELEPORT jogador até você
do
    makeInput("Nome do jogador", "TP pra mim", Color3.fromRGB(40, 70, 130), function(name)
        local p = getPlayerByName(name)
        if p and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = rootPart.CFrame + rootPart.CFrame.LookVector * 3
                notify(p.Name .. " teleportado!")
            end
        else
            notify("Jogador não encontrado")
        end
    end)
end

-- TP você até jogador
do
    makeInput("Nome do jogador", "TP até ele", Color3.fromRGB(30, 80, 120), function(name)
        local p = getPlayerByName(name)
        if p and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                rootPart.CFrame = hrp.CFrame + Vector3.new(3, 0, 0)
                notify("Teleportado até " .. p.Name)
            end
        else
            notify("Jogador não encontrado")
        end
    end)
end

-- KICK (via remote admin)
do
    makeInput("Nome p/ kick", "Kick", Color3.fromRGB(140, 30, 30), function(name)
        local p = getPlayerByName(name)
        if p then
            fireEvent("admin", "kick", p.Name)
            notify("Kick enviado: " .. p.Name)
        else
            notify("Jogador não encontrado")
        end
    end)
end

-- BAN (via remote ban)
do
    makeInput("Nome p/ ban", "Ban", Color3.fromRGB(100, 0, 0), function(name)
        local p = getPlayerByName(name)
        if p then
            fireEvent("ban", p.UserId)
            notify("Ban enviado: " .. p.Name)
        else
            notify("Jogador não encontrado")
        end
    end)
end

-- GIVE ADMIN
do
    makeInput("Dar admin a...", "Give Admin", Color3.fromRGB(140, 100, 0), function(name)
        local p = getPlayerByName(name)
        if p then
            fireEvent("giveadmin", p)
            notify("Admin dado a " .. p.Name)
        else
            notify("Jogador não encontrado")
        end
    end)
end

-- JUMPSCARE em player específico
do
    makeInput("Jumpscare em...", "SCARE", Color3.fromRGB(100, 10, 10), function(name)
        local p = getPlayerByName(name)
        if p then
            fireEvent("jumpscare", p)
            notify("Jumpscare em " .. p.Name)
        else
            notify("Jogador não encontrado")
        end
    end)
end

-- LISTAR JOGADORES
makeButton("📋  Listar Jogadores", Color3.fromRGB(30, 50, 80), function()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(names, p.Name)
    end
    notify(table.concat(names, ", "))
end)

-- ══════════════════════════════════════════════════════
--  SEÇÃO: MAPAS (ChangZone real do jogo)
-- ══════════════════════════════════════════════════════
makeSection("🗺️  MAPAS")

local maps = {
    {"Mall",        "nn_mall"},
    {"Russia",      "nn_russia"},
    {"Hotel",       "nn_hotel"},
    {"Tunnels",     "nn_tunnels"},
    {"Airport",     "nn_airport"},
    {"Backrooms",   "nn_backrooms"},
    {"Poolrooms",   "nn_poolrooms"},
    {"Crossroads",  "nn_crossroads_v2"},
    {"Flat Grass",  "nn_flatgrass"},
    {"Port",        "nn_port"},
    {"Grand Hotel", "nn_grandhotel"},
    {"Kellywood",   "nn_kellywood"},
    {"Outpost",     "nn_outpost"},
    {"Camberturn",  "nn_camberturn"},
}

for _, m in ipairs(maps) do
    local label, id = m[1], m[2]
    makeButton("🗺  " .. label, Color3.fromRGB(25, 50, 35), function()
        fireEvent("changezone", id)
        notify("Mudando para " .. label)
    end)
end

-- ══════════════════════════════════════════════════════
--  SEÇÃO: MISC / ROUBADONAS
-- ══════════════════════════════════════════════════════
makeSection("💀  MISC / ROUBADONAS")

-- REJOIN rápido
makeButton("🔁  Rejoin Server", Color3.fromRGB(50, 50, 50), function()
    local TS = game:GetService("TeleportService")
    TS:Teleport(game.PlaceId, lp)
end)

-- REMOVE TODOS OS CHARACTERS
makeButton("☠️  Remove All Characters", Color3.fromRGB(80, 0, 0), function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            fireEvent("removechar", p)
        end
    end
    notify("Todos removidos!")
end)

-- RESPAWN ALL
makeButton("🔄  Respawn All Players", Color3.fromRGB(30, 70, 30), function()
    for _, p in ipairs(Players:GetPlayers()) do
        fireEvent("respawnchar", p)
    end
    notify("Todos respawnados!")
end)

-- DOORS ALL OPEN
makeButton("🚪  Open All Doors", Color3.fromRGB(60, 40, 20), function()
    fireEvent("door", "openall")
    notify("Portas abertas!")
end)

-- FIREWORKS
makeButton("🎆  Fireworks!", Color3.fromRGB(100, 20, 100), function()
    fireEvent("fireworkEffect", rootPart.Position)
    notify("🎆 Fireworks!")
end)

-- BLACKOUT
makeButton("🌑  Blackout", Color3.fromRGB(10, 10, 10), function()
    Lighting.Brightness    = 0
    Lighting.GlobalShadows = true
    Lighting.FogEnd        = 20
    Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
    notify("Blackout ativado!")
end)

-- TELEPORT TODOS PRA UM PONTO
makeButton("🌀  TP All to Me", Color3.fromRGB(70, 0, 90), function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = rootPart.CFrame + Vector3.new(math.random(-5,5), 0, math.random(-5,5))
            end
        end
    end
    notify("Todos teleportados pra você!")
end)

-- DISCO LIGHTING
local discoConn
local discoBusy = false
makeToggle("🕺  Disco Lighting",
    function() return discoBusy end,
    function(v)
        discoBusy = v
        if v then
            discoConn = RunService.Heartbeat:Connect(function()
                Lighting.OutdoorAmbient = Color3.fromHSV(math.random(), 1, 1)
                Lighting.Brightness     = math.random(1, 5)
            end)
            notify("DISCO MODE 🕺")
        else
            if discoConn then discoConn:Disconnect() end
            Lighting.OutdoorAmbient = Color3.fromRGB(70,70,70)
            Lighting.Brightness     = 1
            notify("Disco OFF")
        end
    end
)

-- INVISÍVEL (transparência do character)
local invisible = false
makeToggle("👻  Invisible",
    function() return invisible end,
    function(v)
        invisible = v
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.Transparency = v and 1 or 0
            end
        end
        notify(v and "Invisível!" or "Visível novamente")
    end
)

-- INFINITE STAMINA (se o jogo tiver stamina como IntValue)
makeButton("⚡  Max Stats (HP/Speed)", Color3.fromRGB(150, 120, 0), function()
    humanoid.MaxHealth = math.huge
    humanoid.Health    = math.huge
    humanoid.WalkSpeed = 32
    humanoid.JumpPower = 75
    notify("Stats maximizadas!")
end)

-- ══════════════════════════════════════════════════════
--  ATUALIZAR CHAR QUANDO RESPAWN
-- ══════════════════════════════════════════════════════
lp.CharacterAdded:Connect(function(newChar)
    char      = newChar
    humanoid  = newChar:WaitForChild("Humanoid")
    rootPart  = newChar:WaitForChild("HumanoidRootPart")
    -- reaplicar estados persistentes
    if state.godMode then
        humanoid.MaxHealth = math.huge
        humanoid.Health    = math.huge
    end
    if state.speedHack then
        humanoid.WalkSpeed = state.origSpeed * 2
    end
end)

notify("✅ Admin Panel carregado!")
