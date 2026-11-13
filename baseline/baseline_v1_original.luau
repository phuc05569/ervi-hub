
-- RNG RollAttacks | Modular Hub v1
-- Feature 1: Cyborg M1 Cooldown (V6)
-- Potassium-compatible client-side GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HUB_NAME = "RNG_RollAttacks_Hub"
local M1_NAME = "RNG_Cyborg_M1_V6"
local COOLDOWN = 6.07

-- Clean up previously running versions
for _, key in ipairs({
    "RNG_HUB_STOP",
    "RNG_CYBORG_V6_STOP",
    "RNG_DIAG_V5_STOP"
}) do
    local stop = _G[key]
    if type(stop) == "function" then
        pcall(stop)
    end
end

for _, name in ipairs({
    HUB_NAME,
    M1_NAME,
    "RNG_AttackDiagnostic_V5"
}) do
    local old = playerGui:FindFirstChild(name)
    if old then
        old:Destroy()
    end
end

local running = true
local minimized = false
local connections = {}
local features = {}

local function connect(signal, callback, bucket)
    local connection = signal:Connect(function(...)
        if running then
            callback(...)
        end
    end)

    table.insert(bucket or connections, connection)
    return connection
end

local function disconnectBucket(bucket)
    for _, connection in ipairs(bucket) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    table.clear(bucket)
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 7)
    c.Parent = parent
    return c
end

local function makeLabel(parent, text, pos, size, fontSize)
    local label = Instance.new("TextLabel")
    label.Position = pos
    label.Size = size
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235, 235, 240)
    label.TextSize = fontSize or 14
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function makeButton(parent, text, pos, size, color)
    local button = Instance.new("TextButton")
    button.Position = pos
    button.Size = size
    button.BackgroundColor3 = color
        or Color3.fromRGB(55, 65, 85)
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 13
    button.Font = Enum.Font.Code
    button.BorderSizePixel = 0
    button.Parent = parent
    corner(button, 6)
    return button
end

local function equippedCyborg()
    local character = player.Character
    if not character then return false end

    local tool = character:FindFirstChild("Cyborg")
    return tool ~= nil and tool:IsA("Tool")
end

local function isOwnAttackBeam(obj)
    if not obj:IsA("Beam") or obj.Name ~= "Beam" then
        return false
    end

    local character = player.Character
    if not character then return false end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local smearFX = root:FindFirstChild("SmearFX")
    return smearFX ~= nil and obj:IsDescendantOf(smearFX)
end

-- =====================================================
-- Feature 1: Cyborg M1 Cooldown
-- =====================================================

local function stopM1()
    local feature = features.M1
    if not feature then return end

    disconnectBucket(feature.connections)

    if feature.gui then
        feature.gui:Destroy()
    end

    features.M1 = nil
    print("[RNG Hub] M1 Cooldown disabled.")
end

local function startM1()
    if features.M1 then return end

    local feature = {
        connections = {},
        gui = nil,
        lastAttackTime = nil,
        lastEffectTime = nil,
        attackCount = 0
    }

    features.M1 = feature

    local gui = Instance.new("ScreenGui")
    gui.Name = M1_NAME
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 300
    gui.Parent = playerGui
    feature.gui = gui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(285, 145)
    frame.Position = UDim2.new(0.5, -142, 0.72, 0)
    frame.BackgroundColor3 = Color3.fromRGB(24, 25, 31)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui
    corner(frame, 9)

    local title = makeLabel(
        frame,
        "CYBORG | M1 COOLDOWN",
        UDim2.fromOffset(12, 8),
        UDim2.new(1, -55, 0, 24),
        14
    )

    local close = makeButton(
        frame, "X",
        UDim2.new(1, -34, 0, 7),
        UDim2.fromOffset(27, 25),
        Color3.fromRGB(165, 45, 45)
    )

    local countdown = makeLabel(
        frame, "WAITING",
        UDim2.fromOffset(12, 38),
        UDim2.new(1, -24, 0, 43),
        29
    )
    countdown.TextXAlignment = Enum.TextXAlignment.Center

    local barBackground = Instance.new("Frame")
    barBackground.Position = UDim2.fromOffset(12, 89)
    barBackground.Size = UDim2.new(1, -24, 0, 10)
    barBackground.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
    barBackground.BorderSizePixel = 0
    barBackground.Parent = frame
    corner(barBackground, 6)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.fromScale(0, 1)
    bar.BackgroundColor3 = Color3.fromRGB(75, 165, 235)
    bar.BorderSizePixel = 0
    bar.Parent = barBackground
    corner(bar, 6)

    local status = makeLabel(
        frame, "Waiting for your Cyborg attack",
        UDim2.fromOffset(12, 105),
        UDim2.new(1, -24, 0, 18),
        11
    )
    status.TextXAlignment = Enum.TextXAlignment.Center

    local details = makeLabel(
        frame, "Detected: 0 | Estimate: 6.07s",
        UDim2.fromOffset(12, 124),
        UDim2.new(1, -24, 0, 16),
        10
    )
    details.TextXAlignment = Enum.TextXAlignment.Center

    connect(workspace.DescendantAdded, function(obj)
        if features.M1 ~= feature then return end
        if not isOwnAttackBeam(obj) then return end
        if not equippedCyborg() then return end

        local now = os.clock()

        if feature.lastEffectTime
            and now - feature.lastEffectTime < 0.5 then
            return
        end

        if feature.lastEffectTime then
            print(string.format(
                "[RNG Hub] Cyborg attack interval: %.3fs",
                now - feature.lastEffectTime
            ))
        end

        feature.lastEffectTime = now
        feature.lastAttackTime = now
        feature.attackCount = feature.attackCount + 1
    end, feature.connections)

    connect(RunService.RenderStepped, function()
        if features.M1 ~= feature then return end

        if not equippedCyborg() then
            countdown.Text = "UNEQUIPPED"
            countdown.TextColor3 =
                Color3.fromRGB(180, 180, 190)
            status.Text = "Equip Cyborg with key 1"
            bar.Size = UDim2.fromScale(0, 1)
            return
        end

        if not feature.lastAttackTime then
            countdown.Text = "WAITING"
            countdown.TextColor3 =
                Color3.fromRGB(225, 225, 225)
            status.Text = "Use M1 to detect first attack"
            bar.Size = UDim2.fromScale(0, 1)
            return
        end

        local elapsed = os.clock() - feature.lastAttackTime
        local remaining = math.max(0, COOLDOWN - elapsed)

        if remaining > 0 then
            countdown.Text = string.format("%.2fs", remaining)
            countdown.TextColor3 =
                Color3.fromRGB(245, 190, 85)
            status.Text = "Estimated M1 cooldown"
            bar.Size = UDim2.fromScale(
                remaining / COOLDOWN, 1
            )
        else
            countdown.Text = "READY"
            countdown.TextColor3 =
                Color3.fromRGB(100, 225, 140)
            status.Text = "Estimated cooldown complete"
            bar.Size = UDim2.fromScale(0, 1)
        end

        details.Text = string.format(
            "Detected: %d | Estimate: %.2fs",
            feature.attackCount,
            COOLDOWN
        )
    end, feature.connections)

    -- This listener is owned by the feature.
    -- Closing the overlay disables only M1.
    connect(close.MouseButton1Click, function()
        stopM1()
    end, feature.connections)

    print("[RNG Hub] M1 Cooldown enabled.")
end

-- =====================================================
-- Main Hub GUI
-- =====================================================

local hubGui = Instance.new("ScreenGui")
hubGui.Name = HUB_NAME
hubGui.ResetOnSpawn = false
hubGui.DisplayOrder = 350
hubGui.Parent = playerGui

local hub = Instance.new("Frame")
hub.Size = UDim2.fromOffset(340, 245)
hub.Position = UDim2.new(0.5, -170, 0.25, 0)
hub.BackgroundColor3 = Color3.fromRGB(25, 26, 33)
hub.BorderSizePixel = 0
hub.Active = true
hub.Draggable = true
hub.Parent = hubGui
corner(hub, 9)

local header = makeLabel(
    hub, "RNG ROLLATTACKS HUB",
    UDim2.fromOffset(14, 9),
    UDim2.new(1, -90, 0, 28),
    17
)

local minimizeButton = makeButton(
    hub, "-",
    UDim2.new(1, -72, 0, 9),
    UDim2.fromOffset(28, 26),
    Color3.fromRGB(70, 75, 90)
)

local closeHubButton = makeButton(
    hub, "X",
    UDim2.new(1, -38, 0, 9),
    UDim2.fromOffset(28, 26),
    Color3.fromRGB(165, 45, 45)
)

local divider = Instance.new("Frame")
divider.Position = UDim2.fromOffset(12, 43)
divider.Size = UDim2.new(1, -24, 0, 1)
divider.BackgroundColor3 = Color3.fromRGB(65, 68, 80)
divider.BorderSizePixel = 0
divider.Parent = hub

local featureTitle = makeLabel(
    hub, "FEATURES",
    UDim2.fromOffset(14, 54),
    UDim2.new(1, -28, 0, 22),
    13
)

local m1Button = makeButton(
    hub, "M1 Cooldown",
    UDim2.fromOffset(14, 85),
    UDim2.fromOffset(312, 36),
    Color3.fromRGB(55, 100, 160)
)

local slot2 = makeButton(
    hub, "Feature 2 - Coming Soon",
    UDim2.fromOffset(14, 130),
    UDim2.fromOffset(312, 36),
    Color3.fromRGB(48, 49, 59)
)
slot2.AutoButtonColor = false

local slot3 = makeButton(
    hub, "Feature 3 - Coming Soon",
    UDim2.fromOffset(14, 175),
    UDim2.fromOffset(312, 36),
    Color3.fromRGB(48, 49, 59)
)
slot3.AutoButtonColor = false

local footer = makeLabel(
    hub, "Modular Hub v1",
    UDim2.fromOffset(14, 220),
    UDim2.new(1, -28, 0, 16),
    10
)
footer.TextColor3 = Color3.fromRGB(145, 145, 155)

local function updateM1Button()
    if features.M1 then
        m1Button.Text = "M1 Cooldown  [ON]"
        m1Button.BackgroundColor3 =
            Color3.fromRGB(45, 130, 90)
    else
        m1Button.Text = "M1 Cooldown  [OFF]"
        m1Button.BackgroundColor3 =
            Color3.fromRGB(55, 100, 160)
    end
end

local function stopHub()
    if not running then return end

    stopM1()
    running = false

    disconnectBucket(connections)

    hubGui:Destroy()

    _G.RNG_HUB_STOP = nil
    print("[RNG Hub] Fully stopped and cleaned.")
end

_G.RNG_HUB_STOP = stopHub

connect(m1Button.MouseButton1Click, function()
    if features.M1 then
        stopM1()
    else
        startM1()
    end

    updateM1Button()
end)

connect(minimizeButton.MouseButton1Click, function()
    minimized = not minimized

    if minimized then
        hub.Size = UDim2.fromOffset(340, 45)
        minimizeButton.Text = "+"
    else
        hub.Size = UDim2.fromOffset(340, 245)
        minimizeButton.Text = "-"
    end

    divider.Visible = not minimized
    featureTitle.Visible = not minimized
    m1Button.Visible = not minimized
    slot2.Visible = not minimized
    slot3.Visible = not minimized
    footer.Visible = not minimized
end)

connect(closeHubButton.MouseButton1Click, stopHub)

-- Keep hub button synchronized when overlay X is used
connect(RunService.Heartbeat, function()
    local shouldBeOn = features.M1 ~= nil

    if shouldBeOn and m1Button.Text ~= "M1 Cooldown  [ON]" then
        updateM1Button()
    elseif not shouldBeOn
        and m1Button.Text ~= "M1 Cooldown  [OFF]" then
        updateM1Button()
    end
end)

updateM1Button()

print("[RNG Hub] Loaded.")
print("[RNG Hub] Click M1 Cooldown to open V6.")
print("[RNG Hub] Hub X removes all hub features.")
