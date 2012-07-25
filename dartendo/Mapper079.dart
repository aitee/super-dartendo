/*
   vNES
   Copyright © 2006-2011 Jamie Sanders

   This program is free software: you can redistribute it and/or modify it under
   the terms of the GNU General License as published by the Free Software
   Foundation, either version 3 of the License, or (at your option) any later
   version.

   This program is distributed in the hope that it will be useful, but WITHOUT ANY
   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
   PARTICULAR PURPOSE.  See the GNU General License for more details.

   You should have received a copy of the GNU General License along with
   this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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
