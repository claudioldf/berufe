import { mountSuspended } from "@nuxt/test-utils/runtime";
import type { NuxtError } from "#app";
import ErrorPage from "../../app/error.vue";

function nuxtError(status: number): NuxtError {
  return {
    status,
    statusCode: status,
    fatal: true,
    unhandled: false,
  };
}

describe("production error page", () => {
  it("gives a lost visitor useful ways out of a 404", async () => {
    const wrapper = await mountSuspended(ErrorPage, {
      props: { error: nuxtError(404) },
    });

    expect(wrapper.get("h1").text()).toContain(
      "Este endereço não mora mais aqui.",
    );
    expect(wrapper.text()).toContain("Erro 404");
    expect(wrapper.get('a[href="/"]').text()).toContain("berufe");
    expect(wrapper.get('a[href="/encontrar"]').text()).toBe(
      "Encontrar profissionais",
    );
    expect(wrapper.text()).not.toContain("Tentar novamente");
  });

  it("offers a retry-first recovery path for any 5xx error", async () => {
    const wrapper = await mountSuspended(ErrorPage, {
      props: { error: nuxtError(503) },
    });

    expect(wrapper.get("h1").text()).toContain(
      "Nossa casa precisa de um pequeno ajuste.",
    );
    expect(wrapper.text()).toContain("Erro 503");
    expect(
      wrapper.get('a[aria-label="Tentar carregar esta página novamente"]'),
    ).toBeDefined();
    expect(wrapper.text()).not.toContain("Encontrar profissionais");
  });
});
