"use client";

import { useState } from "react";

import { Button, Modal, Textarea } from "@/components/ui";

export function ApprovalActionDialog({
  action,
  open,
  isSubmitting,
  onClose,
  onConfirm,
}: {
  action: "approve" | "reject";
  open: boolean;
  isSubmitting: boolean;
  onClose: () => void;
  onConfirm: (reviewNote: string) => void;
}) {
  const [reviewNote, setReviewNote] = useState("");
  const isReject = action === "reject";

  function handleConfirm() {
    onConfirm(reviewNote.trim());
  }

  return (
    <Modal
      onClose={onClose}
      open={open}
      title={isReject ? "Tolak Pendaftaran" : "Setujui Pendaftaran"}
    >
      <div className="grid gap-4">
        <p className="text-sm text-slate-700">
          {isReject
            ? "Alasan penolakan wajib diisi dan akan disimpan sebagai catatan review."
            : "Catatan review opsional. Sistem akan mengaktifkan akun dan membuat assignment atau membership sesuai role."}
        </p>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>{isReject ? "Alasan penolakan" : "Catatan review"}</span>
          <Textarea
            onChange={(event) => setReviewNote(event.target.value)}
            placeholder={
              isReject
                ? "Contoh: Data sekolah atau kelas tidak sesuai."
                : "Contoh: Data telah diverifikasi."
            }
            value={reviewNote}
          />
        </label>
        <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
          <Button disabled={isSubmitting} onClick={onClose} variant="ghost">
            Batal
          </Button>
          <Button
            disabled={isSubmitting || (isReject && !reviewNote.trim())}
            onClick={handleConfirm}
            variant={isReject ? "danger" : "secondary"}
          >
            {isSubmitting
              ? "Memproses..."
              : isReject
                ? "Tolak"
                : "Setujui"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
