Kalaxia Client
==============

Kalaxia is a multiplayer strategy game taking place somewhere in space.

The client is powered by Godot Engine.

Setup
-----

Clone the project locally :

```
git clone git@github.com:Kalaxia/client.git kalaxia-client
```

You will need to setup the version resource. You can run `make setup`.
Alternatively you can copy `version_model.txt` rename it to `version.tres`.
Then add at the end of the file `version="#"` where `#` can be anything.

Open the project with Godot.

You will need a local server to run the game. Follow the instructions in [the server repository](https://github.com/Kalaxia/v2-api) to start it.

Documentation
-------------

Conventions and usages are described in the [wiki documentation](https://github.com/Kalaxia/client/wiki).

Contribute
----------

Kalaxia is a free open-source project. You can join the team anytime and reach us via [Discord](https://discordapp.com/invite/mDTms5c).

You are free to improve the game code by opening a pull request. This concerns only technical improvements.

To develop new features and feedbacks, first consult with the team in order to stay organized.

The gitflow is described in the documentation.
