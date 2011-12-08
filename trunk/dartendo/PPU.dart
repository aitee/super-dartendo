class PPU {
  NES nes;
  Memory ppuMem;
  Memory sprMem;
  
  // Rendering Options:
  bool _showSpr0Hit = false;
  bool _showSoundBuffer = false;
  bool _clipTVcolumn = true;
  bool _clipTVrow = false;

  // Control Flags Register 1:
  int f_nmiOnVblank = 0;    // NMI on VBlank. 0=disable, 1=enable
  int f_spriteSize = 0;     // Sprite size. 0=8x8, 1=8x16
  int f_bgPatternTable = 0; // Background Pattern Table address. 0=0x0000,1=0x1000
  int f_spPatternTable = 0; // Sprite Pattern Table address. 0=0x0000,1=0x1000
  int f_addrInc = 0;        // PPU Address Increment. 0=1,1=32
  int f_nTblAddress = 0;    // Name Table Address. 0=0x2000,1=0x2400,2=0x2800,3=0x2C00
  
  // Control Flags Register 2:
  int f_color = 0;          // Background color. 0=black, 1=blue, 2=green, 4=red
  int f_spVisibility = 0;   // Sprite visibility. 0=not displayed,1=displayed
  int f_bgVisibility = 0;   // Background visibility. 0=Not Displayed,1=displayed
  int f_spClipping = 0;     // Sprite clipping. 0=Sprites invisible in left 8-pixel column,1=No clipping
  int f_bgClipping = 0;     // Background clipping. 0=BG invisible in left 8-pixel column, 1=No clipping
  int f_dispType = 0;       // Display type. 0=color, 1=monochrome
  
  // Status flags:
  static final int _STATUS_VRAMWRITE = 4;
  static final int _STATUS_SLSPRITECOUNT = 5;
  static final int _STATUS_SPRITE0HIT = 6;
  static final int _STATUS_VBLANK = 7;

  // VRAM I/O:
  int _vramAddress = 0;
  int _vramTmpAddress = 0;
  int _vramBufferedReadValue = 0;
  bool _firstWrite = true;    // VRAM/Scroll Hi/Lo latch
  List<int> _vramMirrorTable; // Mirroring Lookup Table.


  // SPR-RAM I/O:
  int _sramAddress = 0; // 8-bit only.

  // Counters:
  int _cntFV = 0;
  int _cntV = 0;
  int _cntH = 0;
  int _cntVT = 0;
  int _cntHT = 0;

  // Registers:
  int _regFV = 0;
  int _regV = 0;
  int _regH = 0;
  int _regVT = 0;
  int _regHT = 0;
  int _regFH = 0;
  int _regS = 0;

  // VBlank extension for PAL emulation:
  int _vblankAdd = 0;
  int curX = 0;
  int scanline = 0;
  int lastRenderedScanline = 0;
  int mapperIrqCounter = 0;
  
  // Sprite data:
  List<int> sprX;        // X coordinate
  List<int> sprY;        // Y coordinate
  List<int> sprTile;     // Tile Index (into pattern table)
  List<int> sprCol;      // Upper two bits of color
  List<bool> vertFlip;    // Vertical Flip
  List<bool> horiFlip;    // Horizontal Flip
  List<bool> bgPriority;  // Background priority
  int spr0HitX = 0;  // Sprite #0 hit X coordinate
  int spr0HitY = 0;  // Sprite #0 hit Y coordinate
  bool hitSpr0 = false;

  // Tiles:
  List<Tile> ptTile;
  
  // Name table data:
  List<int> _ntable1;
  List<NameTable> _nameTable;
  int _currentMirroring = -1;

  // Palette data:
  List<int> _sprPalette;
  List<int> _imgPalette;
    
  // Misc:
  bool _scanlineAlreadyRendered = false;
  bool _requestEndFrame = false;
  bool _nmiOk = false;
  int _nmiCounter = 0;
  int _tmp = 0;
  bool _dummyCycleToggle = false;

  // Vars used when updating regs/address:
  int _address = 0;
  int _b1 = 0;
  int _b2 = 0;
    
  // Variables used when rendering:
  List<int> buffer;
  List<int> _tpix;
  bool requestRenderAll = false;
  bool _validTileData = false;
  int _att = 0;
  List<Tile> _scantile;
  List<int> _attrib;
  List<int> _bgbuffer;
  List<int> _pixrendered;
  List<int> _spr0dummybuffer;
  List<int> _dummyPixPriTable;
  List<int> _oldFrame;
  List<bool> _scanlineChanged;
  Tile _t;

  // These are temporary variables used in rendering and sound procedures.
  // Their states outside of those procedures can be ignored.
  int _curNt = 0;
  int _destIndex = 0;
  int _x = 0;
  int _y = 0;
  int _sx = 0;
  int _si = 0;
  int _ei = 0;
  int _tile = 0;
  int _col = 0;
  int _baseTile = 0;
  int _tscanoffset = 0;
  int _srcy1 = 0;
  int _srcy2 = 0;
  int bufferSize = 0;
  int _available = 0; 
  int _scale = 0;
  int cycles = 0;

  PPU(this.nes) {
    _ntable1 = Util.newIntList(4,0);
    
    _sprPalette = Util.newIntList(16,0);
    _imgPalette = Util.newIntList(16,0);
    
    _scantile = new List<Tile>(32);
    _attrib = Util.newIntList(32,0);
    _bgbuffer = Util.newIntList(256 * 240,0);
    _pixrendered = Util.newIntList(256 * 240,0);
    _spr0dummybuffer = Util.newIntList(256 * 240,0);
    _dummyPixPriTable = Util.newIntList(256 * 240,0);
    _oldFrame = Util.newIntList(256 * 240,0);
    _scanlineChanged = Util.newBoolList(240, false);
  }

  void init() {
    // Get the memory:
    ppuMem = nes.getPpuMemory();
    sprMem = nes.getSprMemory();

    updateControlReg1(0);
    updateControlReg2(0);

    // Initialize misc vars:
    scanline = 0;
    
    // Create sprite arrays:
    sprX = new List<int>(64);
    sprY = new List<int>(64);
    sprTile = new List<int>(64);
    sprCol = new List<int>(64);
    vertFlip = new List<bool>(64);
    horiFlip = new List<bool>(64);
    bgPriority = new List<bool>(64);

    // Create pattern table tile buffers:
    if (ptTile == null) {
      ptTile = new List<Tile>(512);
      for (int i = 0; i < 512; i++) {
        ptTile[i] = new Tile();
      }
    }

    // Create nametable buffers:
    _nameTable = new List<NameTable>(4);
    for (int i = 0; i < 4; i++) {
      _nameTable[i] = new NameTable(32, 32, "Nt" + i);
    }

    // Initialize mirroring lookup table:
    _vramMirrorTable = Util.newIntList(0x8000, 0);
    for (int i = 0; i < 0x8000; i++) {
      _vramMirrorTable[i] = i;
    }

    lastRenderedScanline = -1;
    curX = 0;

    // Initialize old frame buffer:
    for (int i = 0; i < _oldFrame.length; i++) {
      _oldFrame[i] = -1;
    }
  }

  // Sets Nametable mirroring.
  void setMirroring(int mirroring) {
    if (mirroring == _currentMirroring) {
      return;
    }

    _currentMirroring = mirroring;
    triggerRendering();

    // Remove mirroring:
    if (_vramMirrorTable == null) {
      _vramMirrorTable = new List<int>(0x8000);
    }
    for (int i = 0; i < 0x8000; i++) {
      _vramMirrorTable[i] = i;
    }

    // Palette mirroring:
    defineMirrorRegion(0x3f20, 0x3f00, 0x20);
    defineMirrorRegion(0x3f40, 0x3f00, 0x20);
    defineMirrorRegion(0x3f80, 0x3f00, 0x20);
    defineMirrorRegion(0x3fc0, 0x3f00, 0x20);

    // Additional mirroring:
    defineMirrorRegion(0x3000, 0x2000, 0xf00);
    defineMirrorRegion(0x4000, 0x0000, 0x4000);

    if (mirroring == ROM.HORIZONTAL_MIRRORING) {
      // Horizontal mirroring.
      _ntable1[0] = 0;
      _ntable1[1] = 0;
      _ntable1[2] = 1;
      _ntable1[3] = 1;

      defineMirrorRegion(0x2400, 0x2000, 0x400);
      defineMirrorRegion(0x2c00, 0x2800, 0x400);
    } else if (mirroring == ROM.VERTICAL_MIRRORING) {
      // Vertical mirroring.
      _ntable1[0] = 0;
      _ntable1[1] = 1;
      _ntable1[2] = 0;
      _ntable1[3] = 1;
            
      defineMirrorRegion(0x2800, 0x2000, 0x400);      
      defineMirrorRegion(0x2c00, 0x2400, 0x400);
    } else if (mirroring == ROM.SINGLESCREEN_MIRRORING) {
      // Single Screen mirroring
      _ntable1[0] = 0;
      _ntable1[1] = 0;
      _ntable1[2] = 0;
      _ntable1[3] = 0;

      defineMirrorRegion(0x2400, 0x2000, 0x400);
      defineMirrorRegion(0x2800, 0x2000, 0x400);
      defineMirrorRegion(0x2c00, 0x2000, 0x400);
    } else if (mirroring == ROM.SINGLESCREEN_MIRRORING2) {
      _ntable1[0] = 1;
      _ntable1[1] = 1;
      _ntable1[2] = 1;
      _ntable1[3] = 1;

      defineMirrorRegion(0x2400, 0x2400, 0x400);
      defineMirrorRegion(0x2800, 0x2400, 0x400);
      defineMirrorRegion(0x2c00, 0x2400, 0x400);
    } else {
      // Assume Four-screen mirroring.

      _ntable1[0] = 0;
      _ntable1[1] = 1;
      _ntable1[2] = 2;
      _ntable1[3] = 3;
    }
  }

  // Define a mirrored area in the address lookup table.
  // Assumes the regions don't overlap.
  // The 'to' region is the region that is physically in memory.
  void defineMirrorRegion(int fromStart, int toStart, int size) {
    for (int i = 0; i < size; i++) {
      _vramMirrorTable[fromStart + i] = toStart + i;
    }
  }

  // Emulates PPU cycles
  void emulateCycles() {
    //int n = (!_requestEndFrame && curX+cycles<341 && (scanline-20 < spr0HitY || scanline-22 > spr0HitY))?cycles:1;
    for (; cycles > 0; cycles--) {
      if (scanline - 21 == spr0HitY) {
        if ((curX == spr0HitX) && (f_spVisibility == 1)) {
          // Set sprite 0 hit flag:
          setStatusFlag(_STATUS_SPRITE0HIT, true);
        }
      }
      if (_requestEndFrame) {
        _nmiCounter--;
        if (_nmiCounter == 0) {
          _requestEndFrame = false;
          startVBlank();
        }
      }
      curX++;
      if (curX == 341) {
        curX = 0;
        endScanline();
      }
    }
  }

  void startVBlank() {
    // Start VBlank period:
    // Do VBlank.
    if (Globals.debug) {
      Globals.println("VBlank occurs!");
    }

    // Do NMI:
    nes.getCpu().requestIrq(CPU.IRQ_NMI);

    // Make sure everything is rendered:
    if (lastRenderedScanline < 239) {
      renderFramePartially(nes.gui.getScreenView().getBuffer(), lastRenderedScanline + 1, 240 - lastRenderedScanline);
    }

    endFrame();

    // Notify image buffer:
    nes.getGui().getScreenView().imageReady(false);

    // Reset scanline counter:
    lastRenderedScanline = -1;

    startFrame();
  }

  void endScanline() {
    if (scanline < 19 + _vblankAdd) {
      // VINT
      // do nothing.
    } else if (scanline == 19 + _vblankAdd) {
      // Dummy scanline.
      // May be variable length:
      if (_dummyCycleToggle) {
        // Remove dead cycle at end of scanline,
        // for next scanline:
        curX = 1;
        _dummyCycleToggle = !_dummyCycleToggle;
      }
    } else if (scanline == 20 + _vblankAdd) {
      // Clear VBlank flag:
      setStatusFlag(_STATUS_VBLANK, false);

      // Clear Sprite #0 hit flag:
      setStatusFlag(_STATUS_SPRITE0HIT, false);
      hitSpr0 = false;
      spr0HitX = -1;
      spr0HitY = -1;

      if (f_bgVisibility == 1 || f_spVisibility == 1) {
        // Update counters:
        _cntFV = _regFV;
        _cntV = _regV;
        _cntH = _regH;
        _cntVT = _regVT;
        _cntHT = _regHT;

        if (f_bgVisibility == 1) {
          // Render dummy scanline:
          renderBgScanline(buffer, 0);
        }
      }

      if (f_bgVisibility == 1 && f_spVisibility == 1) {
        // Check sprite 0 hit for first scanline:
        checkSprite0(0);
      }

      if (f_bgVisibility == 1 || f_spVisibility == 1) {
        // Clock mapper IRQ Counter:
        nes.memMapper.clockIrqCounter();
      }
    } else if (scanline >= 21 + _vblankAdd && scanline <= 260) {
      // Render normally:
      if (f_bgVisibility == 1) {
        if (!_scanlineAlreadyRendered) {
          // update scroll:
          _cntHT = _regHT;
          _cntH = _regH;
          renderBgScanline(_bgbuffer, scanline + 1 - 21);
        }
        _scanlineAlreadyRendered = false;
        
        // Check for sprite 0 (next scanline):
        if (!hitSpr0 && f_spVisibility == 1) {
          if (sprX[0] >= -7 && sprX[0] < 256 && sprY[0] + 1 <= (scanline - _vblankAdd + 1 - 21) && (sprY[0] + 1 + (f_spriteSize == 0 ? 8 : 16)) >= (scanline - _vblankAdd + 1 - 21)) {
            if (checkSprite0(scanline + _vblankAdd + 1 - 21)) {
              ////System.out.println("found spr0. curscan="+scanline+" hitscan="+spr0HitY);
              hitSpr0 = true;
            }
          }
        }
      }
       
      if (f_bgVisibility == 1 || f_spVisibility == 1) {
        // Clock mapper IRQ Counter:
        nes.memMapper.clockIrqCounter();
      }
    } else if (scanline == 261 + _vblankAdd) {
      // Dead scanline, no rendering.
      // Set VINT:
      setStatusFlag(_STATUS_VBLANK, true);
      _requestEndFrame = true;
      _nmiCounter = 9;

      // Wrap around:
      scanline = -1;  // will be incremented to 0
    }
    scanline++;
    regsToAddress();
    cntsToAddress();
  }

  void startFrame() {
    List<int> buffer = nes.getGui().getScreenView().getBuffer();

    // Set background color:
    int bgColor = 0;

    if (f_dispType == 0) {
      // Color display.
      // f_color determines color emphasis.
      // Use first entry of image palette as BG color.
      bgColor = _imgPalette[0];
    } else {
      // Monochrome display.
      // f_color determines the bg color.
      switch (f_color) {
        case 0: {
          // Black
          bgColor = 0x00000;
          break;
        }
        case 1: {
          // Green
          bgColor = 0x00FF00;
        }
        case 2: {
          // Blue
          bgColor = 0xFF0000;
        }
        case 3: {
          // Invalid. Use black.
          bgColor = 0x000000;
        }
        case 4: {
          // Red
          bgColor = 0x0000FF;
        }
        default: {
          // Invalid. Use black.
          bgColor = 0x0;
        }
      }
    }

    for (int i = 0; i < buffer.length; i++) {
      buffer[i] = bgColor;
    }
    for (int i = 0; i < _pixrendered.length; i++) {
      _pixrendered[i] = 65;
    }
  }

  void endFrame() {
    List<int> buffer = nes.getGui().getScreenView().getBuffer();

    // Draw spr#0 hit coordinates:
    if (_showSpr0Hit) {
      // Spr 0 position:
      if (sprX[0] >= 0 && sprX[0] < 256 && sprY[0] >= 0 && sprY[0] < 240) {
        for (int i = 0; i < 256; i++) {
            buffer[(sprY[0] << 8) + i] = 0xFF5555;
        }
        for (int i = 0; i < 240; i++) {
            buffer[(i << 8) + sprX[0]] = 0xFF5555;
        }
      }
      // Hit position:
      if (spr0HitX >= 0 && spr0HitX < 256 && spr0HitY >= 0 && spr0HitY < 240) {
        for (int i = 0; i < 256; i++) {
            buffer[(spr0HitY << 8) + i] = 0x55FF55;
        }
        for (int i = 0; i < 240; i++) {
            buffer[(i << 8) + spr0HitX] = 0x55FF55;
        }
      }
    }

    // This is a bit lazy..
    // if either the sprites or the background should be clipped,
    // both are clipped after rendering is finished.
    if (_clipTVcolumn || f_bgClipping == 0 || f_spClipping == 0) {
      // Clip left 8-pixels column:
      for (int y = 0; y < 240; y++) {
        for (int x = 0; x < 8; x++) {
          buffer[(y << 8) + x] = 0;
        }
      }
    }

    if (_clipTVcolumn) {
      // Clip right 8-pixels column too:
      for (int y = 0; y < 240; y++) {
        for (int x = 0; x < 8; x++) {
          buffer[(y << 8) + 255 - x] = 0;
        }
      }
    }

    // Clip top and bottom 8 pixels:
    if (_clipTVrow) {
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 256; x++) {
          buffer[(y << 8) + x] = 0;
          buffer[((239 - y) << 8) + x] = 0;
        }
      }
    }

    // Show sound buffer:
    if (_showSoundBuffer && nes.getPapu().getLine() != null) {
      bufferSize = nes.getPapu().getLine().getBufferSize();
      _available = nes.getPapu().getLine().available();
      _scale = bufferSize ~/ 256;

      for (int y = 0; y < 4; y++) {
        _scanlineChanged[y] = true;
        for (int x = 0; x < 256; x++) {
          if (x >= (_available / _scale)) {
            buffer[y * 256 + x] = 0xFFFFFF;
          } else {
            buffer[y * 256 + x] = 0;
          }
        }
      }
    }
  }

  void updateControlReg1(int value) {
    triggerRendering();

    f_nmiOnVblank = (value >> 7) & 1;
    f_spriteSize = (value >> 5) & 1;
    f_bgPatternTable = (value >> 4) & 1;
    f_spPatternTable = (value >> 3) & 1;
    f_addrInc = (value >> 2) & 1;
    f_nTblAddress = value & 3;

    _regV = (value >> 1) & 1;
    _regH = value & 1;
    _regS = (value >> 4) & 1;
  }

  void updateControlReg2(int value) {
    triggerRendering();

    f_color = (value >> 5) & 7;
    f_spVisibility = (value >> 4) & 1;
    f_bgVisibility = (value >> 3) & 1;
    f_spClipping = (value >> 2) & 1;
    f_bgClipping = (value >> 1) & 1;
    f_dispType = value & 1;

    if (f_dispType == 0) {
        nes.palTable.setEmphasis(f_color);
    }
    updatePalettes();
  }

  void setStatusFlag(int flag, bool value) {
    int n = 1 << flag;
    int memValue = nes.getCpuMemory().load(0x2002);
    memValue = ((memValue & (255 - n)) | (value ? n : 0));
    nes.getCpuMemory().write(0x2002,  memValue);
  }

  // CPU Register $2002:
  // Read the Status Register.
  int readStatusRegister() {
    _tmp = nes.getCpuMemory().load(0x2002);

    // Reset scroll & VRAM Address toggle:
    _firstWrite = true;

    // Clear VBlank flag:
    setStatusFlag(_STATUS_VBLANK, false);

    // Fetch status data:
    return _tmp;
  }

  // CPU Register $2003:
  // Write the SPR-RAM address that is used for sramWrite (Register 0x2004 in CPU memory map)
  void writeSRAMAddress(int address) {
    _sramAddress = address;
  }

  // CPU Register $2004 (R):
  // Read from SPR-RAM (Sprite RAM).
  // The address should be set first.
  int sramLoad() {
    int tmp = sprMem.load(_sramAddress);
    /*_sramAddress++; // Increment address
    _sramAddress%=0x100;*/
    return tmp;
  }
   
  // CPU Register $2004 (W):
  // Write to SPR-RAM (Sprite RAM).
  // The address should be set first.
  void sramWrite(int value) {
    sprMem.write(_sramAddress, value);
    spriteRamWriteUpdate(_sramAddress, value);
    _sramAddress++; // Increment address
    _sramAddress %= 0x100;
  }

  // CPU Register $2005:
  // Write to scroll registers.
  // The first write is the vertical offset, the second is the
  // horizontal offset:
  void scrollWrite(int value) {
    triggerRendering();
    if (_firstWrite) {
      // First write, horizontal scroll:
      _regHT = (value >> 3) & 31;
      _regFH = value & 7;
    } else {
      // Second write, vertical scroll:
      _regFV = value & 7;
      _regVT = (value >> 3) & 31;
    }
    _firstWrite = !_firstWrite;
  }

  // CPU Register $2006:
  // Sets the adress used when reading/writing from/to VRAM.
  // The first write sets the high byte, the second the low byte.
  void writeVRAMAddress(int address) {
    if (_firstWrite) {
      _regFV = (address >> 4) & 3;
      _regV = (address >> 3) & 1;
      _regH = (address >> 2) & 1;
      _regVT = (_regVT & 7) | ((address & 3) << 3);
    } else {
      triggerRendering();

      _regVT = (_regVT & 24) | ((address >> 5) & 7);
      _regHT = address & 31;

      _cntFV = _regFV;
      _cntV = _regV;
      _cntH = _regH;
      _cntVT = _regVT;
      _cntHT = _regHT;

      checkSprite0(scanline - _vblankAdd + 1 - 21);
    }
    _firstWrite = !_firstWrite;

    // Invoke mapper latch:
    cntsToAddress();
    if (_vramAddress < 0x2000) {
      nes.memMapper.latchAccess(_vramAddress);
    }
  }

  // CPU Register $2007(R):
  // Read from PPU memory. The address should be set first.
  int vramLoad() {
    cntsToAddress();
    regsToAddress();

    // If address is in range 0x0000-0x3EFF, return buffered values:
    if (_vramAddress <= 0x3EFF) {
      int tmp = _vramBufferedReadValue;

      // Update buffered value:
      if (_vramAddress < 0x2000) {
        _vramBufferedReadValue = ppuMem.load(_vramAddress);
      } else {
        _vramBufferedReadValue = mirroredLoad(_vramAddress);
      }

      // Mapper latch access:
      if (_vramAddress < 0x2000) {
        nes.memMapper.latchAccess(_vramAddress);
      }

      // Increment by either 1 or 32, depending on d2 of Control Register 1:
      _vramAddress += (f_addrInc == 1 ? 32 : 1);

      cntsFromAddress();
      regsFromAddress();
      return tmp; // Return the previous buffered value.
    }

    // No buffering in this mem range. Read normally.
    int tmp = mirroredLoad(_vramAddress);

    // Increment by either 1 or 32, depending on d2 of Control Register 1:
    _vramAddress += (f_addrInc == 1 ? 32 : 1);

    cntsFromAddress();
    regsFromAddress();

    return tmp;
  }

  // CPU Register $2007(W):
  // Write to PPU memory. The address should be set first.
  void vramWrite(int value) {
    triggerRendering();
    cntsToAddress();
    regsToAddress();

    if (_vramAddress >= 0x2000) {
      // Mirroring is used.
      mirroredWrite(_vramAddress, value);
    } else {
      // Write normally.
      writeMem(_vramAddress, value);

      // Invoke mapper latch:
      nes.memMapper.latchAccess(_vramAddress);
    }

    // Increment by either 1 or 32, depending on d2 of Control Register 1:
    _vramAddress += (f_addrInc == 1 ? 32 : 1);
    regsFromAddress();
    cntsFromAddress();
  }

  // CPU Register $4014:
  // Write 256 bytes of main memory
  // into Sprite RAM.
  void sramDMA(int value) {
    Memory cpuMem = nes.getCpuMemory();
    int baseAddress = value * 0x100;
    int data;
    for (int i = _sramAddress; i < 256; i++) {
      data = cpuMem.load(baseAddress + i);
      sprMem.write(i, data);
      spriteRamWriteUpdate(i, data);
    }

    nes.getCpu().haltCycles(513);
  }

  // Updates the scroll registers from a new VRAM address.
  void regsFromAddress() {
    _address = (_vramTmpAddress >> 8) & 0xFF;
    _regFV = (_address >> 4) & 7;
    _regV = (_address >> 3) & 1;
    _regH = (_address >> 2) & 1;
    _regVT = (_regVT & 7) | ((_address & 3) << 3);

    _address = _vramTmpAddress & 0xFF;
    _regVT = (_regVT & 24) | ((_address >> 5) & 7);
    _regHT = _address & 31;
  }

  // Updates the scroll registers from a new VRAM address.
  void cntsFromAddress() {
    _address = (_vramAddress >> 8) & 0xFF;
    _cntFV = (_address >> 4) & 3;
    _cntV = (_address >> 3) & 1;
    _cntH = (_address >> 2) & 1;
    _cntVT = (_cntVT & 7) | ((_address & 3) << 3);

    _address = _vramAddress & 0xFF;
    _cntVT = (_cntVT & 24) | ((_address >> 5) & 7);
    _cntHT = _address & 31;
  }

  void regsToAddress() {
    _b1 = (_regFV & 7) << 4;
    _b1 |= (_regV & 1) << 3;
    _b1 |= (_regH & 1) << 2;
    _b1 |= (_regVT >> 3) & 3;

    _b2 = (_regVT & 7) << 5;
    _b2 |= _regHT & 31;

    _vramTmpAddress = ((_b1 << 8) | _b2) & 0x7FFF;
  }

  void cntsToAddress() {
    _b1 = (_cntFV & 7) << 4;
    _b1 |= (_cntV & 1) << 3;
    _b1 |= (_cntH & 1) << 2;
    _b1 |= (_cntVT >> 3) & 3;

    _b2 = (_cntVT & 7) << 5;
    _b2 |= _cntHT & 31;

    _vramAddress = ((_b1 << 8) | _b2) & 0x7FFF;
  }

  void incTileCounter(int count) {
    for (int i = count; i != 0; i--) {
      _cntHT++;
      if (_cntHT == 32) {
        _cntHT = 0;
        _cntVT++;
        if (_cntVT >= 30) {
          _cntH++;
          if (_cntH == 2) {
            _cntH = 0;
            _cntV++;
            if (_cntV == 2) {
              _cntV = 0;
              _cntFV++;
              _cntFV &= 0x7;
            }
          }
        }
      }
    }
  }

  // Reads from memory, taking into account
  // mirroring/mapping of address ranges.
  int mirroredLoad(int address) {
    return ppuMem.load(_vramMirrorTable[address]);
  }

  // Writes to memory, taking into account
  // mirroring/mapping of address ranges.
  void mirroredWrite(int address, int value) {
    if (address >= 0x3f00 && address < 0x3f20) {
      // Palette write mirroring.

      if (address == 0x3F00 || address == 0x3F10) {
        writeMem(0x3F00, value);
        writeMem(0x3F10, value);
      } else if (address == 0x3F04 || address == 0x3F14) {
        writeMem(0x3F04, value);
        writeMem(0x3F14, value);
      } else if (address == 0x3F08 || address == 0x3F18) {
        writeMem(0x3F08, value);
        writeMem(0x3F18, value);
      } else if (address == 0x3F0C || address == 0x3F1C) {
        writeMem(0x3F0C, value);
        writeMem(0x3F1C, value);
      } else {
        writeMem(address, value);
      }
    } else {
      // Use lookup table for mirrored address:
      if (address < _vramMirrorTable.length) {
        writeMem(_vramMirrorTable[address], value);
      } else {
        if (Globals.debug) {
          //System.out.println("Invalid VRAM address: "+Misc.hex16(address));
          nes.getCpu().setCrashed(true);
        }
      }
    }
  }

  void triggerRendering() {
    if (scanline - _vblankAdd >= 21 && scanline - _vblankAdd <= 260) {
      // Render sprites, and combine:
      renderFramePartially(buffer, lastRenderedScanline + 1, scanline - _vblankAdd - 21 - lastRenderedScanline);

      // Set last rendered scanline:
      lastRenderedScanline = scanline - _vblankAdd - 21;
    }
  }

  void renderFramePartially(List<int> buffer, int startScan, int scanCount) {
    if (f_spVisibility == 1 && !Globals.disableSprites) {
      renderSpritesPartially(startScan, scanCount, true);
    }
     
    if (f_bgVisibility == 1) {
      _si = startScan << 8;
      _ei = (startScan + scanCount) << 8;
      if (_ei > 0xF000) {
        _ei = 0xF000;
      }
      for (_destIndex = _si; _destIndex < _ei; _destIndex++) {
        if (_pixrendered[_destIndex] > 0xFF) {
          buffer[_destIndex] = _bgbuffer[_destIndex];
        }
      }
    }

    if (f_spVisibility == 1 && !Globals.disableSprites) {
      renderSpritesPartially(startScan, scanCount, false);
    }

    BufferView screen = nes.getGui().getScreenView();
    if (screen.scalingEnabled() && /*!screen.useHWScaling() &&*/ !requestRenderAll) {
      // Check which scanlines have changed, to try to
      // speed up scaling:
      int j, jmax;
      if (startScan + scanCount > 240) {
        scanCount = 240 - startScan;
      }
      for (int i = startScan; i < startScan + scanCount; i++) {
        _scanlineChanged[i] = false;
        _si = i << 8;
        jmax = _si + 256;
        for (j = _si; j < jmax; j++) {
          if (buffer[j] != _oldFrame[j]) {
            _scanlineChanged[i] = true;
            break;
          }
          _oldFrame[j] = buffer[j];
        }
        for (int k = j; k < jmax; ++k)
          _oldFrame[k] = buffer[k];
      }
    }

    _validTileData = false;
  }

  void renderBgScanline(List<int> buffer, int scan) {
    _baseTile = (_regS == 0 ? 0 : 256);
    _destIndex = (scan << 8) - _regFH;
    _curNt = _ntable1[_cntV + _cntV + _cntH];

    _cntHT = _regHT;
    _cntH = _regH;
    _curNt = _ntable1[_cntV + _cntV + _cntH];

    if (scan < 240 && (scan - _cntFV) >= 0) {
      _tscanoffset = _cntFV << 3;
      _y = scan - _cntFV;
      for (_tile = 0; _tile < 32; _tile++) {
        if (scan >= 0) {
          // Fetch tile & attrib data:
          if (_validTileData) {
            // Get data from array:
            _t = _scantile[_tile];
            _tpix = _t.pix;
            _att = _attrib[_tile];
          } else {
            // Fetch data:
            _t = ptTile[_baseTile + _nameTable[_curNt].getTileIndex(_cntHT, _cntVT)];
            _tpix = _t.pix;
            _att = _nameTable[_curNt].getAttrib(_cntHT, _cntVT);
            _scantile[_tile] = _t;
            _attrib[_tile] = _att;
          }

          // Render tile scanline:
          _sx = 0;
          _x = (_tile << 3) - _regFH;
          if (_x > -8) {
            if (_x < 0) {
              _destIndex -= _x;
              _sx = -_x;
            }
            if (_t.opaque[_cntFV]) {
              for (; _sx < 8; _sx++) {
                buffer[_destIndex] = _imgPalette[_tpix[_tscanoffset + _sx] + _att];
                _pixrendered[_destIndex] |= 256;
                _destIndex++;
              }
            } else {
              for (; _sx < 8; _sx++) {
                  _col = _tpix[_tscanoffset + _sx];
                  if (_col != 0) {
                    buffer[_destIndex] = _imgPalette[_col + _att];
                    _pixrendered[_destIndex] |= 256;
                  }
                _destIndex++;
              }
            }
          }
        }

        // Increase Horizontal Tile Counter:
        _cntHT++;
        if (_cntHT == 32) {
          _cntHT = 0;
          _cntH++;
          _cntH %= 2;
          _curNt = _ntable1[(_cntV << 1) + _cntH];
        }
      }
      // Tile data for one row should now have been fetched,
      // so the data in the array is valid.
      _validTileData = true;
    }

    // update vertical scroll:
    _cntFV++;
    if (_cntFV == 8) {
      _cntFV = 0;
      _cntVT++;
      if (_cntVT == 30) {
        _cntVT = 0;
        _cntV++;
        _cntV %= 2;
        _curNt = _ntable1[(_cntV << 1) + _cntH];
      } else if (_cntVT == 32) {
        _cntVT = 0;
      }

      // Invalidate fetched data:
      _validTileData = false;
    }
  }

  void renderSpritesPartially(int startscan, int scancount, bool bgPri) {
    buffer = nes.getGui().getScreenView().getBuffer();
    if (f_spVisibility == 1) {
      int sprT1, sprT2;

      for (int i = 0; i < 64; i++) {
        if (bgPriority[i] == bgPri && sprX[i] >= 0 && sprX[i] < 256 && sprY[i] + 8 >= startscan && sprY[i] < startscan + scancount) {
          // Show sprite.
          if (f_spriteSize == 0) {
            // 8x8 sprites
            _srcy1 = 0;
            _srcy2 = 8;

            if (sprY[i] < startscan) {
              _srcy1 = startscan - sprY[i] - 1;
            }

            if (sprY[i] + 8 > startscan + scancount) {
              _srcy2 = startscan + scancount - sprY[i] + 1;
            }

            if (f_spPatternTable == 0) {
              ptTile[sprTile[i]].render(0, _srcy1, 8, _srcy2, sprX[i], sprY[i] + 1, buffer, sprCol[i], _sprPalette, horiFlip[i], vertFlip[i], i, _pixrendered);
            } else {
              ptTile[sprTile[i] + 256].render(0, _srcy1, 8, _srcy2, sprX[i], sprY[i] + 1, buffer, sprCol[i], _sprPalette, horiFlip[i], vertFlip[i], i, _pixrendered);
            }
          } else {
            // 8x16 sprites
            int top = sprTile[i];
            if ((top & 1) != 0) {
              top = sprTile[i] - 1 + 256;
            }

            _srcy1 = 0;
            _srcy2 = 8;

            if (sprY[i] < startscan) {
              _srcy1 = startscan - sprY[i] - 1;
            }

            if (sprY[i] + 8 > startscan + scancount) {
              _srcy2 = startscan + scancount - sprY[i];
            }

            ptTile[top + (vertFlip[i] ? 1 : 0)].render(0, _srcy1, 8, _srcy2, sprX[i], sprY[i] + 1, buffer, sprCol[i], _sprPalette, horiFlip[i], vertFlip[i], i, _pixrendered);

            _srcy1 = 0;
            _srcy2 = 8;

            if (sprY[i] + 8 < startscan) {
              _srcy1 = startscan - (sprY[i] + 8 + 1);
            }

            if (sprY[i] + 16 > startscan + scancount) {
              _srcy2 = startscan + scancount - (sprY[i] + 8);
            }

            ptTile[top + (vertFlip[i] ? 0 : 1)].render(0, _srcy1, 8, _srcy2, sprX[i], sprY[i] + 1 + 8, buffer, sprCol[i], _sprPalette, horiFlip[i], vertFlip[i], i, _pixrendered);
          }
        }
      }
    }
  }

  bool checkSprite0(int scan) {
    spr0HitX = -1;
    spr0HitY = -1;

    int toffset;
    int tIndexAdd = (f_spPatternTable == 0 ? 0 : 256);
    int x, y;
    int bufferIndex;
    int col;
    bool bgPri;
    Tile t;

    x = sprX[0];
    y = sprY[0] + 1;

    if (f_spriteSize == 0) {
      // 8x8 sprites.

      // Check range:
      if (y <= scan && y + 8 > scan && x >= -7 && x < 256) {
        // Sprite is in range.
        // Draw scanline:
        t = ptTile[sprTile[0] + tIndexAdd];
        col = sprCol[0];
        bgPri = bgPriority[0];

        if (vertFlip[0]) {
          toffset = 7 - (scan - y);
        } else {
          toffset = scan - y;
        }
        toffset *= 8;

        bufferIndex = scan * 256 + x;
        if (horiFlip[0]) {
          for (int i = 7; i >= 0; i--) {
            if (x >= 0 && x < 256) {
              if (bufferIndex >= 0 && bufferIndex < 61440 && _pixrendered[bufferIndex] != 0) {
                if (t.pix[toffset + i] != 0) {
                  spr0HitX = bufferIndex % 256;
                  spr0HitY = scan;
                  return true;
                }
              }
            }
            x++;
            bufferIndex++;
          }
        } else {
          for (int i = 0; i < 8; i++) {
            if (x >= 0 && x < 256) {
              if (bufferIndex >= 0 && bufferIndex < 61440 && _pixrendered[bufferIndex] != 0) {
                if (t.pix[toffset + i] != 0) {
                  spr0HitX = bufferIndex % 256;
                  spr0HitY = scan;
                  return true;
                }
              }
            }
            x++;
            bufferIndex++;
          }
        }
      }
    } else {
      // 8x16 sprites:
      
      // Check range:
      if (y <= scan && y + 16 > scan && x >= -7 && x < 256) {
        // Sprite is in range.
        // Draw scanline:
        if (vertFlip[0]) {
          toffset = 15 - (scan - y);
        } else {
          toffset = scan - y;
        }

        if (toffset < 8) {
          // first half of sprite.
          t = ptTile[sprTile[0] + (vertFlip[0] ? 1 : 0) + ((sprTile[0] & 1) != 0 ? 255 : 0)];
        } else {
          // second half of sprite.
          t = ptTile[sprTile[0] + (vertFlip[0] ? 0 : 1) + ((sprTile[0] & 1) != 0 ? 255 : 0)];
          if (vertFlip[0]) {
            toffset = 15 - toffset;
          } else {
            toffset -= 8;
          }
        }
        toffset *= 8;
        col = sprCol[0];
        bgPri = bgPriority[0];

        bufferIndex = scan * 256 + x;
        if (horiFlip[0]) {
          for (int i = 7; i >= 0; i--) {
            if (x >= 0 && x < 256) {
              if (bufferIndex >= 0 && bufferIndex < 61440 && _pixrendered[bufferIndex] != 0) {
                if (t.pix[toffset + i] != 0) {
                  spr0HitX = bufferIndex % 256;
                  spr0HitY = scan;
                  return true;
                }
              }
            }
            x++;
            bufferIndex++;
          }
        } else {
          for (int i = 0; i < 8; i++) {
            if (x >= 0 && x < 256) {
              if (bufferIndex >= 0 && bufferIndex < 61440 && _pixrendered[bufferIndex] != 0) {
                if (t.pix[toffset + i] != 0) {
                  spr0HitX = bufferIndex % 256;
                  spr0HitY = scan;
                  return true;
                }
              }
            }
            x++;
            bufferIndex++;
          }
        }
      }
    }
    return false;
  }

  // Renders the contents of the
  // pattern table into an image.
  void renderPattern() {
    BufferView scr = nes.getGui().getPatternView();
    List<int> buffer = scr.getBuffer();

    int tIndex = 0;
    for (int j = 0; j < 2; j++) {
      for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
          ptTile[tIndex].renderSimple(j * 128 + x * 8, y * 8, buffer, 0, _sprPalette);
          tIndex++;
        }
      }
    }
    nes.getGui().getPatternView().imageReady(false);
  }

  void renderNameTables() {
    List<int> buffer = nes.getGui().getNameTableView().getBuffer();
    if (f_bgPatternTable == 0) {
      _baseTile = 0;
    } else {
      _baseTile = 256;
    }

    int ntx_max = 2;
    int nty_max = 2;

    if (_currentMirroring == ROM.HORIZONTAL_MIRRORING) {
      ntx_max = 1;
    } else if (_currentMirroring == ROM.VERTICAL_MIRRORING) {
      nty_max = 1;
    }

    for (int nty = 0; nty < nty_max; nty++) {
      for (int ntx = 0; ntx < ntx_max; ntx++) {
        int nt = _ntable1[nty * 2 + ntx];
        int x = ntx * 128;
        int y = nty * 120;

        // Render nametable:
        for (int ty = 0; ty < 30; ty++) {
          for (int tx = 0; tx < 32; tx++) {
            //ptTile[baseTile+_nameTable[nt].getTileIndex(tx,ty)].render(0,0,4,4,x+tx*4,y+ty*4,buffer,_nameTable[nt].getAttrib(tx,ty),imgPalette,false,false,0,dummyPixPriTable);
            ptTile[_baseTile + _nameTable[nt].getTileIndex(tx, ty)].renderSmall(x + tx * 4, y + ty * 4, buffer, _nameTable[nt].getAttrib(tx, ty), _imgPalette);
          }
        }
      }
    }
    
    if (_currentMirroring == ROM.HORIZONTAL_MIRRORING) {
      // double horizontally:
      for (int y = 0; y < 240; y++) {
        for (int x = 0; x < 128; x++) {
          buffer[(y << 8) + 128 + x] = buffer[(y << 8) + x];
        }
      }
    } else if (_currentMirroring == ROM.VERTICAL_MIRRORING) {
      // double vertically:
      for (int y = 0; y < 120; y++) {
        for (int x = 0; x < 256; x++) {
          buffer[(y << 8) + 0x7800 + x] = buffer[(y << 8) + x];
        }
      }
    }

    nes.getGui().getNameTableView().imageReady(false);
  }

  void renderPalettes() {
    List<int> buffer = nes.getGui().getImgPalView().getBuffer();
    for (int i = 0; i < 16; i++) {
      for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
          buffer[y * 256 + i * 16 + x] = _imgPalette[i];
        }
      }
    }

    buffer = nes.getGui().getSprPalView().getBuffer();
    for (int i = 0; i < 16; i++) {
      for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
          buffer[y * 256 + i * 16 + x] = _sprPalette[i];
        }
      }
    }

    nes.getGui().getImgPalView().imageReady(false);
    nes.getGui().getSprPalView().imageReady(false);
  }

  // This will write to PPU memory, and
  // update internally buffered data
  // appropriately.
  void writeMem(int address, int value) {
    ppuMem.write(address, value);

    // Update internally buffered data:
    if (address < 0x2000) {
      ppuMem.write(address, value);
      patternWrite(address, value);
    } else if (address >= 0x2000 && address < 0x23c0) {
      nameTableWrite(_ntable1[0], address - 0x2000, value);
    } else if (address >= 0x23c0 && address < 0x2400) {
      attribTableWrite(_ntable1[0], address - 0x23c0, value);
    } else if (address >= 0x2400 && address < 0x27c0) {
      nameTableWrite(_ntable1[1], address - 0x2400, value);
    } else if (address >= 0x27c0 && address < 0x2800) {
      attribTableWrite(_ntable1[1], address - 0x27c0, value);
    } else if (address >= 0x2800 && address < 0x2bc0) {
      nameTableWrite(_ntable1[2], address - 0x2800, value);
    } else if (address >= 0x2bc0 && address < 0x2c00) {
      attribTableWrite(_ntable1[2], address - 0x2bc0, value);
    } else if (address >= 0x2c00 && address < 0x2fc0) {
      nameTableWrite(_ntable1[3], address - 0x2c00, value);
    } else if (address >= 0x2fc0 && address < 0x3000) {
      attribTableWrite(_ntable1[3], address - 0x2fc0, value);
    } else if (address >= 0x3f00 && address < 0x3f20) {
      updatePalettes();
    }
  }

  // Reads data from $3f00 to $f20
  // into the two buffered palettes.
  void updatePalettes() {
    for (int i = 0; i < 16; i++) {
      if (f_dispType == 0) {
        _imgPalette[i] = nes.palTable.getEntry(ppuMem.load(0x3f00 + i) & 63);
      } else {
        _imgPalette[i] = nes.palTable.getEntry(ppuMem.load(0x3f00 + i) & 32);
      }
    }
    for (int i = 0; i < 16; i++) {
      if (f_dispType == 0) {
        _sprPalette[i] = nes.palTable.getEntry(ppuMem.load(0x3f10 + i) & 63);
      } else {
        _sprPalette[i] = nes.palTable.getEntry(ppuMem.load(0x3f10 + i) & 32);
      }
    }

    //renderPalettes();
  }

  // Updates the internal pattern
  // table buffers with this new byte.
  void patternWrite(int address, Object value, [int offset, int length]) {
    if (value is int) {
      int tileIndex = address ~/ 16;
      int leftOver = address % 16;
      if (leftOver < 8) {
        ptTile[tileIndex].setScanline(leftOver, value, ppuMem.load(address + 8));
      } else {
        ptTile[tileIndex].setScanline(leftOver - 8, ppuMem.load(address - 8), value);
      }      
    } else {
      Expect.isTrue(value is List<int>);
      Expect.isTrue(offset !== null);
      Expect.isTrue(length !== null);
      
      List<int> valueList = value;
      
      for (int i = 0; i < length; i++) {
        int tileIndex = (address + i) >> 4;
        int leftOver = (address + i) % 16;

        if (leftOver < 8) {
            ptTile[tileIndex].setScanline(leftOver, valueList[offset + i], ppuMem.load(address + 8 + i));
        } else {
            ptTile[tileIndex].setScanline(leftOver - 8, ppuMem.load(address - 8 + i), valueList[offset + i]);
        }
      }
    }
  }

  void invalidateFrameCache() {
    // Clear the no-update scanline buffer:
    for (int i = 0; i < 240; i++) {
      _scanlineChanged[i] = true;
    }
    _oldFrame.forEach((e) => e = -1);
    requestRenderAll = true;
  }

  // Updates the internal name table buffers
  // with this new byte.
  void nameTableWrite(int index, int address, int value) {
    _nameTable[index].writeTileIndex(address, value);

    // Update Sprite #0 hit:
    //updateSpr0Hit();
    checkSprite0(scanline + 1 - _vblankAdd - 21);
  }

  // Updates the internal pattern
  // table buffers with this new attribute
  // table byte.
  void attribTableWrite(int index, int address, int value) {
    _nameTable[index].writeAttrib(address, value);
  }

  // Updates the internally buffered sprite
  // data with this new byte of info.
  void spriteRamWriteUpdate(int address, int value) {
    int tIndex = address ~/ 4;

    if (tIndex == 0) {
      //updateSpr0Hit();
      checkSprite0(scanline + 1 - _vblankAdd - 21);
    }

    if (address % 4 == 0) {
      // Y coordinate
      sprY[tIndex] = value;
    } else if (address % 4 == 1) {
      // Tile index
      sprTile[tIndex] = value;
    } else if (address % 4 == 2) {
      // Attributes
      vertFlip[tIndex] = ((value & 0x80) != 0);
      horiFlip[tIndex] = ((value & 0x40) != 0);
      bgPriority[tIndex] = ((value & 0x20) != 0);
      sprCol[tIndex] = (value & 3) << 2;
    } else if (address % 4 == 3) {
      // X coordinate
      sprX[tIndex] = value;
    }
  }

  void doNMI() {
    // Set VBlank flag:
    setStatusFlag(_STATUS_VBLANK, true);
    //nes.getCpu().doNonMaskableInterrupt();
    nes.getCpu().requestIrq(CPU.IRQ_NMI);
  }

  int statusRegsToInt() {
    int ret = 0;
    ret = (f_nmiOnVblank) |
            (f_spriteSize << 1) |
            (f_bgPatternTable << 2) |
            (f_spPatternTable << 3) |
            (f_addrInc << 4) |
            (f_nTblAddress << 5) |
            (f_color << 6) |
            (f_spVisibility << 7) |
            (f_bgVisibility << 8) |
            (f_spClipping << 9) |
            (f_bgClipping << 10) |
            (f_dispType << 11);

    return ret;
  }

  void statusRegsFromInt(int n) {
    f_nmiOnVblank = (n) & 0x1;
    f_spriteSize = (n >> 1) & 0x1;
    f_bgPatternTable = (n >> 2) & 0x1;
    f_spPatternTable = (n >> 3) & 0x1;
    f_addrInc = (n >> 4) & 0x1;
    f_nTblAddress = (n >> 5) & 0x1;

    f_color = (n >> 6) & 0x1;
    f_spVisibility = (n >> 7) & 0x1;
    f_bgVisibility = (n >> 8) & 0x1;
    f_spClipping = (n >> 9) & 0x1;
    f_bgClipping = (n >> 10) & 0x1;
    f_dispType = (n >> 11) & 0x1;
  }

  void stateLoad(ByteBuffer buf) {
    // Check version:
    if (buf.readByte() == 1) {
      // Counters:
      _cntFV = buf.readInt();
      _cntV = buf.readInt();
      _cntH = buf.readInt();
      _cntVT = buf.readInt();
      _cntHT = buf.readInt();

      // Registers:
      _regFV = buf.readInt();
      _regV = buf.readInt();
      _regH = buf.readInt();
      _regVT = buf.readInt();
      _regHT = buf.readInt();
      _regFH = buf.readInt();
      _regS = buf.readInt();

      // VRAM address:
      _vramAddress = buf.readInt();
      _vramTmpAddress = buf.readInt();

      // Control/Status registers:
      statusRegsFromInt(buf.readInt());

      // VRAM I/O:
      _vramBufferedReadValue =  buf.readInt();
      _firstWrite = buf.readBoolean();
      //System.out.println("_firstWrite: "+_firstWrite);

      // Mirroring:
      //_currentMirroring = -1;
      //setMirroring(buf.readInt());
      for (int i = 0; i < _vramMirrorTable.length; i++) {
        _vramMirrorTable[i] = buf.readInt();
      }

      // SPR-RAM I/O:
      _sramAddress =  buf.readInt();

      // Rendering progression:
      curX = buf.readInt();
      scanline = buf.readInt();
      lastRenderedScanline = buf.readInt();

      // Misc:
      _requestEndFrame = buf.readBoolean();
      _nmiOk = buf.readBoolean();
      _dummyCycleToggle = buf.readBoolean();
      _nmiCounter = buf.readInt();
      _tmp =  buf.readInt();

      // Stuff used during rendering:
      for (int i = 0; i < _bgbuffer.length; i++) {
        _bgbuffer[i] = buf.readByte();
      }
      for (int i = 0; i < _pixrendered.length; i++) {
        _pixrendered[i] = buf.readByte();
      }

      // Name tables:
      for (int i = 0; i < 4; i++) {
        _ntable1[i] = buf.readByte();
        _nameTable[i].stateLoad(buf);
      }

      // Pattern data:
      for (int i = 0; i < ptTile.length; i++) {
        ptTile[i].stateLoad(buf);
      }

      // Update internally stored stuff from VRAM memory:
      /*List<int> mem = ppuMem.mem;

      // Palettes:
      for(int i=0x3f00;i<0x3f20;i++){
      writeMem(i,mem[i]);
      }
       */
      // Sprite data:
      List<int> sprmem = nes.getSprMemory().mem;
      for (int i = 0; i < sprmem.length; i++) {
        spriteRamWriteUpdate(i, sprmem[i]);
      }
    }
  }

  void stateSave(ByteBuffer buf) {
    // Version:
    buf.putByte( 1);

    // Counters:
    buf.putInt(_cntFV);
    buf.putInt(_cntV);
    buf.putInt(_cntH);
    buf.putInt(_cntVT);
    buf.putInt(_cntHT);

    // Registers:
    buf.putInt(_regFV);
    buf.putInt(_regV);
    buf.putInt(_regH);
    buf.putInt(_regVT);
    buf.putInt(_regHT);
    buf.putInt(_regFH);
    buf.putInt(_regS);

    // VRAM address:
    buf.putInt(_vramAddress);
    buf.putInt(_vramTmpAddress);

    // Control/Status registers:
    buf.putInt(statusRegsToInt());

    // VRAM I/O:
    buf.putInt(_vramBufferedReadValue);
    //System.out.println("_firstWrite: "+_firstWrite);
    buf.putBoolean(_firstWrite);

    // Mirroring:
    //buf.putInt(_currentMirroring);
    for (int i = 0; i < _vramMirrorTable.length; i++) {
      buf.putInt(_vramMirrorTable[i]);
    }

    // SPR-RAM I/O:
    buf.putInt(_sramAddress);

    // Rendering progression:
    buf.putInt(curX);
    buf.putInt(scanline);
    buf.putInt(lastRenderedScanline);

    // Misc:
    buf.putBoolean(_requestEndFrame);
    buf.putBoolean(_nmiOk);
    buf.putBoolean(_dummyCycleToggle);
    buf.putInt(_nmiCounter);
    buf.putInt(_tmp);

    // Stuff used during rendering:
    for (int i = 0; i < _bgbuffer.length; i++) {
      buf.putByte( _bgbuffer[i]);
    }
    for (int i = 0; i < _pixrendered.length; i++) {
      buf.putByte( _pixrendered[i]);
    }

    // Name tables:
    for (int i = 0; i < 4; i++) {
      buf.putByte( _ntable1[i]);
      _nameTable[i].stateSave(buf);
    }

    // Pattern data:
    for (int i = 0; i < ptTile.length; i++) {
      ptTile[i].stateSave(buf);
    }
  }

  // Reset PPU:
  void reset() {
    ppuMem.reset();
    sprMem.reset();

    _vramBufferedReadValue = 0;
    _sramAddress = 0;
    curX = 0;
    scanline = 0;
    lastRenderedScanline = 0;
    spr0HitX = 0;
    spr0HitY = 0;
    mapperIrqCounter = 0;

    _currentMirroring = -1;

    _firstWrite = true;
    _requestEndFrame = false;
    _nmiOk = false;
    hitSpr0 = false;
    _dummyCycleToggle = false;
    _validTileData = false;
    _nmiCounter = 0;
    _tmp = 0;
    _att = 0;

    // Control Flags Register 1:
    f_nmiOnVblank = 0;    // NMI on VBlank. 0=disable, 1=enable
    f_spriteSize = 0;     // Sprite size. 0=8x8, 1=8x16
    f_bgPatternTable = 0; // Background Pattern Table address. 0=0x0000,1=0x1000
    f_spPatternTable = 0; // Sprite Pattern Table address. 0=0x0000,1=0x1000
    f_addrInc = 0;        // PPU Address Increment. 0=1,1=32
    f_nTblAddress = 0;    // Name Table Address. 0=0x2000,1=0x2400,2=0x2800,3=0x2C00

    // Control Flags Register 2:
    f_color = 0;        // Background color. 0=black, 1=blue, 2=green, 4=red
    f_spVisibility = 0;   // Sprite visibility. 0=not displayed,1=displayed
    f_bgVisibility = 0;   // Background visibility. 0=Not Displayed,1=displayed
    f_spClipping = 0;     // Sprite clipping. 0=Sprites invisible in left 8-pixel column,1=No clipping
    f_bgClipping = 0;     // Background clipping. 0=BG invisible in left 8-pixel column, 1=No clipping
    f_dispType = 0;       // Display type. 0=color, 1=monochrome

    // Counters:
    _cntFV = 0;
    _cntV = 0;
    _cntH = 0;
    _cntVT = 0;
    _cntHT = 0;

    // Registers:
    _regFV = 0;
    _regV = 0;
    _regH = 0;
    _regVT = 0;
    _regHT = 0;
    _regFH = 0;
    _regS = 0;

    _scanlineChanged.forEach((e) => e = true);
    _oldFrame.forEach((e) => e = -1);

    // Initialize stuff:
    init();
  }

  void destroy() {
    nes = null;
    ppuMem = null;
    sprMem = null;
    _scantile = null;
  }
}
