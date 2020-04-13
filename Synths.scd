//TODO - add arguments...
// - equal loudness... interpolation in 2d..
// - patch this through fx bus...
SynthDef.new(\modulatedNoise, {
    arg mul = 0.005, modRate = 0.005;
    var pink = PinkNoise.ar(), brown = BrownNoise.ar(), white = WhiteNoise.ar(), clip = ClipNoise.ar(mul: 0.5), gray = GrayNoise.ar();
    var left = XFade2.ar(XFade2.ar(pink, brown, SinOsc.kr(0.03, phase: 2pi.rand)), XFade2.ar(white, clip, SinOsc.kr(0.04, phase: 2pi.rand)), SinOsc.kr(0.05, phase: 2pi.rand, mul: 0.75));
    var right = XFade2.ar(XFade2.ar(white, brown, SinOsc.kr(0.09, phase: 2pi.rand)), XFade2.ar(pink, clip, SinOsc.kr(0.07, phase: 2pi.rand)), SinOsc.kr(0.01, phase: 2pi.rand, mul: 0.75));

    Out.ar(0, LFTri.kr(modRate).unipolar(mul)*[left,right]);
}).add;

SynthDef.new(\timeStretch, {
    arg bufnum = 0, duration = 30, stretch = 1, effectBus = 2, mul = 1, rate = 1, tailTime = 0.01;
    var sig = Warp1.ar(numChannels: 2,  bufnum: bufnum,  pointer: Line.kr(0, 1, duration*stretch/rate),  freqScale: BufRateScale.kr(bufnum)*rate*BrownianWalk.kr(0.0001),  windowSize: 0.8,  envbufnum: -1,  overlaps: 16,  windowRandRatio: 0.5,  interp: 4,  mul:  mul,  add: 0); 
    var env = EnvGen.ar(Env.new([0, 1, 1, 0], [0.1, (duration*stretch/rate)-0.1, 0.1], [-0.5, 0, 0.5]), doneAction: Done.freeSelf); //TODO: envelope hardcoded?
    var mixed = env*sig;
    Out.ar(effectBus, mixed);
}).add;

SynthDef.new(\bufPlaySeparate, {
    arg buf, rate = 1, duration = 1, outBus = 0, effectBus = 2;
    var sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf)*rate*BrownianWalk.kr(0.001)); 
    var env = EnvGen.ar(Env.new([0, 1, 1, 0], [0.1, (duration/rate)-0.1, 0.1], [-0.5, 0, 0.5]), doneAction: Done.freeSelf); //TODO: envelope hardcoded?
    var mixed = sig*env;
    Out.ar(effectBus, mixed);
}).add;

//Delay and reverb effect bus! (and pitch!)
//Dry wet ranges between -1 and 1
//TODO: Order of effects?
SynthDef.new(\delayReverbPitch, {
    arg inBus = 2, outBus = 0, delayTime = 0.2, rvDecay = 26.0, decayTime = 1.0, dryWetReverb = 0.15, dryWetDelay = -0.15, dryWetPitch = 0.0;
    var dry = In.ar(inBus, 2);

    var pitch = XFade2.ar(dry, PitchShift.ar(dry,  windowSize: 0.2, pitchRatio:0.5,  pitchDispersion: 0.0), dryWetPitch);
    var delay = XFade2.ar(pitch, CombC.ar(pitch, delaytime:delayTime*Line.kr(1.0,1.2,5), decaytime:decayTime, maxdelaytime:5), dryWetDelay);
    var reverb = XFade2.ar(delay, NHHall.ar(delay,  rt60: rvDecay,  stereo: 0.5,  lowFreq: 200,  lowRatio: 0.5,  hiFreq: 2000,  hiRatio: 0.3,  earlyDiffusion: 0.5,  lateDiffusion: 0.9,  modRate: 0.2,  modDepth: 0.3), dryWetReverb);

    Out.ar(outBus, reverb);
}).add;


