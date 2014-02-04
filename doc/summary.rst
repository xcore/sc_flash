SPI Flash library
=================

The SPI flash library interfaces to SPI flash (sometimes known as serial
flash), a loosely defined standard to talk to non volatile memory using 4
wires: Slave-Select (SS), Master-In-Slave-Out (MISO), Master-Out-Slave-In
(MOSI), and clock (CLK). SPI flashes are made by many manufacturers in
sizes from a few tens of kilobytes to hundreds of kilobytes, in small 8-pin
SMD packages.

Most SPI flash implement a small set of standard commands that enable cross
platform read and write functions. Erase and protect functions are less
portable.



module_flash
------------

This module supports a general purpose flash module that supports different
flash models by means of specificaion files. The module is designed to be
inter operable with many different sorts of flash memory, and support all
operations.


module_flash_small
------------------

This module supports only few operations, and is designed to be small. Most
parameters must be compiled in (rather than run-time variable).

+----------------------------------+------------------------+------------------------+
| Functionality provided           | Resources required     | Status                 | 
|                                  +-----------+------------+                        |
|                                  | ports     | Memory     |                        |
+----------------------------------+-----------+------------+------------------------+
| Read, Erase, Write               | 4         | 550 bytes  | Implemented            |
+----------------------------------+-----------+------------+------------------------+
| Read, Erase, Write, Persistency  | 4         | 930 bytes  | Implemented            |
+----------------------------------+-----------+------------+------------------------+

The interface comprises functions for reading and writing bytes (up to a
page), and optionally for reading and writing small a small section of
persistent data in a manner that does not wear out flash.

