import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  static values = { startedAt: String, serverTime: String }

  connect() {
    this.initialSeconds = Math.max(0,
      (Date.parse(this.serverTimeValue) - Date.parse(this.startedAtValue)) / 1000)
    this.connectedAt = performance.now()
    this.update()
    this.interval = setInterval(() => this.update(), 1000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  update() {
    const seconds = Math.floor(this.initialSeconds + (performance.now() - this.connectedAt) / 1000)
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    this.displayTarget.textContent = [hours, minutes, seconds % 60]
      .map(value => String(value).padStart(2, "0")).join(":")
  }
}
