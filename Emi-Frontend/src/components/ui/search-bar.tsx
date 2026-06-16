"use client";

import { Input } from "./input";

export function SearchBar({
  value,
  onChange,
  placeholder = "Cari data",
}: {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}) {
  return (
    <Input
      aria-label={placeholder}
      onChange={(event) => onChange(event.target.value)}
      placeholder={placeholder}
      type="search"
      value={value}
    />
  );
}
