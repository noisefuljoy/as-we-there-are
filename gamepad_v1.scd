



HID.findAvailable;
HID.postAvailable;

~myhid = HID.open( 1133, 49686 );

s.boot;

Ndef( \sinewave, { |freq=500, amp=0.1| SinOsc.ar( freq, 0, amp * 0.2 ) } );
Ndef( \sinewave ).play;



Ndef(\t,{

	var sig = VarSaw.ar(FSinOsc.kr(0.1).range(200,210),0,FSinOsc.kr(0.2).range(0.2,0.8),0.3);

	sig = sig!2;


}).play;


~freqRange = [500, 5000, \exponential].asSpec; // create a frequency range

HIDdef.usage( \freq, { |value| Ndef( \sinewave ).set( \freq, ~freqRange.map( value ) ); }, \X );
HIDdef.usage( \amp, { |value| Ndef( \sinewave ).set( \amp, value ); }, \Y );


Ndef( \sinewave ).free;