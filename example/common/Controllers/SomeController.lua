local Arc = require(game.ReplicatedStorage.Packages.Arc)

local SomeController = Arc.Controller "SomeController"

function SomeController:init()
    print("controller initted")
end

function SomeController:start()
    print("controller started")
end

return nil