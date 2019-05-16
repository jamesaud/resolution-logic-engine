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
