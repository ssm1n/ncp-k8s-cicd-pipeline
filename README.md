### 프로젝트 개요
본 프로젝트는 NCP 환경에서 애플리케이션 테스트/빌드/배포 및 DB 성능 테스트 과정을 자동화하는 CI/CD 파이프라인 예제입니다.

실운영 환경에서는 NCP SourceCommit, SourceBuild, SourceDeploy, Container Registry, NKS를 사용해 비공개 인프라에서 파이프라인이 운영되고 있으며, 
본 레포지토리는 실운영 환경을 공개하지 않고 아키텍처 구조, 파이프라인 흐름, 설계 의도 등을 기록하기 위한 레포지토리입니다.

### 구성 요소
- NCP Source Commit
- NCP Source Build
- NCP Source Deploy
- NCP Source Pipeline
- NCP Container Registry
- Kubernetes (NKS)
- DB Migration: Flyway
- 성능 테스트: sysbench (OLTP read/write)
- 알림: Slack Webhook

### 파이프라인 구성

<img width="1028" height="574" alt="과제4다이어그램" src="https://github.com/user-attachments/assets/f6db1bf9-d9ed-4d74-bc1c-79f798b84fd5" />


**1. 애플리케이션 배포 파이프라인**<br>
애플리케이션 코드 또는 K8s 매니페스트 변경 시 컨테이너 빌드 및 NKS 배포가 수행됩니다.
  ```
  SourceCommit (app/, k8s/ 변경)
    → SourceBuild (Docker build)
    → Container Registry
    → SourceDeploy
    → NKS 배포
  ```
**2. DB 테스트 자동화 파이프라인**<br>
DB 스키마 변경 시 DB 엔진 성능 테스트 수행 결과가 Slack으로 전송됩니다.
  ```
  SourceCommit (db/migration/ 변경)
    → SourceBuild
    → App Server
    → migrate
    → 성능 테스트
    → 테스트 결과 Slack 전송
  ```

Slack으로 전송되는 성능 테스트 결과 예시는 다음과 같습니다.

<img width="200" height="450" alt="스크린샷 2026-01-05 오후 2 49 56" src="https://github.com/user-attachments/assets/edbb2105-32ed-434a-a9ec-0c44dad9b1a9" />

### DB 성능 테스트 설정
- **테스트 구성**: 8 threads, 60초 duration
- **최소 성능 기준**: TPS ≥ 500/sec (기준 미달 시 CI 실패)
- **측정 지표**: 
  - **Throughput**: TPS, QPS
  - **Latency**: Avg, P95, Max
  - **Workload**: Read queries, Write queries, Write ratio
  - **Stability**: Error count/rate, Reconnects

### 환경 변수
DB 테스트 스크립트 실행 시 다음 환경 변수가 필요합니다:
- `DB_USER`: 데이터베이스 사용자
- `DB_PASSWORD`: 데이터베이스 비밀번호
- `SLACK_WEBHOOK_URL`: Slack 알림 웹훅 URL (선택)

### 설계 의도
- 애플리케이션 배포, DB 테스트 파이프라인 분리
- DB 스키마 변경 시 성능 지표 변화 사전 검증
- 성능 기준 미달 시 CI 실패 처리로 운영 환경 반영 전 품질 게이트 역할 수행

