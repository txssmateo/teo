--//====================================================
--// MATEO UTILITY V4.1 - IMAGE AUTHENTICATION GATE
--//====================================================

do
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")

    local LocalPlayer = Players.LocalPlayer
    local AUTH_URL = "https://access-auth.txssmateo.workers.dev/"
    local AUTH_IMAGE = "rbxassetid://109860566447823"

    local requestFn =
        (syn and syn.request)
        or (http and http.request)
        or http_request
        or request

    local parentGui = CoreGui
    pcall(function()
        if gethui then parentGui = gethui() end
    end)

    local oldAuth = parentGui:FindFirstChild("MateoUtilityAuth")
    if oldAuth then oldAuth:Destroy() end

    local screen = Instance.new("ScreenGui")
    screen.Name = "MateoUtilityAuth"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.DisplayOrder = 999999
    screen.Parent = parentGui

    -- Full-screen darkened backdrop.
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.25
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 1
    backdrop.Parent = screen

    -- Exact auth artwork used in the Studio version.
    local image = Instance.new("ImageLabel")
    image.Name = "AuthImage"
    image.Size = UDim2.fromScale(1, 1)
    image.Position = UDim2.fromScale(0, 0)
    image.AnchorPoint = Vector2.new(0, 0)
    image.BackgroundTransparency = 0
    image.BackgroundColor3 = Color3.fromRGB(255,255,255)
    image.Image = AUTH_IMAGE
    image.ScaleType = Enum.ScaleType.Stretch
    image.ZIndex = 2
    image.Parent = screen

    -- Functional key field positioned over the artwork.
    local keyBox = Instance.new("TextBox")
    keyBox.Name = "KeyBox"
    keyBox.Position = UDim2.new(0.075, 0, 0.515, 0)
    keyBox.Size = UDim2.new(0.355, 0, 0.105, 0)
    keyBox.BackgroundColor3 = Color3.fromRGB(255,255,255)
    keyBox.BackgroundTransparency = 1
    keyBox.BorderSizePixel = 0
    keyBox.ClearTextOnFocus = false
    keyBox.Text = ""
    keyBox.TextColor3 = Color3.fromRGB(180,180,180)
    keyBox.TextSize = 21
    keyBox.Font = Enum.Font.SourceSans
    keyBox.PlaceholderText = "ENTER ACCESS KEY"
    keyBox.PlaceholderColor3 = Color3.fromRGB(127,127,127)
    keyBox.TextTransparency = 0
    keyBox.TextXAlignment = Enum.TextXAlignment.Left
    keyBox.ZIndex = 3
    keyBox.Parent = image

    local keyPadding = Instance.new("UIPadding")
    keyPadding.PaddingLeft = UDim.new(0.04, 0)
    keyPadding.PaddingRight = UDim.new(0.04, 0)
    -- Move the key-field text ~5 px upward without moving/resizing the field itself.
    keyPadding.PaddingBottom = UDim.new(0, 10)
    keyPadding.Parent = keyBox

    -- Functional authenticate button positioned over the artwork.
    local submit = Instance.new("TextButton")
    submit.Name = "AuthenticateButton"
    submit.Position = UDim2.new(0.075, 0, 0.655, 0)
    submit.Size = UDim2.new(0.355, 0, 0.105, 0)
    submit.BackgroundColor3 = Color3.fromRGB(255,255,255)
    submit.BackgroundTransparency = 1
    submit.BorderSizePixel = 0
    submit.AutoButtonColor = false
    submit.Text = "AUTHENTICATE"
    submit.TextColor3 = Color3.fromRGB(180,180,180)
    submit.TextSize = 22
    submit.Font = Enum.Font.SourceSans
    submit.TextTransparency = 0
    submit.TextXAlignment = Enum.TextXAlignment.Center
    submit.ZIndex = 3
    submit.Parent = image

    -- Move AUTHENTICATE ~5 px downward without moving/resizing the button itself.
    local submitPadding = Instance.new("UIPadding")
    submitPadding.PaddingTop = UDim.new(0, 10)
    submitPadding.Parent = submit

    -- Black overlay used only for the successful fade-out.
    local fadeOverlay = Instance.new("Frame")
    fadeOverlay.Name = "FadeOverlay"
    fadeOverlay.Size = UDim2.fromScale(1, 1)
    fadeOverlay.Position = UDim2.fromScale(0, 0)
    fadeOverlay.BackgroundColor3 = Color3.new(0,0,0)
    fadeOverlay.BackgroundTransparency = 1
    fadeOverlay.BorderSizePixel = 0
    fadeOverlay.Visible = true
    fadeOverlay.ZIndex = 10
    fadeOverlay.Parent = screen

    local authenticated = false
    local busy = false

    local function restoreButton()
        submit.Text = "AUTHENTICATE"
        submit.Active = true
        keyBox.TextEditable = true
        busy = false
    end

    local function flashButton(text)
        submit.Text = text
        task.wait(1)
        if not authenticated then restoreButton() end
    end

    local function authenticate()
        if busy or authenticated then return end

        local enteredKey = keyBox.Text
        if enteredKey == "" then
            busy = true
            submit.Active = false
            flashButton("ENTER A KEY")
            return
        end

        if not requestFn then
            busy = true
            submit.Active = false
            flashButton("CONNECTION ERROR")
            return
        end

        busy = true
        submit.Active = false
        keyBox.TextEditable = false
        submit.Text = "AUTHENTICATING..."

        local ok, response = pcall(function()
            return requestFn({
                Url = AUTH_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    key = enteredKey,
                    userId = tostring(LocalPlayer.UserId)
                })
            })
        end)

        if not ok or not response then
            flashButton("CONNECTION ERROR")
            return
        end

        local body = response.Body or response.body or ""
        local statusCode = tonumber(response.StatusCode or response.Status or response.status_code)

        local decoded
        pcall(function()
            decoded = HttpService:JSONDecode(body)
        end)

        local allowed = type(decoded) == "table"
            and (decoded.success == true or decoded.authorized == true)

        if allowed then
            authenticated = true
            submit.Text = "ACCESS GRANTED"
            task.wait(0.65)

            local tween = TweenService:Create(
                fadeOverlay,
                TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 0}
            )
            tween:Play()
            tween.Completed:Wait()
            screen:Destroy()
            return
        end

        if statusCode == 401 then
            flashButton("INVALID KEY")
        elseif statusCode == 403 then
            flashButton("USER NOT AUTHORIZED")
        else
            local msg = type(decoded) == "table" and tostring(decoded.message or "") or ""
            local lower = string.lower(msg)
            if string.find(lower, "invalid key", 1, true) then
                flashButton("INVALID KEY")
            elseif string.find(lower, "whitelist", 1, true)
                or string.find(lower, "authorized", 1, true) then
                flashButton("USER NOT AUTHORIZED")
            else
                flashButton("CONNECTION ERROR")
            end
        end
    end

    submit.MouseButton1Click:Connect(authenticate)
    keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then authenticate() end
    end)

    repeat task.wait() until authenticated or not screen.Parent
    if not authenticated then return end
end

--//====================================================
--// AUTH PASSED - LOAD FULL MATEO UTILITY V4.1
--//====================================================

--//====================================================
--// MATEO UTILITY V4.1
--// FINAL COMBINED BUILD
--// PART 1
--//====================================================
--//
--// Survivor ESP
--// Beast ESP
--// Computer ESP
--// Hatch ESP
--// Locker / Vent ESP
--// Exit OPEN indicator
--// Hitbox Expander
--// Permanent Full Bright
--//
--// Hitbox:
--//   0 = OFF / NORMAL
--//   1 = 5x5x5
--//   2 = 6x6x6
--//
--// Credits to saintedmateo ✝
--//====================================================


--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Beast1 = RS:WaitForChild("Beast1")
local Beast2 = RS:WaitForChild("Beast2")


--==================================================
-- CLEANUP PREVIOUS MATEO UTILITY
--==================================================

local connectionNames = {
    "MateoUtilityConnection",
    "MateoComputerConnection",
    "MateoSkillConnection",
    "MateoMapConnection",

    "MateoLightingConnection1",
    "MateoLightingConnection2",
    "MateoLightingConnection3",
    "MateoLightingConnection4",

    "MateoHatchAddedConnection",
    "MateoHatchRemovingConnection",

    "MateoExitConnection",
    "MateoHitboxConnection"
}

for _, name in ipairs(connectionNames) do

    local connection = _G[name]

    if connection then

        pcall(function()
            connection:Disconnect()
        end)

        _G[name] = nil
    end
end


-- Remove old GUI.

local oldGUI = PlayerGui:FindFirstChild("MateoUtility")

if oldGUI then
    oldGUI:Destroy()
end


-- Remove diagnostic GUIs if they still exist.

for _, name in ipairs({
    "MateoCheckpointWatcher",
    "CleanCheckpointWatcher",
    "CheckpointWatcher",
    "MateoDiagnostic",
    "ComputerDiagnostic",
    "ComputerProgressDiagnostic",
    "HatchDiagnostic",
    "HatchWatcher",
    "ExitDiagnostic",
    "HitboxDiagnostic"
}) do

    local old = PlayerGui:FindFirstChild(name)

    if old then
        old:Destroy()
    end
end


--==================================================
-- REMOVE OLD ESP OBJECTS
--==================================================

for _, obj in ipairs(workspace:GetDescendants()) do

    if obj.Name == "MateoComputerHighlight"
        or obj.Name == "MateoComputerPercent"

        or obj.Name == "MateoLockerVentHighlight"

        or obj.Name == "MateoHatchHighlight"
        or obj.Name == "MateoHatchTag"

        or obj.Name == "MateoExitHighlight"
        or obj.Name == "MateoExitTag"

        or obj.Name == "MateoHitboxVisual"

    then

        pcall(function()
            obj:Destroy()
        end)
    end
end


local function removeNamedPlayerESP(character)

    if not character then
        return
    end


    for _, name in ipairs({

        "MateoBeastHighlight",
        "MateoSurvivorHighlight"

    }) do

        local object = character:FindFirstChild(name)

        if object then
            object:Destroy()
        end
    end


    local head = character:FindFirstChild("Head")

    if head then

        for _, name in ipairs({

            "MateoBeastTag",
            "MateoSurvivorTag"

        }) do

            local object = head:FindFirstChild(name)

            if object then
                object:Destroy()
            end
        end
    end
end


for _, player in ipairs(Players:GetPlayers()) do
    removeNamedPlayerESP(player.Character)
end


--==================================================
-- STATES
--==================================================

-- Three-state ESP:
--
-- 2 = FULL
-- 1 = HL ONLY
-- 0 = OFF
--
-- Used by:
-- Beast
-- Survivor
-- Computer
-- Hatch


local States = {

    SurvivorESP = 2,
    BeastESP = 2,
    ComputerESP = 2,
    HatchESP = 2,


    -- Binary ESP.
    --
    -- 1 = ON / FULL
    -- 0 = OFF
    --
    -- IMPORTANT:
    -- Locker/Vent and Exit do NOT have HL ONLY mode.

    LockerVentESP = 1,
    ExitESP = 1,

    -- Auto Rope binary toggle.
    -- 1 = ON / 0 = OFF
    AutoRope = 1,


    -- Hitbox slider.
    --
    -- 0 = NORMAL
    -- 1 = 5x5x5
    -- 2 = 6x6x6

    HitboxLevel = 0
}


--==================================================
-- PERMANENT FULL BRIGHT
--==================================================

local FULL_BRIGHT = {

    Brightness = 3,
    ClockTime = 14,
    FogEnd = 100000,
    GlobalShadows = false
}


local function enforceFullBright()

    for property, value in pairs(FULL_BRIGHT) do

        if Lighting[property] ~= value then
            Lighting[property] = value
        end
    end
end


enforceFullBright()


_G.MateoLightingConnection1 =
Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()

    if Lighting.Brightness ~= FULL_BRIGHT.Brightness then
        Lighting.Brightness = FULL_BRIGHT.Brightness
    end

end)


_G.MateoLightingConnection2 =
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()

    if Lighting.ClockTime ~= FULL_BRIGHT.ClockTime then
        Lighting.ClockTime = FULL_BRIGHT.ClockTime
    end

end)


_G.MateoLightingConnection3 =
Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()

    if Lighting.FogEnd ~= FULL_BRIGHT.FogEnd then
        Lighting.FogEnd = FULL_BRIGHT.FogEnd
    end

end)


_G.MateoLightingConnection4 =
Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(function()

    if Lighting.GlobalShadows ~= FULL_BRIGHT.GlobalShadows then
        Lighting.GlobalShadows = FULL_BRIGHT.GlobalShadows
    end

end)


--==================================================
-- COLORS
--==================================================

local Colors = {

    Background = Color3.fromRGB(43,46,52),

    Header =
        Color3.fromRGB(34,37,42),

    Text =
        Color3.fromRGB(248,248,250),

    Muted =
        Color3.fromRGB(165,169,178),

    Accent =
        Color3.fromRGB(52,199,115),

    AccentBright =
        Color3.fromRGB(72,220,135),

    Full =
        Color3.fromRGB(47,145,91),

    HL =
        Color3.fromRGB(177,128,38),

    Off =
        Color3.fromRGB(145,60,65),

    Beast =
        Color3.fromRGB(255,55,55),

    Survivor =
        Color3.fromRGB(60,155,255),

    Computer =
        Color3.fromRGB(255,215,65),

    Hatch =
        Color3.fromRGB(40,255,130),

    ExitOpen =
        Color3.fromRGB(70,255,125),

    LockerVent =
        Color3.fromRGB(40,185,255),

    SwitchOff =
        Color3.fromRGB(75,79,87)
}


--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")

gui.Name = "MateoUtility"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = PlayerGui


--==================================================
-- SETTINGS BUTTON
--==================================================

local gear = Instance.new("TextButton")

gear.Name = "SettingsButton"

gear.Size =
    UDim2.fromOffset(31,31)

gear.Position =
    UDim2.new(0,7,0,335)

gear.BackgroundColor3 =
    Colors.Header

gear.BackgroundTransparency = 0.08

gear.Text = "⚙"

gear.TextColor3 =
    Colors.Text

gear.TextSize = 17

gear.Font =
    Enum.Font.Gotham

gear.AutoButtonColor = false
gear.Active = true

gear.ZIndex = 10
gear.Parent = gui


local gearCorner =
    Instance.new("UICorner")

gearCorner.CornerRadius =
    UDim.new(0,8)

gearCorner.Parent = gear


local gearStroke =
    Instance.new("UIStroke")

gearStroke.Color =
    Colors.Accent

gearStroke.Thickness = 1
gearStroke.Transparency = 0.25

gearStroke.Parent = gear


--==================================================
-- FREEZEPOD CLEAN V7 - INDEPENDENT MINI CONTROL
-- A one-press, manual rescue button immediately
-- underneath the settings gear (same size / X).
-- NOT a settings menu item or an auto-rescue loop.
--==================================================

do
    -- Disconnect any earlier copy before recreating.
    local previous = _G.MattFreezePodMiniCleanup
    if type(previous) == "function" then
        pcall(previous)
    end
    if getgenv then
        local environment = getgenv()
        previous = environment.MattFreezePodMiniCleanup
        if type(previous) == "function" then
            pcall(previous)
        end

        -- Also retire old, standalone diagnostic/clean GUIs.
        for _, key in ipairs({
            "FreezePodDiagnosticV6Cleanup",
            "FreezePodDiagnosticV7Cleanup",
            "FreezePodCleanV7Cleanup"
        }) do
            local cleanupOld = environment[key]
            if type(cleanupOld) == "function" then
                pcall(cleanupOld)
            end
            environment[key] = nil
        end
    end

    for _, name in ipairs({
        "MattFreezePodMini",
        "FreezePodDiagnosticV6",
        "FreezePodDiagnosticV7",
        "FreezePodCleanV7"
    }) do
        local old = PlayerGui:FindFirstChild(name)
        if old then
            old:Destroy()
        end
    end

    local VirtualInputManager = game:GetService("VirtualInputManager")
    local active = true
    local rescuing = false
    local attemptId = 0
    local originalCFrame = nil
    local podConnections = {}

    local podGui = Instance.new("ScreenGui")
    podGui.Name = "MattFreezePodMini"
    podGui.ResetOnSpawn = false
    podGui.IgnoreGuiInset = gui.IgnoreGuiInset
    podGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    podGui.DisplayOrder = gui.DisplayOrder + 1
    podGui.Parent = PlayerGui

    local podButton = Instance.new("TextButton")
    podButton.Name = "FastRescueButton"
    podButton.Size = gear.Size
    podButton.BackgroundColor3 = Colors.Header
    podButton.BackgroundTransparency = gear.BackgroundTransparency
    podButton.BorderSizePixel = 0
    podButton.Text = "FP"
    podButton.TextColor3 = Colors.Text
    podButton.TextSize = 11
    podButton.Font = Enum.Font.GothamBold
    podButton.AutoButtonColor = false
    podButton.Active = true
    podButton.ZIndex = 10
    podButton.Parent = podGui

    local podCorner = Instance.new("UICorner")
    podCorner.CornerRadius = UDim.new(0, 8)
    podCorner.Parent = podButton

    local podStroke = Instance.new("UIStroke")
    podStroke.Color = Colors.Accent
    podStroke.Thickness = 1
    podStroke.Transparency = 0.25
    podStroke.Parent = podButton

    -- Follow the gear precisely, even if its position or size changes.
    local function positionBelowGear()
        if not active then return end
        podButton.Size = gear.Size
        podButton.Position = UDim2.new(
            gear.Position.X.Scale, gear.Position.X.Offset,
            gear.Position.Y.Scale,
            gear.Position.Y.Offset + gear.Size.Y.Offset + 7
        )
    end
    positionBelowGear()

    local function podConnect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(podConnections, connection)
        return connection
    end

    local function setPodDisplay(label, color, resetAfter)
        if not active or not podButton.Parent then return end
        podButton.Text = label
        podButton.BackgroundColor3 = color
        if resetAfter then
            local id = attemptId
            task.delay(resetAfter, function()
                if active and not rescuing and attemptId == id then
                    podButton.Text = "FP"
                    podButton.BackgroundColor3 = Colors.Header
                end
            end)
        end
    end

    local function getRoot()
        local character = LocalPlayer.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end

    -- Original Clean V7 occupied-pod check.
    local function findOccupiedPod()
        local map = workspace:FindFirstChild("Map")
        if not map then return nil end
        for _, object in ipairs(map:GetDescendants()) do
            if object:IsA("Model")
                and object.Name == "FreezePod"
                and object:GetAttribute("Player") ~= nil then
                return object
            end
        end
        return nil
    end

    local function findTrigger(pod)
        if not pod then return nil end
        local trigger = pod:FindFirstChild("PodTrigger", true)
        if trigger and trigger:IsA("BasePart") then
            return trigger
        end
        return nil
    end

    local function returnToStart()
        local root = getRoot()
        if root and originalCFrame then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = originalCFrame
        end
        originalCFrame = nil
    end

    local function finishAttempt(id, label, color)
        if not active or not rescuing or id ~= attemptId then return end
        returnToStart()
        rescuing = false
        setPodDisplay(label, color, 1.2)
    end

    -- Original five E taps and exact intervals retained.
    local function spamE(id)
        task.spawn(function()
            for i = 1, 5 do
                if not active or not rescuing or id ~= attemptId then break end
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.012)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                if i < 5 then
                    task.wait(0.025)
                end
            end
        end)
    end

    -- Hook confirmation asynchronously so the rest of Matt's
    -- utility isn't held up waiting for a game remote.
    task.spawn(function()
        local podFreed = RS:WaitForChild("PodFreed")
        if not active or not podFreed:IsA("RemoteEvent") then return end
        podConnect(podFreed.OnClientEvent, function(...)
            if not rescuing then return end
            local id = attemptId
            task.wait()
            finishAttempt(id, "OK", Colors.Full)
        end)
    end)

    -- Single click = one manual attempt; no automatic repeated rescues.
    podConnect(podButton.MouseButton1Click, function()
        if not active or rescuing then return end
        attemptId += 1
        local id = attemptId

        local pod = findOccupiedPod()
        local trigger = findTrigger(pod)
        local root = getRoot()
        local freezePodRemote = RS:FindFirstChild("FreezePod")

        if not pod then
            setPodDisplay("NP", Colors.Off, 1.2)
            return
        end
        if not trigger or not root or not freezePodRemote
            or not freezePodRemote:IsA("RemoteEvent") then
            setPodDisplay("NA", Colors.Off, 1.2)
            return
        end

        rescuing = true
        originalCFrame = root.CFrame
        setPodDisplay("...", Colors.Accent)

        local target = trigger.Position
            + trigger.CFrame.LookVector * 3
            + Vector3.new(0, 2.5, 0)
        local lookAt = Vector3.new(
            trigger.Position.X, target.Y, trigger.Position.Z
        )

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = CFrame.lookAt(target, lookAt)

        spamE(id)
        task.wait(0.13)
        if not active or not rescuing or id ~= attemptId then return end

        local fired = pcall(function()
            freezePodRemote:FireServer(pod)
        end)
        if not fired then
            finishAttempt(id, "NA", Colors.Off)
            return
        end

        task.delay(1.5, function()
            finishAttempt(id, "??", Colors.HL)
        end)
    end)

    local function cleanup()
        if not active then return end
        active = false
        attemptId += 1
        if rescuing then returnToStart() end
        rescuing = false

        for _, connection in ipairs(podConnections) do
            pcall(function() connection:Disconnect() end)
        end
        if podGui.Parent then
            podGui:Destroy()
        end
        if _G.MattFreezePodMiniCleanup == cleanup then
            _G.MattFreezePodMiniCleanup = nil
        end
        if getgenv then
            local environment = getgenv()
            if environment.MattFreezePodMiniCleanup == cleanup then
                environment.MattFreezePodMiniCleanup = nil
            end
        end
    end

    podConnect(gear:GetPropertyChangedSignal("Position"), positionBelowGear)
    podConnect(gear:GetPropertyChangedSignal("Size"), positionBelowGear)
    podConnect(gui.Destroying, cleanup)
    podConnect(podGui.Destroying, cleanup)
    _G.MattFreezePodMiniCleanup = cleanup
    if getgenv then
        getgenv().MattFreezePodMiniCleanup = cleanup
    end
end

-- FP = ready | ... = attempting | OK = event confirmation
-- NP = no occupied pod | NA = unavailable | ?? = no confirmation


--==================================================
-- MAIN MENU
--==================================================

local menu = Instance.new("Frame")

menu.Name = "Menu"

menu.Size =
    UDim2.fromOffset(215,357)

menu.Position =
    UDim2.new(0,47,0,335)

menu.BackgroundColor3 =
    Colors.Background

menu.BackgroundTransparency = 0.08

menu.Visible = true
menu.Active = true

menu.Parent = gui


local menuCorner =
    Instance.new("UICorner")

menuCorner.CornerRadius =
    UDim.new(0,9)

menuCorner.Parent = menu


local menuStroke =
    Instance.new("UIStroke")

menuStroke.Color =
    Colors.Accent

menuStroke.Thickness = 1
menuStroke.Transparency = 0.55

menuStroke.Parent = menu


--==================================================
-- HEADER
--==================================================

local header = Instance.new("Frame")

header.Name = "Header"

header.Size =
    UDim2.new(1,0,0,38)

header.BackgroundColor3 =
    Colors.Header

header.BackgroundTransparency = 0.12

header.Active = true

header.ZIndex = 5
header.Parent = menu


local headerCorner =
    Instance.new("UICorner")

headerCorner.CornerRadius =
    UDim.new(0,9)

headerCorner.Parent = header


local title =
    Instance.new("TextLabel")

title.Size =
    UDim2.fromScale(1,1)

title.BackgroundTransparency = 1

title.Text = "SETTINGS"

title.TextColor3 =
    Colors.Text

title.TextSize = 13

title.Font =
    Enum.Font.GothamBold

title.ZIndex = 6
title.Parent = header


local accentLine =
    Instance.new("Frame")

accentLine.Size =
    UDim2.new(1,-18,0,2)

accentLine.Position =
    UDim2.new(0,9,1,-2)

accentLine.BackgroundColor3 =
    Colors.Accent

accentLine.BorderSizePixel = 0

accentLine.ZIndex = 6
accentLine.Parent = header


--==================================================
-- PLAYER ESP HELPERS
--==================================================

local function removeBeastESP(character)

    if not character then
        return
    end


    local h =
        character:FindFirstChild(
            "MateoBeastHighlight"
        )

    if h then
        h:Destroy()
    end


    local head =
        character:FindFirstChild("Head")

    if head then

        local tag =
            head:FindFirstChild(
                "MateoBeastTag"
            )

        if tag then
            tag:Destroy()
        end
    end
end


local function removeSurvivorESP(character)

    if not character then
        return
    end


    local h =
        character:FindFirstChild(
            "MateoSurvivorHighlight"
        )

    if h then
        h:Destroy()
    end


    local head =
        character:FindFirstChild("Head")

    if head then

        local tag =
            head:FindFirstChild(
                "MateoSurvivorTag"
            )

        if tag then
            tag:Destroy()
        end
    end
end


local function removeBeastLabel(character)

    if not character then
        return
    end


    local head =
        character:FindFirstChild("Head")

    if not head then
        return
    end


    local tag =
        head:FindFirstChild(
            "MateoBeastTag"
        )

    if tag then
        tag:Destroy()
    end
end


local function removeSurvivorLabel(character)

    if not character then
        return
    end


    local head =
        character:FindFirstChild("Head")

    if not head then
        return
    end


    local tag =
        head:FindFirstChild(
            "MateoSurvivorTag"
        )

    if tag then
        tag:Destroy()
    end
end


local function removeAllBeastESP()

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        removeBeastESP(
            player.Character
        )
    end
end


local function removeAllSurvivorESP()

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        removeSurvivorESP(
            player.Character
        )
    end
end


local function isBeast(player)

    return
        player == Beast1.Value
        or player == Beast2.Value
end


local function isSurvivor(player)

    if isBeast(player) then
        return false
    end


    if player:GetAttribute("Escaped") == true then
        return false
    end


    if not player.Character then
        return false
    end


    return true
end


--==================================================
-- BEAST ESP
--==================================================

local function ensureBeastHighlight(player)

    local character =
        player.Character

    if not character then
        return
    end


    removeSurvivorESP(character)


    local h =
        character:FindFirstChild(
            "MateoBeastHighlight"
        )


    if not h then

        h = Instance.new("Highlight")

        h.Name =
            "MateoBeastHighlight"

        h.FillColor =
            Colors.Beast

        h.FillTransparency = 0.72

        h.OutlineColor =
            Color3.fromRGB(
                255,
                20,
                20
            )

        h.OutlineTransparency = 0

        h.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        h.Parent = character
    end
end


local function ensureBeastLabel(player)

    local character =
        player.Character

    if not character then
        return
    end


    local head =
        character:FindFirstChild("Head")

    if not head then
        return
    end


    local billboard =
        head:FindFirstChild(
            "MateoBeastTag"
        )


    if not billboard then

        billboard =
            Instance.new("BillboardGui")

        billboard.Name =
            "MateoBeastTag"

        billboard.Size =
            UDim2.fromOffset(210,58)

        -- Keep the Beast label consistently
        -- above the character at distance.

        billboard.StudsOffsetWorldSpace =
            Vector3.new(0,3.15,0)

        billboard.AlwaysOnTop = true

        billboard.Parent = head


        local abilityLabel =
            Instance.new("TextLabel")

        abilityLabel.Name =
            "Ability"

        abilityLabel.Size =
            UDim2.new(1,0,0,22)

        abilityLabel.BackgroundTransparency = 1

        abilityLabel.TextColor3 =
            Colors.Beast

        abilityLabel.TextStrokeTransparency =
            0.18

        abilityLabel.TextSize = 15

        abilityLabel.Font =
            Enum.Font.GothamBold

        abilityLabel.Text =
            "BEAST"

        abilityLabel.Parent =
            billboard


        local distanceLabel =
            Instance.new("TextLabel")

        distanceLabel.Name =
            "Distance"

        distanceLabel.Size =
            UDim2.new(1,0,0,18)

        distanceLabel.Position =
            UDim2.fromOffset(0,21)

        distanceLabel.BackgroundTransparency = 1

        distanceLabel.TextColor3 =
            Colors.Beast

        distanceLabel.TextStrokeTransparency =
            0.22

        distanceLabel.TextSize = 12

        distanceLabel.Font =
            Enum.Font.GothamBold

        distanceLabel.Text =
            "0 studs"

        distanceLabel.Parent =
            billboard


        local usernameLabel =
            Instance.new("TextLabel")

        usernameLabel.Name =
            "Username"

        usernameLabel.Size =
            UDim2.new(1,0,0,18)

        usernameLabel.Position =
            UDim2.fromOffset(0,38)

        usernameLabel.BackgroundTransparency = 1

        usernameLabel.TextColor3 =
            Colors.Beast

        usernameLabel.TextStrokeTransparency =
            0.20

        -- Increased from the older build.

        usernameLabel.TextSize = 12

        usernameLabel.Font =
            Enum.Font.GothamBold

        usernameLabel.Text =
            player.Name

        usernameLabel.Parent =
            billboard
    end
end


--==================================================
-- SURVIVOR ESP
--==================================================

local function ensureSurvivorHighlight(player)

    local character =
        player.Character

    if not character then
        return
    end


    removeBeastESP(character)


    local h =
        character:FindFirstChild(
            "MateoSurvivorHighlight"
        )


    if not h then

        h = Instance.new("Highlight")

        h.Name =
            "MateoSurvivorHighlight"

        h.FillColor =
            Colors.Survivor

        h.FillTransparency = 0.72

        h.OutlineColor =
            Color3.fromRGB(
                50,
                165,
                255
            )

        h.OutlineTransparency = 0

        h.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        h.Parent = character
    end
end


local function ensureSurvivorLabel(player)

    local character =
        player.Character

    if not character then
        return
    end


    local head =
        character:FindFirstChild("Head")

    if not head then
        return
    end


    local billboard =
        head:FindFirstChild(
            "MateoSurvivorTag"
        )


    if not billboard then

        billboard =
            Instance.new("BillboardGui")

        billboard.Name =
            "MateoSurvivorTag"

        billboard.Size =
            UDim2.fromOffset(190,42)


        -- LOWER than previous build.
        --
        -- Old:
        -- Vector3.new(0,2.85,0)
        --
        -- This keeps it above the player,
        -- but prevents the username from
        -- floating excessively high when
        -- you're standing close to them.

        billboard.StudsOffsetWorldSpace =
            Vector3.new(0,2.45,0)

        billboard.AlwaysOnTop = true

        billboard.Parent = head


        -- Stud distance.

        local distanceLabel =
            Instance.new("TextLabel")

        distanceLabel.Name =
            "Distance"

        distanceLabel.Size =
            UDim2.new(1,0,0,20)

        distanceLabel.Position =
            UDim2.fromOffset(0,0)

        distanceLabel.BackgroundTransparency = 1

        distanceLabel.TextColor3 =
            Colors.Survivor

        distanceLabel.TextStrokeTransparency =
            0.18

        distanceLabel.TextSize = 13

        distanceLabel.Font =
            Enum.Font.GothamBold

        distanceLabel.Text =
            "0 studs"

        distanceLabel.Parent =
            billboard


        -- Username immediately underneath.
        -- Same readable visual weight as
        -- the stud distance.

        local usernameLabel =
            Instance.new("TextLabel")

        usernameLabel.Name =
            "Username"

        usernameLabel.Size =
            UDim2.new(1,0,0,20)

        usernameLabel.Position =
            UDim2.fromOffset(0,18)

        usernameLabel.BackgroundTransparency = 1

        usernameLabel.TextColor3 =
            Colors.Survivor

        usernameLabel.TextStrokeTransparency =
            0.20

        usernameLabel.TextSize = 12

        usernameLabel.Font =
            Enum.Font.GothamBold

        usernameLabel.Text =
            player.Name

        usernameLabel.Parent =
            billboard
    end
end


--==================================================
-- COMPUTER ESP
--==================================================
-- Continues in Part 2.
--==================================================
--==================================================
-- COMPUTER ESP - LIVE / ROUND PERSISTENT
--==================================================

local ComputerCache = {}
local CachedMap = nil

local MapDescendantAddedConnection = nil
local MapDescendantRemovingConnection = nil

local setComputerState


local function disconnectMapConnections()

    if MapDescendantAddedConnection then
        MapDescendantAddedConnection:Disconnect()
        MapDescendantAddedConnection = nil
    end

    if MapDescendantRemovingConnection then
        MapDescendantRemovingConnection:Disconnect()
        MapDescendantRemovingConnection = nil
    end
end


local function removeComputerPercent(computer)

    if not computer then
        return
    end

    -- Destroy ALL old Mateo percentage tags.
    -- This prevents duplicated 0% labels.

    for _, obj in ipairs(computer:GetChildren()) do

        if obj.Name == "MateoComputerPercent" then
            obj:Destroy()
        end
    end
end


local function removeComputerESP(computer)

    if not computer then
        return
    end

    local h =
        computer:FindFirstChild(
            "MateoComputerHighlight"
        )

    if h then
        h:Destroy()
    end

    removeComputerPercent(computer)
end


local function getComputerAdornee(computer)

    if computer.PrimaryPart then
        return computer.PrimaryPart
    end

    return computer:FindFirstChildWhichIsA(
        "BasePart",
        true
    )
end


--==================================================
-- COMPUTER PROGRESS
--==================================================
-- Diagnostic confirmed:
--
-- ComputerTable.Progress
-- is the TOTAL computer progress.
--
-- PlayerName_Progress attributes also change while
-- individual players hack the computer.
--
-- We use the COMPUTER'S Progress attribute as the
-- authoritative displayed percentage.
--
-- This means FULL mode sees live progress even when
-- ANOTHER PLAYER is hacking a different computer.
--==================================================

local function getComputerProgress(computer)

    if not computer then
        return 0
    end

    local progress =
        tonumber(
            computer:GetAttribute("Progress")
        )

    if progress == nil then
        return 0
    end


    -- In the diagnostic we observed Progress changing
    -- as a normal 0-100 value.

    progress =
        math.clamp(
            progress,
            0,
            100
        )

    return progress
end


local function addComputerToCache(computer)

    if not computer then
        return
    end

    if not computer:IsA("Model") then
        return
    end

    if computer.Name ~= "ComputerTable" then
        return
    end

    if ComputerCache[computer] then
        return
    end


    ComputerCache[computer] = {

        Model = computer,

        Highlight = nil,

        Billboard = nil,

        Label = nil,

        ProgressConnection = nil
    }


    local entry =
        ComputerCache[computer]


    --==================================================
    -- LIVE PROGRESS CONNECTION
    --==================================================
    -- Instead of relying only on the global update loop,
    -- update this computer immediately whenever its
    -- Progress attribute changes.
    --==================================================

    entry.ProgressConnection =
        computer:GetAttributeChangedSignal(
            "Progress"
        ):Connect(function()

            local currentEntry =
                ComputerCache[computer]

            if not currentEntry then
                return
            end

            if States.ComputerESP ~= 2 then
                return
            end

            local label =
                currentEntry.Label

            if label and label.Parent then

                local progress =
                    getComputerProgress(
                        computer
                    )

                label.Text =
                    string.format(
                        "%d%%",
                        math.floor(
                            progress + 0.5
                        )
                    )
            end
        end)


    -- New computers inherit whatever state
    -- Computer ESP is currently using.

    task.defer(function()

        if computer.Parent
            and ComputerCache[computer]
            and setComputerState then

            setComputerState(computer)
        end
    end)
end


local function clearComputerCache()

    for computer, entry in pairs(
        ComputerCache
    ) do

        if entry.ProgressConnection then

            pcall(function()
                entry.ProgressConnection:Disconnect()
            end)

            entry.ProgressConnection = nil
        end

        removeComputerESP(computer)
    end

    table.clear(ComputerCache)
end


local function rebuildComputerCache()

    disconnectMapConnections()

    clearComputerCache()

    local map =
        workspace:FindFirstChild("Map")

    CachedMap = map

    if not map then
        return
    end


    -- Initial computer scan.

    for _, obj in ipairs(
        map:GetDescendants()
    ) do

        if obj:IsA("Model")
            and obj.Name == "ComputerTable" then

            addComputerToCache(obj)
        end
    end


    -- Catch computers that appear while the
    -- map is still loading.

    MapDescendantAddedConnection =
        map.DescendantAdded:Connect(
            function(obj)

                if obj:IsA("Model")
                    and obj.Name == "ComputerTable" then

                    addComputerToCache(obj)
                end
            end
        )


    MapDescendantRemovingConnection =
        map.DescendantRemoving:Connect(
            function(obj)

                local entry =
                    ComputerCache[obj]

                if entry then

                    if entry.ProgressConnection then

                        pcall(function()

                            entry.ProgressConnection:
                                Disconnect()

                        end)
                    end

                    ComputerCache[obj] = nil
                end
            end
        )
end


local function removeAllComputerESP()

    for computer, entry in pairs(
        ComputerCache
    ) do

        removeComputerESP(computer)

        entry.Highlight = nil
        entry.Billboard = nil
        entry.Label = nil
    end
end


--==================================================
-- COMPUTER HIGHLIGHT
--==================================================

local function ensureComputerHighlight(computer)

    local entry =
        ComputerCache[computer]

    if not entry then
        return
    end


    local h =
        entry.Highlight


    if not h or not h.Parent then

        h =
            computer:FindFirstChild(
                "MateoComputerHighlight"
            )
    end


    if not h then

        h = Instance.new("Highlight")

        h.Name =
            "MateoComputerHighlight"

        h.FillColor =
            Colors.Computer

        h.FillTransparency = 0.90

        h.OutlineColor =
            Colors.Computer

        h.OutlineTransparency = 0.42

        h.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        h.Adornee = computer

        h.Parent = computer
    end


    entry.Highlight = h
end


--==================================================
-- COMPUTER % LABEL
--==================================================

local function ensureComputerPercent(computer)

    local entry =
        ComputerCache[computer]

    if not entry then
        return nil
    end


    -- Cached label still valid.

    if entry.Billboard
        and entry.Billboard.Parent
        and entry.Label
        and entry.Label.Parent then

        return entry.Label
    end


    -- Clean stale duplicate labels before creating
    -- a new one.

    removeComputerPercent(computer)

    entry.Billboard = nil
    entry.Label = nil


    local adornee =
        getComputerAdornee(computer)

    if not adornee then
        return nil
    end


    local tag =
        Instance.new("BillboardGui")

    tag.Name =
        "MateoComputerPercent"

    tag.Size =
        UDim2.fromOffset(64,20)

    tag.Adornee =
        adornee


    -- Center label over the whole computer model.

    local boxCF, boxSize =
        computer:GetBoundingBox()

    local desiredWorldPosition =
        boxCF.Position
        + Vector3.new(
            0,
            boxSize.Y / 2 + 0.80,
            0
        )


    tag.StudsOffsetWorldSpace =
        desiredWorldPosition
        - adornee.Position

    tag.AlwaysOnTop = true

    tag.Parent = computer


    local text =
        Instance.new("TextLabel")

    text.Name = "Percent"

    text.Size =
        UDim2.fromScale(1,1)

    text.BackgroundTransparency = 1


    -- Immediately use REAL progress.
    -- Do NOT initialize every computer visually
    -- as 0% and wait for another loop.

    local initialProgress =
        getComputerProgress(
            computer
        )

    text.Text =
        string.format(
            "%d%%",
            math.floor(
                initialProgress + 0.5
            )
        )


    text.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    text.TextStrokeColor3 =
        Color3.fromRGB(
            0,
            0,
            0
        )

    text.TextStrokeTransparency =
        0.15

    text.TextSize = 11

    text.Font =
        Enum.Font.GothamBold

    text.Parent = tag


    entry.Billboard = tag
    entry.Label = text


    return text
end


--==================================================
-- APPLY COMPUTER STATE
--==================================================

setComputerState = function(computer)

    local entry =
        ComputerCache[computer]

    if not entry then
        return
    end

    if not computer.Parent then
        return
    end


    -- OFF

    if States.ComputerESP == 0 then

        removeComputerESP(computer)

        entry.Highlight = nil
        entry.Billboard = nil
        entry.Label = nil

        return
    end


    -- FULL and HL ONLY both use highlight.

    ensureComputerHighlight(computer)


    -- HL ONLY

    if States.ComputerESP == 1 then

        removeComputerPercent(computer)

        entry.Billboard = nil
        entry.Label = nil

        return
    end


    -- FULL
    --
    -- Highlight + real-time %.

    local label =
        ensureComputerPercent(
            computer
        )

    if label then

        local progress =
            getComputerProgress(
                computer
            )

        label.Text =
            string.format(
                "%d%%",
                math.floor(
                    progress + 0.5
                )
            )
    end
end


local function refreshAllComputerStates()

    for computer in pairs(
        ComputerCache
    ) do

        setComputerState(computer)
    end
end


--==================================================
-- BACKUP REAL-TIME COMPUTER UPDATE
--==================================================
-- AttributeChanged handles immediate changes.
--
-- This updater is intentionally also kept as a
-- backup so percentages remain synchronized if a
-- computer's label is recreated, the map streams,
-- or another player is hacking it.
--==================================================

local function updateComputerPercentages()

    if States.ComputerESP ~= 2 then
        return
    end


    for computer, entry in pairs(
        ComputerCache
    ) do

        if computer.Parent then

            local label =
                entry.Label


            if not label
                or not label.Parent then

                label =
                    ensureComputerPercent(
                        computer
                    )
            end


            if label then

                local progress =
                    getComputerProgress(
                        computer
                    )

                label.Text =
                    string.format(
                        "%d%%",
                        math.floor(
                            progress + 0.5
                        )
                    )
            end
        end
    end
end


rebuildComputerCache()

refreshAllComputerStates()


--==================================================
-- LOCKER / VENT ESP
--==================================================
-- BINARY ONLY:
--
-- FULL -> OFF -> FULL
--
-- NO HL ONLY STATE.
--
-- Starts FULL automatically.
--==================================================

local LockerVentCache = {}

local LockerVentMap = nil

local LockerVentAddedConnection = nil
local LockerVentRemovingConnection = nil


local LOCKER_COLOR =
    Color3.fromRGB(
        70,
        210,
        255
    )


local VENT_COLOR =
    Color3.fromRGB(
        190,
        105,
        255
    )


local function disconnectLockerVentConnections()

    if LockerVentAddedConnection then

        LockerVentAddedConnection:
            Disconnect()

        LockerVentAddedConnection = nil
    end


    if LockerVentRemovingConnection then

        LockerVentRemovingConnection:
            Disconnect()

        LockerVentRemovingConnection = nil
    end
end


local function classifyLockerVent(obj)

    if not obj then
        return nil
    end


    --==================================================
    -- LOCKER
    --==================================================
    -- Observed hierarchy:
    --
    -- Lockers
    --   Locker
    --     LockerModel
    --==================================================

    if obj.Name == "LockerModel"
        and obj:IsA("Model") then


        local locker =
            obj.Parent

        local lockers =
            locker and locker.Parent


        if locker
            and locker.Name == "Locker"
            and lockers
            and lockers.Name == "Lockers" then

            return "Locker"
        end
    end


    --==================================================
    -- VENT
    --==================================================

    if obj.Name == "Vent"
        and obj:IsA("Model") then

        return "Vent"
    end


    -- Some maps put BaseParts underneath
    -- Vent / Vents containers.

    if obj:IsA("BasePart") then

        local ancestor =
            obj.Parent


        while ancestor
            and ancestor ~= workspace do


            local name =
                string.lower(
                    ancestor.Name
                )


            if name == "vent"
                or name == "vents" then

                return "Vent"
            end


            if ancestor ==
                LockerVentMap then

                break
            end


            ancestor =
                ancestor.Parent
        end
    end


    return nil
end


local function removeLockerVentHighlight(obj)

    if not obj then
        return
    end


    local h =
        obj:FindFirstChild(
            "MateoLockerVentHighlight"
        )


    if h then
        h:Destroy()
    end
end


local function applyLockerVentState(
    obj,
    kind
)

    if not obj
        or not obj.Parent then

        return
    end


    -- OFF

    if States.LockerVentESP == 0 then

        removeLockerVentHighlight(obj)

        return
    end


    -- FULL / ON

    local h =
        obj:FindFirstChild(
            "MateoLockerVentHighlight"
        )


    if not h then

        h = Instance.new("Highlight")

        h.Name =
            "MateoLockerVentHighlight"

        h.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        h.FillTransparency = 0.84

        h.OutlineTransparency = 0.12

        h.Adornee = obj

        h.Parent = obj
    end


    local color

    if kind == "Vent" then

        color =
            VENT_COLOR

    else

        color =
            LOCKER_COLOR
    end


    h.FillColor = color
    h.OutlineColor = color
end


local function addLockerVentToCache(obj)

    local kind =
        classifyLockerVent(obj)


    if not kind then
        return
    end


    if LockerVentCache[obj] then
        return
    end


    LockerVentCache[obj] =
        kind


    applyLockerVentState(
        obj,
        kind
    )
end


local function refreshAllLockerVentStates()

    for obj, kind in pairs(
        LockerVentCache
    ) do


        if obj.Parent then

            applyLockerVentState(
                obj,
                kind
            )

        else

            LockerVentCache[obj] = nil
        end
    end
end


local function removeAllLockerVentESP()

    for obj in pairs(
        LockerVentCache
    ) do

        removeLockerVentHighlight(obj)
    end
end


local function rebuildLockerVentCache()

    disconnectLockerVentConnections()


    for obj in pairs(
        LockerVentCache
    ) do

        removeLockerVentHighlight(obj)
    end


    table.clear(
        LockerVentCache
    )


    local map =
        workspace:FindFirstChild("Map")


    LockerVentMap = map


    if not map then
        return
    end


    -- Initial scan.

    for _, obj in ipairs(
        map:GetDescendants()
    ) do

        addLockerVentToCache(obj)
    end


    -- Objects that load afterward.

    LockerVentAddedConnection =
        map.DescendantAdded:Connect(
            function(obj)

                addLockerVentToCache(obj)

            end
        )


    LockerVentRemovingConnection =
        map.DescendantRemoving:Connect(
            function(obj)

                if LockerVentCache[obj] then

                    LockerVentCache[obj] =
                        nil
                end
            end
        )
end


rebuildLockerVentCache()

refreshAllLockerVentStates()


--==================================================
-- END PART 2
--==================================================
-- Part 3 continues with:
--
-- HATCH ESP
-- EXIT OPEN detection / OPEN text
-- State/button helpers
--==================================================
--==================================================
-- MATEO UTILITY V4.1
-- PART 3
--
-- HATCH ESP
-- EXIT OPEN INDICATOR
--==================================================


--==================================================
-- HATCH ESP
--==================================================
-- STATES:
--
-- 2 = FULL
--     [HATCH]
--     distance
--     highlight
--
-- 1 = HL ONLY
--     highlight only
--
-- 0 = OFF
--
-- Hatch can spawn AFTER the round has already
-- started, so this system continuously watches
-- workspace.Map for the hatch appearing.
--==================================================

local HatchCache = {}

local HatchMap = nil

local HatchAddedConnection = nil
local HatchRemovingConnection = nil


local HATCH_COLOR =
    Colors.Hatch


--==================================================
-- HATCH CLASSIFICATION
--==================================================

local function isHatchObject(obj)

    if not obj then
        return false
    end


    local lowerName =
        string.lower(
            obj.Name
        )


    -- Exact / common hatch names.

    if lowerName == "hatch"
        or lowerName == "hatchmodel"
        or lowerName == "escapehatch" then

        if obj:IsA("Model")
            or obj:IsA("BasePart") then

            return true
        end
    end


    -- Fallback for dynamically named hatch models.

    if string.find(
        lowerName,
        "hatch",
        1,
        true
    ) then

        if obj:IsA("Model")
            or obj:IsA("BasePart") then

            return true
        end
    end


    return false
end


--==================================================
-- HATCH ROOT / ADORNEE
--==================================================

local function getHatchAdornee(hatch)

    if not hatch then
        return nil
    end


    if hatch:IsA("BasePart") then
        return hatch
    end


    if hatch:IsA("Model") then

        if hatch.PrimaryPart then
            return hatch.PrimaryPart
        end


        return hatch:FindFirstChildWhichIsA(
            "BasePart",
            true
        )
    end


    return nil
end


--==================================================
-- REMOVE HATCH LABEL
--==================================================

local function removeHatchLabel(hatch)

    if not hatch then
        return
    end


    local tag =
        hatch:FindFirstChild(
            "MateoHatchTag"
        )


    if tag then
        tag:Destroy()
    end


    local entry =
        HatchCache[hatch]


    if entry then

        entry.Billboard = nil
        entry.NameLabel = nil
        entry.DistanceLabel = nil
    end
end


--==================================================
-- REMOVE HATCH HIGHLIGHT
--==================================================

local function removeHatchHighlight(hatch)

    if not hatch then
        return
    end


    local highlight =
        hatch:FindFirstChild(
            "MateoHatchHighlight"
        )


    if highlight then
        highlight:Destroy()
    end


    local entry =
        HatchCache[hatch]


    if entry then
        entry.Highlight = nil
    end
end


local function removeHatchESP(hatch)

    removeHatchHighlight(hatch)
    removeHatchLabel(hatch)
end


--==================================================
-- HATCH HIGHLIGHT
--==================================================

local function ensureHatchHighlight(hatch)

    local entry =
        HatchCache[hatch]


    if not entry then
        return
    end


    local highlight =
        entry.Highlight


    if not highlight
        or not highlight.Parent then

        highlight =
            hatch:FindFirstChild(
                "MateoHatchHighlight"
            )
    end


    if not highlight then

        highlight =
            Instance.new("Highlight")

        highlight.Name =
            "MateoHatchHighlight"

        highlight.FillColor =
            HATCH_COLOR

        highlight.FillTransparency =
            0.72

        highlight.OutlineColor =
            HATCH_COLOR

        highlight.OutlineTransparency =
            0

        highlight.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        highlight.Adornee =
            hatch

        highlight.Parent =
            hatch
    end


    entry.Highlight =
        highlight
end


--==================================================
-- HATCH FULL LABEL
--==================================================

local function ensureHatchLabel(hatch)

    local entry =
        HatchCache[hatch]


    if not entry then
        return nil
    end


    if entry.Billboard
        and entry.Billboard.Parent
        and entry.NameLabel
        and entry.NameLabel.Parent
        and entry.DistanceLabel
        and entry.DistanceLabel.Parent then

        return
            entry.NameLabel,
            entry.DistanceLabel
    end


    -- Remove stale duplicate first.

    removeHatchLabel(hatch)


    local adornee =
        getHatchAdornee(
            hatch
        )


    if not adornee then
        return nil
    end


    local billboard =
        Instance.new("BillboardGui")


    billboard.Name =
        "MateoHatchTag"


    billboard.Size =
        UDim2.fromOffset(
            150,
            43
        )


    billboard.Adornee =
        adornee


    -- Position label above the entire hatch rather
    -- than blindly above its PrimaryPart.

    local desiredWorldPosition


    if hatch:IsA("Model") then

        local boxCF, boxSize =
            hatch:GetBoundingBox()


        desiredWorldPosition =
            boxCF.Position
            + Vector3.new(
                0,
                boxSize.Y / 2 + 1.15,
                0
            )

    else

        desiredWorldPosition =
            hatch.Position
            + Vector3.new(
                0,
                hatch.Size.Y / 2 + 1.15,
                0
            )
    end


    billboard.StudsOffsetWorldSpace =
        desiredWorldPosition
        - adornee.Position


    billboard.AlwaysOnTop =
        true


    billboard.Parent =
        hatch


    --==================================================
    -- [HATCH]
    --==================================================

    local nameLabel =
        Instance.new("TextLabel")


    nameLabel.Name =
        "Name"


    nameLabel.Size =
        UDim2.new(
            1,
            0,
            0,
            22
        )


    nameLabel.Position =
        UDim2.fromOffset(
            0,
            0
        )


    nameLabel.BackgroundTransparency =
        1


    nameLabel.Text =
        "[HATCH]"


    nameLabel.TextColor3 =
        HATCH_COLOR


    nameLabel.TextStrokeColor3 =
        Color3.fromRGB(
            0,
            0,
            0
        )


    nameLabel.TextStrokeTransparency =
        0.15


    nameLabel.TextSize =
        14


    nameLabel.Font =
        Enum.Font.GothamBold


    nameLabel.Parent =
        billboard


    --==================================================
    -- DISTANCE
    --==================================================

    local distanceLabel =
        Instance.new("TextLabel")


    distanceLabel.Name =
        "Distance"


    distanceLabel.Size =
        UDim2.new(
            1,
            0,
            0,
            18
        )


    distanceLabel.Position =
        UDim2.fromOffset(
            0,
            21
        )


    distanceLabel.BackgroundTransparency =
        1


    distanceLabel.Text =
        "0 studs"


    distanceLabel.TextColor3 =
        HATCH_COLOR


    distanceLabel.TextStrokeColor3 =
        Color3.fromRGB(
            0,
            0,
            0
        )


    distanceLabel.TextStrokeTransparency =
        0.18


    distanceLabel.TextSize =
        12


    distanceLabel.Font =
        Enum.Font.GothamBold


    distanceLabel.Parent =
        billboard


    entry.Billboard =
        billboard

    entry.NameLabel =
        nameLabel

    entry.DistanceLabel =
        distanceLabel


    return
        nameLabel,
        distanceLabel
end


--==================================================
-- APPLY HATCH STATE
--==================================================

local function applyHatchState(hatch)

    local entry =
        HatchCache[hatch]


    if not entry then
        return
    end


    if not hatch.Parent then
        return
    end


    -- OFF

    if States.HatchESP == 0 then

        removeHatchESP(
            hatch
        )

        return
    end


    -- FULL + HL ONLY

    ensureHatchHighlight(
        hatch
    )


    -- HL ONLY

    if States.HatchESP == 1 then

        removeHatchLabel(
            hatch
        )

        return
    end


    -- FULL

    ensureHatchLabel(
        hatch
    )
end


--==================================================
-- ADD HATCH
--==================================================

local function addHatchToCache(hatch)

    if not hatch then
        return
    end


    if HatchCache[hatch] then
        return
    end


    if not isHatchObject(hatch) then
        return
    end


    HatchCache[hatch] = {

        Highlight = nil,

        Billboard = nil,

        NameLabel = nil,

        DistanceLabel = nil
    }


    task.defer(function()

        if hatch.Parent
            and HatchCache[hatch] then

            applyHatchState(
                hatch
            )
        end
    end)
end


--==================================================
-- REFRESH HATCH STATE
--==================================================

local function refreshAllHatchStates()

    for hatch in pairs(
        HatchCache
    ) do

        if hatch.Parent then

            applyHatchState(
                hatch
            )

        else

            HatchCache[hatch] =
                nil
        end
    end
end


local function removeAllHatchESP()

    for hatch in pairs(
        HatchCache
    ) do

        removeHatchESP(
            hatch
        )
    end
end


--==================================================
-- HATCH MAP WATCHER
--==================================================

local function disconnectHatchConnections()

    if HatchAddedConnection then

        HatchAddedConnection:
            Disconnect()

        HatchAddedConnection =
            nil
    end


    if HatchRemovingConnection then

        HatchRemovingConnection:
            Disconnect()

        HatchRemovingConnection =
            nil
    end
end


local function rebuildHatchCache()

    disconnectHatchConnections()


    for hatch in pairs(
        HatchCache
    ) do

        removeHatchESP(
            hatch
        )
    end


    table.clear(
        HatchCache
    )


    local map =
        workspace:FindFirstChild(
            "Map"
        )


    HatchMap = map


    if not map then
        return
    end


    -- Existing hatch, if it already spawned.

    for _, obj in ipairs(
        map:GetDescendants()
    ) do

        if isHatchObject(obj) then

            addHatchToCache(
                obj
            )
        end
    end


    -- IMPORTANT:
    --
    -- The hatch usually does NOT exist when
    -- Mateo Utility first executes.
    --
    -- We therefore watch the map and catch it
    -- automatically whenever it spawns.

    HatchAddedConnection =
        map.DescendantAdded:Connect(
            function(obj)

                if isHatchObject(obj) then

                    addHatchToCache(
                        obj
                    )
                end
            end
        )


    HatchRemovingConnection =
        map.DescendantRemoving:Connect(
            function(obj)

                if HatchCache[obj] then

                    HatchCache[obj] =
                        nil
                end
            end
        )
end


rebuildHatchCache()

refreshAllHatchStates()


--==================================================
-- LIVE HATCH DISTANCE
--==================================================

local function updateHatchDistances()

    if States.HatchESP ~= 2 then
        return
    end


    local character =
        LocalPlayer.Character


    local myRoot =
        character
        and character:FindFirstChild(
            "HumanoidRootPart"
        )


    if not myRoot then
        return
    end


    for hatch, entry in pairs(
        HatchCache
    ) do


        if hatch.Parent then

            local adornee =
                getHatchAdornee(
                    hatch
                )


            if adornee then

                if not entry.DistanceLabel
                    or not entry.DistanceLabel.Parent then

                    ensureHatchLabel(
                        hatch
                    )
                end


                local distanceLabel =
                    entry.DistanceLabel


                if distanceLabel
                    and distanceLabel.Parent then


                    local distance =
                        math.floor(
                            (
                                myRoot.Position
                                - adornee.Position
                            ).Magnitude
                        )


                    distanceLabel.Text =
                        tostring(distance)
                        .. " studs"
                end
            end

        else

            HatchCache[hatch] =
                nil
        end
    end
end


--==================================================
-- EXIT ESP
--==================================================
-- BINARY:
--
-- ON -> OFF -> ON
--
-- IMPORTANT:
--
-- We are NOT adding another permanent exit
-- highlight because the game already provides
-- its own exit ESP/visual.
--
-- Mateo Utility adds ONLY:
--
--             [OPEN]
--
-- when an exit is actually open.
--
-- Closed exit:
-- NOTHING displayed.
--==================================================

local ExitCache = {}

local ExitMap = nil

local ExitAddedConnection = nil
local ExitRemovingConnection = nil


--==================================================
-- EXIT CLASSIFICATION
--==================================================

local function isExitObject(obj)

    if not obj then
        return false
    end


    if not obj:IsA("Model") then
        return false
    end


    local name =
        string.lower(
            obj.Name
        )


    -- Common names used for exit structures.

    if name == "exit"
        or name == "exitdoor"
        or name == "exitdoor1"
        or name == "exitdoor2"
        or name == "escapedoor" then

        return true
    end


    if string.find(
        name,
        "exitdoor",
        1,
        true
    ) then

        return true
    end


    return false
end


--==================================================
-- EXIT ADORNEE
--==================================================

local function getExitAdornee(exit)

    if not exit then
        return nil
    end


    if exit.PrimaryPart then
        return exit.PrimaryPart
    end


    return exit:FindFirstChildWhichIsA(
        "BasePart",
        true
    )
end


--==================================================
-- EXIT OPEN DETECTION
--==================================================
-- This checks common replicated state indicators
-- without displaying anything merely because an
-- exit model exists.
--==================================================

local function valueMeansOpen(value)

    if value == true then
        return true
    end


    if type(value) == "number" then

        return value >= 1
    end


    if type(value) == "string" then

        local text =
            string.lower(
                value
            )


        return text == "open"
            or text == "opened"
            or text == "true"
            or text == "1"
    end


    return false
end


local function isExitOpen(exit)

    if not exit then
        return false
    end


    --==================================================
    -- ATTRIBUTES
    --==================================================

    for _, attributeName in ipairs({

        "Open",
        "Opened",
        "IsOpen",
        "DoorOpen",
        "ExitOpen"

    }) do


        local value =
            exit:GetAttribute(
                attributeName
            )


        if value ~= nil
            and valueMeansOpen(value) then

            return true
        end
    end


    --==================================================
    -- VALUE OBJECTS
    --==================================================

    for _, object in ipairs(
        exit:GetDescendants()
    ) do


        if object:IsA("BoolValue")
            or object:IsA("IntValue")
            or object:IsA("NumberValue")
            or object:IsA("StringValue") then


            local lowerName =
                string.lower(
                    object.Name
                )


            if lowerName == "open"
                or lowerName == "opened"
                or lowerName == "isopen"
                or lowerName == "dooropen"
                or lowerName == "exitopen" then


                if valueMeansOpen(
                    object.Value
                ) then

                    return true
                end
            end
        end
    end


    return false
end


--==================================================
-- REMOVE EXIT OPEN LABEL
--==================================================

local function removeExitLabel(exit)

    if not exit then
        return
    end


    local tag =
        exit:FindFirstChild(
            "MateoExitTag"
        )


    if tag then
        tag:Destroy()
    end


    local entry =
        ExitCache[exit]


    if entry then

        entry.Billboard =
            nil

        entry.Label =
            nil
    end
end


--==================================================
-- CREATE [OPEN] LABEL
--==================================================

local function ensureExitOpenLabel(exit)

    local entry =
        ExitCache[exit]


    if not entry then
        return nil
    end


    if entry.Billboard
        and entry.Billboard.Parent
        and entry.Label
        and entry.Label.Parent then

        return entry.Label
    end


    removeExitLabel(
        exit
    )


    local adornee =
        getExitAdornee(
            exit
        )


    if not adornee then
        return nil
    end


    local tag =
        Instance.new(
            "BillboardGui"
        )


    tag.Name =
        "MateoExitTag"


    tag.Size =
        UDim2.fromOffset(
            110,
            28
        )


    tag.Adornee =
        adornee


    local boxCF, boxSize =
        exit:GetBoundingBox()


    local desiredWorldPosition =
        boxCF.Position
        + Vector3.new(
            0,
            boxSize.Y / 2 + 1.0,
            0
        )


    tag.StudsOffsetWorldSpace =
        desiredWorldPosition
        - adornee.Position


    tag.AlwaysOnTop =
        true


    tag.Parent =
        exit


    local label =
        Instance.new(
            "TextLabel"
        )


    label.Name =
        "Open"


    label.Size =
        UDim2.fromScale(
            1,
            1
        )


    label.BackgroundTransparency =
        1


    label.Text =
        "[OPEN]"


    label.TextColor3 =
        Colors.ExitOpen


    label.TextStrokeColor3 =
        Color3.fromRGB(
            0,
            0,
            0
        )


    label.TextStrokeTransparency =
        0.12


    label.TextSize =
        14


    label.Font =
        Enum.Font.GothamBold


    label.Parent =
        tag


    entry.Billboard =
        tag

    entry.Label =
        label


    return label
end


--==================================================
-- APPLY EXIT STATE
--==================================================

local function applyExitState(exit)

    if not exit
        or not exit.Parent then

        return
    end


    -- Exit ESP OFF.

    if States.ExitESP == 0 then

        removeExitLabel(
            exit
        )

        return
    end


    -- Exit ESP ON.
    --
    -- ONLY show something when OPEN.

    if isExitOpen(exit) then

        ensureExitOpenLabel(
            exit
        )

    else

        removeExitLabel(
            exit
        )
    end
end


--==================================================
-- EXIT CACHE
--==================================================

local function addExitToCache(exit)

    if not exit then
        return
    end


    if ExitCache[exit] then
        return
    end


    if not isExitObject(exit) then
        return
    end


    ExitCache[exit] = {

        Billboard = nil,
        Label = nil
    }


    task.defer(function()

        if exit.Parent
            and ExitCache[exit] then

            applyExitState(
                exit
            )
        end
    end)
end


local function refreshAllExitStates()

    for exit in pairs(
        ExitCache
    ) do

        if exit.Parent then

            applyExitState(
                exit
            )

        else

            ExitCache[exit] =
                nil
        end
    end
end


local function removeAllExitESP()

    for exit in pairs(
        ExitCache
    ) do

        removeExitLabel(
            exit
        )
    end
end


--==================================================
-- EXIT MAP WATCHER
--==================================================

local function disconnectExitConnections()

    if ExitAddedConnection then

        ExitAddedConnection:
            Disconnect()

        ExitAddedConnection =
            nil
    end


    if ExitRemovingConnection then

        ExitRemovingConnection:
            Disconnect()

        ExitRemovingConnection =
            nil
    end
end


local function rebuildExitCache()

    disconnectExitConnections()


    for exit in pairs(
        ExitCache
    ) do

        removeExitLabel(
            exit
        )
    end


    table.clear(
        ExitCache
    )


    local map =
        workspace:FindFirstChild(
            "Map"
        )


    ExitMap = map


    if not map then
        return
    end


    -- Existing exits.

    for _, obj in ipairs(
        map:GetDescendants()
    ) do

        if isExitObject(obj) then

            addExitToCache(
                obj
            )
        end
    end


    -- Exits/map pieces that load afterward.

    ExitAddedConnection =
        map.DescendantAdded:Connect(
            function(obj)

                if isExitObject(obj) then

                    addExitToCache(
                        obj
                    )
                end
            end
        )


    ExitRemovingConnection =
        map.DescendantRemoving:Connect(
            function(obj)

                if ExitCache[obj] then

                    ExitCache[obj] =
                        nil
                end
            end
        )
end


rebuildExitCache()

refreshAllExitStates()


--==================================================
-- EXIT LIVE UPDATE
--==================================================
-- Exit state doesn't need to be checked every
-- rendered frame.
--
-- This gets called from our combined maintenance
-- loop in a later part.
--==================================================

local function updateExitStates()

    if States.ExitESP == 0 then
        return
    end


    for exit in pairs(
        ExitCache
    ) do

        if exit.Parent then

            applyExitState(
                exit
            )

        else

            ExitCache[exit] =
                nil
        end
    end
end


--==================================================
-- THREE-STATE BUTTON HELPERS
--==================================================

local function getThreeStateText(
    base,
    state
)

    if state == 2 then

        return base

    elseif state == 1 then

        return base
            .. " (HL ONLY)"

    else

        return base
            .. " (OFF)"
    end
end


local function getThreeStateColor(state)

    if state == 2 then

        return Colors.Full

    elseif state == 1 then

        return Colors.HL

    else

        return Colors.Off
    end
end


--==================================================
-- CREATE THREE-STATE BUTTON
--==================================================

local function createThreeStateButton(
    parent,
    baseText,
    stateKey
)

    local button =
        Instance.new(
            "TextButton"
        )


    button.Name =
        stateKey


    button.Size =
        UDim2.new(
            1,
            0,
            0,
            27
        )


    button.BackgroundTransparency =
        0.08


    button.TextColor3 =
        Colors.Text


    button.TextSize =
        10


    button.Font =
        Enum.Font.GothamMedium


    button.AutoButtonColor =
        false


    button.Active =
        true


    button.ZIndex =
        5


    button.Parent =
        parent


    local corner =
        Instance.new(
            "UICorner"
        )


    corner.CornerRadius =
        UDim.new(
            0,
            6
        )


    corner.Parent =
        button


    local stroke =
        Instance.new(
            "UIStroke"
        )


    stroke.Thickness =
        1


    stroke.Transparency =
        0.72


    stroke.Color =
        Colors.Text


    stroke.Parent =
        button


    local function refresh()

        button.Text =
            getThreeStateText(
                baseText,
                States[stateKey]
            )


        button.BackgroundColor3 =
            getThreeStateColor(
                States[stateKey]
            )
    end


    button.MouseButton1Click:
        Connect(function()


            -- FULL -> HL ONLY -> OFF -> FULL

            if States[stateKey] == 2 then

                States[stateKey] =
                    1

            elseif States[stateKey] == 1 then

                States[stateKey] =
                    0

            else

                States[stateKey] =
                    2
            end


            refresh()


            --==========================================
            -- BEAST
            --==========================================

            if stateKey ==
                "BeastESP" then


                if States.BeastESP == 0 then

                    removeAllBeastESP()


                elseif States.BeastESP == 1 then

                    for _, player in ipairs(
                        Players:GetPlayers()
                    ) do

                        removeBeastLabel(
                            player.Character
                        )
                    end
                end


            --==========================================
            -- SURVIVOR
            --==========================================

            elseif stateKey ==
                "SurvivorESP" then


                if States.SurvivorESP == 0 then

                    removeAllSurvivorESP()


                elseif States.SurvivorESP == 1 then

                    for _, player in ipairs(
                        Players:GetPlayers()
                    ) do

                        removeSurvivorLabel(
                            player.Character
                        )
                    end
                end


            --==========================================
            -- COMPUTER
            --==========================================

            elseif stateKey ==
                "ComputerESP" then


                refreshAllComputerStates()


            --==========================================
            -- HATCH
            --==========================================

            elseif stateKey ==
                "HatchESP" then


                refreshAllHatchStates()
            end
        end)


    refresh()


    return button
end


--==================================================
-- BINARY BUTTON
--==================================================
-- Locker/Vent:
--
-- ON -> OFF -> ON
--
-- Exit:
--
-- ON -> OFF -> ON
--
-- NO AMBER / HL ONLY.
--==================================================

local function createBinaryButton(
    parent,
    baseText,
    stateKey
)

    local button =
        Instance.new(
            "TextButton"
        )


    button.Name =
        stateKey


    button.Size =
        UDim2.new(
            1,
            0,
            0,
            27
        )


    button.BackgroundTransparency =
        0.08


    button.TextColor3 =
        Colors.Text


    button.TextSize =
        10


    button.Font =
        Enum.Font.GothamMedium


    button.AutoButtonColor =
        false


    button.Active =
        true


    button.ZIndex =
        5


    button.Parent =
        parent


    local corner =
        Instance.new(
            "UICorner"
        )


    corner.CornerRadius =
        UDim.new(
            0,
            6
        )


    corner.Parent =
        button


    local stroke =
        Instance.new(
            "UIStroke"
        )


    stroke.Thickness =
        1


    stroke.Transparency =
        0.72


    stroke.Color =
        Colors.Text


    stroke.Parent =
        button


    local function refresh()

        local enabled =
            States[stateKey] == 1


        if enabled then

            button.Text =
                baseText

            button.BackgroundColor3 =
                Colors.Full

        else

            button.Text =
                baseText
                .. " (OFF)"

            button.BackgroundColor3 =
                Colors.Off
        end
    end


    button.MouseButton1Click:
        Connect(function()


            if States[stateKey] == 1 then

                States[stateKey] =
                    0

            else

                States[stateKey] =
                    1
            end


            refresh()


            --==========================================
            -- LOCKER / VENT
            --==========================================

            if stateKey ==
                "LockerVentESP" then


                refreshAllLockerVentStates()


            --==========================================
            -- EXIT
            --==========================================

            elseif stateKey ==
                "ExitESP" then


                if States.ExitESP == 0 then

                    removeAllExitESP()

                else

                    refreshAllExitStates()
                end
            end
        end)


    refresh()


    return button
end


--==================================================
-- END PART 3
--==================================================
-- Part 4:
--
-- Feature buttons
-- Hitbox UI
-- INVISIBLE 5x5x5 / 6x6x6 implementation
-- Credits to saintedmateo ✝
--==================================================
--==================================================
-- MATEO UTILITY V4.1
-- PART 4
--
-- FEATURE UI
-- HITBOX SLIDER
-- INVISIBLE HITBOX IMPLEMENTATION
-- CREDITS
--==================================================


--==================================================
-- FEATURE LIST
--==================================================

local list =
    Instance.new("Frame")

list.Name =
    "FeatureList"

list.Size =
    UDim2.new(
        1,
        -18,
        0,
        213
    )

list.Position =
    UDim2.fromOffset(
        9,
        46
    )

list.BackgroundTransparency =
    1

list.ZIndex =
    4

list.Parent =
    menu


local layout =
    Instance.new("UIListLayout")

layout.Padding =
    UDim.new(
        0,
        4
    )

layout.Parent =
    list


--==================================================
-- SURVIVOR
--==================================================

createThreeStateButton(
    list,
    "Survivor ESP",
    "SurvivorESP"
)


--==================================================
-- BEAST
--==================================================

createThreeStateButton(
    list,
    "Beast ESP",
    "BeastESP"
)


--==================================================
-- COMPUTER
--==================================================

createThreeStateButton(
    list,
    "Computer ESP",
    "ComputerESP"
)


--==================================================
-- LOCKER / VENT
--
-- GREEN = ON
-- RED = OFF
--
-- NO AMBER STATE.
--==================================================

createBinaryButton(
    list,
    "Locker / Vent ESP",
    "LockerVentESP"
)


--==================================================
-- EXIT
--
-- GREEN = OPEN DETECTION ENABLED
-- RED = OFF
--
-- NO AMBER STATE.
--==================================================

createBinaryButton(
    list,
    "Exit ESP",
    "ExitESP"
)


--==================================================
-- HATCH
--==================================================

createThreeStateButton(
    list,
    "Hatch ESP",
    "HatchESP"
)


--==================================================
-- AUTO ROPE
-- GREEN = ON / RED = OFF
--==================================================

createBinaryButton(
    list,
    "Auto Rope",
    "AutoRope"
)


--==================================================
-- HITBOX SECTION
--==================================================

local hitboxSection =
    Instance.new("Frame")

hitboxSection.Name =
    "HitboxSection"

hitboxSection.Size =
    UDim2.new(
        1,
        -18,
        0,
        58
    )

hitboxSection.Position =
    UDim2.new(
        0,
        9,
        0,
        269
    )

hitboxSection.BackgroundTransparency =
    1

hitboxSection.ZIndex =
    4

hitboxSection.Parent =
    menu


--==================================================
-- HITBOX TITLE ROW
--==================================================

local hitboxRow =
    Instance.new("Frame")

hitboxRow.Name =
    "HitboxExpander"

hitboxRow.Size =
    UDim2.new(
        1,
        0,
        0,
        27
    )

hitboxRow.BackgroundColor3 =
    Color3.fromRGB(
        55,
        59,
        66
    )

hitboxRow.BackgroundTransparency =
    0.08

hitboxRow.ZIndex =
    5

hitboxRow.Parent =
    hitboxSection


local hitboxCorner =
    Instance.new("UICorner")

hitboxCorner.CornerRadius =
    UDim.new(
        0,
        6
    )

hitboxCorner.Parent =
    hitboxRow


local hitboxLabel =
    Instance.new("TextLabel")

hitboxLabel.Size =
    UDim2.new(
        1,
        -60,
        1,
        0
    )

hitboxLabel.Position =
    UDim2.fromOffset(
        8,
        0
    )

hitboxLabel.BackgroundTransparency =
    1

hitboxLabel.Text =
    "Hitbox Expander"

hitboxLabel.TextColor3 =
    Colors.Text

hitboxLabel.TextSize =
    10

hitboxLabel.Font =
    Enum.Font.GothamMedium

hitboxLabel.TextXAlignment =
    Enum.TextXAlignment.Left

hitboxLabel.ZIndex =
    6

hitboxLabel.Parent =
    hitboxRow


--==================================================
-- HITBOX LEVEL DISPLAY
--==================================================

local hitboxLevelDisplay =
    Instance.new("TextLabel")

hitboxLevelDisplay.Size =
    UDim2.fromOffset(
        46,
        19
    )

hitboxLevelDisplay.Position =
    UDim2.new(
        1,
        -52,
        0.5,
        -9
    )

hitboxLevelDisplay.BackgroundColor3 =
    Colors.SwitchOff

hitboxLevelDisplay.BackgroundTransparency =
    0.05

hitboxLevelDisplay.Text =
    "OFF"

hitboxLevelDisplay.TextColor3 =
    Colors.Text

hitboxLevelDisplay.TextSize =
    9

hitboxLevelDisplay.Font =
    Enum.Font.GothamBold

hitboxLevelDisplay.ZIndex =
    6

hitboxLevelDisplay.Parent =
    hitboxRow


local levelCorner =
    Instance.new("UICorner")

levelCorner.CornerRadius =
    UDim.new(
        0,
        5
    )

levelCorner.Parent =
    hitboxLevelDisplay


--==================================================
-- SLIDER AREA
--==================================================

local sliderArea =
    Instance.new("Frame")

sliderArea.Size =
    UDim2.new(
        1,
        -8,
        0,
        27
    )

sliderArea.Position =
    UDim2.fromOffset(
        4,
        30
    )

sliderArea.BackgroundTransparency =
    1

sliderArea.ZIndex =
    5

sliderArea.Parent =
    hitboxSection


--==================================================
-- SLIDER NUMBERS
--==================================================

local zero =
    Instance.new("TextLabel")

zero.Size =
    UDim2.fromOffset(
        18,
        18
    )

zero.BackgroundTransparency =
    1

zero.Text =
    "0"

zero.TextColor3 =
    Colors.Muted

zero.TextSize =
    10

zero.Font =
    Enum.Font.Gotham

zero.ZIndex =
    6

zero.Parent =
    sliderArea


local two =
    zero:Clone()

two.Text =
    "2"

two.Position =
    UDim2.new(
        1,
        -18,
        0,
        0
    )

two.Parent =
    sliderArea


--==================================================
-- SLIDER BAR
--==================================================

local slider =
    Instance.new("Frame")

slider.Size =
    UDim2.new(
        1,
        -44,
        0,
        3
    )

slider.Position =
    UDim2.new(
        0,
        22,
        0,
        8
    )

slider.BackgroundColor3 =
    Color3.fromRGB(
        82,
        86,
        94
    )

slider.BorderSizePixel =
    0

slider.Active =
    true

slider.ZIndex =
    6

slider.Parent =
    sliderArea


local sliderCorner =
    Instance.new("UICorner")

sliderCorner.CornerRadius =
    UDim.new(
        1,
        0
    )

sliderCorner.Parent =
    slider


--==================================================
-- SLIDER KNOB
--==================================================

local knob =
    Instance.new("Frame")

knob.Size =
    UDim2.fromOffset(
        12,
        12
    )

knob.AnchorPoint =
    Vector2.new(
        0.5,
        0.5
    )

knob.Position =
    UDim2.new(
        0,
        0,
        0.5,
        0
    )

knob.BackgroundColor3 =
    Colors.AccentBright

knob.Active =
    true

knob.ZIndex =
    7

knob.Parent =
    slider


local knobCorner =
    Instance.new("UICorner")

knobCorner.CornerRadius =
    UDim.new(
        1,
        0
    )

knobCorner.Parent =
    knob


local sliderValue =
    Instance.new("TextLabel")

sliderValue.Size =
    UDim2.fromOffset(
        22,
        13
    )

sliderValue.Position =
    UDim2.new(
        0,
        -11,
        0,
        13
    )

sliderValue.BackgroundTransparency =
    1

sliderValue.Text =
    "0"

sliderValue.TextColor3 =
    Colors.Text

sliderValue.TextSize =
    9

sliderValue.Font =
    Enum.Font.GothamBold

sliderValue.ZIndex =
    8

sliderValue.Parent =
    knob


--==================================================
-- HITBOX SYSTEM
--==================================================
--
-- FINAL SIZES:
--
-- LEVEL 0 = ORIGINAL / OFF
-- LEVEL 1 = 5 x 5 x 5
-- LEVEL 2 = 6 x 6 x 6
--
-- IMPORTANT:
--
-- NO SelectionBox.
-- NO Highlight.
-- NO visible cube.
-- NO diagnostic visual.
--==================================================

local HitboxOriginals = {}


local function getHitboxTarget(player)

    if not player then
        return nil
    end


    if player == LocalPlayer then
        return nil
    end


    local character =
        player.Character


    if not character then
        return nil
    end


    local root =
        character:FindFirstChild(
            "HumanoidRootPart"
        )


    if not root
        or not root:IsA("BasePart") then

        return nil
    end


    return root
end


--==================================================
-- SAVE ORIGINAL HITBOX
--==================================================

local function saveOriginalHitbox(root)

    if not root then
        return
    end


    if HitboxOriginals[root] then
        return
    end


    HitboxOriginals[root] = {

        Size =
            root.Size,

        Transparency =
            root.Transparency,

        CanCollide =
            root.CanCollide,

        CanTouch =
            root.CanTouch,

        CanQuery =
            root.CanQuery
    }
end


--==================================================
-- RESTORE ORIGINAL
--==================================================

local function restoreHitbox(root)

    if not root then
        return
    end


    local original =
        HitboxOriginals[root]


    if not original then
        return
    end


    if root.Parent then

        pcall(function()

            root.Size =
                original.Size


            root.Transparency =
                original.Transparency


            root.CanCollide =
                original.CanCollide


            root.CanTouch =
                original.CanTouch


            root.CanQuery =
                original.CanQuery
        end)
    end


    HitboxOriginals[root] =
        nil
end


local function restoreAllHitboxes()

    local restoreList = {}


    for root in pairs(
        HitboxOriginals
    ) do

        table.insert(
            restoreList,
            root
        )
    end


    for _, root in ipairs(
        restoreList
    ) do

        restoreHitbox(
            root
        )
    end
end


--==================================================
-- APPLY INVISIBLE HITBOX
--==================================================

local function applyHitboxToPlayer(player)

    local root =
        getHitboxTarget(
            player
        )


    if not root then
        return
    end


    -- LEVEL 0 = NORMAL.

    if States.HitboxLevel == 0 then

        restoreHitbox(
            root
        )

        return
    end


    saveOriginalHitbox(
        root
    )


    local size


    if States.HitboxLevel == 1 then

        -- Confirmed good diagnostic size.

        size =
            Vector3.new(
                5,
                5,
                5
            )

    else

        -- Level 2 reduced from the larger
        -- diagnostic test to 6x6x6.

        size =
            Vector3.new(
                6,
                6,
                6
            )
    end


    pcall(function()

        root.Size =
            size


        -- Keep the actual expanded part invisible.
        --
        -- The diagnostic blue cube is intentionally
        -- NOT created anywhere in this build.

        root.Transparency =
            1


        -- Prevent the larger part from physically
        -- blocking player movement.

        root.CanCollide =
            false


        -- Keep normal touch/query behavior available.

        root.CanTouch =
            true

        root.CanQuery =
            true
    end)
end


--==================================================
-- APPLY CURRENT LEVEL
--==================================================

local function applyAllHitboxes()

    if States.HitboxLevel == 0 then

        restoreAllHitboxes()

        return
    end


    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        applyHitboxToPlayer(
            player
        )
    end
end


--==================================================
-- CLEAN STALE HITBOX CACHE
--==================================================

local function cleanHitboxCache()

    local stale = {}


    for root in pairs(
        HitboxOriginals
    ) do

        if not root.Parent then

            table.insert(
                stale,
                root
            )
        end
    end


    for _, root in ipairs(
        stale
    ) do

        HitboxOriginals[root] =
            nil
    end
end


--==================================================
-- HITBOX UI REFRESH
--==================================================

local function refreshHitboxUI()

    local level =
        States.HitboxLevel


    knob.Position =
        UDim2.new(
            level / 2,
            0,
            0.5,
            0
        )


    sliderValue.Text =
        tostring(
            level
        )


    if level == 0 then

        hitboxLevelDisplay.Text =
            "OFF"

        hitboxLevelDisplay.BackgroundColor3 =
            Colors.SwitchOff


    elseif level == 1 then

        hitboxLevelDisplay.Text =
            "5x5"

        hitboxLevelDisplay.BackgroundColor3 =
            Colors.Full


    else

        hitboxLevelDisplay.Text =
            "6x6"

        hitboxLevelDisplay.BackgroundColor3 =
            Colors.Full
    end
end


--==================================================
-- SET HITBOX LEVEL
--==================================================

local function setHitboxLevel(level)

    level =
        math.clamp(
            math.floor(level),
            0,
            2
        )


    if States.HitboxLevel ==
        level then

        refreshHitboxUI()

        return
    end


    -- Restore previous expansion BEFORE
    -- changing to another level.
    --
    -- This ensures level changes always
    -- originate from the real original size.

    restoreAllHitboxes()


    States.HitboxLevel =
        level


    applyAllHitboxes()

    refreshHitboxUI()
end


--==================================================
-- SLIDER INPUT
--==================================================

local sliding =
    false


local function setSlider(inputX)

    local relative =
        math.clamp(
            (
                inputX
                - slider.AbsolutePosition.X
            )
            / slider.AbsoluteSize.X,
            0,
            1
        )


    local level


    if relative < 0.25 then

        level = 0


    elseif relative < 0.75 then

        level = 1


    else

        level = 2
    end


    setHitboxLevel(
        level
    )
end


slider.InputBegan:
    Connect(function(input)


        if input.UserInputType
                == Enum.UserInputType.MouseButton1

            or input.UserInputType
                == Enum.UserInputType.Touch then


            sliding =
                true


            setSlider(
                input.Position.X
            )
        end
    end)


knob.InputBegan:
    Connect(function(input)


        if input.UserInputType
                == Enum.UserInputType.MouseButton1

            or input.UserInputType
                == Enum.UserInputType.Touch then


            sliding =
                true
        end
    end)


--==================================================
-- PLAYER RESPAWN HITBOX SUPPORT
--==================================================

local function hookHitboxPlayer(player)

    player.CharacterAdded:
        Connect(function(character)


            if player == LocalPlayer then
                return
            end


            task.spawn(function()

                local root =
                    character:WaitForChild(
                        "HumanoidRootPart",
                        10
                    )


                if not root then
                    return
                end


                task.wait(
                    0.15
                )


                if States.HitboxLevel > 0 then

                    applyHitboxToPlayer(
                        player
                    )
                end
            end)
        end)
end


for _, player in ipairs(
    Players:GetPlayers()
) do

    hookHitboxPlayer(
        player
    )
end


Players.PlayerAdded:
    Connect(function(player)

        hookHitboxPlayer(
            player
        )
    end)


--==================================================
-- INITIAL HITBOX UI
--==================================================

refreshHitboxUI()


--==================================================
-- DRAGGING
--==================================================

local menuDragging =
    false

local menuDragStart
local menuStart


header.InputBegan:
    Connect(function(input)


        if input.UserInputType
                == Enum.UserInputType.MouseButton1

            or input.UserInputType
                == Enum.UserInputType.Touch then


            menuDragging =
                true


            menuDragStart =
                input.Position


            menuStart =
                menu.Position
        end
    end)


UIS.InputChanged:
    Connect(function(input)


        --==========================================
        -- HITBOX SLIDER
        --==========================================

        if sliding
            and (
                input.UserInputType
                    == Enum.UserInputType.MouseMovement

                or input.UserInputType
                    == Enum.UserInputType.Touch
            ) then


            setSlider(
                input.Position.X
            )


            return
        end


        --==========================================
        -- MENU DRAG
        --==========================================

        if menuDragging
            and (
                input.UserInputType
                    == Enum.UserInputType.MouseMovement

                or input.UserInputType
                    == Enum.UserInputType.Touch
            ) then


            local delta =
                input.Position
                - menuDragStart


            menu.Position =
                UDim2.new(

                    menuStart.X.Scale,
                    menuStart.X.Offset
                        + delta.X,

                    menuStart.Y.Scale,
                    menuStart.Y.Offset
                        + delta.Y
                )
        end
    end)


UIS.InputEnded:
    Connect(function(input)


        if input.UserInputType
                == Enum.UserInputType.MouseButton1

            or input.UserInputType
                == Enum.UserInputType.Touch then


            sliding =
                false


            menuDragging =
                false
        end
    end)


--==================================================
-- CREDITS
--==================================================
-- Kept clearly readable instead of using the
-- tiny old signature.
--==================================================

local signature =
    Instance.new("TextLabel")


signature.Size =
    UDim2.new(
        1,
        -18,
        0,
        18
    )


signature.Position =
    UDim2.new(
        0,
        9,
        1,
        -23
    )


signature.BackgroundTransparency =
    1


signature.Text =
    "Credits to saintedmateo ✝"


signature.TextColor3 =
    Colors.Muted


signature.TextTransparency =
    0.04


signature.TextSize =
    10


signature.Font =
    Enum.Font.GothamMedium


signature.TextXAlignment =
    Enum.TextXAlignment.Center


signature.ZIndex =
    6


signature.Parent =
    menu


--==================================================
-- SETTINGS BUTTON
--==================================================

gear.MouseButton1Click:
    Connect(function()


        menu.Visible =
            not menu.Visible
    end)


--==================================================
-- END PART 4
--==================================================
-- Part 5 is the FINAL section:
--
-- Player ESP live loop
-- Computer live loop
-- Hatch live distance
-- Exit OPEN live checking
-- Map replacement / new-round handling
-- Hitbox maintenance
-- Cleanup
-- Full Bright enforcement
-- Final startup
--==================================================
--==================================================
-- AUTO ROPE
-- Integrated from the tested standalone diagnostic.
--==================================================

local Carry = RS:WaitForChild("Carry")

if _G.MateoAutoRopeConnections then
    for _, connection in ipairs(_G.MateoAutoRopeConnections) do
        pcall(function() connection:Disconnect() end)
    end
end

_G.MateoAutoRopeConnections = {}

local function saveAutoRopeConnection(connection)
    table.insert(_G.MateoAutoRopeConnections, connection)
    return connection
end

local autoRopeHandled = {}

local function attemptAutoRope(player, character)
    if States.AutoRope ~= 1 then return end
    if not character or not character.Parent then return end
    if character:GetAttribute("Ragdolled") ~= true then return end
    if autoRopeHandled[character] then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    autoRopeHandled[character] = true
    Carry:FireServer(character, root, root.CFrame)
end

local function hookAutoRopeCharacter(player, character)
    autoRopeHandled[character] = false
    saveAutoRopeConnection(character:GetAttributeChangedSignal("Ragdolled"):Connect(function()
        local ragdolled = character:GetAttribute("Ragdolled")
        if ragdolled == true then
            task.delay(0.05, function() attemptAutoRope(player, character) end)
        else
            autoRopeHandled[character] = false
        end
    end))
    if character:GetAttribute("Ragdolled") == true then
        task.delay(0.05, function() attemptAutoRope(player, character) end)
    end
end

local function hookAutoRopePlayer(player)
    if player == LocalPlayer then return end
    if player.Character then hookAutoRopeCharacter(player, player.Character) end
    saveAutoRopeConnection(player.CharacterAdded:Connect(function(character)
        task.wait(0.25)
        hookAutoRopeCharacter(player, character)
    end))
end

for _, player in ipairs(Players:GetPlayers()) do hookAutoRopePlayer(player) end
saveAutoRopeConnection(Players.PlayerAdded:Connect(hookAutoRopePlayer))

--==================================================
-- MATEO UTILITY V4.1
-- PART 5 / FINAL
--
-- LIVE PLAYER ESP
-- MAP / ROUND MAINTENANCE
-- COMPUTER LIVE %
-- HATCH LIVE DISTANCE
-- EXIT OPEN UPDATE
-- HITBOX MAINTENANCE
-- FINAL STARTUP
--==================================================


--==================================================
-- PLAYER ESP LIVE UPDATE
--==================================================

local playerTimer = 0


_G.MateoUtilityConnection =
RunService.Heartbeat:Connect(function(dt)

    playerTimer += dt


    -- Player labels do not need to update at
    -- rendering FPS.
    --
    -- 20 updates/sec keeps distances looking
    -- smooth without unnecessary work.

    if playerTimer < 0.05 then
        return
    end


    playerTimer = 0


    local myCharacter =
        LocalPlayer.Character


    local myRoot =
        myCharacter
        and myCharacter:FindFirstChild(
            "HumanoidRootPart"
        )


    for _, player in ipairs(
        Players:GetPlayers()
    ) do


        if player ~= LocalPlayer then


            local character =
                player.Character


            --======================================
            -- BEAST
            --======================================

            if States.BeastESP > 0
                and isBeast(player)
                and character then


                -- Make sure Survivor ESP cannot
                -- remain on someone who becomes
                -- Beast.

                removeSurvivorESP(
                    character
                )


                ensureBeastHighlight(
                    player
                )


                if States.BeastESP == 2 then


                    ensureBeastLabel(
                        player
                    )


                    local root =
                        character:FindFirstChild(
                            "HumanoidRootPart"
                        )


                    local head =
                        character:FindFirstChild(
                            "Head"
                        )


                    if root and head then


                        local tag =
                            head:FindFirstChild(
                                "MateoBeastTag"
                            )


                        local abilityLabel =
                            tag
                            and tag:FindFirstChild(
                                "Ability"
                            )


                        local distanceLabel =
                            tag
                            and tag:FindFirstChild(
                                "Distance"
                            )


                        local usernameLabel =
                            tag
                            and tag:FindFirstChild(
                                "Username"
                            )


                        if abilityLabel
                            and distanceLabel
                            and usernameLabel then


                            local distance =
                                0


                            if myRoot then

                                distance =
                                    math.floor(
                                        (
                                            myRoot.Position
                                            - root.Position
                                        ).Magnitude
                                    )
                            end


                            -- Existing game attribute.

                            local chosenPower =
                                player:GetAttribute(
                                    "ChosenPower"
                                )


                            if chosenPower == nil
                                or tostring(
                                    chosenPower
                                ) == "" then


                                abilityLabel.Text =
                                    "BEAST"

                            else

                                abilityLabel.Text =
                                    string.upper(
                                        tostring(
                                            chosenPower
                                        )
                                    )
                            end


                            distanceLabel.Text =
                                tostring(distance)
                                .. " studs"


                            usernameLabel.Text =
                                player.Name
                        end
                    end


                else

                    -- HL ONLY.

                    removeBeastLabel(
                        character
                    )
                end


            else

                removeBeastESP(
                    character
                )
            end


            --======================================
            -- SURVIVOR
            --======================================

            if States.SurvivorESP > 0
                and isSurvivor(player)
                and character then


                -- Never allow Beast + Survivor
                -- visuals simultaneously.

                removeBeastESP(
                    character
                )


                ensureSurvivorHighlight(
                    player
                )


                if States.SurvivorESP == 2 then


                    ensureSurvivorLabel(
                        player
                    )


                    local root =
                        character:FindFirstChild(
                            "HumanoidRootPart"
                        )


                    local head =
                        character:FindFirstChild(
                            "Head"
                        )


                    if root and head then


                        local tag =
                            head:FindFirstChild(
                                "MateoSurvivorTag"
                            )


                        local distanceLabel =
                            tag
                            and tag:FindFirstChild(
                                "Distance"
                            )


                        local usernameLabel =
                            tag
                            and tag:FindFirstChild(
                                "Username"
                            )


                        if distanceLabel
                            and usernameLabel then


                            local distance =
                                0


                            if myRoot then

                                distance =
                                    math.floor(
                                        (
                                            myRoot.Position
                                            - root.Position
                                        ).Magnitude
                                    )
                            end


                            distanceLabel.Text =
                                tostring(distance)
                                .. " studs"


                            usernameLabel.Text =
                                player.Name
                        end
                    end


                else

                    -- HL ONLY.

                    removeSurvivorLabel(
                        character
                    )
                end


            else

                removeSurvivorESP(
                    character
                )
            end
        end
    end
end)


--==================================================
-- MAP / ROUND MAINTENANCE
--==================================================

local maintenanceTimer = 0

local computerTimer = 0

local hatchTimer = 0

local exitTimer = 0

local hitboxTimer = 0


_G.MateoComputerConnection =
RunService.Heartbeat:Connect(function(dt)


    maintenanceTimer += dt

    computerTimer += dt

    hatchTimer += dt

    exitTimer += dt

    hitboxTimer += dt


    --==================================================
    -- MAP REPLACEMENT CHECK
    --==================================================
    -- A new round can replace workspace.Map.
    --
    -- When that happens we rebuild:
    --
    -- Computer cache
    -- Locker/Vent cache
    -- Hatch watcher
    -- Exit watcher
    --
    -- CURRENT UI states remain unchanged.
    --==================================================

    if maintenanceTimer >= 0.50 then


        maintenanceTimer = 0


        local currentMap =
            workspace:FindFirstChild(
                "Map"
            )


        local mapChanged =
            currentMap ~= CachedMap
            or currentMap ~= LockerVentMap
            or currentMap ~= HatchMap
            or currentMap ~= ExitMap


        if mapChanged then


            --======================================
            -- COMPUTER
            --======================================

            rebuildComputerCache()

            refreshAllComputerStates()


            --======================================
            -- LOCKER / VENT
            --======================================

            rebuildLockerVentCache()

            refreshAllLockerVentStates()


            --======================================
            -- HATCH
            --======================================

            rebuildHatchCache()

            refreshAllHatchStates()


            --======================================
            -- EXIT
            --======================================

            rebuildExitCache()

            refreshAllExitStates()
        end
    end


    --==================================================
    -- COMPUTER LIVE %
    --==================================================
    -- 5 updates/sec backup.
    --
    -- Individual computers ALSO have immediate
    -- Progress attribute-change listeners from
    -- Part 2.
    --==================================================

    if computerTimer >= 0.20 then


        computerTimer = 0


        updateComputerPercentages()
    end


    --==================================================
    -- HATCH DISTANCE
    --==================================================

    if hatchTimer >= 0.10 then


        hatchTimer = 0


        updateHatchDistances()
    end


    --==================================================
    -- EXIT OPEN CHECK
    --==================================================
    -- Fast enough to display [OPEN] quickly when
    -- the door state changes, but no reason to
    -- inspect exits every rendered frame.
    --==================================================

    if exitTimer >= 0.15 then


        exitTimer = 0


        updateExitStates()
    end


    --==================================================
    -- HITBOX MAINTENANCE
    --==================================================
    -- Reapply periodically because characters can
    -- respawn or the game can rewrite HRP properties.
    --==================================================

    if hitboxTimer >= 0.40 then


        hitboxTimer = 0


        cleanHitboxCache()


        if States.HitboxLevel > 0 then


            for _, player in ipairs(
                Players:GetPlayers()
            ) do


                if player ~= LocalPlayer then

                    applyHitboxToPlayer(
                        player
                    )
                end
            end
        end
    end
end)


--==================================================
-- MAP CHILD WATCHER
--==================================================
-- This catches Map being inserted quickly between
-- the periodic checks.
--==================================================

_G.MateoMapConnection =
workspace.ChildAdded:Connect(
    function(child)


        if child.Name ~= "Map" then
            return
        end


        task.defer(function()


            task.wait(
                0.20
            )


            rebuildComputerCache()

            refreshAllComputerStates()


            rebuildLockerVentCache()

            refreshAllLockerVentStates()


            rebuildHatchCache()

            refreshAllHatchStates()


            rebuildExitCache()

            refreshAllExitStates()
        end)
    end
)


--==================================================
-- AUTOMATIC NORMAL SKILL CHECK
--==================================================
--
-- Preserved from the previous Mateo Utility.
--
-- This does NOT:
--
-- alter computer Progress
-- increase hacking speed
-- start a computer automatically
-- teleport the player
--
-- It only handles the existing normal challenge
-- once the game's own challenge becomes active.
--==================================================

local ComputerChallenge =
    nil


pcall(function()


    local playerScripts =
        LocalPlayer:WaitForChild(
            "PlayerScripts"
        )


    local interact =
        playerScripts:FindFirstChild(
            "Interact"
        )


    if not interact then
        return
    end


    local module =
        interact:FindFirstChild(
            "ComputerChallenge"
        )


    if module
        and module:IsA(
            "ModuleScript"
        ) then


        ComputerChallenge =
            require(
                module
            )
    end
end)


--==================================================
-- CHALLENGE GUI CACHE
--==================================================

local ChallengeFrame =
    nil

local ChallengeMarker =
    nil

local ChallengeSpace =
    nil


local lastChallengeSearch =
    0


local function challengeObjectsValid()


    return
        ChallengeFrame
        and ChallengeFrame.Parent

        and ChallengeMarker
        and ChallengeMarker.Parent

        and ChallengeSpace
        and ChallengeSpace.Parent
end


local function findChallengeFrame()


    if challengeObjectsValid() then


        return
            ChallengeFrame,
            ChallengeMarker,
            ChallengeSpace
    end


    local now =
        os.clock()


    -- Avoid repeatedly searching all PlayerGui
    -- descendants when the challenge isn't present.

    if now
        - lastChallengeSearch
        < 0.50 then


        return
            nil,
            nil,
            nil
    end


    lastChallengeSearch =
        now


    for _, obj in ipairs(
        PlayerGui:GetDescendants()
    ) do


        if obj:IsA(
            "GuiObject"
        ) then


            local marker =
                obj:FindFirstChild(
                    "Marker"
                )


            local space =
                obj:FindFirstChild(
                    "Space"
                )


            if marker
                and space
                and marker:IsA(
                    "GuiObject"
                )
                and space:IsA(
                    "GuiObject"
                ) then


                ChallengeFrame =
                    obj


                ChallengeMarker =
                    marker


                ChallengeSpace =
                    space


                return
                    obj,
                    marker,
                    space
            end
        end
    end


    return
        nil,
        nil,
        nil
end


findChallengeFrame()


--==================================================
-- AUTOMATIC SKILL CHECK LOOP
--==================================================

local skillPressedThisChallenge =
    false


_G.MateoSkillConnection =
RunService.Heartbeat:Connect(function()


    if not ComputerChallenge then
        return
    end


    if ComputerChallenge.InChallenge
        ~= true then


        skillPressedThisChallenge =
            false


        return
    end


    if skillPressedThisChallenge then
        return
    end


    if ComputerChallenge.Pressed
        == true then

        return
    end


    local frame,
        marker,
        space =
            findChallengeFrame()


    if not frame
        or not marker
        or not space then

        return
    end


    local markerCenter =
        marker.AbsolutePosition.X
        + (
            marker.AbsoluteSize.X
            / 2
        )


    local spaceLeft =
        space.AbsolutePosition.X


    local spaceRight =
        space.AbsolutePosition.X
        + space.AbsoluteSize.X


    -- Trigger safely inside the game's existing
    -- success area rather than directly on its edge.

    local margin =
        math.min(
            2,
            space.AbsoluteSize.X
                * 0.10
        )


    local safeLeft =
        spaceLeft
        + margin


    local safeRight =
        spaceRight
        - margin


    if markerCenter >= safeLeft
        and markerCenter <= safeRight then


        ComputerChallenge.Pressed =
            true


        skillPressedThisChallenge =
            true
    end
end)


--==================================================
-- PLAYER REMOVING CLEANUP
--==================================================

Players.PlayerRemoving:
    Connect(function(player)


        local character =
            player.Character


        if character then


            removeBeastESP(
                character
            )


            removeSurvivorESP(
                character
            )


            local root =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )


            if root
                and HitboxOriginals[root] then


                -- Player is leaving anyway, so just
                -- remove stale cached information.

                HitboxOriginals[root] =
                    nil
            end
        end
    end)


--==================================================
-- INITIAL FEATURE APPLICATION
--==================================================

-- Player ESP gets picked up immediately by
-- MateoUtilityConnection.


-- Computer starts FULL.

refreshAllComputerStates()


-- Locker/Vent starts ON / FULL.

refreshAllLockerVentStates()


-- Hatch starts FULL.

refreshAllHatchStates()


-- Exit detection starts ON.
--
-- Closed exits still display NOTHING.

refreshAllExitStates()


-- Hitbox starts Level 0 / OFF.

States.HitboxLevel =
    0


restoreAllHitboxes()

refreshHitboxUI()


--==================================================
-- FULL BRIGHT FINAL ENFORCEMENT
--==================================================

enforceFullBright()


--==================================================
-- FINAL STARTUP MESSAGE
--==================================================

print(
    "========================================"
)


print(
    "[Mateo Utility] V4.1 loaded"
)


print(
    "[Mateo Utility] Survivor ESP: FULL"
)


print(
    "[Mateo Utility] Beast ESP: FULL"
)


print(
    "[Mateo Utility] Computer ESP: FULL / live %"
)


print(
    "[Mateo Utility] Locker / Vent ESP: ON"
)


print(
    "[Mateo Utility] Hatch ESP: FULL"
)


print(
    "[Mateo Utility] Exit ESP: ON / [OPEN] only"
)


print(
    "[Mateo Utility] Hitbox: OFF | L1=5x5x5 | L2=6x6x6"
)


print(
    "[Mateo Utility] Hitbox visuals: NONE"
)


print(
    "[Mateo Utility] Credits to saintedmateo"
)


print(
    "========================================"
)


--==================================================
-- END MATEO UTILITY V4.1
--==================================================
print("[Mateo Utility] Auto Rope integrated + enabled by default")
