import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track"]

  connect() {
    this.currentIndex = 0
    this.itemsPerView = window.innerWidth >= 768 ? 3 : 1
    this.totalItems = this.trackTarget.children.length
    this.maxIndex = Math.max(0, this.totalItems - this.itemsPerView)

    // Auto-rotate every 5 seconds
    this.startAutoRotate()

    // Adjust on window resize
    window.addEventListener('resize', this.handleResize.bind(this))
  }

  disconnect() {
    this.stopAutoRotate()
    window.removeEventListener('resize', this.handleResize.bind(this))
  }

  handleResize() {
    this.itemsPerView = window.innerWidth >= 768 ? 3 : 1
    this.maxIndex = Math.max(0, this.totalItems - this.itemsPerView)
    if (this.currentIndex > this.maxIndex) {
      this.currentIndex = this.maxIndex
    }
    this.updatePosition()
  }

  previous() {
    this.stopAutoRotate()
    if (this.currentIndex > 0) {
      this.currentIndex--
      this.updatePosition()
    }
    this.startAutoRotate()
  }

  next() {
    this.stopAutoRotate()
    if (this.currentIndex < this.maxIndex) {
      this.currentIndex++
    } else {
      // Loop back to start
      this.currentIndex = 0
    }
    this.updatePosition()
    this.startAutoRotate()
  }

  updatePosition() {
    const itemWidth = 100 / this.itemsPerView
    const offset = -this.currentIndex * itemWidth
    this.trackTarget.style.transform = `translateX(${offset}%)`
  }

  startAutoRotate() {
    this.stopAutoRotate()
    this.autoRotateInterval = setInterval(() => {
      this.next()
    }, 5000)
  }

  stopAutoRotate() {
    if (this.autoRotateInterval) {
      clearInterval(this.autoRotateInterval)
    }
  }
}