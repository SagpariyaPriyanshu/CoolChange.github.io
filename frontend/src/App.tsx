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
        {/* Temporary — verifies the CI/CD pipeline (deployfrontend.yml)
            actually reaches the live site. Safe to remove once the
            workflow's been proven working. */}
        <div
          style={{
            background: "#fef3c7",
            color: "#78350f",
            textAlign: "center",
            padding: "0.75rem 1rem",
            fontSize: "0.9rem",
            fontWeight: 600,
          }}
        >
          Testing deployment pipeline
        </div>
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
