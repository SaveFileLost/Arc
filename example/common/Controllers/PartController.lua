local Arc = require(game.ReplicatedStorage.Packages.arc)

local PartController = Arc.Controller "PartController"
PartController.simulationPriority = 2 -- after CameraController and move

function PartController:simulate(player, input)
    if input.mousePressed then
        self:createPart(Arc.RPC_EVERYONE, player.position)
    end
end

function PartController:createPart(pos)
    local part = Instance.new("Part")
    part.Position = pos
    part.Parent = workspace

    game:GetService("Debris"):AddItem(part, 3)

    Arc.callServerRpc("serverRpcTest", 5015)
end
PartController:bindClientRpc("createPart")

return nil