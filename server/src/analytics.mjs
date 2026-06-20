// 학습 진행 분석 — 이벤트 로그(append-only)에서 지표를 도출하는 순수 함수들.
//
// 날짜 버킷은 Asia/Seoul(UTC+9, KST) 자정 기준으로 통일한다(PLAN §4.3 데일리 키).
// 커버리지(트랙/레벨/유닛 완료율)는 서버가 커리큘럼을 모르므로 여기서 계산하지
// 않는다 — 완료 레슨 id+시각만 돌려주고, 프론트가 자기 units 와 합쳐 그린다.

const KST_OFFSET_MS = 9 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

/** epoch ms → KST 자정 기준 "YYYY-MM-DD" 일자 키. */
export function dayKey(ms) {
  const d = new Date(ms + KST_OFFSET_MS);
  const y = d.getUTCFullYear();
  const mo = String(d.getUTCMonth() + 1).padStart(2, "0");
  const da = String(d.getUTCDate()).padStart(2, "0");
  return `${y}-${mo}-${da}`;
}

/** KST 자정 epoch ms (해당 ms 가 속한 KST 날짜의 0시). */
function kstMidnightMs(ms) {
  return Math.floor((ms + KST_OFFSET_MS) / DAY_MS) * DAY_MS - KST_OFFSET_MS;
}

/** lesson_completed 이벤트를 lesson_id 별 첫 완료로 dedupe. */
function firstCompletions(events) {
  const byLesson = new Map();
  for (const ev of events) {
    if (ev.type !== "lesson_completed" || !ev.lesson_id) continue;
    const prev = byLesson.get(ev.lesson_id);
    if (!prev || ev.at_ms < prev.at_ms) byLesson.set(ev.lesson_id, ev);
  }
  return [...byLesson.values()].sort((a, b) => a.at_ms - b.at_ms);
}

/**
 * 전체 분석을 계산한다. `now` 는 테스트 주입용(기본 Date.now()).
 * 반환: { speed, consistency, completed, events_count }.
 */
export function analyze(events, now = Date.now()) {
  const completions = firstCompletions(events);
  const total = completions.length;

  // 일자별 완료 수.
  const perDay = new Map();
  for (const c of completions) {
    const k = dayKey(c.at_ms);
    perDay.set(k, (perDay.get(k) ?? 0) + 1);
  }
  const activeDays = perDay.size;

  // ── 학습 속도 ──
  const durations = completions.map((c) => c.duration_ms).filter((d) => Number.isFinite(d) && d > 0);
  const avgLessonMs = durations.length ? Math.round(durations.reduce((a, b) => a + b, 0) / durations.length) : null;
  const medianLessonMs = durations.length ? median(durations) : null;

  // 최근 14일 막대(오늘 포함, KST).
  const recent = lastNDays(14, now).map((key) => ({ date: key, count: perDay.get(key) ?? 0 }));

  const speed = {
    lessons_total: total,
    days_active: activeDays,
    lessons_per_active_day: activeDays ? round1(total / activeDays) : 0,
    avg_lesson_ms: avgLessonMs,
    median_lesson_ms: medianLessonMs,
    first_completion_ms: total ? completions[0].at_ms : null,
    last_completion_ms: total ? completions[total - 1].at_ms : null,
    recent,
  };

  // ── 성실성·꾸준함 ──
  const dayKeysSorted = [...perDay.keys()].sort();
  const { current, longest } = streaks(dayKeysSorted, now);
  // 최근 12주(84일) 캘린더 히트맵.
  const calendar = lastNDays(84, now).map((key) => ({ date: key, count: perDay.get(key) ?? 0 }));
  // 요일 분포(0=일 .. 6=토, KST 기준).
  const byWeekday = [0, 0, 0, 0, 0, 0, 0];
  for (const [key, count] of perDay) {
    const wd = new Date(key + "T00:00:00Z").getUTCDay();
    byWeekday[wd] += count;
  }
  const spanDays = total ? Math.floor((kstMidnightMs(now) - kstMidnightMs(completions[0].at_ms)) / DAY_MS) + 1 : 0;

  const consistency = {
    current_streak: current,
    longest_streak: longest,
    active_days: activeDays,
    span_days: spanDays,
    consistency_rate: spanDays ? round1((activeDays / spanDays) * 100) : 0, // 활동일 / 경과일 %
    calendar,
    by_weekday: byWeekday,
  };

  // 커버리지용 완료 목록.
  const completed = completions.map((c) => ({ lesson_id: c.lesson_id, at_ms: c.at_ms }));

  return { speed, consistency, completed, events_count: events.length };
}

// ── 헬퍼 ───────────────────────────────────────────────────────────

function lastNDays(n, now) {
  const todayMid = kstMidnightMs(now);
  const out = [];
  for (let i = n - 1; i >= 0; i--) out.push(dayKey(todayMid - i * DAY_MS));
  return out;
}

// "YYYY-MM-DD" 일자 키를 delta 일 만큼 이동(달력 산술). 키를 UTC 자정 앵커로
// 일관되게 다뤄 월/연 경계도 정확하다(KST 변환은 dayKey 에서 이미 끝났다).
function shiftDay(key, delta) {
  const d = new Date(Date.parse(key + "T00:00:00Z") + delta * DAY_MS);
  const y = d.getUTCFullYear();
  const mo = String(d.getUTCMonth() + 1).padStart(2, "0");
  const da = String(d.getUTCDate()).padStart(2, "0");
  return `${y}-${mo}-${da}`;
}

// 연속 학습일(streak). current 는 오늘 또는 어제까지 이어진 연속, longest 는 최장.
function streaks(dayKeysSorted, now) {
  if (dayKeysSorted.length === 0) return { current: 0, longest: 0 };
  const set = new Set(dayKeysSorted);
  // longest — 이전 날이 없는 구간 시작점에서만 길이를 잰다.
  let longest = 0;
  for (const key of dayKeysSorted) {
    if (set.has(shiftDay(key, -1))) continue;
    let len = 1;
    let cur = key;
    while (set.has(shiftDay(cur, 1))) {
      len++;
      cur = shiftDay(cur, 1);
    }
    if (len > longest) longest = len;
  }
  // current — 오늘(없으면 어제)부터 거꾸로 이어진 연속.
  const today = dayKey(now);
  let cursor = set.has(today) ? today : set.has(shiftDay(today, -1)) ? shiftDay(today, -1) : null;
  let current = 0;
  while (cursor && set.has(cursor)) {
    current++;
    cursor = shiftDay(cursor, -1);
  }
  return { current, longest };
}

function median(arr) {
  const s = [...arr].sort((a, b) => a - b);
  const mid = Math.floor(s.length / 2);
  return s.length % 2 ? s[mid] : Math.round((s[mid - 1] + s[mid]) / 2);
}

function round1(n) {
  return Math.round(n * 10) / 10;
}
