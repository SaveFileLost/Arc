local PubTypes = require(script.Parent.Parent.PubTypes)
local Similar = require(script.Parent.Parent.Similar)

local NetVector3: PubTypes.NetProperty = {
    write = function(value, buffer)
        buffer:writeVector3(value)
    end;

    read = function(buffer)
        return buffer:readVector3()
    end;

    areSimilar = function(v1, v2)
        return Similar.vector3s(v1, v2)
    end;
}

return table.freeze(NetVector3)