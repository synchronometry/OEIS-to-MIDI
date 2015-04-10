//bpm class

public class BPM 
{
 
 //global variables
 dur myDuration[6];
 
 //
 static dur wholeNote, halfNote, quarterNote, eighthNote, sixteenthNote, thirtySecondNote;
 
 
 fun void tempo( float beat )
 {
  //beat is BPM
  
  //Seconds Per Beat
  60.0/ (beat) => float SPB;
  SPB::second => quarterNote;
  quarterNote*4.0 => wholeNote;
  quarterNote*2.0 => halfNote;
  quarterNote*0.5 => eighthNote;
  eighthNote*0.5 => sixteenthNote;
  sixteenthNote*0.5 => thirtySecondNote;
  
  [wholeNote, halfNote, quarterNote, eighthNote, sixteenthNote, thirtySecondNote] @=> myDuration;
     
 }
}
