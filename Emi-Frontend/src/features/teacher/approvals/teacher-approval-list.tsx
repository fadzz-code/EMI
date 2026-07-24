"use client";

import { useState } from "react";
import { format } from "date-fns";
import { id } from "date-fns/locale";
import { Check, Search, ShieldCheck } from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardHeader,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import {
  Select,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Modal } from "@/components/ui/modal";
import { Pagination } from "@/components/ui/pagination";
import {
  Table,
  TableHeader,
  TableCell,
} from "@/components/ui/table";
import { EmptyState } from "@/components/ui/states";

import {
  useApproveTeacherRequest,
  useTeacherApprovals,
} from "./teacher-approval-service";
import { type RegistrationRequest } from "@/features/admin/approvals/types";

export function TeacherApprovalList() {
  const [page, setPage] = useState(1);
  const [status, setStatus] = useState<string>("pending");

  const [search, setSearch] = useState("");
  const { data, isLoading, isError } = useTeacherApprovals({
    page,
    status,
    search,

  });
  const approveMutation = useApproveTeacherRequest();
  const [selectedRequest, setSelectedRequest] = useState<RegistrationRequest | null>(null);

  const [reviewNote, setReviewNote] = useState("");
  const handleApprove = () => {

    approveMutation.mutate(
      { id: selectedRequest?.id as string, review_note: reviewNote },
      {
        onSuccess: () => {
          toast.success("Akun siswa disetujui");
          setSelectedRequest(null);
          setReviewNote("");
        },
        onError: (error: any) => {
          toast.error(
            error.response?.data?.message || "Gagal menyetujui pendaftaran"
          );
        },
      }
    );
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <h2 className="text-xl font-semibold">Daftar Pendaftaran</h2>
          <p className="text-sm text-muted-foreground mt-1">
            Siswa yang disetujui akan ditambahkan ke kelas Anda.
          </p>
        </CardHeader>
        <div className="p-6 pt-0">
          <div className="flex flex-col sm:flex-row gap-4 mb-6">
            <div className="relative flex-1">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Cari nama atau email..."
                className="pl-8"
                value={search}
                onChange={(e: any) => {
                  setSearch(e.target.value);
                  setPage(1);
                }}
              />
            </div>
            <div className="w-full sm:w-48">
              <Select
                value={status}
                onChange={(e: any) => {
                  setStatus(e.target.value);
                  setPage(1);
                }}
              >
                  <option value="pending">Menunggu</option>
                  <option value="approved">Disetujui</option>
                  <option value="rejected">Ditolak</option>
              </Select>
            </div>
          </div>

          <div className="border rounded-md">
            <Table>
              <TableHeader>
                <tr>
                  <th className="px-4 py-3">Nama</th>
                  <th className="px-4 py-3">Email</th>
                  <th className="px-4 py-3">Kelas</th>
                  <th className="px-4 py-3">Tanggal Daftar</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3 text-right">Aksi</th>
                </tr>
              </TableHeader>
              <tbody>
                {isLoading ? Array.from({ length: 5 }).map((_, i) => (
                  <tr key={`skeleton-${i}`}>
                    <TableCell><div className="h-4 w-32 bg-gray-200 animate-pulse rounded"></div></TableCell>
                    <TableCell><div className="h-4 w-32 bg-gray-200 animate-pulse rounded"></div></TableCell>
                    <TableCell><div className="h-4 w-20 bg-gray-200 animate-pulse rounded"></div></TableCell>
                    <TableCell><div className="h-4 w-24 bg-gray-200 animate-pulse rounded"></div></TableCell>
                    <TableCell><div className="h-6 w-20 bg-gray-200 animate-pulse rounded-full"></div></TableCell>
                    <TableCell><div className="h-8 w-20 bg-gray-200 animate-pulse rounded ml-auto"></div></TableCell>
                  </tr>
                )) : isError ? (
                  <tr>
                    <td colSpan={6} className="text-center py-8">Gagal memuat data pendaftaran.</td>
                  </tr>
                ) : !data?.data?.length ? (
                  <tr>
                    <td colSpan={6} className="p-0">
                      <EmptyState
                        title="Tidak ada pendaftaran"
                        description="Belum ada pendaftaran siswa dengan status ini."
                      />
                    </td>
                  </tr>
                ) : data.data.map(req => (
                  <tr key={req.id}>
                    <TableCell className="font-medium">{(req.user as any)?.name}</TableCell>
                    <TableCell>{req.user?.email}</TableCell>
                    <TableCell>{req.school_class?.name}</TableCell>
                    <TableCell>{req.created_at ? format(new Date(req.created_at), "dd MMM yyyy", { locale: id }) : "-"}</TableCell>
                    <TableCell>
                      <Badge
                        tone={
                          (req.status === "approved" ? "success" : req.status === "rejected" ? "destructive" : "neutral") as any
                        }
                      >
                        {req.status === "approved" ? "Disetujui" : req.status === "rejected" ? "Ditolak" : "Menunggu"}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-right">
                      {req.status === "pending" && (
                        <Button
                          variant="secondary"
                          onClick={() => setSelectedRequest(req)}
                        >
                          <Check className="h-4 w-4 mr-1 inline" />
                          Setujui
                        </Button>
                      )}
                    </TableCell>
                  </tr>
                ))}
              </tbody>
            </Table>
          </div>

          {data && data.last_page > 1 && (
            <div className="mt-4 flex justify-end">
              <Pagination
                page={page}
                totalPages={data.last_page}
                onPageChange={setPage}
              />
            </div>
          )}
        </div>
      </Card>

      <Modal
        open={Boolean(selectedRequest)}
        onClose={() => {
          setSelectedRequest(null);
          setReviewNote("");
        }}
        title="Setujui Pendaftaran Siswa"
      >
          <div className="text-sm text-muted-foreground mb-4">
            Apakah Anda yakin ingin menyetujui siswa{" "}
            <span className="font-semibold text-foreground">
              {(selectedRequest?.user as any)?.name}
            </span>
            ? Siswa akan otomatis dimasukkan ke kelas Anda.
          </div>
          <div className="space-y-2 mb-4">
            <label htmlFor="note" className="text-sm font-medium">Catatan (Opsional)</label>
            <Textarea
              id="note"
              placeholder="Tambahkan pesan sambutan atau catatan..."
              value={reviewNote}
              onChange={(e: any) => setReviewNote(e.target.value)}
            />
          </div>
          <div className="flex justify-end gap-2 mt-4">
            <Button
              variant="secondary"
              onClick={() => {
                setSelectedRequest(null);
                setReviewNote("");
              }}
              disabled={approveMutation.isPending}
            >
              Batal
            </Button>
            <Button
              onClick={handleApprove}
              disabled={approveMutation.isPending}
            >
              {approveMutation.isPending ? "Menyimpan..." : "Setujui Siswa"}
            </Button>
          </div>
      </Modal>
    </div>
  );
}