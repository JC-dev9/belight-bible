import { Container } from "@/components/ui/container";

/** Cabeçalho consistente para páginas internas (título + subtítulo). */
export function PageHeader({
  eyebrow,
  title,
  subtitle,
}: {
  eyebrow?: string;
  title: string;
  subtitle?: string;
}) {
  return (
    <Container className="py-16 text-center lg:py-20">
      {eyebrow && (
        <span className="text-sm font-semibold uppercase tracking-wide text-brand">
          {eyebrow}
        </span>
      )}
      <h1 className="mt-3 text-balance font-serif text-4xl font-medium tracking-tight sm:text-5xl">
        {title}
      </h1>
      {subtitle && (
        <p className="mx-auto mt-4 max-w-2xl text-pretty text-muted-foreground">
          {subtitle}
        </p>
      )}
    </Container>
  );
}
