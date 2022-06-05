import experiment/starlight, starutils
import aqua/web/doms
import std/sugar
import aqua/std/proxy

proc createDom(): Element =
  var count = reactive 0
  buildHtml(`div`):
    `input`(`type`="number", onValue=count)
    button(onClick = (e: Event) => (count += 1)): text count


setRenderer createDom