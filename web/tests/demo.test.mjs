import { test } from 'node:test';
import assert from 'node:assert/strict';
import { seedData } from '../src/lib/demo-data.ts';
import { restoreDemoData, validateClaimDecision } from '../src/lib/demo-rules.ts';
test('sample records have unique IDs, valid dates and intact farmer relationships', () => {
  for (const records of [seedData.farmers, seedData.claims, seedData.images])
    assert.equal(new Set(records.map((record) => record.id)).size, records.length);
  for (const record of [...seedData.claims, ...seedData.images]) {
    assert.ok(seedData.farmers.some((farmer) => farmer.id === record.farmerId));
    assert.ok(Number.isFinite(Date.parse(record.createdAt)));
  }
  assert.equal(seedData.claims.filter((c) => c.season === 'Kharif 2026').length, 18);
  assert.equal(seedData.claims.filter((c) => c.season === 'Rabi 2025–26').length, 6);
});
test('approval enforces payable limits and a rejection requires a reason', () => {
  const claim = seedData.claims[0];
  for (const amount of [-1, claim.claimAmount + 1, NaN, Infinity, undefined])
    assert.throws(() => validateClaimDecision(claim, 'Approved', '', amount));
  assert.doesNotThrow(() => validateClaimDecision(claim, 'Approved', 'Assessed', 38000));
  assert.throws(() => validateClaimDecision(claim, 'Rejected', '   '));
  assert.doesNotThrow(() => validateClaimDecision(claim, 'Rejected', 'Duplicate claim'));
});
test('completed claims cannot be reviewed again; only approved claims can be paid', () => {
  for (const status of ['Approved', 'Rejected', 'Paid'])
    assert.throws(() =>
      validateClaimDecision({ ...seedData.claims[0], status }, 'Approved', '', 100),
    );
  assert.throws(() => validateClaimDecision(seedData.claims[0], 'Paid', ''));
  assert.doesNotThrow(() =>
    validateClaimDecision({ ...seedData.claims[0], status: 'Approved' }, 'Paid', ''),
  );
});
test('saved review decisions survive restoration without changing source identities', () => {
  const saved = structuredClone(seedData);
  Object.assign(saved.claims[0], {
    status: 'Approved',
    approvedAmount: 38000,
    reviewerComments: 'Reviewed',
    farmerId: 'fake',
    claimAmount: 999999,
  });
  saved.images[0].imageUrl = 'https://example.invalid/tracking';
  saved.images[0].verificationStatus = 'Verified';
  const restored = restoreDemoData(saved, seedData);
  assert.equal(restored.claims[0].approvedAmount, 38000);
  assert.equal(restored.claims[0].farmerId, seedData.claims[0].farmerId);
  assert.equal(restored.claims[0].claimAmount, seedData.claims[0].claimAmount);
  assert.equal(restored.images[0].imageUrl, seedData.images[0].imageUrl);
  assert.equal(restored.images[0].verificationStatus, 'Verified');
});
test('malformed or outdated storage safely falls back to the original demo', () => {
  for (const value of [
    null,
    {},
    { version: 2 },
    { ...seedData, claims: [null] },
    { ...seedData, activities: [{ date: 'bad' }] },
  ])
    assert.equal(restoreDemoData(value, seedData), seedData);
  const saved = structuredClone(seedData);
  saved.claims[0].approvedAmount = -10;
  assert.equal(restoreDemoData(saved, seedData), seedData);
});
