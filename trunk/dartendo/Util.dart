class Util {

  // System.arraycopy(rom.getRomBank(bank), 0, cpuMem.mem, address, 16384);
  // arraycopy(Object src, int srcPos, Object dest, int destPos, int length)
  void arraycopy(List<int> src, int srcPos, List<int> dest, int destPos, int length)
  {
    // void setRange(int start, int length, List<E> from, [int startFrom])
    dest.setRange(destPos, length, src, srcPos);
  }
  
  List<int> newIntList(int size, int defaultValue)
  {
    List<int> r = new List<int>(size);
    for(int i = 0; i < size; ++i) r[i] = defaultvalue;
    
    return r;
  }
}
