part of dartendo;

class Mapper033 extends MapperDefault {

  Mapper033(NES nes_) : super(nes_);

  void write(int address, int value) {

    if (address < 0x8000) {
      super.write(address, value);
    } else {
      switch (address) {
        case 0x8000:
          {
            if ((value & 0x40) != 0) {
              nes.getPpu().setMirroring(ROM.HORIZONTAL_MIRRORING);
            } else {
              nes.getPpu().setMirroring(ROM.VERTICAL_MIRRORING);
            }
            load8kRomBank(value & 0x1F, 0x8000);
          }
          break;

        case 0x8001:
          {
            load8kRomBank(value & 0x1F, 0xA000);
          }
          break;

        case 0x8002:
          {
            load2kVromBank(value, 0x0000);
          }
          break;

        case 0x8003:
          {
            load2kVromBank(value, 0x0800);
          }
          break;

        case 0xA000:
          {
            load1kVromBank(value, 0x1000);
          }
          break;

        case 0xA001:
          {
            load1kVromBank(value, 0x1400);
          }
          break;

        case 0xA002:
          {
            load1kVromBank(value, 0x1800);
          }
          break;

        case 0xA003:
          {
            load1kVromBank(value, 0x1C00);
          }
          break;
      }
    }
  }

  void loadROM(ROM rom_) {
    assert(rom_ == rom);

    if (!rom.isValid()) {
      print("Mapper033.loadROM: 048: Invalid ROM! Unable to load.");
      return;
    }

    // Get number of 8K banks:
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
}
