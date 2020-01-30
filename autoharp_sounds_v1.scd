




Ndef(\autoharp, {
	var sig, wetsig;
	sig = SoundIn.ar(8);
	sig = Compander.ar(sig, sig, 0.1,1,1.0,0.001,0.1,1);
	wetsig = sig;

	5.do{|i| var del = (i+1)*0.1;
		wetsig = CombL.ar(wetsig,del, SinOsc.kr(del*0.01).range(0.01,del),i+1,0.75,wetsig*0.5);
	};
	sig = (sig * 0.6) + (wetsig * 0.4);

	sig = sig;

	sig = sig!2;


}).play;

5*0.1
	