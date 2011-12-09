class Input {
  
  bool debugMe = false;
  var fileBytes;
  
  void init() {
    // Content section used a lot
    Element content = document.query('#content');
    Element input = document.query('#file');
    
    // Add invisible border to drop area
    content.style.border = '4px solid transparent';
  
    // Input handler
    input.on.change.add((Event event) {
      Util.printDebug("Input.init(): input.on.change Event fired.", debugMe);
      
      unwrapDomObject(event).preventDefault();
      loadFile(input.files.item(0));
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
  }

  void loadFile(File file) {
    document.query('#name').text = file.fileName;
    document.query('#size').text = file.fileSize;
    document.query('#file-content').style.border = "1px solid black";

    dom.FileReader reader = new dom.FileReader();
    reader.readAsText(unwrapDomObject(file));

    (handler() {
      Util.printDebug("Input.loadFile: reader.readyState = " + reader.readyState, debugMe);
      
      if (reader.readyState == 2) {
        document.query('#file-content').text = reader.result;
        fileBytes = reader.result;
      } else {
        window.setTimeout(handler, 50);
      }
    })();
  }        
}
