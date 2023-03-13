local Arc = require(game.ReplicatedStorage.Packages.arc)

Arc.Entity {
    kind = "Player";
    
    netProperties = {
        position = Arc.NetVector3;
    };

    init = function(ent)
        ent.position = Vector3.new(0, 0, 0)
        ent.viewCf = CFrame.identity;
    end;
}

return nil