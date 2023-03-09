local Arc = require(game.ReplicatedStorage.Packages.arc)

local MovementController = Arc.Controller "MovementController"
MovementController.simulationPriority = 0 -- after CameraController

function MovementController:simulate(playerState, input)
    if playerState.position == nil then
        playerState.position = Vector3.zero
    end

    local moveDir = playerState.viewCf:VectorToWorldSpace(input.moveDirection)
    playerState.position += moveDir
end

return nil