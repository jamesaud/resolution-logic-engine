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

function convert_expression(expression::Array)
    expand(expression) = @match expression begin
        s::Symbol => s
        e::Array => convert_expression(nnf(e))
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





function expand_expression(expression)
    expand(exp) = @match expression begin
        s::Symbol => return s
        e::Expr => return [expand_expression(exp) for exp in e.args]
    end
    return expand(expression)
end
