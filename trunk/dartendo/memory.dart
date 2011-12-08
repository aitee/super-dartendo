class Memory{
  
  List<int> mem;
  int memLength;
  NES nes;
  
  Memory(NES nes, int byteCount) {
    this.nes = nes;
    mem = Util.newIntList(byteCount, 0);
    memLength = byteCount;
  }
  
  void stateLoad(ByteBuffer buf){
    if(mem == null) {
      mem = Util.newIntList(memLength, 0);
    }
    buf.readByteArray(mem);
  }
  
  void stateSave(ByteBuffer buf) {
    buf.putByteArray(mem);
  }
  
  void reset(){
    for(int i=0; i<mem.length; i++) mem[i] = 0;
  }
  
  int getMemSize() => memLength;
  
  void write(int address, int value) {
    mem[address] = value;
  }
  
  int load(int address) => mem[address];
  
  void dump(String file) {
    dumpPosition(file,0,mem.length);
  }
  
  // iainmcgin: formerly just dump
  void dumpPosition(String file, int offset, int length) {
    /* iainmcgin: original code, but not useful in dart?
    char[] ch = new char[length];
    for(int i=0;i<length;i++){
      ch[i] = (char)mem[offset+i];
    }
    
    try{
      
      File f = new File(file);
      FileWriter writer = new FileWriter(f);
      writer.write(ch);
      writer.close();
      //System.out.println("Memory dumped to file "+file+".");
      
    }catch(IOException ioe){
      //System.out.println("Memory dump to file: IO Error!");
    }
    */
  }
  
  // iainmcgin: formerly known as write
  void writeList(int address, List<int> array, int length) {
    // iainmcgin: refactored to point to writeListWithOffset
    writeListWithOffset(address, array, 0, length);
  }
  
  // iainmcgin: formerly known as write
  void writeListWithOffset(int address, List<int> array, int arrayoffset, int length) {
    if(address + length > mem.length) return;
    mem.setRange(address, length, array, arrayoffset);
  }
  
  void destroy() {
    nes = null;
    mem = null;
  }
}