// This is just a dummied out version of javax.sound.sampled.SourceDataLine
// Author: bendoug@google.com (Ben Douglass)

// === native methods ===
//Called in Player
AudioContext newAudioContext() native
  "return new webkitAudioContext();";

AudioDestinationNode getDestination(AudioContext context) native
  "return context.destination;";

// Called in newGenerator 
num getSampleRate(AudioContext context) native
  "return context.sampleRate;";

List getOutputBufferArray(AudioProcessingEvent event) native
"return event.outputBuffer.getChannelData(0);";

void setOnAudioProcess(JavaScriptAudioNode node, Function handler) native
"node.onaudioprocess = handler;";
// === Ends native methods ===

class SourceDataLine {
  
  bool debugMe = false;
  
  Controller controller = null;
  
  AudioContext context;
  AudioNode playing = null;
  
  bool active = false;  
  bool open = true;
  
  int soundBufferSize;
  List<int> soundBuffer;
  
  int availableCount = 0;
  int writeOffset = 0;
  int readOffset = 0;
  
  // 
  SourceDataLine(Controller controllerIn) {
    controller = controllerIn;
    
    soundBufferSize = (0xFFFF + 1);
    soundBuffer = Util.newIntList(soundBufferSize, 0);
    
    availableCount = soundBufferSize;
    
    Util.printDebug('SoundDataLine.Constructor(): soundBufferSize = ' + soundBufferSize, debugMe);
    
    context = newAudioContext();
    play();
    active = true;
    
  }
  
  AudioNode newGenerator(AudioContext context) {
    void handler(AudioProcessingEvent event) {
      
      if(controller.sleepTime <= -16) { //We are too far behind, skip the frame
        //print("Skipping render");
        return;
      }
      
      var buffer = getOutputBufferArray(event);
      
      Util.printDebug('SourceDataLine.newGenerator.handler: buffer.length = ' + buffer.length, debugMe);
      for (var i = 0; i < buffer.length; i++) {
         buffer[i] = (soundBuffer[readOffset] / 32768.0) - 1.0;
         if (readOffset != writeOffset) {
           readOffset = (readOffset + 1) & 0xFFFF;
         }
         // buffer[i] = (Math.random() < 0.5) ? 1.0 : -1.0;
      }
    }

    var node = context.createJavaScriptNode(4096);
    setOnAudioProcess(node, handler);
    return node;
  }
    
  void play() {
    Util.printDebug('SourceDataLine.play(): begins', debugMe);
    
    playing = newGenerator(context);
    //getDestination: native method
    playing.connect(getDestination(context));
  }
  
  void stop() {
    if (playing != null) {
      playing.disconnect();
      playing = null;
    }
  }
  
  // Called by PAPU.writeBuffer()
  int write(List<int> sampleBuffer, int off, int len)
  {
     // Util.printDebug('SourceDataLine.write(): len = ' + len, debugMe);
     for (int i = 0; i < len; i += 2) {
       soundBuffer[writeOffset] = (sampleBuffer[i + 1] | (sampleBuffer[i] << 8));
       writeOffset = (writeOffset + 1) & 0xFFFF;
       //++availableCount++;
     }
     
     return len;
  }
  
  bool isActive() {
    Util.printDebug('SourceDataLine.isActive()', debugMe);
    return active;
  }
  
  bool isOpen() {
    Util.printDebug('SourceDataLine.isOpen()', debugMe);
    return open;
  }
  
  void close() 
  {
    Util.printDebug('SourceDataLine.close(): begins', debugMe);
    stop();
    active = false;
    open = false;
  }
  
  int available() {
    return availableCount;
  }
  
  int getBufferSize(){
    return soundBufferSize;
  }
}
