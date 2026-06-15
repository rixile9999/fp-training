# 해설 — fold 방향과 prepend 누산

`list.fold([1, 2, 3], [], fn(acc, x) { [x, ..acc] })`는 **왼쪽부터** 원소를
하나씩 콜백에 넘깁니다. 콜백 인자는 `fn(acc, item)` 순서입니다.

| 단계 | x | acc(이전) | `[x, ..acc]` |
|---|---|---|---|
| 1 | 1 | `[]` | `[1]` |
| 2 | 2 | `[1]` | `[2, 1]` |
| 3 | 3 | `[2, 1]` | `[3, 2, 1]` |

prepend는 O(1)이라 관용적이지만, 그 대가로 **순서가 뒤집힙니다** — U6에서 본
누산기 뒤집힘과 같은 현상입니다 (`tricky:accumulator-reverse`).

## 순서를 보존하고 싶다면 — 모범 답안 비교

```gleam
// 1) fold 후 reverse — 가장 흔한 관용구 (prepend O(1) + reverse 1회)
list.fold([1, 2, 3], [], fn(acc, x) { [x, ..acc] }) |> list.reverse

// 2) fold_right — 오른쪽부터 접으므로 prepend가 순서를 보존
//    (꼬리 재귀가 아니므로 아주 긴 리스트에는 1)을 권장)
list.fold_right([1, 2, 3], [], fn(acc, x) { [x, ..acc] })
```

핵심 두 가지: **fold는 왼쪽부터, 콜백은 `fn(acc, item)` 순서.** 이 둘만
기억하면 fold 계열 predict는 손으로 전개해서 풀 수 있습니다.
