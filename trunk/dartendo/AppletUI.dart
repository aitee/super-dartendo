part of dartendo;

class AppletUI {

  bool debugMe = false;

  Controller applet;
  NES nes;
  KbInputHandler kbJoy1;
  KbInputHandler kbJoy2;
  BufferView vScreen;

  int t1 = 0;
  int t2 = 0;
  int sleepTime = 0;

  AppletUI(Controller applet) {
    this.applet = applet;
    nes = new NES(this);
  }

  void init(bool showGui) {

    vScreen = new BufferView(nes, 256, 240);
    vScreen.init();

    kbJoy1 = new KbInputHandler(nes, 0);
    kbJoy2 = new KbInputHandler(nes, 1);

    // Grab Controller Setting for Player 1:
    /*
    kbJoy1.mapKey(KbInputHandler.KEY_A, 88);
    kbJoy1.mapKey(KbInputHandler.KEY_B, 90);
    kbJoy1.mapKey(KbInputHandler.KEY_START, 13);
    kbJoy1.mapKey(KbInputHandler.KEY_SELECT, 77);
    kbJoy1.mapKey(KbInputHandler.KEY_UP, 73);
    kbJoy1.mapKey(KbInputHandler.KEY_DOWN, 75);
    kbJoy1.mapKey(KbInputHandler.KEY_LEFT, 74);
    kbJoy1.mapKey(KbInputHandler.KEY_RIGHT, 76);
    */
    kbJoy1.mapKey(KbInputHandler.KEY_A, 75);
    kbJoy1.mapKey(KbInputHandler.KEY_B, 74);
    kbJoy1.mapKey(KbInputHandler.KEY_START, 13);
    kbJoy1.mapKey(KbInputHandler.KEY_SELECT, 77);
    kbJoy1.mapKey(KbInputHandler.KEY_UP, 87);
    kbJoy1.mapKey(KbInputHandler.KEY_DOWN, 83);
    kbJoy1.mapKey(KbInputHandler.KEY_LEFT, 65);
    kbJoy1.mapKey(KbInputHandler.KEY_RIGHT, 68);

    kbJoy2.mapKey(KbInputHandler.KEY_A, 88);
    kbJoy2.mapKey(KbInputHandler.KEY_B, 90);
    kbJoy2.mapKey(KbInputHandler.KEY_START, 13);
    kbJoy2.mapKey(KbInputHandler.KEY_SELECT, 77);
    //kbJoy2.mapKey(KbInputHandler.KEY_UP, 38);
    //kbJoy2.mapKey(KbInputHandler.KEY_DOWN, 40);
    //kbJoy2.mapKey(KbInputHandler.KEY_LEFT, 37);
    //kbJoy2.mapKey(KbInputHandler.KEY_RIGHT, 39);
    kbJoy2.mapKey(KbInputHandler.KEY_UP, 73);
    kbJoy2.mapKey(KbInputHandler.KEY_DOWN, 75);
    kbJoy2.mapKey(KbInputHandler.KEY_LEFT, 74);
    kbJoy2.mapKey(KbInputHandler.KEY_RIGHT, 76);
  }

  int getRomFileSize() {
    return applet.romSize;
  }

  void showLoadProgress(int percentComplete) {

    // Show ROM load progress:
    applet.showLoadProgress(percentComplete);

  }

  void destroy() {

    nes = null;
    applet = null;
    kbJoy1 = null;
    kbJoy2 = null;
    vScreen = null;

  }

  NES getNES() => nes;

  KbInputHandler getJoy1() => kbJoy1;
  KbInputHandler getJoy2() => kbJoy2;

  BufferView getScreenView() => vScreen;

  String getWindowCaption() {
    return "";
  }

  int getWidth() => 256;
  int getHeight() => 240;
}
