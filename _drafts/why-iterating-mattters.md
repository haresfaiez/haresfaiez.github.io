The software is more than the user interface in the same sense that is
more than the database, the execution, and the log.
When we are to build a table or a chair, we know where we are heading
toward. We almost see how it will end up looking like.
It isn't probable that we will need to remove a leg of a table after the user
tries it, and even then, a 3D model would save a lot of rework for physical
products.

Thinking about software visibility. Two sayings comes to mind,
the first was of D.T.Ross from 1968 NATO conference
"The most deadly thing in software is the concept,
which almost universally seems to be followed,
that you are going to specify what you are going to do, and then do it.
And that is where most of our troubles come from."
The second was of Frederick Brooks in "No silver bullet",
"The structures of software remain inherently unvisualizable,
thus depriving the mind of some of its most powerful conceptual tools."
An other think I still remember hearing from Grady Booch.
He said: "When I visit a team, I ask them for the patterns of the system"
In "Documenting software architecture", the authors insisted on putting
explicitly to the architecture documentation.

I still think the biggest problem with software is visibility.
How to see the tradeoffs involved in the decisions we need to make?
How to communicate the decisions we have made and the rational that led to them?
In agile initiatives, we focus on shared understanding
more than written documents and comments.
Shared understanding is achieved through conversation and participation
in the design, hence pair/mob programming.

We can draw in a modeling software, we can make it move, we know what the
movement are and the user could imagine that in the world.
The user understand exactly moving the object means and feels like.
She grasps the meaning of each action because he participated in
situations that involve the object.
But, a software user interacts with a software through the interface.
She cannot see the interface.
She cannot manage to keep it all in mind and reason about it as a single whole.

How can we know we are building a right thing?
We don't know. We assume we are.
At best, a set of static interfaces enables the team to test a part of the problem.
They fit well with the other parts?
The interactions as a whole make sense to the user?
How the user will use the software in the real world? and when?
The sum of these answers is more than their sum.

The architecture is a set of patterns.
And patterns are for communication.
The architecture of the software is grown, not choosed or imposed.

I believe that the consistency of design decisions is more important than good design.
UML, wireframes, and a consistent language.
Each view frees us from a set of constraints and enables us to express
the set of forces in that view.
But, the software is more than the sum of its views.
The interactions between the views matter.
When we design to a specified view, we optimize for it, and we
will make decisions that could be significant in the other views of the system.
More dangerous this will be when the view is not the user
view or the business view.


The problem is not with UML itself, but by the illusion that UML should
have a one-to-one mapping to the source code.


When I hear "The software has a database model, a domain model, and a user
interface model are highly correlated", I often hear
"I optimized for three different and got the same units".
And even if the result is unavoidable in the moment,
is the separation worthwhile?
