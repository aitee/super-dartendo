/*
vNES
Copyright © 2011 Occupy Nintendo

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General  License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General  License for more details.

You should have received a copy of the GNU General  License along with
this program.  If not, see <http://www.gnu.org/licenses/>.
 */

 class ByteBuffer {

      final int DEBUG = false;
      final int BO_BIG_ENDIAN = 0;
      final int BO_LITTLE_ENDIAN = 1;
     int byteOrder = 1;
     List<int> buf;
     int size;
     int curPos;
     bool hasBeenErrors;
     bool expandable = true;
     int expandBy = 4096;

     ByteBuffer(int size, int byteOrdering) {
        if (size < 1) {
            size = 1;
        }
        buf = new List<int>(size);
        this.size = size;
        this.byteOrder = byteOrdering;
        curPos = 0;
        hasBeenErrors = false;
    }

     ByteBuffer.fromArray(List<int> content, int byteOrdering) {
        try {
            buf = new List<int>(content.length);
            for (int i = 0; i < content.length; i++) {
                buf[i] = (content[i] & 255);
            }
            size = content.length;
            this.byteOrder = byteOrdering;
            curPos = 0;
            hasBeenErrors = false;
        } catch (Exception e) {
            //System.out.println("ByteBuffer: Couldn't create buffer from empty array.");
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

     void setByteOrder(int byteOrder) {

        if (byteOrder >= 0 && byteOrder < 2) {
            this.byteOrder = byteOrder;
        }

    }

     List<int> getBytes() {
       List<int> ret = new List<int>(buf.length);
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
        if (inRange(start, length)) {
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

        List<int> newbuf = new List<int>(length);
        System.arraycopy(buf, 0, newbuf, 0, Math.min(length, size));
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

     int inRange(int pos) {
        if (pos >= 0 && pos < size) {
            return true;
        } else {
            if (expandable) {
                expand(Math.max(pos + 1 - size, expandBy));
                return true;
            } else {
                return false;
            }
        }
    }

     int inRangeWithLength(int pos, int length) {
        if (pos >= 0 && pos + (length - 1) < size) {
            return true;
        } else {
            if (expandable) {
                expand(Math.max(pos + length - size, expandBy));
                return true;
            } else {
                return false;
            }
        }
    }

     int putint(int b) {
        int ret = putint(b, curPos);
        move(1);
        return ret;
    }

     int putintWithPosition(int b, int pos) {
        if (b) {
            return putByte(1, pos);
        } else {
            return putByte(0, pos);
        }
    }

     int putByte(int mybyte) {
        if (inRange(curPos, 1)) {
            buf[curPos] = mybyte;
            move(1);
            return true;
        } else {
            error();
            return false;
        }
    }

     int putByteWithPos(int mybyte, int pos) {
        if (inRange(pos, 1)) {
            buf[pos] = mybyte;
            return true;
        } else {
            error();
            return false;
        }
    }

     int putShort(int myshort) {
        int ret = putShortWithPos(myshort, curPos);
        if (ret) {
            move(2);
        }
        return ret;
    }

     int putShortWithPos(int myshort, int pos) {
        if (inRange(pos, 2)) {
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

     int putInt(int myint) {
        int ret = putIntWithPos(myint, curPos);
        if (ret) {
            move(4);
        }
        return ret;
    }

     int putIntWithPos(int myint, int pos) {
        if (inRange(pos, 4)) {
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

     int putString(String myString) {
        int ret = putString(myString, curPos);
        if (ret) {
            move(2 * myString.length);
        }
        return ret;
    }

     int putStringWithPos(String myString, int pos) {
        int theChar;
        if (inRange(pos, myString.length() * 2)) {
            for (int i = 0; i < myString.length(); i++) {
                theChar = (myString.charCodeAt(i));
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

     int putChar(int myChar) {
        int ret = putChar(myChar, curPos);
        if (ret) {
            move(2);
        }
        return ret;
    }

     int putCharWithPos(int myChar, int pos) {
        int tmp = myChar;
        if (inRange(pos, 2)) {
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

     int putCharAscii(char myvar) {
        int ret = putCharAscii(myvar, curPos);
        if (ret) {
            move(1);
        }
        return ret;
    }

     int putCharAsciiWithPosition(char myvar, int pos) {
        if (inRange(pos)) {
            buf[pos] = myvar;
            return true;
        } else {
            error();
            return false;
        }
    }

     int putStringAscii(String myvar) {
        bool ret = putStringAscii(myvar, curPos);
        if (ret) {
            move(myvar.length());
        }
        return ret;
    }

     int putStringAsciiWithPosition(String myvar, int pos) {
        String charArr = myvar.toCharArray();
        if (inRange(pos, myvar.length())) {
            for (int i = 0; i < myvar.length(); i++) {
                buf[pos] = charArr[i];
                pos++;
            }
            return true;
        } else {
            error();
            return false;
        }
    }

     int putByteArray(List<int> arr) {
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

     int readByteArray(List<int> arr) {
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

     int putShortArray(List<int> arr) {
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
            strBuf.append((char) (tmp));
        }
        return strBuf.toString();
    }

     String toStringAscii() {
        StringBuffer strBuf = new StringBuffer();
        for (int i = 0; i < size; i++) {
            strBuf.append((char) (buf[i]));
        }
        return strBuf.toString();
    }

     int readBoolean() {
        int ret = readint(curPos);
        move(1);
        return ret;
    }

     int readBooleanWithPosition(int pos) {
        return readByte(pos) == 1;
    }

     int readByte() {
        int ret = readByte(curPos);
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
        int ret = readShort(curPos);
        move(2);
        return ret;
    }

     int readShortWithPosition(int pos) {
        if (inRange(pos, 2)) {
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
        int ret = readInt(curPos);
        move(4);
        return ret;
    }

     int readIntWithPosition(int pos) {
        int ret = 0;
        if (inRange(pos, 4)) {
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
        int ret = readChar(curPos);
        move(2);
        return ret;
    }

     int readCharWithPosition(int pos) {
        if (inRange(pos, 2)) {
            return (char) (readShort(pos));
        } else {
            error();
        }
    }

     int readCharAscii() {
        int ret = readCharAscii(curPos);
        move(1);
        return ret;
    }

     int readCharAsciiWithPosition(int pos) {
        if (inRange(pos, 1)) {
            return (char) (readByte(pos) & 255);
        } else {
            error();
        }
    }

     String readString(int length) {
        if (length > 0) {
            String ret = readString(curPos, length);
            move(ret.length() * 2);
            return ret;
        } else {
            return "";
        }
    }

     String readStringWithPosition(int pos, int length) {
        String tmp = "";
        if (inRange(pos, length * 2) && length > 0) {
            for (int i = 0; i < length; i++) {
                tmp = tmp + readChar(pos + i * 2);
            }
            return tmp;
        } else {
            
        }
    }

     String readStringWithShortLength() {
        String ret = readStringWithShortLength(curPos);
        move(ret.length() * 2 + 2);
        return ret;
    }

     String readStringWithShortLengthAndPosition(int pos) {
        int len;
        if (inRange(pos, 2)) {
            len = readShort(pos);
            if (len > 0) {
                return readString(pos + 2, len);
            } else {
                return "";
            }
        } else {
            
        }
    }

     String readStringAscii(int length) {
        String ret = readStringAscii(curPos, length);
        move(ret.length());
        return ret;
    }

     String readStringAsciiWithPosition(int pos, int length) {
        String tmp = "";
        if (inRange(pos, length) && length > 0) {
            for (int i = 0; i < length; i++) {
                tmp = tmp + readCharAscii(pos + i); //JJG: MAKE THIS USE String.fromCharCodes
            }
            return tmp;
        } else {
          print('INVALID STRING READ');
        }
    }

     String readStringAsciiWithShortLength() {
        String ret = readStringAsciiWithShortLength(curPos);
        move(ret.length() + 2);
        return ret;
    }

     String readStringAsciiWithShortLengthAndPosition(int pos) {
        int len;
        if (inRange(pos, 2)) {
            len = readShort(pos);
            if (len > 0) {
                return readStringAscii(pos + 2, len);
            } else {
                return "";
            }
        } else {
            
        }
    }

     List<int> expandShortArray(List<int> array, int size) {
        List<int> newArr = new List<int>(array.length + size);
        if (size > 0) {
            System.arraycopy(array, 0, newArr, 0, array.length);
        } else {
            System.arraycopy(array, 0, newArr, 0, newArr.length);
        }
        return newArr;
    }

     void crop() {
        if (curPos > 0) {
            if (curPos < buf.length) {
                List<int> newBuf = new List<int>(curPos);
                System.arraycopy(buf, 0, newBuf, 0, curPos);
                buf = newBuf;
            }
        } else {
            //System.out.println("Could not crop buffer, as the current position is 0. The buffer may not be empty.");
        }
    }

      ByteBuffer asciiEncode(ByteBuffer buf) {

        List<int> data = buf.buf;
        List<int> enc = new List<int>(buf.getSize() * 2);

        int encpos = 0;
        int tmp;
        for (int i = 0; i < data.length; i++) {

            tmp = data[i];
            enc[encpos] = (byte) (65 + (tmp) & 0xF);
            enc[encpos + 1] = (byte) (65 + (tmp >> 4) & 0xF);
            encpos += 2;

        }
        return new ByteBuffer(enc, BO_BIG_ENDIAN);

    }

      ByteBuffer asciiDecode(ByteBuffer buf) {
        return null;
    }

}
 
 