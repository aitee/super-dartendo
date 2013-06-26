part of dartendo;

class FileLoader {
  static String get home  => '.'; //window.location.protocol + '//' + window.location.host;

  // Load a file. TODO: async.
  static List<int> loadFile(String fileName) {
    final req = new HttpRequest();
    req.open('GET', '${FileLoader.home}/$fileName', async:false);
    req.send();
    return JSON.parse(req.responseText);
  }
}
