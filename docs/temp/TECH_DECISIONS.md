# TECH_DECISIONS.md — Technology Re-evaluation for a Solo MERN Developer

> **Context shift:** ARCHITECTURE_SPEC.md was written for an abstract engineering team. This document re-evaluates every decision for **you** — a final-year CS student, MERN developer, solo maintainer, building a portfolio flagship.  
> **Rule:** Where this document disagrees with ARCHITECTURE_SPEC.md, this document's reasoning is explained. ARCHITECTURE_SPEC.md remains the architectural source of truth for *what* the system should look like. This document governs *how you personally should build it*.

---

## The honest starting position

You inherited a Flutter codebase you didn't write, in a language you don't know. The app has real technical merit (AR camera pipeline, offline sync, satellite imagery) and real technical debt (exposed database, no auth guard, plaintext passwords). You need to:

1. Fix the critical security defects (non-negotiable — you cannot put a compromised app in a portfolio)
2. Build the parts that demonstrate YOUR skills (backend API, web portal)
3. Learn enough Flutter to maintain what exists (not rewrite it)
4. Ship something production-quality within one semester (~16 weeks)

Your portfolio's job is to get you hired. Every technology choice below is evaluated against that goal.

---

## Decision 1: Mobile Framework — Flutter

### Why the previous reports said "keep Flutter"

The AR camera (2,400 lines of Dart with YUV buffer processing), ML Kit on-device translation, custom `CustomPainter` overlays, and the offline sync pipeline are all deeply Flutter-native. A React Native rewrite was estimated at 9–14 months for a team of 3.

### The question you should be asking

"I'm a MERN developer who doesn't know Dart. Should I rewrite this in React Native so I'm working in my own ecosystem?"

### Honest answer: No. Keep Flutter.

**Not because the previous reports told you to — but for different reasons than they gave.**

#### Reason 1: Time

You have ~16 weeks. A React Native rewrite is 9–14 months for an experienced team. For a solo developer learning React Native's native module system (which you'd need for the camera pipeline), you're looking at 6–8 months minimum to reach feature parity — and that's optimistic. You'd spend your entire final year rewriting and end up with an app that does what the current one already does.

#### Reason 2: The rewrite doesn't showcase your skills

You'd be converting Dart to JavaScript. That's translation, not creation. Your portfolio impact is zero — you can't claim you "built" the AR camera system; you ported it. An interviewer will ask "why did you rewrite a working app?" and the honest answer ("because I didn't know the language") is not impressive.

#### Reason 3: Flutter on your resume is a differentiator

"MERN stack developer" is the most common profile among Indian CS graduates in 2026. "MERN + Flutter + cross-platform system architect" is rare. You don't need to be a Flutter expert — you need to be competent enough to maintain and extend the app. That takes 3–4 weeks of focused learning, not a semester.

#### Reason 4: The work that matters is NOT in Flutter

The mobile app works. It has security defects, but the UI, camera, maps, and offline sync all function. The work that will make your portfolio shine is building the **backend API** (Express/Node — your wheelhouse) and the **web portal** (React/Next.js — your wheelhouse). The Flutter app becomes a client of the API you built. *You built the platform. The Flutter app consumes it.*

### What you should learn

| Dart/Flutter concept | Time to learn | Why you need it |
|---------------------|---------------|-----------------|
| Dart syntax (null safety, async/await, classes) | 3–4 days | It's similar to TypeScript. You'll read it faster than you think. |
| Widget tree + `build()` method | 2–3 days | Analogous to React components returning JSX |
| `ChangeNotifier` + `Provider` | 2–3 days | Analogous to React Context + useReducer |
| GoRouter | 1–2 days | Analogous to React Router |
| `pubspec.yaml` | 1 day | It's `package.json` for Dart |
| Running `flutter run`, hot reload | 1 day | Analogous to `npm run dev` |

**Total: ~2 weeks to be productive.** You won't be writing custom `CustomPainter` code — you'll be wiring screens to the new API, fixing the auth guard, and removing hardcoded data.

### Trade-offs you're accepting

- You're maintaining code in a language you're learning. Some changes will take longer than they would in JavaScript.
- You won't deeply understand the AR camera internals. That's fine — you don't need to modify them.
- Your Flutter code will be "competent maintainer" quality, not "expert architect" quality. For a portfolio project, that's acceptable.

### Alternatives considered

| Alternative | Why not |
|-------------|---------|
| React Native rewrite | 6–8 months solo, no net new functionality, doesn't showcase your skills |
| Expo (React Native) | Same timeline issues, plus Expo's managed workflow doesn't support the native camera module access this app needs |
| Drop mobile, build web-only | Loses the most impressive features (AR camera, offline sync, satellite maps). A web-only CRUD app is a weaker portfolio piece. |
| Flutter Web for everything | Canvas rendering is wrong for data tables. You also don't know Flutter. Building a web portal in Flutter means learning Flutter AND building the portal, vs. building the portal in React (which you already know). |

---

## Decision 2: Backend API

### What ARCHITECTURE_SPEC.md said

Standalone Node.js/Express API. Rejected Firebase Cloud Functions due to cold starts, connection pooling, and vendor lock-in.

### Challenging that for your context

The ARCHITECTURE_SPEC.md concerns are real for production government deployments. For you — a student building a portfolio project — the calculus is different:

| ARCHITECTURE_SPEC concern | Does it apply to you? |
|--------------------------|----------------------|
| Cold start latency | No — your portfolio won't have 50 concurrent officers. Cold starts at portfolio traffic are imperceptible. |
| MongoDB connection pooling | Minor — at your query volume, connection overhead is negligible. |
| Government on-premise hosting | No — you're deploying to Vercel/Railway/Render, not a government VM. |
| Vendor lock-in | Mildly relevant — but you're not building for 10-year government contracts. |

**However, the ARCHITECTURE_SPEC recommendation is still correct for you — for a different reason:** Express is your skill. Building an Express API is the fastest path for you AND the most valuable portfolio artifact. It demonstrates your core MERN competency applied to a real, complex domain.

### The real question: Express standalone vs. Next.js API routes

> [!IMPORTANT]
> **I disagree with ARCHITECTURE_SPEC.md here.** For a solo developer, running a separate Express server AND a separate Next.js server is two things to deploy, two things to monitor, two things that can break independently. Next.js API routes give you the backend co-located with the frontend — one deployment, one repo, one process.

**My recommendation for you: Use Next.js API routes for the backend.**

| Factor | Standalone Express | Next.js API Routes |
|--------|-------------------|-------------------|
| Deployment complexity | Two services (Express on Railway + Next.js on Vercel) | One service (Next.js on Vercel, or self-hosted) |
| Development experience | Two terminals, two `package.json`, two tsconfig | One project, one `npm run dev` |
| Code sharing | Types shared via monorepo or npm package | Types shared via import — same project |
| Portfolio presentation | "I built a REST API and a frontend" | "I built a full-stack application" |
| Scaling independence | API scales separately from frontend | Coupled — but irrelevant at your scale |
| Express middleware ecosystem | Full Express ecosystem | Next.js middleware is different but sufficient |
| Interview talking points | "I designed a decoupled microservices architecture" | "I designed a full-stack Next.js application with server-side API routes" |

**For enterprise: standalone Express is correct.** ARCHITECTURE_SPEC.md is right that decoupling the API from the frontend is better architecture. But you're not running an enterprise. You're one person trying to ship and maintain a system. One project is always easier to maintain than two.

**If you outgrow Next.js API routes**, extracting them into a standalone Express server is a well-documented migration path. Start simple, extract later.

### Alternatives considered

| Alternative | Assessment |
|-------------|------------|
| **NestJS** | More structured than Express (decorators, modules, DI). Impressive on a resume. But it's a framework you'd need to learn, and the Express knowledge you already have is directly applicable in Next.js API routes. Added learning curve without proportional gain for this project. |
| **tRPC** | End-to-end type safety between Next.js frontend and API. Genuinely excellent DX. But it only works if the Flutter app doesn't need the API — and it does. tRPC is not designed for cross-language clients. REST with TypeScript types is the right choice when Flutter (Dart) is also a consumer. |
| **Firebase Cloud Functions** | Zero-config deployment. But you're an Express developer — Cloud Functions abstracts away the thing you're good at. Your portfolio should demonstrate that skill, not hide it. |
| **Fastify** | Faster than Express, modern API. But Express is what you know, and the performance difference is irrelevant at your scale. Don't learn a new framework for a 5% throughput gain you'll never measure. |

### Trade-offs you're accepting

- Next.js API routes are coupled to the Next.js deployment. If you ever need to deploy the API separately (e.g., government hosting requirement), you'll need to extract routes into an Express server.
- Next.js API routes don't support WebSockets natively. If real-time features (live claim status updates) are needed later, you'd add a separate WebSocket server or use Server-Sent Events.
- You're trading architectural purity (decoupled services) for shipping speed (one project). This is the right trade for a solo student. Name the trade-off in interviews — that shows maturity.

---

## Decision 3: Web Portal Framework — Next.js

### What ARCHITECTURE_SPEC.md said

Next.js 15 with App Router. SSR for data pages, SSG for public pages, middleware for auth.

### Should you consider anything else?

**Plain React + Vite?**

You probably know React with Vite already. It's tempting. But:

- Vite SPAs don't do SSR/SSG. The premium calculator and PMFBY info pages should be publicly indexable (SSG). An SPA makes this harder.
- Vite SPAs don't have `middleware.ts`. You'd implement auth guards in every component — the same problem the Flutter app has now.
- Next.js App Router is the current industry standard for React applications. Not knowing it is a gap on your resume in 2026.

**Remix?**

Excellent data-loading model. But smaller ecosystem, fewer tutorials, fewer interview questions about it. Next.js is the safer career bet.

### Recommendation: Next.js 15, App Router

This aligns with ARCHITECTURE_SPEC.md. No change. Next.js is the right call for your skills, your career, and this project.

### Learning curve

You know React. Next.js App Router adds:
- Server Components (RSC) — the biggest mental model shift. ~3–5 days to internalize.
- File-based routing — trivial, learn in an hour.
- `middleware.ts` — learn as you implement auth. Half a day.
- Server Actions — optional, learn as needed.

**Total: ~1 week from React to productive Next.js.** This is one of the smallest learning investments in the project with one of the highest career returns.

### Career ROI

Next.js is the single highest-ROI technology on your resume for 2026 frontend/full-stack roles. Nearly every Indian product startup and service company building React applications is using or migrating to Next.js. Learning it for this project is not a cost — it's the point.

---

## Decision 4: Database — MongoDB

### What ARCHITECTURE_SPEC.md said

MongoDB Atlas as the sole database. Drop Firestore.

### Does this make sense for you?

**Absolutely.** MongoDB is the M in MERN. You already know it. The data is already there. The schemas are defined. The repositories are written (in Dart, but the query patterns translate directly to Mongoose or the Node.js MongoDB driver).

**Drop Firestore?** Yes. You'd be maintaining two databases with overlapping schemas and no sync mechanism. Firestore is used ad-hoc in 3 screens. When you build the API, those 3 screens will call your API instead — and your API talks to MongoDB.

### Should you consider anything else?

| Alternative | Assessment |
|-------------|------------|
| **PostgreSQL** | Relational, better for complex joins and reporting. But your data is already in MongoDB, your schemas are document-shaped (nested objects like `lossDetails`, `mlVerification`), and you already know MongoDB. Migration cost with zero benefit. |
| **Firestore only** (drop MongoDB) | Firestore has richer real-time capabilities (live listeners). But the MongoDB schema is far more developed (6 models with indices vs. 3 thin Firestore models), and you know MongoDB query patterns. |
| **Supabase (Postgres + Auth + Storage)** | All-in-one platform with generous free tier. Genuinely compelling for new projects. But migrating existing MongoDB data to Postgres AND learning Supabase is not worth it when MongoDB works and you know it. |
| **PlanetScale / Turso** | Modern serverless SQL options. Same objection: migration cost, SQL learning curve for document-shaped data, no benefit over what you have. |

### Recommendation: MongoDB Atlas, sole database, Mongoose ODM in the API

Use Mongoose in your Next.js API routes. The Dart `FarmerModel.toMap()` / `FarmerModel.fromMap()` patterns translate directly to Mongoose schemas. This is the fastest path.

### One addition: Use Mongoose, not the raw MongoDB driver

The raw `mongodb` Node.js driver works, but Mongoose gives you:
- Schema validation (catches data shape errors before they hit the database)
- Middleware (pre-save hooks for hashing, timestamps)
- Population (resolving references between collections)
- TypeScript integration via `mongoose.InferSchemaType`

You probably already know Mongoose. Use it.

---

## Decision 5: Authentication — Firebase Auth

### What ARCHITECTURE_SPEC.md said

Firebase Auth as the sole identity provider. Remove local `AuthService`.

### Should you consider alternatives?

| Alternative | Assessment |
|-------------|------------|
| **NextAuth.js (Auth.js v5)** | Excellent Next.js integration. Supports credentials, OAuth, magic links. But it's a separate identity system from what the Flutter app would use. You'd need to sync users between NextAuth and your database, or run NextAuth's session on both platforms. Firebase Auth works on both Flutter and web natively. |
| **Clerk** | Beautiful drop-in auth with UI components. But paid beyond free tier, and it's another vendor dependency. Firebase Auth free tier covers your needs. |
| **Supabase Auth** | Supabase Auth + GoTrue is solid. But you're not using Supabase for anything else. Adding Supabase Auth to a Firebase + MongoDB stack adds a third vendor for no reason. |
| **Roll your own** (JWT + bcrypt) | You could. You know how. But it takes 2–3 weeks to build properly (password reset flow, email verification, session management, token refresh, CSRF protection). Firebase Auth gives you all of this in a day. Your time is better spent on features. |

### Recommendation: Keep Firebase Auth

Firebase Auth is the right call. It works on both Flutter and Next.js. The free tier supports 10K monthly active users. Phone OTP (critical for Indian farmers) is built in. You configure it once and both clients use it.

### Implementation for you specifically

**Flutter side:** The app already has `firebase_auth` wired up. You just need to make it the *only* auth path and activate the GoRouter redirect.

**Next.js side:**
```
Login page → Firebase Client SDK (signInWithEmailAndPassword)
          → Get ID token
          → POST /api/auth/session (send ID token)
          → Verify with Firebase Admin SDK
          → Set HTTP-only session cookie
          → Redirect to /dashboard
```

This is ~100 lines of code total. Firebase's documentation for Next.js is thorough.

### Career ROI

Firebase Auth is ubiquitous in the Indian startup ecosystem. "I implemented Firebase Auth across Flutter and Next.js with session cookies and RBAC" is a strong interview answer.

---

## Decision 6: State Management (Flutter) — Provider vs. Riverpod

### What ARCHITECTURE_SPEC.md said

Keep Provider. Migrate to Riverpod when provider count exceeds 20.

### Challenging this for your context

> [!IMPORTANT]
> **I disagree with ARCHITECTURE_SPEC.md here — partially.** The threshold logic ("wait until 20 providers") makes sense for a team that already knows Provider. You're learning Flutter from scratch. You have a choice of which state management pattern to learn first.

**The case for learning Riverpod instead of Provider:**

- Riverpod doesn't depend on `BuildContext` for reading state. This means you can access state from anywhere (services, other providers, tests) without needing a widget tree. For a newcomer, this removes one of Flutter's most confusing concepts.
- Riverpod providers are globally declared and type-safe. No `context.read<T>()` where forgetting to register `T` in the ancestor tree gives a runtime error.
- Riverpod has better DevTools and testing support.
- Riverpod is the community-agreed "next step" after Provider. Learning it now means you skip the intermediate step.

**The case for keeping Provider:**

- The codebase already uses Provider. 7 providers are registered. The pattern works.
- Migrating to Riverpod means rewriting all 7 providers AND every `context.read<T>()` / `context.watch<T>()` call in every screen. That's a non-trivial refactor.
- You're not building new Flutter features — you're wiring existing screens to a new API. Provider is sufficient for this.
- Learning Provider first is simpler, and you need simple right now.

### Recommendation: Keep Provider

Despite Riverpod being technically superior, migrating the existing codebase is work that doesn't ship new functionality. You're time-constrained. Learn Provider (it'll take 2–3 days), use it to wire screens to your API, and move on. If you later build new Flutter features, consider Riverpod for those.

### Trade-off you're accepting

You're learning the "older" state management pattern. In interviews, if asked about Flutter state management, say: "The existing codebase uses Provider, which I maintained. For new features, I'd evaluate Riverpod for its compile-time safety and context-independence." That answer shows maturity.

---

## Decision 7: Image Storage — Cloudinary

### What ARCHITECTURE_SPEC.md said

Keep Cloudinary. Move the API secret to the backend.

### Should you consider alternatives?

| Alternative | Why / Why not |
|-------------|---------------|
| **Firebase Storage** | Already declared as a dependency (unused). Free 5 GB. But Cloudinary has image transformation (resize, crop, format conversion) built into the URL. Firebase Storage is raw blob storage — you'd need to build transformation yourself. Keep Cloudinary. |
| **AWS S3 + CloudFront** | Industry standard. But it's another vendor, another set of credentials, another SDK to learn. Cloudinary is already configured and working. |
| **Uploadthing** | Modern, Next.js-native file upload. But it doesn't serve the Flutter client. Cloudinary works for both. |

### Recommendation: Keep Cloudinary

The upload pipeline works. The preset is configured. Just move the API secret to your backend environment variables and issue signed upload URLs from your API.

---

## Decision 8: The Web Portal Scope

### What ARCHITECTURE_SPEC.md / WEB_PORTAL_PLAN said

14-week build with 4 phases: foundation → officer core → maps + analytics → admin + polish.

### Challenging this for your context

You have ~16 weeks total. The Flutter refactor (P0 fixes, API wiring) takes 4–6 weeks. The backend API takes 3–4 weeks. That leaves 6–8 weeks for the web portal — and WEB_PORTAL_PLAN assumes 14 weeks of dedicated web work.

**You cannot build the full WEB_PORTAL_PLAN scope.** Attempting it means you ship nothing to completion.

### What to actually build

**MVP web portal (6 weeks):**

| Week | Deliverable |
|------|-------------|
| 1 | Next.js scaffold, design system (CSS variables), Firebase Auth login, middleware |
| 2 | API routes: `/api/claims`, `/api/farmers`, `/api/auth` (Mongoose + MongoDB) |
| 3 | Officer dashboard: stats cards, recent claims table (TanStack Table) |
| 4 | Claims detail page with review form. Crop image verification queue. |
| 5 | Farmer directory with search. Feedback management. |
| 6 | Polish: loading states, error boundaries, responsive breakpoints, deploy |

**What you're cutting:**
- Satellite map on web (complex, less portfolio impact than the dashboard)
- Weather dashboard on web (just an API wrapper — not impressive)
- District efficiency heatmap (nice-to-have, not essential)
- Bulk CSV/PDF export (can add later)
- Admin user management (can add later)
- Audit log viewer (can add later)
- Keyboard shortcuts (polish, not MVP)

**Why this is the right cut:** The claims review workflow (table → detail → approve/reject) is the single highest-value officer interaction. A working, polished claims dashboard with real data from your API demonstrates full-stack competency. Adding satellite maps and weather adds marginal portfolio value at high implementation cost.

### Portfolio narrative

> "Krishi Bandhu is a cross-platform crop insurance system serving farmers and government officers. I built the backend API and officer web portal, and maintained the existing Flutter mobile app. The system processes crop damage claims with AI-assisted image verification and officer review workflows."

That's a strong statement. You don't need 14 features to make it.

---

## Decision 9: Testing Strategy

### What ARCHITECTURE_SPEC.md said

"Write tests before refactoring." Prioritize pure business logic, then widget tests, then integration tests.

### Realistic testing for a solo student

You're not going to write 200 tests. Be honest about that. But zero tests in a portfolio project is a red flag to employers. Write the tests that matter most:

**What to test (in order of career ROI):**

| Layer | What to test | Tool | Why |
|-------|-------------|------|-----|
| API routes | Claim CRUD, auth middleware, input validation | Jest + Supertest | Shows you test your own code. Most interviewers care about backend testing. |
| Mongoose models | Schema validation, required fields, custom validators | Jest | Shows you validate data at the model layer. |
| React components | Claims table renders, review form submits correctly | React Testing Library | Shows you write frontend tests. 3–5 tests is enough. |
| Flutter | None initially | — | You're learning Flutter. Writing Flutter tests while learning Flutter doubles the learning curve for marginal portfolio benefit. |

**Target: 15–25 tests across the API and web portal.** That's enough to demonstrate testing competency without consuming weeks of your time.

### Trade-off

No Flutter tests means Flutter refactoring (wiring screens to the API) is verified manually. This is a conscious trade-off. Acknowledge it if asked: "The Flutter codebase lacks tests — adding them is the next priority. I focused testing on the backend and web layers that I built from scratch."

---

## Summary: Where I Disagree with ARCHITECTURE_SPEC.md

| Decision | ARCHITECTURE_SPEC says | I say for YOU | Why |
|----------|----------------------|---------------|-----|
| **Backend deployment** | Standalone Express on a VM/container | Next.js API routes, co-located with web portal | You're one person. One project is easier than two. Extract later if needed. |
| **Web portal scope** | 14-week, 4-phase enterprise build | 6-week MVP focused on claims workflow | You have 16 weeks total, not 14 weeks just for web. Ship a polished subset, not an unfinished everything. |
| **Flutter testing** | Tests before refactoring (Flutter + API + web) | Tests for API and web only. Skip Flutter tests initially. | Learning Flutter AND learning Flutter testing simultaneously is too much. Focus testing on code you wrote. |
| **Provider threshold** | Keep Provider, migrate at 20 providers | Keep Provider, but for a different reason: you're not building new Flutter features, so the migration question doesn't arise. | Agree on the action, disagree on the framing. You're not "waiting to migrate" — you're not going to be in this codebase long enough for 20 providers. |

Everything else in ARCHITECTURE_SPEC.md holds:
- Flutter for mobile ✅
- Next.js for web ✅
- MongoDB sole database ✅
- Firebase Auth sole identity ✅
- Cloudinary for images ✅
- Drop Firestore ✅
- Drop local AuthService ✅

---

## Final Recommended Stack

### What you're building

```
┌─────────────────────────────────────────────────────┐
│                   YOU BUILD THIS                     │
│                                                     │
│  ┌─────────────────────────────────────────────┐    │
│  │  Next.js 15 (App Router)                    │    │
│  │  ┌──────────────┐  ┌────────────────────┐   │    │
│  │  │  Web Portal   │  │  API Routes        │   │    │
│  │  │  (React)      │  │  (Express-like)    │   │    │
│  │  │  Pages, UI    │  │  /api/claims       │   │    │
│  │  │  TanStack     │  │  /api/farmers      │   │    │
│  │  │  Table/Query  │  │  /api/auth         │   │    │
│  │  └──────────────┘  │  Mongoose + MongoDB │   │    │
│  │                     └────────────────────┘   │    │
│  └─────────────────────────────────────────────┘    │
│                                                     │
├─────────────────────────────────────────────────────┤
│              YOU MAINTAIN THIS                       │
│                                                     │
│  ┌─────────────────────────────────────────────┐    │
│  │  Flutter Mobile App                         │    │
│  │  Wire to new API, fix auth, remove hardcode │    │
│  └─────────────────────────────────────────────┘    │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Technology table

| Layer | Technology | You know it? | Learning time | Career ROI |
|-------|-----------|-------------|---------------|------------|
| **Mobile app** | Flutter + Dart | No → Learning | 2 weeks | High (differentiator) |
| **Mobile state** | Provider | No → Learning | 2–3 days | Medium |
| **Mobile navigation** | GoRouter | No → Learning | 1–2 days | Low (Flutter-specific) |
| **Web portal** | Next.js 15 (App Router) | React yes, Next.js learning | 1 week | **Very High** |
| **Web state** | TanStack Query v5 | Maybe → Learning | 2–3 days | High |
| **Web tables** | TanStack Table v8 | Maybe → Learning | 2–3 days | Medium |
| **Web forms** | React Hook Form + Zod | Maybe → Learning | 1–2 days | High |
| **Backend API** | Next.js API Routes | Learning (Express-adjacent) | 2–3 days | High |
| **Database** | MongoDB Atlas + Mongoose | **Yes** | 0 | High |
| **Auth** | Firebase Auth | Maybe → Learning | 2–3 days | High |
| **Image CDN** | Cloudinary | No → Learning | 1 day | Low |
| **Charts** | Recharts | Maybe → Learning | 1–2 days | Medium |
| **Deployment** | Vercel (web) | Maybe → Learning | 1 day | High |
| **Testing** | Jest + RTL + Supertest | **Yes** | 0 | **Very High** |

### The technologies that matter most on your resume

In order of interview impact:

1. **Next.js 15** — the current industry standard for React applications
2. **MongoDB + Mongoose** — your existing strength, now applied to a complex domain
3. **Firebase Auth** — cross-platform identity, ubiquitous in Indian startups
4. **TanStack Query/Table** — modern React data patterns, asked about in senior frontend interviews
5. **Flutter** — differentiator: "I also maintain a Flutter mobile app"
6. **System design** — "I architected a multi-client platform with shared API and role-based access"

### What you DON'T need to learn

- Docker (deployment to Vercel doesn't need it)
- Kubernetes (you're one person)
- GraphQL (REST is sufficient, and you know REST)
- Redis (no caching layer needed at your scale)
- CI/CD pipelines (Vercel auto-deploys from git push; Flutter builds manually)
- Terraform / AWS CDK (not managing infrastructure)
- Riverpod (not building new Flutter features)

---

## One final thing

The strongest thing about your portfolio is not any single technology. It's the **story**:

> "I inherited a Flutter mobile app with critical security flaws — exposed database credentials, no authentication guard, plaintext passwords. I designed and built a backend API to move all data access off the client, implemented Firebase Auth across mobile and web, and built an officer web portal for claim review. The system now has a proper security boundary, role-based access, and a real data pipeline."

That story demonstrates:
- **Security awareness** (you identified and fixed real vulnerabilities)
- **System design** (you added a backend API layer to a client-only architecture)
- **Full-stack capability** (Flutter mobile + Next.js web + Node.js API + MongoDB)
- **Pragmatism** (you didn't rewrite — you fixed what was broken and built what was missing)

No interviewer cares whether you used Riverpod or Provider. They care whether you can identify a broken architecture and fix it. You can.

---

*This document is advisory, not prescriptive. Adapt it to your actual timeline, energy, and interests. The best portfolio project is the one you finish.*
