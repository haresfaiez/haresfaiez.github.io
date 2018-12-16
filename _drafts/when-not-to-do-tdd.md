10 situation I won't use TDD

- I write code I will never change:
  It is enough to test it manually one time
  
- I am figuring out how to make it work:
  The frequency of changing aip is high

- I can get faster feedback than running tests:
  (working on one page prototype
  -> with the right tools, simple page refresh is enough)
  Mistaken for repl-over-tdd dichotomy.
  But I am talking about other means of verification
  than running automated checks

- When I am in the middle of the process of isolating code

- When I copy-past code

- I don't the first test, I try to work it out differently, most of the time through input/output (through the ui, through input)
- I explicitly avoid writing tests for some logic (i can test it through the ui/other-input cheaply), the person who changes the code should know how to do it
- The primary purpose for writing tests is for checking edge cases (exactly to loop down into a highly controlled and small sequence of instructions in the execution)
- I don't write a test I don't really really need it (for design purposes)