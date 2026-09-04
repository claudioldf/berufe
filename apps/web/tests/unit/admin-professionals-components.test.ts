import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent, readonly, shallowRef } from "vue";
import Table from "@app/components/admin/professionals/Table.vue";
import Toolbar from "@app/components/admin/professionals/Toolbar.vue";
import UnpublishDialog from "@app/components/admin/professionals/UnpublishDialog.vue";
import type { AdminProfessionalItem, AdminProfessionalPage } from "@app/types";

const mocks = vi.hoisted(() => ({
  loadStates: vi.fn(),
  loadCities: vi.fn(),
}));

vi.mock("@app/composables/useLocations", () => {
  const states = shallowRef([
    { code: "42", abbreviation: "SC", name: "Santa Catarina" },
  ]);
  const cities = shallowRef([
    {
      code: "4209102",
      name: "Joinville",
      slug: "joinville",
      stateCode: "42",
      stateAbbreviation: "SC",
      stateName: "Santa Catarina",
    },
  ]);
  return {
    useLocations: () => ({
      states: readonly(states),
      cities: readonly(cities),
      neighborhoods: readonly(shallowRef([])),
      loading: readonly(shallowRef(false)),
      error: readonly(shallowRef("")),
      loadStates: mocks.loadStates,
      loadCities: mocks.loadCities,
      loadNeighborhoods: vi.fn(),
      initialize: vi.fn(),
    }),
  };
});

const UButtonStub = defineComponent({
  props: {
    label: { type: String, default: "" },
    disabled: { type: Boolean, default: false },
    loading: { type: Boolean, default: false },
  },
  emits: ["click"],
  template:
    '<button :disabled="disabled" @click="$emit(\'click\')"><slot>{{ label }}</slot></button>',
});

const UModalStub = defineComponent({
  props: {
    open: { type: Boolean, default: false },
    description: { type: String, default: "" },
  },
  template:
    '<section v-if="open"><p>{{ description }}</p><slot name="body" /><footer><slot name="footer" /></footer></section>',
});

const FieldStub = defineComponent({
  props: { label: { type: String, default: "" } },
  template: "<label>{{ label }}<slot :control-id=\"'field'\" /></label>",
});

const summary: AdminProfessionalPage["summary"] = {
  total: 10,
  published: 6,
  suspended: 1,
  onboardingFinished: 7,
  identityVerified: 3,
};

describe("administrator professionals toolbar", () => {
  it("submits name and phone together and emits immediate filter changes", async () => {
    const wrapper = await mountSuspended(Toolbar, {
      props: {
        summary,
        q: "",
        phone: "",
        city: null,
        state: null,
        identityVerified: "all",
        onboardingFinished: "all",
        sort: "recent",
        isLoading: false,
      },
      global: { stubs: { UButton: UButtonStub, UIcon: true } },
    });

    await wrapper.get("#professionals-q").setValue("ana");
    await wrapper.get("#professionals-phone").setValue("47999996003");
    expect(
      wrapper.get<HTMLInputElement>("#professionals-phone").element.value,
    ).toBe("(47) 9 9999-6003");
    await wrapper.get("form").trigger("submit");
    expect(wrapper.emitted("search")).toEqual([["ana"]]);
    expect(wrapper.emitted("phone")).toEqual([["5547999996003"]]);

    await wrapper.get("#professionals-identity").setValue("yes");
    expect(wrapper.emitted("identityVerified")).toEqual([["yes"]]);

    await wrapper.get("#professionals-onboarding").setValue("no");
    expect(wrapper.emitted("onboardingFinished")).toEqual([["no"]]);

    await wrapper.get("#professionals-sort").setValue("name_asc");
    expect(wrapper.emitted("sort")).toEqual([["name_asc"]]);

    await wrapper.get("#professionals-state").setValue("SC");
    expect(wrapper.emitted("state")).toEqual([["SC"]]);
    expect(mocks.loadCities).toHaveBeenCalledWith("SC");

    await wrapper.findAll("button").at(-1)?.trigger("click");
    expect(wrapper.emitted("clear")).toBeTruthy();
  });

  it("shows the summary totals", async () => {
    const wrapper = await mountSuspended(Toolbar, {
      props: {
        summary,
        q: "",
        phone: "",
        city: null,
        state: null,
        identityVerified: "all",
        onboardingFinished: "all",
        sort: "recent",
        isLoading: false,
      },
      global: { stubs: { UButton: UButtonStub, UIcon: true } },
    });

    expect(wrapper.text()).toContain("10");
    expect(wrapper.text()).toContain("6");
    expect(wrapper.text()).toContain("Identidade verificada");
  });
});

const publishedItem: AdminProfessionalItem = {
  id: "account-1",
  professionalProfileId: "profile-1",
  publicSlug: "ana-souza",
  displayName: "Ana Souza",
  profileStatus: "published",
  city: "Joinville",
  state: "SC",
  phoneVerified: true,
  phoneLast4: "4002",
  identityVerified: true,
  accountStatus: "active",
  impersonationEligible: true,
  portfolioCount: 3,
  referenceCount: 1,
  customerCount: 5,
  quoteCount: 2,
  registeredAt: "2026-01-10T12:00:00Z",
  lastLoginAt: "2026-08-20T09:00:00Z",
  loginCount: 7,
  publishedAt: "2026-01-12T12:00:00Z",
};

const meta: AdminProfessionalPage["meta"] = {
  page: 1,
  perPage: 20,
  totalCount: 2,
  totalPages: 2,
};

describe("administrator professionals table", () => {
  it("shows a published professional with an active unpublish action", async () => {
    const wrapper = await mountSuspended(Table, {
      props: {
        items: [publishedItem],
        meta,
        isMutating: false,
        isManaging: false,
      },
      global: { stubs: { UButton: UButtonStub, UIcon: true } },
    });

    expect(wrapper.find("table").exists()).toBe(true);
    expect(wrapper.text()).toContain("Ana Souza");
    expect(wrapper.text()).toContain("•••• 4002");
    expect(wrapper.text()).toContain("Verificada");
    expect(wrapper.text()).toContain("Publicado");
    expect(wrapper.text()).toContain("Joinville/SC");

    const actions = wrapper.findAll(".professionals-list__action button");
    await actions[0]?.trigger("click");
    expect(wrapper.emitted("manage")).toEqual([[publishedItem]]);
    await actions[1]?.trigger("click");
    expect(wrapper.emitted("unpublish")).toEqual([[publishedItem]]);

    await wrapper
      .get(".professionals-pagination button:last-child")
      .trigger("click");
    expect(wrapper.emitted("changePage")).toEqual([[2]]);
  });

  it("offers to publish a suspended professional", async () => {
    const suspended: AdminProfessionalItem = {
      ...publishedItem,
      profileStatus: "suspended",
    };
    const wrapper = await mountSuspended(Table, {
      props: {
        items: [suspended],
        meta: { ...meta, totalPages: 1 },
        isMutating: false,
        isManaging: false,
      },
      global: { stubs: { UButton: UButtonStub, UIcon: true } },
    });

    await wrapper
      .findAll(".professionals-list__action button")[1]
      ?.trigger("click");
    expect(wrapper.emitted("publish")).toEqual([[suspended]]);
  });

  it("locks all row actions while account management is starting", async () => {
    const wrapper = await mountSuspended(Table, {
      props: {
        items: [publishedItem],
        meta: { ...meta, totalPages: 1 },
        isMutating: false,
        isManaging: true,
      },
      global: { stubs: { UButton: UButtonStub, UIcon: true } },
    });

    for (const button of wrapper.findAll(
      ".professionals-list__action button",
    )) {
      expect(button.attributes("disabled")).toBeDefined();
    }
  });

  it("disables the action for a draft professional without a submitted profile", async () => {
    const draft: AdminProfessionalItem = {
      ...publishedItem,
      profileStatus: "draft",
      identityVerified: false,
      phoneVerified: false,
      phoneLast4: null,
      impersonationEligible: false,
    };
    const wrapper = await mountSuspended(Table, {
      props: {
        items: [draft],
        meta: { ...meta, totalPages: 1 },
        isMutating: false,
        isManaging: false,
      },
      global: { stubs: { UButton: UButtonStub, UIcon: true } },
    });

    const actions = wrapper.findAll(".professionals-list__action button");
    expect(actions[0]?.attributes("disabled")).not.toBeUndefined();
    expect(actions[1]?.attributes("disabled")).not.toBeUndefined();
    expect(wrapper.text()).toContain("Não verificada");
    expect(wrapper.text()).toContain("Rascunho");
  });
});

describe("administrator professionals unpublish dialog", () => {
  it("requires at least ten characters before confirming", async () => {
    const wrapper = await mountSuspended(UnpublishDialog, {
      props: { open: true, reason: "", displayName: "Ana Souza" },
      global: {
        stubs: {
          UModal: UModalStub,
          UButton: UButtonStub,
          DesignSystemFormField: FieldStub,
        },
      },
    });

    expect(wrapper.text()).toContain("Ana Souza");
    const confirmButton = wrapper.findAll("button").at(-1);
    expect(confirmButton?.attributes("disabled")).not.toBeUndefined();

    await wrapper.get("textarea").setValue("Motivo com detalhes suficientes.");
    expect(wrapper.emitted("update:reason")?.at(-1)).toEqual([
      "Motivo com detalhes suficientes.",
    ]);
  });

  it("locks the reason and dialog actions while submitting", async () => {
    const wrapper = await mountSuspended(UnpublishDialog, {
      props: {
        open: true,
        reason: "Motivo com detalhes suficientes.",
        displayName: "Ana Souza",
        submitting: true,
      },
      global: {
        stubs: {
          UModal: UModalStub,
          UButton: UButtonStub,
          DesignSystemFormField: FieldStub,
        },
      },
    });

    expect(wrapper.get("textarea").attributes("disabled")).toBeDefined();
    for (const button of wrapper.findAll("button")) {
      expect(button.attributes("disabled")).toBeDefined();
    }
  });
});
