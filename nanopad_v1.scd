
(



SynthDef(\fieldperc, {|out=0 amp=0.5 release=0.2 bufnum pan=0 pos=0|
	var env, sig;
	env = EnvGen.ar(Env.perc(0.001, release),doneAction: 2);
	sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), 1,BufFrames.kr(bufnum)*pos,1,0);
	//sig = Decimator.ar(sig, 44100*(1 - amp), Rand(5,16));
	Out.ar(out, sig*env*amp*1.5, pan); }).store;



SynthDef(\perc, {|out=0 amp=0.5 release=0.2 bufnum pan=0|
	var env, sig;
	env = EnvGen.ar(Env.perc(0.001, release),doneAction: 2);
	sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), 1, 0,0);
	sig = Decimator.ar(sig, 44100*(1 - amp), Rand(5,16));
	Out.ar(out, sig*env*amp, pan); }).store;


~mainGroup = Group.new;
~fieldrecGroup = Group.new(~mainGroup);
~percGroup = Group.new(~mainGroup);

~percBus = Bus.audio(s, 1);


~combPerc = Synth(\perc_effect, [\in, ~percBus], ~percGroup, \addAfter);

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


);
(
MIDIIn.connectAll;

~decRange = [0.001, 30.0, \exp, 0.001].asSpec;
~ampRange = [0.25, 0.9, \linear, 0.001].asSpec;
~relRange = [1.0, 5.0, \exp, 0.001].asSpec;

MIDIdef.new(\test1, {|val num chan dev|

	[num, val].postln;

	case
	{ num == 39 } { ~combPerc.set(\mix, val/127); }
	{ num == 7 } { ~combPerc.set(\decay, ~decRange.map(val/127);  ); };

}, nil, 1, \control, nil);


MIDIdef.new(\percussion, {|val num chan dev|
	case
	{ num == 36 } { Synth(\kick, [\bufnum, ~kicks.choose,
		\release, ~relRange.map(val/127),
		\amp,~ampRange.map(val/127) ], ~percGroup);
	}
	{ num == 37 } { Synth(\perc, [\out, ~percBus, \bufnum, ~mallets.choose, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 38 } { Synth(\perc, [\out, ~percBus, \bufnum, ~cymbals.choose, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 39 } { Synth(\perc, [\out, ~percBus, \bufnum, ~combo.choose, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 40 } { Synth(\perc, [\out, ~percBus, \bufnum, ~hats.choose, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 41 } { Synth(\perc, [\out, ~percBus, \bufnum, ~hand_drums.choose, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 42 } { Synth(\perc, [\out, ~percBus, \bufnum, ~kicks.choose, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 43 } { Synth(\perc, [\out, ~percBus, \bufnum, ~mallets.choose, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 44 } { Synth(\perc, [\out, ~percBus, \bufnum, ~cymbals.choose, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 45 } { Synth(\perc, [\out, ~percBus, \bufnum, ~hats.choose, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 46 } { Synth(\perc, [\out, ~percBus, \bufnum, ~hand_drums.choose, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 47 } { Synth(\perc, [\out, ~percBus, \bufnum, ~kicks.choose, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	};

	[num, val].postln}, nil, nil, \noteOn, nil);

MIDIdef.new(\percussion, {|val num chan dev|
	case
	{ num == 36 } { Synth(\kick, [\bufnum, ~grainfield_recs.choose,
		\release, ~relRange.map(val/127),
		\amp,~ampRange.map(val/127) ], ~percGroup);
	}
	{ num == 37 } { Synth(\fieldperc, [\out, ~percBus, \bufnum,
~grainfield_recs.choose, \pos, (val/127)*0.9, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 38 } { Synth(\fieldperc, [\out, ~percBus, \bufnum,
~grainfield_recs.choose, \pos, (val/127)*0.9,\amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 39 } { Synth(\fieldperc, [\out, ~percBus, \bufnum,
~grainfield_recs.choose,\pos, (val/127)*0.9, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 40 } { Synth(\fieldperc, [\out, ~percBus, \bufnum,
~grainfield_recs.choose, \pos, (val/127)*0.9, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 41 } { Synth(\fieldperc, [\out, ~percBus, \bufnum,
~grainfield_recs.choose, \pos, (val/127)*0.9, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 42 } { Synth(\fieldperc, [\out, ~percBus, \bufnum,
~grainfield_recs.choose, \pos, (val/127)*0.9, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 43 } { Synth(\fieldperc, [\out, ~percBus, \bufnum,
~grainfield_recs.choose, \pos, (val/127)*0.9, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 44 } { Synth(\fieldperc, [\out, ~percBus, \bufnum,
~grainfield_recs.choose, \pos, (val/127)*0.9, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 45 } { Synth(\fieldperc, [\out, ~percBus, \bufnum,
~grainfield_recs.choose, \pos, (val/127)*0.9, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 46 } { Synth(\fieldperc, [\out, ~percBus, \bufnum,
~grainfield_recs.choose, \pos, (val/127)*0.9, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	}
	{ num == 47 } { Synth(\fieldperc, [\out, ~percBus, \bufnum,
~grainfield_recs.choose, \pos, (val/127)*0.9, \amp,~ampRange.map(val/127),\release, ~relRange.map(val/127); ], ~percGroup);
	};

	[num, val].postln}, nil, nil, \noteOn, nil);




)