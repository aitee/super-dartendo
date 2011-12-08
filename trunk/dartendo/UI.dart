/*
vNES
Copyright © 2011 Occupy Nintendo

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General  License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General  License for more details.

You should have received a copy of the GNU General  License along with
this program.  If not, see <http://www.gnu.org/licenses/>.
 */

 interface UI {

     NES getNES();

     InputHandler getJoy1();

     InputHandler getJoy2();

     BufferView getScreenView();

     BufferView getPatternView();

     BufferView getSprPalView();

     BufferView getNameTableView();

     BufferView getImgPalView();

     HiResTimer getTimer();

     void imageReady(boolean skipFrame);

     void init(boolean showGui);

     String getWindowCaption();

     void setWindowCaption(String s);

     void setTitle(String s);

     Point getLocation();

     int getWidth();

     int getHeight();

     int getRomFileSize();

     void destroy();

     void println(String s);

     void showLoadProgress(int percentComplete);

     void showErrorMsg(String msg);
}