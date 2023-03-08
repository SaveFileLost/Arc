local function requireFolder(folder: Folder)
    for _, v in ipairs(folder:GetChildren()) do
        if not v:IsA("ModuleScript") then continue end
        require(v)
    end
end

return requireFolder