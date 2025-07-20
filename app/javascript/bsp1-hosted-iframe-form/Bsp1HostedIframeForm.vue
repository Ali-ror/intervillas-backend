<template>
  <div>
    <div v-if="showAlert === 'busy'" class="alert alert-info">
      <i class="fa fa-spinner fa-pulse fa-3x fa-fw" />
    </div>

    <PaymentProgress
        v-else-if="showAlert === 'success'"
        provider="bsp1"
        :process-id="bsp1ProcessId"
        :inquiry-token="inquiry_token"
        :redirect="redirect"
    />

    <div v-else-if="showAlert === 'error'" class="alert alert-danger">
      <i class="fa fa-exclamation-triangle" />

      {{ "bsp1_form.error" | translate }}

      <p v-text="errorMessage" />
    </div>

    <div v-else class="well">
      <div class="form-group">
        <label for="cardpanInput">{{ "bsp1_form.cardpan" | translate }}</label>
        <div v-if="detectedCard" class="text-muted pull-right">
          {{ detectedCard.name }}
          <i
              :title="detectedCard.name"
              class="pull-right fa fa-lg"
              :class="detectedCard.icon"
          />
        </div>
        <div :id="makeId('cardpan')" class="inputIframe" />
      </div>

      <div class="row">
        <div class="form-group col-md-6">
          <label for="cvcInput">CVC</label>
          <div :id="makeId('cardcvc2')" class="inputIframe" />
        </div>
        <div class="form-group col-md-6">
          <label for="expireInput">{{ "bsp1_form.valid" | translate }}</label>
          <div id="expireInput" class="inputIframe">
            <span :id="makeId('cardexpiremonth')" />
            <span :id="makeId('cardexpireyear')" />
          </div>
        </div>
      </div>

      <div v-if="deadline === 'downpayment'">
        <div class="radio">
          <label>
            <input
                v-model="paymentScope"
                type="radio"
                :value="deadline"
            >
            {{ "bsp1_form.downpayment" | translate({ sum: currency(singleSum) }) }}
          </label>
        </div>
        <div class="radio">
          <label>
            <input
                v-model="paymentScope"
                type="radio"
                value="downpayment+remainder"
            >
            {{ "bsp1_form.full_payment" | translate({ sum: currency(fullSum) }) }}
          </label>
        </div>
      </div>
      <input
          id="submit"
          class="pull-right btn btn-primary"
          type="button"
          :value="translate('bsp1_form.pay_now')"
          @click="checkCard()"
      >

      <div class="clearfix" />
    </div>
  </div>
</template>

<script>
/* global Payone */
import axios from "axios"
import { translate } from "@digineo/vue-translate"

const KNOWN_CARDS = Object.freeze({
  M: { name: "Mastercard", icon: "fa-cc-mastercard" },
  V: { name: "Visa", icon: "fa-cc-visa" },
  A: { name: "American Express", icon: "fa-cc-amex" },
  O: { name: "Maestro", icon: "fa-credit-card" },
})

const INPUT_STYLE = [
  "display: block",
  "width: 99%",
  "width: calc(100% - 4px)",
  "height: 32px",
  "padding: 6px 12px",
  "margin: 2px",
  "font-size: 13px",
  "line-height: 1.428571429",
  "color: #555555",
  "background-color: #fff",
  "background-image: none",
  "border: 1px solid #ccc",
  "border-radius: 4px",
  "-webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075)",
  "box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075)",
  "-webkit-transition: border-color ease-in-out 0.15s, box-shadow ease-in-out 0.15s",
  "-webkit-transition: border-color ease-in-out 0.15s, -webkit-box-shadow ease-in-out 0.15s",
  "transition: border-color ease-in-out 0.15s, -webkit-box-shadow ease-in-out 0.15s",
  "transition: border-color ease-in-out 0.15s, box-shadow ease-in-out 0.15s",
  "transition: border-color ease-in-out 0.15s, box-shadow ease-in-out 0.15s, -webkit-box-shadow ease-in-out 0.15s",
].join(";")

export default {
  data() {
    return {
      cardType:      "",
      showAlert:     false,
      paymentScope:  "",
      errorMessage:  "",
      bsp1ProcessId: null,
      inquiry_token: null,
      redirect:      null,
    }
  },

  computed: {
    detectedCard() {
      return KNOWN_CARDS[this.cardType]
    },
  },

  mounted() {
    window.bsp1Load.then(() => this.initPayone())
  },

  beforeMount() {
    window.bsp1Load = window.bsp1Load || new Promise((resolve, reject) => {
      let script = document.createElement("script")
      script.onload = () => {
        resolve()
      }

      script.async = true
      script.src = "https://secure.pay1.de/client-api/js/v1/payone_hosted_min.js"
      document.head.appendChild(script)
    })

    this.request = JSON.parse(this.$el.dataset.request)
    this.deadline = this.paymentScope = this.$el.dataset.deadline
    this.singleSum = this.$el.dataset.singleSum
    this.fullSum = this.$el.dataset.fullSum
    this.redirect = this.$el.dataset.redirect
    this.inquiry_token = location.pathname.match(new RegExp("/inquiries/([^/]+)/payments"))[1]
  },

  methods: {
    translate,

    currency(value) {
      const formatter = new Intl.NumberFormat("de-DE", {
        style:                 "currency",
        currency:              this.request.currency,
        minimumFractionDigits: 2,
      })
      return formatter.format(value)
    },

    makeId(id) {
      return [this.deadline, id].join("-")
    },

    initPayone() {
      const config = {
        fields: {
          cardpan: {
            selector: this.makeId("cardpan"),
            style:    INPUT_STYLE,
            class:    "form-input",
            type:     "input",
            iframe:   { width: "100%", height: "36px" },
          },
          cardcvc2: {
            selector:  this.makeId("cardcvc2"),
            type:      "password", // Could be "text" as well.
            style:     INPUT_STYLE,
            size:      "4",
            maxlength: "4",
            length:    { V: 3, M: 3 }, // enforce 3 digit CVC für VISA and Mastercard
            iframe:    { width: "100%", height: "36px" },
          },
          cardexpiremonth: {
            selector:  this.makeId("cardexpiremonth"),
            type:      "text", // select (default), text, tel
            size:      "2",
            maxlength: "2",
            iframe:    { width: "48%", height: "36px" },
            style:     INPUT_STYLE,
          },
          cardexpireyear: {
            selector: this.makeId("cardexpireyear"),
            type:     "text", // select (default), text, tel
            iframe:   { width: "48%", height: "36px" },
            style:    INPUT_STYLE,
          },
        },
        defaultStyle: {
          input:  "font-size: 1em; border: 1px solid #000; width: 175px;",
          select: "font-size: 1em; border: 1px solid #000;",
          iframe: { height: "22px", width: "180px" },
        },
        autoCardtypeDetection: {
          supportedCardtypes: Object.keys(KNOWN_CARDS),
          callback:           this.onAutoCardtypeDetection,
          // deactivate: true // To turn off automatic card type detection.
        },
        language: Payone.ClientApi.Language[document.body.lang], // , // Language to display error-messages (default: Payone.ClientApi.Language.en)
        error:    "error", // area to display error-messages (optional)
      }

      this.iframes = new Payone.ClientApi.HostedIFrames(config, this.request)

      window[this.makeId("cccCallback")] = this.cccCallback.bind(this)
    },

    onAutoCardtypeDetection(detectedCardtype) {
      this.cardType = detectedCardtype
    },

    checkCard() {
      if (this.iframes.isComplete()) {
        this.iframes.creditCardCheck(this.makeId("cccCallback"))
      } else {
        alert("Not complete. Nothing done.")
      }
    },

    cccCallback(response) {
      // {
      //   "status": "VALID",
      //   "pseudocardpan": "9550010000180624531",
      //   "truncatedcardpan": "550000XXXXXX0004",
      //   "cardtype": "M",
      //   "cardexpiredate": "2012",
      //   "errorcode": null,
      //   "errormessage": null
      // }
      // console.debug(response)
      this.showAlert = "busy"

      if (response.status === "VALID") {
        axios.post("/api/bsp1/pseudocardpans",
          {
            pseudocardpan: response.pseudocardpan,
            inquiry_token: this.inquiry_token,
          },
        ).then(response => {
          // console.debug(response)
          this.requestAuthorization()
        }).catch(error => {
          this.showAlert = "error"
        })
      } else {
        this.errorMessage = response.errormessage
        this.showAlert = "error"
      }
    },

    async requestAuthorization() {
      try {
        const { data } = await axios.post("/api/bsp1/transactions", {
          payment_scope: this.paymentScope,
          inquiry_token: this.inquiry_token,
        })
        // console.debug(response)
        const { redirect } = data
        if (redirect) {
          // Für Testmodus
          if (redirect === "reload") {
            location.reload()
          } else {
            location.replace(redirect)
          }
        } else {
          // console.log("success")
          this.bsp1ProcessId = data.bsp1_process_id
          this.showAlert = "success"
        }
      } catch (error) {
        // TODO: genaue Fehlermeldung?
        // console.debug(error)
        this.showAlert = "error"
        this.errorMessage = error.response.data.customermessage
      }
    },
  },
}
</script>

<style scoped>
.nav-tabs > li > a {
  cursor: pointer;
}
</style>
