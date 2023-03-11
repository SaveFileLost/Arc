local PubTypes = require(script.Parent.PubTypes)

export type EntityKind = {
    initializer: PubTypes.EntityInitializer;
    writer: PubTypes.EntityWriter;
    reader: PubTypes.EntityReader;
    comparer: PubTypes.EntityComparer;
}

export type Rpc = {
    isServerRpc: boolean;
    callback: PubTypes.RpcCallback?;
    writer: PubTypes.RpcWriter;
    reader: PubTypes.RpcReader;
}

return nil