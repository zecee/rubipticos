import { Controller } from "@hotwired/stimulus"

// Anima el detalle que carga un Turbo Frame: la primera vez entra con un
// barrido lateral y, al cambiar de elemento, con un fundido. Lo que llega por
// Turbo Streams (por ejemplo, activar un críptico) no se anima.
export default class extends Controller {
  static values = { filledSelector: { type: String, default: ".admin-card" } }

  prepare() {
    const filled = this.element.querySelector(this.filledSelectorValue)
    this.element.dataset.transition = filled ? "fade" : "slide"
  }

  finish(event) {
    if (event.target.parentElement === this.element) delete this.element.dataset.transition
  }
}
