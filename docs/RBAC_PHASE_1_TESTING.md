# RBAC Phase 1 Testing

## Seed The First ADMIN

Run from the `backend` directory:

```bash
npm run seed:admin
```

Required environment variables:

```env
MONGO_URI=mongodb://localhost:27017/your-db
ADMIN_USERNAME=systemadmin
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=change-this-password
```

Behavior:
- If an `ADMIN` user already exists, the script exits safely without creating a duplicate.
- If required environment variables are missing, the script prints a clear error and stops.
- If the username or email is already used by a non-admin account, the script stops and prints a clear error.
- The MongoDB connection is always closed before exit.

## Test ADMIN Login In `web_admin`

1. Seed the admin account with `npm run seed:admin`.
2. Start the backend and `web_admin`.
3. Open the admin login page.
4. Sign in with `ADMIN_EMAIL` and `ADMIN_PASSWORD`.
5. Confirm you are redirected to `/dashboard`.
6. Confirm protected pages like employees, attendance, and payroll load normally.

Expected result:
- Login succeeds.
- `web_admin` stores an authenticated ADMIN session.
- Access to admin UI is allowed only for the ADMIN role.

## Test MANAGER Is Blocked From `web_admin`

1. Create a manager user through the existing auth or data setup flow.
2. Ensure the manager account has role `MANAGER`.
3. Attempt to log in to `web_admin` with the manager credentials.

Expected result:
- Login request may authenticate at API level.
- `web_admin` must block entry and show the admin-only access message.
- The browser should not retain a valid admin session.

## Test MANAGER Only Sees Own Company Data

1. Prepare two companies:
- Company A
- Company B
2. Create one manager in Company A and one manager in Company B.
3. Create employees, attendance records, and payroll records under both companies.
4. Log in as Manager A and call employee, attendance, and payroll endpoints with Manager A's token.
5. Repeat the same checks as Manager B.

Expected result:
- Manager A only sees Company A records.
- Manager B only sees Company B records.
- Requests that target another company's record are rejected or return no access.

## Postman / API Checklist

Use bearer tokens from `/api/auth/login`.

### 1. Seeded ADMIN
- Run `npm run seed:admin`.
- Verify the console says the ADMIN was created, or that one already exists.

### 2. ADMIN Login
- `POST /api/auth/login`
- Body:

```json
{
  "email": "ADMIN_EMAIL value",
  "password": "ADMIN_PASSWORD value"
}
```

Check:
- Response includes `token`
- Response includes `access_token`
- Response includes `role: "ADMIN"`
- Response user payload includes `companyId`

### 3. `/api/auth/me`
- `GET /api/auth/me`
- Header: `Authorization: Bearer <token>`

Check:
- Response includes the authenticated admin profile
- Role is `ADMIN`

### 4. Manager Data Scope
- Login as a manager and get a token.
- `GET /api/employees`
- `GET /api/attendance`
- `GET /api/payroll`

Check:
- Only same-company records are returned.

### 5. Cross-Company Access Protection
- As Manager A, call:
- `GET /api/employees/:id`
- `GET /api/attendance/employee/:employeeId`
- `GET /api/payroll/employee/:employeeId`

Use IDs that belong to Company B.

Check:
- Access is blocked.

### 6. Employee Scope Preparation
- Login as an employee and call own employee/attendance/payroll endpoints.

Check:
- Own records are accessible.
- Other employee records are blocked.

## Notes

- This Phase 1 testing covers the RBAC and tenant foundation for auth, employees, attendance, payroll, and `web_admin`.
- Other modules like orders, products, and dashboard should be included in later tenant-scoping phases.
