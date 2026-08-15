import { effectScope, nextTick } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import moderationData from "../../data/moderation.json";
import professionalsData from "../../data/professionals.json";
import type { ModerationQueueItem, Professional } from "~/types";
import { useModerationQueue } from "~/composables/useModerationQueue";
import { usePhoneAuthFlow } from "~/composables/usePhoneAuthFlow";
import { useProfessionalProfileDraft } from "~/composables/useProfessionalProfileDraft";

afterEach(() => {
  vi.useRealTimers();
});

describe("moderation queue", () => {
  it("filters searchable fields and advances selection after a decision", async () => {
    const workflow = useModerationQueue(
      moderationData.queue as ModerationQueueItem[],
    );
    workflow.searchQuery.value = "verificação";
    await nextTick();
    expect(workflow.filteredQueue.value.length).toBeGreaterThan(0);
    expect(
      workflow.filteredQueue.value.every((item) =>
        `${item.type} ${item.title}`
          .toLocaleLowerCase("pt-BR")
          .includes("verificação"),
      ),
    ).toBe(true);

    const decided = workflow.decide();
    expect(decided).not.toBeNull();
    expect(workflow.queue.value).not.toContainEqual(decided);
  });
});

describe("profile drafts", () => {
  it("clones arrays and returns a normalized typed payload", () => {
    const professional = (professionalsData as Professional[])[0]!;
    const workflow = useProfessionalProfileDraft(professional);
    workflow.form.instagram = "@berufe";
    const draft = workflow.commit();

    expect(draft?.instagram).toBe("https://www.instagram.com/berufe/");
    expect(draft?.selectedServices).not.toBe(professional.services);
  });
});

describe("phone authentication", () => {
  it("owns the OTP progression and clears timers with its effect scope", () => {
    vi.useFakeTimers();
    const scope = effectScope();
    const workflow = scope.run(() => usePhoneAuthFlow())!;

    workflow.requestCode();
    vi.advanceTimersByTime(650);
    expect(workflow.step.value).toBe(2);
    expect(workflow.cooldown.value).toBe(30);

    workflow.code.value = "123456";
    workflow.verifyCode();
    vi.advanceTimersByTime(650);
    expect(workflow.step.value).toBe(3);

    scope.stop();
    expect(vi.getTimerCount()).toBe(0);
  });
});
