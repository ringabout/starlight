import std/jsconsole
import jsffi2

type
  Proxy[T] {.importc.} = ref object

  Reactive[T] = ref object
    when T is ref:
      value: Proxy[T]
    else:
      value: T

  Handler = ref object
    construct: proc()

type
  Descriptor = ref object
    `set`: proc (target: JsObject, key: cstring, value: JsObject)
    `get`: proc (target: JsObject, key: cstring): JsObject


proc defineProperty[T](obj: T, prop: cstring, descriptor: Descriptor) {.importjs: "Object.defineProperty(#, #, #)".}


proc newProxy[T](x: T, value: Descriptor): Proxy[T] {.importjs: """new Proxy(#, #)""".}

# proc newProxy[T](x: T, value: ): Proxy[T] {.importjs: """new Proxy(#,
# {set(target, prop, receiver) {
#     console.log("changed");
#     target[prop] = receiver;
#   }}
#   )""".}

proc setter(target: JsObject, key: cstring, value: JsObject) =
  console.log("setter: ", key, value) # trigger
  target[key] = value


proc getter(target: JsObject, key: cstring): JsObject =
  console.log("getter: ", key) # track
  target[key]

# todo typedesc overload
proc newReactive*[T: ref](x: T): Reactive[T] =
  let descriptor = Descriptor(`set`: setter, `get`: getter)
  let proxy = newProxy[T](x, descriptor)
  result = Reactive[T](value: proxy)

proc newReactive*[T: ref](x: typedesc[T]): Reactive[T] =
  let descriptor = Descriptor(`set`: setter, `get`: getter)
  let proxy = newProxy[T](new T, descriptor)
  result = newReactive[T](proxy)

proc newReactive*[T: not ref](x: T): Reactive[T] =
  let descriptor = Descriptor(`set`: setter, `get`: getter)
  result = Reactive[T](value: x)

template `.?`*[T: ref](x: Reactive[T], y: untyped{ident}): untyped =
  cast[T](x.value).y

template `?`*[T](x: Reactive[T]): untyped =
  x.value

template `:=`*[T](def: untyped, value: T): untyped =
  var def = newReactive(value)

template `value`*[T](x: Reactive[T]): T =
  when T is ref:
    cast[T](x.value)
  else:
    x.value

template `value=`*[T](x: Reactive[T], y: T) =
  when T is ref:
    cast[T](x.value) = y
  else:
    x.value = y

template `raw`*[T](x: Reactive[T]): T =
  when T is ref:
    cast[T](x.value)
  else:
    x.value

template `raw=`*[T](x: Reactive[T], y: T) =
  when T is ref:
    cast[T](x.value) = y
  else:
    x.value = y

template watch(def: untyped, body: untyped) =
  body


