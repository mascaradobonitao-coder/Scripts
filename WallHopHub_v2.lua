-- ============================================================
--  TopoOp Wall Hop Hub v2.1  |  Delta Compatible
--  Key: TopoOp-ofc_mohd
--  AVISO: Não compartilhe sua Key — resulta em BAN permanente.
--  Site para pegar Key: [COLOQUE SEU SITE AQUI]
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- ============================================================
-- CONFIG
-- ============================================================
local CFG = {
    VALID_KEY    = "TopoOp-ofc_mohd",
    KEY_FILE     = "TopoOpKey.txt",
    BAN_FILE     = "TopoOpBans.txt",
    OWNER        = "TopoOp_ofc_mohd", -- SEU NICK AQUI
    BAN_MSG      = "[TopoOp Hub] Voce foi banido.",
    DEFAULT_DEG  = 45,
    WALL_DIST    = 3.5,
    COOLDOWN     = 0.35,
    SMOOTH       = 0.18,
}

-- ============================================================
-- FILE HELPERS (Delta safe)
-- ============================================================
local function fWrite(path, data)
    local ok = pcall(writefile, path, tostring(data))
    return ok
end

local function fRead(path)
    local ok, data = pcall(readfile, path)
    if ok and type(data) == "string" then return data end
    return nil
end

local function fExists(path)
    local ok, r = pcall(isfile, path)
    return ok and r == true
end

-- ============================================================
-- BAN SYSTEM
-- ============================================================
local Bans = {}

local function loadBans()
    if not fExists(CFG.BAN_FILE) then return end
    local raw = fRead(CFG.BAN_FILE)
    if not raw then return end
    for name in raw:gmatch("[^\n]+") do
        Bans[name:lower():gsub("%s","")] = true
    end
end

local function saveBans()
    local lines = {}
    for k in pairs(Bans) do table.insert(lines, k) end
    fWrite(CFG.BAN_FILE, table.concat(lines, "\n"))
end

local function banName(n)
    n = n:lower():gsub("%s","")
    if n == "" then return false end
    Bans[n] = true
    saveBans()
    return true
end

local function unbanName(n)
    n = n:lower():gsub("%s","")
    if Bans[n] then
        Bans[n] = nil
        saveBans()
        return true
    end
    return false
end

local function isBanned(n)
    return Bans[n:lower():gsub("%s","")] == true
end

loadBans()

-- ============================================================
-- SHOW BAN SCREEN & STOP
-- ============================================================
if isBanned(LocalPlayer.Name) then
    local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
    if pg then
        local sg = Instance.new("ScreenGui")
        sg.Name = "TopoOpBan"
        sg.IgnoreGuiInset = true
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 999
        sg.Parent = pg

        local f = Instance.new("Frame", sg)
        f.Size = UDim2.fromScale(1,1)
        f.BackgroundColor3 = Color3.fromRGB(8,0,0)
        f.BorderSizePixel = 0

        local t = Instance.new("TextLabel", f)
        t.Size = UDim2.new(0.8,0,0,60)
        t.Position = UDim2.new(0.1,0,0.4,0)
        t.BackgroundTransparency = 1
        t.Text = CFG.BAN_MSG
        t.TextColor3 = Color3.fromRGB(255,60,60)
        t.Font = Enum.Font.GothamBold
        t.TextScaled = true
    end
    return
end

-- ============================================================
-- STATE
-- ============================================================
local S = {
    keyValid   = false,
    enabled    = true,
    degree     = CFG.DEFAULT_DEG,
    onCooldown = false,
    onWall     = false,
    wasJump    = false,
}

-- ============================================================
-- CAMERA ROTATION (sem travar)
-- ============================================================
local function rotateCamera(deg)
    local cf    = Camera.CFrame
    local pos   = cf.Position
    local look  = cf.LookVector
    local pitch = math.atan2(look.Y, Vector2.new(look.X, look.Z).Magnitude)
    local yaw   = math.atan2(-look.X, -look.Z)
    local nYaw  = yaw + math.rad(deg)

    local target = CFrame.new(pos)
        * CFrame.Angles(0, nYaw, 0)
        * CFrame.Angles(pitch, 0, 0)

    local t0  = tick()
    local dur = CFG.SMOOTH
    local con
    con = RunService.RenderStepped:Connect(function()
        local alpha = math.min((tick()-t0)/dur, 1)
        Camera.CFrame = cf:Lerp(target, alpha)
        if alpha >= 1 then
            con:Disconnect()
            task.delay(CFG.COOLDOWN, function() S.onCooldown = false end)
        end
    end)
end

-- ============================================================
-- WALL DETECTION
-- ============================================================
local function detectWall()
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local cf = hrp.CFrame
    for _, dir in ipairs({ cf.RightVector, -cf.RightVector }) do
        if workspace:Raycast(hrp.Position, dir * CFG.WALL_DIST, params) then
            return true
        end
    end
    return false
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
local function startLoop()
    local hum = nil

    local function grabHum()
        local c = LocalPlayer.Character
        if c then hum = c:FindFirstChildOfClass("Humanoid") end
    end
    grabHum()
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1); grabHum()
        S.wasJump = false; S.onCooldown = false
    end)

    RunService.Heartbeat:Connect(function()
        if not S.keyValid or not S.enabled then return end
        if not hum then grabHum(); return end

        local jumping = hum.Jump
        local wall    = detectWall()
        S.onWall      = wall

        if jumping and wall and not S.wasJump and not S.onCooldown then
            S.onCooldown = true
            rotateCamera(S.degree)
        end
        S.wasJump = jumping
    end)
end

-- ============================================================
-- GUI HELPERS
-- ============================================================
local function corner(parent, rad)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, rad or 10)
end

local function label(parent, props)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
    l.TextColor3 = Color3.fromRGB(220,220,255)
    for k,v in pairs(props) do l[k] = v end
    return l
end

local function frame(parent, props)
    local f = Instance.new("Frame", parent)
    f.BorderSizePixel = 0
    for k,v in pairs(props) do f[k] = v end
    return f
end

-- ============================================================
-- LOADING SCREEN
-- ============================================================
local function showLoading(pg, done)
    local sg = Instance.new("ScreenGui")
    sg.Name = "TopoOpLoad"
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 100
    sg.Parent = pg

    local bg = frame(sg, {
        Size = UDim2.fromScale(1,1),
        BackgroundColor3 = Color3.fromRGB(6,6,16),
    })

    local grd = Instance.new("UIGradient", bg)
    grd.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(6,6,20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10,4,28)),
    })
    grd.Rotation = 135

    -- Title
    local tit = label(bg, {
        Size = UDim2.new(1,0,0,50),
        Position = UDim2.new(0,0,0.33,0),
        Text = "TopoOp Wall Hop Hub",
        TextColor3 = Color3.fromRGB(0,200,255),
        Font = Enum.Font.GothamBold,
        TextSize = 30,
        TextTransparency = 1,
    })

    local sub = label(bg, {
        Size = UDim2.new(1,0,0,26),
        Position = UDim2.new(0,0,0.47,0),
        Text = "by TopoOp-ofc_mohd",
        TextColor3 = Color3.fromRGB(100,100,160),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextTransparency = 1,
    })

    -- Bar
    local barBg = frame(bg, {
        Size = UDim2.new(0.45,0,0,5),
        Position = UDim2.new(0.275,0,0.62,0),
        BackgroundColor3 = Color3.fromRGB(20,20,40),
    })
    corner(barBg, 4)

    local barFill = frame(barBg, {
        Size = UDim2.new(0,0,1,0),
        BackgroundColor3 = Color3.fromRGB(0,180,255),
    })
    corner(barFill, 4)

    local statLbl = label(bg, {
        Size = UDim2.new(1,0,0,20),
        Position = UDim2.new(0,0,0.67,0),
        Text = "Carregando...",
        TextColor3 = Color3.fromRGB(80,80,130),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextTransparency = 1,
    })

    -- Fade in
    TweenService:Create(tit,  TweenInfo.new(0.5), {TextTransparency=0}):Play()
    TweenService:Create(sub,  TweenInfo.new(0.5), {TextTransparency=0}):Play()
    TweenService:Create(statLbl, TweenInfo.new(0.5), {TextTransparency=0}):Play()

    local steps = {
        {0.25,"Verificando integridade..."},
        {0.5, "Carregando módulos..."},
        {0.75,"Configurando câmera..."},
        {1.0, "Pronto!"},
    }

    for _, s in ipairs(steps) do
        task.wait(0.3)
        statLbl.Text = s[2]
        TweenService:Create(barFill, TweenInfo.new(0.25,Enum.EasingStyle.Quad), {
            Size = UDim2.new(s[1],0,1,0)
        }):Play()
    end

    task.wait(0.4)

    -- Fade out
    for _, obj in ipairs({tit, sub, statLbl, barBg}) do
        TweenService:Create(obj, TweenInfo.new(0.35), {BackgroundTransparency=1, TextTransparency=1}):Play()
    end
    TweenService:Create(barFill, TweenInfo.new(0.35), {BackgroundTransparency=1}):Play()
    TweenService:Create(bg, TweenInfo.new(0.45), {BackgroundTransparency=1}):Play()

    task.wait(0.5)
    sg:Destroy()
    done()
end

-- ============================================================
-- KEY SCREEN
-- ============================================================
local function showKeyScreen(pg, onOk)
    local sg = Instance.new("ScreenGui")
    sg.Name = "TopoOpKeyScreen"
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 90
    sg.Parent = pg

    local overlay = frame(sg, {
        Size = UDim2.fromScale(1,1),
        BackgroundColor3 = Color3.fromRGB(6,6,16),
    })

    local card = frame(overlay, {
        Size = UDim2.new(0,360,0,210),
        Position = UDim2.new(0.5,-180,0.5,-105),
        BackgroundColor3 = Color3.fromRGB(12,12,26),
    })
    corner(card, 14)
    local cs = Instance.new("UIStroke", card)
    cs.Color = Color3.fromRGB(0,130,210)
    cs.Thickness = 1.5

    label(card, {
        Size = UDim2.new(1,0,0,40),
        Position = UDim2.new(0,0,0,12),
        Text = "🔑  Insira sua Key",
        TextColor3 = Color3.fromRGB(0,200,255),
        TextSize = 20,
    })

    label(card, {
        Size = UDim2.new(0.88,0,0,30),
        Position = UDim2.new(0.06,0,0,50),
        Text = "Acesse o site para obter sua Key.",
        TextColor3 = Color3.fromRGB(110,110,170),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
    })

    local inp = Instance.new("TextBox", card)
    inp.Size = UDim2.new(0.86,0,0,36)
    inp.Position = UDim2.new(0.07,0,0,88)
    inp.BackgroundColor3 = Color3.fromRGB(18,18,36)
    inp.BorderSizePixel = 0
    inp.Text = ""
    inp.PlaceholderText = "Cole sua Key aqui..."
    inp.TextColor3 = Color3.fromRGB(220,220,255)
    inp.PlaceholderColor3 = Color3.fromRGB(70,70,110)
    inp.Font = Enum.Font.GothamMono
    inp.TextSize = 13
    inp.ClearTextOnFocus = false
    corner(inp, 8)

    local errL = label(card, {
        Size = UDim2.new(1,0,0,16),
        Position = UDim2.new(0,0,0,132),
        Text = "",
        TextColor3 = Color3.fromRGB(255,80,80),
        Font = Enum.Font.Gotham,
        TextSize = 11,
    })

    local btn = Instance.new("TextButton", card)
    btn.Size = UDim2.new(0.5,0,0,36)
    btn.Position = UDim2.new(0.25,0,0,155)
    btn.BackgroundColor3 = Color3.fromRGB(0,130,210)
    btn.Text = "Verificar"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    corner(btn, 10)

    btn.MouseButton1Click:Connect(function()
        local k = inp.Text:gsub("%s","")
        if k == CFG.VALID_KEY then
            fWrite(CFG.KEY_FILE, k)
            sg:Destroy()
            onOk()
        else
            errL.Text = "Key inválida. Obtenha a sua no site."
            -- shake
            local orig = card.Position
            for i = 1, 4 do
                task.wait(0.04)
                card.Position = orig + UDim2.new(0, i%2==0 and 5 or -5, 0, 0)
            end
            card.Position = orig
        end
    end)
end

-- ============================================================
-- MAIN HUB
-- ============================================================
local function showHub(pg)
    local sg = Instance.new("ScreenGui")
    sg.Name = "TopoOpHub"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 80
    sg.Parent = pg

    -- JANELA PRINCIPAL
    local win = frame(sg, {
        Size = UDim2.new(0,310,0,300),
        Position = UDim2.new(0,18,0.5,-150),
        BackgroundColor3 = Color3.fromRGB(10,10,22),
        Active = true,
        Draggable = true,
    })
    corner(win, 14)
    local ws = Instance.new("UIStroke", win)
    ws.Color = Color3.fromRGB(0,120,200)
    ws.Thickness = 1.5

    -- Header
    local hdr = frame(win, {
        Size = UDim2.new(1,0,0,44),
        BackgroundColor3 = Color3.fromRGB(0,95,175),
    })
    corner(hdr, 14)
    frame(hdr, { -- fix bottom corners
        Size = UDim2.new(1,0,0.5,0),
        Position = UDim2.new(0,0,0.5,0),
        BackgroundColor3 = Color3.fromRGB(0,95,175),
    })
    label(hdr, {
        Size = UDim2.new(0.8,0,1,0),
        Position = UDim2.new(0,12,0,0),
        Text = "⚡  TopoOp Wall Hop Hub",
        TextColor3 = Color3.fromRGB(255,255,255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    label(hdr, {
        Size = UDim2.new(0,40,1,0),
        Position = UDim2.new(1,-44,0,0),
        Text = "v2.1",
        TextColor3 = Color3.fromRGB(160,220,255),
        Font = Enum.Font.GothamMono,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    local y = 52

    -- ---- TOGGLE ----
    local function addToggle(labelTxt, initVal, onChange)
        local row = frame(win, {
            Size = UDim2.new(0.88,0,0,32),
            Position = UDim2.new(0.06,0,0,y),
            BackgroundTransparency = 1,
        })
        y = y + 38

        label(row, {
            Size = UDim2.new(0.72,0,1,0),
            Text = labelTxt,
            TextColor3 = Color3.fromRGB(190,190,230),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        local tbg = frame(row, {
            Size = UDim2.new(0,44,0,22),
            Position = UDim2.new(1,-44,0.5,-11),
            BackgroundColor3 = initVal and Color3.fromRGB(0,155,75) or Color3.fromRGB(55,55,75),
        })
        corner(tbg, 20)

        local knob = frame(tbg, {
            Size = UDim2.new(0,18,0,18),
            Position = initVal and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9),
            BackgroundColor3 = Color3.fromRGB(255,255,255),
        })
        corner(knob, 20)

        local state = initVal
        local hitbx = Instance.new("TextButton", row)
        hitbx.Size = UDim2.fromScale(1,1)
        hitbx.BackgroundTransparency = 1
        hitbx.Text = ""

        hitbx.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(tbg, TweenInfo.new(0.18), {
                BackgroundColor3 = state and Color3.fromRGB(0,155,75) or Color3.fromRGB(55,55,75)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.18), {
                Position = state and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
            }):Play()
            onChange(state)
        end)
    end

    -- ---- SLIDER ----
    local function addSlider(labelTxt, mn, mx, initV, onChange)
        local row = frame(win, {
            Size = UDim2.new(0.88,0,0,50),
            Position = UDim2.new(0.06,0,0,y),
            BackgroundTransparency = 1,
        })
        y = y + 58

        label(row, {
            Size = UDim2.new(0.65,0,0,20),
            Text = labelTxt,
            TextColor3 = Color3.fromRGB(190,190,230),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        local valL = label(row, {
            Size = UDim2.new(0.35,0,0,20),
            Position = UDim2.new(0.65,0,0,0),
            Text = tostring(initV).."°",
            TextColor3 = Color3.fromRGB(0,200,255),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Right,
        })

        local track = frame(row, {
            Size = UDim2.new(1,0,0,5),
            Position = UDim2.new(0,0,0,32),
            BackgroundColor3 = Color3.fromRGB(25,25,50),
        })
        corner(track, 4)

        local fill = frame(track, {
            BackgroundColor3 = Color3.fromRGB(0,155,235),
        })
        corner(fill, 4)

        local knob = frame(track, {
            Size = UDim2.new(0,12,0,12),
            AnchorPoint = Vector2.new(0.5,0.5),
            BackgroundColor3 = Color3.fromRGB(255,255,255),
        })
        corner(knob, 20)

        local function setV(v)
            v = math.clamp(math.floor(v+0.5), mn, mx)
            local p = (v-mn)/(mx-mn)
            fill.Size = UDim2.new(p,0,1,0)
            knob.Position = UDim2.new(p,0,0.5,0)
            valL.Text = tostring(v).."°"
            onChange(v)
        end
        setV(initV)

        local drag = false
        local hb = Instance.new("TextButton", track)
        hb.Size = UDim2.new(1,0,0,18)
        hb.Position = UDim2.new(0,0,0.5,-9)
        hb.BackgroundTransparency = 1
        hb.Text = ""

        hb.MouseButton1Down:Connect(function() drag = true end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
        RunService.RenderStepped:Connect(function()
            if not drag then return end
            local mp = UserInputService:GetMouseLocation()
            local ap = track.AbsolutePosition
            local az = track.AbsoluteSize
            setV(mn + math.clamp((mp.X-ap.X)/az.X,0,1)*(mx-mn))
        end)
    end

    -- ---- CONTEÚDO ----
    addToggle("Wall Hop Ativo", S.enabled, function(v) S.enabled = v end)
    addSlider("Ângulo de Rotação", 5, 180, S.degree, function(v) S.degree = v end)

    -- divider
    frame(win, {
        Size = UDim2.new(0.82,0,0,1),
        Position = UDim2.new(0.09,0,0,y),
        BackgroundColor3 = Color3.fromRGB(25,25,50),
    })
    y = y + 10

    label(win, {
        Size = UDim2.new(0.88,0,0,28),
        Position = UDim2.new(0.06,0,0,y),
        Text = "ℹ️  Câmera gira só ao pular encostado na parede",
        TextColor3 = Color3.fromRGB(90,90,140),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    y = y + 32

    -- Status live
    local statLbl = label(win, {
        Size = UDim2.new(0.88,0,0,20),
        Position = UDim2.new(0.06,0,0,y),
        Text = "● Parede: não detectada",
        TextColor3 = Color3.fromRGB(70,70,110),
        Font = Enum.Font.GothamMono,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    RunService.Heartbeat:Connect(function()
        if S.onWall then
            statLbl.Text = "● Parede: DETECTADA"
            statLbl.TextColor3 = Color3.fromRGB(0,220,100)
        else
            statLbl.Text = "● Parede: não detectada"
            statLbl.TextColor3 = Color3.fromRGB(70,70,110)
        end
    end)
    y = y + 28

    -- aviso key
    label(win, {
        Size = UDim2.new(1,0,0,16),
        Position = UDim2.new(0,0,0,y),
        Text = "Não compartilhe sua Key — resulta em BAN",
        TextColor3 = Color3.fromRGB(160,50,50),
        Font = Enum.Font.Gotham,
        TextSize = 10,
    })

    -- Minimizar
    local minimized = false
    local minBtn = Instance.new("TextButton", win)
    minBtn.Size = UDim2.new(0,26,0,26)
    minBtn.Position = UDim2.new(1,-32,0,9)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.fromRGB(200,200,255)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 16
    minBtn.BorderSizePixel = 0

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(win, TweenInfo.new(0.22,Enum.EasingStyle.Quad), {
            Size = minimized and UDim2.new(0,310,0,44) or UDim2.new(0,310,0,300)
        }):Play()
        minBtn.Text = minimized and "□" or "—"
    end)

    -- ============================================================
    -- PAINEL BAN (somente dono)
    -- ============================================================
    if LocalPlayer.Name == CFG.OWNER then

        local banOpenBtn = Instance.new("TextButton", win)
        banOpenBtn.Size = UDim2.new(0,100,0,26)
        banOpenBtn.Position = UDim2.new(0.5,-50,0,265)
        banOpenBtn.BackgroundColor3 = Color3.fromRGB(150,25,25)
        banOpenBtn.Text = "🛡 Painel Ban"
        banOpenBtn.TextColor3 = Color3.fromRGB(255,255,255)
        banOpenBtn.Font = Enum.Font.GothamBold
        banOpenBtn.TextSize = 11
        banOpenBtn.BorderSizePixel = 0
        corner(banOpenBtn, 8)

        local bWin = frame(sg, {
            Size = UDim2.new(0,290,0,215),
            Position = UDim2.new(0.5,-145,0.5,-107),
            BackgroundColor3 = Color3.fromRGB(14,5,5),
            Visible = false,
            Active = true,
            Draggable = true,
        })
        corner(bWin, 14)
        local bStroke = Instance.new("UIStroke", bWin)
        bStroke.Color = Color3.fromRGB(190,30,30)
        bStroke.Thickness = 1.5

        local bHdr = frame(bWin, {
            Size = UDim2.new(1,0,0,40),
            BackgroundColor3 = Color3.fromRGB(150,25,25),
        })
        corner(bHdr, 14)
        frame(bHdr,{
            Size=UDim2.new(1,0,0.5,0),
            Position=UDim2.new(0,0,0.5,0),
            BackgroundColor3=Color3.fromRGB(150,25,25),
        })
        label(bHdr,{
            Size=UDim2.fromScale(1,1),
            Text="🛡  Painel de Banimento",
            TextColor3=Color3.fromRGB(255,255,255),
            TextSize=13,
        })

        -- Fechar
        local closeX = Instance.new("TextButton", bWin)
        closeX.Size = UDim2.new(0,24,0,24)
        closeX.Position = UDim2.new(1,-28,0,8)
        closeX.BackgroundTransparency = 1
        closeX.Text = "✕"
        closeX.TextColor3 = Color3.fromRGB(255,160,160)
        closeX.Font = Enum.Font.GothamBold
        closeX.TextSize = 14
        closeX.BorderSizePixel = 0
        closeX.MouseButton1Click:Connect(function() bWin.Visible = false end)

        -- Input
        local bInput = Instance.new("TextBox", bWin)
        bInput.Size = UDim2.new(0.84,0,0,32)
        bInput.Position = UDim2.new(0.08,0,0,52)
        bInput.BackgroundColor3 = Color3.fromRGB(24,8,8)
        bInput.BorderSizePixel = 0
        bInput.Text = ""
        bInput.PlaceholderText = "Nome do jogador..."
        bInput.TextColor3 = Color3.fromRGB(255,190,190)
        bInput.PlaceholderColor3 = Color3.fromRGB(100,50,50)
        bInput.Font = Enum.Font.GothamMono
        bInput.TextSize = 12
        bInput.ClearTextOnFocus = false
        corner(bInput, 8)

        local bFeed = label(bWin, {
            Size = UDim2.new(1,0,0,16),
            Position = UDim2.new(0,0,0,92),
            Text = "",
            Font = Enum.Font.Gotham,
            TextSize = 11,
        })

        local function actionBtn(xPct, txt, col, fn)
            local b = Instance.new("TextButton", bWin)
            b.Size = UDim2.new(0.38,0,0,30)
            b.Position = UDim2.new(xPct,0,0,114)
            b.BackgroundColor3 = col
            b.Text = txt
            b.TextColor3 = Color3.fromRGB(255,255,255)
            b.Font = Enum.Font.GothamBold
            b.TextSize = 11
            b.BorderSizePixel = 0
            corner(b, 8)
            b.MouseButton1Click:Connect(function()
                local n = bInput.Text:gsub("%s","")
                if n == "" then
                    bFeed.Text = "Digite um nome."
                    bFeed.TextColor3 = Color3.fromRGB(255,200,80)
                    return
                end
                local ok = fn(n)
                bFeed.Text = ok and (txt.." OK: "..n) or "Já feito ou inválido."
                bFeed.TextColor3 = ok and Color3.fromRGB(80,255,120) or Color3.fromRGB(255,100,100)
            end)
        end

        actionBtn(0.08,  "🔨 Banir",    Color3.fromRGB(170,35,35), banName)
        actionBtn(0.54,  "✅ Desbanir", Color3.fromRGB(35,125,55),  unbanName)

        -- Lista banidos
        local listL = label(bWin, {
            Size = UDim2.new(0.88,0,0,36),
            Position = UDim2.new(0.06,0,0,152),
            Font = Enum.Font.GothamMono,
            TextSize = 9,
            TextColor3 = Color3.fromRGB(170,90,90),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        })

        local function refreshList()
            local t = {}
            for k in pairs(Bans) do table.insert(t, k) end
            listL.Text = #t > 0 and ("Banidos: "..table.concat(t,", ")) or "Nenhum banido."
        end

        banOpenBtn.MouseButton1Click:Connect(function()
            refreshList()
            bWin.Visible = not bWin.Visible
        end)
    end
end

-- ============================================================
-- INIT
-- ============================================================
task.spawn(function()
    local pg = LocalPlayer:WaitForChild("PlayerGui", 15)
    if not pg then return end

    -- Loading
    showLoading(pg, function()

        -- Checa key salva
        local saved = fRead(CFG.KEY_FILE)
        if saved and saved:gsub("%s","") == CFG.VALID_KEY then
            S.keyValid = true
            showHub(pg)
            startLoop()
        else
            showKeyScreen(pg, function()
                S.keyValid = true
                showHub(pg)
                startLoop()
            end)
        end

    end)
end)
