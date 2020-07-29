unit Compatibility;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  {$IfDef UNIX}BaseUnix, termio
  {$Else}Windows
  {$Endif};

procedure GetWindowSize(Handle: THandle; out Rows: Integer; out Columns: Integer);
function isATTY(Handle: THandle): Boolean; inline;
function OpenTerminalFile(const FileName: String; OpenWrite: Boolean): THandle;

function StandardIn: THANDLE; inline;
function StandardOut: THANDLE; inline;
function StandardErr: THANDLE; inline;

function InitOutputConsole(Handle: THANDLE): Cardinal;
function InitInputConsole(Handle: THANDLE): Cardinal;

procedure ResetConsole(Handle: THANDLE; OrigState: Cardinal);

implementation

procedure GetWindowSize(Handle: THandle; out Rows: Integer; out
   Columns: Integer);
{$IfDef Unix}
var
  sz: TWinSize;
begin
  FpIOCtl(Handle, TIOCGWINSZ, @sz);
  Rows := sz.ws_row;
  Columns := sz.ws_col;
end;
{$else}
var
  csbi: CONSOLE_SCREEN_BUFFER_INFO;
begin
  FillChar(csbi, SizeOf(csbi), 0);
  GetConsoleScreenBufferInfo(Handle, csbi);
  Columns := csbi.srWindow.Right - csbi.srWindow.Left + 1;
  Rows := csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
end;
{$EndIf}

function isATTY(Handle: THandle): Boolean;
{$IfDef Windows}
var
  dummy: TByHandleFileInformation;
{$EndIf}
begin
 {$IfDef UNIX}
 Result := termio.IsATTY(Handle) <> 0;
 {$Else}
 // dirty hack but seems to work
 Result := not GetFileInformationByHandle(Handle, dummy);
 {$EndIf}
end;

function OpenTerminalFile(const FileName: String; OpenWrite: Boolean): THandle;
begin
 if OpenWrite then
 begin
  {$IfDef UNIX}
  Result := FpOpen(FileName, O_WRONLY);
  {$Else}
  Result := SysUtils.FileOpen(FileName, fmOpenRead);
  {$EndIf}
 end
 else
 begin
  {$IfDef UNIX}
  Result := FpOpen(FileName, O_RDONLY);
  {$Else}
  Result := SysUtils.FileOpen(FileName, fmOpenRead);
  {$EndIf}
 end;
end;

function StandardIn: THANDLE;
begin
 {$IfDef WINDOWS}
 Result := GetStdHandle(STD_INPUT_HANDLE);
 {$Else}
 Result := StdInputHandle;
 {$EndIf}
end;

function StandardOut: THANDLE;
begin
 {$IfDef WINDOWS}
 Result := GetStdHandle(STD_OUTPUT_HANDLE);
 {$Else}
 Result := StdOutputHandle;
 {$EndIf}
end;

function StandardErr: THANDLE;
begin
 {$IfDef WINDOWS}
 Result := GetStdHandle(STD_ERROR_HANDLE);
 {$Else}
 Result := StdErrorHandle;
 {$EndIf}
end;

function InitOutputConsole(Handle: THANDLE): Cardinal;
begin
 Result := 0;
{$IfDef WINDOWS}
  GetConsoleMode(Handle, Result);
  SetConsoleMode(Handle, Result Or ENABLE_VIRTUAL_TERMINAL_PROCESSING);
{$EndIf}
end;

function InitInputConsole(Handle: THANDLE): Cardinal;
begin
 Result := 0;
{$IfDef WINDOWS}
  GetConsoleMode(Handle, Result);
  SetConsoleMode(Handle, Result Or ENABLE_VIRTUAL_TERMINAL_INPUT);
{$EndIf}
end;

procedure ResetConsole(Handle: THANDLE; OrigState: Cardinal);
begin
{$IfDef WINDOWS}
  SetConsoleMode(Handle, OrigState);
{$EndIf}
end;

end.

