var runnerFunc = {
    arg ampScaling = 1.0,
    stepper, 
    scaler = 1.0, 
    noTimeStretch = false,
    buffersLow, buffersHigh,
    currentBuffer, decayReverbSynth,
    decayReverbBus, bufLevelPan;

    var runner = Routine.new({
        loop{
            var speed, index, range, buffer, sleeptime, stretch, repeat;

						repeat = [true, false].wchoose([1,15].normalizeSum());
						stepper.repeat = repeat;

            if(repeat.not, {stepper.currentLevel = [0,1].wchoose([1,1].normalizeSum());}, {});

            stepper.next;
            speed = stepper.speed;
            stretch = if(noTimeStretch,{1}, {120.0.rand.clip(60, 120)}); //add to stepper (new function to calculate stretch...)

            index = stepper.currentStep;
            range = stepper.currentLevel;
            //should possibly be other way around? 0->low 1->high
            buffer = switch(range,
                0, {buffersHigh},
                1, {buffersLow}
            );

						Post << "Speed: " << speed << ", range: " << range << ", index: " << index << ", repeat: " << repeat << Char.nl;
						Post << "Buffer level panning: " << bufLevelPan << " and global: " << ~pan << Char.nl;

            if(noTimeStretch){
                currentBuffer = Synth.before(decayReverbSynth, \bufPlaySeparate, [\buf, buffer[index], \duration, buffer[index].duration, \rate, speed, \effectBus, decayReverbBus.index, \walk_incr, speed*(0.0001+0.001.rand)]);
            } { //else
                currentBuffer = Synth.before(decayReverbSynth, \timeStretch, [\rate, speed, \bufnum, buffer[index], \duration, buffer[index].duration, \mul, ampScaling, \stretch, stretch, \effectBus, decayReverbBus.index]);//TODO change stretch
            };

            sleeptime = (stretch*buffer[index].duration-0.05)/speed;
            sleeptime = scaler.linlin(0,1,1,sleeptime+5.0);
            //sleeptime = scaler.linlin(0,1,1,sleeptime);
            sleeptime.yield;

        }
    });

    runner;
};

runnerFunc;
