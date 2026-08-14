import { AcheiOProfissionalService } from "./achei-o-profissional-service.js";
import { loadCategories } from "./categories.js";
import { scrapeCity } from "./city-scraper.js";
import { validateOutputFormat, writeFormattedOutput } from "./output.js";

const [city, requestedFormat = "cli", ...extraArguments] = process.argv.slice(2);

if (!city || extraArguments.length > 0) {
  console.error("Usage: npm run scrape -- <city-slug> [json|csv|cli]");
  process.exitCode = 1;
} else {
  try {
    const format = validateOutputFormat(requestedFormat.toLowerCase());
    const concurrency = Number.parseInt(
      process.env.CATEGORY_CONCURRENCY ?? "2",
      10,
    );
    const categoryDelayMs = Number.parseInt(
      process.env.CATEGORY_DELAY_MS ?? "1000",
      10,
    );
    const categories = await loadCategories();
    const result = await scrapeCity({
      categories,
      categoryConcurrency: concurrency,
      categoryDelayMs,
      city,
      service: new AcheiOProfissionalService(),
      onProgress({
        category,
        completed,
        error,
        professionalCount,
        total,
      }) {
        const outcome = error
          ? `failed: ${error}`
          : `${professionalCount} professionals`;
        console.error(
          `[${completed}/${total}] ${category.name} (${category.slug}): ${outcome}`,
        );
      },
    });
    const output = await writeFormattedOutput({ city, format, result });

    if (output.contents) {
      process.stdout.write(output.contents);
    } else {
      console.error(`Saved ${format.toUpperCase()} output to ${output.filePath}`);
    }

    if (result.categoriesFailed > 0) process.exitCode = 2;
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
