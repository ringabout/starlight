import starlight, starutils
import aqua/web/doms
import aqua/std/jsconsole
import aqua/std/proxy
import std/sugar

template `+=`*(x: var Reactive[int], y: int) =
  x.value = x.value + y


when false:
  proc createDom(): Element =
    var count = reactive 0
    buildHtml:
      text "count is: "
      button(onClick = (e: Event) => (count += 1)): text count

  setRenderer createDom

when false:
  var name = reactive cstring"Hello world"
  proc createDom(): Element =
    buildHtml:
      h1: text name

  setRenderer createDom
  discard setTimeout(() => (name.value = concat(name.value, cstring"1"); console.log name.value), 10)

when false:
  # import aqua/std/maps # why it cannot be omitted?
  type
    Example = ref object
      text: cstring
  var name = reactive Example(text: cstring"Hello world")
  proc createDom(): Element =
    buildHtml:
      h1: text name

  setRenderer createDom

when true:
  proc createDom(): Element =
    var count = reactive 0
    buildHtml:
      `input`(`type`="number", onValue=count)
      button(onClick = (e: Event) => (count += 1)): text count

  setRenderer createDom
