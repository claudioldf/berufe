import { defineCollection, defineContentConfig, z } from "@nuxt/content";

const routeSlug = z.string().regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/);
const seoTitle = z.string().min(20).max(90);
const seoDescription = z.string().min(70).max(180);

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
    ajuda: defineCollection({
      type: "page",
      source: "ajuda/*.md",
      schema: z.object({
        title: z.string(),
        description: z.string(),
        action: z.enum([
          "entrar",
          "criar-conta",
          "excluir-conta",
          "editar-perfil",
        ]),
        publishedAt: z.string(),
        updatedAt: z.string().optional(),
        retention: z.boolean().default(false),
        cta: z.object({
          title: z.string(),
          description: z.string(),
          label: z.string(),
          to: z.string(),
        }),
      }),
    }),
    localPages: defineCollection({
      type: "page",
      source: "locais/**/*.md",
      schema: z.object({
        title: seoTitle,
        description: seoDescription,
        serviceSlug: routeSlug,
        stateCode: z.string().length(2),
        stateSlug: routeSlug,
        cityCode: z.string().regex(/^\d{7}$/),
        city: z.string().min(2).max(80),
        citySlug: routeSlug,
        published: z.boolean(),
        publishedAt: z.string(),
        updatedAt: z.string().optional(),
      }),
    }),
    providerPages: defineCollection({
      type: "page",
      source: "para-profissionais/*.md",
      schema: z.object({
        title: seoTitle,
        description: seoDescription,
        serviceSlug: routeSlug,
        published: z.boolean(),
        publishedAt: z.string(),
        updatedAt: z.string().optional(),
      }),
    }),
  },
});
