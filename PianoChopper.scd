/**
Program for chopping up piano
TODO: - Add sample breakpoints
- Re-record piano sample
*/

s.boot;
s.options.device = "Soundflower (64ch)"

(size(~breakpoints)-1).rand()

//EQ on piano samples...???
~buf = Buffer.read(s, "samples/piano.wav");
~buf = Buffer.read(s, "samples/piano4.wav");
~buf = Buffer.read(s, "samples/piano5.wav");

(
    ~buf = Buffer.read(s, "samples/piano2.wav");
    ~breakpoints = [48000*1.5, 48000*3]; //placeholder values
)

(
    ~buf = Buffer.read(s, "samples/piano3.wav");
    ~breakpoints = [0,70716, 148109, 334383, 522706, 729012, 839790, 1021891, 1226148, 1456809, 1891424] ; //slightly off as i modified sample
)

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
a = Pgauss.new(mean: 1,  dev: 0.25,  length: inf).asStream;
a.next
x.set(\rate, a.next, \start, 48000*(30.rand()+1), \t_trig, 1)
x.free;

(
r = Routine.new({
    loop{
        var dur, index = (size(~breakpoints)-1).rand(), speed;
        speed = a.next;
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

b = PStepper.new([1,2,3,4], 5).asStream;
b.next

