unit ErrorCodes;

interface

const
  /// <summary>
  ///   More data to send given than could be send in a resonable time
  /// </summary>
  cErrSendBufferFull = 1;
  /// <summary>
  ///   More data received than could stored in the receive buffer
  /// </summary>
  cErrReceiveBufferFull = 2;

resourcestring
  rErrSendBufferFull    = 'Too much data to send specified';
  rErrReceiveBufferFull = 'Too much data received';

implementation

end.
