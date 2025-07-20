import Utils from "../../../intervillas-drp/utils"
import { makeDate } from "../../../lib/DateFormatter"
import { format } from "date-fns"

export class Discount {
  constructor({ inquiry_id, inquiry_kind, subject, value, start_date, end_date }) {
    this.inquiry_id = inquiry_id
    this.inquiry_kind = inquiry_kind // "villa", "boat"
    this.subject = subject // "easter", "christmas", "special", "high_season"

    this.copyFrom({ value, start_date, end_date })
  }

  /** @returns {[Number, String, String]} database primary-key tripel */
  get id() {
    return [this.inquiry_id, this.inquiry_kind, this.subject]
  }

  get ident() {
    return this.id.join("-")
  }

  get percentage() {
    if (!this.value) {
      return ""
    }
    return `${this.value < 0 ? "–" : "+"}${Math.abs(this.value)}%`
  }

  get unit() {
    return this.inquiry_kind === "villa" ? "nights" : "days"
  }

  get type() {
    return this.subject === "special" ? "discount" : "addition"
  }

  copyFrom({ value, start_date, end_date }) {
    this.value = value
    this.start_date = start_date && makeDate(start_date)
    this.end_date = end_date && makeDate(end_date)
  }

  async save() {
    const { inquiry_id, inquiry_kind, subject, value, start_date, end_date } = this,
          url = `/api/admin/inquiries/${inquiry_id}/discounts/${inquiry_kind}/${subject}.json`
    const discount = {
      value,
      period: [
        format(start_date, "yyyy-MM-dd"),
        format(end_date, "yyyy-MM-dd"),
      ],
    }

    return await Utils.putJSON(url, { discount })
  }
}
