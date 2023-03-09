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

export type Input = Map<string, any>
export type InputBuilder = (Input) -> Input

export type ArcCommon = {
    IS_SERVER: boolean;
    IS_CLIENT: boolean;

    getTickRate: () -> number;
    getTime: () -> number;

    getController: (name: string) -> Controller;
    Controller: (name: string) -> Controller;

    addFolder: (folder: Folder) -> ();

    start: () -> ();
}

export type ArcServer = {
    setTickRate: (rate: number) -> ();

    getService: (name: string) -> Service;
    Service: (name: string) -> Service;
}

export type ArcClient = {
    setInputBuilder: (builder: InputBuilder) -> ();
}

return nil