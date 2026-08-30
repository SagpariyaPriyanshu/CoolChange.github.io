import { AddressExplorer } from "./components/AddressExplorer";
import { ClosingImage, Footer } from "./components/Footer";
import { Header } from "./components/Header";
import { Hero, LeadCopy } from "./components/Hero";
import { CaseStudy, EvidenceSection, StorySteps, TreeTimeline } from "./components/StorySections";
import { TreeSimulator } from "./components/TreeSimulator";
import { TrustSection } from "./components/TrustSection";
import { useActiveStoryStep } from "./hooks/useActiveStoryStep";

export default function App() {
  const activeStoryStep = useActiveStoryStep();

  return (
    <>
      <Header />
      <main>
        <Hero />
        <LeadCopy />
        <StorySteps activeStep={activeStoryStep} />
        <CaseStudy />
        <TreeTimeline />
        <TreeSimulator />
        <EvidenceSection />
        <AddressExplorer />
        <TrustSection />
        <ClosingImage />
      </main>
      <Footer />
    </>
  );
}
