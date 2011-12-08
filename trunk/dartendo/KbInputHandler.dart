 class KbInputHandler {

   // Joypad keys:
    static final int KEY_A = 0;
    static final int KEY_B = 1;
    static final int KEY_START = 2;
    static final int KEY_SELECT = 3;
    static final int KEY_UP = 4;
    static final int KEY_DOWN = 5;
    static final int KEY_LEFT = 6;
    static final int KEY_RIGHT = 7;
   
   // Key count:
    static final int NUM_KEYS = 8;
   
    List<bool> allKeysState;
    List<int> keyMapping;
    int id;
    NES nes;

     KbInputHandler(NES nes, int id) {
        this.nes = nes;
        this.id = id;
        allKeysState = Util.newBoolList(255,false);
        keyMapping = new List<int>(KbInputHandler.NUM_KEYS);
    }

     int getKeyState(int padKey) {
       if(allKeysState[keyMapping[padKey]]) {
         return 0x41;
       } else {
         return 0x40;
       }
    }

     void mapKey(int padKey, int kbKeycode) {
        keyMapping[padKey] = kbKeycode;
    }

     /*
     void keyPressed(KeyEvent ke) {

        int kc = ke.getKeyCode();
        if (kc >= allKeysState.length) {
            return;
        }

        allKeysState[kc] = true;

        // Can't hold both left & right or up & down at same time:
        if (kc == keyMapping[InputHandler.KEY_LEFT]) {
            allKeysState[keyMapping[InputHandler.KEY_RIGHT]] = false;
        } else if (kc == keyMapping[InputHandler.KEY_RIGHT]) {
            allKeysState[keyMapping[InputHandler.KEY_LEFT]] = false;
        } else if (kc == keyMapping[InputHandler.KEY_UP]) {
            allKeysState[keyMapping[InputHandler.KEY_DOWN]] = false;
        } else if (kc == keyMapping[InputHandler.KEY_DOWN]) {
            allKeysState[keyMapping[InputHandler.KEY_UP]] = false;
        }
    }

     void keyReleased(KeyEvent ke) {

        int kc = ke.getKeyCode();
        if (kc >= allKeysState.length) {
            return;
        }

        allKeysState[kc] = false;

        if (id == 0) {
            switch (kc) {
                case KeyEvent.VK_F5: {
                    // Reset game:
                    if (nes.isRunning()) {
                        nes.stopEmulation();
                        nes.reset();
                        nes.reloadRom();
                        nes.startEmulation();
                    }
                    break;
                }
                case KeyEvent.VK_F10: {
                    // Just using this to display the battery RAM contents to user.
                    if (nes.rom != null) {
                        nes.rom.closeRom();
                    }
                    break;
                }
                case KeyEvent.VK_F12: {
                    JOptionPane.showInputDialog("Save Code for Resuming Game.", "Test");
                    break;
                }
            }
        }

    }

     void keyTyped(KeyEvent ke) {
        // Ignore.
    }
    */

     void reset() {
        allKeysState = new List<int>(255);
    }

     void update() {
        // doesn't do anything.
    }

     void destroy() {
        nes = null;
    }

}