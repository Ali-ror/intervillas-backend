<template>
  <form
      id="mc-embedded-subscribe-form"
      action="https://intervillas-florida.us7.list-manage.com/subscribe/post?u=00ff637d9a4a9cadd10d33dc1&amp;id=9efcc9f1c7&amp;f_id=0027fae3f0"
      method="post"
      name="mc-embedded-subscribe-form"
      target="_blank"
      @submit="$emit('done')"
  >
    <div class="form-group">
      <label
          class="sr-only"
          for="mce-EMAIL"
          v-text="t('email')"
      />
      <input
          id="mce-EMAIL"
          v-model="email"
          type="email"
          name="EMAIL"
          class="form-control"
          :placeholder="placeholder('email')"
          required
      >
    </div>
    <div class="form-group">
      <label
          class="sr-only"
          for="mce-FNAME"
          v-text="placeholder('firstname')"
      />
      <input
          id="mce-FNAME"
          v-model="firstname"
          type="text"
          name="FNAME"
          class="form-control"
          :placeholder="placeholder('firstname')"
      >
    </div>
    <div class="form-group">
      <label
          class="sr-only"
          for="mce-LNAME"
          v-text="t('lastname')"
      />
      <input
          id="mce-LNAME"
          v-model="lastname"
          type="text"
          name="LNAME"
          class="form-control"
          :placeholder="placeholder('lastname')"
      >
    </div>
    <div class="d-none">
      <input
          id="mce-MMERGE6"
          :value="language"
          type="hidden"
          name="MMERGE6"
      >
    </div>
    <div style="position: absolute; left: -5000px;" aria-hidden="true">
      <input
          type="text"
          name="b_00ff637d9a4a9cadd10d33dc1_9efcc9f1c7"
          tabindex="-1"
          value=""
      >
    </div>
    <div class="clear">
      <input
          id="mc-embedded-subscribe"
          type="submit"
          :value="t('subscribe')"
          name="subscribe"
          class="btn btn-primary btn-block"
      >
    </div>
  </form>
</template>

<script>
import { translate } from "@digineo/vue-translate"
const t = key => translate(key, { scope: "newsletter.signup_form" })

export default {
  data() {
    return {
      email:     null,
      firstname: null,
      lastname:  null,
      language:  document.body.lang,
    }
  },

  methods: {
    t,

    placeholder(key) {
      return [t(key), "*"].join(" ")
    },
  },
}
</script>
