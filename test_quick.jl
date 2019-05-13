using Test
include("logic_conversion.jl")
include("mgu.jl")


function run_code()
    kb = [
     [:or, [:Friend, :Peter, :Eve], [:Friend, :Peter, :Adam]],
     [:not, [:Friend, :Peter, :Eve]]
    ]
    entails = [:Friend, :Peter, :Adam]
    entailed, clauses = resolution(kb, entails)

    # println("Entailed: ", entailed)
    # for clause in clauses
    #     println("- ", clause)
    # end
end

set(exp...) = Set(exp)

kb = [
 [:or, [:Friend, :Peter, :Eve], [:Friend, :Peter, :Adam]],
 [:not, [:Friend, :Peter, :Eve]]
]
entails = :Dana #[:Friend, :Peter, :Adam]
constants = set(:Peter, :Eve, :Adam)
entailed, clauses = resolution(kb, entails, constants)
println(entailed)







# run_code()
