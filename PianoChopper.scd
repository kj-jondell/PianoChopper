/*
Program for chopping up piano
TODO: - Add sample breakpoints
- Re-record piano sample
*/

s.boot;

~buf = Buffer.read(s, "piano.wav");

(
SynthDef.new(\bufPlay, {|buf, rate, t_trig, lag = 0.1, start = 0|
	var sig, envsig;
	sig = PlayBufCF.ar(2, buf, BufRateScale.kr(buf)*rate, t_trig, start, lag: lag); //PlayBufCF for crossfading when jumping in buffer
	Out.ar(0,sig);
}).add;
)

x = Synth.new(\bufPlay, [\buf, ~buf, \rate, 1]);
a = Pwhite.new(0.25, 1,  length: inf).asStream;
a.next;
x.set(\rate, a.next, \start, 48000*(30.rand()+1), \t_trig, 1)
x.free;

(
r = Routine.new({
    loop{
        x.set(\rate, a.next, \start, 48000*(30.rand()+1), \t_trig, 1);
        2.yield;
    }   
});
)

r.play;
r.stop;

