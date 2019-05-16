# Logic AI Engine

This algorithm parses first order logic statements in a knowledge base, takes a query, and gives an answer to that query using resolution.

## Input format

Input can be directly as Julia code, but is much easier using the .yml format. 

Please take a look at the input.yml file to see how to formulate the knowledge base, query, and signature. Here is an example of an input.yml file:

```
signature:
  constants:

  functions:

  relations:
    shaves:
      name: shaves
      arity: 2
    barber:
      name: barber
      arity: 1


knowledge_base:
    - [all, x, [all, y, [implies, [and, [barber, x],
                                        [not, [shaves, y, y]]],
                                  [shaves, x, y]]]]

    - [not, [exists, x, [exists, y, [and, [and, [barber, x],
                                                [shaves, y, y]],
                                          [shaves, x, y]]]]]

query:
  - [not, [exists, x, [barber, x]]]
  - [exists, x, [barber, x]]
```

Another example:
```
signature:
  constants:
    - Peter
    - Adam
    - Eve
    - Eva

  functions:
    mother:
      name: Mother!
      arity: 1
  relations:
    friend:
      name: Friend
      arity: 2
    enemy:
      name: Enemy
      arity: 2

knowledge_base:
    - [or, [Friend, Peter, Eve], [Friend, Peter, Adam]]
    - [not, [Friend, Peter, Eve]]

query:
  - Dana
  - [Friend, Peter, Adam]
```

## Running the code

The input must be in a file called `input.yml` and contain a `knowledge_base`, `query`, and valid `signature`. 

For the signature:
    - constants: shown above, separate with dashes on new lines
    - functions: MUST END WITH AN ! to be parsed correctly. So `Mother` is not a valid function name, but `Mother!` is! Must also provide name and arity.
    - relations: Must provide name and arity, and not end in a !. 
    


