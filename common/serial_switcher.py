#!/usr/bin/env python

import serial
import sys

baudRate = 9600
neutralBaudRate = 14400
portName = "/dev/ttyACM0"

if len(sys.argv) > 1:
  baudRate = int(sys.argv[1])

if len(sys.argv) > 2:
  portName = sys.argv[2]

try:
  serial.Serial(portName, neutralBaudRate).close()
  serial.Serial(portName, baudRate).close()
except:
  print ("exception caught while opening serial port")
