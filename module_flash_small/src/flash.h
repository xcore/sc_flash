
#define spiFlashRead(address,data,bytes) spiCommandAddressStatus(SPI_CMD_READ,address,data,bytes)

/** This function writes a small block of data to the flash at the given
 * address. "Small" means that all writes must happen in the same 256 byte
 * page. In other words, (address + data & 0xff) must equal (address &
 * 0xff). A call can be made to spiFlashWrite() to write arbitrary size
 * data to arbitrary places. A write to flash can only change bits form '1'
 * to '0'. A call can be made to spiFlashErase() to set a whole sector of
 * the flash to all '1'.

 * \param address the address to send to the SPI device. Only the least
 *                significant 24 bits are used.
 *
 * \param data    an array of data that contains the data to be written to
 *                the flash device.
 *
 * \param bytes   The number of bytes that are to be written to the device
 *                from ``data``.
 *
 */
void spiFlashWriteSmall(int address, char data[],int bytes);

/** This function writes a block of data to the flash at the given address.
 * A write to flash can only change bits form '1' to '0'. A spiFlashErase()
 * call can be made to set a whole sector of the flash to all '1'.
 *
 * \param address the address to send to the SPI device. Only the least
 *                significant 24 bits are used.
 *
 * \param data    an array of data that contains the data to be written to
 *                the flash device.
 *
 * \param bytes   The number of bytes that are to be written to the device
 *                from ``data``.
 *
 */
void spiFlashWrite(int address, char data[],int bytes);

/** This function erases a block of data in the flash at the given address.
 * This will replace the block with all '1' bits. The address should be
 * aligned on a 4K boundary, and the length should be a whole number of 4K
 * blocks.
 *
 * \param address the address to send to the SPI device. Only the least
 *                significant 24 bits are used.
 *
 * \param bytes   The number of bytes that are to be erased.
 *
 */
void spiFlashErase4K(int address, int bytes);

int spiFlashPersistentStateRead(char data[]);
