#!/Applications/Mathematica.app/Contents/MacOS/wolframscript -script

ClearAll[installPackage];
installPackage[src_String] := Module[{dst},
  dst = FileNameJoin[{$UserBaseDirectory, "/Applications/MMAREPL"}];
  Which[FileExistsQ@dst, DeleteDirectory[dst, DeleteContents -> True]];
  CopyDirectory[src, dst];
  FileExistsQ[dst]];

installPackage[] := Module[{src, dst},
  src = FileNameJoin[{DirectoryName@$InputFileName, "MMAREPL"}];
  installPackage[src]];

(*installPackage[];*)
installPackage[];
