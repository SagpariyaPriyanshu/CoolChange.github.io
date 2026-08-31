import { useEffect, useState } from "react";

type Page = "story" | "about";

function pageFromHash(): Page {
  return window.location.hash === "#about" ? "about" : "story";
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
