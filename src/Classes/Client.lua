local Controllers = require(script.Parent.Parent.Controllers)

local Client = {}
Client.__index = Client

function Client.new(player: Player)
    return setmetatable({
        player = player;

        state = {};
        _pendingCommands = {};
        lastSimulatedTick = nil; -- Initialized in processCommands
        nextExpectedTick = nil; -- Initialized in pushCommand
    }, Client)
end

function Client:processCommands()
    for i = #self._pendingCommands, 1, -1 do
		local command = table.remove(self._pendingCommands, i)
		
		Controllers.simulate(self.state, command.input)
		
		self.lastSimulatedTick = command.tick
	end
end

function Client:pushCommand(command)
	-- VULNERABILITY
	-- We need initialize the first tick here. Players can spoof this.
	self.nextExpectedTick = self.nextExpectedTick or command.tick
	
	if command.tick ~= self.nextExpectedTick then
		warn(`Received misordered command tick {command.tick}, expected {self.nextExpectedTick}`)
		self.player:Kick("1")
		return
	end
	
	self.nextExpectedTick += 1
	table.insert(self._pendingCommands, 1, command)
end

return Client