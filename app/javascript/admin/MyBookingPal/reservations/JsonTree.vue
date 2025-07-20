<!--
  Sourced from https://github.com/myst729/vue-json-tree (MIT) and slightly modified
-->
<template>
  <span class="json-tree" :class="{'json-tree-root': parsed.depth === 0}">
    <span v-if="parsed.primitive" class="json-tree-row">
      <span
          v-for="n in (parsed.depth * 2 + 3)"
          :key="n"
          class="json-tree-indent"
      >&nbsp;</span>
      <span v-if="parsed.key" class="json-tree-key">{{ parsed.key }}</span>
      <span v-if="parsed.key" class="json-tree-colon">:&nbsp;</span>
      <span
          class="json-tree-value"
          :class="'json-tree-value-' + parsed.type"
      >{{ `${parsed.value}` }}</span>
      <span v-if="!parsed.last" class="json-tree-comma">,</span>
    </span>

    <span v-else class="json-tree-deep">
      <span
          class="json-tree-row json-tree-expando"
          @click="expanded = !expanded"
          @mouseover="hovered = true"
          @mouseout="hovered = false"
      >
        <span class="json-tree-indent">&nbsp;</span>
        <span :class="expanded ? 'json-tree-expando-expanded' : 'json-tree-expando-collapsed'"/>
        <span
            v-for="n in (parsed.depth * 2 + 1)"
            :key="n"
            class="json-tree-indent"
        >&nbsp;</span>
        <span v-if="parsed.key" class="json-tree-key">{{ parsed.key }}</span>
        <span v-if="parsed.key" class="json-tree-colon">:&nbsp;</span>
        <span class="json-tree-open">{{ parsed.type === 'array' ? '[' : '{' }}</span>
        <span v-show="!expanded" class="json-tree-collapsed">&nbsp;/*&nbsp;{{ format(parsed.value.length) }}&nbsp;*/&nbsp;</span>
        <span v-show="!expanded" class="json-tree-close">{{ parsed.type === 'array' ? ']' : '}' }}</span>
        <span v-show="!expanded && !parsed.last" class="json-tree-comma">,</span>
        <span class="json-tree-indent">&nbsp;</span>
      </span>
      <span v-show="expanded" class="json-tree-deeper">
        <JsonTree
            v-for="(item, index) in parsed.value"
            :key="index"
            :kv="item"
            :level="level"
        />
      </span>
      <span v-show="expanded" class="json-tree-row">
        <span class="json-tree-ending" :class="{'json-tree-paired': hovered}">
          <span
              v-for="n in (parsed.depth * 2 + 3)"
              :key="n"
              class="json-tree-indent"
          >&nbsp;</span>
          <span class="json-tree-close">{{ parsed.type === 'array' ? ']' : '}' }}</span>
          <span v-if="!parsed.last" class="json-tree-comma">,</span>
        </span>
      </span>
    </span>
  </span>
</template>

<script>
function parse(data, depth = 0, last = true, key = undefined) {
  const kv = {
    depth,
    last,
    primitive: true,
    key:       JSON.stringify(key),
  }

  if (typeof data !== "object") {
    return Object.assign(kv, { type: typeof data, value: JSON.stringify(data) })
  }
  if (data === null) {
    return Object.assign(kv, { type: "null", value: "null" })
  }
  if (Array.isArray(data)) {
    const value = data.map((item, index) => {
      return parse(item, depth + 1, index === data.length - 1)
    })
    return Object.assign(kv, { primitive: false, type: "array", value })
  }

  const keys = Object.keys(data)
  const value = keys.map((key, index) => {
    return parse(data[key], depth + 1, index === keys.length - 1, key)
  })
  return Object.assign(kv, { primitive: false, type: "object", value })
}

export default {
  name: "JsonTree",

  props: {
    level: { type: Number, default: Infinity },
    kv:    { type: Object, default: undefined },
    value: { type: Object, default: undefined },
  },

  data() {
    return {
      expanded: true,
      hovered:  false,
    }
  },

  computed: {
    parsed() {
      return this.kv ?? parse(this.value)
    },
  },

  created() {
    this.expanded = this.parsed.depth < this.level
  },

  methods: {
    format(n) {
      if (n > 1) {
        return `${n} Einträge`
      }
      return n ? "1 Eintrag" : "Leer"
    },
  },
}
</script>

<style>
.json-tree {
  color: #394359;
  display: flex;
  flex-direction: column;
  font-family: Menlo, Monaco, Consolas, monospace;
  font-size: 12px;
  line-height: 20px;
}

.json-tree-root {
  background-color: #f7f8f9;
  border-radius: 3px;
  margin: 2px 0;
  min-width: 560px;
  padding: 10px;
}

.json-tree-ending,
.json-tree-row {
  border-radius: 2px;
  display: flex;
}

.json-tree-paired,
.json-tree-row:hover {
  background-color: #bce2ff;
}

.json-tree-expando                   { cursor: pointer; }
.json-tree-expando-expanded::before  { font-weight: 700; content: "-"; }
.json-tree-expando-collapsed::before { font-weight: 700; content: "+"; }

.json-tree-collapsed {
  color: gray;
  font-style: italic;
}

.json-tree-value {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.json-tree-value-string {
  color: #9aab3a;
}

.json-tree-value-boolean {
  color: #ff0080;
}

.json-tree-value-number {
  color: #4f7096;
}

.json-tree-value-null {
  color: #c7444a;
}
</style>
