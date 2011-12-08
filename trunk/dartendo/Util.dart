class Util {

  void arraycopy(List<int> src, int srcPos, List<int> dest, int destPos, int length)
  {
    dest.setRange(destPos, length, src, srcPos);
  }
}
