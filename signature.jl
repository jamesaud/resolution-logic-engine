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

struct Signature
    constants::Set{Constant}
    relations::Set{Relation}
    functions::Set{Function}
end


function parse_constants(constants_data)
    return Set(map(Constant, constants_data))
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
        push!(functions, fn)
    end
    return functions
end

function parse_signature(signature_data)
    data = signature_data
    constants = parse_constants(data["constants"])
    relations = parse_relations(data["relations"])
    functions = parse_functions(data["functions"])
    return Signature(constants, relations, functions)
end
