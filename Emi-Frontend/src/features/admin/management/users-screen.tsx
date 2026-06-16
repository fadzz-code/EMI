"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import {
  Badge,
  Button,
  Card,
  CardContent,
  EmptyState,
  ErrorState,
  FilterPanel,
  Input,
  LoadingState,
  Pagination,
  Select,
  Table,
  TableCell,
  TableHeader,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import type { UserRole } from "@/lib/roles";

import { userManagementService } from "./management-service";
import {
  activeClassLabel,
  roleLabel,
  statusTone,
  userStatusLabel,
} from "./management-utils";
import type { UserStatus } from "./types";

export function UsersScreen() {
  const { token } = useAuth();
  const [page, setPage] = useState(1);
  const [role, setRole] = useState<Extract<UserRole, "teacher" | "student">>("teacher");
  const [status, setStatus] = useState<UserStatus | "">("");
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");

  const filters = useMemo(
    () => ({
      role,
      status,
      search,
      page,
      per_page: 15,
    }),
    [page, role, search, status],
  );

  const usersQuery = useQuery({
    queryKey: ["admin", "users", filters],
    queryFn: () => userManagementService.list(token ?? "", filters),
    enabled: Boolean(token),
  });

  const users = usersQuery.data?.items ?? [];
  const meta = usersQuery.data?.meta;

  function applySearch() {
    setPage(1);
    setSearch(searchInput.trim());
  }

  return (
    <div className="grid gap-6">
      <header>
        <Badge tone="yellow">Admin</Badge>
        <h1 className="mt-2 text-3xl font-black text-ink">Data Guru & Siswa</h1>
        <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
          Kelola data pengguna pembelajaran. Admin tidak menjadi target utama
          screen ini.
        </p>
      </header>

      <div className="flex flex-wrap gap-2">
        {[
          { label: "Guru", value: "teacher" },
          { label: "Siswa", value: "student" },
        ].map((item) => (
          <Button
            key={item.value}
            onClick={() => {
              setRole(item.value as Extract<UserRole, "teacher" | "student">);
              setPage(1);
            }}
            variant={role === item.value ? "secondary" : "ghost"}
          >
            {item.label}
          </Button>
        ))}
      </div>

      <FilterPanel className="md:grid-cols-3">
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Cari nama/email</span>
          <Input
            onChange={(event) => setSearchInput(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter") {
                applySearch();
              }
            }}
            placeholder="Contoh: budi@example.com"
            value={searchInput}
          />
        </label>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Status</span>
          <Select
            onChange={(event) => {
              setStatus(event.target.value as UserStatus | "");
              setPage(1);
            }}
            value={status}
          >
            <option value="">Semua status</option>
            <option value="approved">Disetujui</option>
            <option value="inactive">Nonaktif</option>
            <option value="pending">Pending</option>
            <option value="rejected">Ditolak</option>
          </Select>
        </label>
        <div className="flex items-end">
          <Button className="w-full" onClick={applySearch} variant="secondary">
            Terapkan Filter
          </Button>
        </div>
      </FilterPanel>

      <Card>
        <CardContent>
          {usersQuery.isLoading ? <LoadingState title="Memuat pengguna" /> : null}
          {usersQuery.isError ? (
            <ErrorState
              description={getFirstApiError(usersQuery.error)}
              onRetry={() => void usersQuery.refetch()}
              title="Gagal memuat pengguna"
            />
          ) : null}
          {!usersQuery.isLoading && !usersQuery.isError ? (
            users.length === 0 ? (
              <EmptyState
                description="Tidak ada pengguna sesuai filter saat ini."
                title="Data pengguna kosong"
              />
            ) : (
              <div className="grid gap-4">
                <Table>
                  <TableHeader>
                    <tr>
                      <th className="px-4 py-3">Nama</th>
                      <th className="px-4 py-3">Email</th>
                      <th className="px-4 py-3">Role</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3">Sekolah</th>
                      <th className="px-4 py-3">Kelas</th>
                      <th className="px-4 py-3">Aksi</th>
                    </tr>
                  </TableHeader>
                  <tbody>
                    {users.map((user) => (
                      <tr key={user.id}>
                        <TableCell className="font-black text-ink">
                          {user.full_name}
                        </TableCell>
                        <TableCell>{user.email}</TableCell>
                        <TableCell>{roleLabel(user.role)}</TableCell>
                        <TableCell>
                          <Badge tone={statusTone(user.status)}>
                            {userStatusLabel(user.status)}
                          </Badge>
                        </TableCell>
                        <TableCell>{user.active_school?.name ?? "-"}</TableCell>
                        <TableCell>{activeClassLabel(user)}</TableCell>
                        <TableCell>
                          <Link
                            className="inline-flex min-h-9 items-center rounded-lg border-2 border-ink bg-white px-3 py-1 text-xs font-black text-ink hover:bg-yellow-100"
                            href={`/admin/users/${user.id}`}
                          >
                            Detail/Edit
                          </Link>
                        </TableCell>
                      </tr>
                    ))}
                  </tbody>
                </Table>
                <Pagination
                  onPageChange={setPage}
                  page={meta?.current_page ?? page}
                  totalPages={meta?.last_page ?? 1}
                />
              </div>
            )
          ) : null}
        </CardContent>
      </Card>
    </div>
  );
}
