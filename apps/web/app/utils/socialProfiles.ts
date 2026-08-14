export type SocialPlatform = "instagram" | "youtube";

export interface SocialProfileNormalization {
  url: string;
  error: string;
}

const platformLabels: Record<SocialPlatform, string> = {
  instagram: "Instagram",
  youtube: "YouTube",
};

const platformHosts: Record<SocialPlatform, Set<string>> = {
  instagram: new Set(["instagram.com", "www.instagram.com", "m.instagram.com"]),
  youtube: new Set(["youtube.com", "www.youtube.com", "m.youtube.com"]),
};

function invalid(platform: SocialPlatform): SocialProfileNormalization {
  const example =
    platform === "instagram"
      ? "@perfil ou instagram.com/perfil"
      : "@canal ou youtube.com/@canal";

  return {
    url: "",
    error: `Informe um perfil válido do ${platformLabels[platform]}, como ${example}.`,
  };
}

function isValidHandle(handle: string, platform: SocialPlatform) {
  const pattern =
    platform === "instagram"
      ? /^[A-Za-z0-9._]{1,30}$/
      : /^[\p{L}\p{N}._-]{3,30}$/u;

  return pattern.test(handle);
}

function canonicalUrl(handle: string, platform: SocialPlatform) {
  return platform === "instagram"
    ? `https://www.instagram.com/${handle}/`
    : `https://www.youtube.com/@${handle}`;
}

function handleFromUrl(value: string, platform: SocialPlatform) {
  try {
    const candidate = /^https?:\/\//i.test(value) ? value : `https://${value}`;
    const parsed = new URL(candidate);

    if (
      parsed.username ||
      parsed.password ||
      parsed.port ||
      !platformHosts[platform].has(parsed.hostname.toLowerCase())
    ) {
      return "";
    }

    const segments = parsed.pathname.split("/").filter(Boolean);
    if (segments.length !== 1) return "";

    const segment = segments[0] ?? "";
    if (platform === "instagram") return segment;
    return segment.startsWith("@") ? segment.slice(1) : "";
  } catch {
    return "";
  }
}

export function normalizeSocialProfile(
  value: string,
  platform: SocialPlatform,
): SocialProfileNormalization {
  const trimmed = value.trim();
  if (!trimmed) return { url: "", error: "" };

  const looksLikeUrl =
    /^https?:\/\//i.test(trimmed) ||
    trimmed.includes("/") ||
    platformHosts[platform].has(trimmed.toLowerCase());
  const handle = looksLikeUrl
    ? handleFromUrl(trimmed, platform)
    : trimmed.replace(/^@/, "");

  if (!isValidHandle(handle, platform)) return invalid(platform);

  return {
    url: canonicalUrl(handle, platform),
    error: "",
  };
}
