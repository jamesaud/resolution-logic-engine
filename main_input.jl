import YAML
include("knowledge_base.jl")

# Helper functions
function print_data(title, data)
    println(title, ":")
    for elem in data
        println(" - ", elem)
    end
end

# Load data
data = YAML.load(open("input.yml"))
kb = data["knowledge_base"]

# Parse Signature
signature = parse_signature(data["signature"])
println("Signature")
print_data(" Constants", signature.constants)
print_data(" Relations", signature.relations)
print_data(" Functions", signature.functions)
println("----------------------------------")

# Parse Input to Expr
facts = map(Meta.parse, kb["facts"])
theories = map(Meta.parse, kb["theories"])
println(theories)
println("Knowledge Base")

# Parse Expr to Data Structures
constants, relations, functions, prop_functions = parse_syntax_from_kb(facts, signature)



print_data(" Constants", constants)
print_data(" Relations", relations)
print_data(" Functions", functions)
print_data(" Logic", prop_functions)
println("----------------------------------")
