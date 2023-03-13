local Arc = require(game.ReplicatedStorage.Packages.arc).common()

Arc.ClientRpc {
    name = "createPart";
    write = function(buffer, position)
        buffer:writeVector3(position)
    end;
    read = function(buffer)
        return buffer:readVector3()
    end;
}

Arc.ServerRpc {
    name = "serverRpcTest";
    write = function(buf, someUInt)
        buf:writeUInt(16, someUInt)
    end;
    read = function(buffer)
        return buffer:readUInt(16)
    end;
}

return nil