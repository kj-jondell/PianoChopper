var runnerFunc = {
    arg ampScaling = 1.0,
    stepper, 
    scaler = 1.0, 
    noTimeStretch = false,
    buffers_low, buffers_high,
    currentBuffer, decayReverbSynth,
    decayReverbBus;

    var runner = Routine.new({
        loop{
            var speed, index, range, buffer, sleeptime, stretch;

            stepper.next;
            speed = stepper.speed;
            stretch = if(noTimeStretch,{1}, {120.0.rand.clip(60, 120)}); //add to stepper (new function to calculate stretch...)
            index = stepper.currentStep;
            range = stepper.currentLevel;
            //should possibly be other way around? 0->low 1->high
            buffer = switch(range,
                0, {buffers_high},
                1, {buffers_low}
            );
            if(noTimeStretch){
                currentBuffer = Synth.before(decayReverbSynth, \bufPlaySeparate, [\buf, buffer[index], \duration, buffer[index].duration, \rate, speed, \effectBus, decayReverbBus.index]);
            } { //else
                currentBuffer = Synth.before(decayReverbSynth, \timeStretch, [\rate, speed, \bufnum, buffer[index], \duration, buffer[index].duration, \mul, ampScaling, \stretch, stretch, \effectBus, decayReverbBus.index]);//TODO change stretch
            };

            sleeptime = (stretch*buffer[index].duration-0.05)/speed;
            sleeptime = scaler.linlin(0,1,1,sleeptime);
            sleeptime.yield;

        }
    });

    runner;
};

runnerFunc;
