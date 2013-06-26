part of dartendo;

class ChannelDM implements PapuChannel {
  PAPU papu = null;

  static final int MODE_NORMAL = 0;
  static final int MODE_LOOP = 1;
  static final int MODE_IRQ = 2;

  bool _isEnabled = false;
  bool hasSample = false;
  bool irqGenerated = false;
  int playMode = 0;
  int dmaFrequency = 0;
  int dmaCounter = 0;
  int deltaCounter = 0;
  int playStartAddress = 0;
  int playAddress = 0;
  int playLength = 0;
  int playLengthCounter = 0;
  int shiftCounter = 0;
  int reg4012 = 0;
  int reg4013 = 0;
  int status = 0;
  int sample = 0;
  int dacLsb = 0;
  int data = 0;

  ChannelDM(this.papu);

  void clockDmc() {
    // Only alter DAC value if the sample buffer has data:
    if (hasSample) {
      if ((data & 1) == 0) {

        // Decrement delta:
        if (deltaCounter > 0)
          --deltaCounter;
      
      } else {

        // Increment delta:
        if (deltaCounter < 63)
          ++deltaCounter;

      }

      // Update sample value:
      sample = _isEnabled ? (deltaCounter << 1) + dacLsb : 0;

      // Update shift register:
      data >>= 1;
    }

    dmaCounter--;
    if (dmaCounter <= 0) {

      // No more sample bits.
      hasSample = false;
      endOfSample();
      dmaCounter = 8;

    }

    if (irqGenerated) {
      papu.nes.cpu.requestIrq(CPU.IRQ_NORMAL);
    }

  }

  void endOfSample() {

    if (playLengthCounter == 0 && playMode == MODE_LOOP) {

      // Start from beginning of sample:
      playAddress = playStartAddress;
      playLengthCounter = playLength;

    }

    if (playLengthCounter > 0) {

      // Fetch next sample:
      nextSample();

      if (playLengthCounter == 0) {

        // Last byte of sample fetched, generate IRQ:
        if (playMode == MODE_IRQ)
          irqGenerated = true;

      }

    }

  }

  void nextSample() {

    // Fetch byte:
    data = papu.getNes().getMemoryMapper().load(playAddress);
    papu.getNes().cpu.haltCycles(4);

    playLengthCounter--;
    playAddress++;
    if (playAddress > 0xFFFF)
      playAddress = 0x8000;

    hasSample = true;

  }

  void writeReg(int address, int value) {

    if (address == 0x4010) {

      // Play mode, DMA Frequency
      if ((value >> 6) == 0)
        playMode = MODE_NORMAL;
      else if (((value >> 6) & 1) == 1)
        playMode = MODE_LOOP;
      else if ((value >> 6) == 2)
        playMode = MODE_IRQ;

      if ((value & 0x80) == 0)
        irqGenerated = false;

      dmaFrequency = papu.getDmcFrequency(value & 0xF);

    } else if (address == 0x4011) {

      // Delta counter load register:
      deltaCounter = (value >> 1) & 63;
      dacLsb = value & 1;
      if (papu.userEnableDmc) {
        sample = ((deltaCounter << 1) + dacLsb); // update sample value
      }

    } else if (address == 0x4012) {

      // DMA address load register
      playStartAddress = (value << 6) | 0x0C000;
      playAddress = playStartAddress;
      reg4012 = value;

    } else if (address == 0x4013) {

      // Length of play code
      playLength = (value << 4) + 1;
      playLengthCounter = playLength;
      reg4013 = value;

    } else if (address == 0x4015) {

      // DMC/IRQ Status
      if (((value >> 4) & 1) == 0) {
        // Disable:
        playLengthCounter = 0;
      } else {
        // Restart:
        playAddress = playStartAddress;
        playLengthCounter = playLength;
      }
      irqGenerated = false;
    }

  }

  void setEnabled(bool value) {

    if ((!_isEnabled) && value)
      playLengthCounter = playLength;
    _isEnabled = value;

  }

  bool isEnabled() => _isEnabled;

  int getLengthStatus() {
    return ((playLengthCounter == 0 || !_isEnabled) ? 0 : 1);
  }

  int getIrqStatus() {
    return (irqGenerated ? 1 : 0);
  }

  void reset() {

    _isEnabled = false;
    irqGenerated = false;
    playMode = MODE_NORMAL;
    dmaFrequency = 0;
    dmaCounter = 0;
    deltaCounter = 0;
    playStartAddress = 0;
    playAddress = 0;
    playLength = 0;
    playLengthCounter = 0;
    status = 0;
    sample = 0;
    dacLsb = 0;
    shiftCounter = 0;
    reg4012 = 0;
    reg4013 = 0;
    data = 0;

  }

  void destroy() {
    papu = null;
  }
}
