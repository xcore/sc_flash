#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <xclib.h>

#include <flashlib.h>
#include "DeviceAccess.h"
#include "SpecDefinitions.h"

#define IMAGETAG (0x1a551e5)
#define IMAGETAG_13 (0x0FF51DE)

#define MAX_PAGE_SIZE 256

static unsigned int sortBits( unsigned int bits )
{
  return( byterev(bitrev(bits)) );
}

static void fl_initProtection(void);

static int getSectorAtOrAfter(unsigned address);
static int getSectorContaining(unsigned address);

static const fl_DeviceSpec* g_flashAccess = NULL;
fl_SPIPorts g_portHolder;

static const fl_DeviceSpec fl_deviceSpecs[] = FL_DEVICESPECS;


int fl_connect( fl_SPIPorts* pHolder )
{
  return( fl_connectToDevice( pHolder, fl_deviceSpecs, sizeof(fl_deviceSpecs) / sizeof(fl_DeviceSpec) ) );
}

/* Connect to the SPI (i.e. initialise). */
int fl_connectToDevice( fl_SPIPorts* pHolder, const fl_DeviceSpec* deviceSpecPtr, unsigned int specCount )
{
  g_portHolder = *pHolder;
  fl_int_spiMasterInit();
  int found = 0;
  while( specCount > 0 )
  {
    fl_int_spiInit(deviceSpecPtr->clockDiv);
    if( fl_int_issueShortCommand( deviceSpecPtr->idCommand, 0, 0, deviceSpecPtr->idDummyBytes, deviceSpecPtr->idBytes ) == deviceSpecPtr->idValue )
    {
      g_flashAccess = deviceSpecPtr;
      found = 1;
      break;
    }
    deviceSpecPtr++;
    specCount--;
  }
  if( found )
  {
    unsigned int bootPartSize;
    fl_int_readBytes( g_flashAccess, 12, (unsigned char*)&bootPartSize, 4 );
    bootPartSize = bitrev(byterev(bootPartSize));
    if( bootPartSize != 0 )
    {
      fl_setBootPartitionSize( bootPartSize );
    }
    else
    {
      fl_setBootPartitionSize( fl_getFlashSize() );
    }
    fl_initProtection();
  }
  return( found==0 );
}

/* Disconnect from the SPI (i.e. de-initialise). */
int fl_disconnect()
{
  return(0);
}

int fl_getFlashIdNum()
{
  unsigned int infoRootIndex=0;
  int res=-1;
  fl_int_readBytes( g_flashAccess, 4<<2, (unsigned char*)&infoRootIndex, 4 );
  infoRootIndex = sortBits(infoRootIndex);
  if( infoRootIndex != 0 )
  {
    fl_int_readBytes( g_flashAccess, (infoRootIndex+1)<<2,  (unsigned char*)&res, 4 );
    res = sortBits(res);
  }
  return( res );
}

int fl_getFlashIdStr( char buf[], int maxlen )
{
  unsigned int infoRootIndex=0;
  unsigned int strOutIndex = 0;
  unsigned int strWordIndex;
  int res=-1;
  fl_int_readBytes( g_flashAccess, 4<<2, (unsigned char*)&infoRootIndex, 4 );
  infoRootIndex = sortBits(infoRootIndex);
  if( infoRootIndex != 0 )
  {
    strWordIndex = infoRootIndex+2;
    res = maxlen;
    while( strOutIndex < maxlen )
    {
      unsigned int newWord;
      fl_int_readBytes( g_flashAccess, strWordIndex<<2,  (unsigned char*)&newWord, 4 );
      newWord = sortBits(newWord);
      int terminated = 0;
      for( int i=0; i<4; i++ )
      {
        if( strOutIndex==maxlen )
        {
          break;
        }
        buf[strOutIndex] = newWord&0xff;
        if( buf[strOutIndex] == 0 )
        {
          res = strOutIndex;
          terminated=1;
          break;
        }
        newWord >>= 8;
        strOutIndex++;
      }
      if( terminated )
      {
        break;
      }
      strWordIndex++;
    }
  }
  return( res );
}

int fl_getBusyStatus()
{
  return( fl_int_getBusyStatus( g_flashAccess ) );
}

unsigned int fl_getFullStatus()
{
  return( fl_int_getFullStatus( g_flashAccess ) );
}


/* Basic information.
*/

/* Returns an enum value for the flash chip. */
int fl_getFlashType()
{
  return( g_flashAccess->flashId );
}

/* Gets the capacity in bytes of the flash. */
unsigned fl_getFlashSize()
{
  return( g_flashAccess->numPages*g_flashAccess->pageSize );
}


/* Device level operations.
*/

/* Clear the whole thing. */
int fl_eraseAll()
{
  int numSecs = fl_getNumSectors();
  int i;
  for( i=0; i<numSecs; i++ )
  {
    fl_eraseSector(i);
  }
  return( 0 );
}

/* Enable or disable writing to the device. */
int fl_setWritability( int enable )
{
  fl_int_issueShortCommand( enable?g_flashAccess->writeEnableCommand:g_flashAccess->writeDisableCommand, 0, 0, 0, 0 );
  return( 0 );
}

/**
 * Unprotect everything apart from the factory image. If it is not possible
 * to leave the factory image protected without leaving the the entire device
 * protected then the entire device is unprotected. On some devices
 * (e.g. ATMEL_AT25FS010) all sectors are protected after power cycling.
 * We don't want the user to have to unset protection in order to write an
 * upgrade image and we don't want have to unprotect before every write call.
 */
static void fl_initProtection(void)
{
  if (g_flashAccess->protectionType != PROT_TYPE_SECS) {
    // Not possible to protect just the factory image.
    fl_setProtection(0);
    return;
  }
  fl_BootImageInfo bfi;
  if (fl_getFactoryImage(&bfi) != 0) {
    // No factory image to protect.
    fl_setProtection(0);
  }
  int firstUnprotectedSector = getSectorAtOrAfter(bfi.startAddress + bfi.size);
  int numSectors = fl_getNumSectors();
  int i;
  for (i = firstUnprotectedSector; i < numSectors; i++) {
    fl_setSectorProtection(i, 0);
  }
}

/* Protect the device as much as possible without making it irreversible. */
int fl_setProtection( int protect )
{
  switch( g_flashAccess->protectionType )
  {
  case PROT_TYPE_NONE:
    break;
  case PROT_TYPE_SR:
  case PROT_TYPE_SR_2X:
  {
    unsigned int cmd = g_flashAccess->writeSRCommand;
    for( int i=0, iL=((g_flashAccess->protectionType==PROT_TYPE_SR_2X)?2:1); i<iL; i++ )
    {
      fl_setWritability(1);
      if( (cmd>>8) != 0 )
      {
        fl_int_issueShortCommand( (cmd>>8)&0xff, 0, 0, 0, 0);
        cmd &= 0xff;
      }
      fl_int_issueShortCommand( cmd, protect ? g_flashAccess->protection.statusBits.setProtectedValue : g_flashAccess->protection.statusBits.setUnprotectedValue, 1, 0, 0);
      fl_int_waitWhileWriting(g_flashAccess);
    }
    break;
  }
  case PROT_TYPE_SECS:
  {
    int secNum;
    int numSectors = fl_getNumSectors();
    for(secNum=0; secNum<numSectors; secNum++) {
      fl_setSectorProtection(secNum, protect);
    }
    break;
  }
  default:
    return(1);
  }
  return( 0 );
}


/* Sector level operations.
*/

/* Get the number of sectors. */
int fl_getNumSectors()
{
  int res = 0;
  switch( g_flashAccess->sectorLayout )
  {
  case SECTOR_LAYOUT_REGULAR:
    res = fl_getFlashSize() / g_flashAccess->sectorSizes.regularSectorSize;
    break;
  case SECTOR_LAYOUT_IRREGULAR:
    res = g_flashAccess->sectorSizes.irregularSectorSizes.sectorCount;
    break;
  }
  return( res );
}

/* Get the size (in bytes) of a particular sector. */
int fl_getSectorSize( int sectorNum )
{
  int res=0;
  switch( g_flashAccess->sectorLayout )
  {
  case SECTOR_LAYOUT_REGULAR:
    res = g_flashAccess->sectorSizes.regularSectorSize;
    break;
  case SECTOR_LAYOUT_IRREGULAR:
    res = fl_getPageSize() << g_flashAccess->sectorSizes.irregularSectorSizes.sectorSizesLog2[sectorNum];
    break;
  default:
    break;
  }
  return( res );
}

/* Get the address of a particular sector. */
int fl_getSectorAddress( int sectorNum )
{
  int res=0;
  switch( g_flashAccess->sectorLayout )
  {
  case SECTOR_LAYOUT_REGULAR:
    res = g_flashAccess->sectorSizes.regularSectorSize * sectorNum;
    break;
  case SECTOR_LAYOUT_IRREGULAR:
  {
    int countNum=0;
    while( countNum < sectorNum )
    {
      res += fl_getPageSize() << g_flashAccess->sectorSizes.irregularSectorSizes.sectorSizesLog2[countNum++];
    }
    break;
  }
  default:
    break;
  }
  return( res );
}

/**
 * Return the address one past the end of the sector.
 */
static int fl_getSectorEndAddress(int sectorNum)
{
  return fl_getSectorAddress(sectorNum) + fl_getSectorSize(sectorNum);
}

/* Erase a sector. */
static int fl_eraseSectorAsync(int sectorNum)
{
  unsigned secAddr = fl_getSectorAddress(sectorNum);
  unsigned secSize = fl_getSectorSize(sectorNum);
  unsigned sectorEraseSize = g_flashAccess->sectorEraseSize;
  if (sectorEraseSize == 0) {
    sectorEraseSize = secSize;
  }
  fl_setWritability(1);
  fl_int_issueShortCommand(g_flashAccess->sectorEraseCommand, secAddr, 3, 0, 0);
  secSize -= sectorEraseSize;
  secAddr += sectorEraseSize;
  while (secSize > 0) {
    fl_int_waitWhileWriting( g_flashAccess);
    fl_setWritability(1);
    fl_int_issueShortCommand(g_flashAccess->sectorEraseCommand, secAddr, 3, 0, 0);
    secSize -= sectorEraseSize;
    secAddr += sectorEraseSize;
  }
  return 0;
}

/* Erase a sector. */
int fl_eraseSector( int sectorNum )
{
  int res = fl_eraseSectorAsync(sectorNum);
  fl_int_waitWhileWriting( g_flashAccess);
  fl_setWritability(0);
  return res;
}

/* Protect/unprotect a sector. */
int fl_setSectorProtection( int sectorNum, int protect )
{
  if( g_flashAccess->protectionType == PROT_TYPE_SECS )
  {
    unsigned int secAddr = fl_getSectorAddress(sectorNum);
    fl_setWritability(1);
    fl_int_issueShortCommand(
      protect ? g_flashAccess->protection.commandValues.sectorProtectCommand : g_flashAccess->protection.commandValues.sectorUnprotectCommand,
      secAddr, 3, 0, 0);
    fl_int_waitWhileWriting(g_flashAccess);
  }
  return(0);
}

unsigned fl_getNumDataSectors(void)
{
  int sector = getSectorContaining(fl_getDataPartitionBase());
  if (sector < 0)
    return 0;
  return fl_getNumSectors() - sector;
}

unsigned fl_getDataSectorSize(unsigned n)
{
  int sector = getSectorContaining(fl_getDataPartitionBase());
  if (sector < 0)
    return 0;
  sector += n;
  return fl_getSectorSize(sector);
}

int fl_eraseDataSector(unsigned n)
{
  int sector = getSectorContaining(fl_getDataPartitionBase());
  if (sector < 0)
    return 1;
  sector += n;
  if( sector >= fl_getNumSectors() ) { return(1); }
  return fl_eraseSector(sector);
}

int fl_eraseAllDataSectors(void)
{
  int sector = getSectorContaining(fl_getDataPartitionBase());
  if (sector < 0)
    return 0;
  int numSectors = fl_getNumSectors();
  for (; sector < numSectors; sector++) {
    if (fl_eraseSector(sector) != 0)
      return 1;
  }
  return 0;
}

/* Page level operations.
*/

/* Get the number of pages. */
unsigned fl_getNumPages()
{
  return( g_flashAccess->numPages );
}

/* Get the page size (in bytes). */
unsigned fl_getPageSize()
{
  return( g_flashAccess->pageSize );
}

static int fl_writePageAsync(unsigned address, const unsigned char data[])
{
  int res;
  if ((address & (g_flashAccess->pageSize - 1)) != 0)
    return 1;
  fl_setWritability(1);
  res = fl_int_programPageAsync(g_flashAccess, address, data);
  return res;
}

/* Program a page at the given address. */
int fl_writePage( unsigned int address, const unsigned char data[] )
{
  int res = fl_writePageAsync(address, data);
  fl_int_waitWhileWriting(g_flashAccess);
  fl_setWritability(0);
  return res;
}

/* Read a page at the given address. */
int fl_readPage( unsigned int address, unsigned char data[] )
{
  return( fl_int_readBytes( g_flashAccess, address, data, fl_getPageSize() ) );
}

unsigned fl_getNumDataPages(void)
{
  return fl_getDataPartitionSize() / fl_getPageSize();
}

int fl_writeDataPage(unsigned n, const unsigned char data[])
{
  unsigned address;
  if( n >= fl_getNumDataPages() ) { return( 1 ); }
  address = fl_getDataPartitionBase() + n * fl_getPageSize();
  return fl_writePage(address, data);
}

int fl_readDataPage(unsigned n, unsigned char dst[])
{
  unsigned address;
  if( n >= fl_getNumDataPages() ) { return( 1 ); }
  address = fl_getDataPartitionBase() + n * fl_getPageSize();
  return fl_readPage(address, dst);
}

/*
 *  Boot/store level operations
 *  ---------------------------
 */

/* Basic information.
*/
static unsigned int fl_int_bootPartitionSize = 0x0;

/* Sets the size of the boot partition. */
unsigned int fl_setBootPartitionSize( unsigned int s )
{
  int sNum, sLimit=fl_getNumSectors();
  int notFound=1;
  if( s == fl_getFlashSize() )
  {
    fl_int_bootPartitionSize = 0;
    notFound = 0;
  }
  else
  {
    for( sNum=0; sNum<sLimit; sNum++ )
    {
      if( fl_getSectorAddress(sNum) == s )
      {
        fl_int_bootPartitionSize = s;
        notFound = 0;
        break;
      }
    }
  }
  return( notFound );
}

/* Returns the size of the boot partition. */
unsigned int fl_getBootPartitionSize()
{
  return( fl_int_bootPartitionSize ? fl_int_bootPartitionSize : fl_getFlashSize() );
}

/* Returns the base and the size of the persistant store partition. */
unsigned int fl_getDataPartitionBase()
{
  return( fl_getBootPartitionSize() );
}

unsigned int fl_getDataPartitionSize()
{
  return( fl_getFlashSize()-fl_getBootPartitionSize() );
}

/* Query and modify the boot partition.
*/

/* The start of the first image is always the first page.
 */

/* Returns information about the first boot image (the factory image). */
int fl_getFactoryImage( fl_BootImageInfo* bootImageInfo )
{
  unsigned tmpBuf[9];
  fl_int_readBytes(g_flashAccess, 0, (unsigned char*)tmpBuf, 4);
  unsigned startAddr = (sortBits(tmpBuf[0])+2)<<2; /* Normal case. */
  fl_int_readBytes(g_flashAccess, startAddr, (unsigned char*)tmpBuf, (6 + 3) * sizeof(int));
  unsigned *header = tmpBuf;
  unsigned int image13 = 0;
  if (sortBits(tmpBuf[0]) != IMAGETAG) {
    if (sortBits(tmpBuf[0]) != IMAGETAG_13) {
      header += 3; /* Secure case. */
      if (sortBits(header[0]) != IMAGETAG) {
        if (sortBits(header[0]) != IMAGETAG_13) {
          return 1;
        }
        else {
          image13 = 1;
        }
      }
    }
    else {
      image13 = 1;
    }

  }

  /* Image headers changed format in  tools 13*/
  bootImageInfo->startAddress = startAddr;
  bootImageInfo->size         = (image13) ? sortBits(header[6]) : sortBits(header[5]);  /* Size is to next sector start. */
  bootImageInfo->version      = (image13) ? sortBits(header[5]) : sortBits(header[4]);
  bootImageInfo->factory      = 1;

  return 0;
}

/* Returns information about the next boot image. */
int fl_getNextBootImage( fl_BootImageInfo* bootImageInfo )
{
  unsigned tmpBuf[7]; /* Image headers changed format in  tools 13*/
  unsigned numSectors = fl_getNumSectors();
  unsigned lastAddress = bootImageInfo->startAddress+bootImageInfo->size;
  unsigned sectorNum = getSectorAtOrAfter(lastAddress);
  if (sectorNum < 0)
    return 1;
  while (sectorNum < numSectors) {
    unsigned sectorAddress = fl_getSectorAddress(sectorNum);
    fl_int_readBytes(g_flashAccess, sectorAddress, (unsigned char*)tmpBuf, 7 * sizeof(int));
    if (sortBits(tmpBuf[0]) == IMAGETAG) {
      bootImageInfo->startAddress = sectorAddress;
      bootImageInfo->size         = sortBits(tmpBuf[5]);
      bootImageInfo->version      = sortBits(tmpBuf[4]);
      bootImageInfo->factory      = 0;
      return 0;
    }
    else if (sortBits(tmpBuf[0]) == IMAGETAG_13) {        /*New image tag for tools 13*/
      bootImageInfo->startAddress = sectorAddress;
      bootImageInfo->size         = sortBits(tmpBuf[6]);  /*New location in image header*/
      bootImageInfo->version      = sortBits(tmpBuf[5]);  /*New location in image header*/
      bootImageInfo->factory      = 0;
      return 0;
    }

    sectorNum++;
  }
  return 1;
}

/* Erase a boot image. */
int fl_eraseNextBootImage( fl_BootImageInfo* bootImageInfo )
{
  fl_BootImageInfo nextImage = *bootImageInfo;
  if (fl_getNextBootImage(&nextImage) != 0) {
    return 1;
  }
  return fl_deleteImage(&nextImage);
}

/* Add a new boot image after the supplied one.  Three part version. */
typedef struct {
  unsigned baseAddress;
  unsigned limitAddress;
  unsigned currentAddress;
  unsigned eraseSector;
} fl_ImageWriteState;

static fl_ImageWriteState fl_imageWriteState;

/**
 * Returns the number of the first sector starting at or after the specified
 * address.
 * \return The number of sector or -1 if there is no such sector.
 */
static int getSectorAtOrAfter(unsigned address)
{
  unsigned numSectors = fl_getNumSectors();
  unsigned sector;
  for (sector = 0; sector < numSectors; sector++) {
    if (fl_getSectorAddress(sector) >= address)
      return sector;
  }
  return -1;
}

/**
 * Returns the number of the first sector containing the specified
 * address.
 * \return The number of sector or -1 if there is no such sector.
 */
static int getSectorContaining(unsigned address)
{
  unsigned numSectors = fl_getNumSectors();
  unsigned sector;
  for (sector = 0; sector < numSectors; sector++) {
    if (fl_getSectorEndAddress(sector) > address)
      return sector;
  }
  return -1;
}

#include <print.h>

/**
 * Initialise the write state for writing an image to the specified address.
 * The maximum image size is given as an argument. The function checks to is
 * possible to write the image without overriding the data partition or the
 * image after \a bootImageInfo (if it exists).
 */
static int
fl_initImageWriteState(unsigned address, unsigned maxsize,
                       fl_BootImageInfo* bootImageInfo)
{
  /* Initialise state. */
  unsigned baseSectorNum = getSectorAtOrAfter(address);
  /* Don't allow images starting at sector 0 as 0 is overloaded to mean we are
   * not in the middle of writing an image. We shouldn't be erasing sector 0
   * anyway since this will erase the second stage loader. */
  if (baseSectorNum <= 0) {
    return -1;
  }
  fl_imageWriteState.baseAddress = fl_getSectorAddress(baseSectorNum);
  unsigned pageSize = fl_getPageSize();
  unsigned limitAddress = fl_imageWriteState.baseAddress + maxsize;
  limitAddress = ((limitAddress + pageSize - 1) / pageSize) * pageSize;
  fl_imageWriteState.limitAddress = limitAddress;
  fl_imageWriteState.currentAddress = fl_imageWriteState.baseAddress;
  /* Check we won't overwrite anything. Bootable images and the store partition
   * start on sector boundaries so there is no need to round up the limit
   * address to the end of sector for the comparison. */
  unsigned nextAddress;
  fl_BootImageInfo nextImage = *bootImageInfo;
  if (fl_getNextBootImage(&nextImage) == 0) {
    nextAddress = nextImage.startAddress;
  } else {
    nextAddress = fl_getDataPartitionBase();
  }
  if (fl_imageWriteState.limitAddress > nextAddress) {
    return -1;
  }
  fl_imageWriteState.eraseSector = baseSectorNum;
  return 1;
}

unsigned fl_getImageVersion(fl_BootImageInfo* bootImageInfo)
{
  return bootImageInfo->version;
}

static int fl_startAddImageCommon()
{
  /* This is unnecessary if we are erasing the first sector but it does no
   * harm. We would need to keep additional state to avoid waiting before the
   * first erase. */
  fl_int_waitWhileWriting(g_flashAccess);
  fl_eraseSectorAsync(fl_imageWriteState.eraseSector);
  if (fl_getSectorEndAddress(fl_imageWriteState.eraseSector) < fl_imageWriteState.limitAddress) {
    fl_imageWriteState.eraseSector++;
    return 1;
  }
  /* Erasure complete. */
  fl_imageWriteState.eraseSector = 0;
  return 0;
}

int fl_startImageAdd(fl_BootImageInfo* bootImageInfo, unsigned maxsize,
                     unsigned padding)
{
  if (fl_imageWriteState.eraseSector == 0) {
    unsigned address
      = bootImageInfo->startAddress + bootImageInfo->size + padding;
    return fl_initImageWriteState(address, maxsize, bootImageInfo);
  }
  return fl_startAddImageCommon();
}

int fl_startImageAddAt( unsigned offset, unsigned maxsize )
{
  if (fl_imageWriteState.eraseSector == 0) {
    fl_BootImageInfo bii;
    if( fl_getFactoryImage(&bii) != 0 )
    {
      return -1;
    }
    int baseSector = getSectorAtOrAfter(bii.startAddress+bii.size);
    if( baseSector == -1 )
      return -1;
    unsigned baseAddress = fl_getSectorAddress(baseSector);
    if( baseAddress == -1 )
      return -1;
    int writeSector = getSectorAtOrAfter( baseAddress+offset );
    if( writeSector == -1 )
      return -1;
    unsigned writeAddress = fl_getSectorAddress(writeSector);
    if( writeAddress != baseAddress+offset )
      return -1;
    /* Set these so that getNextImage does nothing. */
    bii.startAddress = writeAddress;
    bii.size = 0;
    return fl_initImageWriteState(writeAddress, maxsize, &bii);
  }
  return fl_startAddImageCommon();
}

int fl_startImageReplace(fl_BootImageInfo* bootImageInfo, unsigned maxsize)
{
  if (fl_imageWriteState.eraseSector == 0) {
    // Disallow replacing the factory image.
    if (bootImageInfo->factory)
      return -1;
    return fl_initImageWriteState(bootImageInfo->startAddress, maxsize, bootImageInfo);
  }
  /* This is unnecessary if we are erasing the first sector but it does no
   * harm. We would need to keep additional state to avoid waiting before the
   * first erase. */
  fl_int_waitWhileWriting(g_flashAccess);
  fl_eraseSectorAsync(fl_imageWriteState.eraseSector);
  if (fl_getSectorEndAddress(fl_imageWriteState.eraseSector) < fl_imageWriteState.limitAddress) {
    fl_imageWriteState.eraseSector++;
    return 1;
  }
  /* Erasure complete. */
  fl_imageWriteState.eraseSector = 0;
  return 0;
}

#define VALIDATE

int fl_writeImagePage(const unsigned char page[])
{
  unsigned pageSize = fl_getPageSize();
  if (fl_imageWriteState.currentAddress + pageSize >
      fl_imageWriteState.limitAddress) {
    return -1;
  }
  fl_int_waitWhileWriting(g_flashAccess);
#ifdef VALIDATE
  unsigned char readBuf[MAX_PAGE_SIZE];
  fl_writePage(fl_imageWriteState.currentAddress, page);
  fl_readPage(fl_imageWriteState.currentAddress, readBuf);
  int retval = !!memcmp(page, readBuf, pageSize);
#else
  int retval = fl_writePageAsync(fl_imageWriteState.currentAddress, page);
#endif
  fl_imageWriteState.currentAddress += pageSize;
  return retval;
}

int fl_endWriteImage(void)
{
  fl_int_waitWhileWriting(g_flashAccess);
  fl_setWritability(0);
  return 0;
}

int fl_deleteImage(fl_BootImageInfo* bootImageInfo)
{
  // Disallow deleting the factory image.
  if (bootImageInfo->factory)
    return 1;
  unsigned sector = getSectorContaining(bootImageInfo->startAddress);
  if (sector < 0)
    return 1;
  return fl_eraseSector(sector);
}

#pragma stackfunction 2048
int fl_addBootImage(fl_BootImageInfo* bootImageInfo, unsigned imageSize,
                    unsigned (*getData)(void*,unsigned,unsigned char*),
                    void* userPtr)
{
  if (imageSize == 0)
    return 0;
  unsigned pageSize = fl_getPageSize();
  /* Erase. */
  int result = 0;
  do {
    result = fl_startImageAdd(bootImageInfo, imageSize, 0);
  } while (result > 0);
  if (result < 0)
    return 1;

  /* Write data. */
  unsigned char buf[MAX_PAGE_SIZE];
  int finalPage = 0;
  while (!finalPage) {
    unsigned pageBytes = pageSize;
    if (pageBytes >= imageSize) {
      pageBytes = imageSize;
      finalPage = 1;
    }
    unsigned pageRead = 0;
    /* Get a page of data. */
    do {
      unsigned read = (*getData)(userPtr, pageBytes - pageRead, &buf[pageRead]);
      if (read == 0)
        return 1;
      else if (read > (pageBytes - pageRead))
        return 1;
      pageRead += read;
    } while (pageBytes - pageRead);
    /* Write the page. */
    if (fl_writeImagePage(buf) != 0)
      return 1;
    imageSize -= pageBytes;
  }
  fl_endWriteImage();
  return 0;
}

typedef struct {
  unsigned currentAddress;
  unsigned limitAddress;
} fl_ImageReadState;

static fl_ImageReadState fl_imageReadState;

int fl_startImageRead(fl_BootImageInfo *bootImageInfo)
{
  fl_imageReadState.currentAddress = bootImageInfo->startAddress;
  unsigned limitAddress = fl_imageReadState.currentAddress + bootImageInfo->size;
  unsigned pageSize = fl_getPageSize();
  limitAddress = ((limitAddress + pageSize - 1) / pageSize) * pageSize;
  fl_imageReadState.limitAddress = limitAddress;
  return 0;
}

int fl_readImagePage(unsigned char page[])
{
  unsigned pageSize = fl_getPageSize();
  if (fl_imageReadState.currentAddress + pageSize > fl_imageReadState.limitAddress)
    return 1;
  if (fl_readPage(fl_imageReadState.currentAddress, page) != 0)
    return 1;
  fl_imageReadState.currentAddress += pageSize;
  return 0;
}

/* Query and modify data in the store partition.
*  Addresses are offsets in the store, not flash addresses.
*/

int fl_readData(unsigned offset, unsigned size, unsigned char dst[])
{
  return fl_int_readBytes(g_flashAccess, fl_getDataPartitionBase() + offset, dst, size);
}

/* Returns the scratch buffer size needed to use fl_writeStore() with the given paramters. */
/* Returns 0 on error. */
unsigned fl_getWriteScratchSize( unsigned int offset, unsigned int size )
{
  unsigned address = fl_getDataPartitionBase()+offset;
  unsigned limitAddress = address+size;
  unsigned numSectors = fl_getNumSectors();
  unsigned currSecNum = getSectorContaining(address);
  unsigned maxSectorSize = 0;
  if (currSecNum < 0)
    return -1;
  while( (currSecNum<numSectors) && ( fl_getSectorAddress(currSecNum) < limitAddress ) )
  {
    unsigned int currSectorSize = fl_getSectorSize(currSecNum);
    if( currSectorSize > maxSectorSize )
    {
      maxSectorSize = currSectorSize;
    }
    currSecNum++;
  }
  return( maxSectorSize );
}

/* Write and arbitrary number of bytes to the store (endangers data sharing pages/sectors). */
int fl_writeData(unsigned int offset, unsigned int size,
                 const unsigned char src[], unsigned char buffer[])
{
  /* TODO this is inefficent. The minimum buffer size should depend on
   * maximum number of bytes in a sector that are unwritten. If a sector is
   * completely written then there is no need to read modify write, we should
   * just write the data.
   */
  unsigned address = fl_getDataPartitionBase()+offset;
  unsigned limitAddress = address+size;
  unsigned numSectors = fl_getNumSectors();
  int currSecNum = getSectorContaining(address);
  unsigned pageSize = fl_getPageSize();
  if (currSecNum < 0)
    return 1;
  while( (currSecNum<numSectors) && ( fl_getSectorAddress(currSecNum) < limitAddress ) )
  {
    unsigned int currSectorSize = fl_getSectorSize(currSecNum);
    unsigned int currSectorAddr = fl_getSectorAddress(currSecNum);
    if (fl_int_readBytes(g_flashAccess, currSectorAddr, buffer, currSectorSize) != 0)
      return 1;
    int modOffsetInSector = address-currSectorAddr;
    int modOffsetInBuffer = (modOffsetInSector<0) ? (-modOffsetInSector) : 0;
    if( modOffsetInSector < 0 )
    {
      modOffsetInSector = 0;
    }
    int modSize = size-modOffsetInBuffer;
    if( modOffsetInSector+modSize > currSectorSize )
    {
      modSize = currSectorSize-modOffsetInSector;
    }
    memcpy( buffer+modOffsetInSector, src+modOffsetInBuffer, modSize );
    fl_eraseSector( currSecNum );
    unsigned int writebackToGo = currSectorSize;
    unsigned int writebackAddr = currSectorAddr;
    unsigned char* writebackPtr = buffer;
    while( writebackToGo > 0 )
    {
      fl_writePage( writebackAddr, writebackPtr );
      writebackToGo -= pageSize;
      writebackPtr += pageSize;
      writebackAddr += pageSize;
    }
    currSecNum++;
  }
  return( 0 );
}

int fl_int_copySpec( fl_DeviceSpec* dest )
{
  if( NULL == g_flashAccess )
  {
    return( -1 );
  }
  memcpy( (void*)dest, (void*)g_flashAccess, sizeof( fl_DeviceSpec ) );
  return(0);
}

