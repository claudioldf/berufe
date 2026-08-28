<script setup lang="ts">
interface Props {
  name: string;
  service?: string;
  city?: string;
}

const props = defineProps<Props>();
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
      <span style="font-size: 32px; font-weight: 700">berufe</span>
      <span style="font-size: 32px; font-weight: 700; color: #f8755d">.</span>
    </div>
    <div style="display: flex; flex-direction: column; gap: 16px">
      <span
        v-if="props.service"
        style="
          font-size: 26px;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: 2px;
          color: #f8755d;
        "
      >
        {{ props.service }}
      </span>
      <span style="font-size: 64px; font-weight: 700; line-height: 1.1">
        {{ props.name }}
      </span>
      <span v-if="props.city" style="font-size: 30px; color: #d8f0e7">
        Atende em {{ props.city }}
      </span>
    </div>
  </div>
</template>
