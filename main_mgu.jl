include("mgu.jl")

F = Symbol("f()")
G = Symbol("g()")

z1 = [:P, :a, :x, [F, [G, :y]]]
z2 = [:P, :z, [F, :z], [F, :w]]

result, substitutions = unify(z1, z2)

println("Original Formulas: ")
println(" - $z1")
println(" - $z2")
println()
println("Resulting Formula: ")
println(" - ", result)
println()
println("Substitutions: ")
println(" - ", substitutions)
