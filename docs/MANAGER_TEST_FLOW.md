# Manager Test Flow

## Seed Manager And Company

Run from the `backend` directory:

```bash
npm run seed:manager
```

Required environment variables:

```env
MONGO_URI=mongodb://localhost:27017/your-db
COMPANY_NAME=Demo Coffee Shop
MANAGER_USERNAME=shopowner
MANAGER_EMAIL=owner@example.com
MANAGER_PASSWORD=change-this-password
```

Expected seed behavior:
- If the company already exists, the script reuses it.
- If the manager already exists, the script does not create a duplicate.
- If the existing manager has no `companyId`, the script links that manager to the company.
- Password hashing uses the same bcrypt pattern as the auth service.
- MongoDB connection is closed before exit.

## Manager Login Test

1. Seed the company and manager:

```bash
cd backend
npm run seed:manager
```

2. Login through the backend API:

```http
POST /api/auth/login
Content-Type: application/json
```

```json
{
  "email": "owner@example.com",
  "password": "change-this-password"
}
```

Expected result:
- Login succeeds.
- Response includes `token` and `access_token`.
- Response role is `MANAGER`.
- Response user contains the correct `companyId`.

## Employees API Test

Use the manager bearer token.

### List employees

```http
GET /api/employees
Authorization: Bearer <manager-token>
```

Expected result:
- Only employees from the manager's company are returned.

### Access one employee from another company

```http
GET /api/employees/:employeeId
Authorization: Bearer <manager-token>
```

Expected result:
- Access is blocked for employees outside the manager's company.

## Attendance API Test

Use the manager bearer token.

### List attendance

```http
GET /api/attendance
Authorization: Bearer <manager-token>
```

Expected result:
- Only attendance records from the manager's company are returned.

### Access another company's attendance history

```http
GET /api/attendance/employee/:employeeId
Authorization: Bearer <manager-token>
```

Expected result:
- Manager cannot access another company's employee attendance.

## Payroll API Test

Use the manager bearer token.

### List payroll

```http
GET /api/payroll
Authorization: Bearer <manager-token>
```

Expected result:
- Only payroll records from the manager's company are returned.

### Access another company's payroll

```http
GET /api/payroll/employee/:employeeId
Authorization: Bearer <manager-token>
```

Expected result:
- Manager cannot access another company's payroll records.

## Postman Checklist

1. Seed a manager and company with `npm run seed:manager`.
2. Login as the manager with `POST /api/auth/login`.
3. Save the returned bearer token.
4. Call:
- `GET /api/employees`
- `GET /api/attendance`
- `GET /api/payroll`
5. Confirm only same-company data is returned.
6. Try IDs from another company in:
- `GET /api/employees/:employeeId`
- `GET /api/attendance/employee/:employeeId`
- `GET /api/payroll/employee/:employeeId`
7. Confirm cross-company access is rejected.

## Notes

- This flow prepares real shop-owner / manager usage at the API level.
- No frontend manager UI is added in this phase.
- `web_admin` behavior stays unchanged and remains ADMIN-only.
