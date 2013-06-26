part of dartendo;

class Mapper010 extends MapperDefault {

  int latchLo = 0;
  int latchHi = 0;
  int latchLoVal1 = 0;
  int latchLoVal2 = 0;
  int latchHiVal1 = 0;
  int latchHiVal2 = 0;

  Mapper010(NES nes_) : super(nes_) {
    reset();
  }

  void write(int address, int value) {
    if (address < 0x8000) {
      // Handle normally.
      super.write(address, value);
    } else {
      // MMC4 write.
      value &= 0xFF;
      switch (address >> 12) {
        case 0xA: {
                    // Select 8k ROM bank at 0x8000
                    loadRomBank(value, 0x8000);
                    break;

                  }
        case 0xB: {

                    // Select 4k VROM bank at 0x0000, $FD mode
                    latchLoVal1 = value;
                    if (latchLo == 0xFD) {
                      loadVromBank(value, 0x0000);
                    }
                    break;

                  }
        case 0xC: {

                    // Select 4k VROM bank at 0x0000, $FE mode
                    latchLoVal2 = value;
                    if (latchLo == 0xFE) {
                      loadVromBank(value, 0x0000);
                    }
                    break;

                  }
        case 0xD: {

                    // Select 4k VROM bank at 0x1000, $FD mode
                    latchHiVal1 = value;
                    if (latchHi == 0xFD) {
                      loadVromBank(value, 0x1000);
                    }
                    break;

                  }
        case 0xE: {

                    // Select 4k VROM bank at 0x1000, $FE mode
                    latchHiVal2 = value;
                    if (latchHi == 0xFE) {
                      loadVromBank(value, 0x1000);
                    }
                    break;

                  }
        case 0xF: {

                    // Select mirroring
                    if ((value & 0x1) == 0) {

                      // Vertical mirroring
                      nes.getPpu().setMirroring(ROM.VERTICAL_MIRRORING);

                    } else {

                      // Horizontal mirroring
                      nes.getPpu().setMirroring(ROM.HORIZONTAL_MIRRORING);

                    }
                    break;

                  }
      }

    }

  }

  void loadROM(ROM rom_) {
    assert(rom_ == rom);

    //System.out.println("Loading ROM.");

    if (!rom.isValid()) {
      print("Mapper010.loadROM: MMC2: Invalid ROM! Unable to load.");
      return;
    }

    // Get number of 16K banks:
    int num_16k_banks = rom.getRomBankCount() * 4;

    // Load PRG-ROM:
    loadRomBank(0, 0x8000);
    loadRomBank(num_16k_banks - 1, 0xC000);

    // Load CHR-ROM:
    loadCHRROM();

    // Load Battery RAM (if present):
    loadBatteryRam();

    // Do Reset-Interrupt:
    nes.getCpu().requestIrq(CPU.IRQ_RESET);
  }

  void latchAccess(int address) {

    // Important: Only invoke if address < 0x2000

    //System.out.println("latch addr="+Misc.hex16(address));
    bool lo = (address < 0x2000);
    address &= 0x0FF0;

    if (lo) {

      // Switch lo part of CHR

      if (address == 0xFD0) {

        // Set $FD mode
        latchLo = 0xFD;
        loadVromBank(latchLoVal1, 0x0000);
        //System.out.println("LO FD");

      } else if (address == 0xFE0) {

        // Set $FE mode
        latchLo = 0xFE;
        loadVromBank(latchLoVal2, 0x0000);
        //System.out.println("LO FE");

      }

    } else {

      // Switch hi part of CHR

      if (address == 0xFD0) {

        // Set $FD mode
        latchHi = 0xFD;
        loadVromBank(latchHiVal1, 0x1000);
        //System.out.println("HI FD");

      } else if (address == 0xFE0) {

        // Set $FE mode
        latchHi = 0xFE;
        loadVromBank(latchHiVal2, 0x1000);
        //System.out.println("HI FE");

      }

    }

  }

  void mapperInternalStateLoad(MemByteBuffer buf) {

    super.mapperInternalStateLoad(buf);

    // Check version:
    if (buf.readByte() == 1) {

      latchLo = buf.readByte();
      latchHi = buf.readByte();
      latchLoVal1 = buf.readByte();
      latchLoVal2 = buf.readByte();
      latchHiVal1 = buf.readByte();
      latchHiVal2 = buf.readByte();

    }

  }

  void mapperInternalStateSave(MemByteBuffer buf) {

    super.mapperInternalStateSave(buf);

    // Version:
    buf.putByte( 1);

    // State:
    buf.putByte(latchLo);
    buf.putByte(latchHi);
    buf.putByte(latchLoVal1);
    buf.putByte(latchLoVal2);
    buf.putByte(latchHiVal1);
    buf.putByte(latchHiVal2);

  }

  void reset() {

    // Set latch to $FE mode:
    latchLo = 0xFE;
    latchHi = 0xFE;
    latchLoVal1 = 0;
    latchLoVal2 = 4;
    latchHiVal1 = 0;
    latchHiVal2 = 0;

  }
}
