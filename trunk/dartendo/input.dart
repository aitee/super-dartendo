class Input {
  
  bool debugMe = false;
  List<int> romBytes;
  Controller controller;
  
  Input(this.controller);

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
    if (Controller.getQueryValue('rom').length > 0) {
      defaultRom = 'roms/' + Controller.getQueryValue('rom') + '.json';
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
        List<int> fromFileBytes = new dom.Uint8Array.fromBuffer(reader.result);
        romBytes = fromFileBytes;
        controller.run();
      } else {
        window.setTimeout(handler, 100);
      }
    })();
  }
}
