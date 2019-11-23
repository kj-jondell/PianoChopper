/**
Program for chopping up piano
TODO: - Add sample breakpoints
- Vinyl hang-up in ableton
- Play using Disklavier (later version)
- Osc communication between Live and Sc
- Complete Pstepper
*/

s.boot;
s.quit;
s.options.device = "Soundflower (64ch)"

~buf_low = (SoundFile.collectIntoBuffers("/Users/kj/Documents/school/KMH/åk2/eam\ b/supercollider/samples/samples/low/*"));
~buf_high = (SoundFile.collectIntoBuffers("/Users/kj/Documents/school/KMH/åk2/eam\ b/supercollider/samples/samples/high/*"));

(
SynthDef.new(\bufPlay, {
    arg buf, rate, t_trig, start = 0, out = 0;
	var sig;
	sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf)*rate, t_trig, start); 
	Out.ar(out, sig);
}).add;
)

x = Synth.new(\bufPlay, [\buf, ~buf_high, \rate, 1, \out, 0]);
x.set(\buf, ~buf_high[15.rand], \t_trig, 1)
b = StepCounter([~buf_high.size, ~buf_low.size]);
(
    b.next;
    [b.currentLevel,b.currentStep,b.speed]
)
b.incrementor = {1+4.rand}
b.currentLevel = 1
b.currentLevel = 0;
b.currentStep = 0
b.lo_bound = 0.5
[0.79,0.91, 1.02].choose

(
r = Routine.new({
    loop{
        var speed, index, range, buffer;
        b.next;
        speed = b.speed;
        index = b.currentStep;
        range = b.currentLevel;
        buffer = switch(range,
            0, {~buf_high},
            1, {~buf_low}
        );
        x.set(\buf, buffer[index], \rate, speed, \start, 0, \t_trig, 1);
        ((buffer[index].duration)/speed).yield;
    }   
});
)

r.play;
r.stop;

s.boot
s.meter;

(
    ~buf_high.do({
        arg val, i;
        val.duration.postln;
    });
)

Lag
