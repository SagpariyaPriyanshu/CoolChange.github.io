import { AboutPage } from "./components/AboutPage";
import { Header } from "./components/Header";
import { StoryPage } from "./components/StoryPage";
import { useCurrentPage } from "./hooks/useCurrentPage";

export default function App() {
  const page = useCurrentPage();

  return (
    <>
      <Header />
      {page === "about" ? <AboutPage /> : <StoryPage />}
    </>
  );
}
