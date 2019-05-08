include("logic_conversion.jl")

kb = [
      [:all, :y, [:implies, [:barber, :y],
                            [:double_implies, [:shaves, :x, :y],
                                              [:not, [:shaves, :y, :y]]]]]]
entails = [:not, [:exists, :x, [:barber, :x]]]


is_entailed = resolution(kb, entails)
if is_entailed
      println("The expression is entailed.")
      println()
      clauses = resolution_steps(kb)                                 # Generated clauses from only the knowledge base
      clauses = Set(Set{Any}(c) for c in collect(clauses))   # Easier to read the output of
      print_data("Resolution Steps (Clausal Form)", clauses)
else
      println("The expression is NOT entailed! Exiting...")
      exit()
end
