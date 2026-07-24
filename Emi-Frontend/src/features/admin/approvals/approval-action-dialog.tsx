"use client";

import { useState } from "react";
import { Check, X } from "lucide-react";

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
        <div
          className={[
            "rounded-[10px] border-2 border-border p-4 text-sm font-bold leading-6 shadow-emi",
            isReject ? "bg-danger/15 text-danger" : "bg-success/20 text-success",
          ].join(" ")}
        >
          {isReject
            ? "Alasan penolakan wajib diisi dan akan disimpan sebagai catatan review."
            : "Catatan review opsional. Sistem akan mengaktifkan akun dan membuat assignment atau membership sesuai role."}
        </div>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>{isReject ? "Alasan penolakan" : "Catatan review"}</span>
          <Textarea
            className="rounded-[8px] border-2 border-border bg-surface text-sm shadow-emi focus:ring-primary"
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
          <Button
            className="border-2 border-border bg-surface shadow-emi"
            disabled={isSubmitting}
            onClick={onClose}
            variant="ghost"
          >
            Batal
          </Button>
          <Button
            className={[
              "border-2 border-border font-black shadow-emi",
              isReject
                ? "bg-danger-muted text-danger hover:bg-danger/20"
                : "bg-success text-success-foreground hover:bg-success/80",
            ].join(" ")}
            disabled={isSubmitting || (isReject && !reviewNote.trim())}
            onClick={handleConfirm}
            variant={isReject ? "danger" : "secondary"}
          >
            {!isSubmitting && isReject ? <X aria-hidden="true" className="mr-2 size-4" /> : null}
            {!isSubmitting && !isReject ? <Check aria-hidden="true" className="mr-2 size-4" /> : null}
            {isSubmitting ? "Memproses..." : isReject ? "Tolak" : "Setujui"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
