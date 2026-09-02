import { useEffect, useState } from "react";

type Page = "story" | "map" | "about";

function pageFromHash(): Page {
  if (window.location.hash === "#about") return "about";
  if (window.location.hash === "#map") return "map";
  return "story";
}

export function useCurrentPage() {
  const [page, setPage] = useState<Page>(pageFromHash);

  useEffect(() => {
    function updatePage() {
      setPage(pageFromHash());
    }

    window.addEventListener("hashchange", updatePage);
    return () => window.removeEventListener("hashchange", updatePage);
  }, []);

  return page;
}
