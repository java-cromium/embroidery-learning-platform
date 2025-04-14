import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "presetList", "saveModal", "presetName", "presetDescription", "globalCheckbox"]

  connect() {
    this.loadPresets()
  }

  async loadPresets() {
    const response = await fetch(`/admin/filter_presets?resource_type=${this.resourceType}`)
    const presets = await response.json()
    this.renderPresets(presets)
  }

  async applyPreset(event) {
    const presetId = event.currentTarget.dataset.presetId
    const form = this.formTarget
    
    // Update usage stats
    await fetch(`/admin/filter_presets/${presetId}/apply`, { method: 'POST' })
    
    // Submit the form with preset filters
    form.submit()
  }

  showSaveModal() {
    const currentFilters = new FormData(this.formTarget).entries()
    const filters = {}
    
    for (const [key, value] of currentFilters) {
      if (value) {
        filters[key] = value
      }
    }
    
    this.currentFilters = filters
    this.saveModalTarget.classList.remove('hidden')
  }

  async savePreset(event) {
    event.preventDefault()
    
    const preset = {
      filter_preset: {
        name: this.presetNameTarget.value,
        description: this.presetDescriptionTarget.value,
        resource_type: this.resourceType,
        global: this.globalCheckboxTarget.checked,
        filters: this.currentFilters
      }
    }

    const response = await fetch('/admin/filter_presets', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify(preset)
    })

    if (response.ok) {
      this.saveModalTarget.classList.add('hidden')
      this.loadPresets()
    } else {
      const errors = await response.json()
      alert(errors.join(', '))
    }
  }

  async deletePreset(event) {
    if (!confirm('Are you sure you want to delete this preset?')) return

    const presetId = event.currentTarget.dataset.presetId
    
    const response = await fetch(`/admin/filter_presets/${presetId}`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })

    if (response.ok) {
      this.loadPresets()
    }
  }

  renderPresets(presets) {
    const html = presets.map(preset => `
      <div class="flex items-center justify-between py-3 border-b last:border-b-0">
        <div>
          <h4 class="text-sm font-medium text-gray-900 flex items-center">
            ${preset.name}
            ${preset.global ? '<span class="ml-2 px-2 py-0.5 text-xs rounded-full bg-pink-100 text-pink-800">Global</span>' : ''}
          </h4>
          ${preset.description ? `<p class="mt-1 text-sm text-gray-500">${preset.description}</p>` : ''}
          <div class="mt-1 flex items-center space-x-4 text-xs text-gray-500">
            <span>Used ${preset.usage_count} times</span>
            ${preset.last_used_at ? `<span>Last used ${new Date(preset.last_used_at).toLocaleDateString()}</span>` : ''}
          </div>
        </div>
        <div class="flex items-center space-x-2">
          <button
            type="button"
            class="inline-flex items-center px-2.5 py-1.5 border border-transparent text-xs font-medium rounded text-pink-700 bg-pink-100 hover:bg-pink-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-pink-500"
            data-action="click->filter-presets#applyPreset"
            data-preset-id="${preset.id}"
          >
            Apply
          </button>
          ${preset.modifiable ? `
            <button
              type="button"
              class="inline-flex items-center px-2.5 py-1.5 border border-transparent text-xs font-medium rounded text-gray-700 bg-gray-100 hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-pink-500"
              data-action="click->filter-presets#deletePreset"
              data-preset-id="${preset.id}"
            >
              Delete
            </button>
          ` : ''}
        </div>
      </div>
    `).join('')

    this.presetListTarget.innerHTML = html
  }

  get resourceType() {
    return this.element.dataset.resourceType
  }
}
