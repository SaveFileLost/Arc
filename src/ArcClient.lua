local requireFolder = require(script.Parent.requireFolder)
local Controllers = require(script.Parent.Controllers)
local PubTypes = require(script.Parent.PubTypes)

local TICK_RATE: number

local function getTickRate(): number
    return TICK_RATE
end

local function start()
    local networkRemote: RemoteEvent = script.Parent:WaitForChild("Network")
    
    TICK_RATE = networkRemote:GetAttribute("TickRate")

    Controllers.start()
end

return table.freeze({
    getTickRate = getTickRate;

    getController = Controllers.getController;
    Controller = Controllers.Controller;

    addFolder = requireFolder;
    start = start;
})