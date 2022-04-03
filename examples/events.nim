import stardust, starutils

import std/dom, std/sugar
proc createDom(): Element =
  var count = 0
  var name = cstring""
  let call = (ev: Event) => (count += 1)
  buildHtml:
    text "Enter word and press enter:"
    input(onValue=name)
    br()
    text name.toString()
    br()
    button(onClick=call):
      text "Click me!"
    text fmt" {count}"
setRenderer createDom

# <script>
#     let name = '';
#     let event = '';
#     const click = (e) => {
#       event = e.x + 'x' + e.y;
#     }
#   </script>
  
#   Enter word and press enter:
#   <input bind:value={name} on:keydown|enter={name=''} /> {name}
#   <br />
#   <button on:click={click($event)}>Click!</button>
#   <a href on:click|preventDefault={event=$element.textContent}>Click</a>
#   {event}
  
#   <ul>
#     <li>
#       <b>on:event</b> to listen event, available locals: <i>$element, $event</i>
#     </li>  
#     <li>
#       modifier "preventDefault" to use <i>event.preventDefault()</i>
#     </li>
#     <li>
#       modifier "enter": on:keydown|enter - listen work if keyCode == 13 (Enter), modifer "escape" when keyCode == 27
#     </li>
#   </ul>