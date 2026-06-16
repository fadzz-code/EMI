"use client";

import { Button } from "./button";

export function Pagination({
  page,
  totalPages,
  onPageChange,
}: {
  page: number;
  totalPages: number;
  onPageChange: (page: number) => void;
}) {
  return (
    <div className="flex items-center justify-between gap-3">
      <Button
        disabled={page <= 1}
        onClick={() => onPageChange(page - 1)}
        variant="ghost"
      >
        Sebelumnya
      </Button>
      <span className="text-sm font-bold text-ink">
        Halaman {page} dari {Math.max(totalPages, 1)}
      </span>
      <Button
        disabled={page >= totalPages}
        onClick={() => onPageChange(page + 1)}
        variant="ghost"
      >
        Berikutnya
      </Button>
    </div>
  );
}
