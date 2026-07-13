# Krishi Bandhu — AI-Powered Crop Insurance Platform

An AI-powered crop insurance platform built for India's PMFBY (Pradhan Mantri Fasal Bima Yojana) scheme. Originally a Smart India Hackathon (SIH) winning project, now being rebuilt as a production-quality system.

## Architecture

```
krishi-bandhu/
├── backend/    → Express + TypeScript REST API
├── web/        → Next.js 15 officer dashboard
├── mobile/     → Flutter mobile app (farmer-facing)
├── docs/       → Architecture, API contracts, guides
└── ai/         → (Future) Python FastAPI ML service
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Backend** | Express, TypeScript, Mongoose, Firebase Admin, Cloudinary |
| **Web** | Next.js 15 (App Router), TypeScript, Tailwind CSS |
| **Mobile** | Flutter, Firebase Auth, Camera, GPS |
| **Database** | MongoDB Atlas |
| **Auth** | Firebase Authentication |
| **Storage** | Cloudinary (images) |
| **AI** | (Future) FastAPI + ML models |

## Getting Started

### Prerequisites

- Node.js 20+
- npm 10+
- MongoDB Atlas account
- Firebase project
- Cloudinary account

### Setup

```bash
# Clone the repository
git clone https://github.com/your-username/krishi-bandhu.git
cd krishi-bandhu

# Backend
cd backend
cp .env.example .env    # Fill in your values
npm install
npm run dev

# Web (in a new terminal)
cd web
cp .env.example .env    # Fill in your values
npm install
npm run dev
```

### Environment Variables

Each sub-project has its own `.env.example` with all required variables documented. Copy it to `.env` and fill in your values. See [docs/setup.md](docs/setup.md) for detailed instructions.

## Project Structure

### Backend (`backend/`)

Module-based Express API. Each domain entity (farmer, claim, crop-image, etc.) is a self-contained module with its own model, routes, controller, service, and validation.

### Web (`web/`)

Next.js 15 officer/admin dashboard. Used by insurance officers to review claims, verify crop images, and manage farmer data.

### Mobile (`mobile/`)

Existing Flutter application used by farmers. Handles crop image capture, claim submission, GPS tagging, and offline support.

### Docs (`docs/`)

- [Architecture Overview](docs/architecture.md)
- [API Contracts](docs/api-contracts.md)
- [Database Schema](docs/database-schema.md)
- [Setup Guide](docs/setup.md)

## Conventions

| Area | Convention |
|------|-----------|
| Commits | [Conventional Commits](https://www.conventionalcommits.org/) |
| Branches | `main` / `dev` / `feat/*` / `fix/*` / `chore/*` |
| File naming | `kebab-case` (backend), `PascalCase` (React components) |
| API routes | `kebab-case`, plural (`/api/farmers`, `/api/crop-images`) |

## License

MIT
