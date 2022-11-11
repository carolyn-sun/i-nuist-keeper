#!/bin/bash
cat "Detected V: "
which v
cat "Version: "
v version
v -o i-nuist-keeper.exe -os windows .
cat "Compilation done"
read -rsp $'Press any key to continue...\n' -n 1 key
