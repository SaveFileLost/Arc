local PubTypes = require(script.Parent.PubTypes)

export type EntityKind = {
    initializer: PubTypes.EntityInitializer;
    writer: PubTypes.EntityWriter;
    reader: PubTypes.EntityReader;
    comparer: PubTypes.EntityComparer;
}

return nil