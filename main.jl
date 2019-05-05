import YAML
include("knowledge_base.jl")

#=
signature:
  constants:
    - Peter

  functions:
    lower:
      name: Lower
      args: [Peter]
      output: peter

  relations:
    friend:
      name: Friend
      arity: 2

knowledge_base:
  - (Friend Peter Adam)
  - (Friend Adam Eve)
=#

data = YAML.load(open("input.yml"))
signature = parse_signature(data["signature"])
kb = data["knowledge_base"]["facts"]

sentence = Meta.parse(kb[3])
#sentence = :[and, [Friend, peter, tim], [Friend, peter, [Mother, jim]]]

constants, relations, functions = syntax(sentence)
# println(constants, relations, functions)
# println(validate_syntax(sentence, signature))
# println(convert(sentence))
println(expand_expression(sentence))

# Scan through and get function and relationship names
# Get arity of functions and relations
# Get constants
# Make sure they all appear in the signature correctly
