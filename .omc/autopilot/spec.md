# GX10 Installation Scripts Enhancement - Specification

## Document Information

**Project**: GX10 Auto Installation Scripts Enhancement
**Version**: 1.0.0
**Status**: DRAFT
**Created**: 2026-02-01
**Author**: Claude Sonnet 4.5 (MoAI Autopilot)

---

## Executive Summary

Enhance the 10 installation scripts in `scripts/install/` to add standardized metadata, improve error handling, implement security hardening, and complete P0 optimizations from GX10-09.

---

## Requirements Analysis

### Functional Requirements

1. **Metadata Standardization**
   - All scripts MUST include DOC-ID, version, status
   - Standardized header template for consistency
   - Documentation traceability matrix

2. **Error Handling Framework**
   - Checkpoint mechanism for resuming failed installations
   - Rollback handlers for critical operations
   - State persistence between phases

3. **Security Hardening**
   - Remove hardcoded passwords (n8n, web UI)
   - Enforce password change on first login
   - HTTPS support for web interfaces
   - Port restriction options for firewall

4. **P0 Optimization Completion**
   - L3-1: Vision Brain quantization (INT8)
   - L3-2: Batch processing support
   - Memory stabilization improvements

5. **Documentation Traceability**
   - Each script linked to requirement documents
   - DOC-ID assignment matrix
   - Reference documentation links

### Non-Functional Requirements

- **Performance**: Installation time must not increase significantly
- **Reliability**: Failed installations must be recoverable
- **Security**: No default credentials in production state
- **Maintainability**: Consistent code structure across all scripts
- **Usability**: Clear error messages with recovery suggestions

### Implicit Requirements

- Scripts must be idempotent (safe to re-run)
- Pre-flight checks for disk space, GPU availability
- Network interruption handling for large downloads
- Port conflict detection and resolution

### Out of Scope

- P1/P2 optimizations from GX10-09 (defer to separate work)
- Comprehensive test suite (separate project)
- Advanced monitoring dashboards
- OAuth/SSO integration

---

## Technical Specification

### Architecture Overview

```
Enhancement Framework
├── Metadata Template (Standardized headers)
├── Error Handler Library (Checkpoint/Rollback)
├── Security Library (Password/credential utilities)
├── Logger Library (Standardized logging)
└── Documentation Matrix (Traceability)
```

### File Structure

```
scripts/install/
├── .templates/
│   └── script-header.sh          # Standardized metadata template
├── lib/
│   ├── error-handler.sh          # Rollback/resume framework
│   ├── security.sh               # Password/credential utilities
│   └── logger.sh                 # Standardized logging
├── DOC-MATRIX.md                 # Documentation traceability
├── README.md                     # Updated with new features
├── 00-install-all.sh             # Enhanced with checkpoint awareness
├── 01-initial-setup.sh           # DOC-SCR-001, security fixes
├── 02-directory-structure.sh     # DOC-SCR-002, checkpoint support
├── 03-environment-config.sh      # DOC-SCR-003, P0 optimized
├── 04-code-brain-install.sh      # DOC-SCR-004, integrity checks
├── 05-code-models-download.sh    # DOC-SCR-005, resume capability
├── 06-vision-brain-build.sh      # DOC-SCR-006, P0 quantization
├── 07-brain-switch-api.sh        # DOC-SCR-007, already P0 ready
├── 08-webui-install.sh           # DOC-SCR-008, HTTPS support
├── 09-service-automation.sh      # DOC-SCR-009, password prompt
└── 10-final-validation.sh        # DOC-SCR-010, enhanced validation
```

### Dependencies

- Bash 4.0+
- jq (JSON processing)
- Docker 24.x+
- systemd
- DGX OS 7.2.3 (or compatible Ubuntu 24.04)

---

## Implementation Plan

### Phase 1: Infrastructure (Priority: P0)

1. **Create Metadata Template** (`.templates/script-header.sh`)
   - Standardized DOC-ID format
   - Version and status fields
   - Reference documentation links

2. **Create Error Handler Library** (`lib/error-handler.sh`)
   - Checkpoint registration
   - Rollback handlers
   - State persistence

3. **Create Security Library** (`lib/security.sh`)
   - Password prompt utilities
   - Credential validation
   - HTTPS certificate generation

4. **Create Logger Library** (`lib/logger.sh`)
   - Standardized log format
   - Log levels (CRITICAL, ERROR, WARN, INFO, DEBUG)
   - Log rotation

### Phase 2: Script Enhancement (Priority: P0)

1. **Update All Script Headers**
   - Add DOC-ID (DOC-SCR-000 to DOC-SCR-010)
   - Add version and status
   - Add reference links

2. **Add Error Handling**
   - Integrate error-handler.sh
   - Add checkpoint calls
   - Implement rollback handlers

3. **Security Fixes**
   - Remove hardcoded passwords from 09-service-automation.sh
   - Add HTTPS support to 08-webui-install.sh
   - Add port restrictions to 01-initial-setup.sh

4. **P0 Optimizations**
   - Add Vision Brain quantization to 06-vision-brain-build.sh
   - Add batch processing support

### Phase 3: Documentation (Priority: P0)

1. **Create DOC-MATRIX.md**
   - Script to requirement mapping
   - DOC-ID assignment table
   - Status tracking

2. **Update README.md**
   - New error handling features
   - Security improvements
   - Recovery procedures

---

## Acceptance Criteria

### Installation Success Criteria

- All 10 phases complete without critical errors
- All services running: Ollama, Open WebUI, n8n, Vision Brain
- All models downloaded and listed
- Brain switch executes in < 30 seconds
- Installation report generated with no ERROR entries

### Script Quality Criteria

- 100% of scripts have complete metadata
- 100% of scripts have traceability to GX10 documents
- 0 hardcoded passwords in scripts
- All error messages include: problem, impact, suggested action

### Security Criteria

- First login forces password change
- All web interfaces support HTTPS
- No secrets in script files or logs

### Error Recovery Criteria

- Each phase can be re-run independently
- Resume capability works correctly
- Partial installation state is clearly communicated

---

## DOC-ID Assignment

| Script | DOC-ID | Status | Depends On |
|--------|--------|--------|------------|
| 00-install-all.sh | DOC-SCR-000 | RELEASED | 001-010 |
| 01-initial-setup.sh | DOC-SCR-001 | RELEASED | none |
| 02-directory-structure.sh | DOC-SCR-002 | RELEASED | 001 |
| 03-environment-config.sh | DOC-SCR-003 | RELEASED | 002 |
| 04-code-brain-install.sh | DOC-SCR-004 | RELEASED | 003 |
| 05-code-models-download.sh | DOC-SCR-005 | RELEASED | 004 |
| 06-vision-brain-build.sh | DOC-SCR-006 | RELEASED | 003 |
| 07-brain-switch-api.sh | DOC-SCR-007 | RELEASED | 004, 006 |
| 08-webui-install.sh | DOC-SCR-008 | RELEASED | 004 |
| 09-service-automation.sh | DOC-SCR-009 | RELEASED | 008 |
| 10-final-validation.sh | DOC-SCR-010 | RELEASED | 001-009 |

---

## Risk Assessment

### High Risk Items

- **Security**: Default credentials in scripts (MITIGATION: Remove, use prompts)
- **Data Loss**: No rollback mechanism (MITIGATION: Implement checkpoint system)
- **Recovery**: Partial installation failure (MITIGATION: Resume capability)

### Medium Risk Items

- **Performance**: Large model downloads (MITIGATION: Resume support)
- **Compatibility**: DGX OS version differences (MITIGATION: Pre-flight checks)

### Low Risk Items

- **Documentation**: Inconsistent metadata (MITIGATION: Template enforcement)
- **Maintainability**: Code duplication (MITIGATION: Library extraction)

---

## References

- `GX10-03-Final-Implementation-Guide.md` - Implementation details
- `GX10-09-Two-Brain-Optimization.md` - P0/P1 optimization requirements
- `scripts/install/README.md` - Current installation guide

---

## Change History

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2026-02-01 | 1.0.0 | Initial specification | Claude Sonnet 4.5 |

---

*End of Specification*
---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0
- 작성일: 2026-02-02

**리뷰어**:

- drake

