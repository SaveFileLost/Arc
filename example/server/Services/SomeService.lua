local Arc = require(game.ReplicatedStorage.Packages.arc)

local SomeService = Arc.Service "SomeService"

function SomeService:init()
    print("service initted")
end

function SomeService:start()
    local ent1 = Arc.Entities.spawn("Player")
    local ent2 = Arc.Entities.spawn("Player")

    Arc.Entities.setParent(ent2, ent1)

    print(Arc.Entities.getChildren(ent1))
    print(Arc.Entities.getParent(ent2))
end

return nil