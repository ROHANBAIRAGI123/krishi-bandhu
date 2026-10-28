# Product Requirements Document (PRD)

## Krishi Bandhu Backend

### 1. Product Overview

**Product Name:** Krishi Bandhu Backend
**Version:** 1.0.0
**Product Type:** Backend API for Crop Insurance Management Platform

Krishi Bandhu Backend is a RESTful API service that powers India's PMFBY (Pradhan Mantri Fasal Bima Yojana) crop insurance digitization platform. The system is the single data gateway for a Flutter farmer app, a Next.js officer portal, and future AI services. It manages farmer registration, crop image verification, insurance claim processing, crop loss assessment, and administrative analytics — all behind a secure API that ensures no client ever touches the database directly.

### 2. Target Users

- **Farmers:** Register profiles, submit crop images, file crop loss intimations, check claim status, submit feedback
- **District Officers:** Review and adjudicate insurance claims, verify crop images, assess crop loss reports, manage farmer records
- **Administrators:** Manage officer accounts, view system-wide analytics, handle feedback escalation, audit all operations
- **System Clients:** Flutter mobile app, Next.js web portal, future Python AI service

### 3. Core Features

#### 3.1 Authentication & Session Management

- **Firebase Token Verification:** Validate Firebase ID tokens on every request via Firebase Admin SDK
- **Session Creation:** Exchange verified ID token for a user profile from MongoDB
- **Role Resolution:** Determine user role (farmer, officer, admin) by looking up the authenticated UID in the `farmers` or `officials` collection
- **Current User:** Return the authenticated user's full profile and role

#### 3.2 Farmer Management

- **Farmer Registration:** Create farmer profiles with personal info, Aadhaar (hashed), phone, address, and land parcels
- **Farmer Directory:** List farmers with filters (district, taluka, village) and pagination
- **Farmer Profile:** Access individual farmer details including land parcels
- **Profile Updates:** Modify farmer information
- **Farmer Stats:** Aggregated summary per farmer (claim count, image count, total insured area)
- **Farmer Images:** List all crop images associated with a farmer

#### 3.3 Claim Processing

- **Claim Submission:** Create insurance claims with farmer reference, parcel, season, crop, and supporting image IDs
- **Claim Listing:** View claims with filters (status, season, farmerId, district) and pagination
- **Claim Details:** Access individual claim with full submission, AI assessment, and review history
- **Status Updates:** Transition claim status through the lifecycle
- **Officer Review:** Submit officer adjudication with decision (approve/reject), notes, verified damage percentage, and payout recommendation

#### 3.4 Crop Image Verification

- **Image Record Creation:** Save crop image metadata (Cloudinary URL, GPS coordinates, capture timestamp, crop info, quality scores)
- **Image Listing:** View images with filters (status, farmerId, parcelId, season) and pagination
- **Pending Review Queue:** List images awaiting officer verification, ordered by upload date
- **Flagged Images:** List images flagged by ML verification for manual review
- **Officer Verification:** Submit officer verification with approval/rejection, notes, and verification timestamp

#### 3.5 Crop Loss Assessment

- **Loss Intimation:** Record crop loss reports with cause, affected area, estimated loss percentage, description, and supporting image IDs
- **Loss Listing:** View reports with filters (status, season, year, district) and pagination
- **Loss Details:** Access individual loss report with full assessment history
- **Status Updates:** Transition loss report through assessment lifecycle
- **Officer Assessment:** Submit field assessment with verified loss percentage and notes
- **Loss Statistics:** Aggregated stats (total affected area, count by cause, average loss) with filters

#### 3.6 Feedback Management

- **Feedback Submission:** Create feedback/complaints with category, priority, and description
- **Feedback Listing:** View feedback with filters (status, category, priority) and pagination
- **Feedback Details:** Access individual feedback with admin response history
- **Status Management:** Update feedback status (open → in_progress → resolved)
- **Feedback Statistics:** Aggregated counts by status, category, and priority

#### 3.7 Dashboard & Analytics

- **Dashboard Stats:** Aggregated metrics for officer dashboards — total claims by status, total farmers, total premium value, recent claims
- **Scoped Analytics:** Stats scoped to the authenticated officer's assigned district

#### 3.8 File Upload Support

- **Signed Upload URLs:** Generate Cloudinary signed upload parameters so clients can upload images directly to Cloudinary without holding the API secret

#### 3.9 System Health

- **Health Check:** API endpoint for uptime monitoring and deployment verification

### 4. API Modules & Endpoint Summary

**Authentication Routes** (`/api/auth/`)

- `POST /session` — Verify Firebase ID token, return user profile and role
- `GET /me` — Get current authenticated user profile

**Farmer Routes** (`/api/farmers/`)

- `GET /` — List farmers (secured, officer+)
- `POST /` — Create farmer profile (secured)
- `GET /:farmerId` — Get farmer details (secured)
- `PUT /:farmerId` — Update farmer profile (secured)
- `GET /:farmerId/stats` — Get farmer aggregated stats (secured)
- `GET /:farmerId/images` — Get farmer's crop images (secured)

**Claim Routes** (`/api/claims/`)

- `GET /` — List claims with filters (secured, role-scoped)
- `POST /` — Submit new claim (secured, farmer+)
- `GET /:claimId` — Get claim details (secured, role-scoped)
- `PUT /:claimId/status` — Update claim status (secured, officer+)
- `PUT /:claimId/review` — Submit officer review (secured, officer only)

**Crop Image Routes** (`/api/crop-images/`)

- `GET /` — List images with filters (secured, role-scoped)
- `POST /` — Create image metadata record (secured)
- `GET /pending-review` — Get officer review queue (secured, officer+)
- `GET /flagged` — Get ML-flagged images (secured, officer+)
- `GET /:imageId` — Get image details (secured)
- `PUT /:imageId/officer-verification` — Submit officer verification (secured, officer only)

**Crop Loss Routes** (`/api/crop-loss/`)

- `GET /` — List loss reports with filters (secured, role-scoped)
- `POST /` — Submit loss intimation (secured, farmer+)
- `GET /stats` — Get aggregated loss statistics (secured, officer+)
- `GET /:lossId` — Get loss report details (secured)
- `PUT /:lossId/status` — Update report status (secured, officer+)
- `PUT /:lossId/assessment` — Submit officer assessment (secured, officer only)

**Feedback Routes** (`/api/feedback/`)

- `GET /` — List feedback with filters (secured, role-scoped)
- `POST /` — Submit feedback (secured, farmer+)
- `GET /stats` — Get feedback statistics (secured, officer+)
- `GET /:feedbackId` — Get feedback details (secured)
- `PUT /:feedbackId/status` — Update feedback status (secured, officer+)

**Dashboard Routes** (`/api/dashboard/`)

- `GET /stats` — Get aggregated dashboard metrics (secured, officer+)

**Upload Routes** (`/api/uploads/`)

- `POST /sign` — Generate Cloudinary signed upload parameters (secured)

**Health Check** (`/api/health/`)

- `GET /` — System health status

### 5. Roles & Permission Matrix

| Feature                        | Farmer | Officer | Admin |
| ------------------------------ | ------ | ------- | ----- |
| Create/update own profile      | ✓      | ✗       | ✗     |
| View own claims & images       | ✓      | ✗       | ✗     |
| Submit claims & loss reports   | ✓      | ✗       | ✗     |
| Submit feedback                | ✓      | ✗       | ✗     |
| View farmer directory          | ✗      | ✓       | ✓     |
| View all claims (by district)  | ✗      | ✓       | ✓     |
| Review claims (approve/reject) | ✗      | ✓       | ✓     |
| Verify crop images             | ✗      | ✓       | ✓     |
| Assess crop loss reports       | ✗      | ✓       | ✓     |
| View dashboard analytics       | ✗      | ✓       | ✓     |
| Manage feedback status         | ✗      | ✓       | ✓     |
| View all districts             | ✗      | ✗       | ✓     |
| Manage officer accounts        | ✗      | ✗       | ✓     |
| Request signed upload URL      | ✓      | ✓       | ✓     |

**Scoping Rule:** Officers see only data within their assigned district. Admins see all districts. Farmers see only their own records.

### 6. Business Rules

- **No direct database access from any client.** All data operations go through this API.
- **Firebase Auth is the sole identity provider.** The API verifies Firebase ID tokens — it does not manage passwords, sessions, or OTPs.
- **One claim per parcel per season.** Duplicate claim submissions for the same parcel and season are rejected.
- **Image metadata is stored in MongoDB. Image binaries are stored in Cloudinary.** The API never receives or stores image files directly.
- **Claim status lifecycle:** `SUBMITTED → UNDER_REVIEW → APPROVED | REJECTED`. Status can only move forward. Rejected claims may be resubmitted as new claims.
- **Crop loss status lifecycle:** `REPORTED → ASSESSED → APPROVED | REJECTED`.
- **Officer reviews are append-only.** An officer's review decision and notes are recorded with a timestamp. Reviews cannot be edited or deleted after submission.
- **District scoping is enforced at the API layer.** An officer querying `/api/claims` automatically receives only claims from their assigned district. This is not a client-side filter.
- **All list endpoints support pagination** (`?page=1&limit=20`) with a maximum limit of 100 per page.

### 7. Security Requirements

- Firebase Admin SDK token verification on every authenticated request
- Role-based authorization middleware on all protected routes
- District-scoped data access enforced server-side for officer roles
- Input validation and sanitization on all endpoints
- MongoDB operator injection prevention (reject `$` prefixed keys in request bodies)
- Cloudinary API secret stored server-side only — clients receive signed upload parameters, never the secret
- Rate limiting on auth and upload endpoints
- CORS configuration restricted to known client origins
- All sensitive fields (Aadhaar numbers) stored as hashed values, never in plaintext
- No credentials, connection strings, or API keys in source control

### 8. File & Media Management

- Clients upload images directly to Cloudinary using signed parameters from `POST /api/uploads/sign`
- The API stores image metadata (Cloudinary URL, dimensions, GPS coordinates, file size, MIME type) — not the binary
- Upload preset: `pmfby-app`, folder structure: `pmfby_crops/{farmerId}/{season}/`
- Supported formats: JPEG, PNG
- Maximum file size enforced by Cloudinary upload preset
- Image metadata includes capture-time GPS coordinates for geo-verification

### 9. Success Criteria

- All data access from Flutter and Next.js clients goes through the API — zero direct database connections from any client
- Firebase Auth token verification on 100% of authenticated requests
- District-scoped data isolation verified — officers cannot access data outside their assigned district
- Complete claim lifecycle supported: submission → review → decision, across both mobile and web clients
- API response times under 500ms for single-document queries, under 2s for aggregation endpoints
- All endpoints return consistent error shapes (`{ error, status, details? }`)
- 15+ automated tests covering auth, CRUD operations, and role-based access
- Successfully deployed and serving both Flutter and Next.js clients simultaneously
