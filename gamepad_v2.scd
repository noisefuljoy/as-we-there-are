
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

SynthDef(\kick, {|out=0 amp=0.5 release=0.2 bufnum pan=0|
	var env, sig;
	env = EnvGen.ar(Env.perc(0.001, release),doneAction: 2);
	sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), 1, 0,0);
	Out.ar(out, Pan2.ar( sig*env*amp, pan)); }).add;

SynthDef(\field_rec, {|out=0 amp=1 gate=1 bufnum|
	var env, sig;
	env = EnvGen.ar(Env.adsr(1.0,0.1,0.5,3.0),gate,doneAction: 2);
	sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), 1, 0, 1);
	Out.ar(out, sig*env*amp); }).add;

SynthDef(\fm7, {|out=0 mod1=0, mod2=0, mod3=0, mod4=0 gate=1|
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
	sig = CombC.ar(sig, 0.1, LFNoise2.kr(1.8).range(0.01,0.1),SinOsc.kr(0.2).range(0.1,8.0),0.5,sig*0.5);
	//sig = FreeVerb2.ar(sig[0],sig[1], 0.4, 0.7,0.8);
	Out.ar(out, sig*env);
}).add;




~modRange = [0.001, 9, \exp, 0.001].asSpec;

~mainGroup = Group.new;
~fieldrecGroup = Group.new(~mainGroup);
~fmGroup = Group.new(~mainGroup);
~fm1Group = Group.new(~fmGroup);
~fm1Group = Group.new(~fmGroup);
~fm1Group = Group.new(~fmGroup);

~freezeSwitch = 0;
~fieldrecSwitch = 0;
~fieldrecnum = 0;

~field_rec_files = "field_recs/*.wav".pathMatch;
~field_recs = ~field_rec_files.collect({|sample| Buffer.read(s, sample); });

~field_recs.size

);
(

MIDIIn.connectAll;
/* nanoKontrol  */

MIDIdef.new(\test1, {|val num chan dev| [num, val].postln}, nil, 1, \control, nil);

/* nanoPad */

MIDIdef.new(\test2, {|val num chan dev| [num, val].postln}, nil, nil, \noteOn, nil);


//MIDIdef.freeAll;



/*    LOGITECH DUAL ACTION MAPPING */
/* main buttons */

/* synth trigger */
HIDdef.usage( \main_but_1, { |value|
	if ( ~freezeSwitch == 0, {
		if ( value == 1, {
			Synth(\fm7, [\gate,1], ~fm1Group); }, { ~fm1Group.set(\gate, 0); });
	});
	}, \b5 );

/* freeze button */
HIDdef.usage( \main_but_2, { |value|
	if ( value == 1, {
		if ( ~freezeSwitch == 0, { ~freezeSwitch = 1; "frozen".postln; }, { ~freezeSwitch = 0; "unfrozen".postln; });
	});
}, \b6 );

HIDdef.usage( \main_but_3, { |value|
	if ( value == 1, {
		if ( ~fieldrecSwitch == 0, { "play field rec".postln;
			Synth(\field_rec, [\gate,1,\bufnum,~field_recs[~fieldrecnum]], ~fieldrecGroup);
			~fieldrecSwitch = 1;
			if ( ~fieldrecnum == (~field_recs.size-1), { ~fieldrecnum = 0; }, { ~fieldrecnum = ~fieldrecnum + 1; });
		},
		{  "stop field rec".postln; ~fieldrecGroup.set(\gate, 0);  ~fieldrecSwitch = 0; });
	});
	 }, \b7 );


HIDdef.usage( \main_but_4, { |value|  value.postln; }, \b8 );


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

FM7

Ndef(\t,{

	var sig = VarSaw.ar(FSinOsc.kr(0.1).range(200,210),0,FSinOsc.kr(0.2).range(0.2,0.8),0.3);

	sig = sig!2;


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
            (
            var x= #[ [ [ 0.0, -0.33333333333333, -1.0, 0.0 ], [ 0.75, 0.75, 0.0, -0.5 ], [ -0.5, -0.25, 0.25, -0.75 ], [ -0.5, 1.0, 1.0, 1.0 ], [ 0.0, 0.16666666666667, -0.75, -1.0 ], [ 0.5, 0.5, -0.5, 0.33333333333333 ] ], [ [ -0.33333333333333, 0.5, -0.5, -0.5 ], [ 0.5, 0.75, 0.25, 0.75 ], [ -0.83333333333333, 0.25, -1.0, 0.5 ], [ 1.5, 0.25, 0.25, -0.25 ], [ -0.66666666666667, -0.66666666666667, -1.0, -0.5 ], [ -1.0, 0.0, -0.83333333333333, -0.33333333333333 ] ], [ [ 0.25, -0.5, -0.5, -1.0 ], [ -0.5, 1.0, -1.5, 0.0 ], [ -1.0, -1.5, -0.5, 0.0 ], [ 0.5, -1.0, 1.1666666666667, -0.5 ], [ 0.83333333333333, -0.75, -1.5, 0.5 ], [ 0.25, -1.0, 0.5, 1.0 ] ], [ [ 1.0, 0.33333333333333, 0.0, -0.75 ], [ -0.25, 0.0, 0.0, -0.5 ], [ -0.5, -0.5, 0.0, 0.5 ], [ 1.0, 0.75, 0.5, 0.5 ], [ 0.0, 1.5, -0.5, 0.0 ], [ 1.0, 0.0, -0.25, -0.5 ] ], [ [ 0.5, -0.25, 0.0, 0.33333333333333 ], [ 0.25, -0.75, 0.33333333333333, -1.0 ], [ -0.25, -0.5, 0.25, -1.1666666666667 ], [ 0.0, 0.25, 0.5, 0.16666666666667 ], [ -1.0, -0.5, 0.83333333333333, -0.5 ], [ 0.83333333333333, -0.75, -0.5, 0.0 ] ], [ [ 0.0, -0.75, -0.16666666666667, 0.0 ], [ 1.0, 0.5, 0.5, 0.0 ], [ -0.5, 0.0, -0.5, 0.0 ], [ -0.5, -0.16666666666667, 0.0, 0.5 ], [ -0.25, 0.16666666666667, -0.75, 0.25 ], [ -1.1666666666667, -1.3333333333333, -0.16666666666667, 1.5 ] ] ];
            var y= #[ [ [ 0.0, -0.5, 1.0, 0.0 ], [ -0.5, 1.0, 0.5, -0.5 ], [ 0.0, 0.33333333333333, 1.0, 1.0 ] ], [ [ -0.5, 0.5, 1.0, 1.0 ], [ 0.0, 0.33333333333333, 0.0, 1.5 ], [ -0.5, 0.83333333333333, 1.0, 0.0 ] ], [ [ 0.25, -0.66666666666667, 0.25, 0.0 ], [ 0.5, -0.5, -0.5, -0.5 ], [ 0.5, -0.5, -0.75, 0.83333333333333 ] ], [ [ -0.25, 1.0, 0.0, 0.33333333333333 ], [ -1.25, -0.25, 0.5, 0.0 ], [ 0.0, -1.25, -0.25, -0.5 ] ], [ [ 0.75, -0.25, 1.5, 0.0 ], [ 0.25, -1.5, 0.5, 0.5 ], [ -0.5, -0.5, -0.5, -0.25 ] ], [ [ 0.0, 0.5, -0.5, 0.25 ], [ 0.25, 0.5, -0.33333333333333, 0.0 ], [ 1.0, 0.5, -0.16666666666667, 0.5 ] ] ];
            {
                var ctls= x.collect{|a| a.collect{|b| SinOsc.ar(*b)}};
                var mods= y.collect{|a| a.collect{|b| Pulse.ar(*b)}};
                var chans= #[0, 1, 2, 4, 5];
                (FM7.ar(ctls, mods).slice(chans) * [1, 1, LFSaw.kr(0.1).range(0, -12.dbamp), 1, -3.dbamp]).clump(2).sum*0.5;
            }.play)
)






