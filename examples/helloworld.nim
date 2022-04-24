import stardust, starutils
import aqua/web/doms
import std/sugar


template h1(children: typed) =
  discard
proc text(x: cstring) = discard

proc createDom(): Element =
  var name = cstring"world"
  buildHtml:
    h1: text fmt"Hello {name.toUpperCase()}" 

setRenderer createDom
