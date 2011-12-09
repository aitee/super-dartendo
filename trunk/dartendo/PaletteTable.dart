class PaletteTable {
    bool debugMe = false;
    
    static List<int> curTable;
    static List<int> origTable;
    static List<List<int>> emphTable;

    static void init() {
      curTable = Util.newIntList(64, 0);
      origTable = Util.newIntList(64, 0);
      emphTable = Util.newIntList2d(8,64,0);
    }
    
    int currentEmph = -1;
    int currentHue = 0;
    int currentSaturation = 0;
    int currentLightness = 0;
    int currentContrast = 0;

    // Load the NTSC palette:
    bool loadNTSCPalette() {
        return loadPalette("palettes/ntsc.json");
    }

    // Load the PAL palette:
    bool loadPALPalette() {
        return loadPalette("palettes/pal.json");
    }

    // Load a palette file:
    bool loadPalette(String file) {              
      Util.printDebug("PaletteTable.loadPalette( file = " + file + ")", debugMe);        
      try {
          List<int> rawTable = FileLoader.loadFile(file);
          for(var i=0;i<origTable.length;i++) {
            origTable[i] = getRgb(rawTable[(i*3)], rawTable[(i*3)+1], rawTable[(i*3)+2]);
          }
          
          Util.printDebug("PaletteTable.loadPalette(...): Finished loading palette.", debugMe);            
  
          setEmphasis(0);
          makeTables();
          updatePalette();
          
          Util.printDebug("PaletteTable.loadPalette(...): success!", debugMe);
          return true;
  
      } catch (Exception e) {
          // Unable to load palette.
          print("PaletteTable.loadPalette(...): Exception.  Loading Internal Palette instead.");
          loadDefaultPalette();
          return false;
      }
    }

    void makeTables() {

        int r = 0, g = 0, b = 0, col = 0;

        // Calculate a table for each possible emphasis setting:
        for (int emph = 0; emph < 8; emph++) {

            // Determine color component factors:
            double rFactor = 1.0, gFactor = 1.0, bFactor = 1.0;
            if ((emph & 1) != 0) {
                rFactor = 0.75;
                bFactor = 0.75;
            }
            if ((emph & 2) != 0) {
                rFactor = 0.75;
                gFactor = 0.75;
            }
            if ((emph & 4) != 0) {
                gFactor = 0.75;
                bFactor = 0.75;
            }

            // Calculate table:
            Util.printDebug('PaletteTable.makeTables(): EMPH TABLE BEGIN', debugMe);
            
            for (int i = 0; i < 64; i ++) {
                col = origTable[i];
                r = (getRed(col) * rFactor).toInt();
                g = (getGreen(col) * gFactor).toInt();
                b = (getBlue(col) * bFactor).toInt();
                emphTable[emph][i] = col;
                Util.printDebug(emphTable[emph][i].toString(), debugMe);
            }
            
            Util.printDebug('PaletteTable.makeTables(): EMPH TABLE END', debugMe);

        }

    }

    void setEmphasis(int emph) {

        if (emph != currentEmph) {
            currentEmph = emph;
            for (int i = 0; i < 64; i++) {
              curTable[i] = emphTable[emph][i];
            }
            updatePalette();
        }

    }

    int getEntry(int yiq) {
        return curTable[yiq];
    }
    
 /* List<double> RGBtoHSB(int r, int g, int b) {
    int maxc = Math.max(Math.max(r, g), b);
    int minc = Math.min(Math.min(r, g), b);
    double v = maxc.toDouble();
    
    if (minc == maxc) {
        List<double> r = Util.newDoubleList(3, 0.0);
        r[0] = 0.0;
        r[1] = 0.0;
        r[2] = v;
        return r;
    }

    double s = (maxc-minc) / maxc;
    double rc = (maxc-r) / (maxc-minc);
    double gc = (maxc-g) / (maxc-minc);
    double bc = (maxc-b) / (maxc-minc);
    double h;
    if (r == maxc) {
        h = bc - gc;
    } else if (g == maxc) {
        h = 2.0 + rc - bc;
    } else {
        h = 4.0+gc-rc;
    }
    h = (h/6.0) % 1.0;
    List<double> r2 = Util.newDoubleList(3, 0.0);
    r2[0] = h;
    r2[1] = s;
    r2[2] = v;
    return r2;
  }
      
  int HSBtoRGB(double h, double s, double v) {
    if (s == 0.0) {
        return getRGB(v,v,v);
    }
    int i = (h*6.0).toInt();
    double f = (h*6.0) - i;
    double p = v*(1.0 - s);
    double q = v*(1.0 - s*f);
    double t = v*(1.0 - s*(1.0-f));
    
    i = i%6;
    if (i == 0)
        return getRGB(v, t, p);
    if (i == 1)
        return getRGB(q, v, p);
    if (i == 2)
        return getRGB(p, v, t);
    if (i == 3)
        return getRGB(p, q, v);
    if (i == 4) 
        return getRGB(t, p, v);
    else //i == 5
        return getRGB(v, p, q);
  }
    
  int getRGB(double r, double g, double b) {
    return (r * 255).round().toInt() << 16 | (g * 255).round().toInt() << 8 | (b * 255).round().toInt();
  }*/
    

    // Original function at http://delphi.about.com/od/adptips2006/qt/RgbToHsb.htm
    // used Byte for RGB values--that may have screwed up the port of it.
    List<double> RGBtoHSB(int r, int g, int b) {
       int minRGB = Math.min(Math.min(r, g), b);
       int maxRGB = Math.max(Math.max(r, g), b);
       int delta = (maxRGB - minRGB);
       double brightness = maxRGB.toDouble();
       
       double saturation = 0.0;
       if (maxRGB != 0.0) {
         saturation = 255.0 * delta / maxRGB;
       }

       double hue = -1.0;
       if (saturation != 0.0) {
         if (r == maxRGB)
           hue = (g - b) / delta;
         else {
           if (g == maxRGB) {
             hue = 2.0 + (b - r) / delta;
           } else {
             if (b == maxRGB) {
               hue = 4.0 + (r - g) / delta;
             }
           }
         }
       }

       hue *= 60;
       if (hue < 0.0) {
         hue += 360.0;
       }
       
       List<double> hsb = Util.newDoubleList(3, 0.0);
       hsb[0] = hue;
       hsb[1] = saturation;
       hsb[2] = brightness;
       
       return hsb;
    }

    int HSBtoRGB(double hue, double saturation, double brightness) {
      double r = 0.0, g = 0.0, b = 0.0;
      int i = 0;
      double f = 0.0, p = 0.0, q = 0.0, t = 0.0;

      if (saturation == 0) {
        r = g = b = brightness;
        return (r * 255).round().toInt() << 16 | (g * 255).round().toInt() << 8 | (b * 255).round().toInt();
      }

      hue /= 60;
      i = hue.floor().toInt();
      f = hue - i;
      p = brightness * (1 - saturation);
      q = brightness * (1 - saturation * f);
      t = brightness * (1 - saturation * (1 - f));

      switch (i) {
        case 0:
          r = brightness;
          g = t;
          b = p;
          break;
        case 1:
          r = q;
          g = brightness;
          b = p;
          break;
        case 2:
          r = p;
          g = brightness;
          b = t;
          break;
        case 3:
          r = p;
          g = q;
          b = brightness;
          break;
        case 4:
          r = t;
          g = p;
          b = brightness;
          break;
        default:
          r = brightness;
          g = p;
          b = q;
          break;
      }
      
      return (r * 255).round().toInt() << 16 | (g * 255).round().toInt() << 8 | (b * 255).round().toInt();
    }

    int RGBtoHSL(int r, int g, int b) {
        List<double> hsbvals = RGBtoHSB(r, g, b);
        hsbvals[0] -= hsbvals[0].floor().toInt();

        int ret = 0;
        ret |= (((hsbvals[0] * 255).toInt()) << 16);
        ret |= (((hsbvals[1] * 255).toInt()) << 8);
        ret |= (((hsbvals[2] * 255).toInt()));

        return ret;
    }

    // iainmcgin: formerly RGBtoHSL
    int packedRGBtoHSL(int rgb) {
        return RGBtoHSL((rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, (rgb) & 0xFF);
    }

    int HSLtoRGB(int h, int s, int l) {
        return HSBtoRGB(h / 255.0, s / 255.0, l / 255.0);
    }

    // iainmcgin: formerly HSLtoRGB
    int packedHSLtoRGB(int hsl) {
        double h = 0.0, s = 0.0, l = 0.0;
        h = (((hsl >> 16) & 0xFF) / 255).toDouble();
        s = (((hsl >> 8) & 0xFF) / 255).toDouble();
        l = (((hsl) & 0xFF) / 255).toDouble();
        return HSBtoRGB(h, s, l);
    }

    int getHue(int hsl) {
        return (hsl >> 16) & 0xFF;
    }

    int getSaturation(int hsl) {
        return (hsl >> 8) & 0xFF;
    }

    int getLightness(int hsl) {
        return hsl & 0xFF;
    }

    int getRed(int rgb) {
        return (rgb >> 16) & 0xFF;
    }

    int getGreen(int rgb) {
        return (rgb >> 8) & 0xFF;
    }

    int getBlue(int rgb) {
        return rgb & 0xFF;
    }

    int getRgb(int r, int g, int b) {
        return ((r << 16) | (g << 8) | (b));
    }

    void updatePalette() {
        updatePaletteWith(currentHue, currentSaturation, currentLightness, currentContrast);
    }

    // Change palette colors.
    // Arguments should be set to 0 to keep the original value.
    // iainmcgin: formerly updatePalette
    void updatePaletteWith(int hueAdd, int saturationAdd, int lightnessAdd, int contrastAdd) {

        int hsl = 0, rgb = 0;
        int h = 0, s = 0, l = 0;
        int r = 0, g = 0, b = 0;

        if (contrastAdd > 0) {
            contrastAdd *= 4;
        }
        
        Util.printDebug('PaletteTable.updatePaletteWith(...): Printing curTable....', debugMe);
        for (int i = 0; i < 64; i++) {
          curTable[i] = emphTable[currentEmph][i];
          Util.printDebug(curTable[i].toString(), debugMe);

          /*
            hsl = packedRGBtoHSL(emphTable[currentEmph][i]);
            h = getHue(hsl) + hueAdd;
            s = (getSaturation(hsl) * (1.0 + saturationAdd / 256)).toInt();
            l = getLightness(hsl);

            if (h < 0) { h += 255; }
            if (s < 0) { s = 0; }
            if (l < 0) { l = 0; }

            if (h > 255) { h -= 255; }
            if (s > 255) { s = 255; }
            if (l > 255) { l = 255; }

            rgb = HSLtoRGB(h, s, l);

            r = getRed(rgb);
            g = getGreen(rgb);
            b = getBlue(rgb);

            r = 128 + lightnessAdd + ((r - 128) * (1.0 + contrastAdd / 256)).toInt();
            g = 128 + lightnessAdd + ((g - 128) * (1.0 + contrastAdd / 256)).toInt();
            b = 128 + lightnessAdd + ((b - 128) * (1.0 + contrastAdd / 256)).toInt();

            if (r < 0) { r = 0; }
            if (g < 0) { g = 0; }
            if (b < 0) { b = 0; }

            if (r > 255) { r = 255; }
            if (g > 255) { g = 255; }
            if (b > 255) { b = 255; }

            rgb = getRgb(r, g, b);
            curTable[i] = rgb;
            */
        }

        currentHue = hueAdd;
        currentSaturation = saturationAdd;
        currentLightness = lightnessAdd;
        currentContrast = contrastAdd;
    }

    void loadDefaultPalette() {
        if (origTable == null) {
            origTable = Util.newIntList(64, 0);
        }

        origTable[ 0] = getRgb(124, 124, 124);
        origTable[ 1] = getRgb(0, 0, 252);
        origTable[ 2] = getRgb(0, 0, 188);
        origTable[ 3] = getRgb(68, 40, 188);
        origTable[ 4] = getRgb(148, 0, 132);
        origTable[ 5] = getRgb(168, 0, 32);
        origTable[ 6] = getRgb(168, 16, 0);
        origTable[ 7] = getRgb(136, 20, 0);
        origTable[ 8] = getRgb(80, 48, 0);
        origTable[ 9] = getRgb(0, 120, 0);
        origTable[10] = getRgb(0, 104, 0);
        origTable[11] = getRgb(0, 88, 0);
        origTable[12] = getRgb(0, 64, 88);
        origTable[13] = getRgb(0, 0, 0);
        origTable[14] = getRgb(0, 0, 0);
        origTable[15] = getRgb(0, 0, 0);
        origTable[16] = getRgb(188, 188, 188);
        origTable[17] = getRgb(0, 120, 248);
        origTable[18] = getRgb(0, 88, 248);
        origTable[19] = getRgb(104, 68, 252);
        origTable[20] = getRgb(216, 0, 204);
        origTable[21] = getRgb(228, 0, 88);
        origTable[22] = getRgb(248, 56, 0);
        origTable[23] = getRgb(228, 92, 16);
        origTable[24] = getRgb(172, 124, 0);
        origTable[25] = getRgb(0, 184, 0);
        origTable[26] = getRgb(0, 168, 0);
        origTable[27] = getRgb(0, 168, 68);
        origTable[28] = getRgb(0, 136, 136);
        origTable[29] = getRgb(0, 0, 0);
        origTable[30] = getRgb(0, 0, 0);
        origTable[31] = getRgb(0, 0, 0);
        origTable[32] = getRgb(248, 248, 248);
        origTable[33] = getRgb(60, 188, 252);
        origTable[34] = getRgb(104, 136, 252);
        origTable[35] = getRgb(152, 120, 248);
        origTable[36] = getRgb(248, 120, 248);
        origTable[37] = getRgb(248, 88, 152);
        origTable[38] = getRgb(248, 120, 88);
        origTable[39] = getRgb(252, 160, 68);
        origTable[40] = getRgb(248, 184, 0);
        origTable[41] = getRgb(184, 248, 24);
        origTable[42] = getRgb(88, 216, 84);
        origTable[43] = getRgb(88, 248, 152);
        origTable[44] = getRgb(0, 232, 216);
        origTable[45] = getRgb(120, 120, 120);
        origTable[46] = getRgb(0, 0, 0);
        origTable[47] = getRgb(0, 0, 0);
        origTable[48] = getRgb(252, 252, 252);
        origTable[49] = getRgb(164, 228, 252);
        origTable[50] = getRgb(184, 184, 248);
        origTable[51] = getRgb(216, 184, 248);
        origTable[52] = getRgb(248, 184, 248);
        origTable[53] = getRgb(248, 164, 192);
        origTable[54] = getRgb(240, 208, 176);
        origTable[55] = getRgb(252, 224, 168);
        origTable[56] = getRgb(248, 216, 120);
        origTable[57] = getRgb(216, 248, 120);
        origTable[58] = getRgb(184, 248, 184);
        origTable[59] = getRgb(184, 248, 216);
        origTable[60] = getRgb(0, 252, 252);
        origTable[61] = getRgb(216, 216, 16);
        origTable[62] = getRgb(0, 0, 0);
        origTable[63] = getRgb(0, 0, 0);

        setEmphasis(0);
        makeTables();
    }

    void reset() {
        currentEmph = 0;
        currentHue = 0;
        currentSaturation = 0;
        currentLightness = 0;
        setEmphasis(0);
        updatePalette();
    }
}