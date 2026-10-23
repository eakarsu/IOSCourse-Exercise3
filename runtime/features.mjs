// Pure helpers for search, export, practice tasks, and the labelled
// deterministic AI fallback. No provider call or database access happens here.

export function fallbackCoach(question) {
  const text = String(question || '');
  const found = text.match(/multiples?\s+of\s+(\d{1,4})/i) || text.match(/\b(\d{1,4})\b/);
  const n = found ? Number(found[1]) : 6;
  const seq = [1, 2, 3, 4, 5].map((k) => n * k);
  const content = [
    'Deterministic fallback (no AI provider configured).',
    '',
    `Worked example: the first five positive multiples of ${n} are ${seq.join(', ')}.`,
    `Repeated addition: ${seq.map((_, i) => Array(i + 1).fill(n).join(' + ')).join('; ')}.`,
    'Common mistake: adding the step count instead of the base number.',
    `Check: what is ${n} x 4, and how do you know?`,
  ].join('\n');
  return { content, model: 'deterministic-fallback', fallback: true };
}

function rowText(row) {
  return [row?.input?.question, row?.output?.content, row?.model].filter(Boolean).join('\n').toLowerCase();
}

export function searchReports(rows, query) {
  const q = String(query || '').trim().toLowerCase();
  if (!q) return [...rows];
  return rows.filter((row) => rowText(row).includes(q));
}

const csvCell = (v) => `"${String(v ?? '').replaceAll('"', '""')}"`;

export function exportReports(rows, format = 'json') {
  if (format === 'csv') {
    const lines = ['id,question,model,createdAt,content'];
    for (const r of rows) lines.push([r.id, r.input?.question ?? '', r.model ?? '', r.createdAt ?? '', r.output?.content ?? ''].map(csvCell).join(','));
    return { contentType: 'text/csv; charset=utf-8', body: lines.join('\n') + '\n' };
  }
  if (format === 'txt' || format === 'text') {
    const body = rows.map((r) => `# Report ${r.id} (${r.model ?? ''})\nQ: ${r.input?.question ?? ''}\n\n${r.output?.content ?? ''}`).join('\n\n---\n\n');
    return { contentType: 'text/plain; charset=utf-8', body: body + '\n' };
  }
  return { contentType: 'application/json', body: JSON.stringify(rows, null, 2) + '\n' };
}

export function createTaskStore() {
  const byUser = new Map();
  let nextId = 1;
  const list = (userId) => [...(byUser.get(userId) || [])];
  return {
    list,
    create(userId, title) {
      const clean = String(title || '').trim();
      if (!clean || clean.length > 200) throw Object.assign(new Error('Task title must contain 1-200 characters'), { status: 422 });
      const task = { id: nextId++, title: clean, done: false, createdAt: new Date().toISOString() };
      byUser.set(userId, [...list(userId), task]);
      return task;
    },
    update(userId, id, patch = {}) {
      const tasks = list(userId);
      const task = tasks.find((t) => t.id === Number(id));
      if (!task) return null;
      if (typeof patch.title === 'string') {
        const clean = patch.title.trim();
        if (!clean || clean.length > 200) throw Object.assign(new Error('Task title must contain 1-200 characters'), { status: 422 });
        task.title = clean;
      }
      if (typeof patch.done === 'boolean') task.done = patch.done;
      return task;
    },
    remove(userId, id) {
      const tasks = list(userId);
      const next = tasks.filter((t) => t.id !== Number(id));
      if (next.length === tasks.length) return false;
      byUser.set(userId, next);
      return true;
    },
  };
}
