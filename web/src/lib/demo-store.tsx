'use client';
import { createContext, useContext, useEffect, useState, useSyncExternalStore } from 'react';
import { seedData } from './demo-data';
import { restoreDemoData, validateClaimDecision } from './demo-rules';
import type { ClaimStatus, DemoData, Season, VerificationStatus } from '@/types';

const KEY = 'krishi-bandhu-demo-v1';
let current = seedData;
let loaded = false;
const listeners = new Set<() => void>();
function emit() {
  listeners.forEach((listener) => listener());
}
function readSaved() {
  try {
    current = restoreDemoData(JSON.parse(localStorage.getItem(KEY) || 'null'), seedData);
  } catch {
    current = seedData;
  }
}
function subscribe(listener: () => void) {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
}
function commit(data: DemoData) {
  current = data;
  emit();
  try {
    localStorage.setItem(KEY, JSON.stringify(data));
    return true;
  } catch {
    return false;
  }
}
function activity(message: string, detail: string) {
  return { id: crypto.randomUUID(), message, detail, date: new Date().toISOString() };
}
const ScopeContext = createContext<{
  season: Season;
  setSeason: (season: Season) => void;
  notify: (message: string) => void;
}>({ season: 'Kharif 2026', setSeason: () => {}, notify: () => {} });
export function DemoProvider({ children }: { children: React.ReactNode }) {
  const [season, setSeason] = useState<Season>('Kharif 2026');
  const [toast, setToast] = useState('');
  useEffect(() => {
    if (!loaded) {
      readSaved();
      loaded = true;
      emit();
    }
    const sync = (event: StorageEvent) => {
      if (event.key === KEY || event.key === null) {
        current = seedData;
        readSaved();
        emit();
      }
    };
    window.addEventListener('storage', sync);
    return () => window.removeEventListener('storage', sync);
  }, []);
  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(''), 4500);
    return () => clearTimeout(timer);
  }, [toast]);
  return (
    <ScopeContext.Provider value={{ season, setSeason, notify: setToast }}>
      {children}
      {toast && (
        <div className="toast" role="status">
          {toast}
          <button onClick={() => setToast('')} aria-label="Dismiss notification">
            ×
          </button>
        </div>
      )}
    </ScopeContext.Provider>
  );
}
export function useDemo() {
  const data = useSyncExternalStore(
    subscribe,
    () => current,
    () => seedData,
  );
  const scope = useContext(ScopeContext);
  function save(next: DemoData, message: string) {
    const persisted = commit(next);
    scope.notify(
      persisted
        ? message
        : `${message} Browser storage is unavailable; changes last for this session.`,
    );
  }
  function reviewClaim(id: string, status: ClaimStatus, comments: string, amount?: number) {
    const claim = current.claims.find((c) => c.id === id);
    if (!claim) throw new Error('Claim not found.');
    validateClaimDecision(claim, status, comments, amount);
    const date = new Date().toISOString();
    save(
      {
        ...current,
        claims: current.claims.map((c) =>
          c.id === id
            ? {
                ...c,
                status,
                reviewerComments: comments.trim(),
                ...(status === 'Approved' ? { approvedAmount: amount } : {}),
                reviewedAt: date,
              }
            : c,
        ),
        activities: [
          activity(`Claim ${id} ${status.toLowerCase()}`, comments || 'Reviewed by demo officer'),
          ...current.activities,
        ].slice(0, 30),
      },
      `Claim ${status.toLowerCase()}. Demo records updated.`,
    );
  }
  function verifyImage(id: string, status: VerificationStatus, remarks: string) {
    if (!current.images.some((i) => i.id === id)) throw new Error('Image not found.');
    if (remarks.length > 500) throw new Error('Notes must be 500 characters or fewer.');
    if (['Flagged', 'Rejected'].includes(status) && !remarks.trim())
      throw new Error('Please add a reason for this decision.');
    save(
      {
        ...current,
        images: current.images.map((i) =>
          i.id === id ? { ...i, verificationStatus: status, remarks } : i,
        ),
        activities: [
          activity(`Image ${id} ${status.toLowerCase()}`, remarks || 'Verified by demo officer'),
          ...current.activities,
        ].slice(0, 30),
      },
      `Image ${status.toLowerCase()}.`,
    );
  }
  return {
    ...data,
    ...scope,
    reviewClaim,
    verifyImage,
    reset: () => save(structuredClone(seedData), 'Demo data restored to its original state.'),
  };
}
