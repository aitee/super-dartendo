part of dartendo;

class BufferView {

  CanvasElement canvas;
  CanvasRenderingContext2D context;

  // Scale modes:
  static final int SCALE_NONE = 0;
  static final int SCALE_HW2X = 1;
  static final int SCALE_HW3X = 2;
  static final int SCALE_NORMAL = 3;
  static final int SCALE_SCANLINE = 4;
  static final int SCALE_RASTER = 5;

  NES nes;
  bool usingMenu = false;
  int width = 0;
  int height = 0;

  bool frameFinished = false;

  int skipFrame = 0;
  bool painted = false;

  // Constructor
  BufferView(NES nes, int width, int height) {
    canvas = document.query("#webGlCanvas");
    context = canvas.getContext('2d');

    this.nes = nes;
    this.width = width;
    this.height = height;
  }

  void setScaleMode(int newMode) {
    if (newMode != SCALE_NONE)
      print('SCALE NOT SUPPORTED, USING NO SCALE');
  }

  void init() {
    setScaleMode(SCALE_NONE);
  }

  void imageReady(bool shouldSkipFrame) {
    if (!Globals.focused)
      Globals.focused = true;

    // Skip image drawing if minimized or frameskipping:
    painted = false;
    if (!shouldSkipFrame) {
      //nes.ppu.requestRenderAll = false;
      painted = paint();
    }
    frameFinished = true;
  }

  void finishFrame() {
    if(!frameFinished) return;
    frameFinished = false;

    //if (notifyImageReady) {
    //}
  }

  bool paint() {
    // Skip if not needed:
    if (usingMenu)
      return false;

    skipFrame = (skipFrame+1)%100;

    if(nes.gui.applet.sleepTime <= -16) {
      //We are too far behind, skip the frame
      //print("SKIPPING RENDER");
      return false;
    }

    //if(skipFrame%2 != 0)
    //  return;

    //Util.printDebug('BufferView.paint: Getting imagedata', debugMe);
    ImageData imageData = context.getImageData(0,0,256,240);
    Uint8ClampedList data = imageData.data;
    //Util.printDebug('BufferView.paint: data.length = ' + data.length, debugMe);

    List<int> ppu_buffer = nes.ppu.buffer;       

    int ppui = 0;
    //Util.printDebug('BufferView.paint: setting pixels', debugLoop);
    for (var i = 0; i < 256*240*4;) {
      //Util.printDebug('BufferView.paint: Setting pixels, i = ' + i, debugMe);

      int val = ppu_buffer[ppui];

      // TODO: Are these masks needed now the array is Clamped type?
      data[i++] = val & 0xFF; // r
      data[i++] = (val>>8)  & 0xFF; // g
      data[i++] = (val>>16) & 0xFF; // b
      ppui++;
      data[i++] = 255; // a
    }
    //Util.printDebug('BufferView.paint(): Blitting imagedata', debugMe);
    context.putImageData(imageData, 0, 0, 0,   0, 256, 240);
    return true;
  }

  int getBufferWidth() {
    return width;
  }

  int getBufferHeight() {
    return height;
  }

  void setUsingMenu(bool val) {
    usingMenu = val;
  }

  int getScaleModeScale(int mode) {
    if (mode == -1) {
      return -1;
    } else if (mode == SCALE_NONE) {
      return 1;
    } else if (mode == SCALE_HW3X) {
      return 3;
    } else {
      return 2;
    }
  }

}
