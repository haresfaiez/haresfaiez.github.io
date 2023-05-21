### Samples
If the testing succeeds, a structure is created:
```erlang
#pass{reason = Reason, samples = lists:reverse(Samples),  printers = lists:reverse(Printers), actions = Actions}.
```
*** `samples` are ...?
`NewSamples = add_samples(MoreSamples, Samples)` is called when the checking succeeds.
It adds `MoreSample` to the existing `Samples`.

*** `printers` are ...?
*** `actions` are ...?

If the input fails to pass the property, a structure is created
```erlang
#fail{reason = Reason, bound = lists:reverse(Bound), actions = lists:reverse(Actions)}.
```
*** `actions` are ...?

### When the proprety first elment is `exists` atom


*** `save_counterexample` is ...?
```erlang
MinTestCase = clean_testcase(MinImmTestCase),
save_counterexample(MinTestCase),
{false, MinTestCase};
```

*** PropEr type server ...?


### ensure_code_loaded
*** `ensure_code_loaded` is ...?

## shrinking
*** `mode = try_cexm` is ...?

### Generation a function as an input

### Targeted Property-Based Testing
*** targeted generation/testing `-define(FORALL_TARGETED ...  proper:targeted ...` is ...?

*** `proper_target` module is ...?
```erlang
%%% @doc This module defines the top-level behaviour for Targeted
%%% Property-Based Testing (TPBT). Using TPBT the input generation
%%% is no longer random, but guided by a search strategy to increase
%%% the probability of finding failing input. For this to work, the user
%%% has to specify a search strategy and also needs to extract
%%% utility values from the system under test that the search strategy
%%% then tries to maximize (or minimize).
```

*** `proper_sa` module / simulated annealing is ...?
```erlang
%%% @doc This module provides simulated annealing (SA) as search strategy
%%% for targeted property-based testing. SA is a local search meta-heuristic
%%% that can be used to address discrete and continuous optimization problems.
%%%
%%% SA starts with a random initial input. It then produces a random input in
%%% the neighborhood of the previous one and compares the fitness of both. If
%%% the new input has a higher fitness than the previous one, it is accepted
%%% as new best input. SA can also accepts worse inputs with a certain
%%% probability.
```
