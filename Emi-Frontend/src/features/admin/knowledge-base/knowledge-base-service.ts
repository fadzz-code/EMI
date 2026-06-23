import type { KnowledgeEndpointStatus } from "./types";

export const knowledgeBaseService = {
  endpointStatus: "unavailable" satisfies KnowledgeEndpointStatus,
  endpoints: [] as string[],
};
