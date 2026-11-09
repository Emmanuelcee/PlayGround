import { createServer } from 'node:http'
import { readFile, stat } from 'node:fs/promises'
import { extname, resolve, sep } from 'node:path'

const root = resolve(process.env.PROJECT_DIR || process.cwd(), 'dist')
const port = Number(process.env.PORT || 3000)
const host = process.env.HOST || '0.0.0.0'
const types = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.json': 'application/json; charset=utf-8',
}

if (!Number.isInteger(port) || port < 1 || port > 65535) {
  console.error('PORT must be an integer between 1 and 65535.')
  process.exit(1)
}
try {
  if (!(await stat(root)).isDirectory()) throw new Error('not a directory')
} catch {
  console.error(`Static preview directory is unavailable: ${root}`)
  process.exit(1)
}

const server = createServer(async (request, response) => {
  const started = Date.now()
  try {
    const pathname = new URL(request.url || '/', `http://${request.headers.host || 'localhost'}`).pathname
    const decoded = decodeURIComponent(pathname)
    const relative = decoded === '/' ? 'index.html' : decoded.replace(/^\/+/, '')
    const file = resolve(root, relative)
    if (file !== root && !file.startsWith(root + sep)) {
      response.writeHead(403, { 'content-type': 'text/plain; charset=utf-8' }).end('Forbidden')
      return
    }
    const body = await readFile(file)
    response.writeHead(200, {
      'content-type': types[extname(file)] || 'application/octet-stream',
      'content-length': body.length,
      'cache-control': 'no-store',
      'x-content-type-options': 'nosniff',
    })
    if (request.method === 'HEAD') response.end()
    else response.end(body)
  } catch (error) {
    const status = error.code === 'ENOENT' || error.code === 'ENOTDIR' ? 404 : 400
    response.writeHead(status, { 'content-type': 'text/plain; charset=utf-8' }).end(status === 404 ? 'Not found' : 'Bad request')
  } finally {
    console.log(`${request.method} ${request.url} ${response.statusCode || 500} ${Date.now() - started}ms`)
  }
})

server.listen(port, host, () => console.log(`Static racing preview served from ${root} at http://${host}:${port}`))
for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => server.close(() => process.exit(0)))
}
