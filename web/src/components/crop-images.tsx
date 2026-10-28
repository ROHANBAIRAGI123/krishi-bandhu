'use client';
import { useEffect, useRef, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { useDemo } from '@/lib/demo-store';
import { dateLabel } from '@/lib/utils';
import { Badge, EmptyState, PageHeading } from './ui/shared';
import { Icon } from './ui/icon';
import type { VerificationStatus } from '@/types';
export function CropImagesPage() {
  const params = useSearchParams();
  const { images, farmers, season, verifyImage } = useDemo();
  const [filter, setFilter] = useState('All');
  const [selectedId, setSelectedId] = useState<string | null>(params.get('image'));
  const [remarks, setRemarks] = useState<string | null>(null);
  const [error, setError] = useState('');
  const dialog = useRef<HTMLDialogElement>(null);
  const selected = images.find((i) => i.id === selectedId);
  const filtered = images.filter(
    (i) => i.season === season && (filter === 'All' || i.verificationStatus === filter),
  );
  useEffect(() => {
    if (selected) dialog.current?.showModal();
    else dialog.current?.close();
  }, [selected]);
  function close() {
    setSelectedId(null);
    setError('');
    setRemarks(null);
  }
  function decide(status: VerificationStatus) {
    if (!selected) return;
    try {
      verifyImage(selected.id, status, remarks ?? selected.remarks ?? '');
      close();
    } catch (e) {
      setError((e as Error).message);
    }
  }
  return (
    <>
      <PageHeading
        eyebrow="EVIDENCE FROM THE FIELD"
        title="Crop verification"
        description="Inspect field photographs and record your assessment."
      />
      <div className="info-banner">
        <Icon name="image" size={19} />
        <p>
          Demo gallery: photographs are illustrative. GPS coordinates and crop labels are synthetic;
          no AI analysis has been performed.
        </p>
      </div>
      <div className="gallery-filters">
        <div className="segmented-control">
          {['All', 'Pending', 'Verified', 'Flagged', 'Rejected'].map((s) => (
            <button key={s} className={filter === s ? 'selected' : ''} onClick={() => setFilter(s)}>
              {s}{' '}
              <span>
                {
                  images.filter(
                    (i) => i.season === season && (s === 'All' || i.verificationStatus === s),
                  ).length
                }
              </span>
            </button>
          ))}
        </div>
        <span className="muted">{filtered.length} images</span>
      </div>
      {filtered.length ? (
        <div className="image-grid">
          {filtered.map((i) => {
            const farmer = farmers.find((f) => f.id === i.farmerId)!;
            return (
              <button
                className="image-card"
                aria-label={`${i.id}, ${farmer.name}, ${i.cropName}, ${i.verificationStatus}. Review photograph`}
                key={i.id}
                onClick={() => {
                  setSelectedId(i.id);
                  setRemarks(i.remarks || '');
                }}
              >
                <div
                  className="gallery-photo"
                  style={{ backgroundImage: `url(${i.imageUrl})` }}
                  role="img"
                  aria-label={`Illustrative field photograph, ${i.id}`}
                >
                  <Badge status={i.verificationStatus} />
                  <span className="photo-tag">Sample photograph</span>
                </div>
                <div className="image-card-body">
                  <div>
                    <h3>
                      {i.cropName} · {farmer.village}
                    </h3>
                    <Icon name="arrow" size={18} />
                  </div>
                  <p>
                    {farmer.name} <span>·</span> {i.id}
                  </p>
                  <div className="image-card-meta">
                    <span>
                      <Icon name="pin" size={13} />
                      GPS tagged (demo)
                    </span>
                    <span>{dateLabel(i.createdAt)}</span>
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      ) : (
        <section className="panel">
          <EmptyState
            title="No images in this view"
            message="Choose another status or season to browse demo evidence."
          />
        </section>
      )}
      <dialog
        className="image-dialog"
        ref={dialog}
        onCancel={close}
        aria-labelledby="image-dialog-title"
      >
        {selected && (
          <>
            <div className="dialog-heading">
              <div>
                <span className="eyebrow">FIELD EVIDENCE · DEMO</span>
                <h2 id="image-dialog-title">{selected.id}</h2>
              </div>
              <button className="icon-button" aria-label="Close image review" onClick={close}>
                <Icon name="close" />
              </button>
            </div>
            <div className="image-dialog-layout">
              <div
                className="dialog-photo"
                style={{ backgroundImage: `url(${selected.imageUrl})` }}
                role="img"
                aria-label="Illustrative field photograph"
              />
              <div className="dialog-review">
                <Badge status={selected.verificationStatus} />
                <h3>{farmers.find((f) => f.id === selected.farmerId)!.name}</h3>
                <dl className="info-list">
                  <div>
                    <dt>Crop label</dt>
                    <dd>{selected.cropName}</dd>
                  </div>
                  <div>
                    <dt>Uploaded</dt>
                    <dd>{dateLabel(selected.createdAt)}</dd>
                  </div>
                  <div>
                    <dt>Demo coordinates</dt>
                    <dd>
                      {selected.location.latitude.toFixed(4)},{' '}
                      {selected.location.longitude.toFixed(4)}
                    </dd>
                  </div>
                </dl>
                <label className="form-label">
                  Verification notes
                  <textarea
                    rows={3}
                    maxLength={500}
                    placeholder="Required when flagging or rejecting an image"
                    value={remarks ?? selected.remarks ?? ''}
                    onChange={(e) => setRemarks(e.target.value)}
                  />
                </label>
                {error && (
                  <p role="alert" className="form-error">
                    {error}
                  </p>
                )}
                <button className="button primary full-width" onClick={() => decide('Verified')}>
                  <Icon name="check" size={17} />
                  Verify image
                </button>
                <div className="two-buttons">
                  <button className="button secondary" onClick={() => decide('Flagged')}>
                    Flag for review
                  </button>
                  <button className="button danger" onClick={() => decide('Rejected')}>
                    Reject
                  </button>
                </div>
                <p className="form-hint">Review decisions are saved locally in this demo.</p>
              </div>
            </div>
          </>
        )}
      </dialog>
    </>
  );
}
