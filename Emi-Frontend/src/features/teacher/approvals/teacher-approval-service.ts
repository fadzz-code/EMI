import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { apiClient } from "@/lib/api-client";
import {
  type RegistrationRequest,
  type RegistrationRequestStatus,
} from "@/features/admin/approvals/types";

interface TeacherRegistrationRequestsResponse {
  data: RegistrationRequest[];
  current_page: number;
  last_page: number;
  total: number;
  per_page: number;
}

interface TeacherRegistrationRequestsParams {
  status?: RegistrationRequestStatus;
  search?: string;
  page?: number;
  per_page?: number;
}

export const getTeacherRegistrationRequests = async (
  params?: TeacherRegistrationRequestsParams
) => {
  const response = await apiClient.get<TeacherRegistrationRequestsResponse>(
    "/teacher/registration-requests",
    {
      query: {
        status: params?.status,
        search: params?.search,
        page: params?.page,
        per_page: params?.per_page,
      },
    }
  );
  return response.data;
};

export const approveTeacherRegistrationRequest = async (data: {
  id: string;
  review_note?: string;
}) => {
  const response = await apiClient.post(
    `/teacher/registration-requests/${data.id}/approve`,
    { review_note: data.review_note }
  );
  return response.data;
};

export const useTeacherApprovals = (params?: TeacherRegistrationRequestsParams) => {
  return useQuery({
    queryKey: ["teacher", "registration-requests", params],
    queryFn: () => getTeacherRegistrationRequests(params),
  });
};

export const useApproveTeacherRequest = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: approveTeacherRegistrationRequest,
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