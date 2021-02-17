<img src="https://github.com/di-unipi-socc/osmolog/blob/master/img/logo.png" width="300">

A declarative solution for placing and configuring applications in Osmotic Computing settings.

## Quickstart Example

Consider the Osmotic application below from Augmented Reality.

<img src="https://github.com/di-unipi-socc/osmolog/blob/master/img/app.png" width="600">

It is made of four MicroELements (MELs), some of which exist in more than one version with different IoT, software and hardware requirements. Versions range from the less demanding `light` version (i.e. triangles) to a `medium` version (i.e. squares) to a `full` version (i.e. circles). Those three versions (or flavours) are suited for IoT, Edge and Cloud devices respectively.

Given a Cloud-IoT infrastructure, osmolog *jointly* determines a solution to these placement-related questions:

> Where to deploy each MEL composing the application?

and

> Which MEL version to deploy?

