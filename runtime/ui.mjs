import http from 'node:http';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

export function renderPage(apiPort = process.env.BACKEND_PORT) {
  if (!/^\d+$/.test(String(apiPort))) throw new Error('BACKEND_PORT is required');
  return readFileSync(new URL('./index.html', import.meta.url), 'utf8').replaceAll('__API_PORT__', String(Number(apiPort)));
}
export function createUIServer(apiPort = process.env.BACKEND_PORT) {
  return http.createServer((req, res) => {
    if (['/ai-report.mjs','/coach.js'].includes(req.url)) { res.writeHead(200, {'Content-Type':'text/javascript; charset=utf-8'}); return res.end(readFileSync(new URL('.'+req.url, import.meta.url))); }
    if (req.url !== '/' && req.url !== '/index.html') { res.writeHead(404); return res.end('Not found'); }
    res.writeHead(200, {'Content-Type':'text/html; charset=utf-8', 'Cache-Control':'no-store'}); res.end(renderPage(apiPort));
  });
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) createUIServer().listen(Number(process.env.FRONTEND_PORT), '127.0.0.1', () => console.log('Multiples web companion is ready.'));
