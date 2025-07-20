import Cookies from "js-cookie"

export function newsletterDismissed() {
  return Cookies.get("newsletter") != null
}

export function dismissNewsletter(subscribed) {
  const val = subscribed ? "1" : "0",
        exp = subscribed ? 3650 : 30

  Cookies.set("newsletter", val, {
    expires:  exp, // days
    sameSite: "lax",
  })
}
