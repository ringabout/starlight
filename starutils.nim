import std/macros
import aqua/std/proxy

when false:
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

proc jsTypeof*(x: cstring): cstring {.importjs: "typeof(#)".}
proc toUpperCase*(x: cstring): cstring {.importjs: "#.toUpperCase()".}

template toStringImpl(x: Reactive[cstring]): cstring =
  x.value

template toStringImpl(x: Reactive[int]): cstring =
  toString(x.value)

template toStringImpl[T](x: T): cstring =
  toString(x)

proc parseFormatString(s: string, openChar = '{', closeChar = '}'): NimNode =
  if s.len == 0:
    result = newStrLitNode("")
  elif s.len > 0:
    var stringNode: seq[NimNode]
    var i = 0
    var part = ""
    block outer:
      while i < s.len:
        if s[i] == openChar:
          if part.len > 0:
            stringNode.add newStrLitNode(part)
            part.setLen(0)
          inc i
          while i < s.len:
            if s[i] == closeChar:
              stringNode.add newCall(bindSym"toStringImpl", parseExpr(part))
              part.setLen(0)
              inc i
              break
            else:
              part.add s[i]
              inc i
        else:
          part.add s[i]
          inc i
    if part.len > 0:
      stringNode.add newStrLitNode(part)
    result = stringNode[^1]
    for i in countdown(stringNode.len-2, 0):
      result = newCall(ident"concat", stringNode[i], result)

macro fmt*(x: static string): cstring =
  parseFormatString(x)