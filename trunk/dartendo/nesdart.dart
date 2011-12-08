#import('dart:dom');
#source('ByteBuffer.dart');
#source('Util.dart');
#source('CPU.dart');
#source('CpuInfo.dart');
#source('MapperDefault.dart');
#source('MemoryMapper.dart');
#source('Mapper001.dart');
#source('Mapper002.dart');
#source('Mapper003.dart');
#source('Mapper004.dart');
#source('Mapper007.dart');
#source('Mapper009.dart');
#source('Mapper010.dart');
#source('Mapper011.dart');
#source('Mapper015.dart');
#source('Mapper018.dart');
#source('Mapper021.dart');
#source('Mapper022.dart');
#source('Mapper023.dart');
#source('Mapper032.dart');
#source('Mapper033.dart');
#source('Mapper034.dart');
#source('Mapper048.dart');
#source('Mapper064.dart');
#source('Mapper066.dart');
#source('Mapper068.dart');
#source('Mapper071.dart');
#source('Mapper072.dart');
#source('Mapper075.dart');
#source('Mapper078.dart');
#source('Mapper079.dart');
#source('Mapper087.dart');
#source('Mapper094.dart');
#source('Mapper105.dart');
#source('Mapper140.dart');
#source('Mapper182.dart');

#source('misc.dart');
#source('NameTable.dart');
#source('PaletteTable.dart');
#source('memory.dart');

class snes {
  var canvas;
  var context;
  var gl;

  snes() {
    canvas = document.getElementById("webGlCanvas");
    context = canvas.getContext('2d');

    window.webkitRequestAnimationFrame(animate, canvas);
    
    //var ac = window.webkitAudioContext();
    //audioContext = new AudioContext();
    
    //var src = audioContext.createBufferSource();
    //src.buffer = audioContext.createBuffer(1 /*channels*/, 2048, 44100);
    //var audioData = src.buffer.getChannelData(0);
    //print(audioData.length);
    //src.looping = true;

    //src.connect(audioContext.destination);

    //src.noteOn(0);
    
    //var audioElement = document.createElement('audio');
    //var ac = audioElement.context();
    //audioElement.setAttribute('src', 'sample.ogg');
    //audioElement.play();
    
    int x = 3;
    int y = x & 4;
    print(y);
    
    switch(x) {
    case 1:
      print('1');
      break;
    case 3:
      print('3');
      break;
    }

    List<int> intList = new List<int>(5);
    
    intList[3] = 2;
    print(intList);
  }

  void run() {
  }

  void animate(int time) {
    //print("test: " + time);
    //canvas.width = canvas.width;
    
    //print('Getting imagedata');
    var arr = context.getImageData(0,0,150,50);
    var data = arr.data;
    //print(data.length);
    for (var i=0;i<150*50*4;) {
      //print('Setting pixels');
      data[i++] = 0; // r
      data[i++] = 0; // g
      data[i++] = 0; // b
      data[i++] = 255; // a
    }
    //print('Blitting imagedata');
    var a = 1;
    var b = 2;
    var c = a ~/ b;
    //print(c);
    context.putImageData(arr, 0, 0, 0,   0, 150, 50);
    
    window.webkitRequestAnimationFrame(animate, canvas);
  }
}

void main() {
  new snes().run();
}
