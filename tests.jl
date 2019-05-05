using Test
using Juno
include("logic_conversion.jl")

P = [:and, :x, :y]
Q = [:or, :x, :y]
R = :R

x = :x
Px = [:P, x]

# Input
implication = [:implies, P, Q]
double_implication = [:double_implies, P, Q]
demorgan_or = [:not, [:or, [P, Q]]]
demogran_and = [:not, [:and, [P, Q]]]
double_not = [:not, [:not, P]]

not_all = [:not, [:all, x, Px]]
not_exists = [:not, [:exists, x, Px]]

# Output of negation normal form
implication_nnf = [:or, [:not, P], Q]
double_implication_nnf = [:and, [:or, P, [:not, Q]], [:or, [:not, P], Q]]

demorgan_or_nnf = [:or, [:not, P], [:not, Q]]
demogran_and_nnf = [:or, [:not, P], [:not, Q]]
double_not_nnf = P
not_all_nnf = [:all, x, [:not, Px]]
not_exists_nnf = [:exists, x, [:not, Px]]

# Negation Normal Form
@test eliminate_implication(implication) == implication_nnf
@test eliminate_implication(double_implication) == double_implication_nnf
@test move_not_inward(demorgan_or) == demorgan_or_nnf
@test move_not_inward(demogran_and) == demogran_and_nnf
@test move_not_inward(double_not) == double_not_nnf
@test move_not_inward(not_all) == not_all_nnf
@test move_not_inward(not_exists) == not_exists_nnf

@test nnf([:and, implication, double_not]) ==
                         [:and, implication_nnf, double_not_nnf]

@test nnf([:implies, [:implies, :P, :Q], :Q]) ==
                         [:or, [:not, [:or, [:not, :P], :Q]], :Q]

# Variable Replacement
s = Symbol("x1")          # Symbol function iterates up from 1
s2 = Symbol("x2")

exp = [:exists, :x, [:or, [:Friend, :x], [:Enemy, :x]]] # There is someone who's a friend or enemy of x
@test standardize_expression(exp) == [:exists, s, [:or, [:Friend, s], [:Enemy, s]]]

exp = [:exists, :x, [:all, :x, [:or, [:Friend, :x], [:Enemy, :x]]]]   # Make sure existential quanitfier scoping is correct
@test standardize_expression(exp) == [:exists, s, [:all, s2, [:or, [:Friend, s2], [:Enemy, s2]]]]

exp = [:and, [:all, :x, [:Loves, :x]], [:all, :x, [:Loves, :x]]]
@test standardize_expression(exp) == [:and, [:all, s, [:Loves, s]], [:all, s2, [:Loves, s2]]]


# Move quantifiers
@test move_quantifiers([:and, P, [:all, x, [Q, x]]]) == [:all, x, [:and, P, [Q, x]]]
@test move_quantifiers([:or, P, [:all, x, [Q, x]]]) == [:all, x, [:or, P, [Q, x]]]
@test move_quantifiers([:and, P, [:exists, x, [Q, x]]]) == [:exists, x, [:and, P, [Q, x]]]
@test move_quantifiers([:or, P, [:exists, x, [Q, x]]]) == [:exists, x, [:or, P, [Q, x]]]

# Skolem Function
x, y, z = :x, :y, :z

@test skolem_function([:all, x, [:exists, y, [:and, [:Animal, y], [:Loves, x, y]]]]) ==
                      [:all, :x, [:and, [:Animal, [Symbol("a()"), :x]], [:Loves, :x, [Symbol("a()"), :x]]]]

@test skolem_function([:all, x, [:all, y, [:exists, z, [:and, [:Animal, z], [:Loves, x, z]]]]]) ==
                      [:all, :x, [:all, :y, [:and, [:Animal, [Symbol("a()"), :x, :y]], [:Loves, :x, [Symbol("a()"), :x, :y]]]]]


# Different skolem function for each quantifier
@test skolem_function([:or, [:all, x, [:exists, y, [:Loves, x, y]]], [:all, x, [:exists, y, [:Loves, x, y]]]]) ==
                      [:or, [:all, x, [:Loves, x, [Symbol("a()"), x]]], [:all, x, [:Loves, x, [Symbol("b()"), x]]]]


# Drop Universal Quantifiers
@test drop_universal_quantifiers([:all, x, [:all, y, [:Loves, x, y]]]) == [:Loves, x, y]

# Distribute "ors" inwards over "ands"
@test distribute_or_and([:or, P, [:and, Q, R]]) == [:and, [:or, P, Q], [:or, P, R]]


# Final Conjunctive normal form test
exp = [:all, x,
             [:implies, [:all, y,
                               [:implies, [:Animal, y],
                                          [:Loves, x, y]]],
                        [:exists, y,
                                  [:Loves, y, x]]]]

@test conjunctive_normal_form(exp)

# [:or,
#    [:not,
#         [:or, [:not, Symbol[:Animal, :y2]],
#               [:Loves, :x1, :y2]]],
#    [:Loves, [Symbol("a()"), :x1], :x1]]
