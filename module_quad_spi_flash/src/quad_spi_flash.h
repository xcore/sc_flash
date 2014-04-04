#ifndef QUAD_SPI_FLASH_H_
#define QUAD_SPI_FLASH_H_

#include <xs1.h>
#include "xclib.h"

#define QUAD_SPI_FLASH_ERASED 0xffffffff
#define QUAD_SPI_FLASH_BYTES_PER_PAGE 256
#define QUAD_SPI_FLASH_BYTES_PER_SECTOR 4096
#define QUAD_SPI_FLASH_BYTES_PER_BLOCK 65536

#define QUAD_SPI_FLASH_TOTAL_BYTES (1024*1024)


typedef struct {
    out port CS;
    out port CLK;
    buffered port:32 DQ;
    clock cb;
    int initialised;
} quad_spi_ports;

/**
 * This will wait until the flash is not longer in the busy state. It is a blocking call.
 *
 * /param ports The ports connected to the quad SPI flash.
 */
void quad_spi_wait_until_idle(quad_spi_ports &ports);

/**
 * It is required that this is called before all other quad SPI flash function. It is a blocking call that will return when the
 * flash has been initialised and is no longer in the busy state.
 *
 * /param ports The ports connected to the quad SPI flash.
 */
void quad_spi_flash_init(quad_spi_ports &ports);

/**
 * This sets all memory within a specified sector (4K-bytes) to the erased state of all 1s (FFh).
 * The flash will become busy following this function so a quad_spi_wait_until_idle() may be required
 * to check the status before issuing new instruction. This call is non-blocking.
 *
 * /param ports The ports connected to the quad SPI flash.
 */
void quad_spi_flash_sector_erase(quad_spi_ports &ports, unsigned sector_address);

/**
 * This sets all memory within a specified block (64K-bytes) to the erased state of all 1s (FFh).
 * The flash will become busy following this function so a quad_spi_wait_until_idle() may be required
 * to check the status before issuing new instruction. This call is non-blocking.
 *
 * /param ports The ports connected to the quad SPI flash.
 * /param sector_address The 24-bit sector address to be erased.
 */
void quad_spi_flash_block_erase(quad_spi_ports &ports, unsigned block_address);

/**
 * This sets all memory to the erased state of all 1s (FFh). The flash will become busy following
 * this function so a quad_spi_wait_until_idle() may be required to check the status before
 * issuing new instruction. This call is non-blocking.
 *
 * /param ports The ports connected to the quad SPI flash.
 * /param block_address The 24-bit block address to be erased.
 */
void quad_spi_flash_chip_erase(quad_spi_ports &ports);

/**
 * Returns either status register 1 or 2 depending on parameter. Provided to allow functionality
 * not provided by the API.
 *
 * /param ports The ports connected to the quad SPI flash.
 * /param number The status register number to be read. Must be 1 or 2 else return value will be 0xff.
 */
unsigned char quad_spi_flash_read_status_reg(quad_spi_ports &ports,  unsigned number);

/**
 * Write both of the status registers. Provided to allow functionality not provided by the API.
 *
 * /param ports The ports connected to the quad SPI flash.
 * /param status_register_1 The bit field to be written to status register 1
 * /param status_register_2 The bit field to be written to status register 2
 */
void quad_spi_flash_write_status_reg(quad_spi_ports &ports, unsigned char status_register_1, unsigned char status_register_2);

/**
 *  This will write a page to the given address. Note that the address range need to have been
 *  previously erased.
 *
 * /param ports The ports connected to the quad SPI flash.
 * /param address The address to begin reading from.
 * /param data The array where the data will be returned.
 */
void quad_spi_flash_write_page(quad_spi_ports &ports, unsigned address, unsigned data[64]);

/**
 *  This will write the given number of words to the given address. Note that the address range need to have been
 *  previously erased.
 *
 * /param ports The ports connected to the quad SPI flash.
 */
void quad_spi_flash_write_sub_page(quad_spi_ports &ports, unsigned address, unsigned data[], unsigned words);

/**
 *  This returns the device ID and manafuacture ID of the chip.
 *
 * /param ports The ports connected to the quad SPI flash.
 * /param device_id The device ID passed by reference
 * /param man_id The manafacture ID passed by reference
 */
void quad_spi_flash_device_id(quad_spi_ports &ports, unsigned char &device_id, unsigned char &man_id);

/**
 *  This will read a number of words starting from the address given.
 *
 * /param ports The ports connected to the quad SPI flash.
 * /param address The address to begin reading from.
 * /param data The array where the data will be returned.
 * /param no_of_words The count of words to read.
 */
void quad_spi_flash_read_block(quad_spi_ports &ports, unsigned address, unsigned data[], unsigned no_of_words);

#endif /* QUAD_SPI_FLASH_H_ */
