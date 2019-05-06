# Testing with: https://en.wikipedia.org/wiki/Conjunctive_normal_form

# 1.1 Eliminate Implication
[:all, :x,
        [:or,
            [:not,
                [:all, :y,
                        [:or, [:not, [:Animal, :y]],
                              [:Loves, :x, :y]]]],
            [:exists, :y, [:Loves, :y, :x]]]]

# 1.2 NNF
[:all, :x,
        [:or, [:exists, :y,
                        [:and, [:Animal, :y],
                               [:not, [:Loves, :x, :y]]]],
              [:exists, :y, [:Loves, :y, :x]]]]


# 2 Standardize Variables
[:all, :x1,
        [:or, [:exists, :y2,
                        [:and, [:Animal, :y2],
                               [:not, [:Loves, :x1, :y2]]]],
              [:exists, :y3, [:Loves, :y3, :x1]]]]

# 3 Skolemize & Eliminate Existential Quanitfiers
[:all, :x1,
       [:or, [:and, [:Animal, [Symbol("a()"), :x1]],
                    [:not, [:Loves, :x1, [Symbol("a()"), :x1]]]],
             [:Loves, [Symbol("b()"), :x1], :x1]]]

# 4 Drop Universal Quanitifers
[:or, [:and, [:Animal, [Symbol("a()"), :x1]],
             [:not, [:Loves, :x1, [Symbol("a()"), :x1]]]],
      [:Loves, [Symbol("b()"), :x1], :x1]]

# 5 Distribute and/or
[:and, [:or, [:Loves, [Symbol("b()"), :x1], :x1],
             [:Animal, [Symbol("a()"), :x1]]],
       [:or, [:Loves, [Symbol("b()"), :x1], :x1],
             [:not, [:Loves, :x1, [Symbol("a()"), :x1]]]]]
