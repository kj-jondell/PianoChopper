/**
Program for chopping up piano
TODO: - Play using Disklavier (later version)
- Osc communication between Live and Sc
- Control using Nanokontrol....
- Remove unused samples...
- Icecast from home server
- control with some other data input?
- restructure old ocde and cleaning
- Add FX? Delay..NHHall..
**/

(
    s.options.device = "Soundflower (64ch)";

    s.waitForBoot({
        var buffers_low, buffers_high;
        var stepper; //= StepCounter.new([1,1]);
        var scaler = 1.0;
        var currentBuffer, decayReverbSynth;
        var decayReverbBus = Bus.audio(s,2);

        var runner = Routine.new({
            loop{
                var speed, index, range, buffer, sleeptime;
                stepper.next;
                speed = stepper.speed;
                index = stepper.currentStep;
                range = stepper.currentLevel;
                //should possibly be other way around? 0->low 1->high
                buffer = switch(range,
                    0, {buffers_high},
                    1, {buffers_low}
                );
                currentBuffer = Synth.before(decayReverbSynth, \bufPlaySeparate, [\buf, buffer[index], \duration, buffer[index].duration, \rate, speed, \effectBus, decayReverbBus.index]);

                sleeptime = (buffer[index].duration-0.05)/speed;
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

        SynthDef.new(\bufPlaySeparate, {
            arg buf, rate = 1, duration = 1, outBus = 0, effectBus = 2;
            var sig = PlayBufCF.ar(2, buf, BufRateScale.kr(buf)*rate/*, doneAction: Done.freeSelf*/);
            var env = EnvGen.ar(Env.new([0,1,1,0], [0.1,(duration/rate)-0.1,0.1], [-0.5,0,0.5]), doneAction: Done.freeSelf); //TODO: envelope hardcoded?
            var mixed = sig*env;
            Out.ar(effectBus, mixed);
        }).add;

        //Delay and reverb effect bus!
        SynthDef.new(\delayReverb, {
           arg inBus = 2, outBus = 0, delayTime = 0.75, decayTime = 5.0, dryWetReverb = 0.5, dryWetDelay = 0.0;
            var dry = In.ar(inBus, 2);
            var delay = CombC.ar(dry, maxdelaytime: 5, delaytime: delayTime, decaytime: decayTime);
            var reverb = NHHall.ar(XFade2.ar(delay, dry, dryWetDelay),  rt60: decayTime,  stereo: 0.5,  lowFreq: 200,  lowRatio: 0.5,  hiFreq: 2000,  hiRatio: 0.3,  earlyDiffusion: 0.5,  lateDiffusion: 0.9,  modRate: 0.2,  modDepth: 0.3);
            Out.ar(outBus, XFade2.ar(dry, reverb, dryWetReverb));
        }).add;

        buffers_low = (SoundFile.collectIntoBuffers("/Users/kj/Documents/school/supercollider/projects/simple-radio/chopper/samples/low/*"));
        buffers_high = (SoundFile.collectIntoBuffers("/Users/kj/Documents/school/supercollider/projects/simple-radio/chopper/samples/high/*"));

        s.sync; //wait for buffers..

        buffers_low = sortArrayByDuration.value(buffers_low, true);
        buffers_high = sortArrayByDuration.value(buffers_high, true);

        stepper = StepCounter([buffers_high.size, buffers_low.size]);

        stepper.incrementor = {1+20.rand};//temporary testing variables
        stepper.currentLevel = 2.rand;//temporary testing variables
        stepper.currentLevel = [0,1].wchoose([1,1].normalizeSum());//temporary testing variables
        stepper.repeat = true;//temporary testing variables
        stepper.speedProbability = Array.fill(6,{|i|(6-i)**8;}).normalizeSum();//temporary testing variables

        decayReverbSynth = Synth.new(\delayReverb, [\inBus, decayReverbBus.index]);

        runner.play;

    });
)
s.queryAllNodes
//s.quit;//quit server
//0.exit;//quit sclang

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
