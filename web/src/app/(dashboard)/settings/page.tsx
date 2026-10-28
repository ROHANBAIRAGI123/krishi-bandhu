'use client';
import { useState } from 'react';
import { useDemo } from '@/lib/demo-store';
import { PageHeading } from '@/components/ui/shared';
import { Icon } from '@/components/ui/icon';
export default function SettingsPage() {
  const { reset } = useDemo();
  const [confirm, setConfirm] = useState(false);
  return (
    <>
      <PageHeading
        title="Workspace settings"
        description="Your demo profile and local workspace preferences."
      />
      <div className="settings-grid">
        <section className="panel detail-panel">
          <div className="panel-heading">
            <h2>Officer profile</h2>
            <Icon name="users" />
          </div>
          <div className="profile-summary">
            <span className="avatar large-avatar">PS</span>
            <h3>Priya Sharma</h3>
            <p>Demo review officer · Nagpur, Maharashtra</p>
          </div>
          <dl className="info-list">
            <div>
              <dt>Workspace</dt>
              <dd>Demonstration</dd>
            </div>
            <div>
              <dt>Data source</dt>
              <dd>Local sample records</dd>
            </div>
            <div>
              <dt>Authentication</dt>
              <dd>Not required in demo</dd>
            </div>
          </dl>
        </section>
        <section className="panel detail-panel">
          <div className="panel-heading">
            <h2>Demo data</h2>
            <Icon name="settings" />
          </div>
          <p className="settings-description">
            Your review decisions are saved in this browser. Restore the original sample records to
            start a fresh walkthrough.
          </p>
          {confirm ? (
            <div className="reset-confirm">
              <strong>Restore all demo records?</strong>
              <p>This removes your local review decisions and activity.</p>
              <div className="two-buttons">
                <button
                  className="button danger"
                  onClick={() => {
                    reset();
                    setConfirm(false);
                  }}
                >
                  Restore demo data
                </button>
                <button className="button secondary" onClick={() => setConfirm(false)}>
                  Cancel
                </button>
              </div>
            </div>
          ) : (
            <button className="button secondary" onClick={() => setConfirm(true)}>
              Reset demo data
            </button>
          )}
          <div className="info-banner settings-info">
            <Icon name="shield" />
            <p>No live payments, identity documents, or backend accounts are connected.</p>
          </div>
        </section>
      </div>
    </>
  );
}
