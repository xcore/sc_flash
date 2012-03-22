#ifndef HAVE_DEVICEACCESS_H_
#define HAVE_DEVICEACCESS_H_

#include <xs1.h>
#include "flashlib.h"

#ifdef __XC__
extern out port p_ss;
extern out port p_sclk;
extern in buffered port:8 p_miso;
extern out buffered port:8 p_mosi;
extern clock b_spi;
extern out port p_rdy;
#endif


int fl_int_spiMasterInit(void);
int fl_int_spiInit( int div );
unsigned int fl_int_issueShortCommand( unsigned char cmd, unsigned int addr, unsigned int addrSize, unsigned int dummySize, unsigned int dataSize );
#ifdef __XC__
void fl_int_waitWhileWriting( const fl_DeviceSpec& flashAccess);
#else
void fl_int_waitWhileWriting( const fl_DeviceSpec* flashAccess);
#endif
#ifdef __XC__
int fl_int_programPageAsync( const fl_DeviceSpec& flashAccess, unsigned int pageAddress, const unsigned char data[] );
int fl_int_programPage( const fl_DeviceSpec& flashAccess, unsigned int pageAddress, const unsigned char data[] );
int fl_int_readPage( const fl_DeviceSpec& flashAccess, unsigned int pageAddress, unsigned char data[] );
#else
int fl_int_programPageAsync( const fl_DeviceSpec* flashAccess, unsigned int pageAddress, const unsigned char data[] );
int fl_int_programPage( const fl_DeviceSpec* flashAccess, unsigned int pageAddress, const unsigned char data[] );
int fl_int_readPage( const fl_DeviceSpec* flashAccess, unsigned int pageAddress, unsigned char data[] );
#endif

#ifdef __XC__
int fl_int_readBytes(const fl_DeviceSpec &flashAccess, unsigned address,
                     unsigned char data[], unsigned numBytes);
#else
int fl_int_readBytes(const fl_DeviceSpec *flashAccess, unsigned address,
                     unsigned char data[], unsigned numBytes);
#endif

#ifdef __XC__
int fl_int_getBusyStatus(const fl_DeviceSpec &flashAccess);
#else
int fl_int_getBusyStatus(const fl_DeviceSpec *flashAccess);
#endif

#ifdef __XC__
unsigned fl_int_getFullStatus(const fl_DeviceSpec &flashAccess);
#else
unsigned fl_int_getFullStatus(const fl_DeviceSpec *flashAccess);
#endif

#endif /* HAVE_DEVICEACCESS_H_ */
