import { Suspense } from 'react';
import { CropImagesPage } from '@/components/crop-images';
export default function Page() {
  return (
    <Suspense fallback={<p>Loading crop images…</p>}>
      <CropImagesPage />
    </Suspense>
  );
}
