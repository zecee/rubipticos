import { Controller } from "@hotwired/stimulus"

// Menú lateral del admin. En pantallas anchas está siempre visible;
// en el celular se abre como cajón con el botón ☰.
export default class extends Controller {
  static targets = ["panel", "toggle", "backdrop"]

  toggle() {
    this.element.classList.contains("sidebar-open") ? this.close() : this.open()
  }

  open() {
    this.element.classList.add("sidebar-open")
    this.toggleTarget.setAttribute("aria-expanded", "true")
    this.backdropTarget.hidden = false
  }

  close() {
    this.element.classList.remove("sidebar-open")
    this.toggleTarget.setAttribute("aria-expanded", "false")
    this.backdropTarget.hidden = true
  }

  closeOnLink(event) {
    if (event.target.closest("a")) this.close()
  }
}
