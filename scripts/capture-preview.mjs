import { createRequire } from 'node:module'
import { mkdirSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { pathToFileURL } from 'node:url'

const runtime = process.env.RUNTIME_DIR || '/home/runner/work/_temp/omgithub-runtime'
const playwrightDir = join(process.env.HOME || '/home/runner', '.local/share/omgithub-playwright')
const require = createRequire(join(playwrightDir, 'package.json'))
const { chromium } = require('playwright')
const captures = require(join(playwrightDir, 'wip-screenshots.cjs'))
const config = JSON.parse(readFileSync(join(playwrightDir, process.platform === 'darwin' ? 'metal.json' : 'linux.json'), 'utf8'))
const { startForCapture } = await import(pathToFileURL(join(runtime, 'scripts/capture-start.mjs')))
const url = process.env.CAPTURE_URL
const output = process.env.CAPTURE_DIR

if (!url || !output) {
  console.error('Set CAPTURE_URL and CAPTURE_DIR.')
  process.exit(1)
}
let target
try {
  target = new URL(url)
  if (!['http:', 'https:'].includes(target.protocol)) throw new Error('URL must use HTTP or HTTPS.')
  mkdirSync(output, { recursive: true })
} catch (error) {
  console.error(`Invalid capture configuration: ${error.message}`)
  process.exit(1)
}
if (process.platform === 'linux') {
  try { process.env.DISPLAY ||= ':' + readFileSync(join(playwrightDir, 'display'), 'utf8').trim() }
  catch (error) { console.error(`Capture display is unavailable: ${error.message}`); process.exit(1) }
}

captures.instrument({ chromium })
const transient = error => Object.assign(error, { exitCode: 75 })
const defect = message => Object.assign(new Error(message), { exitCode: 1 })
let browser
let exitCode = 0
try {
  browser = await chromium.launch({ ...config.browser.launchOptions, timeout: 30000 }).catch(error => { throw transient(error) })
  for (const [name, width, height] of [['desktop', 1440, 900], ['mobile', 390, 844]]) {
    const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: 1 }).catch(error => { throw transient(error) })
    page.setDefaultTimeout(30000)
    const failures = []
    page.on('pageerror', error => failures.push(`JavaScript error: ${error.message}`))
    page.on('response', response => {
      if (response.status() < 400) return
      try {
        if (new URL(response.url()).origin === target.origin) failures.push(`HTTP ${response.status()}: ${response.url()}`)
      } catch { /* Ignore non-HTTP browser-internal responses. */ }
    })
    let response
    try { response = await page.goto(url, { waitUntil: 'load', timeout: 45000 }) }
    catch (error) { await page.close().catch(() => {}); throw transient(error) }
    if (!response?.ok()) {
      const status = response?.status()
      await page.close().catch(() => {})
      throw [408, 429, 500, 502, 503, 504].includes(status) || !response
        ? transient(new Error(`Temporary HTTP ${status || 'navigation'} failure loading preview.`))
        : defect(`HTTP ${status} loading preview.`)
    }
    try {
      await page.locator(process.env.CAPTURE_READY_SELECTOR || 'body').waitFor({ state: 'visible', timeout: 30000 })
      await page.waitForFunction(() => document.readyState === 'complete' && document.fonts.status === 'loaded', undefined, { timeout: 30000 })
      const start = await startForCapture(page, {
        enabled: process.env.CAPTURE_AUTO_START !== 'false',
        selector: process.env.CAPTURE_START_SELECTOR || '',
        timeout: 500,
      })
      console.log(`Capture ${name}: auto-start ${start.clicked ? 'clicked' : start.reason}`)
      await page.screenshot({ path: join(output, `final-${name}.png`), timeout: 30000 })
      if (failures.length) throw defect(`${name} preview rendering failed: ${failures.join('; ')}`)
      console.log(`Saved ${join(output, `final-${name}.png`)} (${width}x${height})`)
    } catch (error) {
      await page.close().catch(() => {})
      if (error.exitCode) throw error
      if (error.name === 'TimeoutError' || !browser.isConnected()) throw transient(error)
      throw defect(`${name} capture failed: ${error.message}`)
    }
    await page.close().catch(error => { throw transient(error) })
  }
} catch (error) {
  exitCode = error.exitCode || 1
  console.error(error)
} finally {
  try { await browser?.close() }
  catch (error) { console.error(`Could not close capture browser: ${error.message}`); if (!exitCode) exitCode = 75 }
}
process.exitCode = exitCode
