<template>
  <form
      class="villa-facet-search"
      :class="extraClasses"
      @submit.prevent
  >
    <div v-if="showFacets" class="row open">
      <div class="col-md-4">
        <RangePicker
            class="form-group"
            v-bind="rangePickerBinding"
            split-days
            start-date-input-name="start_date"
            end-date-input-name="end_date"
            @change="drpChange"
        >
          <template #display="display">
            <label>{{ "drp.label.range" | translate }}</label>
            <div v-if="display.start && display.end" class="input-group">
              <span class="form-control hidden-xs">
                {{ "drp.label.arrival" | translate }}: {{ formatDate(display.start) }},
                {{ "drp.label.departure" | translate }}: {{ formatDate(display.end) }}
              </span>
              <span class="form-control visible-xs-inline">
                {{ formatDate(display.start) }} – {{ formatDate(display.end) }}
              </span>
              <span class="input-group-addon">
                <i class="fa fa-calendar" />
              </span>
            </div>
            <div v-else class="input-group">
              <span class="form-control text-muted">
                {{ translate("drp.label.please_select") }}
              </span>
              <span class="input-group-addon">
                <i class="fa fa-calendar" />
              </span>
            </div>
          </template>
        </RangePicker>

        <div class="row">
          <div class="col-sm-6">
            <div class="form-group">
              <label for="people">{{ t("people") }}</label>
              <div class="input-group">
                <span class="input-group-addon">
                  <i class="fa fa-users" />
                </span>
                <select
                    v-model="people"
                    class="form-control"
                    name="people"
                    @change="applyFilter()"
                >
                  <option
                      v-for="i in peopleCollection"
                      :key="i"
                      :value="i"
                  >
                    {{ i }}
                  </option>
                </select>
              </div>
            </div>
          </div>
          <div class="col-sm-6">
            <div class="form-group">
              <label for="rooms">{{ t("rooms") }}</label>
              <div class="input-group">
                <span class="input-group-addon">
                  <i class="fa fa-bed" />
                </span>
                <select
                    v-model="rooms"
                    class="form-control"
                    name="rooms"
                    @change="applyFilter()"
                >
                  <option
                      v-for="i in roomsCollection"
                      :key="i"
                      :value="i"
                  >
                    min. {{ i }}
                  </option>
                </select>
              </div>
            </div>
          </div>
        </div>

        <div class="form-group buttons">
          <button
              class="btn btn-default btn-block"
              type="button"
              @click="removeAndToggleFacets"
          >
            <i class="fa fa-trash" />
            {{ t("hide_filters") }}
          </button>

          <button
              class="btn btn-primary btn-block"
              type="button"
              @click="applyFilter"
          >
            <i class="fa fa-search" />
            {{ t("apply_filter") }}
          </button>
        </div>
      </div>

      <div class="col-md-8 facet-list">
        <div
            v-for="cat in facetsData.categories"
            :key="cat.id"
            class="facet-category"
        >
          <h3>{{ cat.name }}</h3>
          <ul class="facet-tags list-unstyled">
            <li
                v-for="tag in cat.tags"
                :key="tag.id"
                :class="tagDisplayClasses(tag.id)"
            >
              <label>
                <input
                    type="checkbox"
                    :value="tag.id"
                    :disabled="isTagDisabled(tag.id)"
                    :checked="isTagSelected(tag.id)"
                    @change="toggleTag(tag.id)"
                >
                <i class="fa fa-fw fa-lg" :class="tagToggleClasses(tag.id)" />
                <div class="tag-name">{{ tag.name }}</div>
                <div v-if="isTagAvailable(tag.id)" class="tag-count">
                  ({{ countVillasWithTag(tag.id) }})
                </div>
              </label>
            </li>
          </ul>
        </div>

        <div class="facet-category">
          <h3>{{ translate("activerecord.attributes.villa.pool_orientation") }}</h3>
          <ul class="facet-tags list-unstyled">
            <li
                v-for="(sel, o) in orientations"
                :key="o"
                class="available"
            >
              <label>
                <input
                    type="checkbox"
                    :value="o"
                    :checked="sel"
                    @change="toggleOrientation(o)"
                >
                <i class="fa fa-fw fa-lg" :class="orientationToggleClasses(o)" />
                <div class="tag-name">{{ translate(`villas.cardinal_directions.${o}`) }}</div>
              </label>
            </li>
          </ul>
        </div>
      </div>
    </div>

    <div v-else class="row">
      <RangePicker
          v-bind="rangePickerBinding"
          split-days
          :class="offerFacets ? 'col-md-4' : 'col-md-6'"
          start-date-input-name="start_date"
          end-date-input-name="end_date"
          @change="drpChange"
      >
        <template #display="display">
          <label>{{ translate("drp.label.range") }}</label>
          <div v-if="display.start && display.end" class="input-group">
            <span class="form-control hidden-xs hidden-md">
              {{ translate("drp.label.arrival") }}: {{ formatDate(display.start) }},
              {{ translate("drp.label.departure") }}: {{ formatDate(display.end) }}
            </span>
            <span class="form-control visible-xs-inline visible-md-inline">
              {{ formatDate(display.start) }} – {{ formatDate(display.end) }}
            </span>
            <span class="input-group-addon">
              <i class="fa fa-calendar" />
            </span>
          </div>
          <div v-else class="input-group">
            <span class="form-control text-muted">
              {{ translate("drp.label.please_select") }}
            </span>
            <span class="input-group-addon">
              <i class="fa fa-calendar" />
            </span>
          </div>
        </template>
      </RangePicker>

      <div class="col-md-4">
        <div class="row">
          <div class="col-sm-6">
            <div class="form-group">
              <label for="people">{{ t("people") }}</label>
              <div class="input-group">
                <span class="input-group-addon">
                  <i class="fa fa-users" />
                </span>
                <select
                    v-model="people"
                    class="form-control"
                    name="people"
                    @change="applyFilter()"
                >
                  <option
                      v-for="i in peopleCollection"
                      :key="i"
                      :value="i"
                  >
                    {{ i }}
                  </option>
                </select>
              </div>
            </div>
          </div>

          <div class="col-sm-6">
            <div class="form-group">
              <label for="rooms">{{ t("rooms") }}</label>
              <div class="input-group">
                <span class="input-group-addon">
                  <i class="fa fa-bed" />
                </span>
                <select
                    v-model="rooms"
                    class="form-control"
                    name="rooms"
                    @change="applyFilter()"
                >
                  <option
                      v-for="i in roomsCollection"
                      :key="i"
                      :value="i"
                  >
                    min. {{ i }}
                  </option>
                </select>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="text-right buttons" :class="offerFacets ? 'col-md-4' : 'col-md-2'">
        <button
            v-if="offerFacets"
            class="btn btn-default pull-left"
            type="button"
            :title="translate('facets.more_filters')"
            @click="toggleFacets"
        >
          <i class="fa fa-filter" />
          <span class="hidden-md">{{ t("more_filters") }}</span>
        </button>

        <button
            v-if="offerFacets"
            class="btn btn-primary"
            type="button"
            @click="applyFilter"
        >
          <i class="fa fa-search" />
          {{ t("apply_filter") }}
        </button>
        <button
            v-else
            class="btn btn-primary btn-block"
            type="button"
            @click="applyFilter"
        >
          <i class="fa fa-search" />
          {{ t("search") }}
        </button>
      </div>
    </div>
  </form>
</template>

<script src="./VillaFacetSearch.js"></script>

<style lang="scss">
.villa-facet-search {
  padding: 15px 15px 0;
  z-index: 9999;

  h3 {
    color: #5e5e5e !important;
  }

  .buttons {
    margin-top: 22px;
  }

  #reservation-form & {
    margin-top: 30px;
    padding-bottom: 15px;
    background: rgba(#fff, 0.75);
  }
}

.facet-tags {
  input[type="checkbox"] {
    position: absolute;
    opacity: 0;
    height: 0;
    width: 0;
  }
  li {
    > label {
      font-weight: normal;
      cursor: pointer;
      display: block;
    }
    &.selected .tag-name {
      font-weight: bold;
    }
    &.unavailable {
      label {
        cursor: default;
      }
      .tag-name {
        text-decoration: line-through;
      }
    }
    &.available:hover .tag-name {
      text-decoration: underline;
    }
  }
  .tag-name, .tag-count {
    display: inline;
  }
  .tag-count {
    font-size: 11px;
  }
}

@media screen and (min-width: 992px) {
  .facet-list {
    column-count: 3;
    column-gap: 0;
  }

  .facet-list .facet-category {
    break-inside: avoid;
    padding: 5px;
  }

  .villa-facet-search .open .buttons > .btn {
    margin-top: 1ex;
  }
}

@media screen and (min-width: 511px) and (max-width: 991px) {
  .facet-list {
    column-count: 2;
    column-gap: 0;

    .facet-category {
      break-inside: avoid;
      padding: 5px;
    }
  }
}

@media screen and (max-width: 767px) {
  .villa-facet-search {
    margin-left: -15px;
    margin-right: -15px;
  }
}

@media screen and (max-width: 511px) {
  .villa-facet-search .buttons {
    .btn-group.pull-left, .btn {
      display: block;
      float: none !important;
      width: 100%;
      margin-top: 1ex;
    }
  }
}
</style>
