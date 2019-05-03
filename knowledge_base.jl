
include("signature.jl")

FUNCTION_CHAR = '!'

UQ = "all"
EQ = "exists"
AND = "and"
OR = "or"
NOT = "not"
IMPLIES = "implies"

NAMES = [UQ, EQ, AND, OR, NOT, IMPLIES]

function validate_syntax(expression::Expr, signature::Signature)
    constants, relations, functions = syntax(expression)
    return length(setdiff(constants, signature.constants)) +
           length(setdiff(relations, signature.relations)) +
           length(setdiff(functions, signature.functions)) == 0
end

#####

# Returns the constants, function names and arity, and relations and arity of the given expression
# TODO: Add expressions
function syntax(expression)
    constants =  Set{Constant}()
    relations = Set{Relation}()
    functions = Set{Function}()

    if isa(expression, Symbol)
        constant = Constant(string(expression))
        push!(constants, constant)
        return constants, relations, functions
    end

    # Otherwise it's an expression
    type = expression.head
    exp = expression.args

    operator = exp[1]
    clauses = exp[2: end]

    # Functions end in a special character
    if string(operator)[end] == FUNCTION_CHAR
        push!(functions, Function(string(operator), length(clauses) - 1))  # The output is the last clauses of a function
    else   # It is a relation
        push!(relations, Relation(string(operator), length(clauses)))
    end

    # Recur with expression
    for clause in clauses
        c_constants, c_relations, c_functions = syntax(clause)
        constants = union(constants, c_constants)
        relations = union(relations, c_relations)
        functions = union(functions, c_functions)
    end
    return constants, relations, functions

end
