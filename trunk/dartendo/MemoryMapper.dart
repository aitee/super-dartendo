part of dartendo;

abstract class MemoryMapper {
  void loadROM(ROM rom);
  void write(int address, int value);
  int load(int address);

  int joy1Read();
  int joy2Read();

  void reset();
  void setGameGenieState(bool value);

  void clockIrqCounter();
  void loadBatteryRam();
  void destroy();

  void stateLoad(MemByteBuffer buf);
  void stateSave(MemByteBuffer buf);

  void setMouseState(bool pressed, int x, int y);

  void latchAccess(int address);
}

