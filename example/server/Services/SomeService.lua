local Arc = require(game.ReplicatedStorage.Packages.arc).server()

local SomeService = Arc.Service "SomeService"

function SomeService:init()
end

function SomeService:serverRpcTest(player: Player, someUInt: number)
    print("received server rpc", player, someUInt)
end
SomeService:bindServerRpc("serverRpcTest")

function SomeService:start()
end

return nil