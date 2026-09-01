import { config } from "@vue/test-utils";

// `UTooltip` requires a reka-ui `TooltipProvider` ancestor, which the running app gets from
// `UApp` (see app/app.vue) but a bare `mount()` does not — reka-ui's context injection throws
// without one. Stub it globally so any component wrapping a control in
// `DesignSystemDisabledTooltip` still renders that control; a test that needs the tooltip's own
// props/attributes overrides this with a per-mount stub (see tests/unit/disabled-tooltip.test.ts).
config.global.stubs = {
  ...config.global.stubs,
  UTooltip: { template: "<div><slot /></div>" },
};
