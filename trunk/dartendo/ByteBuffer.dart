part of dartendo;

class MemByteBuffer {
  bool debugMe = true;

  final bool DEBUG = false;
  final int BO_BIG_ENDIAN = 0;
  final int BO_LITTLE_ENDIAN = 1;

  int byteOrder = 1;
  List<int> buf;
  int size = 0;
  int curPos = 0;
  bool hasBeenErrors = false;
  bool expandable = true;
  int expandBy = 4096;

  MemByteBuffer(int size, int byteOrdering) {
    if (size < 1) {
      size = 1;
    }
    buf = Util.newIntList(size, 0);
    this.size = size;
    this.byteOrder = byteOrdering;
    curPos = 0;
    hasBeenErrors = false;
  }

  MemByteBuffer.fromArray(List<int> content, int byteOrdering) {
    try {
      buf = Util.newIntList(content.length, 0);
      for (int i = 0; i < content.length; i++) {
        buf[i] = (content[i] & 255);
      }
      size = content.length;
      this.byteOrder = byteOrdering;
      curPos = 0;
      hasBeenErrors = false;
    } catch (e) {
      print("MemByteBuffer: Couldn't create buffer from empty array.");
    }
  }

  void setExpandable(bool exp) {
    expandable = exp;
  }

  void setExpandBy(int expBy) {

    if (expBy > 1024) {
      this.expandBy = expBy;
    }

  }

  void setByteOrder(int bo) {

    if (bo >= 0 && bo < 2) {
      byteOrder = bo;
    }

  }

  List<int> getBytes() {
    List<int> ret = Util.newIntList(buf.length, 0);
    for (int i = 0; i < buf.length; i++) {
      ret[i] = buf[i];
    }
    return ret;
  }

  int getSize() {
    return this.size;
  }

  int getPos() {
    return curPos;
  }

  void error() {
    hasBeenErrors = true;
    //System.out.println("Not in range!");
  }

  bool hasHadErrors() {
    return hasBeenErrors;
  }

  void clear() {
    for (int i = 0; i < buf.length; i++) {
      buf[i] = 0;
    }
    curPos = 0;
  }

  void fill(int value) {
    for (int i = 0; i < size; i++) {
      buf[i] = value;
    }
  }

  bool fillRange(int start, int length, int value) {
    if (inRangeWithLength(start, length)) {
      for (int i = start; i < (start + length); i++) {
        buf[i] = value;
      }
      return true;
    } else {
      error();
      return false;
    }
  }

  void resize(int length) {

    List<int> newbuf = Util.newIntList(length,0);
    Util.arraycopy(buf, 0, newbuf, 0, Math.min(length, size));
    buf = newbuf;
    size = length;

  }

  void resizeToCurrentPos() {
    resize(curPos);
  }

  void expand() {
    expandBySize(expandBy);
  }

  void expandBySize(int byHowMuch) {
    resize(size + byHowMuch);
  }

  void goTo(int position) {
    if (inRange(position)) {
      curPos = position;
    } else {
      error();
    }
  }

  void move(int howFar) {
    curPos += howFar;
    if (!inRange(curPos)) {
      curPos = size - 1;
    }
  }

  bool inRange(int pos) {
    if (pos >= 0 && pos < size) {
      return true;
    } else {
      if (expandable) {
        expandBySize(Math.max(pos + 1 - size, expandBy));
        return true;
      } else {
        return false;
      }
    }
  }

  bool inRangeWithLength(int pos, int length) {
    if (pos >= 0 && pos + (length - 1) < size) {
      return true;
    } else {
      if (expandable) {
        expandBySize(Math.max(pos + length - size, expandBy));
        return true;
      } else {
        return false;
      }
    }
  }

  bool putBoolean(bool b) {
    bool ret = putBooleanWithPosition(b, curPos);
    move(1);
    return ret;
  }

  bool putBooleanWithPosition(bool b, int pos) {
    if (b) {
      return putByteWithPos(1, pos);
    } else {
      return putByteWithPos(0, pos);
    }
  }

  bool putByte(int mybyte) {
    if (inRangeWithLength(curPos, 1)) {
      buf[curPos] = mybyte;
      move(1);
      return true;
    } else {
      error();
      return false;
    }
  }

  bool putByteWithPos(int mybyte, int pos) {
    if (inRangeWithLength(pos, 1)) {
      buf[pos] = mybyte;
      return true;
    } else {
      error();
      return false;
    }
  }

  bool putShort(int myshort) {
    bool ret = putShortWithPos(myshort, curPos);
    if (ret) {
      move(2);
    }
    return ret;
  }

  bool putShortWithPos(int myshort, int pos) {
    if (inRangeWithLength(pos, 2)) {
      if (this.byteOrder == BO_BIG_ENDIAN) {
        buf[pos + 0] =  ((myshort >> 8) & 255);
        buf[pos + 1] =  ((myshort) & 255);
      } else {
        buf[pos + 1] =  ((myshort >> 8) & 255);
        buf[pos + 0] =  ((myshort) & 255);
      }
      return true;
    } else {
      error();
      return false;
    }
  }

  bool putInt(int myint) {
    bool ret = putIntWithPos(myint, curPos);
    if (ret) {
      move(4);
    }
    return ret;
  }

  bool putIntWithPos(int myint, int pos) {
    if (inRangeWithLength(pos, 4)) {
      if (this.byteOrder == BO_BIG_ENDIAN) {
        buf[pos + 0] =  ((myint >> 24) & 255);
        buf[pos + 1] =  ((myint >> 16) & 255);
        buf[pos + 2] =  ((myint >> 8) & 255);
        buf[pos + 3] =  ((myint) & 255);
      } else {
        buf[pos + 3] =  ((myint >> 24) & 255);
        buf[pos + 2] =  ((myint >> 16) & 255);
        buf[pos + 1] =  ((myint >> 8) & 255);
        buf[pos + 0] =  ((myint) & 255);
      }
      return true;
    } else {
      error();
      return false;
    }
  }

  bool putString(String myString) {
    bool ret = putStringWithPos(myString, curPos);
    if (ret) {
      move(2 * myString.length);
    }
    return ret;
  }

  bool putStringWithPos(String myString, int pos) {
    int theChar;
    if (inRangeWithLength(pos, myString.length * 2)) {
      for (int i = 0; i < myString.length; i++) {
        theChar = (myString.codeUnits[i]);
        buf[pos + 0] = ((theChar >> 8) & 255);
        buf[pos + 1] = ((theChar) & 255);
        pos += 2;
      }
      return true;
    } else {
      error();
      return false;
    }
  }

  bool putChar(int myChar) {
    bool ret = putCharWithPos(myChar, curPos);
    if (ret) {
      move(2);
    }
    return ret;
  }

  bool putCharWithPos(int myChar, int pos) {
    int tmp = myChar;
    if (inRangeWithLength(pos, 2)) {
      if (byteOrder == BO_BIG_ENDIAN) {
        buf[pos + 0] =  ((myChar >> 8) & 255);
        buf[pos + 1] =  ((myChar) & 255);
      } else {
        buf[pos + 1] =  ((myChar >> 8) & 255);
        buf[pos + 0] =  ((myChar) & 255);
      }
      return true;
    } else {
      error();
      return false;
    }
  }

  bool putCharAscii(int myvar) {
    bool ret = putCharAsciiWithPosition(myvar, curPos);
    if (ret) {
      move(1);
    }
    return ret;
  }

  bool putCharAsciiWithPosition(int myvar, int pos) {
    if (inRange(pos)) {
      buf[pos] = myvar;
      return true;
    } else {
      error();
      return false;
    }
  }

  bool putStringAscii(String myvar) {
    bool ret = putStringAsciiWithPosition(myvar, curPos);
    if (ret) {
      move(myvar.length);
    }
    return ret;
  }

  bool putStringAsciiWithPosition(String myvar, int pos) {
    String charArr = myvar;
    if (inRangeWithLength(pos, myvar.length)) {
      for (int i = 0; i < myvar.length; i++) {
        buf[pos] = charArr.codeUnits[i];
        pos++;
      }
      return true;
    } else {
      error();
      return false;
    }
  }

  bool putByteArray(List<int> arr) {
    if (arr == null) {
      return false;
    }
    if (buf.length - curPos < arr.length) {
      resize(curPos + arr.length);
    }
    for (int i = 0; i < arr.length; i++) {
      buf[curPos + i] = arr[i];
    }
    curPos += arr.length;
    return true;
  }

  bool readByteArray(List<int> arr) {
    if (arr == null) {
      return false;
    }
    if (buf.length - curPos < arr.length) {
      return false;
    }
    for (int i = 0; i < arr.length; i++) {
      arr[i] =  (buf[curPos + i] & 0xFF);
    }
    curPos += arr.length;
    return true;
  }

  bool putShortArray(List<int> arr) {
    if (arr == null) {
      return false;
    }
    if (buf.length - curPos < arr.length * 2) {
      resize(curPos + arr.length * 2);
    }
    if (byteOrder == BO_BIG_ENDIAN) {
      for (int i = 0; i < arr.length; i++) {
        buf[curPos + 0] =  ((arr[i] >> 8) & 255);
        buf[curPos + 1] =  ((arr[i]) & 255);
        curPos += 2;
      }
    } else {
      for (int i = 0; i < arr.length; i++) {
        buf[curPos + 1] =  ((arr[i] >> 8) & 255);
        buf[curPos + 0] =  ((arr[i]) & 255);
        curPos += 2;
      }
    }
    return true;
  }

  String toString() {
    StringBuffer strBuf = new StringBuffer();
    int tmp;
    for (int i = 0; i < (size - 1); i += 2) {
      tmp =  ((buf[i] << 8) | (buf[i + 1]));
      strBuf.write(tmp);
    }
    return strBuf.toString();
  }

  String toStringAscii() {
    StringBuffer strBuf = new StringBuffer();
    for (int i = 0; i < size; i++) {
      strBuf.write(buf[i]);
    }
    return strBuf.toString();
  }

  bool readBoolean() {
    bool ret = readBooleanWithPosition(curPos);
    move(1);
    return ret;
  }

  bool readBooleanWithPosition(int pos) {
    return readByteWithPosition(pos) == 1;
  }

  int readByte() {
    int ret = readByteWithPosition(curPos);
    move(1);
    return ret;
  }

  int readByteWithPosition(int pos) {
    if (inRange(pos)) {
      return buf[pos];
    } else {
      error();
    }
  }

  int readShort() {
    int ret = readShortWithPosition(curPos);
    move(2);
    return ret;
  }

  int readShortWithPosition(int pos) {
    if (inRangeWithLength(pos, 2)) {
      if (this.byteOrder == BO_BIG_ENDIAN) {
        return  ((buf[pos] << 8) | (buf[pos + 1]));
      } else {
        return  ((buf[pos + 1] << 8) | (buf[pos]));
      }
    } else {
      error();
    }
  }

  int readInt() {
    int ret = readIntWithPosition(curPos);
    move(4);
    return ret;
  }

  int readIntWithPosition(int pos) {
    int ret = 0;
    if (inRangeWithLength(pos, 4)) {
      if (this.byteOrder == BO_BIG_ENDIAN) {
        ret |= (buf[pos + 0] << 24);
        ret |= (buf[pos + 1] << 16);
        ret |= (buf[pos + 2] << 8);
        ret |= (buf[pos + 3]);
      } else {
        ret |= (buf[pos + 3] << 24);
        ret |= (buf[pos + 2] << 16);
        ret |= (buf[pos + 1] << 8);
        ret |= (buf[pos + 0]);
      }
      return ret;
    } else {
      error();
    }
  }

  int readChar() {
    int ret = readCharWithPosition(curPos);
    move(2);
    return ret;
  }

  int readCharWithPosition(int pos) {
    if (inRangeWithLength(pos, 2)) {
      return (readShortWithPosition(pos));
    } else {
      error();
    }
  }

  int readCharAscii() {
    int ret = readCharAsciiWithPosition(curPos);
    move(1);
    return ret;
  }

  int readCharAsciiWithPosition(int pos) {
    if (inRangeWithLength(pos, 1)) {
      return (readByteWithPosition(pos) & 255);
    } else {
      error();
    }
  }

  String readString(int length) {
    if (length > 0) {
      String ret = readStringWithPosition(curPos, length);
      move(ret.length * 2);
      return ret;
    } else {
      return "";
    }
  }

  String readStringWithPosition(int pos, int length) {
    StringBuffer tmp = new StringBuffer();
    if (inRangeWithLength(pos, length * 2) && length > 0) {
      for (int i = 0; i < length; i++) {
        tmp.write(readCharWithPosition(pos + i * 2));
      }
      return tmp.toString();
    }
  }

  String readStringWithShortLength() {
    String ret = readStringWithShortLengthAndPosition(curPos);
    move(ret.length * 2 + 2);
    return ret;
  }

  String readStringWithShortLengthAndPosition(int pos) {
    int len;
    if (inRangeWithLength(pos, 2)) {
      len = readShortWithPosition(pos);
      if (len > 0) {
        return readStringWithPosition(pos + 2, len);
      } else {
        return "";
      }
    } else {

    }
  }

  String readStringAscii(int length) {
    String ret = readStringAsciiWithPosition(curPos, length);
    move(ret.length);
    return ret;
  }

  String readStringAsciiWithPosition(int pos, int length) {
    StringBuffer tmp = new StringBuffer();
    if (inRangeWithLength(pos, length) && length > 0) {
      for (int i = 0; i < length; i++) {
        tmp.write(readCharAsciiWithPosition(pos + i)); //JJG: MAKE THIS USE String.fromCharCodes
      }
      return tmp.toString();
    } else {
      print('MemByteBuffer.readStringAsciiWithPosition: INVALID STRING READ');
    }
  }

  String readStringAsciiWithShortLength() {
    String ret = readStringAsciiWithShortLengthAndPosition(curPos);
    move(ret.length + 2);
    return ret;
  }

  String readStringAsciiWithShortLengthAndPosition(int pos) {
    int len;
    if (inRangeWithLength(pos, 2)) {
      len = readShortWithPosition(pos);
      if (len > 0) {
        return readStringWithPosition(pos + 2, len);
      } else {
        return "";
      }
    } else {

    }
  }

  List<int> expandShortArray(List<int> array, int s) {
    List<int> newArr = Util.newIntList(array.length + s, 0);
    if (s > 0) {
      Util.arraycopy(array, 0, newArr, 0, array.length);
    } else {
      Util.arraycopy(array, 0, newArr, 0, newArr.length);
    }
    return newArr;
  }

  void crop() {
    if (curPos > 0) {
      if (curPos < buf.length) {
        List<int> newBuf = Util.newIntList(curPos, 0);
        Util.arraycopy(buf, 0, newBuf, 0, curPos);
        buf = newBuf;
      }
    } else {
      //System.out.println("Could not crop buffer, as the current position is 0. The buffer may not be empty.");
    }
  }

  MemByteBuffer asciiEncode(MemByteBuffer buffer) {

    List<int> data = buffer.buf;
    List<int> enc = Util.newIntList(buffer.getSize() * 2, 0);

    int encpos = 0;
    int tmp;
    for (int i = 0; i < data.length; i++) {

      tmp = data[i];
      enc[encpos] = (65 + (tmp) & 0xF);
      enc[encpos + 1] = (65 + (tmp >> 4) & 0xF);
      encpos += 2;

    }
    return new MemByteBuffer.fromArray(enc, BO_BIG_ENDIAN);

  }

  MemByteBuffer asciiDecode(MemByteBuffer buffer) => null;
}
