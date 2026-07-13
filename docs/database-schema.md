# Database Schema

> MongoDB Atlas — Database: `krishi_bandhu`
>
> Migrated from the original Flutter project's `MONGODB_SCHEMA_DESIGN.md`.
> This document is the single source of truth for all collections.

## Collections

| Collection | Purpose | Priority |
|------------|---------|----------|
| `farmers` | Farmer profiles, land parcels, verification | P0 |
| `crop_images` | Crop images with ML metadata | P0 |
| `claims` | Insurance claims with approval workflow | P0 |
| `crop_loss_intimations` | Crop loss reports with officer assessments | P1 |
| `officials` | Officer accounts and assignments | P1 |
| `ai_inferences` | ML model results (future) | P2 |
| `satellite_data` | Satellite imagery metadata (future) | P2 |
| `audit_logs` | System activity logs (future) | P2 |

## Schema Definitions

> Detailed schemas will be defined in Mongoose models.
> Reference: `backend/src/modules/{module}/{module}.model.ts`
>
> For the original schema designs, see the Flutter project's
> `MONGODB_SCHEMA_DESIGN.md` which documents all fields, indexes,
> and relationships between collections.

## Key Design Decisions

### Embedded vs Referenced
- **Embedded**: Land parcels in farmers, crop history in parcels, ML verification in images
- **Referenced**: Farmer → Images (one-to-many), Farmer → Claims (one-to-many), Loss → Images (many-to-many)

### Indexes
Each collection defines indexes for its most common query patterns.
See individual model files for index definitions.
