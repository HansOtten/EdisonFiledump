program EdisonFiledump;

{ dumps file from RX01 PDP-11/23 Edison disk images

Syntax: edisonfiledump <name of diskfile with files to dump>
                      [<name of output disk de-interleaved>
                      [verbose]]

  Hans Otten, 2026
   V0.1 5 january catalog and diskmap shown as debug info
   V0.2 7 january commandline and verbose debug info, correct diskmap walktrough
                  right size calcualtion of file
   V0.3 7 january first time files are created

  MIT License
  Copyright (c) 2026 Hans Otten

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE

   }


{  Read the document edison disk structure.txt for information on the
file structures of Edison disks,

}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, sysutils ;

const
  sectorsintrack = 26   ;
  tracksindisk   = 77   ;
  maxsector      = (sectorsintrack * tracksindisk - 1) ; { zerobased }
  wordsinsector  = 64 ;
  maxfiles       = 48 ;{ 4* 12 , 12 sectors , four catalogs per sector }

type
  Tsector = array[1..wordsinsector] of int16 ;
  Tdisk = array[0..maxsector] of Tsector ;



  TCatalog =  record
                numberoffiles : int16 ; { on first catalog entry, next  01 }
                filename : array[1..12] of int16 ;
                location, size, words : int16
              end ;


var
  DiskInputFilename  : string ;
  DiskInputfile      : file of Tsector ;
  DiskoutputFilename : string ;
  DiskOutputfile     : file of Tsector ;
  sectornumber       : integer ;
  inDisk      : Tdisk ;
  outDisk     : Tdisk ;
  Catalog     : array [1..maxfiles] of Tcatalog ;
  FilesInUse  : int16 ;

  Diskmap     : array[1..249] of int16 ;
  freepage,
  nextpage    : int16 ;
  verbose     : boolean ;


function ReadSector(sectornumber : integer): Tsector ;
  var
    tracknumber, sectoraddress: integer ;

begin
  tracknumber := sectornumber div sectorsintrack ;
  sectoraddress := ((3 * sectornumber) mod sectorsintrack) ;
  Readsector :=  inDisk[sectoraddress + (sectorsintrack * tracknumber)] ;
end ;

procedure ReadInDisk ;

var
  sectornumber : integer ;

begin
  for sectornumber := 0 to maxsector  do
    read(Diskinputfile, Indisk[sectornumber] ) ;
end ;

procedure WriteOutDisk ;

var
  sectornumber : integer;

begin
  for sectornumber := 0 to maxsector  do
    begin
      write(Diskoutputfile, Outdisk[sectornumber] ) ;
    end ;
end ;

procedure GetCatalog ;

{ A disk catalog starts at sector 14
  record
    size of catalog  1 word   at first catalog entry, 01 otherwise
    filename        12 words
    attributes       3 words   location, size, ?

  first word is total nr of files
  Each file record in catalog is 16 words
}
var

  usedfile  : integer ;
  scatalog  : array[1..(12*wordsinsector)] of int16 ;
  { catalog is max 12 sectors }

  procedure FillSectorcatalog ;

  { catalog starts at sector 14, and is 12 sectors long
    add words form sectors into buffer scatalog}

  var
    scount, ccount : integer ;
    csector : Tsector ;
  begin
    for scount := 0 to 11 do
      begin
        csector := OutDisk[14 + scount] ;
        for ccount := 1 to wordsinsector  do
          begin
            scatalog[(scount) * wordsinsector  + ccount] := csector[ccount] ;
           end ;
      end ;
  end ;

   procedure FillCatalog(usedfile : integer) ;

  var
    count : integer ;

  begin
     for count := 1 to 12 do
      begin
        catalog[usedfile].filename[count] := scatalog[(usedfile) * 16 + count + 1] ;
      end ;
    catalog[usedfile].location := scatalog[usedfile * 16 + 14] ;
    catalog[usedfile].size := scatalog[usedfile * 16 + 15] ;
    catalog[usedfile].words := scatalog[usedfile * 16 + 16] ;
  end ;


begin
  FillSectorcatalog ;
  { determine nr of files }

  filesInUse:= scatalog[1] ;
  for usedfile := 0 to filesInUse - 1 do
    begin
      FillCatalog(usedfile) ;
    end ;


end ;

procedure Showcatalog ;
var
  usedfile,
  count : integer ;
begin
  writeln ;
  writeln('Catalog of ',DiskInputFilename) ;
  for usedfile := 0 to filesInUse -1 do
    begin
      for count := 1 to 12 do
         write(chr(catalog[usedfile].filename[count])) ;
      writeln(' ', ((catalog[usedfile].size - 1) * 8 * 128) +
                    (2 * catalog[usedfile].words), ' bytes') ;

      if verbose
        then
          begin
            write(' ', inttohex(catalog[usedfile].location, 4)) ;
            write(' ', inttohex(catalog[usedfile].size, 4)) ;
            write(' ', inttohex(catalog[usedfile].words, 4)) ;
            writeln ;
          end;
    end ;
  writeln('Number of files = ', filesInuse ) ;
  writeln ;
end ;

procedure OpenDiskInputfile ;

begin
   if FileExists(DiskInputFilename)
     then
       begin
         assign(DiskInputfile,DiskInputFilename) ;
         {$I-}
         reset(DiskInputFile) ;
         {$I+}
         if IOResult<>0 then
           begin
              writeln ('Error opening file ', DiskInputFilename);
              halt ;
           end ;
       end
   else
     begin
       writeln('No such file ', DiskInputFilename) ;
       halt
     end
 end ;


procedure OpenOutDisk ;
var
  yesno : string ;
begin
   if length(DiskOutputFilename) = 0
     then
       begin
         writeln('hoe kom je hier?') ;
         halt ;
       end;
   if FileExists(DiskOutputFilename)
     then
       begin
         write('Overwrite ', DiskOutputFilename,' [Y/n] ');
         readln(yesno) ;
         if (yesno = 'n') or (yesno = 'N')
           then
             halt ;
       end ;
   assign(DiskOutputfile,DiskOutputFilename) ;
   {$I-}
   rewrite(DiskOutputFile) ;
   {$I+}
   if IOResult<>0 then
     begin
       writeln('Error opening file ', DiskOutputFilename);
       halt ;
     end ;
 end ;


procedure DeInterleave ;

begin
    { deinterleave into internal OutDisk buffer }
  for sectornumber := 0 to maxsector do
    Outdisk[sectornumber] := ReadSector(sectornumber)  ;
end ;

procedure ShowLocationSize ;
var count : integer ;


procedure ShowLocationSizeperfile(filenumber: integer)  ;

 var
  slocation : integer ;
  ssize     : integer ;
  count     : integer ;
begin
  writeln ;
  for count := 1 to 12 do
     write(chr(catalog[filenumber].filename[count])) ;
  writeln ;
  slocation := (8 * catalog[filenumber].location + 2) * 128 ;
  write('Location Page = ',
         inttohex(catalog[filenumber].location, 5),
         ' Sector = ',
         inttohex(slocation,5) );

  writeln ;

  { walk trough diskmap }

  writeln ;
  slocation := catalog[filenumber].location ;
  ssize := catalog[filenumber].size ;
  writeln('Location ',inttohex(slocation,4), ' Size ' , inttohex(ssize,4)) ;
  for count := 1 to ssize do
    begin
       writeln( count:2, ' ',
                'location ', inttohex(slocation,5), ' ' ,
                'diskmap =', inttohex(diskmap[slocation],5), ' ',
                'Sector = ', inttohex((8*slocation +2)*128,5) ) ;
                slocation := diskmap[slocation] ;
    end ;

  writeln('Size of file = ', (ssize - 1) * 8 * 128 + 2 * catalog[filenumber].words) ;

end;

begin
  if FilesInuse > 0
    then
      for count := 1 to FilesInUse do
        ShowLocationSizeperfile(count) ;
end ;

procedure ReadDiskmap ;

var
 sdiskmap :  array[1..(4*wordsinsector)] of int16 ;
 count    : integer  ;

   procedure FillSectordiskmap ;
   { diskmap starts at sector 10, and is 4 sectors long }

   var
     scount, ccount : integer ;
     csector : Tsector ;
   begin
     for scount := 0 to 3 do
       begin
         csector := OutDisk[10 + scount] ;
         for ccount := 1 to wordsinsector do
           sdiskmap[scount * wordsinsector  + ccount] := csector[ccount] ;
       end ;
   end ;

begin
  FillSectordiskmap ;
  Freepage := sdiskmap[1] ;
  Nextpage := sdiskmap[2] ;
  for count := 1 to 249 do
    begin
      Diskmap[count] := sdiskmap[count + 2] ;
    end;
end ;

procedure ShowDiskmap ;

var count : integer ;

begin
  writeln('The Diskmap') ;
  writeln('Free page = ', inttohex(freepage,4), ' ' ,
          'Next page = ', inttohex(nextpage,4)) ;
  for count := 1 to 249 do
    begin
      write(inttohex(Diskmap[count], 4), ' ' ) ;
      if count mod 16 = 0
        then
          writeln ;
    end;
  writeln ;
end ;

procedure CheckParameters ;

begin
  verbose := false ;
  DiskInputfilename := '' ;
  DiskOutputfilename := '' ;
  if paramcount = 0
    then
      begin
       writeln('Syntax: edisonfiledump <name of diskfile with files to dump> [<name of output disk de-interleaved> [verbose]]') ;
       halt ;
      end;
   if paramcount > 0
     then
       DiskInputfilename := paramstr(1) ;
   if paramcount > 1
     then
         DiskOutputfilename := paramstr(2) ;
   if paramcount > 2
     then
       if paramstr(3) = 'verbose'
         then
           verbose := true ;
end ;

procedure Dumpfile(filenumber : integer) ;
var
  pagebuffer   : array[1..(8*wordsinsector)] of int16 ;
  dumpfilename,
  textdumpfilename : string ;
  dumpfile         : file of int16 ;
  textdumpfile     : text ;

  slocation : integer ;
  ssize     : integer ;
  swords    : integer ;
  count     : integer ;
  istext    : boolean ;


  procedure FillPagebuffer(pagenumber : integer)  ;
  { page is 8 sectors long }
  var
    scount, ccount : integer ;
    csector : Tsector ;
  begin
    for scount := 0 to 7 do
      begin
        csector := OutDisk[(pagenumber * 8) +  2 + scount] ;
        for ccount := 1 to wordsinsector  do
          begin
            pagebuffer[(scount) * wordsinsector  + ccount] := csector[ccount] ;
          end ;
      end ;
  end ;

  procedure OpenDumpFiles ;
  begin
    assign(dumpfile,dumpfilename) ;
    {$I-}
    rewrite(dumpfile) ;
    {$I+}
    if IOResult<>0 then
      begin
        writeln('Error opening file ', dumpfilename);
        halt ;
      end ;
    if istext
      then
        begin
          assign(textdumpfile,textdumpfilename) ;
          {$I-}
          rewrite(textdumpfile) ;
          {$I+}
          if IOResult<>0 then
            begin
              writeln('Error opening file ', textdumpfilename);
              halt ;
            end ;
        end;
  end;

  procedure Writetodumpfiles(dumpword : int16)  ;

  begin
    write(dumpfile, dumpword) ;
    if istext
      then
        if (dumpword = $0A)
          then
            writeln(textdumpfile)
        else if (dumpword >= $20) and (dumpword < $7F)
          then
            write(textdumpfile, chr(dumpword)) ;
  end;

  procedure Dumbpage(pagenumber: integer) ;
  { dump pagebuffer }
  var
    count : integer ;
  begin
    Fillpagebuffer(pagenumber) ;
    for count :=  1 to 8*wordsinsector do
      Writetodumpfiles(pagebuffer[count])
  end;

  procedure DumbLastpage(pagenumber, ssize : integer ) ;
  { dump page = 8 sectors of 64 words }
  var
    count : integer ;
   begin
    Fillpagebuffer(pagenumber) ;
    for count :=  1 to ssize do
      Writetodumpfiles(pagebuffer[count]) ;
  end;

begin
  dumpfilename := '' ;
  for count := 1 to 12 do
    if catalog[filenumber].filename[count] <> $20
      then
        dumpfilename := dumpfilename + (chr(catalog[filenumber].filename[count])) ;
  { check if filename contains text }
  istext := (pos('text', dumpfilename) <> 0) or (pos('txt', dumpfilename) <> 0);
  if istext
    then
      textdumpfilename := dumpfilename + '.txt'
    else
      textdumpfilename := '' ;
  OpenDumpfiles ;

  { walk trough diskmap and dump pages to dumpfile, last one only   }

  slocation := catalog[filenumber].location ; {startnummer page}
  ssize     := catalog[filenumber].size ;     { nr of pages    }
  swords    := catalog[filenumber].words ;      { size of last page used }


  for count := 1 to ssize - 1 do
    begin
      Dumbpage(slocation) ; { dump all pages except last one }
      slocation := diskmap[slocation] ;   { next page in list diskmap }
    end ;
  DumbLastpage(slocation, swords) ;
  write('Created ',dumpfilename) ;
  CloseFile(dumpfile) ;
  if Istext
    then
      begin
        writeln(', also created text file ' , textdumpfilename) ;
        CloseFile(textdumpfile) ;
      end
    else
      writeln ;
end;

procedure DumpFiles ;

var count : integer ;

begin
  if FilesInuse > 0
    then
      for count := 0 to FilesInUse - 1 do
        Dumpfile(count) ;
end ;



begin

  writeln('Dump Edison PDP=11/23 files from RX01 floppy dumps') ;
  writeln('V1.0 Hans Otten, 2026') ;

  CheckParameters ;
  OpenDiskInputfile ;
  ReadIndisk ;
  DeInterleave ;
  if length(DiskOutputfilename) > 0
    then
      begin
        OpenOutDisk ;
        WriteOutDisk ;
      end;
  GetCatalog ;
  Showcatalog ;
  ReadDiskmap ;
  if verbose
    then
      ShowDiskmap ;
  if verbose
    then
      ShowLocationSize ;
  DumpFiles ;
 end.
