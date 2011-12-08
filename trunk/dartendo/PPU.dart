class PPU {
  NES nes;
  HiResTimer timer;
  Memory ppuMem;
  Memory sprMem;
  
  // Rendering Options:
  bool _showSpr0Hit = false;
  bool _showSoundBuffer = false;
  bool _clipTVcolumn = true;
  bool _clipTVrow = false;

  // Control Flags Register 1:
  int f_nmiOnVblank;    // NMI on VBlank. 0=disable, 1=enable
  int f_spriteSize;     // Sprite size. 0=8x8, 1=8x16
  int f_bgPatternTable; // Background Pattern Table address. 0=0x0000,1=0x1000
  int f_spPatternTable; // Sprite Pattern Table address. 0=0x0000,1=0x1000
  int f_addrInc;        // PPU Address Increment. 0=1,1=32
  int f_nTblAddress;    // Name Table Address. 0=0x2000,1=0x2400,2=0x2800,3=0x2C00
  
  // Control Flags Register 2:
  int f_color;        // Background color. 0=black, 1=blue, 2=green, 4=red
  int f_spVisibility;   // Sprite visibility. 0=not displayed,1=displayed
  int f_bgVisibility;   // Background visibility. 0=Not Displayed,1=displayed
  int f_spClipping;     // Sprite clipping. 0=Sprites invisible in left 8-pixel column,1=No clipping
  int f_bgClipping;     // Background clipping. 0=BG invisible in left 8-pixel column, 1=No clipping
  int f_dispType;       // Display type. 0=color, 1=monochrome
  
  // Status flags:
  static final int _STATUS_VRAMWRITE = 4;
  static final int _STATUS_SLSPRITECOUNT = 5;
  static final int _STATUS_SPRITE0HIT = 6;
  static final int _STATUS_VBLANK = 7;

  // VRAM I/O:
  int _vramAddress;
  int _vramTmpAddress;
  int _vramBufferedReadValue;
  bool _firstWrite = true;    // VRAM/Scroll Hi/Lo latch
  List<int> _vramMirrorTable; // Mirroring Lookup Table.
  int _i;

  // SPR-RAM I/O:
  int _sramAddress; // 8-bit only.

  // Counters:
  int _cntFV;
  int _cntV;
  int _cntH;
  int _cntVT;
  int _cntHT;

  // Registers:
  int _regFV;
  int _regV;
  int _regH;
  int _regVT;
  int _regHT;
  int _regFH;
  int _regS;

  // VBlank extension for PAL emulation:
  int _vblankAdd = 0;
  int curX;
  int scanline;
  int lastRenderedScanline;
  int mapperIrqCounter;
  
  // Sprite data:
  List<int> sprX;        // X coordinate
  List<int> sprY;        // Y coordinate
  List<int> sprTile;     // Tile Index (into pattern table)
  List<int> sprCol;      // Upper two bits of color
  List<bool> vertFlip;    // Vertical Flip
  List<bool> horiFlip;    // Horizontal Flip
  List<bool> bgPriority;  // Background priority
  int spr0HitX;  // Sprite #0 hit X coordinate
  int spr0HitY;  // Sprite #0 hit Y coordinate
  bool hitSpr0;

  // Tiles:
  List<Tile> ptTile;
  
  // Name table data:
  List<int> _ntable1 = new List<int>(4);
  List<NameTable> _nameTable;
  int _currentMirroring = -1;

  // Palette data:
  List<int> _sprPalette = new List<int>(16);
  List<int> _imgPalette = new List<int>(16);
    
  // Misc:
  bool _scanlineAlreadyRendered;
  bool _requestEndFrame;
  bool _nmiOk;
  int _nmiCounter;
  int _tmp;
  bool _dummyCycleToggle;

  // Vars used when updating regs/address:
  int _address, _b1, _b2;
    
  // Variables used when rendering:
  List<int> _attrib = new List<int>(32);
  List<int> _bgbuffer = new List<int>(256 * 240);
  List<int> _pixrendered = new List<int>(256 * 240);
  List<int> _spr0dummybuffer = new List<int>(256 * 240);
  List<int> _dummyPixPriTable = new List<int>(256 * 240);
  List<int> _oldFrame = new List<int>(256 * 240);
  List<int> _buffer;
  List<int> _tpix;
  List<bool> _scanlineChanged = new List<bool>(240);
  bool _requestRenderAll = false;
  bool _validTileData;
  int _att;
  List<Tile> _scantile = new List<Tile>(32);
  Tile _t;
    
  // These are temporary variables used in rendering and sound procedures.
  // Their states outside of those procedures can be ignored.
  int _curNt;
  int _destIndex;
  int _x, _y, _sx;
  int _si, _ei;
  int _tile;
  int _col;
  int _baseTile;
  int _tscanoffset;
  int _srcy1, _srcy2;
  int _bufferSize, _available, _scale;
  int cycles = 0;

  PPU(this.nes);

  void init() {
    // Get the memory:
    ppuMem = nes.getPpuMemory();
    sprMem = nes.getSprMemory();

    updateControlReg1(0);
    updateControlReg2(0);

    // Initialize misc vars:
    scanline = 0;
    timer = nes.getGui().getTimer();

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
    nameTable = new List<NameTable>(4);
    for (int i = 0; i < 4; i++) {
      nameTable[i] = new NameTable(32, 32, "Nt" + i);
    }

    // Initialize mirroring lookup table:
    _vramMirrorTable = new List<int>(0x8000);
    for (int i = 0; i < 0x8000; i++) {
      _vramMirrorTable[i] = i;
    }

    lastRenderedScanline = -1;
    curX = 0;

    // Initialize old frame buffer:
    for (int i = 0; i < oldFrame.length; i++) {
      oldFrame[i] = -1;
    }
  }

  // Sets Nametable mirroring.
  void setMirroring(int mirroring) {
    if (mirroring == currentMirroring) {
      return;
    }

    currentMirroring = mirroring;
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
      ntable1[0] = 0;
      ntable1[1] = 0;
      ntable1[2] = 1;
      ntable1[3] = 1;

      defineMirrorRegion(0x2400, 0x2000, 0x400);
      defineMirrorRegion(0x2c00, 0x2800, 0x400);
    } else if (mirroring == ROM.VERTICAL_MIRRORING) {
      // Vertical mirroring.
      ntable1[0] = 0;
      ntable1[1] = 1;
      ntable1[2] = 0;
      ntable1[3] = 1;
            
      defineMirrorRegion(0x2800, 0x2000, 0x400);      
      defineMirrorRegion(0x2c00, 0x2400, 0x400);
    } else if (mirroring == ROM.SINGLESCREEN_MIRRORING) {
      // Single Screen mirroring
      ntable1[0] = 0;
      ntable1[1] = 0;
      ntable1[2] = 0;
      ntable1[3] = 0;

      defineMirrorRegion(0x2400, 0x2000, 0x400);
      defineMirrorRegion(0x2800, 0x2000, 0x400);
      defineMirrorRegion(0x2c00, 0x2000, 0x400);
    } else if (mirroring == ROM.SINGLESCREEN_MIRRORING2) {
      ntable1[0] = 1;
      ntable1[1] = 1;
      ntable1[2] = 1;
      ntable1[3] = 1;

      defineMirrorRegion(0x2400, 0x2400, 0x400);
      defineMirrorRegion(0x2800, 0x2400, 0x400);
      defineMirrorRegion(0x2c00, 0x2400, 0x400);
    } else {
      // Assume Four-screen mirroring.

      ntable1[0] = 0;
      ntable1[1] = 1;
      ntable1[2] = 2;
      ntable1[3] = 3;
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
    //int n = (!requestEndFrame && curX+cycles<341 && (scanline-20 < spr0HitY || scanline-22 > spr0HitY))?cycles:1;
    for (; cycles > 0; cycles--) {
      if (scanline - 21 == spr0HitY) {
        if ((curX == spr0HitX) && (f_spVisibility == 1)) {
          // Set sprite 0 hit flag:
          setStatusFlag(STATUS_SPRITE0HIT, true);
        }
      }
      if (requestEndFrame) {
        nmiCounter--;
        if (nmiCounter == 0) {
          requestEndFrame = false;
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
    if (scanline < 19 + vblankAdd) {
      // VINT
      // do nothing.
    } else if (scanline == 19 + vblankAdd) {
      // Dummy scanline.
      // May be variable length:
      if (dummyCycleToggle) {
        // Remove dead cycle at end of scanline,
        // for next scanline:
        curX = 1;
        dummyCycleToggle = !dummyCycleToggle;
      }
    } else if (scanline == 20 + vblankAdd) {
      // Clear VBlank flag:
      setStatusFlag(STATUS_VBLANK, false);

      // Clear Sprite #0 hit flag:
      setStatusFlag(STATUS_SPRITE0HIT, false);
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
    } else if (scanline >= 21 + vblankAdd && scanline <= 260) {
      // Render normally:
      if (f_bgVisibility == 1) {
        if (!scanlineAlreadyRendered) {
          // update scroll:
          _cntHT = _regHT;
          _cntH = _regH;
          renderBgScanline(bgbuffer, scanline + 1 - 21);
        }
        scanlineAlreadyRendered = false;
        
        // Check for sprite 0 (next scanline):
        if (!hitSpr0 && f_spVisibility == 1) {
          if (sprX[0] >= -7 && sprX[0] < 256 && sprY[0] + 1 <= (scanline - vblankAdd + 1 - 21) && (sprY[0] + 1 + (f_spriteSize == 0 ? 8 : 16)) >= (scanline - vblankAdd + 1 - 21)) {
            if (checkSprite0(scanline + vblankAdd + 1 - 21)) {
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
    } else if (scanline == 261 + vblankAdd) {
      // Dead scanline, no rendering.
      // Set VINT:
      setStatusFlag(STATUS_VBLANK, true);
      requestEndFrame = true;
      nmiCounter = 9;

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
      bgColor = imgPalette[0];
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
    for (int i = 0; i < pixrendered.length; i++) {
      pixrendered[i] = 65;
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
      available = nes.getPapu().getLine().available();
      scale = bufferSize / 256;

      for (int y = 0; y < 4; y++) {
        scanlineChanged[y] = true;
        for (int x = 0; x < 256; x++) {
          if (x >= (available / scale)) {
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
    tmp = nes.getCpuMemory().load(0x2002);

    // Reset scroll & VRAM Address toggle:
    _firstWrite = true;

    // Clear VBlank flag:
    setStatusFlag(STATUS_VBLANK, false);

    // Fetch status data:
    return tmp;
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

      checkSprite0(scanline - vblankAdd + 1 - 21);
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
    address = (_vramTmpAddress >> 8) & 0xFF;
    _regFV = (address >> 4) & 7;
    _regV = (address >> 3) & 1;
    _regH = (address >> 2) & 1;
    _regVT = (_regVT & 7) | ((address & 3) << 3);

    address = _vramTmpAddress & 0xFF;
    _regVT = (_regVT & 24) | ((address >> 5) & 7);
    _regHT = address & 31;
  }

  // Updates the scroll registers from a new VRAM address.
  void cntsFromAddress() {
    address = (_vramAddress >> 8) & 0xFF;
    _cntFV = (address >> 4) & 3;
    _cntV = (address >> 3) & 1;
    _cntH = (address >> 2) & 1;
    _cntVT = (_cntVT & 7) | ((address & 3) << 3);

    address = _vramAddress & 0xFF;
    _cntVT = (_cntVT & 24) | ((address >> 5) & 7);
    _cntHT = address & 31;
  }

  void regsToAddress() {
    b1 = (_regFV & 7) << 4;
    b1 |= (_regV & 1) << 3;
    b1 |= (_regH & 1) << 2;
    b1 |= (_regVT >> 3) & 3;

    b2 = (_regVT & 7) << 5;
    b2 |= _regHT & 31;

    _vramTmpAddress = ((b1 << 8) | b2) & 0x7FFF;
  }

  void cntsToAddress() {
    b1 = (_cntFV & 7) << 4;
    b1 |= (_cntV & 1) << 3;
    b1 |= (_cntH & 1) << 2;
    b1 |= (_cntVT >> 3) & 3;

    b2 = (_cntVT & 7) << 5;
    b2 |= _cntHT & 31;

    _vramAddress = ((b1 << 8) | b2) & 0x7FFF;
  }

  void incTileCounter(int count) {
    for (i = count; i != 0; i--) {
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
    if (scanline - vblankAdd >= 21 && scanline - vblankAdd <= 260) {
      // Render sprites, and combine:
      renderFramePartially(buffer, lastRenderedScanline + 1, scanline - vblankAdd - 21 - lastRenderedScanline);

      // Set last rendered scanline:
      lastRenderedScanline = scanline - vblankAdd - 21;
    }
  }

  void renderFramePartially(List<int> buffer, int startScan, int scanCount) {
    if (f_spVisibility == 1 && !Globals.disableSprites) {
      renderSpritesPartially(startScan, scanCount, true);
    }
     
    if (f_bgVisibility == 1) {
      si = startScan << 8;
      ei = (startScan + scanCount) << 8;
      if (ei > 0xF000) {
        ei = 0xF000;
      }
      for (destIndex = si; destIndex < ei; destIndex++) {
        if (pixrendered[destIndex] > 0xFF) {
          buffer[destIndex] = bgbuffer[destIndex];
        }
      }
    }

    if (f_spVisibility == 1 && !Globals.disableSprites) {
      renderSpritesPartially(startScan, scanCount, false);
    }

    BufferView screen = nes.getGui().getScreenView();
    if (screen.scalingEnabled() && !screen.useHWScaling() && !requestRenderAll) {
      // Check which scanlines have changed, to try to
      // speed up scaling:
      int j, jmax;
      if (startScan + scanCount > 240) {
        scanCount = 240 - startScan;
      }
      for (int i = startScan; i < startScan + scanCount; i++) {
        scanlineChanged[i] = false;
        si = i << 8;
        jmax = si + 256;
        for (j = si; j < jmax; j++) {
          if (buffer[j] != oldFrame[j]) {
            scanlineChanged[i] = true;
            break;
          }
          oldFrame[j] = buffer[j];
        }
        System.arraycopy(buffer, j, oldFrame, j, jmax - j);
      }
    }

    validTileData = false;
  }

  void renderBgScanline(List<int> buffer, int scan) {
    baseTile = (_regS == 0 ? 0 : 256);
    destIndex = (scan << 8) - _regFH;
    curNt = ntable1[_cntV + _cntV + _cntH];

    _cntHT = _regHT;
    _cntH = _regH;
    curNt = ntable1[_cntV + _cntV + _cntH];

    if (scan < 240 && (scan - _cntFV) >= 0) {
      tscanoffset = _cntFV << 3;
      y = scan - _cntFV;
      for (tile = 0; tile < 32; tile++) {
        if (scan >= 0) {
          // Fetch tile & attrib data:
          if (validTileData) {
            // Get data from array:
            t = scantile[tile];
            tpix = t.pix;
            att = attrib[tile];
          } else {
            // Fetch data:
            t = ptTile[baseTile + nameTable[curNt].getTileIndex(_cntHT, _cntVT)];
            tpix = t.pix;
            att = nameTable[curNt].getAttrib(_cntHT, _cntVT);
            scantile[tile] = t;
            attrib[tile] = att;
          }

          // Render tile scanline:
          sx = 0;
          x = (tile << 3) - _regFH;
          if (x > -8) {
            if (x < 0) {
              destIndex -= x;
              sx = -x;
            }
            if (t.opaque[_cntFV]) {
              for (; sx < 8; sx++) {
                buffer[destIndex] = imgPalette[tpix[tscanoffset + sx] + att];
                pixrendered[destIndex] |= 256;
                destIndex++;
              }
            } else {
              for (; sx < 8; sx++) {
                  col = tpix[tscanoffset + sx];
                  if (col != 0) {
                    buffer[destIndex] = imgPalette[col + att];
                    pixrendered[destIndex] |= 256;
                  }
                destIndex++;
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
          curNt = ntable1[(_cntV << 1) + _cntH];
        }
      }
      // Tile data for one row should now have been fetched,
      // so the data in the array is valid.
      validTileData = true;
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
        curNt = ntable1[(_cntV << 1) + _cntH];
      } else if (_cntVT == 32) {
        _cntVT = 0;
      }

      // Invalidate fetched data:
      validTileData = false;
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
            srcy1 = 0;
            srcy2 = 8;

            if (sprY[i] < startscan) {
              srcy1 = startscan - sprY[i] - 1;
            }

            if (sprY[i] + 8 > startscan + scancount) {
              srcy2 = startscan + scancount - sprY[i] + 1;
            }

            if (f_spPatternTable == 0) {
              ptTile[sprTile[i]].render(0, srcy1, 8, srcy2, sprX[i], sprY[i] + 1, buffer, sprCol[i], sprPalette, horiFlip[i], vertFlip[i], i, pixrendered);
            } else {
              ptTile[sprTile[i] + 256].render(0, srcy1, 8, srcy2, sprX[i], sprY[i] + 1, buffer, sprCol[i], sprPalette, horiFlip[i], vertFlip[i], i, pixrendered);
            }
          } else {
            // 8x16 sprites
            int top = sprTile[i];
            if ((top & 1) != 0) {
              top = sprTile[i] - 1 + 256;
            }

            srcy1 = 0;
            srcy2 = 8;

            if (sprY[i] < startscan) {
              srcy1 = startscan - sprY[i] - 1;
            }

            if (sprY[i] + 8 > startscan + scancount) {
              srcy2 = startscan + scancount - sprY[i];
            }

            ptTile[top + (vertFlip[i] ? 1 : 0)].render(0, srcy1, 8, srcy2, sprX[i], sprY[i] + 1, buffer, sprCol[i], sprPalette, horiFlip[i], vertFlip[i], i, pixrendered);

            srcy1 = 0;
            srcy2 = 8;

            if (sprY[i] + 8 < startscan) {
              srcy1 = startscan - (sprY[i] + 8 + 1);
            }

            if (sprY[i] + 16 > startscan + scancount) {
              srcy2 = startscan + scancount - (sprY[i] + 8);
            }

            ptTile[top + (vertFlip[i] ? 0 : 1)].render(0, srcy1, 8, srcy2, sprX[i], sprY[i] + 1 + 8, buffer, sprCol[i], sprPalette, horiFlip[i], vertFlip[i], i, pixrendered);
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
              if (bufferIndex >= 0 && bufferIndex < 61440 && pixrendered[bufferIndex] != 0) {
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
              if (bufferIndex >= 0 && bufferIndex < 61440 && pixrendered[bufferIndex] != 0) {
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
              if (bufferIndex >= 0 && bufferIndex < 61440 && pixrendered[bufferIndex] != 0) {
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
              if (bufferIndex >= 0 && bufferIndex < 61440 && pixrendered[bufferIndex] != 0) {
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
          ptTile[tIndex].renderSimple(j * 128 + x * 8, y * 8, buffer, 0, sprPalette);
          tIndex++;
        }
      }
    }
    nes.getGui().getPatternView().imageReady(false);
  }

  void renderNameTables() {
    List<int> buffer = nes.getGui().getNameTableView().getBuffer();
    if (f_bgPatternTable == 0) {
      baseTile = 0;
    } else {
      baseTile = 256;
    }

    int ntx_max = 2;
    int nty_max = 2;

    if (currentMirroring == ROM.HORIZONTAL_MIRRORING) {
      ntx_max = 1;
    } else if (currentMirroring == ROM.VERTICAL_MIRRORING) {
      nty_max = 1;
    }

    for (int nty = 0; nty < nty_max; nty++) {
      for (int ntx = 0; ntx < ntx_max; ntx++) {
        int nt = ntable1[nty * 2 + ntx];
        int x = ntx * 128;
        int y = nty * 120;

        // Render nametable:
        for (int ty = 0; ty < 30; ty++) {
          for (int tx = 0; tx < 32; tx++) {
            //ptTile[baseTile+nameTable[nt].getTileIndex(tx,ty)].render(0,0,4,4,x+tx*4,y+ty*4,buffer,nameTable[nt].getAttrib(tx,ty),imgPalette,false,false,0,dummyPixPriTable);
            ptTile[baseTile + nameTable[nt].getTileIndex(tx, ty)].renderSmall(x + tx * 4, y + ty * 4, buffer, nameTable[nt].getAttrib(tx, ty), imgPalette);
          }
        }
      }
    }
    
    if (currentMirroring == ROM.HORIZONTAL_MIRRORING) {
      // double horizontally:
      for (int y = 0; y < 240; y++) {
        for (int x = 0; x < 128; x++) {
          buffer[(y << 8) + 128 + x] = buffer[(y << 8) + x];
        }
      }
    } else if (currentMirroring == ROM.VERTICAL_MIRRORING) {
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
          buffer[y * 256 + i * 16 + x] = imgPalette[i];
        }
      }
    }

    buffer = nes.getGui().getSprPalView().getBuffer();
    for (int i = 0; i < 16; i++) {
      for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
          buffer[y * 256 + i * 16 + x] = sprPalette[i];
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
      nameTableWrite(ntable1[0], address - 0x2000, value);
    } else if (address >= 0x23c0 && address < 0x2400) {
      attribTableWrite(ntable1[0], address - 0x23c0, value);
    } else if (address >= 0x2400 && address < 0x27c0) {
      nameTableWrite(ntable1[1], address - 0x2400, value);
    } else if (address >= 0x27c0 && address < 0x2800) {
      attribTableWrite(ntable1[1], address - 0x27c0, value);
    } else if (address >= 0x2800 && address < 0x2bc0) {
      nameTableWrite(ntable1[2], address - 0x2800, value);
    } else if (address >= 0x2bc0 && address < 0x2c00) {
      attribTableWrite(ntable1[2], address - 0x2bc0, value);
    } else if (address >= 0x2c00 && address < 0x2fc0) {
      nameTableWrite(ntable1[3], address - 0x2c00, value);
    } else if (address >= 0x2fc0 && address < 0x3000) {
      attribTableWrite(ntable1[3], address - 0x2fc0, value);
    } else if (address >= 0x3f00 && address < 0x3f20) {
      updatePalettes();
    }
  }

  // Reads data from $3f00 to $f20
  // into the two buffered palettes.
  void updatePalettes() {
    for (int i = 0; i < 16; i++) {
      if (f_dispType == 0) {
        imgPalette[i] = nes.palTable.getEntry(ppuMem.load(0x3f00 + i) & 63);
      } else {
        imgPalette[i] = nes.palTable.getEntry(ppuMem.load(0x3f00 + i) & 32);
      }
    }
    for (int i = 0; i < 16; i++) {
      if (f_dispType == 0) {
        sprPalette[i] = nes.palTable.getEntry(ppuMem.load(0x3f10 + i) & 63);
      } else {
        sprPalette[i] = nes.palTable.getEntry(ppuMem.load(0x3f10 + i) & 32);
      }
    }

    //renderPalettes();
  }

  // Updates the internal pattern
  // table buffers with this new byte.
  void patternWrite(int address, int value) {
    int tileIndex = address / 16;
    int leftOver = address % 16;
    if (leftOver < 8) {
      ptTile[tileIndex].setScanline(leftOver, value, ppuMem.load(address + 8));
    } else {
      ptTile[tileIndex].setScanline(leftOver - 8, ppuMem.load(address - 8), value);
    }
  }

  void patternWrite(int address, List<int> value, int offset, int length) {
    int tileIndex;
    int leftOver;

    for (int i = 0; i < length; i++) {
      tileIndex = (address + i) >> 4;
      leftOver = (address + i) % 16;

      if (leftOver < 8) {
          ptTile[tileIndex].setScanline(leftOver, value[offset + i], ppuMem.load(address + 8 + i));
      } else {
          ptTile[tileIndex].setScanline(leftOver - 8, ppuMem.load(address - 8 + i), value[offset + i]);
      }
    }
  }

  void invalidateFrameCache() {
    // Clear the no-update scanline buffer:
    for (int i = 0; i < 240; i++) {
      scanlineChanged[i] = true;
    }
    java.util.Arrays.fill(oldFrame, -1);
    requestRenderAll = true;
  }

  // Updates the internal name table buffers
  // with this new byte.
  void nameTableWrite(int index, int address, int value) {
    nameTable[index].writeTileIndex(address, value);

    // Update Sprite #0 hit:
    //updateSpr0Hit();
    checkSprite0(scanline + 1 - vblankAdd - 21);
  }

  // Updates the internal pattern
  // table buffers with this new attribute
  // table byte.
  void attribTableWrite(int index, int address, int value) {
    nameTable[index].writeAttrib(address, value);
  }

  // Updates the internally buffered sprite
  // data with this new byte of info.
  void spriteRamWriteUpdate(int address, int value) {
    int tIndex = address / 4;

    if (tIndex == 0) {
      //updateSpr0Hit();
      checkSprite0(scanline + 1 - vblankAdd - 21);
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
    setStatusFlag(STATUS_VBLANK, true);
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
      //currentMirroring = -1;
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
      requestEndFrame = buf.readBoolean();
      nmiOk = buf.readBoolean();
      dummyCycleToggle = buf.readBoolean();
      nmiCounter = buf.readInt();
      tmp =  buf.readInt();

      // Stuff used during rendering:
      for (int i = 0; i < bgbuffer.length; i++) {
        bgbuffer[i] = buf.readByte();
      }
      for (int i = 0; i < pixrendered.length; i++) {
        pixrendered[i] = buf.readByte();
      }

      // Name tables:
      for (int i = 0; i < 4; i++) {
        ntable1[i] = buf.readByte();
        nameTable[i].stateLoad(buf);
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
    //buf.putInt(currentMirroring);
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
    buf.putBoolean(requestEndFrame);
    buf.putBoolean(nmiOk);
    buf.putBoolean(dummyCycleToggle);
    buf.putInt(nmiCounter);
    buf.putInt(tmp);

    // Stuff used during rendering:
    for (int i = 0; i < bgbuffer.length; i++) {
      buf.putByte( bgbuffer[i]);
    }
    for (int i = 0; i < pixrendered.length; i++) {
      buf.putByte( pixrendered[i]);
    }

    // Name tables:
    for (int i = 0; i < 4; i++) {
      buf.putByte( ntable1[i]);
      nameTable[i].stateSave(buf);
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

    currentMirroring = -1;

    _firstWrite = true;
    requestEndFrame = false;
    nmiOk = false;
    hitSpr0 = false;
    dummyCycleToggle = false;
    validTileData = false;
    nmiCounter = 0;
    tmp = 0;
    att = 0;
    i = 0;

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

    scanlineChanged.forEach((e) => e = true);
    oldFrame.forEach((e) => e = -1);

    // Initialize stuff:
    init();
  }

  void destroy() {
    nes = null;
    ppuMem = null;
    sprMem = null;
    scantile = null;
  }
}
