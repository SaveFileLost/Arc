local Arc = require(game.ReplicatedStorage.Packages.arc)
local commonSetup = require(game.ReplicatedStorage.Common.commonSetup)

require(game.ReplicatedStorage.Common.EntityDefinitions)

commonSetup()

Arc.addFolder(game.ReplicatedStorage.Common.Controllers)

Arc.start()