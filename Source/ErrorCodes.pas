unit ErrorCodes;

interface

const
  /// <summary>
  ///   More data to send given than could be send in a resonable time
  /// </summary>
  cErrSendBufferFull    = 1;
  /// <summary>
  ///   More data received than could stored in the receive buffer
  /// </summary>
  cErrReceiveBufferFull = 2;
  /// <summary>
  ///   Failure during listing the COM ports found on the system
  /// </summary>
  cErrEnumComPorts      = 3;

resourcestring
  rErrSendBufferFull      = 'Too much data to send specified';
  rErrReceiveBufferFull   = 'Too much data received';
  rErrSetCommBreakError   = 'Error in SetCommBreak. Reason: %0:s';
  rErrApplyComSetsError   = 'Error in ApplyCOMSettings. '+ sLineBreak +
                            'Reason: %0:s.' + sLineBreak +
                            'Position: %1:s';
  rErrClearCommBreakError = 'Error in ClearCommBreak. Reason: %0:s';
  rErrConnectError        = 'Error connecting. Reason: %0:s';
  rErrDisconnectError     = 'Error disconnecting. Reason: %0:s';
  rErrReadError           = 'Error reading. Reason: %0:s';
  rErrSendError           = 'Error sending. Reason: %0:s';
  rErrGetModemStatusError = 'Error retrieving modem status. Reason: %0:s';
  rErrFlushBuffersError   = 'Error flushing buffers. Reason: %0:s';
  rErrClearCommError1     = 'Error in ClearCommError/CountRX. Reason: %0:s';
  rErrClearCommError2     = 'Error in ClearCommError/OutFreeSpace. Reason: %0:s';
  rErrEnumComPortsError   = 'Error during enumerating the comports of this system. Reason: %0:s';

implementation

end.
