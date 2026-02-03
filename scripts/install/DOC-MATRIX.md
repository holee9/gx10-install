# Installation Script Documentation Matrix

## Script to Requirement Mapping

| DOC-ID | Script | Reference | Requirements | Status |
|--------|--------|-----------|--------------|--------|
| DOC-SCR-000 | 00-install-all.sh | PRD.md Phase 1-5 | ALL | RELEASED |
| DOC-SCR-P0-001 | ~~01-initial-setup.sh~~ | PRD.md L1-1 | DGX-001 | Phase 0에 통합됨 |
| DOC-SCR-P0-002 | ~~02-directory-structure.sh~~ | PRD.md L1-2 | DGX-002 | Phase 0에 통합됨 |
| DOC-SCR-P0-003 | ~~03-environment-config.sh~~ | PRD.md L1-3 | DGX-003 | Phase 0에 통합됨 |
| DOC-SCR-P0-004 | ~~04-code-brain-install.sh~~ | PRD.md L2-1 | GX10-01 | Phase 0에 통합됨 |
| DOC-SCR-001 | 01-code-models-download.sh | PRD.md L2-2 | GX10-02, GX10-09-P0 | RELEASED |
| DOC-SCR-002 | 02-vision-brain-build.sh | PRD.md L3-1 | GX10-03 | RELEASED |
| DOC-SCR-003 | 03-brain-switch-api.sh | PRD.md L4-1 | GX10-04 | RELEASED |
| DOC-SCR-004 | 04-webui-install.sh | PRD.md L5-1 | GX10-05 | RELEASED |
| DOC-SCR-P0-009 | ~~09-service-automation.sh~~ | PRD.md L5-2 | GX10-06 | Phase 0에 통합됨 (삭제됨) |
| DOC-SCR-005 | 05-final-validation.sh | PRD.md L6-1 | GX10-07 | RELEASED |
| DOC-SCR-LIB-001 | lib/logger.sh | All scripts | Logging | RELEASED |
| DOC-SCR-LIB-002 | lib/state-manager.sh | All scripts | GX10-07-P0 | RELEASED |
| DOC-SCR-LIB-003 | lib/error-handler.sh | All scripts | SEC-001 | RELEASED |
| DOC-SCR-LIB-004 | lib/security.sh | All scripts | SEC-001, SEC-002 | RELEASED |

## Requirement Traceability

### Core Requirements (Phase 0에 통합됨)

- **DGX-001**: DGX OS 7.2.3 compatibility (~~01-initial-setup.sh~~ → 00-sudo-prereqs.sh)
- **DGX-002**: Directory structure creation (~~02-directory-structure.sh~~ → 00-sudo-prereqs.sh)
- **DGX-003**: Environment configuration (~~03-environment-config.sh~~ → 00-sudo-prereqs.sh)

### Functional Requirements

- **GX10-01**: Code Brain installation (~~04-code-brain-install.sh~~ → 00-sudo-prereqs.sh)
- **GX10-02**: Code model download (01-code-models-download.sh)
- **GX10-03**: Vision Brain build (02-vision-brain-build.sh)
- **GX10-04**: Brain switch API (03-brain-switch-api.sh)
- **GX10-05**: Open WebUI installation (04-webui-install.sh)
- **GX10-06**: Service automation (~~09-service-automation.sh~~ → 00-sudo-prereqs.sh, 삭제됨)
- **GX10-07**: System validation (05-final-validation.sh)

### Priority Requirements

- **GX10-07-P0**: Checkpoint system for error recovery
- **GX10-09-P0**: Memory optimization for models

### Security Requirements

- **SEC-001**: No hardcoded credentials in scripts
- **SEC-002**: HTTPS enforcement for web interfaces

## Version History

| DOC-ID | Version | Date | Changes | Author |
|--------|---------|------|---------|--------|
| DOC-SCR-000 | 2.0.0 | 2026-02-02 | Added error handling, security enhancements | Claude Sonnet 4.5 |
| DOC-SCR-001 | 1.0.0 | 2026-02-01 | Code models download (was 05-code-models-download.sh) | Claude Sonnet 4.5 |
| DOC-SCR-002 | 1.0.0 | 2026-02-01 | Vision Brain Docker build (was 06-vision-brain-build.sh) | Claude Sonnet 4.5 |
| DOC-SCR-003 | 1.0.0 | 2026-02-01 | Brain switch API (was 07-brain-switch-api.sh) | Claude Sonnet 4.5 |
| DOC-SCR-004 | 2.0.0 | 2026-02-02 | WebUI + HTTPS support (was 08-webui-install.sh) | Claude Sonnet 4.5 |
| DOC-SCR-005 | 2.0.0 | 2026-02-02 | Final validation + checkpoints (was 10-final-validation.sh) | Claude Sonnet 4.5 |

## Environment Variables

| Variable | Purpose | Script | Required |
|----------|---------|--------|----------|
| GX10_PASSWORD | Admin password for services | 04-webui-install.sh | Yes |
| GX10_HTTPS_PORT | HTTPS port for Open WebUI | 04-webui-install.sh | No (default: 443) |
| GX10_CHECKPOINT_DIR | Checkpoint storage location | lib/state-manager.sh | No (default: /gx10/runtime/state) |
| GX10_LOG_DIR | Log file directory | lib/logger.sh | No (default: /gx10/runtime/logs) |
| NONINTERACTIVE | Disable prompts for CI/CD | 00-install-all.sh | No |

## Security Features

| Feature | Implementation | Status |
|---------|----------------|--------|
| No hardcoded passwords | Interactive prompt or environment variable | RELEASED |
| HTTPS support | Self-signed SSL certificate on port 443 | RELEASED |
| Password validation | 12+ chars, mixed case, numbers, special chars | RELEASED |
| Credential storage | Secure file in /gx10/runtime/state/.credentials | RELEASED |
| HTTP to HTTPS redirect | Nginx configuration for port 8080 → 443 | RELEASED |

## Verification Commands

### Installation Verification

```bash
# Verify all scripts are executable
grep -r "^#!/bin/bash" scripts/install/*.sh | wc -l  # Expected: 7

# Check for hardcoded passwords (should be empty)
grep -r "password=" scripts/install/*.sh | grep -v "GX10_PASSWORD"

# Verify state manager implementation
test -f scripts/install/lib/state-manager.sh && echo "PASS" || echo "FAIL"

# Verify security features
grep -r "openssl" scripts/install/*.sh | wc -l  # Expected: >0
```

### Runtime Verification

```bash
# Verify all services are running
systemctl is-active ollama
docker ps | grep open-webui
docker ps | grep n8n

# Verify HTTPS access
curl -k https://localhost:443 | grep "Open WebUI"

# Verify checkpoint system
test -d /gx10/runtime/state/checkpoints && echo "PASS" || echo "FAIL"

# Verify log files
ls -la /gx10/runtime/logs/
```

## Recovery Procedures

| Scenario | Procedure | Command |
|----------|-----------|---------|
| Resume from failure | Automatic resume from last checkpoint | `./00-install-all.sh` |
| Manual rollback | Rollback to specific checkpoint | `/gx10/api/rollback.sh <checkpoint_id>` |
| Service restart | Restart failed service | `/gx10/api/restart.sh <service_name>` |
| Full reinstall | Clean install from scratch | `./00-install-all.sh --clean` |

## Documentation References

- **SRS**: [../../GX10_Project_Documents/SRS.md](../../GX10_Project_Documents/SRS.md) (DOC-SRS-001)
- **Installation Plan**: [../../GX10-07-Auto-Installation-Plan.md](../../GX10-07-Auto-Installation-Plan.md) (DOC-GX10-07)
- **Implementation Guide**: [../../GX10-03-Final-Implementation-Guide.md](../../GX10-03-Final-Implementation-Guide.md)
- **Memory Optimization**: [../../GX10-08-CodeBrain-Memory-Optimization.md](../../GX10-08-CodeBrain-Memory-Optimization.md) (DOC-GX10-08)
- **Two Brain Guide**: [../../GX10-09-Two-Brain-Optimization.md](../../GX10-09-Two-Brain-Optimization.md) (DOC-GX10-09)

## Status Definitions

- **RELEASED**: Production-ready, fully tested
- **BETA**: Feature-complete, in testing
- **EXPERIMENTAL**: Early development, may change
- **DEPRECATED**: No longer maintained

---

**Document Information**

**Document ID**: DOC-MATRIX-001
**Version**: 2.0.0
**Status**: RELEASED
**Last Updated**: 2026-02-02

**Author**:
- AI: Claude Sonnet 4.5
- Environment: MoAI-ADK v11.0.0

**Reviewer**:
- drake
---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0
- 작성일: 2026-02-02

**리뷰어**:

- drake

