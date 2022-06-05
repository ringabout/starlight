import starlight
import aqua/web/doms
import aqua/std/proxy


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

when false:
  proc createDom(): Element =
    var count = reactive 0
    buildHtml:
      `input`(`type`="number", onValue=count)
      button(onClick = (e: Event) => (count += 1)): text count

  setRenderer createDom

when false:
  proc createDom(): Element =
    var count = reactive 0
    var name = reactive cstring""
    let call = (ev: Event) => (count += 1)
    buildHtml:
      text "Enter word and press enter:"
      input(onValue=name)
      br()
      text name
      br()
      button(onClick=call):
        text "Click me!"
      text count
  setRenderer createDom

when false:
  proc createDom(): Element =
    var name = reactive cstring"world"
    var active = reactive false
    buildHtml:
      text "Enter name: "
      input(`type`="text", onValue=name)
      text fmt"Hello {name}!"
      br()
      input(`type`="checkbox", onChecked=active)
      text active
  setRenderer createDom

when true:
  import child
  var name = reactive cstring"Hello world"

  proc createDom(): Element =
    buildHtml(`div`):
      h1: text name
      buildText("ciao"):
        p: text "hey hey hey"
        h3: text "yui"
      buildText("set out")
      h2: text "fine"

  setRenderer createDom
