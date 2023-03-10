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

    simulate: (self: Controller, playerState: Map<string, any>, input: Input) -> ();
    frameSimulate: (self: Controller, playerState: Map<string, any>, input: Input) -> ();
}

export type EntityInitializer = (ent: Entity) -> ();
export type EntityWriter = (ent: Entity, buffer: BitBuffer) -> ();
export type EntityReader = (ent: Entity, buffer: BitBuffer) -> ();
export type EntityComparer = (ent1: Entity, ent2: Entity) -> boolean;

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
    [string]: any;
}

export type Command = {
    tick: number;
    input: Input;
}

export type BitBuffer = {
    writeUInt: (self: BitBuffer, bitWidth: number, n: number) -> ();
    readUInt: (self: BitBuffer, bitWidth: number) -> ();

    writeFloat32: (self: BitBuffer, f: number) -> ();
    readFloat32: (self: BitBuffer) -> ();

    writeFloat64: (self: BitBuffer, f: number) -> ();
    readFloat64: (self: BitBuffer) -> ();

    writeString: (self: BitBuffer, str: string) -> ();
    readString: (self: BitBuffer) -> ();

    writeVector3: (self: BitBuffer, vec: Vector3) -> ();
    readVector3: (self: BitBuffer) -> ();

    toString: (self: BitBuffer) -> string;
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

    spawnEntity: (kind: string) -> Entity;
    Entity: (def: EntityDefinition) -> ();

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