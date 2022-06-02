import starlight, starutils
import aqua/web/doms
import aqua/std/jsconsole
import aqua/std/proxy
import std/sugar


template `+=`*(x: var Reactive[int], y: int) =
  x.value = x.value + y

proc createDom(): Element =
  var count = reactive 0
  buildHtml:
    button(onClick = (e: Event) => (count += 1)): text count

setRenderer createDom

when false:
  var name = reactive cstring"Hello world"
  proc createDom(): Element =
    buildHtml:
      h1: text name

  setRenderer createDom
  discard setTimeout(() => (name.value = concat(name.value, cstring"1"); console.log name.value), 10)

