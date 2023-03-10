local Arc = require(game.ReplicatedStorage.Packages.arc)

Arc.Entities.Entity {
    kind = "Player";
    
    init = function(ent)
        ent.position = Vector3.new(0, 0, 0)
        ent.viewCf = CFrame.identity;
    end;

    write = function(ent, buffer)
        buffer:writeVector3(ent.position)
        -- viewCf is not serialized as it is constructed from input later
    end;

    read = function(ent, buffer)
        ent.position = buffer:readVector3()
    end;

    compare = function(ent1, ent2)
        return Arc.Comparison.compareVector3s(ent1.position, ent2.position)
    end;
}

return nil