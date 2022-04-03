import std/[macros, dom, sugar]





# Enter word and press enter:
# <input bind:value={name} on:keydown|enter={name=''} /> {name}
# <br />
# <button on:click={click($event)}>Click!</button>
# <!-- <a href on:click|preventDefault={event=$element.textContent}>Click</a> -->
# {event}
import std/jsconsole

when true:
  import stardust


when false:
  proc createDom(): Element =
    var count = 0
    var name = cstring""
    let call = (ev: Event) => (count += 1)
    buildHtml:
      text "Enter word and press enter:"
      input(onValue=name)
      br()
      text "{name}"
      br()
      button(onClick=call):
        text "Click me"
      text " {count}"
  setRenderer createDom

when false:
  proc createDom(): Element =
    var name = cstring"world"
    buildHtml:
      h1:
        text fmt"Hello {name.toUpperCase()}!"

  setRenderer createDom

when false:
  var counter1 = 0
  var counter2 = 0.5
  # proc click() =
  #   inc counter2
  proc createDom(): Element =
    buildHtml:
      h1:
        text "Conquer World!"
      `div`:
        text "{counter1} => {counter2} => {counter1}"
        button:
          text fmt"{counter1}"
      h2:
        `div`:
          text "hello"
        text fmt"{counter1} => {counter2} => {counter1}"
        # button(onclick = click)
        # text b"{counter}"


  proc main() =
    setRenderer createDom

  main()

when false:
  proc getCstring(): cstring =
    result = "we are cool".cstring

  proc createDom(): Element =
    result = buildHtml:
      h1:
        text getCstring()
  proc main() =
    setRenderer createDom
  main()

when false:
  var counter1 = 0
  var counter2 = 0.5
  # proc click() =
  #   inc counter2

  proc createDom(): Element =
    buildHtml:
      h1:
        text "Conquer World"
      `div`:
        text fmt"{counter1}"
        button:
          text "{counter2}"
      h2:
        text "{counter1}"
        `div`:
          text "hello"
        # button(onclick = click)
        # text b"{counter}"

  proc main() =
    setRenderer createDom

  main()