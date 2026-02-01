# JIT Documentation Loader Examples

실용적인 예시를 통해 Just-In-Time 문서 로딩 시스템의 활용 패턴을 학습합니다.

---

## Example 1: 기술 질문에 대한 JIT 문서 로딩

**Scenario**: 사용자가 FastAPI JWT 인증 구현 방법을 질문하는 상황

**Input**:
```python
# 사용자 질문
user_query = "FastAPI에서 JWT 인증을 어떻게 구현하나요?"

# JIT 스킬 호출
Skill("moai-workflow-jit-docs")
```

**Output**:
```python
# 1. Intent Analysis (의도 분석)
intent = {
    "technologies": ["FastAPI", "JWT"],
    "domains": ["authentication", "security"],
    "question_type": "implementation",
    "complexity": "medium",
    "urgency": "normal"
}

# 2. Source Prioritization (소스 우선순위)
sources = [
    ("local", 1.0),    # 프로젝트 문서 (최우선)
    ("official", 0.9), # FastAPI 공식 문서
    ("community", 0.7) # 고품질 커뮤니티 리소스
]

# 3. Loaded Documentation (로드된 문서)
docs_loaded = [
    {
        "source": "FastAPI Official",
        "title": "Security - OAuth2 with JWT tokens",
        "url": "https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/",
        "relevance": 0.95
    },
    {
        "source": "Project Local",
        "title": ".moai/docs/authentication-patterns.md",
        "relevance": 0.88
    },
    {
        "source": "Community",
        "title": "FastAPI JWT Best Practices 2025",
        "relevance": 0.82
    }
]

# 4. Quality Assessment (품질 평가)
quality_report = {
    "authority_score": 0.90,   # 공식 문서 포함
    "recency_score": 0.85,     # 최신 버전 기준
    "completeness_score": 0.88, # 코드 예시 포함
    "overall_score": 0.88
}
```

**Explanation**: JIT 시스템은 사용자 질문을 분석하여 기술 스택(FastAPI, JWT)과 도메인(인증, 보안)을 식별합니다. 그 후 로컬 프로젝트 문서 → 공식 문서 → 커뮤니티 순으로 우선순위를 정해 관련 문서를 로드합니다.

---

## Example 2: 성능 트러블슈팅 문서 로딩

**Scenario**: PostgreSQL 쿼리 성능 문제 해결을 위한 문서 로딩

**Input**:
```python
# 사용자 질문
user_query = "PostgreSQL 쿼리가 느려요. 어떻게 최적화하나요?"

# Intent Detection (의도 감지)
intent = analyze_user_intent(user_query, project_context)
```

**Output**:
```python
# 의도 분석 결과
intent = {
    "technologies": ["PostgreSQL"],
    "domains": ["database", "performance", "optimization"],
    "question_type": "troubleshooting",
    "complexity": "high",
    "urgency": "high"  # 성능 문제는 긴급
}

# 문서 로딩 전략
loading_strategy = {
    "priority_sources": [
        "PostgreSQL Performance Tuning Guide (Official)",
        "EXPLAIN ANALYZE Usage Patterns",
        "Index Optimization Strategies"
    ],
    "cache_enabled": True,
    "real_time_search": True  # 최신 정보 필요
}

# 로드된 문서
performance_docs = [
    {
        "title": "PostgreSQL Query Optimization",
        "source": "PostgreSQL Official Docs",
        "key_topics": [
            "EXPLAIN ANALYZE usage",
            "Index types and selection",
            "Query planner statistics",
            "Connection pooling"
        ],
        "quality_score": 0.95
    },
    {
        "title": "Database Indexing Best Practices",
        "source": "Community (High-voted)",
        "key_topics": [
            "B-tree vs GIN vs GiST",
            "Partial indexes",
            "Covering indexes"
        ],
        "quality_score": 0.87
    },
    {
        "title": "pg_stat_statements Analysis",
        "source": "Web Search (2025)",
        "key_topics": [
            "Slow query identification",
            "Query pattern analysis"
        ],
        "quality_score": 0.82
    }
]

# 컨텍스트 보강
enriched_context = {
    "user_query": user_query,
    "loaded_docs": performance_docs,
    "actionable_steps": [
        "1. EXPLAIN ANALYZE로 실행 계획 분석",
        "2. pg_stat_statements로 느린 쿼리 식별",
        "3. 적절한 인덱스 추가 검토",
        "4. 쿼리 재작성 고려"
    ]
}
```

**Explanation**: 성능 문제는 긴급도가 높아 실시간 웹 검색을 포함합니다. EXPLAIN ANALYZE, 인덱스 전략, 쿼리 최적화 등 실제 문제 해결에 필요한 구체적인 문서를 로드합니다.

---

## Example 3: 새 기술 도입을 위한 포괄적 문서 로딩

**Scenario**: 기존 REST API 프로젝트에 GraphQL 도입을 검토하는 상황

**Input**:
```python
# 사용자 요청
user_query = "기존 REST API에 GraphQL을 추가하고 싶어요. 마이그레이션 가이드가 필요합니다."

# 프로젝트 컨텍스트
project_context = {
    "current_stack": ["FastAPI", "PostgreSQL", "React"],
    "api_type": "REST",
    "team_experience": {"graphql": "none"}
}
```

**Output**:
```python
# Multi-Source Documentation Loading
graphql_docs = {
    "official_docs": [
        {
            "title": "GraphQL Official Documentation",
            "url": "https://graphql.org/learn/",
            "topics": ["Basic concepts", "Schema design", "Queries and Mutations"]
        },
        {
            "title": "Strawberry GraphQL (Python)",
            "url": "https://strawberry.rocks/docs",
            "topics": ["Python integration", "FastAPI support", "Type safety"]
        }
    ],
    "migration_guides": [
        {
            "title": "REST to GraphQL Migration Patterns",
            "source": "Apollo Engineering Blog",
            "key_insights": [
                "Gradual migration strategy",
                "REST wrapper approach",
                "Schema-first design"
            ]
        },
        {
            "title": "GraphQL Federation for Microservices",
            "source": "Community Best Practices",
            "key_insights": [
                "Service decomposition",
                "Schema stitching",
                "Gateway patterns"
            ]
        }
    ],
    "performance_considerations": [
        {
            "title": "GraphQL Performance Optimization",
            "topics": [
                "DataLoader for N+1 prevention",
                "Query complexity analysis",
                "Persisted queries"
            ]
        }
    ],
    "security_guides": [
        {
            "title": "GraphQL Security Best Practices",
            "topics": [
                "Query depth limiting",
                "Rate limiting",
                "Authentication/Authorization"
            ]
        }
    ]
}

# Strategic Guidance (전략적 가이드)
migration_strategy = {
    "phase_1": {
        "name": "Preparation",
        "duration": "1-2 weeks",
        "tasks": [
            "GraphQL schema 설계 from existing REST endpoints",
            "팀 GraphQL 교육",
            "개발 환경 설정 (Strawberry + FastAPI)"
        ]
    },
    "phase_2": {
        "name": "Parallel Implementation",
        "duration": "2-4 weeks",
        "tasks": [
            "REST와 GraphQL 동시 운영",
            "주요 읽기 작업 GraphQL로 구현",
            "DataLoader 패턴 적용"
        ]
    },
    "phase_3": {
        "name": "Gradual Migration",
        "duration": "4-8 weeks",
        "tasks": [
            "프론트엔드 GraphQL 클라이언트 도입",
            "REST 엔드포인트 점진적 deprecation",
            "성능 모니터링 및 최적화"
        ]
    }
}
```

**Explanation**: 새 기술 도입 시 공식 문서, 마이그레이션 가이드, 성능 고려사항, 보안 가이드 등 포괄적인 문서를 로드합니다. 팀의 경험 수준을 고려하여 단계별 마이그레이션 전략도 제공합니다.

---

## Common Patterns

### Pattern 1: Intent Analysis (의도 분석)

사용자 질문에서 기술, 도메인, 질문 유형을 추출합니다.

```python
def analyze_user_intent(user_input: str, context: dict) -> dict:
    """사용자 의도 분석"""
    intent = {
        "technologies": extract_technologies(user_input),
        "domains": extract_domains(user_input),
        "question_type": classify_question(user_input),
        "complexity": assess_complexity(user_input),
        "urgency": determine_urgency(user_input)
    }
    return intent

# 질문 유형 분류
question_types = {
    "implementation": ["how to", "implement", "create", "build"],
    "troubleshooting": ["error", "not working", "slow", "problem"],
    "conceptual": ["what is", "explain", "difference between"],
    "best_practices": ["best way", "recommended", "pattern"]
}

# 긴급도 판단
urgency_indicators = {
    "high": ["error", "broken", "production", "urgent"],
    "normal": ["how to", "want to", "looking for"],
    "low": ["curious", "later", "someday"]
}
```

### Pattern 2: Source Prioritization (소스 우선순위)

문서 소스의 우선순위를 결정합니다.

```python
def prioritize_sources(intent: dict) -> list:
    """문서 소스 우선순위 결정"""
    priorities = []

    # 1. 로컬 프로젝트 문서 (항상 최우선)
    if has_local_docs():
        priorities.append(("local", 1.0))

    # 2. 공식 문서 (높은 신뢰도)
    for tech in intent["technologies"]:
        if official_docs.get(tech):
            priorities.append(("official", 0.9))

    # 3. 커뮤니티 리소스 (구현 예시)
    if intent["question_type"] == "implementation":
        priorities.append(("community", 0.7))

    # 4. 실시간 웹 검색 (최신 정보)
    if intent["urgency"] == "high" or needs_latest_info(intent):
        priorities.append(("web_search", 0.8))

    return sorted(priorities, key=lambda x: x[1], reverse=True)
```

### Pattern 3: Intelligent Caching (지능형 캐싱)

문서 캐시를 관리하여 성능을 최적화합니다.

```python
class DocumentationCache:
    """다단계 캐싱 시스템"""

    def __init__(self):
        self.session_cache = {}   # 세션 내 캐시
        self.project_cache = {}   # 프로젝트 캐시
        self.global_cache = {}    # 전역 캐시

    def get(self, key: str, context: dict) -> Optional[dict]:
        """컨텍스트 기반 캐시 조회"""
        # 세션 캐시 확인
        if key in self.session_cache:
            if self.is_relevant(key, context):
                return self.session_cache[key]

        # 프로젝트 캐시 확인
        if key in self.project_cache:
            if self.is_recent(self.project_cache[key], days=7):
                return self.project_cache[key]

        # 전역 캐시 확인
        if key in self.global_cache:
            if self.is_high_authority(self.global_cache[key]):
                return self.global_cache[key]

        return None

    def store(self, key: str, content: dict, level: str = "session"):
        """캐시 저장"""
        cache_entry = {
            "content": content,
            "timestamp": datetime.now(),
            "access_count": 0
        }

        if level == "session":
            self.session_cache[key] = cache_entry
        elif level == "project":
            self.project_cache[key] = cache_entry
        elif level == "global":
            self.global_cache[key] = cache_entry
```

---

## Anti-Patterns (피해야 할 패턴)

### Anti-Pattern 1: 모든 문서 미리 로딩

**Problem**: 세션 시작 시 모든 가능한 문서를 로드하여 토큰 낭비

```python
# 잘못된 예시 - 비효율적
def initialize_session():
    # 모든 기술 문서 미리 로드 (불필요!)
    load_all_fastapi_docs()
    load_all_react_docs()
    load_all_postgresql_docs()
    # → 토큰 예산 초과, 관련 없는 문서 로드
```

**Solution**: 필요할 때만 문서 로드 (JIT)

```python
# 올바른 예시 - JIT 로딩
def handle_user_query(query: str):
    # 의도 분석
    intent = analyze_intent(query)

    # 필요한 문서만 로드
    relevant_docs = load_relevant_docs(intent)

    # 캐시하여 재사용
    cache_docs(relevant_docs)
```

### Anti-Pattern 2: 품질 검증 생략

**Problem**: 검증 없이 모든 문서를 동등하게 취급

```python
# 잘못된 예시
def load_docs(query):
    results = web_search(query)
    return results  # 품질 검증 없이 반환
    # → 오래된 정보, 부정확한 내용 포함 가능
```

**Solution**: 품질 평가 후 필터링

```python
# 올바른 예시
def load_docs(query):
    results = web_search(query)

    # 품질 평가
    scored_results = []
    for result in results:
        score = assess_quality(result)
        if score >= 0.7:  # 품질 임계값
            scored_results.append((result, score))

    # 점수순 정렬
    return sorted(scored_results, key=lambda x: x[1], reverse=True)
```

### Anti-Pattern 3: 캐시 무효화 무시

**Problem**: 오래된 캐시 문서를 계속 사용

```python
# 잘못된 예시
class NaiveCache:
    def get(self, key):
        if key in self.cache:
            return self.cache[key]  # 유효성 검사 없음
        return None
```

**Solution**: TTL과 관련성 기반 캐시 관리

```python
# 올바른 예시
class SmartCache:
    def get(self, key, context):
        if key in self.cache:
            entry = self.cache[key]

            # TTL 확인
            if self.is_expired(entry):
                del self.cache[key]
                return None

            # 컨텍스트 관련성 확인
            if not self.is_relevant(entry, context):
                return None

            return entry["content"]
        return None

    def is_expired(self, entry):
        age = datetime.now() - entry["timestamp"]
        # 공식 문서는 30일, 커뮤니티는 7일
        ttl = timedelta(days=30) if entry["is_official"] else timedelta(days=7)
        return age > ttl
```

### Anti-Pattern 4: 단일 소스 의존

**Problem**: 하나의 소스에만 의존하여 정보 편향

```python
# 잘못된 예시
def get_docs(query):
    return web_search_only(query)
    # → 로컬 문서, 공식 문서 무시
```

**Solution**: 다중 소스 집계

```python
# 올바른 예시
def get_docs(query, intent):
    sources = []

    # 1. 로컬 프로젝트 문서
    local_docs = search_local_docs(query)
    sources.extend(local_docs)

    # 2. 공식 문서
    for tech in intent["technologies"]:
        official = get_official_docs(tech, query)
        sources.extend(official)

    # 3. 커뮤니티 리소스
    community = search_community(query)
    sources.extend(community)

    # 4. 웹 검색 (필요시)
    if intent["needs_latest"]:
        web_results = web_search(query)
        sources.extend(web_results)

    # 중복 제거 및 순위화
    return deduplicate_and_rank(sources)
```

---

## Quality Metrics

JIT 문서 로딩 품질 평가 기준:

| 메트릭 | 가중치 | 설명 |
|--------|--------|------|
| Authority | 30% | 공식 문서 = 1.0, 커뮤니티 = 0.7 |
| Recency | 25% | 6개월 이내 = 1.0, 1년 = 0.6 |
| Completeness | 25% | 코드 예시, 설명 포함 여부 |
| Relevance | 20% | 쿼리와의 관련성 점수 |

품질 임계값:
- 0.8 이상: 높은 신뢰도
- 0.6-0.8: 참고용
- 0.6 미만: 추가 검증 필요

---

Version: 1.0.0
Last Updated: 2025-12-06
---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0
- 작성일: 2026-02-01

**리뷰어**:

- drake

