/**
Program for chopping up piano
TODO: - Play using Disklavier (later version)
- Osc communication between Live and Sc
- Control using Nanokontrol....
- Remove unused samples...
*/

s.options.device = "Soundflower (64ch)";

s.waitForBoot({
    var buffers_low, buffers_high;
    var stepper; //= StepCounter.new([1,1]);
    
    //Sorting low and high buffers, outputing an array with longest first
    var sortArrayByDuration = {
        arg array;
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

        array = sorted_hi.reverse;//longest first
        array;
    };

    buffers_low = (SoundFile.collectIntoBuffers("/Users/kj/Documents/school/KMH/åk2/ht/eam\ b/supercollider/samples/samples/low/*"));
    buffers_high = (SoundFile.collectIntoBuffers("/Users/kj/Documents/school/KMH/åk2/ht/eam\ b/supercollider/samples/samples/high/*"));

    s.sync; //wait for buffers..

    sortArrayByDuration.value(buffers_low).postln;

    //s.quit;//quit server
    //0.exit;//quit sclang
});

/*
s.boot;
s.options.device = "Built-In Output";

(
    ~buf_low = (SoundFile.collectIntoBuffers("/Users/kj/Documents/school/KMH/åk2/ht/eam\ b/supercollider/samples/samples/low/*"));
    ~buf_high = (SoundFile.collectIntoBuffers("/Users/kj/Documents/school/KMH/åk2/ht/eam\ b/supercollider/samples/samples/high/*"));
)

(
    ~sortArrayByDuration = {
        arg array;
        var sorted_hi = List();

        array.do({
            arg buf, i; 
            if(sorted_hi.size == 0, {sorted_hi.add(buf);},
            {
                var inserted = false, index = 0;
                while({inserted == false}, {
                    if(buf.duration<sorted_hi[index].duration,
                    {sorted_hi = sorted_hi.insert(index,buf); 
                    inserted = true;} 
                );
                index = index + 1;
                if(index == sorted_hi.size, {
                    sorted_hi.add(buf);
                    inserted = true;
                });
            });
        }
    );
});

array = sorted_hi.reverse;
array;
}
    )

    ~buf_low = ~sortArrayByDuration.value(~buf_low)
    ~buf_high = ~sortArrayByDuration.value(~buf_high)
    ~buf_low.do({arg buf, i; buf.duration.postln;});
    ~buf_low.size
    ~buf_high.size

    (
        SynthDef.new(\bufPlaySeparate, {
            arg buf, rate = 1, duration = 1;
            var sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf)*rate, doneAction: Done.freeSelf);
            var env = EnvGen.ar(Env.new([0,1,1,0], [0.1,(duration/rate)-0.1,0.1], [-0.5,0,0.5]), doneAction: Done.freeSelf);
            Out.ar(0, sig*env);
        }).add;
    )

    b = StepCounter([~buf_high.size, ~buf_low.size]);

    (
        b.next;
        [b.currentLevel,b.currentStep,b.speed]
    )
    b.currentLevel = 1
    ~scaler = 1.1;
    ~scaler = 0.3;
    (
        ~probScale = 1000;
        b.speedProbability = Array.fill(6,{|i|(1/6)**(i/~probScale);}).normalizeSum(); 
    )
    b.speedProbability = Array.fill(6,{1/6}).normalizeSum(); 
    b.speedProbability = [0,0,0,0,0,1];
    b.speedProbability = [1,1,1,1,1,1].normalizeSum();
    (
        b.incrementor = {1+20.rand};
        b.currentLevel = 2.rand;
        b.currentLevel = [0,1].wchoose([1,1].normalizeSum());
        b.repeat = true;
        b.speedProbability = Array.fill(6,{|i|(6-i)**8;}).normalizeSum();
    )

    s.meter;
    r.play;
    r.stop;

    (
        r = Routine.new({
            loop{
                var speed, index, range, buffer, sleeptime;
                b.next;
                speed = b.speed;
                index = b.currentStep;
                range = b.currentLevel;
                buffer = switch(range,
                    0, {~buf_high},
                    1, {~buf_low}
                );
                x = Synth(\bufPlaySeparate, [\buf, buffer[index], \duration, buffer[index].duration, \rate, speed]);

                sleeptime = (buffer[index].duration-0.05)/speed;
                sleeptime = ~scaler.linlin(0,1,1,sleeptime);
                sleeptime.yield;

            }   
        });
    )

    r.stop;

    s.boot
    s.meter;
    s.queryAllNodes

    [1,2,3].normalizeSum()
    Array.fill(6,{1/6;}).plot; //even distribution
    Array.fill(6,{|i|(1/6)**(i/1);}).normalizeSum().plot; //even distribution
    Array.fill(6,{|i|(i+1);}).normalizeSum().plot;
    Array.fill(6,{|i|(6-i);}).normalizeSum().plot;

    (
        ~buf_high.do({
            |val,i|
            val.duration.postln;
        })
    )
    */
