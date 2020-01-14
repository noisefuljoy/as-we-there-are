



Ndef(\t,{

	var sig = VarSaw.ar(FSinOsc.kr(0.1).range(200,210),0,FSinOsc.kr(0.2).range(0.2,0.8),0.3);

	sig = sig!2;


}).play;



HID.findAvailable;