//// 패키지 엔트리포인트 — ui/app.main()에 위임만 한다.
//// 모든 부트 로직(커스텀 엘리먼트 등록, Lustre 마운트)은 fpdojo/ui/app 소관.

import fpdojo/ui/app

pub fn main() -> Nil {
  app.main()
}
