local function boolToNum(bool: boolean): number
    return if bool then 1 else 0
end

local function safeUnit(v: Vector3)
    return if v.Magnitude == 0 then Vector3.zero else v.Unit
end

return {
    boolToNum = boolToNum;
    safeUnit = safeUnit;
}