import type { CSSProperties } from 'react';
const paths = {
  grid: 'M3 3h7v7H3z M14 3h7v7h-7z M3 14h7v7H3z M14 14h7v7h-7z',
  file: 'M14 2H5a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V9z M14 2v7h7 M7 13h10 M7 17h7',
  users:
    'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2 M16 3a4 4 0 0 1 0 8 M22 21v-2a4 4 0 0 0-3-3.87 M13 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0',
  image:
    'M4 3h16a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1 M3 16l5-5 4 4 4-6 5 8 M8 7h.01',
  chart: 'M3 3v18h18 M7 16v-5 M12 16V7 M17 16V4',
  leaf: 'M20 3C7 2 3 7 4 14c1 6 8 8 13 3 3-3 3-8 3-14z M3 22 15 9 M9 16V9 M9 16h7',
  search: 'M21 21l-5-5 M18 10a8 8 0 1 1-16 0 8 8 0 0 1 16 0',
  bell: 'M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9 M10 21h4',
  chevron: 'm9 5 7 7-7 7',
  down: 'm6 9 6 6 6-6',
  arrow: 'M4 12h16 m-6-6 6 6-6 6',
  download: 'M12 3v12 m-5-5 5 5 5-5 M4 16v5h16v-5',
  clock: 'M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0 M12 6v6l4 2',
  check: 'm5 12 4 4L19 6',
  shield: 'm12 2 9 4v6c0 6-9 10-9 10S3 18 3 12V6z m-5 10 3 3 5-5',
  pin: 'M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 0 1 16 0 M15 10a3 3 0 1 1-6 0 3 3 0 0 1 6 0',
  settings:
    'M12 8a4 4 0 1 1 0 8 4 4 0 0 1 0-8 M12 2v3 M12 19v3 M2 12h3 M19 12h3 M5 5l2 2 M17 17l2 2 M5 19l2-2 M17 7l2-2',
  help: 'M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0 M9 9a3 3 0 0 1 6 0c0 2-3 2-3 5 M12 18h.01',
  calendar: 'M3 5h18v16H3z M3 10h18 M7 2v6 M17 2v6',
  alert: 'm12 3 10 18H2z M12 9v5 M12 17h.01',
  close: 'm6 6 12 12 M6 18 18 6',
  menu: 'M3 6h18 M3 12h18 M3 18h18',
  rupee: 'M6 3h12 M6 7h12 M8 3c8 0 8 9 0 9H6l10 9',
  sprout: 'M12 22V12 M12 16C2 16 2 10 2 7c7 0 10 3 10 9 M12 12C12 4 16 2 22 2c0 7-3 10-10 10',
  logout: 'M9 3H3v18h6 M10 12h11 m-5-5 5 5-5 5',
  up: 'm5 15 6-6 4 4 6-8 M15 5h6v6',
};
export type IconName = keyof typeof paths;
export function Icon({
  name,
  size = 20,
  style,
}: {
  name: IconName;
  size?: number;
  style?: CSSProperties;
}) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      style={style}
    >
      <path d={paths[name]} />
    </svg>
  );
}
