using Test
include("logic_conversion.jl")

P = [:and, :x, :y]
Q = [:or, :x, :y]

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
@test nnf(implication) == implication_nnf
@test nnf(double_implication) == double_implication_nnf
@test nnf(demorgan_or) == demorgan_or_nnf
@test nnf(demogran_and) == demogran_and_nnf
@test nnf(double_not) == double_not_nnf
@test nnf(not_all) == not_all_nnf
@test nnf(not_exists) == not_exists_nnf

@test nnf_expression([:and, implication, double_not]) ==
                         [:and, implication_nnf, double_not_nnf]

@test nnf_expression([:implies, [:implies, :P, :Q], :Q]) ==
                         [:or, [:not, [:or, [:not, :P], :Q]], :Q]

# Variable Replacement
s = Symbol("1")          # First new symbol is always Symbol(1)

exp = [:exists, :x, [:or, [:Friend, :x], [:Enemy, :x]]] # There is someone who's a friend or enemy of x
@test standardize_expression(exp) == [:exists, s, [:or, [:Friend, s], [:Enemy, s]]]

exp = [:exists, :x, [:all, :x, [:or, [:Friend, :x], [:Enemy, :x]]]]   # Make sure existential quanitfier scoping is correct
@test standardize_expression(exp) == [:exists, s, [:all, :x, [:or, [:Friend, :x], [:Enemy, :x]]]]

# Move quantifiers
@test move_quantifiers([:and, P, [:all, x, [Q, x]]]) == [:all, x, [:and, P, [Q, x]]]
@test move_quantifiers([:or, P, [:all, x, [Q, x]]]) == [:all, x, [:or, P, [Q, x]]]
@test move_quantifiers([:and, P, [:exists, x, [Q, x]]]) == [:exists, x, [:and, P, [Q, x]]]
@test move_quantifiers([:or, P, [:exists, x, [Q, x]]]) == [:exists, x, [:or, P, [Q, x]]]

# Skolem Function
x = :x
y = :y
z = :z
@test skolem_function([:all, x, [:exists, y, [:and, [:Animal, y], [:Loves, x, y]]]]) ==
                      [:all, :x, [:and, [:Animal, [Symbol("a()"), :x]], [:Loves, :x, [Symbol("a()"), :x]]]]
                      
@test skolem_function([:all, x, [:all, y, [:exists, z, [:and, [:Animal, z], [:Loves, x, z]]]]]) ==
                      [:all, :x, [:all, :y, [:and, [:Animal, [Symbol("a()"), :x, :y]], [:Loves, :x, [Symbol("a()"), :x, :y]]]]]
