class BufferView {

  var canvas;
  var context;
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
     
     List<int> pix;
     List<int> pix_scaled;
     int scaleMode = 0;
     
     // FPS counter variables:
     bool showFPS = false;
     int prevFrameTime = 0;
     String fps;
     int fpsCounter = 0;
     bool notifyImageReady = false;
     bool frameFinished = false;

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
       if (newMode != SCALE_NONE) {
       print('SCALE NOT SUPPORTED, USING NO SCALE');
       }
       scaleMode = SCALE_NONE;
    }

     void init() {
        setScaleMode(SCALE_NONE);
    }

     void imageReady(bool skipFrame) {
       if (!Globals.focused) {
         Globals.focused = true;
       }

       // Skip image drawing if minimized or frameskipping:
       if (!skipFrame) {
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
     
     List<int> getBuffer() => pix;

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