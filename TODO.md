# 📋 뱀서라이크 개발 Phase별 Todo List

PRD를 바탕으로 세분화한 단계별 개발 체크리스트입니다. 각 태스크는 독립적으로 구현 및 검증할 수 있도록 구성되어 있습니다.

---

## 📌 Phase 1: 기본 프로토타입 (Movement & Basic Combat)
> **목표**: 플레이어가 움직이고, 자동으로 가장 가까운 적을 공격하며, 적이 플레이어를 추적하는 기본 플레이 검증

- [x] **1.1 프로젝트 기본 환경 설정**
  - [x] 프로젝트 뷰포트 해상도 설정 (1280x720, canvas_items / expand)
  - [x] 프로젝트 입력 맵(Input Map) 설정 (`move_left`, `move_right`, `move_up`, `move_down`)
  - [x] 전역 싱글톤(Autoload) 생성: `EventBus.gd` (이벤트 신호 관리)

- [x] **1.2 플레이어 기본 구현 (`Player.tscn`)**
  - [x] `CharacterBody2D` 노드 기반 플레이어 씬 생성
  - [x] 8방향 이동 및 대각선 이동 속도 정규화(`velocity.normalized()`)
  - [x] `Camera2D` 추가 (부드러운 추적 `position_smoothing_enabled`)
  - [x] 이동 방향에 따른 스프라이트 좌우 반전(Flip H) 처리

- [x] **1.3 기본 적 구현 (`EnemySlime.tscn`)**
  - [x] `CharacterBody2D` 기반 기본 슬라임 씬 생성
  - [x] 플레이어 위치를 향해 최단 경로로 이동하는 단순 추적 AI
  - [x] 적 체력(HP), 피격 시 화이트 플래시(White Flash) 효과
  - [x] HP가 0 이하일 때 사망 처리

- [x] **1.4 첫 번째 자동 공격 무기 (`WeaponMagicMissile.tscn`)**
  - [x] 투사체 씬 구현 (`MagicMissileProjectile.tscn`, 속도, 데미지, 관통 수, 수명 타이머)
  - [x] 쿨다운 타이머(`Timer`) 기반 자동 발사
  - [x] 사거리 내 "가장 가까운 적"을 탐색하여 조준 및 발사 로직 구현

- [x] **1.5 기본 스포너 (`EnemySpawner.tscn`)**
  - [x] 플레이어 화면 밖 테두리(Bounding Box / Radius)에서 랜덤 스폰 위치 계산
  - [x] 일정 시간 간격으로 기본 몬스터 지속 생성

---

## 📌 Phase 2: 코어 게임 루프 완성 (Farming & Level Up)
> **목표**: 몬스터를 잡아 경험치를 모으고, 레벨업 창에서 스킬을 선택하여 강해지는 핵심 루프 완성

- [x] **2.1 드롭 아이템 및 자석 흡수 (`ExpGem.tscn`)**
  - [x] 몬스터 사망 시 해당 위치에 경험치 보석 스폰
  - [x] 플레이어에 `PickupArea` (자석 영역) 추가
  - [x] 영역에 감지된 보석이 플레이어를 향해 점점 가속하며 끌려오는 로직 구현
  - [x] 획득 시 사운드/이펙트 재생 및 플레이어 경험치 증가

- [x] **2.2 플레이어 레벨업 시스템**
  - [x] 레벨별 요구 경험치 계산 공식 작성 (지수적 증가)
  - [x] 경험치 완충 시 레벨업 이벤트(`level_up`) 발생

- [x] **2.3 레벨업 선택지 팝업 UI (`LevelUpUI.tscn`)**
  - [x] 레벨업 시 게임 일시정지 (`get_tree().paused = true`, UI는 `PROCESS_MODE_ALWAYS`)
  - [x] 3개(또는 4개)의 업그레이드 카드 랜덤 노출
  - [x] 카드 클릭 시 해당 업그레이드 반영 후 게임 재개 (`paused = false`)

- [x] **2.4 플레이어 피격 및 게임 오버**
  - [x] 몬스터와 충돌 시 플레이어 HP 감소 및 무적 시간(i-frame) 부여
  - [x] 상단 HUD에 체력바 및 경험치 진행도 바 표시
  - [x] 플레이어 HP 0 도달 시 사망 연출 및 게임 오버 화면 (재시작 버튼)

---

## 📌 Phase 3: 콘텐츠 확장 및 최적화 (Arsenal, Waves & Optimization)
> **목표**: 다양한 무기와 패시브를 조합하는 빌드 재미 제공, 시간별 웨이브 및 대규모 적 처리를 위한 최적화

- [x] **3.1 데이터 주도형 장비 아키텍처 (Resource / InventoryManager)**
  - [x] 장비 데이터 정의 (이름, 설명, 아이콘, 타입, 레벨별 수치, 진화 조합)
  - [x] 무기 슬롯 매니저 (`InventoryManager.gd`: 최대 6개 무기, 6개 패시브 관리 및 스마트 카드 필터링)

- [x] **3.2 추가 무기 구현 (다양한 공격 메커니즘 & 진화)**
  - [x] **회전형 (오브/성서)**: `WeaponOrbitingOrbs.tscn` (회전 충돌 타격 및 Unholy Vespers 진화)
  - [x] **오라형 (마늘)**: `WeaponGarlic.tscn` (주변 지속 틱 데미지, 넉백 및 Soul Eater 흡혈 진화)
  - [x] **범위 낙하형 (성수)**: `WeaponHolyWater.tscn` & `HolyWaterZone.tscn` (화염 장판 및 La Borra 진화)

- [x] **3.3 패시브 아이템 구현**
  - [x] 공격력 증폭 (Might / Spinach: 공격력 10%~50% 증가)
  - [x] 쿨다운 감소 (Empty Tome: 쿨다운 8%~40% 감소)
  - [x] 이동 속도 증가 (Swift Boots: 이속 12%~60% 증가)
  - [x] 자석 수집 반경 증가 (Attractorb: 픽업 반경 30%~150% 증가)
  - [x] 최대 체력 및 회복 (Vitality / Red Heart)

- [x] **3.4 웨이브 매니저 & 타이머 & 보물 상자**
  - [x] 인게임 10분 생존 타이머 (`mm:ss`) 상단 HUD 표시
  - [x] 시간대별 스폰 테이블 (0~2분 슬라임, 2~4분 박쥐, 3분/6분 엘리트 스폰)
  - [x] 엘리트 몬스터(`EnemyElite`) 및 보물 상자(`TreasureChest`), 진화 팝업(`ChestRewardUI`) 구현

- [x] **3.5 대규모 몬스터 최적화 (Object Pooling)**
  - [x] 오브젝트 풀링 매니저 (`NodePool.gd`) 구현
  - [x] FHD(1920x1080) 해상도 기준 화면 밖 스폰 거리 보정 (1150px) 및 최적화

---

## 📌 Phase 4: 게임성 및 완성도 폴리싱 (Juice & Polish)
> **목표**: 시각적/청각적 타격감 강화, 완성도 높은 게임 경험 완성

- [x] **4.1 타격감 (Juice) 강화**
  - [x] 대미지 플로팅 텍스트 (`DamageNumber.tscn`: 피격 시 숫자가 튀어오름)
  - [x] 카메라 셰이크 (Screen Shake: 피격/엘리트 처치 시 화면 진동)
  - [x] 몬스터 넉백(Knockback) 효과

- [x] **4.2 오디오/사운드 시스템**
  - [x] 오디오 매니저 싱글톤 (`AudioManager.gd`: 프로시저럴 PCM 합성)
  - [x] SFX 완비 (발사음, 피격음, 보석 획득음, 레벨업 팡파레, 상자 오픈, 게임 오버)

- [x] **4.3 UI 및 편의 기능**
  - [x] 일시정지 메뉴 (`PauseMenu.tscn`: ESC 키로 즉시 일시정지/재개/재시작)
  - [x] 결과 화면 (`VictoryGameOverUI.tscn`: 생존 시간, 레벨, 처치 수, 최종 장비 통계 모달)
  - [x] 게임 오버 및 승리(10분 생존) 통합 결과창 연동

- [x] **4.4 보스 인카운터 및 탄막 공격 패턴 강화 (`EnemyBoss.tscn`)**
  - [x] 보스 등장 타이밍 1분(60초)으로 단축 조정 (25초 엘리트 스폰으로 보물 상자 파밍 기회 제공)
  - [x] 보스 능력치 대폭 상향: HP 1800, 이동속도 120, 피격 판정 및 상단 체력바
  - [x] 패턴 A: 360도 전방향 12방향 탄막 발사 (`EnemyProjectile.tscn`, 3.5초 주기)
  - [x] 패턴 B: 플레이어 타겟팅 직선 3연발 고속 투사체 공격 (2.2초 주기)
  - [x] 보스 처치 시 대형 카메라 진동, 황금 보물 상자 드롭, 1.5초 후 게임 승리 모달 연동
  - [x] FHD(1920x1080) 해상도 대응 전역 오브젝트(플레이어, 몬스터, 보석, 상자, 무기 투사체) 2배 스케일업 및 피격 박스 보정
