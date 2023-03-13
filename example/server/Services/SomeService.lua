local Arc = require(game.ReplicatedStorage.Packages.arc)

local SomeService = Arc.Service "SomeService"

function SomeService:init()
end

function SomeService:serverRpcTest(player: Player, num: number)
    print("received server rpc", player, num)
end
SomeService:bindServerRpc("serverRpcTest")

function SomeService:start()
end

return nil