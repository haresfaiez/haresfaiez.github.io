- functional programming is found on the idea of data transformation over algorithms.
- need to keep the Virtual DOM element associated with the previous primitive DOM element
  in cache.
- every step is a module/function -> duplication(constaints, checking, validation)
- test is decoupled from the code -> the structure of the code is not reflected in the test
- something I see in most javascript code bases -> every function starts with a null/undefined
  check. This makes me see the code as not-coherent.
  Handle non-conforming input early, before it gets into the system. Check eagerly at the 
  boundaries and fail fast with a good-enough message.
  There are two reasons to have null checks everywhere:
    - have more context to give error messages (this is solved by requiring bette input)
	- laziness (laziness is about evaluation, defer decisions to evaluate, don't defer
	  decisions to validate)
- Dijkstra talked about the concept of abstraction *levels*. While a lot of research in
  software prefers to see a software as a system with many heads/hierarchies.
  That is why the most effective way to develop software is to grow it organically, carefully
  and considerably adding one piece at a time.
  Design, as I have learned from reading C. Alexander,
  is about how much these different systems fits together in a single piece of code.
  The point I want to make here is about functions, each function encapsulate some decisions
  with different impact from the point of view of the function invocation.
  Highliting these decisions inside the implementation of the function needs to be considered
  carefully.
- One of the hardest thing I encountred while reading the code was figuring what is happening.
  I used to ask "why doing that?" "what it means to increment the variable here and here, and
  then passing it to the recursive call?"
  "why is these two numbers calculated differently, but used together in function calls?"
  I am not implying that I could do better, no. That is how code is written.
  The author have different priorities than mine, different background, and certainly
  different taste than mine.
  Most of a language intricacies are the relations between the words, and design is about
  communication and software is about language design.
  Types help, but types are always one level below the code. Why not automating the writing
  of code if that was not the case.
  Tests helps, but test are about results. What you get, not how you get it.
- Don't read code. Analyse or understand the code.
  Line-by-line reading won't got you there. Comments? It hard also.
  Tests, better, but not for everything. Types, an improvement.
  Don't transform it to an algorithm in another format.
  Use different styles to *digest* the code.
  Here's what I found useful:
	- Rubber-ducking. Or post-writing as I did here.
	- Use the code in examples.
	- Change it and see it breaking.
    - I search for the use of a variable/funciton. Where it is used? What different between
	these points of use?
	- I try to group a set of references under a name. How are they contributing here?
	- I try to ignore lines and try to make sense of others. Then, I go back and fit the
	whole together.
	- Think critically about your assumptions about the code.

- reimplementation using Purescript -> (data transformation)
