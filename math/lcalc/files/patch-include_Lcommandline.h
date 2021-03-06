--- include/Lcommandline.h.orig	2012-08-08 21:21:55 UTC
+++ include/Lcommandline.h
@@ -18,6 +18,8 @@
    with the package; see the file 'COPYING'. If not, write to the Free Software
    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 
+   Patches borrowed from SageMath.
+
 */
 
 
@@ -39,7 +41,7 @@
 
 #include "Lcommandline_globals.h"      //command line global variables
 #ifdef INCLUDE_PARI
-#include "pari.h"          //for pari's elliptic curve functions
+#include "pari/pari.h"          //for pari's elliptic curve functions
 #undef init                //pari has a '#define init pari_init' which
                            //causes trouble with the stream.h init.
                            //pari also causes trouble with things like abs.
