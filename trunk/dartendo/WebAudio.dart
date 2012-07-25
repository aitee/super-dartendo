class WebAudio {
  AudioContext _context;
  int _bufferSize;
  JavaScriptAudioNode _node;

  List<double> _bufferL = null;
  List<double> _bufferR = null;
  bool _dataAvailable = false;

  WebAudio(this._bufferSize)
      : _context = new AudioContext() {
    _node = _context.createJavaScriptNode(_bufferSize, 2, 2);
    _node.on.audioProcess.add(_process);

    _play();
  }

  void write(List<double> bufferL, List<double> bufferR) {
    _bufferL = bufferL;
    _bufferR = bufferR;
    _dataAvailable = true;
    print("audio data ready");
  }

  void _play() {
    _node.connect(_context.destination, 0, 0);
   // _node.connect(_context.destination, 1, 1);
  }

  void _stop() {
    _node.disconnect(0);
   // _node.disconnect(1);
  }

  bool get dataAvailable() => _dataAvailable;

  void _process(AudioProcessingEvent e) {
    if (!_dataAvailable)
      return;

    Float32Array bufferL = e.outputBuffer.getChannelData(0);
    Float32Array bufferR = e.outputBuffer.getChannelData(1);
    for (var i = 0; i < _bufferSize; ++i) {
      bufferL[i] = _bufferL[i];
      bufferR[i] = _bufferR[i];
    }
    print("audio data processed");
    _dataAvailable = false;
  }
}
