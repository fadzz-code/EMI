import { EmptyState } from "@/components/ui";

import { knowledgeEndpointMessage } from "./knowledge-base-utils";

export function KnowledgeBaseEmptyState() {
  return (
    <EmptyState
      description={`${knowledgeEndpointMessage} Buka daftar Basis AI untuk mengelola sumber pengetahuan yang sudah aktif.`}
      title="Detail pengetahuan belum tersedia"
    />
  );
}
