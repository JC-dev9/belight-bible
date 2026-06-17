import { Container } from "@/components/ui/container";
import { CountUp } from "@/components/ui/count-up";
import { Reveal } from "@/components/ui/reveal";
import { stats } from "@/lib/site";

/** Faixa de estatísticas: números da Bíblia com count-up ao entrar no ecrã. */
export function Stats() {
  return (
    <section className="border-y border-border">
      <Container>
        <dl className="grid grid-cols-2 gap-y-10 py-14 lg:grid-cols-4">
          {stats.map((stat, i) => (
            <Reveal
              key={stat.label}
              delay={i * 80}
              className="flex flex-col items-center text-center"
            >
              <dt className="text-4xl font-semibold tracking-tight text-brand sm:text-5xl">
                <CountUp to={stat.value} suffix={"suffix" in stat ? stat.suffix : ""} />
              </dt>
              <dd className="mt-2 text-sm text-muted-foreground">{stat.label}</dd>
            </Reveal>
          ))}
        </dl>
      </Container>
    </section>
  );
}
