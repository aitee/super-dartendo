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
    keyMapping = Util.newIntList(KbInputHandler.NUM_KEYS, 0);
    print('[KbInputHandler] initialized');
  }

  int getKeyState(int padKey) {
    if(allKeysState[keyMapping[padKey]]) {
      return 0x41;
    } else {
      return 0x40;
    }
  }

  void mapKey(int padKey, int kbKeycode) {
    print('[KbInputHandler] Mapping $padKey to $kbKeycode');
    keyMapping[padKey] = kbKeycode;
  }

  void keyPressed(KeyboardEvent ke) {
    print('[KbInputHandler] keyPressed: ${ke.keyIdentifier} (${ke.keyCode})')
    int kc = ke.keyCode;
    if (kc >= allKeysState.length)
      return;

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
    print('[KbInputHandler] keyReleased: ${ke.keyIdentifier} (${ke.keyCode})')

  int kc = ke.keyCode;
  if (kc >= allKeysState.length)
    return;

  allKeysState[kc] = false;

  if (id == 0) {
    switch (ke.keyIdentifier) {
    case KeyName.F5: {
      print('[KbInputHandler] Resetting game');
      // Reset game:
      if (nes.isRunning()) {
          nes.stopEmulation();
          nes.reset();
          nes.reloadRom();
          nes.startEmulation();
      }
      break;
    }
    
    case KeyName.F10: {
      print('[KbInputHandler] Closing ROM');
      // Just using this to display the battery RAM contents to user.
      if (nes.rom != null)
        nes.rom.closeRom();
      break;
    }
    
    case KeyName.F12:
      // TODO
      // JOptionPane.showInputDialog("Save Code for Resuming Game.", "Test");
      break;
    }
  }

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