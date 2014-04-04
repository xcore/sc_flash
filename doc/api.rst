.. _sec_api:

Quad SPI flash API
==================

.. _sec_conf_defines:

Port Config
+++++++++++
The port config is given in ``quad_spi_flash.h``. Access to the ports is performed exclusivly by the module, the application write need only initialize the structure::

  typedef struct {
      out port CS;
      out port CLK;
      buffered port:32 DQ;
      clock cb;
  } quad_spi_ports; 

Where ``CS`` is the chip select, ``CLK`` is the clock, ``DQ`` is the 4 bit parallel data bus and cb is a clock block.

Quad SPI flash API
++++++++++++++++++

These are the functions that are called from the application and are included in ``quad_spi_flash.h``.

.. doxygenfunction:: quad_spi_wait_until_idle
.. doxygenfunction:: quad_spi_flash_init
.. doxygenfunction:: quad_spi_flash_sector_erase
.. doxygenfunction:: quad_spi_flash_block_erase
.. doxygenfunction:: quad_spi_flash_chip_erase
.. doxygenfunction:: quad_spi_flash_read_status_reg
.. doxygenfunction:: quad_spi_flash_write_status_reg
.. doxygenfunction:: quad_spi_flash_write_page
.. doxygenfunction:: quad_spi_flash_write_sub_page
.. doxygenfunction:: quad_spi_flash_device_id
.. doxygenfunction:: quad_spi_flash_read_block

