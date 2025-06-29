using Base.Threads

NUM_FILOSOFOS = 5
N_COMIDAS_POR_FILOSOFO = 5
LockType = ReentrantLock

const tenedores = [LockType() for _ in 1:NUM_FILOSOFOS]

const estados_actuales = Dict{Int, String}(i => "iniciando" for i in 1:NUM_FILOSOFOS)

mutable struct Filosofo
    id::Int
    tenedor_izq::Int
    tenedor_der::Int
    comidas_ingeridas::Int
end

function crear_filosofo(id::Int)
    tenedor_der = (id % NUM_FILOSOFOS) + 1
    return Filosofo(id, id, tenedor_der, 0)
end

function actualizar_estado(p::Filosofo, nuevo_estado::String)

    lock(lock_estados) 
    try
        estados_actuales[p.id] = nuevo_estado
    finally
        unlock(lock_estados) 
    end
end

function pensar(p::Filosofo)
    actualizar_estado(p, "pensando")
    println("Filósofo #$(p.id) está reflexionando...")
    sleep(rand(0.5:0.1:2.0))
end

function comer(p::Filosofo)

    if p.id == NUM_FILOSOFOS
        lock(tenedores[p.tenedor_der])
        lock(tenedores[p.tenedor_izq])
    else
        lock(tenedores[p.tenedor_izq])
        lock(tenedores[p.tenedor_der])
    end
    
    try
        p.comidas_ingeridas += 1
        actualizar_estado(p, "comiendo")
        println(">> Filósofo #$(p.id) está comiendo por $(p.comidas_ingeridas)ª vez.")
        sleep(rand(0.5:0.1:1.5))
    finally
        unlock(tenedores[p.tenedor_der])
        unlock(tenedores[p.tenedor_izq])
        println("Filósofo #$(p.id) ha soltado los tenedores.")
    end
end

function ciclo_de_vida_filosofo(id::Int)
    mi_filosofo = crear_filosofo(id)
    
    while mi_filosofo.comidas_ingeridas < N_COMIDAS_POR_FILOSOFO
        pensar(mi_filosofo)
        
        println("Filósofo #$(mi_filosofo.id) tiene hambre.")
        comer(mi_filosofo)
    end
    
    actualizar_estado(mi_filosofo, "satisfecho")
    println("== Filósofo #$(mi_filosofo.id) está lleno y se va de la mesa. ==")
end

println("Inicio de la cena de los filósofos.")

@threads for i in 1:NUM_FILOSOFOS
    ciclo_de_vida_filosofo(i)
end

println("\nLa cena ha terminado.")
println("Estado final de la mesa: ", estados_actuales)
