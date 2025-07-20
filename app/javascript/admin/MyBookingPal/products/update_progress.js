import { translate } from "@digineo/vue-translate"
import { parseISO } from "date-fns"

const toDate = s => s ? parseISO(s) : null

class UpdateStep {
  constructor({ name, started_at, completed_at, todo, done }) {
    this.name = name
    this.started_at = toDate(started_at)
    this.completed_at = toDate(completed_at)
    this.todo = todo || 0
    this.done = done || 0
  }

  get humanName() {
    return translate(this.name, { scope: "admin.my_booking_pal.update_progress.steps" })
  }

  get xofy() {
    if (this.todo === 0) {
      return "processing"
    }
    return `${this.done} of ${this.todo}`
  }
}

export class UpdateProgress {
  constructor(steps) {
    this.steps = steps.map(data => new UpdateStep(data))
    this.done = this.steps.reduce((sum, { done }) => sum + done, 0)
    this.todo = this.steps.reduce((sum, { todo }) => sum + todo, -this.done)
  }
}
