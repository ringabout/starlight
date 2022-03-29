import std/macros
import std/dom
import std/strutils

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
import std/jsconsole

proc toString*[T](x: T): cstring {.importjs: "#.toString()".}

proc concat*(x1, x2: cstring): cstring {.importjs: "(# + #)".}

type
  Watcher = ref object
    fn: proc (): cstring
    callback: proc (value: cstring) {.closure.}
    value: cstring
  Monitor = ref object
    watchers: seq[Watcher]

proc jsTypeof(x: cstring): cstring {.importjs: "typeof(#)".}

proc detect(monitor: Monitor) =
  while true:
    var changes = 0
    for w in monitor.watchers:
      let value = w.fn()
      if value != w.value:
        w.callback(value)
        w.value = value
        inc changes
    if changes == 0:
      break


proc apply(monitor: Monitor) =
  discard setTimeout(() => detect(monitor), 10)

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
              stringNode.add newCall(ident"toString", parseExpr(part))
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
        bindText(`monitor`, `currentNode`, () => `result`)
    else:
      res.add s
      result = newEmptyNode()
    inc count

proc bindText*(monitor: Monitor, element: Element, fn: proc (): cstring) =
  let watcher = Watcher(fn: fn, callback: (value: cstring) => (element.textContent = value), value: "")
  monitor.watchers.add watcher

proc setAttr[T: cstring|bool](x: Element; name: cstring, value: T) {.importjs: "#[#] = #".}
proc getAttr(x: Element; name: cstring): cstring {.importjs: "#[#]".}

proc getChecked(x: Element; name: cstring): bool {.importjs: "#[#]".}


proc bindInput*(monitor: Monitor, element: Element, name: cstring, variable: var bool,
                getCallBack: proc (): cstring, setCallBack: proc(x: Watcher, node: Element, y: var bool)) =
  let watcher = Watcher(fn: getCallBack, callback: 
    (value: cstring) => (element.setAttr(name, if value == "true": true else: false)), value: "")
  monitor.watchers.add watcher
  addEventListener(element, "input", (ev: Event) => setCallBack(watcher, element, variable))

proc bindInput*(monitor: Monitor, element: Element, name: cstring, variable: var cstring,
                getCallBack: proc (): cstring, setCallBack: proc(x: Watcher, node: Element, y: var cstring)) =
  let watcher = Watcher(fn: getCallBack, callback: (value: cstring) => (element.setAttr(name, value)), value: "")
  monitor.watchers.add watcher
  addEventListener(element, "input", (ev: Event) => setCallBack(watcher, element, variable))

proc buildComponent(monitor: NimNode, parentElement: NimNode, res: var string,
                    count: var int,
                    textCount: var int,
                    node: NimNode): NimNode =
  case node.kind
  of nnkStmtList, nnkStmtListExpr:

    textCount = 0 # todo

    result = newNimNode(node.kind, node)
    for x in node:
      let tmp = buildComponent(monitor, parentElement, res, count, textCount, x)
      if tmp.kind != nnkEmpty:
        result.add tmp

    textCount = 0 # todo
  of nnkCallKinds - {nnkInfix}:
    let name = getName(node[0])
    if name in buildTable:
      textCount = 0 # todo
      # check the length of node
      var parentNode =
        if count == 0:
          quote do:
            cast[Element](`parentElement`.firstChild)
        else:
          quote do:
            `parentElement`[`count`]
      inc count
      let isSingleTag = name in ["input", "br"]
      if node.len == 1:
        result = newEmptyNode()
        if isSingleTag:
          res.add fmt"<{name}/>"
        else:
          res.add fmt"<{name}></{name}>"
      else:
        var part = ""
        var partCount = 0
        if isSingleTag:
          res.add fmt"<{name}"
        result = newStmtList()
        for i in 1..<node.len:
          let x = node[i]
          if x.kind == nnkExprEqExpr:
            let name = getName(x[0])
            if name.startsWith("on"):
              let variable = parseExpr(x[1].strVal[1..^2])
              if name == "onChecked":
                result.add quote do:
                  bindInput(`monitor`, `parentNode`, cstring"checked",
                            `variable`, () => `variable`.toString(),
                            proc (x: Watcher, node: Element, y: var bool) =
                              y = getChecked(node, "checked");

                              x.value = y.toString()
                              apply(`monitor`)
                            )
              else:
                let newName = name[2..^1].toLowerAscii
                result.add quote do:
                  bindInput(`monitor`, `parentNode`, `newName`.cstring,
                            `variable`, () => `variable`,
                            proc (x: Watcher, node: Element, y: var cstring) =
                              x.value = getAttr(node, `newName`.cstring);
                              y = x.value;
                              apply(`monitor`)
                            )
            else:
              # todo x1.kind
              res.add fmt" {name}={x[1].strVal}"
              # result.add newCall(bindSym"setAttr", parentNode, newStrLitNode(name), x[1])
          else:
            if isSingleTag:
              doAssert false, fmt"A empty element({name}) is not allowed to have children"
            result.add buildComponent(monitor, parentNode, part, partCount, textCount, x)
            res.add fmt"<{name}>{part}</{name}>"
        if isSingleTag:
          res.add ">"
      textCount = 0 # todo
    elif name == "text":
      if textCount == 1:
        doAssert false, "The text node is allowed to use sequentially"
      inc textCount # todo
      case node[1].kind:
      of nnkStrLit:
        result = parseBindingString(res, count, parentElement, monitor, node[1].strVal)
      of nnkCallStrLit:
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
      else: doAssert false, fmt"1: {node[1].kind}"
    else:
      doAssert false, fmt"2: {name}"
      # result = newEmptyNode()
  else:
    doAssert false, fmt"3: {node.kind}"
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
  var textCount = 0
  var monitor = genSym(nskVar, "monitor")
  let component = buildComponent(monitor, parentElement, res, count, textCount, children)
  echo repr(component)
  echo res
  result = quote do:
    var `monitor` = Monitor()
    var fragment = document.createElement("template")
    fragment.innerHtml = `res`.cstring
    let `parentElement` = fragment.content
    `component`
    apply(`monitor`)
    cast[Element](`parentElement`)

proc setRender*(render: proc(): Element, id = cstring"ROOT") =
  let root = document.getElementById(id)
  root.appendChild render()
