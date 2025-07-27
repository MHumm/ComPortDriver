# ComPortDriver



Win32/64 VCL and Firemonkey COM-Port component for Delphi
Designed for Delphi 10.4.1 Rio or higher, including 12.3 Athens.



This is an Unicode and further improved version of the CpDrv non-visible component for communicating via
RS232 COM-Ports on Windows. The code is published under the Apache 2.0 license with the consent of its
original author. Due to the use of $(AUTO) for the libsuffix it is compatible from D10.4.1 onwards only.
If you remove this setting in the package project option of both packages it should work with older
versions as well. The code found in SerialPorts.pas is not working yet.



Changes in this V3.2 release compared with 3.1.x:

* added an OnError event, which will be called if an error occurs like trying to send data quicker than
  possible with the selected baudrate or an operating system reported error
* fixed a bug where not checking the return value of a system all could lead to problems when the
  used serial device got disconnected during processing of the data received
* fixed a bug where not checking the return value of a system all could lead to problems when the
  used serial device got disconnected during sending of data
* fixed a bug where not checking the return value of a system all could lead to problems in the
  polling timer event



Changes in the V3.1.x release compared with 2.1:

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
* fixed demo application (there was a Problem with the About Dialog preventing compilation)



Manual installation (if not installed via Delphi's GetIt package manager):
Open BuildPackages from the package subdirectory. Compile the runtime package (the first one)
and then right click on the design time package and call the "Install" menu item in the popup menu.  
Alternatively install via Tools/GetIt package manager

