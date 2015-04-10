// receives number sequences and outputs as midi files to ableton
// 1. receive tempo
// 1. output sequence at tempo speed via midi to iac driver

// loading variables
int loadingCounter;
"Loading Sequence." => string loadingString;
"." => string loadingPeriodString;

// args variables
int numOfArgs;

// midi variables
0 => int midiNote;
0 => int midiCounter;

int velocity[0];
int velocity_temp;
0 => int velocityCounter;

int noteLength[0];
int noteLength_temp;
0 => int noteLengthCounter;

"None" => string noteLength_string;
int maxValue_int;
float maxValue_float;
float scaledMax;
float midiNote_float;
float scaledMidi;


// MIDI OUTPUT
MidiOut mout;
MidiMsg midiMsg;

int note;
1 => int port;

// check midi port
if(!mout.open(port)){<<< "ERROR: MIDI Port did not open on port: ", port >>>; me.exit();}

//BPM CLASS -- USE SCIKIT-LEARN TO FIND TEMPO AND SET AUTOMATICALLY
120.0 => float tempo_rate;
BPM temp;
temp.tempo(tempo_rate);

// send object
OscOut xmit;

// aim the transmitter
xmit.dest( "localhost", 6450 );

// create our OSC receiver
OscRecv oin;
OscRecv oin2;
// create our OSC message
OscMsg msg;
// use port 6449
9001 => oin.port;
oin.listen();

6449 => oin2.port;
oin2.listen();

oin.event( "/live/tempo, f" ) @=> OscEvent tempo_osc_in;
oin2.event( "/numOfArgs, i" ) @=> OscEvent argsOSC;
oin2.event( "/loading, i" ) @=> OscEvent loadingOSC;
oin2.event( "/maxValue, i" ) @=> OscEvent maxValue_in;
oin2.event( "/sequenceOne, i" ) @=> OscEvent sequenceOne_in;
oin2.event( "/sequenceTwo, i" ) @=> OscEvent sequenceTwo_in;
oin2.event( "/sequenceThree, i" ) @=> OscEvent sequenceThree_in;

// function for receiving incoming notes, and deciding number of arguments
fun void note_in_osc()
{
    while( true )
    {
	sequenceOne_in => now;
	if(numOfArgs == 2){ one_sequence(); }
	else if(numOfArgs == 3){ one_sequence(); }
	else if(numOfArgs == 4){ one_sequence(); }
    }
}
// function for sending tempo to ableton, as declared in command-line.
fun void send_tempo( float tempo )
{
    //send tempo as OSC message to Ableton Live
    xmit.start( "/tempo" );
    tempo => xmit.add;
    xmit.send();
    <<< "sent" >>>;
}
// function to receive tempo from command line.
fun void tempo_in()
{
    while ( true )
    {
	// wait for event to arrive
	tempo_osc_in => now;
	// send object
	OscOut xmitLive;

	//	grab the next message from the queue. 
	while ( tempo_osc_in.nextMsg() != 0 )
	{ 
	    // getFloat fetches the expected float (as indicated by "f")
	    tempo_osc_in.getFloat() => tempo_rate;
	    //print
	    temp.tempo(tempo_rate);
	    send_tempo(tempo_rate);
	    <<< "Tempo set: ",(tempo_rate $ int) >>>;
	}
    }
}
// function to clear loading screen
fun void loading()
{
    loadingOSC => now;
    <<< "load in (chuck)", "" >>>;
    1 => loadingCounter;
}
// function for receiving maxValue of incoming sequence
fun void max_value()
{
    maxValue_in => now;
    while( maxValue_in.nextMsg() != 0 ){ maxValue_in.getInt() => maxValue_int; }
}
// function to receive number of arguments from command-line.
fun void args_in()
{
    argsOSC => now;
    while( argsOSC.nextMsg() != 0 ){ argsOSC.getInt() => numOfArgs; }
    <<< "args in (chuck): ", numOfArgs >>>;
    
}
// function for receiving a single sequence argument 
fun void one_sequence()
{
    1 => loadingCounter;
    while( sequenceOne_in.nextMsg() != 0 )
    {
	144 => midiMsg.data1; //note on
	// select note to play
	sequenceOne_in.getInt() => midiNote => midiMsg.data2;

	// select velocity based on sequence
	if(velocity.size() > 1){
	    if(velocity[velocityCounter] < 128 && velocity[velocityCounter] >= 0)
	    { velocity[velocityCounter] => midiMsg.data3; }
	    else Math.random2(64, 127) @=> velocity[velocityCounter];
	    velocityCounter++;

	    if(velocityCounter > velocity.size()-1)
	    {
		0 @=> velocityCounter;
		// 0 @=> midiCounter;
	    }
	}
	else midiNote => midiMsg.data3;

	mout.send(midiMsg);
	
	// select note length based on sequence three
	if(noteLength.size() > 1)
	{
	    if(noteLength[noteLengthCounter] < 128
		&& noteLength[noteLengthCounter] >= 0)
	    { 
		maxValue_int $ float =>  maxValue_float;
		(maxValue_float/maxValue_float )=>  scaledMax;
		noteLength[noteLengthCounter] @=>  midiNote_float;
		((midiNote_float*maxValue_float)/108.0)/maxValue_float =>  scaledMidi;
	    }
	    else { Math.random2(64, 127) @=> noteLength[noteLengthCounter]; }
	    noteLengthCounter++;

	    if(noteLengthCounter > noteLength.size()-1)
	    {
		0 @=> noteLengthCounter;
	    }
	}
	else
	{
	maxValue_int $ float =>  maxValue_float;
	midiNote $ float =>  midiNote_float;
	(maxValue_float/maxValue_float) =>  scaledMax;
	((midiNote_float*maxValue_float)/108.0)/maxValue_float =>  scaledMidi;
	}

	// select noteLength_string based on sequence
	if(scaledMidi <= scaledMax && scaledMidi > ((scaledMax/6)*5))
	{ temp.wholeNote => now; "whole" => noteLength_string; }

	else if(scaledMidi <= ((scaledMax/6)*5) && scaledMidi > ((scaledMax/6)*4))
	{ temp.halfNote => now; "half" => noteLength_string;  }

	else if(scaledMidi <= ((scaledMax/6)*4) && scaledMidi > ((scaledMax/6)*3))
	{ temp.quarterNote => now; "quarter" => noteLength_string; }

	else if(scaledMidi <= ((scaledMax/6)*3) && scaledMidi > ((scaledMax/6)*2))
	{ temp.eighthNote => now;  "eighth" => noteLength_string; }

	else if(scaledMidi <= ((scaledMax/6)*2) && scaledMidi > ((scaledMax/6)*1))
	{ temp.sixteenthNote => now;  "sixteenth" => noteLength_string; }

	else if(scaledMidi <= ((scaledMax/6)*1))
	{ temp.thirtySecondNote => now;  "thirty-second" => noteLength_string; }

	128 => midiMsg.data1; //note off
	midiNote => midiMsg.data2;
	0 => midiMsg.data3;
	mout.send(midiMsg);

	midiCounter++;
	
	for(0=>int i; i < 99; i++) <<< "\n","" >>>;
	<<< "------- OEIS to MIDI v1.0 --------","" >>>;
	<<< "---- Written By: Bruce Dawson ----","" >>>;
	<<< "-------- February 2015 -----------","" >>>; 
	<<< "----------------------------------","" >>>;
	<<< "---- github.com/synchronometry ---","" >>>;
	<<< "---- www.synchronometry.com ------","" >>>;
	<<< "-------- OEIS: oeis.org ----------","" >>>;
	<<< "----------------------------------","" >>>;
	<<< "\n","" >>>;
	<<< "Iteration #", midiCounter >>>;
	<<< "Midi Out:", midiNote >>>;
	<<< "Note Length:", noteLength_string >>>;
	<<< "----------------------------------","" >>>;
	<<< "DEBUG - Args: ", numOfArgs >>>;
	<<< "DEBUG - scaledMax: ", scaledMax >>>;
	<<< "DEBUG - scaledMidi: ", scaledMidi >>>;	
	
	if(velocity.size() > 1)
	{
	<<< "DEBUG - Velocity Size: ", velocity.size() >>>;
	<<< "DEBUG - Velocity Out:", velocity[velocityCounter] >>>; 
	<<< "DEBUG - Velocity Counter:", velocityCounter >>>;
	<<< "----------------------------------","" >>>;
	}	

	if(noteLength.size() > 1)
	{
	<<< "DEBUG - noteLength Size: ", noteLength.size() >>>;
	<<< "DEBUG - noteLength Out:", noteLength[noteLengthCounter] >>>; 
	<<< "DEBUG - noteLength Counter:", noteLengthCounter >>>;
	<<< "----------------------------------","" >>>;
	}	

    }
}
// function for receiving two sequence arguments
fun void two_sequence()
{
    sequenceTwo_in => now;
    while( sequenceTwo_in.nextMsg() != 0 )
    {
	sequenceTwo_in.getInt() => velocity_temp;
	velocity << velocity_temp;
	<<< "Stored Velocity: ", velocity_temp >>>;
	<<< "Size of Velocity Array: ", velocity.size() >>>;
    }	
}

// function for receiving two sequence arguments
fun void three_sequence()
{
    sequenceThree_in => now;
    while( sequenceThree_in.nextMsg() != 0 )
    {
	sequenceThree_in.getInt() => noteLength_temp;
	noteLength << noteLength_temp;
	<<< "Stored Note Length: ", noteLength_temp >>>;
	// <<< "Size of Velocity Array: ", noteLength.size() >>>;
    }	
}


// functions for handling loading and outgoing sequences
spork ~ tempo_in();
spork ~ note_in_osc();
spork ~ loading();
spork ~ max_value();
spork ~ two_sequence();
spork ~ three_sequence();
spork ~ args_in();

// - functions for handling number of incoming sequences
// ~ one_sequence(); -- handles a single sequence and tempo
// ~ two_sequence(); -- handles two sequences and tempo
// ~ three_sequence(); -- handles three sequences and tempo

while( true ){
    while( loadingCounter != 1 ){
	for(0=>int i; i < 99; i++) <<< "\n","" >>>;
	/*
	<<< "------- OEIS to MIDI v1.0 --------","" >>>;
	<<< "---- Written By: Bruce Dawson ----","" >>>;
	<<< "-------- February 2015 -----------","" >>>; 
	<<< "----------------------------------","" >>>;
	<<< "---- github.com/synchronometry ---","" >>>;
	<<< "---- www.synchronometry.com ------","" >>>;
	<<< "-------- OEIS: oeis.org ----------","" >>>;
	<<< "----------------------------------","" >>>;
	<<< "\n","" >>>;
	*/

	<<< loadingPeriodString +=> loadingString, "" >>>;
	250::ms => now;
    }
    1::day => now;
}
