# hubot-malta

Malta is the team-building chat bot plugin for Hubot

See [`src/malta.coffee`](src/malta.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-malta --save`

Then add **hubot-malta** to your `external-scripts.json`:

```json
[
  "hubot-malta"
]
```

## Sample Interaction

The unique thing in tebot's source depends on hubot's `redis-brain` plugin, or
the in-memory brain to save persistent information.  Most hubot plugins only
seem to answer single commands, but don't have a conversation with the user.

`find me a team` command starts a dialog between tebot and the user to build a
database suitable for building teams at a Hack-a-Thon.  Say "help" in a private
message to tebot and read the full list of supported commands.

```
user1>> tebot find me a team
hubot>> (...)
user1>> tebot: i have an idea
hubot>> (...)
user1>> eating a whole wheel of cheese
hubot>> Ok, user1.  I have saved your idea.
user1>> tebot: list users
user1>> tebot: list ideas
user1>> tebot: list me
hubot>> (...)
user1>> tebot: unlist me
hubot>> (...)
```
