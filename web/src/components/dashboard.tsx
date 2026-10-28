'use client';
import Link from 'next/link';
import { useState } from 'react';
import { useDemo } from '@/lib/demo-store';
import { compactCurrency, dateLabel, downloadCsv } from '@/lib/utils';
import { Icon } from './ui/icon';
import { ClaimsTable, PageHeading, StatCard } from './ui/shared';
import type { Claim } from '@/types';

export function ClaimsChart({ claims }: { claims: Claim[] }) {
  const [period, setPeriod] = useState('season');
  const months =
    period === 'recent'
      ? [8, 9]
      : claims.some((c) => c.season === 'Rabi 2025–26')
        ? [0, 1, 2, 3, 4]
        : [5, 6, 7, 8, 9];
  const data = months.map((month) => ({
    month: new Date(2026, month, 1).toLocaleString('en', { month: 'short' }),
    total: claims.filter((c) => new Date(c.createdAt).getUTCMonth() === month).length,
    approved: claims.filter(
      (c) =>
        new Date(c.createdAt).getUTCMonth() === month && ['Approved', 'Paid'].includes(c.status),
    ).length,
  }));
  const max = Math.max(4, ...data.map((d) => d.total));
  return (
    <section className="panel chart-panel">
      <div className="panel-heading">
        <div>
          <h2>Claims overview</h2>
          <p>Submissions and approvals through the season</p>
        </div>
        <select
          aria-label="Chart period"
          value={period}
          onChange={(e) => setPeriod(e.target.value)}
          className="compact-select"
        >
          <option value="season">This season</option>
          <option value="recent">Sep – Oct</option>
        </select>
      </div>
      <div className="chart-legend">
        <span>
          <i className="legend-dot green" />
          Submitted claims
        </span>
        <span>
          <i className="legend-dot light-green" />
          Approved & paid
        </span>
      </div>
      <div
        className="bar-chart"
        role="img"
        aria-label={data
          .map((d) => `${d.month}: ${d.total} submitted, ${d.approved} approved or paid`)
          .join('; ')}
      >
        <div className="chart-y">
          {[max, Math.round(max * 0.75), Math.round(max * 0.5), Math.round(max * 0.25), 0].map(
            (n, i) => (
              <span key={i}>{n}</span>
            ),
          )}
        </div>
        <div className="chart-plot">
          <div className="grid-lines">
            {Array.from({ length: 5 }, (_, i) => (
              <i key={i} />
            ))}
          </div>
          <div className="chart-columns">
            {data.map((d) => (
              <div className="chart-column" key={d.month}>
                <div
                  className="bar-pair"
                  title={`${d.month}: ${d.total} submitted · ${d.approved} approved`}
                >
                  <div className="bar total-bar" style={{ height: `${(d.total / max) * 100}%` }}>
                    <span>{d.total}</span>
                  </div>
                  <div
                    className="bar approved-bar"
                    style={{ height: `${(d.approved / max) * 100}%` }}
                  />
                </div>
                <span className="month-label">{d.month}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
export function StatusChart({ claims }: { claims: Claim[] }) {
  const groups = [
    {
      name: 'Approved & paid',
      value: claims.filter((c) => ['Approved', 'Paid'].includes(c.status)).length,
      color: 'var(--green)',
    },
    {
      name: 'Under review',
      value: claims.filter((c) => c.status === 'Under Review').length,
      color: 'var(--sage)',
    },
    {
      name: 'Submitted',
      value: claims.filter((c) => c.status === 'Submitted').length,
      color: 'var(--gold)',
    },
    {
      name: 'Rejected',
      value: claims.filter((c) => c.status === 'Rejected').length,
      color: 'var(--rose)',
    },
  ];
  let offset = 0;
  const total = claims.length || 1;
  const stops = groups
    .map((group) => {
      const start = offset;
      offset += (group.value / total) * 100;
      return `${group.color} ${start}% ${offset}%`;
    })
    .join(',');
  return (
    <section className="panel status-panel">
      <div className="panel-heading">
        <div>
          <h2>Claim status</h2>
          <p>A clear view of your review queue</p>
        </div>
        <Icon name="file" size={18} />
      </div>
      <div className="donut-wrap">
        <div
          className="donut"
          style={{ background: `conic-gradient(${stops})` }}
          role="img"
          aria-label={groups.map((g) => `${g.name}: ${g.value}`).join(', ')}
        >
          <div>
            <strong>{claims.length}</strong>
            <span>Total claims</span>
          </div>
        </div>
      </div>
      <div className="status-legend">
        {groups.map((g) => (
          <div key={g.name}>
            <span>
              <i className="legend-dot" style={{ background: g.color }} />
              {g.name}
            </span>
            <strong>
              {g.value}
              <small>{Math.round((g.value / total) * 100)}%</small>
            </strong>
          </div>
        ))}
      </div>
    </section>
  );
}
export function Dashboard() {
  const { claims, farmers, images, season, activities, notify } = useDemo();
  const scoped = claims.filter((c) => c.season === season);
  const pending = scoped.filter((c) => ['Submitted', 'Under Review'].includes(c.status));
  const paid = scoped
    .filter((c) => c.status === 'Paid')
    .reduce((sum, c) => sum + (c.approvedAmount || 0), 0);
  const awaiting = images.filter(
    (i) => i.season === season && i.verificationStatus === 'Pending',
  ).length;
  function exportReport() {
    downloadCsv('krishi-bandhu-overview.csv', [
      ['Season', 'Claims', 'Awaiting review', 'Registered farmers', 'Paid amount INR'],
      [season, scoped.length, pending.length, farmers.length, paid],
    ]);
    notify('Overview report downloaded.');
  }
  return (
    <>
      <PageHeading
        eyebrow="YOUR DISTRICT AT A GLANCE"
        title="Welcome back, Priya"
        description="Every claim is a farmer’s livelihood. Let’s make today count."
      >
        <button className="button secondary" onClick={exportReport}>
          <Icon name="download" size={17} />
          Export report
        </button>
        <Link className="button primary" href="/claims?status=Pending">
          Review claims
          <Icon name="arrow" size={17} />
        </Link>
      </PageHeading>
      <div className="welcome-strip">
        <div className="welcome-icon">
          <Icon name="sprout" size={23} />
        </div>
        <div>
          <strong>A stronger safety net, one farmer at a time.</strong>
          <span>
            You have <b>{pending.length} claims</b> awaiting a decision
            {awaiting > 0 && (
              <>
                {' '}
                and <b>{awaiting} crop images</b> to verify
              </>
            )}
            .
          </span>
        </div>
        <span className="season-tag">
          <i />
          {season} season
        </span>
      </div>
      <div className="stats-grid">
        <StatCard
          title="Total claims"
          value={scoped.length}
          note={`Across ${season} season`}
          icon="file"
        />
        <StatCard
          title="Awaiting review"
          value={pending.length}
          note="Your attention makes a difference"
          icon="clock"
          accent="amber-stat"
        />
        <StatCard
          title="Registered farmers"
          value={farmers.length}
          note={`${farmers.reduce((sum, f) => sum + f.hectares, 0).toFixed(1)} hectares of farmland`}
          icon="users"
        />
        <StatCard
          title="Claims paid"
          value={compactCurrency(paid)}
          note={`${scoped.filter((c) => c.status === 'Paid').length} farmers received support`}
          icon="rupee"
        />
      </div>
      <div className="analytics-grid">
        <ClaimsChart claims={scoped} />
        <StatusChart claims={scoped} />
      </div>
      <div className="dashboard-bottom">
        <section className="panel recent-claims">
          <div className="panel-heading">
            <div>
              <h2>
                Recent claims <span className="count-pill">{scoped.length}</span>
              </h2>
              <p>The latest from your farming community</p>
            </div>
            <Link href="/claims" className="text-link">
              View all
              <Icon name="arrow" size={15} />
            </Link>
          </div>
          <ClaimsTable claims={scoped.slice(0, 5)} />
        </section>
        <div className="right-stack">
          <section className="field-card">
            <div className="field-card-content">
              <span className="eyebrow">FROM THE FIELD</span>
              <h2>
                Closer to the crop.
                <br />
                Clearer decisions.
              </h2>
              <p>{awaiting} images awaiting verification</p>
              <Link href="/crop-images" className="button light-button">
                Review crop images
                <Icon name="arrow" size={16} />
              </Link>
            </div>
          </section>
          <section className="panel activity-panel">
            <div className="panel-heading">
              <h2>Recent activity</h2>
              <span className="live-dot" />
            </div>
            <div className="activity-list">
              {activities.slice(0, 3).map((a, i) => (
                <div className="activity-item" key={a.id}>
                  <span className="activity-icon">
                    <Icon name={i === 1 ? 'image' : 'check'} size={13} />
                  </span>
                  <div>
                    <strong>{a.message}</strong>
                    <small>{dateLabel(a.date)}</small>
                  </div>
                </div>
              ))}
            </div>
          </section>
        </div>
      </div>
    </>
  );
}
