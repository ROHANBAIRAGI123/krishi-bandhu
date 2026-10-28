'use client';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useState } from 'react';
import { Icon, type IconName } from '@/components/ui/icon';
import { useDemo } from '@/lib/demo-store';
import type { Season } from '@/types';

const links: { href: string; label: string; icon: IconName }[] = [
  { href: '/', label: 'Overview', icon: 'grid' },
  { href: '/claims', label: 'Insurance claims', icon: 'file' },
  { href: '/farmers', label: 'Farmers', icon: 'users' },
  { href: '/crop-images', label: 'Crop verification', icon: 'image' },
  { href: '/reports', label: 'Reports & insights', icon: 'chart' },
];
export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { season, setSeason, claims, activities } = useDemo();
  const [menu, setMenu] = useState(false);
  const [notifications, setNotifications] = useState(false);
  const [search, setSearch] = useState('');
  const active = links.find((link) =>
    link.href === '/' ? pathname === '/' : pathname.startsWith(link.href),
  );
  const pending = claims.filter(
    (c) => c.season === season && ['Submitted', 'Under Review'].includes(c.status),
  ).length;
  return (
    <div className="app-shell">
      <a className="skip-link" href="#main-content">
        Skip to content
      </a>
      {menu && (
        <button
          className="sidebar-scrim"
          aria-label="Close navigation"
          onClick={() => setMenu(false)}
        />
      )}
      <aside className={`sidebar ${menu ? 'is-open' : ''}`}>
        <Link href="/" className="brand" onClick={() => setMenu(false)}>
          <span className="brand-mark">
            <Icon name="sprout" size={26} />
          </span>
          <span>
            krishi<span className="brand-light">bandhu</span>
            <small>GROWING TRUST. PROTECTING FUTURES.</small>
          </span>
        </Link>
        <div className="workspace-label">OFFICER WORKSPACE</div>
        <nav aria-label="Main navigation">
          {links.map((link) => (
            <Link
              href={link.href}
              key={link.href}
              onClick={() => setMenu(false)}
              className={`nav-link ${active?.href === link.href ? 'active' : ''}`}
              aria-current={active?.href === link.href ? 'page' : undefined}
            >
              <Icon name={link.icon} />
              <span>{link.label}</span>
              {link.href === '/claims' && <span className="nav-count">{pending}</span>}
            </Link>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <div className="season-note">
            <Icon name="shield" size={27} />
            <strong>
              A little assurance.
              <br />A better tomorrow.
            </strong>
            <p>Supporting farmers through every season.</p>
            <span>PMFBY · Crop insurance</span>
          </div>
          <Link
            href="/help"
            className={`nav-link ${pathname === '/help' ? 'active' : ''}`}
            onClick={() => setMenu(false)}
          >
            <Icon name="help" />
            <span>Help & resources</span>
          </Link>
          <Link
            href="/settings"
            className={`nav-link ${pathname === '/settings' ? 'active' : ''}`}
            onClick={() => setMenu(false)}
          >
            <Icon name="settings" />
            <span>Settings</span>
          </Link>
          <Link href="/settings" className="officer">
            <span className="avatar officer-avatar">PS</span>
            <span>
              <strong>Priya Sharma</strong>
              <small>Demo review officer</small>
            </span>
            <Icon name="chevron" size={16} />
          </Link>
        </div>
      </aside>
      <div className="workspace">
        <header className="topbar">
          <div className="breadcrumb">
            <button
              className="icon-button mobile-toggle"
              aria-label="Open navigation"
              onClick={() => setMenu(true)}
            >
              <Icon name="menu" />
            </button>
            <span>Workspace</span>
            <Icon name="chevron" size={14} />
            <strong>
              {active?.label || (pathname === '/settings' ? 'Settings' : 'Help & resources')}
            </strong>
          </div>
          <div className="topbar-actions">
            <form
              className="global-search"
              onSubmit={(event) => {
                event.preventDefault();
                router.push(`/claims?q=${encodeURIComponent(search)}`);
              }}
            >
              <Icon name="search" size={17} />
              <input
                aria-label="Search claims or farmers"
                placeholder="Search claims or farmers…"
                value={search}
                onChange={(event) => setSearch(event.target.value)}
              />
              <kbd>↵</kbd>
            </form>
            <span className="demo-pill">
              <i />
              Demo workspace
            </span>
            <div className="notification-wrap">
              <button
                className="icon-button notification-button"
                aria-label="Notifications"
                aria-expanded={notifications}
                onClick={() => setNotifications(!notifications)}
              >
                <Icon name="bell" />
                <i />
              </button>
              {notifications && (
                <div className="notification-panel">
                  <div className="panel-heading">
                    <h3>Recent notifications</h3>
                    <button
                      className="icon-button"
                      onClick={() => setNotifications(false)}
                      aria-label="Close notifications"
                    >
                      <Icon name="close" size={16} />
                    </button>
                  </div>
                  {activities.slice(0, 3).map((a) => (
                    <div className="notification-item" key={a.id}>
                      <strong>{a.message}</strong>
                      <small>{a.detail}</small>
                    </div>
                  ))}
                  <Link
                    href="/reports"
                    onClick={() => setNotifications(false)}
                    className="text-link"
                  >
                    View activity <Icon name="arrow" size={14} />
                  </Link>
                </div>
              )}
            </div>
            <span className="avatar small-avatar">PS</span>
          </div>
        </header>
        <main id="main-content" className="main-content">
          <div className="context-bar">
            <span>
              <Icon name="pin" size={14} /> Nagpur district{' '}
              <span className="context-divider">/</span> Maharashtra
            </span>
            <label>
              <Icon name="calendar" size={15} />
              <select
                aria-label="Season"
                value={season}
                onChange={(e) => setSeason(e.target.value as Season)}
              >
                <option>Kharif 2026</option>
                <option>Rabi 2025–26</option>
              </select>
            </label>
          </div>
          {children}
          <footer className="footer">
            <span>
              Krishi Bandhu <span>·</span> Every farmer. Every season.
            </span>
            <span>Sample data · Changes saved on this device</span>
          </footer>
        </main>
      </div>
    </div>
  );
}
