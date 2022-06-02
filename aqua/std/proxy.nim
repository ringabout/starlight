import std/jsconsole
import jsffi2
import seqs, weakmaps, sets2, maps

type
  Proxy[T] {.importc.} = ref object

  Reactive*[T] {.importc.} = ref object
    raw: T
    when T is ref:
      value: Proxy[T]
    else:
      deps: Set[Effect]

  Handler = ref object
    construct: proc()

  Effect* = proc ()

  Primitive* = SomeNumber|cstring



var effectStack = newJSeq[Effect]()
var rawToProxy = newMap[JsObject, JsObject]()
var effectsTable = newMap[JsObject, Map[cstring, Set[Effect]]]()

type
  Descriptor = ref object
    `set`: proc (target: JsObject, key: cstring, value: JsObject, receiver: JsObject)
    `get`: proc (target: JsObject, key: cstring, receiver: JsObject): JsObject


proc defineProperty[T](obj: T, prop: cstring, descriptor: Descriptor) {.importjs: "Object.defineProperty(#, #, #)".}

proc getJsType(x: JsObject): cstring {.importjs: "typeof(#)".}

proc newProxy[T](x: T, value: Descriptor): Proxy[T] {.importjs: """new Proxy(#, #)""".}

proc trigger(target: JsObject, key: cstring) =
  let size = effectStack.len

  let depsMap = effectsTable.get(target)
  let effects = depsMap.get(key)
  for effect in effects:
    if size == 0 or effect != effectStack[size-1]:
      effect()

proc track(target: JsObject, key: cstring) =
  let size = effectStack.len
  if size > 0:
    let activeEffect = effectStack[size-1]
    if target notin effectsTable:
      effectsTable.put(target, newMap[cstring, Set[Effect]]())

    let depsMap = effectsTable.get(target)

    if key notin depsMap:
      depsMap.put(key, newJSet[Effect]())

    let effectSet = depsMap.get(key)
    if activeEffect notin effectSet:
      effectSet.add activeEffect

template toAny(x: typed): JsObject =
  cast[JsObject](x)

template `raw`*[T](x: Reactive[T]): T =
  x.raw

template `raw=`*[T](x: Reactive[T], y: T): T =
  x.raw = y

proc `value`*[T: Primitive](x: Reactive[T]): T =
  let size = effectStack.len
  if size > 0:
    let activeEffect = effectStack[size-1]
    if activeEffect notin x.deps:
      x.deps.add activeEffect
  result = x.raw

proc `value=`*[T: Primitive](x: Reactive[T], y: T) =
  x.raw = y
  # bug items must exist
  for effect in items(x.deps):
    effect()

proc reactiveSetter(target: JsObject, key: cstring, value: JsObject, receiver: JsObject) =
  # check old value
  target[key] = value
  trigger(target, key)

proc newReactive2(x: JsObject): Reactive[JsObject]

proc reactiveGetter(target: JsObject, key: cstring, receiver: JsObject): JsObject =
  track(target, key)
  let res = target[key]
  if res != nil and getJsType(res) == "object":
    let data = newReactive2(res)
    result = cast[JsObject](data.value)
  else:
    result = res # todo Reflect.get


let descriptor = Descriptor(`set`: reactiveSetter, `get`: reactiveGetter)

proc newReactive2(x: JsObject): Reactive[JsObject] =
  if x in rawToProxy:
    result = cast[Reactive[JsObject]](rawToProxy.get(x))
  else:
    let proxy = newProxy[JsObject](x, descriptor)
    result = Reactive[JsObject](raw: x, value: proxy)
    rawToProxy.put(x, toAny(result))

# todo typedesc overload
proc reactive*[T: ref](x: T): Reactive[T] =
  if toAny(x) in rawToProxy:
    result = cast[Reactive[T]](rawToProxy.get(toAny(x)))
  else:
    let proxy = newProxy[T](x, descriptor)
    result = Reactive[T](raw: x, value: proxy)
    rawToProxy.put(toAny(x), toAny(result))
    # proxyToRaw[toAny(result)] = toAny(x)

proc reactive*[T: Primitive](x: T): Reactive[T] =
  result = Reactive[T](raw: x, deps: newJSet[Effect]())

# proc reactive*[T: ref](x: typedesc[T]): Reactive[T] =
#   let descriptor = Descriptor(`set`: setter, `get`: getter)
#   let proxy = newProxy[T](new T, descriptor)
#   result = Reactive[T](value: proxy)

# proc reactive*[T: not ref](x: T): Reactive[T] =
#   let descriptor = Descriptor(`set`: setter, `get`: getter)
#   result = Reactive[T](value: x)

template `.?`*[T: ref](x: Reactive[T], y: untyped{ident}): untyped =
  cast[T](x.value).y

proc reassign[T](dest: var Reactive[T], src: T) =
  when T is ref:
    let raw = dest.raw
    dest = reactive(src)
    let effects = effectsTable.get(toAny(raw))
    effectsTable.put(toAny(src), effects)
  else:
    dest.value = src

template `<-`*[T](dest: var Reactive[T], src: T) =
  reassign(dest, src)

# template `?`*[T](x: Reactive[T]): untyped =
#   x.value

template `:=`*[T](def: untyped, value: T): untyped =
  var def = reactive(value)


# template `raw`*[T](x: Reactive[T]): T =
#   if toAny(x) in proxyToRaw:
#     result = cast[T](proxyToRaw[toAny(x)])
#   else:
#     doAssert false, "Use reactive to initalize"

proc watchImpl*(callback: Effect) =
  effectStack.add callback
  # console.log "here2: ", effectsTable
  try:
    # console.log "here3: ", effectsTable
    callback()
    # console.log "here4: ", effectsTable
  finally:
    discard effectStack.pop()

template watch*(x: typed) =
  watchImpl proc () =
    x

when isMainModule:
  type
    Card = ref object
      id: int
    Counter = ref object
      num: int
      card: Card

  var x = reactive Counter(num: 0)
  watch:
    console.log "run: ", x.?num
    # watch:
    #   console.log "run2: ", x.?num


  watch:
    console.log "run2: ", x.?num


  x.?num += 1
  x.?num = 182

  x <- Counter(num: 1)
  x.?num += 1

  # watch proc () =
  #   console.log "card: ", x.?card.id

  # x.?card.id += 1

  y := Counter(card: Card(id: 16))
  watch:
    console.log "card: ", y.?card.id

  y.?card.id += 1

  y <- Counter(card: Card(id: -1))

  console.log effectsTable

  block:
    var x = reactive(1)
    watch:
      console.log x.value

    x <- 3
