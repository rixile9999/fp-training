// Google Identity Services(GIS) 연동 FFI.
//
// GIS 스크립트를 동적 로드하고(개발 서버가 index.html을 자동 생성하므로 정적
// <script>로 못 박지 않는다), client_id로 초기화한 뒤 주어진 요소에 "Sign in
// with Google" 버튼을 렌더한다. 사용자가 로그인하면 GIS가 ID 토큰(JWT)을
// 콜백으로 주고, 우리는 그걸 Lustre 메시지로 흘려보낸다(app이 /api/auth/google로 검증).
//
// Lustre vdom 보호: 버튼을 렌더하는 컨테이너의 vdom 자식은 항상 비어 있으므로
// (app이 빈 div로 그린다) Lustre diff가 GIS가 주입한 iframe을 지우지 않는다.

let gisLoading = null;

function loadGis() {
  if (gisLoading) return gisLoading;
  gisLoading = new Promise((resolve, reject) => {
    if (globalThis.google?.accounts?.id) return resolve();
    const s = document.createElement("script");
    s.src = "https://accounts.google.com/gsi/client";
    s.async = true;
    s.defer = true;
    s.onload = () => resolve();
    s.onerror = () => reject(new Error("GIS script load failed"));
    document.head.appendChild(s);
  });
  return gisLoading;
}

let initializedFor = null;

/**
 * selector 요소에 구글 로그인 버튼을 렌더한다. onCredential(idTokenString)은
 * 로그인 성공 시 호출된다. 요소가 아직 없으면 다음 프레임에 한 번 재시도한다.
 */
export function renderGoogleButton(selector, clientId, onCredential) {
  loadGis()
    .then(() => {
      const g = globalThis.google.accounts.id;
      // initialize는 client_id가 바뀔 때만(중복 호출은 무해하지만 콜백 갱신 위해 1회).
      if (initializedFor !== clientId) {
        g.initialize({
          client_id: clientId,
          callback: (resp) => {
            if (resp && resp.credential) onCredential(resp.credential);
          },
          auto_select: false,
        });
        initializedFor = clientId;
      }
      const draw = (attempt) => {
        const el = document.querySelector(selector);
        if (el) {
          el.innerHTML = "";
          g.renderButton(el, {
            theme: "outline",
            size: "medium",
            type: "standard",
            shape: "pill",
            text: "signin_with",
          });
        } else if (attempt < 5) {
          requestAnimationFrame(() => draw(attempt + 1));
        }
      };
      draw(0);
    })
    .catch((e) => console.error("[gis]", e?.message ?? e));
}

/** One Tap/세션 힌트 비활성(로그아웃 후 자동 재로그인 방지). */
export function disableAutoSelect() {
  if (globalThis.google?.accounts?.id) {
    globalThis.google.accounts.id.disableAutoSelect();
  }
}
