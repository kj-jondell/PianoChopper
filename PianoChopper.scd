/*
Program for chopping up piano
TODO: - Add sample breakpoints
- Re-record piano sample
*/

s.reboot;
s.options.device = "Soundflower (64ch)"

~breakpoints = [0,70716, 148109, 334383, 522706, 729012, 839790, 1021891, 1226148, 1456809, 1891424] ; //slightly off as i modified sample
(size(~breakpoints)-1).rand()


~buf = Buffer.read(s, "piano.wav");
~buf = Buffer.read(s, "piano2.wav");
~buf = Buffer.read(s, "piano3.wav");

(
SynthDef.new(\bufPlay, {|buf, rate, t_trig, lag = 0.05, start = 0|
	var sig, envsig;
	sig = PlayBufCF.ar(1, buf, BufRateScale.kr(buf)*rate, t_trig, start, lag: lag); //PlayBufCF for crossfading when jumping in buffer
	Out.ar(0,sig!2);
}).add;
)

//TODO: add ringmodulation with xfade
(
SynthDef.new(\RingMod, {


}).add;
)

x = Synth.new(\bufPlay, [\buf, ~buf, \rate, 1]);
//TODO: modify a? range lo-high increases with duration of song...
a = Pwhite.new(0.35, 0.8,  length: inf).asStream;
a.next;
x.set(\rate, a.next, \start, 48000*(30.rand()+1), \t_trig, 1)
x.free;

(
r = Routine.new({
    loop{
        var dur, index = (size(~breakpoints)-1).rand(), speed;
        speed = a.next;
        dur = (1/speed)*(~breakpoints[index+1] - ~breakpoints[index])/48000;
        x.set(\rate, speed, \start, ~breakpoints[index], \t_trig, 1);
        dur.yield;
    }   
});
)

r.play;
r.stop;

s.meter;
