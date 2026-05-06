# Employee Test Flow

## Required Environment Variables

Add these values to [backend/.env](/E:/ERP_Workspace/backend/.env):

- `MONGO_URI`
- `COMPANY_NAME`
- `EMPLOYEE_USERNAME`
- `EMPLOYEE_EMAIL`
- `EMPLOYEE_PASSWORD`
- `EMPLOYEE_FULLNAME`

Example:

```env
EMPLOYEE_USERNAME=employee1
EMPLOYEE_EMAIL=employee1@krubkrong.com
EMPLOYEE_PASSWORD=123456
EMPLOYEE_FULLNAME=Employee One
```

## Run The Employee Seed

Run these commands from `backend/`:

```powershell
npm run seed:manager
npm run seed:employee
```

What the seed does:

- connects with the existing `MONGO_URI`
- finds the target company by `COMPANY_NAME`
- verifies that a `MANAGER` user already exists for that company
- creates an `EMPLOYEE` user in the same company
- creates the matching `Employee` entity linked by `userId`
- skips duplicate creation when the employee already exists

Expected seed messages:

- `Employee created`
- `Employee already exists`
- `Company not found`
- `Manager not found`

## Test The Manager Employee API

1. Log in as the seeded manager with `MANAGER_EMAIL` and `MANAGER_PASSWORD`.
2. Copy the returned JWT access token.
3. Call the employee list endpoint with the manager token:

```http
GET /employees
Authorization: Bearer <manager-token>
```

4. Call the active employee endpoint:

```http
GET /employees/active
Authorization: Bearer <manager-token>
```

5. Optional detail check using the employee id returned from the list:

```http
GET /employees/:id
Authorization: Bearer <manager-token>
```

Expected results after seeding:

- `GET /employees` returns an array with the seeded employee record
- `GET /employees/active` returns the seeded employee when `isActive=true`
- employee items should include the same `companyId` as the manager
- employee items should include the linked `userId`

## Expected RBAC Behavior

- `ADMIN` can access employees across companies.
- `MANAGER` can only access employees whose `companyId` matches the manager account.
- `EMPLOYEE` can only access their own employee record through `GET /employees/:id`.
- cross-company manager access should be rejected with `403 Forbidden`.
- missing employee records should return `404 Not Found`.
