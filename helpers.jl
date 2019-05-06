using Match

function expand_expression(expression)
    expand(exp) = @match expression begin
        s::Symbol => return s
        e::Expr => return [expand_expression(exp) for exp in e.args]
    end
    return expand(expression)
end
