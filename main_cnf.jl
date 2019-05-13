include("logic_conversion.jl")

# Formula found at: https://en.wikipedia.org/wiki/Conjunctive_normal_form
# check output_skolem.jl for the full output at each step

x, y = :x, :y

exp = [:all, x,
             [:implies, [:all, y,
                               [:implies, [:Animal, y],
                                          [:Loves, x, y]]],
                        [:exists, y,
                                  [:Loves, y, x]]]]

out = [:and, [:or, [:Loves, [Symbol("b()"), :x1], :x1],
             [:Animal, [Symbol("a()"), :x1]]],
       [:or, [:Loves, [Symbol("b()"), :x1], :x1],
             [:not, [:Loves, :x1, [Symbol("a()"), :x1]]]]]

println("Input Expression:")
println(" - ", exp)

println("CNF and Skolemized Output:")
println(" - ", conjunctive_normal_form(exp))
