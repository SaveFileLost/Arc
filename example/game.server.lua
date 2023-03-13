require(game.ReplicatedStorage.Common.EntityDefinitions)
require(game.ReplicatedStorage.Common.RpcDefinitions)

local Arc = require(game.ReplicatedStorage.Packages.arc).server()
local commonSetup = require(game.ReplicatedStorage.Common.commonSetup)

Arc.setTickRate(61)
Arc.setClientEntityKind("Player")

commonSetup()

Arc.addFolder(game.ServerStorage.Server.Services)
Arc.addFolder(game.ReplicatedStorage.Common.Controllers)

Arc.start()