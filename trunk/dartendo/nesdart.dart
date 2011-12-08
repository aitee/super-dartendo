#import('dart:dom');

#source('AppletUI.dart');
#source('BufferView.dart');
#source('ByteBuffer.dart');

#source('Util.dart');
#source('CPU.dart');
#source('CpuInfo.dart');

#source('FileLoader.dart');

#source('Color.dart');
#source('Globals.dart');
#source('KbInputHandler.dart');

#source('MapperDefault.dart');
#source('MemoryMapper.dart');
#source('Mapper001.dart');
#source('Mapper002.dart');
#source('Mapper003.dart');
#source('Mapper004.dart');
#source('Mapper007.dart');
#source('Mapper009.dart');
#source('Mapper010.dart');
#source('Mapper011.dart');
#source('Mapper015.dart');
#source('Mapper018.dart');
#source('Mapper021.dart');
#source('Mapper022.dart');
#source('Mapper023.dart');
#source('Mapper032.dart');
#source('Mapper033.dart');
#source('Mapper034.dart');
#source('Mapper048.dart');
#source('Mapper064.dart');
#source('Mapper066.dart');
#source('Mapper068.dart');
#source('Mapper071.dart');
#source('Mapper072.dart');
#source('Mapper075.dart');
#source('Mapper078.dart');
#source('Mapper079.dart');
#source('Mapper087.dart');
#source('Mapper094.dart');
#source('Mapper105.dart');
#source('Mapper140.dart');
#source('Mapper182.dart');
#source('MapperDefault.dart');
#source('Color.dart');
#source('Globals.dart');
#source('AppletUI.dart');
#source('KbInputHandler.dart');
#source('PaletteTable.dart');
#source('memory.dart');
#source('NES.dart');
#source('PaletteTable.dart');
#source('ROM.dart');
#source('Tile.dart');
#source('UI.dart');

class Controller {
  var canvas;
  var context;

  bool scale;
  bool scanlines;
  bool sound;
  bool fps;
  bool stereo;
  bool timeemulation;
  bool showsoundbuffer;
  int samplerate;
  int romSize;
  int progress;
  AppletUI gui;
  NES nes;
  BufferView panelScreen;
  String rom;
  Color bgColor;
  bool started;
  
  int lastTime;
  
  
  snes() {
    Globals = new SGlobals();
    canvas = document.getElementById("webGlCanvas");
    context = canvas.getContext('2d');
     scale = false;
     scanlines = false;
     sound = false;
     fps = false;
     stereo = false;
     timeemulation = false;
     showsoundbuffer = false;
     samplerate = 0;
     romSize = 0;
     progress = 0;
     rom = "";
     bgColor = new Color(0,0,0);
     started = false;
     lastTime = 0;
  }

   void init() {
    readParams();
    System.gc();

    gui = new AppletUI(this);
    gui.init(false);

    Globals.appletMode = true;
    Globals.memoryFlushValue = 0x00; // make SMB1 hacked version work.

    nes = gui.getNES();
    nes.enableSound(sound);
    nes.reset();

}

 void addScreenView() {
  print("ADD SCREEN VIEW");

    panelScreen = gui.getScreenView();
    panelScreen.setFPSEnabled(fps);

    if (scale) {
      print("SCALE");

        if (scanlines) {
            panelScreen.setScaleMode(BufferView.SCALE_SCANLINE);
        } else {
            panelScreen.setScaleMode(BufferView.SCALE_NORMAL);
        }

    } else {

        panelScreen.setBounds(0, 0, 256, 240);

    }

}

 void run() {

    // Can start painting:
    started = true;

    // Load ROM file:
    print("vNES 2.14 \u00A9 2006-2011 Jamie Sanders");
    print("For updates, see www.thatsanderskid.com");
    print("Use of this program subject to GNU GPL, Version 3.");

    nes.loadRom(rom);

    if (nes.rom.isValid()) {

        // Add the screen buffer:
        addScreenView();

        // Set some properties:
        Globals.timeEmulation = timeemulation;
        nes.ppu.showSoundBuffer = showsoundbuffer;

        // Start emulation:
        //print("vNES is now starting the processor.");
        nes.getCpu().beginExecution();

    } else {

        // ROM file was invalid.
        print("vNES was unable to find (" + rom + ").");

    }
    
    print("ROM LOADED");
    nes.getCpu().initRun();
    nes.getCpu().active = true;
    
    
    //var ac = window.webkitAudioContext();
    //audioContext = new AudioContext();
    
    //var src = audioContext.createBufferSource();
    //src.buffer = audioContext.createBuffer(1 /*channels*/, 2048, 44100);
    //var audioData = src.buffer.getChannelData(0);
    //print(audioData.length);
    //src.looping = true;

    //src.connect(audioContext.destination);

    //src.noteOn(0);
    
    //var audioElement = document.createElement('audio');
    //var ac = audioElement.context();
    //audioElement.setAttribute('src', 'sample.ogg');
    //audioElement.play();
    
    int x = 3;
    int y = x & 4;
    print(y);
    
    switch(x) {
    case 1:
      print('1');
      break;
    case 3:
      print('3');
      break;
    }

    List<int> intList = new List<int>(5);
    
    intList[3] = 2;
    print(intList);
    
    canvas.addEventListener('click', (Event e) {
      print('GOT EVENT');
    }, true);
    canvas.addEventListener('click', (Event e) {
      print('GOT EVENT');
    }, true);
    window.addEventListener('keydown', (Event e) {
      print('GOT KEY DOWN EVENT ' + e.keyCode);
    }, true);
    window.addEventListener('keyup', (Event e) {
      print('GOT KEY UP EVENT ' + e.keyCode);
    }, true);
    //element.on.keyUp.add( (EventListener event) { 
      //print('KEY RELEASED'); }); 

    window.webkitRequestAnimationFrame(animate, canvas);
}

 void stop() {
   nes.getCpu().active = false;
    nes.stopEmulation();
    print("vNES has stopped the processor.");
    nes.getPapu().stop();
    this.destroy();

}

 void destroy() {

    if (nes != null && nes.getCpu().isRunning()) {
        stop();
    }
    
    if (nes != null) {
        nes.destroy();
    }
    if (gui != null) {
        gui.destroy();
    }

    gui = null;
    nes = null;
    panelScreen = null;
    rom = null;

    System.runFinalization();
    System.gc();

}

 void showLoadProgress(int percentComplete) {

    progress = percentComplete;
}

 void readParams() {

    String tmp;

    tmp = "IceHockey.nes";
    if (tmp == null || tmp.equals("")) {
        rom = "vnes.nes";
    } else {
        rom = tmp;
    }

    tmp = "";
    if (tmp == null || tmp.equals("")) {
        scale = true;
    } else {
        scale = tmp.equals("on");
    }

    if (tmp == null || tmp.equals("")) {
        sound = true;
    } else {
        sound = tmp.equals("on");
    }

    if (tmp == null || tmp.equals("")) {
        stereo = true; // on by default
    } else {
        stereo = tmp.equals("on");
    }

    if (tmp == null || tmp.equals("")) {
        scanlines = false;
    } else {
        scanlines = tmp.equals("on");
    }

    if (tmp == null || tmp.equals("")) {
        fps = true;
    } else {
        fps = tmp.equals("on");
    }

    if (tmp == null || tmp.equals("")) {
        timeemulation = true;
    } else {
        timeemulation = tmp.equals("on");
    }

    if (tmp == null || tmp.equals("")) {
        showsoundbuffer = false;
    } else {
        showsoundbuffer = tmp.equals("on");
    }

    /* Controller Setup for Player 1 */

    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p1_up", "VK_UP");
    } else {
        Globals.controls.put("p1_up", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p1_down", "VK_DOWN");
    } else {
        Globals.controls.put("p1_down", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p1_left", "VK_LEFT");
    } else {
        Globals.controls.put("p1_left", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p1_right", "VK_RIGHT");
    } else {
        Globals.controls.put("p1_right", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p1_a", "VK_X");
    } else {
        Globals.controls.put("p1_a", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p1_b", "VK_Z");
    } else {
        Globals.controls.put("p1_b", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p1_start", "VK_ENTER");
    } else {
        Globals.controls.put("p1_start", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p1_select", "VK_CONTROL");
    } else {
        Globals.controls.put("p1_select", "VK_" + tmp);
    }

    /* Controller Setup for Player 2 */

    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p2_up", "VK_NUMPAD8");
    } else {
        Globals.controls.put("p2_up", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p2_down", "VK_NUMPAD2");
    } else {
        Globals.controls.put("p2_down", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p2_left", "VK_NUMPAD4");
    } else {
        Globals.controls.put("p2_left", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p2_right", "VK_NUMPAD6");
    } else {
        Globals.controls.put("p2_right", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p2_a", "VK_NUMPAD7");
    } else {
        Globals.controls.put("p2_a", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p2_b", "VK_NUMPAD9");
    } else {
        Globals.controls.put("p2_b", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p2_start", "VK_NUMPAD1");
    } else {
        Globals.controls.put("p2_start", "VK_" + tmp);
    }
    if (tmp == null || tmp.equals("")) {
        Globals.controls.put("p2_select", "VK_NUMPAD3");
    } else {
        Globals.controls.put("p2_select", "VK_" + tmp);
    }

    if (tmp == null || tmp.equals("")) {
        romSize = -1;
    } else {
        try {
            romSize = Integer.parseInt(tmp);
        } catch (Exception e) {
            romSize = -1;
        }
    }
}

  void animate(int time) {
    //print("test: " + time);
    //canvas.width = canvas.width;
    
    
    
            if (nes.getCpu().stopRunning) {
              return;
            }

            nes.getCpu().emulate();
            nes.getCpu().finishRun();
    lastTime = time;
    window.webkitRequestAnimationFrame(animate, canvas);
  }
}

void main() {
  new Controller().run();
}
