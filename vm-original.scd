//////////////////////////////////////////////////////////////////
// Tool to Construct Voices from News Recordings
// Developed at Transmarcations worksession in Brussels
//
// This tool loops through multiple sound recordings and interleaves them at
// the microsound level. Each sound recording is played through in a loop.
//
//
// Copyright 2017 Jonathan Reus
// Subject to the GNU General Public License (GPL)
// https://www.gnu.org/licenses/gpl.txt
//
//////////////////////////////////////////////////////////////////

/////
// NOTES
//
// TODO: This is not an ideal approach, as it is not possible to modulate the grain rate and other
// language-size parameters with sample-accuracy -- better to look at ways of doing this on the
// synthesis server.
//
// TODO: Look into approaches for interleaving selectable segments of sound files.
/////


(
s.waitForBoot {

// Buffers
(
~sampledir = "".resolveRelative +/+ "audio";
b = Array.newClear(7);
b[0] = Buffer.read(s, ~sampledir +/+ "BBC-leadin.wav");
b[1] = Buffer.read(s, ~sampledir +/+ "BBC-womeninterviews.wav");
b[2] = Buffer.read(s, ~sampledir +/+ "BBC-capsizedboatinterview.wav");
b[3] = Buffer.read(s, ~sampledir +/+ "CNN-leadin.wav");
b[4] = Buffer.read(s, ~sampledir +/+ "CNN-summary.wav");
b[5] = Buffer.read(s, ~sampledir +/+ "MSNBC-intro.wav");
b[6] = Buffer.read(s, ~sampledir +/+ "MSNBC-migrantinterview.wav");
);


// Synthdefs
(
SynthDef('grain', {arg buf, outchan, playspeed=1.0, startpos=0.0, dur=0.1, pan=0.0, amp=0.5;
	var sig, ctrlsig, duration, startsample, endsample, numframes, env;
	startsample = BufFrames.kr(buf) * startpos;
	numframes = dur * SampleRate.ir * playspeed;
	endsample = min(startsample + numframes, BufFrames.kr(buf));
	ctrlsig = Line.ar(startsample, endsample, dur, doneAction: 2);
	env = EnvGen.ar(Env.sine, timeScale: dur, doneAction: 2);
	sig = BufRd.ar(1, buf, ctrlsig) * amp * env;
	Out.ar(outchan, Pan2.ar(sig, pan));
}).add;
);


// MixBus
~mixbus = Bus.audio(s, 2);
(
Ndef('mix', {arg limitlevel=0.9, verbmix=0.3, verbsize=0.5;
	var sig = InFeedback.ar(~mixbus, 2); // always use InFeedback in your "end of the line" synths
	sig = FreeVerb.ar(sig, verbmix, verbsize); // a little bit of reverb
	sig = Limiter.ar(sig, limitlevel, dur: 0.001);
	sig = LeakDC.ar(sig);
	Out.ar(0, sig);
}).play;
);


s.sync;

// What does a grain sound like?
Synth('grain', ['buf', b[0], 'outchan', ~mixbus, 'startpos', 0.5, 'amp', 1.0]);
Synth('grain', ['buf', b[1], 'outchan', ~mixbus, 'startpos', 0.5, 'playspeed', 0.3, 'amp', 1.0]); // tiny fractions of sound

2.wait;

// Pseudo-object for stochastics and meta parameters for sculpting sound algorithmically...
( // Parameters
ControlSpec.specs['ms'] = ControlSpec(0.001, 1.0, 4, 0.0001, 1.0, "s");
ControlSpec.specs['gps'] = ControlSpec(0.5, 2000, 3, 1, 100, "gps");
ControlSpec.specs['pitch'] = ControlSpec(-2.0, 2.0, 'lin', 0.001, 1.0);
ControlSpec.specs['n'] = ControlSpec(1, 20000, 'lin', 1, 1000, "steps");
ControlSpec.specs['stretch'] = ControlSpec(0.01, 100.0, 4, 0.01, 1.0);
ControlSpec.specs['pan'] = ControlSpec(-1.0, 1.0, 0, 0.01, 0.0);
ControlSpec.specs['amp'] = ControlSpec(0.0, 1.0, 0, 0.01, 0.5);
ControlSpec.specs['buf'] = ControlSpec(0, 10, 0, 1, 0);

// Helper function to count the numbers after a decimal point
~countDecimals = {arg num;
	var val = 0, pt, str = num.asString;
	pt = str.find(".");
	if (pt.notNil) {
		val = str.size - pt - 1;
	};
	val;
};


o = ();
o.sl = ();  // sliders
o.nb = ();  // number boxes
o.tx = ();  // static text (label)
o.un = ();  // static text (units)


// Parameters array [reference, default value, controlspec]
l = [
	['gbuf', 0, ControlSpec.specs['buf']],
	['glen', 0.1, ControlSpec.specs['ms']],
	['glenv', 0.0, ControlSpec.specs['ms']],  // grain length variation, v suffix indicates a variation parameter
	['grate', 100, ControlSpec.specs['gps']],  // grains per second (together with gsteps controls grain flow)
	['gratev',0.00, ControlSpec.specs['gps']],
	['gsteps', 1000, ControlSpec.specs['n']],   // number of grains the sound file will be divided into
	['gstretch', 1.0, ControlSpec.specs['stretch']],  // stretch factor TODO: redundant, can be replaced completely by gsteps?
	['gpitch', 1.0, ControlSpec.specs['pitch']],
	['gpitchv', 0.0, ControlSpec.specs['pitch']],
	['gposv', 0.00, ControlSpec.specs['ms']],    // random variation of grain position in the buffer
	['gpan', 0.0, ControlSpec.specs['pan']],
	['gpanv', 0.0, ControlSpec.specs['pan']],
	['gamp', 0.3, ControlSpec.specs['amp']],
	['gampv', 0.00, ControlSpec.specs['amp']],
];

w = Window.new("Voice Munger", Rect(0, 0, 500,500)).front;
w.layout = VLayout.new();

l.do {arg item;
	var sym, default, spec;
	sym = item[0]; default = item[1]; spec = item[2];
	o[sym] = default;
	o.tx[sym] = StaticText().minWidth_(60).string_(sym);
	o.sl[sym] = Slider().orientation_('horizontal').value_(spec.unmap(default)).maxHeight_(20).action_({|sl| o[sym] = spec.map(sl.value); o.nb[sym].value_(o[sym]); });
	o.nb[sym] = NumberBox().maxWidth_(60).value_(default).decimals_(~countDecimals.value(spec.step));
	o.un[sym] = StaticText().string_(spec.units);
	w.layout.add(HLayout.new(o.tx[sym], [o.sl[sym], stretch: 1], o.nb[sym], o.un[sym]));
};

);

1.wait;

// Synthesis algorithm
(
r = Tdef('munger', {
	var spd, st, dur, pause, pan, amp, step, buf;
	inf.do {arg count;
		buf = o.gbuf;
		if(buf >= b.size) {
			buf = rrand(0, b.size - 1);
		};
		step = count % (o.gsteps * o.gstretch);
		spd = (o.gpitch + rand2(o.gpitchv)).abs;
		st = ((step / o.gsteps / o.gstretch) + rand2(o.gposv)).abs;
		dur = (o.glen + rand2(o.glenv)).abs;
		pan = o.gpan + rand2(o.gpanv);
		amp = (o.gamp + rand2(o.gampv)).abs;
		pause = (o.grate + rand2(o.gratev)).abs.reciprocal;
		Synth('grain', [
			'buf', b[buf],
			'playspeed', spd,
			'startpos', st,
			'dur', dur,
			'pan', pan,
			'amp', amp,
			'outchan', ~mixbus
		]);
		pause.yield;
	};
});
);

r.play; // start the routine
/*
r.stop; // stop the routine
*/

Ndef('mix').set('limitlevel', 0.9, 'verbmix', 0.3, 'verbsize', 0.5);

};

);
