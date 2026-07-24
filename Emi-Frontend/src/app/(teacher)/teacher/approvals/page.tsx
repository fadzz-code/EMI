import { Suspense } from "react";
import { Loader2 } from "lucide-react";

import { TeacherApprovalList } from "@/features/teacher/approvals/teacher-approval-list";

export const metadata = {
  title: "Persetujuan Siswa | EMI Speaking",
};

export default function TeacherApprovalsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Persetujuan Akun Siswa</h1>
        <p className="text-muted-foreground mt-2">
          Periksa dan setujui pendaftaran akun siswa baru di kelas Anda.
        </p>
      </div>
      
      <Suspense fallback={<Loader2 className="h-8 w-8 animate-spin mx-auto mt-8 text-muted-foreground" />}>
        <TeacherApprovalList />
      </Suspense>
    </div>
  );
}