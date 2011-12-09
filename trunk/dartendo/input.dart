class Input {
  
  bool debugMe = false;
  var fileBytes;
  
  void init() {
    // Content section used a lot
//    Element content = document.query('#content');
    InputElement input = document.query('#input-file');
    /*
    // Input handler
    input.on.change.add((EventWrappingImplementation event) {
      print("onchange");
      unwrapDomObject(event).preventDefault();
      // Uncommenting this line slows everything down.
//      File inputFile = input.files.item(0);
//      loadFile(inputFile);
    });

    // Add dragging events
    content.on.dragEnter.add((Event event) {
      Util.printDebug("Input.init(): content.on.dragEnter Event fired.", debugMe);
      unwrapDomObject(event).preventDefault();
      content.style.border = '4px solid #b1ecb3';
      return false;
    });
  
    content.on.dragOver.add((Event event) {
      unwrapDomObject(event).preventDefault();
      return false;
    });
  
    content.on.dragLeave.add((Event event) {
      unwrapDomObject(event).preventDefault();
      return false;
    });
  
    content.on.drop.add((Event event) {
      unwrapDomObject(event).preventDefault();
      content.style.border = '4px solid transparent';
      loadFile(unwrapDomObject(event).dataTransfer.files[0]);
      return false;
    });
    */
    /*
    inputLoadRom.on.click.add((Event event) {
      print('trying to load: ' + input.files.item(0).fileName);
    }); 
    */
//    content.on.drop.add((Event event) {
//      print("onadd");
//      unwrapDomObject(event).preventDefault();
//      loadFile(unwrapDomObject(event).dataTransfer.files[0]);
//    });
  }

//  void loadFile(File file) {
//    document.query('#name').text = file.fileName;
//    document.query('#size').text = file.fileSize;
//
//    dom.FileReader reader = new dom.FileReader();
//    reader.readAsText(unwrapDomObject(file));
//
//    (handler() {
//      if (reader.readyState == 2) {
//        document.query('#file-content').text = reader.result;
//        fileBytes = reader.result;
//      } else {
//        window.setTimeout(handler, 100);
//      }
//    })();
//  }
}
