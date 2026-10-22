# PCI Scope Assessment

## Recommended PCI Self-Assessment Questionnaire

This platform currently qualifies for **SAQ-A**.

### Why SAQ-A fits this platform

- Payment processing is fully outsourced to external payment providers and gateways.
- The backend does not store, process, or transmit full cardholder data (PAN, CVV, expiry) directly.
- All external payment gateways are configured with secure HTTPS endpoints, and tokenized payment flows are used.
- No card numbers, CVV values, or unmasked PANs are persisted in application data, logs, or database entities.

### Payment handling architecture

- External payment providers used include Flutterwave, Paystack, and Sudo Africa.
- The backend consumes provider APIs over HTTPS.
- Cardholder-related data is managed by the payment providers, not by this application.
- Sensitive operations are protected by authentication and RBAC.

### Conditions for SAQ-A

The platform is in scope for SAQ-A as long as:

- No full cardholder data is entered, transmitted, or stored by the application.
- All card acceptance and payment authorization are performed by third-party gateways.
- The platform maintains controls over administrative access, system security, and secure transport.

### When the scope changes to SAQ-D

If the platform later begins to:

- accept raw card PAN/CVV in backend services,
- store full cardholder data,
- process payments directly through its own infrastructure,

then the PCI scope must be elevated to **SAQ-D** and a full PCI compliance program will be required.

## Soroban Smart Contract Scope

Soroban contracts in this repository are reviewed for PCI relevance. Contracts that
move or escrow cardholder-derived funds are treated as in-scope for the controls
below, even though they never handle raw PAN/CVV data. Contracts that only
compute fees or route already-tokenized value are out-of-scope for cardholder data
but remain subject to the same smart contract controls.

### Contract classification

| Contract | Classification | Rationale |
| --- | --- | --- |
| `admin_auth` | In-scope | Gates privileged operations (including fund movement) via admin authentication; a compromise would affect escrowed cardholder funds. |
| `admin_timelock` | In-scope | Delays privileged admin actions, protecting escrowed funds from immediate unauthorized changes. |
| `batch_payments` | In-scope | Moves/escrows funds in batches; directly touches cardholder-derived value. |
| `fee_calculator` | Out-of-scope | Pure fee computation; no cardholder data and no fund custody. |
| `fee_distributor` | Out-of-scope | Distributes already-computed fees; no cardholder data stored or processed. |
| `liquidity_router` | Out-of-scope | Routes tokenized liquidity; no cardholder data handled. |

### Controls applied at the smart contract layer

- **Admin authentication** (`admin_auth`): privileged entry points require an
authenticated admin; unauthorized callers are rejected.
- **Timelock on admin actions** (`admin_timelock`): sensitive admin operations are
queued and delayed, giving operators a window to detect and cancel abuse.
- **Batch limits** (`batch_payments`): batch sizes/amounts are bounded to limit the
blast radius of a single transaction.
- **Fee tier access control** (`fee_calculator`, `fee_distributor`): fee tiers and
distribution are restricted to authorized callers.
- **Event emission**: state-changing operations emit events for auditability and
monitoring of fund movement.

### Date of last review

- **Last reviewed:** 2024-06-01
- **Next review due:** 2025-06-01
