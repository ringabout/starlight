import stardust, starutils
import aqua/web/doms
import std/sugar

proc createDom(): Element =
  var count = 0
  buildHtml:
    `input`(`type`="number", onValue=count)
    button(onClick = (e: Event) => (count += 1)): text count

when false:
  setRenderer createDom