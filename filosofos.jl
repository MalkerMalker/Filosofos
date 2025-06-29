using Base.Threads

const NUM_FILOSOFOS = 5
const N_COMIDAS_POR_FILOSOFO = 5

const LockType = ReentrantLock

const tenedores = [LockType() for _ in 1:NUM_FILOSOFOS]

const estados_actuales = Dict(i => "iniciando" for i in 1:NUM_FILOSOFOS)

mutable struct Filosofo
    id::Int
    estado::String
    tenedor_izq::Int
    tenedor_der::Int
    comidas_ingeridas::Int
end

function crear_filosofo(id)
    tenedor_der = (id % NUM_FILOSOFOS) + 1
    return Filosofo(id, "pensando", id, tenedor_der, 0)
end

function pensar(p::Filosofo)
    p.estado = "pensando"
    estados_actuales[p.id] = p.estado
    println("Filósofo #$(p.id) está reflexionando sobre la concurrencia...")
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
        p.estado = "comiendo"
        estados_actuales[p.id] = p.estado
        p.comidas_ingeridas += 1
        println(">> Filósofo #$(p.id) está comiendo por $(p.comidas_ingeridas)ª vez.")
        sleep(rand(0.5:0.1:1.5))
    finally
        unlock(tenedores[p.tenedor_izq])
        unlock(tenedores[p.tenedor_der])
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
    
    mi_filosofo.estado = "satisfecho"
    estados_actuales[mi_filosofo.id] = mi_filosofo.estado
    println("== Filósofo #$(mi_filosofo.id) está lleno y se va de la mesa. ==")
end

println("Bienvenidos a la cena de los filósofos concurrentes.")

@threads for i in 1:NUM_FILOSOFOS
    ciclo_de_vida_filosofo(i)
end

println("\nLa cena ha terminado. Todos los filósofos se fueron satisfechos.")
println("Estado final de la mesa: ", estados_actuales)
