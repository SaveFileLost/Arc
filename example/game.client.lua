require(game.ReplicatedStorage.Common.EntityDefinitions)
require(game.ReplicatedStorage.Common.RpcDefinitions)

local Arc = require(game.ReplicatedStorage.Packages.arc).client()
local commonSetup = require(game.ReplicatedStorage.Common.commonSetup)

commonSetup()

Arc.addFolder(game.ReplicatedStorage.Common.Controllers)

Arc.start()