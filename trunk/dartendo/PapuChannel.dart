part of dartendo;

abstract class PapuChannel {

    void writeReg(int address, int value);

    void setEnabled(bool value);

    bool isEnabled();

    void reset();

    int getLengthStatus();
}