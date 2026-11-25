import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import vm from "node:vm"

const source = readFileSync(new URL("../../app/javascript/controllers/detail_transition_controller.js", import.meta.url), "utf8")

function buildController({ filled }) {
  const context = vm.createContext({ Controller: class {} })
  vm.runInContext(source.replace(/^import .*$/m, "")
    .replace("export default class", "globalThis.DetailTransition = class"), context)
  const controller = new context.DetailTransition()
  controller.filledSelectorValue = ".admin-card"
  controller.element = { dataset: {}, querySelector: (selector) => (filled && selector === ".admin-card" ? {} : null) }
  return controller
}

test("the first detail slides in and the next ones fade", () => {
  const empty = buildController({ filled: false })
  empty.prepare()
  assert.equal(empty.element.dataset.transition, "slide")

  const filled = buildController({ filled: true })
  filled.prepare()
  assert.equal(filled.element.dataset.transition, "fade")
})

test("the transition is cleared when the frame content finishes animating", () => {
  const controller = buildController({ filled: true })
  controller.prepare()

  controller.finish({ target: { parentElement: {} } })
  assert.equal(controller.element.dataset.transition, "fade")

  controller.finish({ target: { parentElement: controller.element } })
  assert.equal(controller.element.dataset.transition, undefined)
})
