-- mdcp The Final Nox 4.0

local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer
local CoreGui           = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local Debris            = game:GetService("Debris")
local StarterGui        = game:GetService("StarterGui")

-- ============================================================
-- Obsidian ライブラリ
-- ============================================================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
Library.ForceCheckbox = false

local MDCP_ICON = "shield" -- 盾マーク

local Window = Library:CreateWindow({
    Title = "mdcp The Final Nox",
    Footer = "v4.0",
    Icon = MDCP_ICON,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Home    = Window:AddTab("Home", "home"),
    Target  = Window:AddTab("Target", "target"),
    Blobman = Window:AddTab("Blobman", "user"),
    Defense = Window:AddTab("Defense", "shield"),
    Server  = Window:AddTab("Server", "server"),
    Break   = Window:AddTab("Break", "hammer"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Camera  = Window:AddTab("Camera", "camera"),
    Shader  = Window:AddTab("Shader", "sun"),
    Fun     = Window:AddTab("Fun", "smile"),
}

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetFolder("ScriptConfig")
SaveManager:SetFolder("ScriptConfig/Configs")
SaveManager:SetSubFolder("config")

-- ============================================================
-- リモート
-- ============================================================
local MenuToys    = ReplicatedStorage:WaitForChild("MenuToys")
local SpawnRemote = MenuToys:WaitForChild("SpawnToyRemoteFunction")
local DestroyToy  = MenuToys:WaitForChild("DestroyToy")

local GrabEvents      = ReplicatedStorage:WaitForChild("GrabEvents")
local SetNetworkOwner = GrabEvents:WaitForChild("SetNetworkOwner")
local DestroyGrabLine = GrabEvents:WaitForChild("DestroyGrabLine")
local CreateGrabLine  = GrabEvents:WaitForChild("CreateGrabLine")

local CharacterEvents = ReplicatedStorage:FindFirstChild("CharacterEvents")
local StruggleEvent   = CharacterEvents and CharacterEvents:FindFirstChild("Struggle")
local RagdollRemote   = CharacterEvents and CharacterEvents:FindFirstChild("RagdollRemote")

local PlayerEvents    = ReplicatedStorage:FindFirstChild("PlayerEvents")

local StickyPartEvent = PlayerEvents and PlayerEvents:FindFirstChild("StickyPartEvent")

-- ============================================================
-- Desync + Notification Center
-- ============================================================
local Desync = {
    enabled = false,
    loc = CFrame.new(),
    isOffsetted = false,
    _requestActive = false,
    _targetCFFunc = nil,
    _requestTimeout = 5,
    _requestStartTime = 0,
    _spinConn = nil,
    serverCF = nil,
}
local function DS_startSpin()
    if Desync._spinConn then return end
    Desync._spinConn = RunService.Heartbeat:Connect(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and Desync.enabled then
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0.01, 0)
        end
    end)
end
local function DS_stopSpin()
    task.delay(5, function()
        if Desync._spinConn and not Desync.enabled then
            Desync._spinConn:Disconnect()
            Desync._spinConn = nil
        end
    end)
end
function Desync:GetServerCFrame()
    local char = LocalPlayer.Character
    local hrp = char and (char:FindFirstChild("saviHRP") or char:FindFirstChild("HumanoidRootPart"))
    if not hrp then return nil end
    if self.enabled then
        if self._requestActive and self._targetCFFunc then
            local ok, result = pcall(self._targetCFFunc)
            if ok and typeof(result) == "CFrame" then return result end
        end
        if self.serverCF and typeof(self.serverCF) == "CFrame" then return self.serverCF end
    end
    return hrp.CFrame
end
function Desync:RequestDesync(targetCFFunc, requestTimeout)
    if self._requestActive then return false end
    self._requestActive = true
    self._targetCFFunc = targetCFFunc
    self._requestTimeout = requestTimeout or 5
    self._requestStartTime = tick()
    if not self.enabled then
        self.enabled = true
        DS_startSpin()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            self.loc = hrp.CFrame
            self.isOffsetted = false
        end
    end
    return true
end
function Desync:CancelRequest()
    if not self._requestActive then return end
    self._requestActive = false
    self._targetCFFunc = nil
    self.serverCF = nil
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and self.isOffsetted then
        hrp.CFrame = self.loc
    end
    self.isOffsetted = false
    self.enabled = false
    DS_stopSpin()
end
function Desync:IsAvailable()
    return not self._requestActive
end
function Desync:SetEnabled(on)
    if on then
        self.enabled = true
        DS_startSpin()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then self.loc = hrp.CFrame end
    else
        self:CancelRequest()
        self.enabled = false
        DS_stopSpin()
    end
end

RunService.Stepped:Connect(function()
    if Desync.enabled and Desync.isOffsetted and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and Desync.loc then
            hrp.CFrame = Desync.loc
            Desync.isOffsetted = false
        end
    end
end)
pcall(function()
    RunService:BindToRenderStep("_mdcpDesyncCamFix", 0, function()
        if Desync.enabled and Desync.isOffsetted and LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and Desync.loc then
                hrp.CFrame = Desync.loc
                Desync.isOffsetted = false
            end
        end
    end)
end)
RunService.Heartbeat:Connect(function()
    if not Desync.enabled or not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    Desync.loc = hrp.CFrame
    if Desync._requestActive and Desync._requestStartTime then
        if Desync._requestTimeout <= tick() - Desync._requestStartTime then
            Desync:CancelRequest()
            return
        end
    end
    if Desync._requestActive and Desync._targetCFFunc then
        local ok, cFrame = pcall(Desync._targetCFFunc)
        if ok and cFrame then
            hrp.CFrame = cFrame
            Desync.serverCF = cFrame
            Desync.isOffsetted = true
        end
    end
end)
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.1)
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if hrp then Desync.loc = hrp.CFrame end
    Desync.isOffsetted = false
    Desync.serverCF = nil
    if Desync._requestActive then
        Desync._requestActive = false
        Desync._targetCFFunc = nil
        Desync.enabled = false
        DS_stopSpin()
    end
end)
pcall(function()
    if getgenv then getgenv()._DESYNC = Desync end
end)
_G._DESYNC = Desync

-- Notification Center
local NotifCenter = {
    enabled = true,
    disabled = false,
}
_G._notifTypeList = {
    "All Notifications",
    "GUCCI ON",
    "Anti Lag",
    "Kick Frame Detected",
    "Break PCLD",
    "Packet Lag",
    "Line Lag",
    "Pose Target Left / Rejoin",
    "Pose Presets",
    "Target Left / Rejoin",
    "Blobman Target Left / Rejoin",
    "House Barrier Broken",
    "Player Kicked",
    "Kill",
    "Whitelisted Player Joined",
    "Whitelisted Player Left",
    "Custom Notification",
    "Theme / Config",
}
local _notifDurations = {
    ["All Notifications"] = 5,
    ["GUCCI ON"] = 1.7,
    ["Anti Lag"] = 4,
    ["Kick Frame Detected"] = 4,
    ["Break PCLD"] = 3.5,
    ["Packet Lag"] = 5,
    ["Line Lag"] = 5,
    ["Pose Target Left / Rejoin"] = 6,
    ["Pose Presets"] = 3,
    ["Target Left / Rejoin"] = 6,
    ["Blobman Target Left / Rejoin"] = 6,
    ["House Barrier Broken"] = 5.4,
    ["Player Kicked"] = 5.4,
    ["Kill"] = 3,
    ["Whitelisted Player Joined"] = 3,
    ["Whitelisted Player Left"] = 3,
    ["Custom Notification"] = 2.5,
    ["Theme / Config"] = 3,
}
_G._notifTargetSettings = {}
for _, name in ipairs(_G._notifTypeList) do
    _G._notifTargetSettings[name] = {
        Disabled = false,
        Bold = true,
        Duration = _notifDurations[name] or 5,
    }
end

_G._matchNotifType = function(title, desc)
    local a = (title or ""):lower()
    local b = (desc or ""):lower()
    if b:find("gucci") then return "GUCCI ON" end
    if b:find("anti lag") or a:find("anti lag") then return "Anti Lag" end
    if b:find("kick frame") or a:find("kick frame") then return "Kick Frame Detected" end
    if b:find("pcld") or a:find("pcld") then return "Break PCLD" end
    if a:find("packet") or b:find("packet") then return "Packet Lag" end
    if a:find("line lag") or b:find("line lag") then return "Line Lag" end
    if b:find("pose target") then return "Pose Target Left / Rejoin" end
    if b:find("preset") then return "Pose Presets" end
    if b:find("blobman") and (b:find("left") or b:find("rejoin")) then return "Blobman Target Left / Rejoin" end
    if b:find("left") or b:find("rejoin") then return "Target Left / Rejoin" end
    if b:find("house barrier") or b:find("barrier broken") then return "House Barrier Broken" end
    if b:find("kicked") or a:find("player kicked") then return "Player Kicked" end
    if b:find("kill") or a:find("kill") then return "Kill" end
    if b:find("whitelist") and b:find("join") then return "Whitelisted Player Joined" end
    if b:find("whitelist") and b:find("left") then return "Whitelisted Player Left" end
    if b:find("theme") or b:find("config") or b:find("loaded") then return "Theme / Config" end
    return "Custom Notification"
end

local _origLibraryNotify = nil
local function _stripTags(s)
    if not s then return s end
    return (tostring(s):gsub("<[uU]>", ""):gsub("</[uU]>", ""))
end

local function MDCP_Notify(title, desc, duration, notifType)
    if NotifCenter.disabled or not NotifCenter.enabled then return end
    local typ = notifType or _G._matchNotifType(title, desc)
    local cfg = _G._notifTargetSettings[typ] or _G._notifTargetSettings["All Notifications"]
    local allCfg = _G._notifTargetSettings["All Notifications"]
    if cfg and cfg.Disabled then return end
    if allCfg and allCfg.Disabled and typ ~= "Custom Notification" then return end
    local time = duration or (cfg and cfg.Duration) or 3
    local bold = not cfg or cfg.Bold ~= false
    local tTitle = tostring(title or "mdcp")
    local tDesc = tostring(desc or "")
    if not bold then
        tTitle = tTitle:gsub("<[bB]>", ""):gsub("</[bB]>", "")
        tDesc = tDesc:gsub("<[bB]>", ""):gsub("</[bB]>", "")
    end
    tTitle = _stripTags(tTitle)
    tDesc = _stripTags(tDesc)
    if _origLibraryNotify then
        pcall(function()
            _origLibraryNotify(Library, {
                Title = tTitle,
                Description = tDesc,
                Time = time,
            })
        end)
    else
        pcall(function()
            Library:Notify({ Title = tTitle, Description = tDesc, Time = time })
        end)
    end
end
_G.MDCP_Notify = MDCP_Notify

-- Hook Library.Notify (Savitar style) so ALL notifications go through filter
task.defer(function()
    if not Library or not Library.Notify then return end
    if Library._mdcpNotifHooked then return end
    Library._mdcpNotifHooked = true
    _origLibraryNotify = Library.Notify
    Library.Notify = function(self, arg2, ...)
        if NotifCenter.disabled then return end
        local typ
        if typeof(arg2) == "table" then
            typ = _G._matchNotifType(arg2.Title, arg2.Description)
        else
            typ = _G._matchNotifType("", tostring(arg2 or ""))
        end
        local cfg = _G._notifTargetSettings[typ] or _G._notifTargetSettings["All Notifications"] or { Disabled = false, Bold = true, Duration = 5 }
        if typ ~= "All Notifications" and cfg.Disabled then
            return
        end
        if typeof(arg2) == "table" then
            local v = {}
            for k, val in pairs(arg2) do v[k] = val end
            if cfg.Duration and typ ~= "All Notifications" then
                v.Time = cfg.Duration
            end
            if v.Title then
                local s = tostring(v.Title)
                if not cfg.Bold then s = s:gsub("<[bB]>", ""):gsub("</[bB]>", "") end
                v.Title = _stripTags(s)
            end
            if v.Description then
                local s = tostring(v.Description)
                if not cfg.Bold then s = s:gsub("<[bB]>", ""):gsub("</[bB]>", "") end
                v.Description = _stripTags(s)
            end
            return _origLibraryNotify(self, v, ...)
        end
        return _origLibraryNotify(self, arg2, ...)
    end
end)

-- Player kick / leave detection
task.spawn(function()
    Players.PlayerRemoving:Connect(function(plr)
        if plr == LocalPlayer then return end
        MDCP_Notify("Player Kicked", (plr.DisplayName or plr.Name) .. " left / kicked", 4, "Player Kicked")
    end)
    Players.PlayerAdded:Connect(function(plr)
        if plr == LocalPlayer then return end
        -- optional join notif disabled by default type filter
    end)
end)



-- Hook existing Library.Notify optionally for classification - skip to avoid loops



-- ============================================================
-- トイ一覧
-- ============================================================
local ToyList = {
    ["Coconut"]="FoodCoconut", ["Banana"]="FoodBanana", ["Fries"]="FoodFrenchFries",
    ["MeatStick"]="FoodMeatStick", ["Poop"]="PoopPile", ["Donut"]="FoodDonut",
    ["Cake"]="FoodCakePink", ["Burger"]="FoodHamburger", ["Pizza"]="FoodPizzaCheese",
    ["Hotdog"]="FoodHotdog", ["Mushroom"]="FoodMushroomPoison", ["Bread"]="FoodBread",
    ["Egg"]="FoodDippyEgg", ["Mayo"]="FoodMayonnaise", ["WhiteMug"]="CupMugWhite",
    ["BrownMug"]="CupMugBrown", ["SparklePoop"]="PoopPileSparkle",
}
local DropdownValues = {}
for k in pairs(ToyList) do table.insert(DropdownValues, k) end
table.sort(DropdownValues)

-- ============================================================
-- State
-- ============================================================
local State = {
    InputActive=false, InputTask=nil,
    SelectedToy=ToyList["Burger"], HoldDuration=0.02, CycleSpeed=0.05, SpawnOffsetY=-12,

    beam_count=0, auto_antilag_enabled=false,

    AntiGrabActive=false, AntiGrabConns={},
    SeatlessActive=false, SeatlessConn=nil, SeatlessSpawnTick=nil,

    GucciActive=false, GucciRunning=false, GucciType="CreatureBlobman",
    AntiBlobActive=false, AntiBlobConn=nil,
    AntiRagdollActive=false, AntiRagdollConns={},
    AntiBlobAuraActive=false, AntiBlobAuraConn=nil,

    CounterActive=false, CounterConn=nil, CounterMode="Fling",

    WD_Active=false, WD_Task=nil,
    WD_OffsetX=0, WD_OffsetY=0, WD_OffsetZ=0,

    ThirdPersonActive=false, SavedCameraMode=nil, SavedCamMinZoom=nil, SavedCamMaxZoom=nil,
    PCLD_ESP_Active=false, PCLD_ESP_Color=Color3.fromRGB(200,40,40),
    PCLD_ESP_Boxes={}, PCLD_ESP_Conns={},
    WaterWalkActive=false,

    -- Grab Kick v1
    GrabKickOn=false, TargetDisplay="", TargetName=nil,
    DistThreshold=25, UsePalette=true,
    GrabKickOffsetX=0, GrabKickOffsetY=8, GrabKickOffsetZ=0,
    GrabKickP=50000000, GrabKickD=5000,
    PaletteLoopConn=nil, PaletteItem=nil, PaletteBusy=false, GrabTask=nil,

    -- Grab Kick v2
    GrabKickV2On=false, GrabKickV2Task=nil, GrabKickV2LagOn=false, GrabKickV2LagTask=nil,
    GrabKickV2UsePalette=true, GrabKickV2PaletteItem=nil, GrabKickV2PaletteBusy=false,
    GrabKickV2PaletteConn=nil, GrabKickV2Dist=25,

    RagdollKillActive=false, RagdollMonitorTask=nil, RagdollSpawnMonitor=nil,
    RKv2Active=false, RKv2Task=nil, RKv2SavedCF=nil,
    NLKillActive=false, NLKillTask=nil,
    BananaLooping=false, BananaLoopConn=nil, BananaMonitorConn=nil,
    BananaItem=nil, BananaTargetDead=false,

    BlobKickActive=false, BlobKickTask=nil, BlobKickSavedPos=nil,
    BlobKillActive=false, BlobKillTask=nil, BlobKillStreak=0, BlobKillLastTarget=nil,
    AutoSitBlobActive=false, AutoSitBlobTask=nil,

    AntiPencilActive=false, AntiPencilTask=nil,

    -- NoBlob
    NoblobWhitelistFriends=false, NoblobFriendCache={},
    NoblobRunning=false, NoblobTask=nil, NoblobLagConn=nil, NoblobLagMode="low",
}

-- ============================================================
-- ヘルパー
-- ============================================================
local function GetLocalChar() return LocalPlayer.Character end
local function GetHRP()
    local c = GetLocalChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetSpawnedToysFolder()
    return Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
end
local function GetPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.DisplayName .. " (" .. p.Name .. ")")
        end
    end
    return list
end
local function GetPlayerDisplayList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.DisplayName)
        end
    end
    return list
end
local function FindPlayerByDisplay(display)
    if not display or display == "" then return nil end
    local startPos = string.find(display, "%(")
    if startPos then
        local name = string.sub(display, startPos + 1, -2)
        return Players:FindFirstChild(name)
    end
    -- display name only
    for _, p in ipairs(Players:GetPlayers()) do
        if p.DisplayName == display then return p end
    end
    return nil
end

local function GetTargetPlayer()
    if State.TargetName and State.TargetName ~= "" then
        local p = Players:FindFirstChild(State.TargetName)
        if p then return p end
    end
    if State.TargetDisplay and State.TargetDisplay ~= "" then
        return FindPlayerByDisplay(State.TargetDisplay)
    end
    return nil
end

local function FindChild(parent, name, timeout)
    return parent:FindFirstChild(name) or parent:WaitForChild(name, timeout or 5)
end
local function ClaimOwner(part)
    if part and part:IsA("BasePart") then
        SetNetworkOwner:FireServer(part, part.CFrame); task.wait()
    end
end

local function PurgeAllToys()
    task.spawn(function()
        for _ = 1, 3 do
            local inv = GetSpawnedToysFolder()
            if inv then
                for _, v in pairs(inv:GetChildren()) do
                    pcall(function() DestroyToy:FireServer(v) end)
                end
            end
            task.wait(0.1)
        end
    end)
end

-- ============================================================
-- ANTI INPUT LAG
-- ============================================================
local function StartAntiInput()
    if State.InputTask then task.cancel(State.InputTask) State.InputTask=nil end
    State.InputTask = task.spawn(function()
        while State.InputActive do
            local char = GetLocalChar()
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local folder = GetSpawnedToysFolder()
                local name = State.SelectedToy
                local item = folder and folder:FindFirstChild(name)
                if not item or not item.Parent then
                    task.spawn(function() pcall(function()
                        SpawnRemote:InvokeServer(name, hrp.CFrame * CFrame.new(0, State.SpawnOffsetY, 0), Vector3.zero)
                    end) end)
                    task.wait(0.1)
                else
                    local holdPart = item:FindFirstChild("HoldPart")
                    if holdPart then
                        for _, v in pairs(item:GetDescendants()) do
                            if v:IsA("BasePart") then v.CanCollide=false v.Massless=true end
                        end
                        task.spawn(function() pcall(function()
                            holdPart.HoldItemRemoteFunction:InvokeServer(item, char)
                        end) end)
                        task.wait(State.HoldDuration)
                        task.spawn(function() pcall(function()
                            holdPart.DropItemRemoteFunction:InvokeServer(item, CFrame.new(0,5000,0), Vector3.zero)
                        end) end)
                    end
                end
            end
            task.wait(State.CycleSpeed)
        end
    end)
end
local function StopAntiInput()
    State.InputActive = false
    if State.InputTask then pcall(function() task.cancel(State.InputTask) end) State.InputTask=nil end
    task.spawn(function()
        local inv = GetSpawnedToysFolder()
        if inv then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name == State.SelectedToy then
                    pcall(function() DestroyToy:FireServer(v) end)
                end
            end
        end
    end)
end

-- ============================================================
-- VISUALS
-- ============================================================
local ThirdPersonFlag = false
local function ThirdPerson_Start()
    if ThirdPersonFlag then return end
    ThirdPersonFlag = true
    State.ThirdPersonActive = true
    if not State.SavedCameraMode then
        State.SavedCameraMode = LocalPlayer.CameraMode
        State.SavedCamMinZoom = LocalPlayer.CameraMinZoomDistance
        State.SavedCamMaxZoom = LocalPlayer.CameraMaxZoomDistance
    end
    LocalPlayer.CameraMode = Enum.CameraMode.Classic
    pcall(function()
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end)
    task.spawn(function()
        for i = 1, 10 do
            if not ThirdPersonFlag then break end
            local n = 1 - i / 10
            local z = 20 * (1 - n * n * n)
            LocalPlayer.CameraMinZoomDistance = z
            LocalPlayer.CameraMaxZoomDistance = math.max(z, 100000)
            task.wait(0.008)
        end
        if ThirdPersonFlag then
            LocalPlayer.CameraMinZoomDistance = 0
            LocalPlayer.CameraMaxZoomDistance = 100000
        end
    end)
    task.spawn(function()
        while ThirdPersonFlag do
            task.wait(0.3)
            local char = LocalPlayer.Character
            if char then
                for _, child in pairs(char:GetChildren()) do
                    if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" and child.Name ~= "CamPart" then
                        child.LocalTransparencyModifier = 0
                    end
                    if child:IsA("Accessory") then
                        local p = child:FindFirstChildWhichIsA("BasePart")
                        if p then p.LocalTransparencyModifier = 0 end
                    end
                end
            end
        end
    end)
end
local function ThirdPerson_Stop()
    ThirdPersonFlag = false
    State.ThirdPersonActive = false
    LocalPlayer.CameraMode = State.SavedCameraMode or Enum.CameraMode.LockFirstPerson
    if State.SavedCamMinZoom then LocalPlayer.CameraMinZoomDistance = State.SavedCamMinZoom end
    if State.SavedCamMaxZoom then LocalPlayer.CameraMaxZoomDistance = State.SavedCamMaxZoom end
    State.SavedCameraMode = nil
    State.SavedCamMinZoom = nil
    State.SavedCamMaxZoom = nil
end

local function PCLD_IsTarget(obj)
    if not obj:IsA("BasePart") then return false end
    local n = string.lower(obj.Name)
    return n == "partesp" or n == "playercharacterlocationdetector"
end
local function PCLD_AddBox(obj)
    if State.PCLD_ESP_Boxes[obj] then
        State.PCLD_ESP_Boxes[obj].Color3 = State.PCLD_ESP_Color
        return
    end
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee=obj box.AlwaysOnTop=true box.ZIndex=5
    box.Color3=State.PCLD_ESP_Color box.Transparency=0.5
    box.Size=obj.Size box.Parent=CoreGui
    State.PCLD_ESP_Boxes[obj]=box
    table.insert(State.PCLD_ESP_Conns, obj.AncestryChanged:Connect(function(_, parent)
        if not parent and State.PCLD_ESP_Boxes[obj] then
            State.PCLD_ESP_Boxes[obj]:Destroy() State.PCLD_ESP_Boxes[obj]=nil
        end
    end))
end
local function PCLD_ESP_Start()
    if not State.PCLD_ESP_Active then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if PCLD_IsTarget(obj) then PCLD_AddBox(obj) end
    end
    table.insert(State.PCLD_ESP_Conns, Workspace.DescendantAdded:Connect(function(obj)
        if State.PCLD_ESP_Active and PCLD_IsTarget(obj) then PCLD_AddBox(obj) end
    end))
end
local function PCLD_ESP_Stop()
    State.PCLD_ESP_Active=false
    for _, box in pairs(State.PCLD_ESP_Boxes) do if box then box:Destroy() end end
    State.PCLD_ESP_Boxes={}
    for _, c in ipairs(State.PCLD_ESP_Conns) do pcall(function() c:Disconnect() end) end
    State.PCLD_ESP_Conns={}
end

local function WaterWalk_Apply(state)
    local map = Workspace:FindFirstChild("Map"); if not map then return end
    local always = map:FindFirstChild("AlwaysHereTweenedObjects"); if not always then return end
    local ocean = always:FindFirstChild("Ocean"); if not ocean then return end
    local obj = ocean:FindFirstChild("Object"); if not obj then return end
    local objModel = obj:FindFirstChild("ObjectModel"); if not objModel then return end
    for _, child in pairs(objModel:GetChildren()) do
        if child:IsA("BasePart") then child.CanCollide = state end
    end
end

-- ============================================================
-- ANTI GRAB
-- ============================================================
local function StartAntiGrab()
    local function ApplyAntiGrab(char)
        if not char or not State.AntiGrabActive then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        local head = char:WaitForChild("Head", 5)
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        if not (hrp and hum and head and torso) then return end
        local beingHeld = char:FindFirstChild("BeingHeld")
        local wasRagdolled, AntiGrabProc, AGWalk = false, false, false

        table.insert(State.AntiGrabConns, RunService.Heartbeat:Connect(function()
            local rag = hum:FindFirstChild("Ragdolled")
            if rag and rag.Value then
                wasRagdolled = true
                local la,ra = char:FindFirstChild("Left Arm"), char:FindFirstChild("Right Arm")
                local ll,rl = char:FindFirstChild("Left Leg"), char:FindFirstChild("Right Leg")
                if la then la.CFrame = torso.CFrame*CFrame.new(-1.5,0,0) la.CanCollide=false end
                if ra then ra.CFrame = torso.CFrame*CFrame.new(1.5,0,0) ra.CanCollide=false end
                if ll then ll.CFrame = torso.CFrame*CFrame.new(-0.5,-2,0) ll.CanCollide=false end
                if rl then rl.CFrame = torso.CFrame*CFrame.new(0.5,-2,0) rl.CanCollide=false end
            elseif wasRagdolled then
                wasRagdolled = false
                for _, n in ipairs({"Left Arm","Right Arm","Left Leg","Right Leg"}) do
                    local limb = char:FindFirstChild(n)
                    if limb then limb.CanCollide = true end
                end
            end
        end))

        table.insert(State.AntiGrabConns, head.ChildAdded:Connect(function(po)
            if po.Name == "PartOwner" and not AntiGrabProc then
                AntiGrabProc = true
                hum.Sit = false
                pcall(function() if StruggleEvent then StruggleEvent:FireServer(LocalPlayer) end end)
                task.spawn(function()
                    while (head and head:FindFirstChild("PartOwner")) or (beingHeld and beingHeld.Value) do
                        if not State.AntiGrabActive then break end
                        pcall(function() if StruggleEvent then StruggleEvent:FireServer(LocalPlayer) end end)
                        pcall(function() if RagdollRemote then RagdollRemote:FireServer(hrp, 0) end end)
                        task.wait()
                    end
                end)
                task.spawn(function()
                    hrp.Anchored = true
                    if not AGWalk then
                        AGWalk = true
                        pcall(function()
                            while (head and head:FindFirstChild("PartOwner")) or (beingHeld and beingHeld.Value) do
                                if not State.AntiGrabActive then break end
                                hrp.CFrame = hrp.CFrame + hum.MoveDirection * 0.43
                                task.wait()
                            end
                        end)
                    end
                    hrp.Anchored = false
                    AntiGrabProc = false
                    AGWalk = false
                end)
            end
        end))

        local weldHRP = hrp:WaitForChild("WeldHRP", 5)
        if weldHRP then
            table.insert(State.AntiGrabConns, weldHRP.Changed:Connect(function()
                if hrp.WeldHRP and hrp.WeldHRP.Enabled then
                    task.spawn(function()
                        while hrp.WeldHRP and hrp.WeldHRP.Enabled and State.AntiGrabActive do
                            hum.Sit=false hum.AutoRotate=true hum.HipHeight=0
                            pcall(function() head.CFrame = hrp.CFrame + Vector3.new(0,1.35,0) end)
                            task.wait()
                        end
                    end)
                end
            end))
        end
    end
    ApplyAntiGrab(LocalPlayer.Character)
    table.insert(State.AntiGrabConns, LocalPlayer.CharacterAdded:Connect(ApplyAntiGrab))
end
local function StopAntiGrab()
    State.AntiGrabActive = false
    for _, c in ipairs(State.AntiGrabConns) do pcall(function() c:Disconnect() end) end
    State.AntiGrabConns = {}
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = false end
        for _, n in ipairs({"Left Arm","Right Arm","Left Leg","Right Leg"}) do
            local limb = char:FindFirstChild(n)
            if limb then limb.CanCollide = true end
        end
    end
end

-- ============================================================
-- SEATLESS GUCCI / GUCCI / ANTI BLOB etc
-- ============================================================
local function StartSeatlessGucci()
    if State.SeatlessConn then return end
    State.SeatlessConn = RunService.RenderStepped:Connect(function()
        if not State.SeatlessActive then return end
        local char = LocalPlayer.Character; if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        local myToys = GetSpawnedToysFolder()
        local ocarina = myToys and myToys:FindFirstChild("InstrumentWoodwindOcarina")
        if ocarina then
            for _, prt in ipairs(char:GetChildren()) do
                local owner = prt:FindFirstChild("PartOwner")
                if owner and owner.Value ~= "" then
                    local holdFunc = ocarina:FindFirstChild("HoldPart") and ocarina.HoldPart:FindFirstChild("HoldItemRemoteFunction")
                    if holdFunc then
                        task.spawn(function() pcall(function() holdFunc:InvokeServer(ocarina, char) end) end)
                        pcall(function() DestroyToy:FireServer(ocarina) end)
                        if hum then
                            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                            hum.AutoRotate = true
                            if hum.Sit then hum.Sit = false end
                        end
                        owner.Value = ""
                    end
                end
            end
        else
            local canSpawn = LocalPlayer:FindFirstChild("CanSpawnToy")
            if canSpawn and canSpawn.Value and not State.SeatlessSpawnTick then
                State.SeatlessSpawnTick = tick()
                task.spawn(function() pcall(function()
                    SpawnRemote:InvokeServer("InstrumentWoodwindOcarina", CFrame.new(1e5,1e5,1e5), Vector3.zero)
                end) end)
            elseif State.SeatlessSpawnTick and tick() - State.SeatlessSpawnTick > 1 then
                State.SeatlessSpawnTick = nil
            end
            local grabbed = false
            for _, prt in ipairs(char:GetChildren()) do
                local owner = prt:FindFirstChild("PartOwner")
                if owner and owner.Value ~= "" then grabbed = true break end
            end
            if grabbed then
                if StruggleEvent then pcall(function() StruggleEvent:FireServer(LocalPlayer) end) end
                if RagdollRemote and root then pcall(function() RagdollRemote:FireServer(root, 0) end) end
            end
        end
    end)
end
local function StopSeatlessGucci()
    State.SeatlessActive = false
    if State.SeatlessConn then State.SeatlessConn:Disconnect() State.SeatlessConn=nil end
    State.SeatlessSpawnTick = nil
    task.spawn(function()
        local inv = GetSpawnedToysFolder()
        if inv then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name == "InstrumentWoodwindOcarina" then
                    pcall(function() DestroyToy:FireServer(v) end)
                end
            end
        end
    end)
end

local function GucciLoop()
    if State.GucciRunning then return end
    State.GucciRunning = true
    local guccion = false
    while State.GucciActive do
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            local folder = GetSpawnedToysFolder()
            local item = folder and folder:FindFirstChild(State.GucciType)
            if item and item:FindFirstChild("VehicleSeat") then
                local occ = item.VehicleSeat.Occupant
                if occ and occ ~= hum then
                    task.spawn(function() DestroyToy:FireServer(item) end)
                    item = nil; guccion = false
                end
            end
            if not item or not item.Parent then
                if LocalPlayer:FindFirstChild("CanSpawnToy") and LocalPlayer.CanSpawnToy.Value then
                    task.spawn(function() pcall(function()
                        SpawnRemote:InvokeServer(State.GucciType, hrp.CFrame * CFrame.new(0,100000000,10), Vector3.zero)
                    end) end)
                end
            else
                local seat = item:FindFirstChild("VehicleSeat")
                if seat and (not seat.Occupant or seat.Occupant == hum) then
                    if not guccion then seat:Sit(hum) guccion = true end
                    if RagdollRemote then RagdollRemote:FireServer(hrp, 0.016) end
                end
            end
        end
        task.wait()
    end
    State.GucciRunning = false
end
local function StopGucci()
    State.GucciActive = false
    State.GucciRunning = false
    task.spawn(function()
        for _ = 1, 3 do
            local folder = GetSpawnedToysFolder()
            if folder then
                for _, v in pairs(folder:GetChildren()) do
                    if v.Name == "CreatureBlobman" or v.Name == "TractorGreen" or v.Name == "SantaSleigh" then
                        pcall(function() DestroyToy:FireServer(v) end)
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

local function StartAntiBlob()
    if State.AntiBlobConn then return end
    State.AntiBlobConn = Workspace.DescendantAdded:Connect(function(toy)
        if not State.AntiBlobActive then return end
        if toy.Name == "CreatureBlobman" then
            task.wait(0.1)
            local l = toy:FindFirstChild("LeftDetector"); if l then l:Destroy() end
            local r = toy:FindFirstChild("RightDetector"); if r then r:Destroy() end
        end
    end)
end
local function StopAntiBlob()
    State.AntiBlobActive = false
    if State.AntiBlobConn then State.AntiBlobConn:Disconnect() State.AntiBlobConn=nil end
end

local function StartAntiRagdoll()
    local function Apply(char)
        if not char or not State.AntiRagdollActive then return end
        local hum = char:WaitForChild("Humanoid", 5)
        local HRP = char:WaitForChild("HumanoidRootPart", 5)
        if not (hum and HRP) then return end
        table.insert(State.AntiRagdollConns, hum:GetPropertyChangedSignal("SeatPart"):Connect(function()
            if hum.SeatPart and hum.SeatPart.Parent and hum.SeatPart.Parent.Name == "CreatureBlobman" then
                local Seat = hum.SeatPart
                task.wait(0.1)
                if RagdollRemote then RagdollRemote:FireServer(HRP, 3) end
                task.wait(0.4)
                hum.Sit = false
                Seat:Sit(hum)
                task.delay(0.25, function()
                    while hum and hum.SeatPart and State.AntiRagdollActive do
                        if RagdollRemote then RagdollRemote:FireServer(HRP, 1) end
                        task.wait(0.05)
                    end
                end)
            end
        end))
    end
    Apply(LocalPlayer.Character)
    table.insert(State.AntiRagdollConns, LocalPlayer.CharacterAdded:Connect(Apply))
end
local function StopAntiRagdoll()
    State.AntiRagdollActive = false
    for _, c in ipairs(State.AntiRagdollConns) do pcall(function() c:Disconnect() end) end
    State.AntiRagdollConns = {}
end

local function StartAntiBlobAura()
    if State.AntiBlobAuraConn then return end
    State.AntiBlobAuraConn = RunService.Heartbeat:Connect(function()
        if not State.AntiBlobAuraActive then return end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local tRoot = player.Character:FindFirstChild("HumanoidRootPart")
                local tHum = player.Character:FindFirstChild("Humanoid")
                if tRoot and tHum and tHum.SeatPart then
                    local sp = tHum.SeatPart.Parent
                    if sp and sp.Name == "CreatureBlobman" then
                        if (tRoot.Position - myRoot.Position).Magnitude <= 19 then
                            pcall(function() SetNetworkOwner:FireServer(tRoot, tRoot.CFrame) end)
                        end
                    end
                end
            end
        end
    end)
end
local function StopAntiBlobAura()
    State.AntiBlobAuraActive = false
    if State.AntiBlobAuraConn then State.AntiBlobAuraConn:Disconnect() State.AntiBlobAuraConn=nil end
end

-- ============================================================
-- COUNTER
-- ============================================================
local function StartCounter()
    if State.CounterConn then return end
    State.CounterConn = RunService.Heartbeat:Connect(function()
        if not State.CounterActive then return end
        local char = LocalPlayer.Character
        local head = char and char:FindFirstChild("Head")
        if not head then return end
        local owner = head:FindFirstChild("PartOwner")
        if not owner or not owner:IsA("StringValue") then return end
        local attacker = Players:FindFirstChild(owner.Value)
        if not attacker or not attacker.Character then return end
        local root = attacker.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        pcall(function() SetNetworkOwner:FireServer(root, root.CFrame) end)
        if DestroyGrabLine then pcall(function() DestroyGrabLine:FireServer(root) end) end
        local mode = State.CounterMode
        if mode == "Fling" then
            local away = (root.Position - char.HumanoidRootPart.Position).Unit
            away = Vector3.new(away.X,0,away.Z) * 90000
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
            bv.Velocity = away bv.P = 12500 bv.Parent = root
            Debris:AddItem(bv, 0.01)
        elseif mode == "Heaven" then
            root.CFrame = CFrame.new(0,200,0)
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(0,math.huge,0)
            bv.Velocity = Vector3.new(0,200,0) bv.Parent = root
            Debris:AddItem(bv, 0.01)
        elseif mode == "Ragdoll" then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
            bv.Velocity = Vector3.new(0,-20,0) bv.Parent = root
            Debris:AddItem(bv, 0.01)
        end
    end)
end
local function StopCounter()
    State.CounterActive = false
    if State.CounterConn then State.CounterConn:Disconnect() State.CounterConn=nil end
end

-- ============================================================
-- SprayCanWD
-- ============================================================
local function WD_CheckForHome()
    for i = 1, 5 do
        local Plots = Workspace:FindFirstChild("Plots")
        local Plot = Plots and Plots:FindFirstChild("Plot" .. i)
        if Plot then
            local PlotSign = Plot:FindFirstChild("PlotSign")
            local Owners = PlotSign and PlotSign:FindFirstChild("ThisPlotsOwners")
            if Owners then
                for _, v in pairs(Owners:GetChildren()) do
                    if v.Value == LocalPlayer.Name then
                        local PlotItems = Workspace:FindFirstChild("PlotItems")
                        return PlotItems and PlotItems:FindFirstChild("Plot" .. i)
                    end
                end
            end
        end
    end
    return nil
end

local function WD_SpawnToy(ToyName)
    local hrp = GetHRP(); if not hrp then return nil end
    local InPlot      = LocalPlayer:FindFirstChild("InPlot")
    local InOwnedPlot = LocalPlayer:FindFirstChild("InOwnedPlot")
    local CanSpawnToy = LocalPlayer:FindFirstChild("CanSpawnToy")

    if InPlot and InOwnedPlot and InPlot.Value and not InOwnedPlot.Value then
        InPlot:GetPropertyChangedSignal("Value"):Wait()
    end
    if CanSpawnToy and not CanSpawnToy.Value then
        CanSpawnToy:GetPropertyChangedSignal("Value"):Wait()
    end

    local SpawnCF = hrp.CFrame * CFrame.new(0, 14, 20)
    local Container = (InOwnedPlot and InOwnedPlot.Value) and WD_CheckForHome() or GetSpawnedToysFolder()
    if not Container then return nil end

    local spawned = nil
    local conn
    conn = Container.ChildAdded:Connect(function(child)
        if child.Name == ToyName then spawned = child end
    end)

    task.spawn(function()
        pcall(function()
            SpawnRemote:InvokeServer(ToyName, SpawnCF, Vector3.zero)
        end)
    end)

    local start = tick()
    repeat task.wait() until spawned or (tick() - start) > 2.5
    if conn then conn:Disconnect() end
    return spawned
end

local function WD_ChangeCollision(obj, val)
    for _, v in pairs(obj:GetChildren()) do
        if v:IsA("BasePart") and v.Name ~= "GrabParts" then
            v.CanCollide = val
        end
    end
end

local function WD_RenameInShop(Instance, OriginalName, ToRename)
    local inv = GetSpawnedToysFolder()
    if not inv then return end
    local index = nil
    local ToCheckName = Instance.Name or Instance
    for i, v in pairs(inv:GetChildren()) do
        if v.Name == ToCheckName then index = i end
    end
    if index == nil then return end
    local MenuGui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MenuGui")
    local Contents = MenuGui and MenuGui.Menu.TabContents.ToyDestroy.Contents
    if not Contents then return end
    for i, v in ipairs(Contents:GetChildren()) do
        if v.Name == OriginalName and i == index then
            local view = v:FindFirstChild("ViewItemButton")
            if view then
                view.Text = ToRename
                view.TextScaled = true
                local img = view:FindFirstChild("LowResImage")
                if img then img.Image = "" end
            end
        end
    end
end

local function WD_Start()
    if State.WD_Task then task.cancel(State.WD_Task) State.WD_Task=nil end
    State.WD_Task = task.spawn(function()
        local inv = GetSpawnedToysFolder()
        if not inv then return end

        local WD = inv:FindFirstChild("SprayCanWD")
        local SoundPart = WD and WD:FindFirstChild("SoundPart")

        if not WD then
            WD = WD_SpawnToy("SprayCanWD")
            repeat task.wait() until (WD and WD:FindFirstChild("SoundPart")) or not State.WD_Active
            if not WD then State.WD_Active = false return end
            SoundPart = WD:FindFirstChild("SoundPart") or WD:WaitForChild("SoundPart", 3)
            WD_ChangeCollision(WD, false)
            task.delay(1, WD_RenameInShop, WD, WD.Name, "SprayFollow")
        end

        local HitBox = WD:FindFirstChild("Hitbox") or WD:WaitForChild("Hitbox", 3)
        if HitBox then
            repeat
                pcall(function() SetNetworkOwner:FireServer(HitBox, HitBox.CFrame) end)
                task.wait(0.05)
            until not HitBox.Parent or not State.WD_Active or HitBox:FindFirstChild("PartOwner")
        end

        while State.WD_Active do
            local char = LocalPlayer.Character
            if not char then
                char = LocalPlayer.CharacterAdded:Wait()
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(0.1) continue end

            SoundPart = WD and WD.Parent and WD:FindFirstChild("SoundPart")

            if not SoundPart then
                WD = WD_SpawnToy("SprayCanWD")
                repeat task.wait() until (WD and WD:FindFirstChild("SoundPart")) or not State.WD_Active
                if not WD then break end
                SoundPart = WD:FindFirstChild("SoundPart") or WD:WaitForChild("SoundPart", 3)
                WD_ChangeCollision(WD, false)
                HitBox = WD:FindFirstChild("Hitbox") or WD:WaitForChild("Hitbox", 3)
                if HitBox then
                    repeat
                        pcall(function() SetNetworkOwner:FireServer(HitBox, HitBox.CFrame) end)
                        task.wait(0.05)
                    until not HitBox.Parent or HitBox:FindFirstChild("PartOwner") or not State.WD_Active
                end
                task.delay(1, WD_RenameInShop, WD, WD.Name, "SprayFollow")
            end

            if not SoundPart then task.wait(0.1) continue end

            SoundPart.CFrame = hrp.CFrame * CFrame.new(State.WD_OffsetX or 0, State.WD_OffsetY or 0, State.WD_OffsetZ or 0)
            SoundPart.AssemblyAngularVelocity = Vector3.zero
            SoundPart.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.1)
        end
    end)
end

local function WD_Stop()
    State.WD_Active = false
    if State.WD_Task then pcall(function() task.cancel(State.WD_Task) end) State.WD_Task = nil end
    task.spawn(function()
        for _ = 1, 3 do
            local inv = GetSpawnedToysFolder()
            if inv then
                for _, v in pairs(inv:GetChildren()) do
                    if v.Name == "Anti-AntiKick" or v.Name == "SprayCanWD" then
                        pcall(function() DestroyToy:FireServer(v) end)
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- ============================================================
-- ANTI LAG
-- ============================================================
local auto_antilag_thread = nil

local function EnableAntiLagSystem()
    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        if ps and ps:FindFirstChild("CharacterAndBeamMove") then
            ps.CharacterAndBeamMove.Enabled = false
        end
    end)
end

local function DisableAntiLagSystem()
    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        if ps and ps:FindFirstChild("CharacterAndBeamMove") then
            ps.CharacterAndBeamMove.Enabled = true
        end
    end)
end

local function EnableAutoAntiLag()
    if State.auto_antilag_enabled then return end
    State.auto_antilag_enabled = true
    auto_antilag_thread = task.spawn(function()
        while State.auto_antilag_enabled do
            task.wait(0.5)
            if State.beam_count > 100 then
                EnableAntiLagSystem()
                State.beam_count = 0
            end
        end
    end)
end

local function DisableAutoAntiLag()
    State.auto_antilag_enabled = false
    if auto_antilag_thread then
        pcall(function() task.cancel(auto_antilag_thread) end)
        auto_antilag_thread = nil
    end
    DisableAntiLagSystem()
end

Workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "GrabBeam" then
        State.beam_count = State.beam_count + 1
    end
end)

EnableAntiLagSystem()
EnableAutoAntiLag()

-- ============================================================
-- GRAB KICK v1 (既存)
-- ============================================================
local function TeleportAndClaim(targetPlayer, myRoot)
    if not targetPlayer.Character then return end
    local tRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not tRoot or not myRoot then return end
    local saved = myRoot.CFrame
    myRoot.CFrame = tRoot.CFrame * CFrame.new(0,0,2)
    for _ = 1, 15 do SetNetworkOwner:FireServer(tRoot, tRoot.CFrame); task.wait() end
    myRoot.CFrame = saved
end

local function SpawnPallet()
    if State.PaletteBusy then return nil end
    State.PaletteBusy = true

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local w = 0
    while (LocalPlayer.InPlot and LocalPlayer.InPlot.Value
        and LocalPlayer.InOwnedPlot and not LocalPlayer.InOwnedPlot.Value)
        and w < 50 do task.wait(0.1); w = w + 1 end
    w = 0
    while LocalPlayer.CanSpawnToy and not LocalPlayer.CanSpawnToy.Value and w < 50 do
        task.wait(0.1); w = w + 1
    end

    local spawnCF = hrp.CFrame * CFrame.new(0, 14, 20)
    local folder = GetSpawnedToysFolder()
    if not folder then
        folder = Workspace:FindFirstChild("PlotItems")
        if folder then folder = folder:FindFirstChild("Plot1") end
    end
    if not folder then folder = Workspace end

    local spawned = nil
    local conn = folder.ChildAdded:Connect(function(c)
        if c.Name == "PalletLightBrown" then spawned = c end
    end)

    task.spawn(function()
        pcall(function()
            SpawnRemote:InvokeServer("PalletLightBrown", spawnCF, Vector3.zero)
        end)
    end)

    local t0 = tick()
    repeat task.wait(0.05) until spawned or (tick() - t0) > 5
    if conn then pcall(function() conn:Disconnect() end) end

    if not spawned then State.PaletteBusy = false return nil end

    local sp = nil
    for _ = 1, 40 do
        sp = spawned:FindFirstChild("SoundPart")
        if sp then break end
        task.wait(0.05)
    end
    if not sp then
        pcall(function() DestroyToy:FireServer(spawned) end)
        State.PaletteBusy = false
        return nil
    end

    local gotOwner = false
    for _ = 1, 20 do
        pcall(function() SetNetworkOwner:FireServer(sp, sp.CFrame) end)
        task.wait(0.05)
        local po = sp:FindFirstChild("PartOwner")
        if po and po.Value == LocalPlayer.Name then
            gotOwner = true
            break
        end
    end

    if not gotOwner then
        pcall(function() DestroyToy:FireServer(spawned) end)
        State.PaletteBusy = false
        return nil
    end

    for _, v in pairs(spawned:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.CanQuery = false
            v.Transparency = 0.8
        end
    end
    spawned.Name = "RagdollPalete"

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(0, math.huge, 0)
    bv.Velocity = Vector3.new(0, 900, 0)
    bv.Parent = sp

    State.PaletteBusy = false
    return spawned
end

local function GrabKickCleanup()
    if State.PaletteLoopConn then
        State.PaletteLoopConn:Disconnect()
        State.PaletteLoopConn = nil
    end
    task.spawn(function()
        local t = State.TargetName and Players:FindFirstChild(State.TargetName)
        if t and t.Character then
            local tr = t.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local bp = tr:FindFirstChild("ControlBP")
                if bp then bp:Destroy() end
                local bg = tr:FindFirstChild("ControlBG")
                if bg then bg:Destroy() end
                local th = t.Character:FindFirstChild("Humanoid")
                if th then
                    pcall(function()
                        th.PlatformStand = false
                        th.Sit = false
                    end)
                end
            end
        end
        if State.PaletteItem then
            pcall(function() DestroyToy:FireServer(State.PaletteItem) end)
            State.PaletteItem = nil
        end
        task.spawn(function()
            local inv = GetSpawnedToysFolder()
            if inv then
                for _, v in pairs(inv:GetChildren()) do
                    if v.Name == "RagdollPalete" or v.Name == "PalletLightBrown" then
                        pcall(function() DestroyToy:FireServer(v) end)
                    end
                end
            end
        end)
    end)
end

local function StartGrabKick()
    State.GrabTask = task.spawn(function()
        while State.GrabKickOn do
            local target = State.TargetName and Players:FindFirstChild(State.TargetName)
            local myRoot = GetHRP()
            if target and myRoot then
                local tChar = target.Character
                local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                if tRoot then
                    if (myRoot.Position - tRoot.Position).Magnitude > State.DistThreshold then
                        TeleportAndClaim(target, myRoot)
                    end

                    for _ = 1, 5 do
                        pcall(function() SetNetworkOwner:FireServer(tRoot, tRoot.CFrame) end)
                    end
                    if DestroyGrabLine then DestroyGrabLine:FireServer(tRoot) end

                    tRoot.AssemblyLinearVelocity = Vector3.zero
                    tRoot.AssemblyAngularVelocity = Vector3.zero

                    local tHum2 = tChar and tChar:FindFirstChild("Humanoid")
                    if tHum2 then
                        pcall(function()
                            tHum2.PlatformStand = true
                            tHum2.Sit = true
                        end)
                    end
                    for _, partName in ipairs({"Head","Torso","UpperTorso","LowerTorso","Left Arm","Right Arm","Left Leg","Right Leg"}) do
                        local part = tChar and tChar:FindFirstChild(partName)
                        if part then
                            pcall(function()
                                part.AssemblyLinearVelocity = Vector3.zero
                                part.AssemblyAngularVelocity = Vector3.zero
                            end)
                        end
                    end

                    local bp = tRoot:FindFirstChild("ControlBP")
                    if not bp then
                        bp = Instance.new("BodyPosition")
                        bp.Name = "ControlBP"
                        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bp.P = State.GrabKickP
                        bp.D = State.GrabKickD
                        bp.Parent = tRoot
                    end
                    bp.Position = myRoot.Position + Vector3.new(State.GrabKickOffsetX, State.GrabKickOffsetY, State.GrabKickOffsetZ)
                    bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bp.P = State.GrabKickP
                    bp.D = State.GrabKickD

                    local bg = tRoot:FindFirstChild("ControlBG")
                    if not bg then
                        bg = Instance.new("BodyGyro")
                        bg.Name = "ControlBG"
                        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                        bg.P = State.GrabKickP
                        bg.D = State.GrabKickD
                        bg.Parent = tRoot
                    end
                    bg.CFrame = CFrame.new(tRoot.Position, myRoot.Position)
                    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    bg.P = State.GrabKickP
                    bg.D = State.GrabKickD
                end
            end
            RunService.RenderStepped:Wait()
        end
        GrabKickCleanup()
    end)
end

local function StartPaletteLoop()
    local folder = GetSpawnedToysFolder()
    if State.PaletteLoopConn then State.PaletteLoopConn:Disconnect() end
    State.PaletteLoopConn = RunService.RenderStepped:Connect(function()
        if not State.GrabKickOn or not State.UsePalette or not State.TargetName then return end
        local target = Players:FindFirstChild(State.TargetName)
        if not target or not target.Character then return end
        local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
        local tHum = target.Character:FindFirstChild("Humanoid")
        if not tRoot or not tHum then return end
        if State.PaletteItem and State.PaletteItem:IsDescendantOf(Workspace) then
            local sp = State.PaletteItem:FindFirstChild("SoundPart")
            if sp then
                if not FindChild(sp, "PartOwner") then State.PaletteItem:Destroy() State.PaletteItem=nil end
            else
                State.PaletteItem:Destroy() State.PaletteItem=nil
            end
        end
        if not State.PaletteBusy and (not State.PaletteItem or not State.PaletteItem:IsDescendantOf(Workspace)) then
            State.PaletteItem = folder and folder:FindFirstChild("RagdollPalete") or SpawnPallet()
        end
        if State.PaletteItem and State.PaletteItem:FindFirstChild("SoundPart") then
            local rag = tHum:FindFirstChild("Ragdolled")
            if rag and not rag.Value then State.PaletteItem.SoundPart.Position = tRoot.Position end
        end
    end)
end

-- ============================================================
-- GRAB KICK v2 (beta再現)
-- ============================================================
local function GKv2_SpawnPallet()
    if State.GrabKickV2PaletteBusy then return nil end
    State.GrabKickV2PaletteBusy = true

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local w = 0
    while (LocalPlayer:FindFirstChild("InPlot") and LocalPlayer.InPlot.Value
        and LocalPlayer:FindFirstChild("InOwnedPlot") and not LocalPlayer.InOwnedPlot.Value)
        and w < 50 do task.wait(0.1); w = w + 1 end
    w = 0
    while LocalPlayer:FindFirstChild("CanSpawnToy") and not LocalPlayer.CanSpawnToy.Value and w < 50 do
        task.wait(0.1); w = w + 1
    end

    local spawnCF = hrp.CFrame * CFrame.new(0, 14, 20)
    local folder = GetSpawnedToysFolder()
    if not folder then
        folder = Workspace:FindFirstChild("PlotItems")
        if folder then folder = folder:FindFirstChild("Plot1") end
    end
    if not folder then folder = Workspace end

    local spawned = nil
    local conn = folder.ChildAdded:Connect(function(c)
        if c.Name == "PalletLightBrown" then spawned = c end
    end)

    task.spawn(function()
        pcall(function()
            SpawnRemote:InvokeServer("PalletLightBrown", spawnCF, Vector3.zero)
        end)
    end)

    local t0 = tick()
    repeat task.wait(0.05) until spawned or (tick() - t0) > 5
    if conn then pcall(function() conn:Disconnect() end) end

    if not spawned then State.GrabKickV2PaletteBusy = false return nil end

    local sp = FindChild(spawned, "SoundPart", 3)
    if not sp then
        pcall(function() DestroyToy:FireServer(spawned) end)
        State.GrabKickV2PaletteBusy = false
        return nil
    end

    local gotOwner = false
    for _ = 1, 15 do
        if not State.GrabKickV2On then
            pcall(function() DestroyToy:FireServer(spawned) end)
            State.GrabKickV2PaletteBusy = false
            return nil
        end
        pcall(function() SetNetworkOwner:FireServer(sp, sp.CFrame) end)
        task.wait()
        if sp:FindFirstChild("PartOwner") then
            gotOwner = true
            break
        end
    end

    if not gotOwner then
        pcall(function() DestroyToy:FireServer(spawned) end)
        State.GrabKickV2PaletteBusy = false
        return nil
    end

    for _, v in pairs(spawned:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.Transparency = 0.8
        end
    end
    spawned.Name = "RagdollPalete"

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(0, math.huge, 0)
    bv.Velocity = Vector3.new(0, 900, 0)
    bv.Parent = sp

    State.GrabKickV2PaletteBusy = false
    return spawned
end

local function GKv2_StartLag()
    if State.GrabKickV2LagOn then return end
    State.GrabKickV2LagOn = true
    State.GrabKickV2LagTask = task.spawn(function()
        while State.GrabKickV2LagOn do
            local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
                or Workspace:FindFirstChild("Spawn")
                or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
            if spawnLocation and CreateGrabLine then
                pcall(function()
                    CreateGrabLine:FireServer(
                        spawnLocation,
                        CFrame.new(
                            math.random(-2010000000, 2000000001),
                            0,
                            math.random(-2008100000, 2000200000)
                        )
                    )
                end)
            end
            task.wait()
        end
    end)
end

local function GKv2_StopLag()
    State.GrabKickV2LagOn = false
    if State.GrabKickV2LagTask then
        pcall(function() task.cancel(State.GrabKickV2LagTask) end)
        State.GrabKickV2LagTask = nil
    end
end

local function GKv2_Start()
    if State.GrabKickV2Task then return end
    State.GrabKickV2Task = task.spawn(function()
        while State.GrabKickV2On do
            local target = State.TargetName and Players:FindFirstChild(State.TargetName)
            local myRoot = GetHRP()
            if target and myRoot then
                local tChar = target.Character
                local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                if tRoot then
                    if (myRoot.Position - tRoot.Position).Magnitude > State.GrabKickV2Dist then
                        TeleportAndClaim(target, myRoot)
                    end
                    RunService.RenderStepped:Wait()
                    pcall(function() SetNetworkOwner:FireServer(tRoot, tRoot.CFrame) end)
                    if DestroyGrabLine then pcall(function() DestroyGrabLine:FireServer(tRoot) end) end
                    tRoot.AssemblyLinearVelocity = Vector3.zero
                    tRoot.AssemblyAngularVelocity = Vector3.zero

                    local bp = tRoot:FindFirstChild("ControlBP")
                    if not bp then
                        bp = Instance.new("BodyPosition")
                        bp.Name = "ControlBP"
                        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bp.P = 800000
                        bp.Parent = tRoot
                    end
                    bp.Position = myRoot.Position + Vector3.new(5, 10, 5)
                end
            end
            task.wait()
        end
        -- cleanup
        local t = State.TargetName and Players:FindFirstChild(State.TargetName)
        if t and t.Character then
            local tr = t.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local bp = tr:FindFirstChild("ControlBP")
                if bp then bp:Destroy() end
            end
        end
    end)
end

local function GKv2_StartPalette()
    if State.GrabKickV2PaletteConn then State.GrabKickV2PaletteConn:Disconnect() end
    local folder = GetSpawnedToysFolder()
    State.GrabKickV2PaletteConn = RunService.RenderStepped:Connect(function()
        if not State.GrabKickV2On or not State.GrabKickV2UsePalette or not State.TargetName then return end
        local target = Players:FindFirstChild(State.TargetName)
        if not target or not target.Character then return end
        local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
        local tHum = target.Character:FindFirstChild("Humanoid")
        if not tRoot or not tHum then return end

        if State.GrabKickV2PaletteItem and State.GrabKickV2PaletteItem:IsDescendantOf(Workspace) then
            local sp = State.GrabKickV2PaletteItem:FindFirstChild("SoundPart")
            if sp then
                if not sp:FindFirstChild("PartOwner") then
                    State.GrabKickV2PaletteItem:Destroy()
                    State.GrabKickV2PaletteItem = nil
                end
            else
                State.GrabKickV2PaletteItem:Destroy()
                State.GrabKickV2PaletteItem = nil
            end
        end

        if not State.GrabKickV2PaletteBusy and (not State.GrabKickV2PaletteItem or not State.GrabKickV2PaletteItem:IsDescendantOf(Workspace)) then
            State.GrabKickV2PaletteItem = folder and folder:FindFirstChild("RagdollPalete") or GKv2_SpawnPallet()
        end

        if State.GrabKickV2PaletteItem and State.GrabKickV2PaletteItem:FindFirstChild("SoundPart") then
            local rag = tHum:FindFirstChild("Ragdolled")
            if rag and not rag.Value then
                State.GrabKickV2PaletteItem.SoundPart.Position = tRoot.Position
            end
        end
    end)
end

local function GKv2_Stop()
    State.GrabKickV2On = false
    if State.GrabKickV2Task then pcall(function() task.cancel(State.GrabKickV2Task) end) State.GrabKickV2Task=nil end
    if State.GrabKickV2PaletteConn then State.GrabKickV2PaletteConn:Disconnect() State.GrabKickV2PaletteConn=nil end
    GKv2_StopLag()
    task.spawn(function()
        if State.GrabKickV2PaletteItem then
            pcall(function() DestroyToy:FireServer(State.GrabKickV2PaletteItem) end)
            State.GrabKickV2PaletteItem = nil
        end
        local inv = GetSpawnedToysFolder()
        if inv then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name == "RagdollPalete" or v.Name == "PalletLightBrown" then
                    pcall(function() DestroyToy:FireServer(v) end)
                end
            end
        end
    end)
end

-- ============================================================
-- RAGDOLL KILL / BANANA / BLOB
-- ============================================================
local function RK_DestroyPencils()
    local folder = GetSpawnedToysFolder(); if not folder then return end
    for _, c in pairs(folder:GetChildren()) do
        if c.Name == "ToolPencil" then pcall(function() DestroyToy:FireServer(c) end) end
    end
end
local function RK_CountPencils()
    local folder = GetSpawnedToysFolder(); if not folder then return 0 end
    local n = 0
    for _, c in pairs(folder:GetChildren()) do
        if c.Name == "ToolPencil" then n = n + 1 end
    end
    return n
end
local function RK_IsWelded()
    local folder = GetSpawnedToysFolder(); if not folder then return false end
    local target = State.TargetName and Players:FindFirstChild(State.TargetName)
    if not target or not target.Character then return false end
    local tHead = target.Character:FindFirstChild("Head"); if not tHead then return false end
    for _, c in pairs(folder:GetChildren()) do
        if c.Name == "ToolPencil" then
            local sp = c:FindFirstChild("StickyPart")
            if sp then
                local w = sp:FindFirstChild("StickyWeld")
                if w and w.Part1 == tHead then return true end
            end
        end
    end
    return false
end
local function RK_SpawnPencil()
    local hrp = GetHRP(); if not hrp then return nil end
    local folder = GetSpawnedToysFolder(); if not folder then return nil end
    local spawned = nil
    local conn
    conn = folder.ChildAdded:Connect(function(c)
        if c.Name == "ToolPencil" then spawned = c conn:Disconnect() end
    end)
    task.spawn(function() pcall(function()
        SpawnRemote:InvokeServer("ToolPencil", hrp.CFrame * CFrame.new(0,14,20), Vector3.zero)
    end) end)
    local t0 = tick()
    repeat task.wait(0.05) until spawned or (tick()-t0) > 3
    if conn then pcall(function() conn:Disconnect() end) end
    return spawned
end
local function RK_SetNet(part)
    if not part then return end
    pcall(function()
        for _ = 1, 5 do SetNetworkOwner:FireServer(part, part.CFrame) end
    end)
end
local function RK_DoSticky()
    if not State.TargetName then return false end
    local target = Players:FindFirstChild(State.TargetName)
    if not target or not target.Character then return false end
    local tHead = target.Character:FindFirstChild("Head"); if not tHead then return false end
    RK_DestroyPencils(); task.wait(0.05)
    local pencil = RK_SpawnPencil(); if not pencil then return false end
    local sp = pencil:FindFirstChild("SoundPart")
    local sticky = pencil:FindFirstChild("StickyPart")
    if sp then RK_SetNet(sp) end
    task.wait(0.05)
    if sticky and StickyPartEvent then
        pcall(function()
            StickyPartEvent:FireServer(sticky, tHead, CFrame.new(0, 0/0, 0))
            StickyPartEvent:FireServer(sticky, tHead, CFrame.new(0, 0/0, 0))
        end)
        task.wait(0.5)
        if not RK_IsWelded() then
            RK_DestroyPencils(); task.wait(0.05); RK_DoSticky()
        end
        return true
    end
    return false
end
local function RK_Monitor()
    while State.RagdollKillActive do
        local n = RK_CountPencils()
        if n == 0 then RK_DoSticky()
        elseif n >= 2 then RK_DestroyPencils(); task.wait(0.05); RK_DoSticky()
        elseif n == 1 and not RK_IsWelded() then RK_DestroyPencils(); task.wait(0.05); RK_DoSticky() end
        task.wait(0.1)
    end
end
local function RK_Respawn()
    local target = State.TargetName and Players:FindFirstChild(State.TargetName)
    if not target then return end
    if State.RagdollSpawnMonitor then State.RagdollSpawnMonitor:Disconnect() end
    State.RagdollSpawnMonitor = target.CharacterAdded:Connect(function()
        if State.RagdollKillActive then RK_DoSticky() end
    end)
end
local function RagdollKill_Start()
    State.RagdollKillActive = true
    RK_DoSticky(); RK_Respawn()
    State.RagdollMonitorTask = task.spawn(RK_Monitor)
    task.spawn(function()
        local lastAlive = {}
        while State.RagdollKillActive do
            local target = GetTargetPlayer and GetTargetPlayer() or nil
            if target and target.Character then
                local hum = target.Character:FindFirstChildOfClass("Humanoid")
                local name = target.DisplayName or target.Name
                if hum then
                    if hum.Health > 0 then
                        lastAlive[name] = true
                    elseif lastAlive[name] then
                        lastAlive[name] = false
                        State.TargetKillStreak = (State.TargetKillLast == name and (State.TargetKillStreak or 0) + 1) or 1
                        State.TargetKillLast = name
                        if MDCP_Notify then
                            MDCP_Notify("Kill", string.format("%s をキル | 連続: %d", name, State.TargetKillStreak), 3, "Kill")
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end)
end
local function RagdollKill_Stop()
    State.RagdollKillActive = false
    if State.RagdollMonitorTask then pcall(function() task.cancel(State.RagdollMonitorTask) end) State.RagdollMonitorTask=nil end
    if State.RagdollSpawnMonitor then State.RagdollSpawnMonitor:Disconnect() State.RagdollSpawnMonitor=nil end
    task.spawn(function()
        for _ = 1, 3 do
            RK_DestroyPencils()
            task.wait(0.1)
        end
    end)
end

-- Ragdoll Kill v2
local function RKv2_LookAt(fromPos, toPos)
    local d = (toPos - fromPos)
    if d.Magnitude < 0.001 then return CFrame.new(fromPos) end
    d = d.Unit
    local r = d:Cross(Vector3.new(0, 1, 0))
    if r.Magnitude < 0.001 then r = d:Cross(Vector3.new(1, 0, 0)) end
    r = r.Unit
    local u = r:Cross(d)
    return CFrame.fromMatrix(fromPos, r, u)
end

local function RKv2_Stop()
    State.RKv2Active = false
    if State.RKv2Task then pcall(function() task.cancel(State.RKv2Task) end) State.RKv2Task = nil end
    local target = GetTargetPlayer()
    if target and target.Character then
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() DestroyGrabLine:FireServer(hrp) end) end
    end
    if State.RKv2SavedCF then
        local my = GetHRP()
        if my then pcall(function() my.CFrame = State.RKv2SavedCF end) end
    end
end

local function RKv2_Start()
    if State.RKv2Active then return end
    if not GetTargetPlayer() then
        Library:Notify({Title = "mdcp", Description = "ターゲットを選択してください", Time = 3})
        return
    end
    State.RKv2Active = true
    State.RKv2Task = task.spawn(function()
        while State.RKv2Active do
            local myHrp = GetHRP()
            if myHrp and myHrp.Position.Y > -50 then
                State.RKv2SavedCF = myHrp.CFrame
            end

            local target = GetTargetPlayer()
            if target and target.Character then
                local char = target.Character
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hrp and head and hum and hum.Health > 0 then
                    local isCaptured = false

                    task.spawn(function()
                        for _ = 1, 30 do
                            if not State.RKv2Active then break end
                            pcall(function()
                                if StruggleEvent then StruggleEvent:FireServer(char) end
                                if RagdollRemote then RagdollRemote:FireServer(hrp, 0) end
                                local stopVel = ReplicatedStorage:FindFirstChild("GameCorrectionEvents")
                                    and ReplicatedStorage.GameCorrectionEvents:FindFirstChild("StopAllVelocity")
                                if stopVel then stopVel:FireServer() end
                                task.delay(0.03, function() pcall(function() DestroyGrabLine:FireServer(hrp) end) end)
                                task.delay(0.05, function() pcall(function() DestroyGrabLine:FireServer(hrp) end) end)
                                local me = GetHRP()
                                if me and LocalPlayer:DistanceFromCharacter(hrp.Position) <= 30 then
                                    SetNetworkOwner:FireServer(hrp, RKv2_LookAt(me.Position, hrp.Position))
                                end
                            end)
                            task.wait()
                        end
                    end)

                    pcall(function()
                        local truePos = char:FindFirstChild("TruePositionPart")
                        if truePos then truePos:Destroy() end
                        local attach = hrp:FindFirstChild("RootAttachment")
                        if attach then attach.Parent = hrp end
                    end)

                    for _ = 1, 50 do
                        if not State.RKv2Active then break end
                        if not (target.Parent and target.Character and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0) then
                            break
                        end
                        pcall(function()
                            local me = GetHRP()
                            if me and LocalPlayer:DistanceFromCharacter(hrp.Position) <= 30 then
                                SetNetworkOwner:FireServer(hrp, RKv2_LookAt(me.Position, hrp.Position))
                            end
                        end)
                        pcall(function()
                            local truePos = char:FindFirstChild("TruePositionPart")
                            if truePos then truePos:Destroy() end
                            local attach = hrp:FindFirstChild("RootAttachment")
                            if attach then attach.Parent = hrp end
                        end)
                        task.delay(0.03, function() pcall(function() DestroyGrabLine:FireServer(hrp) end) end)
                        pcall(function()
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            hrp.Anchored = false
                        end)
                        pcall(function()
                            local partOwner = head:FindFirstChild("PartOwner")
                            if partOwner then partOwner.Value = LocalPlayer.Name end
                        end)
                        local hasOwner = head:FindFirstChild("PartOwner") and head.PartOwner.Value == LocalPlayer.Name
                        if hasOwner or hrp.AssemblyLinearVelocity.Magnitude > 500 then
                            isCaptured = true
                            break
                        end
                        task.wait()
                        local me = GetHRP()
                        if me then
                            if hrp.Position.Y <= -12 then
                                if State.RKv2SavedCF then me.CFrame = State.RKv2SavedCF end
                            else
                                me.CFrame = CFrame.new(hrp.Position + Vector3.new(0, -10, -10))
                            end
                        end
                        pcall(function()
                            hum.BreakJointsOnDeath = false
                            hum:ChangeState(Enum.HumanoidStateType.Dead)
                            hum.Jump = true
                            hum.Sit = false
                        end)
                    end

                    if isCaptured and State.RKv2Active and target.Parent and target.Character and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
                        if State.RKv2SavedCF then
                            local me = GetHRP()
                            if me then me.CFrame = State.RKv2SavedCF end
                        end
                        for _ = 1, 25 do
                            if not State.RKv2Active then break end
                            pcall(function()
                                hrp.Anchored = false
                                hrp.CFrame = CFrame.new(hrp.Position.X, -400, hrp.Position.Z)
                                hrp.AssemblyLinearVelocity = Vector3.new(0, -3000, 0)
                                for _, p in pairs(char:GetChildren()) do
                                    if p:IsA("BasePart") then p.CanCollide = false end
                                end
                            end)
                            task.delay(0.03, function() pcall(function() DestroyGrabLine:FireServer(hrp) end) end)
                            task.wait()
                        end
                        for _ = 1, 40 do
                            if not State.RKv2Active then break end
                            pcall(function()
                                hrp.Anchored = false
                                hrp.CFrame = CFrame.new(hrp.Position.X, -1000000, hrp.Position.Z)
                                hrp.AssemblyLinearVelocity = Vector3.new(0, -1000000, 0)
                                for _, p in pairs(char:GetChildren()) do
                                    if p:IsA("BasePart") then p.CanCollide = false end
                                end
                            end)
                            task.delay(0.03, function() pcall(function() DestroyGrabLine:FireServer(hrp) end) end)
                            task.wait()
                        end
                        pcall(function()
                            for _, p in pairs(char:GetChildren()) do
                                if p:IsA("BasePart") then p.CanCollide = true end
                            end
                        end)
                        -- kill notify
                        task.delay(0.15, function()
                            local still = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
                            if not still or still.Health <= 0 then
                                local tName = target.DisplayName or target.Name
                                State.TargetKillStreak = (State.TargetKillLast == tName and (State.TargetKillStreak or 0) + 1) or 1
                                State.TargetKillLast = tName
                                if MDCP_Notify then
                                    MDCP_Notify("Kill", string.format("%s をキル | 連続: %d", tName, State.TargetKillStreak), 3, "Kill")
                                end
                            end
                        end)
                    end
                end
            end

            if State.RKv2SavedCF then
                local me = GetHRP()
                if me then pcall(function() me.CFrame = State.RKv2SavedCF end) end
            end
            task.wait(0.1)
        end
    end)
end

-- Kill
local function NLKill_Stop()
    State.NLKillActive = false
    if State.NLKillTask then
        pcall(function() task.cancel(State.NLKillTask) end)
        State.NLKillTask = nil
    end
end

local function NLKill_LookAt(fromPos, toPos)
    local d = (toPos - fromPos)
    if d.Magnitude < 0.001 then return CFrame.new(fromPos) end
    d = d.Unit
    local r = d:Cross(Vector3.new(0, 1, 0))
    if r.Magnitude < 0.001 then r = d:Cross(Vector3.new(1, 0, 0)) end
    r = r.Unit
    local u = r:Cross(d)
    return CFrame.fromMatrix(fromPos, r, u)
end

local function NLKill_Start()
    if State.NLKillActive then return end
    if not GetTargetPlayer() then
        Library:Notify({Title = "mdcp", Description = "ターゲットを選択してください", Time = 3})
        return
    end
    State.NLKillActive = true
    State.NLKillTask = task.spawn(function()
        while State.NLKillActive do
            task.wait()
            local target = GetTargetPlayer()
            if not target or not target.Character then continue end

            local char = target.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            if not (hum and hrp and head and hum.Health > 0) then continue end

            local myHrp = GetHRP()
            if not myHrp then continue end

            local savedCF = myHrp.CFrame
            pcall(function()
                myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 2)
            end)

            local gotOwner = false
            local t0 = tick()
            while State.NLKillActive and head and head.Parent and target.Parent and (tick() - t0) <= 2.5 do
                local me = GetHRP()
                hrp = char:FindFirstChild("HumanoidRootPart") or hrp
                head = char:FindFirstChild("Head") or head
                if not (me and hrp and head) then break end

                pcall(function()
                    if LocalPlayer:DistanceFromCharacter(hrp.Position) <= 35 then
                        local look = NLKill_LookAt(me.Position, hrp.Position)
                        SetNetworkOwner:FireServer(hrp, look)
                        SetNetworkOwner:FireServer(head, look)
                        SetNetworkOwner:FireServer(head, head.CFrame)
                    end
                    me.CFrame = hrp.CFrame * CFrame.new(0, 0, 2)
                end)

                local poHead = head:FindFirstChild("PartOwner")
                local poHrp = hrp:FindFirstChild("PartOwner")
                if (poHead and poHead.Value == LocalPlayer.Name)
                    or (poHrp and poHrp.Value == LocalPlayer.Name) then
                    gotOwner = true
                    break
                end
                -- velocity spike also counts as capture in some cases
                if hrp.AssemblyLinearVelocity.Magnitude > 400 then
                    gotOwner = true
                    break
                end
                task.wait()
            end

            if gotOwner and State.NLKillActive and hum and hum.Parent and hrp and hrp.Parent then
                pcall(function()
                    if hum.RigType ~= Enum.HumanoidRigType.R15 and hum.SeatPart == nil then
                        hum.RigType = Enum.HumanoidRigType.R15
                    end
                    if hum.BreakJointsOnDeath == true and hum.SeatPart == nil then
                        hum.BreakJointsOnDeath = false
                    end
                    local bsc = head and head:FindFirstChildOfClass("BallSocketConstraint")
                    if bsc then bsc.Attachment0 = nil end
                    for _, d in ipairs(char:GetDescendants()) do
                        if d:IsA("BasePart") then d.CanCollide = false end
                    end
                    local fpdh = Workspace.FallenPartsDestroyHeight
                    local killY = (fpdh <= -50000 and -49999) or (fpdh <= -100 and -99) or -100
                    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or hrp
                    if torso then
                        torso.CFrame = CFrame.new(torso.Position.X, killY, torso.Position.Z)
                        torso.AssemblyLinearVelocity = Vector3.new(0, -5000, 0)
                    end
                    hrp.CFrame = CFrame.new(hrp.Position.X, killY, hrp.Position.Z)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, -5000, 0)
                end)
                -- kill notify + return
                local tName = target.DisplayName or target.Name
                State.TargetKillStreak = (State.TargetKillLast == tName and (State.TargetKillStreak or 0) + 1) or 1
                State.TargetKillLast = tName
                if MDCP_Notify then
                    MDCP_Notify("Kill", string.format("%s をキル | 連続: %d", tName, State.TargetKillStreak), 3, "Kill")
                else
                    Library:Notify({Title = "mdcp", Description = string.format("%s をキル | 連続: %d", tName, State.TargetKillStreak), Time = 3})
                end
                local me = GetHRP()
                if me and me.Parent then
                    me.CFrame = savedCF
                    me.AssemblyLinearVelocity = Vector3.zero
                end
                task.wait(0.25)
            else
                -- fail: return home, retry next loop
                local me = GetHRP()
                if me and me.Parent then
                    me.CFrame = savedCF
                    me.AssemblyLinearVelocity = Vector3.zero
                end
                task.wait(0.15)
            end
        end
    end)
end

-- Banana
local function Banana_Destroy(b)
    if b then pcall(function() DestroyToy:FireServer(b) end) end
end
local function Banana_Spawn()
    local hrp = GetHRP(); if not hrp then return nil end
    local folder = GetSpawnedToysFolder(); if not folder then return nil end
    local spawned = nil
    local conn
    conn = folder.ChildAdded:Connect(function(c)
        if c.Name == "FoodBanana" then spawned = c conn:Disconnect() end
    end)
    task.spawn(function() pcall(function()
        SpawnRemote:InvokeServer("FoodBanana", hrp.CFrame * CFrame.new(0,14,20), Vector3.zero)
    end) end)
    local t0 = tick()
    repeat task.wait(0.05) until spawned or (tick()-t0) > 3
    if conn then pcall(function() conn:Disconnect() end) end
    return spawned
end
local function Banana_Hold(b)
    if not b then return end
    local hp = b:FindFirstChild("HoldPart"); if not hp then return end
    local hr = hp:FindFirstChild("HoldItemRemoteFunction"); if not hr then return end
    local char = LocalPlayer.Character; if not char then return end
    for _ = 1, 5 do
        if not b or not b.Parent then break end
        if pcall(function() hr:InvokeServer(b, char) end) then return true end
        task.wait(0.05)
    end
    return false
end
local function Banana_Use(b)
    if not b then return end
    local he = ReplicatedStorage:FindFirstChild("HoldEvents"); if not he then return end
    local ue = he:FindFirstChild("Use"); if not ue then return end
    pcall(function() ue:FireServer(b) end)
end
local function Banana_Drop(b)
    if not b then return end
    local hp = b:FindFirstChild("HoldPart"); if not hp then return end
    local dr = hp:FindFirstChild("DropItemRemoteFunction"); if not dr then return end
    local hrp = GetHRP(); if not hrp then return end
    local pos = hrp.CFrame * CFrame.new(0,15,0)
    pcall(function() dr:InvokeServer(b, pos, pos) end)
end
local function Banana_GetLeg()
    if not State.TargetName then return nil end
    local t = Players:FindFirstChild(State.TargetName)
    if not t or not t.Character then return nil end
    return t.Character:FindFirstChild("Left Leg")
end
local function Banana_GetHealth()
    if not State.TargetName then return 0 end
    local t = Players:FindFirstChild(State.TargetName)
    if not t or not t.Character then return 0 end
    local h = t.Character:FindFirstChildOfClass("Humanoid")
    return h and h.Health or 0
end
local function Banana_FullCycle()
    if not State.TargetName then return false end
    local b = Banana_Spawn(); if not b then return false end
    Banana_Hold(b) task.wait(0.05) Banana_Hold(b) task.wait(0.5)
    Banana_Use(b) task.wait(2.3)
    Banana_Drop(b) task.wait(0.05) Banana_Drop(b) task.wait(0.3)
    return b
end
local function Banana_StopLoop()
    State.BananaLooping = false
    if State.BananaLoopConn then State.BananaLoopConn:Disconnect() State.BananaLoopConn=nil end
    if State.BananaMonitorConn then State.BananaMonitorConn:Disconnect() State.BananaMonitorConn=nil end
    if State.BananaItem then
        Banana_Destroy(State.BananaItem)
        local hb = State.BananaItem:FindFirstChild("HitboxPart")
        if hb then
            local bp = hb:FindFirstChild("BodyPosition"); if bp then bp:Destroy() end
            local bg = hb:FindFirstChild("BodyGyro"); if bg then bg:Destroy() end
        end
        State.BananaItem = nil
    end
    task.spawn(function()
        for _ = 1, 3 do
            local folder = GetSpawnedToysFolder()
            if folder then
                for _, c in pairs(folder:GetChildren()) do
                    if c.Name == "FoodBanana" then Banana_Destroy(c) end
                end
            end
            task.wait(0.1)
        end
    end)
end
local function Banana_RestartLoop(b)
    if State.BananaLoopConn then State.BananaLoopConn:Disconnect() State.BananaLoopConn=nil end
    State.BananaItem = b
    local hb = b:FindFirstChild("HitboxPart"); if not hb then return end
    State.BananaLoopConn = RunService.Heartbeat:Connect(function()
        if not State.BananaLooping then Banana_StopLoop() return end
        if not State.BananaItem or not State.BananaItem.Parent then return end
        local folder = GetSpawnedToysFolder()
        local exists = false
        if folder then
            for _, c in pairs(folder:GetChildren()) do
                if c.Name == "FoodBanana" then exists = true State.BananaItem = c hb = c:FindFirstChild("HitboxPart") break end
            end
        end
        if not exists or not hb then
            State.BananaLoopConn:Disconnect() State.BananaLoopConn=nil State.BananaItem=nil
            return
        end
        local hrp = GetHRP(); if not hrp then return end
        local tPos, tCF
        if Banana_GetHealth() <= 0 then
            State.BananaTargetDead = true
            local p = hrp.CFrame * CFrame.new(0,7,0)
            tPos = p; tCF = CFrame.new(p.Position)
        else
            State.BananaTargetDead = false
            local leg = Banana_GetLeg()
            if leg then
                tPos = leg.CFrame * CFrame.new(0,0.5,0); tCF = leg.CFrame
            else
                local p = hrp.CFrame * CFrame.new(0,7,0)
                tPos = p; tCF = CFrame.new(p.Position)
            end
        end
        SetNetworkOwner:FireServer(hb, hb.CFrame)
        if DestroyGrabLine then DestroyGrabLine:FireServer(hb) end
        local bp = hb:FindFirstChild("BodyPosition")
        if bp then bp.Position = tPos.Position
        else
            bp = Instance.new("BodyPosition")
            bp.P=10000 bp.D=100 bp.MaxForce=Vector3.new(1e9,1e9,1e9)
            bp.Position=tPos.Position bp.Parent=hb
        end
        local bg = hb:FindFirstChild("BodyGyro")
        if bg then bg.CFrame = tCF
        else
            bg = Instance.new("BodyGyro")
            bg.P=10000 bg.D=100 bg.MaxTorque=Vector3.new(1e9,1e9,1e9)
            bg.CFrame=tCF bg.Parent=hb
        end
    end)
end
local function Banana_StartLoop()
    if State.BananaLooping and State.BananaLoopConn then return end
    State.BananaLooping = true
    State.BananaTargetDead = false
    local b = Banana_FullCycle()
    if b then Banana_RestartLoop(b) end
    State.BananaMonitorConn = RunService.Heartbeat:Connect(function()
        if not State.BananaLooping then return end
        local folder = GetSpawnedToysFolder()
        local exists = false
        if folder then
            for _, c in pairs(folder:GetChildren()) do
                if c.Name == "FoodBanana" then exists = true break end
            end
        end
        if not exists then
            if State.BananaLoopConn then State.BananaLoopConn:Disconnect() State.BananaLoopConn=nil end
            task.wait(0.05)
            local nb = Banana_FullCycle()
            if nb then Banana_RestartLoop(nb) end
        end
    end)
end

-- Blob
local function BlobKick_IsOnBlob()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not hum then return false, nil end
    local seat = hum.SeatPart
    if not seat or not seat.Parent then return false, nil end
    if seat.Parent.Name ~= "CreatureBlobman" then return false, nil end
    return true, seat.Parent
end

local function BlobKick_GetTarget()
    if not State.TargetName then return nil end
    local plr = Players:FindFirstChild(State.TargetName)
    if not plr or not plr.Character then return nil end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    local hum = plr.Character:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end
    return plr.Character, hrp, hum
end

local function BlobKick_Loop()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not hum then
        State.BlobKickActive = false
        return
    end
    State.BlobKickSavedPos = hrp.CFrame
    local dragging = false
    local grabStart = 0

    while State.BlobKickActive do
        local ok, blob = BlobKick_IsOnBlob()
        if not ok or not blob then task.wait(0.2) continue end

        char = LocalPlayer.Character
        hum  = char and char:FindFirstChild("Humanoid")
        hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp or not hum then task.wait(0.1) continue end

        local tChar, tRoot, tHum = BlobKick_GetTarget()
        if tChar and tRoot and tHum then
            pcall(function() SetNetworkOwner:FireServer(tRoot, tRoot.CFrame) end)
            if DestroyGrabLine then pcall(function() DestroyGrabLine:FireServer(tRoot) end) end

            pcall(function()
                tHum.PlatformStand = true
                tHum.Sit = true
            end)
            tRoot.AssemblyLinearVelocity = Vector3.zero
            tRoot.AssemblyAngularVelocity = Vector3.zero

            local blobRoot = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
            local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
            local CG = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
            local CD = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
            local R_Det = blob:FindFirstChild("RightDetector")
            local weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld"))

            if not dragging then
                if blobRoot then
                    blobRoot.CFrame = tRoot.CFrame
                    blobRoot.AssemblyLinearVelocity = Vector3.zero
                end
                if CG and CD and R_Det and weld then
                    pcall(function()
                        CD:FireServer(weld)
                        CG:FireServer(R_Det, tRoot, weld)
                    end)
                end
                if grabStart == 0 then grabStart = tick() end
                if tick() - grabStart > 0.35 then
                    dragging = true
                    grabStart = 0
                end
            else
                local lockCF = State.BlobKickSavedPos * CFrame.new(0, 23, 0)
                tRoot.CFrame = lockCF
                tRoot.AssemblyLinearVelocity = Vector3.zero
                if blobRoot then
                    blobRoot.CFrame = State.BlobKickSavedPos
                    blobRoot.AssemblyLinearVelocity = Vector3.zero
                end
                pcall(function() SetNetworkOwner:FireServer(tRoot, lockCF) end)
                if DestroyGrabLine then pcall(function() DestroyGrabLine:FireServer(tRoot) end) end
                if CG and CD and R_Det and weld then
                    pcall(function()
                        CD:FireServer(weld)
                        CG:FireServer(R_Det, tRoot, weld)
                    end)
                end
            end
        else
            dragging = false
            grabStart = 0
        end
        RunService.Heartbeat:Wait()
    end
end

local function Blob_ZeroVel(part)
    if part then
        pcall(function()
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

local function Blob_HasNetworkOwner(part)
    if not part then return false end
    local ok, owned = pcall(function()
        if typeof(isnetworkowner) == "function" then
            return isnetworkowner(part)
        end
        return false
    end)
    if ok and owned then return true end
    local po = part:FindFirstChild("PartOwner")
    return po and po:IsA("StringValue") and po.Value == LocalPlayer.Name
end

local function Blob_DestroyAllBlobs()
    local folder = GetSpawnedToysFolder()
    if not folder then return end
    for _, child in pairs(folder:GetChildren()) do
        if child.Name == "CreatureBlobman" then
            pcall(function() DestroyToy:FireServer(child) end)
        end
    end
    task.wait(0.1)
end

local function Blob_SpawnAndSit(myHrp, myHum)
    if not myHrp or not myHum then return nil end
    -- 既存ブロブがあればそれを使う
    local folder = GetSpawnedToysFolder()
    local existing = folder and folder:FindFirstChild("CreatureBlobman")
    local spawned = existing

    if not spawned then
        Blob_DestroyAllBlobs()
        folder = GetSpawnedToysFolder()
        if not folder then return nil end
        local conn
        conn = folder.ChildAdded:Connect(function(c)
            if c.Name == "CreatureBlobman" then spawned = c; conn:Disconnect() end
        end)
        pcall(function()
            SpawnRemote:InvokeServer("CreatureBlobman", myHrp.CFrame * CFrame.new(0, 4, 2), Vector3.zero)
        end)
        local t0 = tick()
        repeat task.wait(0.05) until spawned or (tick() - t0) > 4
        if conn then pcall(function() conn:Disconnect() end) end
    end
    if not spawned or not spawned.Parent then return nil end

    local seat = spawned:FindFirstChild("VehicleSeat") or spawned:WaitForChild("VehicleSeat", 4)
    if not seat then return spawned end

    -- 確実に乗る: 席の近くにTP → Sit 連打
    for attempt = 1, 25 do
        if not myHum or not myHum.Parent then
            local char = LocalPlayer.Character
            myHum = char and char:FindFirstChildOfClass("Humanoid")
            myHrp = char and char:FindFirstChild("HumanoidRootPart")
            if not myHum or not myHrp then break end
        end
        pcall(function()
            myHum.Sit = false
            myHrp.CFrame = seat.CFrame * CFrame.new(0, 2.5, 0)
            myHrp.AssemblyLinearVelocity = Vector3.zero
            seat:Sit(myHum)
        end)
        task.wait(0.08)
        if myHum.Sit and myHum.SeatPart == seat then
            return spawned
        end
        -- たまに再Sit
        pcall(function() seat:Sit(myHum) end)
        task.wait(0.05)
        if myHum.Sit and myHum.SeatPart == seat then
            return spawned
        end
    end
    return spawned
end

local function Blob_EnsureSitting()
    local ok, blob = BlobKick_IsOnBlob()
    if ok and blob then return blob end
    local myHrp = GetHRP()
    local char = LocalPlayer.Character
    local myHum = char and char:FindFirstChildOfClass("Humanoid")
    if not myHrp or not myHum then return nil end

    local result = Blob_SpawnAndSit(myHrp, myHum)
    -- まだ乗れていなければもう一度
    ok, blob = BlobKick_IsOnBlob()
    if ok and blob then return blob end

    if result then
        local seat = result:FindFirstChild("VehicleSeat")
        if seat then
            for _ = 1, 15 do
                pcall(function()
                    myHrp.CFrame = seat.CFrame * CFrame.new(0, 2.5, 0)
                    seat:Sit(myHum)
                end)
                task.wait(0.1)
                ok, blob = BlobKick_IsOnBlob()
                if ok and blob then return blob end
            end
        end
    end
    return result
end

local function BlobKick_Start()
    if State.BlobKickActive then return end
    State.BlobKickActive = true
    task.spawn(function()
        Blob_EnsureSitting()
    end)
    State.BlobKickTask = task.spawn(BlobKick_Loop)
end
local function BlobKick_Stop()
    State.BlobKickActive = false
    if State.BlobKickTask then pcall(function() task.cancel(State.BlobKickTask) end) State.BlobKickTask=nil end
    State.BlobKickSavedPos = nil
end

local function BlobKill_Notify(targetName)
    if State.BlobKillLastTarget ~= targetName then
        State.BlobKillStreak = 1
        State.BlobKillLastTarget = targetName
    else
        State.BlobKillStreak = (State.BlobKillStreak or 0) + 1
    end
    local streak = State.BlobKillStreak
    if MDCP_Notify then
        MDCP_Notify("Kill", string.format("%s をキル | 連続: %d", targetName, streak), 3, "Kill")
    else
        Library:Notify({
            Title = "mdcp",
            Description = string.format("%s をキル\n連続: %d", targetName, streak),
            Time = 3,
        })
    end
end

local function BlobKill_Loop()
    while State.BlobKillActive do
        task.wait(0.1)
        local myChar = LocalPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myHrp or not myHum or myHum.Health <= 0 then continue end

        local target = GetTargetPlayer()
        if not target or not target.Character then continue end
        local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
        local tHum = target.Character:FindFirstChildOfClass("Humanoid")
        if not tRoot or not tHum or tHum.Health <= 0 then continue end
        if tRoot.Position.Magnitude < 5 or tRoot.AssemblyLinearVelocity.Magnitude > 500 then continue end

        local savedCF = myHrp.CFrame
        local blob = Blob_EnsureSitting()
        if not blob then continue end

        myChar = LocalPlayer.Character
        myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local seat = blob:FindFirstChild("VehicleSeat")
        if not myHum or not seat or not myHum.Sit or myHum.SeatPart ~= seat then
            continue
        end

        local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
        local CG = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
        local CR = scriptObj and scriptObj:FindFirstChild("CreatureRelease")
        local R_Det = blob:FindFirstChild("RightDetector")
        local weld = R_Det and R_Det:FindFirstChild("RightWeld")
        local blobRoot = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
        if not (CG and CR and weld and blobRoot) then continue end

        local t0 = tick()
        while State.BlobKillActive and tHum.Health > 0 and myHum.Sit and myHum.SeatPart == seat
            and not Blob_HasNetworkOwner(tRoot) and (tick() - t0) <= 3.5 do
            if tRoot and tRoot.Parent then
                blobRoot.CFrame = tRoot.CFrame * CFrame.new(0, -18, 0)
                Blob_ZeroVel(blobRoot)
            end
            pcall(function()
                CG:FireServer(nil, tRoot, weld)
                CR:FireServer(weld)
            end)
            task.wait(0.03)
        end

        if State.BlobKillActive and myHum.Sit and myHum.SeatPart == seat
            and Blob_HasNetworkOwner(tRoot) and tHum.Health > 0 then
            local t1 = tick()
            while State.BlobKillActive and tHum.Health > 0 and (tick() - t1) < 3 do
                pcall(function()
                    tHum:ChangeState(Enum.HumanoidStateType.Dead)
                    tRoot.CFrame = CFrame.new(0, -500, 0)
                    CR:FireServer(weld)
                end)
                Blob_ZeroVel(myHrp)
                Blob_ZeroVel(blobRoot)
                task.wait(0.05)
            end
        end

        local killed = (not tHum.Parent) or (tHum.Health <= 0)
        -- 成功でも失敗でも元の場所へ戻す
        pcall(function()
            if blobRoot and blobRoot.Parent then
                blobRoot.CFrame = savedCF
                Blob_ZeroVel(blobRoot)
            end
            local me = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if me then
                me.CFrame = savedCF
                Blob_ZeroVel(me)
            end
            if myHum then myHum.Sit = false end
        end)
        task.wait(0.08)
        Blob_DestroyAllBlobs()

        if killed then
            BlobKill_Notify(target.DisplayName or target.Name)
            task.wait(0.35) -- リスポーン待ち後に再キル
        else
            -- キル失敗: 戻ってすぐ再試行
            task.wait(0.2)
        end
    end
end

local function BlobKill_Start()
    if State.BlobKillActive then return end
    if not GetTargetPlayer() then
        Library:Notify({Title = "mdcp", Description = "ターゲットを選択してください", Time = 3})
        return
    end
    State.BlobKillActive = true
    State.BlobKillTask = task.spawn(BlobKill_Loop)
end
local function BlobKill_Stop()
    State.BlobKillActive = false
    if State.BlobKillTask then pcall(function() task.cancel(State.BlobKillTask) end) State.BlobKillTask=nil end
end

local AutoSit_Active = false
local function AutoSit_Start()
    AutoSit_Active = true
    State.AutoSitBlobActive = true
    task.spawn(function()
        while AutoSit_Active do
            Blob_EnsureSitting()
            task.wait(0.5)
        end
    end)
end
local function AutoSit_Stop()
    AutoSit_Active = false
    State.AutoSitBlobActive = false
end


-- ============================================================
-- NoBlob Kick All (完全移植)
-- ============================================================
local function NB_IsFriend(player)
    if not player then return false end
    local cached = State.NoblobFriendCache[player.UserId]
    if cached ~= nil then return cached end
    for _ = 1, 3 do
        local ok, result = pcall(function()
            return LocalPlayer:IsFriendsWith(player.UserId)
        end)
        if ok then
            State.NoblobFriendCache[player.UserId] = (result == true)
            return result == true
        end
        task.wait(0.2)
    end
    return true
end

local function NB_IsWhitelisted(player)
    if not player then return false end
    return State.NoblobWhitelistFriends and NB_IsFriend(player)
end

local function NB_GetAllPlayersIncludingInPlot()
    local allPlayers = {}
    local seen = {}
    local plotItems = Workspace:FindFirstChild("PlotItems")
    local playersInPlots = plotItems and plotItems:FindFirstChild("PlayersInPlots")

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not NB_IsWhitelisted(player) and not seen[player.Name] then
            seen[player.Name] = true
            table.insert(allPlayers, player)
        end
    end

    if playersInPlots then
        for _, playerObj in ipairs(playersInPlots:GetChildren()) do
            if playerObj:IsA("Folder") or playerObj:IsA("Model") then
                local playerName = playerObj.Name
                local player = Players:FindFirstChild(playerName)
                if player and player ~= LocalPlayer and not NB_IsWhitelisted(player) and not seen[playerName] then
                    seen[playerName] = true
                    table.insert(allPlayers, player)
                end
            end
        end
    end
    return allPlayers
end

local function NB_GetPlayerHRP(player)
    if not player then return nil end
    local char = player.Character
    if char and char.Parent == Workspace then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Parent then return hrp end
    end
    local plotItems = Workspace:FindFirstChild("PlotItems")
    if plotItems then
        for _, plot in ipairs(plotItems:GetChildren()) do
            if plot:IsA("Folder") then
                local playersInPlot = plot:FindFirstChild("PlayersInPlots")
                if playersInPlot and playersInPlot:FindFirstChild(player.Name) then
                    for _, child in ipairs(plot:GetDescendants()) do
                        if child:IsA("Model") and child.Name == player.Name then
                            local hrp = child:FindFirstChild("HumanoidRootPart")
                            if hrp and hrp.Parent then return hrp end
                        end
                    end
                end
            end
        end
    end
    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and model.Name == player.Name then
            local hrp = model:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Parent then return hrp end
        end
    end
    return nil
end

local function NB_SpamOwnership(hrp)
    if SetNetworkOwner and hrp then
        pcall(function() SetNetworkOwner:FireServer(hrp, hrp.CFrame) end)
    end
end

local function NB_TeleportToPlayer(myHrp, targetHrp)
    if not myHrp or not targetHrp then return end
    pcall(function()
        myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 5, 5)
        myHrp.AssemblyLinearVelocity = Vector3.zero
    end)
end

local function NB_DestroyLineOnPlayer(hrp)
    if not CreateGrabLine or not DestroyGrabLine then return end
    pcall(function()
        CreateGrabLine:FireServer(hrp, CFrame.new(0, 1e9, 0))
        task.wait()
        DestroyGrabLine:FireServer(hrp)
    end)
end

local function NB_StartLagSpam(mode)
    if State.NoblobLagConn then
        State.NoblobLagConn:Disconnect()
        State.NoblobLagConn = nil
    end
    local targetRate = (mode == "high") and 520 or 220
    local frameRate  = 60
    local basePerFrame = math.floor(targetRate / frameRate)
    local remainder    = targetRate - (basePerFrame * frameRate)
    local frameCounter = 0
    local burstPerSend = (mode == "high") and 3 or 2

    State.NoblobLagConn = RunService.Heartbeat:Connect(function()
        frameCounter = frameCounter + 1
        local sendCount = basePerFrame
        if frameCounter <= remainder then
            sendCount = sendCount + 1
        end
        local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
            or Workspace:FindFirstChild("Spawn")
            or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
        if spawnLocation then
            for i = 1, sendCount do
                for b = 1, burstPerSend do
                    pcall(function()
                        local randomX = math.random(-2010000000, 2000000001)
                        local randomZ = math.random(-2008100000, 2000200000)
                        CreateGrabLine:FireServer(spawnLocation, CFrame.new(randomX, 0, randomZ))
                    end)
                end
            end
        end
    end)
    State.NoblobLagMode = mode
end

local function NB_StopLagSpam()
    if State.NoblobLagConn then
        State.NoblobLagConn:Disconnect()
        State.NoblobLagConn = nil
    end
end

local function NB_TeleportToCenter(hrp, centerPosition, height)
    if not hrp then return end
    pcall(function()
        hrp.CFrame = CFrame.new(centerPosition.X, height, centerPosition.Z)
        hrp.AssemblyLinearVelocity = Vector3.zero
    end)
end

local KICK_HEIGHT        = 0
local KICK_RADIUS        = 20
local KICK_TILT_DEGREES  = 48
local SMOOTH_TIME        = 0.6

local function NB_BuildCirclePositions(count, center, radius, height)
    local positions = {}
    if count <= 0 then return positions end
    local step = (2 * math.pi) / count
    for i = 0, count - 1 do
        local angle = i * step + math.rad(i * 1.5)
        positions[i + 1] = Vector3.new(
            center.X + math.cos(angle) * radius,
            height,
            center.Z + math.sin(angle) * radius
        )
    end
    return positions
end

local function NB_Execute()
    if State.NoblobRunning then return end
    State.NoblobRunning = true

    State.NoblobTask = task.spawn(function()
        NB_StartLagSpam("low")
        local height = 4
        task.wait(1)

        local players = NB_GetAllPlayersIncludingInPlot()
        if #players == 0 then
            Library:Notify({Title = "NoBlob", Description = "No targets", Time = 3})
            task.wait(10)
            NB_StopLagSpam()
            State.NoblobRunning = false
            return
        end

        local myChar = LocalPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then
            task.wait(10)
            NB_StopLagSpam()
            State.NoblobRunning = false
            return
        end

        local playerData = {}
        for _, plr in ipairs(players) do
            local hrp = NB_GetPlayerHRP(plr)
            if hrp then
                table.insert(playerData, { player = plr, hrp = hrp })
            end
        end

        if #playerData == 0 then
            Library:Notify({Title = "NoBlob", Description = "No targets", Time = 3})
            task.wait(10)
            NB_StopLagSpam()
            State.NoblobRunning = false
            return
        end

        local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
            or Workspace:FindFirstChild("Spawn")
            or Workspace:FindFirstChild("SpawnLocation1")

        local centerX = spawnLocation and spawnLocation.Position.X or 0
        local centerZ = spawnLocation and spawnLocation.Position.Z or 0
        local centerPosition = Vector3.new(centerX, height, centerZ)

        NB_TeleportToCenter(myHrp, centerPosition, height)

        for _, data in ipairs(playerData) do
            NB_TeleportToPlayer(myHrp, data.hrp)
            task.wait(0.2)
            NB_SpamOwnership(data.hrp)
            task.wait()
        end

        local placeCenter = Vector3.new(0, KICK_HEIGHT, 0)
        local placeTilt = math.rad(KICK_TILT_DEGREES)
        local placePositions = NB_BuildCirclePositions(#playerData, placeCenter, KICK_RADIUS, KICK_HEIGHT)
        local placeCFrames = {}
        for idx, pos in ipairs(placePositions) do
            placeCFrames[idx] = CFrame.lookAt(pos, placeCenter) * CFrame.Angles(-placeTilt, 0, 0)
        end

        local placing = {}
        for idx, data in ipairs(playerData) do
            local hum = data.hrp.Parent and data.hrp.Parent:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    hum.PlatformStand = true
                    hum.AutoRotate = false
                    hum.WalkSpeed = 0
                    hum.JumpPower = 0
                end)
            end
            NB_SpamOwnership(data.hrp)
            local startCF = data.hrp.CFrame
            local bp = Instance.new("BodyPosition")
            bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bp.P = 1e12
            bp.D = 1e7
            bp.Position = startCF.Position
            bp.Parent = data.hrp
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.P = 15000
            bg.D = 500
            bg.CFrame = startCF.Rotation
            bg.Parent = data.hrp
            table.insert(placing, {
                hrp = data.hrp, bp = bp, bg = bg,
                startCF = startCF, goalCF = placeCFrames[idx], goalPos = placePositions[idx],
            })
        end

        local startTime = os.clock()
        local alpha = 0
        while alpha < 1 do
            RunService.Heartbeat:Wait()
            alpha = math.clamp((os.clock() - startTime) / SMOOTH_TIME, 0, 1)
            local eased = alpha * alpha * (3 - 2 * alpha)
            for _, item in ipairs(placing) do
                if item.hrp and item.hrp.Parent then
                    local cf = item.startCF:Lerp(item.goalCF, eased)
                    pcall(function()
                        item.hrp.CFrame = cf
                        item.hrp.AssemblyLinearVelocity = Vector3.zero
                        item.hrp.AssemblyAngularVelocity = Vector3.zero
                        item.bp.Position = cf.Position
                        item.bg.CFrame = cf
                    end)
                end
            end
        end

        for _, item in ipairs(placing) do
            local hrp, bp, bg, goalCF, goalPos = item.hrp, item.bp, item.bg, item.goalCF, item.goalPos
            pcall(function()
                hrp.CFrame = goalCF
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                bp.Position = goalPos
                bg.CFrame = goalCF
            end)
            task.spawn(function()
                local endTime = tick() + 6
                while tick() < endTime do
                    if not bp.Parent then break end
                    if not hrp.Parent then break end
                    pcall(function()
                        hrp.CFrame = goalCF
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end)
                    task.wait(0.03)
                end
            end)
            task.delay(6, function()
                pcall(function() bp:Destroy() end)
                pcall(function() bg:Destroy() end)
            end)
        end

        task.wait(0.1)
        for idx, data in ipairs(playerData) do
            pcall(function()
                data.hrp.CFrame = placeCFrames[idx]
                data.hrp.AssemblyLinearVelocity = Vector3.zero
                data.hrp.AssemblyAngularVelocity = Vector3.zero
            end)
            NB_SpamOwnership(data.hrp)
        end

        NB_StartLagSpam("high")
        task.wait(0.1)
        NB_TeleportToCenter(myHrp, centerPosition, height)

        for i = 1, 8 do
            for _, data in ipairs(playerData) do
                NB_DestroyLineOnPlayer(data.hrp)
            end
            task.wait(0.3)
        end

        task.wait(11)
        NB_StopLagSpam()
        State.NoblobRunning = false
        Library:Notify({Title = "NoBlob", Description = "Done", Time = 3})
    end)
end

local function NB_Stop()
    State.NoblobRunning = false
    if State.NoblobTask then
        pcall(function() task.cancel(State.NoblobTask) end)
        State.NoblobTask = nil
    end
    NB_StopLagSpam()
end

-- ============================================================
-- BREAK
-- ============================================================
local BreakState = {
    SelectedPlots = {},
    PlotActive = false,
    PlotShurikens = {},
    GroundActive = false,
    GroundShurikens = {},
}

local function Break_GetLocalRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function Break_GetContainer(plr)
    plr = plr or LocalPlayer
    local playersInPlots = Workspace:FindFirstChild("PlotItems")
        and Workspace.PlotItems:FindFirstChild("PlayersInPlots")
    if playersInPlots and playersInPlots:FindFirstChild(plr.Name) then
        local plots = Workspace:FindFirstChild("Plots")
        if plots then
            for _, p in ipairs(plots:GetChildren()) do
                local sign = p:FindFirstChild("PlotSign")
                local owners = sign and sign:FindFirstChild("ThisPlotsOwners")
                if owners then
                    for _, v in ipairs(owners:GetChildren()) do
                        if v.Value == plr.Name then
                            local items = Workspace:FindFirstChild("PlotItems")
                            local folder = items and items:FindFirstChild(p.Name)
                            if folder then return folder end
                        end
                    end
                end
            end
        end
    end
    return Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
end

local function Break_SpawnAndStick(targetPart, container)
    if not targetPart or not container then return nil end
    local hrp = Break_GetLocalRoot()
    if not hrp then return nil end
    local canSpawn = LocalPlayer:FindFirstChild("CanSpawnToy")
    if canSpawn and not canSpawn.Value then
        local w = 0
        while not canSpawn.Value and w < 30 do task.wait(0.1); w = w + 1 end
    end
    local existing = {}
    for _, c in ipairs(container:GetChildren()) do
        if c.Name == "NinjaShuriken" then existing[c] = true end
    end
    task.spawn(function()
        pcall(function()
            SpawnRemote:InvokeServer("NinjaShuriken", hrp.CFrame * CFrame.new(0, 2, 8), Vector3.zero)
        end)
    end)
    local newSh = nil
    local t0 = tick()
    repeat
        task.wait(0.05)
        for _, c in ipairs(container:GetChildren()) do
            if c.Name == "NinjaShuriken" and not existing[c] then
                newSh = c
                break
            end
        end
    until newSh or (tick() - t0) > 2
    if not newSh then return nil end
    local sp = newSh:FindFirstChild("SoundPart") or newSh:WaitForChild("SoundPart", 0.5)
    if sp then
        pcall(function() SetNetworkOwner:FireServer(sp, sp.CFrame) end)
        task.wait(0.05)
    end
    local sticky = newSh:FindFirstChild("StickyPart")
    if sticky and StickyPartEvent then
        pcall(function()
            StickyPartEvent:FireServer(sticky, targetPart,
                CFrame.new(9.99999996e+11, 9.99999996e+11, 9.99999996e+11, 1, 0, 0, 0, 1, 0, 0, 0, 1))
        end)
    end
    return newSh
end

local function Break_DestroyShuriken(sh)
    if sh and sh.Parent then pcall(function() DestroyToy:FireServer(sh) end) end
end

local function Break_CleanupPlot()
    for _, sh in ipairs(BreakState.PlotShurikens) do Break_DestroyShuriken(sh) end
    BreakState.PlotShurikens = {}
    task.spawn(function()
        local inv = GetSpawnedToysFolder()
        if inv then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name == "NinjaShuriken" or v.Name == "Noclipped" then
                    pcall(function() DestroyToy:FireServer(v) end)
                end
            end
        end
    end)
end

local function Break_PlotLoop()
    while BreakState.PlotActive do
        local validPlots = {}
        for _, name in ipairs(BreakState.SelectedPlots) do
            local plots = Workspace:FindFirstChild("Plots")
            local p = plots and plots:FindFirstChild(name)
            local area = p and p:FindFirstChild("PlotArea")
            if area then table.insert(validPlots, { Name = name, Area = area }) end
        end
        if #validPlots > 0 then
            local container = Break_GetContainer(LocalPlayer)
            if container then
                local alive = {}
                for _, sh in ipairs(BreakState.PlotShurikens) do
                    if sh and sh.Parent then table.insert(alive, sh) end
                end
                BreakState.PlotShurikens = alive
                local needed = #validPlots - #BreakState.PlotShurikens
                for i = 1, needed do
                    if not BreakState.PlotActive then break end
                    local tgt = validPlots[#BreakState.PlotShurikens + 1]
                    if not tgt then break end
                    local newSh = Break_SpawnAndStick(tgt.Area, container)
                    if newSh then table.insert(BreakState.PlotShurikens, newSh) end
                    task.wait(0.05)
                end
            end
        end
        task.wait(0.5)
    end
    Break_CleanupPlot()
end

local function Break_PlotStart()
    if BreakState.PlotActive then return end
    BreakState.PlotActive = true
    task.spawn(Break_PlotLoop)
end
local function Break_PlotStop()
    BreakState.PlotActive = false
    Break_CleanupPlot()
end

local function Break_CleanupGround()
    for _, sh in ipairs(BreakState.GroundShurikens) do Break_DestroyShuriken(sh) end
    BreakState.GroundShurikens = {}
    task.spawn(function()
        for _ = 1, 3 do
            local inv = GetSpawnedToysFolder()
            if inv then
                for _, v in pairs(inv:GetChildren()) do
                    if v.Name == "NinjaShuriken" or v.Name == "Noclipped" then
                        pcall(function() DestroyToy:FireServer(v) end)
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

local function Break_GroundLoop()
    while BreakState.GroundActive do
        local hrp = Break_GetLocalRoot()
        if hrp then
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = { LocalPlayer.Character }
            params.FilterType = Enum.RaycastFilterType.Exclude
            local result = Workspace:Raycast(hrp.Position, Vector3.new(0, -10, 0), params)
            local target = result and result.Instance
            if target and target:IsA("BasePart") and not target:IsA("Terrain") then
                local container = Break_GetContainer(LocalPlayer)
                if container then
                    local newSh = Break_SpawnAndStick(target, container)
                    if newSh then table.insert(BreakState.GroundShurikens, newSh) end
                end
            end
        end
        task.wait(0.8)
    end
    Break_CleanupGround()
end

local function Break_GroundStart()
    if BreakState.GroundActive then return end
    BreakState.GroundActive = true
    task.spawn(Break_GroundLoop)
end
local function Break_GroundStop()
    BreakState.GroundActive = false
    Break_CleanupGround()
end

local PB_Running = false
local PB_Task = nil
local function PB_getHRP()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart
    else
        local c = LocalPlayer.CharacterAdded:Wait()
        return c:WaitForChild("HumanoidRootPart")
    end
end
local function PB_Cleanup()
    PB_Running = false
    if PB_Task then pcall(function() task.cancel(PB_Task) end) PB_Task = nil end
    task.spawn(function()
        for _ = 1, 3 do
            local inv = GetSpawnedToysFolder()
            if inv then
                for _, v in pairs(inv:GetChildren()) do
                    if v.Name == "NinjaShuriken" or v.Name == "Noclipped" then
                        pcall(function() DestroyToy:FireServer(v) end)
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end
local function PB_BreakAll()
    if PB_Running then return end
    local inv = GetSpawnedToysFolder()
    if not inv then
        Library:Notify({Title = "Plot Breaker", Description = "SpawnedInToys が見つかりません", Time = 3})
        return
    end
    local currentHRP = PB_getHRP()
    if not currentHRP then return end
    PB_Running = true
    PB_Task = task.spawn(function()
        for i = 1, 5 do
            if not PB_Running then break end
            local shur = nil
            local conn
            conn = inv.ChildAdded:Connect(function(child)
                if child.Name == "NinjaShuriken" then shur = child conn:Disconnect() end
            end)
            pcall(function()
                SpawnRemote:InvokeServer("NinjaShuriken", currentHRP.CFrame * CFrame.new(5, 8, 20), Vector3.new(0,0,0))
            end)
            local startTime = tick()
            repeat
                if shur and shur:FindFirstChild("StickyPart") and shur:FindFirstChild("SoundPart") then break end
                task.wait(0.01)
            until tick() - startTime > 0.5
            shur = shur or inv:FindFirstChild("NinjaShuriken")
            if shur then
                local soundPart = shur:FindFirstChild("SoundPart")
                local stickyPart = shur:FindFirstChild("StickyPart")
                if soundPart and stickyPart then
                    for _ = 1, 15 do
                        pcall(function() SetNetworkOwner:FireServer(soundPart, soundPart.CFrame) end)
                        if soundPart:FindFirstChild("PartOwner") and soundPart.PartOwner.Value == LocalPlayer.Name then break end
                    end
                    for _, obj in pairs(shur:GetChildren()) do
                        if obj:IsA("BasePart") then
                            obj.CanTouch = false
                            obj.CanCollide = false
                            obj.Transparency = 1
                        end
                    end
                    shur.Name = "Noclipped"
                    local plots = Workspace:FindFirstChild("Plots")
                    local plot = plots and plots:FindFirstChild("Plot" .. i)
                    if plot then
                        local plotArea = plot:FindFirstChild("PlotArea")
                        if plotArea and StickyPartEvent then
                            pcall(function()
                                StickyPartEvent:FireServer(stickyPart, plotArea, CFrame.new(1e12, 1e12, 1e12))
                            end)
                        end
                    end
                end
            end
            task.wait(0.1)
        end
        PB_Running = false
        PB_Task = nil
    end)
end


-- ============================================================
-- Fun / Dance
-- ============================================================
Fun = {}
Fun.Players = game:GetService("Players")
Fun.RunService = game:GetService("RunService")
Fun.ReplicatedStorage = game:GetService("ReplicatedStorage")
Fun.TweenService = game:GetService("TweenService")
Fun.UserInputService = game:GetService("UserInputService")
Fun.me = Fun.Players.LocalPlayer
Fun.camera = workspace.CurrentCamera
Fun.CharacterEvents = Fun.ReplicatedStorage:WaitForChild("CharacterEvents")
Fun.RagdollRemote = Fun.CharacterEvents:WaitForChild("RagdollRemote")
Fun.poseConnection = nil
Fun.activeMode = "off"
Fun.selectedDance = "Floss Dance"

Fun.danceNames = {
	"Floss Dance",
	"Ouen Dance",
	"Head Ball",
	"Cartoon",
	"Kawaii",
	"Cool",
	"Spider",
	"Robot Lock",
	"Disco Point",
	"Wave Ripple",
	"Jazz Hands",
	"Headbang",
	"Shoulder Shimmy",
	"Boxer Bounce",
	"Salsa Hip",
	"Cheer Jump",
	"Propeller Arms",
	"Matrix Lean",
	"Victory Pump",
	"Ninja Flow",
	"Superhero Pose",
	"Snake Wave",
	"Staircase Step",
	"Windmill Arms",
	"Popcorn Pop",
	"Clap Along",
	"Zombie Shuffle",
	"Koshi huri",
	"Head dribble",
	"Angry",
	"soccer",
	"Head orbit",
	"Lol",
}

Fun.stopPose = function()
	if Fun.poseConnection then
		Fun.poseConnection:Disconnect()
		Fun.poseConnection = nil
	end

	Fun.activeMode = "off"
end

Fun.startRagdollOnly = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	Fun.RagdollRemote:FireServer(rootPart, 9999999)

	offsets = {
		Torso = CFrame.new(0, 0, 0),
		Head = CFrame.new(0, 1.5, 0),
		["Left Arm"] = CFrame.new(-1.5, 0, 0),
		["Right Arm"] = CFrame.new(1.5, 0, 0),
		["Left Leg"] = CFrame.new(-0.5, -2, 0),
		["Right Leg"] = CFrame.new(0.5, -2, 0),
	}

	Fun.activeMode = "ragdoll"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function()
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		targetCFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, yawAngle, 0)

		for k, v4 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") then
				part.CFrame = targetCFrame * v4
				part.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity
			end
		end
	end)
end

Fun.startFlossDance = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	humanoid = arg:WaitForChild("Humanoid")
	Fun.RagdollRemote:FireServer(rootPart, 9999999)
	movePosition = rootPart.Position
	walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	teleportThreshold = 8
	Fun.activeMode = "dance"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		t = tick()
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		actualPosition = rootPart.Position

		if (actualPosition - movePosition).Magnitude > teleportThreshold then
			movePosition = actualPosition
		end

		moveDir = humanoid.MoveDirection

		if moveDir.Magnitude > 0.01 then
			movePosition = movePosition + moveDir * walkSpeed * deltaTime
		end

		targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
		rootPart.CFrame = targetCFrame
		speed = 10
		phase = t * speed
		armSideAmp = 0.95993108859688125
		armSideAngle = armSideAmp * math.sin(phase)
		crossAmp = 0.9
		leftArmZ = crossAmp * math.cos(phase)
		rightArmZ = -crossAmp * math.cos(phase)
		hipAmp = 0.3490658503988659
		hipTwist = -hipAmp * math.sin(phase)
		torsoTwistAmp = 0.24434609527920614
		torsoTwist = -torsoTwistAmp * math.sin(phase)
		kneeBounceAmp = 0.12
		kneeBounce = kneeBounceAmp * math.abs(math.sin(phase * 2))
		legSpread = 100
		armHalfHeight = 1

		offsets = {
			Torso = CFrame.new(0, -kneeBounce, 0) * CFrame.Angles(0, torsoTwist, 0),
			Head = CFrame.new(0, 1.5 - kneeBounce, 0),
			["Left Arm"] = CFrame.new(-1.5, 1 - kneeBounce, leftArmZ) * CFrame.Angles(0, 0, armSideAngle) * CFrame.new(0, -armHalfHeight, 0),
			["Right Arm"] = CFrame.new(1.5, 1 - kneeBounce, rightArmZ) * CFrame.Angles(0, 0, armSideAngle) * CFrame.new(0, -armHalfHeight, 0),
			["Left Leg"] = CFrame.new(-legSpread, -2 + kneeBounce * 0.5, 0) * CFrame.Angles(0, hipTwist * 0.4, 0),
			["Right Leg"] = CFrame.new(legSpread, -2 + kneeBounce * 0.5, 0) * CFrame.Angles(0, hipTwist * 0.4, 0),
		}

		for k, v4 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") then
				part.CFrame = targetCFrame * v4
				part.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

Fun.startOrangeJustice = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	humanoid = arg:WaitForChild("Humanoid")
	Fun.RagdollRemote:FireServer(rootPart, 9999999)
	movePosition = rootPart.Position
	walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	teleportThreshold = 8
	Fun.activeMode = "dance"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		t = tick()
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		actualPosition = rootPart.Position

		if teleportThreshold < (actualPosition - movePosition).Magnitude then
			movePosition = actualPosition
		end

		moveDir = humanoid.MoveDirection

		if moveDir.Magnitude > 0.01 then
			movePosition = movePosition + moveDir * walkSpeed * deltaTime
		end

		targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
		rootPart.CFrame = targetCFrame
		speed = 8
		phase = t * speed
		armAngle = 0.78539816339744828 * math.sin(phase * 2)
		armUp = math.sin(phase * 2) * 1.5
		legLift = math.sin(phase) * 0.8
		jumpBounce = math.abs(math.sin(phase * 2)) * 0.3

		offsets = {
			Torso = CFrame.new(0, jumpBounce, 0),
			Head = CFrame.new(0, 1.5, 0),
			["Left Arm"] = CFrame.new(-1.5, 1 + armUp, 0) * CFrame.Angles(armAngle, 0, 0),
			["Right Arm"] = CFrame.new(1.5, 1 - armUp, 0) * CFrame.Angles(-armAngle, 0, 0),
			["Left Leg"] = CFrame.new(-0.5, -2 + legLift, 0),
			["Right Leg"] = CFrame.new(0.5, -2 - legLift, 0),
		}

		for k, v4 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") then
				part.CFrame = targetCFrame * v4
				part.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

Fun.isThrowing = false
Fun.throwProgress = 0
Fun.headStartPos = nil

Fun.startHeadThrow = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	humanoid = arg:WaitForChild("Humanoid")
	head = arg:FindFirstChild("Head")
	Fun.RagdollRemote:FireServer(rootPart, 9999999)
	movePosition = rootPart.Position
	walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	teleportThreshold = 8
	Fun.isThrowing = false
	Fun.throwProgress = 0
	Fun.headStartPos = nil
	Fun.activeMode = "dance"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		actualPosition = rootPart.Position

		if teleportThreshold < (actualPosition - movePosition).Magnitude then
			movePosition = actualPosition
		end

		moveDir = humanoid.MoveDirection

		if moveDir.Magnitude > 0.01 then
			movePosition = movePosition + moveDir * walkSpeed * deltaTime
		end

		targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
		rootPart.CFrame = targetCFrame
		speed = 1.5

		if not Fun.isThrowing then
			Fun.throwProgress = Fun.throwProgress + deltaTime * speed

			if Fun.throwProgress >= 1 then
				Fun.isThrowing = true
				Fun.throwProgress = 0

				if head then
					Fun.headStartPos = head.Position
				end
			end
		else
			Fun.throwProgress = Fun.throwProgress + deltaTime * 4

			if Fun.throwProgress >= 1 then
				Fun.isThrowing = false
				Fun.throwProgress = 0

				if head then
					head.CFrame = targetCFrame * CFrame.new(0, 1.5, 0)
					head.AssemblyLinearVelocity = Vector3.zero
				end
			end
		end

		armAngle = 0
		armPosition = 0
		headOffset = 0
		bodyLean = 0

		if not Fun.isThrowing then
			smooth = Fun.throwProgress * Fun.throwProgress * (3 - 2 * Fun.throwProgress)
			armAngle = -2.0943951023931953 * smooth
			armPosition = smooth * 0.8
			headOffset = smooth * 0.5
			bodyLean = 0.26179938779914941 * smooth
		else
			smooth = Fun.throwProgress * Fun.throwProgress * (3 - 2 * Fun.throwProgress)
			armAngle = -2.0943951023931953 + 3.1415926535897931 * smooth
			armPosition = 0.8 - smooth * 1.5
			headOffset = 0.5
			bodyLean = 0.26179938779914941 - 0.52359877559829882 * smooth
		end

		offsets = {
			Torso = CFrame.new(0, 0, 0) * CFrame.Angles(bodyLean, 0, 0),
			Head = CFrame.new(0, 1.5 + headOffset, 0),
			["Left Arm"] = CFrame.new(-1.5, 1, 0) * CFrame.Angles(armAngle, 0, 0.17453292519943295) * CFrame.new(0, -1 + armPosition, 0),
			["Right Arm"] = CFrame.new(1.5, 1, 0) * CFrame.Angles(armAngle, 0, -0.17453292519943295) * CFrame.new(0, -1 + armPosition, 0),
			["Left Leg"] = CFrame.new(-0.5, -2, 0),
			["Right Leg"] = CFrame.new(0.5, -2, 0),
		}

		for k, v4 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") and part ~= head then
				part.CFrame = targetCFrame * v4
				part.AssemblyLinearVelocity = Vector3.zero
			end
		end

		if head and Fun.isThrowing then
			startPos = Fun.headStartPos or (targetCFrame * CFrame.new(0, 1.5, 0)).Position
			throwDir = targetCFrame.LookVector * 200
			targetPos = startPos + throwDir * Fun.throwProgress * Fun.throwProgress
			head.CFrame = CFrame.new(targetPos)
			head.AssemblyLinearVelocity = Vector3.zero
		end
	end)
end

Fun.startCartoon = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	humanoid = arg:WaitForChild("Humanoid")
	Fun.RagdollRemote:FireServer(rootPart, 9999999)
	movePosition = rootPart.Position
	walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	teleportThreshold = 8
	Fun.activeMode = "dance"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		t = tick()
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		actualPosition = rootPart.Position

		if teleportThreshold < (actualPosition - movePosition).Magnitude then
			movePosition = actualPosition
		end

		moveDir = humanoid.MoveDirection

		if moveDir.Magnitude > 0.01 then
			movePosition = movePosition + moveDir * walkSpeed * deltaTime
		end

		targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
		rootPart.CFrame = targetCFrame
		speed = 8
		phase = t * speed
		jumpHeight = math.abs(math.sin(phase)) * 1.2
		legLift = math.sin(phase) * 1.8
		legLift2 = math.sin(phase + 3.1415926535897931) * 1.8
		armCircle = math.sin(phase) * 2.5
		armCircle2 = math.sin(phase + 3.1415926535897931) * 2.5
		armFlap = math.sin(phase * 1.5) * 1.5
		bodyTwist = math.sin(phase * 2) * 0.8
		headWobble = math.sin(phase * 2) * 0.3
		local cframe = CFrame.Angles
		local n = -2 + jumpHeight * 0.6
		local rad = math.rad

		offsets = {
			Torso = CFrame.new(math.sin(phase) * 0.1, n, 0) * cframe(0, math.rad(bodyTwist * 40), rad(math.sin(phase * 2) * 15)),
			Head = CFrame.new(headWobble * 0.2, 1.5 + jumpHeight + math.sin(phase * 2) * 0.1, 0) * cframe(math.rad(math.sin(phase * 1.5) * 20), 0, math.rad(headWobble * 30)),
			["Left Arm"] = CFrame.new(-1.5 + math.sin(phase) * 0.3, 1 + jumpHeight * 0.5 + math.sin(phase * 2) * 0.2, math.sin(phase) * 0.5) * cframe(n, math.rad(math.sin(phase * 1.5) * 30), math.rad(armFlap * 40)) * CFrame.new(0, -0.5, 0),
			["Right Arm"] = CFrame.new(1.5 + math.sin(phase + 3.1415926535897931) * 0.3, 1 + jumpHeight * 0.5 + math.sin(phase * 2 + 3.1415926535897931) * 0.2, math.sin(phase + 3.1415926535897931) * 0.5) * cframe(n, math.rad(math.sin(phase * 1.5 + 3.1415926535897931) * 30), math.rad(-armFlap * 40)) * CFrame.new(0, -0.5, 0),
			["Left Leg"] = CFrame.new(-0.3 + math.sin(phase) * 0.1, n, math.sin(phase) * 0.3) * CFrame.Angles(-1.0471975511965976 + legLift * 0.8, 0, math.rad(legLift * 30)),
			["Right Leg"] = CFrame.new(0.3 + math.sin(phase + 3.1415926535897931) * 0.1, n, math.sin(phase + 3.1415926535897931) * 0.3) * CFrame.Angles(-1.0471975511965976 + legLift2 * 0.8, 0, math.rad(-legLift2 * 30)),
		}

		for k, v4 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") then
				part.CFrame = targetCFrame * v4
				part.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

Fun.startKawaii = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	humanoid = arg:WaitForChild("Humanoid")
	Fun.RagdollRemote:FireServer(rootPart, 9999999)
	movePosition = rootPart.Position
	walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	teleportThreshold = 8
	Fun.activeMode = "dance"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		t = tick()
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		actualPosition = rootPart.Position

		if (actualPosition - movePosition).Magnitude > teleportThreshold then
			movePosition = actualPosition
		end

		moveDir = humanoid.MoveDirection

		if moveDir.Magnitude > 0.01 then
			movePosition = movePosition + moveDir * walkSpeed * deltaTime
		end

		targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
		rootPart.CFrame = targetCFrame
		speed = 5
		phase = t * speed
		bounce = math.abs(math.sin(phase)) * 0.15
		sway = math.sin(phase * 1.5) * 0.3
		armFold = 0.5 + math.sin(phase * 1.5) * 0.1
		armFold2 = 0.5 + math.sin(phase * 1.5 + 3.1415926535897931) * 0.1
		armForward = 0.3 + math.abs(math.sin(phase * 1.5)) * 0.2
		headTilt = math.sin(phase * 1.5) * 5
		legIn = 0.1
		local n = -headTilt * 1.5
		local cframe = CFrame.Angles
		local rad = math.rad

		offsets = {
			Torso = CFrame.new(sway * 0.1, bounce, 0) * CFrame.Angles(0, 0, math.rad(sway * 15)),
			Head = CFrame.new(0, 1.5 + bounce, 0) * cframe(math.rad(headTilt), 0, rad(n)),
			["Left Arm"] = CFrame.new(-1.2, 1 + bounce * 0.5, armForward) * cframe(math.rad(-30 - armFold * 20), 0.26179938779914941, 0.3490658503988659) * CFrame.new(0, -0.3, 0),
			["Right Arm"] = CFrame.new(1.2, 1 + bounce * 0.5, armForward) * cframe(math.rad(-30 - armFold2 * 20), -0.26179938779914941, -0.3490658503988659) * CFrame.new(0, -0.3, 0),
			["Left Leg"] = CFrame.new(-0.3 + legIn, -2 + bounce * 0.5, 0) * CFrame.Angles(-0.087266462599716474, 0.087266462599716474, 0.13962634015954636),
			["Right Leg"] = CFrame.new(0.3 - legIn, -2 + bounce * 0.5, 0) * CFrame.Angles(-0.087266462599716474, -0.087266462599716474, -0.13962634015954636),
		}

		for k, v4 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") then
				part.CFrame = targetCFrame * v4
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end)
end

Fun.startCool = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	humanoid = arg:WaitForChild("Humanoid")
	Fun.RagdollRemote:FireServer(rootPart, 9999999)
	movePosition = rootPart.Position
	walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	teleportThreshold = 8
	Fun.activeMode = "dance"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		actualPosition = rootPart.Position

		if teleportThreshold < (actualPosition - movePosition).Magnitude then
			movePosition = actualPosition
		end

		moveDir = humanoid.MoveDirection

		if moveDir.Magnitude > 0.01 then
			movePosition = movePosition + moveDir * walkSpeed * deltaTime
		end

		targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
		rootPart.CFrame = targetCFrame

		offsets = {
			Torso = CFrame.new(0, 0, 0),
			Head = CFrame.new(0, 1.5, 0),
			["Left Arm"] = CFrame.new(-0.2, -0.5, -2) * CFrame.Angles(-1.3962634015954636, -0.17453292519943295, 0.17453292519943295) * CFrame.new(0, -0.8, 0),
			["Left Leg"] = CFrame.new(-0.5, -2, 0),
			["Right Leg"] = CFrame.new(0.5, -2, 0),
		}

		for k, v4 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") then
				part.CFrame = targetCFrame * v4
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end)
end

Fun.startSpider = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	humanoid = arg:WaitForChild("Humanoid")
	Fun.RagdollRemote:FireServer(rootPart, 9999999)
	movePosition = rootPart.Position
	walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	teleportThreshold = 8
	stepCycle = 0
	Fun.activeMode = "dance"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		actualPosition = rootPart.Position

		if (actualPosition - movePosition).Magnitude > teleportThreshold then
			movePosition = actualPosition
		end

		moveDir = humanoid.MoveDirection
		isMoving = moveDir.Magnitude > 0.01

		if isMoving then
			movePosition = movePosition + moveDir * walkSpeed * deltaTime
			stepCycle = stepCycle + deltaTime * walkSpeed * 0.5
		else
			stepCycle = stepCycle + deltaTime * 2
		end

		targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
		rootPart.CFrame = targetCFrame
		phase = stepCycle
		stepSmooth = math.sin(phase)
		stepSmooth2 = math.sin(phase + 3.1415926535897931)
		footLift = math.max(0, math.sin(phase)) * 0.6
		footLift2 = math.max(0, math.sin(phase + 3.1415926535897931)) * 0.6
		legForward = math.sin(phase) * 0.5
		legForward2 = math.sin(phase + 3.1415926535897931) * 0.5
		armForward = math.sin(phase + 3.1415926535897931) * 0.5
		armForward2 = math.sin(phase) * 0.5
		bodySway = math.sin(phase * 2) * 0.03
		bodyBounce = math.abs(math.sin(phase * 2)) * 0.08
		headBob = math.sin(phase * 2) * 0.02
		legSpread = 0.35
		armSpread = 0.5
		local cframe = CFrame.Angles
		local n = -0.52359877559829882 + stepSmooth * 0.5
		local rad = math.rad

		offsets = {
			Torso = CFrame.new(bodySway, -0.6 + bodyBounce, 0) * CFrame.Angles(1.4835298641951802, 0, math.rad(bodySway * 20)),
			Head = CFrame.new(0, 0.6 - bodyBounce + headBob, 0.7) * CFrame.Angles(0, 0, 0),
			["Left Arm"] = CFrame.new(-armSpread, -0.2, armForward) * cframe(n, 0, rad(-60 + math.sin(phase) * 10)) * CFrame.new(0, -0.8 - footLift, 0),
			["Right Arm"] = CFrame.new(armSpread, -0.2, armForward2) * cframe(n, 0, rad(60 - math.sin(phase) * 10)) * CFrame.new(0, -0.8 - footLift2, 0),
			["Left Leg"] = CFrame.new(-legSpread, -0.2, legForward) * cframe(n, 0, rad(-50 + math.cos(phase) * 8)) * CFrame.new(0, -0.8 - footLift2, 0),
			["Right Leg"] = CFrame.new(legSpread, -0.2, legForward2) * cframe(n, 0, rad(50 - math.cos(phase) * 8)) * CFrame.new(0, -0.8 - footLift, 0),
		}

		for k, v4 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") then
				part.CFrame = targetCFrame * v4
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end)
end

Fun.startKoshiHuri = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	humanoid = arg:WaitForChild("Humanoid")
	Fun.RagdollRemote:FireServer(rootPart, 9999999)
	movePosition = rootPart.Position
	walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	teleportThreshold = 8
	koshiTime = 0
	Fun.activeMode = "dance"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		koshiTime = koshiTime + deltaTime
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		actualPosition = rootPart.Position

		if teleportThreshold < (actualPosition - movePosition).Magnitude then
			movePosition = actualPosition
		end

		moveDir = humanoid.MoveDirection

		if moveDir.Magnitude > 0.01 then
			movePosition = movePosition + moveDir * walkSpeed * deltaTime
		end

		targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
		rootPart.CFrame = targetCFrame
		danceSpeed = 5
		phase = koshiTime * danceSpeed
		hipX = math.sin(phase) * 0.5
		hipZ = math.cos(phase) * 0.3
		hipBounce = math.abs(math.sin(phase * 2)) * 0.2
		bodyTiltZ = math.rad(math.sin(phase) * 15)
		bodyTiltX = math.rad(5 + math.cos(phase) * 5)
		armSway = math.sin(phase) * 0.3
		kneeBend = math.abs(math.sin(phase * 2)) * 0.2
		local n = -bodyTiltZ * 0.5
		local rad = math.rad
		local cframe = CFrame.Angles

		offsets = {
			Torso = CFrame.new(hipX, hipBounce, hipZ) * CFrame.Angles(bodyTiltX, 0, bodyTiltZ),
			Head = CFrame.new(-hipX * 0.8, 1.5 + hipBounce, -hipZ * 0.5) * cframe(-0.087266462599716474, math.rad(-hipX * 20), rad(n)),
			["Left Arm"] = CFrame.new(-1.2 + armSway, 1.3 + hipBounce, -1.5) * CFrame.Angles(-2.2689280275926285, -0.3490658503988659, 1.0471975511965976) * CFrame.new(0, -0.6, 0),
			["Right Arm"] = CFrame.new(1.2 - armSway, 1.3 + hipBounce, -1.5) * CFrame.Angles(-2.2689280275926285, 0.3490658503988659, -1.0471975511965976) * CFrame.new(0, -0.6, 0),
			["Left Leg"] = CFrame.new(-0.5 + hipX * 0.3, -2 + kneeBend * 0.3, hipZ * 0.3) * cframe(math.rad(-kneeBend * 20), math.rad(hipX * 10), 0),
			["Right Leg"] = CFrame.new(0.5 + hipX * 0.3, -2 + kneeBend * 0.3, -hipZ * 0.3) * cframe(math.rad(-kneeBend * 20), math.rad(-hipX * 10), 0),
		}

		for k, v4 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") then
				part.CFrame = targetCFrame * v4
				part.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

Fun.startHeadDribble = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	humanoid = arg:WaitForChild("Humanoid")
	head = arg:FindFirstChild("Head")
	if not head then
		return
	end
	Fun.RagdollRemote:FireServer(rootPart, 9999999)
	movePosition = rootPart.Position
	walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	teleportThreshold = 8
	dribbleTime = 0
	Fun.activeMode = "dance"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		dribbleTime = dribbleTime + deltaTime
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		actualPosition = rootPart.Position

		if teleportThreshold < (actualPosition - movePosition).Magnitude then
			movePosition = actualPosition
		end

		moveDir = humanoid.MoveDirection

		if moveDir.Magnitude > 0.01 then
			movePosition = movePosition + moveDir * walkSpeed * deltaTime
		end

		targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
		rootPart.CFrame = targetCFrame
		dribbleSpeed = 6
		phase = dribbleTime * dribbleSpeed
		handUpDown = math.sin(phase) * 1.5
		local cframe = CFrame.Angles
		rightHandOffset = CFrame.new(1.5, 0.8 + handUpDown, -0.5) * cframe(math.rad(-80 + math.sin(phase) * 40), 0, -0.26179938779914941) * CFrame.new(0, -1, 0)
		rightHandWorld = targetCFrame * rightHandOffset
		bounceHeight = 0.5 + math.abs(math.sin(phase)) * 2
		headWorldPos = rightHandWorld.Position + Vector3.new(0, bounceHeight, 0)
		headLookAt = CFrame.new(headWorldPos, headWorldPos + cameraLook)
		local n = dribbleTime * 2
		headRotation = headLookAt * CFrame.Angles(math.sin(phase) * 0.4, n, 0)

		offsets = {
			Torso = CFrame.new(0, 0, 0) * CFrame.Angles(0.087266462599716474, 0, 0),
			Head = targetCFrame:ToObjectSpace(headRotation),
			["Right Arm"] = rightHandOffset,
			["Left Arm"] = CFrame.new(-0.6, -0.1, 0.1) * CFrame.Angles(-0.3490658503988659, -0.52359877559829882, 1.0471975511965976) * CFrame.new(0, -1, 0),
			["Left Leg"] = CFrame.new(-0.5, -2, 0),
			["Right Leg"] = CFrame.new(0.5, -2, 0),
		}

		for k, v4 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") then
				part.CFrame = targetCFrame * v4
				part.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

Fun.angryState = "angry"
Fun.angryStateTime = 0
Fun.angryHeadStartPos = nil
Fun.angryHeadVelocity = nil

Fun.startAngry = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	humanoid = arg:WaitForChild("Humanoid")
	head = arg:FindFirstChild("Head")
	if not head then
		return
	end
	Fun.RagdollRemote:FireServer(rootPart, 9999999)
	movePosition = rootPart.Position
	walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	teleportThreshold = 8
	Fun.angryState = "angry"
	Fun.angryStateTime = 0
	Fun.angryHeadStartPos = nil
	Fun.angryHeadVelocity = nil
	Fun.activeMode = "dance"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		Fun.angryStateTime = Fun.angryStateTime + deltaTime
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		actualPosition = rootPart.Position

		if teleportThreshold < (actualPosition - movePosition).Magnitude then
			movePosition = actualPosition
		end

		moveDir = humanoid.MoveDirection

		if moveDir.Magnitude > 0.01 then
			movePosition = movePosition + moveDir * walkSpeed * deltaTime
		end

		targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
		rootPart.CFrame = targetCFrame

		if Fun.angryState == "angry" and Fun.angryStateTime >= 3 then
			Fun.angryState = "launch"
			Fun.angryStateTime = 0

			if head then
				Fun.angryHeadStartPos = head.Position
				Fun.angryHeadVelocity = Vector3.new(0, 600, 0)
			end
		elseif Fun.angryState == "launch" and Fun.angryStateTime >= 1.5 then
			Fun.angryState = "shock"
			Fun.angryStateTime = 0
		elseif Fun.angryState == "shock" and Fun.angryStateTime >= 1 then
			Fun.angryState = "falling"
			Fun.angryStateTime = 0
		elseif Fun.angryState == "falling" and Fun.angryStateTime >= 1.5 then
			Fun.angryState = "catch"
			Fun.angryStateTime = 0
		elseif Fun.angryState == "catch" and Fun.angryStateTime >= 0.5 then
			Fun.angryState = "angry"
			Fun.angryStateTime = 0
			Fun.angryHeadStartPos = nil
			Fun.angryHeadVelocity = nil
		end

		torsoOffset = nil
		headOffset = nil
		leftArmOffset = nil
		rightArmOffset = nil
		leftLegOffset = nil
		rightLegOffset = nil

		if Fun.angryState == "angry" then
			shakeX = math.sin(Fun.angryStateTime * 30) * 0.06
			shakeY = math.sin(Fun.angryStateTime * 35 + 1) * 0.05
			shakeZ = math.sin(Fun.angryStateTime * 28 + 2) * 0.05
			local cframe = CFrame.Angles
			local rad = math.rad
			local n = shakeY * 15
			torsoOffset = CFrame.new(shakeX, shakeY, shakeZ) * cframe(math.rad(shakeX * 20), math.rad(shakeZ * 20), rad(n))
			local cframe2 = CFrame.Angles
			local rad2 = math.rad
			local n2 = shakeY * 20
			headOffset = CFrame.new(shakeX * 1.2, 1.5 + shakeY * 1.2, shakeZ * 1.2) * cframe2(math.rad(-5 + shakeX * 30), math.rad(shakeZ * 25), rad2(n2))
			local cframe3 = CFrame.Angles
			local rad3 = math.rad
			local n3 = 15 + shakeY * 20
			leftArmOffset = CFrame.new(-2, 1, -1.5 + shakeZ) * cframe3(math.rad(10 + shakeX * 15), 0, rad3(n3)) * CFrame.new(0, -1, 0)
			local cframe4 = CFrame.Angles
			local rad4 = math.rad
			local n4 = -15 - shakeY * 20
			rightArmOffset = CFrame.new(2, 1, -1.5 + shakeZ) * cframe4(math.rad(10 + shakeX * 15), 0, rad4(n4)) * CFrame.new(0, -1, 0)
			local cframe5 = CFrame.Angles
			leftLegOffset = CFrame.new(-0.9 + shakeX * 0.5, -2 + shakeY * 0.3, shakeZ * 0.3) * cframe5(math.rad(shakeX * 8), -0.26179938779914941, 0)
			local cframe6 = CFrame.Angles
			rightLegOffset = CFrame.new(0.9 + shakeX * 0.5, -2 + shakeY * 0.3, -shakeZ * 0.3) * cframe6(math.rad(shakeX * 8), 0.26179938779914941, 0)
		elseif Fun.angryState == "launch" then
			angryT = Fun.angryStateTime
			gravity = Vector3.new(0, -workspace.Gravity, 0)
			torsoOffset = CFrame.new(0, 0, 0)

			if head and Fun.angryHeadStartPos then
				headPos = Fun.angryHeadStartPos + Fun.angryHeadVelocity * angryT + 0.5 * gravity * angryT * angryT
				head.CFrame = CFrame.new(headPos) * CFrame.Angles(angryT * 10, angryT * 8, angryT * 12)
				head.AssemblyLinearVelocity = Vector3.zero
			end

			leftArmOffset = CFrame.new(-1.5, 1, -1.5) * CFrame.Angles(-1.5707963267948966, 0, 0.26179938779914941) * CFrame.new(0, -1, 0)
			rightArmOffset = CFrame.new(1.5, 1, -1.5) * CFrame.Angles(-1.5707963267948966, 0, -0.26179938779914941) * CFrame.new(0, -1, 0)
			leftLegOffset = CFrame.new(-0.5, -2, 0)
			rightLegOffset = CFrame.new(0.5, -2, 0)
		elseif Fun.angryState == "shock" then
			shockIntensity = math.min(Fun.angryStateTime * 4, 1)
			local cframe = CFrame.Angles
			torsoOffset = CFrame.new(0, shockIntensity * 0.2, -shockIntensity * 0.3) * cframe(math.rad(-shockIntensity * 20), 0, 0)
			local cframe2 = CFrame.Angles
			leftArmOffset = CFrame.new(-1.5, 1 + shockIntensity * 1.2, -1.5) * cframe2(math.rad(-90 - shockIntensity * 80), 0, 0.52359877559829882) * CFrame.new(0, -1, 0)
			local cframe3 = CFrame.Angles
			rightArmOffset = CFrame.new(1.5, 1 + shockIntensity * 1.2, -1.5) * cframe3(math.rad(-90 - shockIntensity * 80), 0, -0.52359877559829882) * CFrame.new(0, -1, 0)
			leftLegOffset = CFrame.new(-0.6, -2, 0.1) * CFrame.Angles(-0.087266462599716474, 0.26179938779914941, 0)
			rightLegOffset = CFrame.new(0.6, -2, -0.1) * CFrame.Angles(-0.087266462599716474, -0.26179938779914941, 0)
		elseif Fun.angryState == "falling" then
			angryT = Fun.angryStateTime
			torsoOffset = CFrame.new(0, -0.3, 0) * CFrame.Angles(0.26179938779914941, 0, 0)

			if head then
				fallHeight = 150 - angryT / 1.5 * 150
				fallHeight = math.max(fallHeight, 1.5)
				headWorldPos = (targetCFrame * CFrame.new(0, fallHeight, 0)).Position
				head.CFrame = CFrame.new(headWorldPos) * CFrame.Angles(angryT * 20, angryT * 15, angryT * 18)
				head.AssemblyLinearVelocity = Vector3.zero
			end

			leftArmOffset = CFrame.new(-1.5, 1.5, -1.5) * CFrame.Angles(-2.2689280275926285, 0, 0.3490658503988659) * CFrame.new(0, -1, 0)
			rightArmOffset = CFrame.new(1.5, 1.5, -1.5) * CFrame.Angles(-2.2689280275926285, 0, -0.3490658503988659) * CFrame.new(0, -1, 0)
			leftLegOffset = CFrame.new(-0.6, -2, 0.2)
			rightLegOffset = CFrame.new(0.6, -2, -0.2) * CFrame.Angles(0, 0.3490658503988659, 0)
		elseif Fun.angryState == "catch" then
			smooth = Fun.angryStateTime / 0.5
			local cframe = CFrame.Angles
			torsoOffset = CFrame.new(0, -0.1 * (1 - smooth), 0) * cframe(math.rad(5 * (1 - smooth)), 0, 0)

			if head then
				targetHeadCFrame = targetCFrame * CFrame.new(0, 1.5, 0)
				head.CFrame = head.CFrame:Lerp(targetHeadCFrame, smooth)
				head.AssemblyLinearVelocity = Vector3.zero
			end

			leftArmOffset = CFrame.new(-1, 1, -1.5) * CFrame.Angles(-1.7453292519943295, -0.3490658503988659, 0.69813170079773179) * CFrame.new(0, -0.8, 0)
			rightArmOffset = CFrame.new(1, 1, -1.5) * CFrame.Angles(-1.7453292519943295, 0.3490658503988659, -0.69813170079773179) * CFrame.new(0, -0.8, 0)
			leftLegOffset = CFrame.new(-0.5, -2, 0)
			rightLegOffset = CFrame.new(0.5, -2, 0)
		end

		offsets = {}

		if torsoOffset then
			offsets.Torso = torsoOffset
		end

		if headOffset then
			offsets.Head = headOffset
		end

		if leftArmOffset then
			offsets["Left Arm"] = leftArmOffset
		end

		if rightArmOffset then
			offsets["Right Arm"] = rightArmOffset
		end

		if leftLegOffset then
			offsets["Left Leg"] = leftLegOffset
		end

		if rightLegOffset then
			offsets["Right Leg"] = rightLegOffset
		end

		for k, v4 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") then
				part.CFrame = targetCFrame * v4
				part.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

Fun.startSoccer = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	humanoid = arg:WaitForChild("Humanoid")
	head = arg:FindFirstChild("Head")
	if not head then
		return
	end
	Fun.RagdollRemote:FireServer(rootPart, 9999999)
	movePosition = rootPart.Position
	walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	teleportThreshold = 8
	soccerTime = 0
	Fun.activeMode = "dance"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		soccerTime = soccerTime + deltaTime
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		actualPosition = rootPart.Position

		if (actualPosition - movePosition).Magnitude > teleportThreshold then
			movePosition = actualPosition
		end

		moveDir = humanoid.MoveDirection

		if moveDir.Magnitude > 0.01 then
			movePosition = movePosition + moveDir * walkSpeed * deltaTime
		end

		targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
		rootPart.CFrame = targetCFrame
		kickSpeed = 4
		cycle = soccerTime * kickSpeed
		phase = cycle % 1
		legLift = 0
		headBounce = 0

		if phase < 0.25 then
			legLift = phase / 0.25
			headBounce = 0
		elseif phase < 0.35 then
			legLift = 1
			headBounce = (phase - 0.25) / 0.1
		elseif phase < 0.65 then
			legLift = 1 - (phase - 0.35) / 0.3
			headBounce = 1
		elseif phase < 0.8 then
			legLift = 0
			headBounce = 1 - (phase - 0.65) / 0.15
		else
			legLift = 0
			headBounce = 0
		end

		headForward = -1.2
		headDown = 0.2 - headBounce * 4
		rightLegUp = 0.5 + legLift * 1.5
		rightLegForward = -0.5 - legLift * 0.7
		local cframe = CFrame.Angles
		local rad = math.rad
		local n = -legLift * 10

		offsets = {
			Torso = CFrame.new(0, 0, 0) * cframe(math.rad(-legLift * 10), 0, 0),
			Head = CFrame.new(0, 1.5 - headDown, headForward) * CFrame.Angles(headBounce * 3, soccerTime * 4, headBounce * 2),
			["Left Arm"] = CFrame.new(-1.5, 1, -1.5) * CFrame.Angles(-1.7453292519943295, -0.3490658503988659, 0.52359877559829882) * CFrame.new(0, -1, 0),
			["Right Arm"] = CFrame.new(1.5, 1, -1.5) * CFrame.Angles(-1.7453292519943295, 0.3490658503988659, -0.52359877559829882) * CFrame.new(0, -1, 0),
			["Left Leg"] = CFrame.new(-0.3, -2, 0.1),
			["Right Leg"] = CFrame.new(0.5, -2 + rightLegUp, rightLegForward) * cframe(math.rad(-legLift * 100), 0, rad(n)),
		}

		for k, v4 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") then
				part.CFrame = targetCFrame * v4
				part.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

Fun.startHeadOrbit = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	humanoid = arg:WaitForChild("Humanoid")
	torso = arg:FindFirstChild("Torso") or arg:FindFirstChild("UpperTorso")
	head = arg:FindFirstChild("Head")
	if not torso or not head then
		return
	end
	Fun.RagdollRemote:FireServer(rootPart, 9999999)
	movePosition = rootPart.Position
	walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	teleportThreshold = 8
	orbitTime = 0
	orbitSpeed = 3
	orbitRadius = 3
	orbitHeight = 0.5
	Fun.activeMode = "dance"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		orbitTime = orbitTime + deltaTime
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		actualPosition = rootPart.Position

		if teleportThreshold < (actualPosition - movePosition).Magnitude then
			movePosition = actualPosition
		end

		moveDir = humanoid.MoveDirection

		if moveDir.Magnitude > 0.01 then
			movePosition = movePosition + moveDir * walkSpeed * deltaTime
		end

		targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
		rootPart.CFrame = targetCFrame
		torsoWorldPos = (targetCFrame * CFrame.new(0, 0.5, 0)).Position
		orbitAngle = orbitTime * orbitSpeed
		local v4 = orbitRadius
		headOffsetX = math.cos(orbitAngle) * v4
		local v5 = orbitRadius
		headOffsetZ = math.sin(orbitAngle) * v5
		headWorldPos = torsoWorldPos + Vector3.new(headOffsetX, orbitHeight, headOffsetZ)
		tangentX = -math.sin(orbitAngle)
		tangentZ = math.cos(orbitAngle)
		headForward = Vector3.new(tangentX, 0, tangentZ)
		headLookCFrame = CFrame.new(headWorldPos, headWorldPos + headForward)
		headFinalCFrame = headLookCFrame * CFrame.Angles(0, 0, orbitTime * 5)

		offsets = {
			Torso = CFrame.new(0, 0, 0),
			Head = targetCFrame:ToObjectSpace(headFinalCFrame),
			["Left Arm"] = CFrame.new(-1.5, 1, 0) * CFrame.Angles(-2.0943951023931953, 0, 0.52359877559829882) * CFrame.new(0, -1, 0),
			["Right Arm"] = CFrame.new(1.5, 1, 0) * CFrame.Angles(-2.0943951023931953, 0, -0.52359877559829882) * CFrame.new(0, -1, 0),
			["Left Leg"] = CFrame.new(-0.5, -2, 0),
			["Right Leg"] = CFrame.new(0.5, -2, 0),
		}

		for k, v6 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") then
				part.CFrame = targetCFrame * v6
				part.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

Fun.startLol = function(arg)
	Fun.stopPose()
	rootPart = arg:WaitForChild("HumanoidRootPart")
	humanoid = arg:WaitForChild("Humanoid")
	Fun.RagdollRemote:FireServer(rootPart, 9999999)
	movePosition = rootPart.Position
	walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
	teleportThreshold = 8
	lolTime = 0
	Fun.activeMode = "dance"

	Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not rootPart or not rootPart.Parent then
			Fun.stopPose()
			return
		end
		lolTime = lolTime + deltaTime
		cameraLook = Fun.camera.CFrame.LookVector
		yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
		actualPosition = rootPart.Position

		if teleportThreshold < (actualPosition - movePosition).Magnitude then
			movePosition = actualPosition
		end

		moveDir = humanoid.MoveDirection

		if moveDir.Magnitude > 0.01 then
			movePosition = movePosition + moveDir * walkSpeed * deltaTime
		end

		targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
		rootPart.CFrame = targetCFrame
		laughCycle = lolTime * 4
		laughIntensity = math.abs(math.sin(laughCycle))
		leanBack = math.rad(-15 - laughIntensity * 30)
		bounce = laughIntensity * 0.3
		headTilt = math.rad(10 + laughIntensity * 25)
		armsForward = -1.5 + laughIntensity * 0.3
		legSpread = 0.3 + laughIntensity * 0.3
		local v4 = headTilt
		local rad = math.rad
		local n = -50 - laughIntensity * 10
		local cframe = CFrame.Angles

		offsets = {
			Torso = CFrame.new(0, bounce, laughIntensity * 0.3) * CFrame.Angles(leanBack, 0, 0),
			Head = CFrame.new(0, 1.5 + bounce, -laughIntensity * 0.4) * cframe(v4, math.rad(math.sin(laughCycle * 2) * 15), rad(math.sin(laughCycle * 1.5) * 8)),
			["Left Arm"] = CFrame.new(-0.8, 0.3 + bounce * 0.5, armsForward) * cframe(math.rad(-70 + laughIntensity * 15), -0.26179938779914941, rad(n)) * CFrame.new(0, -0.7, 0),
			["Right Arm"] = CFrame.new(0.8, 0.3 + bounce * 0.5, armsForward) * cframe(math.rad(-70 + laughIntensity * 15), 0.26179938779914941, rad(n)) * CFrame.new(0, -0.7, 0),
			["Left Leg"] = CFrame.new(-0.5 - legSpread, -2 + bounce * 0.3, 0) * cframe(math.rad(laughIntensity * 10), math.rad(-legSpread * 30), 0),
			["Right Leg"] = CFrame.new(0.5 + legSpread, -2 + bounce * 0.3, 0) * cframe(math.rad(laughIntensity * 10), math.rad(legSpread * 30), 0),
		}

		for k, v5 in pairs(offsets) do
			part = arg:FindFirstChild(k)

			if part and part:IsA("BasePart") then
				part.CFrame = targetCFrame * v5
				part.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

Fun.makeProceduralDance = function(arg)
	return function(arg2)
		Fun.stopPose()
		rootPart = arg2:WaitForChild("HumanoidRootPart")
		humanoid = arg2:WaitForChild("Humanoid")
		Fun.RagdollRemote:FireServer(rootPart, 9999999)
		movePosition = rootPart.Position
		walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
		teleportThreshold = 8
		Fun.activeMode = "dance"

		Fun.poseConnection = Fun.RunService.Heartbeat:Connect(function(deltaTime)
			if not arg2 or not arg2.Parent or not rootPart or not rootPart.Parent then
				Fun.stopPose()
				return
			end
			t = tick()
			cameraLook = Fun.camera.CFrame.LookVector
			yawAngle = math.atan2(-cameraLook.X, -cameraLook.Z)
			actualPosition = rootPart.Position

			if (actualPosition - movePosition).Magnitude > teleportThreshold then
				movePosition = actualPosition
			end

			moveDir = humanoid.MoveDirection

			if moveDir.Magnitude > 0.01 then
				movePosition = movePosition + moveDir * walkSpeed * deltaTime
			end

			targetCFrame = CFrame.new(movePosition) * CFrame.Angles(0, yawAngle, 0)
			rootPart.CFrame = targetCFrame
			phase = t * arg.speed
			offsets = arg.pose(phase)

			for k, v4 in pairs(offsets) do
				part = arg2:FindFirstChild(k)

				if part and part:IsA("BasePart") then
					part.CFrame = targetCFrame * v4
					part.AssemblyLinearVelocity = Vector3.zero
				end
			end
		end)
	end
end

Fun.originalDanceParams = {
	["Robot Lock"] = {
		speed = 6,
		pose = function(arg)
			snap = math.floor(math.sin(arg) * 4) / 4
			snap2 = math.floor(math.sin(arg + 3.1415926535897931) * 4) / 4
			local cframe = CFrame.Angles

			return {
				Torso = CFrame.new(0, 0, 0) * cframe(0, math.rad(snap * 20), 0),
				Head = CFrame.new(0, 1.5, 0) * cframe(0, math.rad(-snap * 30), 0),
				["Left Arm"] = CFrame.new(-1.5, 1 + snap * 0.5, 0) * cframe(math.rad(snap * 90), 0, 0),
				["Right Arm"] = CFrame.new(1.5, 1 + snap2 * 0.5, 0) * cframe(math.rad(snap2 * 90), 0, 0),
				["Left Leg"] = CFrame.new(-0.5, -2, 0),
				["Right Leg"] = CFrame.new(0.5, -2, 0),
			}
		end,
	},
	["Disco Point"] = {
		speed = 4,
		pose = function(arg)
			up = math.sin(arg) > 0
			pointAngle = up and -2.6179938779914944 or 1.0471975511965976
			pointAngle2 = up and 1.0471975511965976 or -2.6179938779914944
			hip = math.sin(arg * 2) * 0.2

			return {
				Torso = CFrame.new(hip, 0, 0) * CFrame.Angles(0, 0, math.rad(hip * 15)),
				Head = CFrame.new(0, 1.5, 0),
				["Left Arm"] = CFrame.new(-1.5, 1, 0) * CFrame.Angles(pointAngle, 0, 0) * CFrame.new(0, -1, 0),
				["Right Arm"] = CFrame.new(1.5, 1, 0) * CFrame.Angles(pointAngle2, 0, 0) * CFrame.new(0, -1, 0),
				["Left Leg"] = CFrame.new(-0.5, -2, 0),
				["Right Leg"] = CFrame.new(0.5, -2, 0),
			}
		end,
	},
	["Wave Ripple"] = {
		speed = 4,
		pose = function(arg)
			local cframe = CFrame.Angles
			local rad = math.rad

			return {
				Torso = CFrame.new(0, math.sin(arg) * 0.1, 0) * cframe(0, 0, rad(math.sin(arg) * 8)),
				Head = CFrame.new(0, 1.5 + math.sin(arg + 0.3) * 0.1, 0) * cframe(rad(math.sin(arg + 0.3) * 10), 0, 0),
				["Left Arm"] = CFrame.new(-1.5, 1 + math.sin(arg + 0.6) * 0.8, 0) * CFrame.Angles(0, 0, 0.3490658503988659),
				["Right Arm"] = CFrame.new(1.5, 1 + math.sin(arg + 1.2) * 0.8, 0) * CFrame.Angles(0, 0, -0.3490658503988659),
				["Left Leg"] = CFrame.new(-0.5, -2 + math.sin(arg + 1.8) * 0.15, 0),
				["Right Leg"] = CFrame.new(0.5, -2 + math.sin(arg + 2.4) * 0.15, 0),
			}
		end,
	},
	["Jazz Hands"] = {
		speed = 14,
		pose = function(arg)
			shake = math.sin(arg) * 0.15

			return {
				Torso = CFrame.new(0, 0.1, 0),
				Head = CFrame.new(0, 1.6, 0),
				["Left Arm"] = CFrame.new(-1.8 + shake, 1.6, 0) * CFrame.Angles(-2.4434609527920612, 0, math.rad(shake * 60)),
				["Right Arm"] = CFrame.new(1.8 - shake, 1.6, 0) * CFrame.Angles(-2.4434609527920612, 0, math.rad(-shake * 60)),
				["Left Leg"] = CFrame.new(-0.5, -2, 0),
				["Right Leg"] = CFrame.new(0.5, -2, 0),
			}
		end,
	},
	Headbang = {
		speed = 12,
		pose = function(arg)
			snap = math.abs(math.sin(arg))
			local cframe = CFrame.Angles

			return {
				Torso = CFrame.new(0, 0, 0) * cframe(math.rad(snap * 15), 0, 0),
				Head = CFrame.new(0, 1.5 - snap * 0.3, 0.2 * snap) * cframe(math.rad(snap * 55), 0, 0),
				["Left Arm"] = CFrame.new(-1.5, 1, 0) * CFrame.Angles(-0.3490658503988659, 0, 0.17453292519943295),
				["Right Arm"] = CFrame.new(1.5, 1, 0) * CFrame.Angles(-0.3490658503988659, 0, -0.17453292519943295),
				["Left Leg"] = CFrame.new(-0.5, -2, 0),
				["Right Leg"] = CFrame.new(0.5, -2, 0),
			}
		end,
	},
	["Shoulder Shimmy"] = {
		speed = 16,
		pose = function(arg)
			shim = math.sin(arg) * 0.3
			shim2 = math.sin(arg + 3.1415926535897931) * 0.3

			return {
				Torso = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(shim * 6)),
				Head = CFrame.new(0, 1.5, 0),
				["Left Arm"] = CFrame.new(-1.5, 1 + shim, 0) * CFrame.Angles(0, 0, 0.26179938779914941),
				["Right Arm"] = CFrame.new(1.5, 1 + shim2, 0) * CFrame.Angles(0, 0, -0.26179938779914941),
				["Left Leg"] = CFrame.new(-0.5, -2, 0),
				["Right Leg"] = CFrame.new(0.5, -2, 0),
			}
		end,
	},
	["Boxer Bounce"] = {
		speed = 10,
		pose = function(arg)
			bounce = math.abs(math.sin(arg)) * 0.25
			jab = math.sin(arg * 2) * 0.4

			return {
				Torso = CFrame.new(0, bounce, 0) * CFrame.Angles(0.087266462599716474, 0, 0),
				Head = CFrame.new(0, 1.4 + bounce, 0),
				["Left Arm"] = CFrame.new(-1, 1.2 + bounce, -0.3 + jab) * CFrame.Angles(-1.7453292519943295, 0, 0),
				["Right Arm"] = CFrame.new(1, 1.2 + bounce, -0.3 - jab) * CFrame.Angles(-1.7453292519943295, 0, 0),
				["Left Leg"] = CFrame.new(-0.5, -2 + bounce * 0.5, 0.2),
				["Right Leg"] = CFrame.new(0.5, -2 + bounce * 0.5, -0.2),
			}
		end,
	},
	["Salsa Hip"] = {
		speed = 7,
		pose = function(arg)
			hip = math.sin(arg) * 0.5
			local n = hip * 12
			local cframe = CFrame.Angles
			local rad = math.rad

			return {
				Torso = CFrame.new(hip * 0.3, 0, 0) * cframe(0, math.rad(hip * 10), rad(n)),
				Head = CFrame.new(0, 1.5, 0) * cframe(0, math.rad(-hip * 8), 0),
				["Left Arm"] = CFrame.new(-1.4, 1.1, 0) * CFrame.Angles(-0.69813170079773179, 0, math.rad(hip * 20)),
				["Right Arm"] = CFrame.new(1.4, 1.1, 0) * CFrame.Angles(-0.69813170079773179, 0, math.rad(-hip * 20)),
				["Left Leg"] = CFrame.new(-0.5 - hip * 0.2, -2, 0),
				["Right Leg"] = CFrame.new(0.5 + hip * 0.2, -2, 0),
			}
		end,
	},
	["Cheer Jump"] = {
		speed = 9,
		pose = function(arg)
			jump = math.abs(math.sin(arg)) * 0.6

			return {
				Torso = CFrame.new(0, jump, 0),
				Head = CFrame.new(0, 1.5 + jump, 0),
				["Left Arm"] = CFrame.new(-1.5, 2 + jump, 0) * CFrame.Angles(-2.9670597283903604, 0, 0.3490658503988659),
				["Right Arm"] = CFrame.new(1.5, 2 + jump, 0) * CFrame.Angles(-2.9670597283903604, 0, -0.3490658503988659),
				["Left Leg"] = CFrame.new(-0.5, -2 + jump * 0.4, 0),
				["Right Leg"] = CFrame.new(0.5, -2 + jump * 0.4, 0),
			}
		end,
	},
	["Propeller Arms"] = {
		speed = 10,
		pose = function(arg)
			return {
				Torso = CFrame.new(0, 0, 0),
				Head = CFrame.new(0, 1.5, 0),
				["Left Arm"] = CFrame.new(-1.5, 1, 0) * CFrame.Angles(arg, 0, 0) * CFrame.new(0, -1, 0),
				["Right Arm"] = CFrame.new(1.5, 1, 0) * CFrame.Angles(-arg, 0, 0) * CFrame.new(0, -1, 0),
				["Left Leg"] = CFrame.new(-0.5, -2, 0),
				["Right Leg"] = CFrame.new(0.5, -2, 0),
			}
		end,
	},
	["Matrix Lean"] = {
		speed = 3,
		pose = function(arg)
			lean = (math.sin(arg) + 1) / 2
			local cframe = CFrame.Angles

			return {
				Torso = CFrame.new(0, -lean * 0.4, -lean * 0.5) * cframe(math.rad(-lean * 60), 0, 0),
				Head = CFrame.new(0, 1.5 - lean * 0.3, -lean * 0.3) * cframe(math.rad(-lean * 60), 0, 0),
				["Left Arm"] = CFrame.new(-1.5, 1, 0) * cframe(math.rad(-lean * 30), 0, 0),
				["Right Arm"] = CFrame.new(1.5, 1, 0) * cframe(math.rad(-lean * 30), 0, 0),
				["Left Leg"] = CFrame.new(-0.6, -2, 0.2),
				["Right Leg"] = CFrame.new(0.4, -2, -0.2),
			}
		end,
	},
	["Victory Pump"] = {
		speed = 8,
		pose = function(arg)
			pump = math.abs(math.sin(arg))

			return {
				Torso = CFrame.new(0, pump * 0.15, 0),
				Head = CFrame.new(0, 1.5 + pump * 0.15, 0),
				["Left Arm"] = CFrame.new(-1.5, 1 + pump * 1.2, 0) * CFrame.Angles(-2.9670597283903604 * pump, 0, 0),
				["Right Arm"] = CFrame.new(1.5, 1, 0) * CFrame.Angles(-0.52359877559829882, 0, 0),
				["Left Leg"] = CFrame.new(-0.5, -2, 0),
				["Right Leg"] = CFrame.new(0.5, -2, 0),
			}
		end,
	},
	["Ninja Flow"] = {
		speed = 5,
		pose = function(arg)
			crouch = 0.4
			chop = math.sin(arg) * 0.6
			local cframe = CFrame.Angles

			return {
				Torso = CFrame.new(0, -crouch, 0) * cframe(0.17453292519943295, math.rad(chop * 10), 0),
				Head = CFrame.new(0, 1.5 - crouch, 0),
				["Left Arm"] = CFrame.new(-1.3, 1 - crouch, chop) * CFrame.Angles(-0.69813170079773179, 0, 0.3490658503988659),
				["Right Arm"] = CFrame.new(1.3, 1 - crouch, -chop) * CFrame.Angles(-0.69813170079773179, 0, -0.3490658503988659),
				["Left Leg"] = CFrame.new(-0.6, -1.8 - crouch * 0.3, 0.1) * CFrame.Angles(-0.26179938779914941, 0, 0),
				["Right Leg"] = CFrame.new(0.6, -1.8 - crouch * 0.3, -0.1) * CFrame.Angles(-0.26179938779914941, 0, 0),
			}
		end,
	},
	["Superhero Pose"] = {
		speed = 2,
		pose = function(arg)
			breathe = math.sin(arg) * 0.03

			return {
				Torso = CFrame.new(0, breathe, 0.1) * CFrame.Angles(-0.087266462599716474, 0, 0),
				Head = CFrame.new(0, 1.5 + breathe, 0.1) * CFrame.Angles(0.087266462599716474, 0, 0),
				["Left Arm"] = CFrame.new(-1.2, 1.2, 0.3) * CFrame.Angles(-1.7453292519943295, 0, 0.52359877559829882),
				["Right Arm"] = CFrame.new(1.4, 0.9, 0) * CFrame.Angles(-0.17453292519943295, 0, -0.17453292519943295),
				["Left Leg"] = CFrame.new(-0.5, -2, 0.1),
				["Right Leg"] = CFrame.new(0.6, -2, -0.3) * CFrame.Angles(0, 0.3490658503988659, 0),
			}
		end,
	},
	["Snake Wave"] = {
		speed = 5,
		pose = function(arg)
			local cframe = CFrame.Angles
			local rad = math.rad

			return {
				Torso = CFrame.new(math.sin(arg) * 0.4, 0, 0) * cframe(0, 0, rad(math.sin(arg) * 20)),
				Head = CFrame.new(math.sin(arg + 0.8) * 0.5, 1.5, 0) * cframe(0, 0, rad(math.sin(arg + 0.8) * 25)),
				["Left Arm"] = CFrame.new(-1.5 + math.sin(arg) * 0.2, 1, 0) * CFrame.Angles(0, 0, 0.26179938779914941),
				["Right Arm"] = CFrame.new(1.5 + math.sin(arg) * 0.2, 1, 0) * CFrame.Angles(0, 0, -0.26179938779914941),
				["Left Leg"] = CFrame.new(-0.5 - math.sin(arg) * 0.15, -2, 0),
				["Right Leg"] = CFrame.new(0.5 - math.sin(arg) * 0.15, -2, 0),
			}
		end,
	},
	["Staircase Step"] = {
		speed = 4,
		pose = function(arg)
			side = math.sin(arg)
			step = math.abs(math.sin(arg * 2)) * 0.3

			return {
				Torso = CFrame.new(side * 0.8, step, 0),
				Head = CFrame.new(side * 0.8, 1.5 + step, 0),
				["Left Arm"] = CFrame.new(-1.5 + side * 0.8, 1, 0) * CFrame.Angles(0, 0, 0.17453292519943295),
				["Right Arm"] = CFrame.new(1.5 + side * 0.8, 1, 0) * CFrame.Angles(0, 0, -0.17453292519943295),
				["Left Leg"] = CFrame.new(-0.5 + side * 0.8, -2 + step, 0),
				["Right Leg"] = CFrame.new(0.5 + side * 0.8, -2 + step, 0),
			}
		end,
	},
	["Windmill Arms"] = {
		speed = 6,
		pose = function(arg)
			return {
				Torso = CFrame.new(0, 0, 0),
				Head = CFrame.new(0, 1.5, 0),
				["Left Arm"] = CFrame.new(-1.5, 1, 0) * CFrame.Angles(arg, 0, 0) * CFrame.new(0, -1, 0),
				["Right Arm"] = CFrame.new(1.5, 1, 0) * CFrame.Angles(arg + 3.1415926535897931, 0, 0) * CFrame.new(0, -1, 0),
				["Left Leg"] = CFrame.new(-0.5, -2, 0),
				["Right Leg"] = CFrame.new(0.5, -2, 0),
			}
		end,
	},
	["Popcorn Pop"] = {
		speed = 13,
		pose = function(arg)
			pop = math.max(0, math.sin(arg)) ^ 3 * 0.5
			local cframe = CFrame.Angles

			return {
				Torso = CFrame.new(0, pop, 0),
				Head = CFrame.new(0, 1.5 + pop, 0),
				["Left Arm"] = CFrame.new(-1.5, 1 + pop * 1.5, 0) * cframe(math.rad(-pop * 200), 0, 0),
				["Right Arm"] = CFrame.new(1.5, 1 + pop * 1.5, 0) * cframe(math.rad(-pop * 200), 0, 0),
				["Left Leg"] = CFrame.new(-0.5, -2 + pop * 0.3, 0),
				["Right Leg"] = CFrame.new(0.5, -2 + pop * 0.3, 0),
			}
		end,
	},
	["Clap Along"] = {
		speed = 8,
		pose = function(arg)
			clap = (math.sin(arg) + 1) / 2
			local cframe = CFrame.Angles

			return {
				Torso = CFrame.new(0, math.abs(math.sin(arg)) * 0.1, 0),
				Head = CFrame.new(0, 1.5, 0) * cframe(math.rad(clap * 10), 0, 0),
				["Left Arm"] = CFrame.new(-0.7 * clap - 0.3, 1.2, 0.2) * CFrame.Angles(-1.2217304763960306, 0, 0.3490658503988659),
				["Right Arm"] = CFrame.new(0.7 * clap + 0.3, 1.2, 0.2) * CFrame.Angles(-1.2217304763960306, 0, -0.3490658503988659),
				["Left Leg"] = CFrame.new(-0.5, -2, 0),
				["Right Leg"] = CFrame.new(0.5, -2, 0),
			}
		end,
	},
	["Zombie Shuffle"] = {
		speed = 3,
		pose = function(arg)
			shuffle = math.sin(arg) * 0.3
			local cframe = CFrame.Angles

			return {
				Torso = CFrame.new(0, 0, 0) * cframe(-0.13962634015954636, math.rad(shuffle * 5), 0),
				Head = CFrame.new(0, 1.5, 0) * CFrame.Angles(0.087266462599716474, 0, math.rad(shuffle * 10)),
				["Left Arm"] = CFrame.new(-1.5, 1.3, -1) * CFrame.Angles(-1.4835298641951802, 0, 0),
				["Right Arm"] = CFrame.new(1.5, 1.3, -1) * CFrame.Angles(-1.4835298641951802, 0, 0),
				["Left Leg"] = CFrame.new(-0.5 + shuffle * 0.3, -2, 0),
				["Right Leg"] = CFrame.new(0.5 - shuffle * 0.3, -2, 0),
			}
		end,
	},
}

Fun.Dances = {
	["Floss Dance"] = Fun.startFlossDance,
	["Ouen Dance"] = Fun.startOrangeJustice,
	["Head Ball"] = Fun.startHeadThrow,
	Cartoon = Fun.startCartoon,
	Kawaii = Fun.startKawaii,
	Cool = Fun.startCool,
	Spider = Fun.startSpider,
	["Koshi huri"] = Fun.startKoshiHuri,
	["Head dribble"] = Fun.startHeadDribble,
	Angry = Fun.startAngry,
	soccer = Fun.startSoccer,
	["Head orbit"] = Fun.startHeadOrbit,
	Lol = Fun.startLol,
}

for k, originalDanceParam in pairs(Fun.originalDanceParams) do
	Fun.Dances[k] = Fun.makeProceduralDance(originalDanceParam)
end

Fun.playSelectedDance = function(arg)
	fn = Fun.Dances[Fun.selectedDance]

	if fn then
		fn(arg)
	end
end

Fun.me.CharacterAdded:Connect(function(character)
	task.wait(0.2)
	modeAtRespawn = Fun.activeMode

	if modeAtRespawn == "dance" then
		Fun.playSelectedDance(character)
	elseif modeAtRespawn == "ragdoll" then
		Fun.startRagdollOnly(character)
	end

	if Fun.isDancingV2 and Fun.activeDanceDataV2 then
		task.wait(0.3)
		Fun.startHipDanceV2(character)
	end
end)

-- Dance V2
Fun.currentDanceRawTableV2 = {}
Fun.danceListV2 = {}
Fun.activeDanceDataV2 = nil
Fun.selectedDanceNameV2 = ""
Fun.isDancingV2 = false
Fun.poseConnectionV2 = nil
Fun.frameIndexV2 = 1
Fun.frameTimerV2 = 0
local FunV2SkipParts = { HumanoidRootPart = true, Handle = true, LArmIKPart = true, RArmIKPart = true }

Fun.stopHipDanceV2 = function(arg)
	if Fun.poseConnectionV2 then
		Fun.poseConnectionV2:Disconnect()
		Fun.poseConnectionV2 = nil
	end
	if arg then
		local humanoid_ = arg:FindFirstChildOfClass("Humanoid")
		if humanoid_ then
			humanoid_.PlatformStand = false
			humanoid_.AutoRotate = true
		end
	end
end

Fun.startHipDanceV2 = function(arg)
	if not Fun.activeDanceDataV2 or not arg then
		return
	end
	Fun.stopHipDanceV2(arg)
	Fun.stopPose()
	local humanoidRootPart = arg:WaitForChild("HumanoidRootPart", 5)
	local humanoid_ = arg:WaitForChild("Humanoid", 5)
	if not humanoidRootPart or not humanoid_ then return end

	if Fun.RagdollRemote then
		pcall(function() Fun.RagdollRemote:FireServer(humanoidRootPart, 9999999) end)
	else
		humanoid_.PlatformStand = true
		humanoid_.AutoRotate = false
	end

	local position = humanoidRootPart.Position
	local walkSpeed_ = humanoid_.WalkSpeed > 0 and humanoid_.WalkSpeed or 16
	local n = 8
	local n2 = #Fun.activeDanceDataV2.frames
	if n2 == 0 then return end
	Fun.frameIndexV2 = 1
	Fun.frameTimerV2 = 0

	local function parseCFrameData(arg2)
		return CFrame.new(arg2[1], arg2[2], arg2[3], arg2[4], arg2[5], arg2[6], arg2[7], arg2[8], arg2[9], arg2[10], arg2[11], arg2[12])
	end

	Fun.poseConnectionV2 = Fun.RunService.Heartbeat:Connect(function(deltaTime)
		if not arg or not arg.Parent or not humanoidRootPart or not humanoidRootPart.Parent then
			return
		end
		local lookVector = Fun.camera.CFrame.LookVector
		local v4 = math.atan2(-lookVector.X, -lookVector.Z)
		local position2 = humanoidRootPart.Position

		if n < (position2 - position).Magnitude then
			position = position2
		end

		local moveDirection = humanoid_.MoveDirection
		if moveDirection.Magnitude > 0.01 then
			position += moveDirection * walkSpeed_ * deltaTime
		end

		local cFrame = CFrame.new(position) * CFrame.Angles(0, v4, 0)
		humanoidRootPart.CFrame = cFrame
		humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
		Fun.frameTimerV2 = Fun.frameTimerV2 + deltaTime
		local flag = false

		if Fun.activeDanceDataV2.interval <= Fun.frameTimerV2 then
			Fun.frameTimerV2 = Fun.frameTimerV2 - Fun.activeDanceDataV2.interval
			Fun.frameIndexV2 = Fun.frameIndexV2 + 1
			if n2 < Fun.frameIndexV2 then
				Fun.frameIndexV2 = 1
				flag = true
			end
		end

		local v5 = Fun.activeDanceDataV2.frames[Fun.frameIndexV2]
		local v6 = Fun.activeDanceDataV2.frames[Fun.frameIndexV2 < n2 and Fun.frameIndexV2 + 1 or 1]
		local alpha = flag and 1 or (Fun.frameTimerV2 / Fun.activeDanceDataV2.interval)

		if v5 and v5.parts then
			for k, part_ in pairs(v5.parts) do
				if not FunV2SkipParts[k] then
					local v7 = arg:FindFirstChild(k)
					if v7 and v7:IsA("BasePart") then
						local v8 = (v6 and v6.parts and v6.parts[k]) or part_
						pcall(function()
							v7.CFrame = cFrame * parseCFrameData(part_):Lerp(parseCFrameData(v8), alpha)
							v7.AssemblyLinearVelocity = Vector3.zero
						end)
					end
				end
			end
		end
	end)
end

Fun.refreshDanceV2List = function()
	Fun.currentDanceRawTableV2 = {}

	local ok, result = pcall(function()
		return game:HttpGet("https://raw.githubusercontent.com/dcus-official/PoopHub/refs/heads/main/Assets/Emote/List_Json.lua")
	end)

	if ok and result then
		local ok2, result2 = pcall(function()
			local chunk = loadstring(result)
			if chunk then
				return chunk()
			end
		end)
		if ok2 and type(result2) == "table" then
			for k, v4 in pairs(result2) do
				Fun.currentDanceRawTableV2[k] = v4
			end
		end
	end

	pcall(function()
		if isfolder and makefolder then
			if not isfolder("mdcp") then makefolder("mdcp") end
			if not isfolder("mdcp/emote") then makefolder("mdcp/emote") end
			
		end
		if listfiles and readfile then
			local files = listfiles("mdcp/emote")
			if type(files) == "table" then
				for _, v4 in ipairs(files) do
					if v4:match("%.dance$") then
						local match = v4:gsub("\\", "/"):match("([^/]+)%.dance$")
						if match then
							local ok3, result3 = pcall(function() return readfile(v4) end)
							if ok3 and result3 then
								Fun.currentDanceRawTableV2[match] = result3
							end
						end
					end
				end
			end
		end
	end)

	table.clear(Fun.danceListV2)
	for k in pairs(Fun.currentDanceRawTableV2) do
		table.insert(Fun.danceListV2, k)
	end
	table.sort(Fun.danceListV2)
	if #Fun.danceListV2 == 0 then
		table.insert(Fun.danceListV2, "No dances found")
	end
	return Fun.danceListV2
end

-- ============================================================
-- UI
-- ============================================================

-- ---------- Target タブ (Mode選択で設定が展開) ----------
do
    local function StopTargetAttackModes()
        if State.GrabKickOn then
            State.GrabKickOn = false
            if State.GrabTask then pcall(function() task.cancel(State.GrabTask) end) State.GrabTask=nil end
            GrabKickCleanup()
        end
        if State.GrabKickV2On then
            GKv2_Stop()
        end
        GKv2_StopLag()
        if State.RagdollKillActive then RagdollKill_Stop() end
        if State.RKv2Active then RKv2_Stop() end
        if State.NLKillActive then NLKill_Stop() end
        if State.BananaLooping then Banana_StopLoop() end
    end

    local TargetGroup = Tabs.Target:AddLeftGroupbox("ターゲット / Mode")

    local PlayerDropdown = TargetGroup:AddDropdown("TargetPlayer", {
        Text = "ターゲット",
        Default = "",
        Values = GetPlayerList(),
        Callback = function(Value)
            local plr = FindPlayerByDisplay(Value)
            State.TargetName = plr and plr.Name or nil
            State.TargetDisplay = Value
            pcall(function()
                if Options.BlobmanTargetPlayer then
                    Options.BlobmanTargetPlayer:SetValue(Value)
                end
            end)
        end,
    })

    TargetGroup:AddButton({
        Text = "プレイヤーリスト更新",
        Func = function()
            local list = GetPlayerList()
            PlayerDropdown:SetValues(list)
            pcall(function()
                if Options.BlobmanTargetPlayer then
                    Options.BlobmanTargetPlayer:SetValues(list)
                end
            end)
            Library:Notify({Title = "mdcp", Description = "プレイヤーリストを更新しました", Time = 2})
        end,
    })

    TargetGroup:AddDropdown("AttackModeDropdown", {
        Text = "Mode",
        Default = "Kick v1",
        Values = {"Kick v1", "Kick v2", "Ragdoll Kill", "Ragdoll Kill v2", "Kill"},
        Callback = function(Value)
            StopTargetAttackModes()
            Library:Notify({Title = "mdcp", Description = "Mode: " .. Value, Time = 2})
        end,
    })

    -- Kick v1 設定（Mode = Kick v1 のときだけ表示）
    local DepKickV1 = TargetGroup:AddDependencyBox()
    DepKickV1:SetupDependencies({
        { Options.AttackModeDropdown, "Kick v1" },
    })

    DepKickV1:AddToggle("GrabKickToggle", {
        Text = "Enable Kick v1",
        Default = false,
        Callback = function(on)
            if on then
                StopTargetAttackModes()
                State.GrabKickOn = true
                StartGrabKick()
                if State.UsePalette then StartPaletteLoop() end
            else
                State.GrabKickOn = false
                if State.GrabTask then pcall(function() task.cancel(State.GrabTask) end) State.GrabTask=nil end
                GrabKickCleanup()
            end
        end,
    })

    DepKickV1:AddToggle("UsePaletteToggle", {
        Text = "Use Palette",
        Default = true,
        Callback = function(v) State.UsePalette = v end,
    })

    DepKickV1:AddSlider("DistThreshold", {
        Text = "距離閾値",
        Min = 5, Max = 50, Default = 25, Rounding = 0,
        Callback = function(v) State.DistThreshold = v end,
    })

    DepKickV1:AddSlider("GrabKickOffsetY", {
        Text = "Offset Y",
        Min = -20, Max = 30, Default = 8, Rounding = 1,
        Callback = function(v) State.GrabKickOffsetY = v end,
    })

    -- Kick v2 設定（Mode = Kick v2 のときだけ表示）
    local DepKickV2 = TargetGroup:AddDependencyBox()
    DepKickV2:SetupDependencies({
        { Options.AttackModeDropdown, "Kick v2" },
    })

    DepKickV2:AddToggle("GrabKickV2Toggle", {
        Text = "Enable Kick v2",
        Default = false,
        Callback = function(on)
            if on then
                StopTargetAttackModes()
                State.GrabKickV2On = true
                GKv2_Start()
                if State.GrabKickV2UsePalette then GKv2_StartPalette() end
            else
                GKv2_Stop()
            end
        end,
    })

    DepKickV2:AddToggle("GKv2PaletteToggle", {
        Text = "Pallet Ragdoll",
        Default = true,
        Callback = function(v) State.GrabKickV2UsePalette = v end,
    })

    DepKickV2:AddToggle("GKv2LagToggle", {
        Text = "Lag Spam",
        Default = false,
        Callback = function(on)
            if on then GKv2_StartLag() else GKv2_StopLag() end
        end,
    })

    DepKickV2:AddSlider("GKv2Dist", {
        Text = "距離閾値",
        Min = 5, Max = 50, Default = 25, Rounding = 0,
        Callback = function(v) State.GrabKickV2Dist = v end,
    })

    -- Ragdoll Kill（Pencil）
    local DepKill = TargetGroup:AddDependencyBox()
    DepKill:SetupDependencies({
        { Options.AttackModeDropdown, "Ragdoll Kill" },
    })

    DepKill:AddToggle("RagdollKillToggle", {
        Text = "Enable Ragdoll Kill",
        Default = false,
        Callback = function(on)
            if on then
                StopTargetAttackModes()
                RagdollKill_Start()
            else
                RagdollKill_Stop()
            end
        end,
    })

    DepKill:AddToggle("BananaLoopToggle", {
        Text = "Loop Banana",
        Default = false,
        Callback = function(on)
            if on then
                StopTargetAttackModes()
                Banana_StartLoop()
            else
                Banana_StopLoop()
            end
        end,
    })

    -- Ragdoll Kill v2
    local DepKillV2 = TargetGroup:AddDependencyBox()
    DepKillV2:SetupDependencies({
        { Options.AttackModeDropdown, "Ragdoll Kill v2" },
    })

    DepKillV2:AddToggle("RagdollKillV2Toggle", {
        Text = "Enable Ragdoll Kill v2",
        Default = false,
        Callback = function(on)
            if on then
                StopTargetAttackModes()
                RKv2_Start()
            else
                RKv2_Stop()
            end
        end,
    })

    -- Kill
    local DepNLKill = TargetGroup:AddDependencyBox()
    DepNLKill:SetupDependencies({
        { Options.AttackModeDropdown, "Kill" },
    })

    DepNLKill:AddToggle("NLKillToggle", {
        Text = "Enable Kill",
        Default = false,
        Callback = function(on)
            if on then
                StopTargetAttackModes()
                NLKill_Start()
            else
                NLKill_Stop()
            end
        end,
    })
end

-- ---------- Blobman タブ (Mode選択で設定が展開) ----------
do
    local function StopBlobmanModes()
        if State.BlobKickActive then BlobKick_Stop() end
        if State.BlobKillActive then BlobKill_Stop() end
        if State.AutoSitBlobActive or AutoSit_Active then AutoSit_Stop() end
    end

    local BlobGroup = Tabs.Blobman:AddLeftGroupbox("Blobman / Mode")

    local BlobPlayerDropdown = BlobGroup:AddDropdown("BlobmanTargetPlayer", {
        Text = "ターゲット",
        Default = "",
        Values = GetPlayerList(),
        Callback = function(Value)
            local plr = FindPlayerByDisplay(Value)
            State.TargetName = plr and plr.Name or nil
            State.TargetDisplay = Value
            -- Targetタブ側のドロップダウンも同期（あれば）
            pcall(function()
                if Options.TargetPlayer then
                    Options.TargetPlayer:SetValue(Value)
                end
            end)
        end,
    })

    BlobGroup:AddButton({
        Text = "プレイヤーリスト更新",
        Func = function()
            local list = GetPlayerList()
            BlobPlayerDropdown:SetValues(list)
            pcall(function()
                if Options.TargetPlayer then
                    Options.TargetPlayer:SetValues(list)
                end
            end)
            Library:Notify({Title = "mdcp", Description = "プレイヤーリストを更新しました", Time = 2})
        end,
    })

    BlobGroup:AddDropdown("BlobmanModeDropdown", {
        Text = "Mode",
        Default = "Kick",
        Values = {"Kick", "Kill"},
        Callback = function(Value)
            StopBlobmanModes()
            Library:Notify({Title = "mdcp", Description = "Blobman Mode: " .. Value, Time = 2})
        end,
    })

    -- Kick 設定
    local DepBlobKick = BlobGroup:AddDependencyBox()
    DepBlobKick:SetupDependencies({
        { Options.BlobmanModeDropdown, "Kick" },
    })

    DepBlobKick:AddToggle("BlobKickToggle", {
        Text = "Enable Blob Kick",
        Default = false,
        Callback = function(on)
            if on then
                StopBlobmanModes()
                BlobKick_Start() -- 内部で自動乗車
            else
                BlobKick_Stop()
            end
        end,
    })

    -- Kill 設定 (NL Blob Kill)
    local DepBlobKill = BlobGroup:AddDependencyBox()
    DepBlobKill:SetupDependencies({
        { Options.BlobmanModeDropdown, "Kill" },
    })

    DepBlobKill:AddToggle("BlobKillToggle", {
        Text = "Enable Blob Kill",
        Default = false,
        Callback = function(on)
            if on then
                StopBlobmanModes()
                BlobKill_Start()
            else
                BlobKill_Stop()
            end
        end,
    })
end

-- ---------- Defense タブ ----------
do
    -- グループ（Tabbox非依存で確実に全アンチ表示）
    local MainDefenceTabbox = Tabs.Defense:AddLeftTabbox()
    local InvincibilityGroup = MainDefenceTabbox:AddTab("Main Anti's", "shield")

    -- Auto Reset (NL / Flying)
    do
        local AutoResetOn = true
        local GC = ReplicatedStorage:FindFirstChild("GameCorrectionEvents")
        local NotifyEv = GC and GC:FindFirstChild("GameCorrectionsNotify")
        if NotifyEv then
            NotifyEv.OnClientEvent:Connect(function(arg)
                if arg == "Flying" and AutoResetOn then
                    if MDCP_Notify then
                        MDCP_Notify("Auto Reset", "Auto Reset", 2, "Custom Notification")
                    else
                        pcall(function()
                            Library:Notify({ Title = "mdcp", Description = "Auto Reset", Time = 2 })
                        end)
                    end
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end)
                        pcall(function() hum.Health = 0 end)
                    end
                    -- also struggle if available
                    pcall(function()
                        local Struggle = ReplicatedStorage:FindFirstChild("CharacterEvents")
                        Struggle = Struggle and Struggle:FindFirstChild("Struggle")
                        if Struggle then Struggle:FireServer() end
                    end)
                end
            end)
        end
        InvincibilityGroup:AddToggle("AutoResetNL", {
            Text = "Auto Reset (Flying)",
            Default = true,
            Callback = function(on)
                AutoResetOn = on
            end,
        })
        -- ensure default ON at load
        task.defer(function()
            AutoResetOn = true
            pcall(function()
                if Toggles.AutoResetNL then Toggles.AutoResetNL:SetValue(true) end
            end)
        end)
    end

    local ConfigGroup = MainDefenceTabbox:AddTab("Config", "settings")
    local MiscellaneousGroup = Tabs.Defense:AddRightGroupbox("Miscellaneous", "boxes")

    -- Spray Follow（既存機能維持）
    local SprayGroup = Tabs.Defense:AddRightGroupbox("Spray Follow")
    SprayGroup:AddSlider("WD_OffsetX", {
        Text = "Offset X", Min = -20, Max = 20, Default = 0, Rounding = 1,
        Callback = function(v) State.WD_OffsetX = v end,
    })
    SprayGroup:AddSlider("WD_OffsetY", {
        Text = "Offset Y", Min = -20, Max = 20, Default = 0, Rounding = 1,
        Callback = function(v) State.WD_OffsetY = v end,
    })
    SprayGroup:AddSlider("WD_OffsetZ", {
        Text = "Offset Z", Min = -20, Max = 20, Default = 0, Rounding = 1,
        Callback = function(v) State.WD_OffsetZ = v end,
    })
    SprayGroup:AddToggle("WD_Active", {
        Text = "Spray Follow", Default = false,
        Callback = function(on)
            State.WD_Active = on
            if on then WD_Start() else WD_Stop() end
        end,
    })

    local GlobalEnv = (type(getgenv) == "function" and getgenv()) or _G
    GlobalEnv.Tabs = Tabs
    GlobalEnv.Options = Options
    GlobalEnv.Toggles = Toggles
    GlobalEnv.Library = Library
    GlobalEnv.Players = Players
    GlobalEnv.LocalPlayer = LocalPlayer
    GlobalEnv.UserInputService = UserInputService
    GlobalEnv.ContextActionService = game:GetService("ContextActionService")
    GlobalEnv.CAS = game:GetService("ContextActionService")
    GlobalEnv.RunService = RunService
    GlobalEnv.Workspace = Workspace
    GlobalEnv.ReplicatedStorage = ReplicatedStorage
    GlobalEnv.TweenService = game:GetService("TweenService")
    GlobalEnv.Debris = game:GetService("Debris")
    GlobalEnv.Stats = game:GetService("Stats")
    GlobalEnv.rs = ReplicatedStorage
    GlobalEnv.player = LocalPlayer
    GlobalEnv.InvincibilityGroup = InvincibilityGroup
    GlobalEnv.MiscellaneousGroup = MiscellaneousGroup
    GlobalEnv.ConfigGroup = ConfigGroup

    -- 直接実行（loadstring環境問題を回避）
    local function __RunFullDefence()
        local LocalPlayer = GlobalEnv.LocalPlayer
        local Players = GlobalEnv.Players
        local Workspace = GlobalEnv.Workspace
        local ReplicatedStorage = GlobalEnv.ReplicatedStorage
        local RunService = GlobalEnv.RunService
        local UserInputService = GlobalEnv.UserInputService
        local Library = GlobalEnv.Library
        local Options = GlobalEnv.Options
        local Toggles = GlobalEnv.Toggles
        local InvincibilityGroup = GlobalEnv.InvincibilityGroup
        local MiscellaneousGroup = GlobalEnv.MiscellaneousGroup
        local ConfigGroup = GlobalEnv.ConfigGroup
        local Tabs = GlobalEnv.Tabs
--defence tab
-- ============================================================
-- DEFENCE TAB
-- ============================================================
do
    local P = LocalPlayer
    local RS = ReplicatedStorage
    local WS = Workspace
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Debris = game:GetService("Debris")
    local Stats = game:GetService("Stats")

    local GE = RS:WaitForChild("GrabEvents")
    local CE = RS:WaitForChild("CharacterEvents")
    local MT = RS:WaitForChild("MenuToys")
    local PE = RS:WaitForChild("PlayerEvents")

    local SetNetOwner = GE:WaitForChild("SetNetworkOwner")
    local StruggleEvent = CE:WaitForChild("Struggle")
    local RagdollRemote = CE:WaitForChild("RagdollRemote")
    local SpawnToyRemote = MT:WaitForChild("SpawnToyRemoteFunction")
    local DestroyToy = MT:WaitForChild("DestroyToy")
    local StickyEvent = PE:WaitForChild("StickyPartEvent")

    function dhrp()
        local c = P.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end

    function dhum()
        local c = P.Character
        return c and c:FindFirstChildOfClass("Humanoid")
    end

    function stvel(hrp)
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end

    function getDistance(pos1, pos2)
        return (pos1 - pos2).Magnitude
    end

    function fireNetworkOwner(part)
        if part then
            pcall(function() SetNetOwner:FireServer(part, part.CFrame) end)
        end
    end

    function fireDestroyLine(part)
        if part then
            pcall(function() DestroyToy:FireServer(part) end)
        end
    end

    function spawnToy(name, cf, vec)
        local f = WS:FindFirstChild(P.Name .. "SpawnedInToys")
        if not f then return nil end

        local found
        local con
        con = f.ChildAdded:Connect(function(x)
            if x.Name == name then
                found = x
                if con then con:Disconnect() end
            end
        end)

        pcall(function() SpawnToyRemote:InvokeServer(name, cf, vec or Vector3.zero) end)

        local t = tick()
        while not found and tick() - t < 4 do
            RunService.Heartbeat:Wait()
        end

        if con then con:Disconnect() end
        return found
    end

    function toyFolder()
        return WS:FindFirstChild(P.Name .. "SpawnedInToys")
    end

    function checkNetworkOwner(part)
        local po = part:FindFirstChild("PartOwner")
        return po and po.Value == P.Name
    end

    local whitelistFriendsEnabled = false
    local MainProtection = InvincibilityGroup

    _G._DefDefence = {
        P = P,
        RS = RS,
        WS = WS,
        SetNetOwner = SetNetOwner,
        StruggleEvent = StruggleEvent,
        RagdollRemote = RagdollRemote,
        SpawnToyRemote = SpawnToyRemote,
        DestroyToy = DestroyToy,
        StickyEvent = StickyEvent,
        MainProtection = MainProtection,
        dhrp = dhrp,
        dhum = dhum,
        stvel = stvel,
        getDistance = getDistance,
        fireNetworkOwner = fireNetworkOwner,
        fireDestroyLine = fireDestroyLine,
        spawnToy = spawnToy,
        toyFolder = toyFolder,
        checkNetworkOwner = checkNetworkOwner,
        InvincibilityGroup = InvincibilityGroup,
        MainDefenceTabbox = MainDefenceTabbox,
        ConfigGroup = ConfigGroup,
        MiscellaneousGroup = MiscellaneousGroup,
    }
    pcall(function()
        GlobalEnv._DefDefence = _G._DefDefence
        GlobalEnv._DefDefenceConfigGroup = ConfigGroup
    end)
end

local function GetDefDefenceState()
    local state
    pcall(function()
        state = GlobalEnv._DefDefence
    end)
    if state then return state end
    return _G._DefDefence
end

local function GetDefDefenceConfigGroup()
    local state = GetDefDefenceState()
    local group = state and state.ConfigGroup
    if group then return group end
    local tabbox = state and state.MainDefenceTabbox
    if tabbox and tabbox.Tabs then
        group = tabbox.Tabs["Config"]
        if group then return group end
    end
    pcall(function()
        group = GlobalEnv._DefDefenceConfigGroup
    end)
    if group then return group end
    return ConfigGroup or InvincibilityGroup or nil
end
pcall(function()
    GlobalEnv.GetDefDefenceState = GetDefDefenceState
    GlobalEnv.GetDefDefenceConfigGroup = GetDefDefenceConfigGroup
end)

-- BLOCK 2: ANTI GRAB
do
    local E = GetDefDefenceState()
    if not E then return end
    local P = E.P
    local WS = E.WS
    local RS = E.RS
    local StruggleEvent = E.StruggleEvent
    local RagdollRemote = E.RagdollRemote
    local DestroyToy = E.DestroyToy
    local MainProtection = E.MainProtection
    local Players = game:GetService("Players")
    local ContextActionService = game:GetService("ContextActionService")
    local AntiGrabRunService = game:GetService("RunService")

    local antiGrabEnabled = false
    local antiGrabMode = "No Ragdoll"
    _G.__DefAntiGrabMode = _G.__DefAntiGrabMode or antiGrabMode

    function isHeld()
        local v = P:FindFirstChild("IsHeld")
        return v ~= nil and v.Value == true
    end

    -- ============================================================
    -- ANTI GRAB — SHARED HELPERS
    -- ============================================================
    function ownerIsSet(owner)
        if not owner or not owner:IsA("StringValue") then return false end
        local ok, value = pcall(function() return owner.Value end)
        return ok and type(value) == "string" and value ~= ""
    end

    -- true when ANY of our parts currently carries a non-empty PartOwner
    function headOwned(head)
        local char = head and head.Parent
        if not char then return false end
        for _, object in ipairs(char:GetDescendants()) do
            if object.Name == "PartOwner" and ownerIsSet(object) then
                return true
            end
        end
        return false
    end

    function characterIsGrabbed(char)
        if not char or char ~= P.Character then return false end
        return isHeld() or headOwned(char:FindFirstChild("Head"))
    end

    function antiGrabAlive(state, token, char)
        return state.active
            and state._token == token
            and P.Character == char
            and char.Parent ~= nil
    end

    function disconnectAntiGrabConnections(state)
        for _, connection in pairs(state.conns or {}) do
            pcall(function() connection:Disconnect() end)
        end
        state.conns = {}
    end

    function disableRagdoll(char)
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("BasePart") and v:FindFirstChild("BallSocketConstraint") and v.Name ~= "Head" then
                pcall(function() v.BallSocketConstraint.Enabled = false end)
                if v:FindFirstChild("RagdollLimbPart") then
                    pcall(function() v.RagdollLimbPart.WeldConstraint.Enabled = false end)
                end
            end
        end
    end

    function enableRagdoll(char)
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("BasePart") and v:FindFirstChild("BallSocketConstraint") and v.Name ~= "Head" then
                pcall(function() v.BallSocketConstraint.Enabled = true end)
                if v:FindFirstChild("RagdollLimbPart") then
                    pcall(function() v.RagdollLimbPart.WeldConstraint.Enabled = true end)
                end
            end
        end
    end

    -- restores HRP anchor / humanoid flags AND ragdoll joints (no lingering disabled limbs)
    function restoreAntiGrabCharacter(char)
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp then pcall(function() hrp.Anchored = false end) end
        if hum then
            pcall(function()
                hum.PlatformStand = false
                hum.AutoRotate = true
            end)
        end
        pcall(enableRagdoll, char)
    end

    function weldOn(w)
        if not w then return false end
        local ok, res = pcall(function()
            if w.Parent == nil then return false end
            return w.Enabled
        end)
        return ok and res or false
    end

    function destroyGrabLineRemote()
        local ge = RS:FindFirstChild("GrabEvents")
        return ge and ge:FindFirstChild("DestroyGrabLine")
    end

    function clearGrabLines()
        local remote = destroyGrabLineRemote()
        if not remote then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= P and player.Character then
                local character = player.Character
                local root = character:FindFirstChild("HumanoidRootPart")
                local head = character:FindFirstChild("Head")
                if root then pcall(function() remote:FireServer(root) end) end
                if head then pcall(function() remote:FireServer(head) end) end
                for _, object in ipairs(character:GetDescendants()) do
                    if object.Name == "PartOwner" then
                        pcall(function() remote:FireServer(object.Parent) end)
                    end
                end
            end
        end
    end

    function seatKind()
        local hum = P.Character and P.Character:FindFirstChildOfClass("Humanoid")
        if not (hum and hum.SeatPart) then return nil end
        local o = hum.SeatPart
        local seen = {}
        while o do
            if seen[o] then break end
            seen[o] = true
            if o.Name == "CreatureBlobman" then return "blob" end
            if o.Parent and o.Parent.Name == (P.Name .. "SpawnedInToys") then return "own" end
            o = o.Parent
        end
        return nil
    end

    function onBlobSeat()
        return seatKind() == "blob"
    end

    function onProtectedSeat()
        return seatKind() ~= nil
    end

    -- ============================================================
    -- ANTI GRAB MODE: NO RAGDOLL  (xocu)
    -- ============================================================
    local xocu = { conns = {}, proc = false, active = false }

    function xocuClean()
        xocu.active = false
        xocu.proc = false
        xocu._token = (xocu._token or 0) + 1
        disconnectAntiGrabConnections(xocu)
        restoreAntiGrabCharacter(P.Character)
    end

    function xocuApply(char)
        if not char then return end
        xocu._token = (xocu._token or 0) + 1
        local token = xocu._token
        disconnectAntiGrabConnections(xocu)
        xocu.active = true
        xocu.proc = false

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        if not (hrp and hum and head) then
            task.spawn(function()
                char:WaitForChild("HumanoidRootPart", 5)
                char:WaitForChild("Humanoid", 5)
                char:WaitForChild("Head", 5)
                if antiGrabAlive(xocu, token, char) then xocuApply(char) end
            end)
            return
        end

        if onBlobSeat() then
            pcall(enableRagdoll, char)
        elseif not onProtectedSeat() then
            pcall(disableRagdoll, char)
        end

        local function beginEscape()
            if xocu.proc then return end
            if not antiGrabAlive(xocu, token, char) then return end
            if not characterIsGrabbed(char) then return end
            xocu.proc = true
            task.spawn(function()
                pcall(function()
                    hrp.Anchored = true
                    while antiGrabAlive(xocu, token, char) and characterIsGrabbed(char) do
                        pcall(function()
                            StruggleEvent:FireServer(P)
                            RagdollRemote:FireServer(hrp, 0)
                            hum.PlatformStand = false
                            hum.Sit = false
                            hum.AutoRotate = true
                            if hum.MoveDirection.Magnitude > 0 then
                                hrp.CFrame = hrp.CFrame + hum.MoveDirection * (hum.WalkSpeed / 60)
                            end
                            if weldOn(hrp:FindFirstChild("WeldHRP")) then
                                head.CFrame = hrp.CFrame + Vector3.new(0, 1.35, 0)
                            end
                        end)
                        task.wait()
                    end
                end)
                pcall(function() hrp.Anchored = false end)
                if xocu._token == token then xocu.proc = false end
                if P.Character == char and not characterIsGrabbed(char) then
                    task.spawn(clearGrabLines)
                end
            end)
        end

        xocu.conns.Monitor = AntiGrabRunService.Heartbeat:Connect(function()
            if not antiGrabAlive(xocu, token, char) then return end
            local ragdolled = hum:FindFirstChild("Ragdolled")
            if ragdolled and ragdolled.Value and not onBlobSeat() then
                pcall(disableRagdoll, char)
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            end
            beginEscape()
        end)

        beginEscape()
    end

    function xocuStart()
        xocuClean()
        xocuApply(P.Character)
    end

    -- ============================================================
    -- ANTI GRAB MODE: RAGDOLL  (nrd)
    -- ============================================================
    local nrd = { conns = {}, proc = false, active = false, walk = false }

    function nrdDisableLimbs(char)
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("BasePart") and v:FindFirstChild("BallSocketConstraint") and v.Name ~= "Head" then
                pcall(function() v.BallSocketConstraint.Enabled = false end)
                if v:FindFirstChild("RagdollLimbPart") then
                    pcall(function() v.RagdollLimbPart.WeldConstraint.Enabled = false end)
                end
            end
        end
    end

    function nrdClean()
        nrd.active = false
        nrd.proc = false
        nrd.walk = false
        nrd._token = (nrd._token or 0) + 1
        disconnectAntiGrabConnections(nrd)
        restoreAntiGrabCharacter(P.Character)
    end

    function nrdApply(char)
        if not char then return end
        nrd._token = (nrd._token or 0) + 1
        local token = nrd._token
        disconnectAntiGrabConnections(nrd)
        nrd.active = true
        nrd.proc = false
        nrd.walk = false

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        if not (hrp and hum and head) then
            task.spawn(function()
                char:WaitForChild("HumanoidRootPart", 5)
                char:WaitForChild("Humanoid", 5)
                char:WaitForChild("Head", 5)
                if antiGrabAlive(nrd, token, char) then nrdApply(char) end
            end)
            return
        end

        if not onProtectedSeat() then
            nrdDisableLimbs(char)
        end

        local function beginEscape()
            if nrd.proc then return end
            if not antiGrabAlive(nrd, token, char) then return end
            if not characterIsGrabbed(char) then return end
            nrd.proc = true
            task.spawn(function()
                pcall(function()
                    hrp.Anchored = false
                    while antiGrabAlive(nrd, token, char) and characterIsGrabbed(char) do
                        pcall(function()
                            StruggleEvent:FireServer(P)
                            RagdollRemote:FireServer(hrp, 0)
                            hum.Sit = false
                            hum.AutoRotate = true
                            if hum.MoveDirection.Magnitude > 0 then
                                hrp.CFrame = hrp.CFrame + hum.MoveDirection * 0.43
                            end
                            if weldOn(hrp:FindFirstChild("WeldHRP")) then
                                head.CFrame = hrp.CFrame + Vector3.new(0, 1.35, 0)
                            end
                            local ragdolled = hum:FindFirstChild("Ragdolled")
                            if ragdolled and ragdolled.Value and not onBlobSeat() then
                                nrdDisableLimbs(char)
                            end
                        end)
                        task.wait()
                    end
                end)
                pcall(function() hrp.Anchored = false end)
                if nrd._token == token then nrd.proc = false end
                if P.Character == char and not characterIsGrabbed(char) then
                    task.spawn(clearGrabLines)
                end
            end)
        end

        nrd.conns.Monitor = AntiGrabRunService.Heartbeat:Connect(function()
            if not antiGrabAlive(nrd, token, char) then return end
            local ragdolled = hum:FindFirstChild("Ragdolled")
            if ragdolled and ragdolled.Value and not onBlobSeat() then
                nrdDisableLimbs(char)
            end
            beginEscape()
        end)

        beginEscape()
    end

    function nrdStart()
        nrdClean()
        nrdApply(P.Character)
    end

    -- ============================================================
    -- ANTI GRAB MODE: ESCAPE EVERYTHING  (cheeky)
    -- ============================================================
    local ACGE = false
    local cheekyThread = nil

    function checkgrab(obj)
        if obj:FindFirstAncestor('Plots') or obj:FindFirstAncestor('Slots') or obj:FindFirstAncestor('Map') then
            return
        end
        local prt = obj:FindFirstChild('SoundPart') or obj:FindFirstChild('HumanoidRootPart')
            or obj:FindFirstChild('Main') or obj:FindFirstChild('Balloon')
        if obj:FindFirstChild('Humanoid') then
            if not obj.Humanoid.SeatPart then
                if prt and prt.ReceiveAge ~= 0 then
                    return false
                end
            elseif obj.Humanoid.SeatPart.Parent then
                return checkgrab(obj.Humanoid.SeatPart.Parent)
            end
        elseif prt and prt.ReceiveAge ~= 0 then
            return false
        end
        return true
    end

    function cheekyAntiGrab()
        local model
        while ACGE do
            local char = P.Character
            if char and char:FindFirstChild('Humanoid') then
                for _, track in ipairs(char.Humanoid:GetPlayingAnimationTracks()) do
                    if track.Animation.AnimationId == 'rbxassetid://7047322890' then
                        track:Stop()
                    end
                end
            end

            local toyFolder = WS:FindFirstChild(P.Name .. 'SpawnedInToys')
            if toyFolder then
                model = toyFolder:FindFirstChild('FoodMayonnaise')
            end

            if char and not checkgrab(char) then
                local hum = char:FindFirstChild('Humanoid')
                local ragdolled = hum and hum:FindFirstChild('Ragdolled') and hum.Ragdolled.Value

                if ragdolled or not model then
                    pcall(function() StruggleEvent:FireServer(P) end)
                    if hum then
                        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                            if track.Animation.AnimationId == 'rbxassetid://7047322890' then
                                track:Stop()
                            end
                        end
                    end
                else
                    if model and model:FindFirstChild('HoldPart') then
                        local hold = model.HoldPart
                        if hold:FindFirstChild('HoldItemRemoteFunction') then
                            task.spawn(function()
                                pcall(function()
                                    hold.HoldItemRemoteFunction:InvokeServer(model, char)
                                end)
                            end)
                            pcall(function() DestroyToy:FireServer(model) end)
                            if hum then
                                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                                hum.AutoRotate = true
                                hum.Sit = false
                            end
                            pcall(function()
                                ContextActionService:UnbindAction('Escape')
                                ContextActionService:UnbindAction('JumpRemover')
                            end)
                        end
                    end
                end
            end

            task.wait()
        end
    end

    function cheekyCleanup()
        local toyFolder = WS:FindFirstChild(P.Name .. 'SpawnedInToys')
        if toyFolder then
            local model = toyFolder:FindFirstChild('FoodMayonnaise')
            if model then pcall(function() DestroyToy:FireServer(model) end) end
        end
        local char = P.Character
        if char then
            local hum = char:FindFirstChildOfClass('Humanoid')
            if hum then
                pcall(function() hum.Sit = false end)
                pcall(function() hum.PlatformStand = false end)
            end
        end
    end

    function cheekyStart()
        ACGE = true
        if cheekyThread then task.cancel(cheekyThread) end
        cheekyThread = task.spawn(cheekyAntiGrab)
    end

    function cheekyStop()
        ACGE = false
        if cheekyThread then
            task.cancel(cheekyThread)
            cheekyThread = nil
        end
        cheekyCleanup()
    end

    -- ============================================================
    -- MODE DISPATCH / UI
    -- ============================================================
    function stopAll()
        xocuClean()
        nrdClean()
        cheekyStop()
    end

    function startMode(m)
        if m == "No Ragdoll" then
            xocuStart()
        elseif m == "Ragdoll" then
            nrdStart()
        else
            cheekyStart()
        end
    end

    -- ══════════════════════════════════════════════════════════════
    -- UNIVERSAL SHIELD — constraint sweep + network-ownership reclaim
    -- Runs every Heartbeat when Anti Grab is enabled (both modes).
    -- Destroys any Weld / WeldConstraint / RopeConstraint /
    -- SpringConstraint that originates from another player's assembly.
    -- Also re-claims SetNetworkOwner on HRP every 60 frames.
    -- ══════════════════════════════════════════════════════════════

    local HOSTILE_CONSTRAINT_TYPES = {
        WeldConstraint = true,
        Weld = true,
        RopeConstraint = true,
        SpringConstraint = true,
        RodConstraint = true,
        BallSocketConstraint = true,
        HingeConstraint = true,
        AlignPosition = true,
        AlignOrientation = true,
        LinearVelocity = true,
        AngularVelocity = true,
        BodyVelocity = true,
        BodyAngularVelocity = true,
        BodyPosition = true,
        BodyGyro = true,
        BodyForce = true,
        VectorForce = true,
        Torque = true,
    }

    local universalShieldConn = nil
    local universalShieldFrame = 0

    local function isPartFromOtherPlayer(part)
        if not part or not part:IsA("BasePart") then return false end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= P and p.Character and part:IsDescendantOf(p.Character) then
                return true
            end
        end
        return false
    end

    local function sweepConstraints(character)
        for _, desc in ipairs(character:GetDescendants()) do
            if HOSTILE_CONSTRAINT_TYPES[desc.ClassName] then
                local shouldNuke = false
                pcall(function()
                    if desc:IsA("WeldConstraint") or desc:IsA("Weld") then
                        shouldNuke = isPartFromOtherPlayer(desc.Part0)
                                  or isPartFromOtherPlayer(desc.Part1)
                    elseif desc.ClassName == "RopeConstraint"
                        or desc.ClassName == "SpringConstraint"
                        or desc.ClassName == "RodConstraint"
                        or desc.ClassName == "BallSocketConstraint"
                        or desc.ClassName == "HingeConstraint" then
                        local a0 = desc.Attachment0 and desc.Attachment0.Parent
                        local a1 = desc.Attachment1 and desc.Attachment1.Parent
                        shouldNuke = isPartFromOtherPlayer(a0)
                                  or isPartFromOtherPlayer(a1)
                    else
                        -- Movers: nuke in NoRagdoll when parent is external.
                        if antiGrabMode == "No Ragdoll" then
                            shouldNuke = not desc.Parent:IsDescendantOf(character)
                        else
                            shouldNuke = isPartFromOtherPlayer(desc.Parent)
                        end
                    end
                end)
                if shouldNuke then
                    pcall(function() desc:Destroy() end)
                end
            end
        end
    end

    local function startUniversalShield()
        if universalShieldConn then return end
        universalShieldConn = AntiGrabRunService.Heartbeat:Connect(function()
            if not antiGrabEnabled then return end
            local character = P.Character
            if not character then return end

            -- Constraint sweep every frame.
            sweepConstraints(character)

            -- NoRagdoll extras: keep state from flipping, clamp fling velocity.
            if antiGrabMode == "No Ragdoll" then
                local hum = character:FindFirstChildOfClass("Humanoid")
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hum then
                    if hum.PlatformStand then hum.PlatformStand = false end
                    -- Do not cancel a legitimate CreatureBlobman seat.
                    -- The old No Ragdoll heartbeat forced Humanoid.Sit = false
                    -- every frame, which made it impossible to stay seated.
                    if hum.Sit and not onBlobSeat() then
                        hum.Sit = false
                    end
                end
                if hrp and hrp.AssemblyLinearVelocity.Magnitude > 220 then
                    pcall(function()
                        hrp.AssemblyLinearVelocity = Vector3.zero
                    end)
                end
            end

            -- Network ownership reclaim every 60 frames.
            universalShieldFrame = universalShieldFrame + 1
            if universalShieldFrame >= 60 then
                universalShieldFrame = 0
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pcall(function() SetNetOwner:FireServer(hrp, hrp.CFrame) end)
                end
            end
        end)
    end

    local function stopUniversalShield()
        if universalShieldConn then
            pcall(function() universalShieldConn:Disconnect() end)
            universalShieldConn = nil
        end
        universalShieldFrame = 0
    end

    -- ── UI ────────────────────────────────────────────────────────

    local function applyAntiGrabMode()
        antiGrabMode = _G.__DefAntiGrabMode or antiGrabMode
        if antiGrabEnabled then
            stopAll()
            startMode(antiGrabMode)
            stopUniversalShield()
            startUniversalShield()
        end
    end
    MainProtection:AddToggle("AntiGrabMaster", {
        Text = "Anti Grab",
        Default = false,
        Callback = function(Value)
            antiGrabEnabled = Value
            _G.__DefAntiGrabEnabled = Value
            stopAll()
            if Value then
                antiGrabMode = _G.__DefAntiGrabMode or antiGrabMode
                startMode(antiGrabMode)
                startUniversalShield()
            else
                stopUniversalShield()
            end
        end,
    })
    ConfigGroup:AddDropdown("AntiGrabMode", {
        Text = "Anti Grab Mode",
        Values = { "No Ragdoll", "Ragdoll", "Escape Everything" },
        Default = _G.__DefAntiGrabMode or "No Ragdoll",
        Callback = function(m)
            antiGrabMode = m
            _G.__DefAntiGrabMode = m
            applyAntiGrabMode()
        end,
    })

    -- Re-hook on every respawn: re-apply mode AND restart universal shield.
    P.CharacterAdded:Connect(function()
        task.wait(0.5)
        if not antiGrabEnabled then return end
        -- Re-apply mode-specific protection.
        if antiGrabMode == "No Ragdoll" then
            xocuClean()
            xocuApply(P.Character)
        elseif antiGrabMode == "Ragdoll" then
            nrdClean()
            nrdApply(P.Character)
        else
            cheekyStart()
        end
        -- Restart the universal shield for the new character.
        stopUniversalShield()
        startUniversalShield()
    end)

    pcall(function()
        Library:OnUnload(function()
            antiGrabEnabled = false
            stopAll()
            stopUniversalShield()
        end)
    end)
end


-- BLOCK 3: ANTI GUCCI
do
    local E = GetDefDefenceState()
    if not E then return end
    local P = E.P
    local WS = E.WS
    local SetNetOwner = E.SetNetOwner
    local RagdollRemote = E.RagdollRemote
    local SpawnToyRemote = E.SpawnToyRemote
    local DestroyToy = E.DestroyToy
    local MainProtection = E.MainProtection
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local ConfigGroup = GetDefDefenceConfigGroup()
    local CanSpawnToy = P:WaitForChild("CanSpawnToy")
    local MI_CARPETA = P.Name .. "SpawnedInToys"
    local UP_1E15 = Vector3.new(0, 1e15, 0)
    local ALTO = CFrame.new(0, 100000000, 10)
    local antiGucciMode = _G.__DefAntiGucciMode or "Blobman Gucci"
    -- Hard-reset stale Gucci workers from previous Def executions.
    _G.__DefAntiGucciEnabled = false
    _G.__DefGucciRuntimeToken = (_G.__DefGucciRuntimeToken or 0) + 1
    local gucciRuntimeToken = _G.__DefGucciRuntimeToken
    local antiGucciEnabled = false
    local antiGucciSession = 0
    local gucciRunning = false
    local gucciToy = nil
    local gucciCharConn = nil
    local gucciSeatConn = nil
    local gucciSeatFor = nil
    local gucciLastKnownPlayer = nil
    local gucciDestroyWatch = nil
    local gucciSafeCFrame = nil
    local gucciHum = nil
    local gucciRoot = nil
    local gucciInSeat = false
    local tractorGucciActive = false
    local tractorGucciRunning = false
    local autoGucciActiveTrain = false
    local antiGucciConnectionTrain = nil
    local trainJumpConnection = nil
    local trainCharacterConnection = nil
    local safePositionTrain = nil
    local restoreFramesTrain = 0

    _G.__DefAntiGucciMode = antiGucciMode
    _G.__DefAntiGucciEnabled = false

    local function getCharParts()
        local char = P.Character
        if not char then return nil, nil end
        return char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart")
    end

    local function disconnectGucciConnections()
        if gucciSeatConn then
            pcall(function() gucciSeatConn:Disconnect() end)
            gucciSeatConn = nil
        end
        gucciSeatFor = nil
        if gucciDestroyWatch then
            pcall(function() gucciDestroyWatch:Disconnect() end)
            gucciDestroyWatch = nil
        end
        if gucciCharConn then
            pcall(function() gucciCharConn:Disconnect() end)
            gucciCharConn = nil
        end
    end

    local function destroyGucciToy()
        if gucciToy and gucciToy.Parent and DestroyToy then
            pcall(function() DestroyToy:FireServer(gucciToy) end)
        end
        gucciToy = nil
    end

    local function safeGetDescendants(instance)
        if typeof(instance) ~= "Instance" then return {} end
        local ok, result = pcall(function() return instance:GetDescendants() end)
        if ok and type(result) == "table" then return result end
        return {}
    end

    local function watchGucciToy(toy)
        if not toy then return end
        if gucciDestroyWatch then
            pcall(function() gucciDestroyWatch:Disconnect() end)
        end
        gucciLastKnownPlayer = nil
        gucciDestroyWatch = toy.AncestryChanged:Connect(function(_, parent)
            if parent ~= nil or not antiGucciEnabled or gucciToy ~= toy then return end
            local remover = gucciLastKnownPlayer
            pcall(function()
                local seat = toy:FindFirstChild("VehicleSeat", true)
                if not remover and seat and seat.Occupant and seat.Occupant.Parent then
                    local player = Players:GetPlayerFromCharacter(seat.Occupant.Parent)
                    if player and player ~= P then remover = player end
                end
                if not remover then
                    for _, obj in ipairs(safeGetDescendants(toy)) do
                        if obj.Name == "PartOwner" and obj:IsA("StringValue") then
                            local player = Players:FindFirstChild(obj.Value)
                            if player and player ~= P then
                                remover = player
                                break
                            end
                        end
                    end
                end
            end)
            if remover then
                _G.__DefNotify("You're Gucci Has been removed by " .. remover.DisplayName .. " (" .. remover.Name .. ")", "gucci_destroyed", 5, "GucciDestroyed")
            else
                _G.__DefNotify("You're Gucci Has been removed", "gucci_destroyed", 5, "GucciDestroyed")
            end
            gucciToy = nil
            gucciInSeat = false
        end)
    end

    local function spawnSelectedGucci(toyName, root)
        if not antiGucciEnabled or not root or _G.__DefGucciRuntimeToken ~= gucciRuntimeToken then return end
        local ok, allowed = pcall(function() return CanSpawnToy.Value end)
        if not ok or not allowed or not SpawnToyRemote then return end
        pcall(function()
            SpawnToyRemote:InvokeServer(toyName, root.CFrame * ALTO, Vector3.zero)
        end)
    end

    local function prepareGucciToy(toy, hide)
        if not toy or not toy.Parent then return false end
        local descendants = {}
        local ok = pcall(function()
            descendants = safeGetDescendants(toy)
        end)
        if not ok then return false end
        for _, part in ipairs(descendants) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part.AssemblyAngularVelocity = Vector3.zero
                if hide then
                    part.Transparency = 1
                end
            end
        end
        return true
    end

    local function runGucciToy(Session, toyName, hide)
        if gucciRunning then return end
        gucciRunning = true
        local toyAliveSince = 0
        local guccion = false
        local savedCFrame = nil
        local savedVelocity = nil
        while antiGucciEnabled and Session == antiGucciSession and _G.__DefGucciRuntimeToken == gucciRuntimeToken do
            local hum, root = getCharParts()
            gucciHum, gucciRoot = hum, root
            if not hum or not root or not root.Parent then
                task.wait(0.1)
                continue
            end
            if not savedCFrame or not hum.SeatPart then
                savedCFrame = root.CFrame
                savedVelocity = root.AssemblyLinearVelocity
            end
            local folder = WS:FindFirstChild(MI_CARPETA)
            local toy = gucciToy
            if not toy or not toy.Parent then
                toy = folder and folder:FindFirstChild(toyName)
                gucciToy = toy
                gucciInSeat = false
                guccion = false
                toyAliveSince = toy and tick() or 0
                if toy then watchGucciToy(toy) end
            end
            if not toy then
                if tick() - toyAliveSince > 0.15 then
                    spawnSelectedGucci(toyName, root)
                    toyAliveSince = tick()
                end
                task.wait(0.08)
                continue
            end
            local seat = toy:FindFirstChild("VehicleSeat", true) or toy:FindFirstChildWhichIsA("VehicleSeat", true)
            local toyRoot = toy:FindFirstChild("HumanoidRootPart", true) or toy:FindFirstChild("SoundPart", true)
            if not seat or not toyRoot or not seat.Parent or not toyRoot.Parent then
                if tick() - toyAliveSince >= 0.75 then
                    destroyGucciToy()
                    gucciInSeat = false
                    guccion = false
                    toyAliveSince = 0
                end
                task.wait(0.05)
                continue
            end
            if gucciSeatFor ~= seat then
                if gucciSeatConn then pcall(function() gucciSeatConn:Disconnect() end) end
                gucciSeatFor = seat
                gucciSeatConn = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
                    if not antiGucciEnabled or Session ~= antiGucciSession then return end
                    local occupant = seat.Occupant
                    if occupant and occupant ~= hum then
                        destroyGucciToy()
                        gucciInSeat = false
                        guccion = false
                    end
                end)
            end
            if seat.Occupant and seat.Occupant ~= hum then
                destroyGucciToy()
                gucciInSeat = false
                guccion = false
                task.wait(0.1)
                continue
            end
            for _, obj in ipairs(safeGetDescendants(toy)) do
                if obj:IsA("BasePart") then
                    obj.CanCollide = false
                    obj.CanTouch = false
                    obj.CanQuery = false
                    if hide then obj.Transparency = 1 end
                end
            end
            pcall(function() seat.Parent = nil; seat.Parent = toy end)
            if not hum.SeatPart then
                hum.Sit = false
                if not hide then
                    seat.CFrame = ALTO
                end
                root.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
                seat:Sit(hum)
                if RagdollRemote then RagdollRemote:FireServer(root, 0.016) end
                task.wait()
            end
            if seat.Occupant == hum or hum.SeatPart == seat then
                gucciInSeat = true
                guccion = true
                if not savedCFrame then savedCFrame = root.CFrame end
                if RagdollRemote then pcall(function() RagdollRemote:FireServer(root, 0.016) end) end
                if toyRoot:IsA("BasePart") then
                    pcall(function()
                        toyRoot.AssemblyLinearVelocity = UP_1E15
                        toyRoot.AssemblyAngularVelocity = Vector3.zero
                    end)
                end
            else
                gucciInSeat = false
                guccion = false
            end
            if guccion then
                pcall(function()
                    root.CFrame = savedCFrame
                    if savedVelocity then root.AssemblyLinearVelocity = savedVelocity end
                end)
            end
            if not toy.Parent then
                gucciToy = nil
                gucciInSeat = false
                guccion = false
            end
            task.wait()
        end
        gucciRunning = false
    end

    local function stopGucciCore()
        antiGucciSession = antiGucciSession + 1
        gucciRunning = false
        gucciInSeat = false
        disconnectGucciConnections()
        destroyGucciToy()
        gucciSafeCFrame = nil
        gucciHum = nil
        gucciRoot = nil
        local hum = P.Character and P.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Sit = false
            hum.PlatformStand = false
        end
    end

    local function startSelectedGucci()
        stopGucciCore()
        local Session = antiGucciSession
        if not antiGucciEnabled then return end
        if antiGucciMode == "Blobman Gucci" then
            task.spawn(function() runGucciToy(Session, "CreatureBlobman", false) end)
        elseif antiGucciMode == "Tractor Gucci (Invisible)" then
            tractorGucciActive = true
            task.spawn(function()
                runGucciToy(Session, "TractorGreen", true)
            end)
        end
    end

    local function startAntiGucciTrain()
        if not antiGucciEnabled or antiGucciMode ~= "Train Gucci (Invisible)" then return end
        local character = P.Character or P.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
        local rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
        if not humanoid or not rootPart then return end
        local map = WS:FindFirstChild("Map")
        local folder = map and map:FindFirstChild("AlwaysHereTweenedObjects")
        local train = folder and folder:FindFirstChild("Train")
        local seat = nil
        if train then
            for _, d in ipairs(train:GetDescendants()) do
                if d:IsA("Seat") or d:IsA("VehicleSeat") then seat = d break end
            end
        end
        if not seat then return end
        safePositionTrain = rootPart.Position
        restoreFramesTrain = 15
        if trainJumpConnection then pcall(function() trainJumpConnection:Disconnect() end) end
        trainJumpConnection = humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
            if not autoGucciActiveTrain then return end
            if humanoid.Jump and humanoid.Sit then
                restoreFramesTrain = 15
                safePositionTrain = rootPart.Position
            end
        end)
        pcall(function()
            rootPart.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
            seat:Sit(humanoid)
            if RagdollRemote then RagdollRemote:FireServer(rootPart, 0) end
        end)
        if antiGucciConnectionTrain then pcall(function() antiGucciConnectionTrain:Disconnect() end) end
        antiGucciConnectionTrain = RunService.Heartbeat:Connect(function()
            if not autoGucciActiveTrain or not rootPart.Parent or not humanoid.Parent then return end
            pcall(function()
                if RagdollRemote then RagdollRemote:FireServer(rootPart, 0) end
                if restoreFramesTrain > 0 and safePositionTrain then
                    rootPart.CFrame = CFrame.new(safePositionTrain)
                    restoreFramesTrain = restoreFramesTrain - 1
                end
            end)
        end)
    end

    local function stopAntiGucciTrain()
        autoGucciActiveTrain = false
        if antiGucciConnectionTrain then antiGucciConnectionTrain:Disconnect(); antiGucciConnectionTrain = nil end
        if trainJumpConnection then trainJumpConnection:Disconnect(); trainJumpConnection = nil end
        restoreFramesTrain = 0
    end

    trainCharacterConnection = P.CharacterAdded:Connect(function()
        if autoGucciActiveTrain then
            task.wait(0.5)
            if autoGucciActiveTrain then startAntiGucciTrain() end
        elseif antiGucciEnabled and (antiGucciMode == "Blobman Gucci" or antiGucciMode == "Tractor Gucci (Invisible)") then
            task.wait(0.5)
            if antiGucciEnabled then startSelectedGucci() end
        end
    end)

    local function applyAntiGucciMode()
        antiGucciMode = _G.__DefAntiGucciMode or antiGucciMode
        if not antiGucciEnabled then return end
        stopAntiGucciTrain()
        stopGucciCore()
        tractorGucciActive = false
        if antiGucciMode == "Blobman Gucci" then
            task.spawn(function()
                local Session = antiGucciSession
                runGucciToy(Session, "CreatureBlobman", false)
            end)
        elseif antiGucciMode == "Tractor Gucci (Invisible)" then
            tractorGucciActive = true
            task.spawn(function()
                local Session = antiGucciSession
                runGucciToy(Session, "TractorGreen", true)
            end)
        elseif antiGucciMode == "Train Gucci (Invisible)" then
            autoGucciActiveTrain = true
            startAntiGucciTrain()
        end
    end

    ConfigGroup:AddDropdown("AntiGucciMode", {
        Text = "Auto Gucci Method",
        Values = {"Blobman Gucci", "Tractor Gucci (Invisible)", "Train Gucci (Invisible)"},
        Default = _G.__DefAntiGucciMode or "Blobman Gucci",
        Multi = false,
        Callback = function(Value)
            if not Value then return end
            antiGucciMode = Value
            _G.__DefAntiGucciMode = Value
            if antiGucciEnabled then
                applyAntiGucciMode()
            end
        end,
    })

    local antiGucciToggle = MainProtection:AddToggle("AntiGucci", {
        Text = "Auto Gucci",
        Default = false,
        Callback = function(v)
            antiGucciEnabled = v
            _G.__DefAntiGucciEnabled = v
            antiGucciMode = _G.__DefAntiGucciMode or antiGucciMode
            if not v then
                tractorGucciActive = false
                autoGucciActiveTrain = false
                stopAntiGucciTrain()
                stopGucciCore()
                return
            end
            applyAntiGucciMode()
        end
    })

    -- Auto Gucci must never start merely because a previous script execution left a global behind.
    antiGucciEnabled = false
    _G.__DefAntiGucciEnabled = false
    stopGucciCore()
    stopAntiGucciTrain()
end

-- BLOCK 4: ANTI EXPLODE
do
    local E = GetDefDefenceState()
    if not E then return end
    local P = E.P
    local WS = E.WS
    local MainProtection = E.MainProtection
    local RunService = game:GetService("RunService")
    local antiExplodeLoop = nil

    local AntiExplodeEnabled = false
    local AntiExplodeConn = nil
    local function startAntiExplode()
        AntiExplodeEnabled = true
        if AntiExplodeConn then return end
        AntiExplodeConn = Workspace.ChildAdded:Connect(function(child)
            if not AntiExplodeEnabled then return end
            if child.Name ~= "Part" or not child:IsA("BasePart") then return end
            local char = LocalPlayer.Character or P.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then return end
            if (child.Position - hrp.Position).Magnitude <= 20 then
                pcall(function()
                    hrp.Anchored = true
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    task.wait()
                    hrp.Anchored = false
                end)
            end
        end)
    end
    local function stopAntiExplode()
        AntiExplodeEnabled = false
        if AntiExplodeConn then pcall(function() AntiExplodeConn:Disconnect() end) AntiExplodeConn = nil end
    end
    MainProtection:AddToggle("AntiExplode", {
        Text = "Anti Explode",
        Default = false,
        Callback = function(Value)
            if Value then startAntiExplode() else stopAntiExplode() end
        end,
    })

    task.defer(function()
        if Toggles.AntiExplode and Toggles.AntiExplode.Value then startAntiExplode() end
    end)
end

-- BLOCK 5: ANTI BURN / PAINT / VOID / BANANA / TOUCH KILL
do
    local E = GetDefDefenceState()
    if not E then return end
    local P = E.P
    local WS = E.WS
    local RS = E.RS
    local RagdollRemote = E.RagdollRemote
    local MainProtection = E.MainProtection
    local dhrp = E.dhrp
    local dhum = E.dhum
    local Toggles = Toggles
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local ConfigGroup = GetDefDefenceConfigGroup()

    -- ANTI INPUT: Def food/hold method
    local AntiInputToyList = {
        Coconut = "FoodCoconut", Banana = "FoodBanana", Fries = "FoodFrenchFries", MeatStick = "FoodMeatStick",
        Poop = "PoopPile", Donut = "FoodDonut", Cake = "FoodCakePink", Burger = "FoodHamburger",
        Pizza = "FoodPizzaCheese", Hotdog = "FoodHotdog", Mushroom = "FoodMushroomPoison", Banjo = "InstrumentGuitarBanjo",
        Violin = "InstrumentGuitarViolin", Ukulele = "InstrumentGuitarUkulele", Sax = "InstrumentWoodwindSaxophone",
        Vuvuzela = "InstrumentBrassVuvuzela", Bongos = "InstrumentDrumBongos", Mic = "InstrumentVoiceMicrophone",
        Pepperoni = "FoodPizzaPepperoni", Piano = "InstrumentPianoMelodica", Bread = "FoodBread", Egg = "FoodDippyEgg",
        Mayo = "FoodMayonnaise", WhiteMug = "CupMugWhite", Ocarina = "InstrumentWoodwindOcarina", SparklePoop = "PoopPileSparkle",
        BrownMug = "CupMugBrown", Trumpet = "InstrumentBrassTrumpet", Snare = "InstrumentDrumSnare", Lyre = "InstrumentGuitarLyre",
    }
    local AntiInputToyValues = {}
    for Name in pairs(AntiInputToyList) do table.insert(AntiInputToyValues, Name) end
    table.sort(AntiInputToyValues)
    local AntiInputSelectedToy = AntiInputToyList.Burger
    local AntiInputHoldDuration = 0.05
    _G.__DefAntiInputToy = _G.__DefAntiInputToy or AntiInputSelectedToy
    _G.__DefAntiInputHold = _G.__DefAntiInputHold or AntiInputHoldDuration
    ConfigGroup:AddDropdown("AntiInputFood", {
        Text = "Anti - Network ownership Food",
        Values = AntiInputToyValues,
        Default = _G.__DefAntiInputFoodName or "Burger",
        Multi = false,
        Searchable = true,
        ValueImages = {
            Coconut = "rbxassetid://133875991045577",
            Banana = "rbxassetid://75484207768793",
            Fries = "rbxassetid://94745609579445",
            MeatStick = "rbxassetid://119912069009462",
            Donut = "rbxassetid://121685717166327",
            Cake = "rbxassetid://135967824239828",
            Burger = "rbxassetid://107005089698340",
            Pizza = "rbxassetid://106931956314027",
            Hotdog = "rbxassetid://106249136532377",
            Mushroom = "rbxassetid://103335679226894",
            Pepperoni = "rbxassetid://94216796644855",
            Bread = "rbxassetid://73483588123877",
            Egg = "rbxassetid://89197648899618",
            Mayo = "rbxassetid://87917161433070",
        },
        Callback = function(Value)
            AntiInputSelectedToy = AntiInputToyList[Value] or AntiInputToyList.Burger
            _G.__DefAntiInputToy = AntiInputSelectedToy
            _G.__DefAntiInputFoodName = Value
            if Toggles.AntiInput and Toggles.AntiInput.Value then
                stopAntiInput()
                startAntiInput()
            end
        end,
    })
    ConfigGroup:AddSlider("AntiInputHoldDuration", {
        Text = "Hold Duration",
        Default = 0.05,
        Min = 0.01,
        Max = 0.3,
        Rounding = 2,
        Compact = true,
        Callback = function(Value)
            AntiInputHoldDuration = Value
            _G.__DefAntiInputHold = Value
        end,
    })
    local antiInputThread = nil
    local function stopAntiInput()
        if antiInputThread then
            pcall(function() task.cancel(antiInputThread) end)
            antiInputThread = nil
        end
        local inv = WS:FindFirstChild(P.Name .. "SpawnedInToys")
        local item = inv and inv:FindFirstChild(AntiInputSelectedToy)
        if item then pcall(function() E.DestroyToy:FireServer(item) end) end
        if inv and inv:FindFirstChild("antiinputfood") then
            pcall(function() E.DestroyToy:FireServer(inv.antiinputfood) end)
        end
    end
    local function startAntiInput()
        stopAntiInput()
        antiInputThread = task.spawn(function()
            while Toggles.AntiInput and Toggles.AntiInput.Value do
                local char = P.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local inv = WS:FindFirstChild(P.Name .. "SpawnedInToys")
                    local item = inv and inv:FindFirstChild(AntiInputSelectedToy)
                    if not item then
                        pcall(function()
                            E.SpawnToyRemote:InvokeServer(AntiInputSelectedToy, hrp.CFrame * CFrame.new(0, -12, 0), Vector3.zero)
                        end)
                    else
                        local holdPart = item:FindFirstChild("HoldPart")
                        if holdPart then
                            for _, part in ipairs(item:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                    part.CanQuery = false
                                    part.CanTouch = false
                                    part.Massless = true
                                end
                            end
                            pcall(function() holdPart.HoldItemRemoteFunction:InvokeServer(item, char) end)
                            task.wait(AntiInputHoldDuration)
                            pcall(function() holdPart.DropItemRemoteFunction:InvokeServer(item, CFrame.new(0, 5000, 0), Vector3.zero) end)
                        end
                    end
                end
                task.wait(AntiInputHoldDuration)
            end
        end)
    end
    MainProtection:AddToggle("AntiInput", {
        Text = "Anti - Network ownership",
        Default = false,
        Callback = function(Value)
            if Value then
                AntiInputSelectedToy = _G.__DefAntiInputToy or AntiInputSelectedToy
                AntiInputHoldDuration = _G.__DefAntiInputHold or AntiInputHoldDuration
                startAntiInput()
            else
                stopAntiInput()
            end
        end,
    })

    -- Banjo Anti-Input (Ownership)
    local BanjoCfg = {
        targetToy = "InstrumentGuitarBanjo",
        loopActive = false,
        runLoop = nil,
        respawnHandler = nil,
    }
    local function Banjo_Start()
        if BanjoCfg.loopActive then return end
        BanjoCfg.loopActive = true
        if not BanjoCfg.runLoop then
            BanjoCfg.runLoop = RunService.Heartbeat:Connect(function()
                if not BanjoCfg.loopActive then return end
                local toyFolder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                if not toyFolder then return end
                local toy = toyFolder:FindFirstChild(BanjoCfg.targetToy)
                if not toy then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local spawnCF = hrp and hrp.CFrame or CFrame.new(0, 5, 0)
                    pcall(function()
                        SpawnRemote:InvokeServer(BanjoCfg.targetToy, spawnCF, Vector3.new(0, 90, 0))
                    end)
                    for _ = 1, 20 do
                        toy = toyFolder:FindFirstChild(BanjoCfg.targetToy)
                        if toy then break end
                        task.wait()
                    end
                end
                if toy then
                    local char = LocalPlayer.Character
                    local head = char and char:FindFirstChild("Head")
                    local holdPart = toy:FindFirstChild("HoldPart")
                    if head and holdPart then
                        local holdRemote = holdPart:FindFirstChild("HoldItemRemoteFunction")
                        local dropRemote = holdPart:FindFirstChild("DropItemRemoteFunction")
                        if holdRemote and dropRemote then
                            local dropPos = head.CFrame * CFrame.new(0, 3, 0)
                            task.spawn(function()
                                pcall(function()
                                    holdRemote:InvokeServer(toy, char)
                                    dropRemote:InvokeServer(toy, dropPos, dropPos)
                                end)
                            end)
                        end
                    end
                end
            end)
        end
        if not BanjoCfg.respawnHandler then
            BanjoCfg.respawnHandler = LocalPlayer.CharacterAdded:Connect(function()
                if not BanjoCfg.loopActive then return end
                task.wait(0.5)
                if BanjoCfg.runLoop then pcall(function() BanjoCfg.runLoop:Disconnect() end) BanjoCfg.runLoop = nil end
                local cFolder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                local cToy = cFolder and cFolder:FindFirstChild(BanjoCfg.targetToy)
                if cToy then pcall(function() DestroyToy:FireServer(cToy) end) end
                BanjoCfg.loopActive = false
                task.wait(0.1)
                Banjo_Start()
            end)
        end
    end
    local function Banjo_Stop()
        BanjoCfg.loopActive = false
        if BanjoCfg.runLoop then pcall(function() BanjoCfg.runLoop:Disconnect() end) BanjoCfg.runLoop = nil end
        local cFolder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
        local cToy = cFolder and cFolder:FindFirstChild(BanjoCfg.targetToy)
        if cToy then pcall(function() DestroyToy:FireServer(cToy) end) end
        if BanjoCfg.respawnHandler then pcall(function() BanjoCfg.respawnHandler:Disconnect() end) BanjoCfg.respawnHandler = nil end
    end
    MainProtection:AddToggle("BanjoAntiInput", {
        Text = "Anti-Input (Banjo)",
        Default = false,
        Callback = function(on)
            if on then Banjo_Start() else Banjo_Stop() end
        end,
    })


    -- ECHO ANTI BURN
    local antiBurnConnections = {}
    local antiBurnActive = false
    local AntiBurnConn = nil
    local function stopAntiBurn()
        if AntiBurnConn then pcall(function() AntiBurnConn:Disconnect() end) AntiBurnConn = nil end
    end
    local function startAntiBurn()
        stopAntiBurn()
        local plotBarrier = nil
        pcall(function()
            plotBarrier = Workspace.Plots.Plot3.Barrier.PlotBarrier
        end)
        if not plotBarrier then
            pcall(function()
                for _, plot in ipairs(Workspace.Plots:GetChildren()) do
                    local b = plot:FindFirstChild("Barrier")
                    local pb = b and b:FindFirstChild("PlotBarrier")
                    if pb then plotBarrier = pb break end
                end
            end)
        end
        if not plotBarrier then
            Library:Notify({ Title = "mdcp", Description = "PlotBarrier not found", Time = 2 })
            return
        end
        local savedCF = plotBarrier.CFrame
        AntiBurnConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character or P.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local fpp = hrp and hrp:FindFirstChild("FirePlayerPart")
            local canBurn = fpp and fpp:FindFirstChild("CanBurn")
            if canBurn and canBurn.Value then
                pcall(function()
                    plotBarrier.CFrame = hrp.CFrame
                    task.wait()
                    plotBarrier.CFrame = savedCF
                end)
            end
        end)
    end
    MainProtection:AddToggle("AntiBurn", {
        Text = "Anti Burn",
        Default = false,
        Callback = function(Value)
            if Value then startAntiBurn() else stopAntiBurn() end
        end,
    })

    task.defer(function()
        if Toggles.AntiBurn and Toggles.AntiBurn.Value then
            antiBurnActive = true
            if P.Character then setupAntiBurn(P.Character) end
            table.insert(antiBurnConnections, P.CharacterAdded:Connect(function(char)
                task.wait(0.2)
                if antiBurnActive then setupAntiBurn(char) end
            end))
        end
    end)

    local acidSavedPositions = {}
    local paintPartsBackup = {}
    local paintConnections = {}

    local function restorePaintParts()
        for _, data in pairs(paintPartsBackup) do
            if data.clone and data.parent then
                pcall(function() data.clone.Parent = data.parent end)
            end
        end
        paintPartsBackup = {}
    end
    local function disconnectPaintWatchers()
        for _, conn in ipairs(paintConnections) do
            pcall(function() conn:Disconnect() end)
        end
        paintConnections = {}
    end
    local function deleteAllPaintParts()
        for _, obj in ipairs(WS:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name == "PaintPlayerPart" then
                pcall(function()
                    local clone = obj:Clone()
                    clone.Archivable = true
                    paintPartsBackup[obj:GetDebugId()] = {clone = clone, parent = obj.Parent}
                    obj:Destroy()
                end)
            end
        end
    end
    local function setPoisonPartsHidden()
        pcall(function()
            local part1 = WS.Map.FactoryIsland.PoisonContainer.PoisonHurtPart
            if part1 then
                acidSavedPositions.part1 = acidSavedPositions.part1 or part1.CFrame
                part1.CFrame = CFrame.new(0, -1E4, 0)
            end
        end)
        pcall(function()
            local children = WS.Map.FactoryIsland:GetChildren()
            if children and #children > 6 then
                local part2 = children[6]:FindFirstChild("PoisonHurtPart")
                if part2 then
                    acidSavedPositions.part2 = acidSavedPositions.part2 or part2.CFrame
                    part2.CFrame = CFrame.new(0, -1E4, 0)
                end
            end
        end)
        pcall(function()
            local part3 = WS.Map.Hole.PoisonBigHole.PoisonHurtPart
            if part3 then
                acidSavedPositions.part3 = acidSavedPositions.part3 or part3.CFrame
                part3.CFrame = CFrame.new(0, -1E4, 0)
            end
        end)
        pcall(function()
            local part4 = WS.Map.Hole.PoisonSmallHole.PoisonHurtPart
            if part4 then
                acidSavedPositions.part4 = acidSavedPositions.part4 or part4.CFrame
                part4.CFrame = CFrame.new(0, -1E4, 0)
            end
        end)
    end
    local function restorePoisonParts()
        pcall(function()
            if acidSavedPositions.part1 then WS.Map.FactoryIsland.PoisonContainer.PoisonHurtPart.CFrame = acidSavedPositions.part1 end
        end)
        pcall(function()
            local children = WS.Map.FactoryIsland:GetChildren()
            if children and #children > 6 then
                local part2 = children[6]:FindFirstChild("PoisonHurtPart")
                if part2 and acidSavedPositions.part2 then part2.CFrame = acidSavedPositions.part2 end
            end
        end)
        pcall(function()
            if acidSavedPositions.part3 then WS.Map.Hole.PoisonBigHole.PoisonHurtPart.CFrame = acidSavedPositions.part3 end
        end)
        pcall(function()
            if acidSavedPositions.part4 then WS.Map.Hole.PoisonSmallHole.PoisonHurtPart.CFrame = acidSavedPositions.part4 end
        end)
        acidSavedPositions = {}
    end

    MainProtection:AddToggle("AntiPaintPoison", {
        Text = "Anti Paint & Poison",
        Default = false,
        Callback = function(Value)
            disconnectPaintWatchers()
            if Value then
                setPoisonPartsHidden()
                deleteAllPaintParts()
                table.insert(paintConnections, WS.DescendantAdded:Connect(function(obj)
                    if obj:IsA("BasePart") and obj.Name == "PaintPlayerPart" then
                        task.defer(function()
                            if obj and obj.Parent then
                                pcall(function()
                                    local clone = obj:Clone()
                                    clone.Archivable = true
                                    paintPartsBackup[obj:GetDebugId()] = {clone = clone, parent = obj.Parent}
                                    obj:Destroy()
                                end)
                            end
                        end)
                    end
                end))
            else
                restorePaintParts()
                restorePoisonParts()
            end
        end,
    })

    local AntiStickyActive = false
    local StickyScriptName = "StickyPartsTouchDetection"
    local function DisableStickyScripts()
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if not playerScripts then return end
        for _, scriptObject in ipairs(playerScripts:GetChildren()) do
            if scriptObject.Name == StickyScriptName then
                pcall(function() scriptObject.Disabled = true end)
            end
        end
    end
    local function RemoveStickyScripts()
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if not playerScripts then return end
        for _, scriptObject in ipairs(playerScripts:GetChildren()) do
            if scriptObject.Name == StickyScriptName then
                pcall(function() scriptObject:Destroy() end)
            end
        end
    end
    local function RestoreStickyScripts()
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if not playerScripts then return end
        local sourceScript = ReplicatedStorage:FindFirstChild(StickyScriptName)
        if sourceScript then
            pcall(function() sourceScript:Clone().Parent = playerScripts end)
        end
    end
    local function ToggleAntiSticky(Value)
        AntiStickyActive = Value and true or false
        if AntiStickyActive then
            DisableStickyScripts()
            RemoveStickyScripts()
        else
            RestoreStickyScripts()
        end
    end
    LocalPlayer.CharacterAdded:Connect(function()
        if AntiStickyActive then
            task.wait(0.5)
            DisableStickyScripts()
            RemoveStickyScripts()
        end
    end)
    local playerScriptsForSticky = LocalPlayer:WaitForChild("PlayerScripts", 9e9)
    if playerScriptsForSticky then
        playerScriptsForSticky.ChildAdded:Connect(function(child)
            if AntiStickyActive and child.Name == StickyScriptName then
                task.defer(function()
                    if child and child.Parent then
                        pcall(function()
                            child.Disabled = true
                            child:Destroy()
                        end)
                    end
                end)
            end
        end)
    end
    MainProtection:AddToggle("AntiSticky", {
        Text = "Anti Sticky",
        Default = false,
        Callback = ToggleAntiSticky,
    })

    local antiBlobmanGrabEnabled = false
    local antiBlobmanThread = nil

    local function getCharacter(player) return player and player.Character end
    local function getHumanoidRootPart(character) return character and character:FindFirstChild("HumanoidRootPart") end
    local function getHumanoid(character) return character and character:FindFirstChildOfClass("Humanoid") end
    local function getDistance(pos1, pos2)
        if not pos1 or not pos2 then return math.huge end
        return (pos1.Position - pos2.Position).Magnitude
    end
    local function startAntiBlobmanGrab()
        if antiBlobmanThread then task.cancel(antiBlobmanThread) end
        antiBlobmanThread = task.spawn(function()
            while antiBlobmanGrabEnabled do
                local myChar = getCharacter(P)
                local myRoot = getHumanoidRootPart(myChar)
                if myRoot then
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= P then
                            local playerChar = getCharacter(player)
                            local playerRoot = getHumanoidRootPart(playerChar)
                            local playerHum = getHumanoid(playerChar)
                            if playerRoot and playerHum and playerHum.SeatPart then
                                local seat = playerHum.SeatPart
                                local seatParent = seat and seat.Parent
                                if seatParent and seatParent.Name == "CreatureBlobman" and getDistance(playerRoot, myRoot) <= 19 then
                                    pcall(function() SetNetOwner:FireServer(playerRoot, playerRoot.CFrame) end)
                                end
                            end
                        end
                    end
                end
                task.wait(0.01)
            end
        end)
    end
    local function stopAntiBlobmanGrab()
        if antiBlobmanThread then task.cancel(antiBlobmanThread); antiBlobmanThread = nil end
    end

    local antiblob = false
    local antiblobConnection = nil
    local truePosPart = nil

    local function createTruePospart()
        local char = P.Character
        if not char then return end
        if char:FindFirstChild("TruePositionPart") then return char.TruePositionPart end
        local tp = Instance.new("Part")
        tp.Name = "TruePositionPart"
        tp.Anchored = true
        tp.CanCollide = false
        tp.Transparency = 1
        tp.Size = Vector3.new(1, 1, 1)
        tp.CFrame = CFrame.new(0, -100, 0)
        tp.Parent = char
        truePosPart = tp
        return tp
    end
    local function dropFromBlobs()
        local char = P.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for _, plot in pairs(WS.PlotItems:GetChildren()) do
            if plot.Name ~= "PlayersInPlots" then
                for _, itm in pairs(plot:GetChildren()) do
                    if itm.Name == "CreatureBlobman" then
                        pcall(function()
                            local script = itm:FindFirstChild("BlobmanSeatAndOwnerScript")
                            local detector = itm:FindFirstChild("RightDetector")
                            local drop = script and script:FindFirstChild("CreatureDrop")
                            local weld = detector and detector:FindFirstChild("RightWeld")
                            if drop and weld then
                                drop:FireServer(weld, hrp)
                                StruggleEvent:FireServer(P)
                            end
                        end)
                    end
                end
            end
        end
        for _, plr in pairs(Players:GetPlayers()) do
            local toysFolder = WS:FindFirstChild(plr.Name .. "SpawnedInToys")
            if toysFolder then
                for _, itm in pairs(toysFolder:GetChildren()) do
                    if itm.Name == "CreatureBlobman" then
                        pcall(function()
                            local script = itm:FindFirstChild("BlobmanSeatAndOwnerScript")
                            local detector = itm:FindFirstChild("RightDetector")
                            local drop = script and script:FindFirstChild("CreatureDrop")
                            local weld = detector and detector:FindFirstChild("RightWeld")
                            if drop and weld then
                                drop:FireServer(weld, hrp)
                                StruggleEvent:FireServer(P)
                            end
                        end)
                    end
                end
            end
        end
    end
    local function setMassless()
        local char = P.Character
        if not char then return end
        for _, prt in pairs(char:GetChildren()) do
            if prt:IsA("BasePart") and prt.Massless then
                prt.Massless = false
                dropFromBlobs()
            end
        end
    end
    local function moveRootAttachment()
        local char = P.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local truePart = char:FindFirstChild("TruePositionPart")
        if hrp and truePart then
            local rootAttachment = hrp:FindFirstChild("RootAttachment")
            if rootAttachment then task.wait(0.2); rootAttachment.Parent = truePart end
        end
    end
    local function restoreRootAttachment()
        local char = P.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local truePart = char:FindFirstChild("TruePositionPart")
        if hrp and truePart then
            local rootAttachment = truePart:FindFirstChild("RootAttachment")
            if rootAttachment then rootAttachment.Parent = hrp end
            truePart:Destroy()
        end
    end
    local function antiblobLoop()
        while antiblob do
            pcall(function()
                if P.Character then
                    createTruePospart()
                    setMassless()
                    local hrp = P.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and hrp:FindFirstChild("RootAttachment") then
                        local truePart = P.Character:FindFirstChild("TruePositionPart")
                        if truePart and not truePart:FindFirstChild("RootAttachment") then moveRootAttachment() end
                    end
                end
            end)
            task.wait(0.1)
        end
    end

    MainProtection:AddToggle("AntiBlob", {
        Text = "Anti Blob",
        Default = false,
        Callback = function(Value)
            antiblob = Value
            antiBlobmanGrabEnabled = Value
            if Value then
                startAntiBlobmanGrab()
                if antiblobConnection then antiblobConnection:Disconnect() end
                task.spawn(antiblobLoop)
                antiblobConnection = P.CharacterAdded:Connect(function(char)
                    if antiblob then
                        task.wait(1)
                        createTruePospart()
                        task.wait(0.5)
                        moveRootAttachment()
                    end
                end)
            else
                stopAntiBlobmanGrab()
                if antiblobConnection then antiblobConnection:Disconnect(); antiblobConnection = nil end
                restoreRootAttachment()
            end
        end,
    })

    local antiFlingActive = false
    local antiFlingConnection = nil
    local antiFlingOriginal = {}
    MiscellaneousGroup:AddToggle("AntiFlingObjectNoclip", {
        Text = "Anti Fling [Object Noclip]",
        Default = false,
        Callback = function(Value)
            antiFlingActive = Value
            if antiFlingConnection then
                antiFlingConnection:Disconnect()
                antiFlingConnection = nil
            end
            if not Value then
                for part, old in pairs(antiFlingOriginal) do
                    if part and part.Parent then part.CanCollide = old end
                end
                antiFlingOriginal = {}
                return
            end
            antiFlingConnection = RunService.Heartbeat:Connect(function()
                local char = P.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local overlap = OverlapParams.new()
                overlap.FilterType = Enum.RaycastFilterType.Exclude
                overlap.FilterDescendantsInstances = {char}
                local parts = WS:GetPartBoundsInRadius(root.Position, 28, overlap)
                for _, part in ipairs(parts) do
                    if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(char) then
                        if antiFlingOriginal[part] == nil then antiFlingOriginal[part] = part.CanCollide end
                        part.CanCollide = false
                    end
                end
            end)
        end,
    })

    MiscellaneousGroup:AddToggle("WaterWalk", {
        Text = "Water Walk",
        Default = false,
        Callback = function(Value)
            local ocean = WS:FindFirstChild("Map") and WS.Map:FindFirstChild("AlwaysHereTweenedObjects") and WS.Map.AlwaysHereTweenedObjects:FindFirstChild("Ocean") and WS.Map.AlwaysHereTweenedObjects.Ocean:FindFirstChild("Object") and WS.Map.AlwaysHereTweenedObjects.Ocean.Object:FindFirstChild("ObjectModel")
            if not ocean then return end
            for _, Part in ipairs(ocean:GetChildren()) do
                if Part:IsA("BasePart") and Part.Name == "Ocean" then
                    Part.CanCollide = Value
                end
            end
        end,
    })

    local posLockConnection = nil
    local posLockPosition = nil

    MiscellaneousGroup:AddToggle("PosLock", {
        Text = "Pos Lock",
        Default = false,
        Callback = function(Value)
            if posLockConnection then
                posLockConnection:Disconnect()
                posLockConnection = nil
            end

            if Value then
                local char = P.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then posLockPosition = root.CFrame end

                if posLockPosition then
                    posLockConnection = RunService.RenderStepped:Connect(function()
                        local char2 = P.Character
                        local root2 = char2 and char2:FindFirstChild("HumanoidRootPart")
                        if root2 and posLockPosition then
                            pcall(function()
                                local assembly = root2.AssemblyRootPart or root2
                                assembly.AssemblyLinearVelocity = Vector3.zero
                                assembly.AssemblyAngularVelocity = Vector3.zero
                                local offset = assembly.CFrame:ToObjectSpace(root2.CFrame)
                                assembly.CFrame = posLockPosition * offset:Inverse()
                            end)
                        end
                    end)
                end
            else
                pcall(function()
                    local char2 = P.Character
                    local root2 = char2 and char2:FindFirstChild("HumanoidRootPart")
                    if root2 and posLockPosition then
                        root2.CFrame = posLockPosition
                        root2.AssemblyLinearVelocity = Vector3.zero
                        root2.AssemblyAngularVelocity = Vector3.zero
                    end
                end)
                posLockPosition = nil
            end
        end
    })

    local hipHeightLoop = nil

    MainProtection:AddToggle("AntiBanana", {
        Text = "Anti Banana",
        Default = false,
    })

    MainProtection:AddToggle("DefDesyncMain", {
        Text = "Desync",
        Default = false,
        Callback = function(on)
            if Desync and Desync.SetEnabled then
                Desync:SetEnabled(on)
            end
            if on then
                if MDCP_Notify then MDCP_Notify("Desync", "Desync ON", 2, "Custom Notification")
                else Library:Notify({ Title = "mdcp", Description = "Desync ON", Time = 2 }) end
            end
        end,
    })
    MainProtection:AddButton({
        Text = "Delete Legs",
        Func = function()
            local char = LocalPlayer.Character
            if not char then
                Library:Notify({ Title = "mdcp", Description = "Character not found.", Time = 2 })
                return
            end
            local legNames = {
                "Left Leg", "Right Leg",
                "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
                "RightUpperLeg", "RightLowerLeg", "RightFoot",
            }
            local n = 0
            for _, name in ipairs(legNames) do
                local leg = char:FindFirstChild(name)
                if leg and leg:IsA("BasePart") then
                    pcall(function()
                        leg.LocalTransparencyModifier = 1
                        leg.Transparency = 1
                        leg.CanCollide = false
                        leg.CanTouch = false
                        leg.CanQuery = false
                        leg.Massless = true
                        leg.CastShadow = false
                        leg.Size = Vector3.new(0.1, 0.1, 0.1)
                        for _, j in ipairs(leg:GetChildren()) do
                            if j:IsA("Motor6D") or j:IsA("Weld") or j:IsA("WeldConstraint") then j:Destroy() end
                        end
                        for _, j in ipairs(char:GetDescendants()) do
                            if (j:IsA("Motor6D") or j:IsA("Weld")) and (j.Part0 == leg or j.Part1 == leg) then
                                j:Destroy()
                            end
                        end
                    end)
                    n = n + 1
                end
            end
            Library:Notify({
                Title = "mdcp",
                Description = n > 0 and ("Legs deleted (" .. n .. ").") or "Could not find legs.",
                Time = 3,
            })
        end,
    })

    local function runAntiBananaLogic()
        local player = P
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not hrp or not head then return end

        local rs = RS
        local ragdoll = rs:WaitForChild("CharacterEvents"):WaitForChild("RagdollRemote")
        local toy_spawn = rs:WaitForChild("MenuToys"):WaitForChild("SpawnToyRemoteFunction")
        local toy_destroy = rs:WaitForChild("MenuToys"):WaitForChild("DestroyToy")
        local toysFolderName = player.Name .. "SpawnedInToys"
        local Humanoid = char:WaitForChild("Humanoid")
        local bellModel = nil
        local conn

        if hipHeightLoop then task.cancel(hipHeightLoop); hipHeightLoop = nil end
        hipHeightLoop = task.spawn(function()
            while true do
                task.wait(0.2)
                if not Humanoid or Humanoid.Parent == nil then break end
                if Humanoid.HipHeight ~= 2 then Humanoid.HipHeight = 2 end
            end
        end)

        local toysFolder = WS:FindFirstChild(toysFolderName)
        if toysFolder then
            conn = toysFolder.ChildAdded:Connect(function(obj)
                if obj:IsA("Model") and obj.Name == "BellBig" then
                    bellModel = obj
                    task.defer(function() obj:PivotTo(hrp.CFrame) end)
                    if conn then conn:Disconnect() end
                end
            end)
        end

        for i = 1, 10 do pcall(function() ragdoll:FireServer(hrp, 1) end); task.wait(0.05) end
        for _, leg in ipairs({"Left Leg", "Right Leg"}) do
            local part = char:FindFirstChild(leg)
            if part then part.CFrame = CFrame.new(hrp.Position + Vector3.new(5, -59999, 0)) end
        end

        local spawnAttempts = 0
        while not bellModel and spawnAttempts < 40 do
            pcall(function() toy_spawn:InvokeServer("BellBig", head.CFrame, Vector3.new(0, 160.2, 0)) end)
            task.wait(0.05)
            spawnAttempts += 1
            local toysFolderClean = WS:FindFirstChild(toysFolderName)
            if toysFolderClean then bellModel = toysFolderClean:FindFirstChild("BellBig") end
        end

        if bellModel then
            for _, desc in ipairs(bellModel:GetDescendants()) do
                if desc:IsA("BasePart") then desc.CanCollide = false; desc.LocalTransparencyModifier = 1 end
            end
            local primary = bellModel.PrimaryPart
            if primary then primary.CanCollide = false; primary.LocalTransparencyModifier = 1 end
            pcall(function() toy_destroy:FireServer(bellModel) end)
        end
        for i = 1, 5 do pcall(function() ragdoll:FireServer(hrp, 0) end); task.wait(0.05) end
    end

    Toggles.AntiBanana:OnChanged(function(state)
        if state then
            task.spawn(runAntiBananaLogic)
            P.CharacterAdded:Connect(function()
                task.wait(0.2)
                if Toggles.AntiBanana and Toggles.AntiBanana.Value then task.spawn(runAntiBananaLogic) end
            end)
        else
            if hipHeightLoop then task.cancel(hipHeightLoop); hipHeightLoop = nil end
        end
    end)



MiscellaneousGroup:AddToggle("BarrierNoclip", {
    Text = "Barrier Noclip",
    Default = false,
})
Toggles.BarrierNoclip:OnChanged(function(state)
    local SvcWS = game:GetService("Workspace")
    SvcWS:SetAttribute("PlotBarrierGrabable", state)
    local plots = SvcWS:FindFirstChild("Plots")
    if plots then
        for _, v in pairs(plots:GetDescendants()) do
            if v.Name == "PlotBarrier" then
                v.CanQuery = not state
                v.CanCollide = not state
                v.CanTouch = not state
            end
        end
    end
end)

-- LOOP TP
local DefDefence = GetDefDefenceState()
local MainProtection = DefDefence and DefDefence.MainProtection
local P = DefDefence and DefDefence.P or LocalPlayer

if not MainProtection then
    warn("[Def] Defence Main Protection group was not created.")
end

local loopTPActive = false
local loopTPThread = nil
_G.__DefLoopTPMode = _G.__DefLoopTPMode or "Loop TP (Random)"

function stopLoopTP()
    loopTPActive = false
    if loopTPThread then
        pcall(function() task.cancel(loopTPThread) end)
        loopTPThread = nil
    end
    local char = P.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum.PlatformStand = false end)
        end
    end
end

function startLoopTP()
    stopLoopTP()
    loopTPActive = true
    loopTPThread = task.spawn(function()
        local angle = 0
        while loopTPActive do
            local char = P.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if hrp and hum then
                pcall(function()
                    hum.PlatformStand = true

                    if _G.__DefLoopTPMode == "Loop TP (OP / Tornado)" then
                        angle = angle + 0.5
                        local rad = math.rad(angle)
                        hrp.CFrame = CFrame.new(math.cos(rad) * 10000, 0, math.sin(rad) * 10000)
                    else
                        hrp.CFrame = CFrame.new(
                            math.random(-500, 500),
                            math.random(30, 480),
                            math.random(-500, 500)
                        )
                    end

                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)
            end

            task.wait(_G.__DefLoopTPMode == "Loop TP (OP / Tornado)" and 0.03 or 0.05)
        end
    end)
end

local ConfigGroup = GetDefDefenceConfigGroup()
if ConfigGroup then ConfigGroup:AddDropdown("LoopTPMode", {
    Text = "Loop TP Mode",
    Values = {"Loop TP (Random)", "Loop TP (OP / Tornado)", "None"},
    Default = _G.__DefLoopTPMode or "Loop TP (Random)",
    Multi = false,
    Callback = function(Value)
        _G.__DefLoopTPMode = Value
        if Toggles.LoopTP and Toggles.LoopTP.Value then
            if Value == "None" then stopLoopTP() else startLoopTP() end
        end
    end,
})
end


-- ANTI SNOWBALL / LOOP RAGDOLL + DELETE LEGS
do
    local E = GetDefDefenceState()
    if not E then return end
    local P = E.P
    local WS = E.WS
    local RagdollRemote = E.RagdollRemote
    local MainProtection = E.MainProtection
    local Toggles = Toggles

    local loopRagdollActive = false
    local loopRagdollThread = nil

    MainProtection:AddToggle("LoopRagdollAntiSnowball", {
        Text = "Anti Snowball",
        Default = false,
        Callback = function(Value)
            loopRagdollActive = Value

            if loopRagdollThread then
                task.cancel(loopRagdollThread)
                loopRagdollThread = nil
            end

            if not Value then return end

            loopRagdollThread = task.spawn(function()
                while loopRagdollActive do
                    pcall(function()
                        local char = P.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp and RagdollRemote then
                            RagdollRemote:FireServer(hrp, 0.5)
                        end
                    end)
                    task.wait(0.05)
                end
            end)
        end,
    })

    local antiVoidEnabled = false
    local antiVoidTPEnabled = false
    local antiVoidConnection = nil
    local antiVoidTPConnection = nil
    local antiVoidOriginalDestroyHeight = nil
    local antiVoidSavedCFrame = nil

    local function stopAntiVoid()
        antiVoidEnabled = false
        if antiVoidConnection then
            pcall(function() antiVoidConnection:Disconnect() end)
            antiVoidConnection = nil
        end
        if antiVoidOriginalDestroyHeight ~= nil then
            pcall(function()
                WS.FallenPartsDestroyHeight = antiVoidOriginalDestroyHeight
            end)
            antiVoidOriginalDestroyHeight = nil
        end
    end

    local function startAntiVoid()
        stopAntiVoid()
        antiVoidEnabled = true
        if antiVoidOriginalDestroyHeight == nil then
            pcall(function()
                antiVoidOriginalDestroyHeight = WS.FallenPartsDestroyHeight
            end)
        end
        pcall(function()
            WS.FallenPartsDestroyHeight = 0 / 0
        end)
    end

    local function stopAntiVoidTP()
        antiVoidTPEnabled = false
        if antiVoidTPConnection then
            pcall(function() antiVoidTPConnection:Disconnect() end)
            antiVoidTPConnection = nil
        end
    end

    local function startAntiVoidTP()
        stopAntiVoidTP()
        antiVoidTPEnabled = true
        local char = P.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            antiVoidSavedCFrame = root.CFrame
        end
        antiVoidTPConnection = RunService.Heartbeat:Connect(function()
            if not antiVoidTPEnabled then return end
            local character = P.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return end
            if humanoidRootPart.Position.Y < -100 then
                local target = antiVoidSavedCFrame
                if not target then
                    local spawnLocation = WS:FindFirstChild("SpawnLocation")
                    target = spawnLocation and spawnLocation.CFrame or CFrame.new(0, 10, 0)
                end
                pcall(function()
                    humanoidRootPart.CFrame = target + Vector3.new(0, 5, 0)
                    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                    humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                end)
            else
                antiVoidSavedCFrame = humanoidRootPart.CFrame
            end
        end)
    end

    MainProtection:AddToggle("AntiVoid", {
        Text = "Anti Void",
        Default = true,
        Callback = function(Value)
            if Value then startAntiVoid() else stopAntiVoid() end
        end,
    })
    MainProtection:AddToggle("AntiVoidTP", {
        Text = "Anti Void TP",
        Default = true,
        Callback = function(Value)
            if Value then startAntiVoidTP() else stopAntiVoidTP() end
        end,
    })

    task.defer(function()
        if Toggles.AntiVoid and Toggles.AntiVoid.Value then startAntiVoid() end
        if Toggles.AntiVoidTP and Toggles.AntiVoidTP.Value then startAntiVoidTP() end
    end)

    MainProtection:AddToggle("LoopTP", {
    Text = "Loop TP",
    Default = false,
    Callback = function(Value)
        if Value then
            if _G.__DefLoopTPMode == "None" then
                stopLoopTP()
                return
            end
            startLoopTP()
        else
            stopLoopTP()
        end
    end,
})

    -- ANTI LAG + AUTO ANTI LAG
    do
        while not game:IsLoaded() do task.wait() end

        local Players2 = game:GetService("Players")
        local LocalPlayer2 = Players2.LocalPlayer
        local ReplicatedStorage2 = game:GetService("ReplicatedStorage")

        local antiLagEnabled = true

        local function DefStartAntiLag()
            _G.TheWorstAntiLagEnabled = true

            if _G.TheWorstAntiLagConn then
                pcall(function()
                    _G.TheWorstAntiLagConn:Disconnect()
                end)
                _G.TheWorstAntiLagConn = nil
                if not _G.TheWorstAntiLagEnabled then return end
            end

            local CreateGrabLine = ReplicatedStorage2:WaitForChild("GrabEvents", 9e9):WaitForChild("CreateGrabLine", 9e9)
            local BeamMove = LocalPlayer2:WaitForChild("PlayerScripts", 9e9):WaitForChild("CharacterAndBeamMove", 9e9)
            BeamMove.Enabled = false

            task.spawn(function()
                while _G.TheWorstAntiLagEnabled and task.wait(1) do
                    BeamMove.Enabled = true
                end
            end)

            _G.TheWorstAntiLagConn = CreateGrabLine.OnClientEvent:Connect(function(Player, _, CF)
                if Player == LocalPlayer2 then return end

                local PlayerChar = Player ~= LocalPlayer2 and Player.Character
                local PlayerRoot = PlayerChar and PlayerChar:FindFirstChild("HumanoidRootPart")
                if not PlayerRoot or typeof(CF) ~= "CFrame" then return end
                if vector.magnitude(PlayerRoot.Position - CF.Position) < 10000 then return end

                BeamMove.Enabled = false

                for _, Plr in Players2:GetPlayers() do
                    if not Plr.Character then continue end
                    local GrabParts = Plr.Character:FindFirstChild("GrabParts")
                    if GrabParts then GrabParts:Destroy() end
                end
            end)
        end

        local function DefStopAntiLag()
            _G.TheWorstAntiLagEnabled = false

            if _G.TheWorstAntiLagConn then
                pcall(function()
                    _G.TheWorstAntiLagConn:Disconnect()
                end)
                _G.TheWorstAntiLagConn = nil
            end

            pcall(function()
                local BeamMove = LocalPlayer2:WaitForChild("PlayerScripts", 2):FindFirstChild("CharacterAndBeamMove")
                if BeamMove then
                    BeamMove.Enabled = true
                end
            end)
        end

        MainProtection:AddToggle("DefAntiLag", {
            Text = "Anti Lag",
            Default = true,
            Tooltip = "Protects against abnormal grab-line lag.",
            Callback = function(Value)
                antiLagEnabled = Value and true or false
                if antiLagEnabled then
                    DefStartAntiLag()
                else
                    DefStopAntiLag()
                end
            end,
        })

        pcall(function()
            Library:OnUnload(function()
                DefStopAntiLag()
            end)
        end)

        local autoAntiLagEnabled = true
        local autoAntiLagConnection = nil
        local autoAntiLagCounterConnection = nil
        local autoAntiLagLines = 0
        local function DefStartAutoAntiLag()
            autoAntiLagEnabled = true
            autoAntiLagLines = 0
            if autoAntiLagConnection then pcall(function() autoAntiLagConnection:Disconnect() end) end
            if autoAntiLagCounterConnection then pcall(function() autoAntiLagCounterConnection:Disconnect() end) end
            autoAntiLagConnection = nil
            autoAntiLagCounterConnection = nil
            local playerScripts = LocalPlayer2:FindFirstChild("PlayerScripts")
            local beamMove = playerScripts and playerScripts:FindFirstChild("CharacterAndBeamMove")
            local grabEvents = ReplicatedStorage2:FindFirstChild("GrabEvents")
            local createGrabLine = grabEvents and grabEvents:FindFirstChild("CreateGrabLine")
            if not beamMove or not createGrabLine then return end
            autoAntiLagCounterConnection = createGrabLine.OnClientEvent:Connect(function()
                if autoAntiLagEnabled then
                    autoAntiLagLines = autoAntiLagLines + 1
                end
            end)
            autoAntiLagConnection = task.spawn(function()
                while autoAntiLagEnabled do
                    task.wait(1)
                    if not autoAntiLagEnabled then break end
                    if autoAntiLagLines > 100 then
                        pcall(function() beamMove.Enabled = false end)
                        autoAntiLagLines = 0
                    else
                        pcall(function() beamMove.Enabled = true end)
                    end
                end
            end)
        end
        local function DefStopAutoAntiLag()
            autoAntiLagEnabled = false
            if autoAntiLagCounterConnection then
                pcall(function() autoAntiLagCounterConnection:Disconnect() end)
                autoAntiLagCounterConnection = nil
            end
            autoAntiLagConnection = nil
            autoAntiLagLines = 0
            pcall(function()
                local beamMove = LocalPlayer2:FindFirstChild("PlayerScripts") and LocalPlayer2.PlayerScripts:FindFirstChild("CharacterAndBeamMove")
                if beamMove then beamMove.Enabled = true end
            end)
        end
        MainProtection:AddToggle("DefAutoAntiLag", {
            Text = "Auto Anti Lag",
            Default = true,
            Callback = function(Value)
                if Value then DefStartAutoAntiLag() else DefStopAutoAntiLag() end
            end,
        })
        -- Anti Lag and Auto Anti Lag are enabled automatically whenever Def joins.
        task.defer(function()
            pcall(DefStartAntiLag)
            pcall(DefStartAutoAntiLag)
        end)
        pcall(function()
            Library:OnUnload(DefStopAutoAntiLag)
        end)
    end
end

local CounterGroup = Tabs.Defense:AddRightGroupbox("Counters", "sword")
local OtherAntisGroup = Tabs.Defense:AddRightGroupbox("Other Anti's", "shield-alert")

-- ANTI KICK
do
    local E = GetDefDefenceState()
    if not E then return end
    local P = E.P
    local WS = E.WS
    local RS = E.RS
    local SetNetOwner = E.SetNetOwner
    local StruggleEvent = E.StruggleEvent
    local RagdollRemote = E.RagdollRemote
    local SpawnToyRemote = E.SpawnToyRemote
    local DestroyToy = E.DestroyToy
    local StickyEvent = E.StickyEvent
    local dhrp = E.dhrp
    local dhum = E.dhum
    local checkNetworkOwner = E.checkNetworkOwner
    local Toggles = Toggles
    local Players = game:GetService("Players")
    local Debris = game:GetService("Debris")
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")

    local AntiKickGroup = OtherAntisGroup
    local AntiKickTogglesTab = AntiKickGroup

    AntiKickTogglesTab:AddDivider("<b>Selection</b>")

    local AntiKickToyValues = {
        "Shuriken",
        "Kunai",
        "Cleaver",
        "Rusty Fork",
        "Pencil",
        "Pickaxe",
        "Katana",
    }
    local AntiKickToyNames = {
        Shuriken = "NinjaShuriken",
        Kunai = "NinjaKunai",
        Cleaver = "ToolCleaver",
        ["Rusty Fork"] = "ToolDiggingForkRusty",
        Pencil = "ToolPencil",
        Pickaxe = "ToolPickaxe",
        Katana = "NinjaKatana",
    }
    local SelectedAntiKickToy = "NinjaShuriken"
    _G.__DefAntiKickToy = _G.__DefAntiKickToy or SelectedAntiKickToy

    AntiKickTogglesTab:AddDropdown("AntiKickToyMethod", {
        Text = "Sticky Toy",
        Values = AntiKickToyValues,
        Default = "Shuriken",
        Multi = false,
        ValueImages = {
            Shuriken = "rbxassetid://140368128539182",
            Kunai = "rbxassetid://85197427890853",
            Cleaver = "rbxassetid://70617572473301",
            ["Rusty Fork"] = "rbxassetid://99651991375781",
            Pencil = "rbxassetid://92908917595707",
            Pickaxe = "rbxassetid://129936050231156",
            Katana = "rbxassetid://139546965155982",
        },
        Callback = function(Value)
            SelectedAntiKickToy = AntiKickToyNames[Value] or Value
            _G.__DefAntiKickToy = SelectedAntiKickToy
        end,
    })

    local DefAntiKickActive = false
    local DefAntiKickThread = nil
    local DefAntiKickCurrentToy = nil
    local DefAntiKickAttaching = false

    local function DefGetPing()
        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        return ping
    end
    local function DefGetStickDelay()
        local ping = DefGetPing()
        if ping < 100 then return 0.02 elseif ping < 150 then return 0.08 elseif ping < 220 then return 0.15 elseif ping < 300 then return 0.25 else return 0.4 end
    end
    local function DefGetStickTimeout()
        local ping = DefGetPing()
        if ping < 100 then return 0.5 elseif ping < 150 then return 1 elseif ping < 220 then return 2 elseif ping < 300 then return 3 else return 4.5 end
    end
    local function DefIsProperlyStuck(toy)
        if not toy or not toy.Parent then return false end
        local sp = toy:FindFirstChild("StickyPart")
        local weld = sp and sp:FindFirstChild("StickyWeld")
        local hrp = P.Character and P.Character:FindFirstChild("HumanoidRootPart")
        local firePart = hrp and hrp:FindFirstChild("FirePlayerPart")
        return sp ~= nil and weld ~= nil and weld.Part1 ~= nil and firePart ~= nil and weld.Part1 == firePart
    end
    local function DefUpdateTransparency(toy)
        if not toy then return end
        for _, obj in ipairs(toy:GetDescendants()) do
            if obj:IsA("BasePart") then
                if obj.Name == "StickyPart" or obj.Name == "SoundPart" or obj.Name == "Main" then
                    obj.Transparency = 1
                end
            end
        end
    end
    local function DefStickToy(toy)
        if not toy or not toy.Parent or DefAntiKickAttaching then return end
        DefAntiKickAttaching = true
        local sp = toy:FindFirstChild("StickyPart")
        local hrp = P.Character and P.Character:FindFirstChild("HumanoidRootPart")
        local firePart = hrp and hrp:FindFirstChild("FirePlayerPart")
        if not sp or not firePart then DefAntiKickAttaching = false; return end
        pcall(function() SetNetOwner:FireServer(sp, sp.CFrame) end)
        local soundPart = toy:FindFirstChild("SoundPart")
        if soundPart then pcall(function() SetNetOwner:FireServer(soundPart, soundPart.CFrame) end) end
        task.wait(DefGetStickDelay())
        pcall(function() StickyEvent:FireServer(sp, firePart, CFrame.new(0, -0.1, 0) * CFrame.Angles(0, math.rad(90), math.rad(90))) end)
        for _, obj in ipairs(toy:GetDescendants()) do
            if obj:IsA("Highlight") or obj:IsA("SelectionBox") or obj:IsA("BillboardGui") then pcall(function() obj:Destroy() end) end
        end
        for _, obj in ipairs(toy:GetChildren()) do
            if obj:IsA("BasePart") then
                obj.CanTouch = false; obj.CanCollide = false; obj.CanQuery = false; obj.CastShadow = false
            end
        end
        DefUpdateTransparency(toy)
        DefAntiKickCurrentToy = toy
        DefAntiKickAttaching = false
        if toy and not toy:GetAttribute("DefAntiKickRemovalWatch") then
            toy:SetAttribute("DefAntiKickRemovalWatch", true)
            toy.AncestryChanged:Connect(function(_, parent)
                if parent == nil and DefAntiKickActive then
                    local attacker
                    pcall(function() attacker = getAttacker() end)
                    if attacker then
                        Library:Notify({
                            Title = "Def",
                            Description = "Your Anti kick was removed by " .. attacker.DisplayName .. "(" .. attacker.Name .. ")",
                            Time = 4,
                        })
                    end
                end
            end)
        end
    end
    local function DefStickGuaranteed(toy)
        DefStickToy(toy)
        local timeout = DefGetStickTimeout()
        local started = tick()
        while tick() - started < timeout do
            if DefIsProperlyStuck(toy) then return true end
            task.wait(0.05)
        end
        for _ = 1, 15 do
            DefStickToy(toy)
            local retry = tick()
            while tick() - retry < timeout / 2 do
                if DefIsProperlyStuck(toy) then return true end
                task.wait(0.05)
            end
        end
        return false
    end
    local function DefSpawnSelectedToy()
        local canSpawn = P:FindFirstChild("CanSpawnToy")
        local hrp = P.Character and P.Character:FindFirstChild("HumanoidRootPart")
        if not canSpawn or not hrp then return nil end
        local started = tick()
        while not canSpawn.Value do
            if not DefAntiKickActive or tick() - started > 8 then return nil end
            task.wait(0.02)
        end
        local inv = WS:FindFirstChild(P.Name .. "SpawnedInToys")
        if not inv then return nil end
        pcall(function() SpawnToyRemote:InvokeServer(SelectedAntiKickToy, hrp.CFrame * CFrame.new(0, 20, 15), Vector3.zero) end)
        return inv:WaitForChild(SelectedAntiKickToy, 1.5)
    end
    local function DefClearAntiKickToy()
        local inv = WS:FindFirstChild(P.Name .. "SpawnedInToys")
        if inv then
            for _, v in ipairs(inv:GetChildren()) do
                if v.Name == "AntiKick" then
                    pcall(function() DestroyToy:FireServer(v) end)
                end
            end
        end
        DefAntiKickCurrentToy = nil
    end
    local function DefRunAntiKick()
        while DefAntiKickActive do
            task.wait(0.003)
            local char = P.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            local inv = WS:FindFirstChild(P.Name .. "SpawnedInToys")
            local toy = inv and inv:FindFirstChild(SelectedAntiKickToy)
            if DefAntiKickCurrentToy and DefAntiKickCurrentToy.Parent and DefIsProperlyStuck(DefAntiKickCurrentToy) then toy = DefAntiKickCurrentToy end
            if not toy or not toy.Parent then
                toy = DefSpawnSelectedToy()
                if toy then
                    toy.Name = "AntiKick"
                    DefStickGuaranteed(toy)
                    DefUpdateTransparency(toy)
                end
            end
            if toy and toy.Parent then
                repeat
                    if toy:FindFirstChild("StickyPart") and not DefIsProperlyStuck(toy) then
                        DefStickGuaranteed(toy)
                        toy.Name = "AntiKick"
                        DefUpdateTransparency(toy)
                    end
                    task.wait(0.15)
                until not toy.Parent or not DefAntiKickActive or not toy:FindFirstChild("StickyPart") or not P.Character or not P.Character:FindFirstChild("HumanoidRootPart") or (P.Character.HumanoidRootPart.Position - toy.StickyPart.Position).Magnitude >= 30
            end
        end
        DefClearAntiKickToy()
    end

    AntiKickTogglesTab:AddToggle("AntiKickToggle", {
        Text = "Anti Kick",
        Default = false,
        Callback = function(Value)
            DefAntiKickActive = Value
            SelectedAntiKickToy = _G.__DefAntiKickToy or SelectedAntiKickToy
            if DefAntiKickThread then task.cancel(DefAntiKickThread); DefAntiKickThread = nil end
            if Value then DefAntiKickThread = task.spawn(DefRunAntiKick) else DefClearAntiKickToy() end
        end,
    })

    local AutoPCLDBreak = false
    local BusyBreaking = false
    local PCLDBreakNotification
    local function DestroyPCLDBreakNotification()
        if PCLDBreakNotification and PCLDBreakNotification.Destroy then
            pcall(function() PCLDBreakNotification:Destroy() end)
        end
        PCLDBreakNotification = nil
    end
    local function BreakPCLD()
        if BusyBreaking then return end
        BusyBreaking = true
        DestroyPCLDBreakNotification()
        DestroyDefNotificationsByDescription("Breaking pcld...")
        local ok, err = pcall(function()
            PCLDBreakNotification = Library:Notify({
                Title = "Def",
                Description = "Breaking pcld...",
                Time = 999,
            })
            local Character = P.Character
            if not Character then
                error("Character not found")
            end
            local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
            if not Humanoid then
                error("Humanoid not found")
            end
            Humanoid.Health = 0
            local NewCharacter = P.CharacterAdded:Wait()
            local NewHumanoid = NewCharacter:WaitForChild("Humanoid")
            task.wait(0.15)
            if NewHumanoid and NewHumanoid.Health > 0 then
                NewHumanoid.Health = 0
            end
            task.wait(0.35)
        end)
        DestroyPCLDBreakNotification()
        DestroyDefNotificationsByDescription("Breaking pcld...")
        BusyBreaking = false
        if ok then
            Library:Notify({
                Title = "Def",
                Description = "Broke pcld successfully",
                Time = 3,
            })
        else
            Library:Notify({
                Title = "Def",
                Description = "Could not break pcld.",
                Time = 3,
            })
            warn("[Defence] Break PCLD failed: " .. tostring(err))
        end
    end
    local function SetupPCLDCharacter(Character)
        local Humanoid = Character:WaitForChild("Humanoid")
        Humanoid.Died:Connect(function()
            if not AutoPCLDBreak or BusyBreaking then return end
            task.spawn(function()
                P.CharacterAdded:Wait()
                if not AutoPCLDBreak then return end
                task.wait(0.25)
                BreakPCLD()
            end)
        end)
    end
    AntiKickTogglesTab:AddToggle("AutoPCLDBreak", {
        Text = "Anti Kick [PCLD]",
        Default = false,
        Callback = function(state)
            AutoPCLDBreak = state
            if state then task.spawn(BreakPCLD) end
        end,
    })
    if P.Character then SetupPCLDCharacter(P.Character) end
    P.CharacterAdded:Connect(SetupPCLDCharacter)

    local autoResetConnection = nil
    local autoResetCharacterConnection = nil
    local function DefFlaggedReset(reason)
        local flag = Toggles and Toggles.AutoReset
        if not flag or not flag.Value then return end
        local text = tostring(reason or "")
        if text == "Flying" or text:lower():find("flying", 1, true) or text:lower():find("flag", 1, true) then
            Library:Notify({
                Title = "Def",
                Description = "Anti cheat warning",
                Time = 3,
            })
            task.defer(function()
                local char = P.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    pcall(function() hum.Health = 0 end)
                end
            end)
        end
    end
    AntiKickTogglesTab:AddToggle("AutoReset", {
        Text = "Auto Reset",
        Default = true,
        Callback = function(enabled)
            if autoResetConnection then pcall(function() autoResetConnection:Disconnect() end); autoResetConnection = nil end
            if autoResetCharacterConnection then pcall(function() autoResetCharacterConnection:Disconnect() end); autoResetCharacterConnection = nil end
            if not enabled then return end
            local correctionEvents = RS:FindFirstChild("GameCorrectionEvents")
            local correctionNotify = correctionEvents and correctionEvents:FindFirstChild("GameCorrectionsNotify")
            if correctionNotify then
                autoResetConnection = correctionNotify.OnClientEvent:Connect(DefFlaggedReset)
            end
            autoResetCharacterConnection = P.CharacterAdded:Connect(function()
                task.defer(function()
                    local flag = Toggles and Toggles.AutoReset
                    if not flag or not flag.Value then return end
                    local correctionEvents2 = RS:FindFirstChild("GameCorrectionEvents")
                    local correctionNotify2 = correctionEvents2 and correctionEvents2:FindFirstChild("GameCorrectionsNotify")
                    if correctionNotify2 and not autoResetConnection then
                        autoResetConnection = correctionNotify2.OnClientEvent:Connect(DefFlaggedReset)
                    end
                end)
            end)
        end,
    })

    local autoLeaveConnection = nil
    AntiKickTogglesTab:AddToggle("AutoLeave", {
        Text = "Auto Leave",
        Default = true,
        Callback = function(enabled)
            if autoLeaveConnection then
                pcall(function() autoLeaveConnection:Disconnect() end)
                autoLeaveConnection = nil
            end
            if not enabled then return end

            local correctionEvents = RS:FindFirstChild("GameCorrectionEvents")
            local correctionNotify = correctionEvents and correctionEvents:FindFirstChild("GameCorrectionsNotify")
            if correctionNotify then
                local warnTimestamps = {}
                autoLeaveConnection = correctionNotify.OnClientEvent:Connect(function(reason)
                    if reason ~= "Flying" then return end
                    local currentTime = os.clock()
                    table.insert(warnTimestamps, currentTime)
                    for i = #warnTimestamps, 1, -1 do
                        if currentTime - warnTimestamps[i] > 1 then
                            table.remove(warnTimestamps, i)
                        end
                    end
                    if #warnTimestamps >= 3 then
                        Library:Notify({Title = "Def", Description = "Def detected a threat, Leaving to prevent kick", Time = 3}); task.wait(0.05); P:Kick("Def: Def has detected a threat and left to prevent kick.")
                    end
                end)
            end
        end,
    })

    -- Both protections are ON by default; Obsidian does not reliably invoke the
    -- callback just because Default=true, so initialize their listeners explicitly.
    task.defer(function()
        if Toggles.AutoReset and Toggles.AutoReset.Value then
            local correctionEvents = RS:FindFirstChild("GameCorrectionEvents")
            local correctionNotify = correctionEvents and correctionEvents:FindFirstChild("GameCorrectionsNotify")
            if correctionNotify and not autoResetConnection then
                autoResetConnection = correctionNotify.OnClientEvent:Connect(DefFlaggedReset)
            end
            if not autoResetCharacterConnection then
                autoResetCharacterConnection = P.CharacterAdded:Connect(function()
                    task.defer(function()
                        local flag = Toggles.AutoReset
                        if not flag or not flag.Value then return end
                        local ce = RS:FindFirstChild("GameCorrectionEvents")
                        local cn = ce and ce:FindFirstChild("GameCorrectionsNotify")
                        if cn then
                            if autoResetConnection then pcall(function() autoResetConnection:Disconnect() end) end
                            autoResetConnection = cn.OnClientEvent:Connect(DefFlaggedReset)
                        end
                    end)
                end)
            end
        end
        if Toggles.AutoLeave and Toggles.AutoLeave.Value and not autoLeaveConnection then
            local correctionEvents = RS:FindFirstChild("GameCorrectionEvents")
            local correctionNotify = correctionEvents and correctionEvents:FindFirstChild("GameCorrectionsNotify")
            if correctionNotify then
                local warnTimestamps = {}
                autoLeaveConnection = correctionNotify.OnClientEvent:Connect(function(reason)
                    if reason ~= "Flying" then return end
                    local now = os.clock()
                    table.insert(warnTimestamps, now)
                    for i = #warnTimestamps, 1, -1 do
                        if now - warnTimestamps[i] > 1 then table.remove(warnTimestamps, i) end
                    end
                    if #warnTimestamps >= 3 then
                        Library:Notify({Title = "Def", Description = "Def detected a threat, Leaving to prevent kick", Time = 3}); task.wait(0.05); P:Kick("Def: Def has detected a threat and left to prevent kick.")
                    end
                end)
            end
        end
    end)

    local correctionWatcher = nil
    pcall(function()
        correctionWatcher = RS.ChildAdded:Connect(function(child)
            if child.Name ~= "GameCorrectionEvents" then return end
            task.defer(function()
                local notify = child:FindFirstChild("GameCorrectionsNotify") or child:WaitForChild("GameCorrectionsNotify", 5)
                if not notify then return end
                if Toggles.AutoReset and Toggles.AutoReset.Value then
                    if autoResetConnection then pcall(function() autoResetConnection:Disconnect() end) end
                    autoResetConnection = notify.OnClientEvent:Connect(DefFlaggedReset)
                end
                if Toggles.AutoLeave and Toggles.AutoLeave.Value then
                    local timestamps = {}
                    if autoLeaveConnection then pcall(function() autoLeaveConnection:Disconnect() end) end
                    autoLeaveConnection = notify.OnClientEvent:Connect(function(reason)
                        if reason ~= "Flying" then return end
                        local now = os.clock()
                        table.insert(timestamps, now)
                        for i = #timestamps, 1, -1 do
                            if now - timestamps[i] > 1 then table.remove(timestamps, i) end
                        end
                        if #timestamps >= 3 then Library:Notify({Title = "Def", Description = "Def detected a threat, Leaving to prevent kick", Time = 3}); task.wait(0.05); P:Kick("Def: Def has detected a threat and left to prevent kick.") end
                    end)
                end
            end)
        end)
    end)

    local defenseEnabled = false
    local defenseConnection = nil
    local defenseMode = "Fling"
    local GrabEvents = RS:WaitForChild("GrabEvents")
    local SetNetworkOwner = GrabEvents:WaitForChild("SetNetworkOwner")
    local DestroyGrabLine = GrabEvents:FindFirstChild("DestroyGrabLine")
    local CreateGrabEvent = GrabEvents:FindFirstChild("CreateGrabLine")

    local function getCounterAttacker()
        local char = P.Character
        if not char then return nil end
        local head = char:FindFirstChild("Head")
        local owner = head and head:FindFirstChild("PartOwner")
        if not owner or not owner:IsA("StringValue") then return nil end
        return Players:FindFirstChild(owner.Value)
    end
    local function counterRoot(attacker)
        return attacker and attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
    end
    local function performFling(attacker)
        local root = counterRoot(attacker)
        local myRoot = P.Character and P.Character:FindFirstChild("HumanoidRootPart")
        if not root or not myRoot then return end
        pcall(function()
            SetNetworkOwner:FireServer(root, root.CFrame)
            if DestroyGrabLine then DestroyGrabLine:FireServer(root) end
            local away = (root.Position - myRoot.Position).Unit
            local bv = Instance.new("BodyVelocity")
            bv.Name = "RinneganFling"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(away.X, 0, away.Z) * 999999999
            bv.P = 12500
            bv.Parent = root
            Debris:AddItem(bv, 0.1)
        end)
    end
    local function performKill(attacker)
        local root = counterRoot(attacker)
        if not root then return end
        pcall(function()
            SetNetworkOwner:FireServer(root, root.CFrame)
            if DestroyGrabLine then DestroyGrabLine:FireServer(root) end
            local away = Vector3.new(0, -90, 0)
            local bv = Instance.new("BodyVelocity")
            bv.Name = "RinneganSpy"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = away
            bv.P = 12500
            bv.Parent = root
            Debris:AddItem(bv, 0.1)
        end)
    end
    local function performHeaven(attacker)
        local root = counterRoot(attacker)
        if not root then return end
        pcall(function()
            SetNetworkOwner:FireServer(root, root.CFrame)
            if DestroyGrabLine then DestroyGrabLine:FireServer(root) end
            root.CFrame = CFrame.new(0, 100, 0)
            local bv = Instance.new("BodyVelocity")
            bv.Name = "RinneganHeaven"
            bv.MaxForce = Vector3.new(0, math.huge, 0)
            bv.Velocity = Vector3.new(0, 100, 0)
            bv.P = 12500
            bv.Parent = root
            Debris:AddItem(bv, 5)
        end)
    end
    local function performKick(attacker)
        local root = counterRoot(attacker)
        if not root then return end
        pcall(function()
            SetNetworkOwner:FireServer(root, root.CFrame)
            if DestroyGrabLine then DestroyGrabLine:FireServer(root) end
            root.CFrame = CFrame.new(0, 999999999999, 0)
            local bv = Instance.new("BodyVelocity")
            bv.Name = "RinneganHeaven"
            bv.MaxForce = Vector3.new(0, math.huge, 0)
            bv.Velocity = Vector3.new(0, 99999999999999, 0)
            bv.P = 12500
            bv.Parent = root
            Debris:AddItem(bv, 5)
        end)
    end
    local function performRagdoll(attacker)
        local root = counterRoot(attacker)
        if not root then return end
        pcall(function()
            SetNetworkOwner:FireServer(root, root.CFrame)
            if DestroyGrabLine then DestroyGrabLine:FireServer(root) end
            local bv = Instance.new("BodyVelocity")
            bv.Name = "RinneganSpy"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(0, -90, 0)
            bv.P = 12500
            bv.Parent = root
            Debris:AddItem(bv, 0.1)
        end)
    end
    local function performHell(attacker)
        local root = counterRoot(attacker)
        if not root then return end
        pcall(function()
            SetNetworkOwner:FireServer(root, root.CFrame)
            if DestroyGrabLine then DestroyGrabLine:FireServer(root) end
            for _, part in ipairs(attacker.Character:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored then part.CanCollide = false end
            end
            local bv = Instance.new("BodyVelocity")
            bv.Name = "RinneganSpy"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(0, -1E7, 0)
            bv.P = 12500
            bv.Parent = root
            Debris:AddItem(bv, 0.1)
        end)
    end
    local function performChina(attacker)
        local root = counterRoot(attacker)
        if not root then return end
        pcall(function()
            SetNetworkOwner:FireServer(root, root.CFrame)
            if DestroyGrabLine then DestroyGrabLine:FireServer(root) end
            root.CFrame = CFrame.new(591, 153, -101)
        end)
    end
    local crazyline = false
    local function performSpamGrabLines()
        while crazyline do
            local attacker = getCounterAttacker()
            if attacker and attacker.Character then
                local head = attacker.Character:FindFirstChild("Head")
                local hrp = attacker.Character:FindFirstChild("HumanoidRootPart")
                if head and hrp and CreateGrabEvent then
                    for _ = 1, 3 do pcall(function() CreateGrabEvent:FireServer(head, head.CFrame) end) end
                    for _ = 1, 3 do pcall(function() CreateGrabEvent:FireServer(hrp, hrp.CFrame) end) end
                end
            end
            task.wait(1)
        end
    end
    local function startDefense()
        if defenseConnection then return end
        defenseConnection = RunService.Heartbeat:Connect(function()
            if not defenseEnabled then return end
            local attacker = getCounterAttacker()
            if not attacker then return end
            if defenseMode == "Fling" then performFling(attacker)
            elseif defenseMode == "Kill" then performKill(attacker)
            elseif defenseMode == "Heaven" then performHeaven(attacker)
            elseif defenseMode == "Kick" then performKick(attacker)
            elseif defenseMode == "Ragdoll" then performRagdoll(attacker)
            elseif defenseMode == "Hell" then performHell(attacker)
            elseif defenseMode == "China" then performChina(attacker)
            elseif defenseMode == "GrabLine" then
                if not crazyline then
                    crazyline = true
                    task.spawn(performSpamGrabLines)
                end
            end
        end)
    end
    local function stopDefense()
        if defenseConnection then
            pcall(function() defenseConnection:Disconnect() end)
            defenseConnection = nil
        end
        crazyline = false
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if char then
                for _, obj in ipairs(char:GetDescendants()) do
                    if obj:IsA("BodyVelocity") and (obj.Name == "RinneganFling" or obj.Name == "RinneganHeaven" or obj.Name == "RinneganSpy") then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end
        end
    end
    CounterGroup:AddDropdown("CounterMode", {
        Text = "Counter Mode",
        Values = {"Fling", "Kill", "Heaven", "Kick", "Ragdoll", "Hell", "China", "GrabLine"},
        Default = "Fling",
        Multi = false,
        Callback = function(mode) defenseMode = mode end,
    })
    CounterGroup:AddToggle("CounterAttacks", {
        Text = "Counter Attack",
        Default = false,
        Callback = function(enabled)
            defenseEnabled = enabled
            if enabled then startDefense() else stopDefense() end
        end,
    })
    P.CharacterAdded:Connect(function()
        if defenseEnabled then
            task.wait(1)
            startDefense()
        end
    end)


    pcall(function()
        Library:OnUnload(function()
            if DefAntiKickThread then pcall(function() task.cancel(DefAntiKickThread) end) end
            if autoResetConnection then pcall(function() autoResetConnection:Disconnect() end) end
            if autoLeaveConnection then pcall(function() autoLeaveConnection:Disconnect() end) end
            if counterConn then pcall(function() counterConn:Disconnect() end) end
            pcall(stopAntiBlobmanGrab)
            DefClearAntiKickToy()
        end)
    end)
end
end

--enddefence tab

    end

    local ok, err = pcall(__RunFullDefence)
    if not ok then
        warn("[Defence] error:", err)
        Library:Notify({Title = "mdcp", Description = "Defence load error (see console)", Time = 5})
    end
end

-- Line Lag / Packet Lag
local LagState = {
    LineLag = false,
    LineLagTask = nil,
    LagLines = 11,
    PacketLag = false,
    PacketLagTask = nil,
    Packets = 0.35,
    PacketPrefix = "RSC | ",
    PacketDelay = 0.1,
}
local ExtendGrabLine = GrabEvents and GrabEvents:FindFirstChild("ExtendGrabLine")

local function LineLag_Start()
    if LagState.LineLagTask then return end
    LagState.LineLag = true
    if MDCP_Notify then MDCP_Notify("Line Lag", "Line Lag - Server ON", 3, "Line Lag") end
    LagState.LineLagTask = task.spawn(function()
        while LagState.LineLag do
            local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
            if spawnLocation and CreateGrabLine then
                local n = -2 ^ (20 + (LagState.LagLines or 11))
                pcall(function()
                    CreateGrabLine:FireServer(spawnLocation, CFrame.new(n, 0, n))
                end)
            end
            task.wait()
        end
        pcall(function()
            if CreateGrabLine then CreateGrabLine:FireServer() end
        end)
    end)
end

local function LineLag_Stop()
    LagState.LineLag = false
    if LagState.LineLagTask then
        pcall(function() task.cancel(LagState.LineLagTask) end)
        LagState.LineLagTask = nil
    end
    pcall(function()
        if CreateGrabLine then CreateGrabLine:FireServer() end
    end)
end

local function PacketLag_Start()
    if LagState.PacketLagTask then return end
    local packet = ExtendGrabLine
    if not packet then
        if MDCP_Notify then MDCP_Notify("Packet Lag", "ExtendGrabLine missing", 3, "Packet Lag") end
        Library:Notify({Title = "mdcp", Description = "ExtendGrabLine が見つかりません", Time = 3})
        return
    end
    LagState.PacketLag = true
    if MDCP_Notify then MDCP_Notify("Packet Lag", "Packet Lag - Server ON", 3, "Packet Lag") end
    LagState.PacketLagTask = task.spawn(function()
        while LagState.PacketLag do
            local prefix = LagState.PacketPrefix or "RSC | "
            local size = math.floor((LagState.Packets or 0.35) * 1000000)
            local payload = prefix .. string.rep("0", math.max(0, size - #prefix))
            pcall(function()
                packet:FireServer(payload)
            end)
            task.wait(LagState.PacketDelay or 0.1)
        end
    end)
end

local function PacketLag_Stop()
    LagState.PacketLag = false
    if LagState.PacketLagTask then
        pcall(function() task.cancel(LagState.PacketLagTask) end)
        LagState.PacketLagTask = nil
    end
end

local function PacketLag_Once()
    local packet = ExtendGrabLine
    if not packet then
        Library:Notify({Title = "mdcp", Description = "ExtendGrabLine が見つかりません", Time = 3})
        return
    end
    local prefix = LagState.PacketPrefix or "RSC | "
    local size = math.floor((LagState.Packets or 0.35) * 1000000)
    local payload = prefix .. string.rep("0", math.max(0, size - #prefix))
    pcall(function() packet:FireServer(payload) end)
end


-- ---------- Defense: Anti Kick (手裏剣のみ ON/OFF) ----------
do
    local AKGroup = Tabs.Defense:AddRightGroupbox("Anti Kick")

    local AntiKick = {
        Enabled = false,
        Item = "NinjaShuriken",
        RotationX = 90,
        RotationY = 111,
        RotationZ = 0,
        OffsetX = 0,
        OffsetY = 0,
        OffsetZ = 0.1,
        Transparency = 0,
        Task = nil,
    }

    local function AK_TargetCF()
        return CFrame.new(AntiKick.OffsetX, AntiKick.OffsetY, AntiKick.OffsetZ)
            * CFrame.Angles(math.rad(AntiKick.RotationX), math.rad(AntiKick.RotationY), math.rad(AntiKick.RotationZ))
    end

    local function AK_FindPCLD()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        for _, v in ipairs(Workspace:GetChildren()) do
            if v.Name == "PlayerCharacterLocationDetector" then
                if (v.Position - hrp.Position).Magnitude < 1.2 then return v end
            end
        end
        return nil
    end

    local function AK_Claim(part)
        if not part then return false end
        for _ = 1, 10 do
            pcall(function() SetNetworkOwner:FireServer(part, part.CFrame) end)
            local po = part:FindFirstChild("PartOwner")
            if po and po.Value == LocalPlayer.Name then return true end
            task.wait()
        end
        return false
    end

    local function AK_Spawn(pcld)
        pcall(function()
            SpawnRemote:InvokeServer(AntiKick.Item, pcld.CFrame * CFrame.new(0, 0, 15), Vector3.zero)
        end)
        local folder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
        if not folder then return nil end
        for _ = 1, 40 do
            local toy = folder:FindFirstChild(AntiKick.Item) or folder:FindFirstChild("AntiKick")
            if toy then
                pcall(function() toy.Name = "AntiKick" end)
                return toy
            end
            task.wait(0.03)
        end
        return nil
    end

    local function AK_Destroy(toy)
        if toy then pcall(function() DestroyToy:FireServer(toy) end) end
    end

    local function AK_Stick(sticky, fire)
        if StickyPartEvent and sticky and fire then
            pcall(function() StickyPartEvent:FireServer(sticky, fire, AK_TargetCF()) end)
        end
    end

    local function AK_IsDrifted(sticky, fire, weld)
        if not weld or not weld.Parent or weld.Part1 ~= fire then return true end
        if sticky and fire and (sticky.Position - fire.Position).Magnitude > 3.5 then return true end
        return false
    end

    local function AK_Loop()
        while AntiKick.Enabled do
            task.wait()
            local char = LocalPlayer.Character
            if not char then continue end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then continue end
            local pcld = AK_FindPCLD()
            if not pcld then continue end
            local fire = hrp:FindFirstChild("FirePlayerPart")
            if not fire then continue end

            local folder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
            local toy = folder and folder:FindFirstChild("AntiKick")
            if not toy then toy = AK_Spawn(pcld) end
            if not toy then continue end

            local sticky = toy:FindFirstChild("StickyPart") or toy:WaitForChild("StickyPart", 1)
            if not sticky then AK_Destroy(toy) continue end
            local query = nil
            for _, v in ipairs(toy:GetChildren()) do
                if v:IsA("BasePart") and v.CanQuery then query = v break end
            end
            if not query then continue end
            if not AK_Claim(query) then continue end

            local weld = sticky:FindFirstChild("StickyWeld")
            if AK_IsDrifted(sticky, fire, weld) then
                for _ = 1, 8 do
                    AK_Stick(sticky, fire)
                    task.wait()
                end
            end

            while AntiKick.Enabled and hum.Health > 0 and toy.Parent and fire.Parent do
                weld = sticky:FindFirstChild("StickyWeld")
                if AK_IsDrifted(sticky, fire, weld) then
                    AK_Stick(sticky, fire)
                else
                    AK_Stick(sticky, fire)
                end
                for _, v in ipairs(toy:GetChildren()) do
                    if v:IsA("BasePart") then
                        if v.Transparency ~= 1 then v.Transparency = AntiKick.Transparency end
                        v.CanCollide = false
                    end
                end
                RunService.Heartbeat:Wait()
            end
        end
    end

    AKGroup:AddToggle("AK_Shuriken", {
        Text = "Anti Kick (Shuriken)",
        Default = false,
        Callback = function(on)
            AntiKick.Enabled = on
            if on then
                if AntiKick.Task then pcall(function() task.cancel(AntiKick.Task) end) end
                AntiKick.Task = task.spawn(AK_Loop)
            else
                AntiKick.Enabled = false
                local folder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                local toy = folder and folder:FindFirstChild("AntiKick")
                if toy then AK_Destroy(toy) end
            end
        end,
    })
end

-- ---------- Server タブ ----------
do
    local NoBlobGroup = Tabs.Server:AddLeftGroupbox("NoBlob Kick All")

    NoBlobGroup:AddButton({
        Text = "Execute NoBlob Kick All",
        Func = function()
            if State.NoblobRunning then
                Library:Notify({Title = "mdcp The Final Nox", Description = "Already running", Time = 2})
                return
            end
            NB_Execute()
        end,
    })

    NoBlobGroup:AddButton({
        Text = "Stop",
        Func = function()
            NB_Stop()
        end,
    })

    local WhitelistGroup = Tabs.Server:AddRightGroupbox("Whitelist")

    WhitelistGroup:AddToggle("NoblobWhitelistFriends", {
        Text = "Whitelist Friends",
        Default = false,
        Callback = function(Value)
            State.NoblobWhitelistFriends = Value
            if Value then
                task.spawn(function()
                    local count = 0
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and NB_IsFriend(plr) then
                            count = count + 1
                        end
                    end
                    Library:Notify({Title = "mdcp The Final Nox", Description = "Whitelisted friends: " .. count, Time = 3})
                end)
            end
        end,
    })

    -- Line Lag / Packet Lag
    local LineLagGroup = Tabs.Server:AddLeftGroupbox("Line Lag")
    LineLagGroup:AddToggle("LineLagToggle", {
        Text = "Line-Lag Server",
        Default = false,
        Callback = function(on)
            if on then LineLag_Start() else LineLag_Stop() end
        end,
    })
    LineLagGroup:AddSlider("LineLagStrength", {
        Text = "Lag Strength",
        Min = 1, Max = 11, Default = 11, Rounding = 0,
        Callback = function(v) LagState.LagLines = v end,
    })

    local PacketLagGroup = Tabs.Server:AddRightGroupbox("Packet Lag")
    PacketLagGroup:AddToggle("PacketLagToggle", {
        Text = "Packet-Lag Server",
        Default = false,
        Callback = function(on)
            if on then PacketLag_Start() else PacketLag_Stop() end
        end,
    })
    PacketLagGroup:AddSlider("PacketSize", {
        Text = "Packet Size (MB)",
        Min = 0.05, Max = 1, Default = 0.35, Rounding = 2,
        Callback = function(v) LagState.Packets = v end,
    })
    PacketLagGroup:AddSlider("PacketDelay", {
        Text = "Delay (s)",
        Min = 0.01, Max = 0.5, Default = 0.1, Rounding = 2,
        Callback = function(v) LagState.PacketDelay = v end,
    })
    PacketLagGroup:AddButton({
        Text = "Send One Packet",
        Func = function()
            PacketLag_Once()
        end,
    })
    local NotifGroup = Tabs.Server:AddLeftGroupbox("Notifications")
    NotifGroup:AddToggle("NotifMaster", {
        Text = "Enable Notifications",
        Default = true,
        Callback = function(on)
            NotifCenter.enabled = on
            NotifCenter.disabled = not on
        end,
    })
    NotifGroup:AddDropdown("NotifDisableType", {
        Text = "Notification Type",
        Values = _G._notifTypeList,
        Default = "All Notifications",
        Callback = function(v)
            _G._mdcpNotifPick = v
        end,
    })
    NotifGroup:AddButton({
        Text = "Mute / Unmute Selected Type",
        Func = function()
            local v = _G._mdcpNotifPick or "All Notifications"
            local cfg = _G._notifTargetSettings[v]
            if cfg then
                cfg.Disabled = not cfg.Disabled
                MDCP_Notify("Notifications", v .. (cfg.Disabled and " muted" or " unmuted"), 2, "Custom Notification")
            end
        end,
    })
    NotifGroup:AddButton({
        Text = "Test Packet Lag Notif",
        Func = function() MDCP_Notify("Packet Lag", "Packet Lag Detected!", 5, "Packet Lag") end,
    })
    NotifGroup:AddButton({
        Text = "Test Line Lag Notif",
        Func = function() MDCP_Notify("Line Lag", "Line Lag Detected!", 5, "Line Lag") end,
    })
    NotifGroup:AddButton({
        Text = "Test Kick Frame Notif",
        Func = function() MDCP_Notify("Kick Frame Detected", "Kick Frame Detected!", 4, "Kick Frame Detected") end,
    })
    NotifGroup:AddButton({
        Text = "Test Kill Notif",
        Func = function() MDCP_Notify("Kill", "Kill!", 3, "Kill") end,
    })
    NotifGroup:AddButton({
        Text = "Test Player Kicked Notif",
        Func = function() MDCP_Notify("Player Kicked", "Player left / kicked", 5, "Player Kicked") end,
    })
    NotifGroup:AddButton({
        Text = "Test GUCCI ON Notif",
        Func = function() MDCP_Notify("GUCCI ON", "GUCCI ON", 2, "GUCCI ON") end,
    })

end

-- ---------- Break タブ ----------
do
    local PlotGroup = Tabs.Break:AddLeftGroupbox("Plot Break")

    PlotGroup:AddDropdown("BreakPlotSelect", {
        Text = "破壊するプロット",
        Default = {},
        Values = {"Plot1","Plot2","Plot3","Plot4","Plot5"},
        Multi = true,
        Callback = function(opts)
            BreakState.SelectedPlots = opts or {}
        end,
    })

    PlotGroup:AddToggle("BreakPlot", {
        Text = "Plot Break",
        Default = false,
        Callback = function(on)
            if on then Break_PlotStart() else Break_PlotStop() end
        end,
    })

    local GroundGroup = Tabs.Break:AddRightGroupbox("Ground Break")
    GroundGroup:AddToggle("BreakGround", {
        Text = "Break Ground (下のパーツ)",
        Default = false,
        Callback = function(on)
            if on then Break_GroundStart() else Break_GroundStop() end
        end,
    })

    local PBGroup = Tabs.Break:AddRightGroupbox("Plot Breaker (1-5)")

    PBGroup:AddButton({
        Text = "Break All Plots (1-5)",
        Func = function()
            PB_BreakAll()
        end,
    })

    PBGroup:AddButton({
        Text = "Stop / Cleanup",
        Func = function()
            PB_Cleanup()
        end,
    })
end


-- ---------- Fun タブ ----------
do
    local DanceGroup = Tabs.Fun:AddLeftGroupbox("Dance")

    DanceGroup:AddDropdown("DanceType", {
        Text = "Dance",
        Default = Fun.selectedDance or "Floss Dance",
        Values = Fun.danceNames or {"Floss Dance"},
        Callback = function(v)
            Fun.selectedDance = v
            if Fun.activeMode == "dance" then
                local char = LocalPlayer.Character
                if char then
                    Fun.playSelectedDance(char)
                end
            end
        end,
    })

    DanceGroup:AddToggle("EnableDance", {
        Text = "Enable Dance",
        Default = false,
        Callback = function(on)
            if on then
                Fun.isDancingV2 = false
                Fun.stopHipDanceV2(LocalPlayer.Character)
                local char = LocalPlayer.Character
                if char then
                    Fun.playSelectedDance(char)
                end
            else
                Fun.stopPose()
            end
        end,
    })

    DanceGroup:AddToggle("RagdollPose", {
        Text = "Ragdoll Pose",
        Default = false,
        Callback = function(on)
            if on then
                local char = LocalPlayer.Character
                if char then
                    Fun.startRagdollOnly(char)
                end
            else
                Fun.stopPose()
            end
        end,
    })

    DanceGroup:AddButton({
        Text = "Stop",
        Func = function()
            Fun.stopPose()
            Fun.isDancingV2 = false
            Fun.stopHipDanceV2(LocalPlayer.Character)
            pcall(function()
                if Options.EnableDance then Options.EnableDance:SetValue(false) end
                if Options.RagdollPose then Options.RagdollPose:SetValue(false) end
                if Options.DanceV2Toggle then Options.DanceV2Toggle:SetValue(false) end
            end)
        end,
    })

    local DanceV2Group = Tabs.Fun:AddRightGroupbox("Dance V2")

    local HttpService = game:GetService("HttpService")
    local danceV2Values = {"Click Refresh..."}

    local DanceV2Dropdown = DanceV2Group:AddDropdown("DanceV2Dropdown", {
        Text = "Select Dance V2",
        Default = "Click Refresh...",
        Values = danceV2Values,
        Callback = function(selectedDanceNameV2)
            if selectedDanceNameV2 == "Click Refresh..."
                or selectedDanceNameV2 == "No dances found"
                or selectedDanceNameV2 == "" then
                return
            end
            Fun.selectedDanceNameV2 = selectedDanceNameV2
            local raw = Fun.currentDanceRawTableV2[selectedDanceNameV2]
            if not raw then
                Fun.activeDanceDataV2 = nil
                return
            end
            local ok2, activeDanceDataV2 = pcall(function()
                if type(raw) == "table" then
                    return raw
                end
                return HttpService:JSONDecode(raw)
            end)
            if ok2 and activeDanceDataV2 then
                Fun.activeDanceDataV2 = activeDanceDataV2
                if Fun.isDancingV2 and LocalPlayer.Character then
                    Fun.startHipDanceV2(LocalPlayer.Character)
                end
            else
                Fun.activeDanceDataV2 = nil
                Library:Notify({Title = "mdcp", Description = "Dance V2 parse failed", Time = 3})
            end
        end,
    })

    DanceV2Group:AddToggle("DanceV2Toggle", {
        Text = "Enable Dance V2",
        Default = false,
        Callback = function(on)
            Fun.isDancingV2 = on
            if on then
                Fun.stopPose()
                if Fun.activeDanceDataV2 and LocalPlayer.Character then
                    Fun.startHipDanceV2(LocalPlayer.Character)
                else
                    Library:Notify({Title = "mdcp", Description = "Dance V2 を選んで Refresh してください", Time = 3})
                    Fun.isDancingV2 = false
                    task.defer(function()
                        pcall(function()
                            if Options.DanceV2Toggle then Options.DanceV2Toggle:SetValue(false) end
                        end)
                    end)
                end
            else
                Fun.stopHipDanceV2(LocalPlayer.Character)
            end
        end,
    })

    DanceV2Group:AddButton({
        Text = "Refresh List",
        Func = function()
            local list = Fun.refreshDanceV2List()
            pcall(function()
                DanceV2Dropdown:SetValues(list)
                if list[1] and list[1] ~= "No dances found" then
                    DanceV2Dropdown:SetValue(list[1])
                end
            end)
            Library:Notify({
                Title = "mdcp",
                Description = "Dance V2: " .. tostring(#list) .. " loaded",
                Time = 3,
            })
        end,
    })

    task.spawn(function()
        task.wait(1)
        local list = Fun.refreshDanceV2List()
        pcall(function()
            DanceV2Dropdown:SetValues(list)
            if list[1] and list[1] ~= "No dances found" then
                DanceV2Dropdown:SetValue(list[1])
            end
        end)
    end)
end


-- ---------- Home タブ (Resonance-style Movement) ----------
do
    local Values = Tabs.Home:AddLeftGroupbox("Values", "user")
    local Character = Tabs.Home:AddLeftGroupbox("Character", "badge")

    local Move = {
        WalkSpeed = false,
        JumpPower = false,
        InfJump = false,
        Noclip = false,
        Flight = false,
        Spin = false,
    }
    local MoveVal = {
        WalkSpeed = 16,
        JumpPower = 50,
        FlightSpeed = 1,
        SpinSpeed = 15,
    }

    local flyBV, flyBG = nil, nil
    local spinBV = nil
    local moveConns = {}

    local function CharParts()
        local char = LocalPlayer.Character
        if not char then return nil, nil, nil end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        return char, hrp, hum
    end

    local function ToggleCollisions(char, canCollide)
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = canCollide
            end
        end
    end

    local function StopFly()
        if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
        if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
        local _, hrp, hum = CharParts()
        if hum then pcall(function() hum.PlatformStand = false end) end
    end

    local function StartFly()
        StopFly()
        local char, hrp, hum = CharParts()
        if not hrp or not hum then return end
        hum.PlatformStand = true
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        flyBG.P = 1e4
        flyBG.Parent = hrp
    end

    local function UpdateFlight()
        if not Move.Flight then return end
        local char, hrp, hum = CharParts()
        if not hrp then return end
        if not flyBV or not flyBV.Parent then StartFly() end
        if not flyBV then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
            move -= Vector3.new(0, 1, 0)
        end
        -- mobile thumbstick via humanoid MoveDirection
        if move.Magnitude < 0.05 and hum then
            local md = hum.MoveDirection
            if md.Magnitude > 0.05 then
                move = Vector3.new(md.X, 0, md.Z)
            end
        end
        local speed = (MoveVal.FlightSpeed or 1) * 50
        local target = (move.Magnitude > 0 and move.Unit * speed) or Vector3.zero
        flyBV.Velocity = flyBV.Velocity:Lerp(target, move.Magnitude > 0 and 0.22 or 0.12)
        flyBG.CFrame = cam.CFrame
    end

    local function UpdateWalkSpeed()
        if not Move.WalkSpeed then return end
        local _, hrp, hum = CharParts()
        if not hum then return end
        -- FTAP often uses HumanoidCreature; also set normal WalkSpeed
        pcall(function() hum.WalkSpeed = MoveVal.WalkSpeed end)
        local hc = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidCreature")
        if hc and hc:IsA("Humanoid") then
            pcall(function() hc.WalkSpeed = MoveVal.WalkSpeed end)
        end
        if hrp and hum.MoveDirection.Magnitude > 0 then
            -- extra boost like resonance translate
            pcall(function()
                hrp.CFrame = hrp.CFrame + hum.MoveDirection * math.max(0, (MoveVal.WalkSpeed - 16) * 0.02)
            end)
        end
    end

    -- Values sliders
    Values:AddSlider("Home_WalkSpeedVal", {
        Text = "Walk Speed",
        Default = 16, Min = 5, Max = 1000, Rounding = 0,
        Callback = function(v) MoveVal.WalkSpeed = v end,
    })
    Values:AddSlider("Home_JumpPowerVal", {
        Text = "Jump Power",
        Default = 50, Min = 24, Max = 1000, Rounding = 0,
        Callback = function(v) MoveVal.JumpPower = v end,
    })
    Values:AddSlider("Home_FlightSpeedVal", {
        Text = "Flight Speed",
        Default = 1, Min = 1, Max = 20, Rounding = 1,
        Callback = function(v) MoveVal.FlightSpeed = v end,
    })
    Values:AddSlider("Home_SpinSpeedVal", {
        Text = "Spin Speed",
        Default = 15, Min = 5, Max = 1000, Rounding = 0,
        Callback = function(v) MoveVal.SpinSpeed = v end,
    })

    -- Character toggles
    Character:AddToggle("Home_Flight", {
        Text = "Flight",
        Default = false,
        Callback = function(on)
            Move.Flight = on
            if on then StartFly() else StopFly() end
        end,
    })
    Character:AddToggle("Home_WalkSpeed", {
        Text = "Walkspeed",
        Default = false,
        Callback = function(on)
            Move.WalkSpeed = on
            if not on then
                local _, _, hum = CharParts()
                if hum then pcall(function() hum.WalkSpeed = 16 end) end
            end
        end,
    })
    Character:AddToggle("Home_JumpPower", {
        Text = "Jump Power",
        Default = false,
        Callback = function(on)
            Move.JumpPower = on
            if not on then
                local _, _, hum = CharParts()
                if hum then
                    pcall(function() hum.JumpPower = 50 end)
                    pcall(function() hum.JumpHeight = 7.2 end)
                end
            end
        end,
    })
    Character:AddToggle("Home_Noclip", {
        Text = "Noclip",
        Default = false,
        Callback = function(on)
            Move.Noclip = on
            if not on then
                local char = LocalPlayer.Character
                if char then ToggleCollisions(char, true) end
            end
        end,
    })
    Character:AddToggle("Home_InfJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(on)
            Move.InfJump = on
        end,
    })
    Character:AddToggle("Home_Spin", {
        Text = "Spin",
        Default = false,
        Callback = function(on)
            Move.Spin = on
            if spinBV then pcall(function() spinBV:Destroy() end) spinBV = nil end
            if on then
                local _, hrp = CharParts()
                if hrp then
                    spinBV = Instance.new("BodyAngularVelocity")
                    spinBV.MaxTorque = Vector3.new(0, math.huge, 0)
                    spinBV.AngularVelocity = Vector3.new(0, MoveVal.SpinSpeed, 0)
                    spinBV.Parent = hrp
                end
            end
        end,
    })

    -- Runtime loops (Resonance style)
    table.insert(moveConns, RunService.Heartbeat:Connect(function()
        if Move.WalkSpeed then UpdateWalkSpeed() end
        if Move.JumpPower then
            local _, _, hum = CharParts()
            if hum then
                pcall(function() hum.JumpPower = MoveVal.JumpPower end)
                pcall(function() hum.JumpHeight = MoveVal.JumpPower / 3.5 end)
            end
        end
        if Move.Noclip then
            local char = LocalPlayer.Character
            if char then ToggleCollisions(char, false) end
        end
        if Move.Spin and spinBV and spinBV.Parent then
            spinBV.AngularVelocity = Vector3.new(0, MoveVal.SpinSpeed, 0)
        elseif Move.Spin and not spinBV then
            local _, hrp = CharParts()
            if hrp then
                spinBV = Instance.new("BodyAngularVelocity")
                spinBV.MaxTorque = Vector3.new(0, math.huge, 0)
                spinBV.AngularVelocity = Vector3.new(0, MoveVal.SpinSpeed, 0)
                spinBV.Parent = hrp
            end
        end
    end))
    table.insert(moveConns, RunService.RenderStepped:Connect(function()
        if Move.Flight then UpdateFlight() end
    end))
    table.insert(moveConns, UserInputService.JumpRequest:Connect(function()
        if not Move.InfJump then return end
        local _, _, hum = CharParts()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end))
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.3)
        if Move.Flight then StartFly() end
        if not Move.Noclip then
            local char = LocalPlayer.Character
            if char then ToggleCollisions(char, true) end
        end
        if spinBV then pcall(function() spinBV:Destroy() end) spinBV = nil end
    end)
end

-- ---------- Camera タブ ----------
do
    local CamGroup = Tabs.Camera:AddLeftGroupbox("Camera")
    CamGroup:AddToggle("ThirdPersonT", {
        Text = "Third Person View",
        Default = false,
        Callback = function(on)
            if on then ThirdPerson_Start() else ThirdPerson_Stop() end
        end,
    })

    State.FOVEnabled = false
    State.FOVValue = 70
    State.FOVOriginal = nil
    local function FOV_Apply()
        pcall(function()
            local cam = workspace.CurrentCamera
            if not cam then return end
            if State.FOVEnabled then
                if State.FOVOriginal == nil then
                    State.FOVOriginal = cam.FieldOfView
                end
                cam.FieldOfView = State.FOVValue
            elseif State.FOVOriginal ~= nil then
                cam.FieldOfView = State.FOVOriginal
                State.FOVOriginal = nil
            end
        end)
    end

    CamGroup:AddToggle("Cam_FOVToggle", {
        Text = "Custom FOV",
        Default = false,
        Callback = function(on)
            State.FOVEnabled = on
            FOV_Apply()
        end,
    })
    CamGroup:AddSlider("Cam_FOV", {
        Text = "FOV Value",
        Min = 70, Max = 120, Default = 70, Rounding = 0,
        Callback = function(v)
            State.FOVValue = v
            if State.FOVEnabled then FOV_Apply() end
        end,
    })
end

-- ---------- Visuals タブ (ESP) ----------
do
    local ESPGroup = Tabs.Visuals:AddLeftGroupbox("Player ESP")
    local WorldESP = Tabs.Visuals:AddRightGroupbox("World ESP")

    -- Player Name ESP
    local NameESP = { enabled = false, tags = {}, conns = {} }
    local function PlayerChams_Apply(char, on)
        if not char then return end
        local hl = char:FindFirstChild("mdcp_PlayerChams")
        if on then
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = "mdcp_PlayerChams"
                hl.FillColor = Color3.fromRGB(200, 40, 40)
                hl.OutlineColor = Color3.fromRGB(0, 0, 0)
                hl.FillTransparency = 0.45
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = char
            end
        else
            if hl then hl:Destroy() end
        end
    end
    local function NameESP_Clear(player)
        local tag = NameESP.tags[player]
        if tag then pcall(function() tag:Destroy() end) NameESP.tags[player] = nil end
        if player and player.Character then PlayerChams_Apply(player.Character, false) end
    end
    local function NameESP_Update(player)
        if not NameESP.enabled or player == LocalPlayer then return end
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        if not head then NameESP_Clear(player); PlayerChams_Apply(char, false) return end
        PlayerChams_Apply(char, true)
        local tag = NameESP.tags[player]
        if not tag or not tag.Parent then
            local bb = Instance.new("BillboardGui")
            bb.Name = "mdcp_NameESP"
            bb.Size = UDim2.new(0, 200, 0, 40)
            bb.StudsOffset = Vector3.new(0, 2.5, 0)
            bb.AlwaysOnTop = true
            bb.Adornee = head
            bb.Parent = head
            local tl = Instance.new("TextLabel")
            tl.BackgroundTransparency = 1
            tl.Size = UDim2.fromScale(1, 1)
            tl.Font = Enum.Font.GothamBold
            tl.TextSize = 14
            tl.TextColor3 = Color3.fromRGB(255, 255, 255)
            tl.TextStrokeTransparency = 0.4
            tl.Text = player.DisplayName or player.Name
            tl.Parent = bb
            NameESP.tags[player] = bb
        else
            tag.Adornee = head
            local tl = tag:FindFirstChildOfClass("TextLabel")
            if tl then tl.Text = player.DisplayName or player.Name end
        end
    end
    local function NameESP_Refresh()
        for _, plr in ipairs(Players:GetPlayers()) do
            if NameESP.enabled then NameESP_Update(plr) else NameESP_Clear(plr) end
        end
    end
    ESPGroup:AddToggle("Vis_PlayerESP", {
        Text = "Player ESP",
        Default = false,
        Callback = function(on)
            NameESP.enabled = on
            NameESP_Refresh()
            if on then
                for _, c in ipairs(NameESP.conns) do pcall(function() c:Disconnect() end) end
                NameESP.conns = {}
                table.insert(NameESP.conns, Players.PlayerAdded:Connect(function(p)
                    p.CharacterAdded:Connect(function() task.wait(0.3); if NameESP.enabled then NameESP_Update(p) end end)
                end))
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then
                        table.insert(NameESP.conns, p.CharacterAdded:Connect(function()
                            task.wait(0.3); if NameESP.enabled then NameESP_Update(p) end
                        end))
                    end
                end
            else
                for _, c in ipairs(NameESP.conns) do pcall(function() c:Disconnect() end) end
                NameESP.conns = {}
                for p in pairs(NameESP.tags) do NameESP_Clear(p) end
            end
        end,
    })

    -- Anti Kick ESP (Sticky / Pyramid highlight)
    local StickESP = {
        enabled = false,
        mode = "Black-White",
        conns = {},
        tracked = {},
    }
    local function StickESP_Colors()
        if StickESP.mode == "Gray-Black" then
            return Color3.fromRGB(80,80,80), Color3.fromRGB(0,0,0), 0.35, 0
        elseif StickESP.mode == "Black" then
            return Color3.fromRGB(0,0,0), Color3.fromRGB(0,0,0), 0, 0
        elseif StickESP.mode == "Red" then
            return Color3.fromRGB(200,40,40), Color3.fromRGB(0,0,0), 0.45, 0
        end
        -- default match NL red box look
        return Color3.fromRGB(200,40,40), Color3.fromRGB(0,0,0), 0.45, 0
    end
    local function StickESP_ClearModel(model)
        if not model then return end
        local h = model:FindFirstChildOfClass("Highlight")
        if h then h:Destroy() end
        for _, ch in pairs(model:GetChildren()) do
            local h2 = ch:FindFirstChildOfClass("Highlight")
            if h2 then h2:Destroy() end
        end
        StickESP.tracked[model] = nil
    end
    local function StickESP_Apply(model)
        if not StickESP.enabled or not model or not model.Parent then return end
        if not model:FindFirstChild("StickyPart") then StickESP_ClearModel(model) return end
        local fill, outline, ft, ot = StickESP_Colors()
        local function ensureHL(target)
            local hl = target:FindFirstChildOfClass("Highlight")
            if not hl then
                hl = Instance.new("Highlight")
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = target
            end
            hl.FillColor = fill
            hl.OutlineColor = outline
            hl.FillTransparency = ft
            hl.OutlineTransparency = ot
        end
        if model:FindFirstChild("Pyramid") then
            for _, ch in pairs(model:GetChildren()) do
                if ch:IsA("BasePart") and ch.Name == "Pyramid" then ensureHL(ch) end
            end
        else
            ensureHL(model)
        end
        StickESP.tracked[model] = true
    end
    local function StickESP_Scan()
        for _, plr in ipairs(Players:GetPlayers()) do
            local folder = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
            if folder then
                for _, child in pairs(folder:GetChildren()) do
                    if child:IsA("Model") and child:FindFirstChild("StickyPart") then
                        StickESP_Apply(child)
                    end
                end
            end
        end
    end
    ESPGroup:AddToggle("Vis_StickESP", {
        Text = "Anti Kick ESP",
        Default = false,
        Callback = function(on)
            StickESP.enabled = on
            for _, c in ipairs(StickESP.conns) do pcall(function() c:Disconnect() end) end
            StickESP.conns = {}
            if on then
                StickESP_Scan()
                table.insert(StickESP.conns, Workspace.DescendantAdded:Connect(function(obj)
                    if not StickESP.enabled then return end
                    if obj.Name == "StickyPart" and obj.Parent and obj.Parent:IsA("Model") then
                        StickESP_Apply(obj.Parent)
                    end
                end))
                table.insert(StickESP.conns, RunService.Heartbeat:Connect(function()
                    -- light refresh every ~1s via counter would be better; keep simple scan throttle
                end))
            else
                for model in pairs(StickESP.tracked) do StickESP_ClearModel(model) end
            end
        end,
    })
    ESPGroup:AddDropdown("Vis_StickESPMode", {
        Text = "Anti Kick ESP Mode",
        Values = { "Red", "Black-White", "Gray-Black", "Black" },
        Default = "Red",
        Callback = function(v)
            StickESP.mode = v or "Black-White"
            if StickESP.enabled then
                for model in pairs(StickESP.tracked) do
                    StickESP_ClearModel(model)
                end
                StickESP_Scan()
            end
        end,
    })

    -- PCLD ESP (use existing helpers if present)
    WorldESP:AddToggle("Vis_PCLD", {
        Text = "PCLD ESP",
        Default = false,
        Callback = function(on)
            State.PCLD_ESP_Active = on
            if on then
                if PCLD_ESP_Start then PCLD_ESP_Start() end
            else
                if PCLD_ESP_Stop then PCLD_ESP_Stop() end
            end
        end,
    })
    WorldESP:AddDropdown("Vis_PCLD_Style", {
        Text = "PCLD Style",
        Values = { "Gray / Black Outline", "White / Black Outline", "Gray / White Outline", "Brick (Solid Red)" },
        Default = "Brick (Solid Red)",
        Callback = function(style)
            if style == "Brick (Solid Red)" then
                State.PCLD_ESP_Color = Color3.fromRGB(200, 40, 40)
            elseif style == "White / Black Outline" then
                State.PCLD_ESP_Color = Color3.fromRGB(255, 255, 255)
            elseif style == "Gray / White Outline" then
                State.PCLD_ESP_Color = Color3.fromRGB(120, 120, 120)
            else
                State.PCLD_ESP_Color = Color3.fromRGB(80, 80, 80)
            end
            for obj, box in pairs(State.PCLD_ESP_Boxes or {}) do
                if box then box.Color3 = State.PCLD_ESP_Color end
            end
        end,
    })
end

-- ---------- Shader タブ ----------
do
    local Lighting = game:GetService("Lighting")
    local ShaderGroup = Tabs.Shader:AddLeftGroupbox("Shaders")
    local WorldGroup = Tabs.Shader:AddRightGroupbox("World")

    local function ClearNamed(...)
        for _, name in ipairs({...}) do
            local o = Lighting:FindFirstChild(name)
            if o then o:Destroy() end
        end
    end

    ShaderGroup:AddToggle("Vis_BlueShaders", {
        Text = "Blue Shaders",
        Default = false,
        Callback = function(on)
            if on then
                pcall(function()
                    local galCC = Lighting:FindFirstChild("mdcp_GalCC") or Instance.new("ColorCorrectionEffect")
                    galCC.Name = "mdcp_GalCC"
                    galCC.Saturation = 0.5
                    galCC.Contrast = 0.3
                    galCC.TintColor = Color3.fromRGB(240, 220, 255)
                    galCC.Parent = Lighting
                    galCC.Enabled = true
                    local galBloom = Lighting:FindFirstChild("mdcp_GalBloom") or Instance.new("BloomEffect")
                    galBloom.Name = "mdcp_GalBloom"
                    galBloom.Intensity = 0.3
                    galBloom.Threshold = 0.8
                    galBloom.Parent = Lighting
                    galBloom.Enabled = true
                    local galAtmo = Lighting:FindFirstChild("mdcp_GalAtmo") or Instance.new("Atmosphere")
                    galAtmo.Name = "mdcp_GalAtmo"
                    galAtmo.Density = 0.3
                    galAtmo.Color = Color3.fromRGB(40, 0, 100)
                    galAtmo.Parent = Lighting
                    Lighting.GlobalShadows = true
                end)
            else
                ClearNamed("mdcp_GalCC", "mdcp_GalBloom", "mdcp_GalAtmo")
                pcall(function() Lighting.GlobalShadows = false end)
            end
        end,
    })

    local function ApplyPurple()
        Lighting.ClockTime = 6.7
        Lighting.Brightness = 2.27
        Lighting.FogColor = Color3.fromRGB(94, 76, 106)
        Lighting.FogEnd = 1000
        Lighting.FogStart = 0
        Lighting.ExposureCompensation = 0.24
        Lighting.ShadowSoftness = 0
        Lighting.Ambient = Color3.fromRGB(59, 33, 27)
        for _, child in pairs(Lighting:GetChildren()) do
            if child.Name:match("^mdcp_Purple") then child:Destroy() end
        end
        local bloom = Instance.new("BloomEffect", Lighting)
        bloom.Name = "mdcp_PurpleBloom"
        bloom.Intensity = 0.1
        bloom.Threshold = 0
        bloom.Size = 100
        local blur = Instance.new("BlurEffect", Lighting)
        blur.Name = "mdcp_PurpleBlur"
        blur.Size = 2
        local cc = Instance.new("ColorCorrectionEffect", Lighting)
        cc.Name = "mdcp_PurpleCC"
        cc.Saturation = 0.05
        cc.TintColor = Color3.fromRGB(255, 224, 219)
        local sun = Instance.new("SunRaysEffect", Lighting)
        sun.Name = "mdcp_PurpleSun"
        sun.Intensity = 0.05
        local sky = Instance.new("Sky", Lighting)
        sky.Name = "mdcp_PurpleSky"
        sky.SkyboxUp = "rbxassetid://323493360"
        sky.SkyboxLf = "rbxassetid://323494252"
        sky.SkyboxBk = "rbxassetid://323494035"
        sky.SkyboxFt = "rbxassetid://323494130"
        sky.SkyboxDn = "rbxassetid://323494368"
        sky.SkyboxRt = "rbxassetid://323494067"
        sky.SunAngularSize = 14
    end
    local function ClearPurple()
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
        Lighting.ExposureCompensation = 0
        Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
        for _, child in pairs(Lighting:GetChildren()) do
            if child.Name:match("^mdcp_Purple") then child:Destroy() end
        end
        if not Lighting:FindFirstChildOfClass("Sky") then
            Instance.new("Sky", Lighting)
        end
    end

    ShaderGroup:AddToggle("Vis_PurpleShaders", {
        Text = "Purple Shaders",
        Default = false,
        Callback = function(on)
            if on then ApplyPurple() else ClearPurple() end
        end,
    })

    WorldGroup:AddButton({
        Text = "Real Ocean",
        Func = function()
            local ocean = Workspace:FindFirstChild("Ocean") or Workspace:FindFirstChild("ocean")
            if not ocean then
                for _, o in ipairs(Workspace:GetDescendants()) do
                    if o.Name:lower() == "ocean" then ocean = o break end
                end
            end
            if ocean then
                pcall(function()
                    -- replace with terrain water if possible
                    local terrain = Workspace.Terrain
                    if ocean:IsA("BasePart") then
                        terrain:FillBlock(ocean.CFrame, ocean.Size, Enum.Material.Water)
                        ocean:Destroy()
                    elseif ocean:IsA("Model") then
                        for _, p in ipairs(ocean:GetDescendants()) do
                            if p:IsA("BasePart") then
                                terrain:FillBlock(p.CFrame, p.Size, Enum.Material.Water)
                            end
                        end
                        ocean:Destroy()
                    end
                end)
                Library:Notify({Title = "mdcp", Description = "Ocean replaced with terrain water", Time = 3})
            else
                Library:Notify({Title = "mdcp", Description = "Ocean model not found", Time = 3})
            end
        end,
    })
end

-- Watermark
-- Format: "mdcp vX.X | X fps | Y ms"  (FPS/Ping 表示)
-- ============================================================
do
    local StatsService = game:GetService("Stats")
    local VERSION_STR = "v4.0"
    local Watermark

    -- Prefer Obsidian DraggableLabel (draggable style) when available
    local okLabel, labelObj = pcall(function()
        if type(Library.AddDraggableLabel) == "function" then
            return Library:AddDraggableLabel("mdcp " .. VERSION_STR, MDCP_ICON)
        end
        return nil
    end)

    if okLabel and labelObj and labelObj.SetText then
        Watermark = labelObj
        pcall(function()
            if Watermark.SetVisible then Watermark:SetVisible(true) end
            if Watermark.SetIcon then
                pcall(function() Watermark:SetIcon("shield") end)
            end
        end)

        task.spawn(function()
            while Watermark and Watermark.Label and Watermark.Label.Parent do
                local fps = 60
                local ping = 0
                pcall(function()
                    fps = math.floor(StatsService.Workspace.Heartbeat:GetValue())
                end)
                pcall(function()
                    ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
                end)
                Watermark:SetText(("mdcp %s | %s fps | %s ms"):format(VERSION_STR, fps, ping))
                task.wait(1)
            end
        end)
    else
        -- Fallback: DraggableLabel 相当の見た目 (mdcp カラー)
        local function getGuiParent()
            local protect = protect_gui or protectgui or (syn and syn.protect_gui)
            local root = gethui and gethui() or (get_hidden_gui and get_hidden_gui())
            local gui = Instance.new("ScreenGui")
            gui.Name = "mdcpWatermark"
            gui.ResetOnSpawn = false
            gui.IgnoreGuiInset = true
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.DisplayOrder = 999999
            if type(protect) == "function" then pcall(protect, gui) end
            if root then pcall(function() gui.Parent = root end) end
            if not gui.Parent then pcall(function() gui.Parent = CoreGui end) end
            if not gui.Parent then
                pcall(function() gui.Parent = LocalPlayer:WaitForChild("PlayerGui", 3) end)
            end
            return gui
        end

        local gui = getGuiParent()
        if gui then
            -- Theme colors (mdcp: dark bg / white text / white outline)
            local bgColor = Color3.fromRGB(25, 25, 25)
            local fontColor = Color3.fromRGB(255, 255, 255)
            local outlineColor = Color3.fromRGB(255, 255, 255)
            pcall(function()
                if Library.Scheme then
                    bgColor = Library.Scheme.BackgroundColor or bgColor
                    fontColor = Library.Scheme.FontColor or fontColor
                    outlineColor = Library.Scheme.OutlineColor or outlineColor
                end
            end)

            local Label = Instance.new("TextLabel")
            Label.Name = "mdcpWatermarkLabel"
            Label.AutomaticSize = Enum.AutomaticSize.XY
            Label.BackgroundColor3 = bgColor
            Label.BackgroundTransparency = 0
            Label.BorderSizePixel = 0
            Label.Position = UDim2.fromOffset(6, 6)
            Label.Size = UDim2.fromOffset(0, 0)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 15
            Label.TextColor3 = fontColor
            Label.Text = "mdcp " .. VERSION_STR
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextYAlignment = Enum.TextYAlignment.Center
            Label.ZIndex = 1
            Label.Parent = gui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = Label

            local padding = Instance.new("UIPadding")
            padding.PaddingBottom = UDim.new(0, 6)
            padding.PaddingLeft = UDim.new(0, 34)
            padding.PaddingRight = UDim.new(0, 12)
            padding.PaddingTop = UDim.new(0, 6)
            padding.Parent = Label

            local stroke = Instance.new("UIStroke")
            stroke.Color = outlineColor
            stroke.Thickness = 1
            stroke.Transparency = 0
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Parent = Label

            -- left icon: 盾マーク
            local icon = Instance.new("TextLabel")
            icon.Name = "Icon"
            icon.BackgroundTransparency = 1
            icon.Size = UDim2.fromOffset(18, 18)
            icon.AnchorPoint = Vector2.new(0, 0.5)
            icon.Position = UDim2.new(0, -24, 0.5, 0)
            icon.Font = Enum.Font.GothamBold
            icon.TextSize = 15
            icon.TextColor3 = fontColor
            icon.Text = "🛡"
            icon.ZIndex = 2
            icon.Parent = Label

            local function SetText(text)
                Label.Text = text
            end

            Watermark = {
                Label = Label,
                SetText = function(_, text) SetText(text) end,
                SetVisible = function(_, v) Label.Visible = v end,
            }

            -- drag (MakeDraggable 相当)
            local dragging, dragStart, startPos
            Label.Active = true
            Label.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragStart = input.Position
                    startPos = Label.Position
                end
            end)
            Label.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if not dragging then return end
                if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                    local delta = input.Position - dragStart
                    Label.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end)

            -- update loop (1s, Heartbeat + Data Ping)
            task.spawn(function()
                while Watermark and Watermark.Label and Watermark.Label.Parent do
                    local fps = 60
                    local ping = 0
                    pcall(function()
                        fps = math.floor(StatsService.Workspace.Heartbeat:GetValue())
                    end)
                    pcall(function()
                        ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
                    end)
                    Watermark:SetText(("mdcp %s | %s fps | %s ms"):format(VERSION_STR, fps, ping))
                    task.wait(1)
                end
            end)
        end
    end
end

-- ============================================================
-- セーブ/テーマ適用
-- ============================================================
SaveManager:LoadAutoloadConfig()

Library:Notify({Title = "mdcp The Final Nox", Description = "v4.0 Loaded", Time = 3})

-- 起動時チャット
task.spawn(function()
    local msg = "mdcp The Final nox"
    local ok = pcall(function()
        local TCS = game:GetService("TextChatService")
        local channel = TCS:FindFirstChild("TextChannels") and TCS.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            channel:SendAsync(msg)
            return
        end
    end)
    if not ok then
        pcall(function()
            local ev = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
            if ev and ev:FindFirstChild("SayMessageRequest") then
                ev.SayMessageRequest:FireServer(msg, "All")
            end
        end)
    end
end)
