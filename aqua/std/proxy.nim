import std/jsconsole
import jsffi2
import seqs, weakmaps, sets2

type
  # Proxy[T] {.importc.} = ref object

  Reactive[T] {.importc.} = ref object
    # when T is ref:
    #   value: Proxy[T]
    # else:
    #   value: T

  Handler = ref object
    construct: proc()

  Effect = proc ()

var effectStack = newJSeq[Effect]()
var rawToProxy = newWeakMap[JsObject, JsObject]()
var proxyToRaw = newWeakMap[JsObject, JsObject]()
var effectsTable = newWeakMap[JsObject, Set[JsObject]]()


type
  Descriptor = ref object
    `set`: proc (target: JsObject, key: cstring, value: JsObject)
    `get`: proc (target: JsObject, key: cstring): JsObject


proc defineProperty[T](obj: T, prop: cstring, descriptor: Descriptor) {.importjs: "Object.defineProperty(#, #, #)".}


proc newProxy[T](x: T, value: Descriptor): Reactive[T] {.importjs: """new Proxy(#, #)""".}

proc trigger() = discard

proc track(target: JsObject, key: cstring) =
  discard

template toAny(x: typed): JsObject =
  cast[JsObject](x)


proc setter(target: JsObject, key: cstring, value: JsObject) =
  console.log("setter: ", key, value) # trigger
  trigger()
  target[key] = value

proc getter(target: JsObject, key: cstring): JsObject =
  console.log("getter: ", key) # track
  track(target, key)
  result = target[key] # todo Reflect.get

# todo typedesc overload
proc newReactive*[T: ref](x: T): Reactive[T] =
  if toAny(x) in rawToProxy:
    result = cast[Reactive[T]](rawToProxy[toAny(x)])
  else:
    let descriptor = Descriptor(`set`: setter, `get`: getter)
    result = newProxy[T](x, descriptor)
    rawToProxy[toAny(x)] = toAny(result)

# proc newReactive*[T: ref](x: typedesc[T]): Reactive[T] =
#   let descriptor = Descriptor(`set`: setter, `get`: getter)
#   let proxy = newProxy[T](new T, descriptor)
#   result = Reactive[T](value: proxy)

# proc newReactive*[T: not ref](x: T): Reactive[T] =
#   let descriptor = Descriptor(`set`: setter, `get`: getter)
#   result = Reactive[T](value: x)

template `.?`*[T: ref](x: Reactive[T], y: untyped{ident}): untyped =
  cast[T](x).y

# template `?`*[T](x: Reactive[T]): untyped =
#   x.value

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

proc watch*(callback: Effect) =
  effectStack.add callback
  callback()

when isMainModule:
  type
    Counter = ref object
      num: int

  x := Counter(num: 0)
  watch proc () =
    console.log "run: ", x.?num

  x.?num += 1

