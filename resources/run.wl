#!/Applications/Mathematica.app/Contents/MacOS/wolframscript -script

$host = "127.0.0.1";
$port = 8003;
$serverURL = "http://" <> $host <> ":" <> ToString@$port;

runFromScript[] := Module[{cmd, path},
  path = FileNameJoin[{DirectoryName@$InputFileName, "activatemma.scpt"}];
  cmd = {"/usr/bin/osascript", path};
  RunProcess[cmd]
];

runFromWeb[] := Module[{cmd},
  cmd = {"/usr/bin/curl", serverURL};
  RunProcess[cmd]
];

REPLDStartedQ[] := Module[{port, socket, result},
  socket = SocketConnect[$host <> ":" <> ToString@$port];

  result = Switch[Head[socket],
    SocketObject, True,
    Symbol, False,
    _, False
  ];
  If[result, Close[socket], False];
  result
];

ClearAll[MathematicaStartedQ];
MathematicaStartedQ[] := Module[{output, mathematicaPath, anyMathematicaQ, mathematicaStartedQ},
  mathematicaPath = "/Applications/Mathematica.app/Contents/MacOS/Mathematica";
  output = RunProcess[{"/bin/ps","x"}]["StandardOutput"];
  anyMathematicaQ[xs_]:= AnyTrue[xs, Last@# == mathematicaPath&];
  mathematicaStartedQ[xs_] := ImportString[xs, "Table"] // Rest // anyMathematicaQ;
  mathematicaStartedQ[output]
];

(*******************************************************************************)
(*                                                                             *)
(**  Shortcut                                                                  *)
(*                                                                             *)
(*******************************************************************************)
ClearAll[addRunShortcutOfMathematica];
addRunShortcutOfMathematica[] :=
    Module[{removeComma, toListString, readNSUserKeyEquivalents, associationFromPlist,
      userKeyEquivalents, writeNSUserKeyEquivalents, addShortcut, addUniversalAccess, addRunShortcut},

    (*Add NSUserKeyEquivalents*)
      readNSUserKeyEquivalents[] := Module[{readDefaults, xs},
        readDefaults = {"/usr/bin/defaults", "read", "com.wolfram.Mathematica", "NSUserKeyEquivalents"};
        xs = RunProcess[readDefaults]["StandardOutput"];
        If[StringLength@xs > 0 || Length@xs > 0, associationFromPlist[xs], Association[{}]]];

      removeComma[s_String] := StringReplace[s, ",}" -> "}"];
      toListString[s_String, pattern_] := removeComma@StringReplace[s, pattern];

      associationFromPlist[xs_] := Module[{patt},
        patt = {"\\n" -> "", ";" -> ",", "=" -> "->", "(" -> "{", ");" -> "}", "};" -> "},", "\n" -> ""};
        toListString[xs, patt] // ToExpression // Association
      ];

      userKeyEquivalents[assc_Association] := Module[{template, listFormatString},
        template[key_, value_] := StringTemplate["\"``\" = \"``\";\n"][key, value];
        listFormatString[xs_List] := TextString[xs, ListFormat -> {"{", "", "}"}];
        KeyValueMap[template, assc] // listFormatString];

      writeNSUserKeyEquivalents[value_] := Module[{ writeDefaults},
        writeDefaults = {"/usr/bin/defaults", "write", "com.wolfram.Mathematica", "NSUserKeyEquivalents"};
        RunProcess@Append[writeDefaults, value]];

      addRunShortcut[] := writeNSUserKeyEquivalents@userKeyEquivalents@addShortcut@readNSUserKeyEquivalents[];

      (*Add UniversalAccess*)
      addUniversalAccess[] := Module[{cmd},
        cmd = {"/usr/bin/defaults", "write", "com.apple.universalaccess", "com.apple.custommenu.apps", "(\n\"com.wolfram.Mathematica\"\n);"};
        RunProcess[cmd];]; (*["StandardOutput"]*)

      addShortcut[a_Association] := Append[a, {"Evaluate Notebook" -> "@r"}];

      (*Main*)
      addRunShortcut[];
      addUniversalAccess[];
    ];

run[] := Module[{filePath, notebookFileQ},
  notebookFileQ[path_] := FileExistsQ@path && FileExtension@path == "nb";
  filePath = If[Length@$ScriptCommandLine > 1 && notebookFileQ@$ScriptCommandLine[[2]], $ScriptCommandLine[[2]], "/Applications/Mathematica.app/"];
  Print@$ScriptCommandLine;
  (RunProcess[{"/usr/bin/open", filePath}]; Pause[5];);
  If[REPLDStartedQ[], runFromWeb[], runFromScript[]];
];

addRunShortcutOfMathematica[];
run[];
