import stardust, starutils
import std/dom


proc createDom(): Element =
  var name = cstring"world"
  var active = false
  buildHtml:
    text "Enter name: "
    input(`type`="text", onValue=name)
    text fmt"Hello {name}!"
    br()
    input(`type`="checkbox", onChecked=active)
    text active.toString()
setRenderer createDom