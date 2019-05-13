include("logic_conversion.jl")

kb = [
      [:all, :y, [:implies, [:barber, :y],
                            [:double_implies, [:shaves, :x, :y],
                                              [:not, [:shaves, :y, :y]]]]]]
query = [:not, [:exists, :x, [:barber, :x]]]


entailed, clauses = resolution(kb, query)
clauses = Set(Set{Any}(c) for c in clauses)

if entailed
      println("The query is entailed (by contradiction of the negated query).")
      println()
         # Easier to read the output
else
      println("The expression is NOT entailed (no contradiction found of negated query).")
end

print_data("Resolution Clauses Entailed from KB", clauses)
