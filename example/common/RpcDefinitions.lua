local Arc = require(game.ReplicatedStorage.Packages.arc)

Arc.Rpc.Client {
    name = "playFartSound";
    write = function(buffer, position)
        return buffer:writeVector3(position)
    end;
    read = function(buffer)
        return buffer:readVector3()
    end;
}

return nil