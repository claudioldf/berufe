import { effectScope, nextTick, ref } from "vue";
import { useDelayedFlag } from "~/composables/useDelayedFlag";

describe("useDelayedFlag", () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  function setup(initial = false) {
    const source = ref(initial);
    const scope = effectScope();
    const delayed = scope.run(() => useDelayedFlag(source, 2_000))!;
    return { source, delayed, scope };
  }

  it("shows only after the source stayed true for the whole delay", async () => {
    const { source, delayed } = setup();

    source.value = true;
    await nextTick();
    vi.advanceTimersByTime(1_999);
    expect(delayed.value).toBe(false);

    vi.advanceTimersByTime(1);
    expect(delayed.value).toBe(true);
  });

  it("never shows when the source flips back before the delay", async () => {
    const { source, delayed } = setup();

    source.value = true;
    await nextTick();
    vi.advanceTimersByTime(1_500);
    source.value = false;
    await nextTick();
    vi.advanceTimersByTime(5_000);

    expect(delayed.value).toBe(false);
  });

  it("hides immediately when the source turns false", async () => {
    const { source, delayed } = setup();

    source.value = true;
    await nextTick();
    vi.advanceTimersByTime(2_000);
    expect(delayed.value).toBe(true);

    source.value = false;
    await nextTick();
    expect(delayed.value).toBe(false);
  });

  it("restarts the delay for a second slow load", async () => {
    const { source, delayed } = setup();

    source.value = true;
    await nextTick();
    vi.advanceTimersByTime(2_000);
    source.value = false;
    await nextTick();
    source.value = true;
    await nextTick();

    expect(delayed.value).toBe(false);
    vi.advanceTimersByTime(2_000);
    expect(delayed.value).toBe(true);
  });

  it("starts the delay for a source that is already true", () => {
    const { delayed } = setup(true);

    expect(delayed.value).toBe(false);
    vi.advanceTimersByTime(2_000);
    expect(delayed.value).toBe(true);
  });

  it("cancels a pending timer when its scope stops", async () => {
    const { source, delayed, scope } = setup();

    source.value = true;
    await nextTick();
    scope.stop();
    vi.advanceTimersByTime(5_000);

    expect(delayed.value).toBe(false);
  });
});
