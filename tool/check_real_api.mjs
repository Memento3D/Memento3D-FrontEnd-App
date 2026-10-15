// Calls a running backend directly. No fixtures or replacement responses.
// MEMENTO_API_URL=http://localhost:8080
// MEMENTO_API_EMAIL=... MEMENTO_API_PASSWORD=... node tool/check_real_api.mjs
// --write additionally checks create/update/delete on a temporary image scan.
// MEMENTO_SCAN_ID optionally checks images, video, quality runs, job, outputs,
// and ratings belonging to an existing scan, without mutating that scan.
import { writeFile } from 'node:fs/promises';

const base = (process.env.MEMENTO_API_URL || 'http://localhost:8080').replace(/\/+$/, '');
const results = [];
let token;
async function call(method, path, body, accepted = [200]) {
  try {
    const response = await fetch(`${base}${path}`, {
      method,
      headers: {
        Accept: 'application/json',
        ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: AbortSignal.timeout(15000),
      redirect: 'error',
    });
    const text = await response.text();
    const payload = text ? JSON.parse(text) : null;
    const real = payload?.execution_mode !== 'mock';
    const ok = accepted.includes(response.status) && real;
    results.push({ method, path, status: response.status, ok,
      ...(real ? {} : { error: 'Mock execution rejected' }) });
    if (!ok) throw new Error(`HTTP ${response.status} or unsupported execution mode`);
    return payload;
  } catch (error) {
    if (results.at(-1)?.path !== path || results.at(-1)?.method !== method) {
      results.push({ method, path, ok: false, error: error.message });
    }
    throw error;
  }
}

let refreshToken;
try {
  await call('GET', '/v3/api-docs');
  const email = process.env.MEMENTO_API_EMAIL;
  const password = process.env.MEMENTO_API_PASSWORD;
  if (!email || !password) throw new Error('Set MEMENTO_API_EMAIL and MEMENTO_API_PASSWORD for authenticated checks.');
  const session = await call('POST', '/api/v1/auth/login', { email, password });
  if (!session.accessToken) throw new Error('Login returned no access token');
  token = session.accessToken;
  refreshToken = session.refreshToken;
  await call('GET', '/api/v1/auth/me');
  await call('GET', '/api/v1/users/me');
  await call('GET', '/api/v1/scans?page=1&limit=100');
  await call('GET', '/api/v1/reconstruction-jobs');
  const scan = process.env.MEMENTO_SCAN_ID;
  if (scan) {
    const path = `/api/v1/scans/${encodeURIComponent(scan)}`;
    await call('GET', path);
    for (const suffix of ['/status', '/images', '/quality-runs', '/outputs', '/ratings']) {
      await call('GET', `${path}${suffix}`);
    }
    const job = await call('GET', `${path}/job`, undefined, [200, 404]);
    if (job?.job_id) {
      await call('GET', `/api/v1/reconstruction-jobs/${job.job_id}`);
      await call('GET', `/api/v1/reconstruction-jobs/${job.job_id}/outputs`);
    }
  }
  if (process.argv.includes('--write')) {
    let temporaryId;
    try {
      const created = await call('POST', '/api/v1/scans', {
        name: `API verification ${new Date().toISOString()}`, input_mode: 'image',
      }, [201]);
      if (!created.id) throw new Error('Create scan returned no ID');
      temporaryId = created.id;
      await call('GET', `/api/v1/scans/${temporaryId}`);
      await call('PATCH', `/api/v1/scans/${temporaryId}`, { name: 'API verification updated' });
    } finally {
      if (temporaryId) await call('DELETE', `/api/v1/scans/${temporaryId}`, undefined, [204]);
    }
  }
  if (refreshToken) {
    const refreshed = await call('POST', '/api/v1/auth/refresh', { refreshToken });
    if (!refreshed.accessToken || !refreshed.refreshToken) throw new Error('Refresh returned incomplete tokens');
    token = refreshed.accessToken;
    refreshToken = refreshed.refreshToken;
  }
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally {
  if (token) {
    try { await call('POST', '/api/v1/auth/logout', { refreshToken }); }
    catch { process.exitCode = 1; }
  }
  await writeFile('real-api-check.json', JSON.stringify({ base, results }, null, 2));
  for (const result of results) {
    console.log(`${result.ok ? 'PASS' : 'FAIL'} ${result.method} ${result.path} ${result.status ?? 'unreachable'}`);
  }
}
