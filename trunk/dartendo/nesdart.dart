#import('dart:html');
#import('dart:json');
#import('dart:htmlimpl');
#import('dart:dom', prefix:'dom');

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

  static final String _sendUrl = "http://dartendo.appspot.com/sendStatus";

  bool debugMe = false;

  CanvasElement canvas;
  CanvasRenderingContext context;
  Input input;
  
  bool scale = false;
  bool sound = false;
  bool fps = false;
  bool stereo = false;
  bool timeemulation = false;
  bool showsoundbuffer = false;
  bool _netplay = false;

  int matchid = 0;
  int playerid = 0;

  int samplerate = 0;
  int romSize = 0;
  int progress = 0;

  AppletUI gui;
  NES nes;
  BufferView panelScreen;
  Color bgColor;
  bool started;

  int lastTime = 0;
  int sleepTime = 0;
  int frameCount = 0;
  int _lastFrameCount = 0;

  Map<int, Map<String, int>> _netStatus;

  Controller() {
    Globals = new SGlobals();
    Util = new CUtil();
    Misc = new MiscClass();
    canvas = document.query("#webGlCanvas");
    context = canvas.getContext('2d');
    scale = false;
    sound = false;
    fps = false;
    stereo = false;
    timeemulation = false;
    showsoundbuffer = false;
    _netplay = false;
    matchid = 0;
    playerid = 0;
    samplerate = 0;
    romSize = 0;
    progress = 0;
    bgColor = new Color(0,0,0);
    started = false;
    lastTime = 0;
    sleepTime=0;
    _lastFrameCount = 0;
    frameCount = 0;
    _netStatus = new Map<int, Map<String, int>>();

    init();
  }

  void init() {
    Util.printDebug("nesdart.init(): begins", debugMe);
    PaletteTable.init();
    readParams();

    gui = new AppletUI(this);
    gui.init(false);

    Globals.appletMode = true;
    Globals.memoryFlushValue = 0x00; // make SMB1 hacked version work.

    nes = gui.getNES();
    nes.enableSound(sound);
    nes.reset();
    window.setInterval(_updateFps, 1000);
     
     input = new Input(nes);
     input.init();
  }

  void _updateFps() {
    document.query('#fps_counter').innerHTML =
      (frameCount - _lastFrameCount).toString();
    _lastFrameCount = frameCount;
  }

  void addScreenView() {
    Util.printDebug("nesdart.addScreenView(): begins", debugMe);

    panelScreen = gui.getScreenView();
    //panelScreen.setFPSEnabled(fps);

    if (scale) {
      Util.printDebug("nesdart.addScreenView(): SCALE NOT SUPPORTED!", debugMe);
      panelScreen.setScaleMode(BufferView.SCALE_NORMAL);
    }
  }

  void run() {

    // Can start painting:
    started = true;

    // Load ROM file:
    print("vNES 2.14 \u00A9 2006-2011 Jamie Sanders");
    print("For updates, see www.thatsanderskid.com");
    print("Use of this program subject to GNU GPL, Version 3.");

    nes.loadRom(input.romBytes);

    if (nes.rom.isValid()) {
      // Add the screen buffer:
      addScreenView();

      // Set some properties:
      Globals.timeEmulation = timeemulation;
      nes.ppu.showSoundBuffer = showsoundbuffer;

      // Start emulation:
      Util.printDebug("nesdart.run(): vNES is now starting the processor.", debugMe);
      nes.getCpu().beginExecution();

    } else {

      // ROM file was invalid.
      print("vNES was unable to find ROM.");

    }

    Util.printDebug("nesdart.run(): ROM LOADED", debugMe);
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

    List<int> intList = Util.newIntList(5, 0);

    intList[3] = 2;

    document.on.keyDown.add((Event e) {
        Expect.isTrue(e is KeyboardEvent);
        KeyboardEvent ke = e;
        gui.kbJoy1.keyPressed(ke);
        return false;
        }, true);
    document.on.keyUp.add((Event e) {
        Expect.isTrue(e is KeyboardEvent);
        KeyboardEvent ke = e;
        gui.kbJoy1.keyReleased(ke);
        return false;
        }, true);

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
  }

  void showLoadProgress(int percentComplete) {
    progress = percentComplete;
  }

  void readParams() {
    print("READING PARAMS");
    print(window.location.getParameter('rom'));
    String tmp = "";
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

    tmp = window.location.getParameter('netplay');
    if (tmp == null || tmp == ('')) {
      _netplay = false;
    } else {
      _netplay = (tmp == ('on'));
    }
    print('NETPLAY: '+_netplay);

    tmp = window.location.getParameter('matchid');
    if (tmp == null || tmp == ('')) {
      matchid = 0;
    } else {
      matchid = Math.parseInt(tmp);
    }

    tmp = window.location.getParameter('playerid');
    if (tmp == null || tmp == ('')) {
      playerid = 0;
    } else {
      playerid = Math.parseInt(tmp);
    }

    romSize = -1;
  }

  void animate(int time) {
    //print("nesdart.animate(" + time + ") begins.");

    if (nes.getCpu().stopRunning) {
      print('NOT RUNNING');
      nes.getCpu().finishRun();
      return;
    }

    int frameTime = time - lastTime;
    // Skip one frame to set lastTime and skip if too much time has passed since
    // the last frame.
    if(frameTime < 1000) {
      final BufferView screen = nes.getGui().getScreenView();
      final CPU cpu = nes.getCpu();
      while(sleepTime<=0) {
        //print('SLEEP TIME'+sleepTime);
        while(true) {
          if (_netplay)
            _sendStatus();
          if (!_netplay || _handleRemoteInput()) {
            cpu.emulate();
            if(screen.frameFinished) {
              ++frameCount;
              screen.finishFrame();
              break;
            }
          }
        }
        sleepTime += 16;
      }
      sleepTime -= frameTime;
      //print("FRAME TIME: "+(time-lastTime));
    } else {
      //print('SKIPPING FRAME');
    }
    lastTime = time;
    window.webkitRequestAnimationFrame(animate, canvas);
  }

  void _sendStatus() {
    final req = new XMLHttpRequest();
    String url = _sendUrl + '?matchid=' + matchid;
    url += '&playerid=' + playerid;
    url += '&framecount=' + frameCount;

    KbInputHandler joy = (playerid == 1 ? gui.kbJoy1 : gui.kbJoy2);

    url += '&left=' + joy.getKeyState(KbInputHandler.KEY_LEFT);
    url += '&right=' + joy.getKeyState(KbInputHandler.KEY_RIGHT);
    url += '&up=' + joy.getKeyState(KbInputHandler.KEY_UP);
    url += '&down=' + joy.getKeyState(KbInputHandler.KEY_DOWN);
    url += '&a=' + joy.getKeyState(KbInputHandler.KEY_A);
    url += '&b=' + joy.getKeyState(KbInputHandler.KEY_B);
    url += '&select=' + joy.getKeyState(KbInputHandler.KEY_SELECT);
    url += '&start=' + joy.getKeyState(KbInputHandler.KEY_START);
    req.open('GET', url, false);
    req.send();

    Map<String, Map<String, int>> resp = JSON.parse(req.responseText);
    resp.forEach((k, v) => _netStatus[Math.parseInt(k)] = v);
  }

  bool _handleRemoteInput() {
    if (!_netStatus.containsKey(frameCount))
      return false;
    Map<String, int> status = _netStatus[frameCount];
    KbInputHandler joy = (playerid == 1 ? gui.kbJoy2 : gui.kbJoy1);
    joy.setKeyState(KbInputHandler.KEY_LEFT, status['left']);
    joy.setKeyState(KbInputHandler.KEY_RIGHT, status['right']);
    joy.setKeyState(KbInputHandler.KEY_UP, status['up']);
    joy.setKeyState(KbInputHandler.KEY_DOWN, status['down']);
    joy.setKeyState(KbInputHandler.KEY_A, status['a']);
    joy.setKeyState(KbInputHandler.KEY_B, status['b']);
    joy.setKeyState(KbInputHandler.KEY_SELECT, status['select']);
    joy.setKeyState(KbInputHandler.KEY_START, status['start']);
  }

  void addSleepTime(int timeToAdd) {
    sleepTime += timeToAdd;    
  }
}

void main() {
  new Controller().run();
}
