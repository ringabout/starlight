import experiment/starlight, starutils
import aqua/web/doms
import aqua/std/proxy

proc createDom(): Element =
  var name = reactive cstring"world"
  var active = reactive false
  buildHtml(`div`):
    text "Enter name: "
    input(`type`="text", onValue=name)
    text fmt"Hello {name}!"
    br()
    input(`type`="checkbox", onChecked=active)
    text active
setRenderer createDom