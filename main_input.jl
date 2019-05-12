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
    res = @match expression begin
        s::Symbol => s
        e::Expr   => map(expand_expression, e.args)
    end
    return res
end

function input_to_julia(input::String)
    input = Meta.parse(input)
    input = expand_expression(input)
    return input
end

# Load data
data = YAML.load(open("_input.yml"))

# Parse Signature
signature = parse_signature(data["signature"])

print_title("Signature")
print_data(" Constants", signature.constants)
print_data(" Relations", signature.relations)
print_data(" Functions", signature.functions)

# Parse Input to Expr
kb = map(input_to_julia, data["knowledge_base"])


# Parse Expr to Data Structures
constants, relations, functions, prop_functions, q_functions = parse_syntax_from_kb(kb, signature)

print_title("Knowledge Base")
print_data("Constants", constants)
print_data("Relations", relations)
print_data("Functions", functions)
print_data("Logic", [collect(prop_functions); collect(q_functions)])


# Converting to CNF
queries = map(input_to_julia, data["query"])

print_title("Input for Resolution")
print_data("KB", kb)
print_data("Queries", queries)

print_title("Entailment for Queries")
answers = [resolution(kb, query)[1] for query in queries]
query_answers = map(qa -> string(qa[1]) * "  ⊨ " * string(qa[2]), zip(queries, answers))
print_data("", query_answers)
