import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import RelationshipCreateDialog from "@app/components/relationship/CreateDialog.vue";

const mocks = vi.hoisted(() => ({
  requestRelationship: vi.fn(),
  searchCandidates: vi.fn(),
  clearCandidates: vi.fn(),
  clearError: vi.fn(),
  showToast: vi.fn(),
  state: {
    isSubmitting: { value: false },
    error: { value: "" },
    candidates: { value: [] },
    isSearching: { value: false },
  },
}));

vi.mock("@app/composables/useProfessionalRelationships", () => ({
  useProfessionalRelationships: () => ({
    ...mocks.state,
    requestRelationship: mocks.requestRelationship,
    searchCandidates: mocks.searchCandidates,
    clearCandidates: mocks.clearCandidates,
    clearError: mocks.clearError,
  }),
}));
vi.mock("@app/composables/useToast", () => ({
  useToast: () => ({ showToast: mocks.showToast }),
}));

const ModalStub = defineComponent({
  props: { open: { type: Boolean, default: false } },
  emits: ["update:open"],
  template:
    '<section v-if="open"><slot name="body" /><footer><slot name="footer" /></footer></section>',
});
const FieldStub = defineComponent({
  props: { label: { type: String, default: "" } },
  template: "<label>{{ label }}<slot /></label>",
});
const ButtonStub = defineComponent({
  props: {
    disabled: { type: Boolean, default: false },
    loading: { type: Boolean, default: false },
  },
  emits: ["click"],
  template:
    '<button type="button" :disabled="disabled" @click="$emit(\'click\')"><slot /></button>',
});

const createdRelationship = {
  id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
  relationshipType: "worked_together",
  contextNote: "Executamos uma reforma juntos.",
  status: "pending",
  source: "external_phone",
  createdAt: "2026-08-20T12:00:00Z",
  respondedAt: null,
  initiator: {
    id: "f39d4810-f28d-4977-b5e5-387131d12942",
    publicSlug: "ana-souza",
    displayName: "Ana Souza",
    profileType: "self_service",
    photoUrl: null,
    profileAvailable: true,
  },
  recipient: {
    id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
    publicSlug: "beto-lima",
    displayName: "Beto Lima",
    profileType: "external",
    photoUrl: null,
    profileAvailable: true,
  },
} as const;

async function mountDialog(eligible = true) {
  return mountSuspended(RelationshipCreateDialog, {
    props: {
      open: true,
      eligible,
      services: [
        {
          id: "cc1e5dfa-36a2-4f13-b37c-d1a3f9d25460",
          name: "Pintura",
          slug: "pintura",
          categoryId: "category",
          categoryName: "Reformas",
          icon: "i-lucide-paint-roller",
          description: "Pintura residencial.",
          aliases: [],
        },
      ],
      neighborhoods: [{ code: "america", name: "América", city: "Joinville" }],
    },
    global: {
      stubs: {
        UModal: ModalStub,
        UButton: ButtonStub,
        UIcon: true,
        DesignSystemFormField: FieldStub,
      },
    },
  });
}

describe("relationship create dialog", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.state.isSubmitting.value = false;
    mocks.state.error.value = "";
    mocks.requestRelationship.mockResolvedValue(createdRelationship);
  });

  it("creates an external target with normalized phone, optional supply, and explicit attestation", async () => {
    const wrapper = await mountDialog();
    await wrapper
      .findAll("button")
      .find((button) => button.text().includes("Adicionar pelo telefone"))!
      .trigger("click");
    await wrapper.get('input[name="external-name"]').setValue("Beto Lima");
    await wrapper
      .get('input[name="external-phone"]')
      .setValue("(47) 99999-1234");
    await wrapper
      .get(`input[value="cc1e5dfa-36a2-4f13-b37c-d1a3f9d25460"]`)
      .setValue(true);
    await wrapper.get('input[value="all_joinville"]').setValue(true);
    await wrapper.get('input[name="external-contact-consent"]').setValue(true);
    await wrapper.get("select").setValue("worked_together");
    await wrapper.get("textarea").setValue("Executamos uma reforma juntos.");
    await wrapper
      .findAll("footer button")
      .find((button) => button.text().includes("Enviar solicitação"))!
      .trigger("click");

    expect(mocks.requestRelationship).toHaveBeenCalledWith({
      target: {
        type: "phone",
        name: "Beto Lima",
        phone: "+5547999991234",
        serviceIds: ["cc1e5dfa-36a2-4f13-b37c-d1a3f9d25460"],
        coverage: { allJoinville: true, neighborhoodCodes: [] },
        contactPublicationAttested: true,
      },
      relationshipType: "worked_together",
      contextNote: "Executamos uma reforma juntos.",
    });
    expect(wrapper.emitted("created")?.at(-1)).toEqual([createdRelationship]);
    expect(mocks.showToast).toHaveBeenCalledWith(
      expect.objectContaining({ title: "Solicitação enviada" }),
    );
  });

  it("blocks submission when the account is not eligible", async () => {
    const wrapper = await mountDialog(false);

    expect(wrapper.get('[role="alert"]').text()).toContain(
      "conclua seu cadastro, confirme o telefone e tenha a identidade aprovada",
    );
    expect(wrapper.text()).not.toContain("Enviar solicitação");
    expect(mocks.requestRelationship).not.toHaveBeenCalled();
  });
});
