local Arc = require(game.ReplicatedStorage.Packages.arc).common()

local MovementController = Arc.Controller "MovementController"
MovementController.simulationPriority = 1 -- after CameraController

function MovementController:simulate(player, input)
    local moveDir = player.viewCf:VectorToWorldSpace(input.moveDirection)
    player.position += moveDir
end

return nil