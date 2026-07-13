# Local Development Setup

## Prerequisites

- **Node.js** 20+ ([download](https://nodejs.org/))
- **npm** 10+ (comes with Node.js)
- **Git** ([download](https://git-scm.com/))
- **MongoDB Atlas** account ([sign up](https://cloud.mongodb.com/))
- **Firebase** project ([console](https://console.firebase.google.com/))
- **Cloudinary** account ([sign up](https://cloudinary.com/))

## 1. Clone the Repository

```bash
git clone https://github.com/your-username/krishi-bandhu.git
cd krishi-bandhu
```

## 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env
```

Fill in `.env` with your actual values:

| Variable | Where to get it |
|----------|----------------|
| `MONGODB_URI` | MongoDB Atlas → Connect → Connection String |
| `FIREBASE_PROJECT_ID` | Firebase Console → Project Settings → General |
| `FIREBASE_CLIENT_EMAIL` | Firebase Console → Project Settings → Service Accounts → Generate Key |
| `FIREBASE_PRIVATE_KEY` | Same service account JSON file |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary Dashboard |
| `CLOUDINARY_API_KEY` | Cloudinary Dashboard → API Keys |
| `CLOUDINARY_API_SECRET` | Cloudinary Dashboard → API Keys |

```bash
# Start development server
npm run dev
# Server runs at http://localhost:5000
```

## 3. Web Dashboard Setup

```bash
cd web

# Install dependencies
npm install

# Create environment file
cp .env.example .env.local
```

Fill in `.env.local`:

| Variable | Value |
|----------|-------|
| `NEXT_PUBLIC_API_URL` | `http://localhost:5000/api` |
| `NEXT_PUBLIC_FIREBASE_*` | Firebase Console → Project Settings → General → Web app config |

```bash
# Start development server
npm run dev
# Dashboard runs at http://localhost:3000
```

## 4. Mobile App

The Flutter app in `mobile/` is the existing project. See its own README for setup instructions.

## Verification

After starting both backend and web:

1. Backend health check: `curl http://localhost:5000/api/v1/health`
2. Web dashboard: Open `http://localhost:3000` in your browser
