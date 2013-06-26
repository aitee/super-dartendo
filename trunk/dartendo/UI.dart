part of dartendo;

abstract class UI {

     NES getNES();

     KbInputHandler getJoy1();

     KbInputHandler getJoy2();

     BufferView getScreenView();

     BufferView getPatternView();

     BufferView getSprPalView();

     BufferView getNameTableView();

     BufferView getImgPalView();

     void imageReady(bool skipFrame);

     void init(bool showGui);

     String getWindowCaption();

     void setWindowCaption(String s);

     void setTitle(String s);

     int getWidth();

     int getHeight();

     int getRomFileSize();

     void destroy();

     void println(String s);

     void showLoadProgress(int percentComplete);

     void showErrorMsg(String msg);
}