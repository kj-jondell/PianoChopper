/**
Program for chopping up piano
TODO: - Play using Disklavier (later version)
- Osc communication between Live and Sc
- Control using Nanokontrol....
- Remove unused samples...
- Icecast from home server
- control with some other data input?
- restructure old ocde and cleaning
**/

s.options.device = "Soundflower (64ch)";

s.waitForBoot({
    var buffers_low, buffers_high;
    var stepper; //= StepCounter.new([1,1]);
    var scaler = 1.0;

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
            x = Synth(\bufPlaySeparate, [\buf, buffer[index], \duration, buffer[index].duration, \rate, speed]);

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
        arg buf, rate = 1, duration = 1;
        var sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf)*rate, doneAction: Done.freeSelf);
        var env = EnvGen.ar(Env.new([0,1,1,0], [0.1,(duration/rate)-0.1,0.1], [-0.5,0,0.5]), doneAction: Done.freeSelf); //TODO: envelope hardcoded?
        Out.ar(0, sig*env);
    }).add;

    buffers_low = (SoundFile.collectIntoBuffers("/Users/kj/Documents/school/KMH/åk2/ht/eam\ b/supercollider/samples/samples/low/*"));
    buffers_high = (SoundFile.collectIntoBuffers("/Users/kj/Documents/school/KMH/åk2/ht/eam\ b/supercollider/samples/samples/high/*"));

    s.sync; //wait for buffers..

    buffers_low = sortArrayByDuration.value(buffers_low, true);
    buffers_high = sortArrayByDuration.value(buffers_high, true);

    stepper = StepCounter([buffers_high.size, buffers_low.size]);

    stepper.incrementor = {1+20.rand};//temporary testing variables
    stepper.currentLevel = 2.rand;//temporary testing variables
    stepper.currentLevel = [0,1].wchoose([1,1].normalizeSum());//temporary testing variables
    stepper.repeat = true;//temporary testing variables
    stepper.speedProbability = Array.fill(6,{|i|(6-i)**8;}).normalizeSum();//temporary testing variables

    runner.play;

    //s.quit;//quit server
    //0.exit;//quit sclang
});

/**
*
* some old remainders...
*
* [1,2,3].normalizeSum()
* Array.fill(6,{1/6;}).plot; //even distribution
* Array.fill(6,{|i|(1/6)**(i/1);}).normalizeSum().plot; //even distribution
* Array.fill(6,{|i|(i+1);}).normalizeSum().plot;
* Array.fill(6,{|i|(6-i);}).normalizeSum().plot;
* 
* (
*     ~buf_high.do({
*         |val,i|
*         val.duration.postln;
*     })
* )
**/
