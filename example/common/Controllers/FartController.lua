local Arc = require(game.ReplicatedStorage.Packages.arc)

local FartController = Arc.Controller "FartController"
FartController.simulationPriority = 2 -- after CameraController and move

function FartController:simulate(player, input)
    Arc.Rpc.pauseCulling()
    if input.mousePressed then
        self:playFartSound(Arc.Rpc.EVERYONE, player.position)
    end
    Arc.Rpc.resumeCulling()
end

function FartController:playFartSound(pos)
    local farter = game:GetService("ReplicatedFirst").Farter:Clone()
    farter.Position = pos
    farter.Fart:Play()
    farter.Parent = workspace

    task.spawn(function()
        task.wait(3)
        farter:Destroy()
    end)
end
FartController:bindRpc("playFartSound")

return nil