WebAudio = function(bufferSize) {
  var that = this;
  
  if (!window.AudioContext) {
    if (window.webkitAudioContext)
      window.AudioContext = window.webkitAudioContext;
    else if (window.Audio)
      window.AudioContext = window.Audio;
  }

  var context = new AudioContext();
  this.bufferSize = bufferSize;
  this.context = context;
  if (window.webkitAudioContext) {
    // TODO: should be 1, 2 for channels I think. Maybe 2, 2 makes more sense.
    this.node = context.createJavaScriptNode(bufferSize, 2, 2);
    this.node.onaudioprocess = function(e) { that.process(e); }
  } else {
    context.mozSetup(2, 44100);
    window.setInterval(this.process, 100);
  }

  this.bufferL = null;
  this.bufferR = null;
  this.dataAvailable = false;

  this.play();
}

WebAudio.prototype.write = function(bufferL, bufferR) {
  this.bufferL = bufferL;
  this.bufferR = bufferR;
  this.dataAvailable = true;
}

WebAudio.prototype.isDataAvailable = function() {
  return this.dataAvailable?1:0;
}

WebAudio.prototype.process = function(e) {
  if (!this.dataAvailable)
    return;

  if (window.webkitAudioContext) {
    var dataL = e.outputBuffer.getChannelData(0);
    var dataR = e.outputBuffer.getChannelData(1);
    for (var i = 0; i < this.bufferSize; ++i) {
      dataL[i] = this.bufferL[i];
      dataR[i] = this.bufferR[i];
    }
  } else {
    data = new Float32Array(2 * this.bufferSize);
    for (var i = 0; i < this.bufferSize; ++i) {
      data[2*i] = this.bufferL[i];
      data[2*i + 1] = this.bufferR[i];
    }
    this.context.mozWriteAudio(data);  
  }
  this.dataAvailable = false;
}

WebAudio.prototype.play = function() {
  if (this.node)
    this.node.connect(this.context.destination);
}

WebAudio.prototype.stop = function() {
  if (this.node)
    this.node.disconnect();
}
