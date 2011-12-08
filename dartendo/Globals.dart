 class SGlobals {

      final double CPU_FREQ_NTSC = 1789772.5;
      final double CPU_FREQ_PAL = 1773447.4;
      final int preferredFrameRate = 60;
    
    // Microseconds per frame:
      final int frameTime = 1000000 ~/ 60;
    // What value to flush memory with on power-up:
      final int memoryFlushValue = 0xFF;

      final bool debug = true;
      final bool fsdebug = false;

      bool appletMode = true;
      bool disableSprites = false;
      bool timeEmulation = true;
      bool palEmulation;
      bool enableSound = true;
      bool focused = false;

      HashMap keycodes; //Java key codes
      HashMap controls; //vNES controls codes

      NES nes;
      
      Globals() {
        keycodes = new HashMap<int,int>(); //Java key codes
        controls = new HashMap<int,int>(); //vNES controls codes
      }

      void println(String s) {
        nes.getGui().println(s);
    }
}
 
 SGlobals Globals
 
 