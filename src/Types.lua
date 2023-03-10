local PubTypes = require(script.Parent.PubTypes)

export type EntityKind = {
    initializer: PubTypes.EntityInitializer;
    writer: PubTypes.EntityWriter;
    reader: PubTypes.EntityReader;
    comparer: PubTypes.EntityComparer;
}

export type Entity = PubTypes.Entity & {
    parentId: number?;
    childIds: PubTypes.List<number>;
}

return nil