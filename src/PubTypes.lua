export type Set<T> = {[T]: true}
export type Map<K,V> = {[K]: V}

export type Service = {
    name: string;
    
    init: (self: Service) -> ();
    start: (self: Service) -> ();
}

return nil