---
name: Performance Issue
about: Report a performance regression, slow endpoint, or inefficient query
title: "perf: "
labels: ["performance", "needs-triage"]
assignees: ""
---

## Area Affected

<!-- Which part of the system is slow or inefficient? -->

- [ ] Authentication (`/api/v1/auth/`)
- [ ] Projects (`/api/v1/projects/`)
- [ ] Tasks (`/api/v1/tasks/`)
- [ ] Notes (`/api/v1/notes/`)
- [ ] Database query / Mongoose aggregation
- [ ] Middleware (sanitization, validation, RBAC)
- [ ] File upload / Multer
- [ ] Server startup / initialization
- [ ] Other: <!-- specify -->

**Affected endpoint(s):**

```
<!-- e.g. GET /api/v1/tasks/:projectId -->
```

---

## Current Behavior

<!-- Describe the observed performance problem. Include response times, memory usage, or CPU spikes where available. -->

---

## Expected Improvement

<!-- What response time, resource usage, or throughput would be acceptable? -->

---

## Reproduction Steps

```bash
# Example: reproduce with curl and measure response time
time curl -X GET http://localhost:3000/api/v1/tasks/:projectId \
  -H "Authorization: Bearer <token>"
```

1.
2.
3.

---

## Benchmark Results

<!-- Share before/after numbers if you have them. Include the tool used (e.g. autocannon, wrk, Artillery, or simple `time curl`). -->

| Metric         | Current | Expected |
| -------------- | ------- | -------- |
| Response time  |         |          |
| Requests/sec   |         |          |
| Memory usage   |         |          |
| CPU usage      |         |          |

---

## Profiling Information

<!-- If you have profiling output (Node.js `--inspect`, MongoDB slow query logs, Winston logs, etc.), paste or attach it here. -->

<details>
<summary>Profiling output / slow query logs</summary>

```
<!-- paste here -->
```

</details>

---

## Suspected Root Cause

<!-- Optional: If you have a hypothesis about the cause (e.g. missing MongoDB index, N+1 query, unoptimised aggregation pipeline, missing caching layer), describe it here. -->

---

## Additional Context

<!-- Environment details, dataset size, concurrent users, or other relevant context. -->

| Field           | Value                             |
| --------------- | --------------------------------- |
| Node.js version | <!-- e.g. v20.11.0 -->           |
| MongoDB version | <!-- e.g. 7.0 / Atlas tier -->    |
| Dataset size    | <!-- e.g. ~10k tasks, ~500 projects --> |
| `NODE_ENV`      | <!-- development / production --> |

---

## Checklist

- [ ] I can reproduce this performance issue consistently
- [ ] I have included response time measurements or profiling output
- [ ] I have checked whether the relevant MongoDB collections have appropriate indexes
- [ ] I have checked `logs/app.log` for slow query warnings
