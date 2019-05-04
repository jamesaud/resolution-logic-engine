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
        s::Symbol => return s
        e::Array => return convert_expression(nnf(e))
    end

    # recur(expression) = @match expression begin
    #     s::Symbol => return s
    #     e::Array => return convert_expression(e)
    # end

    expression = map(expand, expression)
    return expression
end

function test_my(expression)
    answer = convert_expression(expression)
    println(answer)
end

function expand_expression(expression)
    expand(exp) = @match expression begin
        s::Symbol => return s
        e::Expr => return [expand_expression(exp) for exp in e.args]
    end
    return expand(expression)
end
