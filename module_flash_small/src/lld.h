#define SPI_CMD_WRITE_ENABLE   0x06
#define SPI_CMD_WRITE_DISABLE  0x04
#define SPI_CMD_WRITE          0x02
#define SPI_CMD_READ           0x03
#define SPI_CMD_READSR         0x05
#define SPI_CMD_READID         0x9f

/** This function is to be called prior to any SPI operation. It initialises the ports.
  */
void spiInit();

/** This function issues a single command without parameters to the SPI,
 * and reads up to 4 bytes status value from the device.
 *
 * \param cmd        command value - listed above
 *
 * \param returnBytes The number of bytes that are to be read from the
 *                    device after the command is issued. 0 means no bytes
 *                    will be read.
 *
 * \returns the read bytes, or zero if no bytes were requested. If multiple
 * bytes are requested, then the last byte read is in the least-significant
 * byte of the return value.
 */
int spiCommandStatus(int cmd, int returnBytes);

/** This function issues a single command with a 3-byte address parameter
 * and an optional data-set to be output to or input form the device.
 *
 * \param cmd        command value - listed above
 *
 * \param address    the address to send to the SPI device. Only the least
 *                   significant 24 bits are used.
 *
 * \param data       an array of data that contains either data to be written to
 *                   the device, or which is used to store that that is
 *                   read from the device.
 *
 * \param returnBytes If positive, then this is the number of bytes that
 *                    are to be read from the device, into ``data``. If
 *                    negative, then this is (minus) the number of bytes to
 *                    be written to the device from ``data``. 0 means no
 *                    bytes will be read or written.
 *
 */
void spiCommandAddressStatus(int cmd, int address, char data[], int returnBytes);

#define spiFlashRead(address,data,bytes) spiCommandAddressStatus(SPI_CMD_READ,address,data,bytes)


/** This function writes a block of data to the flash at the given address.
 * A write to flash can only change bits form '1' to '0'. A spiFlashErase()
 * call can be made to set a whole sector of the flash to all '1'. Note
 * that (address + data & 0xff) must equal (address & 0xff); that is, all
 * writes must happen in the same 256 byte page.
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
