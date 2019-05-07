using Test
include("logic_conversion.jl")

set(exp...) = Set(exp)

kb = [
      [:and, :P, :Q],
      [:or, [:Loves, :P, :Q], :X],
      [:not, :X],
]

query = [:Loves, [:P, :Q]]

@test _contains_complement(:a, set([:not, :a]))
@test !_contains_complement(:a, set([:not, :b]))
@test !_contains_complement(:a, set([:a]))

c1 = set(:a, :b, [:not, :c])
c2 = set(:c)

@test _complementary_literals(c1, c2) == set(:c)
@test _complementary_literals(c1, set(:d)) == set()

@test _remove_literals_and_negations(set(:a, :b), c1) == set([:not, :c])
@test _remove_literals_and_negations(set([:not, :c]), c1) == set(:a, :b)


c3 = set([:not, :a])
@test _resolution_rule(set(c1, c2)) == set(set(:a, :b))
@test _resolution_rule(set(c1, c2, c3)) == set(set(:a, :b), set(:b, [:not, :c]))

@test _has_complementary_literals(set(:s), set([:not, :s]))
@test !_has_complementary_literals(set(:s), set([:not, :p]))

clauses = set(set(:c), set([:not, :c]))
@test_throws ArgumentError resolve(clauses)
