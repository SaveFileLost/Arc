local PubTypes = require(script.Parent.PubTypes)

export type EntityKind = {
    netProperties: PubTypes.Map<string, PubTypes.NetProperty>;
    netPropertyIdToName: PubTypes.Map<number, string>;
    netPropertyNameToId: PubTypes.Map<string, number>;

    initializer: PubTypes.EntityInitializer;
}

export type Rpc = {
    isServerRpc: boolean;
    callback: PubTypes.RpcCallback?;
    writer: PubTypes.RpcWriter;
    reader: PubTypes.RpcReader;
}

export type SimilarityMismatch = {
    propName: string;
    value1: any;
    value2: any;
}

return nil