import { mount } from "@vue/test-utils";
import { nextTick } from "vue";
import VerificationPanel from "~/components/dashboard/VerificationPanel.vue";
import IdentityUploadForm from "~/components/dashboard/verification/IdentityUploadForm.vue";

describe("professional verification panel", () => {
  it("allows submit to reveal and focus a missing identity image", async () => {
    const wrapper = mount(IdentityUploadForm, { attachTo: document.body });
    const submit = wrapper.get('button[type="submit"]');

    expect(submit.attributes("disabled")).toBeUndefined();
    await wrapper.get("form").trigger("submit");
    await nextTick();

    const file = wrapper.get<HTMLInputElement>(
      'input[name="identity-document"]',
    );
    expect(wrapper.get('[role="alert"]').text()).toContain("Selecione");
    expect(file.attributes("aria-invalid")).toBe("true");
    expect(document.activeElement).toBe(file.element);
    expect(wrapper.emitted("submitted")).toBeUndefined();
    wrapper.unmount();
  });

  it("keeps phone confirmation separate from the controlled identity label", () => {
    const wrapper = mount(VerificationPanel, {
      props: {
        evidence: [
          { id: "phone", label: "Telefone confirmado" },
          { id: "identity", label: "Identidade verificada" },
        ],
        verification: {
          current: {
            id: "verification-approved",
            verificationType: "identity",
            status: "approved",
            rejectionReason: null,
            submittedAt: "2026-08-17T12:00:00Z",
          },
        },
      },
    });

    expect(wrapper.text()).toContain("Telefone confirmado");
    expect(wrapper.text()).toContain("Confirmação concluída");
    expect(wrapper.text()).toContain("confirmou o acesso ao número cadastrado");
    expect(wrapper.text()).toContain("Identidade verificada");
    expect(wrapper.text()).toContain("Verificação concluída");
    expect(wrapper.text()).toContain("documento enviado continua privado");
    expect(
      wrapper.get(".verification-panel__phone").attributes(),
    ).toMatchObject({
      "aria-labelledby": "phone-confirmation-title",
    });
    expect(
      wrapper
        .get(".verification-panel__phone .verification-panel__status-icon")
        .attributes("aria-hidden"),
    ).toBe("true");
    expect(wrapper.get(".verification-panel__request").classes()).toContain(
      "verification-panel__confirmation",
    );
    expect(
      wrapper.get(".verification-panel__status-icon").attributes("aria-hidden"),
    ).toBe("true");
    expect(wrapper.find('input[type="file"]').exists()).toBe(false);
  });

  it("shows private pending status without exposing another upload action", () => {
    const wrapper = mount(VerificationPanel, {
      props: {
        evidence: [{ id: "phone", label: "Telefone confirmado" }],
        verification: {
          current: {
            id: "verification-1",
            verificationType: "identity",
            status: "pending_review",
            rejectionReason: null,
            submittedAt: "2026-08-17T12:00:00Z",
          },
        },
      },
    });

    expect(wrapper.text()).toContain("Aguardando análise");
    expect(wrapper.text()).toContain("está privada");
    expect(wrapper.find('input[type="file"]').exists()).toBe(false);
  });

  it("shows private rejection guidance and permits a new image", () => {
    const wrapper = mount(VerificationPanel, {
      props: {
        evidence: [{ id: "phone", label: "Telefone confirmado" }],
        verification: {
          current: {
            id: "verification-2",
            verificationType: "identity",
            status: "rejected",
            rejectionReason: "A imagem não está legível.",
            submittedAt: "2026-08-17T12:00:00Z",
          },
        },
      },
    });

    expect(wrapper.text()).toContain("A imagem não está legível.");
    expect(wrapper.find('input[type="file"]').exists()).toBe(true);
  });
});
