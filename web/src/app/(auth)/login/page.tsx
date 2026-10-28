import Link from 'next/link';
import { Icon } from '@/components/ui/icon';
export default function LoginPage() {
  return (
    <main className="login-page">
      <section className="login-card">
        <span className="brand-mark">
          <Icon name="sprout" size={30} />
        </span>
        <div className="eyebrow">KRISHI BANDHU · OFFICER WORKSPACE</div>
        <h1>
          Every farmer.
          <br />
          Every season.
        </h1>
        <p>
          Explore a complete crop insurance workspace with sample farmers, claims, and field
          evidence.
        </p>
        <Link href="/" className="button primary full-width">
          Enter demo workspace
          <Icon name="arrow" size={18} />
        </Link>
        <small>No account required. All review actions use local demo data.</small>
      </section>
    </main>
  );
}
