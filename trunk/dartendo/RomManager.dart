/**
 * Manages ROMs.  Maintains bytes for the current ROM in memory and 
 * handles events in the ROM menu. 
 */
class RomManager {

  final Controller _controller;

  Element _menu;
  Element _romsLabel;
  Element _romsContent;
  Element _tv;
  InputElement _inputFile;
  
  /**
   * Raw data for the currently-loaded ROM.  Each int has a value between 0 
   * and 254 and represents one byte.
   */
  List<int> _romBytes;
  
  /**
   * 0 if not dragging over ROM area.
   * > 0 if dragging over ROM area.
   */
  int _dragState = 0; 
  
  RomManager(this._controller) {
    this._menu = document.query('#menu');  
    this._romsLabel = document.query('#roms-label');
    this._romsContent = document.query('#roms-content');
    this._inputFile = document.query('#input-file');
    this._tv = document.query('#tv');
  }

  void toggleMenuVisibility() {
    if (_menu.style.bottom == '0px') {
      hideMenu();
    } else {
      showMenu();
    }
  }
  
  void showMenu() {
    _menu.style.transition = 'bottom 0.2s';
    _menu.style.bottom = '0';
  }
  
  void hideMenu() {
    _menu.style.transition = 'bottom 0.2s';
    // TODO(tedmao): measure height of menu instead of hard-coding height. 
    _menu.style.bottom = '-15ex';
  }
  
  void init() {
    _registerEventHandlers();
    _loadDefaultRom();
  }
  
  List<int> get romBytes() => _romBytes;

  void _registerEventHandlers() {
    _romsLabel.on.click.add((EventWrappingImplementation event) {
      unwrapDomObject(event).preventDefault();
      toggleMenuVisibility();
    });

    // Input handler
    _inputFile.on.change.add((EventWrappingImplementation event) {
      unwrapDomObject(event).preventDefault();
      File file = _inputFile.files.item(0);
      _loadFile(file);
    });

    
    // change background color of drag area if it's dragged over
    _romsContent.on.dragEnter.add((EventWrappingImplementation event) {
      unwrapDomObject(event).preventDefault();
      _dragState++;
      _updateRomsContentDragStyle();
    });
  
    _romsContent.on.dragLeave.add((EventWrappingImplementation event) {
      unwrapDomObject(event).preventDefault();
      _dragState--;
      _updateRomsContentDragStyle();
    });
  
    // dragOver needs to be cancelled in order for the drop event to fire.
    var onDragOverHandler = (EventWrappingImplementation event) {
      unwrapDomObject(event).preventDefault();
    };
    _romsContent.on.dragOver.add(onDragOverHandler);
    _tv.on.dragOver.add(onDragOverHandler);
  
    // if a file is dropped, attempt to load it as a rom.
    var onDropHandler = (EventWrappingImplementation event) {
      unwrapDomObject(event).preventDefault();
      _loadFile(new FileWrappingImplementation._wrap(unwrapDomObject(event).dataTransfer.files[0]));
    };
    _romsContent.on.drop.add(onDropHandler);
    _tv.on.drop.add(onDropHandler);
}
  
  void _updateRomsContentDragStyle() {
    if (_dragState > 0) {
      _romsContent.classes = ["roms-drag-in"];
    } else {
      _romsContent.classes = ["roms-drag-out"];
    }
  }
    
  void _loadDefaultRom() {
    String defaultRom = 'roms/SuperMario3.json';
    String romParameter = Controller.getQueryValue('rom');
    if (romParameter != null && romParameter.length > 0) {
      defaultRom = 'roms/' + Controller.getQueryValue('rom') + '.json';
    }
    
    final req = new XMLHttpRequest();
    req.open('GET', '${FileLoader.home}/$defaultRom', false);
    req.send();
    
    _romBytes = JSON.parse(req.responseText);
  }

  void _loadFile(FileWrappingImplementation file) {
    document.query('#name').text = file.fileName;
    document.query('#size').text = file.fileSize;

    dom.FileReader reader = new dom.FileReader();
    reader.readAsArrayBuffer(unwrapDomObject(file));

    (handler() {
      if (reader.readyState == 2) {
        List<int> fromFileBytes = new dom.Uint8Array.fromBuffer(reader.result);
        _romBytes = fromFileBytes;
        hideMenu();
        _controller.run();
      } else {
        window.setTimeout(handler, 100);
      }
    })();
  }

}
