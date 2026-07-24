import http from 'node:http';
const port=Number(process.env.FRONTEND_PORT);
const page=`<!doctype html><html><head><meta charset="utf-8"><title>Multiples Coach</title><style>body{font:16px system-ui;max-width:720px;margin:4rem auto;padding:1rem;background:#f7f8fc;color:#15213b}main{background:white;padding:2rem;border-radius:16px;box-shadow:0 8px 30px #ccd3e0}code{color:#3456d1}</style></head><body><main><h1>Multiples Exercise Coach</h1><p>The native iOS exercise runtime is ready.</p><p>API: <code>http://127.0.0.1:${process.env.BACKEND_PORT}</code></p></main></body></html>`;
http.createServer((_req,res)=>{res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});res.end(page)}).listen(port,'127.0.0.1',()=>console.log(`Multiples runtime UI listening on ${port}`));
