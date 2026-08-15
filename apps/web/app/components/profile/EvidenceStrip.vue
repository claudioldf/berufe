<script setup lang="ts">
import type { Evidence } from "~/types";

defineProps<{ evidence: Evidence[] }>();
</script>

<template>
  <section class="evidence-strip" aria-labelledby="evidence-strip-title">
    <DesignSystemContainer class="evidence-strip__inner">
      <div>
        <span class="evidence-strip__icon"
          ><UIcon name="i-lucide-shield-check"
        /></span>
        <div>
          <strong id="evidence-strip-title"
            >Evidências conferidas pela Berufe</strong
          >
          <small>Cada selo representa uma verificação específica.</small>
        </div>
      </div>
      <div class="evidence-strip__badges">
        <PublicEvidenceBadge
          v-for="item in evidence"
          :key="item.id"
          :evidence="item"
        />
      </div>
    </DesignSystemContainer>
  </section>
</template>
