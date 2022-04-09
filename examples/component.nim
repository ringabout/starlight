import stardust, starutils
import aqua/web/doms

proc buildDom(name2: cstring) {.component.} =
  build(`div`):
    h1: text fmt"Hello {name2.toUpperCase()}"
    `div`:
      h2: text fmt"Now {name2.toUpperCase()}"
    h3: text fmt"Goodbye {name2.toUpperCase()}"
proc createDom(): Element =
  var name = cstring"world"
  var cheer = cstring"cheer"
  buildHtml:
    h1: text fmt"Hello {name.toUpperCase()}"
    buildDom(name)
    buildDom(cheer)
    buildDom "All right"

setRenderer createDom