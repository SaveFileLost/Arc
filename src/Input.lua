local PubTypes = require(script.Parent.PubTypes)

local inputBuilder: PubTypes.InputBuilder
local inputWriter: PubTypes.InputWriter
local inputReader: PubTypes.InputReader

local function setInputBuilder(builder: PubTypes.InputBuilder)
    inputBuilder = builder
end

local function setInputWriter(writer: PubTypes.InputWriter)
    inputWriter = writer
end

local function setInputReader(reader: PubTypes.InputReader)
    inputReader = reader
end

local function getInputWriter(): PubTypes.InputWriter
    return inputWriter
end

local function getInputReader(): PubTypes.InputReader
    return inputReader
end

local function buildInput(): PubTypes.Input
    local input = {}
    inputBuilder(input)
    return input
end

local function checkSetup()
    assert(inputBuilder ~= nil, "Input builder is not set")
    assert(inputWriter ~= nil, "Input writer is not set")
    assert(inputReader ~= nil, "Input reader is not set")
end

return table.freeze({
    setInputBuilder = setInputBuilder;
    setInputWriter = setInputWriter;
    setInputReader = setInputReader;

    buildInput = buildInput;
    getInputWriter = getInputWriter;
    getInputReader = getInputReader;

    checkSetup = checkSetup;
})