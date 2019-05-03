function eliminate_implication(expression::Expr)
    exp = expression.args
    P, Q = exp[2], exp[3]
    return :[or, [not, $P], $Q]
end

function eliminate_double_implications(expression::Expr)
    exp = expression.args
    P, Q = exp[2], exp[3]
    return :[and, [or, $P, [not, $Q]], [or, [not, $P], $Q]]
end

function demorgan_or(expression::Expr)
    P, Q = expression.args[2].args[2].args
    return :[and, [not, $P], [not, $Q]]
end

function demorgan_and(expression::Expr)
    P, Q = expression.args[2].args[2].args
    return :[or, [not, $P], [not, $Q]]
end

function convert(expression::Expr)
    operator = expression[1]     # This should be implicaton
    if operator == :implication
    end
    return "test"
end
