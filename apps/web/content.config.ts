import { defineCollection, defineContentConfig, z } from "@nuxt/content";

export default defineContentConfig({
  collections: {
    guias: defineCollection({
      type: "page",
      source: "guias/*.md",
      schema: z.object({
        title: z.string(),
        description: z.string(),
        publishedAt: z.string(),
        updatedAt: z.string().optional(),
      }),
    }),
  },
});
