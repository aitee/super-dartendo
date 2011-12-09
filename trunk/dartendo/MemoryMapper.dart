/*
vNES
Copyright © 2006-2011 Jamie Sanders

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.
 */
interface MemoryMapper {

    void init(NES nes);   
    void loadROM(ROM rom);
    void write(int address, int value);
    int load(int address);
    
    int joy1Read();
    int joy2Read();

    void reset();
    void setGameGenieState(bool value);

    void clockIrqCounter();
    void loadBatteryRam();
    void destroy();

    void stateLoad(MemByteBuffer buf);
    void stateSave(MemByteBuffer buf);

    void setMouseState(bool pressed, int x, int y);

    void latchAccess(int address);
}

