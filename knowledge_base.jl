using Match

include("signature.jl")
include("logic_conversion.jl")
include("helpers.jl")

FN_CHAR = '!'

UQ = :all
EQ = :exists
AND = :and
OR = :or
NOT = :not
IMPLIES = :implies
DIMPLIES = :double_implies
EQUAL = :equal

PROP_ARITY = Dict(UQ=>2, EQ=>2, AND=>2, OR=>2, NOT=>1, IMPLIES=>2, DIMPLIES=>2, EQUAL=>2)
PROP_LOGIC = collect(keys(PROP_ARITY))
PROP_FUNCTIONS = Set([PropFunction(string(key), val) for (key, val) in PROP_ARITY])

function validate_syntax(expression::Expr, signature::Signature)
    diff(x, y) = length(setdiff(x, y))
    constants, relations, functions, prop_functions = syntax(expression)
    return diff(constants, signature.constants) +
           diff(relations, signature.relations) +
           diff(functions, signature.functions) +
           diff(prop_functions, PROP_FUNCTIONS) == 0
end


function _syntax(expression,
                constants::Set{Constant},
                relations::Set{Relation},
                functions::Set{Function},
                prop_functions::Set{PropFunction})

    arity(clause) = length(clause)
    recur(expression) = _syntax(expression, constants, relations, functions, prop_functions)

    @match expression begin
        s::Symbol                                   => push!(constants, Constant(string(s)))

        [op::Symbol, clause...],
          if op in PROP_LOGIC end                   => push!(prop_functions, PropFunction(string(op), arity(clause)))

        [op::Symbol, clause...],
          if string(op)[end] == FN_CHAR end         => push!(functions, Function(string(op), arity(clause)))

        [:equal, [op::Symbol, clause...], val]      => push!(functions, Function(string(op), arity(clause)))

        [op::Symbol, clause...]                     => push!(relations, Relation(string(op), arity(clause)))
    end

    @match expression begin
        [s::Symbol, clause...] => map(recur, clause)
    end
    return constants, relations, functions, prop_functions
end

function syntax(expression::Expr)
    expression = expand_expression(expression)
    c =  Set{Constant}()
    r = Set{Relation}()
    f = Set{Function}()
    p = Set{PropFunction}()
    return _syntax(expression, c, r, f, p)
end

function parse_syntax_from_kb(expressions::Array{Expr}, signature)
    c =  Set{Constant}()
    r = Set{Relation}()
    f = Set{Function}()
    p = Set{PropFunction}()
    for exp in expressions
        if !validate_syntax(exp, signature)
            throw(ArgumentError("Signature does not match syntax: ", expression))
        end
        _c, _r, _f, _p = syntax(exp)
        c = union(c, _c)
        r = union(r, _r)
        f = union(f, _f)
        p = union(p, _p)
    end
    return c, r, f, p
end
