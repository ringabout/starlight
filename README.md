# stardust
Another front-end framework in Nim (working in progress). It directly compiles to the dom.

## Reactivity

```nim
  type
    Card = ref object
      id: int
    Counter = ref object
      num: int
      card: Card

  var x = newReactive Counter(num: 0)
  watch:
    console.log "run: ", x.?num

  console.log "here: ", effectsTable

  watch:
    console.log "run2: ", x.?num


  x.?num += 1
  x.?num = 182

  x <- Counter(num: 1)
  x.?num += 1

  var y = newReactive Counter(card: Card(id: 16))
  watch:
    console.log "card: ", y.?card.id

  y.?card.id += 1

  y <- Counter(card: Card(id: -1))
  ```

### primitives
```nim
  proc createDom(): Element =
    var count = reactive(0)
    buildHtml:
      text count
      button(onClick = (e: Event) => (count += 1)): text "Count"

  setRenderer createDom
```

### ref object
```nim
  type
    Counter = ref object
      c: int

  proc createDom(): Element =
    var count = reactive(Counter(c: 12))
    buildHtml:
      text count.?c
      button(onClick = (e: Event) => (count.?c += 1)): text "Count"

  setRenderer createDom
```