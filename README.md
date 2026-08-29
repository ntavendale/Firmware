# VHDL

VHDL Modules And Projects. I have started learning VHDL and designing FPGAs. To do this I have been using the Nandland book - _Getting Started with FPGAs_ by Russell Merrick. You can find more details on the book here here: https://nandland.com/

There is also a github site, https://github.com/nandland, where you can get the code from the book.

The book gears it's examples to the Go Board available on the site. That board uses a Lattice chip which means using the Lattice ICE Cube software which I found pretty clunky. It's also been deprecated by Lattice and there have been licensing issues in the past where, for a while, Lattice was trying to charge learners & hobbyists for it. In all fairness though, Russell Merrick was very helpful with licenses when contacted during this time.

Where I work we use AMD Vivado which, while far from perfect and with a slightly steeper learning curve, has built in simulation and the Standard Edition works free with a large range of lower end AMD/Xilinx FPGAs.

To that end I bought a entry level Digilent [Basys 3 Trainer Board](https://digilent.com/shop/basys-3-artix-7-fpga-trainer-board-recommended-for-introductory-users/) which has an Artix-7 FPGA. You can create circuits, and simulations, for this chip with the free Standard version of [Vivado](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vivado/vivado-buy.html). It seems that AMD _really, really_ want people using their stuff and seem to be going out of their way to make the barriers to doing so as low as possible.

Most of the files in this repository represent modules I have created to use the Basys 3/Artix-7 in place of the Go Board, and Vivado in place of ICE Cube. The Basys 3 has different pin outs (obviously), is clocked faster (100 MHz compared to the Go Board's 25 MHz), and since constraints files are not standardized the Vivado file will have a different format.

In addition the 7 Segment display on the Basys 3 works very differently from the Go Board and there are 4 digits to the Go Board's 2. The segment pin and decimal point signals are common to all 4 digits. Only the anode pin is different for each. This means that, to display a multiple digit number the display must be clocked.

You can find details [here](https://digilent.com/reference/programmable-logic/basys-3/reference-manual?redirect=1#seven_segment_display)

### Projects

I have this repository in my C:\Development\Firmware folder so the instructions below use that path. Update them for the path you are using when you set up the projects yourself.

I am using Vivado 2024.2 so if you are using a different version you may need to change stuff - particularly in the .tcl scripts as the part numbers may be different.

You will also need to [Install The Digilent Board Files](https://digilent.com/reference/programmable-logic/guides/install-board-files?srsltid=AfmBOorpSUrHndqL4rEyBMx-KnJ47-cCizt0wOQMAx5tg5Ju91RXEn3X)

To recreate the projects open Vivado but **do not** create or open a project.

### basys_seven_segment

This a simple project that displays a 4 digit decimal integer, starting at 0, on the 7 segment display and increments it once every second.

Run the following two commands in the Vivado Tcl console:

```
C:/Development/Firmware
source basys_seven_segment.tcl
```

Note the use of the "/" as the path delimiter.

### uart_loopback

VHDL Modules And Top Project for UART Loopback and Display on Basys 3 Board. Original Project on nandland.com used different display module. I'm using the one I have for the 4 digit Basys 3 display.

Connect Putty terminal (or any other serial terminal) to the COM port and type letters. You should see the letters appear in the terminal (loopback) as well as the hex value for the ASCII code on the seven segment display.

COM port can be obtained from the device manager on Windows.

Use at least VHDL 2008.

Run the following two commands in the Vivado Tcl console:

```
C:/Development/Firmware
source uart_loopback.tcl
```

Note the use of the "/" as the path delimiter.
