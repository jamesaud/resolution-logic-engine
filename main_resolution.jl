include("logic_conversion.jl")

kb = [
      [:all, :y, [:implies, [:barber, :y],
                            [:double_implies, [:shaves, :x, :y],
                                              [:not, [:shaves, :y, :y]]]]]]
query = [:not, [:exists, :x, [:barber, :x]]]


if resolution(kb, query)
      println("The query is entailed.")
      println()
      clauses = resolution_steps(kb)                # Generated clauses from only the knowledge base
      clauses = Set(Set{Any}(c) for c in clauses)   # Easier to read the output
      print_data("Resolution Clauses Entailed from KB (without query, in clausal form)", clauses)
else
      println("The expression is NOT entailed! Exiting...")
      exit()
end
