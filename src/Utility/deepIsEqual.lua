local function areVector3sEqual(v1: Vector3, v2: Vector3): boolean
    return v1:FuzzyEq(v2, 0.0001)
end

local function areCFramesEqual(cf1: CFrame, cf2: CFrame): boolean
    return areVector3sEqual(cf1.LookVector, cf2.LookVector) 
        and areVector3sEqual(cf1.RightVector, cf2.RightVector) 
        and areVector3sEqual(cf1.UpVector, cf2.UpVector) 
end

local function areEqual(v1, v2, comparer): boolean
    if typeof(v2) ~= typeof(v1) then return false end

    return comparer(v1, v2)
end

local function deepIsEqualOrdered(t1, t2)
    for k, v1 in pairs(t1) do
        local v2 = t2[k]

        if typeof(v1) == "table" then
            if not areEqual(v1, v2, deepIsEqualOrdered) then
                return false
            end
        elseif typeof(v1) == "CFrame" then
            if not areEqual(v1, v2, areCFramesEqual) then
                return false
            end
        elseif typeof(v1) == "Vector3" then
            if not areEqual(v1, v2, areVector3sEqual) then
                return false
            end
        else
            if t2[k] ~= v1 then return false end
        end
    end

    return true
end

-- Main implementation relies on the tables being ordered
local function deepIsEqualUnordered(t1, t2)
    return deepIsEqualOrdered(t1, t2) and deepIsEqualOrdered(t2, t1)
end

return deepIsEqualUnordered