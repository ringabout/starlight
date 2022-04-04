import macros

template test(body: typed) =
  body

template hello(x: int, y: typed = nil) =
  static: echo astToStr(y)
  echo 123
  when astToStr(y) == "nil":
    discard
  else:
    y


test:
  hello(x = 12):
    hello(x = 178)