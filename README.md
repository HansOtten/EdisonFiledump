# Dump Edison (Per Brinch Hansen) images to textfiles 

Edison disk images sources converted to ASCII

![License](https://img.shields.io/badge/license-MIT-blue.svg) ![Version](https://img.shields.io/badge/version-1.0.0-green.svg)

## Table of Contents
1. Dump Edison PDP-11/23 files from RX01 floppy images to files
2. Run the Edison system in SIMH


### Tech Stack

- **Freepascal**

## Installation

```bash
download repository
fpc EdisonFiledump.lpr
or use Lazarus project EdisonFiledump
```

## Usage

```
Here an example of the basic usage:

> EdisonFiledump rx02_system.bin
Dump Edison PDP=11/23 files from RX01 floppy dumps
V1.0 Hans Otten, 2026

Catalog of edison_progs1.bin
alva1text    58698 bytes
alva2text    9616 bytes
assembletext 14326 bytes
compiletext  16404 bytes
edison1text  18928 bytes
edison2text  49726 bytes
Number of files = 6

Created alva1text, also created text file alva1text.txt
Created alva2text, also created text file alva2text.txt
Created assembletext, also created text file assembletext.txt
Created compiletext, also created text file compiletext.txt
Created edison1text, also created text file edison1text.txt
Created edison2text, also created text file edison2text.txt

In the folder diskimages you find all the disk images as dumped by Jos Dreessen and the files extracted with EdisonFiledump as binaries without type and with type .txt as sources.
. The .ibin files are the de-interleaved disk images, that will not run in simh!

2. Run the Edison system in simh

The disk images run fine in the PDP-11 emulator of SIMH 
In the folder simh you find:
- pdp11.exe, a precompiled simh Windows executable. Compile simh from source for other operating systems. 
- config.simh, the bootloader (thanks Peter de Wachter)

> simh config.simh

PDP-11 simulator Open SIMH V4.1-0 Current        git commit id: 6e9324e0+uncommitted-changes
#
# Load two disk images using the commands:
#
#     attach ry0 disk1.dsk
#     attach ry1 disk2.dsk
#
# and boot using:
#
#     go 0
#
%SIM-INFO: RY0: buffering file in memory
sim> att ry0 rx02_kernel.bin
%SIM-INFO: RY0: buffering file in memory
sim> att ry1 rx02_system.bin
%SIM-INFO: RY1: buffering file in memory
sim> go 0

The Edison system

insert two disks and type

s if both disks are standard
0 if only disk 0 is standard
1 if only disk 1 is standard
b if both disks are blank


Command =

```

Describe how to use the project here.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤ by [HansOtten](https://github.com/HansOtten)
