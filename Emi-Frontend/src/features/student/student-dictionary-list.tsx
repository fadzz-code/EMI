"use client";

import { type FormEvent, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowRight, Languages, Search } from "lucide-react";

import {
  AudioPlayer,
  Badge,
  Button,
  Card,
  CardContent,
  EmptyState,
  ErrorState,
  FilterPanel,
  Input,
  LoadingState,
  PageHeader,
  Pagination,
  Select,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentDictionaryService } from "./student-dictionary-service";
import { formatOptional } from "./student-utils";

export function StudentDictionaryList() {
  const { token } = useAuth();
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [language, setLanguage] = useState<"all" | "indonesia" | "english" | "mekongga">("all");
  const [categoryId, setCategoryId] = useState("");

  const filters = useMemo(
    () => ({
      search,
      language,
      category_id: categoryId,
      page,
      per_page: 12,
    }),
    [categoryId, language, page, search],
  );

  const entriesQuery = useQuery({
    queryKey: ["student", "dictionary", "entries", filters],
    queryFn: () => studentDictionaryService.entries(token ?? "", filters),
    enabled: Boolean(token),
  });
  const categorySourceQuery = useQuery({
    queryKey: ["student", "dictionary", "categories-source"],
    queryFn: () => studentDictionaryService.entries(token ?? "", { per_page: 100 }),
    enabled: Boolean(token),
  });

  const entries = entriesQuery.data?.items ?? [];
  const meta = entriesQuery.data?.meta;
  const categories = Array.from(
    new Map(
      (categorySourceQuery.data?.items ?? [])
        .map((entry) => entry.category)
        .filter((category): category is NonNullable<typeof category> => Boolean(category?.id))
        .map((category) => [category.id, category]),
    ).values(),
  );

  function applySearch(event?: FormEvent<HTMLFormElement>) {
    event?.preventDefault();
    setPage(1);
    setSearch(searchInput.trim());
  }

  // Live search with short debounce
  useEffect(() => {
    const timer = setTimeout(() => {
      setSearch(searchInput.trim());
      setPage(1);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchInput]);

  return (
    <div className="grid gap-8">
      <PageHeader
        badge="Siswa"
        description="Cari arti kata, contoh kalimat, dan audio Bahasa Mekongga."
        title="Kamus Mekongga"
      />

      <form onSubmit={applySearch}>
        <FilterPanel className="md:grid-cols-4">
          <label className="grid gap-2 text-sm font-bold text-ink md:col-span-2">
            <span>Cari kata</span>
            <Input
              onChange={(event) => setSearchInput(event.target.value)}
              placeholder="Cari Indonesia, Inggris, atau Mekongga"
              type="search"
              value={searchInput}
            />
          </label>
          <label className="grid gap-2 text-sm font-bold text-ink">
            <span>Bahasa</span>
            <Select
              onChange={(event) => {
                setLanguage(event.target.value as typeof language);
                setPage(1);
              }}
              value={language}
            >
              <option value="all">Semua bahasa</option>
              <option value="indonesia">Indonesia</option>
              <option value="english">Inggris</option>
              <option value="mekongga">Mekongga</option>
            </Select>
          </label>
          <label className="grid gap-2 text-sm font-bold text-ink">
            <span>Kategori</span>
            <Select
              onChange={(event) => {
                setCategoryId(event.target.value);
                setPage(1);
              }}
              value={categoryId}
            >
              <option value="">Semua kategori</option>
              {categories.map((category) => (
                <option key={category.id} value={category.id}>
                  {category.name}
                </option>
              ))}
            </Select>
          </label>
          <div className="flex items-end md:col-span-4">
            <Button className="w-full gap-2 md:w-fit" type="submit" variant="secondary">
              <Search className="size-5" strokeWidth={2.5} />
              Terapkan Filter
            </Button>
          </div>
        </FilterPanel>
      </form>

      <Card>
        <CardContent>
          {entriesQuery.isLoading ? <LoadingState title="Memuat kamus" /> : null}
          {entriesQuery.isError ? (
            <ErrorState
              description={getFirstApiError(entriesQuery.error)}
              onRetry={() => void entriesQuery.refetch()}
              title="Gagal memuat kamus"
            />
          ) : null}

          {!entriesQuery.isLoading && !entriesQuery.isError ? (
            entries.length === 0 ? (
              <EmptyState description="Belum ada kata sesuai pencarian atau filter saat ini." title="Kamus kosong" />
            ) : (
              <div className="grid gap-4">
                <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                  {entries.map((entry) => (
                    <article className="flex h-full flex-col rounded-2xl border-2 border-border bg-surface p-5 transition hover:-translate-y-1 hover:shadow-emi" key={entry.id}>
                      <div className="flex flex-wrap items-center gap-2">
                        <Badge tone="blue">{entry.category?.name ?? "Tanpa kategori"}</Badge>
                        <Badge tone={entry.audio ? "yellow" : "neutral"}>{entry.audio ? "Audio tersedia" : "Audio belum tersedia"}</Badge>
                      </div>
                      <div className="mt-4 flex items-start gap-3">
                        <div className="inline-flex size-12 shrink-0 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-ink">
                          <Languages className="size-6" strokeWidth={2.5} />
                        </div>
                        <div>
                          <p className="text-xs font-black uppercase tracking-[0.08em] text-muted">Bahasa Mekongga</p>
                          <h2 className="text-2xl font-black text-ink">{entry.mekongga}</h2>
                        </div>
                      </div>
                      <div className="mt-4 grid gap-2 rounded-xl border-2 border-border bg-surface-muted p-4">
                        <p className="text-sm font-semibold text-muted">Indonesia: <span className="font-black text-ink">{entry.indonesia}</span></p>
                        <p className="text-sm font-semibold text-muted">Inggris: <span className="font-black text-ink">{entry.english}</span></p>
                      </div>
                      <p className="mt-4 flex-1 text-sm font-semibold leading-6 text-muted">Contoh: {formatOptional(entry.example_mekongga)}</p>
                      <div className="mt-4">
                        <AudioPlayer src={entry.audio?.url} title="Mekongga" />
                      </div>
                      <Link className="mt-4 inline-flex min-h-12 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-4 py-2 text-sm font-black text-primary-foreground shadow-emi transition-transform hover:-translate-y-0.5" href={`/student/dictionary/${entry.id}`}>
                        Lihat Detail
                        <ArrowRight className="size-5" strokeWidth={2.5} />
                      </Link>
                    </article>
                  ))}
                </div>
                <Pagination onPageChange={setPage} page={meta?.current_page ?? page} totalPages={meta?.last_page ?? 1} />
              </div>
            )
          ) : null}
        </CardContent>
      </Card>
    </div>
  );
}
