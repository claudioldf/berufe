import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import RelationshipManager from "@app/components/dashboard/RelationshipManager.vue";
import type { ProfessionalRelationship } from "~/types";

const ownerId = "2cc1bdc4-e2d1-452b-8e76-241931a32bc9";
const other = {
  id: "f39d4810-f28d-4977-b5e5-387131d12942",
  publicSlug: "ana-souza",
  displayName: "Ana Souza",
  profileType: "self_service" as const,
  photoUrl: "https://api.example.test/ana.jpg",
  profileAvailable: true,
};
const owner = {
  id: ownerId,
  publicSlug: "beto-lima",
  displayName: "Beto Lima",
  profileType: "self_service" as const,
  photoUrl: null,
  profileAvailable: true,
};

function relationship(
  overrides: Partial<ProfessionalRelationship> = {},
): ProfessionalRelationship {
  return {
    id: "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
    relationshipType: "recommendation",
    contextNote: "Executamos uma reforma juntos.",
    status: "pending",
    source: "existing_profile",
    createdAt: "2026-08-17T12:00:00Z",
    respondedAt: null,
    initiator: other,
    recipient: owner,
    ...overrides,
  };
}

const ModalStub = defineComponent({
  props: {
    open: { type: Boolean, default: false },
    title: { type: String, default: "" },
    description: { type: String, default: "" },
  },
  emits: ["update:open"],
  template:
    '<section v-if="open" role="dialog"><h2>{{ title }}</h2><p>{{ description }}</p><slot name="body" /><footer><slot name="footer" /></footer></section>',
});
const ButtonStub = defineComponent({
  props: {
    disabled: { type: Boolean, default: false },
    loading: { type: Boolean, default: false },
    to: { type: String, default: "" },
  },
  emits: ["click"],
  template:
    '<button type="button" :disabled="disabled" :data-loading="loading" :data-to="to" @click="$emit(\'click\')"><slot /></button>',
});
const AvatarStub = defineComponent({
  props: { name: { type: String, required: true }, src: { type: String } },
  template: '<span class="avatar" :data-src="src">{{ name }}</span>',
});

const global = {
  stubs: {
    UModal: ModalStub,
    UButton: ButtonStub,
    DesignSystemAvatar: AvatarStub,
    DesignSystemSurfaceCard: defineComponent({
      template: "<section><slot /></section>",
    }),
    DesignSystemEyebrow: defineComponent({
      template: "<span><slot /></span>",
    }),
    UIcon: true,
  },
};

describe("professional relationship manager", () => {
  it("renders compact cards and lets the recipient respond to an inbound request", async () => {
    const accepted = relationship({
      id: "accepted-relationship",
      status: "accepted",
      respondedAt: "2026-08-18T12:00:00Z",
      initiator: owner,
      recipient: {
        ...other,
        id: "unavailable-professional",
        displayName: "Caio Costa",
        profileAvailable: false,
        photoUrl: null,
      },
    });
    const wrapper = await mountSuspended(RelationshipManager, {
      props: {
        relationships: [relationship(), accepted],
        ownerId,
      },
      global,
    });

    expect(wrapper.text()).toContain("Ana Souza recomendou você");
    expect(wrapper.text()).toContain("Aguardando sua resposta");
    expect(wrapper.text()).toContain("Caio Costa");
    expect(wrapper.text()).toContain("Perfil público indisponível");
    expect(wrapper.find('a[href="/profissionais/ana-souza"]').exists()).toBe(
      true,
    );

    const inboundCard = wrapper
      .findAll("article")
      .find((card) => card.text().includes("Ana Souza recomendou você"));
    const confirm = inboundCard!
      .findAll("button")
      .find((button) => button.text().includes("Conectar"));
    await confirm!.trigger("click");

    expect(wrapper.emitted("respond")?.[0]).toEqual([
      "d25c64fa-3e6a-4e56-adc9-85bdac0045cb",
      "accepted",
    ]);
  });

  it("confirms cancellation of an outbound request before emitting removal", async () => {
    const outbound = relationship({ initiator: owner, recipient: other });
    const wrapper = await mountSuspended(RelationshipManager, {
      props: { relationships: [outbound], ownerId },
      global,
    });

    expect(wrapper.text()).toContain("Você recomendou Ana Souza");
    await wrapper
      .findAll("button")
      .find((button) =>
        button.text().includes("Cancelar solicitação de conexão"),
      )!
      .trigger("click");

    const dialog = wrapper.get('[role="dialog"]');
    expect(dialog.text()).toContain("Cancelar solicitação de conexão");
    expect(dialog.text()).toContain("se conectar novamente no futuro");
    await dialog
      .findAll("button")
      .find((button) =>
        button.text().includes("Cancelar solicitação de conexão"),
      )!
      .trigger("click");

    expect(wrapper.emitted("remove")?.[0]).toEqual([outbound.id]);
  });

  it("shows safe error and empty feedback", async () => {
    const wrapper = await mountSuspended(RelationshipManager, {
      props: {
        relationships: [],
        ownerId,
        error: "Não foi possível remover a conexão agora.",
      },
      global,
    });

    expect(wrapper.get('[role="alert"]').text()).toContain(
      "Não foi possível remover a conexão agora.",
    );
    expect(wrapper.text()).toContain(
      "Transforme boas parcerias em prova social.",
    );
    expect(wrapper.text()).toContain("Recomendações baseadas em trabalho real");
    expect(wrapper.text()).not.toContain("Rede profissional");
    const add = wrapper
      .findAll("button")
      .find((button) => button.text().includes("Criar minha primeira conexão"));
    expect(add).toBeDefined();
    await add!.trigger("click");
    expect(wrapper.emitted("add")?.at(-1)).toEqual([]);
  });
});
