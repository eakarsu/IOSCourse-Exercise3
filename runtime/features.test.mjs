import test from 'node:test';
import assert from 'node:assert/strict';
import { createTaskStore, exportReports, fallbackCoach, searchReports } from './features.mjs';

const rows = [
  { id: 1, input: { question: 'multiples of 6' }, output: { content: '6, 12, 18' }, model: 'm1', createdAt: '2026-01-01' },
  { id: 2, input: { question: 'multiples of 9' }, output: { content: '9, 18, 27' }, model: 'm2', createdAt: '2026-01-02' },
];

test('fallback is labelled, deterministic, and needs no provider', () => {
  const a = fallbackCoach('Explain multiples of 6');
  assert.equal(a.fallback, true);
  assert.match(a.content, /Deterministic fallback/);
  assert.match(a.content, /6, 12, 18, 24, 30/);
  assert.deepEqual(a, fallbackCoach('Explain multiples of 6'));
});

test('search filters saved reports', () => {
  assert.equal(searchReports(rows, 'of 9').length, 1);
  assert.equal(searchReports(rows, '').length, 2);
});

test('export renders json, csv, and text', () => {
  assert.match(exportReports(rows, 'json').body, /multiples of 6/);
  assert.match(exportReports(rows, 'csv').body, /^id,question,model,createdAt,content/);
  assert.match(exportReports(rows, 'txt').body, /# Report 1/);
});

test('task store validates and isolates users', () => {
  const store = createTaskStore();
  const task = store.create('u1', 'Practise 7s');
  assert.equal(store.list('u1').length, 1);
  assert.equal(store.list('u2').length, 0);
  assert.equal(store.update('u1', task.id, { done: true }).done, true);
  assert.throws(() => store.create('u1', '  '), /1-200/);
  assert.equal(store.remove('u1', task.id), true);
  assert.equal(store.remove('u1', task.id), false);
});
