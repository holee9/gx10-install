# Functional Requirements Specification (FRS)

## Status
- Overall: COMPLETE
- Core Functions: COMPLETE
- Brain Control: COMPLETE
- TBD Items: IDENTIFIED

## Table of Contents
1. [Introduction](#introduction)
2. [Core Functions](#core-functions)
3. [Brain Control](#brain-control)
4. [Error Handling](#error-handling)
5. [Open Items](#open-items)

---

## Introduction

### 문서 목적

본 문서는 GX10 시스템의 기능적 요구사항을 상세히 명세합니다.

---

## Core Functions

### FC-1: Execution Plan 수신 및 검증 (Execution Plan Reception and Validation)

**우선순위**: P0 (필수)

**설명**: 시스템은 사용자가 제공한 Execution Plan을 수신하고 유효성을 검증해야 합니다.

**입력**:
- Execution Plan 파일 (JSON/YAML)
- 파일 경로 또는 직접 업로드

**처리**:
1. 파일 형식 검증 (JSON/YAML)
2. 스키마 유효성 검증
3. 필수 필드 존재 확인
4. 필드 값 타입 검증
5. 의존성 순환 검증

**출력**:
- 성공: `{"success": true, "plan_id": "..."}`
- 실패: `{"success": false, "error": "..."}`

---

### FC-2: 코드 생성 및 수정 (Code Generation and Modification)

**우선순위**: P0 (필수)

**설명**: Execution Plan을 기반으로 코드를 생성하고 수정합니다.

**처리 단계**:

1. **디렉토리 생성**
   - root_dir 경로 확인
   - 필요한 하위 디렉토리 생성

2. **파일별 구현**
   - implementation_order 순서 준수
   - 각 파일의 responsibility에 따라 코드 생성
   - dependencies 필드 참조

3. **테스트 자동 생성**
   - test_target이 명시된 파일에 대해 테스트 생성
   - 테스트 프레임워크 자동 감지

4. **테스트 실행 및 재시도**
   - 테스트 명령어 실행 (tests.command)
   - 실패 시 자동 재수정 (최대 3회)
   - 성공 시 다음 파일로 진행

**출력**:
- 생성된 파일들
- 테스트 결과 (pass/fail, coverage)
- 실행 로그

---

### FC-3: 보고서 생성 (Report Generation)

**우선순위**: P1 (중요)

**설명**: 작업 완료 후 실행 결과 보고서를 생성합니다.

**보고서 내용**:
- task_id
- status (success/failed)
- files_created (파일 목록)
- test_results (pass/fail, coverage)
- duration_seconds
- timestamp

**형식**:
- Markdown: `/gx10/runtime/logs/reports/{task_id}.md`
- JSON: `/gx10/runtime/logs/reports/{task_id}.json`

---

## Brain Control

### BC-1: Brain 상태 조회 (Brain Status Query)

**우선순위**: P0 (필수)

**설명**: 현재 활성화된 Brain의 상태를 조회합니다.

**API**: `GET /api/brain/status`

**응답**:
```json
{
  "success": true,
  "data": {
    "active_brain": "code-brain",
    "health": "healthy",
    "container_status": {
      "cpu_usage_percent": 45.2,
      "memory_usage_mb": 12800,
      "gpu_usage_percent": 75.0,
      "gpu_memory_mb": 24576
    },
    "timestamp": "2026-02-01T19:00:00Z"
  }
}
```

---

### BC-2: Brain 전환 (Brain Switching)

**우선순위**: P0 (필수)

**설명**: Code Brain과 Vision Brain을 전환합니다.

**API**: `POST /api/brain/switch`

**요청**:
```json
{
  "target_brain": "code-brain",
  "reason": "Code implementation task",
  "force": false
}
```

**처리 단계**:
1. 현재 Brain 상태 조회
2. target_brain과 비교
3. 불일치 시 현재 Brain 정지
4. Buffer Cache 플러시 (필수!)
5. 목표 Brain 시작
6. 헬스체크 통과 확인

**응답**:
```json
{
  "success": true,
  "data": {
    "result": "success",
    "target_brain": "code-brain",
    "estimated_duration_seconds": 10
  }
}
```

**제약**:
- 단일 Brain만 실행 가능
- Code + Vision 동시 실행 금지
- 전환 시간: < 30초

---

### BC-3: 단일 Brain 실행 강제 (Single Brain Enforcement)

**우선순위**: P0 (필수)

**설명**: 시스템은 단일 Brain만 실행 가능하도록 강제합니다.

**구현**:
- active_brain.json 상태 관리
- Brain 시작 시 lock 획득
- Brain 전환 시 lock 해제 및 재획득
- 동시 실행 시도 차단

**데이터 구조**:
```json
{
  "active_brain": "code",
  "pid": 12345,
  "since": "2026-02-01T19:00:00Z",
  "last_switch": "2026-02-01T19:00:00Z"
}
```

---

## Error Handling

### EH-1: Execution Plan 오류 (Execution Plan Errors)

**에러 타입**:

1. **파일 형식 오류**
   - 코드: 400
   - 메시지: "Invalid file format. Expected JSON or YAML."

2. **스키마 유효성 오류**
   - 코드: 422
   - 메시지: "Schema validation failed. Missing required field: project_name"

3. **의존성 순환 오류**
   - 코드: 422
   - 메시지: "Circular dependency detected: file1.py → file2.py → file1.py"

---

### EH-2: 코드 생성 오류 (Code Generation Errors)

**에러 타입**:

1. **테스트 실패**
   - 코드: 200 (성공이지만 실패 기록)
   - 메시지: "Test failed after 3 retries. See logs for details."

2. **메모리 부족**
   - 코드: 500
   - 메시지: "Out of memory. Cannot load model."

3. **타임아웃**
   - 코드: 408
   - 메시지: "Task timeout after 3600 seconds."

---

### EH-3: Brain 전환 오류 (Brain Switching Errors)

**에러 타입**:

1. **잘못된 Brain 이름**
   - 코드: 400
   - 메시지: "Invalid target brain. Expected 'code' or 'vision'."

2. **전환 실패**
   - 코드: 500
   - 메시지: "Failed to switch to vision brain. Container startup failed."

3. **이미 활성화된 Brain**
   - 코드: 409
   - 메시지: "Code brain is already active."

---

## Open Items

### TBD (To Be Determined)

1. **에러 분류 체계**
   - 현재: 기본 에러 메시지만 존재
   - 필요: 에러 코드, 카테고리, 심각도 분류
   - 우선순위: P1

2. **재시도 정책 고도화**
   - 현재: 고정된 3회 재시도
   - 필요: 에러 타입별 재시도 정책
   - 우선순위: P2

3. **부분 재실행 지원**
   - 현재: 전체 재실행만 지원
   - 필요: 실패한 파일만 재실행
   - 우선순위: P1

---

## 📝 문서 정보

**작성자**:
- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0
- 작성일: 2026-02-01

**리뷰어**:
- drake

---

## 📜 수정 이력

| 일자 | 버전 | 설명 | 리뷰어 |
|------|------|------|--------|
| 2026-02-01 | 1.0 | 기존 문서 기반 전면 보완 | drake |
