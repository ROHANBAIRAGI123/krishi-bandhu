# Architecture Overview

## System Diagram

```
┌─────────────┐     ┌─────────────────┐     ┌──────────────┐
│   Mobile    │     │     Backend     │     │     Web      │
│  (Flutter)  │────▶│  (Express/TS)  │◀────│  (Next.js)   │
│  Farmer App │     │   REST API     │     │  Officer UI  │
└─────────────┘     └───────┬────────┘     └──────────────┘
                            │
                 ┌──────────┼──────────┐
                 │          │          │
           ┌─────▼──┐  ┌───▼────┐  ┌──▼────────┐
           │MongoDB │  │Firebase│  │Cloudinary │
           │ Atlas  │  │  Auth  │  │  (Images) │
           └────────┘  └────────┘  └───────────┘
                            │
                    ┌───────▼────────┐
                    │  AI Service    │
                    │  (Future)      │
                    │  FastAPI/Python │
                    └────────────────┘
```

## Data Flow

1. **Farmer submits crop image** → Mobile captures image with GPS → uploads to Cloudinary via Backend → Backend stores metadata in MongoDB
2. **Officer reviews claim** → Web dashboard fetches claims from Backend → Officer approves/rejects → Backend updates MongoDB
3. **AI verification (future)** → Backend sends image URL to AI Service → AI returns predictions → Backend stores results in MongoDB

## Authentication Flow

- Mobile and Web both use Firebase Authentication
- Clients send Firebase ID tokens in `Authorization: Bearer <token>` header
- Backend verifies tokens using Firebase Admin SDK
- No session management — stateless JWT verification

## Key Design Decisions

### Why Express over NestJS?
Solo developer with MERN stack expertise. Express is simpler, has less boilerplate, and the developer is already proficient with it.

### Why module-based structure?
Co-location of related files (model, routes, controller, service, validation) reduces context switching for a solo developer.

### Why no shared package/monorepo tooling?
Backend and web share almost no code initially. A `shared/` folder will be introduced when 3+ type definitions are duplicated.

### Why Cloudinary over Firebase Storage?
Cloudinary provides built-in image transformations (thumbnails, compression) that are critical for crop image processing.
