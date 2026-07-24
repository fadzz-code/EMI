import type { ApiPaginationMeta } from "@/lib/api-client";
import type { UserRole } from "@/lib/roles";

export type EntityStatus = "active" | "inactive";
export type UserStatus = "approved" | "inactive" | "pending" | "rejected";

export type School = {
  id: string;
  name: string;
  address?: string | null;
  phone?: string | null;
  status: EntityStatus;
  classes_count?: number;
  active_classes_count?: number;
  active_teachers_count?: number;
  active_students_count?: number;
  created_at?: string | null;
  updated_at?: string | null;
};

export type TeacherAssignment = {
  id: string;
  teacher_id: string;
  class_id: string;
  is_active: boolean;
  assigned_at?: string | null;
  ended_at?: string | null;
  teacher?: {
    id: string;
    full_name: string;
    email: string;
    status: UserStatus | string;
  };
};

export type StudentMembership = {
  id: string;
  student_id: string;
  class_id: string;
  is_active: boolean;
  joined_at?: string | null;
  ended_at?: string | null;
  student?: {
    id: string;
    full_name: string;
    email: string;
    status: UserStatus | string;
  };
};

export type SchoolClass = {
  id: string;
  school_id: string;
  name: string;
  grade_level?: string | null;
  academic_year: string;
  status: EntityStatus;
  school?: Pick<School, "id" | "name" | "status"> | null;
  active_teacher_assignment?: TeacherAssignment | null;
  active_students_count?: number;
  created_at?: string | null;
  updated_at?: string | null;
};

export type ManagedUser = {
  id: string;
  full_name: string;
  email: string;
  phone?: string | null;
  avatar?: {
    id: string;
    url: string;
  } | null;
  role: UserRole;
  status: UserStatus | string;
  password_must_change?: boolean;
  active_school?: Pick<School, "id" | "name" | "status"> | null;
  active_class?: Pick<SchoolClass, "id" | "name" | "grade_level" | "academic_year" | "status"> | null;
  active_assignment?: TeacherAssignment | null;
  active_membership?: StudentMembership | null;
  approved_at?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
};

export type ClassStudent = {
  membership_id: string;
  joined_at?: string | null;
  student: {
    id: string;
    full_name: string;
    email: string;
    phone?: string | null;
    role: UserRole;
    status: UserStatus | string;
  };
};

export type PaginatedResult<T> = {
  items: T[];
  meta?: ApiPaginationMeta;
};

export type SchoolFilters = {
  search?: string;
  status?: EntityStatus | "";
  page?: number;
  per_page?: number;
};

export type ClassFilters = {
  search?: string;
  school_id?: string;
  status?: EntityStatus | "";
  academic_year?: string;
  grade_level?: string;
  teacher_id?: string;
  page?: number;
  per_page?: number;
};

export type UserFilters = {
  role?: UserRole | "";
  status?: UserStatus | "";
  school_id?: string;
  class_id?: string;
  search?: string;
  page?: number;
  per_page?: number;
};

export type ClassStudentFilters = {
  search?: string;
  status?: UserStatus | "";
  page?: number;
  per_page?: number;
};

export type SchoolPayload = {
  name: string;
  address?: string | null;
  phone?: string | null;
  status?: EntityStatus;
};

export type ClassPayload = {
  school_id?: string;
  name: string;
  grade_level?: string | null;
  academic_year: string;
  status?: EntityStatus;
};

export type UserPayload = {
  full_name: string;
  email: string;
  phone?: string | null;
};
