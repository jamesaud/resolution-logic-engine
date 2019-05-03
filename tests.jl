using Test
include("logic_conversion.jl")

P = :[and, x, y]
Q = :[or, x, y]
@test eliminate_implication(:[implies, $P, $Q]) == :[or, [not, $P], $Q]
@test demorgan_or(:[not, [or, [$P, $Q]]]) == :[and, [not, $P], [not, $Q]]
@test demorgan_and(:[not, [and, [$P, $Q]]]) == :[or, [not, $P], [not, $Q]]
