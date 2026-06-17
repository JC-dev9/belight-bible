/** Junta classes condicionais, ignorando valores falsy. Sem dependências. */
export function cn(...classes: Array<string | false | null | undefined>): string {
  return classes.filter(Boolean).join(" ");
}
