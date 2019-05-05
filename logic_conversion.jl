using Match


# Converts simple expression to negation normal form
function nnf(expression::Array)
    return @match expression begin
      [:implies, P, Q]                 => [:or, [:not, P], Q]
      [:double_implies, P, Q]          => [:and, [:or, P, [:not, Q]], [:or, [:not, P], Q]]
      [:not, [:or, [P, Q]]]            => [:or, [:not, P], [:not, Q]]
      [:not, [:and, [P, Q]]]           => [:or, [:not, P], [:not, Q]]
      [:not, [:not, P]]                => P
      [:not, [:all, x, Px]]            => [:all, x, [:not, Px]]
      [:not, [:exists, x, Px]]         => [:exists, x, [:not, Px]]
      X                                => X
    end
end

function nnf_expression(expression::Array)
    expand(expression) = @match expression begin
        s::Symbol => s
        e::Array => nnf_expression(nnf(e))
    end
    expression = map(expand, nnf(expression))
    return expression
end


# Standardize Variables
# Algorithm: anytime an existential quantifier is seen, change the variable
# symbol_fn: function to get the next symbol
function _standardize_variables(expression, variable_scope::Dict{Symbol, Symbol}, symbol_fn)
    recur(expression) = _standardize_variables(expression, variable_scope, symbol_fn)
    expand(exp) = @match exp begin
        s::Symbol           => get(variable_scope, s, s)
        [:exists, x, e]     => begin
                                symbol = symbol_fn()
                                variable_scope[x] = symbol
                                [:exists, symbol, recur(e)]
                               end
        [:all, x, e]        => begin
                                delete!(variable_scope, x)
                                [:all, x, recur(e)]
                                end
        e::Array            => map(recur, e)
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
      [:and, P, [:all, x, [Q, x]]]    => [:all, x, [:and, P, [Q, x]]]
      [:or, P, [:all, x, [Q, x]]]     => [:all, x, [:or, P, [Q, x]]]
      [:and, P, [:exists, x, [Q, x]]] => [:exists, x, [:and, P, [Q, x]]]
      [:or, P, [:exists, x, [Q, x]]]  => [:exists, x, [:or, P, [Q, x]]]
      X                               => X
    end
end


function move_quantifiers(expression::Array)
    expand(expression) = @match expression begin
        s::Symbol => s
        e::Array => move_quantifiers(_move_quantifiers(e))
    end
    expression = map(expand, _move_quantifiers(expression))
    return expression
end


# Replaces existential qualitifers with the skolem function
# variable_scope should map a variable to a function, like  UxUyEz  z: [f, x, y]
# Replace variabels with f(variable_scope)
# Variables maaps the existentional variable to a skolem function symbol
function _skolem_function(expression, variable_scope::Array{Symbol}, variables::Dict{Symbol, Symbol}, symbol_fn)
    recur(expression) = _skolem_function(expression, variable_scope, variables, symbol_fn)
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
    println(expression)
    return true
end


function skolemize(expression)

end




function expand_expression(expression)
    expand(exp) = @match expression begin
        s::Symbol => return s
        e::Expr => return [expand_expression(exp) for exp in e.args]
    end
    return expand(expression)
end
