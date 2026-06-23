import { EmptyState } from "@/components/ui";

import { knowledgeEndpointMessage } from "./knowledge-base-utils";

export function KnowledgeBaseEmptyState() {
  return (
    <EmptyState
      description={`${knowledgeEndpointMessage} Data sumber pengetahuan belum dapat dimuat dari backend aktual.`}
      title="Basis pengetahuan AI belum tersedia"
    />
  );
}
