import { Suspense } from 'react';
import { ClaimsPage } from '@/components/claims';
export default function Page() {
  return (
    <Suspense fallback={<p>Loading claims…</p>}>
      <ClaimsPage />
    </Suspense>
  );
}
