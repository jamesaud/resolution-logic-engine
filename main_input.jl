import YAML
include("knowledge_base.jl")

# Load data
data = YAML.load(open("input.yml"))
signature = parse_signature(data["signature"])
kb = data["knowledge_base"]["facts"]

# Parse Input to Expr
sentence = Meta.parse(kb[3])

# Parse Expr to Data Structures
constants, relations, functions = syntax(sentence)

# println(constants, relations, functions)
if validate_syntax(sentence, signature)
    print("Syntax is correct for input")
else
    throw(ArgumentError("Invalid Argument, Signature does not Match Syntax"))
end
