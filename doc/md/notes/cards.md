# Cards


I feel like I'm on the verge of a breakthrough in understanding this, so it's
time to start an Orb doc on (hyper) Cards.


The vision is a hypercard for the future.  This file is likely to be a hot
mess for a good long time; you have been warned.


Here, let's throw out a card.

```orb
:[Vote-Card]:
How do you feel about *voting*

- ( ) I hate it
- ( ) I love it
- ( ) Giraffes!

[[Vote][!@sendVote]] [[View Results][!@viewResults]]
:[/Vote-Card]:
```

The flow is intended to be something like this.


Clicking a result _annotates_ the card:

```orb
:[Vote-Card]:
How do you feel about *voting*

- ( ) I hate it
- ( ) I love it
- (X) Giraffes! #selected-by @~barpub-tarber

[[Vote][!@sendVote]] [[View Results][!@viewResults]]

:[/Vote-Card]:
```
#selected-by claim.#### despair

I sometimes wonder if the task I've set myself is simply imposssible and my
efforts to produce the magickal Orb format are more mania than genius. :\


### contd.

The link syntax is the key complexity sink here.


A link is a message, basically. It's passed to a server, along with a chunk
of Orb as a payload, and the server must decide what to do with it.


``!@sendvote`` is a placeholder, basically. It should be read as "send the
message ``sendvote`` to [something]"


told you this will be a hot mess!


Links and the tag engine need to be functional anyway, so this is all just
an attempt to force the chaos in my brain to stop swirling around so I can
get to that point.
