import Image from "next/image";

import { cn } from "@/lib/cn";

/**
 * Moldura de telemóvel à volta de uma captura real da app (já recortada, sem
 * a barra de estado nem os botões do sistema). A imagem escala com
 * `w-full h-auto` (sem corte nem letterbox); o bisel arredondado dá o look de
 * dispositivo.
 */
export function PhoneFrame({
  src,
  alt,
  className,
  width = 921,
  height = 1851,
  priority = false,
}: {
  src: string;
  alt: string;
  className?: string;
  width?: number;
  height?: number;
  priority?: boolean;
}) {
  return (
    <div
      className={cn(
        "relative w-[250px] rounded-[2.5rem] border border-border bg-foreground p-2 shadow-2xl sm:w-[280px]",
        className,
      )}
    >
      <div className="overflow-hidden rounded-[2rem]">
        <Image
          src={src}
          alt={alt}
          width={width}
          height={height}
          priority={priority}
          sizes="(max-width: 640px) 250px, 280px"
          className="h-auto w-full"
        />
      </div>
    </div>
  );
}
