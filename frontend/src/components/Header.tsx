export function Header() {
  return (
    <header className="site-header">
      <a className="wordmark" href="#top" aria-label="Cool Change home">
        <span className="wordmark-dot" />
        Cool Change
      </a>
      <nav aria-label="Main navigation">
        <a href="#story">The story</a>
        <a href="#explore">Explore an address</a>
      </nav>
    </header>
  );
}
