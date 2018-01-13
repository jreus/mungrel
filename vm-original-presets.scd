// PARAMETER PRESETS
( // INIT
o.sl['glen'].valueAction = 0.05;
o.sl['glenv'].valueAction = 0.001;
o.sl['gratev'].valueAction = 0;
o.sl['gpitch'].valueAction = 1.0;
o.sl['gpitchv'].valueAction = 0.01;
o.sl['gposv'].valueAction = 0.01;
o.sl['gsteps'].valueAction = 10000;
o.sl['gpan'].valueAction = 0.0;
o.sl['gpanv'].valueAction = 0.1;
o.sl['gamp'].valueAction = 0.3;
o.sl['gampv'].valueAction = 0.2;
o.sl['gstretch'].valueAction = 1.0;
);

(
// Nice one...
~grainlen = 0.34;
~grainlenvar = 2.28;
~grainpause = 0.15;
~grainpausevar = 9.97;
~grainspd = 0.95;
~grainspdvar = 0.01;
~startvar = 0.01;  // add random variation to the grain start point
~numsteps = 6436;  // try different step numbers
~grainpan = 0.0;
~grainpanvar = 0.5; // increasing the pan variation makes a wider stereo field
~grainamp = 0.4;   // adjust the amplitude as necessary for your sample
~grainampvar = 0.1;
~stretch = 1.69; // you can stretch the sound out to insanely long durations
~mix.set('limitlevel', 0.9, 'verbmix', 0.4, 'verbsize', 0.8);
);


(
~grainlen = rrand(0.01, 0.5);
~grainlenvar = 0.5;
~grainpause = 0.01;
~grainpausevar = 0.0;
~grainspd = 1.0 * Scale.major.ratios[6];
~grainspdvar = 0.01;
~startvar = 0.01;  // add random variation to the grain start point
~numsteps = 10000;  // try different step numbers
~grainpan = 0.0;
~grainpanvar = 0.9; // increasing the pan variation makes a wider stereo field
~grainamp = 0.7;   // adjust the amplitude as necessary for your sample
~grainampvar = 0.2;
~stretch = 1.0; // you can stretch the sound out to insanely long durations
~mix.set('limitlevel', 0.9, 'verbmix', 0.4, 'verbsize', 0.8);
);


