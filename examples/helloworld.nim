import experiment/starlight, starutils
import aqua/web/doms
import std/sugar



proc createDom(): Element =
  var name = cstring"world"
  buildHtml(`div`):
    h1: text fmt"Hello {name.toUpperCase()}" 

setRenderer createDom
