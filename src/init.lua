if game:GetService("RunService"):IsServer() then
    return require(script.ArcServer)
else
    return require(script.ArcClient)
end