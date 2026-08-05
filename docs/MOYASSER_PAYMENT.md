# Moyasser Payment Gateway — Full Workflow

## Configuration

### 1. VPS `site_config.json`

Add to `/home/dg/dev-b/sites/ftms.galaxylabs.online/site_config.json`:

```json
{
  "moyasser_secret_key": "sk_live_xxxxxxxxxxxx",
  "moyasser_webhook_secret": "moyasser2026"
}
```

Then restart bench:

```bash
bench restart
```

### 2. Frappe Desk → Integration Settings

| Field | Value |
|---|---|
| `payment_provider` | `Moyasser` |
| `payment_public_key` | Moyasser publishable key (`pk_...`) |
| `payment_webhook_secret` | Same as `moyasser_webhook_secret` |

### 3. Moyasser Dashboard

| Field | Value |
|---|---|
| Webhook URL | `https://ftms.galaxylabs.online/api/method/ftms.api.payment.payment_webhook` |
| Secret Token | `moyasser2026` |
| HTTP Method | POST |
| Events | All payment events selected |

---

## Payment Flow (End-to-End)

```
┌─────────────┐     ┌──────────────────┐     ┌──────────────┐
│  Flutter App │     │  Frappe Backend   │     │   Moyasser    │
│  (Wallet)    │     │  ftms.galaxy...   │     │   API         │
└──────┬───────┘     └────────┬─────────┘     └──────┬────────┘
       │                      │                      │
       │ 1. POST create_moyasser_payment               │
       │    {amount, currency, description}            │
       │─────────────────────>│                      │
       │                      │                      │
       │                      │ 2. POST /v1/payments  │
       │                      │    Basic auth: sk_... │
       │                      │──────────────────────>│
       │                      │                      │
       │                      │ 3. {id, url, status}  │
       │                      │<──────────────────────│
       │                      │                      │
       │ 4. {payment_id, payment_url}                  │
       │<─────────────────────│                      │
       │                      │                      │
       │ 5. launchUrl(payment_url)                     │
       │──────────────────────────────────────────────>│
       │                      │                      │
       │     [User pays on Moyasser checkout page]     │
       │                      │                      │
       │                      │ 6. Webhook POST        │
       │                      │    X-Moyaser-Signature│
       │                      │<──────────────────────│
       │                      │                      │
       │                      │ 7. Verify HMAC-SHA256 │
       │                      │ 8. Credit wallet      │
       │                      │ 9. Emit notification  │
       │                      │                      │
```

### Step Details

1. **User initiates**: Opens Wallet screen → "Top Up" → enters amount → selects "Moyasser" → "Proceed"
2. **Backend creates payment**: `create_moyasser_payment` calls Moyasser API `POST /v1/payments` with amount (in halalas), currency SAR, description
3. **Moyasser responds**: Returns `id`, payment URL (`source.transaction_url`), status
4. **Redirect to checkout**: `launchUrl(payment_url)` opens Moyasser hosted payment page in browser
5. **User pays**: Completes card/Mada/Apple Pay on Moyasser's secure page
6. **Webhook arrives**: Moyasser POSTs payment status to webhook URL with `X-Moyaser-Signature` header
7. **Verify signature**: `HMAC-SHA256(raw_body, webhook_secret)` compared against header
8. **Credit wallet**: `credit_wallet()` adds funds, creates `Payment Transaction` record
9. **Notification**: `emit_event("Payment Received")` sends in-app notification

### Idempotency
- Webhook checks `Payment Transaction.webhook_event_id` — duplicate events return `"already_processed"`
- `SELECT FOR UPDATE` not needed since webhook creates new doc

---

## Admin Test Credit

**Administrator only** — no real payment required:

```
POST /api/method/ftms.api.payment.test_credit_wallet
{ amount: 100, currency: "SAR", description: "Test credit" }
```

Directly credits wallet without going through Moyasser. Used for:
- Testing wallet balance display
- Verifying transaction history
- Pre-funding admin accounts for demo/testing

---

## Backend Files

| File | Purpose |
|---|---|
| `ftms/payments/moyaser.py` | Moyasser API client (create payment, verify webhook, get status) |
| `ftms/api/payment.py` | REST API endpoints + webhook handler |
| `ftms/wallet/service.py` | Wallet credit/debit logic |
| `ftms/config/service.py` | Integration Settings reader |

## Flutter Files

| File | Purpose |
|---|---|
| `lib/services/frappe_api_client.dart` | `createMoyasserPayment`, `paymentConfig`, `checkPaymentStatus` |
| `lib/screens/passenger/wallet_screen.dart` | Wallet UI with Top Up dialog, Moyasser option, admin test credit |

---

## Testing

```bash
# Check payment config (public)
curl https://ftms.galaxylabs.online/api/method/ftms.api.payment.payment_config

# Admin test credit (requires admin session)
bench --site ftms.galaxylabs.online execute ftms.api.payment.test_credit_wallet \
  --kwargs '{"amount":100,"description":"Test from CLI"}'

# Simulate webhook (with correct signature)
curl -X POST https://ftms.galaxylabs.online/api/method/ftms.api.payment.payment_webhook \
  -H "Content-Type: application/json" \
  -H "X-Moyaser-Signature: <hmac-sha256-of-body>" \
  -d '{"status":"paid","user":"galaxylab2020@gmail.com","amount":100,"payment_id":"test-123"}'
```
