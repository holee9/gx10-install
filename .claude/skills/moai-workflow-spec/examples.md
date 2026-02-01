# SPEC Workflow Examples

## Real-World SPEC Documents

This document provides complete, production-ready SPEC examples for common development scenarios.

---

## Example 1: User Authentication System (Simple CRUD)

```markdown
# SPEC-001: User Authentication System

Created: 2025-12-07
Status: Planned
Priority: High
Assigned: manager-ddd
Related SPECs: SPEC-002 (User Registration)
Epic: EPIC-AUTH
Estimated Effort: 8 hours
Labels: backend, security, high-priority, api
Version: 1.0.0

## Description

Implement JWT-based user authentication system with email/password login. Users authenticate with credentials, receive JWT access token and refresh token, and use tokens to access protected resources.

### User Stories
- As a user, I want to log in with email and password to access my account
- As a user, I want my session to persist for 24 hours without re-login
- As a system admin, I want failed login attempts logged for security monitoring

## Requirements

### Ubiquitous
- 시스템은 항상 로그인 시도를 로깅해야 한다 (timestamp, user_id, IP, success/failure)
- 시스템은 항상 비밀번호를 bcrypt로 해싱하여 저장해야 한다 (salt rounds: 12)
- 시스템은 항상 토큰 검증 실패 시 명확한 에러 메시지를 반환해야 한다

### Event-Driven
- WHEN 사용자가 유효한 자격증명으로 로그인하면 THEN JWT 액세스 토큰과 리프레시 토큰을 발급한다
- WHEN 액세스 토큰이 만료되면 THEN 리프레시 토큰으로 새 액세스 토큰을 발급한다
- WHEN 로그인 실패가 5회 연속 발생하면 THEN 계정을 15분간 일시 잠금한다
- WHEN 사용자가 로그아웃하면 THEN 해당 세션의 리프레시 토큰을 무효화한다

### State-Driven
- IF 계정 상태가 "active"이면 THEN 로그인을 허용한다
- IF 계정 상태가 "suspended" 또는 "deleted"이면 THEN 로그인을 거부하고 403 에러를 반환한다
- IF 로그인 실패 횟수가 5회 이상이면 THEN 계정 잠금 시간 종료까지 로그인을 차단한다
- IF 마지막 비밀번호 변경일로부터 90일이 지났으면 THEN 비밀번호 변경을 요구한다

### Unwanted
- 시스템은 평문 비밀번호를 데이터베이스에 저장하지 않아야 한다
- 시스템은 비밀번호를 로그 파일에 기록하지 않아야 한다
- 시스템은 인증되지 않은 사용자의 보호된 리소스 접근을 허용하지 않아야 한다
- 시스템은 만료된 토큰으로 리소스 접근을 허용하지 않아야 한다

### Optional
- 가능하면 OAuth 2.0 소셜 로그인(Google, GitHub)을 제공한다
- 가능하면 이중 인증(2FA, TOTP)을 지원한다
- 가능하면 "Remember Me" 기능으로 30일간 자동 로그인을 제공한다

## API Specification

### POST /api/auth/login

Request:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "rememberMe": false
}
```

Success Response (200 OK):
```json
{
  "accessToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 86400,
  "tokenType": "Bearer",
  "user": {
    "id": 12345,
    "email": "user@example.com",
    "role": "user",
    "lastLogin": "2025-12-07T10:00:00Z"
  }
}
```

Error Responses:

401 Unauthorized - Invalid Credentials:
```json
{
  "error": "INVALID_CREDENTIALS",
  "message": "Email or password is incorrect",
  "timestamp": "2025-12-07T10:00:00Z"
}
```

403 Forbidden - Account Locked:
```json
{
  "error": "ACCOUNT_LOCKED",
  "message": "Account temporarily locked due to multiple failed login attempts",
  "lockUntil": "2025-12-07T10:15:00Z",
  "timestamp": "2025-12-07T10:00:00Z"
}
```

403 Forbidden - Account Suspended:
```json
{
  "error": "ACCOUNT_SUSPENDED",
  "message": "Account has been suspended. Contact support for assistance",
  "timestamp": "2025-12-07T10:00:00Z"
}
```

400 Bad Request - Validation Error:
```json
{
  "error": "VALIDATION_ERROR",
  "message": "Request validation failed",
  "details": [
    {"field": "email", "issue": "Invalid email format"},
    {"field": "password", "issue": "Password is required"}
  ],
  "timestamp": "2025-12-07T10:00:00Z"
}
```

### POST /api/auth/refresh

Request:
```json
{
  "refreshToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

Success Response (200 OK):
```json
{
  "accessToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 86400,
  "tokenType": "Bearer"
}
```

### POST /api/auth/logout

Request:
```
Headers:
  Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

Success Response (204 No Content)

## Constraints

### Technical Constraints
- Backend: Node.js 20+ with Express.js 4.18+
- Database: PostgreSQL 15+ for user credentials and session storage
- Authentication: JWT with RS256 algorithm (RSA public/private key pair)
- Password Hashing: bcrypt with salt rounds 12
- Token Storage: Redis 7+ for refresh token blacklist and rate limiting

### Business Constraints
- Session Timeout: 24 hours for standard users, 1 hour for admin users
- Password Policy:
  - Minimum 8 characters
  - At least 1 uppercase letter
  - At least 1 lowercase letter
  - At least 1 number
  - At least 1 special character (!@#$%^&*)
- Login Attempt Limit: 5 failures trigger 15-minute account lockout
- Password Rotation: Required every 90 days for compliance
- Concurrent Sessions: Maximum 3 active sessions per user

### Security Constraints
- OWASP Authentication Cheat Sheet compliance
- TLS 1.3 required for all authentication endpoints
- Rate Limiting: 10 login attempts per minute per IP adddess
- CORS: Whitelist approved frontend domains only
- Token Rotation: Access token 24h, refresh token 7 days

## Success Criteria

### Functional Criteria
- All EARS requirements implemented and verified
- All API endpoints return correct status codes and response schemas
- Test coverage >= 85% for authentication module
- All test scenarios pass with expected results

### Performance Criteria
- Login endpoint response time P95 < 200ms
- Token generation time < 50ms
- Password hashing time < 500ms
- Refresh token endpoint P95 < 100ms
- Concurrent login throughput >= 100 requests/second

### Security Criteria
- OWASP Top 10 vulnerabilities absent (verified by OWASP ZAP scan)
- No SQL injection vulnerabilities (verified by SQLMap)
- No plaintext passwords in database (verified by audit)
- All sensitive data encrypted at rest and in transit
- Security headers present (HSTS, CSP, X-Frame-Options)

## Test Scenarios

| ID | Category | Scenario | Input | Expected | Status |
|---|---|---|---|---|---|
| TC-1 | Normal | Valid login | email+password | JWT tokens, 200 | Pending |
| TC-2 | Normal | Token refresh | valid refresh token | new access token, 200 | Pending |
| TC-3 | Normal | Logout | valid access token | session invalidated, 204 | Pending |
| TC-4 | Error | Invalid password | wrong password | 401 error | Pending |
| TC-5 | Error | Nonexistent user | unknown email | 401 error | Pending |
| TC-6 | Error | Empty email | empty string | 400 error | Pending |
| TC-7 | Error | Invalid email format | "notanemail" | 400 error | Pending |
| TC-8 | Error | Expired access token | expired token | 401 error | Pending |
| TC-9 | Error | Revoked refresh token | blacklisted token | 401 error | Pending |
| TC-10 | State | Suspended account | valid credentials | 403 error | Pending |
| TC-11 | State | Deleted account | valid credentials | 403 error | Pending |
| TC-12 | State | Account lockout | 5 failed attempts | 403 error, locked 15min | Pending |
| TC-13 | State | Lockout expiry | after 15min wait | login succeeds | Pending |
| TC-14 | Security | SQL injection | ' OR '1'='1 | 400 error, blocked | Pending |
| TC-15 | Security | XSS in password | <script>alert(1)</script> | sanitized, blocked | Pending |
| TC-16 | Security | Rate limit | 11 requests/min | 429 error | Pending |
| TC-17 | Performance | Concurrent logins | 100 req/sec | < 200ms P95 | Pending |
| TC-18 | Performance | Token refresh load | 500 req/sec | < 100ms P95 | Pending |

## Implementation Notes

### Database Schema

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'user',
  account_status VARCHAR(50) DEFAULT 'active',
  failed_login_attempts INT DEFAULT 0,
  locked_until TIMESTAMP NULL,
  last_password_change TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(account_status);
```

### Redis Schema

```
# Refresh token blacklist (for logout)
Key: blacklist:{refresh_token_jti}
Value: user_id
TTL: refresh_token_expiry

# Rate limiting
Key: ratelimit:login:{ip_adddess}
Value: attempt_count
TTL: 60 seconds

# Login failure tracking
Key: loginfail:{user_id}
Value: {attempts, locked_until}
TTL: 900 seconds (15 minutes)
```

### Environment Variables

```bash
# JWT Configuration
JWT_ACCESS_SECRET=<RSA_PRIVATE_KEY>
JWT_REFRESH_SECRET=<RSA_PRIVATE_KEY>
JWT_ACCESS_EXPIRY=24h
JWT_REFRESH_EXPIRY=7d

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname

# Redis
REDIS_URL=redis://localhost:6379

# Security
BCRYPT_SALT_ROUNDS=12
RATE_LIMIT_WINDOW=60
RATE_LIMIT_MAX_REQUESTS=10
```

## Migration Plan

1. Create database tables and indexes
2. Set up Redis for session management
3. Generate RSA key pair for JWT signing
4. Implement password hashing utility
5. Implement JWT generation and validation
6. Implement login endpoint with validation
7. Implement token refresh endpoint
8. Implement logout with token blacklist
9. Add rate limiting middleware
10. Add security headers middleware
11. Write unit tests (target 85% coverage)
12. Write integration tests for API endpoints
13. Run security audit (OWASP ZAP, SQLMap)
14. Performance testing (load test with 100 req/sec)
15. Documentation generation

## References

- OWASP Authentication Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- JWT RFC 7519: https://tools.ietf.org/html/rfc7519
- bcrypt Algorithm: https://en.wikipedia.org/wiki/Bcrypt
- Redis Best Practices: https://redis.io/docs/manual/
```

---

## Example 2: Payment Processing API (Complex Workflow)

```markdown
# SPEC-005: Payment Processing Workflow

Created: 2025-12-07
Status: Planned
Priority: High
Assigned: manager-ddd
Related SPECs: SPEC-003 (Order Management), SPEC-006 (Refund System)
Epic: EPIC-PAYMENT
Estimated Effort: 16 hours
Labels: backend, payment, critical, workflow
Version: 1.0.0

## Description

Process payment for orders with comprehensive error handling, rollback mechanisms, and third-party payment gateway integration (Stripe, PayPal). Implements idempotent payment processing with precondition validation and multi-step side effect management.

### Preconditions
1. Order must exist in "pending_payment" status
2. Payment method must be registered and validated
3. User account balance sufficient for payment amount
4. All order items must be in stock and purchasable
5. Order total must match payment amount (fraud prevention)

### Side Effects
1. Deduct payment amount from user account or charge payment method
2. Update order status from "pending_payment" to "paid"
3. Create payment record in payment_transactions table
4. Create refund eligibility record (policy: 30 days)
5. Add order to fulfillment queue for shipping
6. Send notification to seller
7. Send confirmation email to buyer
8. Generate invoice PDF and store in object storage
9. Update inventory levels for purchased items
10. Create accounting journal entry for revenue recognition

## Requirements

### Ubiquitous
- 시스템은 항상 결제 시도를 감사 로그에 기록해야 한다 (user_id, order_id, amount, timestamp, result)
- 시스템은 항상 결제 금액과 주문 금액의 일치를 검증해야 한다
- 시스템은 항상 idempotency key를 검증하여 중복 결제를 방지해야 한다

### Event-Driven
- WHEN 결제 요청이 수신되면 THEN 모든 사전 조건을 검증한다
- WHEN 사전 조건 검증이 통과하면 THEN 결제 게이트웨이를 호출한다
- WHEN 결제가 성공하면 THEN 모든 부작용을 순차적으로 실행한다
- WHEN 부작용 실행 중 오류가 발생하면 THEN 롤백 프로세스를 시작한다
- WHEN 결제가 완료되면 THEN 구매자와 판매자에게 알림을 전송한다

### State-Driven
- IF 주문 상태가 "pending_payment"이면 THEN 결제를 허용한다
- IF 주문 상태가 "paid", "cancelled", "refunded"이면 THEN 결제를 거부한다
- IF 재고가 충분하면 THEN 결제를 진행한다
- IF 재고가 부족하면 THEN 결제를 거부하고 주문을 취소한다
- IF 동일한 idempotency key로 이전 결제가 있으면 THEN 이전 결과를 반환한다

### Unwanted
- 시스템은 사전 조건 검증 없이 결제를 처리하지 않아야 한다
- 시스템은 중복 결제를 허용하지 않아야 한다 (idempotency 보장)
- 시스템은 결제 실패 시 부분적인 부작용 실행을 허용하지 않아야 한다 (원자성 보장)
- 시스템은 민감한 결제 정보(카드 번호, CVV)를 저장하지 않아야 한다 (PCI DSS 준수)

### Optional
- 가능하면 결제 시 할인 쿠폰 적용을 지원한다
- 가능하면 포인트 적립 및 사용을 지원한다
- 가능하면 무이자 할부 옵션을 제공한다

## API Specification

### POST /api/orders/{orderId}/payment

Request:
```json
{
  "paymentMethodId": "pm_visa_1234",
  "amount": {
    "value": 149900,
    "currency": "KRW"
  },
  "captureFullAmount": true,
  "idempotencyKey": "order_123_payment_1",
  "metadata": {
    "couponCode": "WELCOME10",
    "usePoints": 1000
  }
}
```

Success Response (200 OK):
```json
{
  "orderId": "order_123abc",
  "paymentId": "payment_456def",
  "status": "paid",
  "amount": {
    "value": 149900,
    "currency": "KRW",
    "paid": 148900,
    "discount": 1000
  },
  "paymentMethod": {
    "id": "pm_visa_1234",
    "type": "card",
    "last4": "4242",
    "brand": "visa"
  },
  "transactions": [
    {
      "id": "txn_789ghi",
      "type": "payment",
      "amount": 148900,
      "status": "succeeded",
      "gateway": "stripe",
      "gatewayTransactionId": "ch_1ABC2DEF3GHI",
      "createdAt": "2025-12-07T10:00:00Z"
    }
  ],
  "refundPolicy": {
    "eligible": true,
    "expiresAt": "2026-01-06T10:00:00Z"
  },
  "invoice": {
    "id": "inv_2025_001234",
    "url": "https://cdn.example.com/invoices/inv_2025_001234.pdf"
  },
  "createdAt": "2025-12-07T10:00:00Z"
}
```

Error Responses:

400 Bad Request - Precondition Failed:
```json
{
  "error": "PRECONDITION_FAILED",
  "message": "Payment cannot be processed due to failed preconditions",
  "details": [
    {"check": "order_status", "expected": "pending_payment", "actual": "paid"},
    {"check": "inventory", "expected": "available", "actual": "out_of_stock"}
  ]
}
```

402 Payment Required - Insufficient Funds:
```json
{
  "error": "INSUFFICIENT_FUNDS",
  "message": "Payment method has insufficient funds",
  "required": 149900,
  "available": 100000
}
```

409 Conflict - Duplicate Payment:
```json
{
  "error": "DUPLICATE_PAYMENT",
  "message": "Payment with this idempotency key already processed",
  "originalPaymentId": "payment_456def",
  "originalPayment": { /* original payment response */ }
}
```

## Constraints

### Technical Constraints
- Backend: Node.js 20+ with NestJS framework
- Database: PostgreSQL 15+ with transaction support
- Payment Gateways: Stripe, PayPal SDK integration
- Message Queue: RabbitMQ for async notifications and fulfillment
- Object Storage: AWS S3 for invoice PDFs

### Business Constraints
- Payment Gateway Fees: 2.9% + $0.30 per transaction (Stripe)
- Transaction Timeout: 30 seconds maximum processing time
- Refund Window: 30 days from payment date
- Maximum Transaction: $10,000 per payment
- Daily Limit: $50,000 per user account

### Security Constraints
- PCI DSS Level 1 compliance (no card data storage)
- TLS 1.3 required for all payment endpoints
- Rate Limiting: 10 payment attempts per hour per user
- 3D Secure authentication for high-value transactions (> $500)
- Fraud detection: Block suspicious patterns (velocity, geography)

## Success Criteria

### Functional Criteria
- All preconditions validated before payment processing
- All side effects executed in correct order
- Rollback mechanism tested for all failure points
- Idempotency verified with duplicate requests
- Test coverage >= 90% for payment module

### Performance Criteria
- Payment processing P95 < 2000ms (includes gateway roundtrip)
- Precondition validation < 200ms
- Side effect execution < 500ms per step
- Rollback execution < 1000ms

### Security Criteria
- PCI DSS compliance verified by QSA audit
- No sensitive payment data in logs or database
- All transactions encrypted end-to-end
- Fraud detection catches 99% of known attack patterns

## Test Scenarios

| ID | Category | Scenario | Input | Expected | Status |
|---|---|---|---|---|---|
| TC-1 | Normal | Valid payment | valid order+payment | payment succeeds, 200 | Pending |
| TC-2 | Normal | Payment with coupon | coupon code | discount applied | Pending |
| TC-3 | Normal | Idempotent retry | same idempotency key | same result, 200 | Pending |
| TC-4 | Error | Order not pending | paid order | 400 precondition failed | Pending |
| TC-5 | Error | Insufficient stock | out of stock item | 400 precondition failed | Pending |
| TC-6 | Error | Amount mismatch | wrong amount | 400 validation error | Pending |
| TC-7 | Error | Insufficient funds | balance too low | 402 payment required | Pending |
| TC-8 | Error | Gateway timeout | slow gateway | 504 gateway timeout | Pending |
| TC-9 | Rollback | Side effect failure | DB error | payment rolled back | Pending |
| TC-10 | Rollback | Gateway decline | card declined | no side effects | Pending |
| TC-11 | Security | PCI data exposure | card number | masked, not stored | Pending |
| TC-12 | Security | Rate limit | 11 payments/hour | 429 too many requests | Pending |
| TC-13 | Performance | Concurrent payments | 50 req/sec | < 2000ms P95 | Pending |

## Rollback Strategy

### Rollback Triggers
- Payment gateway returns decline or error
- Database transaction fails during side effects
- Notification service unavailable (optional, compensate later)
- Inventory update fails (race condition)

### Rollback Steps
1. If payment charged: Initiate automatic refund via gateway
2. Revert order status to "pending_payment"
3. Delete payment transaction record
4. Restore inventory levels if decremented
5. Remove from fulfillment queue if added
6. Log rollback event with full context
7. Notify user of payment failure

### Compensating Transactions
- Async notifications: Retry with exponential backoff (not rollback trigger)
- Email delivery: Queue for retry, not critical path
- Invoice generation: Regenerate on-demand, not rollback trigger

## Implementation Notes

### Database Schema

```sql
CREATE TABLE payment_transactions (
  id SERIAL PRIMARY KEY,
  order_id INT REFERENCES orders(id),
  user_id INT REFERENCES users(id),
  amount INT NOT NULL,
  currency VARCHAR(3) DEFAULT 'KRW',
  status VARCHAR(50) NOT NULL,
  gateway VARCHAR(50) NOT NULL,
  gateway_transaction_id VARCHAR(255),
  idempotency_key VARCHAR(255) UNIQUE,
  payment_method_id VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_payments_order ON payment_transactions(order_id);
CREATE INDEX idx_payments_idempotency ON payment_transactions(idempotency_key);
```

### State Machine

```
pending_payment → [precondition check] → validating
validating → [gateway call] → processing
processing → [success] → paid
processing → [failure] → failed → [rollback] → pending_payment
paid → [refund request] → refunding → refunded
```
```

---

## Example 3: React Component Library (Frontend)

```markdown
# SPEC-010: Reusable Button Component Library

Created: 2025-12-07
Status: Planned
Priority: Medium
Assigned: expert-frontend
Related SPECs: SPEC-011 (Design System), SPEC-012 (Accessibility)
Epic: EPIC-UI
Estimated Effort: 4 hours
Labels: frontend, react, ui, component
Version: 1.0.0

## Description

Create comprehensive, accessible button component library for React 19 with TypeScript. Supports multiple variants (primary, secondary, outline, ghost), sizes (small, medium, large), states (default, hover, active, disabled, loading), and full WCAG 2.1 AA accessibility compliance.

## Requirements

### Ubiquitous
- 시스템은 항상 WCAG 2.1 AA 접근성 기준을 준수해야 한다
- 시스템은 항상 TypeScript 타입 안정성을 보장해야 한다
- 시스템은 항상 적절한 ARIA 속성을 제공해야 한다

### Event-Driven
- WHEN 버튼이 클릭되면 THEN onClick 핸들러를 실행한다
- WHEN 로딩 상태이면 THEN 클릭 이벤트를 차단한다
- WHEN 키보드 포커스를 받으면 THEN 포커스 링을 표시한다
- WHEN 비활성 상태이면 THEN 모든 인터랙션을 차단한다

### State-Driven
- IF variant가 "primary"이면 THEN 브랜드 색상 스타일을 적용한다
- IF variant가 "outline"이면 THEN 테두리 스타일을 적용한다
- IF size가 "small"이면 THEN 작은 패딩과 폰트 크기를 적용한다
- IF isLoading이 true이면 THEN 스피너를 표시하고 텍스트를 숨긴다

### Unwanted
- 시스템은 비활성 버튼의 클릭 이벤트를 발생시키지 않아야 한다
- 시스템은 접근성 속성 없이 버튼을 렌더링하지 않아야 한다
- 시스템은 키보드 내비게이션을 차단하지 않아야 한다

### Optional
- 가능하면 아이콘 버튼 변형을 제공한다
- 가능하면 버튼 그룹 컴포넌트를 제공한다
- 가능하면 다크 모드 자동 지원을 제공한다

## Component API

### Props Interface

```typescript
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  // Variant
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';

  // Size
  size?: 'small' | 'medium' | 'large';

  // States
  isLoading?: boolean;
  isDisabled?: boolean;
  isFullWidth?: boolean;

  // Content
  children: React.ReactNode;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;

  // Accessibility
  ariaLabel?: string;
  ariaDescribedBy?: string;

  // Events
  onClick?: (event: React.MouseEvent<HTMLButtonElement>) => void;

  // Styling
  className?: string;
  style?: React.CSSProperties;
}
```

### Usage Examples

```tsx
// Basic primary button
<Button variant="primary" onClick={handleClick}>
  Click Me
</Button>

// Loading state
<Button variant="primary" isLoading>
  Processing...
</Button>

// With icons
<Button variant="secondary" leftIcon={<Icon name="plus" />}>
  Add Item
</Button>

// Disabled state
<Button variant="outline" isDisabled>
  Unavailable
</Button>

// Full width
<Button variant="primary" isFullWidth>
  Submit Form
</Button>

// Custom accessibility
<Button
  variant="danger"
  ariaLabel="Delete user account permanently"
  ariaDescribedBy="delete-warning"
>
  Delete Account
</Button>
```

## Constraints

### Technical Constraints
- React: 19+ with React Server Components support
- TypeScript: 5.3+ with strict mode
- Styling: Tailwind CSS 4+ or CSS Modules
- Build: Vite 5+ for fast HMR
- Testing: Vitest + React Testing Library

### Design Constraints
- Color Palette: Must use design system tokens
- Typography: Inter font family, variable sizes
- Spacing: 4px grid system (padding: 8px, 12px, 16px)
- Border Radius: 6px for medium, 4px for small, 8px for large
- Transition: 150ms ease-in-out for all state changes

### Accessibility Constraints
- WCAG 2.1 AA compliance mandatory
- Color contrast ratio >= 4.5:1 for text
- Focus indicator visible and distinct (2px outline)
- Keyboard navigation full support (Tab, Enter, Space)
- Screen reader friendly with proper ARIA labels

## Success Criteria

### Functional Criteria
- All variants render correctly
- All sizes apply correct styles
- Loading and disabled states work as expected
- Event handlers execute correctly
- Icons render in correct positions

### Accessibility Criteria
- Passes axe-core automated accessibility audit
- Keyboard navigation works for all interactions
- Screen reader announces button purpose and state
- Color contrast meets WCAG AA requirements
- Focus indicators clearly visible

### Quality Criteria
- Test coverage >= 90% for component
- TypeScript strict mode with no errors
- Bundle size < 5KB (gzipped)
- Render performance < 16ms (60fps)
- Storybook documentation complete

## Test Scenarios

| ID | Category | Scenario | Input | Expected | Status |
|---|---|---|---|---|---|
| TC-1 | Render | Primary variant | variant="primary" | blue bg, white text | Pending |
| TC-2 | Render | Small size | size="small" | 8px padding, 14px font | Pending |
| TC-3 | State | Loading | isLoading=true | spinner visible, text hidden | Pending |
| TC-4 | State | Disabled | isDisabled=true | gray bg, no click | Pending |
| TC-5 | Event | Click handler | onClick={fn} | function called on click | Pending |
| TC-6 | Event | Disabled click | isDisabled + click | function not called | Pending |
| TC-7 | A11y | Keyboard focus | Tab key | focus ring visible | Pending |
| TC-8 | A11y | Enter key | Enter key | onClick called | Pending |
| TC-9 | A11y | Space key | Space key | onClick called | Pending |
| TC-10 | A11y | ARIA label | ariaLabel prop | screen reader announces | Pending |
| TC-11 | A11y | Color contrast | all variants | ratio >= 4.5:1 | Pending |
| TC-12 | Icon | Left icon | leftIcon prop | icon before text | Pending |
| TC-13 | Icon | Right icon | rightIcon prop | icon after text | Pending |

## Implementation Notes

### File Structure

```
src/components/Button/
├── Button.tsx              # Main component
├── Button.styles.ts        # Styled components or CSS modules
├── Button.types.ts         # TypeScript interfaces
├── Button.test.tsx         # Unit tests
├── Button.stories.tsx      # Storybook stories
├── Button.spec.cy.tsx      # Cypress component tests
└── index.ts                # Public exports
```

### Style Variants (Tailwind)

```typescript
const variantStyles = {
  primary: 'bg-blue-600 text-white hover:bg-blue-700 active:bg-blue-800',
  secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300 active:bg-gray-400',
  outline: 'border-2 border-blue-600 text-blue-600 hover:bg-blue-50',
  ghost: 'text-blue-600 hover:bg-blue-50 active:bg-blue-100',
  danger: 'bg-red-600 text-white hover:bg-red-700 active:bg-red-800'
};

const sizeStyles = {
  small: 'px-3 py-1.5 text-sm',
  medium: 'px-4 py-2 text-base',
  large: 'px-6 py-3 text-lg'
};

const baseStyles = 'inline-flex items-center justify-center font-medium rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed';
```

### Accessibility Implementation

```tsx
<button
  type="button"
  disabled={isDisabled || isLoading}
  aria-label={ariaLabel}
  aria-describedby={ariaDescribedBy}
  aria-busy={isLoading}
  className={cn(baseStyles, variantStyles[variant], sizeStyles[size])}
  onClick={handleClick}
  {...props}
>
  {leftIcon && <span className="mr-2">{leftIcon}</span>}
  {isLoading ? <Spinner /> : children}
  {rightIcon && <span className="ml-2">{rightIcon}</span>}
</button>
```

## Storybook Stories

```tsx
export default {
  title: 'Components/Button',
  component: Button,
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary', 'outline', 'ghost', 'danger']
    },
    size: {
      control: 'select',
      options: ['small', 'medium', 'large']
    }
  }
};

export const AllVariants = () => (
  <div className="space-x-2">
    <Button variant="primary">Primary</Button>
    <Button variant="secondary">Secondary</Button>
    <Button variant="outline">Outline</Button>
    <Button variant="ghost">Ghost</Button>
    <Button variant="danger">Danger</Button>
  </div>
);

export const AllSizes = () => (
  <div className="space-x-2">
    <Button size="small">Small</Button>
    <Button size="medium">Medium</Button>
    <Button size="large">Large</Button>
  </div>
);

export const LoadingStates = () => (
  <div className="space-x-2">
    <Button variant="primary" isLoading>Loading</Button>
    <Button variant="secondary" isLoading>Processing</Button>
  </div>
);
```
```

---

Version: 1.0.0
Last Updated: 2025-12-07
---

## 📝 문서 정보

**작성자**:

- AI: Claude Sonnet 4.5
- 환경: MoAI-ADK v11.0.0
- 작성일: 2026-02-01

**리뷰어**:

- drake

