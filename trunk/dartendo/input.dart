class Input {
  
  Controller controller;
  List<int> romBytes;
  Element menuElement;
  
  Input(this.controller) {
    this.menuElement = document.query('#menu');  
  }
  
  void toggleMenu() {
    if (menuElement.style.bottom == '0px') {
      menuElement.style.transition = 'bottom 0.2s';
      menuElement.style.bottom = '-21ex';
    } else {
      menuElement.style.transition = 'bottom 0.2s';
      menuElement.style.bottom = '0';
    }
  }

  void init() {
    // Menu handler
    Element menuLabel = document.query('#roms-label');
    Element content = document.query('#roms-content');
    InputElement input = document.query('#input-file');

    menuLabel.on.click.add((EventWrappingImplementation event) {
      print("menu click");
      unwrapDomObject(event).preventDefault();
      toggleMenu();
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
      return false;
    });
  
    content.on.dragOver.add((EventWrappingImplementation event) {
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
      loadFile(new FileWrappingImplementation._wrap(unwrapDomObject(event).dataTransfer.files[0]));
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
        toggleMenu();
        controller.run();
      } else {
        window.setTimeout(handler, 100);
      }
    })();
  }
}
