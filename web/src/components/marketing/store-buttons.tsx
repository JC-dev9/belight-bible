import { cn } from "@/lib/cn";
import { appStores } from "@/lib/site";

import { AppleIcon, PlayIcon } from "./icons";

/**
 * Badges "Descarregar na App Store / Google Play".
 * Enquanto os links de site.ts estiverem vazios, mostra um estado "Em breve"
 * (não-clicável) — assim a UI fica pronta para o lançamento sem alterar markup.
 */
type Store = {
  href: string;
  icon: (props: { className?: string }) => React.ReactElement;
  top: string;
  bottom: string;
};

const stores: Store[] = [
  { href: appStores.appStore, icon: AppleIcon, top: "Descarregar na", bottom: "App Store" },
  { href: appStores.playStore, icon: PlayIcon, top: "Disponível no", bottom: "Google Play" },
];

const badge =
  "group inline-flex h-14 items-center gap-3 rounded-[var(--radius-base)] border border-border px-5 transition-[transform,background-color] duration-200 will-change-transform";

export function StoreButtons({ className }: { className?: string }) {
  return (
    <div className={cn("flex flex-col gap-3 sm:flex-row", className)}>
      {stores.map(({ href, icon: Icon, top, bottom }) => {
        const content = (
          <>
            <Icon className="size-7 shrink-0" />
            <span className="flex flex-col text-left leading-none">
              <span className="text-[0.7rem] text-muted-foreground">{top}</span>
              <span className="text-base font-semibold">{bottom}</span>
            </span>
            {!href && (
              <span className="ml-1 rounded-full bg-muted px-2 py-0.5 text-[0.65rem] font-medium text-muted-foreground">
                Em breve
              </span>
            )}
          </>
        );

        return href ? (
          <a
            key={bottom}
            href={href}
            className={cn(badge, "bg-foreground text-background hover:-translate-y-0.5")}
          >
            {content}
          </a>
        ) : (
          <div
            key={bottom}
            aria-disabled
            className={cn(badge, "cursor-default bg-muted/40 text-foreground")}
          >
            {content}
          </div>
        );
      })}
    </div>
  );
}
