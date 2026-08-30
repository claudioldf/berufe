import { mountSuspended } from "@nuxt/test-utils/runtime";
import { defineComponent } from "vue";
import NotificationItem from "@app/components/dashboard/notifications/Item.vue";
import type { ProfessionalNotification } from "@app/types";

const NuxtLinkStub = defineComponent({
  props: { to: { type: String, required: true } },
  emits: ["click"],
  template: '<a :href="to" @click="$emit(\'click\')"><slot /></a>',
});

const item: ProfessionalNotification = {
  id: "2cc1bdc4-e2d1-452b-8e76-241931a32bc9",
  notificationType: "quote_approved",
  status: "unread",
  title: "Orçamento aprovado",
  description: "Um cliente aprovou um orçamento.",
  route: "/app/professional/quotes/new?quote=quote-id",
  occurredAt: "2026-08-30T12:00:00Z",
  readAt: null,
};

describe("professional notification item", () => {
  it("renders a navigable activity and exposes a separate read action", async () => {
    const wrapper = await mountSuspended(NotificationItem, {
      props: { notification: item },
      global: { stubs: { NuxtLink: NuxtLinkStub, UIcon: true } },
    });

    expect(wrapper.text()).toContain("Orçamento aprovado");
    expect(wrapper.get("a").attributes("href")).toBe(item.route);
    expect(wrapper.get("time").attributes("datetime")).toBe(item.occurredAt);

    await wrapper.get("a").trigger("click");
    expect(wrapper.emitted("select")?.[0]).toEqual([item]);

    await wrapper.get("button").trigger("click");
    expect(wrapper.emitted("read")?.[0]).toEqual([item]);
  });

  it("disables the read action while its mutation is pending", async () => {
    const wrapper = await mountSuspended(NotificationItem, {
      props: { notification: item, reading: true },
      global: { stubs: { NuxtLink: NuxtLinkStub, UIcon: true } },
    });

    expect(wrapper.get("button").attributes()).toHaveProperty("disabled");
  });
});
