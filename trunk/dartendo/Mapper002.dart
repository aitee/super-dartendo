part of dartendo;

class Mapper002 extends MapperDefault {

  Mapper002(NES nes_) : super(nes_);

  void write(int address, int value) {
    if (address < 0x8000) {
      // Let the base mapper take care of it.
      super.write(address, value);
    } else {
      // This is a ROM bank select command.
      // Swap in the given ROM bank at 0x8000:
      loadRomBank(value, 0x8000);
    }
  }

  void loadROM(ROM rom_) {
    assert(rom_ == rom);
    if (!rom.isValid()) {
      //System.out.println("UNROM: Invalid ROM! Unable to load.");
      return;
    }

    //System.out.println("UNROM: loading ROM..");

    // Load PRG-ROM:
    loadRomBank(0, 0x8000);
    loadRomBank(rom.getRomBankCount() - 1, 0xC000);

    // Load CHR-ROM:
    loadCHRROM();

    // Do Reset-Interrupt:
    //nes.getCpu().doResetInterrupt();
    nes.getCpu().requestIrq(CPU.IRQ_RESET);
  }
}
