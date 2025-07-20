import { formatDateRange, formatDateTime } from "../../../lib/DateFormatter"

export class Reservation {
  constructor({ id, type, created_at, inquiry, product, reservation_id, channel, url, payload, total, rent, deposit, cleaning, commission }) {
    this.id = id
    this.type = type
    this.date = formatDateTime(created_at)
    this.inquiry = inquiry
    this.product = product
    this.reservation_id = reservation_id
    this.channel = channel
    this.url = url
    this.payload = payload
    this.total = total
    this.rent = rent
    this.cleaning = cleaning
    this.deposit = deposit
    this.commission = commission
  }

  get dates() {
    return this.inquiry ? formatDateRange(this.inquiry) : undefined
  }

  get isCancelled() {
    return this.inquiry?.cancelled === true
  }
}
