// Preact sanitize text inserted into the dom, except for attributes.
// This helper is here specifically for the attributes 'href' and 'src' which can be used to inject malicious content into the dom.
export function sanitize(text?: string | null): string {
  if (!text) return "";

  // Reject control characters (null bytes, newlines, tabs, etc.)
  if (/[\u0000-\u001F\u007F]/.test(text)) {
    return "";
  }

  const trimmed = text.trim();
  if (!trimmed) return "";

  // Allow clean relative paths (e.g. "/profile"), reject protocol-relative "//..."
  if (trimmed.startsWith("/")) {
    return trimmed.startsWith("//") ? "" : trimmed;
  }

  try {
    const parsed = new URL(trimmed);
    if (parsed.protocol === "https:" || parsed.protocol === "http:") {
      return parsed.toString();
    }
    return "";
  } catch {
    return "";
  }
}