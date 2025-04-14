import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "tagContainer"]

  connect() {
    this.submitDebounceTimer = null
  }

  submit() {
    this.formTarget.requestSubmit()
  }

  debounceSubmit() {
    clearTimeout(this.submitDebounceTimer)
    this.submitDebounceTimer = setTimeout(() => this.submit(), 500)
  }

  toggleRating(event) {
    const rating = event.currentTarget.dataset.rating
    const filterName = event.currentTarget.dataset.filterName
    const input = this.formTarget.querySelector(`input[name="${filterName}"]`)
    
    if (input.value === rating) {
      input.value = ''
    } else {
      input.value = rating
    }

    // Update star colors
    const stars = event.currentTarget.parentElement.querySelectorAll('svg')
    stars.forEach((star, index) => {
      if (index < rating) {
        star.classList.remove('text-gray-300')
        star.classList.add('text-yellow-400')
      } else {
        star.classList.remove('text-yellow-400')
        star.classList.add('text-gray-300')
      }
    })

    this.submit()
  }

  toggleTag(event) {
    const tagValue = event.currentTarget.dataset.tagValue
    const filterName = event.currentTarget.dataset.filterName
    const input = this.formTarget.querySelector(`input[name="${filterName}[]"]`)
    const currentValues = input.value ? input.value.split(',') : []
    
    const index = currentValues.indexOf(tagValue)
    if (index > -1) {
      currentValues.splice(index, 1)
      event.currentTarget.classList.remove('bg-pink-100', 'text-pink-800')
      event.currentTarget.classList.add('bg-gray-100', 'text-gray-800')
    } else {
      currentValues.push(tagValue)
      event.currentTarget.classList.remove('bg-gray-100', 'text-gray-800')
      event.currentTarget.classList.add('bg-pink-100', 'text-pink-800')
    }

    input.value = currentValues.join(',')
    this.submit()
  }
}
