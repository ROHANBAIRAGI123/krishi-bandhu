'use client';
import Link from 'next/link';
import { Icon, type IconName } from './icon';
import { currency, dateLabel, initials } from '@/lib/utils';
import { useDemo } from '@/lib/demo-store';
import type { Claim } from '@/types';
export function Badge({ status }: { status: string }) {
  return (
    <span className={`badge badge-${status.toLowerCase().replaceAll(' ', '-')}`}>
      <i />
      {status}
    </span>
  );
}
export function PageHeading({
  eyebrow,
  title,
  description,
  children,
}: {
  eyebrow?: string;
  title: string;
  description: string;
  children?: React.ReactNode;
}) {
  return (
    <div className="page-heading">
      <div>
        {eyebrow && <div className="eyebrow">{eyebrow}</div>}
        <h1>{title}</h1>
        <p>{description}</p>
      </div>
      <div className="heading-actions">{children}</div>
    </div>
  );
}
export function EmptyState({
  title = 'No matching records',
  message = 'Try a different search or filter.',
  children,
}: {
  title?: string;
  message?: string;
  children?: React.ReactNode;
}) {
  return (
    <div className="empty-state">
      <Icon name="search" size={30} />
      <h3>{title}</h3>
      <p>{message}</p>
      {children}
    </div>
  );
}
export function StatCard({
  title,
  value,
  note,
  icon,
  accent,
}: {
  title: string;
  value: string | number;
  note: string;
  icon: IconName;
  accent?: string;
}) {
  return (
    <div className={`stat-card ${accent || ''}`}>
      <div className="stat-top">
        <span>{title}</span>
        <span className="stat-icon">
          <Icon name={icon} size={19} />
        </span>
      </div>
      <strong className="stat-value">{value}</strong>
      <span className="stat-note">{note}</span>
    </div>
  );
}
export function ClaimsTable({ claims }: { claims: Claim[] }) {
  const { farmers } = useDemo();
  if (!claims.length) return <EmptyState />;
  return (
    <div className="table-scroll">
      <table>
        <thead>
          <tr>
            <th>Claim / Farmer</th>
            <th>Crop & location</th>
            <th>Submitted</th>
            <th>Claim amount</th>
            <th>Status</th>
            <th>
              <span className="sr-only">View</span>
            </th>
          </tr>
        </thead>
        <tbody>
          {claims.map((claim) => {
            const farmer = farmers.find((f) => f.id === claim.farmerId)!;
            return (
              <tr key={claim.id}>
                <td>
                  <Link className="farmer-cell" href={`/claims/${claim.id}`}>
                    <span className={`avatar avatar-${farmers.indexOf(farmer) % 4}`}>
                      {initials(farmer.name)}
                    </span>
                    <span>
                      <strong>{farmer.name}</strong>
                      <small>{claim.id}</small>
                    </span>
                  </Link>
                </td>
                <td>
                  <strong className="normal-weight">{claim.cropName}</strong>
                  <small>{farmer.village}</small>
                </td>
                <td className="muted">{dateLabel(claim.createdAt)}</td>
                <td className="amount">{currency(claim.claimAmount)}</td>
                <td>
                  <Badge status={claim.status} />
                </td>
                <td>
                  <Link
                    className="row-action"
                    aria-label={`View claim ${claim.id}`}
                    href={`/claims/${claim.id}`}
                  >
                    <Icon name="arrow" size={17} />
                  </Link>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
