import Link from "next/link";

import { footerNav, mainNav, site } from "@/lib/site";
import { Container } from "@/components/ui/container";

import { Logo } from "./logo";

/** Rodapé global com marca, navegação e ligações legais. */
export function SiteFooter() {
  return (
    <footer className="mt-auto border-t border-border">
      <Container className="flex flex-col gap-6 py-10 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex flex-col gap-2">
          <Logo />
          <p className="text-sm text-muted-foreground">
            © {new Date().getFullYear()} {site.name}. Todos os direitos reservados.
          </p>
        </div>
        <nav className="flex flex-wrap gap-x-6 gap-y-2">
          {[...mainNav, ...footerNav].map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="text-sm text-muted-foreground transition-colors hover:text-foreground"
            >
              {item.label}
            </Link>
          ))}
        </nav>
      </Container>
    </footer>
  );
}
