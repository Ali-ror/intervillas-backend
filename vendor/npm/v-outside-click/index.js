/**
 * Injects an "outside click handler" into the document, allowing you
 * e.g. to close a widget, if it currently is open.
 *
 * @example
 *    new Vue({
 *      template: `<div v-outside-click="hide">{{ msg }}</div>`,
 *      data() {
 *        return { msg: "hello world" }
 *      },
 *      methods: {
 *        hide() { this.msg = "" },
 *      },
 *    })
 */
export default {
  /**
   * @param {HTMLElement} el The element the directive is bound to
   * @param {Object} binding A context object
   * @param {VNode} vnode The virtual node produced by Vue’s compiler
   */
  bind(el, binding, vnode) {
    el.outsideClickEventHandler = event => {
      if (!(el === event.target || el.contains(event.target))) {
        vnode.context[binding.expression](event)
      }
    }
    document.body.addEventListener("click", el.outsideClickEventHandler)
  },

  /**
   * @param {HTMLElement} el The element the directive is bound to
   */
  unbind(el) {
    document.body.removeEventListener("click", el.outsideClickEventHandler)
  },
}
