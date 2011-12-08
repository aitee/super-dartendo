// This is just a dummied out version of javax.sound.sampled.SourceDataLine
// Author: bendoug@google.com (Ben Douglass)

class SourceDataLine {
  int write(List<int> b, int off, int len) => len;
  
  bool isActive() => false;
  
  bool isOpen() => false;
  
  void close() {}
  
  int available() => 0;
  
  int getBufferSize() => 0;
}

