local Arc = require(game.ReplicatedStorage.Packages.arc)
local commonSetup = require(game.ReplicatedStorage.Common.commonSetup)

Arc.setTickRate(66)

commonSetup()

Arc.addFolder(game.ServerStorage.Server.Services)
Arc.addFolder(game.ReplicatedStorage.Common.Controllers)

Arc.start()