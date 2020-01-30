SynthDef(\cicade, {|out=0 amp=0.5 pan=0 fadeTime=10 gate=0|
	var env, sig, trig, seq, freq, mul, vals;
	env = EnvGen.ar(Env.adsr(fadeTime, 0.0,1.0,fadeTime), gate, doneAction: 2);

	trig = Impulse.kr(0.2);
	vals = [
		[0.5, 128],
		[8,6],
		[30,3]
	];
	freq = TChoose.kr(trig, vals);


	sig = WhiteNoise.ar;
	// The one pole filters in pure data and SC differ, so I changed the coefficents
	// a little. Also the  multiplication by 5 is not in the book, but helps to
	// approach the audible result of Farnells patch.
	sig = (sig - OnePole.ar(sig, exp(-2pi * (8000 * SampleDur.ir))));
	sig = (sig - OnePole.ar(sig, exp(-2pi * (8000 * SampleDur.ir))));
	sig = OnePole.ar(sig, exp(-2pi * (10000 * SampleDur.ir)));
	sig = OnePole.ar(sig, exp(-2pi * (10000 * SampleDur.ir)));
	sig = sig * 5;


	sig = BPF.ar(sig, [7500, 5500], 40.reciprocal).sum * SinOsc.ar(500);
	sig = sig * (1 / (SinOsc.ar( freq[0], 0, freq[1] ).squared + 1));
	sig = (sig - OnePole.ar(sig, exp(-2pi * (4000 * SampleDur.ir)))) * 4;
	Out.ar(out, Pan2.ar(sig*env*amp, pan));
}).store;




SynthDef(\cricket, {|out rate=1 pan amp=0.5 gate=0 fadeTime=8|
	var env,trig, seq, demand, cricket;
	env = EnvGen.ar(Env.adsr(fadeTime, 0.0,1.0,fadeTime), gate, doneAction: 2);
	// instead of [metro], Impulse.kr is used here. Delta t = 17 ms equates to 58.82 Hz.
	trig = Impulse.kr(58.82*rate);

	// the main idea of the following line was to use an approach
	// that uses the same coefficients as described in the pd patch
	seq = Dseq(Array.fill(41, {|i| if(i<7, {(i+2)/9},{0}) }),inf);
	demand = Demand.kr(trig,0,seq);

	// Implementation of the pd code for pulses including amplitude grow:
	// cricket = EnvGen.ar(Env.new([0, 1, 1, 0], [0.0001, 0.0001, 0]), trig) * demand;

	// 2nd implementation: pure data seemed to slightly disobey its own specifications,
	// so I ana lysed the waveform and came up with this:
	cricket = EnvGen.ar(Env.new([0, 1, 0], [4/44100, 0]), trig) * demand;


	cricket = OnePole.ar(cricket, exp(-2pi * (1000 * SampleDur.ir)));
	cricket = (
			// changed the Q factor of the first 3 BPFs to approximate farnells sound
		BPF.ar(cricket, Rand(4200,4700) + ((0..2)*50), 300.reciprocal, 100)).sum
	+ BPF.ar(cricket, Rand(8500,9500), 500.reciprocal, 42
	);
	cricket = ((cricket - OnePole.ar(cricket, exp(-2pi * (Rand(3500,4500) * SampleDur.ir)))) * 0.5);
	Out.ar(out, Pan2.ar(cricket*env*amp, pan));

}).store;

SynthDef(\river, {|out=0 amp=0.5 gate=0 pan=0 fadeTime=3|
	var env, sig, trigs, freq;
	env = EnvGen.ar(Env.adsr(fadeTime, 0.0,1.0,fadeTime),gate, doneAction: 2);
	sig = 6.collect{
		trigs = Dust.kr(170);
		freq =
			// Generally choose from a varied base freq
			TExpRand.kr(800, 2000, trigs)
			// Wobbly variation
			+ LFNoise2.kr(20, mul: 300)
			// General tendency for upward rise
			+ EnvGen.kr(Env.perc(1).range(0,17), trigs);
		SinOsc.ar(freq, 0, 0.3)
	}.mean;

	Out.ar(out, Pan2.ar(sig*env*amp,pan) );
}).store;

SynthDef(\radioplaypattern, {|out=0 ampBus lengthBus start=0 endBus octave=1 trig=1 reverse=1 bufnum envbuf xpos=0 ypos=0 vectorOut nyquist|
	//var trigger = EnvGen.kr(Env([0,1,0],[0.001,0.001]),trig);
	var amp = In.kr(ampBus, 1);
	var end = In.kr(endBus, 1);
	var length = In.kr(lengthBus, 1);
	var env = Osc1.ar(envbuf, length*Rand(1.0,2.0));
	var sig = BufRd.ar(1, bufnum, Phasor.ar(trig, BufRateScale.kr(bufnum)*reverse*octave,start,end ),loop: 1) * env * 0.5;
	//var sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum),trig, loop: 1);
	//Out.ar(out, Pan2.ar(sig, LFNoise1.kr(Rand(0.8,3.2)).range(pan,pan+0.25)));
	//Out.ar(out, Pan4.ar(sig, xpos, ypos));
	sig = LPF.ar(sig, nyquist);
			sig = HPF.ar(sig, 400);
			sig = HPF.ar(sig, 400);
	Out.ar(out, Pan2.ar(sig*amp, LFNoise0.kr(6.4).range(-1.0,1.0) ));
	/*
	Out.ar(out, Pan2.ar(sig*amp,LFNoise0.kr(3.2).range(-1.0,1.0)) );

	Out.ar(out, PanAz.ar(6, sig*amp,
				LFNoise0.kr(3.2).range(0.0,1.0),1.0,6.0,0.5));
			*/
	//Out.ar(out, sig*amp);

	}).store;

SynthDef(\kick, {|out=0 amp=0.5 release=0.2 bufnum pan=0|
	var env, sig;
	env = EnvGen.ar(Env.perc(0.001, release),doneAction: 2);
	sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), 1, 0,0);
	Out.ar(out, Pan2.ar( sig*env*amp, pan)); }).store;

SynthDef(\perc, {|out=0 amp=0.5 release=0.2 bufnum pan=0|
	var env, sig;
	env = EnvGen.ar(Env.perc(0.001, release),doneAction: 2);
	sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), 1, 0,0);
	Out.ar(out, sig*env*amp, pan); }).store;

SynthDef(\perc_effect, {|in=0 out=0 amp=1.0 mix=0.0 decay=1|
	var sig,drysig, wetsig;
	drysig = In.ar(in, 1);
	wetsig = drysig;
	3.do{|i| var del = (i+1)*0.1;
		wetsig = CombL.ar(wetsig, del, SinOsc.kr(del*0.1).range(del*0.1,del),(i+1)*decay,0.4,wetsig*0.6);
	};
	sig = ((1-mix)*drysig) + (mix*wetsig);
	Out.ar(out, Pan2.ar(sig*amp, SinOsc.kr(LFNoise0.kr(0.8).range(0.1,80.0)).range(-0.25,0.25)));
}).store;

SynthDef(\grain_verb, {|in=0 out=0 amp=1.0 mix=0.4 decay=1|
	var sig,sig1,sig2;
	sig = In.ar(in, 2);
	sig1 = sig[0];
	sig2 = sig[1];

	4.do{|i| var del = (i+1)*0.01;
		sig1 = CombC.ar(sig1, del, SinOsc.kr(del*0.1).range(del*0.1,del),(i+1)*0.1,0.17,sig1*0.5);
		sig2 = CombC.ar(sig2, del, SinOsc.kr(del*0.1).range(del*0.1,del),(i+1)*0.1,0.17,sig2*0.5);
	};

	sig = FreeVerb2.ar(sig1, sig2, mix, 0.9,0.7);


	Out.ar(out, Pan2.ar(sig*amp*4, 0));
}).store;


SynthDef(\dist_effect, {|in=0 out=0 amp=1.0 mix=0.0 decay=1|
	var sig,drysig, wetsig;
	drysig = In.ar(in, 1);
	wetsig = drysig;
	wetsig = Decimator.ar(wetsig, 10000,8);
	2.do{|i| var del = (i+1)*0.1;
		wetsig = CombC.ar(wetsig, del, SinOsc.kr(del*0.1).range(del*0.1,del),(i+1)*decay,0.4,wetsig*0.6);
	};
	sig = ((1-mix)*drysig) + (mix*wetsig);
	Out.ar(out, Pan2.ar(sig*amp, SinOsc.kr(LFNoise0.kr(0.8).range(0.1,80.0)).range(-0.25,0.25)));
}).store;

SynthDef(\field_rec, {|out=0 amp=0.4 gate=1 bufnum|
	var env, sig;
	env = EnvGen.ar(Env.adsr(1.0,0.1,0.5,3.0),gate,doneAction: 2);
	sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), 1, 0, 1);
	Out.ar(out, sig*env*amp); }).store;

SynthDef(\fm7, {|out=0 amp=0.4 mod1=0, mod2=0, mod3=0, mod4=0 gate=1|
    var env, ctls, mods, chans, sig;
	env = EnvGen.ar(Env.adsr(1.0,0.1,0.5,2.0),gate, doneAction: 2);
    ctls = [
        // freq, phase, amp
        [LFNoise1.kr(0.5).range(300, 310), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 310), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1]
    ];
    mods = [
        [Line.kr(0, 0.001, 2), Line.kr(0.1, 0, 4), 0, mod2, 0, 0],
        [mod1, 0, 0, 0, 0, 0],
        [0, mod4, 0, 0, mod3, 0],
        [0, mod3, 0, 0, mod4, 0],
        [mod4, 0, 0, 0, 0, 0],
        [mod3, 0, 0, 0, 0, 0]
    ];
    chans = [0, 1];
    sig = FM7.ar(ctls, mods).slice(chans) * -12.dbamp; // using "slice" to select specific channels
	sig = CombC.ar(sig, 0.1, LFNoise2.kr(1.8).range(0.001,0.1),SinOsc.kr(LFNoise2.kr(0.4).range(0.001,0.5)).range(0.1,8.0),0.5,sig*0.5);
	//sig = FreeVerb2.ar(sig[0],sig[1], 0.4, 0.7,0.8);
	Out.ar(out, sig*env*amp);
}).store;

 SynthDef(\fmseven, {|out=0 amp=0.25 gate=1 mod1=1 mod2=1 mod3=1 mod4=1|

	var env = EnvGen.ar(Env.adsr(5.0,0.1,1.0,6.0),gate, doneAction: 2);
            var x= #[ [ [ 0.0, -0.33333333333333, -1.0, 0.0 ], [ 0.75, 0.75, 0.0, -0.5 ], [ -0.5, -0.25, 0.25, -0.75 ], [ -0.5, 1.0, 1.0, 1.0 ], [ 0.0, 0.16666666666667, -0.75, -1.0 ], [ 0.5, 0.5, -0.5, 0.33333333333333 ] ], [ [ -0.33333333333333, 0.5, -0.5, -0.5 ], [ 0.5, 0.75, 0.25, 0.75 ], [ -0.83333333333333, 0.25, -1.0, 0.5 ], [ 1.5, 0.25, 0.25, -0.25 ], [ -0.66666666666667, -0.66666666666667, -1.0, -0.5 ], [ -1.0, 0.0, -0.83333333333333, -0.33333333333333 ] ], [ [ 0.25, -0.5, -0.5, -1.0 ], [ -0.5, 1.0, -1.5, 0.0 ], [ -1.0, -1.5, -0.5, 0.0 ], [ 0.5, -1.0, 1.1666666666667, -0.5 ], [ 0.83333333333333, -0.75, -1.5, 0.5 ], [ 0.25, -1.0, 0.5, 1.0 ] ], [ [ 1.0, 0.33333333333333, 0.0, -0.75 ], [ -0.25, 0.0, 0.0, -0.5 ], [ -0.5, -0.5, 0.0, 0.5 ], [ 1.0, 0.75, 0.5, 0.5 ], [ 0.0, 1.5, -0.5, 0.0 ], [ 1.0, 0.0, -0.25, -0.5 ] ], [ [ 0.5, -0.25, 0.0, 0.33333333333333 ], [ 0.25, -0.75, 0.33333333333333, -1.0 ], [ -0.25, -0.5, 0.25, -1.1666666666667 ], [ 0.0, 0.25, 0.5, 0.16666666666667 ], [ -1.0, -0.5, 0.83333333333333, -0.5 ], [ 0.83333333333333, -0.75, -0.5, 0.0 ] ], [ [ 0.0, -0.75, -0.16666666666667, 0.0 ], [ 1.0, 0.5, 0.5, 0.0 ], [ -0.5, 0.0, -0.5, 0.0 ], [ -0.5, -0.16666666666667, 0.0, 0.5 ], [ -0.25, 0.16666666666667, -0.75, 0.25 ], [ -1.1666666666667, -1.3333333333333, -0.16666666666667, 1.5 ] ] ];
            var y= #[ [ [ 0.0, -0.5, 1.0, 0.0 ], [ -0.5, 1.0, 0.5, -0.5 ], [ 0.0, 0.33333333333333, 1.0, 1.0 ] ], [ [ -0.5, 0.5, 1.0, 1.0 ], [ 0.0, 0.33333333333333, 0.0, 1.5 ], [ -0.5, 0.83333333333333, 1.0, 0.0 ] ], [ [ 0.25, -0.66666666666667, 0.25, 0.0 ], [ 0.5, -0.5, -0.5, -0.5 ], [ 0.5, -0.5, -0.75, 0.83333333333333 ] ], [ [ -0.25, 1.0, 0.0, 0.33333333333333 ], [ -1.25, -0.25, 0.5, 0.0 ], [ 0.0, -1.25, -0.25, -0.5 ] ], [ [ 0.75, -0.25, 1.5, 0.0 ], [ 0.25, -1.5, 0.5, 0.5 ], [ -0.5, -0.5, -0.5, -0.25 ] ], [ [ 0.0, 0.5, -0.5, 0.25 ], [ 0.25, 0.5, -0.33333333333333, 0.0 ], [ 1.0, 0.5, -0.16666666666667, 0.5 ] ] ];

                var ctls= x.collect{|a| a.collect{|b| SinOsc.ar(*b)}};
                var mods= y.collect{|a| a.collect{|b| Pulse.ar(*b)}};
                var chans= #[0, 1, 2, 4, 5];
	var sig = (FM7.ar(ctls, mods).slice(chans) * [mod1*2, mod2*2, LFSaw.kr(mod3*3).range(0, -12.dbamp), mod4, -3.dbamp]).clump(2).sum*0.5;

	3.do{|i| var del = (i+2)*0.1;
		sig = AllpassC.ar(sig,del,LFNoise0.kr(del).range(0.01,del),FSinOsc.kr(LFNoise0.kr(del*mod2).range(0.01,30.0)).range(0.1,(i+1)*(mod4)),0.75,sig*0.25); };

	//sig = Mix(sig);
	Out.ar(out, Pan2.ar(sig*env*amp, LFSaw.kr(LFNoise0.kr(0.8*mod3).range(3.0,120.0)).range(-1.0,1.0) ) );
}).store;


SynthDef(\magic_drone,{|out=0 amp=1.0 gate=1 ratio=1|

	var env = EnvGen.ar(Env.adsr(3.0,0.1,1,4.0),gate, doneAction: 2);
	var sig = VarSaw.ar([82.41,184.995,329.64]*ratio,[0,0,0],
		[ SinOsc.kr(0.01).range(0.3,0.8), LFSaw.kr(0.02).range(0.01,0.5), LFTri.kr(0.04).range(0.5,0.99) ],
		0.33!3);

	sig = Mix(sig);
	3.do{ |i| var del = (i+3)*0.1;

		sig = AllpassC.ar(sig,0.3,SinOsc.kr(0.003).range(0.001,0.3),LFNoise1.kr(0.2).range(1.0,8.0),0.5,sig*0.5);

	};
	Out.ar(out, Pan2.ar(sig*env*amp, SinOsc.kr(0.1).range(-0.4,0.7))    );

}).store;


SynthDef(\sjoerd_in, {|in=0 out=0 amp=0.8 gate=1 delAmount=0|

	var env, sig, delsig;
	env = EnvGen.ar(Env.adsr(3.0,0.1,1,4.0),gate, doneAction: 2);
	sig = SoundIn.ar(in);


	sig = HPF.ar(sig, 35);
	sig = MidEQ.ar(sig,230,0.6,-8);
	sig = MidEQ.ar(sig,2000,0.6,5);
	delsig = sig;
	3.do{|i| var del = (i+1)*0.15;
	delsig = AllpassC.ar(delsig,del,SinOsc.kr(0.003).range(0.01,del),LFNoise1.kr(del).range(1.0,8.0),0.25,delsig*0.9);
	};
	/*
	3.do{|i| var del = (i+1)*0.1;
	delsig = CombC.ar(delsig,del,SinOsc.kr(del*0.001).range(0.01,del),LFNoise1.kr(del).range(1.0,3.0),0.3,delsig*0.7);
	};
	*/
	sig = ((1-delAmount)*sig) + (delAmount * delsig);
	Out.ar(out, Pan2.ar(sig*env*amp,0)    );

}).store;



SynthDef(\mari_in, {|in=0 out=0 amp=0.8 gate=1 delAmount=0 bpAmount=0|

	var env, sig, bpsig, delsig;
	env = EnvGen.ar(Env.adsr(3.0,0.1,1,4.0),gate, doneAction: 2);
	sig = SoundIn.ar(in);


	sig = HPF.ar(sig, 100);
	sig = MidEQ.ar(sig,230,0.6,-12);
	sig = MidEQ.ar(sig,1000,0.6,3);
	sig = MidEQ.ar(sig,2000,0.6,8);
	/*
	bpsig = BPF.ar(sig, 1000,0.3,4.0).tanh;
	sig = ((1-bpAmount)*sig) + (bpAmount * bpsig);
	*/
	delsig = sig;


	//delsig = PitchShift.ar(sig,0.2,1.15,0.1,0.1);

	3.do{|i| var del = (i+1)*0.15;
	delsig = AllpassC.ar(delsig,del,SinOsc.kr(0.003).range(0.01,del),LFNoise1.kr(del).range(1.0,8.0),0.25,delsig*0.9);
	};
	3.do{|i| var del = (i+1)*0.1;
	delsig = CombC.ar(delsig,del,SinOsc.kr(del*0.001).range(0.01,del),LFNoise1.kr(del).range(1.0,3.0),0.3,delsig*0.7);
	};

	sig = ((1-delAmount)*sig) + (delAmount * delsig);
	Out.ar(out, Pan2.ar(sig*env*amp,0));
}).store;



// a custom envelope
SynthDef(\field_grain, { |out=0, gate = 1, amp = 1, sndbuf, envbuf, trate=10 dur=0.1|
    var sig, pan, env, freqdev;

    env = EnvGen.kr(
        Env([0, 1, 0], [1, 1], \sin, 1),
        gate,
        levelScale: amp,
        doneAction: Done.freeSelf);


    Out.ar(out,
		GrainBuf.ar(2, Impulse.kr(FSinOsc.kr(LFNoise2.kr(3.2).range(0.001,15.0)).range(trate*0.75,trate*1.5)), dur, sndbuf, LFNoise1.kr.range(0.5, 2),
			LFNoise2.kr(0.4).range(0, 1), 2, FSinOsc.kr(LFNoise0.kr(3.2).range(0.1,60.0)).range(-1.0,1.0), envbuf) * env)
}).store;




SynthDef(\zitarRecorder, {|in=0 amplitudeBus fftbuf recbuf|
var input = SoundIn.ar(in);
var chain = FFT(fftbuf, input);
var onsets = Onsets.kr(chain,0.3);

//input = Compander.ar(input, input, 0.001,1,0.001,0.001,0.1,500);
//amplitude.poll;
RecordBuf.ar(input, recbuf,loop:0,trigger:onsets);
}).store;