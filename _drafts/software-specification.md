Where I do not agree with BDD:

 * There is no systematic way to software design.

 * Scenarios (as in GWT) are not always the adequate medium
   to convey knowledge/examples. Graphs, grids, excel sheets
   are expressive, but it is complicated to automate checks 
   while using them.
   
 * Examples should be used as a support for shared understanding (as in CRC cards)
   and not for specification. The team, then, chooses the test cases to automate
   as well as their level/granularity regarding to risk/certainty.
   The konwledge cannot be conveyed in examples.
   And it could be acquired using more methods than examples.
   
 * Scenarios are about compression, the reader/maintainer still
   needs to learn the implicit domain konwledge in order to understand what
   is going on. So, it is better to invest effort in better documentation
   and simpler code than automating the checks.
   
 * The solution to the up-to-date documentation is more training/consciousness,
   and not a tool. We are still able to game the tools.
   
 * Natural language/programming language dichotomy.
   Scenarios are trying to solve a human/communication problem (shared understanding, ...)
   with a tool/software through automation.
   Expression are not the concept. The word "tree" is not a tree.
   At best, it reminds us of a tree, and each one of us have a different tree in mind.
   Words are not the whole thing.
   We loose the freedom of natural communication (drawing, diagrams, conversation, ...)
   that enable us to discuss/communicate ideas and thoughts, and we loose the power
   of the programming language trying to fit in the arbitrary language expression.
   Each tool, then, is not used for its own purpose.
   We try to fit two tools together and we loose the power of each of them.
   
 * Each scenario is a box of knowledge. There need to be communicaiton between the boxes.
   Software is knowledge/understanding. There is more to it than the examples.
   The examples are constraints within wich the software should thrive and evolve and
   solve the problems. They are not the specificiation.

 * Conversation, up-to-date documentation, ... are human problems that need to be solved
   with human solution.

Why TDD matters:
 * TDD is not about automation (check automation is a side effect).
 * TDD does not mandate a test structure/format.
 * TDD is a tech solution to a tech problem.
