/* eslint-env node */

import { defineConfig } from "vite"
import createVuePlugin from "@vitejs/plugin-vue2"
import createRailsPlugin from "vite-plugin-rails"
import createInjectPlugin from "@rollup/plugin-inject"
import { join, resolve } from "path"

const jsRoot = {
  base: resolve(__dirname, "app/javascript"),
  join(name) {
    return join(this.base, name)
  },
}

export default defineConfig({
  clearScreen: false,

  build: {
    // Vite doesn't emit *.gz or *.br files, but in order to report savings,
    // it'll compress them in-memoroy. This is a waste of CPU cycles, especially
    // for the large vendor chunk...
    reportCompressedSize: false,

    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes("/node_modules/")) {
            return "vendor"
          }
        }
      }
    }
  },

  resolve: {
    alias: [
      // vue incl. compiler
      { find: "vue", replacement: "vue/dist/vue.esm.js" },

      // point to ESM files
      { find: "vuedraggable", replacement: "vuedraggable/src/vuedraggable.js" },
      { find: "@googlemaps/markerclusterer", replacement: "@googlemaps/markerclusterer/dist/index.esm.js" },
      { find: /^vuelidate$/, replacement: jsRoot.join("vendor/vuelidate/index.js") },
      { find: "vuelidate/lib/validators", replacement: jsRoot.join("vendor/vuelidate/validators/index.js") },
    ],
  },

  plugins: [
    createVuePlugin(),
    createRailsPlugin({
      stimulus: false,
      sri:      false, // XXX: evaluate
    }),
    createInjectPlugin({
      $:      "jquery",
      jQuery: "jquery",
      Popper: ["popper.js", "default"],
    }),
  ],
})
