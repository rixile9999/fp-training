// compiler_ffi.mjs — 컴파일 워커 메인스레드 포트 (PLAN §5.2 듀얼 워커).
//
// fpdojo/engine/compiler.gleam 의 @external 대상. 인터페이스는 후일 sandboxed
// iframe 격상에 대비해 message-passing 형태로 고정한다(interfaces.md "JS 자산",
// architecture.md §3.6): initCompiler() / compileModules(modules) 두 export 뿐.
//
// 워커 메시지 프로토콜 (interfaces.md — priv/static/workers/compiler.worker.js):
//   요청  { id: number, type: "init" }
//        { id: number, type: "compile", modules: [{ name: string, code: string }] }
//   응답  { id, ok: true,  modules: [{ name: string, js: string }], warnings: string[] }
//        { id, ok: false, pretty: string }    // 컴파일 에러 pretty 평문 원문
//
// 장수명 워커: WASM init + stdlib ~50모듈 write_module 비용을 1회만 지불한다.
// 유저 코드는 여기서 실행되지 않으므로 워커가 무한루프로 죽을 일이 없다.
// 안전망 watchdog 30s — 컴파일러 자체 panic 시에만 풀 respawn(PLAN §5.2).

const WORKER_URL = "/workers/compiler.worker.js"; // priv/static 정적 루트 기준
const SAFETY_TIMEOUT_MS = 30_000; // 컴파일러 panic 안전망 (PLAN §5.2)

let worker = null; // 장수명 Worker 인스턴스 (lazy spawn)
let nextId = 1; // 메시지 상관관계(correlation) id
const pending = new Map(); // id -> { resolve, reject, timer }
let initialised = null; // initCompiler() Promise 캐시 — 멱등성

function ensureWorker() {
  // TODO 1: worker가 null이면 new Worker(WORKER_URL, { type: "module" }) 스폰
  // TODO 2: worker.onmessage = (e) => { pending에서 e.data.id 조회 →
  //         clearTimeout(timer), pending.delete(id), resolve(e.data) }
  //         — 응답 raw 객체를 그대로 resolve (CompileOutcome 디코드는 compiler.gleam 몫)
  // TODO 3: worker.onerror — 모든 pending reject 후 worker.terminate(),
  //         worker = null, initialised = null (다음 호출이 풀 respawn 비용 지불)
  // TODO 4: return worker
  throw new Error("TODO");
}

function post(message) {
  // TODO 1: const id = nextId++
  // TODO 2: new Promise — pending.set(id, { resolve, reject, timer })
  // TODO 3: timer = setTimeout(SAFETY_TIMEOUT_MS): 컴파일러 panic 경로 —
  //         worker.terminate(); worker = null; initialised = null;
  //         pending 전부 reject("compiler worker watchdog (30s)") 후 클리어
  // TODO 4: ensureWorker().postMessage({ id, ...message })
  throw new Error("TODO");
}

/**
 * WASM 컴파일러 lazy-load + 워커 부팅. 첫 인터랙티브 연습 진입 시 호출
 * (architecture.md §3.2 — 앱 셸 초기 로드는 가볍게).
 * resolve: 워커의 init 응답 raw 객체 ({ok:true} | {ok:false, pretty}).
 * Gleam 쪽 compiler.init()이 Result(Nil, String)으로 매핑한다.
 */
export function initCompiler() {
  // TODO 1: initialised가 있으면 그대로 반환 (멱등 — 중복 init 방지)
  // TODO 2: initialised = post({ type: "init" }); 실패(reject) 시
  //         initialised = null 로 되돌려 재시도 가능하게
  // TODO 3: return initialised
  throw new Error("TODO");
}

/**
 * 소스 모듈 컴파일. modules는 Gleam List(SourceModule) — 프렐류드 List는
 * toArray()를 제공하고 레코드 필드는 .name / .code 로 접근한다.
 * resolve: 워커의 compile 응답 raw 객체
 *          ({ok:true, modules:[{name,js}], warnings} | {ok:false, pretty}).
 */
export function compileModules(modules) {
  // TODO 1: const arr = modules.toArray().map((m) => ({ name: m.name, code: m.code }))
  // TODO 2: return post({ type: "compile", modules: arr })
  //         — harness 주입은 워커 몫이므로 여기서는 손대지 않는다
  throw new Error("TODO");
}
