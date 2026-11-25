In this archive: 

1. Dump Edison PDP-11/23 files from RX01 floppy images to files
2. Run the Edison system in SIMH

Hans Otten , 2026
http://pascal.hansotten.com


Jos Dreessen received a disk set of the Edision system from Günter Dotzel of Modulaware.
And he made images of it. 

This diskset contains the whole Edison system, binaries and sources of all programs. 
Even the sources not published in the book Programming a Personal Computer, by Per Brinch Hansen
like the Alva PDP-11 'assembler'.

The program edisonFiledump is written to extract the files from the disk image.
Therefore the structure of the disk was studied, most of it was somehow documented in the book.
A detailed look with an hex editor was helful also!  
The relevant information is available in the document 'edison disk structure.txt'.

The program runs as a command line.
Syntax: edisonfiledump <name of diskfile with files to dump> [<name of output disk de-interleaved> [verbose]]'

With only the name of the disk image the files on the disk are extracted as binary files.
If a filename contains the string 'text' or 'txt' it is assumed to be a source file and also extracted in normal text format.
This appears to be true for all text files in the disk images.

If the second optional argument is given, the disk image is written into it as file but without the interleaving. Useful for study/debugging, not for running!

A third parameter 'verbose' shows a lot of the internal dats structures of the disk. That was very helpful, in combination with a hex editor, 
to find out how the disk structure really works and is interpreted the right way.

The program is written in portable Freepascal. A Windows and Ubuntu executable is included. For other Linux or Mac use Freepascal and the source to compile to a command line program.

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
s

Command =
