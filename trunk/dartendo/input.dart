class Input {
  
  bool debugMe = false;
  List<int> romBytes;
  Controller controller;
  
  Input(this.controller);

  void init() {
    // Menu handler
    Element menuLabel = document.query('#roms-label');
    Element menu = document.query('#menu');
    Element content = document.query('#roms-content');
    InputElement input = document.query('#input-file');

    menuLabel.on.click.add((EventWrappingImplementation event) {
      print("menu click");
      unwrapDomObject(event).preventDefault();
      if (menu.style.bottom == '0px') {
        menu.style.transition = 'bottom 0.2s';
        menu.style.bottom = '-21ex';
      } else {
        menu.style.transition = 'bottom 0.2s';
        menu.style.bottom = '0';
      }
    });

    // Input handler
    input.on.change.add((EventWrappingImplementation event) {
      print("onchange");
      unwrapDomObject(event).preventDefault();
      File inputFile = input.files.item(0);
      loadFile(inputFile);
    });
    
    // Default ROM
    String defaultRom = 'roms/SuperMario3.json';
    String romParameter = Controller.getQueryValue('rom');
    if (romParameter != null && romParameter.length > 0) {
      defaultRom = 'roms/' + Controller.getQueryValue('rom') + '.json';
    }
    
    final req = new XMLHttpRequest();
    req.open('GET', '${FileLoader.home}/$defaultRom', false);
    req.send();
    
    romBytes = JSON.parse(req.responseText); 
      
    // Add dragging events
    content.on.dragEnter.add((EventWrappingImplementation event) {
      print("dragEnter");
      unwrapDomObject(event).preventDefault();
      content.style.border = '4px solid #b1ecb3';
      return false;
    });
  
    content.on.dragOver.add((EventWrappingImplementation event) {
      print("dragOver");
      unwrapDomObject(event).preventDefault();
      return false;
    });
  
    content.on.dragLeave.add((EventWrappingImplementation event) {
      print("dragLeave");
      unwrapDomObject(event).preventDefault();
      return false;
    });
  
    content.on.drop.add((EventWrappingImplementation event) {
      print("drop");
      unwrapDomObject(event).preventDefault();
      content.style.border = '4px solid transparent';
      loadFile(unwrapDomObject(event).dataTransfer.files[0]);
      return false;
    });
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
