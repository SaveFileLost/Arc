local UserInputService = game:GetService("UserInputService")

local Arc = require(game.ReplicatedStorage.Packages.Arc)

Arc.setInputBuilder(function(input)
    input.isLeftMouseDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
end)

Arc.addFolder(game.ReplicatedStorage.Common.Controllers)

Arc.start()