<script setup lang="ts">
interface Props {
  title?: string;
  description?: string;
}

withDefaults(defineProps<Props>(), {
  title: "Berufe",
  description: "Profissionais verificados para sua casa e seu dia a dia.",
});
</script>

<template>
  <div
    style="
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      width: 1200px;
      height: 630px;
      padding: 80px;
      background: #12625d;
      color: #f7f5ef;
      font-family: sans-serif;
    "
  >
    <div style="display: flex; align-items: center">
      <span style="font-size: 40px; font-weight: 700">berufe</span>
      <span style="font-size: 40px; font-weight: 700; color: #f8755d">.</span>
    </div>
    <div style="display: flex; flex-direction: column; gap: 20px">
      <span
        style="
          font-size: 58px;
          font-weight: 700;
          line-height: 1.15;
          max-width: 980px;
        "
      >
        {{ title }}
      </span>
      <span
        style="
          font-size: 28px;
          color: #d8f0e7;
          max-width: 900px;
          line-height: 1.4;
        "
      >
        {{ description }}
      </span>
    </div>
  </div>
</template>
