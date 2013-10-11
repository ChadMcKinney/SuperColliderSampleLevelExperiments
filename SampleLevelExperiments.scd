// Let's write OSCillators by hand...yay!


// Here's a wrapper function for playback. SCLang doesn't have access to the sample level in Pseudo Ugens or similar because of block rate. Instead we do it with Signal, boooo.
(
~simpleSynth = { |freq, oscFunc, play = true, plot = false, length = 3|
	var sr = s.sampleRate;
	var data = Signal.fill(sr*length, {
		|i|
		oscFunc.value(freq, i, sr);
	});

	if(play, { data.play });
	if(plot, { data.plot });

	data;
};

// Simple Sine Wave, slooooowwww but accurate
~simpleSine = { |freq, i, sampleRate| sin(freq*2pi*(i/sampleRate)) };

// Crude saw
~simpleSaw = { |freq, i, sampleRate| (freq * 2 * i / sampleRate).wrap2(1) };

// Crude simple Tri
~simpleTri = { |freq, i, sampleRate|
	var val = ~simpleSaw.value(freq, i, sampleRate);
	if(val > 0, { 0 - (val * 2) + 1 }, { val * 2 + 1 });
};

~simpleNoise = { |freq, i, sampleRate|
	rrand(-1.0, 1.0);
};

~sampleSignal = { |path|
	var file = SoundFile.openRead(path);
	var sig = Signal.fill(file.numFrames, { 0 });
	file.readData(sig);
	file.close;
	sig;
};

// Very simple delay. Just copying contents and adding previous samples. Some high level functions could make this nicer looking.
// This is horribly slow.
(
~simpleDelay = { |input, delayTime, play = true, plot = false|
	var sr = s.sampleRate;
	var srDelay = delayTime * sr;
	var data = Signal.fill(input.size + srDelay, {
		|i|

		var val = 0;

		if(i - srDelay > 0, { val = val + input[i - srDelay] });
		if(i < input.size, { val = val + input[i] });
		val;
	});

	if(play, { data.play });
	if(plot, { data.plot });

	data;
}

);

~bitR = { |input, bitDepth, play = true, plot = true|
	var data = Signal.fill(input.size, {
		|i|
		input.at(i).trunc(0.5**bitDepth);
	});

	if(play, { data.play });
	if(plot, { data.plot });

	data;
};

~ring = { |input1, input2, play = true, plot = true|
	var data = Signal.fill(input1.size, {
		|i|
		input1.at(i).ring1(input2.at(i % input2.size)); // % is slow, we can come up with faster ways to do this but this is fine for a demo
	});

	if(play, { data.play });
	if(plot, { data.plot });

	data;
};

~bitor = { |input1, input2, play = true, plot = false|
	var data = Signal.fill(input1.size, {
		|i|
		input1.at(i).round.asInt.bitOr(input2.at(i % input2.size).round.asInt); // % is slow, we can come up with faster ways to do this but this is fine for a demo
	});

	if(play, { data.play });
	if(plot, { data.plot });

	data;
};

~bitxor = { |input1, input2, play = true, plot = false|
	var data = Signal.fill(input1.size, {
		|i|
		input1.at(i).round.asInt.bitXor(input2.at(i % input2.size).round.asInt); // % is slow, we can come up with faster ways to do this but this is fine for a demo
	});

	if(play, { data.play });
	if(plot, { data.plot });

	data;
};

~thresh = { |input1, input2, play = true, plot = false|
	var data = Signal.fill(input1.size, {
		|i|
		input1.at(i).thresh(input2.at(i % input2.size)); // % is slow, we can come up with faster ways to do this but this is fine for a demo
	});

	if(play, { data.play });
	if(plot, { data.plot });

	data;
};

~fold = { |input1, input2, play = true, plot = false|
	var data = Signal.fill(input1.size, {
		|i|
		input1.at(i).fold2(input2.at(i % input2.size)); // % is slow, we can come up with faster ways to do this but this is fine for a demo
	});

	if(play, { data.play });
	if(plot, { data.plot });

	data;
};

~wrap = { |input1, input2, play = true, plot = false|
	var data = Signal.fill(input1.size, {
		|i|
		input1.at(i).wrap2(input2.at(i % input2.size)); // % is slow, we can come up with faster ways to do this but this is fine for a demo
	});

	if(play, { data.play });
	if(plot, { data.plot });

	data;
};

~mAverage = { |input, asize, amp, play = true, plot = false|
	var subset = Array.fill(asize, { 0 });
	var data = Signal.fill(input.size, {
		|i|

		subset.removeAt(0);
		subset = subset.add(input.at(i));
		subset.mean * amp;
	});

	if(play, { data.play });
	if(plot, { data.plot });

	data;
};

~fir = { | input, coefficients, play = true, plot = false|
	var mem = Array.fill(coefficients.size, { 0 });
	var data = Signal.fill(input.size, {
		|i|
		mem.removeAt(mem.size - 1);
		mem.insert(0, input.at(i));
		coefficients.collect{ |item, i2| mem.at(i2) * item }.sum;
	});

	if(play, { data.play });
	if(plot, { data.plot });

	data;
};

~iir = { | input, coefficients1, coefficients2, play = true, plot = false|
	var inMem = Array.fill(coefficients1.size, { 0 });
	var outMem = Array.fill(coefficients2.size, { 0 });
	var data = Signal.fill(input.size, {
		|i|
		var output;
		inMem.removeAt(inMem.size - 1);
		inMem.insert(0, input.at(i));
		output = coefficients1.collect{ |item, i2| (inMem.at(i2) * item) }.sum;
		output = output + coefficients2.collect{ |item, i2| (outMem.at(i2) * item) }.sum;
		outMem.removeAt(outMem.size - 1);
		outMem.insert(0, output);
		output;
	});

	if(play, { data.play });
	if(plot, { data.plot });

	data;
};

~bandpass = { | input, frequency, r, play = true, plot = false|
	var outMem = Array.fill(2, { 0 });
	var data = Signal.fill(input.size, {
		|i|
		var phx = cos(2pi * (frequency / s.sampleRate));
		var a0 = (1-r) * sqrt(r*(r-4*phx+2)+1);
		var b1 = 2*r*phx;
		var b2 = r.pow(2) * -1;
		var output = (a0 * input.at(i)) + (b1 * outMem[0]) + (b2 * outMem[1]);
		outMem.removeAt(outMem.size - 1);
		outMem.insert(0, output);
		output;
	});

	if(play, { data.play });
	if(plot, { data.plot });

	data;
};

)

~simpleSynth.value(440, ~simpleSine).size.postln;
~simpleSynth.value(5, ~simpleSine, true, true, 1);

~simpleSynth.value(440, ~simpleSaw);
~simpleSynth.value(5, ~simpleSaw, true, true, 1);

~simpleSynth.value(440, ~simpleTri);
~simpleSynth.value(5, ~simpleTri, true, true, 1);

~simpleSynth.value(0, ~simpleNoise);

// Delayed impulses
~simpleDelay.value(~simpleSynth.value(5, ~simpleSaw, false, false), 1.25, true, true);

// Easier to hear the delay if we use a sample
~sample = ~sampleSignal.value("/home/octopian/Documents/source/SuperCollider/SuperColliderDev/SuperColliderSampleLevelExperiments/OfReptilesLeftEdit.wav");

// Takes forrrreevverrr to play back. Have patience young padawant.
~simpleDelay.value(~sample, 0.25, true, true);

// Crunchy
~bitR.value(~sample, 1);

// Spacey
~ring.value(~sample, ~simpleSynth.value(13, ~simpleSaw, false, false));

// Yerp, ring mod
~ring.value(~sample, ~simpleSynth.value(666, ~simpleSine, false, false));

// Yerp, ring mod
~ring.value(~sample, ~simpleSynth.value(666, ~simpleSine, false, false));

// !
~bitor.value(~sample, ~simpleSynth.value(6, ~simpleTri, false, false), true, true);

// ?!
~bitxor.value(~sample, ~simpleSynth.value(6, ~simpleSine, false, false), true, true);

// Thr3sh
~thresh.value(~sample, ~simpleSynth.value(6, ~simpleSine, false, false), true, true);

// fold is fun
~fold.value(~sample, ~simpleSynth.value(13, ~simpleSine, false, false), true, true);

// Wrapter
~wrap.value(~sample, ~simpleSynth.value(0.1, ~simpleTri, false, false), true, true);

// Mavericky maverage
~mAverage.value(~sample, 1000, 125, true, true);

// FIR
~fir.value(~sample, Array.fill(10, { rrand(-1.0, 1.0) }));
~fir.value(~simpleSynth.value(440, ~simpleSaw, false, false), Array.fill(10, { rrand(-0.4, 0.4) }));
~fir.value(~simpleSynth.value(0, ~simpleNoise, false, false), Array.fill(10, { rrand(-0.4, 0.4) }), true, true);

// IIR
~iir.value(~sample, Array.fill(rrand(1,10), { rrand(-1, 1) }), Array.fill(rrand(1,10), { rrand(-0.4, 0.4) }), true, true);
~iir.value(~simpleSynth.value(440, ~simpleSaw, false, false), Array.fill(rrand(1,10), { rrand(-0.4, 0.4) }), Array.fill(rrand(1,10), { rrand(-0.4, 0.4) }), true, true);
~iir.value(~simpleSynth.value(0, ~simpleNoise, false, false), Array.fill(rrand(1,10), { rrand(-0.4, 0.4) }), Array.fill(rrand(1,10), { rrand(-0.4, 0.4) }), true, true);

// Bandpass
~bandpass.value(~sample, 1300, 0.9, true, true);
~bandpass.value(~simpleSynth.value(440, ~simpleSaw, false, false), 1900, 0.99, true, true);
~bandpass.value(~simpleSynth.value(0, ~simpleNoise, false, false), 5000, 0.99, true, true);