using Match
include("mgu.jl")


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

function _contains_complement_literal(literal, clause::Set)
    return @match literal begin
        [:not, exp] => exp in clause
        exp         => [:not, exp] in clause
    end
end

function _complementary_literals(clause1, clause2)
    get_literal(literal) = @match literal begin
        [:not, l] || l => l
    end
    literals = [lit for lit in clause1 if _contains_complement_literal(lit, clause2)]
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
            try
                if _has_complementary_predicates(c1, c2)
                    c1, c2, subs = unify_clause_predicates(c1, c2)
                end
            catch exception
                continue
            end
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


# Returns the complementary predicates expressions in clause 1
function _complementary_predicate_expressions(clause1, clause2)

    is_in_expr(pred, expr) = @match expr begin
        [p, _...] => p == pred
        _         => false
    end

    is_negation_in_expr(pred, expr) = @match expr begin
        [:not, [p, _...]] => p == pred
        _                 => false
    end

    is_in_clause(pred, clause) = any(is_in_expr(pred, e) for e in clause)
    is_negation_in_clause(pred, clause) = any(is_negation_in_expr(pred, e) for e in clause)

    is_complementary(expr, clause2) = @match expr begin
        [:not, [p, _...]] => is_in_clause(p, clause2)
        [p, _...]         => is_negation_in_clause(p, clause2)
        _                 => false
    end

    predicates = [expr for expr in clause1 if is_complementary(expr, clause2)]
    return predicates
end

function _extract_predicate(expr)
    return @match expr begin
        [:not, [p, _...]] => p
        [p, _...]         => p
    end
end


function _complementary_predicates(clause1, clause2)
    expressions = _complementary_predicate_expressions(clause1, clause2)
    predicates = [_extract_predicate(expr) for expr in expressions]
    return Set(predicates)
end

function _has_complementary_predicates(clause1, clause2)
    return !isempty(_complementary_predicates(clause1, clause2))
end

function _replace_unbounded_variable(clause::Set, var, new_var)
    replace_variable(expr) = @match expr begin
        s::Symbol        => var == s ? new_var : s
        [p, e...]        => [p, map(replace_variable, e)...]
        [:not [p, e...]] => [:not, [p, map(replace_variable, e)...]]
        e                => e
    end

    replace(expr) = @match expr begin
        [p, e...] || [:not [p, e...]] => replace_variable(expr)
        e                             => e
    end

    return Set([replace(expr) for expr in clause])
end

# Finds predicate in CNF clause and unifies based on it. Returns clauses with predicate replaced with the unification
function unify_clause_predicates(clause1::Set, clause2::Set)
    extract_predicate_expression(expr) = @match expr begin
        [:not, [p, e...]] => [p, e...]
        [p, e...]         => [p, e...]
    end

    replace(expr, predicate, new_expr) = begin
        expr = @match expr begin
            [:not, [p, _...]] => p == predicate ? [:not, new_expr] : expr
            [p, _...]         => p == predicate ? new_expr : expr
            _                 => expr
        end
        return expr

    end

    c1_expressions = _complementary_predicate_expressions(clause1, clause2)
    c2_expressions = _complementary_predicate_expressions(clause2, clause1)
    c1_expressions = map(extract_predicate_expression, c1_expressions)
    c2_expressions = map(extract_predicate_expression, c2_expressions)

    unifications = [unify(e1, e2) for (e1, e2) in zip(c1_expressions, c2_expressions)]
    unifications, subs = collect(zip(unifications...))
    subs = reduce(merge, subs)
    predicates = map(_extract_predicate, c1_expressions)


    c1, c2 = clause1, clause2
    for (pred, unification) in zip(predicates, unifications)
        c1 = [replace(expr, pred, unification) for expr in c1]
        c2 = [replace(expr, pred, unification) for expr in c2]
    end

    # Now unbound variables in other predicates need to replaced
    c1, c2 = Set(c1), Set(c2)

    for (var, new_var) in subs
        c1 = _replace_unbounded_variable(c1, var, new_var)
        c2 = _replace_unbounded_variable(c2, var, new_var)
    end

    return c1, c2, subs
end


# Returns all new possible clauses that are entailed, throws exception if contradiction found
function resolve(clauses::Set)
    S = clauses
    _prev = Set()

    # Run until no new clauses are found
    while _prev != S
        _prev = S
        S = union(S, _resolution_rule(S))
        if any([isempty(c) for c in S])
            throw(ArgumentError("Empty set found during resolution, therefore a contradiction!"))
        end
    end
    return S
end

# Returns true if statement in resolution, and all of the generated clauses
function resolution(kb::Array, query)
    kb = [kb; [[:not, query]]]
    kb = map(conjunctive_normal_form, kb)
    kb = map(clause_form, kb)
    kb = reduce(union, kb)

    try
        resolve(kb)
        return false
    catch exception
        return true
    end
end

function resolution_steps(kb::Array)
    kb = map(conjunctive_normal_form, kb)
    kb = map(clause_form, kb)
    kb = reduce(union, kb)
    return resolve(kb)
end

function print_data(title, data)
    println(" ", title, ":")
    for elem in data
        println("  - ", elem)
    end
end
