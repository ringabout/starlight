import std/macros
import aqua/web/doms
import aqua/std/proxy
import std/strutils
import aqua/std/jsconsole

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
    echo n.treeRepr
    echo n.repr
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

var illegalTag {.compileTime.} = toHashSet(["body", "head", "html", "title", "script"])

import std/sugar


proc toString*[T](x: T): cstring {.importjs: "#.toString()".}

proc concat*(x1, x2: cstring): cstring {.importjs: "(# + #)".}


proc construct(parentElement: NimNode, res: var string,
                    count: var int,
                    textCount: var int,
                    node: NimNode,
                    isCall: static bool = false,
                    passedCount = newEmptyNode(),
                    passedParent = newEmptyNode(),
                    passedChildren = newEmptyNode()): NimNode


import std/tables
var buildTableNode {.compileTime.}: Table[string, NimNode]
var constructedTableNode {.compileTime.}: Table[string, NimNode]
var countNodeTable {.compileTime.}: Table[string, (NimNode, NimNode)]
var countTableNode {.compileTime.}: Table[string, int]

type
  ComponentContext* = object
    parent: NimNode
    res: string
    count, textCount: int

template toUpperCase*(x: Reactive[cstring]): cstring =
  x.value.toUpperCase

proc replaceChild*(n: Node, newNode, oldNode: Element) {.importcpp.}

macro component*(x: untyped) =
  if x[0].kind == nnkPostfix: # check exported component
    x[0] = x[0][1]

  buildTableNode[x[0].getName] = x
  countTableNode[x[0].getName] = 0


proc setAttr[T: cstring|bool](x: Element; name: cstring, value: T) {.importjs: "#[#] = #".}
proc getAttr(x: Element; name: cstring): cstring {.importjs: "#[#]".}

proc getChecked(x: Element; name: cstring): bool {.importjs: "#[#]".}

proc parseInt(x: cstring): int {.importjs: "parseInt(#)".}

proc `[]=`*(n: Node, count: int, child: Element) {.importjs: "#[#] = #".}

template textImpl(x: Reactive[cstring]): cstring =
  x.value

template textImpl(x: Reactive[bool]): cstring =
  toString(x.value)

template textImpl(x: Reactive[int]): cstring =
  toString(x.value)

template parseImpl[T](x: Reactive[T], y: cstring) =
  when T is int:
    if y.len == 0:
      x.value = 0
    else:
      x.value = parseInt(y)
  elif T is bool:
    if y == cstring"true":
      x.value = true
    elif y == cstring"false":
      x.value = false
    else:
      x.value = false # todo raise?
  elif T is cstring:
    x.value = y
  else:
    assert false, "Not implemented"

template textImpl[T](x: T): cstring =
  when T is cstring:
    x
  else:
    toString(x)

proc construct(parentElement: NimNode, res: var string,
                    count: var int,
                    textCount: var int,
                    node: NimNode,
                    isCall: static bool = false,
                    passedCount = newEmptyNode(),
                    passedParent = newEmptyNode(),
                    passedChildren = newEmptyNode()): NimNode =
  case node.kind
  of nnkStmtList, nnkStmtListExpr:

    textCount = 0 # todo

    result = newNimNode(node.kind, node)
    for x in node:
      let tmp = construct(parentElement, res, count, textCount, x, passedChildren = passedChildren)
      if tmp.kind != nnkEmpty:
        result.add tmp

    textCount = 0 # todo
  of nnkCallKinds - {nnkInfix}:
    let name = getName(node[0])
    if name in buildTable:
      if name in illegalTag:
        error(fmt"{name} is not allowed", node)
      textCount = 0 # todo
      # check the length of node
      var parentNode =
        when isCall:
          var access = newNimNode(nnkBracketExpr)
          access.add passedParent
          access.add passedCount
          access
        else:
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
              let variable = x[1]
              if name == "onChecked":

                result.add quote do:
                  let node = `parentNode` # todo why need a new copy? consider make renderDom a closure?
                  addEventListener(`parentNode`, "input", (ev: Event) => (`variable`.value =
                                   getChecked(node, cstring"checked")))
              elif name == "onClick":
                result.add quote do:
                  addEventListener(`parentNode`, "click", (ev: Event) => (`variable`(ev)))
              else:
                let newName = name[2..^1].toLowerAscii
                result.add quote do:
                  let node = `parentNode` # todo why need a new copy? consider make renderDom a closure?
                  addEventListener(`parentNode`, "input", (ev: Event) => (parseImpl(`variable`,
                                   getAttr(node, `newName`.cstring))))
            else:
              # todo x1.kind
              res.add fmt" {name}={x[1].strVal}"
              # result.add newCall(bindSym"setAttr", parentNode, newStrLitNode(name), x[1])
          else:
            if isSingleTag:
              error(fmt"A empty element({name}) is not allowed to have children", x)
            result.add construct(parentNode, part, partCount, textCount, x, passedChildren = passedChildren)
            res.add fmt"<{name}>{part}</{name}>"
        if isSingleTag:
          res.add ">"
      textCount = 0 # todo
    elif name == "text":
      if textCount == 1:
         error("The text node is not allowed to use sequentially", node)
      inc textCount # todo
      case node[1].kind:
      of nnkStrLit:
        res.add node[1].strVal
        result = newEmptyNode()
      else:
        res.add " "
        var currentNode =
          if count == 0:
            quote do:
              cast[Element](`parentElement`.firstChild) #! Node
          else:
            quote do:
              `parentElement`[count]

        # ! bug cannot inline node[1]
        let tmp = node[1]
        # textImpl
        let textCall = newCall(bindSym"textImpl", tmp)
        let procName = genSym(nskProc)
        result = quote do:
          proc `procName`(x: Element): Effect =
            result = proc () =
              x.textContent = `textCall`
          watchImpl `procName`(`currentNode`)
      inc count
    elif name == "children":
      var partCount = 0
      textCount = 0
      if passedChildren.kind != nnkEmpty:
        result = construct(parentElement, res, partCount, textCount, passedChildren)
    else:
      const bodyPos = 6
      var passedChildren = newEmptyNode()
      if node[^1].kind == nnkStmtList:
        passedChildren = node[^1]
        node.del(node.len-1)

      let nodeName = node[0].getName
      if nodeName notin countTableNode:
        error(fmt"{nodeName} is undefined", node) # todo better message
      elif countTableNode[nodeName] == 0:
        const paramsPos = 3
        let def = buildTableNode[nodeName]
        let passedCount = genSym(nskParam, "count")
        let passedParent = genSym(nskParam, "parent")
        let params = def[paramsPos]
        let staticCount = newNimNode(nnkStaticTy)
        staticCount.add ident"int"
        params.insert(1, newIdentDefs(passedCount, ident"int"))
        params.insert(1, newIdentDefs(passedParent, ident"Element"))

        let body = def[bodyPos][^1]
        # echo def.treeRepr
        # echo "---> ", body.treeRepr
        body.del(0)
        constructedTableNode[nodeName] = buildTableNode[nodeName].copy

        # echo "---> ", body.repr
        buildTableNode[nodeName][bodyPos][^1] = construct(parentElement, res,
                      count, textCount, body, isCall = true, passedCount, passedParent, passedChildren)
        countNodeTable[nodeName] = (passedCount, passedParent)
        countTableNode[nodeName] = 1

        echo "----------------------------------"
        echo def.repr
        echo "----------------------------------"

      else:
        let def = constructedTableNode[nodeName]
        let body = def[bodyPos][^1]
        let (passedCount, passedParent) = countNodeTable[nodeName]
        discard construct(parentElement, res,
                      count, textCount, body, isCall = true, passedCount, passedParent, passedChildren)
      let nodeCopy = node.copy # todo why copy is needed?
      nodeCopy.insert(1, newLit(count-1))
      nodeCopy.insert(1, quote do:
        cast[Element](`parentElement`)
        )
      # node.insert(2, monitor)
      # node.insert(3, parentElement)
      echo "----------------------------------"
      echo nodeCopy.repr
      echo "----------------------------------"

      result = quote do:
        `nodeCopy`
  of nnkLetSection:
    result = node
  else:
    echo node.treeRepr
    doAssert false, fmt"3: {node.kind}"
    # if node.len > 0:
    #   for i in node:
    #     result = construct(i, res, content)
    # else:
    #   result = node

template build*(name, children: untyped): untyped =
  discard

macro buildHtml*(name, children: untyped): Element =
  let parentElement = genSym(nskLet, "parentElement")
  var res = ""
  var count = 0
  var textCount = 0
  let component = construct(parentElement, res, count, textCount, children)
  var defs = newStmtList()
  res = fmt"{res}"
  for i in buildTableNode.values:
    defs.add i
  result = quote do:
    var fragment = document.createElement("template")
    fragment.innerHTML = `res`.cstring
    let `parentElement` = fragment.content
    `defs`
    `component`
    cast[Element](`parentElement`)
  echo "***********************************"
  echo result.repr
  echo "***********************************"


proc setRenderer*(render: proc(): Element, id = cstring"ROOT") =
  let root = document.getElementById(id)
  root.appendChild render()

