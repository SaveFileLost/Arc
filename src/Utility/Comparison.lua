local PubTypes = require(script.Parent.Parent.PubTypes)

local function compareFloats(f1: number, f2: number, maxDiff: number?): boolean
    return math.abs(f1 - f2) < (maxDiff or 0.0001)
end

local function compareVector3s(vec1: Vector3, vec2: Vector3, maxDiff: number?): boolean
    return vec1:FuzzyEq(vec2, maxDiff or 0.0001)
end

local function compareCFrames(cf1: CFrame, cf2: CFrame, maxDiff: number?): boolean
    return compareVector3s(cf1.LookVector, cf2.LookVector, maxDiff)
        and compareVector3s(cf1.UpVector, cf2.UpVector, maxDiff)
        and compareVector3s(cf1.RightVector, cf2.RightVector, maxDiff)
end

local Comparison: PubTypes.Comparison = {
    compareFloats = compareFloats;
    compareVector3s = compareVector3s;
    compareCFrames = compareCFrames;
}

return table.freeze(Comparison)