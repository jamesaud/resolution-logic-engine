using Test
include("mgu.jl")


F = Symbol("f()")
G = Symbol("g()")

z1 = [:P, [:a, :x, [F, [G, :y]]]]
z2 = [:P, [:z, [F, :z], [F, :w]]]

@test check_predicates_match([z1, z2])
@test check_predicates_match([z1, [:Q]]) == false

# Occurs Check
@test _occurs_in(:x, [F, [F, :x]])
@test !_occurs_in(:x, [F, :y])


@test replace_in_expression(:a, :b, [:a]) == [:b]
@test replace_in_expression(:a, :b, [:a, [:a, :a]]) == [:b, [:b, :b]]
@test replace_in_expression(:a, :b, [:x, [F, :a]]) == [:x, [F, :b]]
@test replace_in_expression(F, :a, [:x, [F, :x]]) == [:x, [:a, :x]]
@test replace_in_expression(:a, F, [:x, [:a, :x]]) == [:x, [F, :x]]
@test replace_in_expression(F, :z, z1) == [:P, [:a, :x, [:z, [G, :y]]]]


# Unification
# examples from http://www8.cs.umu.se/kurser/TDBB08/vt98b/Slides4/unify1_4.pdf
@test unify([:P, [:x]], [:P, [:y]]) == ([:P, [:y]], Dict(:x=>:y))

res = [:P, [:z, [F, :z], [F, [G, :y]]]]
subs = Dict(:a => :z, :w => [G, :y], :x => [F, :z])
r, s = unify(z1, z2)

@test r == res && s == subs
@test_throws ArgumentError unify([:P [:x]], [:Q [:x]])                  # Impossible to unify
@test_throws ArgumentError unify([:Q, [:y, :y]], [:Q, [:y, [F, :y]]])   # Occurs check condition
