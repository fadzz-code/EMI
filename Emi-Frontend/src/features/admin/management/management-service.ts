import { apiClient } from "@/lib/api-client";

import type {
  ClassFilters,
  ClassPayload,
  ClassStudent,
  ClassStudentFilters,
  ManagedUser,
  PaginatedResult,
  School,
  SchoolClass,
  SchoolFilters,
  SchoolPayload,
  StudentMembership,
  TeacherAssignment,
  UserFilters,
  UserPayload,
  UserStatus,
} from "./types";

function paginated<T>(
  data: T[] | undefined,
  meta: unknown,
): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

export const schoolService = {
  async list(token: string, filters: SchoolFilters = {}) {
    const response = await apiClient.get<School[]>("/schools", {
      token,
      query: {
        search: filters.search,
        status: filters.status,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 15,
        sort_by: "name",
        sort_direction: "asc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async detail(token: string, schoolId: string) {
    const response = await apiClient.get<School>(`/schools/${schoolId}`, { token });

    if (!response.data) {
      throw new Error("Detail sekolah tidak tersedia.");
    }

    return response.data;
  },

  async create(token: string, payload: SchoolPayload) {
    const response = await apiClient.post<School>("/schools", payload, { token });

    if (!response.data) {
      throw new Error("Response sekolah tidak tersedia.");
    }

    return response.data;
  },

  async update(token: string, schoolId: string, payload: SchoolPayload) {
    const response = await apiClient.put<School>(`/schools/${schoolId}`, payload, { token });

    if (!response.data) {
      throw new Error("Response sekolah tidak tersedia.");
    }

    return response.data;
  },

  async deactivate(token: string, schoolId: string) {
    const response = await apiClient.delete<School>(`/schools/${schoolId}`, { token });

    if (!response.data) {
      throw new Error("Response sekolah tidak tersedia.");
    }

    return response.data;
  },

  async forceDelete(token: string, schoolId: string) {
    await apiClient.delete<null>(`/schools/${schoolId}/force`, { token });
  },
};

export const classService = {
  async list(token: string, filters: ClassFilters = {}) {
    const response = await apiClient.get<SchoolClass[]>("/classes", {
      token,
      query: {
        search: filters.search,
        school_id: filters.school_id,
        status: filters.status,
        academic_year: filters.academic_year,
        grade_level: filters.grade_level,
        teacher_id: filters.teacher_id,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 15,
        sort_by: "name",
        sort_direction: "asc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async detail(token: string, classId: string) {
    const response = await apiClient.get<SchoolClass>(`/classes/${classId}`, { token });

    if (!response.data) {
      throw new Error("Detail kelas tidak tersedia.");
    }

    return response.data;
  },

  async create(token: string, payload: ClassPayload) {
    const response = await apiClient.post<SchoolClass>("/classes", payload, { token });

    if (!response.data) {
      throw new Error("Response kelas tidak tersedia.");
    }

    return response.data;
  },

  async update(token: string, classId: string, payload: ClassPayload) {
    const body = {
      name: payload.name,
      grade_level: payload.grade_level,
      academic_year: payload.academic_year,
      status: payload.status,
    };
    const response = await apiClient.put<SchoolClass>(`/classes/${classId}`, body, { token });

    if (!response.data) {
      throw new Error("Response kelas tidak tersedia.");
    }

    return response.data;
  },

  async deactivate(token: string, classId: string) {
    const response = await apiClient.delete<SchoolClass>(`/classes/${classId}`, { token });

    if (!response.data) {
      throw new Error("Response kelas tidak tersedia.");
    }

    return response.data;
  },

  async forceDelete(token: string, classId: string) {
    await apiClient.delete<null>(`/classes/${classId}/force`, { token });
  },

  async students(token: string, classId: string, filters: ClassStudentFilters = {}) {
    const response = await apiClient.get<ClassStudent[]>(`/classes/${classId}/students`, {
      token,
      query: {
        search: filters.search,
        status: filters.status,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 15,
        sort_by: "full_name",
        sort_direction: "asc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async assignTeacher(token: string, classId: string, teacherId: string) {
    const response = await apiClient.post<TeacherAssignment>(
      `/classes/${classId}/assign-teacher`,
      { teacher_id: teacherId },
      { token },
    );

    if (!response.data) {
      throw new Error("Response assignment guru tidak tersedia.");
    }

    return response.data;
  },

  async assignStudent(token: string, classId: string, studentId: string) {
    const response = await apiClient.post<StudentMembership>(
      `/classes/${classId}/assign-student`,
      { student_id: studentId },
      { token },
    );

    if (!response.data) {
      throw new Error("Response membership siswa tidak tersedia.");
    }

    return response.data;
  },
};

export const userManagementService = {
  async list(token: string, filters: UserFilters = {}) {
    const response = await apiClient.get<ManagedUser[]>("/users", {
      token,
      query: {
        role: filters.role,
        status: filters.status,
        school_id: filters.school_id,
        class_id: filters.class_id,
        search: filters.search,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 15,
        sort_by: "full_name",
        sort_direction: "asc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async detail(token: string, userId: string) {
    const response = await apiClient.get<ManagedUser>(`/users/${userId}`, { token });

    if (!response.data) {
      throw new Error("Detail pengguna tidak tersedia.");
    }

    return response.data;
  },

  async update(token: string, userId: string, payload: UserPayload) {
    const response = await apiClient.put<ManagedUser>(`/users/${userId}`, payload, { token });

    if (!response.data) {
      throw new Error("Response pengguna tidak tersedia.");
    }

    return response.data;
  },

  async updateStatus(token: string, userId: string, status: Extract<UserStatus, "approved" | "inactive">, reason?: string) {
    const response = await apiClient.patch<ManagedUser>(
      `/users/${userId}/status`,
      { status, reason },
      { token },
    );

    if (!response.data) {
      throw new Error("Response status pengguna tidak tersedia.");
    }

    return response.data;
  },

  async forcePasswordReset(token: string, userId: string, payload: { password: string; password_confirmation: string }) {
    const response = await apiClient.post<ManagedUser>(`/users/${userId}/force-password-reset`, payload, { token });

    if (!response.data) {
      throw new Error("Response reset password tidak tersedia.");
    }

    return response.data;
  },
};
