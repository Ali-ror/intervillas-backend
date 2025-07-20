export default class Filter {
  constructor(activeVillaIDs, options = {}) {
    const { startDate, endDate, numPeople, numRooms, tagIDs, locations } = options

    // URL params
    this.startDate = startDate
    this.endDate = endDate
    this.numPeople = numPeople
    this.numRooms = numRooms
    this.tagIDs = tagIDs
    this.locations = locations

    // not URL params
    this.activeVillaIDs = activeVillaIDs
  }

  toParams() {
    const params = {}

    if (this.startDate) {
      params["start_date"] = this.startDate
    }
    if (this.endDate) {
      params["end_date"] = this.endDate
    }
    if (this.numPeople) {
      params["people"] = this.numPeople
    }
    if (this.numRooms) {
      params["rooms"] = this.numRooms
    }
    if (this.tagIDs.length > 0) {
      params["tags"] = this.tagIDs.join(",")
    }
    if (this.locations.length > 0 && this.locations.length < 8) {
      params["locations"] = this.locations.join(",")
    }
    return params
  }
}
