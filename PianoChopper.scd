/**
Program for chopping up piano
TODO: - Add sample breakpoints
- Re-record piano sample
*/

s.boot;
s.quit;
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
SynthDef.new(\bufPlay, {
    arg buf, rate, t_trig, lag = 0.05, start = 0, out = 0;
	var sig, envsig;
	sig = PlayBufCF.ar(1, buf, BufRateScale.kr(buf)*rate, t_trig, start, lag: lag); //PlayBufCF for crossfading when jumping in buffer
	Out.ar(out, sig!2);
}).add;
)

//TODO: stereo/multichannel fx, with different AM-freq per speaker!
(
SynthDef.new(\RingMod, {
    arg in = 3;
    var signal = In.ar(in, 1), mod_signal, out_signal;
    mod_signal = signal*[SinOsc.ar(70.midicps),SinOsc.ar(74.midicps),SinOsc.ar(77.midicps),SinOsc.ar(70.midicps),SinOsc.ar(74.midicps),SinOsc.ar(77.midicps),SinOsc.ar(70.midicps),SinOsc.ar(74.midicps),SinOsc.ar(77.midicps)]*0.5;
    out_signal = XFade2.ar(signal!2, mod_signal, SinOsc.kr(0.05), level: 1.0); //change modulation to parameter instead
    Out.ar(0, out_signal); 
}).add;
)

x = Synth.new(\bufPlay, [\buf, ~buf, \rate, 1, \out, 11]);
y = Synth.after(x, \RingMod, [\in, 11]);
//TODO: modify a? range lo-high increases with duration of song...
a = Pwhite.new(0.4,0.9,  length: inf).asStream;
b = Pstepper.new(size:(size(~breakpoints)-1), repeats: inf).asStream;
b.next;
b.reset;
a = Pgauss.new(mean: 1,  dev: 0.25,  length: inf).asStream;
a.next

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
b.postln;

r.play;
r.stop;

s.boot
s.meter;

b = Pstepper.new(length:5).asStream;
b.next
b.reset

