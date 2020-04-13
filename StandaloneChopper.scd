/**
Program for chopping up piano
TODO: 
- Remove unused samples...
- Icecast from home server
- control with some other data input?
- scenes... 
- change envelopes of buffers!
- form..
 - ≥ stretch : between 60 and 120
               between 1.8 and 6
               no stretch
**/

(
    //Server.default.addr = NetAddr("localhost", 58009); //non-standard port
    //Server.default.options.device = "scjack:supercollider";
    //Server.default.options.numInputBusChannels = 0;
    //"SC_JACK_DEFAULT_INPUTS".setenv();
    //"SC_JACK_DEFAULT_OUTPUTS".setenv("darkice-piano");

    Server.default.waitForBoot({
        var buffers_low, buffers_high;
        var stepper; 
        var scaler = 1.0, ampScaling = 1.0;
        var currentBuffer, decayReverbSynth, noTimeStretch = false;
        var noise, runner;
        var decayReverbBus = Bus.audio(s, 2);

        var helperFunctions, helperRoutines;

        // ====================  IMPORT ====================   
        helperFunctions = Require.new("Functions.scd"); //Helper functions
        helperRoutines = Require.new("Routines.scd"); //Routines
        Require.new("Synths.scd"); //Synth defs

        buffers_low = SoundFile.collectIntoBuffers(File.getcwd+/+"/samples/low/*");
        buffers_high = SoundFile.collectIntoBuffers(File.getcwd+/+"/samples/high/*");

        s.sync; //wait for buffers..

        buffers_low = helperFunctions[\sortArrayByDuration].value(buffers_low, true);
        buffers_high = helperFunctions[\sortArrayByDuration].value(buffers_high, true);

        stepper = StepCounter([buffers_high.size, buffers_low.size]);

        stepper.incrementor = {1+20.rand};//temporary testing variables
        stepper.currentLevel = 2.rand;//temporary testing variables
        stepper.currentLevel = [0,1].wchoose([1,1].normalizeSum());//temporary testing variables
        stepper.repeat = true;//temporary testing variables
        //stepper.speedProbability = Array.fill(6,{|i|(6-i)**8;}).normalizeSum();//temporary testing variables
        stepper.speedProbability = [1,0,0,0,0,0];
        scaler = 0.05;
        ampScaling = 0.1;

        decayReverbSynth = Synth.new(\delayReverbPitch, [\inBus, decayReverbBus.index]);
        noise = Synth.before(decayReverbSynth, \modulatedNoise, [\mul, 0.02]);

        helperRoutines.value(currentBuffer: currentBuffer, decayReverbSynth: decayReverbSynth, decayReverbBus: decayReverbBus, stepper: stepper, scaler: scaler, noTimeStretch: noTimeStretch, ampScaling: ampScaling, buffers_low: buffers_low, buffers_high: buffers_high).play;

        //runner.play;

    });
)

s.meter
s.queryAllNodes;
/**
* some old remainders...
* [1,2,3].normalizeSum()
* Array.fill(6,{1/6;}).plot; //even distribution
* Array.fill(6,{|i|(1/6)**(i/1);}).normalizeSum().plot; //even distribution
* Array.fill(6,{|i|(i+1);}).normalizeSum().plot;
* Array.fill(6,{|i|(6-i);}).normalizeSum().plot;
* (
    *     ~buf_high.do({
        *         |val,i|
        *         val.duration.postln;
        *     })
        * )
        **/

