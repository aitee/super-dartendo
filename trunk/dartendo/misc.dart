part of dartendo;

class MiscClass {
  bool debug = false;
  // TODO: wtf?
  List<double> rnd;
  int nextRnd = 0;
  double rndret = 0.0;

  MiscClass() {
    debug = Globals.debug;
    rnd = Util.newDoubleList(10000, 0.0);
    var rng = new Math.Random();
    for (int i = 0; i < rnd.length; i++) {
      rnd[i] = rng.nextDouble();
    }
  }
/*
  String hex8(int i) {
    String s = i.toRadixString(16);
    while (s.length < 2) {
      s = "0" + s;
    }
    return s.toUpperCase();
  }

  String hex16(int i) {
    String s = i.toRadixString(16);
    while (s.length < 4) {
      s = "0" + s;
    }
    return s.toUpperCase();
  }*/
/*
  String binN(int num, int N) {
    // iainmcgin: refactored to use toRadixString rather
    // than manual shift-compare on bits
    // TODO: will this actually work with negative numbers
    // as intended?
    String binString = num.toRadixString(2);
    while(binString.length < N) {
      binString = '0' + binString;
    }
  }

  String bin8(int num) => binN(num, 8);
  String bin16(int num) => binN(num, 16);

  String binStr(int value, int bitcount) {
    String ret = "";
    for (int i = 0; i < bitcount; i++) {
      ret = ((value & (1 << i)) != 0 ? "1" : "0") + ret;
    }
    return ret;
  }
*/
  List<int> resizeArray(List<int> array, int newSize) {
    List<int> newArr = Util.newIntList(newSize, 0);
    Util.arraycopy(array, 0, newArr, 0, Math.min(newSize, array.length));        
    return newArr;
  }
/*
  String pad(String str, String padStr, int length) {
    while (str.length < length) {
      str += padStr;
    }
    return str;
  }
*/
  /*
  double random() {
    rndret = rnd[nextRnd];
    nextRnd++;
    if (nextRnd >= rnd.length) {
      nextRnd = (Math.random() * (rnd.length - 1)).toInt();
    }
    return rndret;
  }*/
}


MiscClass Misc;
