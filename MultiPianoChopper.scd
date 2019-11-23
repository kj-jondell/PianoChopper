/**
Program for chopping up piano
TODO: - Add sample breakpoints
- Vinyl hang-up in ableton
- Play using Disklavier (later version)
- Osc communication between Live and Sc
- Complete Pstepper
*/

s.reboot;
s.quit;
s.options.device = "Soundflower (64ch)"
s.options.device = "Built-In Output";
ServerOptions.outDevices;
s.meter

~buf_low = (SoundFile.collectIntoBuffers("/Users/kj/Documents/school/KMH/åk2/eam\ b/supercollider/samples/samples/low/*"));
~buf_high = (SoundFile.collectIntoBuffers("/Users/kj/Documents/school/KMH/åk2/eam\ b/supercollider/samples/samples/high/*"));

(
SynthDef.new(\bufPlaySeparate, {
    arg buf, rate = 1, duration = 1;
    var sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf)*rate, doneAction: Done.freeSelf);
    var env = EnvGen.ar(Env.new([0,1,1,0], [0.1,(duration/rate)-0.1,0.1], [-0.5,0,0.5]), doneAction: Done.freeSelf);
    Out.ar(0, sig*env);
}).add;
)

x = Synth.new(\bufPlaySeparate, [\buf, ~buf_high[0], \duration, ~buf_high[0].duration]);

b = StepCounter([~buf_high.size, ~buf_low.size]);

(
    b.next;
    [b.currentLevel,b.currentStep,b.speed]
)

b.incrementor = {1+4.rand}
b.currentLevel = 1
b.currentLevel = 2.rand;
b.currentStep = 0
b.lo_bound = 0.5

~scaler = 1;
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
        //2.yield; //VERY COOL EFFECT!!!! måste vara med i stycket!

        sleeptime = (buffer[index].duration-0.1)/speed;
        sleeptime = ~scaler.linlin(0,1,1,sleeptime);
        sleeptime.yield;

    }   
});
)

r.play;
r.stop;

s.boot
s.meter;
s.queryAllNodes
