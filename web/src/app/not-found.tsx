import Link from 'next/link';
export default function NotFound() {
  return (
    <main className="not-found">
      <span className="eyebrow">KRISHI BANDHU · 404</span>
      <h1>This page hasn’t taken root.</h1>
      <p>Return to your workspace to find claims, farmers, and crop evidence.</p>
      <Link href="/" className="button primary">
        Back to overview
      </Link>
    </main>
  );
}
