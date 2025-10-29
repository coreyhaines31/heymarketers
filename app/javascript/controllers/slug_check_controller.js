import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "feedback"]
  static values = {
    url: String,
    profileId: String
  }

  connect() {
    this.timeout = null
  }

  check() {
    clearTimeout(this.timeout)

    const slug = this.inputTarget.value.trim()

    if (!slug) {
      this.hideFeedback()
      return
    }

    // Validate format first
    if (!this.isValidFormat(slug)) {
      this.showError("Only lowercase letters, numbers, and hyphens allowed")
      return
    }

    // Debounce the API call
    this.timeout = setTimeout(() => {
      this.checkAvailability(slug)
    }, 500)
  }

  isValidFormat(slug) {
    return /^[a-z0-9\-]+$/.test(slug)
  }

  async checkAvailability(slug) {
    try {
      this.showChecking()

      const url = `/marketer_profiles/check_slug?slug=${encodeURIComponent(slug)}`
      const params = this.profileIdValue ? `&id=${this.profileIdValue}` : ''

      const response = await fetch(url + params)
      const data = await response.json()

      if (data.available) {
        this.showSuccess("✓ This URL is available")
      } else {
        this.showError(`✗ This URL is not available${data.reason ? `: ${data.reason}` : ''}`)
      }
    } catch (error) {
      this.showError("Unable to check availability")
    }
  }

  showChecking() {
    this.feedbackTarget.style.display = "block"
    this.feedbackTarget.style.color = "var(--color-muted-foreground)"
    this.feedbackTarget.textContent = "Checking availability..."
  }

  showSuccess(message) {
    this.feedbackTarget.style.display = "block"
    this.feedbackTarget.style.color = "var(--color-primary)"
    this.feedbackTarget.textContent = message
  }

  showError(message) {
    this.feedbackTarget.style.display = "block"
    this.feedbackTarget.style.color = "var(--color-destructive)"
    this.feedbackTarget.textContent = message
  }

  hideFeedback() {
    this.feedbackTarget.style.display = "none"
  }
}