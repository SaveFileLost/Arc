local Arc = require(game.ReplicatedStorage.Packages.Arc)

local SomeController = Arc.Controller "SomeController"

function SomeController:init()
    print("controller initted")
end

function SomeController:start()
    print("controller started")
end

function SomeController:simulate(playerState, input)
    -- cause a misprediction on purpose
    if Arc.IS_SERVER then
        playerState.florb = 4
    else
        playerState.florb = 5
    end
end

return nil