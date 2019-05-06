using Match


# Converts expression to negation normal form
function eliminate_implication(expression)
    conversion = @match expression begin
      [:implies, P, Q]                 => [:or, [:not, P], Q]
      [:double_implies, P, Q]          => [:and, [:or, P, [:not, Q]], [:or, [:not, P], Q]]
      X                                => X
    end

    return @match conversion begin
        s::Symbol => s
        e::Array => map(eliminate_implication, e)
    end
end

function move_not_inward(expression)
    conversion = @match expression begin
        [:not, [:or, P, Q]]            => [:and, [:not, P], [:not, Q]]
        [:not, [:and, P, Q]]           => [:or, [:not, P], [:not, Q]]
        [:not, [:not, P]]                => P
        [:not, [:all, x, Px]]            => [:exists, x, [:not, Px]]
        [:not, [:exists, x, Px]]         => [:exists, x, [:not, Px]]
        X                                => X
    end

    return @match conversion begin
        s::Symbol => s
        e::Array => map(move_not_inward, e)
    end
end


function nnf(expression::Array)
    expression = eliminate_implication(expression)

    prev_exp = nothing
    while expression != prev_exp
        prev_exp = expression
        expression = move_not_inward(expression)
    end
    return expression
end


# Standardize Variables
# Algorithm: anytime an existential quantifier is seen, change the variable
# symbol_fn: function to get the next symbol
function _standardize_variables(expression, variable_scope::Dict{Symbol, Symbol}, symbol_fn)
    recur(expression) = _standardize_variables(expression, variable_scope, symbol_fn)
    expand(exp) = @match exp begin
        s::Symbol                           => get(variable_scope, s, s)
        [:exists, x, e]                     => begin
                                                symbol = Symbol(string(x) * string(symbol_fn()))
                                                variable_scope[x] = symbol
                                                [:exists, symbol, recur(e)]
                                               end
        [:all, x, e]                        => begin
                                                symbol = Symbol(string(x) * string(symbol_fn()))
                                                variable_scope[x] = symbol
                                                [:all, symbol, recur(e)]
                                               end
        e::Array                            => map(recur, e)
    end
    return expand(expression)
end


function standardize_expression(expression::Array)
    variable_scope =  Dict{Symbol, Symbol}()
    # Create new Symbol everytime the function is called
    count = 0
    function symbol_fn()
        count += 1
        return Symbol(count)
    end
    expression = _standardize_variables(expression, variable_scope, symbol_fn)
    return expression
end


# SKOLEMIZATION
function _move_quantifiers(expression)
    return @match expression begin
      [:and, P, [:all, x, [Q, x]]]    || [:and, [:all, x, [Q, x]], P]    => [:all, x, [:and, P, [Q, x]]]
      [:or, P, [:all, x, [Q, x]]]     || [:or, [:all, x, [Q, x]], P]     => [:all, x, [:or, P, [Q, x]]]
      [:and, P, [:exists, x, [Q, x]]] || [:and, [:exists, x, [Q, x]], P] => [:exists, x, [:and, P, [Q, x]]]
      [:or, P, [:exists, x, [Q, x]]]  || [:or, [:exists, x, [Q, x]], P]  => [:exists, x, [:or, P, [Q, x]]]
      X                                    => X
    end
end


function move_quantifiers(expression::Array)
    recur(expression) = @match expression begin
        s::Symbol => s
        e::Array => move_quantifiers(_move_quantifiers(e))
    end

    # Keep moving quanitifers outward if needed
    prev_exp = nothing
    while expression != prev_exp
        prev_exp = expression
        expression = map(recur, _move_quantifiers(prev_exp))
    end
    return expression
end


# Replaces existential qualitifers with the skolem function
# variable_scope should map a variable to a function, like  UxUyEz  z: [f, x, y]
# Replace variabels with f(variable_scope)
# Variables maaps the existentional variable to a skolem function symbol
function _skolem_function(expression, variable_scope::Array{Symbol}, variables::Dict{Symbol, Symbol}, symbol_fn)
    recur(expression) = _skolem_function(expression, copy(variable_scope), copy(variables), symbol_fn)
    expand(exp) = @match exp begin
        s::Symbol           => begin
                                if haskey(variables, s)
                                    e = [variables[s]]
                                    append!(e, variable_scope)
                                else
                                    e = s
                                end
                                e
                               end
        [:all, x, e]        => begin
                                push!(variable_scope, x)
                                [:all, x, recur(e)]
                               end
        [:exists, x, e]     => begin
                                variables[x] = symbol_fn()
                                recur(e)
                               end
        e                   => map(recur, e)
    end
    return expand(expression)
end

function skolem_function(expression)
    alphabet = map(string, collect('a':'z'))
    alphabet = [letter * "()" for letter in alphabet]
    alphabet = reverse(alphabet)
    alphabet = map(Symbol, alphabet)

    function symbol_fn()
        return pop!(alphabet)
    end

    variables = Dict{Symbol, Symbol}()
    variable_scope = Symbol[]
    expression = _skolem_function(expression, variable_scope, variables, symbol_fn)
    return expression
end


function drop_universal_quantifiers(expression)
    return @match expression begin
        s::Symbol           => s
        [:all, x, e]        => drop_universal_quantifiers(e)
        e                   => map(drop_universal_quantifiers, e)
    end
end


function _distribute_or_and(expression)
    recur(exp) = _distribute_or_and(exp)
    return @match expression begin
        s::Symbol                                        => s
        [:or, P, [:and, Q, R]] || [:or, [:and, Q, R], P] => recur([:and, [:or, P, Q], [:or, P, R]])
        e                                                => map(recur, e)
    end
end

function distribute_or_and(expression)
    prev_exp = nothing
    while expression != prev_exp
        prev_exp = expression
        expression = _distribute_or_and(expression)
    end
    return expression
end

function conjunctive_normal_form(expression)
    # 1: Negation Normal Form
    expression = nnf(expression)

    # 2: Standardize Variables
    expression = standardize_expression(expression)

    # 3: Skolemize the statement
    expression = move_quantifiers(expression)
    expression = skolem_function(expression)

    # 4: Drop universal quanitfiers
    expression = drop_universal_quantifiers(expression)

    # 5: Distribute ors and ands
    expression = distribute_or_and(expression)

    return expression
end


function expand_expression(expression)
    expand(exp) = @match expression begin
        s::Symbol => return s
        e::Expr => return [expand_expression(exp) for exp in e.args]
    end
    return expand(expression)
end
