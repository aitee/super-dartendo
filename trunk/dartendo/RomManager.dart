part of dartendo;

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
    _menu.style.transition = 'bottom 0.2s';
    _menu.style.bottom = '0';
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
    _menu.style.bottom = _menu.clientHeight.toString();
  }
  
  void init() {
    _registerEventHandlers();
    _loadDefaultRom();
  }
  
  List<int> get romBytes => _romBytes;

  void _registerEventHandlers() {
    _romsLabel.onClick.listen((event) {
      event.preventDefault();
      toggleMenuVisibility();
    });

    // Input handler
    _inputFile.onChange.listen((event) {
      event.preventDefault();
      File file = _inputFile.files[0];
      _loadFile(file);
    });

    
    // change background color of drag area if it's dragged over
    _romsContent.onDragEnter.listen((event) {
      event.preventDefault();
      _dragState++;
      _updateRomsContentDragStyle();
    });
  
    _romsContent.onDragLeave.listen((event) {
      event.preventDefault();
      _dragState--;
      _updateRomsContentDragStyle();
    });
  
    // dragOver needs to be cancelled in order for the drop event to fire.
    var onDragOverHandler = (event) => event.preventDefault();
    _romsContent.onDragOver.listen(onDragOverHandler);
    _tv.onDragOver.listen(onDragOverHandler);
  
    // if a file is dropped, attempt to load it as a rom.
    var onDropHandler = (e) {
      e.preventDefault();
      _loadFile(e.dataTransfer.files[0]);
    };
    _romsContent.onDrop.listen(onDropHandler);
    _tv.onDrop.listen(onDropHandler);
  }
  
  void _updateRomsContentDragStyle() {
    if (_dragState > 0) {
      _romsContent.classes = ["roms-drag-in"].toSet();
    } else {
      _romsContent.classes = ["roms-drag-out"].toSet();
    }
  }
    
  void _loadDefaultRom() {
    String defaultRom = 'roms/SuperMario3.json';
    String romParameter = Controller.getQueryValue('rom');
    if (romParameter != null && romParameter.length > 0)
      defaultRom = "roms/$romParameter.json";
    
    final req = new HttpRequest();
    req.open('GET', '${FileLoader.home}/$defaultRom', async:false);
    req.send();
    
    _romBytes = JSON.parse(req.responseText);
  }

  void _loadFile(File file) {
    document.query('#name').text = file.name;
    document.query('#size').text = "$file.size";

    FileReader reader = new FileReader();
    reader.onLoadEnd.listen((e) {
      List<int> fromFileBytes = new Uint8List.fromList(reader.result);
      _romBytes = fromFileBytes;
      hideMenu();
      _controller.run();
    });
    reader.readAsArrayBuffer(file);
  }
}
