<template>
  <div v-if="success">
    <div class="text-center">
      <i class="fa fa-check fa-4x" /><br>
    </div>
    <h4 v-text="translate('contact_form.created.heading')" />
    <p v-text="translate('contact_form.created.body')" />
    <p>
      {{ translate("contact_form.created.closing") }},<br>
      {{ translate("footer.closing") }}
    </p>
  </div>

  <form v-else @submit.prevent="onSubmit">
    <h4 v-text="translate('contact_form.heading')" />
    <div class="form-group" :class="{ 'has-error': errors.name }">
      <label
          class="sr-only"
          for="contact-form-name"
          v-text="translate('contact_form.request.name')"
      />
      <input
          id="contact-form-name"
          v-model="name"
          class="form-control"
          name="name"
          type="text"
          required
          :disabled="loading"
          :placeholder="translate('contact_form.request.name') + ' *'"
      >
      <span
          v-if="errors.name"
          class="help-class"
          v-text="errors.name.join(', ')"
      />
    </div>
    <div class="form-group" :class="{ 'has-error': errors.email }">
      <label
          class="sr-only"
          for="contact-form-email"
          v-text="translate('contact_form.request.email')"
      />
      <input
          id="contact-form-email"
          v-model="email"
          class="form-control"
          name="email"
          type="email"
          required
          :disabled="loading"
          :placeholder="translate('contact_form.request.email') + ' *'"
      >
      <span
          v-if="errors.email"
          class="help-class"
          v-text="errors.email.join(', ')"
      />
    </div>
    <div class="form-group" :class="{ 'has-error': errors.phone }">
      <label
          class="sr-only"
          for="contact-form-phone"
          v-text="translate('contact_form.request.phone')"
      />
      <input
          id="contact-form-phone"
          v-model="phone"
          class="form-control"
          name="phone"
          type="tel"
          :disabled="loading"
          :placeholder="translate('contact_form.request.phone')"
      >
      <span
          v-if="errors.phone"
          class="help-class"
          v-text="errors.phone.join(', ')"
      />
    </div>
    <div class="form-group" :class="{ 'has-error': errors.text }">
      <label
          class="sr-only"
          for="contact-form-text"
          v-text="translate('contact_form.request.text')"
      />
      <textarea
          id="contact-form-text"
          v-model="text"
          class="form-control"
          name="text"
          required
          :disabled="loading"
          :placeholder="translate('contact_form.request.text') + ' *'"
      />
      <span
          v-if="errors.text"
          class="help-class"
          v-text="errors.text.join(', ')"
      />
    </div>

    <div
        v-if="dirty || haveCaptcha || errors.captcha"
        class="form-group"
        :class="{ 'has-error': errors.captcha }"
    >
      <div ref="captcha" />
      <span
          v-if="errors.captcha"
          class="help-class"
          v-text="errors.captcha.join(', ')"
      />
    </div>

    <button
        class="btn btn-sm btn-block"
        type="submit"
        :disabled="loading || requireCaptcha"
    >
      <i v-if="loading" class="fa fa-spinner fa-pulse" />
      {{ translate("contact_form.submit") }}
    </button>
  </form>
</template>

<script>
import { translate } from "@digineo/vue-translate"
import Utils from "../intervillas-drp/utils"

export default {
  props: {
    url:     { type: String, required: true },
    sitekey: { type: String, default: null },
    villaId: { type: [String, Number], default: null },
  },

  data() {
    return {
      name:    null,
      email:   null,
      phone:   null,
      text:    null,
      captcha: null,

      loading:     false, // POST in progress?
      success:     false, // contact request created?
      errors:      {}, // model validation errors
      haveCaptcha: false, // recaptcha loaded?
    }
  },

  computed: {
    dirty() {
      return !!this.name && !!this.email && !!this.text
    },

    requireCaptcha() {
      const { captcha, sitekey } = this
      if (!sitekey) {
        return false
      }
      return captcha == null
    },
  },

  watch: {
    dirty(isDirty) {
      if (this.sitekey && isDirty && !this.haveCaptcha) {
        this.loadCaptcha()
      }
    },
  },

  methods: {
    translate,

    async onSubmit() {
      if (this.loading) {
        return
      }


      try {
        const { name, email, phone, text, villaId, captcha } = this
        this.errors = await Utils.postJSON(this.url, {
          "g-recaptcha-response": captcha,
          "contact_request":      {
            name,
            email,
            phone,
            text,
            villa_id:     villaId,
            current_page: window.location.toString(),
          },
        })
        this.success = !this.errors
      } finally {
        this.loading = false
      }
    },

    loadCaptcha() {
      const script = document.createElement("script"),
            init = `captchaLoaded${new Date().valueOf()}`,
            hl = document.body.lang
      window[init] = this.captchaLoaded.bind(this)
      script.async = true
      script.defer = true
      script.src = `https://www.recaptcha.net/recaptcha/api.js?hl=${hl}&onload=${init}&render=explicit`
      document.head.appendChild(script)
    },

    captchaLoaded() {
      this.haveCaptcha = true
      this.captcha = null
      window.grecaptcha.render(this.$refs.captcha, {
        "sitekey":          this.sitekey,
        "callback":         this.onRecaptcha.bind(this),
        "expired-callback": this.onRecaptchaExpired.bind(this),
      })
    },

    onRecaptcha(response) {
      this.captcha = response
    },

    onRecaptchaExpired() {
      this.captcha = null
    },
  },
}
</script>
