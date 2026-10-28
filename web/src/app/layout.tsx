import type { Metadata } from 'next';
import { DM_Sans, Manrope } from 'next/font/google';
import { DemoProvider } from '@/lib/demo-store';
import './globals.css';

const bodyFont = DM_Sans({
  variable: '--font-body',
  subsets: ['latin'],
});

const headingFont = Manrope({
  variable: '--font-heading',
  subsets: ['latin'],
});

export const metadata: Metadata = {
  title: { default: 'Krishi Bandhu · Officer workspace', template: '%s · Krishi Bandhu' },
  description:
    'A crop insurance officer workspace for reviewing claims, supporting farmers, and verifying field evidence. Interactive demo.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${bodyFont.variable} ${headingFont.variable}`}>
      <body>
        <DemoProvider>{children}</DemoProvider>
      </body>
    </html>
  );
}
