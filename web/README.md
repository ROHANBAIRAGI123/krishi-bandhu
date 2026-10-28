# Krishi Bandhu officer workspace

A responsive Next.js 16 / React 19 frontend with a ready-to-use local demo. No Firebase, MongoDB, Cloudinary, or backend environment variables are needed.

## Run locally

```bash
cd web
npm ci
npm run dev
```

Open http://localhost:3000. The optional `/login` page introduces the demo; it does not implement production authentication.

## Included workflows

- Overview: season-specific totals, charts, recent claims and activity.
- Claims: name/ID/village/crop search, status/crop filters, pagination and filtered CSV downloads.
- Review: inspect evidence, approve a bounded amount, reject with a required reason, mark in review, and mark approved claims paid (demo only).
- Farmers: searchable directory, crop filters, profiles and claim history across seasons.
- Crop verification: gallery, accessible modal review, verification/flagging/rejection with required reasons.
- Reports: crop totals, season filtering, CSV downloads and review activity.
- Settings: restore original demo data with an inline confirmation.
- Responsive navigation, keyboard focus, reduced motion, notifications and empty states.

## Demo data

`src/lib/demo-data.ts` contains 12 farmers, 24 claims across two seasons and 9 illustrative image records. The first three farmer identities are reused from `mobile/lib/src/utils/demo_users.dart`; additional identities, claims, parcels, amounts and image metadata are synthetic. The demo review officer uses the existing Priya Sharma name with a demo Nagpur assignment, not her mobile account's jurisdiction.

Decisions and activity persist under `krishi-bandhu-demo-v1` in local storage and synchronize across tabs. Invalid storage falls back to fixtures; failed saves show a session-only notice. Dashboard metrics and exports derive from those records. No payment or live AI assessment occurs.

## Verification

```bash
npm run lint
npm test
npm run build
```

Dependency-free tests require Node 22.6+ (validated on Node 24). They cover fixture relationships, claim transitions, approval limits and storage restoration. The app requires Node 20.9+ for Next.js. `next/font/google` bundles fonts at build time, so the first build needs access to Google Fonts.

## Source layout

- `src/app/(dashboard)`: routes and shared shell.
- `src/components`: dashboard, claims, farmers and image workflows.
- `src/lib/demo-store.tsx`: browser persistence and notifications.
- `src/lib/demo-rules.ts`: review validation and safe restoration.
- `src/types`: frontend domain types aligned with backend statuses.
- `public/demo`: local illustrative photographs; see `SOURCES.md`.

## Backend boundary

The latest backend includes health, officer, farmer and claim routes. This frontend still uses its local demo store. Before production use, connect the authenticated API, complete crop-image endpoints and evidence storage, and validate server-side authorization and audit logging. Client-side demo validation is not authorization.

Design: forest green and warm neutrals, DM Sans body text, Manrope headings, a 4px spacing rhythm and restrained hover/focus motion. Repository findings are documented in `../docs/FRONTEND_IMPLEMENTATION.md`.
