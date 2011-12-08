class CUtil {

  // System.arraycopy(rom.getRomBank(bank), 0, cpuMem.mem, address, 16384);
  // arraycopy(Object src, int srcPos, Object dest, int destPos, int length)
  void arraycopy(List<int> src, int srcPos, List<int> dest, int destPos, int length)
  {
    // void setRange(int start, int length, List<E> from, [int startFrom])
    //dest.setRange(destPos, length, src, srcPos);
    for (var i = 0 ; i < length ; i++) {
      dest[destPos+i] = src[srcPos+i];
    }
  }

  void arrayTileCopy(List<Tile> src, int srcPos, List<Tile> dest, int destPos, int length)
  {
    // void setRange(int start, int length, List<E> from, [int startFrom])
    //dest.setRange(destPos, length, src, srcPos);
    for (var i = 0 ; i < length ; i++) {
      dest[destPos+i] = src[srcPos+i];
    }
  }

  List<double> newDoubleList(int size, double defaultValue)  {
    List<double> r = new List<double>(size);
    for (int i = 0; i < size; ++i) r[i] = defaultValue;
    return r;
  }

  List<int> newIntList(int size, int defaultValue)
  {
    List<int> r = new List<int>(size);
    for(int i = 0; i < size; ++i) r[i] = defaultValue;
    return r;
  }

  List<bool> newBoolList(int size, bool defaultValue)
  {
    List<bool> r = new List<bool>(size);
    for(int i = 0; i < size; ++i) r[i] = defaultValue;
    
    return r;
  }

  List<List<int>> newIntList2d(int size1, int size2, int defaultValue)
  {
    List<List<int>> r = new List<List<int>>(size1);
    for(int i = 0; i < size1; ++i) {
    	    r[i] = new List<int>(size2);
	    for(int j=0;j < size2 ; j++) {
               r[i][j] = defaultValue;
            }
    }

    return r;
  }
  
}

CUtil Util = null;
