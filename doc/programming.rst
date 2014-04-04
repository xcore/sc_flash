
Quad SPI flash Programming Guide
================================

This section provides information on how to program applications using the quad SPI flash module.


Source Code Structure
---------------------

Directory Structure
+++++++++++++++++++

A typical quad SPI flash application will have at least three top level directories. The application will be contained in a directory starting with ``app_`` and the quad SPI flash module source is in 
the ``module_quad_spi_flash``. ::
    
    app_[app_name]/
    module_quad_spi_flash/

Of course the application may use other modules which can also be directories at this level. Which modules are compiled into the application is controlled by the ``USED_MODULES`` define in the application Makefile.

Key Files
+++++++++

The following header file contains prototypes of all functions required to use use the quad SPI flash module. The API is described in :ref:`sec_api`.

.. list-table:: Key Files
  :header-rows: 1

  * - File
    - Description
  * - ``quad_spi_flash.h``
    - Quad SPI flash API header file

Module Usage
------------
To use the quad SPI flash module you will need to declare the ``quad_spi_ports`` structure used by all of the functions belonging to the ``module_quad_spi_flash``. This will look like::

	quad_spi_ports ports = {
		XS1_PORT_4A,
                    XS1_PORT_1B,
                    XS1_PORT_4B,
                    XS1_CLKBLK_1, 0
	}; 

The ``0`` is a flag to denote if the ports have been initialised. The first function called by the application to the quad SPI flash library must be ``quad_spi_flash_init()``. This will setup the ports to the configuration required by the module.

Now the application is able to use the ``module_quad_spi_flash`` library calls.

All functions that write to the memory of the flash will set the ``BUSY`` flag of the status register. Action cannot be performed on the flash while this flag is set. A blocking function ``quad_spi_wait_until_idle()`` has been provided to allow easy checking of this.

Software Requirements
---------------------

The component is built on xTIMEcomposer Tools version 13.0.
The component can be used in version 13.0 or any higher version of xTIMEcomposer Tools.
