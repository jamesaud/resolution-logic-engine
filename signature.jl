struct Constant
    name::String
end

struct Relation
    name::String
    arity::Integer
end

struct Function
    name::String
    arity::Integer
end

struct PropFunction
    name::String
    arity::Integer
end

struct QuantFunction
    name::String
    arity::Integer
end

struct Signature
    constants::Set{Constant}
    relations::Set{Relation}
    functions::Set{Function}
end

mutable struct KnowledgeBase
    sentences::Array
end

function parse_constants(constants_data)
    constants = Set{Constant}()
    for constant in constants_data
        constant = Constant(constant)
        push!(constants, constant)
    end
    return constants
end

function parse_relations(relations_data)
    relations = Set{Relation}()
    for relation in relations_data
        relation = relation.second
        relation = Relation(relation["name"], relation["arity"])
        push!(relations, relation)
    end
    return relations
end

function parse_functions(functions_data)
    functions = Set{Function}()
    for fn in functions_data
        fn = fn.second
        fn = Function(fn["name"], fn["arity"])
        if fn.name[end] != '!'
            throw(ArgumentError("Functions should end with '!': " * fn.name))
        end
        push!(functions, fn)
    end
    return functions
end


function get_var(data, var)
    val = get(data, var, [])
    return val == nothing ? [] : val
end

function parse_signature(data)
    constants = parse_constants(get_var(data, "constants"))
    relations = parse_relations(get_var(data, "relations"))
    functions = parse_functions(get_var(data, "functions"))
    return Signature(constants, relations, functions)
end
