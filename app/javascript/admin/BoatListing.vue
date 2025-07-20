<template>
  <div class="list-group list-group-condensed admin-boat-list">
    <div class="list-group-item">
      <div class="input-group">
        <span class="input-group-addon">
          <i class="fa fa-search" />
        </span>
        <input
            v-model.trim="filterInput"
            type="text"
            class="form-control"
            placeholder="Filter"
        >
        <span v-if="filterInput" class="input-group-btn">
          <button
              class="btn btn-default"
              type="button"
              @click="filterInput = ''"
          >
            <i class="fa fa-times" />
          </button>
        </span>
      </div>
    </div>
    <div class="list-group-item">
      <div class="btn-group btn-group-sm d-flex">
        <button
            class="btn btn-default flex-grow-1"
            :class="{ active: visibility == null }"
            type="button"
            @click.prevent="visibility = null"
        >
          alle
        </button>
        <button
            class="btn btn-default flex-grow-1"
            :class="{ active: visibility === false }"
            type="button"
            @click.prevent="visibility = false"
        >
          aktive
        </button>
        <button
            class="btn btn-default flex-grow-1"
            :class="{ active: visibility === true }"
            type="button"
            @click.prevent="visibility = true"
        >
          ausgebl.
        </button>
      </div>
    </div>

    <div class="boats">
      <a
          v-for="boat in filteredBoats"
          :key="boat.id"
          :href="boat.url"
          class="list-group-item"
          :class="{ active: boat.isActive }"
      >
        <span v-if="boat.hidden" v-text="boat.model" />
        <strong v-else v-text="boat.model" />

        <div class="small">
          <div class="pull-right">
            <i
                v-if="boat.hidden"
                class="fa fa-fw fa-eye-slash"
                title="ausgeblendetes Boot aus Bestandsbuchungen"
            />
            {{ boat.id }}
          </div>
          {{ boat.matno }}
        </div>
      </a>
    </div>
  </div>
</template>

<script>
const normalize = s => s.toString()
  .replace(/[^-\wäöüß]+/g, "")
  .replace(/\s+/g, " ")
  .toLowerCase()

class Boat {
  constructor([id, model, hidden, url, matno]) {
    this.id = id
    this.model = model
    this.hidden = hidden
    this.url = url
    this.matno = matno || "FL-???"

    this.matchText = normalize([this.model, this.matno, this.id].join(" "))
  }

  matches(str) {
    return this.matchText.indexOf(str) >= 0
  }

  get isActive() {
    return window.location.pathname.indexOf(this.url) === 0
  }
}

export default {
  props: {
    boats:   { type: Array, required: true },
    current: { type: Number, default: null },
  },

  data() {
    const current = this.boats.find(b => b[0] === this.current)

    return {
      visibility:   current && current[2], // null = show all, otherwise match boats[i].hidden
      showInactive: true,
      filterInput:  "",
    }
  },

  computed: {
    actualBoats() {
      return this.boats.map(data => new Boat(data))
    },

    filteredBoats() {
      const { visibility } = this,
            byVisibility = this.actualBoats.filter(boat => {
              return visibility == null || boat.hidden === visibility
            })

      if (this.filterInput) {
        const q = normalize(this.filterInput)
        return byVisibility.filter(boat => boat.matches(q))
      }
      return byVisibility
    },
  },
}
</script>

<style>
  .admin-boat-list {
    position: sticky;
    top: 0;
  }
  .admin-boat-list .boats {
    max-height: 78vh;
    overflow: scroll;
  }
</style>
