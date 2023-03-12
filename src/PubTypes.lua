export type List<V> = {V}
export type Map<K,V> = {[K]: V}
export type Set<T> = {[T]: true}

export type Service = {
    name: string;
    
    init: (self: Service) -> ();
    start: (self: Service) -> ();

    bindServrRpc: (self: Controller, name: string) -> ();
}

export type Controller = {
    name: string;
    simulationPriority: number?;
    
    init: (self: Controller) -> ();
    start: (self: Controller) -> ();

    simulate: (self: Controller, entity: Entity, input: Input) -> ();
    frameSimulate: (self: Controller, entity: Entity, input: Input) -> ();

    bindClientRpc: (self: Controller, name: string) -> ();
}

export type EntityInitializer = (ent: Entity) -> ();
export type EntityWriter = (ent: Entity, buffer: BitBuffer) -> ();
export type EntityReader = (ent: Entity, buffer: BitBuffer) -> ();
export type EntityComparer = (ent1: Entity, ent2: Entity) -> boolean;
export type EntityPredicate = (ent: Entity) -> boolean

export type NetProperty = {
    write: (value: any, buffer: BitBuffer) -> ();
    read: (buffer: BitBuffer) -> any;
    areSimilar: (v1: any, v2: any) -> boolean;
}

export type EntityDefinition = {
    kind: string;

    netProperties: Map<string, NetProperty>;

    init: EntityInitializer;
}

export type Entity = {
    kind: string;
    id: number;

    active: boolean;
    authority: boolean; -- did we create this entity?

    [string]: any;
}

export type Command = {
    tick: number;
    requestFullSnapshot: boolean;
    input: Input;
    serverRpcs: List<RpcCall>;
}

export type Snapshot = {
    tick: number;
    clientId: number;
    entities: List<Entity>;
    deletedEntityIds: List<number>;
    rpcs: List<RpcCall>;
}

export type RpcWriter = (buffer: BitBuffer, ...any) -> ()
export type RpcReader = (buffer: BitBuffer) -> (...any)
export type RpcCallback = (...any) -> ()

export type RpcDefinition = {
    name: string;
    write: RpcWriter;
    read: RpcReader;
}

export type PendingClientRpc = {
    name: string;
    targets: Set<Player>;
    args: List<any>;
}

export type PendingServerRpc = {
    name: string;
    args: List<any>;
}

export type RpcCall = {
    name: string;
    args: List<any>;
}

export type BitBuffer = {
    writeBool: (self: BitBuffer, b: boolean) -> ();
    readBool: (self: BitBuffer) -> boolean;

    writeUInt: (self: BitBuffer, bitWidth: number, n: number) -> ();
    readUInt: (self: BitBuffer, bitWidth: number) -> number;

    writeFloat32: (self: BitBuffer, f: number) -> ();
    readFloat32: (self: BitBuffer) -> number;

    writeFloat64: (self: BitBuffer, f: number) -> ();
    readFloat64: (self: BitBuffer) -> number;

    writeString: (self: BitBuffer, str: string) -> ();
    readString: (self: BitBuffer) -> string;

    writeVector3: (self: BitBuffer, vec: Vector3) -> ();
    readVector3: (self: BitBuffer) -> Vector3;

    toString: (self: BitBuffer) -> string;
}

export type Similar = {
    floats: (f1: number, f2: number, maxDiff: number?) -> boolean;
    vector3s: (vec1: Vector3, vec2: Vector3, maxDiff: number?) -> boolean;
    cframes: (cf1: CFrame, cf2: CFrame, maxDiff: number?) -> boolean;
}

export type Input = Map<string, any>
export type InputBuilder = (input: Input) -> Input
export type InputWriter = (input: Input, buffer: BitBuffer) -> ()
export type InputReader = (input: Input, buffer: BitBuffer) -> ();

export type ArcCommon = {
    IS_SERVER: boolean;
    IS_CLIENT: boolean;

    setInputBuilder: (builder: InputBuilder) -> ();
    setInputWriter: (serializer: InputWriter) -> ();
    setInputReader: (reader: InputReader) -> ();

    getTickRate: () -> number;
    getTime: () -> number;

    getController: (name: string) -> Controller;
    Controller: (name: string) -> Controller;

    -- ENTITIES

    Entity: (def: EntityDefinition) -> ();

    spawnEntity: (kind: string) -> Entity;
    deleteEntity: (ent: Entity) -> ();

    getAllEntities: () -> List<Entity>;

    getAllEntitiesWhere: (predicate: EntityPredicate) -> List<Entity>;
    getFirstEntityWhere: (predicate: EntityPredicate) -> Entity?;

    -- RPCS

    RPC_EVERYONE: Set<Player>;

    ClientRpc: (def: RpcDefinition) -> ();
    ServerRpc: (def: RpcDefinition) -> ();
    bindRpcCallback: (rpcName: string, callback: RpcCallback) -> ();
    callClientRpc: (rpcName: string, targets: Set<Player>, ...any) -> ();

    pauseRpcCulling: () -> ();
    resumeRpcCulling: () -> ();
    isRpcCulling: () -> boolean;

    -- NET PROPERTIES

    NetVector3: NetProperty;

    Similar: Similar;

    addFolder: (folder: Folder) -> ();

    start: () -> ();
}

export type ArcServer = ArcCommon & {
    setTickRate: (rate: number) -> ();

    getService: (name: string) -> Service;
    Service: (name: string) -> Service;

    setClientEntityKind: (kind: string) -> ();
}

export type ArcClient = ArcCommon & {
    callServerRpc: (rpcName: string, ...any) -> ();
}

return nil