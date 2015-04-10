# OEIS-to-MIDI
Transposes the OEIS database to MIDI Output.

OEIS to MIDI
(Online Encyclopedia of Integer Sequences)
LINK: http://www.oeis.org

This program allows the user to select up to three integer sequences from the OEIS, and an output tempo, 
and output MIDI to the local IAC Bus. localhost's IAC bus must be set up to work properly. 

    Example Syntax:
    $ python3 oeis-search.py A000010 A000056 A000100 120.0
  
  ONE SEQUENCE: MIDI Values
  TWO SEQUENCE: MIDI Velocity
  THREE SEQUENCE: MIDI Note length
  FOURTH VALUE: Tempo (Example 120.0)
    
-- Design Overview
OEIS-to-MIDI is a command-line application built to extract integer sequences from the OEIS database, 
using these integer sequences as means for musical content generation, as an approach to CAAC methodologies. 
The software is designed to be user-friendly, and as such, the following list provides an overview of the main 
software requirements:

* Support for input of up to three integer sequences (MIDI Note, Note Velocity, Note Length).
* Minimal programming required (integer sequence ID and tempo input needed only).
* MIDI Output via IAC Bus, for use with MIDI-Compatible DAWs.

-- System Overview
A user provides up to three integer sequences and tempo to the OEIS-to-MIDI program, and by default, 
MIDI is output through the user's IAC Bus as source material for a CAAC-based approach to the compositional process. 
Integer sequences are mapped to MIDI note, MIDI note length, and MIDI velocity.
