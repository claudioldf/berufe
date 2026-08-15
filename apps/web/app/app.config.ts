export default defineAppConfig({
  ui: {
    colors: {
      primary: "emerald",
      secondary: "orange",
      success: "emerald",
      info: "sky",
      warning: "amber",
      error: "red",
      neutral: "stone",
    },
    button: {
      slots: {
        base: "cursor-pointer disabled:cursor-not-allowed aria-disabled:cursor-not-allowed",
      },
      defaultVariants: {
        size: "lg",
      },
    },
  },
});
