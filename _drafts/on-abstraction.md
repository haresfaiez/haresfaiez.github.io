Real world concepts aren't a good ground to base the units of software design of software upon.
The expectations we set on
  each of these concept is not the same in software. Think of each software as a new language with the same
  words as the english language, but with different symentics/meaning, or as a new world where the concepts
  are named differently than we konwn. Think of a world where the garden is eating trees and called profile
  when joined with a dog.
- This why it is very complex to design software upfront. It is built behaviour by beahviour, reflecting after
  each step.
  The meaning of the employed concepts emerge, they could change with each new behaviour.
  For the same reason, it is hard to design the software using data types first, these reflects the real world
  and are far from the interaction between each other and the behaviour the software needs to provide.
  The functional programmer succeeds because they base their language is mathematics.
  And as every language, it fails and it, itself, needs a different meaning, a meaning that embraces the ambiguity
  of the domain.

Edsger Dijkstra once said that "The purpose of abstraction is not to be vague,
but to create a new semantic level in which one can be absolutely precise."
Since a software is merely an intellectual construct -a product of the programmer 
thoughts and imagination,
each piece of a program is both abstract and specific.
The level of abstraction of a unit is defined by its relations to
other computational units in its context.
A non-specific abstraction might not be a good fit.
I like to think of non-specific abstraction as units that accomplish a computation
that affects the context of its use, but that the context is not aware of.
A unit with non-explicit IO at the edge of the system for example might be a non-specific abstraction.

The opposite of abstraction is continuity, and not specificity.
If we take abstraction as the explicit omit of information about a unit in context,
then continuity is the conservation of every detail as well as the knowledge about the context.
Indeed, an abstraction is abstraction in context. Or better,
a selection from a set of units and rules from a context.
A context is continuous by definion. it is imaginary.
Stories, pictures, and metphors (more about this later) are imaginary contexts.

Abstraction usefulness has boundaries. When we abstract, we remove details.
Those same details can bring down our assumptions/expectations about the abstraction
when we push it beyond its usefulness boundaries.
///When we omit a part of the conext, it is not the same conext anymore.
This is why we talk about a level of abstraction, and not an abstract unit in a vaccum.
A abstarction level is a system of abstract units where the omitted details cannot harm the objective.
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
