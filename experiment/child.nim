import starlight, starutils
import aqua/web/doms
import aqua/std/jsconsole
import aqua/std/proxy
import std/sugar

proc buildText*(name: cstring) {.component.} =
  build(`div`):
    h1: text name
    children()