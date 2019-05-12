
include("logic_conversion.jl")

kb = [
 [:and, [:Friend, :Adam, :Eve], [:Friend, :Eve, :Adam]],
 [:or, [:Friend, :Peter, :Eve], [:Friend, :Peter, :Adam]],
 [:not, [:Friend, :Peter, :Eve]]
]
entails = :Dana #[:Friend, :Peter, :Adam]
entailed, clauses = resolution(kb, entails)

# println("Entailed: ", entailed)
# for clause in clauses
#     println("- ", clause)
# end
