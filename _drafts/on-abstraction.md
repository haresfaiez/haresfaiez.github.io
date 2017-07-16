Edsger Dijkstra once said that "The purpose of abstraction is not to be vague,
but to create a new semantic level in which one can be absolutely precise."
Since a software is merely an intellectual construct -a product of the programmer 
thoughts and imagination,
each piece of a program it is abstract as well as specific,
and that its level of abstraction is defined by its relations with
the other computational units in its context.

A non-specific abstraction might not be a good fit for its context of use.
The opposite of abstraction is continuity, and not specificity.
If we take abstraction as the explicit omit of information about a unit in context,
then continuity is the conservation of every detail as well as the knowledge about the context.
Indeed, an abstraction is abstraction in context, or better,
an abstraction from a concept in a context.
A context is continuous by definion. If we omit a part of the conext, it is not the same conext
anymore.

We think of a context as a story, a picture, or a metphor (more about this later).
Abstraction usefulness has boundaries. When we abstract, we remove details.
Those same details can bring down our assumptions about the abstraction
when we push it beyond its usefulness boundaries.
This is why we talk about a level of abstraction, and not an abstract unit in a vaccum.
A unit is a system of abstract units where the omitted details cannot harm the goal.
Again, the abstraction is tied to its implicit and explicit relationships with the other
abstract units in the same level.

- There is a confusion in the software world between generalization, abstraction, and compression.
- I see a confusion between the abstraction of a real world concept (a tree, a book, a paper, an activity, ...)
  and the abstraction of a computational unit (a unit that only makes sense with the actual program).
  The former help at communication (and at the explanation of the outcome) within the team and with outsiders.
  The later kind of units suppots more the programming activity (the design, the construction of the units forming the program).
- A 'Tree' has not the same meaning in the world as it has in a program. It, certainly, has different intention and meaning for two
  different programs (and two units of the same program).
- The two methods that approaches this and that I am aware of are the mataphor building (introduced by the xp community)
  and the category grouding theory of computational units (encouraged by the functional programming community).
- The problem I see with UML is the assumption that the diagram should have a one-to-one mapping to the code.
  'It's not a programming language', Grady Booch said. And the diagram alone is a weak communication tool, it needs to be
  supported by a conversation and playing with the code.
  This also why it was seen as waste by some agile developer, 'If we can express the idea in the code, why use a diagram.
  If we can generate the class diagram from the code, we create it manually'
  One of my principles is to not draw a diagram on unliss it brings a radical change of perspective to the table.
