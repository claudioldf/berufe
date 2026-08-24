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
    searchError: { value: "" },
    candidates: { value: [] },
    isSearching: { value: false },
    searchedQuery: { value: "" },
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
    to: { type: String, default: "" },
  },
  emits: ["click"],
  template:
    '<button type="button" :disabled="disabled" :data-to="to" @click="$emit(\'click\')"><slot /></button>',
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

async function enterProfessionalNameAndFinishSearch(
  wrapper: Awaited<ReturnType<typeof mountDialog>>,
  name: string,
) {
  vi.useFakeTimers();
  try {
    await wrapper.get('input[name="professional-search"]').setValue(name);
    await vi.advanceTimersByTimeAsync(500);
  } finally {
    vi.useRealTimers();
  }
}

describe("relationship create dialog", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.state.isSubmitting.value = false;
    mocks.state.error.value = "";
    mocks.state.searchError.value = "";
    mocks.state.candidates.value = [];
    mocks.state.isSearching.value = false;
    mocks.state.searchedQuery.value = "";
    mocks.requestRelationship.mockResolvedValue(createdRelationship);
    mocks.searchCandidates.mockResolvedValue([]);
  });

  it("waits until typing pauses before requesting professional suggestions", async () => {
    const wrapper = await mountDialog();
    vi.useFakeTimers();

    try {
      const search = wrapper.get('input[name="professional-search"]');
      await search.setValue("B");
      expect(search.attributes("aria-busy")).toBe("true");
      expect(wrapper.find(".professional-lookup__loader").exists()).toBe(true);
      await vi.advanceTimersByTimeAsync(300);
      await search.setValue("Beto");
      await vi.advanceTimersByTimeAsync(499);

      expect(mocks.searchCandidates).not.toHaveBeenCalled();
      expect(search.attributes("aria-busy")).toBe("true");

      await vi.advanceTimersByTimeAsync(1);
      expect(mocks.searchCandidates).toHaveBeenCalledOnce();
      expect(mocks.searchCandidates).toHaveBeenCalledWith("Beto");
      expect(search.attributes("aria-busy")).toBe("false");
    } finally {
      vi.useRealTimers();
    }
  });

  it("shows candidate loading inside the professional name input", async () => {
    mocks.state.isSearching.value = true;
    const wrapper = await mountDialog();
    const search = wrapper.get('input[name="professional-search"]');

    expect(search.attributes("type")).toBe("text");
    expect(search.attributes("placeholder")).toBe(
      "Digite o nome do profissional aqui...",
    );
    expect(search.attributes("aria-busy")).toBe("true");
    expect(wrapper.find(".professional-lookup__loader").exists()).toBe(true);
    expect(wrapper.find(".professional-lookup__feedback").exists()).toBe(false);
    expect(wrapper.get(".professional-lookup__status").text()).toBe(
      "Buscando profissionais",
    );
  });

  it("requires a choice when the candidate search returns suggestions", async () => {
    mocks.state.searchedQuery.value = "Beto Lima";
    mocks.state.candidates.value = [
      {
        id: createdRelationship.recipient.id,
        publicSlug: createdRelationship.recipient.publicSlug,
        displayName: createdRelationship.recipient.displayName,
        profileType: "self_service",
        photoUrl: null,
      },
    ];
    const wrapper = await mountDialog();
    await enterProfessionalNameAndFinishSearch(wrapper, "Beto Lima");
    const continueButton = wrapper
      .findAll("footer button")
      .find((button) => button.text().includes("Continuar"))!;

    expect(continueButton.attributes("disabled")).toBeDefined();
    expect(wrapper.text()).toContain("Não encontrei a pessoa na lista");
    expect(wrapper.text()).toContain("Continuar informando o telefone");

    await wrapper
      .findAll("button")
      .find((button) =>
        button.text().includes("Não encontrei a pessoa na lista"),
      )!
      .trigger("click");

    expect(continueButton.attributes("disabled")).toBeUndefined();
    await continueButton.trigger("click");
    expect(wrapper.find('input[name="external-phone"]').exists()).toBe(true);
  });

  it("removes the upfront mode choice and creates an external target on the second step", async () => {
    mocks.state.searchedQuery.value = "Beto Lima";
    const wrapper = await mountDialog();
    expect(wrapper.text()).not.toContain("Já está na Berufe");
    expect(wrapper.text()).not.toContain("Adicionar pelo telefone");
    expect(wrapper.text()).toContain(
      "Boas conexões tornam seu perfil mais forte.",
    );

    await enterProfessionalNameAndFinishSearch(wrapper, "Beto Lima");
    await wrapper
      .findAll("footer button")
      .find((button) => button.text().includes("Continuar"))!
      .trigger("click");
    expect(wrapper.text()).toContain(
      "Qual o serviço esse profissional oferece?",
    );
    expect(wrapper.text()).toContain("Qual região esse profissional atende?");
    expect(wrapper.text()).toContain("Não sei");
    await wrapper
      .get('input[name="external-phone"]')
      .setValue("(47) 99999-1234");
    await wrapper
      .findAll("footer button")
      .find((button) => button.text().includes("Voltar"))!
      .trigger("click");
    expect(wrapper.find('input[name="external-phone"]').exists()).toBe(false);
    await wrapper
      .findAll("footer button")
      .find((button) => button.text().includes("Continuar"))!
      .trigger("click");
    expect(
      wrapper.get<HTMLInputElement>('input[name="external-phone"]').element
        .value,
    ).toBe("(47) 99999-1234");
    await wrapper
      .get(`input[value="cc1e5dfa-36a2-4f13-b37c-d1a3f9d25460"]`)
      .setValue(true);
    await wrapper.get('input[value="all_joinville"]').setValue(true);
    expect(
      wrapper.find('input[name="external-contact-consent"]').exists(),
    ).toBe(false);
    expect(wrapper.text()).not.toContain(
      "Confirmo que posso compartilhar estes dados profissionais",
    );
    await wrapper.get("select").setValue("worked_together");
    await wrapper.get("textarea").setValue("Executamos uma reforma juntos.");
    await wrapper
      .findAll("footer button")
      .find((button) => button.text().includes("Conectar"))!
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
      expect.objectContaining({ title: "Solicitação de conexão enviada" }),
    );
  });

  it("continues with a selected Berufe professional without asking for a phone", async () => {
    mocks.state.candidates.value = [
      {
        id: createdRelationship.recipient.id,
        publicSlug: createdRelationship.recipient.publicSlug,
        displayName: createdRelationship.recipient.displayName,
        profileType: "self_service",
        photoUrl: null,
      },
    ];
    const wrapper = await mountDialog();
    await enterProfessionalNameAndFinishSearch(wrapper, "Beto Lima");
    await wrapper
      .findAll("button")
      .find((button) => button.text().includes("Beto Lima"))!
      .trigger("click");
    await wrapper
      .findAll("footer button")
      .find((button) => button.text().includes("Continuar"))!
      .trigger("click");
    await wrapper
      .findAll("footer button")
      .find((button) => button.text().includes("Conectar"))!
      .trigger("click");

    expect(wrapper.find('input[name="external-phone"]').exists()).toBe(false);
    expect(mocks.requestRelationship).toHaveBeenCalledWith({
      target: {
        type: "profile",
        professionalProfileId: createdRelationship.recipient.id,
      },
      relationshipType: "recommendation",
      contextNote: "",
    });
  });

  it("blocks submission when the account is not eligible", async () => {
    const wrapper = await mountDialog(false);

    const alert = wrapper.get('[role="alert"]');
    expect(alert.text()).toContain(
      "conclua seu cadastro, confirme o telefone e tenha a identidade aprovada",
    );
    expect(alert.text()).toContain(
      "Prepare seu perfil para criar conexões reais.",
    );
    expect(alert.text()).toContain(
      "Recomendações confirmadas fortalecem os dois perfis",
    );
    expect(
      alert.find(".relationship-create-dialog__eligibility-icon").exists(),
    ).toBe(true);
    expect(
      alert
        .findAll("button")
        .find((button) => button.text().includes("Concluir meu perfil"))
        ?.attributes("data-to"),
    ).toBe("/app/professional/profile?tab=verificacoes");
    expect(
      wrapper
        .findAll("footer button")
        .some((button) => button.text().trim() === "Conectar"),
    ).toBe(false);
    expect(mocks.requestRelationship).not.toHaveBeenCalled();
  });
});
