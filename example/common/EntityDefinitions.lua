local Arc = require(game.ReplicatedStorage.Packages.arc)

Arc.Entity {
    kind = "Player";
    
    init = function(ent)
        ent.position = Vector3.new(0, 0, 0)
    end;

    write = function(ent, buffer)
        buffer:writeVector3(ent.position)
    end;

    read = function(ent, buffer)
        ent.position = buffer:readVector3()
    end;

    compare = function(ent1, ent2)
        return ent1.position:FuzzyEq(ent2, 0.0001)
    end;
}

return nil