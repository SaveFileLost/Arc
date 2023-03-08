export type Set<T> = {[T]: true}
export type Map<K,V> = {[K]: V}

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

    simulate: ((self: Controller, plr: Player, input: Map<any, any>) -> ())?;
}

return nil