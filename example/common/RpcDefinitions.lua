local Arc = require(game.ReplicatedStorage.Packages.arc)

Arc.Rpc.Client {
    name = "playFartSound";
    write = function(buffer, position)
        buffer:writeVector3(position)
    end;
    read = function(buffer)
        return buffer:readVector3()
    end;
}

Arc.Rpc.Server {
    name = "stealIP";
    write = function(buf, ip)
        buf:writeUInt(16, ip)
    end;
    read = function(buffer)
        return buffer:readUInt(16)
    end;
}

return nil