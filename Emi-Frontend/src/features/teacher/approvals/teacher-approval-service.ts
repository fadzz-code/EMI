import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { apiClient, type ApiPaginationMeta } from "@/lib/api-client";
import {
  type RegistrationRequest,
  type RegistrationRequestStatus,
} from "@/features/admin/approvals/types";

interface TeacherRegistrationRequestsResult {
  items: RegistrationRequest[];
  meta?: ApiPaginationMeta;
}

interface TeacherRegistrationRequestsParams {
  status?: RegistrationRequestStatus;
  search?: string;
  page?: number;
  per_page?: number;
}

export const getTeacherRegistrationRequests = async (
  token: string,
  params?: TeacherRegistrationRequestsParams
): Promise<TeacherRegistrationRequestsResult> => {
  const response = await apiClient.get<RegistrationRequest[]>(
    "/teacher/registration-requests",
    {
      token,
      query: {
        status: params?.status,
        search: params?.search,
        page: params?.page,
        per_page: params?.per_page,
      },
    }
  );
  return {
    items: response.data ?? [],
    meta: response.meta as ApiPaginationMeta,
  };
};

export const approveTeacherRegistrationRequest = async (
  token: string,
  data: {
    id: string;
    review_note?: string;
  }
) => {
  const response = await apiClient.post(
    `/teacher/registration-requests/${data.id}/approve`,
    { review_note: data.review_note },
    { token }
  );
  return response.data;
};

export const useTeacherApprovals = (
  token: string | null,
  params?: TeacherRegistrationRequestsParams
) => {
  return useQuery({
    queryKey: ["teacher", "registration-requests", params],
    queryFn: () => getTeacherRegistrationRequests(token ?? "", params),
    enabled: Boolean(token),
  });
};

export const useApproveTeacherRequest = (token: string | null) => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { id: string; review_note?: string }) =>
      approveTeacherRegistrationRequest(token ?? "", data),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["teacher", "registration-requests"],
      });
      queryClient.invalidateQueries({
        queryKey: ["teacher", "students"],
      });
    },
  });
};