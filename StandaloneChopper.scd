/**
Program for chopping up piano
TODO: - Play using Disklavier (later version)
- Osc communication between Live and Sc
- Control using Nanokontrol....
- Remove unused samples...
- Icecast from home server
- control with some other data input?
- restructure old code and cleaning
- Add FX? Delay..NHHall..
- scenes... time stretch (WarpZ or something...) 
- form..
**/

(
    //Server.default.addr = NetAddr("localhost", 58009); //non-standard port
    //Server.default.options.device = "scjack:supercollider";
    //Server.default.options.numInputBusChannels = 0;
    //"SC_JACK_DEFAULT_INPUTS".setenv();
    //"SC_JACK_DEFAULT_OUTPUTS".setenv("darkice-piano");

    Server.default.waitForBoot({
        var buffers_low, buffers_high;
        var stepper; 
        var scaler = 1.0;
        var currentBuffer, decayReverbSynth, noTimeStrech = false;
        var noise;
        var decayReverbBus = Bus.audio(s, 2);

        var runner = Routine.new({
            loop{
                var speed, index, range, buffer, sleeptime, stretch;
                stepper.next;
                speed = stepper.speed;
                stretch = if(noTimeStrech,{1}, {6.0.rand.clip(1.8,6)}); //add to stepper (new function to calculate stretch...)
                index = stepper.currentStep;
                range = stepper.currentLevel;
                //should possibly be other way around? 0->low 1->high
                buffer = switch(range,
                    0, {buffers_high},
                    1, {buffers_low}
                );
                if(noTimeStrech){
                    currentBuffer = Synth.before(decayReverbSynth, \bufPlaySeparate, [\buf, buffer[index], \duration, buffer[index].duration, \rate, speed, \effectBus, decayReverbBus.index]);
                } { //else
                    currentBuffer = Synth.before(decayReverbSynth, \timeStretch, [\rate, speed, \bufnum, buffer[index], \duration, buffer[index].duration, \stretch, stretch, \effectBus, decayReverbBus.index]);//TODO change stretch
                };

                sleeptime = (stretch*buffer[index].duration-0.05)/speed;
                sleeptime = scaler.linlin(0,1,1,sleeptime);
                sleeptime.yield;

            }
        });

        //Sorting low and high buffers, outputing an array with longest first 
        var sortArrayByDuration = {
            arg array, longest_first = true;
            var sorted_hi = List();

            array.do({
                arg buf, i; 
                if(sorted_hi.size == 0, {sorted_hi.add(buf);},
                {
                    var inserted = false, index = 0;
                    while({inserted == false})
                    {
                        if(buf.duration<sorted_hi[index].duration)
                        {
                            sorted_hi = sorted_hi.insert(index,buf); 
                            inserted = true;
                        }; 
                        index = index + 1;
                        if(index == sorted_hi.size)
                        {
                            sorted_hi.add(buf);
                            inserted = true;
                        };
                    }
                });
            });

            if(longest_first)
            {
                array = sorted_hi.reverse;//longest first
            };
            array;
        };

        //TODO - add arguments...
        // - equal loudness... interpolation in 2d..
        // - patch this through fx bus...
        SynthDef.new(\modulatedNoise, {
            arg mul = 0.005, modRate = 0.005;
            var pink = PinkNoise.ar(), brown = BrownNoise.ar(), white = WhiteNoise.ar(), clip = ClipNoise.ar(mul:0.5), gray = GrayNoise.ar();
            var left = XFade2.ar(XFade2.ar(pink, brown, SinOsc.kr(0.03, phase:2pi.rand)), XFade2.ar(white, clip, SinOsc.kr(0.04, phase:2pi.rand)), SinOsc.kr(0.05, phase:2pi.rand, mul:0.75));
            var right = XFade2.ar(XFade2.ar(white, brown, SinOsc.kr(0.09, phase:2pi.rand)), XFade2.ar(pink, clip, SinOsc.kr(0.07, phase:2pi.rand)), SinOsc.kr(0.01, phase:2pi.rand, mul:0.75));
            //left = XFade2.ar(left, CombC.ar(left, maxdelaytime:3, decaytime:1));
            //right = XFade2.ar(right, CombC.ar(right, decaytime:1, maxdelaytime:3));
            Out.ar(0, LFTri.kr(modRate).unipolar(mul)*[left,right]);
        }).add;

        SynthDef.new(\timeStretch, {
            arg bufnum = 0, duration = 30, stretch = 1, effectBus = 2, mul = 1, rate = 1, tailTime = 0.01;
            var sig = Warp1.ar(numChannels: 2,  bufnum: bufnum,  pointer: Line.kr(0, 1, duration*stretch/rate),  freqScale: rate,  windowSize: 0.8,  envbufnum: -1,  overlaps: 16,  windowRandRatio: 0.5,  interp: 4,  mul: mul,  add: 0); //freeSelf in Line.kr instead of DetectSilence...
            var env = EnvGen.ar(Env.new([0, 1, 1, 0], [0.1, (duration*stretch/rate)-0.1, 0.1], [-0.5, 0, 0.5]), doneAction: Done.freeSelf); //TODO: envelope hardcoded?
            var mixed = env*sig;
            Out.ar(effectBus, mixed);
        }).add;

        SynthDef.new(\bufPlaySeparate, {
            arg buf, rate = 1, duration = 1, outBus = 0, effectBus = 2;
            var sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf)*rate*BrownianWalk.kr(0.001)); //PlayBufCF!!! TODO install this...
            var env = EnvGen.ar(Env.new([0, 1, 1, 0], [0.1, (duration/rate)-0.1, 0.1], [-0.5, 0, 0.5]), doneAction: Done.freeSelf); //TODO: envelope hardcoded?
            var mixed = sig*env;
            Out.ar(effectBus, mixed);
        }).add;

        //Delay and reverb effect bus! (and pitch!)
        //Dry wet ranges between -1 and 1
        //TODO: Order of effects?
        SynthDef.new(\delayReverbPitch, {
            arg inBus = 2, outBus = 0, delayTime = 0.2, rvDecay = 2.0, decayTime = 1.0, dryWetReverb = -0.15, dryWetDelay = -0.15, dryWetPitch = 0.0;
            var dry = In.ar(inBus, 2);
            var delay = XFade2.ar(dry, CombC.ar(dry, delaytime:delayTime*Line.kr(1.0,1.2,5), decaytime:decayTime, maxdelaytime:5), dryWetDelay);
            var reverb = XFade2.ar(delay, NHHall.ar(delay,  rt60: rvDecay,  stereo: 0.5,  lowFreq: 200,  lowRatio: 0.5,  hiFreq: 2000,  hiRatio: 0.3,  earlyDiffusion: 0.5,  lateDiffusion: 0.9,  modRate: 0.2,  modDepth: 0.3), dryWetReverb);
            var pitch = XFade2.ar(reverb, PitchShift.ar(reverb,  windowSize: 0.2, pitchRatio:0.25,  pitchDispersion: 0.0), dryWetPitch);
            Out.ar(outBus, pitch);
        }).add;

        buffers_low = SoundFile.collectIntoBuffers(File.getcwd+/+"/samples/low/*");
        buffers_high = SoundFile.collectIntoBuffers(File.getcwd+/+"/samples/high/*");

        s.sync; //wait for buffers..

        buffers_low = sortArrayByDuration.value(buffers_low, true);
        buffers_high = sortArrayByDuration.value(buffers_high, true);

        stepper = StepCounter([buffers_high.size, buffers_low.size]);

        stepper.incrementor = {1+20.rand};//temporary testing variables
        stepper.currentLevel = 2.rand;//temporary testing variables
        stepper.currentLevel = [0,1].wchoose([1,1].normalizeSum());//temporary testing variables
        stepper.repeat = true;//temporary testing variables
        stepper.speedProbability = Array.fill(6,{|i|(6-i)**8;}).normalizeSum();//temporary testing variables
        scaler = 0.7;

        decayReverbSynth = Synth.new(\delayReverbPitch, [\inBus, decayReverbBus.index]);
        noise = Synth.before(decayReverbSynth, \modulatedNoise, [\mul, 0.02]);

        runner.play;

    });
)

s.queryAllNodes;
/**
* some old remainders...
* [1,2,3].normalizeSum()
* Array.fill(6,{1/6;}).plot; //even distribution
* Array.fill(6,{|i|(1/6)**(i/1);}).normalizeSum().plot; //even distribution
* Array.fill(6,{|i|(i+1);}).normalizeSum().plot;
* Array.fill(6,{|i|(6-i);}).normalizeSum().plot;
* (
    *     ~buf_high.do({
        *         |val,i|
        *         val.duration.postln;
        *     })
        * )
        **/

