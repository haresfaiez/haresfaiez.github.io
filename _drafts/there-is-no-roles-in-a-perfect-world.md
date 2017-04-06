In such a world, the type nails it all, leaving the variable name to either duplicate
the type name or to pick a single-character name.

To dig a little deeper. I will put under lenses the wide decision in the world of OOP
to use the class name for the variable name.
We often see signatures like:

Result doSomething(Computer computer, Program program);
Computer getComputer();
void setComputer(Computer computer);

Those samples fall into the pattern of "The role is the class".

To make this pattern viable, we may have those signature instead
Result doSomething(TheBobMachine computer, TheQuickSortProgram program);

It starts with "The" those reference are unique, they have a global identity within
the context of use.
And those are called object.

The Computer is a clasas, wheareas the TheBobMachine is an object.

To put it in other words, the class is seen as an object from the lenses of the client.
And because each object has a unique identity in the system, its role is its identity.

I think also that the purpose of classes in Object-Oriented Programming languages
is to avoid code duplication and that designing with classes instead of objects
resuts in rigid design(that is often labeld as "Class-Oriented Programming").

We introduce a class for each colleciton of objects that share a common behaviour.
So in a perfect world, each class maps only to one object.

So, the if we are about to use the class name for the variable names we should
talk the language of objects instead of the language of classes.

For object without identity now.

There are also interesting ideas on the advantages of using single word variable names.
Following that line of toughts, we leverage all the knowldge about 
the variable to its type to the point that the set of potential names for variable
of a such type shoudl containt no elements than the type name.
I have no deep understanding for type theory, but I think there are a plenty of
useful patterns and tools that make that kind of decisions viable.

We may end up with 

And mos the object/classes that do not fit in one of the categories explained ahead
are abstractions that hide other programming paradigms in order to make them work
with objects.
