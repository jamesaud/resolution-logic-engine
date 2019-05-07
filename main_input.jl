import YAML
include("knowledge_base.jl")

# Helper functions
print_break() = println("----------------------------------")

function print_data(title, data)
    println(" ", title, ":")
    for elem in data
        println("  - ", elem)
    end
end

function print_title(title)
    print_break()
    println("| ", title)
    print_break()
end

function expand_expression(expression)
    return @match expression begin
        s::Symbol => s
        e::Expr   => [expand_expression(exp) for exp in e.args]
    end
end

# Load data
data = YAML.load(open("input.yml"))
kb = data["knowledge_base"]

# Parse Signature
signature = parse_signature(data["signature"])

print_title("Signature")
print_data(" Constants", signature.constants)
print_data(" Relations", signature.relations)
print_data(" Functions", signature.functions)

# Parse Input to Expr
kb = map(Meta.parse, kb)
kb = map(expand_expression, kb)

# Parse Expr to Data Structures
constants, relations, functions, prop_functions, q_functions = parse_syntax_from_kb(kb, signature)

print_title("Knowledge Base")
print_data("Constants", constants)
print_data("Relations", relations)
print_data("Functions", functions)
print_data("Logic", [collect(prop_functions); collect(q_functions)])
print_break()


# Converting to CNF
resolution(kb)
