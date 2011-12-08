class NES {

     AppletUI gui;
     CPU cpu;
     PPU ppu;
     PAPU papu;
     Memory cpuMem;
     Memory ppuMem;
     Memory sprMem;
     MemoryMapper memMapper;
     PaletteTable palTable;
     ROM rom;
    int cc;
     String romFile;
    bool isRunningFlag = false;

    // Creates the NES system.
     NES(AppletUI gui) {

        Globals.nes = this;
        this.gui = gui;

        // Create memory:
        cpuMem = new Memory(this, 0x10000); // Main memory (internal to CPU)
        ppuMem = new Memory(this, 0x8000);  // VRAM memory (internal to PPU)
        sprMem = new Memory(this, 0x100); // Sprite RAM  (internal to PPU)


        // Create system units:
        cpu = new CPU(this);
        palTable = new PaletteTable();
        ppu = new PPU(this);
        papu = new PAPU(this);

        // Init sound registers:
        for (int i = 0; i < 0x14; i++) {
            if (i == 0x10) {
                papu.writeReg(0x4010,  0x10);
            } else {
                papu.writeReg(0x4000 + i,  0);
            }
        }

        // Load NTSC palette:
        if (!palTable.loadNTSCPalette()) {
            //System.out.println("Unable to load palette file. Using default.");
            palTable.loadDefaultPalette();
        }

        // Initialize units:
        cpu.init();
        ppu.init();

        // Enable sound:
        enableSound(true);

        // Clear CPU memory:
        clearCPUMemory();

    }

     bool stateLoad(ByteBuffer buf) {

        bool continueEmulation = false;
        bool success;

        // Pause emulation:
        if (cpu.isRunning()) {
            continueEmulation = true;
            stopEmulation();
        }

        // Check version:
        if (buf.readByte() == 1) {

            // Let units load their state from the buffer:
            cpuMem.stateLoad(buf);
            ppuMem.stateLoad(buf);
            sprMem.stateLoad(buf);
            cpu.stateLoad(buf);
            memMapper.stateLoad(buf);
            ppu.stateLoad(buf);
            success = true;

        } else {

            //System.out.println("State file has wrong format. version="+buf.readByte(0));
            success = false;

        }

        // Continue emulation:
        if (continueEmulation) {
            startEmulation();
        }

        return success;

    }

     void stateSave(ByteBuffer buf) {

        bool continueEmulation = isRunning();
        stopEmulation();

        // Version:
        buf.putByte( 1);

        // Let units save their state:
        cpuMem.stateSave(buf);
        ppuMem.stateSave(buf);
        sprMem.stateSave(buf);
        cpu.stateSave(buf);
        memMapper.stateSave(buf);
        ppu.stateSave(buf);

        // Continue emulation:
        if (continueEmulation) {
            startEmulation();
        }

    }

     bool isRunning() {

        return isRunningFlag;

    }

     void startEmulation() {

        if (Globals.enableSound && !papu.isRunning()) {
            papu.start();
        }
        {
            if (rom != null && rom.isValid() && !cpu.isRunning()) {
                cpu.beginExecution();
                isRunningFlag = true;
            }
        }
    }

     void stopEmulation() {
        if (cpu.isRunning()) {
            cpu.endExecution();
            isRunningFlag = false;
        }

        if (Globals.enableSound && papu.isRunning()) {
            papu.stop();
        }
    }

     void reloadRom() {

        if (romFile != null) {
            loadRom(romFile);
        }

    }

     void clearCPUMemory() {

        int flushval = Globals.memoryFlushValue;
        for (int i = 0; i < 0x2000; i++) {
            cpuMem.mem[i] = flushval;
        }
        for (int p = 0; p < 4; p++) {
            int i = p * 0x800;
            cpuMem.mem[i + 0x008] = 0xF7;
            cpuMem.mem[i + 0x009] = 0xEF;
            cpuMem.mem[i + 0x00A] = 0xDF;
            cpuMem.mem[i + 0x00F] = 0xBF;
        }

    }

     void setGameGenieState(bool enable) {
        if (memMapper != null) {
            memMapper.setGameGenieState(enable);
        }
    }

    // Returns CPU object.
     CPU getCpu() {
        return cpu;
    }

    // Returns PPU object.
     PPU getPpu() {
        return ppu;
    }

    // Returns pAPU object.
     PAPU getPapu() {
        return papu;
    }

    // Returns CPU Memory.
     Memory getCpuMemory() {
        return cpuMem;
    }

    // Returns PPU Memory.
     Memory getPpuMemory() {
        return ppuMem;
    }

    // Returns Sprite Memory.
     Memory getSprMemory() {
        return sprMem;
    }

    // Returns the currently loaded ROM.
     ROM getRom() {
        return rom;
    }

    // Returns the GUI.
     AppletUI getGui() {
        return gui;
    }

    // Returns the memory mapper.
     MemoryMapper getMemoryMapper() {
        return memMapper;
    }

    // Loads a ROM file into the CPU and PPU.
    // The ROM file is validated first.
     bool loadRom(String file) {

        // Can't load ROM while still running.
        if (isRunningFlag) {
            stopEmulation();
        }

        {
            // Load ROM file:

            rom = new ROM(this);
            rom.load(file);
            if (rom.isValid()) {

                // The CPU will load
                // the ROM into the CPU
                // and PPU memory.

                reset();

                memMapper = rom.createMapper();
                memMapper.init(this);
                cpu.setMapper(memMapper);
                memMapper.loadROM(rom);
                ppu.setMirroring(rom.getMirroringType());

                this.romFile = file;

            }
            return rom.isValid();
        }

    }

    // Resets the system.
     void reset() {

        if (rom != null) {
            rom.closeRom();
        }
        if (memMapper != null) {
            memMapper.reset();
        }

        cpuMem.reset();
        ppuMem.reset();
        sprMem.reset();

        clearCPUMemory();

        cpu.reset();
        cpu.init();
        ppu.reset();
        palTable.reset();
        papu.reset();

        KbInputHandler joy1 = gui.getJoy1();
        if (joy1 != null) {
            joy1.reset();
        }

    }

    // Enable or disable sound playback.
     void enableSound(bool enable) {

        bool wasRunning = isRunning();
        if (wasRunning) {
            stopEmulation();
        }

        if (enable) {
            papu.start();
        } else {
            papu.stop();
        }

        //System.out.println("** SOUND ENABLE = "+enable+" **");
        Globals.enableSound = enable;

        if (wasRunning) {
            startEmulation();
        }

    }

     void setFramerate(int rate) {

        Globals.preferredFrameRate = rate;
        Globals.frameTime = (1000000 / rate).toInt();
        papu.setSampleRate(papu.getSampleRate(), false);

    }

     void destroy() {

        if (cpu != null) {
            cpu.destroy();
        }
        if (ppu != null) {
            ppu.destroy();
        }
        if (papu != null) {
            papu.destroy();
        }
        if (cpuMem != null) {
            cpuMem.destroy();
        }
        if (ppuMem != null) {
            ppuMem.destroy();
        }
        if (sprMem != null) {
            sprMem.destroy();
        }
        if (memMapper != null) {
            memMapper.destroy();
        }
        if (rom != null) {
            rom.destroy();
        }

        gui = null;
        cpu = null;
        ppu = null;
        papu = null;
        cpuMem = null;
        ppuMem = null;
        sprMem = null;
        memMapper = null;
        rom = null;
        palTable = null;

    }
}
