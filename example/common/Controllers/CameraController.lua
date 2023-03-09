local Arc = require(game.ReplicatedStorage.Packages.Arc)

local CameraController = Arc.Controller "CameraController"

function CameraController:frameSimulate(playerState, input)
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    workspace.CurrentCamera.CFrame =  input.viewCf + playerState.position
end

return nil