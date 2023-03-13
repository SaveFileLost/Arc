local getTime = require(script.Parent.Parent.Utility.getTime)

local Controllers = require(script.Parent.Parent.Controllers)
local PubTypes = require(script.Parent.Parent.PubTypes)

local Client = {}
Client.__index = Client

function Client.new(player: Player, entity: PubTypes.Entity)
    return setmetatable({
        player = player;

		entity = entity;
        _pendingCommands = {};

		lastFullSnapshot = -math.huge; -- so they can request one right away
		grantFullSnapshot = false;

        lastSimulatedTick = nil; -- Initialized in processCommands
        nextExpectedTick = nil; -- Initialized in pushCommand
    }, Client)
end

function Client:processCommands()
	self.grantFullSnapshot = false

    for i = #self._pendingCommands, 1, -1 do
		local command = table.remove(self._pendingCommands, i)
		
		if command.requestFullSnapshot and getTime() - self.lastFullSnapshot > 20 then
			self.grantFullSnapshot = true
		end
		
		Controllers.simulate(self.entity, command.input)
		
		self.lastSimulatedTick = command.tick
	end

	-- granting full snapshots has a cooldown, yeah
	-- exploiters could technically trigger this, but normal people also need em
	if self.grantFullSnapshot then
		self.lastFullSnapshot = getTime()
	end
end

function Client:pushCommand(command: PubTypes.Command)
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