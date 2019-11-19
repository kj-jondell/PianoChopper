/**
Program for chopping up piano
TODO: - Add sample breakpoints
- Waltz change speed (but no jump), through Soundflower (OR vinyl hang-up in ableton)
- Play using Disklavier (later version)
*/


s.reboot;
s.quit;
s.options.device = "Soundflower (64ch)"
//EQ on piano samples...???
~buf2 = Buffer.read(s, "samples/piano9.wav");

(
    ~buf = Buffer.read(s, "samples/piano8.wav");
    ~breakpoints = [0,338154,587473, 1102151,1375474,1785763,2177647,2510000,2731168, 3134488,3405530,3572824]
//    ~breakpoints = [0,338154,587473, 1102323,1373365,1785763,2177412,2512000,2731168, 3134488,3405530,3572824];
    //~breakpoints = [327635,440035,617005,786802,988883,1375109,2152345,2448890,2798048];
)

(
SynthDef.new(\bufPlay, {
    arg buf, rate, t_trig, lag = 0.05, start = 0, out = 0;
	var sig, envsig;
	sig = PlayBufCF.ar(2, buf, BufRateScale.kr(buf)*rate, t_trig, start, lag: lag); //PlayBufCF for crossfading when jumping in buffer
	Out.ar(out, sig);
}).add;
)

//TODO: stereo/multichannel fx, with different AM-freq per speaker!
/*(
SynthDef.new(\RingMod, {
    arg in = 3;
    var signal = In.ar(in, 1), mod_signal, out_signal;
    mod_signal = signal*[SinOsc.ar(70.midicps),SinOsc.ar(74.midicps),SinOsc.ar(77.midicps),SinOsc.ar(70.midicps),SinOsc.ar(74.midicps),SinOsc.ar(77.midicps),SinOsc.ar(70.midicps),SinOsc.ar(74.midicps),SinOsc.ar(77.midicps)]*0.5;
    out_signal = XFade2.ar(signal!2, mod_signal, SinOsc.kr(0.05), level: 1.0); //change modulation to parameter instead
    Out.ar(0, In.ar(in, 2)); 
}).add;
)*/

x = Synth.new(\bufPlay, [\buf, ~buf, \rate, 1, \out, 0]);
y = Synth.new(\bufPlay, [\buf, ~buf2, \rate, 1, \out, 2]);
//TODO: modify a? range lo-high increases with duration of song...
//a = Pwhite.new(0.5,1.1,inf).asStream;
//a = Pbrown.new(0.5,1.1,0.05,length: inf).asStream;
a = Pwrand.new([0.79,1,0.62,1.59,1.27], [0.2,0.3,0.2,0.1,0.2], inf).asStream;//discrete steps (key change!!)
//b = Pstepper.new(size:(size(~breakpoints)-1), repeats: inf).asStream;
b = Prand.new([0,1,2,3,4,5,6,7,8,9,10], inf).asStream;

(
r = Routine.new({
    loop{
        var dur, speed, index;
        speed = a.next;
        index = b.next ? (size(~breakpoints)-2);
        dur = (1/speed)*(~breakpoints[index+1] - ~breakpoints[index])/48000;
        x.set(\buf, ~buf, \rate, speed, \start, ~breakpoints[index], \t_trig, 1);
        //y.set(\rate, speed);
        dur.yield;
    }   
});
)

r.play;
r.stop;

s.boot
s.meter;

