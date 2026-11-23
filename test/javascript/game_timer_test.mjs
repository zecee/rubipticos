import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const source = readFileSync(new URL("../../app/javascript/controllers/game_timer_controller.js", import.meta.url), "utf8")

function buildTimer() {
  let now = 0
  const intervals = new Map()
  let nextId = 0
  const context = vm.createContext({
    Controller: class {},
    performance: { now: () => now },
    setInterval(callback) { intervals.set(++nextId, callback); return nextId },
    clearInterval(id) { intervals.delete(id) }
  })
  // Stimulus supplies the base class and values in the browser; emulate that
  // boundary while executing the actual controller's lifecycle and timer logic.
  vm.runInContext(source.replace(/^import .*$/m, "")
    .replace("export default class", "globalThis.Timer = class"), context)
  const timer = new context.Timer()
  timer.displayTarget = { textContent: "" }
  timer.startedAtValue = "2026-11-22T00:00:00.000Z"
  timer.serverTimeValue = "2026-11-23T01:01:05.000Z"
  return { timer, intervals, advance(milliseconds) { now += milliseconds } }
}

test("elapsed display uses the server reference, supports more than 24 hours and advances monotonically", () => {
  const { timer, advance } = buildTimer()
  timer.connect()
  assert.equal(timer.displayTarget.textContent, "25:01:05")
  advance(2000)
  timer.update()
  assert.equal(timer.displayTarget.textContent, "25:01:07")
  timer.disconnect()
})

test("Turbo disconnection removes the interval and reconnection uses a fresh server reference", () => {
  const { timer, intervals } = buildTimer()
  timer.connect()
  assert.equal(intervals.size, 1)
  timer.disconnect()
  assert.equal(intervals.size, 0)
  timer.serverTimeValue = "2026-11-23T02:00:00.000Z"
  timer.connect()
  assert.equal(intervals.size, 1)
  assert.equal(timer.displayTarget.textContent, "26:00:00")
  timer.disconnect()
  assert.equal(intervals.size, 0)
})

test("negative elapsed references are clamped to zero", () => {
  const { timer } = buildTimer()
  timer.serverTimeValue = "2026-11-21T23:59:59.000Z"
  timer.connect()
  assert.equal(timer.displayTarget.textContent, "00:00:00")
  timer.disconnect()
})
