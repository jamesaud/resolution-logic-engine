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


function nnf(expression)
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


function standardize_expression(expression)
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


function move_quantifiers(expression)
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

# Skoelmized, CNF expression should be passed as input
function clause_form(expression)
    remove_and(exp) = @match exp begin
        [:and, P, Q] => union(remove_and(P), remove_and(Q))
        s::Symbol    => Set([s])
        expr         => Set([expr])
    end

    remove_or(exp) = @match exp begin
        [:or, P, Q]  => union(remove_or(P), remove_or(Q))
        s::Symbol    => Set([s])
        expr         => Set([expr])
    end

    expression = remove_and(expression)
    expression = map(remove_or, collect(expression))
    return Set(expression)
end

function print_data(title, data)
    println(" ", title, ":")
    for elem in data
        println("  - ", elem)
    end
end


function _contains_complement(literal, clause::Set)
    return @match literal begin
        [:not, exp] => exp in clause
        exp         => [:not, exp] in clause
    end
end

function _complementary_literals(clause1, clause2)
    get_literal(literal) = @match literal begin
        [:not, l] || l => l
    end
    literals = [lit for lit in clause1 if _contains_complement(lit, clause2)]
    literals = map(get_literal, literals)
    literals = Set(literals)
    return literals
end

function _has_complementary_literals(clause1, clause2)
    return !isempty(_complementary_literals(clause1, clause2))
end

# Removes literals and the their complements in a clause
function _remove_literals_and_negations(literals::Set, clause::Set)
    negated_literals = Set([[:not, l] for l in literals])
    all_literals = union(negated_literals, literals)
    return setdiff(clause, all_literals)
end

function _resolve(clause1::Set, clause2::Set)
    literals = _complementary_literals(clause1, clause2)
    clause = union(clause1, clause2)
    clause = _remove_literals_and_negations(literals, clause)
    return clause
end

# Produces all possible new clauses using the resoltion rule
function _resolution_rule(clauses::Set)
    S = Set()
    for c1 in clauses
        for c2 in clauses
            if _has_complementary_literals(c1, c2)
                sentence = _resolve(c1, c2)
                if !_has_complementary_literals(sentence, sentence)
                    push!(S, sentence)
                end
            end
        end
    end
    return S
end

# Returns all new possible clauses that are entailed
function resolve(clauses::Set)
    S = Set()
    while S != clauses
        clauses = S
        S = _resolution_rule(clauses)
        if any(map(isempty, S))
            throw(ArgumentError("Empty set found during resolution, therefore a contradiction!"))
        end
    end
    return S
end

function resolution(kb::Array, query)
    kb = [kb; [[:not, query]]]
    kb = map(conjunctive_normal_form, kb)
    kb = map(clause_form, kb)
    kb = reduce(union, kb)

    # KB is simply a group of clauses at this point
    print_data("Clauses", kb)
    return true
end
