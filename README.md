### 프로젝트 개요
본 프로젝트는 NCP 환경에서 애플리케이션 배포 CI/CD와 DB 테스트 CI를 분리하여 설계한 예제입니다.

실운영 환경에서는 NCP SourceCommit, SourceBuild, SourceDeploy, NKS를 사용해 비공개로 운영되며, 
본 레포지토리는 구조와 설계 설명을 위한 공개용 문서 레포지토리입니다. 

### 구성 요소
- NCP Source Commit
- NCP Source Build
- NCP Source Deploy
- NCP Source Pipeline
- NKS
- Cloud DB for MySQL

### 파이프라인 구성
1. 애플리케이션 배포 파이프라인
```
SourceCommit (app / k8s 변경)
  → SourceBuild (Docker build)
  → Container Registry
  → SourceDeploy
  → NKS 배포
```
2. DB 테스트 자동화 파이프라인
```
SourceCommit (db/migration 변경)
  → SourceBuild
  → App Server
  → Flyway migrate
  → sysbench 부하 테스트
```