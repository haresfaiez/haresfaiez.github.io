- Think only about the structure when refactoring
- Instead of mark-swap/recursive set-elements evaluation,
  consider fixed-point convergence:
  f(x) = previous-result & f(x-again)
  or f(x) == previous-result -> f(x) = previous-result 
