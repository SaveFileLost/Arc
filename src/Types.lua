local PubTypes = require(script.Parent.PubTypes)

export type EntityKind = {
    netProperties: PubTypes.Map<string, PubTypes.NetProperty>;
    initializer: PubTypes.EntityInitializer;
}

export type Rpc = {
    isServerRpc: boolean;
    callback: PubTypes.RpcCallback?;
    writer: PubTypes.RpcWriter;
    reader: PubTypes.RpcReader;
}

return nil