(function() {
  if ("undefined" === typeof window.Payone) {
    window.Payone = {}
  } else {
    throw Error("Namespace 'Payone' is not available.")
  }
  if ("undefined" === typeof PayoneGlobals) {
    window.PayoneGlobals = {
      options:  {},
      callback: function(a) {
        document.getElementsByTagName("body")[0].removeChild(window.PayoneGlobals.options.payoneScript)
        var e = window.PayoneGlobals.options.callbackFunctionName
        switch (window.PayoneGlobals.options.returnType) {
          case "object":
            window[e]({
              get: function(e) {
                return a[e]
              },
            })
            break
          case "handler":
            window.PayoneGlobals.options.callbackHandler(a)
            break
          default:
            window[e](a)
        }
      },
    }
  } else {
    throw Error("Namespace 'PayoneGlobals' is not available.")
  }
  Payone.ClientApi = {}
  Payone.ClientApi.Origin = "Payone"
  Payone.ClientApi.MessageEvents = {
    ready:             "READY",
    value:             "VALUE",
    render:            "RENDER",
    setRequestData:    "SET_REQUEST_DATA",
    creditcardcheck:   "CREDITCARDCHECK",
    isComplete:        "IS_COMPLETE",
    focus:             "FOCUS",
    cardtypeChanged:   "CARD_TYPE_CHANGED",
    cardtypeDetection: "CARD_TYPE_DETECTION",
  }
  Payone.ClientApi.InputTypes = {
    cardpan:        "cardpan", cardcvc2: "cardcvc2", cardexpiremonth: "cardexpiremonth",
    cardexpireyear: "cardexpireyear", cardtype: "cardtype",
  }
  Payone.ClientApi.CardTypes = {
    "#": "",
    V:   "Visa",
    M:   "Mastercard",
    A:   "Amex",
    O:   "Maestro (Int)",
    U:   "Maestro (UK)",
    D:   "Diners",
    B:   "Carte Bleue",
    C:   "Discover",
    J:   "JCB",
    P:   "China Union Pay",
  }
  Payone.ClientApi.Defaults = {
    iFrameUrl:                  "https://secure.pay1.de/client-api/js/v1/payone_iframe.html",
    secureDomain:               "https://secure.pay1.de",
    clientApiUrl:               "https://secure.pay1.de/client-api/",
    cardcvc2MaxLength:          4,
    cardtypeDetectionMinLength: 6,
    cardtypeUnknown:            "?",
    cardtypeNotConfigured:      "-",
    cardtypePleaseSelectKey:    "#",
  }
  Payone.ClientApi.Language = {
    de:    {
      months:                {
        month1:  "1",
        month2:  "2",
        month3:  "3",
        month4:  "4",
        month5:  "5",
        month6:  "6",
        month7:  "7",
        month8:  "8",
        month9:  "9",
        month10: "10",
        month11: "11",
        month12: "12",
      },
      invalidCardpan:        "UngÃ¼ltige Kartennummer. Bitte Ã¼berprÃ¼fen Sie die Angaben auf der Karte.",
      invalidCvc:            "UngÃ¼ltige KartenprÃ¼fnummer. Bitte Ã¼berprÃ¼fen Sie die Angaben auf der Karte.",
      invalidPanForCardtype: "Kartentyp stimmt nicht mit der Kartennummer Ã¼berein. Bitte Ã¼berprÃ¼fen Sie die Angaben auf der Karte.",
      invalidCardtype:       "UngÃ¼ltiger Kartentyp. Bitte Ã¼berprÃ¼fen Sie die Angaben auf der Karte.",
      invalidExpireDate:     "Verfallsdatum ungÃ¼ltig. Bitte Ã¼berprÃ¼fen Sie die Angaben auf der Karte.",
      invalidIssueNumber:    "UngÃ¼ltige Kartenfolgenummer (Issue-Number). Bitte Ã¼berprÃ¼fen Sie die Angaben auf der Karte.",
      transactionRejected:   "Die Transaktion wurde abgelehnt. ÃœberprÃ¼fen Sie ggf. Ihre eingegebenen Daten.",
      pleaseSelectCardType:  "Kartentyp auswÃ¤hlen",
      placeholders:          { cardpan: "", cvc: "", expireMonth: "", expireYear: "", issueNumber: "" },
    },
    en:    {
      months:                {
        month1:  "1",
        month2:  "2",
        month3:  "3",
        month4:  "4",
        month5:  "5",
        month6:  "6",
        month7:  "7",
        month8:  "8",
        month9:  "9",
        month10: "10",
        month11: "11",
        month12: "12",
      },
      invalidCardpan:        "Invalid card number. Please verify your card data.",
      invalidCvc:            "Invalid Card Verification Value. Please verify your card data.",
      invalidPanForCardtype: "Card type does not match card number. Please verify your card data.",
      invalidCardtype:       "Card type invalid. Please verify your card data.",
      invalidExpireDate:     "Expiry date invalid. Please verify your card data.",
      invalidIssueNumber:    "Invalid Issue-Number (card sequence number). Please verify your card data.",
      transactionRejected:   "Transaction has been rejected. Please verify your data.",
      pleaseSelectCardType:  "Select cardtype",
      placeholders:          { cardpan: "", cvc: "", expireMonth: "", expireYear: "", issueNumber: "" },
    }, fr: {
      months:                {
        month1:  "1",
        month2:  "2",
        month3:  "3",
        month4:  "4",
        month5:  "5",
        month6:  "6",
        month7:  "7",
        month8:  "8",
        month9:  "9",
        month10: "10",
        month11: "11",
        month12: "12",
      },
      invalidCardpan:        "NumÃ©ro de carte invalide. Veuillez vÃ©rifier les donnÃ©es sur la carte.",
      invalidCvc:            "NumÃ©ro de contrÃ´le de carte invalide. Veuillez vÃ©rifier les donnÃ©es sur la carte.",
      invalidPanForCardtype: "Le type de carte ne correspond pas au numÃ©ro de carte. Veuillez vÃ©rifier les donnÃ©es sur la carte.",
      invalidCardtype:       "Type de carte invalide. Veuillez vÃ©rifier les donnÃ©es sur la carte.",
      invalidExpireDate:     "Date d'expiration invalide. Veuillez vÃ©rifier les donnÃ©es sur la carte.",
      invalidIssueNumber:    "NumÃ©ro d'Ã©mission (Issue Number) incorrect. Veuillez vÃ©rifier les donnÃ©es sur la carte.",
      transactionRejected:   "La transaction a Ã©tÃ© refusÃ©e. Veuillez le cas Ã©chÃ©ant vÃ©rifier vos donnÃ©es.",
      pleaseSelectCardType:  "SÃ©lectionnez le type de carte",
      placeholders:          { cardpan: "", cvc: "", expireMonth: "", expireYear: "", issueNumber: "" },
    }, it: {
      months:                {
        month1:  "1",
        month2:  "2",
        month3:  "3",
        month4:  "4",
        month5:  "5",
        month6:  "6",
        month7:  "7",
        month8:  "8",
        month9:  "9",
        month10: "10",
        month11: "11",
        month12: "12",
      },
      invalidCardpan:        "Numero della carta non valido. Verificare i dati della carta.",
      invalidCvc:            "Numero di controllo della carta non valido. Verificare i dati della carta.",
      invalidPanForCardtype: "Il tipo di carta non coincide con il numero della stessa. Verificare i dati della carta.",
      invalidCardtype:       "Tipo di carta non valido. Verificare i dati della carta.",
      invalidExpireDate:     "Data di scadenza non valida. Verificare i dati della carta.",
      invalidIssueNumber:    "Cifre carta non valide (Issue-Number). Verificare i dati sulla carta.",
      transactionRejected:   "La transazione Ã¨ stata rifiutata. Verificare i dati inseriti.",
      pleaseSelectCardType:  "Scegliere il tipo di carta",
      placeholders:          {
        cardpan: "",
        cvc:     "", expireMonth: "", expireYear: "", issueNumber: "",
      },
    }, es: {
      months:                {
        month1:  "1",
        month2:  "2",
        month3:  "3",
        month4:  "4",
        month5:  "5",
        month6:  "6",
        month7:  "7",
        month8:  "8",
        month9:  "9",
        month10: "10",
        month11: "11",
        month12: "12",
      },
      invalidCardpan:        "NÃºmero de tarjeta invÃ¡lido. SÃ­rvase verificar las indicaciones en la tarjeta.",
      invalidCvc:            "NÃºmero de verificaciÃ³n invÃ¡lido de tarjeta. SÃ­rvase verificar las indicaciones en la tarjeta.",
      invalidPanForCardtype: "Tipo de tarjeta no coincide con nÃºmero de tarjeta. SÃ­rvase verificar las indicaciones en la tarjeta.",
      invalidCardtype:       "Tipo invÃ¡lido de tarjeta. SÃ­rvase verificar las indicaciones en la tarjeta.",
      invalidExpireDate:     "Fecha de expiraciÃ³n invÃ¡lida. SÃ­rvase verificar las indicaciones en la tarjeta.",
      invalidIssueNumber:    "NÃºmero de tarjeta no vÃ¡lido (nÃºmero de emisiÃ³n). Por favor, compruebe los datos de la tarjeta.",
      transactionRejected:   "La transacciÃ³n fue rechazada. SÃ­rvase revisar sus datos ingresados.",
      pleaseSelectCardType:  "Seleccione el tipo de tarjeta",
      placeholders:          {
        cardpan:     "", cvc: "", expireMonth: "", expireYear: "",
        issueNumber: "",
      },
    }, pt: {
      months:                {
        month1:  "1",
        month2:  "2",
        month3:  "3",
        month4:  "4",
        month5:  "5",
        month6:  "6",
        month7:  "7",
        month8:  "8",
        month9:  "9",
        month10: "10",
        month11: "11",
        month12: "12",
      },
      invalidCardpan:        "NÃºmero invÃ¡lido do cartÃ£o de crÃ©dito. Favor verificar os dados do cartÃ£o.",
      invalidCvc:            "NÃºmero invÃ¡lido de seguranÃ§a do cartÃ£o. Favor verificar os dados do cartÃ£o.",
      invalidPanForCardtype: "O tipo do cartÃ£o nÃ£o combina com o nÃºmero do cartÃ£o. Favor verificar os dados do cartÃ£o.",
      invalidCardtype:       "Tipo de cartÃ£o invÃ¡lido. Favor verificar os dados do cartÃ£o.",
      invalidExpireDate:     "Data de expiraÃ§Ã£o invÃ¡lida. Favor verificar os dados do cartÃ£o.",
      invalidIssueNumber:    "SequÃªncia de nÃºmeros do cartÃ£o invÃ¡lida (Issue-Number). Por favor verifique os dados no cartÃ£o.",
      transactionRejected:   "A transacÃ§Ã£o foi recusada. Favor verificar os dados entrados.",
      pleaseSelectCardType:  "Selecione o tipo de cartÃ£o",
      placeholders:          { cardpan: "", cvc: "", expireMonth: "", expireYear: "", issueNumber: "" },
    }, nl: {
      months:                {
        month1: "1", month2: "2", month3: "3", month4: "4", month5: "5", month6: "6", month7: "7",
        month8: "8", month9: "9", month10: "10", month11: "11", month12: "12",
      },
      invalidCardpan:        "Ongeldig creditcardnummer. Controleer s.v.p. de gegevens op de card.",
      invalidCvc:            "Ongeldig cardcontolenummer. Controleer s.v.p. de gegevens op de card.",
      invalidPanForCardtype: "Cardtype past niet bij cardnummer. Controleer s.v.p. de gegevens op de card.",
      invalidCardtype:       "Ongeldig cardtype. Controleer s.v.p. de gegevens op de card.",
      invalidExpireDate:     "Afloopdatum ongeldig. Controleer s.v.p. de gegevens op de card.",
      invalidIssueNumber:    "Ongeldig kaartvolgnummer (issue number). Controleer de gegevens op de kaart a.u.b.",
      transactionRejected:   "De transactie is geweigerd. Controleer s.v.p. uw gegevens.",
      pleaseSelectCardType:  "Select kaarttype",
      placeholders:          { cardpan: "", cvc: "", expireMonth: "", expireYear: "", issueNumber: "" },
    },
  }
  Payone.ClientApi.Request = function(a, e) {
    if ("object" !== typeof a) {
      throw Error("Property 'data' must be of type 'object'")
    }
    if ("object" !== typeof e) {
      throw Error("Property 'options' must be of type 'object'")
    }
    if (e.callbackFunctionName && "string" !== typeof e.callbackFunctionName) {
      throw Error("Property 'options.callbackFunctionName' must be of type 'string'")
    }
    if (e.callbackHandler && "function" !== typeof e.callbackHandler) {
      throw Error("Property 'options.callbackHandler' must be of type 'function'")
    }
    a.callback_method = "PayoneGlobals.callback"
    var r = function() {
      var f = "?", p, g
      Object.keys(a).forEach(function(e) {
        "string" === typeof e && "undefined" !== typeof a[e] && (f = f + encodeURIComponent(e) + "\x3d" + encodeURIComponent(a[e]) + "\x26")
      })
      f = f.substring(0, f.length - 1)
      p = Payone.ClientApi.Defaults.clientApiUrl + f
      g = document.createElement("script")
      g.setAttribute("type", "text/javascript")
      g.setAttribute("src", p)
      e.payoneScript = g
      window.PayoneGlobals.options = e
      document.getElementsByTagName("body")[0].appendChild(g)
    }
    this.checkAndStore = this.send = r
  }
  Payone.ClientApi.HostedIFrames = function(config, e) {
    var r,
        f,
        p,
        g,
        z,
        v,
        A,
        w,
        B,
        l,
        E,
        s,
        F,
        t = "",
        C = !1,
        n,
        h = { value: null, maxlength: null, length: null, applyToInput: null },
        G = !1,
        H = !1,
        I = !1,
        J = !1,
        K = !1,
        L = !1,
        D = "object" === typeof config.autoCardtypeDetection && !("boolean" === typeof config.autoCardtypeDetection.deactivate && !0 === config.autoCardtypeDetection.deactivate),
        x = "object" === typeof config.fields.cardtype ?
          null : !1,
        k = function(a) {
          var b, c = Date.now() + Math.floor(999 * Math.random() + 1)
          b = document.createElement("iframe")
          b.frameBorder = 0
          b.setAttribute("scrolling", "no")
          b.allowtransparency = "true"
          b.height = N(a)
          b.width = O(a)
          b.src = Payone.ClientApi.Defaults.iFrameUrl + "?" + c
          switch (a) {
            case Payone.ClientApi.InputTypes.cardpan:
              f = b
              r.appendChild(b)
              break
            case Payone.ClientApi.InputTypes.cardcvc2:
              g = b
              p.appendChild(b)
              break
            case Payone.ClientApi.InputTypes.cardexpiremonth:
              v = b
              z.appendChild(b)
              break
            case Payone.ClientApi.InputTypes.cardexpireyear:
              w =
                b
              A.appendChild(b)
              break
            case Payone.ClientApi.InputTypes.cardtype:
              l = b, B.appendChild(b)
          }
        },
        m = function(a, b, c) {
          b = JSON.stringify({ event: b, message: c, origin: Payone.ClientApi.Origin })
          a.postMessage(b, Payone.ClientApi.Defaults.secureDomain)
        },
        N = function(d) {
          switch (d) {
            case Payone.ClientApi.InputTypes.cardpan:
              if (config.fields.cardpan.iframe && config.fields.cardpan.iframe.height) {
                return config.fields.cardpan.iframe.height
              }
              break
            case Payone.ClientApi.InputTypes.cardcvc2:
              if (config.fields.cardcvc2.iframe && config.fields.cardcvc2.iframe.height) {
                return config.fields.cardcvc2.iframe.height
              }
              break
            case Payone.ClientApi.InputTypes.cardexpiremonth:
              if (config.fields.cardexpiremonth.iframe && config.fields.cardexpiremonth.iframe.height) {
                return config.fields.cardexpiremonth.iframe.height
              }
              break
            case Payone.ClientApi.InputTypes.cardexpireyear:
              if (config.fields.cardexpireyear.iframe && config.fields.cardexpireyear.iframe.height) {
                return config.fields.cardexpireyear.iframe.height
              }
              break
            case Payone.ClientApi.InputTypes.cardtype:
              if (config.fields.cardtype.iframe && config.fields.cardtype.iframe.height) {
                return config.fields.cardtype.iframe.height
              }
          }
          return config.defaultStyle.iframe.height ||
            "auto"
        },
        O = function(d) {
          switch (d) {
            case Payone.ClientApi.InputTypes.cardpan:
              if (config.fields.cardpan.iframe && config.fields.cardpan.iframe.width) {
                return config.fields.cardpan.iframe.width
              }
              break
            case Payone.ClientApi.InputTypes.cardcvc2:
              if (config.fields.cardcvc2.iframe && config.fields.cardcvc2.iframe.width) {
                return config.fields.cardcvc2.iframe.width
              }
              break
            case Payone.ClientApi.InputTypes.cardexpiremonth:
              if (config.fields.cardexpiremonth.iframe && config.fields.cardexpiremonth.iframe.width) {
                return config.fields.cardexpiremonth.iframe.width
              }
              break
            case Payone.ClientApi.InputTypes.cardexpireyear:
              if (config.fields.cardexpireyear.iframe &&
                config.fields.cardexpireyear.iframe.width) {
                return config.fields.cardexpireyear.iframe.width
              }
              break
            case Payone.ClientApi.InputTypes.cardtype:
              if (config.fields.cardtype.iframe && config.fields.cardtype.iframe.width) {
                return config.fields.cardtype.iframe.width
              }
          }
          return config.defaultStyle.iframe.width || "auto"
        },
        y = function() {
          E && (E = "")
          s && (s.innerHTML = "")
        },
        P = function(d) {
          var b
          try {
            if (d && d.data && (b = JSON.parse(d.data)) && b.event) {
              switch (b.event) {
                case Payone.ClientApi.MessageEvents.ready:
                  d.source == f.contentWindow ? (C = !0, u(f.contentWindow, Payone.ClientApi.InputTypes.cardpan),
                    m(d.source, Payone.ClientApi.MessageEvents.value, {
                      type:  Payone.ClientApi.InputTypes.cardtype,
                      value: t,
                    }), m(d.source, Payone.ClientApi.MessageEvents.setRequestData, {
                    requestData:  e,
                    clientApiUrl: Payone.ClientApi.Defaults.clientApiUrl,
                  })) : d.source == v.contentWindow ? u(v.contentWindow, Payone.ClientApi.InputTypes.cardexpiremonth) : d.source == w.contentWindow ? u(w.contentWindow, Payone.ClientApi.InputTypes.cardexpireyear) : g && d.source == g.contentWindow ? u(g.contentWindow, Payone.ClientApi.InputTypes.cardcvc2) : l && d.source ==
                    l.contentWindow && u(l.contentWindow, Payone.ClientApi.InputTypes.cardtype)
                  break
                case Payone.ClientApi.MessageEvents.value:
                  if (d.source && d.source == f.contentWindow) {
                    y()
                    var c = b.message
                    if ("VALID" === c.status) {
                      c.errorcode = null, c.errormessage = null
                    } else {
                      c.pseudocardpan = null
                      c.truncatedcardpan = null
                      c.cardtype = null
                      c.cardexpiredate = null
                      switch (c.errorcode) {
                        case "31":
                        case "1076":
                        case "880":
                          c.errormessage = n.invalidCardtype || Payone.ClientApi.Language.en.invalidCardtype
                          break
                        case "33":
                        case "1077":
                          c.errormessage =
                            n.invalidExpireDate || Payone.ClientApi.Language.en.invalidExpireDate
                          break
                        case "877":
                        case "878":
                        case "1078":
                          c.errormessage = n.invalidCardpan || Payone.ClientApi.Language.en.invalidCardpan
                          break
                        case "879":
                        case "1079":
                          c.errormessage = n.invalidCvc || Payone.ClientApi.Language.en.invalidCvc
                          break
                        case "1075":
                          c.errormessage = n.invalidIssueNumber || Payone.ClientApi.Language.en.invalidIssueNumber
                          break
                        default:
                          c.errormessage = n.transactionRejected || Payone.ClientApi.Language.en.transactionRejected
                      }
                      s && s.appendChild(document.createTextNode(c.errormessage))
                    }
                    window[F]({
                      status:           c.status,
                      pseudocardpan:    c.pseudocardpan,
                      truncatedcardpan: c.truncatedcardpan,
                      cardtype:         c.cardtype,
                      cardexpiredate:   c.cardexpiredate,
                      errorcode:        c.errorcode,
                      errormessage:     c.errormessage,
                    })
                  } else {
                    y(), m(f.contentWindow, Payone.ClientApi.MessageEvents.value, b.message), d.source && d.source == l.contentWindow && (x = null !== x), config.fields && config.fields.cardcvc2 && ("object" === typeof config.fields.cardcvc2.length || config.fields.cardcvc2.maxlength) && b.message && b.message.type && "cardtype" === b.message.type && (h = {
                      value:  b.message.value, maxlength: config.fields.cardcvc2.maxlength,
                      length: config.fields.cardcvc2.length, applyToInput: !1,
                    }, m(f.contentWindow, Payone.ClientApi.MessageEvents.cardtypeChanged, h), h.applyToInput = !0, m(g.contentWindow, Payone.ClientApi.MessageEvents.cardtypeChanged, h))
                  }
                  break
                case Payone.ClientApi.MessageEvents.isComplete:
                  d.source === f.contentWindow && (G = b.message.isComplete, H = b.message.isCardTypeComplete, I = b.message.isCardpanComplete, J = b.message.isCvcComplete, K = b.message.isExpireMonthComplete, L = b.message.isExpireYearComplete)
                  break
                case Payone.ClientApi.MessageEvents.cardtypeDetection:
                  var q =
                        Payone.ClientApi.Defaults.cardtypeUnknown
                  D && b.message && (d = q = b.message, d !== Payone.ClientApi.Defaults.cardtypeUnknown && config.autoCardtypeDetection.supportedCardtypes.length && -1 === config.autoCardtypeDetection.supportedCardtypes.indexOf(d) && (d = Payone.ClientApi.Defaults.cardtypeNotConfigured), q = d, !x || q !== Payone.ClientApi.Defaults.cardtypeUnknown && q !== Payone.ClientApi.Defaults.cardtypeNotConfigured) && ("function" === typeof config.autoCardtypeDetection.callback && config.autoCardtypeDetection.callback(q), M(q, "cardtypeDetection"))
              }
            }
          } catch (k) {
          }
        },
        u = function(d, b) {
          var c = [], e, f, g, h, k, l = {}, p = []
          switch (b) {
            case Payone.ClientApi.InputTypes.cardpan:
              f = config.fields.cardpan.style || config.defaultStyle.input || ""
              e = config.fields.cardpan.type || "text"
              g = config.fields.cardpan.size || null
              h = config.fields.cardpan.maxlength || null
              break
            case Payone.ClientApi.InputTypes.cardcvc2:
              f = config.fields.cardcvc2.style || config.defaultStyle.input || ""
              e = config.fields.cardcvc2.type || "text"
              g = config.fields.cardcvc2.size || null
              h = config.fields.cardcvc2.maxlength || null
              k = config.fields.cardcvc2.length || null
              break
            case Payone.ClientApi.InputTypes.cardexpiremonth:
              e =
                config.fields.cardexpiremonth.type || "select"
              f = "select" === e ? config.fields.cardexpiremonth.style || config.defaultStyle.select || "" : config.fields.cardexpiremonth.style || config.defaultStyle.input || ""
              g = config.fields.cardexpiremonth.size || null
              h = config.fields.cardexpiremonth.maxlength || null
              l = n.months
              break
            case Payone.ClientApi.InputTypes.cardexpireyear:
              e = config.fields.cardexpireyear.type || "select"
              f = "select" === e ? config.fields.cardexpireyear.style || config.defaultStyle.select || "" : config.fields.cardexpireyear.style || config.defaultStyle.input || ""
              g = config.fields.cardexpireyear.size ||
                null
              h = config.fields.cardexpireyear.maxlength || null
              break
            case Payone.ClientApi.InputTypes.cardtype:
              e = "select", f = config.fields.cardtype.style || config.defaultStyle.select || "", g = config.fields.cardtype.size || null, h = config.fields.cardtype.maxlength || null, p = config.fields.cardtype.cardtypes || [], l = n.pleaseSelectCardType
          }
          c.push(f)
          c.push(e)
          c.push(g)
          c.push(h)
          c.push(l)
          c.push(b)
          c.push(p)
          c.push(n.placeholders)
          c.push(k)
          m(d, Payone.ClientApi.MessageEvents.render, c)
        },
        Q = function() {
          switch (document.activeElement) {
            case l:
            case f:
            case g:
            case v:
            case w:
              m(document.activeElement.contentWindow,
                Payone.ClientApi.MessageEvents.focus)
          }
        },
        M = function(d, b) {
          "undefined" === typeof b && (x = !0)
          t = d
          C && (y(), m(f.contentWindow, Payone.ClientApi.MessageEvents.value, {
            type:  Payone.ClientApi.InputTypes.cardtype,
            value: t,
          }), h.value = t, null === h.length && null === h.maxlength && (h.maxlength = config.fields.cardcvc2.maxlength || null, h.length = config.fields.cardcvc2.length || null), h.applyToInput = !1, m(f.contentWindow, Payone.ClientApi.MessageEvents.cardtypeChanged, h), h.applyToInput = !0, m(g.contentWindow, Payone.ClientApi.MessageEvents.cardtypeChanged,
            h), l && l.contentWindow && m(l.contentWindow, Payone.ClientApi.MessageEvents.cardtypeChanged, t))
        };
    (function() {
      config.error && document.getElementById(config.error) && (s = document.getElementById(config.error))
      if ("object" === typeof config.autoCardtypeDetection && "object" === typeof config.autoCardtypeDetection.supportedCardtypes && "number" === typeof config.autoCardtypeDetection.supportedCardtypes.length) {
        for (var d in config.autoCardtypeDetection.supportedCardtypes) {
          config.autoCardtypeDetection.supportedCardtypes.hasOwnProperty(d) && (config.autoCardtypeDetection.supportedCardtypes[d] =
            config.autoCardtypeDetection.supportedCardtypes[d].toUpperCase())
        }
      } else {
        config.autoCardtypeDetection = {}, config.autoCardtypeDetection.supportedCardtypes = []
      }
      window.addEventListener("message", P)
      if (config.fields.cardpan && config.fields.cardpan.selector && document.getElementById(config.fields.cardpan.selector)) {
        r = document.getElementById(config.fields.cardpan.selector), k(Payone.ClientApi.InputTypes.cardpan)
      } else if (config.fields.cardpan && config.fields.cardpan.element) {
        r = config.fields.cardpan.element, k(Payone.ClientApi.InputTypes.cardpan)
      } else {
        throw Error("Configuration Problem: Property 'fields.cardpan.selector' or 'fields.cardpan.element' is mandatory")
      }
      if (config.fields.cardexpiremonth && config.fields.cardexpiremonth.selector && document.getElementById(config.fields.cardexpiremonth.selector)) {
        z = document.getElementById(config.fields.cardexpiremonth.selector), k(Payone.ClientApi.InputTypes.cardexpiremonth)
      } else if (config.fields.cardexpiremonth && config.fields.cardexpiremonth.element) {
        z = config.fields.cardexpiremonth.element, k(Payone.ClientApi.InputTypes.cardexpiremonth)
      } else {
        throw Error("Configuration Problem: Property 'fields.cardexpiremonth.selector' or 'fields.cardexpiremonth.element' is mandatory")
      }
      if (config.fields.cardexpireyear && config.fields.cardexpireyear.selector && document.getElementById(config.fields.cardexpireyear.selector)) {
        A = document.getElementById(config.fields.cardexpireyear.selector), k(Payone.ClientApi.InputTypes.cardexpireyear)
      } else if (config.fields.cardexpireyear && config.fields.cardexpireyear.element) {
        A = config.fields.cardexpireyear.element, k(Payone.ClientApi.InputTypes.cardexpireyear)
      } else {
        throw Error("Configuration Problem: Property 'fields.cardexpireyear.selector' or 'fields.cardexpireyear.element' is mandatory")
      }
      if (config.fields.cardcvc2 && config.fields.cardcvc2.selector && document.getElementById(config.fields.cardcvc2.selector)) {
        if (config.fields.cardcvc2.length && "object" === typeof config.fields.cardcvc2.length) {
          for (var b in config.fields.cardcvc2.length) {
            "string" === typeof b && config.fields.cardcvc2.length.hasOwnProperty(b) && (config.fields.cardcvc2.length[b.toUpperCase()] = config.fields.cardcvc2.length[b])
          }
        }
        p = document.getElementById(config.fields.cardcvc2.selector)
        k(Payone.ClientApi.InputTypes.cardcvc2)
      } else {
        config.fields.cardcvc2 && config.fields.cardcvc2.element && (p = config.fields.cardcvc2.element,
          k(Payone.ClientApi.InputTypes.cardcvc2))
      }
      config.fields.cardtype && config.fields.cardtype.selector && document.getElementById(config.fields.cardtype.selector) ? (B = document.getElementById(config.fields.cardtype.selector), k(Payone.ClientApi.InputTypes.cardtype)) : config.fields.cardtype && config.fields.cardtype.element && (B = config.fields.cardtype.element, k(Payone.ClientApi.InputTypes.cardtype))
      n = config.language || Payone.ClientApi.Language.en
    })()
    this.setCardType = function(a) {
      M(a)
    }
    this.enableCardTypeDetection = function() {
      D = !0
    }
    this.disableCardTypeDetection =
      function() {
        D = !1
      }
    this.isComplete = function() {
      return C && G
    }
    this.isCardTypeComplete = function() {
      return H
    }
    this.isCvcComplete = function() {
      return J
    }
    this.isCardpanComplete = function() {
      return I
    }
    this.isExpireMonthComplete = function() {
      return K
    }
    this.isExpireYearComplete = function() {
      return L
    }
    this.creditCardCheck = function(a) {
      y()
      F = a
      m(f.contentWindow, Payone.ClientApi.MessageEvents.creditcardcheck)
    }
    /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || window.setInterval(Q,
      100)
  }
})()

