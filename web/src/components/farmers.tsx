'use client';
import Link from 'next/link';
import { useState } from 'react';
import { useDemo } from '@/lib/demo-store';
import { currency, dateLabel, initials, downloadCsv } from '@/lib/utils';
import { ClaimsTable, EmptyState, PageHeading, StatCard } from './ui/shared';
import { Icon } from './ui/icon';
export function FarmersPage() {
  const { farmers, claims, notify } = useDemo();
  const [query, setQuery] = useState('');
  const [crop, setCrop] = useState('All crops');
  const filtered = farmers.filter(
    (f) =>
      `${f.name} ${f.id} ${f.village} ${f.phone}`.toLowerCase().includes(query.toLowerCase()) &&
      (crop === 'All crops' || f.crop === crop),
  );
  return (
    <>
      <PageHeading
        eyebrow="YOUR FARMING COMMUNITY"
        title="Farmers"
        description="Get to know the people and parcels behind every claim."
      >
        <button
          className="button secondary"
          onClick={() => {
            downloadCsv('krishi-bandhu-farmers.csv', [
              ['Farmer ID', 'Name', 'Village', 'Crop', 'Area (ha)'],
              ...filtered.map((f) => [f.id, f.name, f.village, f.crop, f.hectares]),
            ]);
            notify('Farmer directory exported.');
          }}
        >
          <Icon name="download" size={17} />
          Export directory
        </button>
      </PageHeading>
      <div className="stats-grid three-stats">
        <StatCard
          title="Registered farmers"
          value={farmers.length}
          note="Across Nagpur district"
          icon="users"
        />
        <StatCard
          title="Registered farmland"
          value={`${farmers.reduce((s, f) => s + f.hectares, 0).toFixed(1)} ha`}
          note="Across all registered parcels"
          icon="sprout"
        />
        <StatCard
          title="Villages represented"
          value={new Set(farmers.map((f) => f.village)).size}
          note="One connected farming community"
          icon="pin"
        />
      </div>
      <section className="panel">
        <div className="table-toolbar">
          <label className="search-field">
            <Icon name="search" size={18} />
            <input
              aria-label="Search farmers"
              placeholder="Search farmer, village, ID or phone…"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
          </label>
          <select
            className="filter-select"
            aria-label="Filter farmers by crop"
            value={crop}
            onChange={(e) => setCrop(e.target.value)}
          >
            <option>All crops</option>
            <option>Soybean</option>
            <option>Cotton</option>
            <option>Rice</option>
          </select>
          <span className="results-label">{filtered.length} farmers · all seasons</span>
        </div>
        {filtered.length ? (
          <div className="table-scroll">
            <table>
              <thead>
                <tr>
                  <th>Farmer</th>
                  <th>Village</th>
                  <th>Primary crop</th>
                  <th>Farm area</th>
                  <th>Claims</th>
                  <th>Profile</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((f, i) => (
                  <tr key={f.id}>
                    <td>
                      <Link href={`/farmers/${f.id}`} className="farmer-cell">
                        <span className={`avatar avatar-${i % 4}`}>{initials(f.name)}</span>
                        <span>
                          <strong>{f.name}</strong>
                          <small>{f.id}</small>
                        </span>
                      </Link>
                    </td>
                    <td>
                      {f.village}
                      <small>{f.district}</small>
                    </td>
                    <td>
                      <span className="crop-label">
                        <Icon name="sprout" size={15} />
                        {f.crop}
                      </span>
                    </td>
                    <td>{f.hectares} ha</td>
                    <td>{claims.filter((c) => c.farmerId === f.id).length}</td>
                    <td>
                      <Link className="text-link" href={`/farmers/${f.id}`}>
                        View
                        <Icon name="arrow" size={15} />
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <EmptyState />
        )}
      </section>
    </>
  );
}
export function FarmerDetail({ id }: { id: string }) {
  const { farmers, claims, images } = useDemo();
  const farmer = farmers.find((f) => f.id === id);
  if (!farmer)
    return (
      <EmptyState title="Farmer not found" message="This farmer is not in the demo directory.">
        <Link className="button primary" href="/farmers">
          Back to farmers
        </Link>
      </EmptyState>
    );
  const farmerClaims = claims.filter((c) => c.farmerId === id);
  return (
    <>
      <Link href="/farmers" className="back-link">
        ← Back to farmers
      </Link>
      <PageHeading
        eyebrow={farmer.id}
        title={farmer.name}
        description={`${farmer.village}, ${farmer.district}, ${farmer.state}`}
      >
        <span className="badge badge-verified">
          <i />
          Registered farmer
        </span>
      </PageHeading>
      <div className="detail-grid">
        <div className="detail-main">
          <div className="stats-grid three-stats">
            <StatCard
              title="Farm area"
              value={`${farmer.hectares} ha`}
              note={farmer.crop}
              icon="sprout"
            />
            <StatCard
              title="Total claims"
              value={farmerClaims.length}
              note="All seasons"
              icon="file"
            />
            <StatCard
              title="Support received"
              value={currency(
                farmerClaims
                  .filter((c) => c.status === 'Paid')
                  .reduce((s, c) => s + (c.approvedAmount || 0), 0),
              )}
              note="Paid claims"
              icon="rupee"
            />
          </div>
          <section className="panel">
            <div className="panel-heading">
              <h2>Claim history</h2>
              <span className="count-pill">{farmerClaims.length}</span>
            </div>
            <ClaimsTable claims={farmerClaims} />
          </section>
        </div>
        <section className="panel detail-panel fit-content">
          <div className="profile-summary">
            <span className="avatar large-avatar">{initials(farmer.name)}</span>
            <h2>{farmer.name}</h2>
            <p>{farmer.id}</p>
          </div>
          <dl className="info-list">
            <div>
              <dt>Phone</dt>
              <dd>+91 {farmer.phone}</dd>
            </div>
            <div>
              <dt>Village</dt>
              <dd>{farmer.village}</dd>
            </div>
            <div>
              <dt>State</dt>
              <dd>{farmer.state}</dd>
            </div>
            <div>
              <dt>Enrolled</dt>
              <dd>{dateLabel(farmer.enrolled)}</dd>
            </div>
            <div>
              <dt>Crop images</dt>
              <dd>{images.filter((i) => i.farmerId === id).length}</dd>
            </div>
          </dl>
          <p className="form-hint">
            Sample farmer profile. No personal identity documents are stored in this demo.
          </p>
        </section>
      </div>
    </>
  );
}
