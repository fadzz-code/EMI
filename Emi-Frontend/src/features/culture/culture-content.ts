export const cultureFileTypes = ["image", "audio", "pdf", "video"] as const;
export const cultureUrlTypes = ["youtube", "article", "link"] as const;

export function isCultureFileType(type: string) {
  return cultureFileTypes.includes(type as (typeof cultureFileTypes)[number]);
}

export function cultureMediaAccept(type: string) {
  return { image: "image/jpeg,image/png,image/webp", audio: "audio/mpeg,audio/wav,audio/mp4,audio/ogg,audio/webm", pdf: "application/pdf", video: "video/mp4,video/webm" }[type] ?? "";
}

export function cultureFileMatches(type: string, file: Pick<File, "type">) {
  if (type === "image") return ["image/jpeg", "image/png", "image/webp"].includes(file.type);
  if (type === "audio") return file.type.startsWith("audio/");
  if (type === "pdf") return file.type === "application/pdf";
  if (type === "video") return ["video/mp4", "video/webm"].includes(file.type);
  return false;
}

export function cultureFields(type: string, mediaId: string | null, externalUrl: string | null) {
  return isCultureFileType(type) ? { media_id: mediaId, external_url: null } : { media_id: null, external_url: externalUrl };
}

export function cultureTypeTransition(previousType: string, nextType: string, originalMediaId: string | null = null) {
  return {
    file: null,
    mediaId: nextType === previousType && isCultureFileType(nextType) ? originalMediaId : null,
    externalUrl: "",
  };
}
