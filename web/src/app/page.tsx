import { AppSection } from "@/components/marketing/app-section";
import { Compare } from "@/components/marketing/compare";
import { Features } from "@/components/marketing/features";
import { Hero } from "@/components/marketing/hero";
import { Quote } from "@/components/marketing/quote";
import { Reading } from "@/components/marketing/reading";
import { Showcase } from "@/components/marketing/showcase";
import { Stats } from "@/components/marketing/stats";
import { Steps } from "@/components/marketing/steps";

/** Landing de divulgação da app Belight Bible. */
export default function HomePage() {
  return (
    <>
      <Hero />
      <Stats />
      <Features />
      <Showcase />
      <Reading />
      <Compare />
      <Steps />
      <Quote />
      <AppSection />
    </>
  );
}
