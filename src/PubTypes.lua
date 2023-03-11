export type List<V> = {V}
export type Map<K,V> = {[K]: V}
export type Set<T> = {[T]: true}

export type Service = {
    name: string;
    
    init: (self: Service) -> ();
    start: (self: Service) -> ();
}

export type Controller = {
    name: string;
    simulationPriority: number?;
    
    init: (self: Controller) -> ();
    start: (self: Controller) -> ();

    simulate: (self: Controller, entity: Entity, input: Input) -> ();
    frameSimulate: (self: Controller, entity: Entity, input: Input) -> ();

    bindRpc: (self: Controller, name: string) -> ();
}

export type EntityInitializer = (ent: Entity) -> ();
export type EntityWriter = (ent: Entity, buffer: BitBuffer) -> ();
export type EntityReader = (ent: Entity, buffer: BitBuffer) -> ();
export type EntityComparer = (ent1: Entity, ent2: Entity) -> boolean;
export type EntityPredicate = (ent: Entity) -> boolean

export type EntityDefinition = {
    kind: string;

    init: EntityInitializer;
    write: EntityWriter;
    read: EntityReader;
    compare: EntityComparer;
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
    input: Input;
}

export type Snapshot = {
    tick: number;
    clientId: number;
    entities: List<Entity>;
    deletedEntityIds: List<number>;
    rpcs: List<ClientRpcCall>;
}

export type RpcWriter = (buffer: BitBuffer, ...any) -> ()
export type RpcReader = (buffer: BitBuffer) -> (...any)
export type RpcCallback = (...any) -> ()

export type RpcDefinition = {
    name: string;
    write: RpcWriter;
    read: RpcReader;
}

export type PendingRpc = {
    name: string;
    targets: Set<Player>;
    args: List<any>;
}

export type ClientRpcCall = {
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

export type Comparison = {
    compareFloats: (f1: number, f2: number, maxDiff: number?) -> boolean;
    compareVector3s: (vec1: Vector3, vec2: Vector3, maxDiff: number?) -> boolean;
    compareCFrames: (cf1: CFrame, cf2: CFrame, maxDiff: number?) -> boolean;
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

    Entities: {
        Entity: (def: EntityDefinition) -> ();
        setClientKind: (kind: string) -> ();

        spawn: (kind: string) -> Entity;
        delete: (ent: Entity) -> ();

        getAll: () -> List<Entity>;

        getAllWhere: (predicate: EntityPredicate) -> List<Entity>;
        getFirstWhere: (predicate: EntityPredicate) -> Entity?;

        getById: (id: number) -> Entity?;
    };

    Rpc: {
        EVERYONE: Set<Player>;

        Client: (def: RpcDefinition) -> ();
        bindCallback: (rpcName: string, callback: RpcCallback) -> ();
        callClient: (rpcName: string, targets: Set<Player>, ...any) -> ();

        pauseCulling: () -> ();
        resumeCulling: () -> ();
        isCulling: () -> boolean;
    };

    Comparison: Comparison;

    addFolder: (folder: Folder) -> ();

    start: () -> ();
}

export type ArcServer = {
    setTickRate: (rate: number) -> ();

    getService: (name: string) -> Service;
    Service: (name: string) -> Service;
}

export type ArcClient = {

}

return nil