import proxy
import std/jsconsole

type
  Counter = ref object
    num: int

x := Counter(num: 0)
x.?num += 1
x.?num = 77
console.log x.?num

y := 10
?y = 10
?y += 1
console.log ?y
y.value = 88
console.log y.value

watch(proc() =
  console.log ?y
)
