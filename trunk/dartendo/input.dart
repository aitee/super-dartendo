class Input {
  
  bool debugMe = false;
  List<int> romBytes;
  
  void init() {
    // Content section used a lot
    Element content = document.query('#content');
    InputElement input = document.query('#input-file');

    // Input handler
    input.on.change.add((EventWrappingImplementation event) {
      print("onchange");
      unwrapDomObject(event).preventDefault();
      File inputFile = input.files.item(0);
      loadFile(inputFile);
    });
    
    // Default ROM
    String defaultRom = 'roms/SuperMario3.json';
    if (window.location.href.indexOf('rom=') >= 0) {
      defaultRom = 'roms/' + window.location.href.substring(
        window.location.href.indexOf('rom=')+4)+'.json';
    }
    
    final req = new XMLHttpRequest();
    req.open('GET', '${FileLoader.home}/$defaultRom', false);
    req.send();    
    
    romBytes = JSON.parse(req.responseText); 

      
    // Add dragging events
//    content.on.dragEnter.add((Event event) {
//      Util.printDebug("Input.init(): content.on.dragEnter Event fired.", debugMe);
//      unwrapDomObject(event).preventDefault();
//      content.style.border = '4px solid #b1ecb3';
//      return false;
//    });
//  
//    content.on.dragOver.add((Event event) {
//      unwrapDomObject(event).preventDefault();
//      return false;
//    });
//  
//    content.on.dragLeave.add((Event event) {
//      unwrapDomObject(event).preventDefault();
//      return false;
//    });
//  
//    content.on.drop.add((Event event) {
//      unwrapDomObject(event).preventDefault();
//      content.style.border = '4px solid transparent';
//      loadFile(unwrapDomObject(event).dataTransfer.files[0]);
//      return false;
//    });
  }

  void loadFile(FileWrappingImplementation file) {
    document.query('#name').text = file.fileName;
    document.query('#size').text = file.fileSize;

    dom.FileReader reader = new dom.FileReader();
    reader.readAsArrayBuffer(unwrapDomObject(file));

    (handler() {
      if (reader.readyState == 2) {
        document.query('#file-content').text = reader.result;
        romBytes = reader.result;
      } else {
        window.setTimeout(handler, 100);
      }
    })();
  }
}
