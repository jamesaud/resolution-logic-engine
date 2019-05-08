using Test
include("logic_conversion.jl")

set(exp...) = Set(exp)

@test _contains_complement_literal(:a, set([:not, :a]))
@test !_contains_complement_literal(:a, set([:not, :b]))
@test !_contains_complement_literal(:a, set([:a]))

c1 = set(:a, :b, [:not, :c])
c2 = set(:c)

@test _complementary_literals(c1, c2) == set(:c)
@test _complementary_literals(c1, set(:d)) == set()
@test _complementary_literals(set(:c1), set(:c1)) == set()

@test _remove_literals_and_negations(set(:a, :b), c1) == set([:not, :c])
@test _remove_literals_and_negations(set([:not, :c]), c1) == set(:a, :b)

@test _has_complementary_literals(set(:s), set([:not, :s]))
@test !_has_complementary_literals(set(:s), set([:not, :p]))

# Predicates
@test _complementary_predicates(set([:Loves, :x, :y]), set([:not, [:Loves, :x, :y]])) == set(:Loves)
@test _complementary_predicates(set([:Loves, :x, :y]), set([:not, [:Hates, :x, :y]])) == set()
@test _complementary_predicates(set([:not, [:Loves, :x, :y]]), set([:Loves, :x, :z])) == set(:Loves)
@test _complementary_predicates(set([:Loves, :x, :y]), [:Loves, :x, :y]) == set()
@test _complementary_predicate_expressions(set([:Loves, :x, :y]), set([:not, [:Loves, :x, :y]])) == [[:Loves, :x, :y]]


@test _replace_unbounded_variable(set([:Loves, :x, :y]), :x, :a) == set([:Loves, :a, :y])
@test _replace_unbounded_variable(set([:Loves, :x, :y]), :a, :b) == set([:Loves, :x, :y])
@test _replace_unbounded_variable(set([:not, [:Loves, :x, :y]]), :x, :a) == set([:not, [:Loves, :a, :y]])
@test _replace_unbounded_variable(set([:Loves, :x, :y], :x), :x, :a) == set([:Loves, :a, :y], :x)
@test _replace_unbounded_variable(set([:not, [:Loves, :x, :y]], :x), :x, :a) == set([:not, [:Loves, :a, :y]], :x)

predicate = :Loves
clause = set(set([:Loves, :x, :y], :z))

c1, c2, subs = unify_clause_predicates(set([:Loves, :x, :y]), set([:not, [:Loves, :x, :z]]))
@test c1 == set([:Loves, :x, :z])
@test c2 == set([:not, [:Loves, :x, :z]])
@test subs == Dict(:y=>:z)

c1, c2, subs = unify_clause_predicates(set([:not, [:Loves, :x, :z]]), set([:Loves, :x, :y]))
@test c1 == set([:not, [:Loves, :x, :y]])
@test c2 == set([:Loves, :x, :y])
@test subs == Dict(:z=>:y)

c1, c2, subs = unify_clause_predicates(set([:not, [:Loves, :x, :z]], :a), set([:Loves, :x, :y], :b))
@test c1 == set([:not, [:Loves, :x, :y]], :a)
@test c2 == set([:Loves, :x, :y], :b)
@test subs == Dict(:z=>:y)

c1, c2, subs = unify_clause_predicates(set([:not, [:Loves, :x, :z]], :x), set([:Loves, :x, :y], :x))
@test c1 == set([:not, [:Loves, :x, :y]], :x)
@test c2 == set([:Loves, :x, :y], :x)
@test subs == Dict(:z=>:y)

c1, c2, subs = unify_clause_predicates(set([:not, [:Loves, :x, :z]], [:Hates, :z, :x]), set([:Loves, :x, :y], :x))
@test c1 == set([:not, [:Loves, :x, :y]], [:Hates, :y, :x])
@test c2 == set([:Loves, :x, :y], :x)
@test subs == Dict(:z=>:y)


# TESTING RESOLUTION
c1 = set(:a, :b, [:not, :c])
c2 = set(:c)
c3 = set([:not, :a])
@test _resolution_rule(set(c1, c2)) == set(set(:a, :b))
@test _resolution_rule(set(c1, c2, c3)) == set(set(:a, :b), set(:b, [:not, :c]))

clauses = set(set(:c), set([:not, :c]))
@test_throws ArgumentError resolve(clauses)

clauses = set(
      set([:not, :b], :c),
      set(:a, :b),
      set([:not, :a])
)
entailed = set(set(:b), set(:c), set(:a, :c))
@test resolve(clauses) == union(clauses, entailed)
@test resolve(set(set(:a), set(:b))) == set(set(:a), set(:b))
@test resolve(set()) == set()

clauses = set(
      set([:not, [:P, :x]], [:Q, :x]),
      set([:P, :a])
)
entailed = set(set([:Q, :a]), set([:Q, :x]))
@test resolve(clauses) == union(clauses, entailed)

# Test Resolution
kb = [
      [:or, [:not, [:P, :x]], [:Q, :x]],
      [:P, :a],
]
query = [:Q, :a]

@test resolution(kb, query)
@test !resolution(kb, [:H, :z])


kb = [
      [:exists, :x, [:and, [:person, :x],
                           [:all, :y, [:implies, [:person, :y],
                                                 [:double_implies, [:shaves, :x, :y],
                                                                   [:not, [:shaves, :y, :y]]]]]]]]

@test resolution(kb, [:not, [:exists, :x, [:person, :x]]])
@test_throws ArgumentError resolution_steps(kb)


kb = [
      [:all, :y, [:implies, [:barber, :y],
                            [:double_implies, [:shaves, :x, :y],
                                              [:not, [:shaves, :y, :y]]]]]]
entails = [:not, [:exists, :x, [:barber, :x]]]

@test resolution(kb, entails)
@test !resolution(kb, [:exists, :x, [:barber, :x]])


print_data("Resolution Steps (Clausal Form)", map(collect, collect(resolution_steps(kb))))

kb = []
entails = [:implies, :p, :p]
@test resolution(kb, entails)
