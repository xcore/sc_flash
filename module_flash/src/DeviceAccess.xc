#include <xclib.h>
#include <xs1.h>
#include <print.h>

#include <print.h>

#include "DeviceAccess.h"

extern fl_PortHolderStruct g_portHolder;
extern int g_fl_int_doWaitForCompletion;

int fl_int_spiMasterInit(void)
{
  return( 0 );
}

int fl_int_spiInit( int div )
{
  // Reset resource state.
  set_port_use_on(g_portHolder.spiCLK);
  set_port_use_on(g_portHolder.spiMOSI);
  set_port_use_on(g_portHolder.spiMISO);
  set_port_use_on(g_portHolder.spiSS);
  set_clock_on(g_portHolder.spiClkblk);

  // SCLK, MOSI and MISO are clocked off generated 50 MHz clock
  // Do not make SCLK a clock-out port yet, we don't want clock now
  g_portHolder.spiCLK <: 0;
  set_port_clock(g_portHolder.spiCLK, g_portHolder.spiClkblk);
  set_port_clock(g_portHolder.spiMOSI, g_portHolder.spiClkblk);
  set_port_clock(g_portHolder.spiMISO, g_portHolder.spiClkblk);
  set_clock_div(g_portHolder.spiClkblk, div);
  set_port_mode_clock(g_portHolder.spiCLK);
  g_portHolder.spiSS <: 0x1;
  return(0);
}

static void fl_int_startTalking( unsigned char cmd )
{
  /* Send command. */
  stop_clock(g_portHolder.spiClkblk);
  clearbuf(g_portHolder.spiMISO);
  clearbuf(g_portHolder.spiMOSI);

  /* The time taken to set up the initial MOSI state is always greater than min SS setup. */
  g_portHolder.spiSS  <: 0x0;

  set_port_mode_data( g_portHolder.spiCLK );
  start_clock(g_portHolder.spiClkblk);
  partout( g_portHolder.spiMOSI, 1, (unsigned int)(cmd>>7) );
  sync( g_portHolder.spiMOSI );
  stop_clock(g_portHolder.spiClkblk);
  set_port_mode_clock(g_portHolder.spiCLK);

  partout( g_portHolder.spiMOSI, 7, (byterev(bitrev(cmd<<1))) );
}

unsigned int fl_int_issueShortCommand( unsigned char cmd, unsigned int addr, unsigned int addrSize, unsigned int dummySize, unsigned int dataSize )
{
  unsigned int data;
  int gotFirstBack = 0;

  addr = bitrev(addr)>>((4-addrSize)<<3);

  fl_int_startTalking(cmd);
  start_clock(g_portHolder.spiClkblk);

  while( addrSize != 0 )
  {
    addrSize--;
    g_portHolder.spiMOSI  <: >> addr;
    if( !gotFirstBack )
    {
      g_portHolder.spiMISO @7 :> void;   /* fill */
      gotFirstBack = 1;
    }
    else
    {
      g_portHolder.spiMISO  :> void;   /* fill */
    }
  }

  /* Skip over dummy response bytes. */
  while( dummySize != 0 )
  {
    dummySize--;
    g_portHolder.spiMOSI <: 0;
    if( !gotFirstBack )
    {
      g_portHolder.spiMISO @7 :> void;   /* fill */
      gotFirstBack = 1;
    }
    else
    {
      g_portHolder.spiMISO  :> void;
    }
  }

  if( dataSize != 0 )
  {
    g_portHolder.spiMOSI  <: 0;
    if( !gotFirstBack )
    {
      g_portHolder.spiMISO @7 :> void;   /* fill */
      gotFirstBack = 1;
    }
    else
    {
      g_portHolder.spiMISO  :> void;
    }

    /* Collect up to a wordful of real data. */
    data = 0;
    while( dataSize-- > 0 )
    {
      g_portHolder.spiMOSI  <: 0;
      g_portHolder.spiMISO  :> >> data;         /* data */
    }
  }

  /* Stop talking. */
  sync( g_portHolder.spiMOSI );
  stop_clock(g_portHolder.spiClkblk);

  g_portHolder.spiSS  <: 0x1;

  /* Result needs bit-reversing. */
  return( bitrev(data) );
}

int fl_int_getBusyStatus( const fl_DeviceSpec& flashAccess )
{
  unsigned int statusReg = fl_int_issueShortCommand( flashAccess.readSRCommand, 0, 0, 0, 1 );
  return( ( statusReg & flashAccess.wipBitMask ) ? 1 : 0 );
}

unsigned int fl_int_getFullStatus( const fl_DeviceSpec& flashAccess )
{
  return( fl_int_issueShortCommand( flashAccess.readSRCommand, 0, 0, 0, 1 ) );
}

void fl_int_waitWhileWriting(const fl_DeviceSpec& flashAccess)
{
  timer tmr;
  unsigned int t;
  while(fl_int_getBusyStatus(flashAccess))
  {
    tmr :> t;
    tmr when timerafter(t+100) :> t;
  }
}

#pragma unsafe arrays
int fl_int_programPageAsync( const fl_DeviceSpec& flashAccess, unsigned int pageAddress, const unsigned char data[] )
{
  unsigned int pageSize = fl_getPageSize();

  unsigned char cmd = flashAccess.programPageCommand;
  if( 0 != (cmd&0xff) )
  {
    unsigned addr = bitrev(pageAddress)>>8;
    fl_int_startTalking(cmd);
    start_clock(g_portHolder.spiClkblk);

    g_portHolder.spiMOSI <: >> addr;
    g_portHolder.spiMOSI <: >> addr;
    g_portHolder.spiMOSI <: >> addr;
    for (int i = 0; i < pageSize; i++)
    {
      g_portHolder.spiMOSI <: (unsigned char)(bitrev(data[i])>>24);
    }

    sync(g_portHolder.spiMOSI);
    stop_clock(g_portHolder.spiClkblk);
    g_portHolder.spiSS  <: 0x1;
  }
  else
  {
    /* When the program page command is 0, use AAI. */
    int offset = 0;
    unsigned int bytesPerWrite = (flashAccess.programPageCommand>>16)&0xf;
    cmd = (flashAccess.programPageCommand>>8)&0xff;
    while( offset < pageSize )
    {
      unsigned shiftedAddr = bitrev(pageAddress)>>8;
      fl_int_issueShortCommand( flashAccess.writeEnableCommand, 0, 0, 0, 0 );
      fl_int_startTalking( cmd );      /* AAI program start */
      start_clock(g_portHolder.spiClkblk);
      if( offset == 0 )
      {
        g_portHolder.spiMOSI <: >> shiftedAddr;
        g_portHolder.spiMOSI <: >> shiftedAddr;
        g_portHolder.spiMOSI <: >> shiftedAddr;
      }
      for( int i=0; i<bytesPerWrite; i++ )
      {
        g_portHolder.spiMOSI <: (unsigned char)(bitrev(data[offset++])>>24);
      }
      sync(g_portHolder.spiMOSI);
      stop_clock(g_portHolder.spiClkblk);
      g_portHolder.spiSS  <: 0x1;
      pageAddress += bytesPerWrite;
      fl_int_waitWhileWriting( flashAccess);
    }
    fl_int_issueShortCommand( flashAccess.writeDisableCommand, 0, 0, 0, 0 );
  }

  return(0);
}

int fl_int_programPage( const fl_DeviceSpec& flashAccess, unsigned int pageAddress, const unsigned char data[] )
{
  fl_int_programPageAsync(flashAccess, pageAddress, data);
  fl_int_waitWhileWriting( flashAccess);
  return(0);
}

#pragma unsafe arrays
static void fl_int_readPageBlock(unsigned char data[], unsigned int numBytes )
{
  unsigned int tmp;
  for (int i=0; i<numBytes; i++)
  {
    g_portHolder.spiMISO :> tmp;
    data[i] = bitrev(tmp<<24);
  }
  stop_clock(g_portHolder.spiClkblk);
}

int fl_int_readBytes(const fl_DeviceSpec& flashAccess, unsigned pageAddress,
                     unsigned char data[], unsigned int numBytes)
{
  unsigned addr = bitrev(pageAddress)>>8;
  unsigned char cmd = flashAccess.readCommand;

  fl_int_startTalking(cmd);
  start_clock(g_portHolder.spiClkblk);

  g_portHolder.spiMOSI <: >> addr;
  g_portHolder.spiMISO @7 :> void;
  g_portHolder.spiMOSI <: >> addr;
  g_portHolder.spiMISO :> void;
  g_portHolder.spiMOSI <: >> addr;
  g_portHolder.spiMISO :> void;
  g_portHolder.spiMOSI <: 0;
  g_portHolder.spiMISO :> void;

  /* Fast only */
  for (unsigned i = 0; i < flashAccess.readDummyBytes; i++) {
    g_portHolder.spiMISO :> void;
  }

  fl_int_readPageBlock( data, numBytes );

  g_portHolder.spiSS  <: 0x1;
  return(0);
}

