<script setup lang="ts">
import catalogsData from "@data/catalogs.json";
import type {
  Neighborhood,
  Professional,
  ProfessionalProfileDraft,
  Service,
} from "~/types";
import { useProfessionalProfileDraft } from "~/composables/useProfessionalProfileDraft";

const props = defineProps<{ professional: Professional }>();
const emit = defineEmits<{ save: [draft: ProfessionalProfileDraft] }>();
const services = catalogsData.services as Service[];
const neighborhoods = catalogsData.neighborhoods.filter(
  (item) => item.code !== "all",
) as Neighborhood[];

const {
  form,
  saved,
  socialErrors,
  markDirty,
  validateSocialField,
  clearSocialError,
  toggleService,
  toggleNeighborhood,
  commit,
} = useProfessionalProfileDraft(() => props.professional);

function save() {
  const draft = commit();
  if (draft) emit("save", draft);
}
</script>

<template>
  <form class="profile-editor" @input="markDirty" @submit.prevent="save">
    <DashboardProfileFormLayout>
      <DashboardProfileIdentitySection v-model="form" />
      <DashboardProfileSocialSection
        v-model="form"
        :errors="socialErrors"
        @clear="clearSocialError"
        @validate="validateSocialField"
      />
      <DashboardProfileServicesSection
        v-model="form"
        :services="services"
        @toggle="toggleService"
      />
      <DashboardProfileCoverageSection
        v-model="form"
        :neighborhoods="neighborhoods"
        @dirty="markDirty"
        @toggle="toggleNeighborhood"
      />
    </DashboardProfileFormLayout>
    <DashboardProfileSaveBar :saved="saved" />
  </form>
</template>

<style scoped lang="scss">
.profile-editor {
  display: grid;
  gap: 18px;
}

:deep() {
  .editor-savebar {
    position: sticky;
    z-index: 20;
    bottom: 14px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 15px;
    padding: 12px 14px;
    border: 1px solid var(--line);
    border-radius: 15px;
    background: rgb(255 255 255 / 95%);
    box-shadow: var(--shadow-lg);
    backdrop-filter: blur(14px);
  }
  .editor-savebar > span {
    display: flex;
    align-items: center;
    gap: 6px;
    color: var(--ink-soft);
    font-size: 0.86rem;
    font-weight: 700;
  }
  .editor-savebar > div {
    display: flex;
    gap: 8px;
  }
  @media (width <= 750px) {
    .editor-savebar {
      display: grid;
    }
    .editor-savebar > div {
      justify-content: stretch;
    }
    .editor-savebar > div > * {
      flex: 1;
      justify-content: center;
    }
  }
}
</style>
