 class AppletUI {

    Controller applet;
    NES nes;
    KbInputHandler kbJoy1;
    KbInputHandler kbJoy2;
    BufferView vScreen;
    int t1, t2;
    int sleepTime;

     AppletUI(Controller applet) {

        this.applet = applet;
        nes = new NES(this);
    }

     void init(bool showGui) {

        vScreen = new BufferView(nes, 256, 240);
        vScreen.init();

        kbJoy1 = new KbInputHandler(nes, 0);
        kbJoy2 = new KbInputHandler(nes, 1);

        /*
        // Grab Controller Setting for Player 1:
        kbJoy1.mapKey(InputHandler.KEY_A, 88);
        kbJoy1.mapKey(InputHandler.KEY_B, 90);
        kbJoy1.mapKey(InputHandler.KEY_START, 13);
        kbJoy1.mapKey(InputHandler.KEY_SELECT, 32);
        kbJoy1.mapKey(InputHandler.KEY_UP, 38);
        kbJoy1.mapKey(InputHandler.KEY_DOWN, 40);
        kbJoy1.mapKey(InputHandler.KEY_LEFT, 37);
        kbJoy1.mapKey(InputHandler.KEY_RIGHT, 39);
        vScreen.addKeyListener(kbJoy1);

        // Grab Controller Setting for Player 2:
        kbJoy2.mapKey(InputHandler.KEY_A, 0);
        kbJoy2.mapKey(InputHandler.KEY_B, 0);
        kbJoy2.mapKey(InputHandler.KEY_START, 0);
        kbJoy2.mapKey(InputHandler.KEY_SELECT, 0);
        kbJoy2.mapKey(InputHandler.KEY_UP, 0);
        kbJoy2.mapKey(InputHandler.KEY_DOWN, 0);
        kbJoy2.mapKey(InputHandler.KEY_LEFT, 0);
        kbJoy2.mapKey(InputHandler.KEY_RIGHT, 0);
        vScreen.addKeyListener(kbJoy2);
        */
    }

     void imageReady() {

        // Sound stuff:
        int tmp = nes.getPapu().bufferIndex;
        if (Globals.enableSound && Globals.timeEmulation && tmp > 0) {

            //int min_avail = nes.getPapu().line.getBufferSize() - 4 * tmp;

            //int timeToSleep = nes.papu.getMillisToAvailableAbove(min_avail);
            //applet.addSleepTime(timeToSleep);

            //nes.getPapu().writeBuffer();

          //TODO: Support sound
        }

        // Sleep a bit if sound is disabled:
        if (Globals.timeEmulation && !Globals.enableSound) {

            applet.addSleepTime(16);
        }

        // Update timer:
        t1 = t2;

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

     NES getNES() {
        return nes;
    }

     KbInputHandler getJoy1() {
       return kbJoy1;
   }

   KbInputHandler getJoy2() {
       return kbJoy2;
   }
   
     BufferView getScreenView() {
        return vScreen;
    }

     String getWindowCaption() {
        return "";
    }

     void setWindowCaption(String s) {
    }

     void setTitle(String s) {
    }

     int getWidth() {
        return 256;
    }

     int getHeight() {
        return 240;
    }

     void println(String s) {
    }

     void showErrorMsg(String msg) {
        print(msg);
    }
}