import pluginVue from "eslint-plugin-vue"
import stylisticJs from "@stylistic/eslint-plugin"

export default [
  // Ignorierte Dateien - müssen separat deklariert werden, sonst ignoriert
  // ESlint das `ignores`-Feld. Völlig klar...
  //
  // > works as intended
  // >
  // > - https://github.com/eslint/eslint/issues/18234#issuecomment-2022138665
  //
  // > "If `ignores` is used without files and there are other keys (such as `rules`),
  // > then the configuration object applies to all files except the ones specified
  // > in `ignores`.
  // >
  // > - https://eslint.org/docs/latest/use/configure/configuration-files#excluding-files-with-ignores
  {
    ignores: [
      "data/**", // file uploads
      "vendor/**", // vendor modules
      "**/node_modules/**", // really!?
      "public/packs*", // compiled assetes
      "app/javascript/**/i18n.js", // auto-generated
      "app/javascript/**/jquery.*.js", // legacy
      "app/javascript/vendor/**", // frontend vendor modules
      "app/javascript/legacy/lib/**", // legacy
      "app/javascript/legacy/plugins/**", // legacy
      "app/javascript/bsp1-hosted-iframe-form/payone_hosted_min.js", // TODO: move to vendor
    ],
  },

  stylisticJs.configs["recommended-flat"],
  ...pluginVue.configs["flat/vue2-essential"],

  {
    languageOptions: {
      ecmaVersion: "latest",
      sourceType:  "module",
      globals:     {
        $: "readonly",
      },
    },
    plugins: {
      "vue":        pluginVue,
      "@stylistic": stylisticJs,
    },
    files: [
      "*.js",
      "*.cjs",
      "config/**/*.js",
      "app/javascript/**/*.js",
      "app/javascript/**/*.vue",
    ],
    rules: {
      "constructor-super":        "error",
      "curly":                    ["error", "all"],
      "eqeqeq":                   ["error", "always", { null: "ignore" }],
      "no-const-assign":          "error",
      "no-else-return":           "error",
      "no-redeclare":             "error",
      "no-restricted-properties": ["warn",
        { property: "lengt" },
        { property: "lengh" },
        { property: "lenth" },
      ],
      "no-this-before-super": "error",
      "no-undef":             "error",
      "no-unreachable":       "error",
      "no-unused-vars":       ["error", {
        args:              "none",
        varsIgnorePattern: "^_",
        caughtErrors:      "none",
      }],
      "object-shorthand": ["error", "methods"],
      "strict":           ["error", "function"],
      "valid-typeof":     "error",

      "@stylistic/array-bracket-spacing":   ["error", "never"],
      "@stylistic/arrow-parens":            ["error", "as-needed"],
      "@stylistic/arrow-spacing":           "error",
      "@stylistic/brace-style":             ["error", "1tbs", { allowSingleLine: false }],
      "@stylistic/comma-dangle":            ["error", "always-multiline"],
      "@stylistic/comma-spacing":           ["error", { before: false, after: true }],
      "@stylistic/indent":                  ["error", 2, { VariableDeclarator: { var: 2, let: 2, const: 3 } }],
      "@stylistic/key-spacing":             ["error", { align: "value" }],
      "@stylistic/keyword-spacing":         ["error", { before: true, after: true }],
      "@stylistic/no-debugger":             "off",
      "@stylistic/no-multi-spaces":         "error",
      "@stylistic/no-multiple-empty-lines": ["error", {
        max:    1,
        maxEOF: 0,
        maxBOF: 0,
      }],
      "@stylistic/no-trailing-spaces":              "error",
      "@stylistic/object-curly-spacing":            ["error", "always"],
      "@stylistic/padded-blocks":                   ["error", "never"],
      "@stylistic/padding-line-between-statements": ["error",
        { blankLine: "always", prev: "block-like", next: "*" },
        { blankLine: "never", prev: "block-like", next: ["break", "return"] },
        { blankLine: "never", prev: ["if", "switch", "for"], next: ["if", "switch", "for"] },
        { blankLine: "always", prev: ["break", "return"], next: "case" },
        { blankLine: "always", prev: "function", next: "function" },
      ],
      "@stylistic/quotes":                      ["error", "double", { avoidEscape: true }],
      "@stylistic/semi":                        ["warn", "never"],
      "@stylistic/space-before-function-paren": ["error", "never"],
      "@stylistic/space-in-parens":             ["error", "never"],
      "@stylistic/space-infix-ops":             ["error", { int32Hint: true }],
      "@stylistic/spaced-comment":              ["error", "always", { markers: ["=", "#region", "#endregion"] }],

      "vue/eqeqeq":                    ["error", "always", { null: "ignore" }],
      "vue/first-attribute-linebreak": "error",
      "vue/html-indent":               ["error", 2, {
        attribute:                 2,
        alignAttributesVertically: false,
      }],
      "vue/html-self-closing":       "error",
      "vue/max-attributes-per-line": ["error", {
        singleline: { max: 2 },
        multiline:  { max: 1 },
      }],
      "vue/multi-word-component-names":        "warn",
      "vue/no-child-content":                  "error",
      "vue/no-empty-component-block":          "error",
      "vue/padding-line-between-blocks":       ["error", "always"],
      "vue/component-name-in-template-casing": ["warn", "PascalCase", {
        registeredComponentsOnly: false,
      }],
    },
  },
]
