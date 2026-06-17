import Image from "next/image";
import Link from "next/link";

import { cn } from "@/lib/cn";
import { site } from "@/lib/site";

/**
 * Marca (logótipo + nome), reutilizada no header e no footer.
 * `wordmark={false}` mostra só o símbolo.
 */
export function Logo({
  className,
  wordmark = true,
}: {
  className?: string;
  wordmark?: boolean;
}) {
  return (
    <Link
      href="/"
      aria-label={site.name}
      className={cn("inline-flex items-center gap-2.5", className)}
    >
      <Image
        src="/logo.png"
        alt=""
        width={36}
        height={36}
        priority
        className="size-9"
      />
      {wordmark && (
        <span className="text-lg font-semibold tracking-tight">{site.name}</span>
      )}
    </Link>
  );
}
