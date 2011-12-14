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

class ChannelNoise implements PapuChannel {

  PAPU papu = null;
  bool _isEnabled = false;
  bool envDecayDisable = false;
  bool envDecayLoopEnable = false;
  bool lengthCounterEnable = false;
  bool envReset = false;
  bool shiftNow = false;
  int lengthCounter = 0;
  int progTimerCount = 0;
  int progTimerMax = 0;
  int envDecayRate = 0;
  int envDecayCounter = 0;
  int envVolume = 0;
  int masterVolume = 0;
  int shiftReg = 0;
  int randomBit = 0;
  int randomMode = 0;
  int sampleValue = 0;
  int accValue = 0; //changed from long to int
  int accCount = 1; //changed from long to int
  int tmp = 0;

  ChannelNoise(this.papu) {
    shiftReg = 1;
  }

  void clockLengthCounter() {
    if (lengthCounterEnable && lengthCounter > 0) {
      lengthCounter--;
      if (lengthCounter == 0)
        updateSampleValue();
    }
  }

  void clockEnvDecay() {

    if (envReset) {
      // Reset envelope:
      envReset = false;
      envDecayCounter = envDecayRate + 1;
      envVolume = 0xF;
    } else if (--envDecayCounter <= 0) {
      // Normal handling:
      envDecayCounter = envDecayRate + 1;
      if (envVolume > 0)
        envVolume--;
      else
        envVolume = envDecayLoopEnable ? 0xF : 0;

    }

    masterVolume = envDecayDisable ? envDecayRate : envVolume;
    updateSampleValue();

  }

  void updateSampleValue() {
    if (_isEnabled && lengthCounter > 0)
      sampleValue = randomBit * masterVolume;
  }

  void writeReg(int address, int value) {

    if (address == 0x400C) {

      // Volume/Envelope decay:
      envDecayDisable = ((value & 0x10) != 0);
      envDecayRate = value & 0xF;
      envDecayLoopEnable = ((value & 0x20) != 0);
      lengthCounterEnable = ((value & 0x20) == 0);
      masterVolume = envDecayDisable ? envDecayRate : envVolume;

    } else if (address == 0x400E) {

      // Programmable timer:
      progTimerMax = papu.getNoiseWaveLength(value & 0xF);
      randomMode = value >> 7;

    } else if (address == 0x400F) {

      // Length counter
      lengthCounter = papu.getLengthMax(value & 248);
      envReset = true;

    }

    // Update:
    //updateSampleValue();

  }

  void setEnabled(bool value) {

    _isEnabled = value;
    if (!value)
      lengthCounter = 0;
    updateSampleValue();

  }

  bool isEnabled() => _isEnabled;

  int getLengthStatus() {
    return ((lengthCounter == 0 || !_isEnabled) ? 0 : 1);
  }

  void reset() {
    progTimerCount = 0;
    progTimerMax = 0;
    _isEnabled = false;
    lengthCounter = 0;
    lengthCounterEnable = false;
    envDecayDisable = false;
    envDecayLoopEnable = false;
    shiftNow = false;
    envDecayRate = 0;
    envDecayCounter = 0;
    envVolume = 0;
    masterVolume = 0;
    shiftReg = 1;
    randomBit = 0;
    randomMode = 0;
    sampleValue = 0;
    tmp = 0;
  }

  void destroy() {
    papu = null;
  }
}
