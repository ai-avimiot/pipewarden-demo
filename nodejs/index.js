const https = require('https');

const ENDPOINT = 'https://httpbin.org/ip';

// The point of this demo is to make a real outbound request so PipeWarden has
// something to observe. Whether the response is usable is not the point, so an
// upstream outage must not fail the build. httpbin.org is a free service and
// regularly answers 503 with an HTML body; parsing that as JSON used to throw
// `SyntaxError: Unexpected token '<'` and take the whole pipeline down.
function fetchData() {
  return new Promise((resolve) => {
    https.get(ENDPOINT, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode !== 200) {
          console.warn(`Warning: ${ENDPOINT} returned HTTP ${res.statusCode} — skipping (upstream issue, not a pipeline failure)`);
          resolve(null);
          return;
        }
        try {
          const parsed = JSON.parse(data);
          console.log(`Origin IP: ${parsed.origin}`);
          resolve(parsed);
        } catch (err) {
          console.warn(`Warning: ${ENDPOINT} returned a non-JSON body (${err.message}) — skipping`);
          resolve(null);
        }
      });
    }).on('error', (err) => {
      // In enforce mode, PipeWarden blocking this request also lands here — a
      // legitimate demo outcome rather than a crash.
      console.warn(`Warning: request to ${ENDPOINT} failed (${err.message}) — skipping`);
      resolve(null);
    });
  });
}

if (require.main === module) {
  fetchData();
}

module.exports = { fetchData };
