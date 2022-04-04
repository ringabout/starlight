import std/[strformat, strutils]
import std/os

for name in walkdir("examples"):
  let path = name.path
  if path.endsWith("nim"):
    exec fmt"nim js {path}"
