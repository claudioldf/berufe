import withNuxt from "./.nuxt/eslint.config.mjs";

export default withNuxt(
  {
    name: "berufe/generated-ignores",
    ignores: ["coverage/**"],
  },
  {
    rules: {
      "vue/html-self-closing": [
        "error",
        {
          html: {
            void: "always",
            normal: "always",
            component: "always",
          },
          svg: "always",
          math: "always",
        },
      ],
      "vue/multi-word-component-names": "off",
      "vue/no-v-html": "error",
    },
  },
);
