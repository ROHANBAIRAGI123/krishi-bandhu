'use client';
import { useDemo } from '@/lib/demo-store';
import { currency, dateLabel, downloadCsv } from '@/lib/utils';
import { ClaimsChart, StatusChart } from '@/components/dashboard';
import { PageHeading } from '@/components/ui/shared';
import { Icon } from '@/components/ui/icon';
export default function ReportsPage() {
  const { claims, season, activities, notify } = useDemo();
  const scoped = claims.filter((c) => c.season === season);
  const crops = Array.from(new Set(scoped.map((c) => c.cropName))).map((crop) => ({
    crop,
    count: scoped.filter((c) => c.cropName === crop).length,
    amount: scoped.filter((c) => c.cropName === crop).reduce((s, c) => s + c.claimAmount, 0),
    approved: scoped
      .filter((c) => c.cropName === crop && ['Approved', 'Paid'].includes(c.status))
      .reduce((s, c) => s + (c.approvedAmount || 0), 0),
  }));
  return (
    <>
      <PageHeading
        eyebrow="INFORMED DECISIONS, BETTER OUTCOMES"
        title="Reports & insights"
        description={`A closer look at your district’s crop insurance activity for ${season}.`}
      >
        <button
          className="button primary"
          onClick={() => {
            downloadCsv('krishi-bandhu-crop-report.csv', [
              ['Crop', 'Claims', 'Requested INR', 'Approved INR'],
              ...crops.map((c) => [c.crop, c.count, c.amount, c.approved]),
            ]);
            notify('Crop report downloaded.');
          }}
        >
          <Icon name="download" size={17} />
          Download report
        </button>
      </PageHeading>
      <div className="analytics-grid">
        <ClaimsChart claims={scoped} />
        <StatusChart claims={scoped} />
      </div>
      <section className="panel report-table">
        <div className="panel-heading">
          <div>
            <h2>Crop-wise summary</h2>
            <p>Amounts calculated from the current demo records</p>
          </div>
        </div>
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Crop</th>
                <th>Claims</th>
                <th>Total requested</th>
                <th>Approved (including paid)</th>
              </tr>
            </thead>
            <tbody>
              {crops.map((c) => (
                <tr key={c.crop}>
                  <td>
                    <span className="crop-label">
                      <Icon name="sprout" size={17} />
                      {c.crop}
                    </span>
                  </td>
                  <td>{c.count}</td>
                  <td>{currency(c.amount)}</td>
                  <td>{currency(c.approved)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
      <section className="panel report-table">
        <div className="panel-heading">
          <div>
            <h2>Workspace activity</h2>
            <p>Review decisions across all seasons on this device</p>
          </div>
        </div>
        <div className="audit-list">
          {activities.map((a) => (
            <div key={a.id}>
              <span className="activity-icon">
                <Icon name="check" size={14} />
              </span>
              <div>
                <strong>{a.message}</strong>
                <p>{a.detail}</p>
              </div>
              <time>{dateLabel(a.date)}</time>
            </div>
          ))}
        </div>
      </section>
    </>
  );
}
