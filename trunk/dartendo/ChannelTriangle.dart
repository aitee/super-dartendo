part of dartendo;

class ChannelTriangle implements PapuChannel {

  PAPU papu = null;

  bool _isEnabled = false;
  bool sampleCondition = false;
  bool lengthCounterEnable = false;
  bool lcHalt = false;
  bool lcControl = false;

  int progTimerCount = 0;
  int progTimerMax = 0;
  int triangleCounter = 0;
  int lengthCounter = 0;
  int linearCounter = 0;
  int lcLoadValue = 0;
  int sampleValue = 0;
  int tmp = 0;

  ChannelTriangle(this.papu);

  void clockLengthCounter() {
    if (lengthCounterEnable && lengthCounter > 0) {
      lengthCounter--;
      if (lengthCounter == 0)
        updateSampleCondition();
    }
  }

  void clockLinearCounter() {

    if (lcHalt) {
      // Load:
      linearCounter = lcLoadValue;
      updateSampleCondition();
    } else if (linearCounter > 0) {
      // Decrement:
      linearCounter--;
      updateSampleCondition();
    }

    if (!lcControl) {
      // Clear halt flag:
      lcHalt = false;
    }

  }

  int getLengthStatus() {
    return ((lengthCounter == 0 || !_isEnabled) ? 0 : 1);
  }

  int readReg(int address) {
    return 0;
  }

  void writeReg(int address, int value) {
    if (address == 0x4008) {
      // New values for linear counter:
      lcControl = (value & 0x80) != 0;
      lcLoadValue = value & 0x7F;

      // Length counter enable:
      lengthCounterEnable = !lcControl;
    } else if (address == 0x400A) {
      // Programmable timer:
      progTimerMax &= 0x700;
      progTimerMax |= value;

    } else if (address == 0x400B) {
      // Programmable timer, length counter
      progTimerMax &= 0xFF;
      progTimerMax |= ((value & 0x07) << 8);
      lengthCounter = papu.getLengthMax(value & 0xF8);
      lcHalt = true;
    }

    updateSampleCondition();
  }

  void clockProgrammableTimer(int nCycles) {

    if (progTimerMax > 0) {
      progTimerCount += nCycles;
      while (progTimerMax > 0 && progTimerCount >= progTimerMax) {
        progTimerCount -= progTimerMax;
        if (_isEnabled && lengthCounter > 0 && linearCounter > 0) {
          clockTriangleGenerator();
        }
      }
    }

  }

  void clockTriangleGenerator() {
    triangleCounter++;
    triangleCounter &= 0x1F;
  }

  void setEnabled(bool value) {
    _isEnabled = value;
    if (!value)
      lengthCounter = 0;
    updateSampleCondition();
  }

  bool isEnabled() => _isEnabled;

  void updateSampleCondition() {
    sampleCondition = _isEnabled && progTimerMax > 7 &&
                      linearCounter > 0 && lengthCounter > 0;
  }

  void reset() {
    progTimerCount = 0;
    progTimerMax = 0;
    triangleCounter = 0;
    _isEnabled = false;
    sampleCondition = false;
    lengthCounter = 0;
    lengthCounterEnable = false;
    linearCounter = 0;
    lcLoadValue = 0;
    lcHalt = true;
    lcControl = false;
    tmp = 0;
    sampleValue = 0xF;
  }

  void destroy() {
    papu = null;
  }
}
