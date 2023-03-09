local RstkBitBuffer = require(script.Parent.Parent.Parent.BitBuffer)

local BitBuffer = {}
BitBuffer.__index = BitBuffer

function BitBuffer.new()
    return setmetatable({_buffer = RstkBitBuffer.new()}, BitBuffer)
end

function BitBuffer.fromString(str: string)
    return setmetatable({_buffer = RstkBitBuffer.FromString(str)}, BitBuffer)
end

function BitBuffer:writeFloat32(f: number)
    self._buffer:WriteFloat32(f)
end

function BitBuffer:readFloat32(): number
    return self._buffer:ReadFloat32()
end

function BitBuffer:writeFloat64(f: number)
    self._buffer:WriteFloat64(f)
end

function BitBuffer:readFloat64(): number
    return self._buffer:ReadFloat64()
end

function BitBuffer:writeVector3(v: Vector3)
    self:writeFloat32(v.X)
    self:writeFloat32(v.Y)
    self:writeFloat32(v.Z)
end

function BitBuffer:readVector3(): Vector3
    return Vector3.new(self:readFloat32(), self:readFloat32(), self:readFloat32())
end

function BitBuffer:toString()
    return self._buffer:ToString()
end

return BitBuffer