### 프로젝트 개요
본 프로젝트는 NCP 환경에서 애플리케이션 배포 CI/CD와 데이터베이스 변경 테스트 CI 파이프라인을 분리한 예제입니다.

실운영 환경에서는 NCP SourceCommit, SourceBuild, SourceDeploy, NKS를 사용해 비공개 인프라에서 파이프라인이 운영되고 있으며, 
본 레포지토리는 실제 운영 환경을 그대로 공개하지 않고 아키텍처 구조, 파이프라인 흐름, 설계 의도를 기록하기 위한 레포지토리입니다.

### 구성 요소
- NCP Source Commit
- NCP Source Build
- NCP Source Deploy
- NCP Source Pipeline
- kubernetes (NKS)
- NCP Container Registry
- NCP Cloud DB 

### 파이프라인 구성
1. 애플리케이션 배포 파이프라인
애플리케이션 코드 또는 K8s 매니페스트 변경 시 컨테이너 빌드 및 NKS 배포가 수행됩니다.
  ```
  SourceCommit (app / k8s 변경)
    → SourceBuild (Docker build)
    → Container Registry
    → SourceDeploy
    → NKS 배포
  ```
2. DB 테스트 자동화 파이프라인
DB 스키마 변경 시 DB 엔진 성능 테스트 수행 결과가 slack으로 전송됩니다.
  ```
  SourceCommit (db/migration 변경)
    → SourceBuild
    → App Server
    → migrate
    → 성능 테스트
    → 테스트 결과 slack 전송
  ```

결과 예시는 다음과 같습니다. 

<img width="316" height="472" alt="스크린샷 2026-01-05 오후 2 49 56" src="https://github.com/user-attachments/assets/edbb2105-32ed-434a-a9ec-0c44dad9b1a9" />



### 설계 의도
- 애플리케이션 배포 CI/CD와 DB 변경 검증을 명확히 분리
- DB 스키마 변경 시:
  - 성능 지표 변화 사전 검증
- 성능 기준 미달 시 CI 실패 처리로 운영 환경 반영 전 품질 게이트 역할 수행

