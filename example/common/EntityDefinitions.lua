local Arc = require(game.ReplicatedStorage.Packages.arc)

Arc.Entity {
    kind = "Player";
    
    netProperties = {
        position = Arc.NetVector3;
        megaPosition = Arc.NetVector3;
        gigaPosition = Arc.NetVector3;
        bibaPosition = Arc.NetVector3;
        vivaPosition = Arc.NetVector3;
    };

    init = function(ent)
        ent.position = Vector3.new(0, 0, 0)
        ent.megaPosition = Vector3.new(0, 0, 0)
        ent.gigaPosition = Vector3.new(0, 0, 0)
        ent.bibaPosition = Vector3.new(0, 0, 0)
        ent.vivaPosition = Vector3.new(0, 0, 0)
        ent.viewCf = CFrame.identity;
    end;
}

return nil