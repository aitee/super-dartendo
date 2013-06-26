part of dartendo;

class Mapper079 extends MapperDefault {

  Mapper079(NES nes_) : super(nes_);

  void writelow(int address, int value) {

    if (address < 0x4000) {
      super.writelow(address, value);
    }

    if (address < 0x6000 && address >= 0x4100) {
      int prg_bank = (value & 0x08) >> 3;
      int chr_bank = value & 0x07;

      load32kRomBank(prg_bank, 0x8000);
      load8kVromBank(chr_bank, 0x0000);
    }

  }

  void loadROM(ROM rom_) {
    assert(rom_ == rom);

    if (!rom.isValid()) {
      print("Mapper079.loadROM: Invalid ROM! Unable to load.");
      return;
    }

    // Initial Load:
    loadPRGROM();
    loadCHRROM();

    // Do Reset-Interrupt:
    nes.getCpu().requestIrq(CPU.IRQ_RESET);

  }
}
