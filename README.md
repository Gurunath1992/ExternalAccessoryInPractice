# ExternalAccessorySample
Sample project showing the use of Apple's ExternalAccessory framework for communication between iOS devices and its accessories

Make sure to change the name of the protocol that your gadget uses before running this code.
The protocol name has to be changed at two places:

1. Info.plist:
Change the value for the string at line number 65

2. ViewController.swift:
Change the value of the property "communicationProtocol" at line number 16
