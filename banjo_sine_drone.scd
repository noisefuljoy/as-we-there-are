





~banjodrones = [
Ndef(\banjo_sine_drone1, {|ratio=2 delmod=1 del=1 fadeTime=3|

	var sig = SinOsc.ar(196*SinOsc.kr(LFNoise2.kr(0.8).range(0.0001,0.001)).range(0.98,1.015)*ratio,
		SinOsc.kr(LFNoise0.kr(0.01).range(0.001,1.0)).range(-2pi, 2pi),
		SinOsc.kr(LFNoise1.kr(0.1).range(0.001,0.1)).range(0.15,0.3));

Pan2.ar(AllpassC.ar(sig, 0.1,SinOsc.kr(LFNoise0.kr(0.2).range(0.001,0.01*del )).range(0.001,0.1),SinOsc.kr(0.002*delmod).range(0.1,8.0),0.55,sig*0.25), SinOsc.kr(0.02).range(-0.25,0.25));

}),

Ndef(\banjo_sine_drone2, {|ratio=2 delmod=1 del=1|

	var sig = SinOsc.ar(293.66*SinOsc.kr(0.005).range(0.99,1.025)*ratio,
		SinOsc.kr(LFNoise1.kr(0.025).range(0.001,2.0)).range(-2pi, 2pi),
		SinOsc.kr(LFNoise1.kr(0.2).range(0.001,2.5)).range(0.15,0.3));

		Pan2.ar(AllpassC.ar(sig, 0.1,SinOsc.kr(LFNoise0.kr(0.1).range(0.0025,0.01*del)).range(0.001,0.1),SinOsc.kr(0.004*delmod).range(0.1,12.0),0.6,sig*0.4)*0.75, SinOsc.kr(0.04).range(-0.5,0.5));
}),

Ndef(\banjo_sine_drone3, {|ratio=2 delmod=1 del=1|

		var sig = SinOsc.ar(440*SinOsc.kr(0.01).range(0.97,1.01)*ratio,
		SinOsc.kr(LFNoise2.kr(0.05).range(0.001,5.0)).range(-2pi, 2pi),
		SinOsc.kr(LFNoise1.kr(0.4).range(0.001,5.0)).range(0.15,0.3) );

		Pan2.ar(AllpassC.ar(sig, 0.1,SinOsc.kr(LFNoise0.kr(0.4).range(0.001,0.1*del)).range(0.001,0.1),SinOsc.kr(0.002*delmod).range(0.1,16.0),0.5,sig*0.5)*0.5, SinOsc.kr(LFNoise2.kr(0.2).range(0.1,20.0) ).range(-1.0,1.0));

}),

Ndef(\banjo_sine_drone4, {|ratio=2 delmod=1 del=1|
		var sig = SinOsc.ar(587.33*SinOsc.kr(0.005).range(0.99,1.03)*ratio,

		SinOsc.kr(LFNoise0.kr(0.075).range(0.001,10.0)).range(-2pi, 2pi),
		SinOsc.kr(LFNoise1.kr(0.8).range(0.001,10.0)).range(0.15,0.3) );

		Pan2.ar(AllpassC.ar(sig, 0.1,SinOsc.kr(LFNoise2.kr(0.8).range(0.001,0.01*del)).range(0.001,0.1),SinOsc.kr(0.005*delmod).range(0.1,24.0),0.3,sig*0.75)*0.35, SinOsc.kr(LFNoise0.kr(0.8).range(0.1,30.0) ).range(-1.0,1.0));
});
];



~field_rec_files = "field_recs/*.wav".pathMatch;
~field_recs = ~field_rec_files.collect({|sample| Buffer.read(s, sample); });
~grainfield_recs = ~field_rec_files.collect({|sample| Buffer.readChannel(s, sample, channels: [0] ); });


~droneRatios = [0.25,0.5,1,2,4,8,16];
~ratioRange = [0,6,\linear,1].asSpec;
~deldecRange = [1,100000,\exp,0.001].asSpec;
~delRange = [1,100,\exp,0.001].asSpec;

//MIDIIn.connectAll;

MIDIdef.new(\test2, {|val num chan dev|
	[num, val].postln;
	case
	{ num == 19 } {

			if ( val == 127, {
			~banjodrones.put(0,
			Ndef(\banjo_sine_drone1, {|ratio=2 delmod=1 del=1 fadeTime=3|

						var sig = PlayBuf.ar(1, ~grainfield_recs[4],
						BufRateScale.kr(~grainfield_recs[4])*SinOsc.kr(LFNoise2.kr(0.8).range(0.0001,0.001)).range(0.98,1.015),
							1,0,1);

Pan2.ar(AllpassC.ar(sig, 0.1,SinOsc.kr(LFNoise0.kr(0.2).range(0.001,0.01*del )).range(0.001,0.1),SinOsc.kr(0.002*delmod).range(0.1,8.0),0.55,sig*0.25), SinOsc.kr(0.02).range(-0.25,0.25));
					});
				);

			}, {

	~banjodrones.put(0,
			Ndef(\banjo_sine_drone1, {|ratio=2 delmod=1 del=1 fadeTime=3|

	var sig = SinOsc.ar(196*SinOsc.kr(LFNoise2.kr(0.8).range(0.0001,0.001)).range(0.98,1.015)*ratio,
		SinOsc.kr(LFNoise0.kr(0.01).range(0.001,1.0)).range(-2pi, 2pi),
		SinOsc.kr(LFNoise1.kr(0.1).range(0.001,0.1)).range(0.15,0.3));

Pan2.ar(AllpassC.ar(sig, 0.1,SinOsc.kr(LFNoise0.kr(0.2).range(0.001,0.01*del )).range(0.001,0.1),SinOsc.kr(0.002*delmod).range(0.1,8.0),0.55,sig*0.25), SinOsc.kr(0.02).range(-0.25,0.25));

					});
				);


			});

		}
	{ num == 27 } {
		if ( val == 127, {


			~banjodrones.do{|i| i.play; };


		}, {

			~banjodrones.do{|i| i.stop; };

		});
	}
	{ num == 35 } {
		~banjodrones.do{|i| i.set(\ratio,~droneRatios[~ratioRange.map(val/127) ]); };
	}
	{ num == 3 } {
		~banjodrones.do{|i| i.set(\delmod,~deldecRange.map(val/127), \del, ~delRange.map(val/127); ); };
	}

}, nil, 1, \control, nil);


