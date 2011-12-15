Audio = function(bufferSize) {
  var that = this;
  var context = new webkitAudioContext();
  this.bufferSize = bufferSize;
  this.context = context;
  // TODO: should be 1, 2 for channels I think. Maybe 2, 2 makes more sense.
  this.node = context.createJavaScriptNode(bufferSize, 2, 2);
  this.node.onaudioprocess = function(e) { that.process(e); }

  this.bufferL = null;
  this.bufferR = null;
  this.dataAvailable = false;

  this.play();
}

Audio.prototype.write = function(bufferL, bufferR) {
  this.bufferL = bufferL;
  this.bufferR = bufferR;
  this.dataAvailable = true;
}

Audio.prototype.process = function(e) {
  if (!this.dataAvailable)
    return;

  var dataL = e.outputBuffer.getChannelData(0);
  var dataR = e.outputBuffer.getChannelData(1);
  for (var i = 0; i < this.bufferSize; ++i) {
    dataL[i] = this.bufferL[i];
    dataR[i] = this.bufferR[i];
  }
  this.dataAvailable = false;
}

Audio.prototype.play = function() {
  this.node.connect(this.context.destination);
}

Audio.prototype.stop = function() {
  this.node.disconnect();
}
