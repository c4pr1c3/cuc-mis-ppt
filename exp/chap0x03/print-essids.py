#!/usr/bin/env python

import os
import sys
from scapy.all import Dot11Elt, rdpcap


pcap = sys.argv[1]

if not os.path.isfile(pcap):
    print('input file does not exist')
    exit(1)

pkts = rdpcap(pcap)

i = 0
output = {}

print("{:5} {:18} {:18} {:18}".format("No.", "SA", "Type", "ESSID"))
for pkt in pkts:
    i += 1
    if not pkt.haslayer(Dot11Elt) or pkt.info.decode('utf8').strip('\x00') == '':
        continue
    if pkt.subtype == 0:  # Association Req
        output["{:18} {:18} {:18}".format(pkt.addr2, "Assoc Req", pkt.info.decode('utf8'))] = "{:5} {:18} {:18} {:18}".format(i, pkt.addr2, "Assoc Req", pkt.info.decode('utf8'))
    if pkt.subtype == 4:  # Probe Req
        output["{:18} {:18} {:18}".format(pkt.addr2, "Probe Req", pkt.info.decode('utf8'))] = "{:5} {:18} {:18} {:18}".format(i, pkt.addr2, "Probe Req", pkt.info.decode('utf8'))
    if pkt.subtype == 5:  # Probe Resp
        output["{:18} {:18} {:18}".format(pkt.addr2, "Probe Resp", pkt.info.decode('utf8'))] = "{:5} {:18} {:18} {:18}".format(i, pkt.addr2, "Probe Rep", pkt.info.decode('utf8'))
    if pkt.subtype == 8:  # Beacon Frame
        output["{:18} {:18} {:18}".format(pkt.addr2, "Beacon", pkt.info.decode('utf8'))] = "{:5} {:18} {:18} {:18}".format(i, pkt.addr2, "Beacon", pkt.info.decode('utf8'))

for key in output.keys():
    print(output[key])
