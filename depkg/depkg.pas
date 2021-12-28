program depkg;


type

 bigstr    = string[255];


var

 counter    : byte;
 pkgname    : bigstr;
 ch         : char;
 ch2        : char;
 chb        : byte absolute ch;
 chb2       : byte absolute ch2;
 theline    : bigstr;
 f          : text;
 prog       : file;
 prog_sum   : byte;
 prog_count : byte;
 fname      : bigstr;
 checksum   : bigstr;
 buffer     : array [1..128] of byte;
 the_byte   : byte;
 buffer_ptr : byte;
 blocks_out : byte;
 hextable   : array[1..102] of byte;
 message    : bigstr;


(* nothing entered on CLI, display info *)
procedure display_help;
begin
 writeln('depkg - 8 April 2018 - http://www.foxhollow.ca/cpm');
 writeln('usage: depkg filename.pkg');
 writeln;
 writeln('This program will extract files created by G. Searle''s');
 writeln('Binary to CPM Package Utility for Windows');
end;


(* extract filename from line of data *)
function get_filename(linein: bigstr) : bigstr;
var thespace : integer;
begin
 get_filename := '';
 thespace := pos(' ',linein);
 if thespace > 0 then
 begin
  thespace := thespace+1;
  get_filename := copy(linein,thespace,255);
 end;
end;


(* this will write a full 128 byte sector *)
(* after the buffer has been filled       *)
procedure write_buffer;
begin
 (* increment and store the byte *)
 buffer_ptr := buffer_ptr + 1;
 buffer[buffer_ptr] := the_byte;

 (* is the buffer full? *)
 if buffer_ptr = 128 then
 begin
   blockwrite(prog, buffer, 1);
   buffer_ptr := 0;
   write('.');
   blocks_out := blocks_out + 1;
   if blocks_out = 35 then
   begin (* too many dots on the line, start new one *)
     writeln;
     write('   ');
     blocks_out := 0;
   end;
 end;
end;

(* write the remaining buffer *)
(* then close the file        *)
procedure close_buffer;
begin
 (* deal with partial buffer *)
 if buffer_ptr <> 0 then (* not empty *)
    begin
      (* writeln('buffer not full'); *)
      if buffer_ptr <> 128 then (* not full *)
         for counter := buffer_ptr + 1 to 128 do
         begin
          buffer[counter] := 0;
         end;
       blockwrite(prog, buffer, 1);
    end;
 close(prog);
 write('.');
end;


procedure process_pkg;
var OK : boolean;
begin

 (* open the pkg file for read *)
 assign(f, pkgname);
 {$I-} reset(f); {$I+}
 OK := (IOresult = 0);
 if not OK then
   begin
     writeln;
     writeln('!!! Check your spelling !!!');
     writeln;
     writeln('"' + pkgname + '" was not found on disk');
     halt;
   end;

 writeln('-- Reading ' + pkgname);

 while not eof(f) do
   begin

     (* grab the filename *)
     readln(f, theline);
     fname := get_filename(theline);

     if (fname = '') then
     begin
      close(f);
      exit;
     end;

     writeln('   Extracting ' + fname);
     write('   ');
     buffer_ptr := 0; (* how many bytes in the buffer *)
     blocks_out := 0; (* how many records written*)
     ch := '.'; ch2 := '.';

     (* open the file for writing *)
     assign(prog, fname);
     rewrite(prog);

     (* zero our counters for a new file *)
     prog_sum := 0;
     prog_count := 0;

     (* user are eg:  U0 *)
     readln(f, theline);

     (* main portion containing hex encoded binary data *)
     read(f,ch);
     while ch <> '>' do
     begin
       read(f, ch);
       if ch <> '>' then
       begin
         if eof(f) then writeln('!!! unexpected end-of-file while reading pkg !!!');
         read(f, ch2);
         if ch2 = '>' then writeln('!!! I think your pkg file has issues !!!');
         the_byte := (hextable[chb] * 16) + hextable[chb2];
         write_buffer;
         prog_count := prog_count + 1;
         prog_sum := prog_sum + the_byte;
      end;
     end;
     close_buffer;
     writeln;
     message := '';

     (* length *)
     read(f,ch);
     read(f,ch2);
     the_byte := (hextable[ord(ch)] * 16) + hextable[ord(ch2)];
     if the_byte <> prog_count then message := '   * Bad File, incorrect file length *';

     (*checksum *)
     read(f,ch);
     read(f,ch2);
     the_byte := (hextable[ord(ch)] * 16) + hextable[ord(ch2)];
     if the_byte <> prog_sum then message := '   * Bad File, checksum is incorrect *';

     (* read to end of line *)
     readln(f,theline);

     if message <> '' then writeln(message);
     writeln;

   end;
 close(f);
end;


(* build a hex table for fast conversions *)
procedure make_hex_table;
begin
  for counter := 0 to 9 do (* numbers 0..9 *)
  begin
   hextable[counter+48] := counter
  end;

  for counter := 0 to 5 do (* upper case A..F *)
  begin
   hextable[counter+65] := 10 + counter;
  end;

  for counter := 0 to 5 do (* lower case a..f *)
  begin
   hextable[counter+97] := 10 + counter;
  end;
end;



begin

 make_hex_table;


 (*
 pkgname := 'g:infocom.pkg';
 pkgname := 'k:test.pkg';
 process_pkg;
 exit;
 *)

 if paramcount = 0 then
 begin
  display_help;
  exit;
 end;

 pkgname := paramstr(1);
 process_pkg;

 writeln('-- Done.');
end.
