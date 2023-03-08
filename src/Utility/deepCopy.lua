local function deepCopy(t)
    local copy = table.clone(t)
    
    for k, v in pairs(table) do
        if typeof(v) ~= "table" then continue end
        copy[k] = deepCopy(v)
    end

    return copy
end

return deepCopy