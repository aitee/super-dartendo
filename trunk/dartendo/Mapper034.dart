part of dartendo;

class Mapper034 extends MapperDefault {

  Mapper034(NES nes_) : super(nes_);

  void write(int address, int value) {
    if (address < 0x8000) {
      super.write(address, value);
    } else {
      load32kRomBank(value, 0x8000);
    }
  }
}
