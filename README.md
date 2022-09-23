# ComPortDriver
Win32/64 VCL and Firemonkey COM-Port component for Delphi

This is a Unicode and further improved version of the CpDrv non-visible component for communicating via 
RS232 COM-Ports on Windows. The code is published under the Apache 2.0 license with the consent of its 
original author. Due to the use of $(AUTO) for the libsuffix it is compatible from D10.4.1 onwards only.
If you remove this setting in the package project option of both packages it should work with older 
versions as well. The code found in SerialPorts.pas is not working yet.

Changes in this V3.0 release compared with 2.1:

* fix non packet mode for higher baudrates: the old version didn't check if the buffer the received data 
  shall be written into is large enough. The new version calls the received event in a loop until all data
  has been received and signalled to avoid memory corruption
* the maximum buffer size has been increased from 8192 (8 kb) to 65536 byte (64 kb)
* SetCommBreak and ClearCommBreak functions for sending a break signal have been added
* EnumComPorts to get a list of available COM-ports has been added. This is a list of port names only, 
  without the description or friendly name.
* Properties for getting the minimum and maximum transmit and receive buffer sizes have been added
* The source code is XMLDOC commented now
* changed license to Apache 2.0

Installation:
Open BuildPackages from the package subdirectory. Compile the runtime package (the first one)
and then right click on the design time package and call the "Install" menu item in the popup menu.  
