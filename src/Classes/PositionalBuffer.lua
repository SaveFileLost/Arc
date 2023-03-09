local PositionalBuffer = {}
PositionalBuffer.__index = PositionalBuffer

function PositionalBuffer.new(maxSize: number)
	return setmetatable({
		_maxSize = maxSize;
		_size = 0;
		_buffer = {};
	}, PositionalBuffer)
end

function PositionalBuffer:get(pos: number)
	return self._buffer[pos]
end

function PositionalBuffer:set(pos: number, value)
	self._size = math.max(self._size, pos)
	self._buffer[pos] = value
	
	self._buffer[self._size - self._maxSize] = nil
end

function PositionalBuffer:latest()
	return self._buffer[self._size]
end

function PositionalBuffer:clear()
	self._size = 0
	table.clear(self._buffer)
end

return PositionalBuffer