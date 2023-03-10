local Arc = require(game.ReplicatedStorage.Packages.arc)

local SomeService = Arc.Service "SomeService"

function SomeService:init()
    print("service initted")
end

function SomeService:start()
    
end

return nil