// iainmcgin: arithmetic operations in this class haven't been
// audited at all. Possible overflow / truncation semantic differences.
class Tile {
  // Tile data:
  List<int> pix;
  int fbIndex = 0;
  int tIndex = 0;
  int incX = 0, incY = 0;
  int palIndex = 0;
  int tpri = 0;
  int c = 0;
  bool initialized = false;

  List<bool> opaque;

  Tile() {
    pix = Util.newIntList(64,0);
    opaque = Util.newBoolList(8,false);
  }

  void setBuffer(List<int> scanline) {
    for (var y = 0; y < 8; y++) {
      setScanline(y, scanline[y], scanline[y + 8]);
    }
  }

  void setScanline(int sline, int b1, int b2) {
    initialized = true;
    tIndex = sline << 3;
    for (var x = 0; x < 8; x++) {
      pix[tIndex + x] = ((b1 >> (7 - x)) & 1) + (((b2 >> (7 - x)) & 1) << 1);
      if (pix[tIndex + x] == 0) {
        opaque[sline] = false;
      }
    }
  }

  void renderSimple(int dx, int dy, List<int> fBuffer, int palAdd, List<int> palette) {
    tIndex = 0;
    fbIndex = (dy << 8) + dx;
    for (var y = 8; y != 0; y--) {
      for (var x = 8; x != 0; x--) {
        palIndex = pix[tIndex];
        if (palIndex != 0) {
          fBuffer[fbIndex] = palette[palIndex + palAdd];
        }
        fbIndex++;
        tIndex++;
      }
      fbIndex -= 8;
      fbIndex += 256;
    }
  }

  void renderSmall(int dx, int dy, List<int> buffer, int palAdd, List<int> palette) {

    tIndex = 0;
    fbIndex = (dy << 8) + dx;
    for (var y = 0; y < 4; y++) {
      for (var x = 0; x < 4; x++) {

        c = (palette[pix[tIndex] + palAdd] >> 2) & 0x003F3F3F;
        c += (palette[pix[tIndex + 1] + palAdd] >> 2) & 0x003F3F3F;
        c += (palette[pix[tIndex + 8] + palAdd] >> 2) & 0x003F3F3F;
        c += (palette[pix[tIndex + 9] + palAdd] >> 2) & 0x003F3F3F;
        buffer[fbIndex] = c;
        fbIndex++;
        tIndex += 2;
      }
      tIndex += 8;
      fbIndex += 252;
    }

  }

  void render(int srcx1, int srcy1, 
      int srcx2, int srcy2, 
      int dx, int dy, 
      List<int> fBuffer, 
      int palAdd, 
      List<int> palette, 
      bool flipHorizontal, 
      bool flipVertical, 
      int pri, 
      List<int> priTable) {

    if (dx < -7 || dx >= 256 || dy < -7 || dy >= 240) {
      return;
    }

    var w = srcx2 - srcx1;
    var h = srcy2 - srcy1;

    if (dx < 0) {
      srcx1 -= dx;
    }
    if (dx + srcx2 >= 256) {
      srcx2 = 256 - dx;
    }

    if (dy < 0) {
      srcy1 -= dy;
    }
    if (dy + srcy2 >= 240) {
      srcy2 = 240 - dy;
    }

    if (!flipHorizontal && !flipVertical) {

      fbIndex = (dy << 8) + dx;
      tIndex = 0;
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          if (x >= srcx1 && x < srcx2 && y >= srcy1 && y < srcy2) {
            palIndex = pix[tIndex];
            tpri = priTable[fbIndex];
            if (palIndex != 0 && pri <= (tpri & 0xFF)) {
              fBuffer[fbIndex] = palette[palIndex + palAdd];
              tpri = (tpri & 0xF00) | pri;
              priTable[fbIndex] = tpri;
            }
          }
          fbIndex++;
          tIndex++;
        }
        fbIndex -= 8;
        fbIndex += 256;
      }

    } else if (flipHorizontal && !flipVertical) {

      fbIndex = (dy << 8) + dx;
      tIndex = 7;
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          if (x >= srcx1 && x < srcx2 && y >= srcy1 && y < srcy2) {
            palIndex = pix[tIndex];
            tpri = priTable[fbIndex];
            if (palIndex != 0 && pri <= (tpri & 0xFF)) {
              fBuffer[fbIndex] = palette[palIndex + palAdd];
              tpri = (tpri & 0xF00) | pri;
              priTable[fbIndex] = tpri;
            }
          }
          fbIndex++;
          tIndex--;
        }
        fbIndex -= 8;
        fbIndex += 256;
        tIndex += 16;
      }

    } else if (flipVertical && !flipHorizontal) {

      fbIndex = (dy << 8) + dx;
      tIndex = 56;
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          if (x >= srcx1 && x < srcx2 && y >= srcy1 && y < srcy2) {
            palIndex = pix[tIndex];
            tpri = priTable[fbIndex];
            if (palIndex != 0 && pri <= (tpri & 0xFF)) {
              fBuffer[fbIndex] = palette[palIndex + palAdd];
              tpri = (tpri & 0xF00) | pri;
              priTable[fbIndex] = tpri;
            }
          }
          fbIndex++;
          tIndex++;
        }
        fbIndex -= 8;
        fbIndex += 256;
        tIndex -= 16;
      }

    } else {

      fbIndex = (dy << 8) + dx;
      tIndex = 63;
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          if (x >= srcx1 && x < srcx2 && y >= srcy1 && y < srcy2) {
            palIndex = pix[tIndex];
            tpri = priTable[fbIndex];
            if (palIndex != 0 && pri <= (tpri & 0xFF)) {
              fBuffer[fbIndex] = palette[palIndex + palAdd];
              tpri = (tpri & 0xF00) | pri;
              priTable[fbIndex] = tpri;
            }
          }
          fbIndex++;
          tIndex--;
        }
        fbIndex -= 8;
        fbIndex += 256;
      }

    }

  }

  bool isTransparent(int xx, int yy) {
    return (pix[(yy << 3) + xx] == 0);
  }

  void stateSave(MemByteBuffer buf) {
    buf.putBoolean(initialized);
    for (int i = 0; i < 8; i++) {
      buf.putBoolean(opaque[i]);
    }
    for (int i = 0; i < 64; i++) {
      // iainmcgin: cast to byte was here, no longer needed
      // as truncation handled by MemByteBuffer?
      buf.putByte(pix[i]);
    }
  }

  void stateLoad(MemByteBuffer buf) {
    initialized = buf.readBoolean();
    for (int i = 0; i < 8; i++) {
      opaque[i] = buf.readBoolean();
    }
    for (int i = 0; i < 64; i++) {
      pix[i] = buf.readByte();
    }
  }
}
