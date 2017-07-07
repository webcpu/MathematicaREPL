(* Wolfram Language Package *)

(* Created by the Wolfram Workbench 15-May-2017 *)

BeginPackage["MMAREPL`"];
(*******************************************************************************)
(*                                                                             *)
(**  Exported symbols                                                          *)
(*                                                                             *)
(*******************************************************************************)
loadFiles::usage = "Load source code";

addRunShortcutOfMathematica::usage = "Add run shortcut, restart Mathematica once";
showCells::usage = "Show cells";
hideCells::usage = "Hide cells";
cleanSelectedNotebook::usage = "Clean selected notebook";
deleteEmptyInputCells::usage = "Delete empty input cells";

REPLDStartedQ::usage = "REPL daemon status?";
REPLD::usage = "Start REPL daemon";

Begin["`Private`"];

(*******************************************************************************)
(*                                                                             *)
(**  Internal variables                                                        *)
(*                                                                             *)
(*******************************************************************************)
$host = "127.0.0.1";
$port = 8003;
Once[REPLLocked[] := False];

(*******************************************************************************)
(*                                                                             *)
(** File Loader                                                                *)
(*                                                                             *)
(*******************************************************************************)
ClearAll@loadFiles;
loadFiles[] := Module[{filelistPath, pathEndsQ, validFileQ, files},
  (*FileNameJoin[{$UserBaseDirectory, "Applications"}];*)
  filelistPath = NotebookDirectory[] <> "/filelist";
  pathEndsQ[path_][patt_] := StringEndsQ[path, patt];
  validFileQ[path_] := ! AnyTrue[{"/Kernel/init.m", "/MMAREPL.m"}, pathEndsQ[path]];
  files = Import[filelistPath, "List"] // Flatten // Select[validFileQ];
  Get@First@files
];

(*******************************************************************************)
(*                                                                             *)
(** REPLD                                                                      *)
(*                                                                             *)
(*******************************************************************************)
addRunShortcutOfMathematica[];
$REPLDSocket;
$ClientScoket;

ClearAll[REPLD];
REPLD[] := Module[{},
  If[REPLDStartedQ[], Null, (REPLLocked[] := False; REPLD[socketHandler])]];

REPLD[handler_] := Module[{port = $port},
  Needs["SocketLink`"];

  Close[$REPLDSocket] // Quiet;
  Close[$ClientSocket] // Quiet;

  $REPLSocket = SocketLink`CreateServerSocket[port]; (*// Quiet;*)
  $ClientSocket = SocketLink`CreateAsynchronousServer[$REPLSocket, handler] (* // Quiet;*)
];

(*******************************************************************************)
ClearAll[REPLDStartedQ];
REPLDStartedQ[] := Module[{host = $host, port = $port, address, socket, result},
  address = host <> ":" <> ToString@port;
  socket = SocketConnect@address // Quiet;
  result = Switch[Head[socket],
    SocketObject, True,
    Symbol, False,
    _, False
  ];
  Which[result, Close[socket]];
  result
];

ClearAll[socketHandler];
socketHandler[streams_] := Module[{ins = streams[[1]], outs = streams[[2]], request},
  request = handleHTTPRequest[streams];

  debugRequest@request;

  Which[tryLockREPLLock[ins, outs] == False, Return[]];

  Which[
    helpRequestQ@request, helpLookup@getHelpKeyword@request,
    StringLength@request > 0, evaluateREPLNotebookCells[]];

  sendResponse[outs];
  unlockREPLLock[ins, outs];
];

ClearAll[debugRequest];
debugRequest[request_] := Module[{},
  Print@StringLength@request;
  Print@request;
];

(*******************************************************************************)
ClearAll[handleHTTPRequest];
handleHTTPRequest[streams_] := Module[{ins = streams[[1]], outs = streams[[2]], data = {}},
  While[True, TimeConstrained[AppendTo[data, BinaryRead[ins]], 0.05, Break[]];];
  (*sendResponse[outs];*)
  FromCharacterCode[data]
];

ClearAll[sendResponse];
sendResponse[stream_] := Module[{newLine, content, length, response},
  newLine = "\r\n";
  content = "<html><body>" <> ToString@RandomInteger[{1, 10}]  <>
      "</body></html>" <> newLine ;
  length  = ToString[StringLength[content]];
  response =
      "HTTP/1.1 200 OK" <> newLine
          <> "Content-length: " <> length <> newLine <> newLine
          <> content <> newLine;
  BinaryWrite[stream, ToCharacterCode[response]];
];

(*******************************************************************************)
ClearAll[tryLockREPLLock];
tryLockREPLLock[ins_, outs_] := Module[{},
  If[REPLLocked[] == True,
    (sendResponse[outs]; Close[ins]; Close[outs]; False;),
    (REPLLocked[] := True; Protect[REPLLocked]; True)];
];

(*******************************************************************************)
CLearAll[unlockREPLLock];
unlockREPLLock[ins_, outs_] := Module[{},
  Unprotect[REPLLocked];
  REPLLocked[] := False;
  Close[ins];
  Close[outs];
];

(*******************************************************************************)
ClearAll[evaluateREPLNotebookCells];
evaluateREPLNotebookCells[] := Module[{},
  selectREPLNotebook[];
  (*evaluateCell /@ {"LOADER", "REPL"};*)
  evaluateCell /@ {"LOADER"};
];

ClearAll[selectREPLNotebook];
selectREPLNotebook[] := Module[{nb},
  nb = REPLNotebook[];
  SetSelectedNotebook[nb];
  SelectionMove[nb, All, EvaluationCell];

(*help = Notebooks[][[1]];
help = Documentation`HelpLookup[""];*)
(*SelectionMove[Cells[nb, CellStyle -> "NotesSection"][[1]], All, Cell];*)
(*FrontEndTokenExecute[nb, "OpenCloseGroup"];*)

(*FrontEndTokenExecute[#, "WindowMiniaturize"] & /@ DeleteCases[Notebooks[], nb];*)
];

ClearAll[evaluateCell];
evaluateCell[tag_] := Module[{nb},
  nb = REPLNotebook[];
  NotebookFind[nb, tag, All, CellTags];
  SelectionEvaluate[nb];
];

ClearAll[REPLNotebook];
REPLNotebook[] := Module[{REPLNotebookQ, rs},
  REPLNotebookQ[nb_] := NotebookGet@nb // Cases[#, (CellTags -> x_) -> x, Infinity] & // Union // MemberQ[#, "LOADER"] &;
  rs = Notebooks[] // Select[REPLNotebookQ] // First;
  rs
];

(*******************************************************************************)
(*                                                                             *)
(**  Utilities                                                                 *)
(*                                                                             *)
(*******************************************************************************)
ClearAll[showCells];
showCells[] := Module[{cells, show},
  cells[] := Cells[REPLNotebook[], CellStyle -> #]& /@ {"Input", "Output", "Standard"} // Catenate;
  show[cs_List] := SetOptions[#, CellOpen -> True]& /@ cs ;
  show@cells[];
];

(*******************************************************************************)
ClearAll[getEmptyInputCells];
getEmptyInputCells[] := Module[{emptyCells, inputCells,nb},
  nb = REPLNotebook[];
  inputCells = Cells[nb, CellStyle -> "Input"];
  emptyCells = Complement[getEmptyCells[], replCells];
  emptyCells
];

ClearAll[getEmptyCells];
getEmptyCells[] := Module[{plainText, emptyCellQ},
  plainText[cell_] := Module[{rules},
    rules = RowBox | BoxData -> List;
    StringJoin @@ Flatten[List @ First[NotebookRead@cell] /. rules]
  ];

  emptyCellQ[cell_] := Module[{text, patt},
    text = plainText[cell];
    patt = Except[{" ", "\n", "\[IndentingNewLine]"}];
    StringCount[text, patt] == 0];

  Cells[GeneratedCell -> False] // Select[emptyCellQ]
];

(*******************************************************************************)
ClearAll[deleteEmptyInputCells];
deleteEmptyInputCells[] := NotebookDelete /@ getEmptyInputCells[];

(*******************************************************************************)
ClearAll[hideCells];
hideCells[] := Module[{nb, cellTags, inputCells, outputCells, hide, show},
  nb = REPLNotebook[];
  cellTags = {"LOADER"};
  inputCells[tags_List] := Cells[nb, CellStyle -> {"Input"}, CellTags -> tags];

  hide[cs_List] := SetOptions[#, CellOpen -> False, Editable -> False] & /@ cs;
  hide@inputCells@cellTags;

  show[cs_List] := SetOptions[#, CellOpen -> True] & /@ cs;

  outputCells = Cells[nb, CellStyle -> {"Output", "Standard"}];
  show@outputCells;
];

(*******************************************************************************)
ClearAll[cleanNotebook];
cleanNotebook[nb_: SelectedNotebook[], styles_: {"Output"}] :=
    (NotebookFind[nb, #, All, CellStyle];NotebookDelete[nb];) & /@ styles;

ClearAll[cleanSelectedNotebook];
cleanSelectedNotebook[] := cleanNotebook[SelectedNotebook[]];

(*REPLNotebookStartedQ[] := Module[{nbs},*)
(*nbs = Notebooks[] // Select[ToString@# == "NotebookObject[<<MMAREPL>>]" &];*)
(*Length[nbs] > 0*)
(*];*)

(*******************************************************************************)
(*                                                                             *)
(**  Find Selected Function                                                    *)
(*                                                                             *)
(*******************************************************************************)
helpLookup[keyword_] := Module[{notebooks},
  notebooks = Notebooks[] // Select[referenceNotebookQ];
  $helpLookup[keyword, notebooks];];

(*******************************************************************************)
referenceNotebookQ[notebook_] := StyleDefinitions /. Options[notebook] // (List @@ #) & // referenceStyleDefinitionQ;

(*******************************************************************************)
$helpLookup[keyword_, {}] := Documentation`HelpLookup[keyword];
$helpLookup[keyword_, notebooks_] := Documentation`HelpLookup[keyword,  notebooks // First];

referenceStyleDefinitionQ[{{"Wolfram"}, "Reference.nb", CharacterEncoding -> "UTF-8"}] := True;
referenceStyleDefinitionQ["Default.nb"] := False;
referenceStyleDefinitionQ[_] := False;

(*******************************************************************************)
helpRequestQ[data_] := Module[{getPath, helpPathQ},
  getPath[requestData_] := ImportString[requestData, "Table"] // First // #[[2]] &;
  helpPathQ[path_] := StringStartsQ[path, "/?"];
  data // getPath // helpPathQ
];

getHelpKeyword[data_] := Module[{getPath, helpPathQ},
  getPath[requestData_] := ImportString[requestData, "Table"] // First // #[[2]] &;
  helpPathQ[path_] := StringStartsQ[path, "/?"];
  data // getPath // StringDrop[#, 2]&
];

End[];

EndPackage[];

(*******************************************************************************)
(*                                                                             *)
(**  Initialization                                                            *)
(*                                                                             *)
(*******************************************************************************)
MMAREPL`hideCells[];
MMAREPL`REPLD[];

(*
Get["MMAREPL/MMAREPL.m"];
MMAREPL`loadFiles[]
*)