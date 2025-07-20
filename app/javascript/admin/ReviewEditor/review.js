import { has } from "../../lib/has"

const ensureTrimmedString = (obj, field) => {
  if (has(obj, field) && obj[field]) {
    obj[field] = obj[field].toString().trim()
  }
}

export class Review {
  constructor(data, normalize = true) {
    if (normalize) {
      ensureTrimmedString(data, "text")
      ensureTrimmedString(data, "name")
    }

    Object.assign(this, {
      id:           null,
      rating:       null,
      name:         null,
      city:         null,
      text:         null,
      published_at: null,
      url:          null,
      booking:      null,
    }, data)
  }

  clone() {
    return new Review(this, false)
  }

  get isPublished() {
    return !!this.published_at
  }

  get hasRating() {
    return this.rating !== null && this.rating !== undefined
  }

  get isPublishable() {
    return !this.isPublished && !!this.text && this.hasRating
  }

  get isComplete() {
    return !!this.text && this.hasRating && !!this.name
  }

  get isIncomplete() {
    return !this.isPublished && (!this.text || !this.hasRating || !this.name)
  }

  get isNoStars() {
    return !!this.text && !this.hasRating
  }

  toJSON() {
    return {
      id:           this.id,
      rating:       this.rating,
      name:         this.name,
      city:         this.city,
      text:         this.text,
      published_at: this.published_at,
    }
  }
}
