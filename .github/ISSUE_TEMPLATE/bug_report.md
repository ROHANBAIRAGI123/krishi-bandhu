---
name: Bug Report
about: Report a reproducible defect in Project Camp Backend
title: "fix: "
labels: ["bug", "needs-triage"]
assignees: ""
---

## Summary

<!-- A clear, one-sentence description of the bug. -->

---

## Expected Behavior

<!-- What should happen? -->

---

## Actual Behavior

<!-- What actually happens? Include HTTP status codes and response bodies where relevant. -->

---

## Steps to Reproduce

<!-- Provide the exact sequence of steps needed to reproduce the bug. Be specific — include request method, endpoint, headers, and body where applicable. -->

1.
2.
3.

**Minimal reproduction (curl / Postman snippet):**

```bash
curl -X POST http://localhost:3000/api/v1/ \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## Environment

| Field          | Value                              |
| -------------- | ---------------------------------- |
| Node.js version | <!-- e.g. v20.11.0 -->            |
| npm version    | <!-- e.g. 10.2.4 -->              |
| MongoDB version | <!-- e.g. 7.0 / Atlas -->         |
| `NODE_ENV`     | <!-- development / production --> |
| OS             | <!-- e.g. macOS 14, Ubuntu 22.04 --> |
| Commit / Branch | <!-- e.g. `main`, SHA `abc1234` --> |

---

## Logs

<!-- Paste relevant output from `logs/app.log` or `logs/error.log`. Redact any credentials or PII. -->

<details>
<summary>Application logs</summary>

```
<!-- paste logs here -->
```

</details>

---

## Screenshots

<!-- If applicable, add screenshots or API response screenshots. -->

---

## Additional Context

<!-- Any other context about the problem — related issues, recent changes, etc. -->

---

## Checklist

- [ ] I have searched existing issues and this bug has not been reported before
- [ ] I can reproduce this bug consistently using the steps above
- [ ] I have included relevant logs and environment details
- [ ] I have redacted any sensitive data (passwords, tokens, emails) from this report
