part of dartendo;

class Mapper032 extends MapperDefault {

  List<int> regs = null;
  int patch = 0;

  Mapper032(NES nes_) : super(nes_) {
    regs = Util.newIntList(1, 0);
  }

  void write(int address, int value) {

    if (address < 0x8000) {
      super.write(address, value);
    } else {

      switch (address & 0xF000) {
        case 0x8000:
          {
            if ((regs[0] & 0x02) != 0) {
              load8kRomBank(value, 0xC000);
            } else {
              load8kRomBank(value, 0x8000);
            }
          }
          break;

        case 0x9000:
          {
            if ((value & 0x01) != 0) {
              nes.getPpu().setMirroring(ROM.HORIZONTAL_MIRRORING);
            } else {
              nes.getPpu().setMirroring(ROM.VERTICAL_MIRRORING);
            }
            regs[0] = value;
          }
          break;

        case 0xA000:
          {
            load8kRomBank(value, 0xA000);
          }
          break;
      }


      switch (address & 0xF007) {
        case 0xB000:
          {
            load1kVromBank(value, 0x0000);
          }
          break;

        case 0xB001:
          {
            load1kVromBank(value, 0x0400);
          }
          break;

        case 0xB002:
          {
            load1kVromBank(value, 0x0800);
          }
          break;

        case 0xB003:
          {
            load1kVromBank(value, 0x0C00);
          }
          break;

        case 0xB004:
          {
            load1kVromBank(value, 0x1000);
          }
          break;

        case 0xB005:
          {
            load1kVromBank(value, 0x1400);
          }
          break;

        case 0xB006:
          {
            if ((patch == 1) && ((value & 0x40) != 0)) {
              // nes.getPpu().setMirroring(ROM.SINGLESCREEN_MIRRORING); /* 0,0,0,1 */
            }
            load1kVromBank(value, 0x1800);
          }
          break;

        case 0xB007:
          {
            if ((patch == 1) && ((value & 0x40) != 0)) {
              nes.getPpu().setMirroring(ROM.SINGLESCREEN_MIRRORING);
            }
            load1kVromBank(value, 0x1C00);
          }
          break;
      }
    }
  }

  void loadROM(ROM rom_) {
    assert(rom_ == rom);

    int num_8k_banks = rom.getRomBankCount() * 2;

    // Load PRG-ROM:
    load8kRomBank(0, 0x8000);
    load8kRomBank(1, 0xA000);
    load8kRomBank(num_8k_banks - 2, 0xC000);
    load8kRomBank(num_8k_banks - 1, 0xE000);

    // Load CHR-ROM:
    loadCHRROM();

    // Do Reset-Interrupt:
    nes.getCpu().requestIrq(CPU.IRQ_RESET);

  }

  void reset() {

    if (patch == 1) {
      nes.getPpu().setMirroring(ROM.SINGLESCREEN_MIRRORING);
    }

    for (int i = 0; i < regs.length; i++) {
      regs[i] = 0;
    }
  }
}
