import std/macros
import std/dom


proc getName(n: NimNode): string =
  case n.kind
  of nnkIdent, nnkSym:
    result = $n
  of nnkAccQuoted:
    result = ""
    for i in 0..<n.len:
      result.add getName(n[i])
  of nnkStrLit..nnkTripleStrLit:
    result = n.strVal
  of nnkInfix:
    # allow 'foo-bar' syntax:
    if n.len == 3 and $n[0] == "-":
      result = getName(n[1]) & "-" & getName(n[2])
    else:
      expectKind(n, nnkIdent)
  of nnkDotExpr:
    result = getName(n[0]) & "." & getName(n[1])
  of nnkOpenSymChoice, nnkClosedSymChoice:
    result = getName(n[0])
  else:
    #echo repr n
    expectKind(n, nnkIdent)

import std/[sets, strformat]

var buildTable {.compileTime.} = toHashSet([
    "a", "abbr", "acronym", "address", "applet", "area", "article",
    "aside", "audio",
    "b", "base", "basefont", "bdi", "bdo", "big", "blockquote", "body",
    "br", "button", "canvas", "caption", "center", "cite", "code",
    "col", "colgroup", "command",
    "datalist", "dd", "del", "details", "dfn", "dialog", "div",
    "dir", "dl", "dt", "em", "embed", "fieldset",
    "figcaption", "figure", "font", "footer",
    "form", "frame", "frameset", "h1", "h2", "h3",
    "h4", "h5", "h6", "head", "header", "hgroup", "html", "hr",
    "i", "iframe", "img", "input", "ins", "isindex",
    "kbd", "keygen", "label", "legend", "li", "link", "map", "mark",
    "menu", "meta", "meter", "nav", "nobr", "noframes", "noscript",
    "object", "ol",
    "optgroup", "option", "output", "p", "param", "pre", "progress", "q",
    "rp", "rt", "ruby", "s", "samp", "script", "section", "select", "small",
    "source", "span", "strike", "strong", "style",
    "sub", "summary", "sup", "table",
    "tbody", "td", "textarea", "tfoot", "th", "thead", "time",
    "title", "tr", "track", "tt", "u", "ul", "var", "video", "wbr"])

import std/sugar

proc toString*[T](x: T): cstring {.importjs: "#.toString()".}

proc concat*(x1, x2: cstring): cstring {.importjs: "(# + #)".}

proc parseBindingString(res: var string, count: var int, parentElement: NimNode,
                        monitor: NimNode,
                        s: string, openChar = '{', closeChar = '}'): NimNode =
  if s.len == 0:
    result = newStrLitNode("")
  elif s.len > 0:
    var stringNode: seq[NimNode]
    var i = 0
    var part = ""
    var isBinding = false
    block outer:
      while i < s.len:
        if s[i] == openChar:
          if part.len > 0:
            stringNode.add newStrLitNode(part)
            part.setLen(0)
          inc i
          while i < s.len:
            if s[i] == closeChar:
              isBinding = true
              stringNode.add newCall(ident"toString", ident(part))
              part.setLen(0)
              inc i
              break
            else:
              part.add s[i]
              inc i
        else:
          part.add s[i]
          inc i

    if isBinding:
      result = stringNode[^1]
      for i in countdown(stringNode.len-2, 0):
        result = newCall(ident"concat", stringNode[i], result)

      res.add " "
      var currentNode =
        if count == 0:
          quote do:
            cast[Element](`parentElement`.firstChild)
        else:
          quote do:
            `parentElement`[`count`]
      result = quote do:
        bindText(`monitor`, `currentNode`, () => cstring(`part`))
    else:
      res.add s
      result = newEmptyNode()
    inc count

type
  Watcher = ref object
    fn: proc (): cstring
    callback: proc (value: cstring) {.closure.}
  Monitor = ref object
    watchers: seq[Watcher]

proc newWatcher(fn: proc (): cstring, callback: proc (value: cstring) {.closure.}): Watcher =
  result = Watcher(fn: fn, callback: callback)

proc newMonitor(): Monitor =
  result = new Monitor

proc bindText*(monitor: Monitor, element: Element, fn: proc (): cstring) =
  let watcher = newWatcher(fn, (value: cstring) => (element.textContent = value))
  monitor.watchers.add watcher


proc buildComponent(monitor: NimNode, parentElement: NimNode, res: var string,
                    count: var int, node: NimNode): NimNode =
  case node.kind
  of nnkStmtList, nnkStmtListExpr:
    result = newNimNode(node.kind, node)
    for x in node:
      let tmp = buildComponent(monitor, parentElement, res, count, x)
      if tmp.kind != nnkEmpty:
        result.add tmp
  of nnkCallKinds - {nnkInfix}:
    let name = getName(node[0])
    if name in buildTable:
      # check the length of node
      var parentNode = quote do:
        `parentElement`[`count`]
      inc count
      echo (count, name)
      var part = ""
      var partCount = 0
      result = newStmtList()

      # result.add quote do:
      #   let test = `parentNode`
      result.add buildComponent(monitor, parentNode, part, partCount, node[1])
      res.add fmt"<{name}>{part}</{name}>"
    elif name == "text":
      case node[1].kind:
      of nnkStrLit:
        result = parseBindingString(res, count, parentElement, monitor, node[1].strVal)
      of nnkCallStrLit:
        # let name = getName(node[1][0])
        # if name == "raw":
        #   let part = parseFormatString(node[1][1].strVal)
        #   res.add " "
        #   var currentNode =
        #     if count == 0:
        #       quote do:
        #         `parentElement`.firstChild.textContent
        #     else:
        #       quote do:
        #         `parentElement`[`count`].textContent
        #   inc count
        #   result = quote do:
        #     `currentNode` = `part`
        # else:
        res.add " "
        var currentNode =
          if count == 0:
            quote do:
              `parentElement`.firstChild.textContent #! Node
          else:
            quote do:
              `parentElement`[`count`].textContent
        inc count
        result = newAssignment(currentNode, node[1])
      of {nnkCommand, nnkCall}: # todo
          res.add " "
          var currentNode =
            if count == 0:
              quote do:
                `parentElement`.firstChild.textContent #! Node
            else:
              quote do:
                `parentElement`[`count`].textContent
          inc count
          result = newAssignment(currentNode, node[1])
          # let tmp = node[1] # ! bug cannot inline node[1]
          # result = quote do:
          #   `currentNode` = `tmp`
      else: doAssert false
    else:
      doAssert false
      # result = newEmptyNode()
  else:
    doAssert false
    # if node.len > 0:
    #   for i in node:
    #     result = buildComponent(i, res, content)
    # else:
    #   result = node


macro buildHtml*(children: untyped): Element =
  echo children.treeRepr
  echo "-----------------build----------------------"
  let parentElement = genSym(nskLet, "parentElement")
  var res = ""
  var count = 0
  var monitor = genSym(nskVar, "monitor")

  let component = buildComponent(monitor, parentElement, res, count, children)
  echo repr(component)
  echo res
  result = quote do:
    var `monitor` = newMonitor()
    var fragment = document.createElement("template")
    fragment.innerHtml = `res`.cstring
    let `parentElement` = fragment.content
    `component`
    cast[Element](`parentElement`)


proc setRender*(render: proc(): Element, id = cstring"ROOT") =
  let root = document.getElementById(id)
  root.appendChild render()
