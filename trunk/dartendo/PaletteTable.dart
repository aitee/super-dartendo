class PaletteTableStatics {
    List<int> curTable = new List<int>(64);
    List<int> origTable = new List<int>(64);
    List<List<int>> emphTable = new List<List<int>>(8);
    
    PaletteTableStatics() {
      for(int i = 0; i < emphTable.length; i++) {
        emphTable[i] = new List<int>(64);
      }
    }
}

PaletteTableStatics PaletteTable__static = PaletteTableStatics(); 

class PaletteTable {

    int currentEmph = -1;
    int currentHue, currentSaturation, currentLightness, currentContrast;


    // Load the NTSC palette:
    bool loadNTSCPalette() {
        return loadPalette("palettes/ntsc.txt");
    }

    // Load the PAL palette:
    bool loadPALPalette() {
        return loadPalette("palettes/pal.txt");
    }

    // Load a palette file:
    bool loadPalette(String file) {
      // cannot read from files in dart... what to do?
        int r, g, b;

        try {

            if (file.toLowerCase().endsWith("pal")) {

                // Read binary palette file.
                InputStream fStr = getClass().getResourceAsStream(file);
                List<int> tmp = new List<int>(64 * 3);

                int n = 0;
                while (n < 64) {
                    n += fStr.read(tmp, n, tmp.length - n);
                }

                List<int> tmpi = new List<int>(64 * 3);
                for (int i = 0; i < tmp.length; i++) {
                    tmpi[i] = tmp[i] & 0xFF;
                }

                for (int i = 0; i < 64; i++) {
                    r = tmpi[i * 3 + 0];
                    g = tmpi[i * 3 + 1];
                    b = tmpi[i * 3 + 2];
                    PaletteTable__static.origTable[i] = r | (g << 8) | (b << 16);
                }

            } else {

                // Read text file with hex codes.
                InputStream fStr = getClass().getResourceAsStream(file);
                InputStreamReader isr = new InputStreamReader(fStr);
                BufferedReader br = new BufferedReader(isr);

                String line = br.readLine();
                String hexR, hexG, hexB;
                int palIndex = 0;
                while (line != null) {

                    if (line.startsWith("#")) {

                        hexR = line.substring(1, 3);
                        hexG = line.substring(3, 5);
                        hexB = line.substring(5, 7);

                        r = Integer.decode("0x" + hexR).intValue();
                        g = Integer.decode("0x" + hexG).intValue();
                        b = Integer.decode("0x" + hexB).intValue();
                        PaletteTable__static.origTable[palIndex] = r | (g << 8) | (b << 16);

                        palIndex++;

                    }
                    line = br.readLine();
                }
            }

            setEmphasis(0);
            makeTables();
            updatePalette();

            return true;

        } catch (Exception e) {

            // Unable to load palette.
            System.out.println("PaletteTable: Internal Palette Loaded.");
            loadDefaultPalette();
            return false;

        }

    }

    void makeTables() {

        int r, g, b, col;

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
            for (int i = 0; i < 64; i++) {
                col = PaletteTable__static.origTable[i];
                r = (getRed(col) * rFactor).toInt();
                g = (getGreen(col) * gFactor).toInt();
                b = (getBlue(col) * bFactor).toInt();
                PaletteTable__static.emphTable[emph][i] = getRgb(r, g, b);
            }

        }

    }

    void setEmphasis(int emph) {

        if (emph != currentEmph) {
            currentEmph = emph;
            for (int i = 0; i < 64; i++) {
              PaletteTable__static.curTable[i] = PaletteTable__static.emphTable[emph][i];
            }
            updatePalette();
        }

    }

    int getEntry(int yiq) {
        return PaletteTable__static.curTable[yiq];
    }

    int RGBtoHSL(int r, int g, int b) {
        List<double> hsbvals = new List<double>(3);
        hsbvals = Color.RGBtoHSB(b, g, r, hsbvals);
        hsbvals[0] -= Math.floor(hsbvals[0]);

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
        return Color.HSBtoRGB(h / 255.0, s / 255.0, l / 255.0);
    }

    // iainmcgin: formerly HSLtoRGB
    int packedHSLtoRGB(int hsl) {
        double h, s, l;
        h = (float) (((hsl >> 16) & 0xFF) / 255);
        s = (float) (((hsl >> 8) & 0xFF) / 255);
        l = (float) (((hsl) & 0xFF) / 255);
        return Color.HSBtoRGB(h, s, l);
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
        updatePalette(currentHue, currentSaturation, currentLightness, currentContrast);
    }

    // Change palette colors.
    // Arguments should be set to 0 to keep the original value.
    // iainmcgin: formerly updatePalette
    void updatePaletteWith(int hueAdd, int saturationAdd, int lightnessAdd, int contrastAdd) {

        int hsl, rgb;
        int h, s, l;
        int r, g, b;

        if (contrastAdd > 0) {
            contrastAdd *= 4;
        }
        for (int i = 0; i < 64; i++) {

            hsl = RGBtoHSL(PaletteTable__static.emphTable[currentEmph][i]);
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
            PaletteTable__static.curTable[i] = rgb;
        }

        currentHue = hueAdd;
        currentSaturation = saturationAdd;
        currentLightness = lightnessAdd;
        currentContrast = contrastAdd;

    }

    void loadDefaultPalette() {
        if (PaletteTable__static.origTable == null) {
            PaletteTable__static.origTable = new List<int>(64);
        }

        PaletteTable__static.origTable[ 0] = getRgb(124, 124, 124);
        PaletteTable__static.origTable[ 1] = getRgb(0, 0, 252);
        PaletteTable__static.origTable[ 2] = getRgb(0, 0, 188);
        PaletteTable__static.origTable[ 3] = getRgb(68, 40, 188);
        PaletteTable__static.origTable[ 4] = getRgb(148, 0, 132);
        PaletteTable__static.origTable[ 5] = getRgb(168, 0, 32);
        PaletteTable__static.origTable[ 6] = getRgb(168, 16, 0);
        PaletteTable__static.origTable[ 7] = getRgb(136, 20, 0);
        PaletteTable__static.origTable[ 8] = getRgb(80, 48, 0);
        PaletteTable__static.origTable[ 9] = getRgb(0, 120, 0);
        PaletteTable__static.origTable[10] = getRgb(0, 104, 0);
        PaletteTable__static.origTable[11] = getRgb(0, 88, 0);
        PaletteTable__static.origTable[12] = getRgb(0, 64, 88);
        PaletteTable__static.origTable[13] = getRgb(0, 0, 0);
        PaletteTable__static.origTable[14] = getRgb(0, 0, 0);
        PaletteTable__static.origTable[15] = getRgb(0, 0, 0);
        PaletteTable__static.origTable[16] = getRgb(188, 188, 188);
        PaletteTable__static.origTable[17] = getRgb(0, 120, 248);
        PaletteTable__static.origTable[18] = getRgb(0, 88, 248);
        PaletteTable__static.origTable[19] = getRgb(104, 68, 252);
        PaletteTable__static.origTable[20] = getRgb(216, 0, 204);
        PaletteTable__static.origTable[21] = getRgb(228, 0, 88);
        PaletteTable__static.origTable[22] = getRgb(248, 56, 0);
        PaletteTable__static.origTable[23] = getRgb(228, 92, 16);
        PaletteTable__static.origTable[24] = getRgb(172, 124, 0);
        PaletteTable__static.origTable[25] = getRgb(0, 184, 0);
        PaletteTable__static.origTable[26] = getRgb(0, 168, 0);
        PaletteTable__static.origTable[27] = getRgb(0, 168, 68);
        PaletteTable__static.origTable[28] = getRgb(0, 136, 136);
        PaletteTable__static.origTable[29] = getRgb(0, 0, 0);
        PaletteTable__static.origTable[30] = getRgb(0, 0, 0);
        PaletteTable__static.origTable[31] = getRgb(0, 0, 0);
        PaletteTable__static.origTable[32] = getRgb(248, 248, 248);
        PaletteTable__static.origTable[33] = getRgb(60, 188, 252);
        PaletteTable__static.origTable[34] = getRgb(104, 136, 252);
        PaletteTable__static.origTable[35] = getRgb(152, 120, 248);
        PaletteTable__static.origTable[36] = getRgb(248, 120, 248);
        PaletteTable__static.origTable[37] = getRgb(248, 88, 152);
        PaletteTable__static.origTable[38] = getRgb(248, 120, 88);
        PaletteTable__static.origTable[39] = getRgb(252, 160, 68);
        PaletteTable__static.origTable[40] = getRgb(248, 184, 0);
        PaletteTable__static.origTable[41] = getRgb(184, 248, 24);
        PaletteTable__static.origTable[42] = getRgb(88, 216, 84);
        PaletteTable__static.origTable[43] = getRgb(88, 248, 152);
        PaletteTable__static.origTable[44] = getRgb(0, 232, 216);
        PaletteTable__static.origTable[45] = getRgb(120, 120, 120);
        PaletteTable__static.origTable[46] = getRgb(0, 0, 0);
        PaletteTable__static.origTable[47] = getRgb(0, 0, 0);
        PaletteTable__static.origTable[48] = getRgb(252, 252, 252);
        PaletteTable__static.origTable[49] = getRgb(164, 228, 252);
        PaletteTable__static.origTable[50] = getRgb(184, 184, 248);
        PaletteTable__static.origTable[51] = getRgb(216, 184, 248);
        PaletteTable__static.origTable[52] = getRgb(248, 184, 248);
        PaletteTable__static.origTable[53] = getRgb(248, 164, 192);
        PaletteTable__static.origTable[54] = getRgb(240, 208, 176);
        PaletteTable__static.origTable[55] = getRgb(252, 224, 168);
        PaletteTable__static.origTable[56] = getRgb(248, 216, 120);
        PaletteTable__static.origTable[57] = getRgb(216, 248, 120);
        PaletteTable__static.origTable[58] = getRgb(184, 248, 184);
        PaletteTable__static.origTable[59] = getRgb(184, 248, 216);
        PaletteTable__static.origTable[60] = getRgb(0, 252, 252);
        PaletteTable__static.origTable[61] = getRgb(216, 216, 16);
        PaletteTable__static.origTable[62] = getRgb(0, 0, 0);
        PaletteTable__static.origTable[63] = getRgb(0, 0, 0);

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