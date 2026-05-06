# Phase 2 Manager + Employee Flutter Plan

## Purpose

This document defines the no-code technical plan for Phase 2 of the KrubKrong ERP mobile application.

Phase 1 completed RBAC and multi-tenant backend isolation in NestJS + MongoDB.

Phase 2 will introduce one shared Flutter application for:

- `MANAGER`
- `EMPLOYEE`

The `ADMIN` role remains in the Vue `web_admin` application only.

## Final Decision

- Use one Flutter app for both `MANAGER` and `EMPLOYEE`.
- Keep `ADMIN` in `web_admin` only.
- Reuse the existing `mobile_pos` Flutter project as the implementation base.
- Do not create a separate `manager_app` at this stage.
- Do not modify Flutter code until router, auth, and API contract cleanup are planned clearly.

## Role Permission Matrix

### MANAGER

Manager access in the Flutter app should include:

- dashboard
- employees list
- employee detail
- create employee
- deactivate employee
- attendance overview
- attendance by employee
- payroll overview
- payroll by employee
- settings
- profile
- logout

### EMPLOYEE

Employee access in the Flutter app should include:

- own profile
- check-in
- check-out
- own attendance history
- own payroll
- logout

### Explicit Exclusions

- `ADMIN` should not use the Flutter app.
- `OWNER` and `STAFF` should not be introduced into the Flutter role model yet.
- Flutter routing and permissions should be built only for `MANAGER` and `EMPLOYEE` in Phase 2.

## Current Backend API Contract

The current backend APIs relevant to the Flutter app are as follows.

### Auth

#### `POST /auth/login`

Purpose:

- authenticate user
- return JWT token and current user payload

Expected usage:

- used by both `MANAGER` and `EMPLOYEE`

#### `GET /auth/me`

Status:

- implemented

Purpose:

- return current authenticated user profile from JWT

Note:

- this endpoint should be used to hydrate app session state after login and on app restart

### Employees

#### `GET /employees`

Purpose:

- manager employee list

RBAC expectation:

- `MANAGER` only sees employees in the same company
- `EMPLOYEE` should not use this list endpoint in the Flutter app

#### `GET /employees/active`

Purpose:

- fetch active employees only

#### `GET /employees/:id`

Purpose:

- employee detail

RBAC expectation:

- `MANAGER` can access same-company employee records
- `EMPLOYEE` can access only their own record

#### `POST /employees`

Purpose:

- create employee

RBAC expectation:

- manager flow only

#### `PATCH /employees/:id`

Purpose:

- update employee

#### `PATCH /employees/:id/deactivate`

Purpose:

- deactivate employee

### Attendance

#### `GET /attendance`

Purpose:

- attendance overview

RBAC expectation:

- `MANAGER` sees same-company attendance
- `EMPLOYEE` should not use this as a general list page in MVP unless backend behavior is explicitly confirmed for self-only usage

#### `GET /attendance/employee/:employeeId`

Purpose:

- attendance history by employee

RBAC expectation:

- `MANAGER` can inspect same-company employees
- `EMPLOYEE` can inspect only their own attendance

#### `POST /attendance/check-in`

Purpose:

- employee check-in

#### `POST /attendance/check-out`

Purpose:

- employee check-out

#### `GET /attendance/shop-settings`

Purpose:

- get attendance shop settings

#### `POST /attendance/shop-settings`

Purpose:

- update attendance shop settings

RBAC expectation:

- manager flow only

### Payroll

#### `GET /payroll`

Purpose:

- payroll overview

#### `GET /payroll/employee/:employeeId`

Purpose:

- payroll history by employee

#### `GET /payroll/employee/:employeeId/:month`

Purpose:

- payroll detail by month

#### `POST /payroll/generate`

Purpose:

- payroll generation

RBAC expectation:

- manager flow only

### Dashboard

Dashboard should not be treated as Flutter MVP-ready yet.

Reason:

- dashboard endpoint availability and tenant-safe behavior must be confirmed before implementation

## Recommended Flutter Structure

The Flutter app should be reorganized around a focused manager/employee structure while reusing the existing `mobile_pos` codebase.

```text
lib/
  app/
    app.dart
    router/
      app_router.dart
      route_guards.dart
      route_paths.dart
    shell/
      app_shell.dart
      app_navigation.dart
  core/
    auth/
      auth_session.dart
      auth_interceptor.dart
      auth_guard.dart
    network/
      dio_client.dart
      api_endpoints.dart
      error_mapper.dart
    storage/
      secure_storage_service.dart
      shared_prefs_service.dart
  features/
    auth/
      data/
      domain/
      presentation/
    dashboard/
      data/
      domain/
      presentation/
    employees/
      data/
      domain/
      presentation/
    attendance/
      data/
      domain/
      presentation/
    payroll/
      data/
      domain/
      presentation/
    profile/
      data/
      domain/
      presentation/
```

### Structure Notes

- `core/auth` should own token lifecycle, auth state hydration, and route gating helpers.
- `core/network` should own Dio setup, interceptors, endpoint constants, and common error translation.
- `core/storage` should own secure token storage and any lightweight cached session/profile data.
- `features/auth` should contain login and profile bootstrapping logic.
- `features/dashboard` should remain planned but not actively implemented until backend support is confirmed.
- `features/employees` should replace the current POS-oriented staff concept as the main manager team module.
- `app/router` and `app/shell` should own role-aware navigation and responsive shell layout.

## `mobile_pos` Files To Inspect Or Refactor First

These files should be the first review targets before implementation begins.

### App Bootstrap

- `mobile_pos/lib/main.dart`
- `mobile_pos/lib/app.dart`

Reason:

- controls bootstrap, provider scope, app theme, orientation, and app entry behavior

### Router And Shell

- `mobile_pos/lib/core/router/app_router.dart`
- `mobile_pos/lib/presentation/widgets/app_navigation_shell.dart`

Reason:

- current route tree is POS-first and must be realigned to manager/employee flows

### Auth Service And Provider

- `mobile_pos/lib/features/auth/presentation/providers/auth_provider.dart`
- `mobile_pos/lib/features/auth/data/datasources/auth_remote_datasource.dart`
- `mobile_pos/lib/features/auth/data/datasources/auth_local_datasource.dart`
- `mobile_pos/lib/features/auth/data/repositories/auth_repository_impl.dart`
- `mobile_pos/lib/features/auth/data/models/user_model.dart`
- `mobile_pos/lib/features/auth/domain/entities/user.dart`

Reason:

- current auth and role handling must be aligned to backend `MANAGER` and `EMPLOYEE` roles
- current auth layer expects endpoints and token behavior that should be validated against backend

### API / HTTP Client

- `mobile_pos/lib/core/network/http_client.dart`
- `mobile_pos/lib/core/constants/api_constants.dart`
- `mobile_pos/lib/core/constants/app_constants.dart`
- `mobile_pos/lib/core/providers/core_providers.dart`

Reason:

- API contract, token injection, timeout behavior, and endpoint assumptions should be cleaned up before feature expansion

### Storage Services

- `mobile_pos/lib/core/storage/storage_service.dart`

Reason:

- secure session storage behavior should be confirmed before router/auth cleanup

### Current POS Screens And Related Flows

- `mobile_pos/lib/features/pos/...`
- `mobile_pos/lib/features/order/...`
- `mobile_pos/lib/features/product/...`
- `mobile_pos/lib/features/staff/...`
- `mobile_pos/lib/features/dashboard/...`

Reason:

- identify what should be reused, renamed, archived, or removed from the Phase 2 navigation shell

## Implementation Phases

### Phase 2.1 App Shell / Auth Alignment

Goals:

- align Flutter roles to backend `MANAGER` and `EMPLOYEE`
- clean up token/session bootstrap
- simplify router to one app shell with role-based destinations
- remove assumptions about unsupported auth flows

Primary outcome:

- stable login + session restoration + role-aware navigation shell

### Phase 2.2 Manager Employee List

Goals:

- implement manager employee list
- implement employee detail
- implement create employee
- implement deactivate employee

Primary outcome:

- managers can manage same-company employees from Flutter

### Phase 2.3 Manager Attendance

Goals:

- implement attendance overview
- implement attendance-by-employee view
- implement attendance settings access

Primary outcome:

- managers can monitor attendance inside company scope

### Phase 2.4 Manager Payroll

Goals:

- implement payroll overview
- implement payroll by employee
- implement payroll detail by month

Primary outcome:

- managers can view payroll data for same-company employees

### Phase 2.5 Employee Self-Service

Goals:

- implement employee check-in
- implement employee check-out
- implement own attendance history
- implement own payroll view
- implement own profile view

Primary outcome:

- employees can use one mobile app for self-service without manager/admin features

### Phase 2.6 Responsive Polish

Goals:

- improve phone layouts
- adapt shell for tablet
- define wide-screen behavior
- review navigation density and screen hierarchy

Primary outcome:

- app works well across small and medium form factors

## Risks

### Do Not Mix `ADMIN` Into Flutter

Reason:

- admin remains in Vue `web_admin`
- mixing admin into Flutter increases scope and creates UX confusion

### Do Not Add `OWNER` Or `STAFF` Yet

Reason:

- current business decision is `MANAGER` + `EMPLOYEE` only for Flutter Phase 2
- adding extra roles now will complicate router, permissions, and testing

### Do Not Build Dashboard Until Backend Dashboard Endpoint Exists And Is Confirmed

Reason:

- dashboard should only be added when backend response shape and tenant-safe filtering are confirmed

### Do Not Break Existing `mobile_pos` Before Router / Auth Cleanup

Reason:

- current Flutter app already contains working auth, staff, and attendance foundations
- uncontrolled feature edits before architecture cleanup can create inconsistent route and session behavior

### Additional Practical Risks

- stale Flutter documentation may still describe GraphQL patterns that no longer match the current REST-based code
- current user role parsing in Flutter may not match backend roles exactly
- current router still centers POS flows rather than manager/employee flows
- current dashboard assumptions may not be safe for multi-tenant manager access

## Recommended Next Coding Step

Before any feature implementation, perform a focused technical refactor plan for:

1. Flutter role model alignment
2. auth/session contract alignment with backend
3. router and shell simplification
4. endpoint inventory for employees, attendance, and payroll

The first actual coding phase should be:

- `Phase 2.1 App Shell / Auth Alignment`

That phase should happen before employee, attendance, or payroll UI work begins.
