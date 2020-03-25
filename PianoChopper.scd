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

ajijijifjia
(
    ~buf = Buffer.read(s, "samples/piano8.wav");
    ~breakpoints = [0,338154,587473, 1102151,1375474,1785763,2177647,2510000,2731168, 3134488,3405530,3572824]
)

(
SynthDef.new(\bufPlay, {
    arg buf, rate, t_trig, lag = 0.01, start = 0, out = 0;
	var sig, envsig;
	sig = PlayBufCF.ar(2, buf, BufRateScale.kr(buf)*rate, t_trig, start, lag: lag); //PlayBufCF for crossfading when jumping in buffer
	Out.ar(out, sig);
}).add;
)

x = Synth.new(\bufPlay, [\buf, ~buf, \rate, 1, \out, 0]);
y = Synth.new(\bufPlay, [\buf, ~buf2, \rate, 1, \out, 2]);
//TODO: modify a? range lo-high increases with duration of song...
//a = Pwhite.new(0.5,1.1,inf).asStream;
//a = Pbrown.new(0.5,1.1,0.05,length: inf).asStream;
a = Pwrand.new([0.79,1,0.62,1.27]/1.27+0.1, [0.2,0.5,0.1,0.2], inf).asStream;//discrete steps (key change!!)
b = Pstepper.new(size:(size(~breakpoints)-1), repeats: inf).asStream;
//b = Prand.new([0,1,2,3,4,5,6,7,8,9,10], inf).asStream;

(
r = Routine.new({
    loop{
        var dur, speed, index;
        speed = a.next;
        index = b.next ? (size(~breakpoints)-2);
        dur = (1/speed)*(~breakpoints[index+1] - ~breakpoints[index])/48000;
        x.set(\buf, ~buf, \rate, speed, \start, ~breakpoints[index], \t_trig, 1);
        dur.yield;
    }   
});
)

r.play;
r.stop;

s.boot
s.meter;

