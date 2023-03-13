local Arc = require(game.ReplicatedStorage.Packages.arc)

local FartController = Arc.Controller "FartController"
FartController.simulationPriority = 2 -- after CameraController and move

function FartController:simulate(player, input)
    if input.mousePressed then
        self:createPart(Arc.RPC_EVERYONE, player.position)
    end
end

function FartController:createPart(pos)
    local part = Instance.new("Part")
    part.Position = pos
    part.Parent = workspace

    game:GetService("Debris"):AddItem(part, 3)

    Arc.callServerRpc("serverRpcTest", 5015)
end
FartController:bindClientRpc("createPart")

return nil