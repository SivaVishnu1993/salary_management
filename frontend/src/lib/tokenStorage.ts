// Access-token persistence. localStorage keeps the session across reloads; the
// trade-off (readable by injected scripts) is documented in docs/DECISIONS.md.
const KEY = 'acme.salary.token'

export const tokenStorage = {
  get(): string | null {
    try {
      return window.localStorage.getItem(KEY)
    } catch {
      return null
    }
  },
  set(token: string): void {
    try {
      window.localStorage.setItem(KEY, token)
    } catch {
      // Storage unavailable (private mode): the session lasts for this page only.
    }
  },
  clear(): void {
    try {
      window.localStorage.removeItem(KEY)
    } catch {
      // Nothing to clear.
    }
  },
}
