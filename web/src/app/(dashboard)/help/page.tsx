import Link from 'next/link';
import { PageHeading } from '@/components/ui/shared';
import { Icon } from '@/components/ui/icon';
export default function HelpPage() {
  return (
    <>
      <PageHeading
        eyebrow="HERE TO HELP"
        title="Help & resources"
        description="A quick guide to your Krishi Bandhu demo workspace."
      />
      <div className="help-grid">
        {[
          {
            title: 'Review an insurance claim',
            text: 'Open Insurance claims, choose a farmer, and inspect the claim and supporting photographs. Enter the payable amount and review notes, then approve or reject. A rejection requires a reason.',
            link: '/claims',
            action: 'Explore claims',
            icon: 'file' as const,
          },
          {
            title: 'Verify field evidence',
            text: 'Open a crop photograph to see its sample location and farmer details. Verify it or add a reason to flag or reject it. Gallery counts update immediately.',
            link: '/crop-images',
            action: 'Open crop verification',
            icon: 'image' as const,
          },
          {
            title: 'Understand your district',
            text: 'Use the season selector to compare sample seasons. Reports show totals from current records, and CSV exports respect your selected season or table filters.',
            link: '/reports',
            action: 'View reports',
            icon: 'chart' as const,
          },
        ].map((item) => (
          <section className="panel help-card" key={item.title}>
            <span className="help-icon">
              <Icon name={item.icon} size={26} />
            </span>
            <h2>{item.title}</h2>
            <p>{item.text}</p>
            <Link href={item.link} className="text-link">
              {item.action}
              <Icon name="arrow" size={16} />
            </Link>
          </section>
        ))}
      </div>
      <section className="panel detail-panel help-faq">
        <h2>Good to know</h2>
        <details>
          <summary>Where is the data saved?</summary>
          <p>
            Sample records are bundled with the frontend. Your changes stay in this browser’s local
            storage. Clearing browser data or resetting the demo restores the original records.
          </p>
        </details>
        <details>
          <summary>Are the photographs actual claim evidence?</summary>
          <p>
            No. The field photographs are illustrative samples, and their crop labels and GPS
            coordinates are synthetic. There is no live AI verification in this demo.
          </p>
        </details>
        <details>
          <summary>Does approving a claim transfer money?</summary>
          <p>
            No. Approval and marking a claim as paid update demo records only. This workspace is not
            connected to a payment service.
          </p>
        </details>
        <details>
          <summary>How do I start again?</summary>
          <p>
            Open Settings and choose Reset demo data. Confirm to restore the original claims,
            crop-image statuses, and activity history.
          </p>
        </details>
      </section>
    </>
  );
}
