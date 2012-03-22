#include <platform.h>
#include <flash.h>

#define MAX_PSIZE 256

/* initializers defined in XN file
 * and available via platform.h */

fl_SPIPorts SPI = { PORT_SPI_MISO,
                    PORT_SPI_SS,
                    PORT_SPI_CLK,
                    PORT_SPI_MOSI,
                    XS1_CLKBLK_1 };
                        
int upgrade(chanend c, int usize) {

  /* obtain an upgrade image and write 
   * it to flash memory 
   * error checking omitted */
  
  fl_BootImageInfo b;
  unsigned char page[MAX_PSIZE];
  int psize;

  fl_connect(SPI);

  psize = fl_getPageSize();
  fl_getFactoryImage(b);
  fl_getNextBootImage(b);

  while(fl_startImageReplace(b, usize))
    ;

  c :> psize;
  while (psize) {
    for(int i=0;i<psize;i++)
      c :> page[i];
    fl_writeImagePage(page);
    c :> psize;
  }

  fl_endWriteImage();

  fl_disconnect();
  
   return 0;
}

int main() {
  /* main application - calls upgrade 
   * to perform an in-field upgrade */
}
