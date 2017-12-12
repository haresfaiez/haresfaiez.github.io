Communication between software takes many shapes;
shared files, buffers, databases, RPC, HTTP messages, etc.
When two applications communicate,
they share assumptions about the channel of communication and the format of the message.
This is why communication protocols exist.

The problem is that communication protocols are too general to accomodate
the specificity of each application apart.
Indeed, application uses different vocabulary and have different points of view of
the same unit.
Also, different messages require different shapes and are best communicated
through different types of content.

Methods for rejecting unpredictable messages exists all the way down the application stack;
non-standard file formats, mal-written commands, unvalid parameters of a command, ...
The perfect input is a well-typed collection
of data-structures with a list of operations. The problem is how to get there.
The problem is getting the data out there under the shape you need to do the significant
function of the application in the most effective way.

One common goal is, "Make the input formal as soon as possible".
Or "Build a consistent model of the input".

Applications make significant decisions based on external input,
and thus assuring that the input is comprehensible is an issues
that requires rigorous design thought.
It is, also, the kind of problems that mandates collaboration between developers,
UX professionals (to decide what ill-formed input to tolorate), and the business
team (to decide how much cost dealing with such matter is needed).

One of widely acknowelged principle of dealing with outside input is to validate it
at the boundarise of the system.
In other words, a nonvalid data shall not be processed by the application.
This takes away the issues of mixing parsing logic with application (and domain logic) logic.
It also moves the interpretation of the input to the edge, wich eliminates a wide space of
security risks.
This leaves us with a complicated logic at the boundaries.

Let's take a look at different strategies to handle this problem:
 * query languages
 * meta-description/constraints languages
 * let-it-fail
 * compilers
 * interpreters
 * parsers
 * events (stateless)
 * rules(CSS)
 * annotations (doesn't scale/duplicate/hand to refactor-> one level)
 
It turns out, validating data as one expects it exactly is not a common case between
successful applications.

- Imperative data validation. is hard.
- Focus on specification over implementation.

So, what are your stories with such problems? How are used to deal with them?
