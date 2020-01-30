
/* re-open device after being detached*/
(
Tdef( 'tryOpenHID' , {
   var keepLooking = true;
   while ( { keepLooking } ){
      if ( ~myhid.notNil ){
         if ( ~myhid.isOpen ){
            keepLooking = false;
         }
      };
      if ( keepLooking ){
         HID.findAvailable;
         if ( HID.findBy(1133, 49686).size > 0 ){
            ~myhid = HID.open( 1133, 49686 );
            if ( ~myhid.notNil ){
               ~myhid.closeAction = {
                    "device closed".postln;
                    Tdef( \tryOpenHID ).reset.play;
               };
               keepLooking = false;
            }{
               3.0.wait;
            };
         }{
            3.0.wait;
         }
      }
   }
} );

Tdef( 'tryOpenHID' ).play;


/*
HID.debug = false;
~myhid.postUsages;
*/



~nyquist = s.sampleRate * 0.5;

~modRange = [0.001, 9, \exp, 0.001].asSpec;
~ampRange = [0.25, 1.0, \linear, 0.001].asSpec;
~relRange = [0.1, 2.0, \linear, 0.001].asSpec;
~decRange = [0.001, 30.0, \exp, 0.001].asSpec;
~ratioSpec = [0, 15, \linear, 1].asSpec;

~ratios = [0.25,0.25,0.5,0.75,0.85,0.9,1,1.1,1.2,1.3,1.4,1.5,1.75,1.8,1.9,2.0];

~lengthSpec = [1.0,0.001,\exp].asSpec;
~trateSpec = [1.0,500.0,\exp].asSpec;
//~lengthSpec = [0.001, 1.0,\linear].asSpec;
//~endSpec = [0.001, 1.0,\linear].asSpec;
~endSpec = [1.0,0.0001,\exp].asSpec;
~clockSpec = [0.5, 3.0, \exp].asSpec;
~startSpec = [0.0,0.9,\linear].asSpec;

~mainGroup = Group.new;
~digitalnatureGroup = Group.new(~mainGroup);
~fieldrecGroup = Group.new(~mainGroup);
~percGroup = Group.new(~mainGroup);
~fmGroup = Group.new(~mainGroup);
~fm1Group = Group.new(~fmGroup);
~fm1Group = Group.new(~fmGroup);
~fm1Group = Group.new(~fmGroup);

~percBus = Bus.audio(s, 1);
~grainverb = Bus.audio(s, 2);

~combPerc = Synth(\perc_effect, [\in, ~percBus], ~percGroup, \addAfter);
~verbsynth = Synth(\grain_verb, [\in, ~grainverb], ~mainGroup, \addAfter);
//~verbsynth.free;

~kick_files = (Platform.resourceDir +/+ "sounds/kicks/*.wav").pathMatch;
~kicks = ~kick_files.collect({|i| Buffer.read(s, i); });

~hat_files = "Drums/HiHat/*.wav".pathMatch;
~hats = ~hat_files.collect({|i| Buffer.read(s, i); });

~cymbal_files = "Drums/Cymbal/*.wav".pathMatch;
~cymbals = ~cymbal_files.collect({|i| Buffer.read(s, i); });

~combo_files = "Drums/Combo/*.wav".pathMatch;
~combo = ~combo_files.collect({|i| Buffer.read(s, i); });

~mallet_files = "Drums/Mallet_Drum/*.wav".pathMatch;
~mallets = ~mallet_files.collect({|i| Buffer.read(s, i); });

~hand_files = "Drums/Hand_Drum/*.wav".pathMatch;
~hand_drums = ~hand_files.collect({|i| Buffer.read(s, i); });

~field_rec_files = "field_recs/*.wav".pathMatch;
~field_recs = ~field_rec_files.collect({|sample| Buffer.read(s, sample); });
~grainfield_recs = ~field_rec_files.collect({|sample| Buffer.readChannel(s, sample, channels: [0] ); });

~recBufs = [ Buffer.alloc(s, 44100*5, 1), Buffer.alloc(s, 44100*5, 1); ];
~samNum1 = 0;
~fftbuf = Buffer.alloc(s, 1024,1);

~freezeSwitch = 0;
~fieldrecSwitch = 0;
~fieldrecnum = 0;

~lengthBus = Bus.control(s, 1).set(0.1);
~startBus = Bus.control(s, 1).set(0.0);
~patAmpBus = Bus.control(s, 1).set(1.0);

~endBus = Bus.control(s, 1).set(~recBufs[~samNum1].numFrames);
~clock = TempoClock.new;

~sine = Env.sine.discretize(1024).putLast(0);
~sineEnv = Buffer.sendCollection(s, ~sine, 1);

~winenv = Env([0, 1, 0], [0.5, 0.5], [8, -8]);
~window = Buffer.sendCollection(s, ~winenv.discretize, 1);


);
(

MIDIIn.connectAll;
/* nanoKontrol  */

MIDIdef.new(\test1, {|val num chan dev|

	[num, val].postln;

	case
	/*play button */
	{ num == 103 }
	{
		if ( val == 127, {
			Synth(\cicade, [\gate,1,\pan, 0.9], ~digitalnatureGroup);

			12.do{|i|
	var pan = (i+1)/6 - 1, amp = (i+1)/6, rate = (i+1)/3+0.25;
	Synth(\cricket, [\gate,1,\rate, rate, \pan, pan, \amp, amp], ~digitalnatureGroup);

};

			Synth(\river, [\pan, -0.8,\gate,1], ~digitalnatureGroup);
		},
		{
			~digitalnatureGroup.set(\gate,0 );

		});

	}

	/* first */
	{ num == 24 } {
		if ( val == 127, {  ~droneSynth = Synth(\magic_drone); }, { ~droneSynth.set(\gate, 0); }); }
	{ num == 32 } { ~droneSynth.set(\ratio, ~ratios[~ratioSpec.map(val/127);]; ); }

	/* second */
	{ num == 25 } {
		if ( val == 127, {  ~sjoerdSynth = Synth(\sjoerd_in,[\in,0]); }, { ~sjoerdSynth.set(\gate, 0); }); }
	{ num == 33 } { ~sjoerdSynth.set(\delAmount, val/127); }
	/* third */
	{ num == 26 } {
		if ( val == 127, {  ~mariSynth = Synth(\mari_in,[\in,1]); },
		{ ~mariSynth.set(\gate, 0); }); }
	{ num == 34 } { ~mariSynth.set(\delAmount, val/127); }
	{ num == 18 } { if ( val == 127, { ~mariSynth.set(\bpAmount, 0.75); }, { ~mariSynth.set(\bpAmount, 0); }); }

	/* fourth */
	{ num == 27 }
	{
	if ( val == 127, {
			~fieldgrain = Synth(\field_grain, [\amp,1, \out,0,\sndbuf, ~grainfield_recs[~fieldrecnum], \envbuf, ~window], ~mainGroup)     },
		{   ~fieldgrain.set(\gate, 0);

		});

	}
	{ num == 3 }
	{ ~fieldgrain.set(\dur, ~lengthSpec.map(val/127));  }
	{ num == 35 }
	{ ~fieldgrain.set(\trate, ~trateSpec.map(val/127)); }
	/* fifth */
	{ num == 28 }
	{
	if ( val == 127, {
		if ( ~fieldrecSwitch == 0, { "play field rec".postln;
			Synth(\field_rec, [\gate,1,\bufnum,~field_recs[~fieldrecnum] ], ~fieldrecGroup);
			~fieldrecSwitch = 1;

			});
		},
		{  if ( ~fieldrecSwitch == 1, { "stop field rec".postln; ~fieldrecGroup.set(\gate, 0);  ~fieldrecSwitch = 0; });
	});
	}
	/* switch field rec sample */
	{ num == 20 }
	{

		if ( ~fieldrecnum == (~field_recs.size-1), { ~fieldrecnum = 0; }, { ~fieldrecnum = ~fieldrecnum + 1; });
		"fieldrec sample: "++~fieldrecnum.postln;




	}
	/* sixth */
	{ num == 29 }
	{

	}

	{ num == 13 }
	{
	if ( val == 127, {
	"rec direct input 0".postln;
	~recsynth1 = Synth(\zitarRecorder, [\in,8,\recbuf, ~recBufs[~samNum1],\fftbuf, ~fftbuf  ]); }, { ~recsynth1.free; });

	}
	/* seven */
	{ num == 30 } {
	"playing pattern".postln;
	if ( val == 127, {
10.do{|i|var pan = ((i+1)*0.1)-1, dur = 0.1 + (i*0.01);
Pbindef(("grainpattern1"++i).asSymbol,\instrument, \radioplaypattern,\group,~mainGroup,
\nyquist, ~nyquist,
\xpos, Pwhite(pan,pan+0.1), \ypos, Pwhite(pan, pan+0.1),
								\out,~grainverb,
\octave, 1,
\start,0,\endBus,~endBus.index,\lengthBus, ~lengthBus.index,\dur,dur,\reverse,Pwrand([1,-1],[0.6,0.4],inf),
\bufnum,~recBufs[~samNum1],\envbuf, ~sineEnv,\ampBus,~patAmpBus.index,\pan,Pwhite(pan,pan+0.1),
).play(~clock);
};	},{ 10.do{|i| Pbindef(("grainpattern1"++i).asSymbol).pause; }; }); }

	{ num == 38 }
	{ ~clock.tempo = ~clockSpec.map(val/127).postln;
		10.do{|i| ~lengthBus.set(~lengthSpec.map(val/127);); } }
	//end position in sample
	{ num == 6 }
	{ ~endBus.set(~lengthSpec.map(val/127)*~recBufs[~samNum1].numFrames); }
	//switch on/off duration variation routine
	{ num == 22 }
	{ if ( val == 127, {
		~durVar = Routine({ inf.do{ 100.do{|i| var dur = ~clock.tempo.reciprocal*0.25, time = 0.001 + rrand(0.0001,0.001);
		10.do{|i|
		~lengthBus.set(rrand(dur*0.001,dur)); }; time.wait; } }}).play; "dur routine playing".postln; },
		{ ~durVar.stop; "dur routine stop".postln; });
	}

/* eight */
	{ num == 31 }
	{

	}

	{ num == 39 } { ~combPerc.set(\mix, val/127); }
	{ num == 7 } { ~combPerc.set(\decay, ~decRange.map(val/127);  ); };

}, nil, 1, \control, nil);




/* nanoPad */

MIDIdef.new(\test2, {|val num chan dev|
	case
	{ num == 36 } { Synth(\kick, [\bufnum, ~kicks.choose,
		\release, ~relRange.map(val/127),
		\amp,~ampRange.map(val/127) ], ~percGroup);
	}
	{ num == 37 } { Synth(\perc, [\out, ~percBus, \bufnum, ~mallets.choose, \amp,~ampRange.map(val/127) ], ~percGroup);
	}
	{ num == 38 } { Synth(\perc, [\out, ~percBus, \bufnum, ~mallets.choose, \amp,~ampRange.map(val/127) ], ~percGroup);
	}
	{ num == 39 } { Synth(\perc, [\out, ~percBus, \bufnum, ~mallets.choose, \amp,~ampRange.map(val/127) ], ~percGroup);
	}
	{ num == 40 } { Synth(\perc, [\out, ~percBus, \bufnum, ~mallets.choose, \amp,~ampRange.map(val/127) ], ~percGroup);
	}
	{ num == 41 } { Synth(\perc, [\out, ~percBus, \bufnum, ~hand_drums.choose, \amp,~ampRange.map(val/127) ], ~percGroup);
	}
	{ num == 42 } { Synth(\perc, [\out, ~percBus, \bufnum, ~mallets.choose, \amp,~ampRange.map(val/127) ], ~percGroup);
	}
	{ num == 43 } { Synth(\perc, [\out, ~percBus, \bufnum, ~mallets.choose, \amp,~ampRange.map(val/127) ], ~percGroup);
	}
	{ num == 44 } { Synth(\perc, [\out, ~percBus, \bufnum, ~mallets.choose, \amp,~ampRange.map(val/127) ], ~percGroup);
	}
	{ num == 45 } { Synth(\perc, [\out, ~percBus, \bufnum, ~mallets.choose, \amp,~ampRange.map(val/127) ], ~percGroup);
	}
	{ num == 46 } { Synth(\perc, [\out, ~percBus, \bufnum, ~mallets.choose, \amp,~ampRange.map(val/127) ], ~percGroup);
	}
	{ num == 47 } { Synth(\perc, [\out, ~percBus, \bufnum, ~mallets.choose, \amp,~ampRange.map(val/127) ], ~percGroup);
	};



	[num, val].postln}, nil, nil, \noteOn, nil);


//MIDIdef.freeAll;



/*    LOGITECH DUAL ACTION MAPPING */
/* main buttons */
~fmSwitch = 0;

HIDdef.usage( \button_1, { |value|

	if ( value == 0, {
	if ( ~fmSwitch != 1, { ~fmSwitch = ~fmSwitch + 1; },
		{
			~fmSwitch = 0;

	});
	("fm synth : "++~fmSwitch).postln;

	});

}, \b1 );


/* synth trigger */
HIDdef.usage( \main_but_1, { |value|
	if ( ~freezeSwitch == 0, {
		if ( value == 1, {

			case
			{ ~fmSwitch == 0 }
			{

				Synth(\fm7, [\gate,1], ~fm1Group); }
			{ ~fmSwitch == 1 }
			{
				Synth(\fmseven, [\gate,1], ~fm1Group);

			};


		}, { ~fm1Group.set(\gate, 0);  });

		});


	}, \b5 );

/* freeze button */
HIDdef.usage( \main_but_2, { |value|
	if ( value == 1, {
		if ( ~freezeSwitch == 0, { ~freezeSwitch = 1; "frozen".postln; }, { ~freezeSwitch = 0; "unfrozen".postln; });
	});
}, \b6 );

HIDdef.usage( \main_but_3, { |value|



	 }, \b7 );


HIDdef.usage( \main_but_4, { |value|

	}, \b8 );


/* eerste joystick */
HIDdef.usage( \x_ax_1, { |value|
	if ( ~freezeSwitch == 0, {
		~fmGroup.set(\mod1, ~modRange.map(value));
	});

	}, \X );
HIDdef.usage( \y_ax_1, { |value|
	if ( ~freezeSwitch == 0, {
		~fmGroup.set(\mod2, ~modRange.map(value));
	});
	}, \Joystick );
HIDdef.usage( \joy_but_1, { |value|  value.postln; }, \b11 );

/* tweede joystick */
HIDdef.usage( \x_ax_2, { |value|
	if ( ~freezeSwitch == 0, {
		~fmGroup.set(\mod3, ~modRange.map(value));
	});
	}, \Y );
HIDdef.usage( \y_ax_2, { |value| if ( ~freezeSwitch == 0, {
	~fmGroup.set(\mod4, ~modRange.map(value));
});
}, \Z );

HIDdef.usage( \joy_but_2, { |value|  value.postln; }, \b12 );



);



Server.default.makeGui


s.boot;



Ndef(\sjoerd_in, {
	var sig = SoundIn.ar(0);

	sig = HPF.ar(sig, 35);
	sig = MidEQ.ar(sig,230,0.6,-8);
	sig = MidEQ.ar(sig,2000,0.6,5);


	sig = sig!2;

}).play;


Ndef(\mariana_in, {
	var sig = SoundIn.ar(1);

	sig = HPF.ar(sig, 35);
	sig = MidEQ.ar(sig,220,0.7,-12);
	sig = MidEQ.ar(sig,1100,0.6,3);
	sig = MidEQ.ar(sig,5000,0.8,2);

	sig = Compander.ar(sig, sig,0.3,1.0,0.2,0.001,0.1,2);

	sig = sig!2;

}).play;





Ndef(\banjo_in, {
	var sig = SoundIn.ar(2);

	sig = HPF.ar(sig, 50);
	sig = AllpassC.ar(sig,0.1,SinOsc.kr(0.003).range(0.001,0.1),SinOsc.kr(0.003).range(1.0,11.0),0.5,sig*0.5);
	sig = AllpassC.ar(sig,0.1,SinOsc.kr(0.003).range(0.001,0.1),SinOsc.kr(0.003).range(1.0,11.0),0.5,sig*0.5);

	sig = sig!2;

}).play;

Ndef(\t,{

	var sig = VarSaw.ar(FSinOsc.kr(0.01).range(97.5,98.5),0,FSinOsc.kr(0.02).range(0.2,0.8),0.3);
	sig = MoogFF.ar(sig, SinOsc.kr(LFNoise0.kr(0.4).range(0.001,0.2)).range(50,900),3,0,0.5,sig*0.5);
	sig = AllpassC.ar(sig,0.1,SinOsc.kr(0.003).range(0.001,0.1),SinOsc.kr(0.003).range(1.0,11.0),0.5,sig*0.5);
	sig = LPF.ar(sig, 900);
	sig = LPF.ar(sig, 900,4);

	Pan2.ar(sig, SinOsc.kr(0.0025).range(-1.0,1.0));


}).play;


~freqRange = [500, 5000, \exponential].asSpec; // create a frequency range

HIDdef.usage( \freq, { |value| Ndef( \sinewave ).set( \freq, ~freqRange.map( value ) ); }, \X );
HIDdef.usage( \amp, { |value| Ndef( \sinewave ).set( \amp, value ); }, \Y );


Ndef( \sinewave ).free;

Quarks.gui




(
{
    var ctls = [
        // freq, phase, amp
        [LFNoise1.kr(0.5).range(300, 310), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 310), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1],
        [LFNoise1.kr(0.5).exprange(3, 100), 0, 1]
    ];
    FM7.arAlgo(1, ctls, MouseX.kr(0, 2))
}.play

)


(
// Courtesy Fredrik Olofsson (2008)
Routine.run{
    var syn, time = 3; // Allow each patch to run for 16sec / 8bars
    inf.do{|i|
        ("// FM7 patch"+i).post;
        syn= ("
            (
            var x= #"++({{{ |i| rrand(0.5, 1.5).round(0.5)}!4}!3}!6).asCompileString++";
            var y= #"++({{{ |i| rrand(0.2, 1.6).round(0.5)}!4}!6}!6).asCompileString++";
            {
                var ctls= x.collect{|a| a.collect{|b| LFSaw.kr(*b)}};
                var mods= y.collect{|a| a.collect{|b| LFPar.kr(*b)}};
                var chans= #[0, 1];
                FM7.ar(ctls, mods).slice(chans)*0.5;
            }.play)").postln.interpret;
        time.wait;
        syn.free;
    };
};
)

(
// Courtesy Fredrik Olofsson (2008), edited by <sk>
// FM7 patch 4 generated on Thu Jun 26 18:27:12 2008







