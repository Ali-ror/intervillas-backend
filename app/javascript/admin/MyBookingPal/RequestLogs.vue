<template>
  <AsyncLoader :url="url" @data="onData">
    <p>
      Showing {{ entries.length }} of the last {{ totalEntries }} log entries.
    </p>

    <table class="table table-striped table-condensed">
      <thead>
        <tr>
          <th>Date</th>
          <th>Endpoint</th>
          <th class="text-center">
            Access<br>Level
          </th>
          <th class="text-right">
            Request<br>size
          </th>
          <th class="text-right">
            Response<br>size
          </th>
          <th>
            Response<br>code
          </th>
          <th class="text-right">
            Duration
            <div class="small">
              (seconds)
            </div>
          </th>
          <th>
            Response<br>message
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="ent, i in entries" :key="i">
          <td>{{ ent.time || "?" }}</td>
          <td>
            <span
                class="label mr-2"
                :class="['label', `label-${ent.methodVariant}`]"
                v-text="ent.method"
            />
            <code v-text="ent.path" />
          </td>
          <td class="text-center">
            {{ ent.privileged === null ? "—" : ent.privileged ? "PMS" : "PM" }}
          </td>
          <td class="text-right" :title="ent.request_length === null ? undefined : `${ent.request_length} bytes`">
            {{ ent.request_length === null ? "—" : formatUnit(ent.request_length) }}
          </td>
          <td class="text-right" :title="ent.response_length === null ? undefined : `${ent.response_length} bytes`">
            {{ ent.response_length === null ? "—" : formatUnit(ent.response_length) }}
          </td>
          <td :class="`text-${ent.codeVariant}`">
            {{ ent.code }} {{ ent.codeText }}
          </td>
          <td class="text-right">
            <TurtleIcon
                v-if="ent.slow"
                :solid="ent.verySlow"
                class="text-danger"
            />
            <span class="duration">
              {{ ent.duration }}
            </span>
          </td>
          <td
              class="small"
              :class="{ 'text-danger': ent.error }"
              v-text="ent.error || ent.message || '—'"
          />
        </tr>
      </tbody>
    </table>

    <UiPagination
        v-model="currentPage"
        :total-entries="totalEntries"
        :per-page="perPage"
    />
  </AsyncLoader>
</template>

<script>
import UiPagination from "../../components/UiPagination.vue"
import AsyncLoader from "../AsyncLoader.vue"
import { formatDateTime } from "../../lib/DateFormatter"
import TurtleIcon from "./TurtleIcon.vue"
import { HttpStatusCode } from "axios"

const URL = "/admin/my_booking_pal/request_logs.json"

const fmtNum = new Intl.NumberFormat(document.body.lang, {
  style:                    "decimal",
  minimumIntegerDigits:     1,
  maximumFractionDigits:    3,
  maximumSignificantDigits: 3,
}).format

const formatUnit = val => val < 900 ? `${val} B` : `${fmtNum(val / 1000)} kB`

const CODE_VARIANTS = new Map([
  [2, "success"],
  [4, "warning"],
  [5, "danger"],
])

const METHOD_VARIANTS = new Map([
  ["GET", "success"],
  ["POST", "warning"],
  ["PUT", "info"],
  ["DELETE", "danger"],
])

const describeHttpStatusCode = (resolved => {
  return code => {
    let t = resolved.get(code)
    if (t === undefined) {
      t = (HttpStatusCode[code] || "")
        .replace(/([a-z])([A-Z])/g, "$1 $2")
        .toLocaleLowerCase()
      resolved.set(code, t)
    }
    return t
  }
})(new Map())

function toEntry({ time, code, method, duration, ...rest }) {
  const ent = {
    ...rest,
    time:          null,
    code:          parseInt(code, 10),
    codeVariant:   null,
    codeText:      describeHttpStatusCode(code),
    method:        method.toUpperCase(),
    methodVariant: null,
    duration:      fmtNum(Math.round(duration * 1000) / 1000),
    slow:          duration > 5,
    verySlow:      duration > 15,
  }

  ent.time = time ? formatDateTime(time) : null
  ent.codeVariant = CODE_VARIANTS.get(Math.floor(ent.code / 100)) ?? null
  ent.methodVariant = METHOD_VARIANTS.get(ent.method) ?? "default"
  return ent
}

export default {
  components: {
    UiPagination,
    AsyncLoader,
    TurtleIcon,
  },

  data() {
    return {
      entries:      [],
      totalEntries: null,
      currentPage:  1,
      perPage:      30,
    }
  },

  computed: {
    url() {
      return `${URL}?page=${this.currentPage}`
    },
  },

  methods: {
    formatUnit,

    onData({ entries, pagination: { page, total, per } }) {
      this.entries = entries.map(ent => toEntry(ent))
      this.totalEntries = total
      this.perPage = per
      this.currentPage = page
    },
  },
}
</script>

<style lang="scss" scoped>
.duration {
  display: inline-block;
  width: 60px;
}
</style>
