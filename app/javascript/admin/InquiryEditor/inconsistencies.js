export default {
  display(inconsistencies) {
    const container = $("#inconsistencies")
    container.empty()

    if (!inconsistencies || inconsistencies.trim() === "") {
      return
    }

    container.append(inconsistencies)
  },
}
