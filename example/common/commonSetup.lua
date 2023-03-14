local UserInputService = game:GetService("UserInputService")

local Arc = require(game.ReplicatedStorage.Packages.arc)
local Util = require(game.ReplicatedStorage.Common.Util)

local camAngleX: number = 0
local camAngleY: number = 0

local function buildInput(input)
    local zMove = Util.boolToNum(UserInputService:IsKeyDown(Enum.KeyCode.W)) - Util.boolToNum(UserInputService:IsKeyDown(Enum.KeyCode.S))
    local xMove = Util.boolToNum(UserInputService:IsKeyDown(Enum.KeyCode.D)) - Util.boolToNum(UserInputService:IsKeyDown(Enum.KeyCode.A))
    input.moveDirection = Util.safeUnit(Vector3.new(xMove, 0, -zMove))

    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    local mouseChange = UserInputService:GetMouseDelta() * 0.1

    camAngleY = (camAngleY - mouseChange.X) % 360
    camAngleX = math.clamp((camAngleX - mouseChange.Y), -89, 89)

    input.camAngleX = camAngleX
    input.camAngleY = camAngleY

    input.mousePressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    input.mouse2Pressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

local function writeInput(input, buffer)
    buffer:writeVector3(input.moveDirection)
    buffer:writeFloat64(input.camAngleX)
    buffer:writeFloat64(input.camAngleY)
    buffer:writeBool(input.mousePressed)
    buffer:writeBool(input.mouse2Pressed)
end

local function readInput(input, buffer)
    input.moveDirection = buffer:readVector3()
    input.camAngleX = buffer:readFloat64()
    input.camAngleY = buffer:readFloat64()
    input.mousePressed = buffer:readBool()
    input.mouse2Pressed = buffer:readBool()
end

local function commonSetup()
    Arc.setInputBuilder(buildInput)
    Arc.setInputWriter(writeInput)
    Arc.setInputReader(readInput)
end

return commonSetup