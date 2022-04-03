import stardust, starutils
import std/[dom, sugar]

proc createDom(): Element =
  var name = cstring"world"
  buildHtml:
    h1: text fmt"Hello {name.toUpperCase()}" 

setRenderer createDom
