local UserInputService = game:GetService("UserInputService")

local Arc = require(game.ReplicatedStorage.Packages.Arc)
local Util = require(game.ReplicatedStorage.Common.Util)

local camAngleX = 0
local camAngleY = 0

Arc.setInputBuilder(function(input)
    local zMove = Util.boolToNum(UserInputService:IsKeyDown(Enum.KeyCode.W)) - Util.boolToNum(UserInputService:IsKeyDown(Enum.KeyCode.W))
    local xMove = Util.boolToNum(UserInputService:IsKeyDown(Enum.KeyCode.D)) - Util.boolToNum(UserInputService:IsKeyDown(Enum.KeyCode.A))
    input.moveDirection = Util.safeUnit(Vector3.new(xMove, 0, zMove))

    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    local mouseChange = UserInputService:GetMouseDelta() * 0.1

    camAngleY = (camAngleY - mouseChange.X) % 360
    camAngleX = math.clamp((camAngleX - mouseChange.Y), -89, 89)

    input.viewCf = CFrame.Angles(0, math.rad(camAngleY), 0) * CFrame.Angles(math.rad(camAngleX), 0, 0)
end)

Arc.addFolder(game.ReplicatedStorage.Common.Controllers)

Arc.start()