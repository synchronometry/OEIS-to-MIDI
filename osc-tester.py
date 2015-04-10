from pythonosc import osc_message_builder
from pythonosc import udp_client
# from pythonosc import dispatcher
# from pythonosc import osc_server

import argparse

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

argsMsg = osc_message_builder.OscMessageBuilder(address=("/sndbuf/buf/rate"))
argsMsg.add_arg(5.0)
argsMsg.add_arg(10.0)
argsMsg = argsMsg.build()
client.send(argsMsg)
print("does this happen?")
