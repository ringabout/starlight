import experiment/starlight, starutils
import aqua/web/doms
import aqua/std/proxy


proc buildChild() {.component.} =
  let r = cstring"123"
  build(`div`):
    p: text r

proc buildDom(name2: Reactive[cstring]) {.component.} =
  let store = 12
  build(`div`):
    buildChild()
    h1: text fmt"Hello {name2.toUpperCase()}"
    `div`:
      h2: text fmt"Now {name2.toUpperCase()}"
    h3: text fmt"Goodbye {name2.toUpperCase()}"
proc createDom(): Element =
  var name = reactive cstring"world"
  var cheer = reactive cstring"cheer"
  buildHtml(`div`):
    h1: text fmt"Hello {name.toUpperCase()}"
    buildDom(name)
    buildDom(cheer)
    buildDom reactive cstring"All right"

setRenderer createDom