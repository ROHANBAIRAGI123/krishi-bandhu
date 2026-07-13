# API Contracts

> REST API endpoints served by the backend at `http://localhost:5000/api`

## Common Patterns

### Base URL
```
/api/v1
```

### Authentication
All endpoints (except health check) require Firebase ID token:
```
Authorization: Bearer <firebase-id-token>
```

### Response Format
```json
// Success
{
  "success": true,
  "data": { ... }
}

// Error
{
  "success": false,
  "error": {
    "message": "Human-readable error message",
    "code": "MACHINE_READABLE_CODE"
  }
}
```

### Pagination
```
GET /api/v1/farmers?page=1&limit=20
```
```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 150,
      "totalPages": 8
    }
  }
}
```

---

## Endpoints

> Define endpoints here as you build each module.
> Follow the pattern: METHOD /path → Description → Request → Response

### Health
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/health` | Server health check (no auth) |

### Farmers
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/farmers` | List farmers (paginated) |
| GET | `/api/v1/farmers/:id` | Get farmer by ID |
| POST | `/api/v1/farmers` | Register a new farmer |
| PATCH | `/api/v1/farmers/:id` | Update farmer profile |

### Claims
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/claims` | List claims (paginated, filterable) |
| GET | `/api/v1/claims/:id` | Get claim by ID |
| POST | `/api/v1/claims` | Submit a new claim |
| PATCH | `/api/v1/claims/:id/status` | Update claim status (officer) |

### Crop Images
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/crop-images` | List crop images (paginated) |
| GET | `/api/v1/crop-images/:id` | Get crop image by ID |
| POST | `/api/v1/crop-images` | Upload crop image metadata |
| PATCH | `/api/v1/crop-images/:id/verify` | Officer verify image |

### Crop Loss
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/crop-losses` | List crop loss reports |
| GET | `/api/v1/crop-losses/:id` | Get crop loss by ID |
| POST | `/api/v1/crop-losses` | Submit crop loss report |
| PATCH | `/api/v1/crop-losses/:id/assess` | Officer assess loss |

### Officers
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/officers/me` | Get current officer profile |
| GET | `/api/v1/officers/:id` | Get officer by ID |

### Upload
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/upload/image` | Upload image to Cloudinary |
