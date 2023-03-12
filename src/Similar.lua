local PubTypes = require(script.Parent.PubTypes)

local function floats(f1: number, f2: number, maxDiff: number?): boolean
    return math.abs(f1 - f2) < (maxDiff or 0.0001)
end

local function vector3s(vec1: Vector3, vec2: Vector3, maxDiff: number?): boolean
    return vec1:FuzzyEq(vec2, maxDiff or 0.0001)
end

local function cframes(cf1: CFrame, cf2: CFrame, maxDiff: number?): boolean
    return vector3s(cf1.LookVector, cf2.LookVector, maxDiff)
        and vector3s(cf1.UpVector, cf2.UpVector, maxDiff)
        and vector3s(cf1.RightVector, cf2.RightVector, maxDiff)
end

local Similar: PubTypes.Similar = {
    floats = floats;
    vector3s = vector3s;
    cframes = cframes;
}

return table.freeze(Similar)