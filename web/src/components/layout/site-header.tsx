import Link from "next/link";

import { Button } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { mainNav } from "@/lib/site";

import { Logo } from "./logo";
import { MobileNav } from "./mobile-nav";
import { ThemeToggle } from "./theme-toggle";

/**
 * Cabeçalho global: marca e navegação encostadas à esquerda; ações à direita
 * (tema + CTA em desktop, hambúrguer em mobile). Cada link tem um sublinhado
 * traseiro (scale-x a partir da esquerda) no hover — animado só por transform.
 */
export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 border-b border-border bg-background/80 backdrop-blur">
      <Container className="flex h-16 items-center justify-between gap-8">
        <div className="flex items-center gap-8">
          <Logo />

          <nav className="hidden items-center gap-7 md:flex">
            {mainNav.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className="relative text-sm text-muted-foreground transition-colors hover:text-foreground after:absolute after:-bottom-1.5 after:left-0 after:h-px after:w-full after:origin-left after:scale-x-0 after:bg-brand after:transition-transform after:duration-300 after:ease-out hover:after:scale-x-100"
              >
                {item.label}
              </Link>
            ))}
          </nav>
        </div>

        <div className="flex items-center gap-2 sm:gap-3">
          <ThemeToggle />
          <Button href="/app" size="sm" className="hidden md:inline-flex">
            Obter a app
          </Button>
          <MobileNav />
        </div>
      </Container>
    </header>
  );
}
