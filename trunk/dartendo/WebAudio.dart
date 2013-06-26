part of dartendo;

class WebAudio {
  AudioContext _context = null;
  int _bufferSize;
  ScriptProcessorNode _node;

  List<double> _bufferL = null;
  List<double> _bufferR = null;
  bool _dataAvailable = false;

  WebAudio(this._bufferSize) {
    _bufferL = new List<double>(_bufferSize);
    _bufferR = new List<double>(_bufferSize);
    if (AudioContext.supported) {
      _context = new AudioContext();
      _node = _context.createJavaScriptNode(_bufferSize, 2, 2);
      _node.onAudioProcess.listen(_process);
  
      _play();
    }
  }

  void write(List<double> bufferL, List<double> bufferR) {
    //print(bufferL[0]);
    for (var i = 0; i < _bufferSize; ++i) {
      _bufferL[i] = bufferL[i];
      _bufferR[i] = bufferR[i];
    }
    _dataAvailable = true;
  }

  void _play() {
    if (AudioContext.supported) {
      _node.connect(_context.destination, 0, 0);
    }
  }

  void _stop() {
    if (AudioContext.supported) {
      _node.disconnect(0);
      _node.disconnect(1);
    }
  }

  bool get dataAvailable => _dataAvailable;

  void _process(AudioProcessingEvent e) {
    if (!_dataAvailable)
      return;

    Float32List bufferL = e.outputBuffer.getChannelData(0);
    Float32List bufferR = e.outputBuffer.getChannelData(1);
    for (var i = 0; i < _bufferSize; ++i) {
      bufferL[i] = _bufferL[i];
      bufferR[i] = _bufferR[i];
    }
    //print("audio data processed");
    _dataAvailable = false;
  }
}
