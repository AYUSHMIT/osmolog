<img src="https://github.com/di-unipi-socc/osmolog/blob/master/img/logo.png" width="300">

A declarative solution for placing and configuring applications in Osmotic Computing settings.

## Quickstart Example

Consider the Osmotic application below from Augmented Reality.

<img src="https://github.com/di-unipi-socc/osmolog/blob/master/img/app.png" width="500">

It is made of four MicroELements (MELs), some of which exist in more than one version with different IoT, software and hardware requirements. Versions range from the less demanding `light` version (i.e. triangles) to a `medium` version (i.e. squares) to a `full` version (i.e. circles). Those three versions (or flavours) are suited for IoT, Edge and Cloud devices respectively.

Given a Cloud-IoT infrastructure, osmolog *jointly* determines a solution to these placement-related questions:

> Where to deploy each MEL composing the application?

and

> Which MEL version to deploy?

### Model

We first describe the osmolog model, following the input data contained in the file `example.pl`.

#### Application

A fully adaptive version of the application above can be specified as in:

```prolog
mel((usersData,full), [docker], 64, []).

mel((videoStorage,full), [docker], 16, []).
mel((videoStorage,medium), [docker], 8, []).

mel((movementProcessing,full), [docker], 8, []).
mel((movementProcessing,medium), [gcc, make], 4, []).

mel((arDriver,full), [docker], 4, [phone, lightSensor]).
mel((arDriver,medium), [gcc,caffe], 2, [phone, lightSensor]).
mel((arDriver,light), [gcc], 1, [phone]).

mel2mel(usersData, videoStorage, 70).
mel2mel(videoStorage, movementProcessing, 30).
mel2mel(movementProcessing, arDriver, 20).

application((arApp, adaptive), [(usersData,full), (videoStorage,_), (movementProcessing,_), (arDriver,_)]).
```

Note that `mel/4` facts denote all MEL requirements for different versions `(MelId, Version)` in terms of software requirements, hardware resources and IoT requirements. Besides, `mel2mel/3` denote latency requirements in milliseconds between application MELs. Finally, `application/2` facts denote instead the services composing a certain version `(AppId, Version)` of the considered application.

#### Infrastructure

A Cloud-IoT infrastructure of two nodes is declared as in

```prolog
node(edge42, [(gcc,0),(caffe,4)], (6, 3), [(phone,1),(lightSensor,1)]).
node(cloud42, [(docker, 5)], (100, 1), []).

link(edge42, cloud42, 20).
```

Note that `node/4` facts denote the software, hardware and IoT capabilities of each node, associated with their estimated monthly usage cost.
Finally, `link/3` facts denote the end-to-end latency in milliseconds between two nodes.

### Exhaustive Search

### Heuristic Search
