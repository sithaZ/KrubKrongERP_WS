import { Role } from '../enums/role.enum';

export function normalizeRole(role?: string | null): Role | undefined {
  const normalizedRole = String(role ?? '')
    .trim()
    .toUpperCase();

  switch (normalizedRole) {
    case Role.ADMIN:
      return Role.ADMIN;
    case Role.MANAGER:
    case Role.OWNER:
      return Role.MANAGER;
    case Role.EMPLOYEE:
    case Role.STAFF:
      return Role.EMPLOYEE;
    default:
      return undefined;
  }
}

