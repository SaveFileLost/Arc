local function deepIsEqualOrdered(t1, t2)
    for k, v in pairs(t1) do
        if typeof(v) == "table" then
            if typeof(t2[k]) ~= "table" or not deepIsEqualOrdered(v, t2[k]) then
                return false
            end
        else
            if t2[k] ~= v then return false end
        end
    end

    return true
end

-- Main implementation relies on the tables being ordered
local function deepIsEqualUnordered(t1, t2)
    return deepIsEqualOrdered(t1, t2) and deepIsEqualOrdered(t2, t1)
end

return deepIsEqualUnordered