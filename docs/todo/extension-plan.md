# 에이전트 사이드바 — 구현 계획

> **상태: 2026-06-14 구현·브라우저 E2E 검증 완료** (비스트리밍 베이스라인).
> 멀티턴 메모리·전 라우트 상주·세션 격리·에러 처리 확인. 영속화/스트리밍은 후속.
>
> `docs/todo/extension.md`(원 요구)에 대한 확정 구현 계획.
> 연구 → 후보 3안 → 적대적 비평 → 채점을 거쳐 도출, 실제 코드베이스에서 핵심 가정 검증 완료.

## 확정 결정

- **백엔드 스택: Node.js + 공식 `openai` SDK(DashScope baseURL) + Hono.** (대안: Python+MAF 66점, Gleam+wisp 68점 — 아래 "왜 Node" 참고. 채점 1위 80점.)
- **세션 메모리: 서버 측 `Map<sessionId, messages[]>` 누산기.** MAF `AgentSession`도 내부적으로 동일 방식(메시지 배열 보관 후 매 턴 재전송)이라, 요구의 "비스므리한 쓰기 편한 툴" 조건을 충족하면서 파이썬 런타임을 들이지 않음.
- **스트리밍: 베이스라인 제외.** 비스트리밍 POST 먼저. (사유: dev 프록시가 응답을 통째 버퍼링 — 검증됨.)

### 왜 Node (MAF 아님)
- **키 격리가 진짜 설계 축.** `DASHSCOPE_API_KEY`는 서버 환경변수 → 브라우저 불가독. 세 후보 모두 same-origin 프록시 백엔드가 필수이고, 이건 `connect-src 'self'` 의도와도 일치.
- **MAF는 첫 실행 실패 위험.** 현행 문서 기준 in-memory 히스토리가 자동 연결 안 됨(`InMemoryHistoryProvider load_messages=True` 명시 필요), `create_session()` await 문서 불일치, 프레임워크 마이그레이션 중. 자기 핵심 기능(메모리)에서 turn-2가 "이름 모름"으로 깨질 확률이 가장 큼 + 파이썬+venv 추가.
- **Gleam+wisp는 현재 컴파일 불가(검증됨).** 핀된 `gleam_otp 1.2.0`에 `actor.send_reply` 없음·빌더 API(`new/on_message/start`)로 변경, `wisp 2.2.2` `json_response(json,status)` 인자 순서 반대·`bad_request()` 인자 필요. 추가로 BEAM TLS CA·`gleam_httpc` 30s 타임아웃 블로커. 단일 언어 이점은 크나 실비용 ~2배.

## 아키텍처 (3계층, 전부 동일 출처)

```
브라우저(Lustre SPA)  ──POST /api/chat──▶  Node 서비스(server/)  ──Bearer key──▶  DashScope(qwen-plus)
  chat_panel 사이드바  ◀──{session_id,text}── Hono+openai SDK         ◀────────────
  Model.chat: UUID만 보관                     Map<sid, messages[]>
                                              DASHSCOPE_API_KEY (이 프로세스 전용)
```

브라우저는 DashScope를 **직접 접촉하지 않음** → CSP `connect-src 'self'` 유지, 키 노출 0.

## 백엔드 — `server/` (신규, ~120줄)

| 파일 | 역할 |
|---|---|
| `server/package.json` | `type:module`; deps `hono @hono/node-server openai`; `dev: node --watch --env-file=.env src/server.mjs` |
| `server/.env` (gitignore) | `DASHSCOPE_API_KEY=...` (+ 선택 `DASHSCOPE_BASE_URL`, `DASHSCOPE_MODEL`, `PORT`) |
| `server/src/config.mjs` | env 1회 읽기·검증. 키 없으면 즉시 종료. `BASE_URL`(기본 intl), `MODEL=qwen-plus`, `PORT=8787` |
| `server/src/llm.mjs` | `new OpenAI({ apiKey, baseURL })` — 키는 이 프로세스 밖으로 안 나감 |
| `server/src/memory.mjs` | **세션 메모리**: `Map<sid,messages[]>`, 시스템 프롬프트 시드, `get/append/windowed/reset` |
| `server/src/server.mjs` | Hono: `GET /api/health`, `POST /api/chat`, `POST /api/chat/reset`; `127.0.0.1` 바인드 |
| `server/.gitignore` | `node_modules`, `.env`, `.sessions.json` |

**HTTP 계약** (진짜 인터페이스 — 추후 MAF/wisp로 교체해도 프론트 불변):
```
POST /api/chat        {session_id, message} → {session_id, text} | 400 | 502
POST /api/chat/reset  {session_id}          → {ok:true}
GET  /api/health                            → {ok:true}
```

메모리 흐름: 요청마다 `history.push(user)` → `windowed(history)` → DashScope 호출 → `history.push(assistant)`. 다음 요청이 전체 맥락을 자동 운반.

## 프론트엔드 — Lustre (신규 Gleam, **새 deps 0개**)

`rsvp`/`lustre`/`gleam_json`이 이미 deps에 존재. 단 이게 **앱 최초의 실제 async Effect**(현재 전부 동기).

신규 `src/fpdojo/ui/chat.gleam` (리프 모듈 — `ui/app`·컴포넌트가 함께 import, 역방향 의존 없음):
```gleam
pub type ChatMsg { ChatMsg(role: String, text: String) }   // "user"|"assistant"|"system"
pub type ChatState {
  ChatState(open: Bool, session_id: String, draft: String,
            messages: List(ChatMsg), streaming: Bool)
}
pub type ChatReply { ChatReply(session_id: String, text: String) }
```

`src/fpdojo/ui/app.gleam` 수정:
- `Model`에 `chat: ChatState`; `init`에서 `session_id: platform.new_uuid()`
- `Msg` += `ChatToggled / ChatInputChanged(String) / ChatSubmitted / ChatResponse(Result(chat.ChatReply, rsvp.Error))`
  — ⚠️ **rsvp 2.x는 `Error`가 파라미터화**됨. 구버전 샘플의 bare `rsvp.Error`는 타입 안 맞음
- `update` 4개 arm: 제출 시 낙관적 user 버블 추가 + `streaming:True` + `rsvp.post` Effect 반환; 응답 시 assistant 버블 + `streaming:False`; 에러 시 system 버블
- `view` 리팩터: route별 `page` 먼저 계산(Lesson arm의 중첩 `case model.lesson` 보존 주의) → `app-shell` div로 `page` + `chat_panel.view`를 감싸 **전 라우트 상주**

신규 `src/fpdojo/ui/components/chat_panel.gleam` — 주입 msg 생성자 규약(`on_input/on_submit/on_toggle`) 따르는 우측 사이드바 + FAB. `fpdojo/ui/chat`만 import, `ui/app` import 금지.

`assets/styles.css` — `.app-shell/.app-main/.chat-fab/.chat-panel/.chat-bubble`. 기존 `#app` 중앙정렬 규칙은 `.app-main` 하위로 스코핑(레이아웃 보존).

`send_chat` Effect 스케치:
```gleam
fn send_chat(session_id: String, prompt: String) -> Effect(Msg) {
  let body = json.object([
    #("session_id", json.string(session_id)),
    #("message", json.string(prompt)),
  ])
  rsvp.post("/api/chat", body, rsvp.expect_json(reply_decoder(), ChatResponse))
}
```

## 개발/실행 워크플로

```fish
# 터미널 A — 백엔드
cd server; node --watch --env-file=.env src/server.mjs   # :8787

# 터미널 B — 프론트엔드
cd app; gleam run -m lustre/dev start                      # :1234
```

`app/gleam.toml`에 프록시 추가. ⚠️ lustre_dev_tools 는 설정을 `[tools.lustre]` 하위에서 읽고(`project.options = tom.get_table(config, ["tools","lustre"])`), `proxy.gleam`은 **인라인 테이블만** 인식한다. 따라서 top-level `[dev.proxy]` 섹션이 아니라 `[tools.lustre.dev]` 아래 인라인 테이블로 써야 한다(검증 완료):
```toml
[tools.lustre.dev]
proxy = { from = "/api", to = "http://localhost:8787/api" }
```
- 프록시가 `/api` 프리픽스를 매칭 후 `filepath.join(to.path, 나머지)`로 합치므로 `to`에 `/api`를 포함시켜야 백엔드 라우트(`/api/chat`)와 경로가 일치한다. `GET /api/health`로 검증.
- **프록시는 응답 전체 버퍼링** → dev 경유 SSE 스트리밍 불가(베이스라인 비스트리밍이라 무관).

프로덕션: Node가 빌드된 SPA + `/api/*`를 single-origin 서빙(CORS 불필요). **단 정적 서빙 경로 주의** — `index.html`은 `app/`에 있고 번들은 `priv/static/`. lustre가 index.html을 생성하므로 실제 산출 디렉터리를 가리키는 조립 스텝 필요(`serveStatic` root는 cwd 상대).

## 검증으로 바로잡은 함정 (반드시 준수)

1. **CSP는 이 기능에서 건드리지 않는다.** same-origin이라 `connect-src 'self'`는 이미 충족. CSP는 PLAN §249의 WASM 워커 샌드박스 경계라, 미래 컴파일러 도입 시 넣을 때 `worker-src 'self'` + `script-src` + `wasm-unsafe-eval`을 반드시 포함(안 그러면 레슨 엔진 사망). 또 dev/build index.html은 lustre가 생성 → 손편집 무효.
2. **스트리밍 보류.** dev 프록시 버퍼링으로 토큰 단위 불가. single-origin 전제의 후속 과제(`chat_ffi.mjs` + SSE + AbortController).
3. **메모리 버그 픽스**: `reset` 핸들러가 body에서 `session_id` 읽기(ReferenceError 방지); `windowed()`는 **시스템 메시지 보존**(`slice(-N)` 금지, 시스템 + 최근 N턴); 빈/거부 응답(`finish_reason`)을 메모리에 안 넣기; `message` 길이 상한.
4. **보안**: 서버 `127.0.0.1` 바인드 + 간단 공유 토큰(키 쿼터 도난 방지); 502 `detail` 스크럽(SDK 에러에 키 파편 가능); 공개 노출 금지.
5. **하이브리드**: 서버=메모리 진실원천, 클라이언트는 **UUID만** `localStorage`(`fpdojo.v1.chat`, 기존 네임스페이스)에 저장; 메모리 레이어 단위 테스트 1개(두 session_id 격리); 파일 영속화 시 temp+rename 원자적 쓰기.

## 빌드 순서

0. **curl로 DashScope 먼저 확인**(region↔key 짝 — #1 실패 원인):
   ```
   curl $BASE_URL/chat/completions -H "Authorization: Bearer $DASHSCOPE_API_KEY" \
     -H 'Content-Type: application/json' \
     -d '{"model":"qwen-plus","messages":[{"role":"user","content":"hi"}]}'
   ```
   intl 키 → `dashscope-intl.aliyuncs.com/compatible-mode/v1`, 베이징 키 → `dashscope.aliyuncs.com/compatible-mode/v1`.
1. `server/` 스캐폴드 → `/api/chat` 작성 → curl로 2턴 메모리 검증(이름 말하고 되묻기).
2. `chat.gleam` 타입 → `chat_panel.gleam` 컴포넌트.
3. `ui/app.gleam` 배선(Model/Msg/update/view + `send_chat`/decoder) → `gleam build` 클린(rsvp `Error` 타입 주의).
4. CSS → `[dev.proxy]` 배선 → 양쪽 띄우고 전 라우트 E2E + 멀티턴 메모리 검증.
5. (선택) 영속화 · (선택) 스트리밍.

**노력 추정**: 비스트리밍 베이스라인 **~2–3일** (주로 `view` 리팩터 + 프록시/single-origin 배선).
