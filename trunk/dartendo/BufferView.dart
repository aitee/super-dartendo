class BufferView {

  var canvas;
  var context;
    // Scale modes:
      final int SCALE_NONE = 0;
      final int SCALE_HW2X = 1;
      final int SCALE_HW3X = 2;
      final int SCALE_NORMAL = 3;
      final int SCALE_SCANLINE = 4;
      final int SCALE_RASTER = 5;
     NES nes;
     bool usingMenu = false;
     int width;
     int height;
     List<int> pix;
     List<int> pix_scaled;
     int scaleMode;
    // FPS counter variables:
     bool showFPS = false;
     long prevFrameTime;
     String fps;
     int fpsCounter;

    // Constructor
     BufferView(NES nes, int width, int height) {
       canvas = document.getElementById("webGlCanvas");
       context = canvas.getContext('2d');

        this.nes = nes;
        this.width = width;
        this.height = height;
        this.scaleMode = -1;

    }

     void setScaleMode(int newMode) {

        if (newMode != scaleMode) {

            // Check differences:
            bool diffHW = useHWScaling(newMode) != useHWScaling(scaleMode);
            bool diffSz = getScaleModeScale(newMode) != getScaleModeScale(scaleMode);

            // Change scale mode:
            this.scaleMode = newMode;

            if (diffHW || diffSz) {
            }

        }

    }

     void init() {

        setScaleMode(SCALE_NONE);

    }

     void imageReady(bool skipFrame) {
       if (!Globals.focused) {
         setFocusable(true);
         requestFocus();
         Globals.focused = true;
     }

        // Skip image drawing if minimized or frameskipping:
        if (!skipFrame) {

            if (scaleMode != SCALE_NONE) {

                if (scaleMode == SCALE_NORMAL) {

                    Scale.doNormalScaling(pix, pix_scaled, nes.ppu.scanlineChanged);

                } else if (scaleMode == SCALE_SCANLINE) {

                    Scale.doScanlineScaling(pix, pix_scaled, nes.ppu.scanlineChanged);

                } else if (scaleMode == SCALE_RASTER) {

                    Scale.doRasterScaling(pix, pix_scaled, nes.ppu.scanlineChanged);

                }
            }

            nes.ppu.requestRenderAll = false;
            paint();

        }

        frameFinished = true;
    }
    
     void finishFrame() {
       if(!frameFinished) return;
       frameFinished=false;

         // Notify GUI, so it can write the sound buffer:
         if (notifyImageReady) {
             nes.getGui().imageReady();
         }
      
    }

     bool scalingEnabled() {
        return scaleMode != SCALE_NONE;
    }

     int getScaleMode() {
        return scaleMode;
    }

     bool useNormalScaling() {
        return (scaleMode == SCALE_NORMAL);
    }

     void paint() {

        // Skip if not needed:
        if (usingMenu) {
            return;
        }

        //JJG: TODO: DRAW NES HERE
        
        //print('Getting imagedata');
        var arr = context.getImageData(0,0,150,50);
        var data = arr.data;
        //print(data.length);
        for (var i=0;i<150*50*4;) {
          //print('Setting pixels');
          data[i++] = 0; // r
          data[i++] = 0; // g
          data[i++] = 0; // b
          data[i++] = 255; // a
        }
        //print('Blitting imagedata');
        var a = 1;
        var b = 2;
        var c = a ~/ b;
        //print(c);
        context.putImageData(arr, 0, 0, 0,   0, 150, 50);

    }

     void setFPSEnabled(bool val) {

        // Whether to show FPS count.
        showFPS = val;

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

     bool useHWScaling() {
        return useHWScaling(scaleMode);
    }

     bool useHWScalingWithMode(int mode) {
        return false;
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

     void destroy() {

        nes = null;
        img = null;

    }
}