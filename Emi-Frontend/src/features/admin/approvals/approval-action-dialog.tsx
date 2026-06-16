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
        <div
          className={[
            "rounded-[10px] border-2 border-[#241914] p-4 text-sm font-bold leading-6 shadow-[3px_3px_0_#241914]",
            isReject ? "bg-[#ffdad6] text-[#93000a]" : "bg-[#94f990] text-[#004910]",
          ].join(" ")}
        >
          {isReject
            ? "Alasan penolakan wajib diisi dan akan disimpan sebagai catatan review."
            : "Catatan review opsional. Sistem akan mengaktifkan akun dan membuat assignment atau membership sesuai role."}
        </div>
        <label className="grid gap-2 text-sm font-bold text-[#241914]">
          <span>{isReject ? "Alasan penolakan" : "Catatan review"}</span>
          <Textarea
            className="rounded-[8px] border-2 border-[#241914] bg-[#fff8f6] text-sm shadow-[2px_2px_0_#241914] focus:ring-[#fdd758]"
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
            className="border-2 border-[#241914] bg-[#fff8f6] shadow-[2px_2px_0_#241914]"
            disabled={isSubmitting}
            onClick={onClose}
            variant="ghost"
          >
            Batal
          </Button>
          <Button
            className={[
              "border-2 border-[#241914] font-black shadow-[3px_3px_0_#241914]",
              isReject
                ? "bg-[#ffdad6] text-[#93000a] hover:bg-[#ffe6e2]"
                : "bg-[#5bbe5d] text-[#004910] hover:bg-[#75d877]",
            ].join(" ")}
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
