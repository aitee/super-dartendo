class FileLoader {
  static String get home()  => window.location.protocol + '//' + window.location.host;

  // Load a file. TODO: async.
  List<int> loadFile([String fileName = 'IceHockey.json']) {
    final req = new XMLHttpRequest();
    req.open('GET', '${FileLoader.home}/$fileName', false);
    req.send();
    return JSON.parse(req.responseText);
  }
}
