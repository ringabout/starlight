import stardust, starutils
import aqua/web/doms
import std/sugar

proc createDom(): Element =
  var name = cstring"world"
  buildHtml:
    h1: text fmt"Hello {name.toUpperCase()}" 

setRenderer createDom
