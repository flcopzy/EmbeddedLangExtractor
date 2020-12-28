{ *************************************************************************** }
{                                                                             }
{   ModuleName  :   LangExtractor.pas                                         }
{   Author      :   ZY                                                        }
{   EMail       :   zylove619@hotmail.com                                     }
{   Description :   Extract embedded lang from exe file which use             }
{                   the gnugettext lib.                                       }
{                                                                             }
{ *************************************************************************** }

unit LangExtractor;

interface

type

  /// <summary> Lang Extracting Callback. </summary>
  /// <param name="ASavedDirectory"> Lang saved directory. </param>
  /// <param name="ALangFileName"> The lang file name(Relative). </param>
  /// <param name="ACurrentIndex"> Current extracting file index(start from 0). </param>
  /// <param name="ATotalCount"> Total lang file count. </param>
  TOnLangExtracting = procedure(const ASavedDirectory, ALangFileName: string; ACurrentIndex, ATotalCount: Integer) of object;

/// <summary> Extract lang from exe file. </summary>
/// <param name="AExecutableFileName"> The executable file full name. </param>
/// <param name="ASavedDirectory"> Lang saved directory. </param>
/// <param name="AOnLangExtracting"> Lang extracting callback proc. </param> 
procedure ExtractLang(const AExecutableFileName, ASavedDirectory: string; AOnLangExtracting: TOnLangExtracting = nil);

implementation

uses

  { System }
  SysUtils, Classes;

type

  { Types from gnugettext }
  {$IFNDEF UNICODE}
  RawByteString=AnsiString;
  {$ENDIF}

  FilenameString = string;

  { Class from gnugettext.pas }
  TEmbeddedFileInfo=
    class
      offset,size:int64;
    end;

  { TLangExtractor do the actual extraction work, the
    analysis logic is from TFileLocator in gnugettext. }
  TLangExtractor = class
  private
    FExecutableFilename: string;
    FOnLangExtracting: TOnLangExtracting;

    procedure DoExtracting(const ASavedDirectory, ALangFileName: string; ACurrentIndex, ATotalCount: Integer);
    { Part from TFileLocator.Create }
    function CreateFileList: TStringList;
    { Part from TFileLocator.Destroy }
    procedure FreeFileList(var AFileList: TStringList);
    { TFileLocator.FindSignaturePos }
    function FindSignaturePos(const signature: RawByteString; str: TFileStream): Int64;
    { TFileLocator.ReadInt64 }
    function ReadInt64 (str:TStream):int64;
    { TFileLocator.Analyze }
    procedure SaveLangTo(const ASavedDirectory: string); overload;
    procedure SaveLangTo(AExecutableFileStream: TFileStream; AFileList: TStringList; const ASavedDirectory: string); overload;
  public
    constructor Create(const AExecutableFilename: string; AOnLangExtracting: TOnLangExtracting = nil);
  end;

procedure ExtractLang(const AExecutableFileName, ASavedDirectory: string; AOnLangExtracting: TOnLangExtracting = nil);
begin
  with TLangExtractor.Create(AExecutableFileName, AOnLangExtracting) do
    try
      SaveLangTo(ASavedDirectory);
    finally
      Free;
    end;
end;

{ TLangExtractor }

procedure TLangExtractor.SaveLangTo(const ASavedDirectory: string);
var
  HeaderSize,
  PrefixSize: Integer;
  dummysig,
  headerpre,
  headerbeg,
  headerend:RawByteString;
  i:integer;
  headerbeginpos,
  headerendpos:integer;
  offset,
  tableoffset:int64;
  fs:TFileStream;
  fi:TEmbeddedFileInfo;
  filename,
  BaseDirectory:FilenameString;
  filename8bit:RawByteString;
  filelist: TStringList;
const
  // DetectionSignature: used solely to detect gnugettext usage by assemble
  DetectionSignature: array[0..35] of AnsiChar='2E23E563-31FA-4C24-B7B3-90BE720C6B1A';
  // Embedded Header Begin Signature (without dynamic prefix written by assemble)
  BeginHeaderSignature: array[0..35] of AnsiChar='BD7F1BE4-9FCF-4E3A-ABA7-3443D11AB362';
  // Embedded Header End Signature (without dynamic prefix written by assemble)
  EndHeaderSignature: array[0..35] of AnsiChar='1C58841C-D8A0-4457-BF54-D8315D4CF49D';
  // Assemble Prefix (do not put before the Header Signatures!)
  SignaturePrefix: array[0..2] of AnsiChar='DXG'; // written from assemble
begin

  // Attn: Ensure all Signatures have the same size!
  HeaderSize := High(BeginHeaderSignature) - Low(BeginHeaderSignature) + 1;
  PrefixSize := High(SignaturePrefix) - Low(SignaturePrefix) + 1;

  // dummy usage of DetectionSignature (otherwise not compiled into exe)
  SetLength(dummysig, HeaderSize);
  for i := 0 to HeaderSize-1 do
    dummysig[i+1] := DetectionSignature[i];

  // copy byte by byte (D2009+ compatible)
  SetLength(headerpre, PrefixSize);
  for i:= 0 to PrefixSize-1 do
    headerpre[i+1] := SignaturePrefix[i];

  SetLength(headerbeg, HeaderSize);
  for i:= 0 to HeaderSize-1 do
    headerbeg[i+1] := BeginHeaderSignature[i];

  SetLength(headerend, HeaderSize);
  for i:= 0 to HeaderSize-1 do
    headerend[i+1] := EndHeaderSignature[i];

  BaseDirectory:=ExtractFilePath(FExecutableFilename);

  fs:=TFileStream.Create(FExecutableFilename,fmOpenRead or fmShareDenyNone);
  try

    filelist := CreateFileList;
    try
      // try to find new header begin and end signatures
      headerbeginpos := FindSignaturePos(headerpre+headerbeg, fs);
      headerendpos := FindSignaturePos(headerpre+headerend, fs);

      if (headerbeginpos > 0) and (headerendpos > 0) then
      begin
        // adjust positions (to the end of each signature)
        headerbeginpos := headerbeginpos + HeaderSize + PrefixSize;

        // get file table offset (8 byte, stored directly before the end header)
        fs.Seek(headerendpos - 8, soFromBeginning);
        // get relative offset and convert to absolute offset during runtime
        tableoffset := headerbeginpos + ReadInt64(fs);

        // go to beginning of embedded block
        fs.Seek(headerbeginpos, soFromBeginning);

        offset := tableoffset;
        Assert(sizeof(offset)=8);
        while (true) and (fs.Position<headerendpos) do begin
          fs.Position := offset;
          offset:=ReadInt64(fs);
          if offset=0 then
            exit;
          offset:=headerbeginpos+offset;
          fi:=TEmbeddedFileInfo.Create;
          try
            // get embedded file info (adjusting dynamic to real offsets now)
            fi.Offset:=headerbeginpos+ReadInt64(fs);
            fi.Size:=ReadInt64(fs);
            SetLength (filename8bit, offset-fs.position);
            fs.ReadBuffer (filename8bit[1], offset-fs.position);
            filename:=trim({$IFNDEF UNICODE}utf8decode{$ELSE}UTF8ToString{$ENDIF}(filename8bit));
            filelist.AddObject(filename,fi);
          except
            FreeAndNil (fi);
            raise;
          end;
        end;
      end;
    finally
      try
        SaveLangTo(fs, filelist, ASavedDirectory);
      finally
        FreeFileList(filelist);
      end;
    end;
  finally
    FreeAndNil (fs);
  end;
end;

constructor TLangExtractor.Create(const AExecutableFilename: string; AOnLangExtracting: TOnLangExtracting);
begin
  inherited Create;
  FExecutableFilename := AExecutableFilename;
  FOnLangExtracting := AOnLangExtracting;
end;

function TLangExtractor.CreateFileList: TStringList;
begin
  Result:=TStringList.Create;
  Result.Duplicates:=dupError;
  { TODO : what if it's neither LINUX nor MSWINDOWS? }
  {$ifdef LINUX}
  Result.CaseSensitive:=True;
  {$endif}
  {$ifdef MSWINDOWS}
  Result.CaseSensitive:=False;
  {$endif}
  Result.Sorted:=True;
end;

procedure TLangExtractor.DoExtracting(const ASavedDirectory, ALangFileName: string; ACurrentIndex, ATotalCount: Integer);
begin
  if Assigned(FOnLangExtracting) then
    FOnLangExtracting(ASavedDirectory, ALangFileName, ACurrentIndex, ATotalCount);
end;

function TLangExtractor.FindSignaturePos(const signature: RawByteString;
  str: TFileStream): Int64;
// Finds the position of signature in the file.
const
  bufsize=100000;
var
  a:RawByteString;
  b:RawByteString;
  offset:integer;
  rd,p:Integer;
begin
  if signature='' then
  begin
    Result := 0;
    Exit;
  end;

  offset:=0;
  str.Seek(0, soFromBeginning);

  SetLength (a, bufsize);
  SetLength (b, bufsize);
  str.Read(a[1],bufsize);

  while true do begin
    rd:=str.Read(b[1],bufsize);
    p:=pos(signature,a+b);
    if (p<>0) then begin // do not check p < bufsize+100 here!
      Result:=offset+p-1;
      exit;
    end;
    if rd<>bufsize then begin
      // Prematurely ended without finding anything
      Result:=0;
      exit;
    end;
    a:=b;
    offset:=offset+bufsize;
  end;
  Result:=0;
end;

procedure TLangExtractor.FreeFileList(var AFileList: TStringList);
var
  Idx: integer;
begin
  for Idx := 0 to AFileList.Count-1  do
    AFileList.Objects[Idx].Free;
  FreeAndNil (AFileList);
end;

function TLangExtractor.ReadInt64(str: TStream): int64;
begin
  Assert (sizeof(Result)=8);
  str.ReadBuffer(Result,8);
end;

procedure TLangExtractor.SaveLangTo(AExecutableFileStream: TFileStream; AFileList: TStringList; const ASavedDirectory: string);
var
  I,
  LTotalCount: Integer;
  
  LSavedLangFileName,
  LLangRelativeFileName,
  LSavedLangFileDirectory: string;

  LLangFileStream: TFileStream;
  LEmbeddedFileInfo: TEmbeddedFileInfo;  
begin
  LTotalCount := AFileList.Count;

  { Lang files not found. }
  if LTotalCount  = 0 then
  begin
    DoExtracting('', '', -1, LTotalCount);
    Exit;
  end;

  { Extract all lang files. }
  for I := 0 to LTotalCount - 1 do
  begin
    LEmbeddedFileInfo := TEmbeddedFileInfo(AFileList.Objects[I]);

    { Make sure the saved directory exists. }
    LLangRelativeFileName := AFileList[I];
    LSavedLangFileName := IncludeTrailingPathDelimiter(ASavedDirectory) + LLangRelativeFileName;
    LSavedLangFileDirectory := ExtractFilePath(LSavedLangFileName);
    if not DirectoryExists(LSavedLangFileDirectory) then
      if not ForceDirectories(LSavedLangFileDirectory) then
        raise Exception.CreateFmt('Unable to create directory ''%s''', [LSavedLangFileDirectory]);

    { Create lang file. }    
    LLangFileStream := TFileStream.Create(LSavedLangFileName, fmCreate);
    try
      { Do call back. }
      DoExtracting(ASavedDirectory, LLangRelativeFileName, I, LTotalCount);

      { Save the lang file content from original exe file stream. }
      AExecutableFileStream.Position := LEmbeddedFileInfo.offset;
      LLangFileStream.CopyFrom(AExecutableFileStream, LEmbeddedFileInfo.size);
    finally
      LLangFileStream.Free;
    end;
  end;
end;

end.
