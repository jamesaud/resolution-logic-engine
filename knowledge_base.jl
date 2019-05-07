using Match

include("signature.jl")
include("logic_conversion.jl")

FN_CHAR = '!'

AND = :and
OR = :or
NOT = :not
IMPLIES = :implies
DIMPLIES = :double_implies
EQUAL = :equal
UQ = :all
EQ = :exists

PROP_ARITY = Dict(AND=>2, OR=>2, NOT=>1, IMPLIES=>2, DIMPLIES=>2, EQUAL=>2)
PROP_FUNCTIONS = Set([PropFunction(string(name), arity) for (name, arity) in PROP_ARITY])

Q_ARITY =  Dict(UQ=>2, EQ=>2)
Q_FUNCTIONS = Set([QuantFunction(string(name), arity) for (name, arity) in Q_ARITY])


function validate_syntax(expression::Array, signature::Signature)
    err(type) = throw(ArgumentError("$type do not match signature in statement: " * string(expression)))
    diff(x, y) = length(setdiff(x, y))

    constants, relations, functions, prop_functions, q_functions = syntax(expression)

    if diff(constants, signature.constants)     != 0; err("Constants")
    elseif diff(relations, signature.relations) != 0; err("Relations")
    elseif diff(functions, signature.functions) != 0; err("Functions")
    elseif diff(prop_functions, PROP_FUNCTIONS) != 0; err("Propositional Logic")
    elseif diff(q_functions, Q_FUNCTIONS)       != 0; err("Quantifier Logic")
    end
end

function _syntax(expression,
                constants::Set{Constant},
                relations::Set{Relation},
                functions::Set{Function},
                prop_functions::Set{PropFunction},
                q_functions::Set{QuantFunction},
                quantified_vars::Set{Symbol})

    arity(clause) = length(clause)
    recur(expression) = _syntax(expression, constants, relations, functions,
                                prop_functions, q_functions, copy(quantified_vars))

    @match expression begin
        s::Symbol,
          if !(s in quantified_vars) end            => push!(constants, Constant(string(s)))

        [op::Symbol, clause...],
          if haskey(PROP_ARITY, op) end             => push!(prop_functions, PropFunction(string(op), arity(clause)))

        [op::Symbol, x, clause...],
          if haskey(Q_ARITY, op) end                => begin push!(q_functions, QuantFunction(string(op), arity(clause)+1))
                                                             push!(quantified_vars, x) end
        [op::Symbol, clause...],
          if string(op)[end] == FN_CHAR end         => push!(functions, Function(string(op), arity(clause)))

        [op::Symbol, clause...]                     => push!(relations, Relation(string(op), arity(clause)))
    end

    @match expression begin
        [op::Symbol, clause...]        => map(recur, clause) # Matches everything but Quantifiers correctly
    end
    return constants, relations, functions, prop_functions, q_functions
end

function syntax(expression::Array)
    c =  Set{Constant}()
    r = Set{Relation}()
    f = Set{Function}()
    p = Set{PropFunction}()
    q = Set{QuantFunction}()
    vars = Set{Symbol}()
    return _syntax(expression, c, r, f, p, q, vars)
end

function parse_syntax_from_kb(expressions::Array, signature)
    c = Set{Constant}()
    r = Set{Relation}()
    f = Set{Function}()
    p = Set{PropFunction}()
    q = Set{QuantFunction}()

    for exp in expressions
        validate_syntax(exp, signature)
        _c, _r, _f, _p, _q = syntax(exp)
        c = union(c, _c)
        r = union(r, _r)
        f = union(f, _f)
        p = union(p, _p)
        q = union(q, _q)
    end
    return c, r, f, p, q
end
