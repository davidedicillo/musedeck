export type DictationTarget = "current" | "main";

export function dictationTarget(frontmostBundleId: string | null): DictationTarget {
  return frontmostBundleId === "com.meta.endo" ? "current" : "main";
}
