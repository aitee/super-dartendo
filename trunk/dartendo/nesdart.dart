#import('dart:dom');
#import('dart:json');
#import('dart:html', prefix:'html');
#import('dart:htmlimpl', prefix:'htmlimpl');

#source('AppletUI.dart');
#source('BufferView.dart');
#source('ByteBuffer.dart');
#source('ChannelDM.dart');
#source('ChannelNoise.dart');
#source('ChannelSquare.dart');
#source('ChannelTriangle.dart');
#source('Color.dart');
#source('CPU.dart');
#source('CpuInfo.dart');
#source('FileLoader.dart');
#source('Globals.dart');
#source('input.dart');
#source('KbInputHandler.dart');
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
#source('misc.dart');
#source('memory.dart');
#source('NameTable.dart');
#source('NES.dart');
#source('PaletteTable.dart');
#source('PAPU.dart');
#source('PapuChannel.dart');
#source('PPU.dart');
#source('ROM.dart');
#source('Tile.dart');
#source('Scale.dart');
#source('SourceDataLine.dart');
#source('UI.dart');
#source('Util.dart');

class Controller {
  var canvas;
  var context;

  bool scale = false;
  bool sound = false;
  bool fps = false;
  bool stereo = false;
  bool timeemulation = false;
  bool showsoundbuffer = false;
  
  int samplerate = 0;
  int romSize = 0;
  int progress = 0;
  
  AppletUI gui;
  NES nes;
  BufferView panelScreen;
  String rom;
  Color bgColor;
  bool started;
  
  int lastTime = 0;
  
  int sleepTime = 0;
  
  Controller() {
    Globals = new SGlobals();
    Util = new CUtil();
    Misc = new MiscClass();
    canvas = document.getElementById("webGlCanvas");
    context = canvas.getContext('2d');
     scale = false;
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
     sleepTime=0;
     init();
  }

   void init() {
     print("CALLED INIT");
     PaletteTable.init();
    readParams();

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
      print("SCALE NOT SUPPORTED");

            panelScreen.setScaleMode(BufferView.SCALE_NORMAL);

    } else {

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

    List<int> intList = Util.newIntList(5, 0);
    
    intList[3] = 2;
    print(intList);
    
    canvas.addEventListener('click', (Event e) {
      print('GOT EVENT');
    }, true);
    canvas.addEventListener('click', (Event e) {
      print('GOT EVENT');
    }, true);
    window.addEventListener('keydown', (Event e) {
      Expect.isTrue(e is KeyboardEvent);
      KeyboardEvent ke = e;
      print('GOT KEY DOWN EVENT ' + ke.keyIdentifier);
      gui.kbJoy1.keyPressed(ke);
    }, true);
    window.addEventListener('keyup', (Event e) {
      Expect.isTrue(e is KeyboardEvent);
      KeyboardEvent ke = e;
      print('GOT KEY UP EVENT ' + ke.keyIdentifier);
      gui.kbJoy1.keyReleased(ke);
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

}

 void showLoadProgress(int percentComplete) {

    progress = percentComplete;
}

 void readParams() {

    String tmp;

    tmp = "IceHockey.json";
    if (tmp == null || tmp == ("")) {
        rom = "vnes.nes";
    } else {
        rom = tmp;
    }

    tmp = "";
    if (tmp == null || tmp == ("")) {
        scale = false;
    } else {
        scale = tmp == ("on");
    }

    if (tmp == null || tmp == ("")) {
        sound = false; //TODO: Support sound
    } else {
        sound = tmp == ("on");
    }

    if (tmp == null || tmp == ("")) {
        stereo = true; // on by default
    } else {
        stereo = tmp == ("on");
    }

    if (tmp == null || tmp == ("")) {
        fps = true;
    } else {
        fps = tmp == ("on");
    }

    if (tmp == null || tmp == ("")) {
        timeemulation = true;
    } else {
        timeemulation = tmp == ("on");
    }

    if (tmp == null || tmp == ("")) {
        showsoundbuffer = false;
    } else {
        showsoundbuffer = tmp == ("on");
    }

    romSize = -1;
}

  void animate(int time) {
    //print("test: " + time);
    //canvas.width = canvas.width;

    if (nes.getCpu().stopRunning) {
      print('NOT RUNNING');
      nes.getCpu().finishRun();
      return;
    }

    while (true) {
      nes.getCpu().emulate();
      if (nes.getGui().getScreenView().frameFinished) {
        nes.getGui().getScreenView().finishFrame();
        break;
      }
    }
    lastTime = time;
    window.webkitRequestAnimationFrame(animate, canvas);
  }
  
  void addSleepTime(int timeToAdd) {
    sleepTime += timeToAdd;    
  }
}

void main() {
  Input input = new Input();
  input.init();
  new Controller().run();
}
