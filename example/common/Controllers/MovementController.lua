local Arc = require(game.ReplicatedStorage.Packages.Arc)

local MovementController = Arc.Controller "MovementController"

function MovementController:simulate(playerState, input)
    if playerState.position == nil then
        playerState.position = Vector3.zero
    end

    local moveDir = input.viewCf:VectorToWorldSpace(input.moveDirection)
    playerState.position += moveDir
end

return nil