'use strict';

require("./styles.scss");
const js = import("./fountain.js");
js.then(js => {
    const { Elm } = require('./Main');
    var app = Elm.Main.init({ flags: { startingText } });

    app.ports.renderRequest.subscribe(rawScreenplay => {
        const renderedHtml = js.parse(rawScreenplay);
        app.ports.renderResponse.send(renderedHtml);
    })
});

const startingText = `Title:
    Alien
Author:
    Dan O'Bannon

INT. MESS

The entire crew is seated. Hungrily swallowing huge portions of artificial food. The cat eats from a dish on the table.

KANE
First thing I'm going to do when we get back is eat some decent food.

PARKER
I've had worse than this, but I've had better too, if you know what I mean.

LAMBERT
Christ, you're pounding down this stuff like there's no tomorrow.

Pause.

PARKER
I mean I like it.

KANE
No kidding.

PARKER
Yeah.  It grows on you.

KANE
It should.  You know what they make this stuff out of...

PARKER
I know what they make it out of. So what. It's food now. You're eating it.

Suddenly Kane grimaces.

RIPLEY
What's wrong?
`