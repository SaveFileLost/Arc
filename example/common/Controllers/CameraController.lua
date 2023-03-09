local Arc = require(game.ReplicatedStorage.Packages.Arc)

local CameraController = Arc.Controller "CameraController"
CameraController.simulationPriority = 0

local function constructCameraCFrame(camAngleX: number, camAngleY: number): CFrame
    return CFrame.Angles(0, math.rad(camAngleY), 0) * CFrame.Angles(math.rad(camAngleX), 0, 0)
end

function CameraController:simulate(playerState, input)
    playerState.viewCf = constructCameraCFrame(input.camAngleX, input.camAngleY)
end

function CameraController:frameSimulate(playerState, input)
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    workspace.CurrentCamera.CFrame = constructCameraCFrame(input.camAngleX, input.camAngleY) + playerState.position
end

return nil