class Input {
  
  var fileBytes;
  
  void init() {
    // Content section used a lot
    html.Element content = html.document.query('#content');
    html.Element input = html.document.query('#file');
    
    // Add invisible border to drop area
    content.style.border = '4px solid transparent';
  
    // Input handler
    input.on.change.add((html.Event event) {
      print("change");
      unwrapDomObject(event).preventDefault();
      loadFile(input.files.item(0));
    });
    
    // Add dragging events
    content.on.dragEnter.add((html.Event event) {
      print("dragEnter");
      unwrapDomObject(event).preventDefault();
      content.style.border = '4px solid #b1ecb3';
      return false;
    });
  
    content.on.dragOver.add((html.Event event) {
      unwrapDomObject(event).preventDefault();
      return false;
    });
  
    content.on.dragLeave.add((html.Event event) {
      unwrapDomObject(event).preventDefault();
      return false;
    });
  
    content.on.drop.add((html.Event event) {
      unwrapDomObject(event).preventDefault();
      content.style.border = '4px solid transparent';
      loadFile(unwrapDomObject(event).dataTransfer.files[0]);
      return false;
    });
  }

  void loadFile(html.File file) {
    html.document.query('#name').text = file.fileName;
    html.document.query('#size').text = file.fileSize;
    html.document.query('#file-content').style.border = "1px solid black";

    FileReader reader = new FileReader();
    reader.readAsText(unwrapDomObject(file));

    (handler() {
      print(reader.readyState);
      if (reader.readyState == 2) {
        html.document.query('#file-content').text = reader.result;
        fileBytes = reader.result;
      } else {
        window.setTimeout(handler, 50);
      }
    })();
  }        
}
