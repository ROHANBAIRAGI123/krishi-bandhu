import type { Claim, DemoData, Farmer } from '@/types';

// The first three identities come from mobile/lib/src/utils/demo_users.dart.
// All land, claims, dates, and evidence metadata below are synthetic demo fixtures.
const identities = [
  ['Ramesh Patel', '9876543210', 'Khandala', 'Soybean', 3.8],
  ['Suresh Kumar', '9876543211', 'Pipri', 'Cotton', 2.4],
  ['Anita Devi', '9876543212', 'Kamptee', 'Rice', 1.8],
  ['Vijay Deshmukh', '9000000103', 'Katol', 'Soybean', 4.2],
  ['Meena Wankhede', '9000000104', 'Saoner', 'Cotton', 2.1],
  ['Prakash Patil', '9000000105', 'Ramtek', 'Rice', 3.5],
  ['Sunita Pawar', '9000000106', 'Hingna', 'Soybean', 2.8],
  ['Ganesh Shinde', '9000000107', 'Umred', 'Cotton', 5.2],
  ['Kavita More', '9000000108', 'Kalmeshwar', 'Rice', 1.6],
  ['Ashok Jadhav', '9000000109', 'Narkhed', 'Soybean', 4.6],
  ['Lakshmi Thakur', '9000000110', 'Parseoni', 'Cotton', 3.1],
  ['Dinesh Meshram', '9000000111', 'Kuhi', 'Rice', 2.5],
] as const;
export const farmers: Farmer[] = identities.map(([name, phone, village, crop, hectares], i) => ({
  id: `FRM-${1001 + i}`,
  name,
  phone,
  village,
  district: 'Nagpur',
  state: 'Maharashtra',
  hectares,
  crop,
  enrolled: `2026-06-${String(10 + i).padStart(2, '0')}`,
}));
const statuses: Claim['status'][] = [
  'Submitted',
  'Under Review',
  'Submitted',
  'Approved',
  'Paid',
  'Under Review',
  'Approved',
  'Rejected',
  'Paid',
  'Submitted',
  'Under Review',
  'Approved',
];
const claims: Claim[] = Array.from({ length: 24 }, (_, i) => ({
  id: `CLM-${2026}-${String(1048 - i).padStart(4, '0')}`,
  farmerId: farmers[i % 12].id,
  cropName: i < 18 ? farmers[i % 12].crop : 'Wheat',
  damageReason: ['Heavy Rain', 'Flood', 'Pest Attack', 'Drought'][i % 4],
  incidentDate:
    i < 18
      ? `2026-${String(10 - Math.floor(i / 4)).padStart(2, '0')}-${String(23 - (i % 4)).padStart(2, '0')}`
      : `2026-03-${String(10 + (i % 6)).padStart(2, '0')}`,
  createdAt:
    i < 18
      ? `2026-${String(10 - Math.floor(i / 4)).padStart(2, '0')}-${String(25 - (i % 4)).padStart(2, '0')}`
      : `2026-03-${String(12 + (i % 6)).padStart(2, '0')}`,
  season: i < 18 ? 'Kharif 2026' : 'Rabi 2025–26',
  estimatedLossPercentage: [65, 42, 78, 35, 55, 48][i % 6],
  claimAmount: [42000, 28500, 56000, 18500, 36000, 24000][i % 6],
  status: statuses[i % 12],
  ...(['Approved', 'Paid'].includes(statuses[i % 12])
    ? { approvedAmount: [42000, 28500, 56000, 18500, 36000, 24000][i % 6] * 0.9 }
    : {}),
  ...(statuses[i % 12] === 'Rejected'
    ? {
        reviewerComments:
          'Duplicate submission for the same parcel and incident. Refer to the existing claim.',
      }
    : {}),
  description:
    'The farmer reported damage across the insured parcel. Field observations and uploaded crop photographs are available for officer assessment. This is a sample claim for demonstration.',
}));
export const seedData: DemoData = {
  version: 1,
  farmers,
  claims,
  images: farmers.slice(0, 9).map((farmer, i) => ({
    id: `IMG-${2101 + i}`,
    farmerId: farmer.id,
    cropName: farmer.crop,
    season: 'Kharif 2026',
    imageUrl: `/demo/field-${(i % 3) + 1}.jpg`,
    location: { latitude: 21.1458 + i * 0.012, longitude: 79.0882 + i * 0.008 },
    verificationStatus: i < 5 ? 'Pending' : i < 7 ? 'Verified' : 'Flagged',
    createdAt: `2026-10-${25 - i}`,
  })),
  activities: [
    {
      id: 'act-1',
      message: 'New claim from Ramesh Patel',
      detail: 'Heavy rain · Khandala',
      date: '2026-10-25T10:30:00+05:30',
    },
    {
      id: 'act-2',
      message: 'Crop images ready for review',
      detail: '5 submissions need verification',
      date: '2026-10-25T09:45:00+05:30',
    },
    {
      id: 'act-3',
      message: 'Claim approved for Vijay Deshmukh',
      detail: 'Soybean · Katol',
      date: '2026-10-24T16:15:00+05:30',
    },
  ],
};
