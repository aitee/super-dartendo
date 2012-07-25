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

class Mapper140 extends MapperDefault {
  Mapper140(NES nes_) : super(nes_);

  void loadROM(ROM rom_) {
    assert(rom_ == rom);

    if (!rom.isValid()) {
      //System.out.println("Invalid ROM! Unable to load.");
      return;
    }

    // Initial Load:
    loadPRGROM();
    loadCHRROM();

    // Do Reset-Interrupt:
    nes.getCpu().requestIrq(CPU.IRQ_RESET);

  }

  void write(int address, int value) {

    if (address < 0x8000) {
      // Handle normally:
      super.write(address, value);
    }

    if (address >= 0x6000 && address < 0x8000) {
      int prg_bank = (value & 0xF0) >> 4;
      int chr_bank = value & 0x0F;

      load32kRomBank(prg_bank, 0x8000);
      load8kVromBank(chr_bank, 0x0000);
    }
  }
}
