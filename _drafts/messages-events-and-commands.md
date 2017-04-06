Difference between messages, events, and commands

Events, messages, and commands date back to early days of computing.
However, the low cost of ressources 
and the pervasiveness of distrubed systems now, 
brings those concepts to the surface, 
together with new purposes and new use cases.

*Messages*
The message carries data across the network.
It is a communcation medium.
There is no common structure for messages.
But, elements such as the destination and the content are fundamentals to each message.
The message does not constrain neither the representation of the destination
nor the structure of the content.
It is required, though, that the destination attribute specifies the identity of one receiver,
which should be recognizable by the channel used to deliver the message.
If there are multiple destinations, then the source sends each of them a new message.

The two end-points of the communication share a unified structure of the content
and a messaging protocol.
Neither the routing of the message nor the localisation of the destination
is a responsibilty of the source.
The source, however, must ensure the conformity of each message to the communication protocol.
So, activities such as ensuring a successful reception of the message and
providing a valid content structure are are up to the sender.

The message could be sent multiple times.

*Events*
Each event is a fact. It models the occurence of an action in the past.
We have event such as "Flower delivered", "Query executed", and "Mission accomplished".
The event does not necessarily have a consumer. But, it needs to have a source.
One benefit of events is that they decouple the producer from the consumer.
An emitted event could be stored or sent to an event processing network.
A database or an event log, however, are adequate container to store and event locally.
A message, however, could be a medium that carries the event across the network.

Each event occures only once, but it could be sent mulitple times across the networks.

There are two types of event distribution[event processing platform?];
Protocol based(Transport-level protocols)
and API based(two kinds: receiving events objects [as in message-oriented middleware,
reference to stateful ressources]).

*Commands*
A command is an order.
We could have commands such as "Print this invoice", "Execute this query", 
and "Write this entry".
A command implies a high degree of coupling between the source and the destination.
Indeed, the source is fully aware of the capabilities of the destination and the servcies
it provides.
command: order
