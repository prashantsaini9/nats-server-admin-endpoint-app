const express = require('express');
const httpProxy = require('http-proxy');
const http = require('http');

const app = express();
const proxy = httpProxy.createProxyServer({
    target: 'http://localhost:4223',
    ws: true
});

const PORT = process.env.PORT || 10000;

// ── HTTP ENDPOINTS (Keep-Alive) ──

// Standard health check for Render
app.get('/healthz', (req, res) => {
    res.status(200).send('NATS Gateway: Healthy');
});

// Explicit ping endpoint for Cron-job.org or UptimeRobot
app.get('/ping', (req, res) => {
    console.log(`[GATEWAY] Ping received at ${new Date().toISOString()}`);
    res.status(200).json({
        status: 'alive',
        timestamp: new Date().toISOString(),
        message: 'D-Secure NATS is staying awake!'
    });
});

// Root handler
app.get('/', (req, res) => {
    res.status(200).send('D-Secure NATS Server Gateway is running.');
});

// ── ERROR HANDLING ──
proxy.on('error', (err, req, res) => {
    console.error('[GATEWAY] Proxy Error:', err);
    if (res && res.writeHead) {
        res.writeHead(502, { 'Content-Type': 'text/plain' });
        res.end('Gateway Error: NATS server might be starting up...');
    }
});

// ── SERVER INITIALIZATION ──
const server = http.createServer(app);

// Handle WebSocket upgrades
server.on('upgrade', (req, socket, head) => {
    console.log(`[GATEWAY] Upgrading connection to WebSocket for ${req.url}`);
    proxy.ws(req, socket, head);
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`================================================`);
    console.log(`  D-Secure NATS Keep-Alive Gateway`);
    console.log(`  Listening on Port: ${PORT}`);
    console.log(`  Proxying to NATS: localhost:4223`);
    console.log(`================================================`);
});
