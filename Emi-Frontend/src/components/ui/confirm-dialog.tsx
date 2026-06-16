"use client";

import { Button } from "./button";
import { Modal } from "./modal";

export function ConfirmDialog({
  open,
  title,
  description,
  confirmLabel = "Ya, lanjutkan",
  onCancel,
  onConfirm,
}: {
  open: boolean;
  title: string;
  description: string;
  confirmLabel?: string;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  return (
    <Modal onClose={onCancel} open={open} title={title}>
      <p className="text-sm text-slate-700">{description}</p>
      <div className="mt-5 flex flex-col gap-3 sm:flex-row sm:justify-end">
        <Button onClick={onCancel} variant="ghost">
          Batal
        </Button>
        <Button onClick={onConfirm} variant="danger">
          {confirmLabel}
        </Button>
      </div>
    </Modal>
  );
}
