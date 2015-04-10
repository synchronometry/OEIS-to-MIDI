#!/usr/bin/env python

"""
allows user to search OEIS database

syntax:(python3 oeis-search.py SEQUENCE_ID TEMPO
>python3 py-search.py A111555 120.0
>
>>A111555 ,1,3,16,116,1016,10176,113216,1375456,18047296,253815936,3805221376,
>>60558070016,1019617312256,18111737604096,338602832961536,6648048064792576,
>>136810876329865216,2945671077411987456,
>
"""

from pythonosc import osc_message_builder
from pythonosc import udp_client
from pythonosc import dispatcher
from pythonosc import osc_server

import re
import sys
import argparse
import time
import threading
import os


def init_chuck():
    # initialize chuck-side of code
    os.system("chuck oeis_init.ck")

init_thread = threading.Thread(target=init_chuck)
init_thread.start()
# give chuck code a moment to open, may execute too soon.
time.sleep(1)

# OEIS DATABASE ACCESS
oeis_database = open("oeisdb.txt", "r")
velocity_database = open("oeisdb.txt", "r")
noteLength_database = open("oeisdb.txt", "r")


# SET UP OSC CLIENT
parser = argparse.ArgumentParser()
parser.add_argument("--ip", default="127.0.0.1",
                    help="The ip of the OSC server")
parser.add_argument("--ClientPort", type=int, default=6449,
                    help="The port the OSC client is listening on")
parser.add_argument("--ServerPort", type=int, default=6450,
                    help="The port the OSC server is listening on")

args, unknown = parser.parse_known_args()
client = udp_client.UDPClient(args.ip, args.ClientPort)


tester = 0
# OSC Server
dispatcher = dispatcher.Dispatcher()
dispatcher.map("/tempo", print)
# dispatcher.map("/tempo", get_tempo_osc, print)
server = osc_server.ForkingOSCUDPServer((args.ip, args.ServerPort), dispatcher)
server_thread = threading.Thread(target=server.serve_forever)
server_thread.start()
print("Serving on {}".format(server.server_address))


def sendArgs(args):
    # send num of args to chuck
    # NOTE WILL BE OSC MESSAGE SENT
    print("send args (Py): ", args)
    argsMsg = osc_message_builder.OscMessageBuilder(address=("/numOfArgs"))
    argsMsg.add_arg(args)
    argsMsg = argsMsg.build()
    client.send(argsMsg)


try:
    # check command-line for four arguments
    if(sys.argv[4] is not 0):
        print("four args")
        argsCounter = 4
        sendArgs(argsCounter)

        sequenceOne = sys.argv[1]
        sequenceTwo = sys.argv[2]
        sequenceThree = sys.argv[3]
        tempo = float(sys.argv[4])
        print("TEMPO: ", tempo)

except IndexError:
    try:
        # check command-line for three arguments
        if(sys.argv[3] is not 0):
            print("three args")
            argsCounter = 3
            sendArgs(argsCounter)

            sequenceOne = sys.argv[1]
            sequenceTwo = sys.argv[2]
            tempo = float(sys.argv[3])
            print("TEMPO: ", tempo)

    except IndexError:
        try:
            # check command-line for two arguments
            if(sys.argv[2] is not 0):
                print("two arguments")
                argsCounter = 2
                sendArgs(argsCounter)

                sequenceOne = sys.argv[1]
                tempo = float(sys.argv[2])
                print("TEMPO: ", tempo)

        except IndexError:
            tempo = 120.0
            print("Please identify Integer Sequence ID: Axxxxxx")


if(tempo is not 0):
    SPB = 60.0 / tempo
    whole_note = (SPB*4)
else:
    SPB = 60.0 / 120
    whole_note = (SPB*4)


def loading():
    # turn off chucK loading message via OSC
    loadingMsg = osc_message_builder.OscMessageBuilder(
        address=("/loading"))

    # TIMING WILL BE OSC VALUE SENT
    loadingMsg.add_arg(1)
    loadingMsg = loadingMsg.build()
    print("Loading message sent via OSC")
    client.send(loadingMsg)

loading_thread = threading.Thread(target=loading)


def max_value(split):
    # send max value of integer sequence via OSC
    maxValueMsg = osc_message_builder.OscMessageBuilder(
        address=("/maxValue"))

    if(split > 2147483647):
        split = abs(int(split / 2147483647))

    maxValueMsg.add_arg(split)
    maxValueMsg = maxValueMsg.build()
    print("Max Value sent: ", split)
    client.send(maxValueMsg)


def one_sequence():
    for line in oeis_database:
        if re.match(sequenceOne, line):
            # removes algorithm name from search line
            sequence = line[9:-2]
            # splits return string to list
            rawSplit = sequence.split(',')
            mySplit = []

            # convert all items in list to abs value
            for i in range(len(rawSplit)):
                try:
                    print("ABS Before: ", rawSplit[i])
                    mySplit.append(abs(int(rawSplit[i])))
                    print("ABS After: ", mySplit[i])
                except:
                    mySplit.append(abs(rawSplit[i]))
                    print("Didn't Work: ", mySplit[i])

            # print(sequence)
            print(mySplit)
            # casts all list items to ints
            # mySplit = map(int, mySplit)
            # finds max value
            lenSplit = len(mySplit)
            minSplit = min(map(int, mySplit))
            maxSplit = max(map(int, mySplit))

            print("len: ", lenSplit)
            print("min: ", minSplit)
            print("max: ", maxSplit)

            # send max value of integer sequence via OSC
            if(argsCounter == 2):
                max_value(abs(maxSplit))

            loading_thread.start()

            for i in range(len(mySplit)):
                noteValue = abs((int(mySplit[i])/maxSplit) * 108.0)
                if(noteValue < 21):
                    newNote = (21 + int(noteValue))
                    noteValue = newNote
                    # print("new note: ", noteValue)
                    # NOTE WILL BE OSC MESSAGE SENT
                    msg = osc_message_builder.OscMessageBuilder(
                        address=("/sequenceOne"))
                    # TIMING WILL BE OSC VALUE SENT
                    msg.add_arg(int(noteValue))
                    msg = msg.build()
                    client.send(msg)
                    time.sleep(SPB)

oneSeq_thread = threading.Thread(target=one_sequence)


def two_sequence():
    for velocity_line in velocity_database:
        if re.match(sequenceTwo, velocity_line):
            # removes algorithm name from search line
            velocity_sequence = velocity_line[9:-2]
            # splits return string to list
            rawSplit = velocity_sequence.split(',')
            velocitySplit = []

            # convert all items in list to abs value
            for i in range(len(rawSplit)):
                try:
                    print("ABS Before: ", rawSplit[i])
                    velocitySplit.append(abs(int(rawSplit[i])))
                    print("ABS After: ", velocitySplit[i])
                except:
                    velocitySplit.append(abs(rawSplit[i]))
                    print("Didn't Work: ", velocitySplit[i])

            print(velocitySplit)
            # casts all list items to ints
            # mySplit = map(int, mySplit)
            # finds max value
            vel_lenSplit = len(velocitySplit)
            vel_minSplit = abs(min(map(int, velocitySplit)))
            vel_maxSplit = abs(max(map(int, velocitySplit)))

            print("velocity len: ", vel_lenSplit)
            print("velocity min: ", vel_minSplit)
            print("velocity max: ", vel_maxSplit)

            # send max value of integer sequence via OSC
            if(argsCounter == 3):
                max_value(abs(vel_maxSplit))

            for i in range(len(velocitySplit)):
                velocityValue = abs((
                    int(velocitySplit[i])/vel_maxSplit) * 127.0)
                if(velocityValue < 64):
                    newVelocity = (64 + int(velocityValue))
                    velocityValue = newVelocity
                    # print("new note: ", noteValue)
                    # NOTE WILL BE OSC MESSAGE SENT
                    vel_msg = osc_message_builder.OscMessageBuilder(
                        address=("/sequenceTwo"))
                    # TIMING WILL BE OSC VALUE SENT
                    print("Sending Velocity: ", int(velocityValue))
                    vel_msg.add_arg(int(velocityValue))
                    vel_msg = vel_msg.build()
                    client.send(vel_msg)
            time.sleep(2)
            oneSeq_thread.start()

twoSeq_thread = threading.Thread(target=two_sequence)


def three_sequence():
    for line in noteLength_database:
        if re.match(sequenceThree, line):
            # removes algorithm name from search line
            noteLength_sequence = line[9:-2]
            # splits return string to list
            rawSplit = noteLength_sequence.split(',')
            noteLengthSplit = []

            # convert all items in list to abs value
            for i in range(len(rawSplit)):
                try:
                    print("ABS Before: ", rawSplit[i])
                    noteLengthSplit.append(abs(int(rawSplit[i])))
                    print("ABS After: ", noteLengthSplit[i])
                except:
                    noteLengthSplit.append(abs(rawSplit[i]))
                    print("Didn't Work: ", noteLengthSplit[i])

            # print(sequence)
            print(noteLengthSplit)
            # casts all list items to ints
            # mySplit = map(int, mySplit)
            # finds max value
            noteLength_lenSplit = len(noteLengthSplit)
            noteLength_minSplit = abs(min(map(int, noteLengthSplit)))
            noteLength_maxSplit = abs(max(map(int, noteLengthSplit)))

            print("noteLength len: ", noteLength_lenSplit)
            print("noteLength min: ", noteLength_minSplit)
            print("noteLength max: ", noteLength_maxSplit)

            # send max value of integer sequence via OSC
            if(argsCounter == 4):
                max_value(abs(noteLength_maxSplit))

            for i in range(len(noteLengthSplit)):
                noteLengthValue = (
                    abs(int(noteLengthSplit[i])/noteLength_maxSplit) * 108.0)
                if(noteLengthValue < 21):
                    newNoteLength = (21 + int(noteLengthValue))
                    noteLengthValue = newNoteLength
                    # print("new note: ", noteValue)
                    # NOTE WILL BE OSC MESSAGE SENT
                    noteLength_msg = osc_message_builder.OscMessageBuilder(
                        address=("/sequenceThree"))
                    # TIMING WILL BE OSC VALUE SENT
                    print("Sending noteLength: ", int(noteLengthValue))
                    noteLength_msg.add_arg(int(noteLengthValue))
                    noteLength_msg = noteLength_msg.build()
                    client.send(noteLength_msg)
            time.sleep(2)
            two_sequence()
            # twoSeq_thread.start()

threeSeq_thread = threading.Thread(target=three_sequence)

# determine how many args were given
if(argsCounter == 2):
    oneSeq_thread.start()
elif(argsCounter == 3):
    twoSeq_thread.start()
elif(argsCounter == 4):
    threeSeq_thread.start()
