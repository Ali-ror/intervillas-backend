export default {
  filters: {
    numberFormat(val, options = {}) {
      return (new Intl.NumberFormat("de", options)).format(+val)
    },
  },
}
