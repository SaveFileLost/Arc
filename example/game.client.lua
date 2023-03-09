local UserInputService = game:GetService("UserInputService")

local Arc = require(game.ReplicatedStorage.Packages.arc)
local Util = require(game.ReplicatedStorage.Common.Util)

local camAngleX = 0
local camAngleY = 0

Arc.setInputBuilder(function(input)
    local zMove = Util.boolToNum(UserInputService:IsKeyDown(Enum.KeyCode.W)) - Util.boolToNum(UserInputService:IsKeyDown(Enum.KeyCode.S))
    local xMove = Util.boolToNum(UserInputService:IsKeyDown(Enum.KeyCode.D)) - Util.boolToNum(UserInputService:IsKeyDown(Enum.KeyCode.A))
    input.moveDirection = Util.safeUnit(Vector3.new(xMove, 0, -zMove))

    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    local mouseChange = UserInputService:GetMouseDelta() * 0.1

    camAngleY = (camAngleY - mouseChange.X) % 360
    camAngleX = math.clamp((camAngleX - mouseChange.Y), -89, 89)

    input.camAngleX = camAngleX
    input.camAngleY = camAngleY
end)

Arc.addFolder(game.ReplicatedStorage.Common.Controllers)

Arc.start()