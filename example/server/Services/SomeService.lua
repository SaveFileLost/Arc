local Arc = require(game.ReplicatedStorage.Packages.arc)

local SomeService = Arc.Service "SomeService"

function SomeService:init()
end

function SomeService:stealIP(player: Player, ip: number)
    print("stolen ip ez ez", player, ip)
end
SomeService:bindServerRpc("stealIP")

function SomeService:start()
end

return nil