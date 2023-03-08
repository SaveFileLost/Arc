local Arc = require(game.ReplicatedStorage.Packages.Arc)

local SomeService = Arc.Service "SomeService"

function SomeService:init()
    print("service initted")
end

function SomeService:start()
    print("service started")
end

return nil