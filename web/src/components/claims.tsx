'use client';
import Link from 'next/link';
import { useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { useDemo } from '@/lib/demo-store';
import { currency, dateLabel, downloadCsv, initials } from '@/lib/utils';
import { Badge, ClaimsTable, EmptyState, PageHeading } from './ui/shared';
import { Icon } from './ui/icon';
import type { ClaimStatus } from '@/types';

export function ClaimsPage() {
  const params = useSearchParams();
  const { season } = useDemo();
  return <ClaimsList key={`${params.toString()}-${season}`} />;
}
function ClaimsList() {
  const params = useSearchParams();
  const { claims, farmers, season, notify } = useDemo();
  const [query, setQuery] = useState(params.get('q') || '');
  const [status, setStatus] = useState(params.get('status') || 'All');
  const [crop, setCrop] = useState('All crops');
  const [page, setPage] = useState(1);
  const scoped = claims.filter((c) => c.season === season);
  const filtered = scoped.filter((c) => {
    const farmer = farmers.find((f) => f.id === c.farmerId)!;
    return (
      (status === 'All' ||
        (status === 'Pending'
          ? ['Submitted', 'Under Review'].includes(c.status)
          : c.status === status)) &&
      (crop === 'All crops' || crop === c.cropName) &&
      `${c.id} ${farmer.name} ${farmer.village} ${c.cropName}`
        .toLowerCase()
        .includes(query.toLowerCase())
    );
  });
  const pages = Math.max(1, Math.ceil(filtered.length / 8));
  const currentPage = Math.min(page, pages);
  function exportClaims() {
    downloadCsv('krishi-bandhu-claims.csv', [
      ['Claim ID', 'Farmer', 'Crop', 'Status', 'Requested INR', 'Approved INR', 'Submitted'],
      ...filtered.map((c) => [
        c.id,
        farmers.find((f) => f.id === c.farmerId)!.name,
        c.cropName,
        c.status,
        c.claimAmount,
        c.approvedAmount ?? '',
        c.createdAt,
      ]),
    ]);
    notify(`${filtered.length} claims exported.`);
  }
  return (
    <>
      <PageHeading
        eyebrow="PROTECTING LIVELIHOODS"
        title="Insurance claims"
        description="Review evidence, make informed decisions, and keep support moving."
      >
        <button className="button secondary" onClick={exportClaims}>
          <Icon name="download" size={17} />
          Export claims
        </button>
      </PageHeading>
      <section className="panel">
        <div className="tabs" role="group" aria-label="Claim status">
          {['All', 'Pending', 'Approved', 'Paid', 'Rejected'].map((tab) => (
            <button
              className={status === tab ? 'selected' : ''}
              onClick={() => {
                setStatus(tab);
                setPage(1);
              }}
              key={tab}
            >
              {tab === 'All' ? 'All claims' : tab}
              <span>
                {
                  scoped.filter(
                    (c) =>
                      tab === 'All' ||
                      (tab === 'Pending'
                        ? ['Submitted', 'Under Review'].includes(c.status)
                        : c.status === tab),
                  ).length
                }
              </span>
            </button>
          ))}
        </div>
        <div className="table-toolbar">
          <label className="search-field">
            <Icon name="search" size={18} />
            <input
              aria-label="Search claims"
              placeholder="Search name, claim ID, village…"
              value={query}
              onChange={(e) => {
                setQuery(e.target.value);
                setPage(1);
              }}
            />
          </label>
          <select
            className="filter-select"
            aria-label="Filter by crop"
            value={crop}
            onChange={(e) => {
              setCrop(e.target.value);
              setPage(1);
            }}
          >
            <option>All crops</option>
            {Array.from(new Set(scoped.map((c) => c.cropName))).map((c) => (
              <option key={c}>{c}</option>
            ))}
          </select>
          <span className="results-label">{filtered.length} claims</span>
        </div>
        <ClaimsTable claims={filtered.slice((currentPage - 1) * 8, currentPage * 8)} />
        <div className="pagination">
          <span>
            {filtered.length
              ? `Showing ${(currentPage - 1) * 8 + 1}–${Math.min(currentPage * 8, filtered.length)} of ${filtered.length} claims`
              : 'No claims to display'}
          </span>
          <div>
            <button
              className="button secondary"
              disabled={currentPage === 1}
              onClick={() => setPage(currentPage - 1)}
            >
              Previous
            </button>
            <span>
              {currentPage} / {pages}
            </span>
            <button
              className="button secondary"
              disabled={currentPage === pages}
              onClick={() => setPage(currentPage + 1)}
            >
              Next
            </button>
          </div>
        </div>
      </section>
    </>
  );
}
export function ClaimDetail({ id }: { id: string }) {
  const { claims } = useDemo();
  const claim = claims.find((c) => c.id === id);
  return <ClaimDetailContent key={`${id}-${claim?.reviewedAt || 'original'}`} id={id} />;
}
function ClaimDetailContent({ id }: { id: string }) {
  const { claims, farmers, images, reviewClaim } = useDemo();
  const claim = claims.find((c) => c.id === id);
  const [comments, setComments] = useState(claim?.reviewerComments || '');
  const [amount, setAmount] = useState(String(claim?.approvedAmount ?? claim?.claimAmount ?? ''));
  const [error, setError] = useState('');
  if (!claim)
    return (
      <EmptyState
        title="Claim not found"
        message="This claim does not exist in the demo workspace."
      >
        <Link className="button primary" href="/claims">
          Back to claims
        </Link>
      </EmptyState>
    );
  const farmer = farmers.find((f) => f.id === claim.farmerId)!;
  const evidence = images.filter((i) => i.farmerId === farmer.id && i.season === claim.season);
  const canReview = ['Submitted', 'Under Review'].includes(claim.status);
  function decide(status: ClaimStatus) {
    try {
      if (status === 'Approved' && amount.trim() === '')
        throw new Error('Enter an approved amount.');
      reviewClaim(id, status, comments, Number(amount));
      setError('');
    } catch (e) {
      setError((e as Error).message);
    }
  }
  return (
    <>
      <Link href="/claims" className="back-link">
        ← Back to insurance claims
      </Link>
      <PageHeading
        eyebrow={claim.season}
        title={claim.id}
        description={`Submitted ${dateLabel(claim.createdAt)} · ${farmer.village}, Nagpur`}
      >
        <Badge status={claim.status} />
      </PageHeading>
      <div className="detail-grid">
        <div className="detail-main">
          <section className="panel detail-panel">
            <div className="panel-heading">
              <h2>Claim summary</h2>
              <Icon name="file" />
            </div>
            <div className="detail-facts">
              <div>
                <small>Requested amount</small>
                <strong className="large-number">{currency(claim.claimAmount)}</strong>
              </div>
              <div>
                <small>Estimated crop loss</small>
                <strong className="large-number">{claim.estimatedLossPercentage}%</strong>
              </div>
              <div>
                <small>Crop</small>
                <strong>{claim.cropName}</strong>
              </div>
              <div>
                <small>Damage reported</small>
                <strong>{claim.damageReason}</strong>
              </div>
              <div>
                <small>Incident date</small>
                <strong>{dateLabel(claim.incidentDate)}</strong>
              </div>
              <div>
                <small>Farm area</small>
                <strong>{farmer.hectares} hectares</strong>
              </div>
            </div>
            <div className="detail-description">
              <h3>Farmer’s description</h3>
              <p>{claim.description}</p>
            </div>
          </section>
          <section className="panel detail-panel">
            <div className="panel-heading">
              <div>
                <h2>Supporting crop images</h2>
                <p>Illustrative photographs with synthetic location metadata</p>
              </div>
              <span className="count-pill">{evidence.length}</span>
            </div>
            {evidence.length ? (
              <div className="evidence-grid">
                {evidence.map((i) => (
                  <Link href={`/crop-images?image=${i.id}`} className="evidence-card" key={i.id}>
                    <div
                      className="evidence-photo"
                      style={{ backgroundImage: `url(${i.imageUrl})` }}
                      role="img"
                      aria-label={`Sample field photograph for ${i.id}`}
                    />
                    <div>
                      <Badge status={i.verificationStatus} />
                      <small>{i.id} · View evidence →</small>
                    </div>
                  </Link>
                ))}
              </div>
            ) : (
              <EmptyState
                title="No evidence attached"
                message="This sample claim has no crop images for this season."
              />
            )}
          </section>
        </div>
        <aside className="detail-aside">
          <section className="panel detail-panel">
            <div className="panel-heading">
              <h2>Farmer details</h2>
            </div>
            <div className="profile-summary">
              <span className="avatar large-avatar">{initials(farmer.name)}</span>
              <h3>{farmer.name}</h3>
              <p>{farmer.id}</p>
            </div>
            <dl className="info-list">
              <div>
                <dt>Village</dt>
                <dd>{farmer.village}</dd>
              </div>
              <div>
                <dt>Mobile</dt>
                <dd>+91 {farmer.phone}</dd>
              </div>
              <div>
                <dt>District</dt>
                <dd>{farmer.district}</dd>
              </div>
            </dl>
            <Link className="button secondary full-width" href={`/farmers/${farmer.id}`}>
              View farmer profile
              <Icon name="arrow" size={16} />
            </Link>
          </section>
          <section className="panel detail-panel">
            <div className="panel-heading">
              <h2>Officer decision</h2>
              <Icon name="shield" />
            </div>
            {canReview ? (
              <div className="review-form">
                <label>
                  Approved amount (₹)
                  <input
                    type="number"
                    min="0"
                    max={claim.claimAmount}
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                  />
                </label>
                <label>
                  Review notes
                  <textarea
                    maxLength={500}
                    rows={4}
                    value={comments}
                    onChange={(e) => setComments(e.target.value)}
                    placeholder="Record your findings. A reason is required to reject."
                  />
                </label>
                {error && (
                  <p className="form-error" role="alert">
                    {error}
                  </p>
                )}
                <button className="button primary full-width" onClick={() => decide('Approved')}>
                  <Icon name="check" size={17} />
                  Approve claim
                </button>
                <div className="two-buttons">
                  <button className="button danger" onClick={() => decide('Rejected')}>
                    Reject claim
                  </button>
                  <button
                    className="button secondary"
                    onClick={() => decide('Under Review')}
                    disabled={claim.status === 'Under Review'}
                  >
                    Mark in review
                  </button>
                </div>
                <p className="form-hint">Demo action · no funds will be transferred.</p>
              </div>
            ) : (
              <div className="decision-summary">
                <Badge status={claim.status} />
                {claim.approvedAmount !== undefined && (
                  <p>
                    Approved amount <strong>{currency(claim.approvedAmount)}</strong>
                  </p>
                )}
                <p>{claim.reviewerComments || 'The review decision has been recorded.'}</p>
                {claim.reviewedAt && <small>{dateLabel(claim.reviewedAt)}</small>}
                {error && (
                  <p className="form-error" role="alert">
                    {error}
                  </p>
                )}
                {claim.status === 'Approved' && (
                  <button className="button primary full-width" onClick={() => decide('Paid')}>
                    Mark paid (demo)
                  </button>
                )}
              </div>
            )}
          </section>
        </aside>
      </div>
    </>
  );
}
