-- xzzyscripts Hub | Universal & MM2/MMV
-- Created by xzzyscripts

local Rayfield = loadstring(game:HttpGet('https://sirius.menu'))()

local Window = Rayfield:CreateWindow({
   Name = "xzzyscripts Hub | Universal & MM2/MMV",
   LoadingTitle = "xzzyscripts Hub",
   LoadingSubtitle = "by xzzyscripts",
   ConfigurationSaving = {
      Enabled = false
   }
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Tabs
local MoveTab = Window:CreateTab("Movement", 4483362458)
local VisualTab = Window:CreateTab("ESP & Visuals", 4483362458)

-- State Variables
local FlyEnabled = false
local FlySpeed = 50
local NoclipEnabled = false
local InfiniteJumpEnabled = false
local BodyGyro, BodyVelocity

local PlayerESPEnabled = false
local MM2RoleESPEnabled = false
local GunDropESPEnabled = false
local ESPHighlights = {}
local GunHighlight = nil

---------------------------------------------------------
-- 1. MOVEMENT (FLY, SPEED, JUMP, NOCLIP)
---------------------------------------------------------
local function StartFly()
   local char = LocalPlayer.Character
   local root = char and char:FindFirstChild("HumanoidRootPart")
   local hum = char and char:FindFirstChildOfClass("Humanoid")
   if not root or not hum then return end

   hum.PlatformStand = true

   BodyGyro = Instance.new("BodyGyro")
   BodyGyro.P = 9e4
   BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
   BodyGyro.CFrame = root.CFrame
   BodyGyro.Parent = root

   BodyVelocity = Instance.new("BodyVelocity")
   BodyVelocity.Velocity = Vector3.zero
   BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
   BodyVelocity.Parent = root

   task.spawn(function()
      while FlyEnabled and char and root and hum.Parent do
         RunService.RenderStepped:Wait()
         local moveDir = Vector3.zero
         local camCF = Camera.CFrame

         if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
         if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
         if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
         if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
         if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
         if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.yAxis end

         if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
         end

         BodyVelocity.Velocity = moveDir * FlySpeed
         BodyGyro.CFrame = camCF
      end
   end)
end

local function StopFly()
   if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end
   if BodyVelocity then BodyVelocity:Destroy() BodyVelocity = nil end
   local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
   if hum then hum.PlatformStand = false end
end

MoveTab:CreateToggle({
   Name = "Enable Fly",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      FlyEnabled = Value
      if FlyEnabled then StartFly() else StopFly() end
   end,
})

MoveTab:CreateSlider({
   Name = "Fly Speed",
   Range = {10, 300},
   Increment = 5,
   Suffix = " Speed",
   CurrentValue = 50,
   Flag = "FlySpeedSlider",
   Callback = function(Value)
      FlySpeed = Value
   end,
})

MoveTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 1,
   Suffix = " Speed",
   CurrentValue = 16,
   Flag = "WalkSpeedSlider",
   Callback = function(Value)
      if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
         LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = Value
      end
   end,
})

MoveTab:CreateSlider({
   Name = "JumpPower",
   Range = {50, 300},
   Increment = 5,
   Suffix = " Power",
   CurrentValue = 50,
   Flag = "JumpPowerSlider",
   Callback = function(Value)
      local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
      if hum then
         hum.UseJumpPower = true
         hum.JumpPower = Value
      end
   end,
})

MoveTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfJumpToggle",
   Callback = function(Value)
      InfiniteJumpEnabled = Value
   end,
})

UserInputService.JumpRequest:Connect(function()
   if InfiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
      LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
   end
end)

MoveTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "NoclipToggle",
   Callback = function(Value)
      NoclipEnabled = Value
   end,
})

RunService.Stepped:Connect(function()
   if NoclipEnabled and LocalPlayer.Character then
      for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
         if part:IsA("BasePart") then
            part.CanCollide = false
         end
      end
   end
end)

---------------------------------------------------------
-- 2. UNIVERSAL, MM2/MMV ROLE & DROPPED GUN ESP
---------------------------------------------------------
local function GetMM2RoleColor(player)
   local backpack = player:FindFirstChild("Backpack")
   local char = player.Character

   local function hasTool(name)
      return (backpack and backpack:FindFirstChild(name)) or (char and char:FindFirstChild(name))
   end

   if hasTool("Knife") then
      return Color3.fromRGB(255, 50, 50) -- Murderer (Red)
   elseif hasTool("Gun") then
      return Color3.fromRGB(50, 130, 255) -- Sheriff (Blue)
   else
      return Color3.fromRGB(50, 255, 100) -- Innocent (Green)
   end
end

local function UpdateESP()
   -- Player & Role ESP
   for _, player in ipairs(Players:GetPlayers()) do
      if player ~= LocalPlayer and player.Character then
         local highlight = ESPHighlights[player]

         if PlayerESPEnabled or MM2RoleESPEnabled then
            if not highlight or not highlight.Parent then
               highlight = Instance.new("Highlight")
               highlight.Name = "xzzyESP"
               highlight.FillTransparency = 0.5
               highlight.OutlineTransparency = 0
               highlight.Parent = player.Character
               ESPHighlights[player] = highlight
            end

            if MM2RoleESPEnabled then
               highlight.FillColor = GetMM2RoleColor(player)
            else
               highlight.FillColor = Color3.fromRGB(255, 255, 0)
            end
         else
            if highlight then
               highlight:Destroy()
               ESPHighlights[player] = nil
            end
         end
      end
   end

   -- Dropped Gun ESP
   local gunDrop = workspace:FindFirstChild("GunDrop", true)
   if GunDropESPEnabled and gunDrop then
      if not GunHighlight or GunHighlight.Parent ~= gunDrop then
         if GunHighlight then GunHighlight:Destroy() end
         GunHighlight = Instance.new("Highlight")
         GunHighlight.Name = "xzzyGunESP"
         GunHighlight.FillColor = Color3.fromRGB(0, 255, 255) -- Cyan
         GunHighlight.FillTransparency = 0.3
         GunHighlight.OutlineTransparency = 0
         GunHighlight.Parent = gunDrop
      end
   else
      if GunHighlight then
         GunHighlight:Destroy()
         GunHighlight = nil
      end
   end
end

RunService.Heartbeat:Connect(function()
   if PlayerESPEnabled or MM2RoleESPEnabled or GunDropESPEnabled then
      UpdateESP()
   end
end)

Players.PlayerRemoving:Connect(function(player)
   if ESPHighlights[player] then
      ESPHighlights[player]:Destroy()
      ESPHighlights[player] = nil
   end
end)

VisualTab:CreateToggle({
   Name = "Universal Player ESP",
   CurrentValue = false,
   Flag = "UniversalESP",
   Callback = function(Value)
      PlayerESPEnabled = Value
      if not Value and not MM2RoleESPEnabled then UpdateESP() end
   end,
})

VisualTab:CreateToggle({
   Name = "MM2 / MMV Role ESP (Knife/Gun)",
   CurrentValue = false,
   Flag = "MM2RoleESP",
   Callback = function(Value)
      MM2RoleESPEnabled = Value
      if not Value and not PlayerESPEnabled then UpdateESP() end
   end,
})

VisualTab:CreateToggle({
   Name = "Dropped Gun ESP (Cyan)",
   CurrentValue = false,
   Flag = "GunDropESP",
   Callback = function(Value)
      GunDropESPEnabled = Value
      if not Value then UpdateESP() end
   end,
})
