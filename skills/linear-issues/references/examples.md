# Worked Examples

Four worked software-engineering issues in the canonical template, shown in
both **Open** (right after creation) and **Done** (after the PR merged and the
issue closed) states. Use these as ground truth when drafting new issues —
match the granularity, the title style, and the section depth of the example
closest to your situation.

Sources: [ENG-412](https://linear.app/<workspace>/issue/ENG-412) (bug),
[ENG-377](https://linear.app/<workspace>/issue/ENG-377) (feature),
[ENG-419](https://linear.app/<workspace>/issue/ENG-419) (research),
[ENG-405](https://linear.app/<workspace>/issue/ENG-405) (infra).

---

## Example 1 — Bug (ENG-412)

**Title:** Invalidate the permissions cache on role change to stop stale authz decisions

### At open

```markdown
**TL;DR:** Changing a user's role has no effect for up to 5 minutes — the permissions cache is only invalidated by its TTL, not on writes — so a demoted user keeps their old access until the entry expires.
**Resolution:** _(to be filled at close)_

---

## Context
**Background:** `authz-service` gates every API request against a per-user permission set. To keep the hot path off the database, it caches each user's resolved permissions in an in-process LRU with a 5-minute TTL.
**What's happening:** After an admin changes a user's role, the new permissions don't apply until the cached entry expires. The write path (`RoleService.updateRole`) updates the database but never evicts the cache, so reads keep returning the stale set for up to 5 minutes.
\```
2026-06-14T10:02:11Z role  user=u_8831 admin→member
2026-06-14T10:02:12Z authz user=u_8831 decision=ALLOW resource=billing.write   # still admin
2026-06-14T10:07:11Z authz user=u_8831 decision=DENY  resource=billing.write   # TTL expired
\```
**Why it matters:** A user demoted for cause keeps privileged access for up to 5 minutes — a security-relevant window, not just a UX lag.

## Repro
1. Grant a test user the `admin` role; make one request so their permissions get cached.
2. Demote them to `member` via `PATCH /users/{id}/role`.
3. Immediately call an admin-only endpoint as that user → still `200`, should be `403`.
4. Wait 5 minutes and retry → correctly `403`.

## Root cause
`RoleService.updateRole` (`src/authz/role_service.py:88`) commits the role change but never touches the cache. `PermissionCache` (`src/authz/cache.py`) only evicts on TTL expiry or LRU pressure — there is no write-through or explicit invalidation hook.

## Fix
- Add `PermissionCache.invalidate(user_id)` in `src/authz/cache.py` — removes the single user's entry; no-op if absent.
- Call it from `RoleService.updateRole` after the DB commit succeeds (`src/authz/role_service.py:94`), in the same request, so the next read misses and re-resolves.
- Scope: invalidate only the mutated user's key, not the whole cache, so unrelated users keep their warm entries.

## Verification
- [ ] Demote-then-immediately-call returns `403` with no TTL wait
- [ ] Unrelated users' cache entries survive a single-user role change (no full flush)
- [ ] Load test shows no measurable increase in DB reads on the hot path

## Links
- Related: [ENG-408](https://linear.app/<workspace>/issue/ENG-408) (add write-through invalidation to the shared cache wrapper — same root pattern)
```

### At close (the patch the skill applies)

Only these blocks change:

```markdown
**TL;DR:** Changing a user's role has no effect for up to 5 minutes — the permissions cache is only invalidated by its TTL, not on writes — so a demoted user keeps their old access until the entry expires.
**Resolution:** Added `PermissionCache.invalidate(user_id)` and call it from `RoleService.updateRole` after the DB commit; only the mutated user's key is evicted, so warm entries for other users are preserved.
```

```markdown
## Verification
- [x] Demote-then-immediately-call returns `403` with no TTL wait (`tests/authz/test_role_change.py::test_invalidates_on_demote`)
- [x] Unrelated users' entries survive a single-user change (`::test_scoped_invalidation`)
- [x] Load test flat on DB reads — hot-path p99 unchanged vs. baseline (run `lt-2026-06-15`)

## Links
- Related: [ENG-408](https://linear.app/<workspace>/issue/ENG-408) (write-through invalidation — bundled follow-up)
```

Notice: TL;DR and Context are untouched. The Repro, Root cause, and Fix
sections are also untouched (they captured the open-time understanding and
remain accurate). Only the Resolution line, Verification (boxes flipped +
evidence), and Links change. The PR is linked via Linear's GitHub integration,
not manually in the body.

---

## Example 2 — Feature (ENG-377)

**Title:** Add cursor pagination to `GET /events` to replace offset paging

### At open

```markdown
**TL;DR:** Add cursor-based pagination to the `GET /events` endpoint so clients can page stably through large result sets without the skipped or duplicated rows that offset paging produces under concurrent writes.
**Resolution:** _(to be filled at close)_

---

## Context
**Background:** `events-api` exposes `GET /events`, currently paginated with `?limit=&offset=`. Under write load the underlying set shifts between requests, so offset paging skips or duplicates rows.
**What's happening:** Two client teams building infinite-scroll views over the audit log (millions of rows) hit gaps and dupes with offset paging and asked for a stable cursor. Inputs: RFC `docs/rfcs/0042-cursor-pagination.md`.
**Why it matters:** Without stable paging, the audit UI shows missing and repeated events; two client teams are blocked on it.

## Scope
- New `?cursor=&limit=` params on `GET /events`
- Opaque base64 cursor encoding the `(created_at, id)` sort key
- Response envelope gains `next_cursor` (null on the last page)
- Keep `offset` working for one deprecation window

## Implementation
- Add a `Cursor` codec in `src/events/pagination.py` (encode/decode, tamper-evident)
- Change the query in `EventRepo.list` to `WHERE (created_at, id) < (:ts, :id) ORDER BY created_at DESC, id DESC LIMIT :n`
- Emit `next_cursor` from the last row of the returned page
- Keep the existing response envelope; add the field, don't break shape

## Out of scope
- Bidirectional (previous-page) cursors — forward-only for now
- Removing `offset` (separate deprecation issue)
- A `total_count` field — unbounded to compute at this scale

## Acceptance
- [ ] Paging with `cursor` returns every row exactly once across concurrent inserts
- [ ] `next_cursor` is null on the final page
- [ ] A tampered cursor returns `400`, not a 500 or a silently wrong page
- [ ] `offset` still works during the deprecation window

## Links
- Design: `docs/rfcs/0042-cursor-pagination.md`
```

### At close (the patch the skill applies)

```markdown
**TL;DR:** Add cursor-based pagination to the `GET /events` endpoint so clients can page stably through large result sets without the skipped or duplicated rows that offset paging produces under concurrent writes.
**Resolution:** Shipped forward-only cursor paging on `GET /events` — opaque `(created_at, id)` cursor via `src/events/pagination.py`, `next_cursor` in the envelope; `offset` retained for the deprecation window.
```

```markdown
## Acceptance
- [x] Paging with `cursor` returns every row exactly once across concurrent inserts (`tests/events/test_pagination.py::test_stable_under_writes`)
- [x] `next_cursor` is null on the final page (`::test_last_page_null_cursor`)
- [x] Tampered cursor returns `400` (`::test_tampered_cursor_400`)
- [x] `offset` still works — kept behind a deprecation warning header (`::test_offset_still_works`)

## Links
- Follow-ups: [ENG-390](https://linear.app/<workspace>/issue/ENG-390) (bidirectional cursors), [ENG-391](https://linear.app/<workspace>/issue/ENG-391) (remove `offset` after deprecation window)
```

---

## Example 3 — Research / spike (ENG-419, in-progress state)

**Title:** Spike: choose the session-cache backend — Redis vs in-process LRU

### At open

```markdown
**TL;DR:** Benchmark Redis against an in-process LRU for the session cache under our production read/write mix to decide which backend to standardize on before the multi-node rollout.
**Resolution:** _(to be filled at close)_

---

## Context
**Background:** `session-service` caches sessions in a per-process LRU. We're about to run several replicas behind a load balancer, where a per-process cache means low hit rates and sessions that differ across nodes.
**What's happening:** We need a decision — move to a shared Redis cache, or keep the per-process LRU with sticky sessions. This spike measures hit rate, p99 latency, and operational cost of each under production-like load.
**Why it matters:** The choice gates the multi-node rollout; picking wrong means either a latency regression (a network hop per lookup) or session inconsistency across nodes.

## Analysis goals
1. Hit rate: measure cache hit rate per backend under the production read/write mix at 1/3/5 replicas
2. Latency: p50/p99 for session lookup, cold and warm, for each backend
3. Failure behavior: what happens to sessions when the backend restarts or a node dies
4. Cost/ops: rough $/month and operational burden (backups, failover) of running Redis

## Methods
- Replay a captured 1-hour production traffic sample (`fixtures/session_trace.jsonl`) against each backend
- In-process: the existing `LRUCache(maxsize=50_000)`; Redis: single-node `redis:7`, then a 3-node cluster
- Drive load with the existing harness (`bench/run.py`), 3 runs each, report the median
- Hold replica count and traffic shape fixed across backends

## Deliverables
- Benchmark notebook + raw numbers → `bench/results/session_cache_2026_q3/`
- One-page decision doc with a recommendation → `docs/rfcs/0045-session-cache-backend.md`
- If Redis wins: a follow-up implementation issue with the rollout plan

## Acceptance
- [ ] All three replica counts benchmarked for both backends
- [ ] Decision doc merged with an explicit recommendation and the numbers behind it
- [ ] Any regression risks (e.g. network-hop latency) documented for the rollout

## Links
- Related: [ENG-401](https://linear.app/<workspace>/issue/ENG-401) (multi-node rollout epic — consumes this decision)
```

### Mid-flight update (UPDATE flow output, not close)

Linear's state field is set to `In Progress` via the API. The description body is unchanged — status narrative goes in comments, not the description.

---

## Example 4 — Infra (ENG-405)

**Title:** Create `service/worker` ECR repo and extend OIDC push role

### At open

```markdown
**TL;DR:** Unblock the new `worker` image lane in `org/service` by creating the `service/worker` ECR repository and extending the GitHub Actions OIDC push role to cover it.
**Resolution:** _(to be filled at close)_

---

## Context
**Background:** `service` is our backend monorepo; its CI builds and pushes a per-component Docker image to ECR. A new background-worker component is being added in `org/service#312`.
**What's happening:** The worker build lane fails on `docker push` because there's no `service/worker` ECR repository and the GitHub Actions OIDC role doesn't grant write to it.
**Why it matters:** Until the repo and IAM grant exist, the worker image can't publish and `org/service#312` stays blocked.

## Change
- Add `service/worker` to `org/terraform/aws/ecr.tf`, mirroring `service/api`
- Extend the GitHub OIDC push role's `ecr:PutImage` resource list to include `service/worker`
- Account `123456789012`, region `us-east-1`
- Full URI: `123456789012.dkr.ecr.us-east-1.amazonaws.com/service/worker`

## Blast radius
- Touches one Terraform module (`aws/ecr.tf`) and one IAM policy
- No effect on the existing `service/api` repo or its CI lane
- New repo starts empty; nothing depends on it until `org/service#312` ships
- Region/account unchanged

## Rollback
- Revert the Terraform PR; `terraform apply` deletes the (still-empty) repo and removes the IAM grant
- Safe even if the upstream PR has merged, because pushing to a deleted repo just fails the CI lane — no data loss

## Verification
- [ ] `terraform plan` shows only the expected `aws_ecr_repository.service_worker` + IAM update
- [ ] `aws ecr describe-repositories --repository-names service/worker` returns the new repo
- [ ] `org/service#312` CI lane succeeds at `docker push`

## Links
- Upstream: [org/service#312](https://github.com/org/service/pull/312)
```

### At close (the patch the skill applies)

```markdown
**TL;DR:** Unblock the new `worker` image lane in `org/service` by creating the `service/worker` ECR repository and extending the GitHub Actions OIDC push role to cover it.
**Resolution:** Added `service/worker` to `aws/ecr.tf` mirroring `service/api`; extended the OIDC role's `ecr:PutImage` resource list. Repo live; the `org/service#312` CI lane is unblocked.
```

```markdown
## Verification
- [x] `terraform plan` showed only the expected `aws_ecr_repository.service_worker` + IAM resource-list update
- [x] `aws ecr describe-repositories --repository-names service/worker` returns the repo (account 123456789012, region us-east-1)
- [x] `org/service#312` CI lane now succeeds at `docker push service/worker:latest`

## Links
- Upstream merged: [org/service#312](https://github.com/org/service/pull/312)
```

---

## What to copy from these examples

- **Title style** — verb-led, encodes the *fix* or *mechanism*, not just the symptom. "Invalidate the permissions cache on role change…" not "Authz broken."
- **Context structure** — three labeled lines: **Background** (plain-language — names what `authz-service` / `events-api` / `session-service` / the `service` repo *are*, so an outsider can follow), **What's happening** (the problem + inline evidence), **Why it matters** (impact up front). Each 1–2 sentences; never a dense paragraph.
- **TL;DR style** — one sentence, includes both the *what* and a hint at the *why-it-matters*. Stays unchanged at close.
- **Resolution style** — match the TL;DR's granularity. If the TL;DR is one sentence, the Resolution is 1–3 sentences. Don't write a paragraph.
- **Verification evidence** — every `[x]` has a one-line evidence note. "Test passed" alone is too thin; "Returns `403` with no TTL wait (`tests/authz/test_role_change.py`)" is right.
- **Out-of-scope discipline** — for features, list what's NOT included so reviewers don't ask. The pagination example is a model.
- **Blast radius + Rollback** — infra issues require these. They're what makes the difference between "I'll merge this on a Friday" and "I'll wait until Monday."
