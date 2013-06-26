part of dartendo;

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
  List<int> inverseKeyMapping;
  int id;
  NES nes;

  KbInputHandler(NES nes, int id) {
    this.nes = nes;
    this.id = id;
    allKeysState = Util.newBoolList(255, false);
    keyMapping = Util.newIntList(KbInputHandler.NUM_KEYS, 0);
    //Util.printDebug('KbInputHandler.constructor(): Exits', debugMe);
  }

  int getKeyState(int padKey) {
    if(allKeysState[keyMapping[padKey]]) {
      return 0x41;
    } else {
      return 0x40;
    }
  }

  void setKeyState(int padKey, int state) {
    if (state == 0x41)
      allKeysState[keyMapping[padKey]] = true;
    else if (state == 0x40)
      allKeysState[keyMapping[padKey]] = false;
  }

  void mapKey(int padKey, int kbKeycode) {
    //Util.printDebug('KbInputHandler.mapKey: Mapping $padKey to $kbKeycode', debugMe);
    keyMapping[padKey] = kbKeycode;
  }

  void keyPressed(KeyboardEvent ke) {
    int kc = ke.keyCode;
    if (kc >= allKeysState.length)
      return;

    //Util.printDebug('KbInputHandler.keyPressed(...): ${ke.keyIdentifier} (${ke.keyCode})', debugMe);
    allKeysState[kc] = true;

    // Can't hold both left & right or up & down at same time:
    if (kc == keyMapping[KbInputHandler.KEY_LEFT])
      allKeysState[keyMapping[KbInputHandler.KEY_RIGHT]] = false;
    else if (kc == keyMapping[KbInputHandler.KEY_RIGHT])
      allKeysState[keyMapping[KbInputHandler.KEY_LEFT]] = false;
    else if (kc == keyMapping[KbInputHandler.KEY_UP])
      allKeysState[keyMapping[KbInputHandler.KEY_DOWN]] = false;
    else if (kc == keyMapping[KbInputHandler.KEY_DOWN])
      allKeysState[keyMapping[KbInputHandler.KEY_UP]] = false;
  }

  void keyReleased(KeyboardEvent ke) {
    //Util.printDebug('KbInputHandler.keyReleased(...): ${ke.keyIdentifier} (${ke.keyCode})', debugMe);

    int kc = ke.keyCode;
    if (kc >= allKeysState.length)
      return;

    allKeysState[kc] = false;

    if (id == 0) {
      switch (ke.$dom_keyIdentifier) {
        case 'F5': {
                     //Util.printDebug('KbInputHandler.keyReleased: Resetting game IF running.', debugMe);
                     // Reset game:
                     if (nes.isRunning()) {
                       //Util.printDebug('KbInputHandler.keyReleased: nes is Running', debugMe);
                       nes.stopEmulation();
                       nes.reset();
                       nes.reloadRom();
                       nes.startEmulation();
                     }
                     break;
                   }

        case 'F10': {
                      //Util.printDebug('KbInputHandler.keyReleased: Closing ROM', debugMe); 
                      // Just using this to display the battery RAM contents to user.
                      if (nes.rom != null)
                        nes.rom.closeRom();
                      break;
                    }

        case 'F12':
                    // TODO
                    // JOptionPane.showInputDialog("Save Code for Resuming Game.", "Test");
                    break;
      }// Ends switch (ke.keyIdentifier)
    }// Ends if (id == 0)
  }// Ends void keyReleased(KeyboardEvent ke)

  void keyTyped(KeyboardEvent ke) {
    // Ignore.
  }

  void reset() {
    allKeysState = Util.newBoolList(255, false);
  }

  void update() {
    // doesn't do anything.
  }

  void destroy() {
    nes = null;
  }

}
