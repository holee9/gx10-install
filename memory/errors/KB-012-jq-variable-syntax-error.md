# KB-012: switch.sh 다중 오류 (jq 변수, PID null, 컨테이너 충돌)

## 오류 정보

- **발생일**: 2026-02-03
- **Phase**: Phase 5 (Final Validation) 실행 중 발견
- **스크립트**: `switch.sh` (생성: `03-brain-switch-api.sh`)
- **심각도**: Medium
- **상태**: ✅ 해결됨

## 증상

```
jq: error: syntax error, unexpected ' 05 를 실행한 결과야., expecting FORMAT or QQSTRING_START or '[' (Unix shell quoting issues?) at <top-level>, line 1:
.statistics.total_switches += 1 | .statistics.${FROM_TO} += 1
jq: 1 compile error
```

Brain 전환 후 통계 업데이트 시 jq 오류 발생. 기능에는 영향 없으나 오류 메시지 출력.

## 원인

**bash 변수를 jq 표현식 내에서 직접 사용할 수 없음**

잘못된 코드:
```bash
jq ".statistics.total_switches += 1 | .statistics.\${FROM_TO} += 1" "$PATTERN_FILE"
```

jq는 `${FROM_TO}`를 bash 변수로 인식하지 못하고 리터럴 문자열로 처리함.

## 해결 방법

### jq --arg 옵션 사용

```bash
jq --arg key "$FROM_TO" '.statistics.total_switches += 1 | .statistics[$key] += 1' "$PATTERN_FILE"
```

### 적용 파일

1. **소스 스크립트**: `scripts/install/03-brain-switch-api.sh` (switch.sh 생성 부분)
2. **배포된 스크립트**: `/gx10/api/switch.sh` (수동 수정 필요)

### 수동 수정 명령

```bash
# 배포된 switch.sh 수정
sudo sed -i 's/jq ".statistics.total_switches += 1 | .statistics.\\${FROM_TO} += 1"/jq --arg key "$FROM_TO" '"'"'.statistics.total_switches += 1 | .statistics[$key] += 1'"'"'/' /gx10/api/switch.sh
```

또는 Phase 3 재실행:
```bash
# 기존 API 파일 백업 후 재생성
./03-brain-switch-api.sh
```

## 검증

```bash
# Brain 전환 테스트
sudo /gx10/api/switch.sh code
sudo /gx10/api/switch.sh vision

# jq 오류 없이 전환 완료되어야 함
```

## 추가 수정 사항 (같은 세션)

### 이슈 2: PID null 오류

**증상**: `"pid": ,` (빈 값)으로 JSON 파싱 오류

**원인**: `pgrep -a "$TARGET_BRAIN"`이 프로세스를 찾지 못하면 빈 문자열 반환

**해결**:
```bash
# Brain별 PID 조회 로직
if [ "$TARGET_BRAIN" == "code" ]; then
  PID=$(pgrep -f "ollama" 2>/dev/null | head -1 || true)
elif [ "$TARGET_BRAIN" == "vision" ]; then
  PID=$(docker inspect -f '{{.State.Pid}}' gx10-vision-brain 2>/dev/null || true)
fi
PID="${PID:-null}"
```

### 이슈 3: Vision 컨테이너 충돌

**증상**: `docker: Error response from daemon: Conflict. The container name "/gx10-vision-brain" is already in use`

**원인**: 이전 실행에서 컨테이너가 남아있음

**해결**:
```bash
# Vision brain 시작 전 기존 컨테이너 제거
docker rm -f gx10-vision-brain 2>/dev/null || true
```

## 교훈

1. jq 내에서 bash 변수 사용 시 `--arg` 또는 `--argjson` 옵션 필수
2. 동적 키 접근은 `.$key`가 아닌 `.[$key]` 형식 사용
3. PID 조회 시 서비스별 적절한 명령어 사용 (systemd vs docker)
4. 컨테이너 시작 전 기존 컨테이너 정리 로직 필수
5. 배포 전 다양한 시나리오로 스크립트 테스트 필요

## 검증 결과

```
none → code: 5초 ✅
code → vision: 11초 ✅
vision → code: 17초 ✅
code → vision: 10초 ✅
```

## 관련 문서

- [jq Manual - --arg](https://stedolan.github.io/jq/manual/#Invokingjq)
- GX10-09-Two-Brain-Optimization.md
